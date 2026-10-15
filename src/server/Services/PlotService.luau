--!strict
-- Pens, eggs and pets (server). Rework 2026-10-13 (docs/Rework.md): no more pedestals.
--   * Pens: one of the map's bases per player (5: MapBuilder.PenCount) (Base<i>, PenArea = the pen's floor and frame). No free pen ->
--     the player waits (attribute PenWaiting) and gets the next one that frees up.
--   * Eggs: a secured egg goes into the inventory (data.eggs). EquipEgg(uid) puts it in the player's hand as an
--     "Egg" Tool (one at a time); PlaceEgg(uid, position) puts the held egg down anywhere valid inside the
--     player's own pen (ownership, held tool, pen bounds, spacing, capacity, no double placement). It hatches on
--     its server-time timer (survives rejoin) where it stands.
--   * Pets: placed pets ROAM their pen. The server decides every move (one scheduler for everyone): a target
--     inside the pen away from other pets, a start/end time; the model's attributes PathFrom / PathTo /
--     PathStart / PathEnd let every client walk it smoothly (PlotController). The server knows each pet's
--     position at any time (for pickups) without moving parts every frame. A pet stops and idles while its
--     owner stands next to it (OWNER_NEAR), so it can't wander out of its Pick Up prompt mid-hold.
--     PickupPet(uid) stores a placed pet (owner only, near it); PlacePet(uid, pos?) places a stored pet.
--   * Income: every second each placed pet's income (Config/Pets x size x weather x rebirth x gamepass x Index
--     bonus) is added straight to the owner's money: no pedestals to collect, nothing earned while stored or
--     offline, nothing doubled by rejoining or trading.
--   * Hatching and model building never stop the loop for everyone: each player / model is protected, a model
--     that fails to build is retried (the pet itself is saved first, so nothing is lost or duplicated).
--
-- Data: plots = { [eggUid]: {uid, petId, size?, weather?, placedAt, hatchAt, x, z} } -- placed eggs
--       pets  = { [petUid]: {petId, size?, weather?, placed?, x?, z?} }               -- x/z = pen-local spot
-- Pen-local: PenArea's frame (origin = pen centre on the floor, -Z toward the entrance).
-- Replicated models live in Base<i>.Plots: egg: Kind="Egg", EggUid, PlacedAt, HatchAt, Rarity, ModelKey
--   pet: Kind="Pet", PetUid, OwnerUserId, Rarity, PetName, Size, Weather, Income, HatchedAt, ModelKey, Path*

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Mutations = require(Shared.Config.Mutations)
local Upgrades = require(Shared.Config.Upgrades)
local Pets = require(Shared.Config.Pets)
local Builder = require(Shared.Builders.BlockBuilder)
local Models = require(Shared.Builders.Models)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)

type EggPlot = {
	uid: string,
	petId: string,
	size: string?,
	weather: string?,
	placedAt: number,
	hatchAt: number,
	x: number,
	z: number,
}

type PetEntry = {
	petId: string,
	size: string?,
	weather: string?,
	placed: boolean?,
	x: number?,
	z: number?,
}

type Roam = {
	from: Vector3, -- pen-local (x, 0, z)
	to: Vector3,
	t0: number,
	t1: number,
	nextAt: number, -- next decision (after the walk and an idle pause)
}

local TICK = 1 -- income + hatching
local ROAM_TICK = 0.25 -- pet move decisions
local MODEL_RETRY = 5 -- seconds before rebuilding a model that failed
local PEN_MARGIN = 3.5 -- studs kept clear of the fences
local EGG_SPACING = 4 -- min distance between placed eggs
local PET_SPEED = 5 -- studs/s
local IDLE_MIN, IDLE_MAX = 2.5, 6
local PLACE_REACH = 30 -- a placement must be this close to the player
local PICKUP_REACH = 16 -- the player must be this close to the pet's (server) position
local OWNER_NEAR = 10 -- a pet stops and idles while its owner is this close (its Pick Up prompt reaches 9)
local SPAWN_ABOVE = 3

local PlotService = {}

local petsById: { [string]: Pets.Pet } = {}
for _, pet in Pets do
	petsById[pet.id] = pet
end

local rng = Random.new()
local limiter = RateLimiter.new()
local baseOf: { [Player]: Model } = {}
local waiting: { Player } = {} -- no free pen yet, in join order
local roams: { [Player]: { [string]: Roam } } = {}
local retryAt: { [Player]: { [string]: number } } = {} -- uid -> when to rebuild a failed model
local carry: { [Player]: number } = {} -- fractional income not yet paid
local eggHatched: RemoteEvent
local announce: RemoteEvent

-- Pens -------------------------------------------------------------------------------------------------------

