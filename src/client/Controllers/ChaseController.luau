--!strict
-- Draws every chase (own and other players') and lets the owner STEER their egg.
-- The egg is the server's model at workspace.Chases[eggUid]. From controlStart (ChaseStart.eggRunStart)
-- the owner has physics ownership: their movement input (keyboard / thumbstick, camera-relative)
-- sets the egg's LinearVelocity, and the camera follows the egg. The server validates and decides.
-- Egg form: while an egg is steered its kicker's character is hidden on every client (local Transparency, so the
-- body stays in place for game logic; restored at the end of the chase, after a respawn too). The run animation
-- follows the egg's real speed (Anim/Egg.EggRun) and stops when it stands still. At the finish the egg is gone
-- at once (the "SECURED!" burst plays where it crossed) and the avalanche crumbles straight away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VFX = require(Shared.VFX)
local Audio = require(Shared.Audio)
local SoundBank = require(Shared.Audio.SoundBank)
local Anim = require(Shared.Anim)
local Remotes = require(Shared.Remotes)

local FlightController = require(script.Parent.FlightController)

type ChaseStartPayload = {
	eggUid: string,
	ownerUserId: number,
	theme: string,
	startZ: number,
	startTime: number,
	speed: number,
	eggStartPos: Vector3,
	eggRunStart: number, -- control starts here
	eggModel: string?,
	rarity: string?,
}

type ChaseView = {
	payload: ChaseStartPayload,
	isOwn: boolean,
	folder: Folder, -- client-side avalanche VFX
	egg: Model?, -- the server's egg
	steering: boolean,
	stops: { () -> () },
	connection: RBXScriptConnection?,
	contact: SoundBank.ContactState, -- landing / bounce sounds from the egg's vertical velocity (never Touched)
	clock: number,
	stepIn: number, -- seconds to the next footstep sound
}

local EGG_WAIT = 10 -- seconds to wait for the server egg to replicate
local CLEANUP_DELAY = 1.2 -- AvalancheStop crumble time
local BURST_LIFE = 2
local MOVE_DEADZONE = 0.05

local ChaseController = {}

local player = Players.LocalPlayer
local chasesFolder: Folder -- client VFX folders
local views: { [string]: ChaseView } = {}
local controls: any = nil -- PlayerModule ControlModule (move vector from keyboard / thumbstick / gamepad)

local function getControls(): any
	if not controls then
		local ok, playerModule = pcall(function()
			return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
		end)
		if ok and playerModule then
			controls = playerModule:GetControls()
		end
	end
	return controls
end

-- Camera-relative input → flat world direction (length 0..1).
local function steerDirection(): Vector3
	local ctl = getControls()
	if not ctl then
		return Vector3.zero
	end
	local move: Vector3 = ctl:GetMoveVector()
	if move.Magnitude < MOVE_DEADZONE then
		return Vector3.zero
	end
	local cf = workspace.CurrentCamera.CFrame
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
	if look.Magnitude < 1e-3 or right.Magnitude < 1e-3 then
		return Vector3.zero
	end
	local dir = right.Unit * move.X - look.Unit * move.Z
	return if dir.Magnitude > 1 then dir.Unit else dir
end

-- Egg form: hide / show a player's character locally (parts, decals, accessories, name tag, trails).
type Hidden = { saved: { [Instance]: any }, conns: { RBXScriptConnection } }
local hidden: { [number]: Hidden } = {} -- userId -> what was changed
local function hideOne(h: Hidden, d: Instance)
	if h.saved[d] ~= nil then
		return
	end
	if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
		local v = d :: any -- (all three have Transparency)
		h.saved[d] = v.Transparency
		v.Transparency = 1
	elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Light") then
		local v = d :: any -- (all four have Enabled)
		h.saved[d] = v.Enabled
		v.Enabled = false
	elseif d:IsA("Humanoid") then
		h.saved[d] = d.DisplayDistanceType
		d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end
local function showCharacter(userId: number)
	local h = hidden[userId]
	if not h then
		return
	end
	hidden[userId] = nil
	for _, c in h.conns do
		c:Disconnect()
	end
	for d, v in h.saved do
		if d.Parent then
			if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
				(d :: any).Transparency = v
			elseif d:IsA("Humanoid") then
				d.DisplayDistanceType = v
			else
				(d :: any).Enabled = v
			end
		end
	end
