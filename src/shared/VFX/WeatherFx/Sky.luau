--!strict
-- Partner A. Brick centrepieces for the weather looks (client only), in the game's classic style: native Plastic
-- blocks with studs (Neon only for glow), round shapes as stepped voxel rows. Built in prop space (origin = centre,
-- -Z faces the camera for billboards) and moved every frame with one BulkMoveTo; nothing collides, touches or is
-- raycast-visible. Sky props follow the camera like a skybox (Elements.sky), region props stand in a local storm.
--   fade(w, q)            weight 0..1 -> part transparency, beam transparency, emitter rate, light brightness
--   place(root, t, reduced) position (and animate unless Reduced Motion)
local Sprites = require(script.Parent.Sprites)

local Sky = {}

export type Prop = {
	fade: (w: number, q: number) -> (),
	place: (root: CFrame, t: number, reduced: boolean) -> (),
	linger: number,
	destroy: () -> (),
}

type Rec = { part: BasePart, cf: CFrame, base: number, spin: number?, orbit: number?, bob: number? }
type BeamRec = { beam: Beam, base: NumberSequence }
type Builder = {
	model: Model,
	recs: { Rec },
	beams: { BeamRec },
	emitters: { { e: ParticleEmitter, rate: number } },
	lights: { { l: Light, b: number } },
	animate: ((b: Builder, t: number) -> ())?,
	linger: number,
}

local STUDS, INLET, SMOOTH = Enum.SurfaceType.Studs, Enum.SurfaceType.Inlet, Enum.SurfaceType.Smooth
local rng = Random.new()
local rgb = Color3.fromRGB

local function newBuilder(name: string, folder: Instance): Builder
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = folder
	return { model = m, recs = {}, beams = {}, emitters = {}, lights = {}, animate = nil, linger = 0 }
end

-- One brick: studded Plastic, or smooth Neon when `neon`.
local function brick(b: Builder, color: Color3, size: Vector3, cf: CFrame, neon: boolean?, transparency: number?): Rec
	local p = Instance.new("Part")
	p.Name = if neon then "Glow" else "Brick"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Transparency = 1
	if neon then
		p.Material = Enum.Material.Neon
		p.TopSurface, p.BottomSurface = SMOOTH, SMOOTH
	else
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = STUDS, INLET
		p.FrontSurface, p.BackSurface, p.LeftSurface, p.RightSurface = STUDS, STUDS, STUDS, STUDS
	end
	p.Parent = b.model
	local r: Rec = { part = p, cf = cf, base = transparency or 0 }
	table.insert(b.recs, r)
	return r
end

-- An invisible anchor (for attachments / emitters) that moves with the prop.
local function anchor(b: Builder, cf: CFrame): Rec
	local r = brick(b, Color3.new(1, 1, 1), Vector3.one, cf, false, 1)
	r.part.Name = "Anchor"
	return r
end

-- A flat voxel disc in the XY plane: one wide brick per row (radius in blocks of `cell` studs).
local function disc(
	b: Builder,
	radius: number,
	cell: number,
	color: Color3,
	z: number,
	neon: boolean?,
	t: number?
): { Rec }
	local out = {}
	for y = -radius, radius do
		local half = math.floor(math.sqrt(math.max(radius * radius - y * y, 0)) + 0.5)
		if half > 0 or y == 0 then
			local w = (2 * half + 1) * cell
			table.insert(out, brick(b, color, Vector3.new(w, cell, cell), CFrame.new(0, y * cell, z), neon, t))
		end
	end
	return out
end

