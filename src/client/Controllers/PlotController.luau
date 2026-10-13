--!strict
-- Brings every pen to life on this client (PlotService models in Base<i>.Plots):
--   * Eggs wobble and crack toward HatchAt and wear their own idle effect (VFX/PetFx).
--   * Pets WALK their pen: the server picks each move (attributes PathFrom / PathTo / PathStart / PathEnd, server
--     time); ONE RenderStepped here moves every pet along its path (one CFrame write on the anchored root: the
--     rig follows), faces it where it walks, and switches Waddle (walking) / Idle (standing, with the odd hop).
--     Level of detail (VFX/SackLod bands + view test): near and on screen = every frame with pose animation;
--     further out every few frames without it; far away / off screen = not moved until it matters again.
--   * Freshly hatched pets burst + reveal; weather mutations wear their overlay.
--   * Your own pets get a "Pick Up" prompt (local; PickupPet, the server checks ownership and distance).
--   * A small "+$" pops over your pen every few seconds while your pets earn (money goes straight in).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)
local VFX = require(Shared.VFX)
local Audio = require(Shared.Audio)
local PetFx = require(Shared.VFX.PetFx)
local SackLod = require(Shared.VFX.SackLod)
local Anim = require(Shared.Anim)
local Remotes = require(Shared.Remotes)

local CRACK_STEPS = 10 -- HatchCrack fires each time progress crosses a tenth
local REVEAL_WINDOW = 5 -- seconds after HatchedAt during which a new pet plays its reveal
local ANIM_RANGE = 90 -- studs: pose animations (waddle / idle) only this close and on screen
local MOVE_RANGE = 220 -- studs: beyond this pets aren't moved (they jump to their spot when you come back)
local FAR_STRIDE = 4 -- frames between moves for pets past ANIM_RANGE
local POP_EVERY = 3 -- seconds between income pops over your pen

local PlotController = {}

type PetView = {
	model: Model,
	root: BasePart,
	from: Vector3,
	to: Vector3,
	t0: number,
	t1: number,
	facing: CFrame, -- rotation only
	anim: (() -> ())?,
	animKind: string?,
	index: number,
	own: boolean,
	prompt: ProximityPrompt?,
	stops: { () -> () },
}

local player = Players.LocalPlayer
local tracked: { [Model]: { () -> () } } = {}
local pets: { [Model]: PetView } = {}
local petCount = 0
local frameNo = 0

local function untrack(model: Model)
	local view = pets[model]
	if view then
		pets[model] = nil
		if view.anim then
			view.anim()
		end
		for _, stop in view.stops do
			stop()
		end
		if view.prompt then
			view.prompt:Destroy()
		end
	end
	local stops = tracked[model]
	if stops then
		tracked[model] = nil
		for _, stop in stops do
			stop()
		end
	end
end

-- The model's own idle effect, if its pair has a recipe yet (docs/EggPetPlan.md).
local function petFx(model: Model, kind: string, stops: { () -> () })
	local key = model:GetAttribute("ModelKey")
	local handle = if typeof(key) == "string" then PetFx.attach(model, kind, key) else nil
	if handle then
		table.insert(stops, handle.Destroy)
	end
end

local function fresh(model: Model, attribute: string): boolean
	local at = model:GetAttribute(attribute)
	return typeof(at) == "number" and workspace:GetServerTimeNow() - at < 2
end

local function trackEgg(egg: Model)
	if egg:GetAttribute("OwnerUserId") == player.UserId and fresh(egg, "PlacedAt") then
		Audio.play("EggPlace", egg) -- you just put it down
	end
	local stops = { Anim.play(egg, "EggWobble") }
	petFx(egg, "egg", stops)
	tracked[egg] = stops
	local lastStep = -1
	local connection = RunService.Heartbeat:Connect(function()
		local placedAt = egg:GetAttribute("PlacedAt")
		local hatchAt = egg:GetAttribute("HatchAt")
		if typeof(placedAt) ~= "number" or typeof(hatchAt) ~= "number" or hatchAt <= placedAt then
			return
		end
		local progress = math.clamp((workspace:GetServerTimeNow() - placedAt) / (hatchAt - placedAt), 0, 1)
		local step = math.floor(progress * CRACK_STEPS)
		if step ~= lastStep then
			lastStep = step
			VFX.play("HatchCrack", egg, { progress = progress })
		end
	end)
	table.insert(stops, function()
		connection:Disconnect()
	end)
end

-- Reads the server's path attributes into the view.
local function readPath(view: PetView)
	local m = view.model
	local from, to = m:GetAttribute("PathFrom"), m:GetAttribute("PathTo")
	local t0, t1 = m:GetAttribute("PathStart"), m:GetAttribute("PathEnd")
	if typeof(from) == "Vector3" and typeof(to) == "Vector3" and typeof(t0) == "number" and typeof(t1) == "number" then
		view.from, view.to, view.t0, view.t1 = from, to, t0, t1
		local dir = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
		if dir.Magnitude > 0.05 then
			view.facing = CFrame.lookAt(Vector3.zero, dir)
		end
	end
end

local function pickupPrompt(view: PetView)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PickUpPet"
	prompt.ActionText = "Pick Up"
	local name = view.model:GetAttribute("PetName")
	prompt.ObjectText = if typeof(name) == "string" then name else "Pet"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.UIOffset = Vector2.new(0, 30)
	prompt.Triggered:Connect(function()
		local uid = view.model:GetAttribute("PetUid")
		if typeof(uid) == "string" then
			Audio.play("PetPickup", view.root)
			Remotes.get("PickupPet"):FireServer(uid)
		end
	end)
	prompt.Parent = view.root
	view.prompt = prompt
end

