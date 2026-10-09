--!strict
-- Partner A. Looping pet overlays for VFX.attach(name, pet) -> cleanup().
-- Weather names are Config/Mutations.Weather[*].vfx:
--   SunRays      warm tint, orbiting crown of golden Neon cubes, golden sparkles, warm light
--   RainDrops    little rain cloud overhead, falling drops, wet sheen (reflectance)
--   Frost        icy tint, frost crust plates on the top parts, drifting flakes
--   Lightning    crackling Neon arcs flickering around the pet + light flashes
--   Stardust     purple tint, falling Neon stars, purple shimmer
--   RainbowShift hue-cycling outline (Highlight) + a rainbow-trailed cube orbiting the pet
-- Plus "IncomeLabel": floating "$X/s" that follows the pet's "Income" attribute (set by B).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Mutations = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Mutations"))
local Pool = require(script.Parent.Pool)
local Fx = require(script.Parent.Fx)

local Weather = {}

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local rng = Random.new()

type Cleanup = () -> ()

local function bodyParts(model: Model): { BasePart }
	local out = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" and d.Transparency < 1 then
			table.insert(out, d)
		end
	end
	return out
end

-- Lerp every part toward `color`; returns a restore function.
local function tint(model: Model, color: Color3?, amount: number): Cleanup
	if not color then
		return function() end
	end
	local saved: { [BasePart]: Color3 } = {}
	for _, p in bodyParts(model) do
		if p.Material ~= Enum.Material.Neon then
			saved[p] = p.Color
			p.Color = p.Color:Lerp(color, amount)
		end
	end
	return function()
		for p, c in saved do
			p.Color = c
		end
	end
end

local function emitter(model: Model, props: { [string]: any }): Cleanup
	local root = model.PrimaryPart
	if not root then
		return function() end
	end
	local _, size = model:GetBoundingBox()
	local a = Instance.new("Attachment")
	a.Name = "WeatherFx"
	a.Position = Vector3.new(0, size.Y * (props.height or 0.6), 0)
	a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Texture = props.texture or SPARK
	e.Color = ColorSequence.new(props.color)
	e.Size = props.size or NumberSequence.new(0.4, 0)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = props.lifetime or NumberRange.new(0.8, 1.4)
	e.Speed = props.speed or NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = props.rate or 6
	e.LightEmission = props.lightEmission or 0.8
	e.Acceleration = props.acceleration or Vector3.zero
	e.Parent = a
	if props.squash then
		e.Squash = props.squash
	end
	if props.direction then
		e.EmissionDirection = props.direction
		e.SpreadAngle = Vector2.new(5, 5)
	end
	return function()
		a:Destroy()
	end
end

local function light(model: Model, color: Color3, brightness: number, range: number): (PointLight?, Cleanup)
	local root = model.PrimaryPart
	if not root then
		return nil, function() end
	end
	local l = Instance.new("PointLight")
	l.Name = "WeatherLight"
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = false
	l.Parent = root
	return l, function()
		l:Destroy()
	end
end

-- Per-frame driver; `fn(t, pivot, size)` positions the overlay's parts.
local function every(model: Model, fn: (t: number, pivot: CFrame, size: Vector3) -> ()): Cleanup
	local conn = RunService.RenderStepped:Connect(function()
		if model.Parent then
			local cf, size = model:GetBoundingBox()
			fn(os.clock(), cf, size)
		end
	end)
	return function()
		conn:Disconnect()
	end
end

local function combine(list: { Cleanup }): Cleanup
	return function()
		for _, c in list do
			c()
		end
	end
end

local function neonCube(color: Color3, s: number): BasePart
	local p = Pool.get("Block")
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.one * s
	return p
end

function Weather.SunRays(model: Model): Cleanup
	local gold = Color3.fromRGB(255, 205, 70)
	local cubes = {}
	for i = 1, 6 do
		cubes[i] = neonCube(gold, 0.35)
	end
	local _, lightOff = light(model, Color3.fromRGB(255, 200, 120), 1.2, 10)
	return combine({
		tint(model, Mutations.Weather.Sunny.tint, 0.25),
		emitter(model, { color = gold, rate = 6, size = NumberSequence.new(0.35, 0) }),
		lightOff,
		every(model, function(t, cf, size)
			local r = math.max(size.X, size.Z) * 0.35 + 0.4
			for i, c in cubes do
				local a = t * 1.2 + i * math.pi / 3
				c.CFrame = CFrame.new(
					cf.Position
						+ Vector3.new(math.cos(a) * r, size.Y / 2 + 0.7 + math.sin(t * 3 + i) * 0.1, math.sin(a) * r)
				) * CFrame.Angles(t * 2, t * 3, 0)
			end
		end),
		function()
			for _, c in cubes do
				Pool.release(c)
			end
		end,
	})
end