local function basesFolder(): Instance?
	local map = workspace:FindFirstChild("Map")
	local safeZone = map and map:FindFirstChild("SafeZone")
	return safeZone and safeZone:FindFirstChild("Bases")
end

local function plotsFolder(base: Model): Folder
	local folder = base:FindFirstChild("Plots")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = "Plots"
	created.Parent = base
	return created
end

local function penArea(base: Model): BasePart?
	local area = base:FindFirstChild("PenArea")
	return if area and area:IsA("BasePart") then area else nil
end

-- Usable half extents of a pen (the floor minus the fence margin).
function PlotService.penHalf(area: BasePart): (number, number)
	return area.Size.X / 2 - PEN_MARGIN, area.Size.Z / 2 - PEN_MARGIN
end

-- Pen-local (x, z) of a world position, and whether it is inside the usable pen floor.
function PlotService.toLocal(area: BasePart, world: Vector3): (number, number, boolean)
	local p = area.CFrame:PointToObjectSpace(world)
	local hx, hz = PlotService.penHalf(area)
	return p.X, p.Z, math.abs(p.X) <= hx and math.abs(p.Z) <= hz and math.abs(p.Y) <= 6
end

-- World position on the pen floor of pen-local (x, z).
function PlotService.toWorld(area: BasePart, x: number, z: number): Vector3
	return (area.CFrame * CFrame.new(x, area.Size.Y / 2, z)).Position
end

local function clampLocal(area: BasePart, x: number, z: number): (number, number)
	local hx, hz = PlotService.penHalf(area)
	return math.clamp(x, -hx, hx), math.clamp(z, -hz, hz)
end

-- Pen capacity (placed eggs + placed pets) from the pen level (Config/Upgrades.Pen).
function PlotService.slotsForPen(penLevel: number): number
	local slots = Economy.PlotSlots.base + (penLevel - 1) * Upgrades.Pen.slotsPerLevel
	return math.clamp(slots, 1, Economy.PlotSlots.max)
end

function PlotService.used(data: DataService.Data): number
	local n = 0
	for _ in data.plots do
		n += 1
	end
	for _, pet: PetEntry in data.pets do
		if pet.placed then
			n += 1
		end
	end
	return n
end

local function hasRoom(data: DataService.Data): boolean
	return PlotService.used(data) < PlotService.slotsForPen(data.penLevel or 1)
end

-- Income ------------------------------------------------------------------------------------------------------

local function rebirthMultiplier(data: DataService.Data): number
	return 1 + data.rebirths * Economy.Rebirth.multiplierPerRebirth
end

-- Permanent bonus from claimed Pet Index milestones (Economy.IndexMilestones[].incomeBonus).
function PlotService.indexBonus(data: DataService.Data): number
	local bonus = 0
	for _, m in Economy.IndexMilestones do
		if m.incomeBonus and data.indexMilestones and data.indexMilestones[tostring(m.count)] then
			bonus += m.incomeBonus
		end
	end
	return 1 + bonus
end

-- Optional MonetizationService exposes :GetIncomeMultiplier(player) -> number.
local function gamepassMultiplier(player: Player): number
	local module = script.Parent:FindFirstChild("MonetizationService")
	if module and module:IsA("ModuleScript") then
		local service = (require :: any)(module)
		if service.GetIncomeMultiplier then
			return service:GetIncomeMultiplier(player)
		end
	end
	return 1
end

-- $/s of one pet for this player (0 for an unknown pet).
function PlotService.petIncome(pet: PetEntry, data: DataService.Data, gamepass: number): number
	local config = petsById[pet.petId]
	if not config then
		return 0
	end
	local size = if pet.size then Mutations.Size[pet.size] else nil
	local weather = if pet.weather then Mutations.Weather[pet.weather] else nil
	return config.income
		* (if size then size.income else 1)
		* (if weather then weather.income else 1)
		* rebirthMultiplier(data)
		* gamepass
		* PlotService.indexBonus(data)
end

-- Total $/s of every placed pet.
function PlotService.incomePerSecond(player: Player, data: DataService.Data): number
	local gamepass = gamepassMultiplier(player)
	local total = 0
	for _, pet: PetEntry in data.pets do
		if pet.placed then
			total += PlotService.petIncome(pet, data, gamepass)
		end
	end
	return total
end

local function payIncome(player: Player)
	local data = DataService:Get(player)
	if not data or not baseOf[player] then
		return
	end
	local due = (carry[player] or 0) + PlotService.incomePerSecond(player, data) * TICK
	local whole = math.floor(due)
	carry[player] = due - whole
	if whole > 0 then
		DataService:Set(player, { money = data.money + whole })
		Analytics.addIncome(player, whole)
	end
	player:SetAttribute("IncomePerSecond", math.floor(PlotService.incomePerSecond(player, data) * 10) / 10)
end

-- Models ------------------------------------------------------------------------------------------------------

