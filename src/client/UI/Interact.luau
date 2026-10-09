--!strict
-- World interactions (client):
--   * ProximityPrompts from the map carry an "Action" attribute: UpgradePen / UpgradeTraining fire their
--     remotes, "OpenMenu:<Name>" opens a window.
--   * Training: while standing on your own rack's Plate, auto-kick every Config/Upgrades.Rack.interval:
--     fire Remotes.Train (the server validates and grants), play PlayerKick, swing the bag, pop "+X Power".
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MyBase = require(script.Parent.MyBase)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Upgrades = require(Shared:WaitForChild("Config"):WaitForChild("Upgrades"))

local Interact = {}

local BAG_PARTS = { "Chain", "Bag", "BagCap", "BagBand", "BagBottom" }

local function fire(name: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireServer()
	end
end

-- Swing the (anchored) bag parts around the top of the chain: kicked back, then sway home.
local function swing(rack: Instance)
	local chain = rack:FindFirstChild("Chain")
	if not (chain and chain:IsA("BasePart")) then
		return
	end
	local pivot = chain.CFrame * CFrame.new(0, chain.Size.Y / 2, 0)
	local parts: { [BasePart]: CFrame } = {}
	for _, n in BAG_PARTS do
		local p = rack:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			parts[p] = pivot:ToObjectSpace(p.CFrame)
		end
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local a = math.rad(28) * math.exp(-t * 4) * math.sin(t * 14) -- damped swing away from the kicker
		for p, rel in parts do
			p.CFrame = pivot * CFrame.Angles(-a, 0, 0) * rel
		end
		if t > 1.1 then
			conn:Disconnect()
			for p, rel in parts do
				p.CFrame = pivot * rel
			end
		end
	end)
end

function Interact.start(openMenu: (name: string) -> ()): (data: { [string]: any }) -> ()
	local data: { [string]: any } = {}
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if player ~= Players.LocalPlayer then
			return
		end
		local action = prompt:GetAttribute("Action")
		if action == "UpgradePen" or action == "UpgradeTraining" then
			fire(action)
		elseif typeof(action) == "string" and string.sub(action, 1, 9) == "OpenMenu:" then
			openMenu(string.sub(action, 10))
		end
	end)

	local Anim = require(Shared:WaitForChild("Anim")) :: any
	local VFX = require(Shared:WaitForChild("VFX")) :: any
	local last = 0
	RunService.Heartbeat:Connect(function()
		if os.clock() - last < Upgrades.Rack.interval then
			return
		end
		local base = MyBase.get()
		local rack = base and base:FindFirstChild("TrainingRack")
		local plate = rack and rack:FindFirstChild("Plate")
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (rack and plate and plate:IsA("BasePart") and hrp and hrp:IsA("BasePart")) then
			return
		end
		local d = hrp.Position - plate.Position
		if Vector2.new(d.X, d.Z).Magnitude > math.min(Upgrades.Rack.range, 3.5) or d.Y > 6 or d.Y < 0 then
			return
		end
		last = os.clock()
		fire("Train")
		local levels = Upgrades.Rack.levels
		local level = math.clamp(MyBase.level("RackLevel", data, "rackLevel"), 1, #levels)
		Anim.play(char, "PlayerKick", {})
		task.delay(0.18, function()
			swing(rack)
			VFX.play("TrainHit", rack:FindFirstChild("Bag"), { gain = levels[level].gain })
		end)
	end)

	return function(d: { [string]: any })
		data = d
	end
end

return Interact