function Weather.RainDrops(model: Model): Cleanup
	local grey = Color3.fromRGB(150, 160, 180)
	local puffs = {}
	for i = 1, 3 do
		local p = Pool.get("Block")
		p.Color = grey:Lerp(Color3.new(1, 1, 1), (i - 1) * 0.15)
		puffs[i] = p
	end
	local sheen: { [BasePart]: number } = {}
	for _, p in bodyParts(model) do
		sheen[p] = p.Reflectance
		p.Reflectance = 0.25
	end
	local cloudAnchor = Pool.anchor(CFrame.new(), Vector3.new(1.5, 0.2, 1.5))
	local rain = Instance.new("ParticleEmitter")
	rain.Color = ColorSequence.new(Color3.fromRGB(120, 180, 255))
	rain.Size = NumberSequence.new(0.12)
	rain.Squash = NumberSequence.new(-1.5)
	rain.Transparency = NumberSequence.new(0.2, 0.6)
	rain.Lifetime = NumberRange.new(0.35, 0.5)
	rain.Speed = NumberRange.new(12, 14)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.SpreadAngle = Vector2.new(4, 4)
	rain.Rate = 24
	rain.Parent = cloudAnchor
	return combine({
		every(model, function(t, cf, size)
			local top = cf.Position + Vector3.new(0, size.Y / 2 + 1.6 + math.sin(t * 1.5) * 0.15, 0)
			local w = math.max(size.X, size.Z) * 0.45 + 0.6
			puffs[1].Size = Vector3.new(w, 0.7, w * 0.7)
			puffs[1].CFrame = CFrame.new(top)
			puffs[2].Size = Vector3.new(w * 0.6, 0.6, w * 0.5)
			puffs[2].CFrame = CFrame.new(top + Vector3.new(w * 0.35, 0.35, 0.1))
			puffs[3].Size = Vector3.new(w * 0.5, 0.5, w * 0.45)
			puffs[3].CFrame = CFrame.new(top + Vector3.new(-w * 0.3, 0.3, -0.1))
			cloudAnchor.Size = Vector3.new(w * 0.9, 0.2, w * 0.6)
			cloudAnchor.CFrame = CFrame.new(top - Vector3.new(0, 0.4, 0))
		end),
		function()
			for p, r in sheen do
				p.Reflectance = r
			end
			for _, p in puffs do
				Pool.release(p)
			end
			Pool.release(cloudAnchor)
		end,
	})
end

function Weather.Frost(model: Model): Cleanup
	-- Crust: thin white plates welded on top of the highest parts.
	local parts = bodyParts(model)
	table.sort(parts, function(a, b)
		return a.Position.Y + a.Size.Y / 2 > b.Position.Y + b.Size.Y / 2
	end)
	local crust = {}
	for i = 1, math.min(5, #parts) do
		local p = parts[i]
		if p.Material ~= Enum.Material.Neon then
			local c = Instance.new("Part")
			c.Name = "FrostCrust"
			c.Size = Vector3.new(p.Size.X * 0.9, 0.12, p.Size.Z * 0.9)
			c.Color = Color3.fromRGB(240, 250, 255)
			c.Material = Enum.Material.Glass
			c.Transparency = 0.15
			c.CanCollide, c.CanQuery, c.CanTouch, c.Massless = false, false, false, true
			c.CFrame = p.CFrame * CFrame.new(0, p.Size.Y / 2 + 0.05, 0)
			c.Parent = model
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = p, c
			w.Parent = c
			table.insert(crust, c)
		end
	end
	return combine({
		tint(model, Mutations.Weather.Snowy.tint, 0.35),
		emitter(model, {
			color = Color3.fromRGB(240, 250, 255),
			rate = 8,
			size = NumberSequence.new(0.3, 0.15),
			speed = NumberRange.new(0.5, 1),
			acceleration = Vector3.new(0, -1.5, 0),
			height = 1,
			lightEmission = 0.3,
		}),
		function()
			for _, c in crust do
				c:Destroy()
			end
		end,
	})
end

function Weather.Lightning(model: Model): Cleanup
	local arc = {
		neonCube(Color3.fromRGB(170, 230, 255), 0.15),
		neonCube(Color3.fromRGB(170, 230, 255), 0.15),
		neonCube(Color3.fromRGB(170, 230, 255), 0.15),
	}
	local flashLight, lightOff = light(model, Color3.fromRGB(170, 220, 255), 0, 12)
	local nextArc, arcUntil = 0, 0
	return combine({
		emitter(model, { color = Color3.fromRGB(150, 220, 255), rate = 5, size = NumberSequence.new(0.25, 0) }),
		lightOff,
		every(model, function(t, cf, size)
			if t >= nextArc then
				nextArc = t + rng:NextNumber(0.4, 1.0)
				arcUntil = t + 0.09
				-- zig-zag between two random points on the pet's bounding box
				local function onBox(): Vector3
					return cf.Position
						+ Vector3.new(
							rng:NextNumber(-0.6, 0.6) * size.X,
							rng:NextNumber(-0.2, 0.6) * size.Y,
							rng:NextNumber(-0.6, 0.6) * size.Z
						)
				end
				local a, b = onBox(), onBox()
				local mid1 = a:Lerp(b, 0.33)
					+ Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5))
				local mid2 = a:Lerp(b, 0.66)
					+ Vector3.new(rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-0.5, 0.5))
				for i, seg in { { a, mid1 }, { mid1, mid2 }, { mid2, b } } do
					local len = (seg[2] - seg[1]).Magnitude
					arc[i].Size = Vector3.new(0.12, 0.12, math.max(len, 0.1))
					arc[i].CFrame = CFrame.lookAt(seg[1]:Lerp(seg[2], 0.5), seg[2])
					arc[i].Transparency = 0
				end
				if flashLight then
					flashLight.Brightness = 3
				end
			elseif t >= arcUntil then
				for _, s in arc do
					s.Transparency = 1
				end
				if flashLight then
					flashLight.Brightness = math.max(0, flashLight.Brightness - 0.4)
				end
			end
		end),
		function()
			for _, s in arc do
				Pool.release(s)
			end
		end,
	})