local function findModel(base: Model, attr: string, uid: string): Model?
	for _, child in plotsFolder(base):GetChildren() do
		if child:IsA("Model") and child:GetAttribute(attr) == uid then
			return child
		end
	end
	return nil
end

local function removeModel(base: Model, attr: string, uid: string)
	local model = findModel(base, attr, uid)
	if model then
		model:Destroy()
	end
end

-- Builds `Models.<kind>(key)` without letting one bad model break anything; nil on failure.
local function build(kind: "Egg" | "Pet", key: string): Model?
	local ok, model = pcall(if kind == "Pet" then Models.pet else Models.egg, key)
	if ok and typeof(model) == "Instance" and model:IsA("Model") and model.PrimaryPart then
		return model
	end
	warn(`[PlotService] {kind} model "{key}" failed to build: {model}`)
	return nil
end

local function markRetry(player: Player, uid: string)
	local list = retryAt[player]
	if not list then
		list = {}
		retryAt[player] = list
	end
	list[uid] = os.clock() + MODEL_RETRY
end

local function spawnEggModel(player: Player, base: Model, egg: EggPlot): Model?
	removeModel(base, "EggUid", egg.uid)
	local area = penArea(base)
	local config = petsById[egg.petId]
	local key = if config then config.model else egg.petId
	local model = build("Egg", key)
	if not model or not area then
		markRetry(player, egg.uid)
		return nil
	end
	model.Name = `Egg_{egg.uid}`
	model:SetAttribute("ModelKey", key)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Kind", "Egg")
	model:SetAttribute("EggUid", egg.uid)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("PlacedAt", egg.placedAt)
	model:SetAttribute("HatchAt", egg.hatchAt)
	model:SetAttribute("Rarity", if config then config.rarity else "Common")
	local pos = PlotService.toWorld(area, egg.x, egg.z)
	model:PivotTo(CFrame.lookAt(pos, pos + area.CFrame.LookVector))
	model.Parent = plotsFolder(base)
	return model
end

local function setPath(model: Model, area: BasePart, r: Roam)
	model:SetAttribute("PathFrom", PlotService.toWorld(area, r.from.X, r.from.Z))
	model:SetAttribute("PathTo", PlotService.toWorld(area, r.to.X, r.to.Z))
	model:SetAttribute("PathStart", r.t0)
	model:SetAttribute("PathEnd", r.t1)
end

local function spawnPetModel(player: Player, base: Model, petUid: string, pet: PetEntry, hatchedAt: number?): Model?
	removeModel(base, "PetUid", petUid)
	local area = penArea(base)
	local config = petsById[pet.petId]
	local key = if config then config.model else pet.petId
	local model = build("Pet", key)
	local data = DataService:Get(player)
	if not model or not area or not data then
		markRetry(player, petUid)
		return nil
	end
	model.Name = `Pet_{petUid}`
	model:SetAttribute("ModelKey", key)
	local size = if pet.size then Mutations.Size[pet.size] else nil
	if size then
		Builder.scale(model, size.scale)
	end
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Kind", "Pet")
	model:SetAttribute("PetUid", petUid)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("PetName", if config then config.name else pet.petId)
	model:SetAttribute("Rarity", if config then config.rarity else "Common")
	model:SetAttribute("Size", pet.size)
	model:SetAttribute("Weather", pet.weather)
	model:SetAttribute("Income", PlotService.petIncome(pet, data, gamepassMultiplier(player)))
	model:SetAttribute("HatchedAt", hatchedAt)
	local x, z = clampLocal(area, pet.x or 0, pet.z or 0)
	local here = Vector3.new(x, 0, z)
	local now = workspace:GetServerTimeNow()
	local list = roams[player]
	if not list then
		list = {}
		roams[player] = list
	end
	local r: Roam = { from = here, to = here, t0 = now, t1 = now, nextAt = now + rng:NextNumber(0.5, IDLE_MAX) }
	list[petUid] = r
	setPath(model, area, r)
	local pos = PlotService.toWorld(area, x, z)
	model:PivotTo(CFrame.lookAt(pos, pos + area.CFrame.LookVector))
	model.Parent = plotsFolder(base)
	return model
end

local function rebuildModels(player: Player)
	local base = baseOf[player]
	local data = DataService:Get(player)
	if not base or not data then
		return
	end
	plotsFolder(base):ClearAllChildren()
	roams[player] = {}
	for _, egg: EggPlot in data.plots do
		spawnEggModel(player, base, egg)
	end
	for petUid, pet: PetEntry in data.pets do
		if pet.placed then
			spawnPetModel(player, base, petUid, pet, nil)
		end
	end
end

