--!strict
-- Partner A. World ambience VFX with the original sprites (VFX/WorldSprites): area emitters for zones and the hub,
-- waterfalls (beam sheet + mist + splash), the fountain (jets, splash ring, golden sparkles). Every emitter is
-- tagged "WorldFx" with attributes BaseRate and CullDist: the client's WorldLife controller turns emitters off past
-- their cull distance and scales rates down on low graphics quality (VFX/Ambient.luau). Particle counts stay small:
-- rates are per emitter per second at full quality.
local CollectionService = game:GetService("CollectionService")

local Parts = require(script.Parent.Parts)
local Sprites = require(script.Parent.Parent.Parent.Parent.VFX.WorldSprites)

local Fx = {}

local rgb = Color3.fromRGB
export type Preset = {
	tex: string,
	colors: { Color3 },
	size: { number }, -- start, end (or start, mid, end)
	trans: { number }?, -- start, end (or start, mid, end)
	rate: number,
	life: { number },
	speed: { number },
	spread: number?,
	accel: Vector3?,
	drag: number?,
	rot: { number }?, -- Rotation range
	spin: { number }?, -- RotSpeed range
	light: number?, -- LightEmission
	influence: number?, -- LightInfluence
	dir: Enum.NormalId?,
	flip: boolean?, -- 2x2 flipbook
	orient: Enum.ParticleOrientation?,
	cull: number?,
	zoff: number?,
}

