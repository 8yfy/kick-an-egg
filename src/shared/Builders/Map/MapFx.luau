--!strict
-- Partner A. Map particle effects (built once with the map; ParticleEmitters replicate to clients).
-- MapFx.emit(part, preset, overrides?) attaches a ParticleEmitter. Presets cover every Zones.ambient
-- name plus map details (fountain, lamps, kick pad, stations, stalls, safe line).
local MapFx = {}

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local rgb = Color3.fromRGB

export type Preset = {
	texture: string?,
	colors: { Color3 },
	size: { number }, -- start, end
	rate: number,
	life: { number },
	speed: { number },
	accel: Vector3?,
	dir: Enum.NormalId?,
	spread: number?,
	light: number?, -- LightEmission
	transparency: { number }?, -- start, end
	drag: number?,
	rot: number?, -- RotSpeed range
}

local P: { [string]: Preset } = {
	-- zone ambience (falls from a sheet above the canyon floor unless noted)
	Petals = {
		colors = { rgb(255, 170, 210), rgb(255, 255, 255) },
		size = { 0.5, 0.3 },
		rate = 6,
		life = { 4, 6 },
		speed = { 1, 2 },
		accel = Vector3.new(1, -2, 0),
		dir = Enum.NormalId.Bottom,
		rot = 90,
	},
	Bubbles = {
		colors = { rgb(190, 235, 255) },
		size = { 0.4, 0.7 },
		rate = 6,
		life = { 4, 6 },
		speed = { 2, 3 },
		accel = Vector3.new(0, 1, 0),
		dir = Enum.NormalId.Top,
		light = 0.3,
	},
	Leaves = {
		colors = { rgb(240, 130, 40), rgb(220, 70, 40), rgb(250, 200, 70) },
		size = { 0.6, 0.4 },
		rate = 6,
		life = { 4, 6 },
		speed = { 1, 2 },
		accel = Vector3.new(1.5, -2, 0),
		dir = Enum.NormalId.Bottom,
		rot = 120,
	},
	Spores = {
		colors = { rgb(200, 140, 255), rgb(255, 120, 120) },
		size = { 0.3, 0.5 },
		rate = 7,
		life = { 4, 6 },
		speed = { 0.5, 1 },
		accel = Vector3.new(0, 0.6, 0),
		dir = Enum.NormalId.Top,
		light = 0.7,
	},
	Sand = {
		texture = SMOKE,
		colors = { rgb(240, 210, 150) },
		size = { 2, 4 },
		rate = 4,
		life = { 3, 4 },
		speed = { 6, 9 },
		accel = Vector3.new(4, -1, 0),
		dir = Enum.NormalId.Bottom,
		transparency = { 0.6, 1 },
	},
	Snow = {
		colors = { rgb(255, 255, 255) },
		size = { 0.4, 0.3 },
		rate = 10,
		life = { 5, 7 },
		speed = { 1, 2 },
		accel = Vector3.new(0.5, -2, 0),
		dir = Enum.NormalId.Bottom,
	},
	Sprinkles = {
		colors = { rgb(255, 120, 180), rgb(120, 220, 255), rgb(255, 230, 90), rgb(140, 255, 140) },
		size = { 0.35, 0.35 },
		rate = 8,
		life = { 4, 5 },
		speed = { 1, 2 },
		accel = Vector3.new(0, -3, 0),
		dir = Enum.NormalId.Bottom,
		rot = 200,
	},
	Embers = {
		texture = FIRE,
		colors = { rgb(255, 160, 40), rgb(255, 80, 20) },
		size = { 0.5, 0.1 },
		rate = 10,
		life = { 3, 5 },
		speed = { 2, 4 },
		accel = Vector3.new(0, 2, 0),
		dir = Enum.NormalId.Top,
		light = 1,
	},
	Sparkles = {
		colors = { rgb(140, 245, 255), rgb(220, 160, 255) },
		size = { 0.4, 0 },
		rate = 10,
		life = { 2, 3 },
		speed = { 0.3, 0.6 },
		dir = Enum.NormalId.Top,
		light = 1,
	},
	Fireflies = {
		colors = { rgb(220, 255, 120) },
		size = { 0.3, 0.3 },
		rate = 6,
		life = { 4, 6 },
		speed = { 0.5, 1 },
		accel = Vector3.new(0, 0.3, 0),
		dir = Enum.NormalId.Top,
		light = 1,
		spread = 180,
	},
	Neon = {
		colors = { rgb(255, 60, 220), rgb(60, 230, 255) },
		size = { 0.35, 0 },
		rate = 10,
		life = { 2, 3 },
		speed = { 1, 2 },
		dir = Enum.NormalId.Top,
		light = 1,
	},
	Wisps = {
		texture = SMOKE,
		colors = { rgb(150, 255, 130) },
		size = { 1.5, 3 },
		rate = 3,
		life = { 4, 6 },
		speed = { 0.5, 1 },
		accel = Vector3.new(0, 0.5, 0),
		dir = Enum.NormalId.Top,
		light = 0.5,
		transparency = { 0.6, 1 },
	},
	Clouds = {
		texture = SMOKE,
		colors = { rgb(255, 255, 255) },
		size = { 4, 7 },
		rate = 2,
		life = { 6, 8 },
		speed = { 1, 2 },
		accel = Vector3.new(1, 0, 0),
		dir = Enum.NormalId.Top,
		transparency = { 0.5, 1 },
	},
	ToxicBubbles = {
		colors = { rgb(170, 255, 40) },
		size = { 0.5, 0.8 },
		rate = 8,
		life = { 3, 4 },
		speed = { 1.5, 2.5 },
		accel = Vector3.new(0, 1, 0),
		dir = Enum.NormalId.Top,
		light = 0.6,
	},
	Steam = {
		texture = SMOKE,
		colors = { rgb(235, 235, 235) },
		size = { 2, 5 },
		rate = 4,
		life = { 3, 4 },
		speed = { 3, 5 },
		dir = Enum.NormalId.Top,
		transparency = { 0.5, 1 },
	},
	Aurora = {
		colors = { rgb(120, 255, 200), rgb(140, 160, 255) },
		size = { 0.5, 0 },
		rate = 10,
		life = { 3, 5 },
		speed = { 0.3, 0.6 },
		dir = Enum.NormalId.Top,
		light = 1,
	},
	Magma = {
		texture = FIRE,
		colors = { rgb(255, 170, 40), rgb(255, 60, 20) },
		size = { 0.8, 0.1 },
		rate = 12,
		life = { 2, 4 },
		speed = { 3, 5 },
		accel = Vector3.new(0, 1, 0),
		dir = Enum.NormalId.Top,
		light = 1,
	},
	Stars = {
		colors = { rgb(255, 255, 255), rgb(200, 170, 255) },
		size = { 0.35, 0 },
		rate = 10,
		life = { 3, 5 },
		speed = { 0.2, 0.4 },
		dir = Enum.NormalId.Top,
		light = 1,
		spread = 180,
	},
	Rainbow = {
		colors = { rgb(255, 120, 120), rgb(255, 220, 100), rgb(120, 255, 140), rgb(120, 180, 255), rgb(220, 140, 255) },
		size = { 0.4, 0 },
		rate = 10,
		life = { 3, 4 },
		speed = { 0.5, 1 },
		dir = Enum.NormalId.Top,
		light = 1,
	},
	-- map details
	FountainJet = {
		colors = { rgb(170, 225, 255), rgb(255, 255, 255) },
		size = { 0.75, 0.4 },
		rate = 90,
		life = { 1, 1.3 },
		speed = { 14, 17 },
		accel = Vector3.new(0, -26, 0),
		dir = Enum.NormalId.Top,
		spread = 14,
		light = 0.4,
	},
	FountainSplash = {
		texture = SMOKE,
		colors = { rgb(220, 240, 255) },
		size = { 1, 2.4 },
		rate = 10,
		life = { 0.6, 0.9 },
		speed = { 2, 3 },
		dir = Enum.NormalId.Top,
		spread = 60,
		transparency = { 0.5, 1 },
	},
	FountainSparkle = {
		colors = { rgb(200, 240, 255) },
		size = { 0.3, 0 },
		rate = 8,
		life = { 1, 2 },
		speed = { 0.2, 0.5 },
		dir = Enum.NormalId.Top,
		light = 1,
		spread = 180,
	},
	Firefly = {
		colors = { rgb(255, 240, 150) },
		size = { 0.22, 0.22 },
		rate = 0.8,
		life = { 3, 5 },
		speed = { 0.4, 0.8 },
		dir = Enum.NormalId.Top,
		spread = 180,
		light = 1,
	},
	PadRise = {
		colors = { rgb(255, 230, 90), rgb(255, 255, 255) },
		size = { 0.4, 0 },
		rate = 14,
		life = { 1.2, 1.8 },
		speed = { 3, 5 },
		dir = Enum.NormalId.Top,
		spread = 4,
		light = 1,
	},
	SafeShimmer = {
		colors = { rgb(120, 210, 255), rgb(255, 255, 255) },
		size = { 0.3, 0 },
		rate = 10,
		life = { 1, 1.6 },
		speed = { 1.5, 2.5 },
		dir = Enum.NormalId.Top,
		spread = 5,
		light = 1,
	},
	StallSparkle = {
		colors = { rgb(255, 240, 150), rgb(255, 255, 255) },
		size = { 0.35, 0 },
		rate = 4,
		life = { 1, 1.6 },
		speed = { 0.5, 1 },
		dir = Enum.NormalId.Top,
		spread = 40,
		light = 1,
	},
	LampGlow = {
		colors = { rgb(255, 255, 255) },
		size = { 0.35, 0 },
		rate = 3,
		life = { 0.8, 1.2 },
		speed = { 0.5, 1 },
		dir = Enum.NormalId.Top,
		spread = 40,
		light = 1,
	},
	InfernoEmbers = {
		texture = FIRE,
		colors = { rgb(255, 170, 40), rgb(255, 80, 20) },
		size = { 0.6, 0.1 },
		rate = 8,
		life = { 1, 1.6 },
		speed = { 2, 4 },
		dir = Enum.NormalId.Top,
		spread = 20,
		light = 1,
	},
}

