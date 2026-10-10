--!strict
-- World interactions (client):
--   * ProximityPrompts from the map carry an "Action" attribute: UpgradePen / UpgradeTraining fire their
--     remotes, "OpenMenu:<Name>" opens a window.
--   * Training: while running on your own treadmill's belt (Plate), every Config/Upgrades.Rack.interval:
--     fire Remotes.Train (the server validates and grants) and play TreadStep (streaks, puff, "+X Power").
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MyBase = require(script.Parent.MyBase)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Upgrades = require(Shared:WaitForChild("Config"):WaitForChild("Upgrades"))
local Economy = require(Shared:WaitForChild("Config"):WaitForChild("Economy"))

local Interact = {}

local function fire(name: string)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireServer()
	end
end

-- Red bouncing "!" over an upgrade sign of your own base when you can afford it.
local function alert(sign: Instance?, on: boolean)
	if not (sign and sign:IsA("BasePart")) then
		return
	end
	local gui = sign:FindFirstChild("Alert")
	if not on then
		if gui then
			gui:Destroy()
		end
		return
	end
	if gui then
		return
	end
	local b = Instance.new("BillboardGui")
	b.Name = "Alert"
	b.Size = UDim2.fromOffset(40, 60)
	b.StudsOffsetWorldSpace = Vector3.new(0, sign.Size.Y / 2 + 2, 0)
	b.AlwaysOnTop = true
	b.MaxDistance = 120
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = "!"
	l.TextColor3 = Color3.fromRGB(240, 40, 40)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = l
	l.Parent = b
	b.Parent = sign
	task.spawn(function()
		while b.Parent do
			b.StudsOffsetWorldSpace = Vector3.new(0, sign.Size.Y / 2 + 2 + math.abs(math.sin(os.clock() * 4)) * 0.8, 0)
			task.wait()
		end
	end)
end

local function refreshAlerts(data: { [string]: any })
	local base = MyBase.get()
	if not base then
		return
	end
	local money = if typeof(data.money) == "number" then data.money else 0
	local levels = Upgrades.Rack.levels
	local rl = MyBase.level("RackLevel", data, "rackLevel")
	local nextRack = levels[rl + 1]
	alert(base:FindFirstChild("RackSign"), nextRack ~= nil and money >= nextRack.cost)
	local pl = math.max(1, MyBase.level("PenLevel", data, "penLevel"))
	local slots = Economy.PlotSlots.base + (pl - 1) * Upgrades.Pen.slotsPerLevel
	local penCost = Upgrades.Pen.costBase * Upgrades.Pen.costGrowth ^ (pl - 1)
	alert(base:FindFirstChild("PenSign"), slots < Economy.PlotSlots.max and money >= penCost)
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
		-- Treadmill (map v3): anywhere on the running belt counts (the conveyor keeps you near the console)
		local rel = plate.CFrame:PointToObjectSpace(hrp.Position)
		local half = plate.Size / 2
		if math.abs(rel.X) > half.X + 0.5 or math.abs(rel.Z) > half.Z + 0.5 or rel.Y < 0 or rel.Y > 6 then
			return
		end
		last = os.clock()
		fire("Train")
		local levels = Upgrades.Rack.levels
		local level = math.clamp(MyBase.level("RackLevel", data, "rackLevel"), 1, #levels)
		VFX.play("TreadStep", rack, { tier = levels[level].tier, gain = levels[level].gain })
	end)

	return function(d: { [string]: any })
		data = d
		refreshAlerts(d)
	end
end

return Interact