local function seq(values: { number }): NumberSequence
	if #values == 1 then
		return NumberSequence.new(values[1])
	elseif #values == 2 then
		return NumberSequence.new(values[1], values[2])
	end
	local kps = {}
	for i, v in values do
		table.insert(kps, NumberSequenceKeypoint.new((i - 1) / (#values - 1), v))
	end
	return NumberSequence.new(kps)
end

local function colorSeq(colors: { Color3 }): ColorSequence
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local kps = {}
	for i, c in colors do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
	end
	return ColorSequence.new(kps)
end

local P: { [string]: Preset } = {
	-- meadow
	Pollen = {
		tex = "softdot",
		colors = { rgb(255, 240, 150) },
		size = { 0.18, 0.3, 0.1 },
		trans = { 0.2, 0.1, 1 },
		rate = 10,
		life = { 5, 8 },
		speed = { 0.3, 0.8 },
		spread = 180,
		accel = Vector3.new(0.4, 0.15, 0),
		light = 0.6,
	},
	Butterflies = {
		tex = "butterfly",
		colors = { rgb(255, 170, 60) },
		size = { 1.1 },
		trans = { 0, 0, 1 },
		rate = 0.8,
		life = { 7, 10 },
		speed = { 1.5, 3 },
		spread = 180,
		accel = Vector3.new(0, 0.25, 0),
		drag = 0.4,
		flip = true,
		cull = 160,
	},
	Blossoms = {
		tex = "blossom",
		colors = { rgb(255, 190, 220), rgb(255, 255, 255) },
		size = { 0.45, 0.35 },
		trans = { 0, 0, 1 },
		rate = 4,
		life = { 6, 9 },
		speed = { 0.5, 1.2 },
		spread = 60,
		accel = Vector3.new(0.8, -0.9, 0.2),
		rot = { 0, 360 },
		spin = { -90, 90 },
		dir = Enum.NormalId.Bottom,
	},
	-- beach
	SeaMist = {
		tex = "mist",
		colors = { rgb(235, 248, 255) },
		size = { 6, 10 },
		trans = { 1, 0.82, 1 },
		rate = 1.2,
		life = { 8, 12 },
		speed = { 0.5, 1.2 },
		spread = 40,
		accel = Vector3.new(0.6, 0.05, 0),
		influence = 0.6,
		cull = 260,
	},
	SandGust = {
		tex = "streak",
		colors = { rgb(250, 228, 170) },
		size = { 1.2, 2.2 },
		trans = { 1, 0.45, 1 },
		rate = 2.5,
		life = { 1.4, 2.2 },
		speed = { 10, 16 },
		spread = 8,
		dir = Enum.NormalId.Left,
		orient = Enum.ParticleOrientation.VelocityParallel,
	},
	-- autumn
	Leaves = {
		tex = "leaf",
		colors = { rgb(240, 130, 40) },
		size = { 0.6, 0.5 },
		trans = { 0, 0, 1 },
		rate = 5,
		life = { 6, 9 },
		speed = { 0.5, 1.5 },
		spread = 70,
		accel = Vector3.new(1.0, -1.1, 0.3),
		rot = { 0, 360 },
		spin = { -140, 140 },
		dir = Enum.NormalId.Bottom,
	},
	LeavesRed = {
		tex = "leaf",
		colors = { rgb(220, 70, 45) },
		size = { 0.55, 0.45 },
		trans = { 0, 0, 1 },
		rate = 3,
		life = { 6, 9 },
		speed = { 0.5, 1.5 },
		spread = 70,
		accel = Vector3.new(1.0, -1.1, -0.3),
		rot = { 0, 360 },
		spin = { -140, 140 },
		dir = Enum.NormalId.Bottom,
	},
	-- mushroom
	Spores = {
		tex = "spore",
		colors = { rgb(190, 140, 255), rgb(120, 255, 220) },
		size = { 0.25, 0.4, 0.1 },
		trans = { 0.3, 0, 1 },
		rate = 9,
		life = { 5, 8 },
		speed = { 0.4, 1.0 },
		spread = 180,
		accel = Vector3.new(0, 0.35, 0),
		light = 1,
		influence = 0.2,
	},
	GroundMist = {
		tex = "mist",
		colors = { rgb(200, 170, 255) },
		size = { 7, 11 },
		trans = { 1, 0.85, 1 },
		rate = 1,
		life = { 9, 13 },
		speed = { 0.3, 0.8 },
		spread = 90,
		accel = Vector3.new(0.2, 0, 0.1),
		influence = 0.5,
		cull = 220,
	},
	-- generic
	Fireflies = {
		tex = "softdot",
		colors = { rgb(220, 255, 140) },
		size = { 0.3 },
		trans = { 1, 0, 0.2, 1 },
		rate = 3,
		life = { 4, 7 },
		speed = { 0.4, 1 },
		spread = 180,
		accel = Vector3.new(0, 0.1, 0),
		light = 1,
		influence = 0,
		drag = 0.5,
	},
	Sparkle = {
		tex = "sparkle",
		colors = { rgb(255, 245, 190) },
		size = { 0.2, 0.9, 0.1 },
		trans = { 0, 0, 1 },
		rate = 2,
		life = { 0.8, 1.4 },
		speed = { 0, 0.2 },
		spread = 180,
		light = 1,
		influence = 0,
	},
	Dust = {
		tex = "puff",
		colors = { rgb(240, 225, 190) },
		size = { 1.5, 3 },
		trans = { 0.7, 1 },
		rate = 1,
		life = { 3, 5 },
		speed = { 0.3, 0.8 },
		spread = 90,
		accel = Vector3.new(0.3, 0.1, 0),
	},
	-- water
	FallsMist = {
		tex = "mist",
		colors = { rgb(240, 250, 255) },
		size = { 4, 9 },
		trans = { 0.55, 1 },
		rate = 5,
		life = { 2, 3.5 },
		speed = { 2, 5 },
		spread = 60,
		accel = Vector3.new(0, 1.2, 0),
		dir = Enum.NormalId.Top,
		influence = 0.7,
		cull = 260,
	},
	Splash = {
		tex = "softdot",
		colors = { rgb(225, 245, 255) },
		size = { 0.5, 0.2 },
		trans = { 0, 1 },
		rate = 18,
		life = { 0.6, 1.0 },
		speed = { 6, 11 },
		spread = 35,
		accel = Vector3.new(0, -26, 0),
		dir = Enum.NormalId.Top,
	},
	FountainJet = {
		tex = "softdot",
		colors = { rgb(200, 235, 255) },
		size = { 0.7, 0.4 },
		trans = { 0.1, 1 },
		rate = 26,
		life = { 1.0, 1.3 },
		speed = { 15, 17 },
		spread = 7,
		accel = Vector3.new(0, -26, 0),
		dir = Enum.NormalId.Top,
	},
	Ripples = {
		tex = "ring",
		colors = { rgb(235, 250, 255) },
		size = { 0.5, 4 },
		trans = { 0.3, 1 },
		rate = 2.5,
		life = { 1.5, 2 },
		speed = { 0, 0 },
		orient = Enum.ParticleOrientation.VelocityPerpendicular,
		dir = Enum.NormalId.Top,
	},
	-- snow / ice
	Snow = {
		tex = "snowflake",
		colors = { rgb(255, 255, 255) },
		size = { 0.45, 0.35 },
		trans = { 0, 0, 1 },
		rate = 14,
		life = { 6, 9 },
		speed = { 2, 3 },
		spread = 25,
		accel = Vector3.new(0.8, -0.5, 0),
		dir = Enum.NormalId.Bottom,
		rot = { 0, 360 },
		spin = { -60, 60 },
	},
	IcyWind = {
		tex = "streak",
		colors = { rgb(220, 240, 255) },
		size = { 1.2, 2.4 },
		trans = { 1, 0.5, 1 },
		rate = 2.5,
		life = { 1.2, 2 },
		speed = { 14, 20 },
		spread = 6,
		dir = Enum.NormalId.Left,
		orient = Enum.ParticleOrientation.VelocityParallel,
	},
	-- fire
	Embers = {
		tex = "ember",
		colors = { rgb(255, 210, 90), rgb(255, 90, 30) },
		size = { 0.35, 0.1 },
		trans = { 0, 1 },
		rate = 12,
		life = { 3, 5 },
		speed = { 2, 4 },
		spread = 40,
		accel = Vector3.new(0.3, 2, 0),
		light = 1,
		influence = 0,
		dir = Enum.NormalId.Top,
	},
	Ash = {
		tex = "puff",
		colors = { rgb(120, 112, 110) },
		size = { 0.6, 1.2 },
		trans = { 0.5, 1 },
		rate = 4,
		life = { 5, 8 },
		speed = { 0.5, 1 },
		spread = 60,
		accel = Vector3.new(0.4, -0.3, 0),
		dir = Enum.NormalId.Bottom,
		rot = { 0, 360 },
	},
	Steam = {
		tex = "puff",
		colors = { rgb(240, 240, 240) },
		size = { 1.5, 5 },
		trans = { 0.4, 1 },
		rate = 5,
		life = { 2, 3.5 },
		speed = { 4, 7 },
		spread = 12,
		accel = Vector3.new(0.4, 1, 0),
		dir = Enum.NormalId.Top,
		influence = 0.7,
		cull = 260,
	},
	-- water / reef
	Bubbles = {
		tex = "bubble",
		colors = { rgb(200, 245, 255) },
		size = { 0.3, 0.8 },
		trans = { 0.1, 0.1, 1 },
		rate = 8,
		life = { 4, 6 },
		speed = { 1.5, 3 },
		spread = 20,
		accel = Vector3.new(0, 1.5, 0),
		dir = Enum.NormalId.Top,
		light = 0.2,
	},
	-- candy
	CandySprinkles = {
		tex = "sprinkle",
		colors = { rgb(255, 110, 170), rgb(255, 230, 90) },
		size = { 0.3 },
		trans = { 0, 0, 1 },
		rate = 8,
		life = { 5, 8 },
		speed = { 1, 2 },
		spread = 40,
		accel = Vector3.new(0.3, -0.8, 0),
		dir = Enum.NormalId.Bottom,
		rot = { 0, 360 },
		spin = { -120, 120 },
	},
	CandySparkle = {
		tex = "star",
		colors = { rgb(255, 240, 255) },
		size = { 0.2, 0.8, 0.1 },
		trans = { 0, 0, 1 },
		rate = 3,
		life = { 1, 1.6 },
		speed = { 0, 0.3 },
		spread = 180,
		light = 1,
		influence = 0,
	},
	-- desert
	SandSwirl = {
		tex = "puff",
		colors = { rgb(244, 214, 150) },
		size = { 1.5, 4 },
		trans = { 0.5, 1 },
		rate = 2,
		life = { 2, 3.5 },
		speed = { 6, 10 },
		spread = 15,
		dir = Enum.NormalId.Left,
		accel = Vector3.new(0, 0.6, 0),
	},
	HeatGlint = {
		tex = "sparkle",
		colors = { rgb(255, 230, 160) },
		size = { 0.2, 0.7, 0.1 },
		trans = { 0, 0, 1 },
		rate = 2,
		life = { 0.8, 1.2 },
		speed = { 0, 0.2 },
		spread = 180,
		light = 1,
		influence = 0,
	},
	CrystalGlimmer = {
		tex = "glint",
		colors = { rgb(170, 220, 255) },
		size = { 0.2, 1.0, 0.1 },
		trans = { 0, 0, 1 },
		rate = 5,
		life = { 0.8, 1.4 },
		speed = { 0, 0.3 },
		spread = 180,
		light = 1,
		influence = 0,
	},
	JungleMist = {
		tex = "mist",
		colors = { rgb(200, 240, 210) },
		size = { 7, 12 },
		trans = { 1, 0.82, 1 },
		rate = 1.2,
		life = { 9, 13 },
		speed = { 0.3, 0.8 },
		spread = 90,
		accel = Vector3.new(0.2, 0.05, 0.1),
		influence = 0.6,
		cull = 240,
	},
	NeonDrift = {
		tex = "pixel",
		colors = { rgb(255, 80, 210), rgb(80, 230, 255) },
		size = { 0.35, 0.2 },
		trans = { 0.2, 1 },
		rate = 6,
		life = { 3, 5 },
		speed = { 0.6, 1.4 },
		spread = 60,
		accel = Vector3.new(0, 0.6, 0),
		light = 1,
		influence = 0,
		dir = Enum.NormalId.Top,
		rot = { 0, 90 },
	},
	Wisps = {
		tex = "softdot",
		colors = { rgb(170, 255, 170) },
		size = { 0.6, 1.0, 0.2 },
		trans = { 1, 0.2, 1 },
		rate = 3,
		life = { 5, 8 },
		speed = { 0.4, 1 },
		spread = 180,
		accel = Vector3.new(0, 0.2, 0),
		drag = 0.3,
		light = 1,
		influence = 0,
	},
	GhostMist = {
		tex = "mist",
		colors = { rgb(210, 230, 220) },
		size = { 8, 14 },
		trans = { 1, 0.8, 1 },
		rate = 1.4,
		life = { 9, 13 },
		speed = { 0.3, 0.8 },
		spread = 90,
		accel = Vector3.new(0.3, 0, 0),
		influence = 0.5,
		cull = 240,
	},
	CloudDrift = {
		tex = "mist",
		colors = { rgb(255, 255, 255) },
		size = { 14, 22 },
		trans = { 1, 0.6, 1 },
		rate = 0.8,
		life = { 12, 16 },
		speed = { 1, 2 },
		spread = 10,
		dir = Enum.NormalId.Left,
		influence = 0.8,
		cull = 360,
	},
	ToxicBubbles = {
		tex = "bubble",
		colors = { rgb(170, 255, 90) },
		size = { 0.4, 1.0 },
		trans = { 0.1, 0.2, 1 },
		rate = 8,
		life = { 2, 3.5 },
		speed = { 1, 2 },
		spread = 25,
		accel = Vector3.new(0, 1, 0),
		light = 0.6,
		influence = 0.3,
		dir = Enum.NormalId.Top,
	},
	Sparks = {
		tex = "ember",
		colors = { rgb(255, 230, 120), rgb(255, 150, 40) },
		size = { 0.25, 0.05 },
		trans = { 0, 1 },
		rate = 10,
		life = { 0.5, 0.9 },
		speed = { 8, 14 },
		spread = 50,
		accel = Vector3.new(0, -30, 0),
		light = 1,
		influence = 0,
		dir = Enum.NormalId.Top,
	},
	AuroraSparkle = {
		tex = "star",
		colors = { rgb(140, 255, 210), rgb(190, 140, 255) },
		size = { 0.2, 0.7, 0.1 },
		trans = { 0, 0, 1 },
		rate = 4,
		life = { 1.2, 2 },
		speed = { 0, 0.4 },
		spread = 180,
		light = 1,
		influence = 0,
	},
	Stars = {
		tex = "star",
		colors = { rgb(255, 255, 255), rgb(190, 220, 255) },
		size = { 0.1, 0.6, 0.1 },
		trans = { 1, 0, 1 },
		rate = 10,
		life = { 2, 4 },
		speed = { 0, 0.2 },
		spread = 180,
		light = 1,
		influence = 0,
		cull = 400,
	},
	CosmicDust = {
		tex = "softdot",
		colors = { rgb(190, 120, 255), rgb(90, 200, 255) },
		size = { 0.3, 0.8, 0.2 },
		trans = { 1, 0.3, 1 },
		rate = 6,
		life = { 6, 10 },
		speed = { 0.3, 0.8 },
		spread = 180,
		drag = 0.3,
		light = 1,
		influence = 0,
	},
	RainbowSparkle = {
		tex = "star",
		colors = { rgb(255, 120, 160), rgb(255, 230, 100), rgb(120, 220, 255) },
		size = { 0.2, 0.7, 0.1 },
		trans = { 0, 0, 1 },
		rate = 5,
		life = { 1.4, 2.2 },
		speed = { 0.2, 0.6 },
		spread = 180,
		accel = Vector3.new(0, 0.4, 0),
		light = 1,
		influence = 0,
	},
	GoldGlint = {
		tex = "glint",
		colors = { rgb(255, 236, 150) },
		size = { 0.2, 1.2, 0.1 },
		trans = { 0, 0, 1 },
		rate = 3,
		life = { 0.6, 1.0 },
		speed = { 0, 0 },
		spread = 180,
		light = 1,
		influence = 0,
	},
}
Fx.presets = P

-- Attach preset `name` to `part` (tinted with `tint` when given; `rateScale` multiplies the rate).
function Fx.emit(part: BasePart, name: string, tint: { Color3 }?, rateScale: number?, cull: number?): ParticleEmitter?
	local p = P[name]
	if not p then
		warn(`[World.Fx] unknown preset {name}`)
		return nil
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = Sprites[p.tex] or Sprites.softdot
	e.Color = colorSeq(tint or p.colors)
	e.Size = seq(p.size)
	e.Transparency = seq(p.trans or { 0, 1 })
	e.Lifetime = NumberRange.new(p.life[1], p.life[2])
	e.Speed = NumberRange.new(p.speed[1], p.speed[2])
	e.SpreadAngle = Vector2.new(p.spread or 0, p.spread or 0)
	e.Acceleration = p.accel or Vector3.zero
	e.Drag = p.drag or 0
	if p.rot then
		e.Rotation = NumberRange.new(p.rot[1], p.rot[2])
	end
	if p.spin then
		e.RotSpeed = NumberRange.new(p.spin[1], p.spin[2])
	end
	e.LightEmission = p.light or 0
	e.LightInfluence = p.influence or 1
	e.EmissionDirection = p.dir or Enum.NormalId.Top
	e.Orientation = p.orient or Enum.ParticleOrientation.FacingCamera
	e.ZOffset = p.zoff or 0
	if p.flip then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
		e.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		e.FlipbookFramerate = NumberRange.new(10, 14)
	end
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	local rate = p.rate * (rateScale or 1)
	e.Rate = rate
	e:SetAttribute("BaseRate", rate)
	e:SetAttribute("CullDist", cull or p.cull or 200)
	CollectionService:AddTag(e, "WorldFx")
	e.Parent = part
	return e
end

-- An invisible emitter box (size) at `cf` with preset `name`.
function Fx.area(
	parent: Instance,
	name: string,
	size: Vector3,
	pos: Vector3,
	tint: { Color3 }?,
	rateScale: number?,
	cull: number?
): BasePart
	local a = Parts.anchor(parent, name .. "Fx", size, pos)
	Fx.emit(a, name, tint, rateScale, cull)
	return a
end

-- A thin water sheet (part) whose front face carries a scrolling streak texture (VFX/Ambient scrolls "WorldScroll").
-- `cf` = sheet centre, its -Z (front) facing the viewer; size = (width, height, thickness).
function Fx.waterSheet(parent: Instance, cf: CFrame, size: Vector3, speed: number, color: Color3?): BasePart
	local sheet = Parts.block(parent, "WaterSheet", size, cf, color or rgb(120, 205, 250), {
		collide = false,
		query = false,
		transparency = 0.15,
		shadow = false,
		smooth = true,
	})
	local tex = Instance.new("Texture")
	tex.Texture = Sprites.falls
	tex.Face = Enum.NormalId.Front
	tex.StudsPerTileU = 6
	tex.StudsPerTileV = 8
	tex.Transparency = 0.25
	tex.Color3 = Color3.new(1, 1, 1)
	tex:SetAttribute("SpeedV", speed)
	CollectionService:AddTag(tex, "WorldScroll")
	tex.Parent = sheet
	return sheet
end

-- Waterfall over the World kit Waterfall model placed at `pivot` (scaled `sy` in height): a scrolling sheet on
-- the face of each of its 4 steps (40 tall, 8 wide at scale 1), mist, splash and ripples in the pool.
function Fx.waterfall(parent: Instance, pivot: CFrame, sy: number)
	local folder = Parts.folder(parent, "WaterfallFx")
	local steps, height, width = 4, 40 * sy, 8
	local sh = height / steps
	for i = 0, steps - 1 do
		local w = width * (1 - 0.06 * i)
		local cf = pivot * CFrame.new(0, height - (i + 0.5) * sh, -(i * 1.2) - 0.46)
		Fx.waterSheet(folder, cf, Vector3.new(w - 0.2, sh + 0.1, 0.1), -9)
	end
	local pool = (pivot * CFrame.new(0, 0, -steps * 1.2 - 2.5)).Position
	Fx.area(folder, "FallsMist", Vector3.new(10, 1, 6), pool + Vector3.new(0, 1, 0))
	Fx.area(folder, "Splash", Vector3.new(6, 0.5, 4), pool + Vector3.new(0, 0.5, 0))
	Fx.area(folder, "Ripples", Vector3.new(10, 0.2, 10), pool + Vector3.new(0, 0.2, 0))
end

-- The Golden Egg Fountain: four jets arcing from the egg spouts, splash ring, ripples, glints on the egg, light.
function Fx.fountain(parent: Instance, base: Vector3, scale: number?)
	local k_ = scale or 1
	local folder = Parts.folder(parent, "FountainFx")
	for k = 0, 3 do
		local ang = math.rad(45 + k * 90)
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local spout =
			Parts.anchor(folder, "Jet", Vector3.new(0.4, 0.4, 0.4), base + dir * 3.4 * k_ + Vector3.new(0, 4.4 * k_, 0))
		spout.CFrame = CFrame.lookAt(spout.Position, spout.Position + dir + Vector3.new(0, 0.9, 0))
			* CFrame.Angles(-math.pi / 2, 0, 0)
		local e = Fx.emit(spout, "FountainJet", nil, 0.6)
		if e then
			e.Speed = NumberRange.new(7, 8)
			e.SpreadAngle = Vector2.new(4, 4)
		end
	end
	Fx.area(folder, "Splash", Vector3.new(12, 0.4, 12) * k_, base + Vector3.new(0, 1.4 * k_, 0), nil, 0.5)
	Fx.area(folder, "Ripples", Vector3.new(14, 0.2, 14) * k_, base + Vector3.new(0, 1.65 * k_, 0))
	Fx.area(folder, "GoldGlint", Vector3.new(5, 7, 5) * k_, base + Vector3.new(0, 11.8 * k_, 0))
	local glow = Parts.anchor(folder, "EggLight", Vector3.one * 0.5, base + Vector3.new(0, 12 * k_, 0))
	Parts.light(glow, rgb(255, 214, 120), 22, 1.2)
end

-- Aurora ribbons: curved, camera-facing beams with the curtain sprite scrolling along them, high in the sky between
-- a and b, in two colours that fade toward the ends.
function Fx.aurora(parent: Instance, a: Vector3, b: Vector3, width: number, c0: Color3, c1: Color3)
	local folder = Parts.folder(parent, "AuroraFx")
	local a0 = Parts.anchor(folder, "AuroraA", Vector3.one * 0.2, a)
	local a1 = Parts.anchor(folder, "AuroraB", Vector3.one * 0.2, b)
	local att0, att1 = Instance.new("Attachment"), Instance.new("Attachment")
	att0.Parent, att1.Parent = a0, a1
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = att0, att1
	beam.Texture = Sprites.curtain
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureSpeed = 0.15
	beam.Width0, beam.Width1 = width, width * 0.7
	beam.CurveSize0, beam.CurveSize1 = width * 0.8, -width * 0.6
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 24
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c0),
		ColorSequenceKeypoint.new(0.5, c1),
		ColorSequenceKeypoint.new(1, c0),
	})
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.45),
		NumberSequenceKeypoint.new(0.8, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Parent = a0
	return beam
end

-- Gentle hub ambience: pollen and butterflies over the lawns, fireflies in the groves, sparkles at the plaza.
function Fx.hubAmbient(root: Instance, ctx: any)
	local folder = Parts.folder(root, "AmbientFx")
	local W, D = ctx.halfWidth, ctx.depth
	Fx.area(folder, "Pollen", Vector3.new(2 * W - 40, 10, D - 60), Vector3.new(0, 7, -D / 2), nil, 1.5, 260)
	for k, c in { rgb(255, 170, 60), rgb(110, 190, 255), rgb(255, 230, 90) } do
		Fx.area(
			folder,
			"Butterflies",
			Vector3.new(2 * W - 60, 6, D / 3),
			Vector3.new(0, 4, -40 - (k - 1) * D / 3),
			{ c },
			1.2,
			180
		)
	end
	Fx.area(
		folder,
		"Sparkle",
		Vector3.new(50, 4, 50),
		ctx.plaza + Vector3.new(0, 3, 0),
		{ rgb(255, 245, 200) },
		1.5,
		150
	)
	Fx.area(folder, "Fireflies", Vector3.new(30, 8, D - 40), Vector3.new(W - 20, 6, -D / 2), nil, 1, 160)
	Fx.area(folder, "Fireflies", Vector3.new(30, 8, D - 40), Vector3.new(-W + 20, 6, -D / 2), nil, 1, 160)
end

return Fx
