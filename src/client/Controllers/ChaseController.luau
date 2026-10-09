--!strict
-- Draws every chase (own and other players'): avalanche VFX, the running egg (same formula as
-- the server + a cosmetic zig-zag), touch pickup for the owner, the carry weld and outcome VFX.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chase = require(Shared.Config.Chase)
local Pets = require(Shared.Config.Pets)
local Zones = require(Shared.Config.Zones)
local Models = require(Shared.Builders.Models)
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
	eggRunStart: number,
	eggModel: string?, -- added by the ChaseStart contract update; older servers omit them
	rarity: string?,
}

type ChaseView = {
	payload: ChaseStartPayload,
	isOwn: boolean,
	folder: Folder,
	egg: Model?,
	eggModel: string,
	rarity: string?,
	carrier: Player?,
	running: boolean,
	stops: { () -> () },
	connection: RBXScriptConnection?,
	lastPickupSend: number,
}

local ZIGZAG_RATE = 4 -- sin(t × 4), as in the spec
local CARRY_ABOVE_HEAD = 1.5
local PICKUP_RESEND = 0.25
local CLEANUP_DELAY = 1.2 -- AvalancheStop crumble time
local RAY_TOP = 40

local Egg = Chase.Egg

local ChaseController = {}

local player = Players.LocalPlayer
local chasesFolder: Folder
local views: { [string]: ChaseView } = {}
local ownKicks: { [string]: { eggModel: string, rarity: string } } = {}
local pickupEgg: RemoteEvent

local function zoneAt(z: number): number
	for _, zone in Zones do
		if z < zone.start + zone.length then
			return zone.id
		end
	end
	return #Zones
end

local function groundY(x: number, z: number, near: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { chasesFolder }
	local clientEggs = workspace:FindFirstChild("ClientEggs")
	if clientEggs then
		table.insert(ignore, clientEggs)
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(x, near + RAY_TOP, z), Vector3.new(0, -RAY_TOP * 3, 0), params)
	return if hit then hit.Position.Y else near
end

-- Same Z as ChaseService.eggZ on the server, plus a cosmetic zig-zag on X.
local function eggPlacement(payload: ChaseStartPayload, now: number): (Vector3, Vector3)
	local t = math.max(0, now - payload.eggRunStart)
	local start = payload.eggStartPos
	local rawZ = start.Z - Egg.runSpeed * t
	local z = math.max(rawZ, Chase.SafeLineZ)
	local x = start.X + Egg.zigzag * math.sin(t * ZIGZAG_RATE)
	local running = t > 0 and rawZ > Chase.SafeLineZ
	local heading = if running
		then Vector3.new(Egg.zigzag * ZIGZAG_RATE * math.cos(t * ZIGZAG_RATE), 0, -Egg.runSpeed)
		else Vector3.new(0, 0, -1)
	return Vector3.new(x, start.Y, z), heading
end

local function stopAll(view: ChaseView)
	for _, stop in view.stops do
		stop()
	end
	table.clear(view.stops)
end

local function destroyView(view: ChaseView, delay: number)
	if views[view.payload.eggUid] == view then
		views[view.payload.eggUid] = nil
	end
	if view.connection then
		view.connection:Disconnect()
		view.connection = nil
	end
	stopAll(view)
	if view.egg then
		view.egg:Destroy()
		view.egg = nil
	end
	local folder = view.folder
	task.delay(delay, function()
		folder:Destroy()
	end)
end

local function tryPickup(view: ChaseView, now: number)
	if not view.isOwn or view.carrier or now - view.lastPickupSend < PICKUP_RESEND then
		return
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local egg = view.egg
	if not hrp or not hrp:IsA("BasePart") or not egg then
		return
	end
	local delta = hrp.Position - egg:GetPivot().Position
	if Vector3.new(delta.X, 0, delta.Z).Magnitude <= Egg.pickupDistance then
		view.lastPickupSend = now
		pickupEgg:FireServer(view.payload.eggUid)
	end
end

-- The owner's landed egg comes from FlightController (it may still be swapping at touchdown);
-- other players' eggs, or a missing one, are spawned here.
local function ensureEgg(view: ChaseView): Model?
	local egg = view.egg
	if egg and egg.Parent then
		return egg
	end
	local model: Model
	local taken = if view.isOwn then FlightController:TakeEgg(view.payload.eggUid) else nil
	if taken and taken.Parent then
		model = taken
	elseif view.isOwn and FlightController:GetEgg(view.payload.eggUid) then
		return nil -- our egg is still landing; take it next frame
	else
		model = Models.egg(view.eggModel)
		model:PivotTo(CFrame.new(view.payload.eggStartPos))
	end
	model.Name = "Egg"
	model.Parent = view.folder
	view.egg = model
	if view.isOwn then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Touched:Connect(function(hit)
					local character = player.Character
					if character and hit:IsDescendantOf(character) then
						tryPickup(view, workspace:GetServerTimeNow())
					end
				end)
			end
		end
	end
	return model
