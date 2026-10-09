--!strict
-- KickResult → egg flies on a parabola from the pad to landPos over flightSeconds (server time),
-- EggSpin on every zone boundary, swaps to the rolled egg at touchdown (Landing + LegsSprout).
-- The camera follows the egg and hands back to the player 0.6 s after touchdown.
-- ChaseController takes the landed egg with :TakeEgg(eggUid).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chase = require(Shared.Config.Chase)
local Pets = require(Shared.Config.Pets)
local Zones = require(Shared.Config.Zones)
local Models = require(Shared.Builders.Models)
local VFX = require(Shared.VFX)
local Remotes = require(Shared.Remotes)

export type KickResult = {
	eggUid: string,
	zonesCrossed: { number },
	landZone: number,
	distance: number,
	landPos: Vector3,
	launchTime: number,
	flightSeconds: number,
	eggModel: string,
	petId: string,
	rarity: string,
	size: string?,
	weather: string?,
}

local CAMERA_RETURN_DELAY = 0.6
local CAMERA_LERP = 0.15 -- per 60 fps frame
local CAMERA_OFFSET = Vector3.new(0, 14, -34) -- behind (toward the bases) and above the egg
local PAD_RAY_TOP = 50

local FlightController = {}

local player = Players.LocalPlayer
local eggFolder: Folder
local eggs: { [string]: Model } = {} -- in flight or landed, not yet taken by ChaseController
local landedEggs: { [string]: boolean } = {} -- touched down, ready for ChaseController
local flightConnection: RBXScriptConnection? = nil

local function groundY(x: number, z: number, top: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = { eggFolder }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(ignore, other.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -top * 2, 0), params)
	return if hit then hit.Position.Y else 0
end

local function spawnEgg(key: string, uid: string, at: Vector3): Model
	local egg = Models.egg(key)
	egg.Name = uid
	egg:PivotTo(CFrame.new(at))
	egg.Parent = eggFolder
	return egg
end

local function releaseCamera()
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function fly(result: KickResult)
	-- One flight at a time; drop any landed egg nobody claimed.
	if flightConnection then
		flightConnection:Disconnect()
		flightConnection = nil
	end
	for uid, old in eggs do
		old:Destroy()
		eggs[uid] = nil
		landedEggs[uid] = nil
	end

	local startPos = Vector3.new(0, groundY(0, 0, PAD_RAY_TOP), 0)
	local landPos = result.landPos
	local apex = math.min(result.distance * Chase.Flight.arcHeightPerStud, Chase.Flight.maxArcHeight)
	local touchdown = result.launchTime + result.flightSeconds
	local lastZoneIndex = #result.zonesCrossed

	local firstKeys = Models.eggKeysForZone(Pets, result.zonesCrossed[1] or 1)
	local egg = spawnEgg(firstKeys[1] or result.eggModel, result.eggUid, startPos)
	eggs[result.eggUid] = egg

	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable

	local nextZone = 1 -- index into zonesCrossed of the next boundary to announce
	local landed = false

	local function positionAt(now: number): Vector3
		local t = math.clamp((now - result.launchTime) / result.flightSeconds, 0, 1)
		local flat = startPos:Lerp(landPos, t)
		return flat + Vector3.new(0, 4 * apex * t * (1 - t), 0)
	end

	local function enterZones(z: number, launched: boolean)
		while nextZone <= lastZoneIndex do
			local zoneId = result.zonesCrossed[nextZone]
			if not launched or z < Zones[zoneId].start then
				return
			end
			local isLast = nextZone == lastZoneIndex
			VFX.play("ZoneEnter", egg, { zone = zoneId })
			VFX.play("EggSpin", egg, {
				zone = zoneId,
				keys = Models.eggKeysForZone(Pets, zoneId),
				finalKey = if isLast then result.eggModel else nil,
				seconds = Chase.Flight.spinSecondsPerZone,
			})
			nextZone += 1
		end
	end

	local function land()
		landed = true
		egg:Destroy()
		egg = spawnEgg(result.eggModel, result.eggUid, landPos)
		eggs[result.eggUid] = egg
		landedEggs[result.eggUid] = true
		VFX.play("Landing", egg, { rarity = result.rarity, zone = result.landZone })
		VFX.play("LegsSprout", egg, {})
	end

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function(dt: number)
		local now = workspace:GetServerTimeNow()

		if not landed then
			local pos = positionAt(now)
			local ahead = positionAt(now + 0.05)
			local facing = if (ahead - pos).Magnitude > 0.01 then CFrame.lookAt(pos, ahead) else CFrame.new(pos)
			egg:PivotTo(if now >= result.launchTime then facing else CFrame.new(pos))
			enterZones(pos.Z, now >= result.launchTime)
			if now >= touchdown then
				land()
			end
		end

		if egg.Parent then
			local target = egg:GetPivot().Position
			local goal = CFrame.lookAt(target + CAMERA_OFFSET, target)
			local alpha = 1 - (1 - CAMERA_LERP) ^ (dt * 60)
			camera.CFrame = camera.CFrame:Lerp(goal, alpha)
		end

		if now >= touchdown + CAMERA_RETURN_DELAY then
			connection:Disconnect()
			if flightConnection == connection then
				flightConnection = nil
			end
			releaseCamera()
		end
	end)
	flightConnection = connection
end

-- Public API ---------------------------------------------------------------

-- The egg model for `eggUid` (flying or landed), still owned by this controller.
function FlightController:GetEgg(eggUid: string): Model?
	return eggs[eggUid]
end

-- Hands the landed egg over (ChaseController); nil while still in flight.
function FlightController:TakeEgg(eggUid: string): Model?
	if not landedEggs[eggUid] then
		return nil -- still flying; ChaseController asks again next frame
	end
	local egg = eggs[eggUid]
	eggs[eggUid] = nil
	landedEggs[eggUid] = nil
	return egg
end

function FlightController:Init()
	eggFolder = Instance.new("Folder")
	eggFolder.Name = "ClientEggs"
	eggFolder.Parent = workspace
end

function FlightController:Start()
	Remotes.get("KickResult").OnClientEvent:Connect(function(result: KickResult)
		-- With StreamingEnabled the landing zone may be far outside the streamed radius:
		-- ask for it during the flight so the egg lands (and runs) on real ground.
		task.spawn(pcall, player.RequestStreamAroundAsync, player, result.landPos)
		fly(result)
	end)
	player.CharacterAdded:Connect(function()
		if not flightConnection then
			releaseCamera()
		end
	end)
end

return FlightController
