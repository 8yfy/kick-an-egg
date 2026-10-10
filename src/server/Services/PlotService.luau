--!strict
-- Bases and pedestals. Assigns a base on join (spawn there, owner sign), PlaceEgg onto a free
-- pedestal, hatches on a server-time timer that survives rejoin, spawns pets (size via
-- Builder.scale). Every second each placed pet STORES its income on its pedestal; the owner
-- collects it by stepping onto that pedestal (Economy.CollectRadius).
--
-- Data: plots = { [slot]: {uid, petId, size?, weather?, placedAt, hatchAt} } -- eggs hatching
--       pets  = { [petUid]: {petId, size?, weather?, slot?, stored?} }         -- hatched pets
--       (`stored` is updated in place every tick without DataChanged; the model attribute shows it)
-- Replicated models live in Base<i>.Plots with attributes for PlotController (client VFX/Anim):
--   egg: Kind="Egg", Slot, PlacedAt, HatchAt, Rarity      pet: Kind="Pet", Slot, PetUid, Rarity,
--   PetName, Size, Weather, Income ($/s with multipliers), Stored ($ waiting), HatchedAt

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
}

type PetEntry = {
	petId: string,
	size: string?,
	weather: string?,
	slot: number?,
	stored: number?, -- income waiting on the pedestal
}

local INCOME_TICK = 1
local COLLECT_TICK = 0.2
local COLLECT_HEIGHT = 7 -- HumanoidRootPart up to this far above the pedestal top
local SPAWN_ABOVE = 3
local SIT_ABOVE = 0.15 -- MapBuilder: egg sits at Top.Position + up * 0.15
local EMPTY_SIGN = "Empty Base"

local PlotService = {}

local petsById: { [string]: Pets.Pet } = {}
for _, pet in Pets do
	petsById[pet.id] = pet
end

local limiter = RateLimiter.new()
local baseOf: { [Player]: Model } = {}
local eggHatched: RemoteEvent

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