local function emitterOn(b: Builder, rec: Rec, props: { [string]: any }, rate: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Rate = 0
	e.Parent = rec.part
	table.insert(b.emitters, { e = e, rate = rate })
	b.linger = math.max(b.linger, e.Lifetime.Max)
	return e
end

local function finish(b: Builder): Prop
	local parts: { BasePart } = {}
	for _, r in b.recs do
		table.insert(parts, r.part)
	end
	local cfs: { CFrame } = table.create(#parts)
	local lastW = -1
	return {
		fade = function(w: number, q: number)
			for _, em in b.emitters do
				em.e.Rate = em.rate * w * q
			end
			if math.abs(w - lastW) < 0.003 then
				return
			end
			lastW = w
			for _, r in b.recs do
				r.part.Transparency = 1 - (1 - r.base) * w
			end
			for _, br in b.beams do
				local kps = {}
				for _, k in br.base.Keypoints do
					table.insert(kps, NumberSequenceKeypoint.new(k.Time, 1 - (1 - k.Value) * w))
				end
				br.beam.Transparency = NumberSequence.new(kps)
			end
			for _, l in b.lights do
				l.l.Brightness = l.b * w
			end
		end,
		place = function(root: CFrame, t: number, reduced: boolean)
			local anim = b.animate
			if anim and not reduced then
				anim(b, t)
			end
			for i, r in b.recs do
				cfs[i] = root * r.cf
			end
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end,
		linger = b.linger,
		destroy = function()
			b.model:Destroy()
		end,
	}
end

-- Builders ------------------------------------------------------------------------------------------------------------

-- A chunky voxel sun: stepped yellow disc, an orange corona behind and 12 slowly turning ray blades.
local function sun(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherSun", folder)
	local s: number = spec.scale or 1
	local cell = 4 * s
	disc(b, 5, cell, spec.color or rgb(255, 222, 92), 0, true, 0)
	disc(b, 7, cell, spec.corona or rgb(255, 160, 50), cell, true, 0.35)
	local rays = {}
	for i = 0, 11 do
		local a = i * math.pi / 6
		local r = brick(
			b,
			spec.rays or rgb(255, 238, 150),
			Vector3.new(cell * 1.2, cell * 3.4, cell * 0.6),
			CFrame.new(),
			true,
			0.15
		)
		r.spin = a
		table.insert(rays, r)
	end
	local R = 9.6 * cell
	local function setRays(t: number)
		for _, r in rays do
			local a = (r.spin :: number) + t * 0.12
			r.cf = CFrame.Angles(0, 0, a) * CFrame.new(0, R, cell * 0.5)
		end
	end
	setRays(0)
	b.animate = function(_b, t)
		setRays(t)
	end
	return finish(b)
end

-- A stepped voxel rainbow arc (6 Neon bands, red outside) with a little studded cloud at each foot.
local function rainbow(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherRainbow", folder)
	local R: number = spec.radius or 150
	local band: number = spec.band or 9
	local len: number = spec.blockLen or 14
	local colors: { Color3 } = spec.colors
		or {
			rgb(255, 70, 70),
			rgb(255, 150, 40),
			rgb(255, 230, 60),
			rgb(90, 220, 80),
			rgb(60, 160, 255),
			rgb(170, 90, 255),
		}
	for i, c in colors do
		local r = R - (i - 1) * band
		local n = math.ceil(math.pi * r / len)
		for j = 0, n - 1 do
			local th = math.pi * (j + 0.5) / n
			brick(
				b,
				c,
				Vector3.new(len + 1.5, band, band * 0.8),
				CFrame.new(r * math.cos(th), r * math.sin(th), 0) * CFrame.Angles(0, 0, th + math.pi / 2),
				true,
				spec.transparency or 0.12
			)
		end
	end
	local mid = R - band * (#colors - 1) / 2
	for _, x in { -mid, mid } do
		for k, puff in { { 0, 0, 34, 12 }, { -12, 9, 18, 12 }, { 10, 10, 20, 14 }, { 0, 16, 16, 10 } } do
			local col = if k == 1 then rgb(225, 235, 250) else rgb(255, 255, 255)
			brick(
				b,
				col,
				Vector3.new(puff[3], puff[4], puff[3] * 0.7),
				CFrame.new(x + puff[1], puff[2] - 2, 0),
				false,
				0
			)
		end
	end
	return finish(b)
end

-- A ring of chunky studded cloud clusters around the camera (overcast); drifts slowly.
local function clouds(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherClouds", folder)
	local n: number = spec.count or 8
	local radius = spec.radius or { 170, 280 }
	local top: Color3 = spec.top or rgb(235, 238, 245)
	local bottom: Color3 = spec.bottom or rgb(170, 178, 195)
	local s: number = spec.scale or 1
	local members: { Rec } = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2 + rng:NextNumber(-0.25, 0.25)
		local r = rng:NextNumber(radius[1], radius[2])
		local y = rng:NextNumber(-14, 14)
		local base = CFrame.Angles(0, a, 0) * CFrame.new(0, y, -r)
		local w = rng:NextNumber(44, 66) * s
		-- a chunky cumulus like the map's own voxel clouds: a flat-ish base, rounded puffs stacked on top
		table.insert(members, brick(b, bottom, Vector3.new(w, 12 * s, w * 0.55), base, false, 0))
		table.insert(
			members,
			brick(
				b,
				bottom:Lerp(top, 0.5),
				Vector3.new(w * 0.8, 10 * s, w * 0.5),
				base * CFrame.new(0, 9 * s, 0),
				false,
				0
			)
		)
		for k = 1, 4 do
			local pw = rng:NextNumber(18, 30) * s
			local off = CFrame.new(
				rng:NextNumber(-w * 0.3, w * 0.3),
				(14 + rng:NextNumber(0, 9)) * s,
				rng:NextNumber(-5, 5) * s
			)
			table.insert(members, brick(b, top, Vector3.new(pw, pw * 0.8, pw * 0.85), base * off, false, 0))
		end
	end
	local rest = {}
	for i, r in members do
		rest[i] = r.cf
	end
	b.animate = function(_b, t)
		local turn = CFrame.Angles(0, t * 0.006, 0)
		for i, r in members do
			r.cf = turn * rest[i]
		end
	end
	return finish(b)
end

-- Aurora curtains: wavy Beam ribbons overhead (green -> cyan -> violet), slowly rippling.
local function aurora(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherAurora", folder)
	local count: number = spec.count or 3
	local length: number = spec.length or 220
	-- saturated and mostly alpha-blended: additive glow washes out against the daytime sky
	local colors = spec.colors or { rgb(40, 225, 140), rgb(40, 175, 235), rgb(150, 85, 235) }
	local beams = {}
	for i = 1, count do
		local off = CFrame.new((i - (count + 1) / 2) * 45, (i % 2) * 18, (i - 1) * 40)
			* CFrame.Angles(0, math.rad((i - 2) * 14), 0)
		local rec = anchor(b, off)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		-- attachment X axis = beam direction (+X), so CurveSize bends the ribbon sideways; Y up = curtain height
		a0.CFrame = CFrame.new(-length / 2, 0, 0) * CFrame.fromMatrix(Vector3.zero, Vector3.zAxis, Vector3.yAxis)
		a1.CFrame = CFrame.new(length / 2, 0, 0) * CFrame.fromMatrix(Vector3.zero, Vector3.zAxis, Vector3.yAxis)
		a0.Parent, a1.Parent = rec.part, rec.part
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Texture = Sprites.aurora
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = spec.textureLength or 90
		beam.TextureSpeed = 0.06
		beam.Width0, beam.Width1 = spec.height or 70, spec.height or 70
		beam.Segments = 24
		beam.FaceCamera = false
		beam.LightEmission = spec.lightEmission or 0.1
		beam.LightInfluence = 0
		beam.Brightness = spec.brightness or 1.6
		local cs = {}
		for k, c in colors do
			table.insert(cs, ColorSequenceKeypoint.new((k - 1) / (#colors - 1), c))
		end
		beam.Color = ColorSequence.new(cs)
		beam.CurveSize0, beam.CurveSize1 = 40, -40
		beam.Parent = rec.part
		local base = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, spec.transparency or 0.3),
			NumberSequenceKeypoint.new(0.85, spec.transparency or 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Transparency = NumberSequence.new(1)
		table.insert(b.beams, { beam = beam, base = base })
		table.insert(beams, { beam = beam, phase = i * 1.7 })
	end
	b.animate = function(_b, t)
		for _, x in beams do
			x.beam.CurveSize0 = 45 * math.sin(t * 0.25 + x.phase)
			x.beam.CurveSize1 = -45 * math.sin(t * 0.21 + x.phase + 1)
		end
	end
	return finish(b)
end

-- Void Eclipse (concept): a dark voxel disc with a violet corona and a tilted orbit ring of glowing blocks.
local function eclipse(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherEclipse", folder)
	local cell = 4 * (spec.scale or 1)
	disc(b, 6, cell, rgb(22, 14, 40), 0, false, 0)
	disc(b, 8, cell, rgb(170, 90, 255), cell, true, 0.25)
	local ring = {}
	for i = 0, 27 do
		local a = i / 28 * math.pi * 2
		local r = brick(b, rgb(200, 150, 255), Vector3.new(cell * 0.9, cell * 0.5, cell * 0.5), CFrame.new(), true, 0.1)
		r.orbit = a
		table.insert(ring, r)
	end
	local function setRing(t: number)
		for _, r in ring do
			local a = (r.orbit :: number) + t * 0.05
			r.cf = CFrame.Angles(0, 0, math.rad(-14))
				* CFrame.new(math.cos(a) * 12 * cell, math.sin(a) * 2.2 * cell, -math.sin(a) * cell)
		end
	end
	setRing(0)
	b.animate = function(_b, t)
		setRing(t)
	end
	return finish(b)
end

-- Divine Ascension (concept): a slowly turning golden halo ring of glowing blocks with a soft inner glow.
local function halo(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherHalo", folder)
	local cell = 4 * (spec.scale or 1)
	local ring = {}
	for i = 0, 23 do
		local r = brick(b, rgb(255, 214, 90), Vector3.new(cell * 1.6, cell * 0.8, cell * 0.8), CFrame.new(), true, 0.05)
		r.orbit = i / 24 * math.pi * 2
		table.insert(ring, r)
	end
	disc(b, 6, cell, rgb(255, 245, 200), cell * 2, true, 0.75)
	local function turn(_b: Builder, t: number)
		for _, r in ring do
			local a = (r.orbit :: number) + t * 0.08
			r.cf = CFrame.Angles(math.rad(70), 0, 0)
				* CFrame.new(math.cos(a) * 10 * cell, math.sin(a) * 10 * cell, 0)
				* CFrame.Angles(0, 0, a + math.pi / 2)
		end
	end
	turn(b, 0)
	b.animate = turn
	return finish(b)
end

-- Void Rift (local concept): an upright ring of violet glow blocks around a dark core, a turning swirl and
-- floating shards orbiting it.
local function portal(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherRift", folder)
	local R: number = spec.radius or 9
	for i = 0, 17 do
		local a = i / 18 * math.pi * 2
		brick(
			b,
			rgb(185, 110, 255),
			Vector3.new(3.6, 3.6, 3),
			CFrame.new(math.cos(a) * R, R + 2 + math.sin(a) * R, 0) * CFrame.Angles(0, 0, a),
			true,
			0
		)
	end
	for _, rec in disc(b, 2, 3.4, rgb(18, 8, 32), 0.6, false, 0) do
		rec.cf = CFrame.new(0, R + 2, 0) * rec.cf
	end
	local core = anchor(b, CFrame.new(0, R + 2, -0.5))
	emitterOn(b, core, {
		Texture = Sprites.swirl,
		Color = ColorSequence.new(rgb(200, 130, 255), rgb(90, 40, 200)),
		Size = NumberSequence.new(R * 1.9),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Lifetime = NumberRange.new(2.5, 3),
		Speed = NumberRange.new(0),
		RotSpeed = NumberRange.new(60, 90),
		Rotation = NumberRange.new(0, 360),
		LightEmission = 1,
		LockedToPart = true,
		Orientation = Enum.ParticleOrientation.FacingCamera,
	}, 1.2)
	local shards = {}
	for i = 1, 8 do
		local r = brick(b, rgb(70, 30, 120), Vector3.new(1.6, 2.6, 1.6), CFrame.new(), false, 0)
		r.orbit = i / 8 * math.pi * 2
		r.bob = rng:NextNumber(0, 6)
		table.insert(shards, r)
	end
	local light = Instance.new("PointLight")
	light.Color = rgb(170, 90, 255)
	light.Range = 34
	light.Brightness = 0
	light.Parent = core.part
	table.insert(b.lights, { l = light, b = 2.5 })
	local function setShards(t: number)
		for _, r in shards do
			local a = (r.orbit :: number) + t * 0.45
			r.cf = CFrame.new(
				math.cos(a) * (R + 6),
				R + 2 + math.sin(t * 1.3 + (r.bob :: number)) * 3,
				math.sin(a) * (R + 6)
			) * CFrame.Angles(t, a, 0.3)
		end
	end
	setShards(0)
	b.animate = function(_b, t)
		setShards(t)
	end
	return finish(b)
end

-- Thunder Surge (local concept): three studded pylons with glowing caps and soft-flickering arc Beams between them.
local function pylons(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherSurge", folder)
	local R: number = spec.radius or 18
	local caps: { Rec } = {}
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2
		local x, z = math.cos(a) * R, math.sin(a) * R
		for k = 0, 2 do
			brick(
				b,
				rgb(80 + k * 12, 92 + k * 12, 118 + k * 12),
				Vector3.new(4 - k * 0.6, 6, 4 - k * 0.6),
				CFrame.new(x, 3 + k * 6, z),
				false,
				0
			)
		end
		table.insert(caps, brick(b, rgb(120, 230, 255), Vector3.new(3, 3, 3), CFrame.new(x, 20.5, z), true, 0))
	end
	local arcs = {}
	for i = 1, 3 do
		local c0, c1 = caps[i], caps[i % 3 + 1]
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = c0.part, c1.part
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Texture = Sprites.arc
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 12
		beam.TextureSpeed = 1.5
		beam.Width0, beam.Width1 = 3, 3
		beam.Segments = 12
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Color = ColorSequence.new(rgb(140, 235, 255), rgb(90, 160, 255))
		beam.Transparency = NumberSequence.new(1)
		beam.Parent = c0.part
		local base = NumberSequence.new(0.15)
		table.insert(b.beams, { beam = beam, base = base })
		table.insert(arcs, beam)
		local l = Instance.new("PointLight")
		l.Color = rgb(120, 220, 255)
		l.Range = 22
		l.Brightness = 0
		l.Parent = c0.part
		table.insert(b.lights, { l = l, b = 2 })
	end
	local nextFlick = 0
	b.animate = function(_b, t)
		if t >= nextFlick then -- soft re-shape a few times a second; brightness never strobes on / off
			nextFlick = t + rng:NextNumber(0.18, 0.4)
			for _, beam in arcs do
				beam.CurveSize0 = rng:NextNumber(-5, 5)
				beam.CurveSize1 = rng:NextNumber(-5, 5)
				beam.TextureSpeed = rng:NextNumber(1, 2.5)
			end
		end
	end
	return finish(b)
end

-- Toxic Bloom (local concept): voxel flowers with glowing centres that puff spores.
local function blooms(spec: { [string]: any }, folder: Instance): Prop
	local b = newBuilder("WeatherBloom", folder)
	local spread: number = spec.spread or 26
	local heads = {}
	for i = 1, (spec.count or 5) do
		local x, z = rng:NextNumber(-spread, spread), rng:NextNumber(-spread, spread)
		local h = rng:NextNumber(5, 9)
		brick(b, rgb(60, 140, 50), Vector3.new(1.4, h, 1.4), CFrame.new(x, h / 2, z), false, 0)
		local center = brick(b, rgb(210, 255, 80), Vector3.new(2.4, 2.4, 2.4), CFrame.new(x, h + 1, z), true, 0)
		center.bob = rng:NextNumber(0, 6)
		table.insert(heads, { rec = center, x = x, z = z, h = h, petals = {} :: { Rec } })
		for k = 0, 3 do
			local a = k * math.pi / 2
			local p = brick(b, rgb(120, 230, 60), Vector3.new(3.4, 1, 2.2), CFrame.new(), false, 0)
			p.orbit = a
			table.insert(heads[#heads].petals, p)
		end
		emitterOn(b, center, {
			Texture = Sprites.toxicspore,
			Color = ColorSequence.new(rgb(190, 255, 90), rgb(90, 230, 120)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.2) }),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(2.5, 4),
			Speed = NumberRange.new(2, 4),
			SpreadAngle = Vector2.new(30, 30),
			Acceleration = Vector3.new(0, 0.6, 0),
			LightEmission = 0.8,
			EmissionDirection = Enum.NormalId.Top,
		}, 2.5)
	end
	local function setHeads(t: number)
		for _, hd in heads do
			local y = hd.h + 1 + math.sin(t * 1.6 + (hd.rec.bob :: number)) * 0.35
			hd.rec.cf = CFrame.new(hd.x, y, hd.z)
			for _, p in hd.petals do
				local a = p.orbit :: number
				p.cf = CFrame.new(hd.x, y - 0.4, hd.z)
					* CFrame.Angles(0, a, 0)
					* CFrame.new(0, 0, -2.2)
					* CFrame.Angles(math.rad(-25), 0, 0)
			end
		end
	end
	setHeads(0)
	b.animate = function(_b, t)
		setHeads(t)
	end
	return finish(b)
end

local BUILDERS: { [string]: (spec: { [string]: any }, folder: Instance) -> Prop } = {
	sun = sun,
	rainbow = rainbow,
	clouds = clouds,
	aurora = aurora,
	eclipse = eclipse,
	halo = halo,
	portal = portal,
	pylons = pylons,
	blooms = blooms,
}

function Sky.build(name: string, spec: { [string]: any }, folder: Instance): Prop
	local fn = BUILDERS[name]
	if not fn then
		error(`[WeatherFx] unknown sky prop "{name}"`)
	end
	return fn(spec, folder)
end

return Sky
