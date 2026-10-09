--!strict
-- Draws every chase (own and other players') and lets the owner STEER their egg.
-- The egg is the server's model at workspace.Chases[eggUid]. From controlStart (ChaseStart.eggRunStart)
-- the owner has physics ownership: their movement input (keyboard / thumbstick, camera-relative)
-- sets the egg's LinearVelocity, and the camera follows the egg. The server validates and decides.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VFX = require(Shared.VFX)
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
}

local EGG_WAIT = 10 -- seconds to wait for the server egg to replicate
local CLEANUP_DELAY = 1.2 -- AvalancheStop crumble time
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

local function step(view: ChaseView)
	local egg = view.egg
	if not egg or not egg.Parent then
		return
	end
	local now = workspace:GetServerTimeNow()
	if not view.steering and now >= view.payload.eggRunStart then
		view.steering = true
		table.insert(view.stops, Anim.play(egg, "EggRun"))
	end
	if view.isOwn and view.steering then
		steer(egg)
	end
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
		VFX.play("Landing", egg, { rarity = view.payload.rarity })
	end
	VFX.play("LegsSprout", egg, {})
	view.connection = RunService.RenderStepped:Connect(function()
		step(view)
	end)
end

local function onChaseStart(payload: ChaseStartPayload)
	if views[payload.eggUid] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = payload.eggUid
	folder.Parent = chasesFolder

	local view: ChaseView = {
		payload = payload,
		isOwn = payload.ownerUserId == player.UserId,
		folder = folder,
		egg = nil,
		steering = false,
		stops = {},
		connection = nil,
	}
	views[payload.eggUid] = view

	local now = workspace:GetServerTimeNow()
	VFX.play("AvalancheWarn", folder, {
		theme = payload.theme,
		startZ = payload.startZ,
		seconds = math.max(0, payload.startTime - now),
	})
	task.delay(math.max(0, payload.startTime - now), function()
		if views[payload.eggUid] == view then
			VFX.play("AvalancheStart", folder, {
				theme = payload.theme,
				startZ = payload.startZ,
				speed = payload.speed,
				startTime = payload.startTime,
			})
		end
	end)
	task.spawn(attachEgg, view)
end

local function onEggSecured(payload: { eggUid: string })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	if view.connection then
		view.connection:Disconnect()
		view.connection = nil
	end
	stopAll(view)
	if view.isOwn and view.steering then
		returnCamera()
	end
	view.steering = false
	if view.egg then
		VFX.play("EggSecured", view.egg, { rarity = view.payload.rarity })
	end
	-- The avalanche keeps rolling to the safe line; ChaseEnded removes the folder.
end

local function onEggLost(payload: { eggUid: string, reason: string })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	if payload.reason ~= "Left" then
		VFX.play("EggCaught", view.egg or view.folder, { theme = view.payload.theme })
		VFX.play("AvalancheStop", view.folder, {})
	end
	endView(view, if payload.reason == "Left" then 0 else CLEANUP_DELAY)
end

local function onChaseEnded(payload: { eggUid: string })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	VFX.play("AvalancheStop", view.folder, {})
	endView(view, CLEANUP_DELAY)
end

function ChaseController:Init()
	chasesFolder = Instance.new("Folder")
	chasesFolder.Name = "ClientChases"
	chasesFolder.Parent = workspace
end

function ChaseController:Start()
	task.spawn(getControls)
	Remotes.get("ChaseStart").OnClientEvent:Connect(onChaseStart)
	Remotes.get("EggSecured").OnClientEvent:Connect(onEggSecured)
	Remotes.get("EggLost").OnClientEvent:Connect(onEggLost)
	Remotes.get("ChaseEnded").OnClientEvent:Connect(onChaseEnded)
end

return ChaseController
