--!strict
-- A's KICK button fires Shared.KickPressed(timing) → RequestKick. Plays the kick lean on the
-- root joint and KickImpact on the egg at launch. Studio only: press K for a perfect kick.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VFX = require(Shared.VFX)
local Remotes = require(Shared.Remotes)

local FlightController = require(script.Parent.FlightController)

local LEAN_ANGLE = math.rad(-25)
local LEAN_IN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local LEAN_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLIENT_COOLDOWN = 0.5 -- the server enforces the real rule; this just avoids spam

local KickController = {}

local player = Players.LocalPlayer
local requestKick: RemoteEvent
local kickPower = 1
local lastPress = 0
local leaning = false

local function rootJoint(): Motor6D?
	local character = player.Character
	if not character then
		return nil
	end
	local lowerTorso = character:FindFirstChild("LowerTorso") -- R15
	local joint = lowerTorso and lowerTorso:FindFirstChild("Root")
	if not joint then
		local hrp = character:FindFirstChild("HumanoidRootPart") -- R6
		joint = hrp and hrp:FindFirstChild("RootJoint")
	end
	return if joint and joint:IsA("Motor6D") then joint else nil
end

local function playLean()
	local joint = rootJoint()
	if not joint or leaning then
		return
	end
	leaning = true
	local rest = joint.C0
	local lean = TweenService:Create(joint, LEAN_IN, { C0 = rest * CFrame.Angles(LEAN_ANGLE, 0, 0) })
	lean.Completed:Once(function()
		local back = TweenService:Create(joint, LEAN_OUT, { C0 = rest })
		back.Completed:Once(function()
			leaning = false
		end)
		back:Play()
	end)
	lean:Play()
end

local function kick(timing: number)
	local now = os.clock()
	if now - lastPress < CLIENT_COOLDOWN then
		return
	end
	lastPress = now
	playLean()
	requestKick:FireServer(math.clamp(timing, 0, 1))
end

function KickController:Init()
	requestKick = Remotes.get("RequestKick")
end

function KickController:Start()
	local kickPressed = Shared:WaitForChild("KickPressed") :: BindableEvent
	kickPressed.Event:Connect(function(timing: any)
		if typeof(timing) == "number" then
			kick(timing)
		end
	end)

	Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
		if typeof(partial.kickPower) == "number" then
			kickPower = partial.kickPower
		end
	end)

	Remotes.get("KickResult").OnClientEvent:Connect(function(result: FlightController.KickResult)
		task.delay(math.max(0, result.launchTime - workspace:GetServerTimeNow()), function()
			local egg = FlightController:GetEgg(result.eggUid)
			if egg then
				VFX.play("KickImpact", egg, { power = kickPower })
			end
		end)
	end)

	if RunService:IsStudio() then
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.K then
				kickPressed:Fire(0.95)
			end
		end)
	end
end

return KickController