end

local function step(view: ChaseView)
	if view.carrier then
		return -- welded to the carrier's head
	end
	local now = workspace:GetServerTimeNow()
	local egg = ensureEgg(view)
	if not egg then
		return
	end
	local pos, heading = eggPlacement(view.payload, now)
	local y = groundY(pos.X, pos.Z, pos.Y)
	local at = Vector3.new(pos.X, y, pos.Z)
	egg:PivotTo(CFrame.lookAt(at, at + heading))

	if not view.running and now >= view.payload.eggRunStart then
		view.running = true
		table.insert(view.stops, Anim.play(egg, "EggRun"))
	end
	tryPickup(view, now)
end

local function onChaseStart(payload: ChaseStartPayload)
	if views[payload.eggUid] then
		return
	end
	local isOwn = payload.ownerUserId == player.UserId
	local own = ownKicks[payload.eggUid]
	local guessKeys = Models.eggKeysForZone(Pets, zoneAt(payload.eggStartPos.Z))

	local folder = Instance.new("Folder")
	folder.Name = payload.eggUid
	folder.Parent = chasesFolder

	local view: ChaseView = {
		payload = payload,
		isOwn = isOwn,
		folder = folder,
		egg = nil,
		eggModel = if own then own.eggModel else (payload.eggModel or guessKeys[1] or "Unknown"),
		rarity = if own then own.rarity else payload.rarity,
		carrier = nil,
		running = false,
		stops = {},
		connection = nil,
		lastPickupSend = 0,
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

	ensureEgg(view)
	view.connection = RunService.RenderStepped:Connect(function()
		step(view)
	end)
end

local function onEggPickedUp(payload: { eggUid: string, userId: number })
	local view = views[payload.eggUid]
	local carrier = Players:GetPlayerByUserId(payload.userId)
	local character = carrier and carrier.Character
	local head = character and character:FindFirstChild("Head")
	if not view or not carrier or not character or not head or not head:IsA("BasePart") then
		return
	end
	view.carrier = carrier
	stopAll(view)
	local egg = ensureEgg(view)
	if not egg then
		return
	end
	egg:PivotTo(head.CFrame * CFrame.new(0, head.Size.Y / 2 + CARRY_ABOVE_HEAD, 0))
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
			part.CanCollide = false
			part.CanTouch = false
		end
	end
	local root = egg.PrimaryPart
	if root then
		root.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = head
		weld.Parent = root
	end
	VFX.play("EggPickup", egg, {})
	table.insert(view.stops, Anim.play(egg, "EggCarried"))
	table.insert(view.stops, Anim.play(character, "PlayerCarry"))
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
	if view.egg then
		VFX.play("EggSecured", view.egg, { rarity = view.rarity })
		view.egg:Destroy()
		view.egg = nil
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
	destroyView(view, if payload.reason == "Left" then 0 else CLEANUP_DELAY)
	ownKicks[payload.eggUid] = nil
end

local function onChaseEnded(payload: { eggUid: string })
	local view = views[payload.eggUid]
	if not view then
		return
	end
	VFX.play("AvalancheStop", view.folder, {})
	destroyView(view, CLEANUP_DELAY)
end

function ChaseController:Init()
	pickupEgg = Remotes.get("PickupEgg")
	chasesFolder = Instance.new("Folder")
	chasesFolder.Name = "ClientChases"
	chasesFolder.Parent = workspace
end

function ChaseController:Start()
	Remotes.get("KickResult").OnClientEvent:Connect(function(result: FlightController.KickResult)
		ownKicks[result.eggUid] = { eggModel = result.eggModel, rarity = result.rarity }
	end)
	Remotes.get("ChaseStart").OnClientEvent:Connect(onChaseStart)
	Remotes.get("EggPickedUp").OnClientEvent:Connect(onEggPickedUp)
	Remotes.get("EggSecured").OnClientEvent:Connect(onEggSecured)
	Remotes.get("EggLost").OnClientEvent:Connect(onEggLost)
	Remotes.get("ChaseEnded").OnClientEvent:Connect(function(payload: { eggUid: string })
		onChaseEnded(payload)
		ownKicks[payload.eggUid] = nil
	end)
end

return ChaseController