end

function Weather.Stardust(model: Model): Cleanup
	local purple = Color3.fromRGB(190, 150, 255)
	local stars = {}
	for i = 1, 3 do
		stars[i] = {
			part = neonCube(Color3.fromRGB(255, 240, 180), 0.3),
			offset = rng:NextNumber(0, 1),
			x = rng:NextNumber(-0.5, 0.5),
			z = rng:NextNumber(-0.5, 0.5),
		}
	end
	return combine({
		tint(model, Mutations.Weather.Starfall.tint, 0.2),
		emitter(model, { color = purple, rate = 10, size = NumberSequence.new(0.3, 0) }),
		every(model, function(t, cf, size)
			for _, s in stars do
				local k = (t * 0.6 + s.offset) % 1
				local height = size.Y + 3
				s.part.CFrame = CFrame.new(
					cf.Position + Vector3.new(s.x * size.X, height / 2 + 1 - k * height, s.z * size.Z)
				) * CFrame.Angles(0, 0, t * 4)
				s.part.Transparency = if k > 0.85 then (k - 0.85) / 0.15 else 0
			end
		end),
		function()
			for _, s in stars do
				Pool.release(s.part)
			end
		end,
	})
end

function Weather.RainbowShift(model: Model): Cleanup
	local h = Instance.new("Highlight")
	h.Name = "RainbowOutline"
	h.FillTransparency = 1
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = model
	h.Parent = model
	local orb = neonCube(Color3.new(1, 1, 1), 0.4)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 0.2, 0), Vector3.new(0, -0.2, 0)
	a0.Parent, a1.Parent = orb, orb
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.6
	trail.LightEmission = 1
	trail.Transparency = NumberSequence.new(0, 1)
	local keys = {}
	for i = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.7, 1)))
	end
	trail.Color = ColorSequence.new(keys)
	trail.Parent = orb
	return combine({
		every(model, function(t, cf, size)
			local hue = (t * 0.3) % 1
			h.OutlineColor = Color3.fromHSV(hue, 0.8, 1)
			orb.Color = Color3.fromHSV((hue + 0.5) % 1, 0.6, 1)
			local r = math.max(size.X, size.Z) * 0.6 + 0.8
			local a = t * 2.4
			orb.CFrame = CFrame.new(
				cf.Position + Vector3.new(math.cos(a) * r, math.sin(t * 1.7) * size.Y * 0.3, math.sin(a) * r)
			)
		end),
		function()
			h:Destroy()
			Pool.release(orb)
		end,
	})
end

-- Floating "$X/s" over the pet; reads the "Income" attribute (number, $/s after multipliers).
function Weather.IncomeLabel(model: Model): Cleanup
	local root = model.PrimaryPart
	if not root then
		return function() end
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "IncomeLabel"
	gui.Size = UDim2.fromOffset(140, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y + 0.8, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(130, 255, 120)
	local s = Instance.new("UIStroke")
	s.Thickness = 2.5
	s.Color = Color3.fromRGB(20, 60, 20)
	s.Parent = l
	l.Parent = gui
	gui.Adornee = root
	gui.Parent = root
	local function refresh()
		local v = model:GetAttribute("Income")
		l.Text = if typeof(v) == "number" then `${Fx.formatNumber(v)}/s` else ""
	end
	refresh()
	local conn = model:GetAttributeChangedSignal("Income"):Connect(refresh)
	return function()
		conn:Disconnect()
		gui:Destroy()
	end
end

return Weather
