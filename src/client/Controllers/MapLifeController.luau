--!strict
-- Brings map v3 scenery to life on this client (local-only motion of anchored map models):
--   models with a "Spin" attribute (degrees / second) turn in place (the hub's egg statues and the
--   sack hanging on each base's Kick Sack stand, Base<i>.SackStand.Sack, which plays "SackUpgrade"
--   when the base's RackLevel goes up);
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
local OWNER_SETTLE = 2 -- seconds after an owner change in which level changes are just restored data

local MapLifeController = {}

type Spinner = { model: Model, base: CFrame, speed: number }
type Merchant = { model: Model, base: CFrame, yaw: number, bubble: BillboardGui?, phase: number }

local player = Players.LocalPlayer
local spinners: { Spinner } = {}
local merchants: { Merchant } = {}

-- Stand sacks (Base<i>.SackStand.Sack) show their tier's idle VFX (VFX/SackAura) while the camera is
-- near; step() moves them (spin) and then advances their effects.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sacks = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks"))
local SackAura = require(Shared:WaitForChild("VFX"):WaitForChild("SackAura"))
local AURA_ON, AURA_OFF = 90, 110 -- studs from the camera: effects start / stop
local standSacks: { [Model]: any } = {} -- model -> SackAura context, or false while off
local auraCheck = 0

local function addStandSack(model: Instance)
	if model:IsA("Model") and model.Name == "Sack" and typeof(model:GetAttribute("Tier")) == "number" then
		standSacks[model] = false
	end
end

local function refreshAuras()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	for model, ctx in standSacks do
		if not model.Parent then
			standSacks[model] = nil
			continue
		end
		local d = (model:GetPivot().Position - cam.CFrame.Position).Magnitude
		if not ctx and d < AURA_ON then
			local tier = model:GetAttribute("Tier") :: number
			local ok, made =
				pcall(SackAura.Apply, model, tier, model:GetPivot() * Sacks.vfxRoot(tier), Sacks.SCALE, true)
			standSacks[model] = if ok then made else false
		elseif ctx and d > AURA_OFF then
			SackAura.Remove(model)
			standSacks[model] = false
		end
	end
end

local function addSpinner(model: Instance)
	if not model:IsA("Model") or not model.PrimaryPart then
		return
	end
	local spin = model:GetAttribute("Spin")
	if typeof(spin) == "number" then
		table.insert(spinners, { model = model, base = model:GetPivot(), speed = math.rad(spin) })
	end
end

-- The stand's sack is rebuilt for every new tier: spin the new one and celebrate real upgrades
-- (RackLevel going up), not the level restored when an owner joins.
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
		task.delay(0.35, function() -- the server rebuilds the stand's sack first
			local stand = base:FindFirstChild("SackStand")
			local sack = stand and stand:FindFirstChild("Sack")
			if sack then
				VFX.play("SackUpgrade", sack, { tier = new, own = base:GetAttribute("OwnerUserId") == player.UserId })
			end
		end)
	end)
	local function watchStand(stand: Instance)
		if stand.Name == "SackStand" then
			stand.ChildAdded:Connect(function(child)
				task.defer(addSpinner, child)
				task.defer(addStandSack, child)
			end)
		end
	end
	for _, child in base:GetChildren() do
		watchStand(child)
	end
	base.ChildAdded:Connect(watchStand)
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
	addSpinner(model)
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
	for i = #spinners, 1, -1 do
		local s = spinners[i]
		if s.model.Parent then
			s.model:PivotTo(s.base * CFrame.Angles(0, s.speed * t, 0))
		else
			table.remove(spinners, i) -- replaced stand sacks
		end
	end
	auraCheck -= dt
	if auraCheck <= 0 then
		auraCheck = 0.5
		refreshAuras()
	end
	for _, ctx in standSacks do
		if ctx then
			ctx:step(dt) -- after the spin, so orbits and wings follow the turning sack
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
			addStandSack(d)
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