-- Rebuilds models that failed earlier (still placed, model still missing).
local function retryModels(player: Player)
	local list = retryAt[player]
	local base = baseOf[player]
	local data = DataService:Get(player)
	if not list or not base or not data then
		return
	end
	local now = os.clock()
	for uid, at in list do
		if now < at then
			continue
		end
		list[uid] = nil
		local egg: EggPlot? = data.plots[uid]
		local pet: PetEntry? = data.pets[uid]
		if egg and not findModel(base, "EggUid", uid) then
			spawnEggModel(player, base, egg)
		elseif pet and pet.placed and not findModel(base, "PetUid", uid) then
			spawnPetModel(player, base, uid, pet, nil)
		end
	end
end

-- Roaming -----------------------------------------------------------------------------------------------------

-- The pet's pen-local position at server time `now`.
local function roamPos(r: Roam, now: number): Vector3
	if now >= r.t1 or r.t1 <= r.t0 then
		return r.to
	end
	return r.from:Lerp(r.to, (now - r.t0) / (r.t1 - r.t0))
end

-- A free-ish pen-local spot: the best of a few random candidates, away from the other pets and the eggs.
function PlotService.pickSpot(halfX: number, halfZ: number, avoid: { Vector3 }, from: Vector3?): Vector3
	local best, bestScore = Vector3.zero, -math.huge
	for _ = 1, 8 do
		local c = Vector3.new(rng:NextNumber(-halfX, halfX), 0, rng:NextNumber(-halfZ, halfZ))
		local nearest = 1e9
		for _, p in avoid do
			nearest = math.min(nearest, (p - c).Magnitude)
		end
		local score = math.min(nearest, 12)
		if from then
			local d = (c - from).Magnitude
			score -= if d < 5 then 6 else 0 -- a real walk, not a shuffle on the spot
		end
		if score > bestScore then
			best, bestScore = c, score
		end
	end
	return best
end

local function occupied(player: Player, data: DataService.Data, except: string?, now: number): { Vector3 }
	local list: { Vector3 } = {}
	for _, egg: EggPlot in data.plots do
		table.insert(list, Vector3.new(egg.x, 0, egg.z))
	end
	local pets = roams[player]
	if pets then
		for uid, r in pets do
			if uid ~= except then
				table.insert(list, r.to)
				table.insert(list, roamPos(r, now))
			end
		end
	end
	return list
end

local function roamTick(now: number)
	for player, list in roams do
		local base = baseOf[player]
		local data = DataService:Get(player)
		local area = base and penArea(base)
		if not base or not data or not area then
			continue
		end
		local hx, hz = PlotService.penHalf(area)
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local owner: Vector3? = nil
		if hrp and hrp:IsA("BasePart") then
			local ox, oz = PlotService.toLocal(area, hrp.Position)
			owner = Vector3.new(ox, 0, oz)
		end
		for uid, r in list do
			-- Idle: the owner is right here (to pick it up / look at it): stop on the spot until they step away
			local here = roamPos(r, now)
			if owner and (here - owner).Magnitude < OWNER_NEAR then
				local model = if now < r.t1 then findModel(base, "PetUid", uid) else nil
				if model then
					r.from, r.to, r.t0, r.t1 = here, here, now, now
					setPath(model, area, r)
				end
				r.nextAt = math.max(r.nextAt, now + rng:NextNumber(0.75, 1.5))
				continue
			end
			if now < r.nextAt then
				continue
			end
			local model = findModel(base, "PetUid", uid)
			local pet: PetEntry? = data.pets[uid]
			if not model or not pet or not pet.placed then
				continue
			end
			local from = roamPos(r, now)
			if math.abs(from.X) > hx + 0.5 or math.abs(from.Z) > hz + 0.5 then
				-- Returning: somehow outside the usable pen (pen changed, bad save): walk back in
				from = Vector3.new(math.clamp(from.X, -hx, hx), 0, math.clamp(from.Z, -hz, hz))
			end
			local to = PlotService.pickSpot(hx, hz, occupied(player, data, uid, now), from)
			local walk = (to - from).Magnitude / PET_SPEED
			r.from, r.to, r.t0, r.t1 = from, to, now, now + walk
			r.nextAt = r.t1 + rng:NextNumber(IDLE_MIN, IDLE_MAX)
			setPath(model, area, r)
		end
	end
end

-- Egg tools ---------------------------------------------------------------------------------------------------

local function eggIndex(data: DataService.Data, eggUid: string): number?
	for i, egg in data.eggs do
		if egg.uid == eggUid then
			return i
		end
	end
	return nil
end

