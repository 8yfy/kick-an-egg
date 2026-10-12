--!strict
-- Brings map v3 scenery to life on this client (local-only motion of anchored map models):
--   models with a "Spin" attribute (degrees / second) turn in place (the hub's egg statues and the
--   sack hanging on each base's Kick Sack stand, Base<i>.SackStand.Sack, which plays "SackUpgrade"
--   when the base's RackLevel goes up). Spinning follows VFX/SackLod's levels: every frame up close,
--   every 2nd / 4th frame (interleaved) further out, not at all far away or off screen. A turn is one
--   workspace:BulkMoveTo of the model's cached parts (about 3.5x cheaper than PivotTo, tools/perf); parts
--   the sack effect places itself ("SackVFX_Placed", "SackVFX_Rest") are left to the effect;
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

type Spinner = {
	model: Model,
	base: CFrame,
	speed: number,
	radius: number,
	level: number,
	visible: boolean,
	angle: number, -- last turn written
	parts: { BasePart }?, -- cached parts and their offsets from the pivot (nil = rebuild before the next turn)
	rel: { CFrame },
	cfs: { CFrame },
}
type Merchant = { model: Model, base: CFrame, yaw: number, bubble: BillboardGui?, phase: number }

local player = Players.LocalPlayer
local spinners: { Spinner } = {}
local merchants: { Merchant } = {}

-- Stand and shop sacks (map "Sack" models with a Tier: Base<i>.SackStand.Sack, the Boxing Sack Shop's rack)
-- show their tier's idle VFX (VFX/SackAura). An effect is built when the camera first comes within the farthest
-- detail band (nearest first, one per check, so joining or teleporting never builds them all in one frame) and
-- is then kept: VFX/SackLod thins, slows, hides and shows it by distance and view, instead of the old destroy /
-- rebuild at 110 / 90 studs. step() spins the sacks and then advances their effects.
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sacks = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks"))
local SackAura = require(Shared:WaitForChild("VFX"):WaitForChild("SackAura"))
local SackLod = require(Shared:WaitForChild("VFX"):WaitForChild("SackLod"))
local AURA_CHECK = 0.25 -- seconds between "build the nearest missing effect" checks
local standSacks: { [Model]: any } = {} -- model -> SackAura context, or false until built
local broken: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- effects that failed to build
local auraCheck = 0
local lodCheck = 0
local frameNo = 0
local profile = SackLod.profile()

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
	local nearest: Model?, best = nil, SackLod.BANDS[#SackLod.BANDS] * profile.reach + SackLod.HYSTERESIS
	for model, ctx in standSacks do
		if not model.Parent or (ctx and ctx.dead) then
			standSacks[model] = nil -- replaced, or streamed out (SackLod freed its effect)
			continue
		end
		if not ctx and not broken[model] then
			local d = (model:GetPivot().Position - cam.CFrame.Position).Magnitude
			if d < best then
				nearest, best = model, d
			end
		end
	end
	if nearest then
		local tier = nearest:GetAttribute("Tier") :: number
		local ok, made =
			pcall(SackAura.Apply, nearest, tier, nearest:GetPivot() * Sacks.vfxRoot(tier), Sacks.SCALE, true)
		if ok then
			standSacks[nearest] = made
		else
			broken[nearest] = true
			warn("[MapLife] sack effect failed for tier", tier, made)
		end
	end
end

local function addSpinner(model: Instance)
	if not model:IsA("Model") or not model.PrimaryPart then
		return
	end
	local spin = model:GetAttribute("Spin")
	if typeof(spin) == "number" then
		local s: Spinner = {
			model = model,
			base = model:GetPivot(),
			speed = math.rad(spin),
			radius = model:GetExtentsSize().Magnitude / 2,
			level = SackLod.FULL,
			visible = true,
			angle = 0,
			parts = nil,
			rel = {},
			cfs = {},
		}
		local function stale(d: Instance)
			if d:IsA("BasePart") then
				s.parts = nil -- e.g. the sack effect was built: re-cache, leaving its own parts out
			end
		end
		model.DescendantAdded:Connect(stale)
		model.DescendantRemoving:Connect(stale)
		table.insert(spinners, s)
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

local function turn(s: Spinner, angle: number)
	local parts = s.parts
	if not parts then
		local pivot = s.base * CFrame.Angles(0, s.angle, 0)
		local list, rel = {}, {}
		for _, d in s.model:GetDescendants() do
			if
				d:IsA("BasePart")
				and d:GetAttribute("SackVFX_Placed") == nil
				and d:GetAttribute("SackVFX_Rest") == nil
			then
				table.insert(list, d)
				table.insert(rel, pivot:ToObjectSpace(d.CFrame))
			end
		end
		parts = list
		s.parts, s.rel, s.cfs = list, rel, table.create(#list)
	end
	local at = s.base * CFrame.Angles(0, angle, 0)
	local cfs = s.cfs
	for k, r in s.rel do
		cfs[k] = at * r
	end
	workspace:BulkMoveTo(parts :: { BasePart }, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	s.angle = angle
end

local function step(dt: number)
	local t = os.clock()
	frameNo += 1
	lodCheck -= dt
	local recheck = lodCheck <= 0
	if recheck then
		lodCheck = SackLod.CHECK_INTERVAL
		profile = SackLod.profile()
	end
	local cam = workspace.CurrentCamera
	local camCF = cam and cam.CFrame
	local tanY = if cam then math.tan(math.rad(cam.FieldOfView) / 2) else 1
	local vp = if cam then cam.ViewportSize else Vector2.one
	local aspect = if vp.Y > 0 then vp.X / vp.Y else 16 / 9
	for i = #spinners, 1, -1 do
		local s = spinners[i]
		if not s.model.Parent then
			table.remove(spinners, i) -- replaced stand sacks
			continue
		end
		if camCF then
			local at = s.base.Position
			local d = (at - camCF.Position).Magnitude
			if recheck then
				s.level = SackLod.band(d, s.level, profile.reach)
			end
			s.visible = d < SackLod.CULL_MIN or SackLod.inView(camCF, tanY, aspect, at, s.radius * SackLod.CULL_MARGIN)
		end
		if s.level < SackLod.DISABLED and s.visible then
			local stride = profile.stride[s.level]
			if stride <= 1 or (frameNo + i) % stride == 0 then
				turn(s, s.speed * t) -- absolute angle: skipped frames catch up
			end
		end
	end
	auraCheck -= dt
	if auraCheck <= 0 then
		auraCheck = AURA_CHECK
		refreshAuras()
	end
	for _, ctx in standSacks do
		if ctx and not ctx.dead then
			ctx:step(dt) -- after the spin, so orbits and wings follow the turning sack (returns at once when hidden)
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
