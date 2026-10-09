--!strict
-- Partner A. Egg flight + landing effects (client). B moves the egg; these only decorate it.
--   KickImpact {power}                    target = egg/pad: star burst + thump
--   ZoneEnter  {zone}                     target = egg: ring of sparks in the zone's accent colour
--   EggSpin    {zone, keys, finalKey?, seconds}  target = flying egg: slot-machine spin. The egg's own
--              parts are hidden locally and a visual egg (built from Models.egg(key)) rides on a
--              Motor6D, swapped every 0.07 s easing to 0.18 s. The last spin stops on finalKey with a
--              1.2 -> 1 pop and a rarity flash, and stays until B swaps the real model at touchdown.
--   Landing    {rarity, zone}             target = egg: dust ring + 40-stud rarity light pillar (1.5 s)
--   LegsSprout {}                         target = egg: stubby legs (+ arms for Rare+) pop out with
--              squash/stretch, then the egg shakes off dust. Adds Motor6Ds LegL/LegR (ArmL/ArmR)
--              under the egg's Root so Anim "EggRun"/"EggCarried" can drive them.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Pets = require(Config:WaitForChild("Pets"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Zones = require(Config:WaitForChild("Zones"))
local Rig = require(Shared:WaitForChild("Anim"):WaitForChild("Rig"))
local Pool = require(script.Parent.Pool)
local Burst = require(script.Parent.Burst)
local Shake = require(script.Parent.Shake)
local Themes = require(script.Parent.Themes)

local Egg = {}

local SWAP_FAST, SWAP_SLOW = 0.07, 0.18
local HIP = 1.15 -- body lift once the legs are out
local LEG_COLOR, FOOT_COLOR = Color3.fromRGB(255, 165, 50), Color3.fromRGB(255, 130, 40)

local function rarityOfKey(key: string?): string
	if key then
		for _, p in Pets do
			if p.model == key then
				return p.rarity
			end
		end
	end
	return "Common"
end

local function keyOfModel(model: Instance): string?
	local name = model.Name
	return if string.sub(name, -3) == "Egg" then string.sub(name, 1, -4) else nil
end

local function posOf(target: Instance?): Vector3?
	if target and target:IsA("Model") then
		return target:GetPivot().Position
	elseif target and target:IsA("BasePart") then
		return target.Position
	end
	return nil
end

local function flash(pos: Vector3, color: Color3, size: number, seconds: number)
	local ball = Pool.get("Ball")
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.one * size * 0.3
	ball.CFrame = CFrame.new(pos)
	ball.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = size * 2
	light.Brightness = 4
	light.Parent = ball
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ball, info, { Size = Vector3.one * size, Transparency = 1 }):Play()
	TweenService:Create(light, info, { Brightness = 0 }):Play()
	task.delay(seconds + 0.05, Pool.release, ball)
end

local function hideLocally(model: Model, hidden: boolean, except: Instance?)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not (except and d:IsDescendantOf(except)) then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

function Egg.KickImpact(target: Instance?, params: { [string]: any })
	local pos = posOf(target) or Vector3.new(0, 1, 0)
	local power = math.clamp((params.power or 1) / 25, 0.3, 1)
	Burst.play(
		pos + Vector3.new(0, 1, 0),
		10,
		{ Color3.fromRGB(255, 230, 80), Color3.new(1, 1, 1) },
		NumberRange.new(0.3, 0.7),
		26 * (0.6 + power),
		0.7,
		false,
		true
	)
	flash(pos, Color3.fromRGB(255, 240, 160), 6 + 4 * power, 0.3)
	Shake.impulse("Kick", 0.25 + 0.35 * power, 0.25)
end

function Egg.ZoneEnter(target: Instance?, params: { [string]: any })
	local pos = posOf(target)
	local zone = Zones[params.zone or 1]
	if pos and zone then
		Burst.play(pos, 8, { zone.accent, Color3.new(1, 1, 1) }, NumberRange.new(0.3, 0.6), 18, 0.5, false, true)
	end
end

-- Per-egg spin state: visual models built once per key and swapped by parenting.
type SpinState = { visuals: { [string]: Model }, current: Model?, token: number }
local spins: { [Model]: SpinState } = {}

local function visual(state: SpinState, egg: Model, key: string): Model
	local m = state.visuals[key]
	if m then
		return m
	end
	local Models = require(Shared:WaitForChild("Builders"):WaitForChild("Models")) :: any
	local built: Model = Models.egg(key)
	built.Name = "SpinVisual"
	local root = built.PrimaryPart :: BasePart
	root.Anchored = false
	local motor = Instance.new("Motor6D")
	motor.Name = "SpinMotor"
	motor.Part0 = egg.PrimaryPart
	motor.Part1 = root
	motor.Parent = root
	for _, d in built:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery, d.CanTouch, d.CanCollide = false, false, false
			d.Massless = true
		end
	end
	state.visuals[key] = built
	return built
end