local function setSign(base: Model, text: string)
	local label = base:FindFirstChild("OwnerLabel", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function pedestalTop(base: Model, slot: number): BasePart?
	local pedestals = base:FindFirstChild("Pedestals")
	local pedestal = pedestals and pedestals:FindFirstChild(`Pedestal{slot}`)
	local top = pedestal and pedestal:FindFirstChild("Top")
	return if top and top:IsA("BasePart") then top else nil
end

-- Pedestal slots from the pen level (Config/Upgrades.Pen): base at level 1, +slotsPerLevel per level.
function PlotService.slotsForPen(penLevel: number): number
	local slots = Economy.PlotSlots.base + (penLevel - 1) * Upgrades.Pen.slotsPerLevel
	return math.clamp(slots, 1, Economy.PlotSlots.max)
end

local function slotCount(data: DataService.Data): number
	return PlotService.slotsForPen(data.penLevel or 1)
end

local function slotTaken(data: DataService.Data, slot: number): boolean
	if data.plots[tostring(slot)] then
		return true
	end
	for _, pet: PetEntry in data.pets do
		if pet.slot == slot then
			return true
		end
	end
	return false
end

local function rebirthMultiplier(data: DataService.Data): number
	return 1 + data.rebirths * Economy.Rebirth.multiplierPerRebirth
end

-- Optional MonetizationService (B8) exposes :GetIncomeMultiplier(player) -> number.
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
end

-- Models ---------------------------------------------------------------------

local function placeModel(base: Model, slot: number, model: Model)
	local top = pedestalTop(base, slot)
	if top then
		local cf = top.CFrame * CFrame.new(0, top.Size.Y / 2 + SIT_ABOVE, 0)
		model:PivotTo(cf)
	end
	model.Parent = plotsFolder(base)
end

local function clearSlot(base: Model, slot: number)
	for _, child in plotsFolder(base):GetChildren() do
		if child:GetAttribute("Slot") == slot then
			child:Destroy()
		end
	end
end

local function spawnEggModel(base: Model, slot: number, egg: EggPlot)
	clearSlot(base, slot)
	local config = petsById[egg.petId]
	local model = Models.egg(if config then config.model else egg.petId)
	model.Name = `Egg{slot}`
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- streams in whole, never half-built
	model:SetAttribute("Kind", "Egg")
	model:SetAttribute("Slot", slot)
	model:SetAttribute("PlacedAt", egg.placedAt)
	model:SetAttribute("HatchAt", egg.hatchAt)
	model:SetAttribute("Rarity", if config then config.rarity else "Common")
	placeModel(base, slot, model)
end

local function spawnPetModel(player: Player, base: Model, petUid: string, pet: PetEntry, hatchedAt: number?)
	local slot = pet.slot :: number
	clearSlot(base, slot)
	local config = petsById[pet.petId]
	local model = Models.pet(if config then config.model else pet.petId)
	model.Name = `Pet{slot}`
	local size = if pet.size then Mutations.Size[pet.size] else nil
	if size then
		Builder.scale(model, size.scale)
	end
	local data = DataService:Get(player)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Kind", "Pet")
	model:SetAttribute("Slot", slot)
	model:SetAttribute("PetUid", petUid)
	model:SetAttribute("PetName", if config then config.name else pet.petId)
	model:SetAttribute("Rarity", if config then config.rarity else "Common")
	model:SetAttribute("Size", pet.size)
	model:SetAttribute("Weather", pet.weather)
	model:SetAttribute("Income", if data then PlotService.petIncome(pet, data, gamepassMultiplier(player)) else 0)
	model:SetAttribute("Stored", math.floor(pet.stored or 0))
	model:SetAttribute("HatchedAt", hatchedAt)
	placeModel(base, slot, model)
end

local function rebuildModels(player: Player)
	local base = baseOf[player]
	local data = DataService:Get(player)
	if not base or not data then
		return
	end
	plotsFolder(base):ClearAllChildren()
	for key, egg: EggPlot in data.plots do
		spawnEggModel(base, tonumber(key) :: number, egg)
	end
	for petUid, pet: PetEntry in data.pets do
		if pet.slot then
			spawnPetModel(player, base, petUid, pet, nil)
		end
	end
end

-- Hatching & income ----------------------------------------------------------

local function hatchDue(player: Player, now: number)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local due: { string } = {}
	for key, egg: EggPlot in data.plots do
		if now >= egg.hatchAt then
			table.insert(due, key)
		end
	end
	if #due == 0 then
		return
	end
	local plots = table.clone(data.plots)
	local pets = table.clone(data.pets)
	local hatched: { { eggUid: string, slot: number, petUid: string } } = {}
	for _, key in due do
		local egg: EggPlot = plots[key]
		plots[key] = nil
		local petUid = HttpService:GenerateGUID(false)
		local slot = tonumber(key) :: number
		pets[petUid] = { petId = egg.petId, size = egg.size, weather = egg.weather, slot = slot }
		table.insert(hatched, { eggUid = egg.uid, slot = slot, petUid = petUid })
	end
	DataService:Set(player, { plots = plots, pets = pets })

	local base = baseOf[player]
	for _, info in hatched do
		if base then
			spawnPetModel(player, base, info.petUid, pets[info.petUid], now)
		end
		eggHatched:FireAllClients(info)
		Analytics.custom(player, "EggHatched", 1, pets[info.petUid].petId)
	end
	Analytics.funnel(player, Analytics.Funnel.FirstHatch, "FirstHatch")
end

local function petModel(base: Model, petUid: string): Model?
	for _, child in plotsFolder(base):GetChildren() do
		if child:IsA("Model") and child:GetAttribute("PetUid") == petUid then
			return child
		end
	end
	return nil
end

-- Each placed pet stores its income on its pedestal (no DataChanged; the model shows it).
local function accrueIncome(player: Player)
	local data = DataService:Get(player)
	local base = baseOf[player]
	if not data or not base then
		return
	end
	local gamepass = gamepassMultiplier(player)
	for petUid, pet: PetEntry in data.pets do
		if pet.slot then
			pet.stored = (pet.stored or 0) + PlotService.petIncome(pet, data, gamepass)
			local model = petModel(base, petUid)
			if model then
				model:SetAttribute("Stored", math.floor(pet.stored :: number))
			end
		end
	end
end

-- True if `position` (HumanoidRootPart) stands on the pedestal whose top is `top`.
function PlotService.onPedestal(top: BasePart, position: Vector3): boolean
	local offset = position - top.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= Economy.CollectRadius
		and offset.Y >= 0
		and offset.Y <= COLLECT_HEIGHT
end

-- Pays out every pedestal the owner is standing on.
local function collect(player: Player)
	local data = DataService:Get(player)
	local base = baseOf[player]
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not base or not hrp or not hrp:IsA("BasePart") then
		return
	end
	local total = 0
	for petUid, pet: PetEntry in data.pets do
		local amount = math.floor(pet.stored or 0)
		local top = if pet.slot and amount > 0 then pedestalTop(base, pet.slot) else nil
		if top and PlotService.onPedestal(top, hrp.Position) then
			pet.stored = (pet.stored :: number) - amount
			total += amount
			local model = petModel(base, petUid)
			if model then
				model:SetAttribute("Stored", 0)
			end
		end
	end
	if total > 0 then
		DataService:Set(player, { money = data.money + total })
		Analytics.addIncome(player, total)
	end
end

-- Bases ----------------------------------------------------------------------

local function spawnAtBase(player: Player, character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local cf = PlotService:GetBaseCFrame(player)
	if hrp and cf then
		task.defer(function()
			character:PivotTo(cf)
		end)
	end
end

local function assignBase(player: Player)
	local bases = basesFolder()
	if not bases then
		warn("[PlotService] workspace.Map.SafeZone.Bases not found; no base assigned")
		return
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
	if not free then
		warn(`[PlotService] no free base for {player.Name}`)
		return
	end
	baseOf[player] = free
	setSign(free, player.DisplayName)
	player:SetAttribute("BaseIndex", bestIndex)
	PlotService:MirrorBase(player)
	hatchDue(player, workspace:GetServerTimeNow()) -- eggs that finished while offline
	rebuildModels(player)
	if player.Character then
		spawnAtBase(player, player.Character)
	end
end

local function releaseBase(player: Player)
	local base = baseOf[player]
	if base then
		plotsFolder(base):ClearAllChildren()
		setSign(base, EMPTY_SIGN)
		base:SetAttribute("OwnerUserId", 0)
		base:SetAttribute("RackLevel", 1)
		base:SetAttribute("PenLevel", 1)
	end
	baseOf[player] = nil
end

local function onPlaceEgg(player: Player, eggUid: any, slot: any)
	if not limiter:allow(player) or typeof(eggUid) ~= "string" or typeof(slot) ~= "number" then
		return
	end
	local data = DataService:Get(player)
	local base = baseOf[player]
	if not data or not base then
		return
	end
	if slot ~= math.floor(slot) or slot < 1 or slot > slotCount(data) or slotTaken(data, slot) then
		return
	end
	local index: number? = nil
	for i, egg in data.eggs do
		if egg.uid == eggUid then
			index = i
			break
		end
	end
	if not index then
		return -- not this player's egg
	end
	local eggs = table.clone(data.eggs)
	local egg = eggs[index :: number]
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
	}
	local plots = table.clone(data.plots)
	plots[tostring(slot)] = plot
	DataService:Set(player, { eggs = eggs, plots = plots })
	Analytics.funnel(player, Analytics.Funnel.FirstPlace, "FirstPlace")
	spawnEggModel(base, slot, plot)
end

-- Public API -----------------------------------------------------------------

-- Mirrors owner and upgrade levels on Base<i> so every client can draw signs, rack tier and pen
-- slots (Config/Upgrades contract): OwnerUserId, RackLevel, PenLevel.
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

-- Recomputes pet income labels (after a rebirth or a gamepass purchase).
function PlotService:Refresh(player: Player)
	rebuildModels(player)
end

-- Puts pets without a slot (e.g. just received in a trade) on free pedestals, then redraws.
-- Pets that don't fit stay in the inventory (slot = nil) and earn nothing until placed.
function PlotService:PlaceUnplacedPets(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local pets: { [string]: PetEntry } = table.clone(data.pets)
	local changed = false
	for petUid, pet: PetEntry in pets do
		if not pet.slot then
			for slot = 1, slotCount(data) do
				if not slotTaken({ plots = data.plots, pets = pets }, slot) then
					local placed = table.clone(pet)
					placed.slot = slot
					pets[petUid] = placed
					changed = true
					break
				end
			end
		end
	end
	if changed then
		DataService:Set(player, { pets = pets })
	end
	rebuildModels(player)
end

function PlotService:Init()
	eggHatched = Remotes.get("EggHatched")
end

function PlotService:Start()
	Remotes.get("PlaceEgg").OnServerEvent:Connect(onPlaceEgg)

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
		end)
	end)
	Players.PlayerRemoving:Connect(releaseBase)

	task.spawn(function()
		while true do
			task.wait(INCOME_TICK)
			local now = workspace:GetServerTimeNow()
			for player in baseOf do
				hatchDue(player, now)
				accrueIncome(player)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(COLLECT_TICK)
			for player in baseOf do
				collect(player)
			end
		end
	end)
end

return PlotService