local function seq(colors: { Color3 }): ColorSequence
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
	end
	return ColorSequence.new(keys)
end

-- Attach a preset emitter to `part` (emits from its whole volume). `tint` replaces the colours.
function MapFx.emit(part: BasePart, preset: string, tint: Color3?, rateScale: number?): ParticleEmitter?
	local p = P[preset]
	if not p then
		return nil
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = preset
	e.Texture = p.texture or SPARK
	e.Color = if tint then ColorSequence.new(tint) else seq(p.colors)
	e.Size = NumberSequence.new(p.size[1], p.size[2])
	local t = p.transparency or { 0.1, 1 }
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, t[1]),
		NumberSequenceKeypoint.new(0.7, t[1] + (t[2] - t[1]) * 0.3),
		NumberSequenceKeypoint.new(1, t[2]),
	})
	e.Rate = p.rate * (rateScale or 1)
	e.Lifetime = NumberRange.new(p.life[1], p.life[2])
	e.Speed = NumberRange.new(p.speed[1], p.speed[2])
	e.Acceleration = p.accel or Vector3.zero
	e.EmissionDirection = p.dir or Enum.NormalId.Top
	local s = p.spread or 25
	e.SpreadAngle = Vector2.new(s, s)
	e.LightEmission = p.light or 0
	e.Drag = p.drag or 0
	e.Rotation = NumberRange.new(0, 360)
	if p.rot then
		e.RotSpeed = NumberRange.new(-p.rot, p.rot)
	end
	e.Parent = part
	return e
end

return MapFx