local function show(state: SpinState, egg: Model, key: string): Model
	local m = visual(state, egg, key)
	if state.current ~= m then
		if state.current then
			state.current.Parent = nil
		end
		-- Place it first: WeldConstraints lock their offset when the parts enter the workspace.
		m:PivotTo(egg:GetPivot())
		m.Parent = egg
		state.current = m
	end
	return m
end

function Egg.EggSpin(target: Instance?, params: { [string]: any })
	if not (target and target:IsA("Model") and target.PrimaryPart) then
		return
	end
	local egg = target :: Model
	local keys: { string } = params.keys or {}
	local finalKey: string? = params.finalKey
	if #keys == 0 and finalKey then
		keys = { finalKey }
	end
	if #keys == 0 then
		return
	end
	local seconds: number = params.seconds or 0.45

	local state = spins[egg]
	if not state then
		local s: SpinState = { visuals = {}, current = nil, token = 0 }
		state = s
		spins[egg] = s
		egg.Destroying:Connect(function()
			for _, v in s.visuals do
				v:Destroy()
			end
			spins[egg] = nil
		end)
	end
	state.token += 1
	local token = state.token
	hideLocally(egg, true, state.current)

	local index = math.random(1, #keys)
	local current = show(state, egg, keys[index])
	local angle, nextSwap, t0 = 0, 0, os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		if state.token ~= token or not egg.Parent then
			conn:Disconnect()
			return
		end
		local f = math.clamp((os.clock() - t0) / seconds, 0, 1)
		angle += dt * (6 + 30 * (1 - f) ^ 2)
		if os.clock() - t0 >= nextSwap and f < 1 then
			index = index % #keys + 1
			current = show(state, egg, keys[index])
			hideLocally(egg, true, current)
			nextSwap = (os.clock() - t0) + SWAP_FAST + (SWAP_SLOW - SWAP_FAST) * f * f
		end
		local motor = (current.PrimaryPart :: BasePart):FindFirstChild("SpinMotor") :: Motor6D
		if f < 1 then
			motor.C0 = CFrame.Angles(0, angle, 0)
			return
		end
		conn:Disconnect()
		motor.C0 = CFrame.identity
		if not finalKey then
			return
		end
		-- Final stop: land on finalKey, pop 1.2 -> 1 and flash in the rarity colour.
		current = show(state, egg, finalKey)
		hideLocally(egg, true, current)
		local rarity = Rarities[rarityOfKey(finalKey)] or Rarities.Common
		local pivot = egg:GetPivot().Position + Vector3.new(0, 2, 0)
		flash(pivot, rarity.color, 9, 0.4)
		local popT0 = os.clock()
		local popConn: RBXScriptConnection
		popConn = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - popT0) / 0.3, 0, 1)
			local s = 1.70158
			local back = 1 + (s + 1) * (k - 1) ^ 3 + s * (k - 1) ^ 2 -- Back out, 0 -> 1
			if current.Parent then
				current:ScaleTo(1.2 - 0.2 * back)
			end
			if k >= 1 then
				popConn:Disconnect()
				if current.Parent then
					current:ScaleTo(1)
				end
			end
		end)
	end)
end

function Egg.Landing(target: Instance?, params: { [string]: any })
	local pos = posOf(target)
	if not pos then
		return
	end
	local ground = Vector3.new(pos.X, 0.3, pos.Z)
	local rarity = Rarities[params.rarity or "Common"] or Rarities.Common
	local zone = Zones[params.zone or 1]
	local dustColor = if zone then zone.ground:Lerp(Color3.new(1, 1, 1), 0.45) else Color3.new(1, 1, 1)

	-- Dust ring: a flat smoke puff plus bricky chunks sliding out along the ground.
	local puff = Pool.anchor(CFrame.new(ground), Vector3.new(5, 0.2, 5))
	local e = Instance.new("ParticleEmitter")
	e.Texture = Themes.SMOKE
	e.Color = ColorSequence.new(dustColor)
	e.Size = NumberSequence.new(2.5, 6)
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Lifetime = NumberRange.new(0.6, 1)
	e.Speed = NumberRange.new(14, 20)
	e.SpreadAngle = Vector2.new(85, 85)
	e.Drag = 4
	e.Rate = 0
	e.Parent = puff
	e:Emit(28)
	task.delay(1.2, Pool.release, puff)
	Burst.play(ground, 10, { dustColor, dustColor:Lerp(Color3.new(0, 0, 0), 0.2) }, NumberRange.new(0.4, 0.9), 14, 0.6)

	-- Rarity light pillar: a 40-stud beam that fades over 1.5 s.
	local base = Pool.anchor(CFrame.new(ground))
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a1.Position = Vector3.new(0, 40, 0)
	a0.Parent, a1.Parent = base, base
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Color = ColorSequence.new(rarity.color)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Width0, beam.Width1 = 6, 3
	beam.Brightness = 4
	beam.Segments = 1
	beam.Parent = base
	-- Solid Neon core so the pillar reads in daylight.
	local core = Pool.get("Cylinder")
	core.Material = Enum.Material.Neon
	core.Color = rarity.color
	core.Size = Vector3.new(40, 1.4, 1.4)
	core.CFrame = CFrame.new(ground + Vector3.new(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90))
	core.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Range = 18
	light.Brightness = 3
	light.Parent = base
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / 1.5
		if k >= 1 then
			conn:Disconnect()
			Pool.release(base)
			Pool.release(core)
			return
		end
		beam.Transparency = NumberSequence.new(0.9 * k, 1)
		core.Transparency = 0.2 + 0.8 * k
		core.Size = Vector3.new(40, 1.4 * (1 - 0.6 * k), 1.4 * (1 - 0.6 * k))
		light.Brightness = 3 * (1 - k)
	end)
