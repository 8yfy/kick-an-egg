--!strict
-- Map v3: every zone has its own landing signature (client only, called from Egg.Landing).
-- A shockwave ring in the zone accent, a themed particle burst, brick debris in the zone colours,
-- a light flash and a camera thump that grows with the zone (zone 20 hits hardest).
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Zones = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Zones"))
local Pool = require(script.Parent.Pool)
local Burst = require(script.Parent.Burst)
local Fx = require(script.Parent.Fx)
local Shake = require(script.Parent.Shake)

local ZoneLanding = {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local rgb = Color3.fromRGB
local UP = CFrame.Angles(0, 0, math.rad(90))

type Theme = {
	texture: string, -- particle texture for the burst
	colors: { Color3 }, -- particle colours
	count: number,
	speed: number,
	rise: number, -- particle acceleration Y (+ floats up, - falls)
	size: number,
	debris: { Color3 }?, -- brick pieces (petals, leaves, candy, shards...); zone colours if nil
	pieces: number?,
	doubleRing: boolean?,
	flat: boolean?, -- debris as flat flakes (petals, leaves, confetti)
	neon: boolean?, -- glowing debris (embers, crystals, sparks)
}

local THEMES: { [number]: Theme } = {
	[1] = {
		texture = SPARK,
		colors = { rgb(255, 255, 255), rgb(255, 230, 90) },
		count = 30,
		speed = 22,
		rise = -8,
		size = 1.2,
		debris = { rgb(255, 170, 210), rgb(255, 255, 255), rgb(255, 220, 60) },
		pieces = 18,
		flat = true,
	},
	[2] = {
		texture = SMOKE,
		colors = { rgb(245, 220, 160) },
		count = 30,
		speed = 26,
		rise = -10,
		size = 3.5,
		debris = { rgb(255, 240, 220), rgb(240, 200, 150) },
		pieces = 12,
	},
	[3] = {
		texture = SMOKE,
		colors = { rgb(230, 170, 110) },
		count = 18,
		speed = 16,
		rise = -4,
		size = 3,
		debris = { rgb(240, 130, 40), rgb(220, 70, 40), rgb(250, 190, 60) },
		pieces = 24,
		flat = true,
	},
	[4] = {
		texture = SMOKE,
		colors = { rgb(190, 130, 255), rgb(255, 150, 200) },
		count = 30,
		speed = 14,
		rise = 4,
		size = 3,
		doubleRing = true,
	},
	[5] = {
		texture = SMOKE,
		colors = { rgb(240, 200, 120) },
		count = 36,
		speed = 34,
		rise = 6,
		size = 4,
		debris = { rgb(255, 215, 80) },
		pieces = 10,
	},
	[6] = {
		texture = SMOKE,
		colors = { rgb(255, 255, 255), rgb(210, 235, 255) },
		count = 40,
		speed = 24,
		rise = -6,
		size = 4.5,
		debris = { rgb(250, 252, 255), rgb(170, 220, 255) },
		pieces = 14,
	},
	[7] = {
		texture = SPARK,
		colors = { rgb(255, 120, 190), rgb(120, 220, 230), rgb(255, 240, 120) },
		count = 36,
		speed = 26,
		rise = -12,
		size = 1.4,
		debris = { rgb(255, 90, 160), rgb(90, 220, 230), rgb(255, 220, 60), rgb(170, 110, 255) },
		pieces = 26,
		flat = true,
	},
	[8] = {
		texture = SPARK,
		colors = { rgb(200, 240, 255), rgb(150, 220, 255) },
		count = 34,
		speed = 12,
		rise = 14,
		size = 1.6,
		doubleRing = true,
	},
	[9] = {
		texture = FIRE,
		colors = { rgb(255, 150, 40), rgb(255, 80, 20) },
		count = 40,
		speed = 30,
		rise = 10,
		size = 3,
		debris = { rgb(60, 45, 40), rgb(255, 110, 20) },
		pieces = 16,
		neon = true,
	},
	[10] = {
		texture = SPARK,
		colors = { rgb(120, 240, 255), rgb(200, 150, 255) },
		count = 40,
		speed = 30,
		rise = -4,
		size = 1.6,
		debris = { rgb(120, 240, 255), rgb(170, 120, 255) },
		pieces = 20,
		neon = true,
	},
	[11] = {
		texture = SMOKE,
		colors = { rgb(170, 160, 120) },
		count = 24,
		speed = 18,
		rise = -4,
		size = 3.5,
		debris = { rgb(80, 150, 70), rgb(60, 130, 50), rgb(150, 145, 120) },
		pieces = 22,
		flat = true,
	},
	[12] = {
		texture = SPARK,
		colors = { rgb(255, 40, 200), rgb(60, 230, 255) },
		count = 50,
		speed = 40,
		rise = -2,
		size = 1.4,
		doubleRing = true,
	},
	[13] = {
		texture = SMOKE,
		colors = { rgb(140, 255, 120), rgb(200, 255, 200) },
		count = 28,
		speed = 8,
		rise = 10,
		size = 3,
		debris = { rgb(120, 125, 120) },
		pieces = 10,
	},
	[14] = {
		texture = SMOKE,
		colors = { rgb(255, 255, 255) },
		count = 40,
		speed = 18,
		rise = 4,
		size = 5,
		debris = { rgb(255, 255, 255), rgb(255, 250, 230) },
		pieces = 16,
		flat = true,
	},
	[15] = {
		texture = SPARK,
		colors = { rgb(170, 255, 40), rgb(220, 255, 120) },
		count = 36,
		speed = 20,
		rise = -14,
		size = 1.8,
		debris = { rgb(170, 255, 40), rgb(80, 110, 40) },
		pieces = 18,
	},
	[16] = {
		texture = SPARK,
		colors = { rgb(255, 210, 90), rgb(255, 160, 50) },
		count = 44,
		speed = 34,
		rise = -20,
		size = 1.2,
		debris = { rgb(230, 180, 60), rgb(200, 110, 60), rgb(90, 80, 70) },
		pieces = 16,
		neon = true,
	},
	[17] = {
		texture = SPARK,
		colors = { rgb(120, 255, 200), rgb(110, 190, 255), rgb(190, 130, 255) },
		count = 44,
		speed = 22,
		rise = 6,
		size = 1.6,
		debris = { rgb(200, 235, 250) },
		pieces = 14,
		doubleRing = true,
	},
	[18] = {
		texture = FIRE,
		colors = { rgb(255, 170, 40), rgb(255, 90, 20) },
		count = 56,
		speed = 38,
		rise = 12,
		size = 3.4,
		debris = { rgb(35, 25, 35), rgb(255, 130, 30) },
		pieces = 22,
		doubleRing = true,
		neon = true,
	},
	[19] = {
		texture = SPARK,
		colors = { rgb(255, 255, 255), rgb(170, 120, 255), rgb(255, 200, 120) },
		count = 60,
		speed = 34,
		rise = 0,
		size = 1.6,
		doubleRing = true,
	},
	[20] = {
		texture = SPARK,
		colors = { rgb(255, 120, 200), rgb(255, 230, 120), rgb(120, 220, 255) },
		count = 70,
		speed = 36,
		rise = -6,
		size = 1.8,
		debris = { rgb(255, 90, 90), rgb(255, 210, 60), rgb(90, 220, 120), rgb(70, 160, 255), rgb(190, 110, 255) },
		pieces = 30,
		doubleRing = true,
		flat = true,
		neon = true,
	},
}

-- Flat neon disc that grows to `diameter` and fades out.
local function shockwave(ground: Vector3, color: Color3, diameter: number, seconds: number, delay: number)
	task.delay(delay, function()
		local ring = Pool.get("Cylinder")
		ring.Material = Enum.Material.Neon
		ring.Color = color
		ring.Transparency = 0.15
		ring.Size = Vector3.new(0.2, 2, 2)
		ring.CFrame = CFrame.new(ground + Vector3.new(0, 0.15, 0)) * UP
		local tween = TweenService:Create(
			ring,
			TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, diameter, diameter), Transparency = 1 }
		)
		tween.Completed:Once(function()
			Pool.release(ring)
		end)
		tween:Play()
	end)
