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
local Economy = require(Shared:WaitForChild("Config"):WaitForChild("Economy"))

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
		refreshAlerts(d)
	end
end

return Interact