end

local function limb(
	parent: Model,
	root: BasePart,
	name: string,
	size: Vector3,
	c0: CFrame,
	hang: number,
	color: Color3
): (Motor6D, BasePart)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
	p.Anchored = false
	p.CFrame = root.CFrame * c0 * CFrame.new(0, -hang, 0)
	p.Parent = parent
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0, m.Part1 = root, p
	m.C0 = c0
	m.C1 = CFrame.new(0, hang, 0) -- pivot at the top of the limb (hip/shoulder)
	m.Parent = root
	return m, p
end

function Egg.LegsSprout(target: Instance?, _params: { [string]: any })
	if not (target and target:IsA("Model") and target.PrimaryPart) or target:GetAttribute("Legs") then
		return
	end
	local egg = target :: Model
	egg:SetAttribute("Legs", true)
	local root = egg.PrimaryPart :: BasePart
	local motors = Rig.motors(egg)
	local body = motors.Body
	local key = keyOfModel(egg)
	local rare = (Rarities[rarityOfKey(key)] or Rarities.Common).order >= Rarities.Rare.order

	-- Legs start tucked under the ground and push the egg up.
	local legs: { Motor6D } = {}
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local m, leg =
			limb(egg, root, "Leg" .. s, Vector3.new(0.55, 0.9, 0.55), CFrame.new(side * 0.6, 0, 0), 0.45, LEG_COLOR)
		local foot = Instance.new("Part")
		foot.Name = "Foot" .. s
		foot.Size = Vector3.new(0.8, 0.35, 1.1)
		foot.Color = FOOT_COLOR
		foot.Material = Enum.Material.SmoothPlastic
		foot.CanCollide, foot.CanQuery, foot.CanTouch, foot.Massless = false, false, false, true
		foot.CFrame = leg.CFrame * CFrame.new(0, -0.45 + 0.175 - 0.1, -0.15)
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = leg, foot
		weld.Parent = foot
		foot.Parent = egg
		table.insert(legs, m)
	end
	local arms: { Motor6D } = {}
	if rare then
		for _, side in { -1, 1 } do
			local s = if side < 0 then "L" else "R"
			local m =
				limb(egg, root, "Arm" .. s, Vector3.new(0.4, 0.9, 0.4), CFrame.new(side * 1.55, 1.7, 0), 0.4, LEG_COLOR)
			table.insert(arms, m)
		end
	end

	-- Squash (dip) -> stretch (Back overshoot up to HIP) -> settle -> shake off dust.
	local bodyBase = if body then Rig.base(body) else CFrame.identity
	local pos = egg:GetPivot().Position
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if not egg.Parent then
			conn:Disconnect()
			return
		end
		local t = os.clock() - t0
		local lift, roll
		if t < 0.12 then
			lift, roll = -0.25 * (t / 0.12), 0
		elseif t < 0.5 then
			local k = (t - 0.12) / 0.38
			local s = 2.2
			local back = 1 + (s + 1) * (k - 1) ^ 3 + s * (k - 1) ^ 2
			lift, roll = -0.25 + (HIP + 0.25) * back, 0
		elseif t < 1.0 then
			local k = (t - 0.5) / 0.5
			lift, roll = HIP, math.sin(k * math.pi * 6) * math.rad(12) * (1 - k)
		else
			conn:Disconnect()
			if body then
				Rig.setBase(body, bodyBase * CFrame.new(0, HIP, 0))
				Rig.reset(body)
			end
			for _, m in legs do
				Rig.setBase(m, m.C0)
			end
			for _, m in arms do
				Rig.setBase(m, m.C0)
			end
			return
		end
		if body then
			body.C0 = bodyBase * CFrame.new(0, lift, 0) * CFrame.Angles(0, 0, roll)
		end
		local hip = math.max(0, lift)
		for i, m in legs do
			local side = if i == 1 then -1 else 1
			m.C0 = CFrame.new(side * 0.6, hip, 0)
		end
		for i, m in arms do -- shoulders ride with the body, arms flick out as it lands
			local side = if i == 1 then -1 else 1
			m.C0 = CFrame.new(side * 1.55, hip + 1.7, 0)
				* CFrame.Angles(0, 0, side * math.rad(25) * math.clamp(hip / HIP, 0, 1))
		end
	end)
	task.delay(0.5, function()
		if egg.Parent then
			Burst.play(
				pos + Vector3.new(0, 2, 0),
				8,
				{ Color3.fromRGB(230, 220, 200) },
				NumberRange.new(0.25, 0.5),
				12,
				0.6
			)
		end
	end)
end

return Egg