end
local function hideCharacter(userId: number)
	showCharacter(userId)
	local owner = Players:GetPlayerByUserId(userId)
	local character = owner and owner.Character
	if not owner or not character then
		return
	end
	local h: Hidden = { saved = {}, conns = {} }
	hidden[userId] = h
	for _, d in character:GetDescendants() do
		hideOne(h, d)
	end
	table.insert(
		h.conns,
		character.DescendantAdded:Connect(function(d)
			hideOne(h, d) -- accessories / tools that load later
		end)
	)
end

local function stopAll(view: ChaseView)
	for _, stop in view.stops do
		stop()
	end
	table.clear(view.stops)
end

local function returnCamera()
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	camera.CameraType = Enum.CameraType.Custom
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function endView(view: ChaseView, delay: number)
	if views[view.payload.eggUid] == view then
		views[view.payload.eggUid] = nil
	end
	showCharacter(view.payload.ownerUserId)
	if view.connection then
		view.connection:Disconnect()
		view.connection = nil
	end
	stopAll(view)
	if view.isOwn and view.steering then
		returnCamera()
	end
	view.steering = false
	local folder = view.folder
	task.delay(delay, function()
		folder:Destroy()
	end)
end

-- Own steering, every frame while in control.
local function steer(egg: Model)
	local hitbox = egg:FindFirstChild("Hitbox")
	local velocity = hitbox and hitbox:FindFirstChild("SteerVelocity")
	local align = hitbox and hitbox:FindFirstChild("SteerAlign")
	if not hitbox or not hitbox:IsA("BasePart") or not velocity or not velocity:IsA("LinearVelocity") then
		return
	end
	local camera = workspace.CurrentCamera
	if camera.CameraSubject ~= hitbox then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = hitbox
	end
	local speed = egg:GetAttribute("Speed")
	local dir = steerDirection()
	local planar = dir * (if typeof(speed) == "number" then speed else 16)
	velocity.PlaneVelocity = Vector2.new(planar.X, planar.Z)
	if align and align:IsA("AlignOrientation") and dir.Magnitude > MOVE_DEADZONE then
		align.CFrame = CFrame.lookAt(Vector3.zero, dir)
	end
end

-- The egg's own sounds: a landing / bounce when a fall stops (SoundBank.contactStep, with a minimum speed and a
-- cooldown, so contacts can't stack), and light footsteps while your legged egg runs on the ground.
local function sounds(view: ChaseView, egg: Model)
	local hitbox = egg:FindFirstChild("Hitbox")
	if not hitbox or not hitbox:IsA("BasePart") then
		return
	end
	local t = os.clock()
	local dt = math.min(t - view.clock, 0.1)
	view.clock = t
	local v = hitbox.AssemblyLinearVelocity
	local kind, speed = SoundBank.contactStep(view.contact, dt, v.Y, t)
	local own = if view.isOwn then nil else false
	if kind then
		Audio.landing(hitbox, speed, kind == "bounce", nil, { key = view.payload.eggUid, own = own })
	end
	local flat = Vector2.new(v.X, v.Z).Magnitude
	if view.isOwn and view.steering and flat > 4 and math.abs(v.Y) < 2 then
		view.stepIn -= dt
		if view.stepIn <= 0 then
			view.stepIn = math.clamp(4.5 / flat, 0.09, 0.3)
			Audio.play("EggStep", hitbox, { follow = true })
		end
	end
end

local function step(view: ChaseView)
	local egg = view.egg
	if not egg or not egg.Parent then
		return
	end
	local now = workspace:GetServerTimeNow()
	if not view.steering and now >= view.payload.eggRunStart then
		view.steering = true
		hideCharacter(view.payload.ownerUserId) -- egg form: the kicker IS the egg now
		table.insert(view.stops, Anim.play(egg, "EggRun")) -- runs only while the egg actually moves
	end
	if view.isOwn and view.steering then
		steer(egg)
	end
	sounds(view, egg)
end

local function attachEgg(view: ChaseView)
	local serverChases = workspace:WaitForChild("Chases", EGG_WAIT)
	local egg = serverChases and serverChases:WaitForChild(view.payload.eggUid, EGG_WAIT)
	if not egg or not egg:IsA("Model") or views[view.payload.eggUid] ~= view then
		return
	end
	view.egg = egg
	if view.isOwn then
		-- Swap FlightController's local landed egg for the real one (wait if it is still landing).
		local uid = view.payload.eggUid
		local landed = FlightController:TakeEgg(uid)
		local deadline = os.clock() + 1.5
		while not landed and FlightController:GetEgg(uid) and os.clock() < deadline do
			task.wait(0.05)
			landed = FlightController:TakeEgg(uid)
		end
		if landed then
			landed:Destroy()
		end
	else
		VFX.play("Landing", egg, { rarity = view.payload.rarity, ownerUserId = view.payload.ownerUserId })
	end
	VFX.play("LegsSprout", egg, { ownerUserId = view.payload.ownerUserId })
	view.connection = RunService.RenderStepped:Connect(function()
		step(view)
	end)