local function trackPet(pet: Model)
	local root = pet.PrimaryPart
	if not root then
		return
	end
	local rarity = pet:GetAttribute("Rarity")
	local hatchedAt = pet:GetAttribute("HatchedAt")
	if typeof(hatchedAt) == "number" and workspace:GetServerTimeNow() - hatchedAt < REVEAL_WINDOW then
		VFX.play("HatchBurst", pet, { rarity = rarity })
		VFX.play("PetReveal", pet, { rarity = rarity, name = pet:GetAttribute("PetName") })
	elseif fresh(pet, "PlacedAt") then
		Audio.play("PetPlace", pet, { own = if pet:GetAttribute("OwnerUserId") == player.UserId then nil else false })
	end
	petCount += 1
	local view: PetView = {
		model = pet,
		root = root,
		from = root.Position,
		to = root.Position,
		t0 = 0,
		t1 = 0,
		facing = root.CFrame.Rotation,
		anim = nil,
		animKind = nil,
		index = petCount,
		own = pet:GetAttribute("OwnerUserId") == player.UserId,
		prompt = nil,
		stops = {},
	}
	petFx(pet, "pet", view.stops)
	local weather = pet:GetAttribute("Weather")
	local mutation = if typeof(weather) == "string" then Mutations.Weather[weather] else nil
	if mutation then
		table.insert(view.stops, VFX.attach(mutation.vfx, pet))
	end
	readPath(view)
	local conn = pet.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, 4) == "Path" then
			readPath(view)
		end
	end)
	table.insert(view.stops, function()
		conn:Disconnect()
	end)
	if view.own then
		pickupPrompt(view)
	end
	pets[pet] = view
end

local function setAnim(view: PetView, kind: string?)
	if view.animKind == kind then
		return
	end
	if view.anim then
		view.anim()
		view.anim = nil
	end
	view.animKind = kind
	if kind then
		view.anim = Anim.play(view.model, kind)
	end
end

-- One frame for every pet: position along its path, facing, and the right animation at the right detail.
local function movePets()
	frameNo += 1
	local now = workspace:GetServerTimeNow()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local camCF = cam.CFrame
	local tanY = math.tan(math.rad(cam.FieldOfView) / 2)
	local vp = cam.ViewportSize
	local aspect = if vp.Y > 0 then vp.X / vp.Y else 16 / 9
	for model, view in pets do
		if not model.Parent then
			continue
		end
		local target = if now >= view.t1 or view.t1 <= view.t0
			then view.to
			else view.from:Lerp(view.to, (now - view.t0) / (view.t1 - view.t0))
		local d = (target - camCF.Position).Magnitude
		if d > MOVE_RANGE then
			setAnim(view, nil)
			continue
		end
		local visible = d < SackLod.CULL_MIN or SackLod.inView(camCF, tanY, aspect, target, 6)
		local near = visible and d < ANIM_RANGE
		if not near and (frameNo + view.index) % FAR_STRIDE ~= 0 then
			continue
		end
		local walking = now < view.t1 and view.t1 > view.t0
		view.root.CFrame = CFrame.new(target) * view.facing
		setAnim(view, if not near then nil elseif walking then "Waddle" else "Idle")
	end
end

local function onPlotChild(child: Instance)
	if not child:IsA("Model") or tracked[child] or pets[child] then
		return
	end
	local kind = child:GetAttribute("Kind")
	if kind == "Egg" then
		trackEgg(child)
	elseif kind == "Pet" then
		trackPet(child)
	else
		return
	end
	child.AncestryChanged:Connect(function()
		if not child:IsDescendantOf(workspace) then
			untrack(child)
		end
	end)
end

local function watchPlots(plots: Instance)
	for _, child in plots:GetChildren() do
		task.spawn(onPlotChild, child)
	end
	plots.ChildAdded:Connect(function(child)
		-- Attributes replicate with the model; defer so children are in place too.
		task.defer(onPlotChild, child)
	end)
end

local function watchBases()
	local map = workspace:WaitForChild("Map", 60)
	local safeZone = map and map:WaitForChild("SafeZone", 30)
	local bases = safeZone and safeZone:WaitForChild("Bases", 30)
	if not bases then
		return
	end
	local function watchBase(base: Instance)
		task.spawn(function()
			local plots = base:WaitForChild("Plots", math.huge)
			if plots then
				watchPlots(plots)
			end
		end)
	end
	for _, base in bases:GetChildren() do
		watchBase(base)
	end
	bases.ChildAdded:Connect(watchBase)
end

local function myBase(): Instance?
	local index = player:GetAttribute("BaseIndex")
	local map = workspace:FindFirstChild("Map")
	local safeZone = map and map:FindFirstChild("SafeZone")
	local bases = safeZone and safeZone:FindFirstChild("Bases")
	return if bases and typeof(index) == "number" then bases:FindFirstChild(`Base{index}`) else nil
end

function PlotController:Start()
	-- income pops: money from placed pets arrives every second; show it every few seconds near your pen
	local lastMoney: number? = nil
	local pending, lastPop = 0, 0
	Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
		if typeof(partial.money) ~= "number" then
			return
		end
		if lastMoney and partial.money > lastMoney then
			pending += partial.money - lastMoney
		end
		lastMoney = partial.money
		local now = os.clock()
		local base = myBase()
		local area = base and base:FindFirstChild("PenArea")
		local cam = workspace.CurrentCamera
		if pending > 0 and now - lastPop >= POP_EVERY and area and area:IsA("BasePart") and cam then
			if (area.Position - cam.CFrame.Position).Magnitude < 140 then
				VFX.play("MoneyPop", area, { amount = math.floor(pending) })
			end
			pending, lastPop = 0, now
		end
	end)

	task.spawn(watchBases)
	RunService.RenderStepped:Connect(movePets)
end

return PlotController