-- Backpack tools: every inventory egg and every stored pet is a Tool in the player's Backpack (Roblox hotbar:
-- keys 1-9, click / tap, gamepad). The tool is only a handle on the saved item (attribute EggUid / PetUid): the
-- server makes and removes them from the data (syncTools), so they can't be duplicated, survive respawns
-- (rebuilt on CharacterAdded) and rejoining (rebuilt from the save). The held model is built only while the
-- tool is in hand (a big inventory stays light).
local function displayName(entry: { [string]: any }): string
	local config = petsById[entry.petId]
	local name = if config then config.name else tostring(entry.petId)
	local tags = {}
	if typeof(entry.size) == "string" then
		table.insert(tags, entry.size)
	end
	if typeof(entry.weather) == "string" then
		table.insert(tags, entry.weather)
	end
	table.insert(tags, name)
	return table.concat(tags, " ")
end

local function holdModel(tool: Tool, kind: "Egg" | "Pet", key: string, scale: number)
	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") or tool:FindFirstChild("Held") then
		return
	end
	local model = build(kind, key)
	if not model then
		return
	end
	Builder.scale(model, scale)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		end
	end
	local _, size = model:GetBoundingBox()
	model:PivotTo(handle.CFrame * CFrame.new(0, -size.Y / 2, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = handle, model.PrimaryPart :: BasePart
	weld.Parent = handle
	model.Name = "Held"
	model.Parent = tool
end

local function makeTool(kind: "Egg" | "Pet", uid: string, entry: { [string]: any }): Tool
	local config = petsById[entry.petId]
	local key = if config then config.model else tostring(entry.petId)
	local tool = Instance.new("Tool")
	tool.Name = if kind == "Egg" then displayName(entry) .. " Egg" else displayName(entry)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = if kind == "Egg"
		then "Hold it, walk to your pen and place it"
		else "Hold it and place it in your pen"
	tool:SetAttribute(if kind == "Egg" then "EggUid" else "PetUid", uid)
	tool:SetAttribute("ModelKey", key)
	tool:SetAttribute("Rarity", if config then config.rarity else "Common")
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Transparency = 1
	handle.CanCollide, handle.CanQuery, handle.CanTouch, handle.Massless = false, false, false, true
	handle.Parent = tool
	tool.Grip = CFrame.new(0, -0.6, 1.4) * CFrame.Angles(math.rad(-90), 0, 0) -- in both hands, in front
	tool.Equipped:Connect(function()
		holdModel(tool, kind, key, if kind == "Egg" then 0.55 else 0.45)
	end)
	tool.Unequipped:Connect(function()
		local held = tool:FindFirstChild("Held")
		if held then
			held:Destroy()
		end
	end)
	return tool
end

-- Makes the player's Backpack (+ hand) hold exactly one tool per inventory egg and stored pet.
function PlotService.syncTools(player: Player)
	local data = DataService:Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	local want: { [string]: { kind: "Egg" | "Pet", uid: string, entry: { [string]: any } } } = {}
	local order: { string } = {}
	for _, egg in data.eggs do
		if typeof(egg) == "table" and typeof(egg.uid) == "string" then
			want["Egg:" .. egg.uid] = { kind = "Egg", uid = egg.uid, entry = egg }
			table.insert(order, "Egg:" .. egg.uid)
		end
	end
	for uid, pet in data.pets do
		if typeof(pet) == "table" and not pet.placed then
			want["Pet:" .. uid] = { kind = "Pet", uid = uid, entry = pet }
			table.insert(order, "Pet:" .. uid)
		end
	end
	local have: { [string]: Tool } = {}
	local holders: { Instance } = { backpack }
	if player.Character then
		table.insert(holders, player.Character)
	end
	for _, holder in holders do
		for _, child in holder:GetChildren() do
			if child:IsA("Tool") then
				local egg, pet = child:GetAttribute("EggUid"), child:GetAttribute("PetUid")
				local key = if typeof(egg) == "string"
					then "Egg:" .. egg
					elseif typeof(pet) == "string" then "Pet:" .. pet
					else nil
				if key then
					if want[key] and not have[key] then
						have[key] = child
					else
						child:Destroy() -- placed, sold, traded away, or a duplicate
					end
				end
			end
		end
	end
	for _, key in order do
		if not have[key] then
			local item = want[key]
			makeTool(item.kind, item.uid, item.entry).Parent = backpack
		end
	end
end

local function heldTool(player: Player, attribute: string): string?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local uid = tool and tool:GetAttribute(attribute)
	return if typeof(uid) == "string" then uid else nil
end

-- The inventory egg the player holds (nil if none).
function PlotService.heldEgg(player: Player): string?
	return heldTool(player, "EggUid")
end

-- The stored pet the player holds (nil if none).
function PlotService.heldPet(player: Player): string?
	return heldTool(player, "PetUid")
end

-- Puts inventory egg `eggUid` in the player's hands (its Backpack tool), or with nil puts what they hold away.
function PlotService:EquipEgg(player: Player, eggUid: string?): boolean
	local data = DataService:Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not character or not humanoid or humanoid.Health <= 0 then
		return false
	end
	if eggUid == nil then
		humanoid:UnequipTools()
		return true
	end
	if not eggIndex(data, eggUid) then
		return false
	end
	if PlotService.heldEgg(player) == eggUid then
		return true
	end
	PlotService.syncTools(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tools: { Instance } = if backpack then backpack:GetChildren() else {}
	for _, tool in tools do
		if tool:IsA("Tool") and tool:GetAttribute("EggUid") == eggUid then
			humanoid:EquipTool(tool)
			return true
		end
	end
	return false
end

-- Placement ---------------------------------------------------------------------------------------------------

-- Why a placement of an egg at `world` is invalid (nil = valid). Pure checks shared with the tests.
function PlotService.eggSpotProblem(area: BasePart, data: DataService.Data, world: Vector3): string?
	local x, z, inside = PlotService.toLocal(area, world)
	if not inside then
		return "outside your pen"
	end
	for _, egg: EggPlot in data.plots do
		if (Vector2.new(egg.x, egg.z) - Vector2.new(x, z)).Magnitude < EGG_SPACING then
			return "too close to another egg"
		end
	end
	if not hasRoom(data) then
		return "your pen is full"
	end
	return nil
end

local function placeEgg(player: Player, eggUid: string, world: Vector3): boolean
	local data = DataService:Get(player)
	local base = baseOf[player]
	local area = base and penArea(base)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not base or not area or not hrp or not hrp:IsA("BasePart") then
		return false
	end
	local index = eggIndex(data, eggUid)
	if not index or data.plots[eggUid] then
		return false -- not yours, or already placed (a repeated request)
	end
	if PlotService.heldEgg(player) ~= eggUid then
		return false -- you place the egg you are carrying
	end
	if (world - hrp.Position).Magnitude > PLACE_REACH then
		return false
	end
	local problem = PlotService.eggSpotProblem(area, data, world)
	if problem then
		announce:FireClient(player, `Can't place the egg here: {problem}`, "Common")
		return false
	end
	local x, z = PlotService.toLocal(area, world)
	local egg = data.eggs[index]
	local eggs = table.clone(data.eggs)
	table.remove(eggs, index)
	local config = petsById[egg.petId]
	local now = workspace:GetServerTimeNow()
	local plot: EggPlot = {
		uid = egg.uid,
		petId = egg.petId,
		size = egg.size,
		weather = egg.weather,
		placedAt = now,
		hatchAt = now + (if config then config.hatchSeconds else 10),
		x = x,
		z = z,
	}
	local plots = table.clone(data.plots)
	plots[egg.uid] = plot
	DataService:Set(player, { eggs = eggs, plots = plots }) -- (its Backpack tool goes with it: syncTools)
	Analytics.funnel(player, Analytics.Funnel.FirstPlace, "FirstPlace")
	spawnEggModel(player, base, plot)
	return true
end

-- Places stored pet `petUid` at `world` (nil = a free spot) in the player's pen.
function PlotService:PlacePet(player: Player, petUid: string, world: Vector3?): boolean
	local data = DataService:Get(player)
	local base = baseOf[player]
	local area = base and penArea(base)
	local pet: PetEntry? = data and data.pets[petUid]
	if not data or not base or not area or not pet or pet.placed or not hasRoom(data) then
		return false
	end
	local x, z
	if world then
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if PlotService.heldPet(player) ~= petUid or not hrp or not hrp:IsA("BasePart") then
			return false -- a chosen spot: you place the pet you are holding
		end
		if (world - hrp.Position).Magnitude > PLACE_REACH then
			return false
		end
		local lx, lz, inside = PlotService.toLocal(area, world)
		if not inside then
			return false
		end
		x, z = lx, lz
	else
		local hx, hz = PlotService.penHalf(area)
		local spot = PlotService.pickSpot(hx, hz, occupied(player, data, nil, workspace:GetServerTimeNow()), nil)
		x, z = spot.X, spot.Z
	end
	local pets = table.clone(data.pets)
	local placed = table.clone(pet)
	placed.placed, placed.x, placed.z = true, x, z
	pets[petUid] = placed
	DataService:Set(player, { pets = pets })
	local model = spawnPetModel(player, base, petUid, placed, nil)
	if model then
		model:SetAttribute("PlacedAt", workspace:GetServerTimeNow()) -- clients: the placement knock (not a rebuild)
	end
	return true
end

-- Stores placed pet `petUid` (owner only, standing near it): the model leaves the pen and its income stops.
function PlotService:PickupPet(player: Player, petUid: string): boolean
	local data = DataService:Get(player)
	local base = baseOf[player]
	local area = base and penArea(base)
	local pet: PetEntry? = data and data.pets[petUid]
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not base or not area or not pet or not pet.placed or not hrp or not hrp:IsA("BasePart") then
		return false
	end
	local r = roams[player] and roams[player][petUid]
	local now = workspace:GetServerTimeNow()
	local here = if r then roamPos(r, now) else Vector3.new(pet.x or 0, 0, pet.z or 0)
	local world = PlotService.toWorld(area, here.X, here.Z)
	if (world - hrp.Position).Magnitude > PICKUP_REACH then
		return false
	end
	local pets = table.clone(data.pets)
	local stored = table.clone(pet)
	stored.placed, stored.x, stored.z = nil, here.X, here.Z
	pets[petUid] = stored
	DataService:Set(player, { pets = pets })
	if roams[player] then
		roams[player][petUid] = nil
	end
	removeModel(base, "PetUid", petUid)
	return true
end

-- A pet left the player's data (sold, traded away): remove its model.
function PlotService:ForgetPet(player: Player, petUid: string)
	local base = baseOf[player]
	if roams[player] then
		roams[player][petUid] = nil
	end
	if base then
		removeModel(base, "PetUid", petUid)
	end
end

-- Hatching ----------------------------------------------------------------------------------------------------

local function hatchDue(player: Player, now: number)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local due: { string } = {}
	for uid, egg: EggPlot in data.plots do
		if now >= egg.hatchAt then
			table.insert(due, uid)
		end
	end
	if #due == 0 then
		return
	end
	-- 1. the server creates the owned pets (unique ids) and saves them in one change
	local plots = table.clone(data.plots)
	local pets = table.clone(data.pets)
	local discovered = table.clone(data.discovered)
	local hatched: { { eggUid: string, petUid: string } } = {}
	for _, uid in due do
		local egg: EggPlot = plots[uid]
		plots[uid] = nil
		local petUid = HttpService:GenerateGUID(false)
		pets[petUid] =
			{ petId = egg.petId, size = egg.size, weather = egg.weather, placed = true, x = egg.x, z = egg.z }
		discovered[egg.petId] = true -- the Pet Index reveals a pet once you have hatched it
		table.insert(hatched, { eggUid = uid, petUid = petUid })
	end
	DataService:Set(player, { plots = plots, pets = pets, discovered = discovered })
	-- 2. then its model (a failed model is retried; the pet is already saved)
	local base = baseOf[player]
	local area = base and penArea(base)
	for _, info in hatched do
		if base then
			removeModel(base, "EggUid", info.eggUid)
			spawnPetModel(player, base, info.petUid, pets[info.petUid], now)
		end
		local pet = pets[info.petUid]
		eggHatched:FireAllClients({
			eggUid = info.eggUid,
			petUid = info.petUid,
			position = if area then PlotService.toWorld(area, pet.x or 0, pet.z or 0) else Vector3.zero,
		})
		Analytics.custom(player, "EggHatched", 1, pet.petId)
	end
	Analytics.funnel(player, Analytics.Funnel.FirstHatch, "FirstHatch")
end

-- Bases -------------------------------------------------------------------------------------------------------

local function spawnAtBase(player: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local cf = PlotService:GetBaseCFrame(player)
	if hrp and cf then
		task.defer(function()
			character:PivotTo(cf)
		end)
	end
end

local function freeBase(): (Model?, number)
	local bases = basesFolder()
	if not bases then
		return nil, 0
	end
	local taken: { [Model]: boolean } = {}
	for _, base in baseOf do
		taken[base] = true
	end
	local free: Model? = nil
	local bestIndex = math.huge
	for _, child in bases:GetChildren() do
		local index = child:GetAttribute("BaseIndex")
		if child:IsA("Model") and not taken[child] and typeof(index) == "number" and index < bestIndex then
			free, bestIndex = child, index
		end
	end
	return free, bestIndex
end

local function assignBase(player: Player)
	if baseOf[player] or not player.Parent then
		return
	end
	local free, index = freeBase()
	if not free then
		if not table.find(waiting, player) then
			table.insert(waiting, player)
		end
		player:SetAttribute("PenWaiting", true)
		announce:FireClient(player, "All pens are taken: you'll get one as soon as a player leaves.", "Rare")
		warn(`[PlotService] no free pen for {player.Name}; waiting`)
		return
	end
	baseOf[player] = free
	player:SetAttribute("PenWaiting", nil)
	player:SetAttribute("BaseIndex", index)
	PlotService:MirrorBase(player)
	pcall(hatchDue, player, workspace:GetServerTimeNow()) -- eggs that finished while offline
	rebuildModels(player)
	if player.Character then
		spawnAtBase(player, player.Character)
	end
end

local function releaseBase(player: Player)
	local base = baseOf[player]
	if base then
		plotsFolder(base):ClearAllChildren()
		base:SetAttribute("OwnerUserId", 0)
		base:SetAttribute("RackLevel", 1)
		base:SetAttribute("PenLevel", 1)
	end
	baseOf[player] = nil
	roams[player] = nil
	retryAt[player] = nil
	carry[player] = nil
	local i = table.find(waiting, player)
	if i then
		table.remove(waiting, i)
	end
	-- the next waiting player gets the freed pen
	while #waiting > 0 do
		local nextPlayer = table.remove(waiting, 1) :: Player
		if nextPlayer.Parent then
			task.spawn(assignBase, nextPlayer)
			break
		end
	end
end

-- Public API --------------------------------------------------------------------------------------------------

-- Mirrors owner and upgrade levels on Base<i> for every client (owner display, pen level):
-- OwnerUserId, RackLevel, PenLevel.
function PlotService:MirrorBase(player: Player)
	local base = baseOf[player]
	local data = DataService:Get(player)
	if base and data then
		base:SetAttribute("OwnerUserId", player.UserId)
		base:SetAttribute("RackLevel", data.rackLevel or 1)
		base:SetAttribute("PenLevel", data.penLevel or 1)
	end
end

function PlotService:GetBase(player: Player): Model?
	return baseOf[player]
end

-- Where the player (re)spawns: their base's SpawnPoint (ChaseService uses this after "Caught").
function PlotService:GetBaseCFrame(player: Player): CFrame?
	local base = baseOf[player]
	local spawnPoint = base and base:FindFirstChild("SpawnPoint")
	if spawnPoint and spawnPoint:IsA("BasePart") then
		return spawnPoint.CFrame + Vector3.new(0, SPAWN_ABOVE, 0)
	end
	return nil
end

-- Recomputes pet income labels (after a rebirth, a gamepass purchase or an Index bonus).
function PlotService:Refresh(player: Player)
	rebuildModels(player)
end

-- (Pedestal-era API, kept so older callers keep working: eggs wait in the inventory, pets are placed by hand.)
function PlotService:PlaceWaitingEggs(_player: Player) end
function PlotService:PlaceUnplacedPets(player: Player)
	rebuildModels(player)
end

function PlotService:Init()
	eggHatched = Remotes.get("EggHatched")
	announce = Remotes.get("Announce")
end

function PlotService:Start()
	Remotes.get("PlaceEgg").OnServerEvent:Connect(function(player: Player, eggUid: any, position: any)
		if limiter:allow(player) and typeof(eggUid) == "string" and typeof(position) == "Vector3" then
			placeEgg(player, eggUid, position)
		end
	end)
	Remotes.get("EquipEgg").OnServerEvent:Connect(function(player: Player, eggUid: any)
		if limiter:allow(player) and (eggUid == nil or typeof(eggUid) == "string") then
			PlotService:EquipEgg(player, eggUid)
		end
	end)
	Remotes.get("PickupPet").OnServerEvent:Connect(function(player: Player, petUid: any)
		if limiter:allow(player) and typeof(petUid) == "string" then
			PlotService:PickupPet(player, petUid)
		end
	end)
	Remotes.get("PlacePet").OnServerEvent:Connect(function(player: Player, petUid: any, position: any)
		if
			limiter:allow(player)
			and typeof(petUid) == "string"
			and (position == nil or typeof(position) == "Vector3")
		then
			PlotService:PlacePet(player, petUid, position)
		end
	end)

	local bases = basesFolder()
	if bases then
		for _, base in bases:GetChildren() do
			if base:GetAttribute("OwnerUserId") == nil then
				base:SetAttribute("OwnerUserId", 0) -- 0 = free (Config/Upgrades contract)
				base:SetAttribute("RackLevel", 1)
				base:SetAttribute("PenLevel", 1)
			end
		end
	end

	DataService:OnLoaded(function(player)
		assignBase(player)
		player.CharacterAdded:Connect(function(character)
			spawnAtBase(player, character)
			task.defer(PlotService.syncTools, player) -- a new Backpack every life
		end)
		if player.Character then
			task.defer(PlotService.syncTools, player)
		end
	end)
	DataService:OnChanged(function(player, partial)
		if partial.eggs ~= nil or partial.pets ~= nil then
			PlotService.syncTools(player)
		end
	end)
	Players.PlayerRemoving:Connect(releaseBase)

	-- One loop for everyone; each player's work is protected so one bad save or model never stops the rest.
	task.spawn(function()
		while true do
			task.wait(TICK)
			local now = workspace:GetServerTimeNow()
			for player in baseOf do
				local ok, err = pcall(function()
					hatchDue(player, now)
					payIncome(player)
					retryModels(player)
				end)
				if not ok then
					warn(`[PlotService] tick failed for {player.Name}: {err}`)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(ROAM_TICK)
			xpcall(roamTick, function(err)
				warn(`[PlotService] roam tick failed: {err}`)
			end, workspace:GetServerTimeNow())
		end
	end)
end

return PlotService
