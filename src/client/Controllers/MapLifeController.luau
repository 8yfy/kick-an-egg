--!strict
-- Brings map v3 scenery to life on this client (local-only motion of anchored map models):
--   models with a "Spin" attribute (degrees / second) turn in place (the hub's egg statues);
--   treadmills (Base<i>.TrainingRack) scroll their belt slats at BeltSpeed and play "TreadUpgrade"
--   when their RackLevel goes up;
--   models with a "Merchant" attribute bob, turn to face the local player when they are near and
--   show their "Greeting" in a speech bubble.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VFX = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX")) :: any

local FACE_RANGE = 24 -- studs: merchants turn toward you inside this
local TALK_RANGE = 14 -- studs: the speech bubble shows inside this
local TURN_RATE = 4 -- how fast merchants turn (per second, exponential)
local BOB = 0.15

local MapLifeController = {}

type Spinner = { model: Model, base: CFrame, speed: number }
type Merchant = { model: Model, base: CFrame, yaw: number, bubble: BillboardGui?, phase: number }

local player = Players.LocalPlayer
local spinners: { Spinner } = {}
local merchants: { Merchant } = {}

-- Treadmills: belt slats scroll toward the entry at the rack's BeltSpeed; upgrades get a VFX.
type Belt = { rack: Model, plate: BasePart, slats: { { part: BasePart, rel: CFrame } }, speed: number, length: number }
local belts: { [Model]: Belt } = {}
local OWNER_SETTLE = 2 -- seconds after an owner change in which level changes are just restored data

local function trackBelt(rack: Instance)
	if not rack:IsA("Model") or rack.Name ~= "TrainingRack" then
		return
	end
	local plate = rack:FindFirstChild("Plate")
	if not plate or not plate:IsA("BasePart") then
		return
	end
	local slats = {}
	for _, d in rack:GetChildren() do
		if d:IsA("BasePart") and d.Name == "Slat" then
			table.insert(slats, { part = d, rel = plate.CFrame:ToObjectSpace(d.CFrame) })
		end
	end
	local speed = rack:GetAttribute("BeltSpeed")
	belts[rack] = {
		rack = rack,
		plate = plate,
		slats = slats,
		speed = if typeof(speed) == "number" then speed else 6,
		length = plate.Size.Z,
	}
	rack.AncestryChanged:Connect(function()
		if not rack:IsDescendantOf(workspace) then
			belts[rack] = nil
		end
	end)
end

local function stepBelts(t: number)
	for _, belt in belts do
		local span = belt.length - 0.4
		for _, s in belt.slats do
			local z = (s.rel.Z - belt.speed * t + belt.length / 2 - 0.2) % span - belt.length / 2 + 0.2
			s.part.CFrame = belt.plate.CFrame * CFrame.new(s.rel.X, s.rel.Y, z)
		end
	end
end

-- Celebrates real upgrades (RackLevel going up), not the level restored when an owner joins.
local function watchBase(base: Instance)
	local ownerChangedAt = os.clock()
	local level = base:GetAttribute("RackLevel")
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		ownerChangedAt = os.clock()
	end)
	base:GetAttributeChangedSignal("RackLevel"):Connect(function()
		local new = base:GetAttribute("RackLevel")
		local old = level
		level = new
		if typeof(new) ~= "number" or typeof(old) ~= "number" or new <= old then
			return
		end
		if os.clock() - ownerChangedAt < OWNER_SETTLE then
			return
		end
		task.delay(0.35, function() -- the server may rebuild the treadmill for a new tier first
			local rack = base:FindFirstChild("TrainingRack")
			if rack then
				VFX.play("TreadUpgrade", rack, {
					tier = rack:GetAttribute("Tier"),
					own = base:GetAttribute("OwnerUserId") == player.UserId,
				})
			end
		end)
	end)
	for _, child in base:GetChildren() do
		trackBelt(child)
	end
	base.ChildAdded:Connect(function(child)
		task.defer(trackBelt, child)
	end)
end

local function makeBubble(model: Model, text: string): BillboardGui?
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return nil
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Greeting"
	gui.Size = UDim2.fromOffset(240, 64)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.Enabled = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.TextColor3 = Color3.fromRGB(25, 30, 45)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = label
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	pad.Parent = label
	label.Parent = gui
	gui.Adornee = head
	gui.Parent = head
	return gui
end

local function track(model: Instance)
	if not model:IsA("Model") or not model.PrimaryPart then
		return
	end
	local spin = model:GetAttribute("Spin")
	if typeof(spin) == "number" then
		table.insert(spinners, { model = model, base = model:GetPivot(), speed = math.rad(spin) })
	end
	if model:GetAttribute("Merchant") ~= nil then
		local greeting = model:GetAttribute("Greeting")
		table.insert(merchants, {
			model = model,
			base = model:GetPivot(),
			yaw = 0,
			bubble = if typeof(greeting) == "string" then makeBubble(model, greeting) else nil,
			phase = #merchants * 1.7,
		})
	end
end

local function step(dt: number)
	local t = os.clock()
	stepBelts(t)
	for _, s in spinners do
		if s.model.Parent then
			s.model:PivotTo(s.base * CFrame.Angles(0, s.speed * t, 0))
		end
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local me = if hrp and hrp:IsA("BasePart") then hrp.Position else nil
	for _, m in merchants do
		if m.model.Parent then
			local target = 0
			local near = false
			if me then
				local rel = m.base:PointToObjectSpace(me)
				local dist = Vector2.new(rel.X, rel.Z).Magnitude
				if dist < FACE_RANGE then
					target = math.clamp(math.atan2(-rel.X, -rel.Z), -1.2, 1.2) -- don't turn their back
				end
				near = dist < TALK_RANGE
			end
			m.yaw += (target - m.yaw) * math.min(1, dt * TURN_RATE)
			local bob = math.sin(t * 2.2 + m.phase) * BOB
			m.model:PivotTo(m.base * CFrame.new(0, bob, 0) * CFrame.Angles(0, m.yaw, 0))
			if m.bubble then
				m.bubble.Enabled = near
			end
		end
	end
end

function MapLifeController:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		if not map then
			return
		end
		for _, d in map:GetDescendants() do
			track(d)
		end
		local safeZone = map:FindFirstChild("SafeZone")
		local bases = safeZone and safeZone:FindFirstChild("Bases")
		if bases then
			for _, base in bases:GetChildren() do
				watchBase(base)
			end
		end
		RunService.RenderStepped:Connect(step)
	end)
end

return MapLifeController