end

local function onChaseStart(payload: ChaseStartPayload)
	if views[payload.eggUid] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = `Fx_{payload.eggUid}` -- not the egg's name: A's overlay finds the egg by eggUid
	folder.Parent = chasesFolder

	local view: ChaseView = {
		payload = payload,
		isOwn = payload.ownerUserId == player.UserId,
		folder = folder,
		egg = nil,
		steering = false,
		contact = SoundBank.newContact(),
		clock = os.clock(),
		stepIn = 0,
		stops = {},
		connection = nil,
	}
	views[payload.eggUid] = view

	local now = workspace:GetServerTimeNow()
	VFX.play("AvalancheWarn", folder, {
		ownerUserId = payload.ownerUserId, -- other players' chases render at low detail
		theme = payload.theme,
		startZ = payload.startZ,
		seconds = math.max(0, payload.startTime - now),
	})
	task.delay(math.max(0, payload.startTime - now), function()
		if views[payload.eggUid] == view then
			VFX.play("AvalancheStart", folder, {
				ownerUserId = payload.ownerUserId,
				theme = payload.theme,
				startZ = payload.startZ,
				speed = payload.speed,
				startTime = payload.startTime,
			})
		end
	end)
	task.spawn(attachEgg, view)
end

-- A short-lived invisible anchor for effects that need a position after the egg itself is gone.
local function burstAnchor(at: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "SecuredFx"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(at)
	p.Parent = chasesFolder
	task.delay(BURST_LIFE, p.Destroy, p)
	return p
end

local function onEggSecured(payload: { eggUid: string, position: Vector3? })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	if view.connection then
		view.connection:Disconnect()
		view.connection = nil
	end
	local at = payload.position or (if view.egg and view.egg.Parent then view.egg:GetPivot().Position else nil)
	stopAll(view)
	if view.isOwn and view.steering then
		returnCamera()
	end
	view.steering = false
	showCharacter(view.payload.ownerUserId)
	if at then
		VFX.play(
			"EggSecured",
			burstAnchor(at),
			{ rarity = view.payload.rarity, ownerUserId = view.payload.ownerUserId }
		)
	end
	-- ChaseEnded follows at once: the avalanche crumbles and the folder goes.
end

local function onEggLost(payload: { eggUid: string, reason: string })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	if payload.reason ~= "Left" then
		VFX.play(
			"EggCaught",
			view.egg or view.folder,
			{ theme = view.payload.theme, ownerUserId = view.payload.ownerUserId }
		)
		VFX.play("AvalancheStop", view.folder, { ownerUserId = view.payload.ownerUserId })
	end
	endView(view, if payload.reason == "Left" then 0 else CLEANUP_DELAY)
end

local function onChaseEnded(payload: { eggUid: string })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	VFX.play("AvalancheStop", view.folder, { ownerUserId = view.payload.ownerUserId })
	endView(view, CLEANUP_DELAY)
end

function ChaseController:Init()
	chasesFolder = Instance.new("Folder")
	chasesFolder.Name = "ClientChases"
	chasesFolder.Parent = workspace
end

function ChaseController:Start()
	task.spawn(getControls)
	-- a respawn mid-chase (or after it) never leaves a body hidden / visible by mistake
	local function watch(other: Player)
		other.CharacterAdded:Connect(function()
			if hidden[other.UserId] then
				task.defer(hideCharacter, other.UserId)
			end
		end)
	end
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(other)
		local h = hidden[other.UserId]
		if h then
			for _, c in h.conns do
				c:Disconnect()
			end
			hidden[other.UserId] = nil
		end
	end)
	Remotes.get("ChaseStart").OnClientEvent:Connect(onChaseStart)
	Remotes.get("EggSecured").OnClientEvent:Connect(onEggSecured)
	Remotes.get("EggLost").OnClientEvent:Connect(onEggLost)
	Remotes.get("ChaseEnded").OnClientEvent:Connect(onChaseEnded)
end

return ChaseController