end

local function particles(ground: Vector3, theme: Theme)
	local anchor = Pool.anchor(CFrame.new(ground + Vector3.new(0, 1, 0)), Vector3.new(4, 0.2, 4))
	local e = Instance.new("ParticleEmitter")
	e.Texture = theme.texture
	local colors = theme.colors
	e.Color = if #colors > 1 then ColorSequence.new(colors[1], colors[#colors]) else ColorSequence.new(colors[1])
	e.Size = NumberSequence.new(theme.size, theme.size * 1.6)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.8, 1.4)
	e.Speed = NumberRange.new(theme.speed * 0.6, theme.speed)
	e.SpreadAngle = Vector2.new(70, 70)
	e.Acceleration = Vector3.new(0, theme.rise, 0)
	e.Drag = 2
	e.RotSpeed = NumberRange.new(-180, 180)
	e.LightEmission = if theme.texture == SMOKE then 0 else 0.7
	e.Rate = 0
	e.Parent = anchor
	e:Emit(theme.count)
	task.delay(1.6, Pool.release, anchor)
end

-- Plays zone `zoneId`'s landing signature at `ground` (the egg's touchdown point).
function ZoneLanding.play(ground: Vector3, zoneId: number?)
	local id = math.clamp(zoneId or 1, 1, #Zones)
	local zone = Zones[id]
	local theme = THEMES[id] or THEMES[1]
	local strength = (id - 1) / (#Zones - 1) -- 0 for zone 1 .. 1 for zone 20

	shockwave(ground, zone.accent, 26 + 30 * strength, 0.55, 0)
	if theme.doubleRing then
		shockwave(ground, zone.ground:Lerp(Color3.new(1, 1, 1), 0.3), 16 + 20 * strength, 0.5, 0.12)
	end
	particles(ground, theme)
	Burst.play(
		ground + Vector3.new(0, 0.5, 0),
		theme.pieces or 10,
		theme.debris or { zone.ground, zone.accent },
		NumberRange.new(0.4, 1.1),
		22 + 18 * strength,
		1,
		theme.flat,
		theme.neon
	)
	Fx.flash(ground + Vector3.new(0, 2, 0), zone.accent, 10 + 14 * strength, 0.35)
	Shake.impulse("ZoneLanding", 0.25 + 0.6 * strength, 0.35 + 0.3 * strength)
end

return ZoneLanding
