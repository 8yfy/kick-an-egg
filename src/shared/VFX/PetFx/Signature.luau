--!strict
-- Partner A. Signature layer kinds for VFX/PetFx: effect ideas the basic kinds (emit, orbit, disc, board, light,
-- beam) can't express, so each pet can have its own concept rather than a shared stack (docs/EggPetPlan.md
-- "Signature effects"). PetFx calls Signature[kind](kit, layer, i, at) while it builds; `kit` carries its helpers
-- (attachment, fxPart, colors, seq, vec, sprite, timed, partNamed), the state and the model scale `s`. Positions are
-- studs at model scale 1 in the model's frame (-Z = its front) unless a part anchors them.
--   arc     lightning between two parts: from/to {part, tip?, at}, segments, jitter, rate (re-rolls/s), duty (chance
--           a re-roll is visible), width, color, alpha, glow, sprite, light {brightness, range}; its own timed surge
--           (every/sync/beat/time) and boosts {{on, delay, time, jitter}, ...} (other layers' specials) make it
--           always-on and wilder for `time` s
--   blades  a crown of light-blades turning in the plane facing the front, riding a joint: joint, at (centre),
--           radius, count, size {w, len, t}, long (alternate blades x this length), color (C3 or list), material,
--           alpha, spin (rad/s); boost {on, delay, time, radius, spin, len} flares it on a special
--   strike  pillars of light slamming down in a ring on a special: count, radius, height, width, life, stagger,
--           phase, color, sprite; impact {sprite, size, color, count} rings and sparks {sprite, color, count} where
--           each lands
--   dial    a giant sprite that spins up in front of the pet on a special: at, size, life, turns, sprite, color,
--           alpha, glow
--   ribbon  a flowing streamer from a part to a swaying point behind it: part, from, to, sway {x, y, z}, hz, phase,
--           curve, width, width1, color, alpha, glow, sprite, scroll, segments
--   trail   a Trail between two points on a part (it streaks as the part moves): part, a0, a1, life, color, alpha,
--           glow, bright, sprite, width {start, end}
--   curtain a ring of veils that unfurls from the ground and ripples on a special: count, radius, height, life,
--           rise, fade, ripple, fill (share of each slot a veil covers, gaps between), sprite, color (one per veil,
--           cycling a list), alpha, glow, bright, scroll
local Signature = {}

type Kit = any
type Layer = { [string]: any }
type Pillar = { beam: Beam, a0: Attachment, a1: Attachment, at: number, hit: boolean }

local TAU = 2 * math.pi

local function ease(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- A boost envelope: 0 before `at`, up over the first 15 %, eased back to 0 by the end of `time` s.
local function boostEnv(at: number, time: number, now: number): number
	if at < 0 then
		return 0
	end
	local u = (now - at) / time
	if u < 0 or u >= 1 then
		return 0
	end
	return if u < 0.15 then ease(u / 0.15) else 1 - ease((u - 0.15) / 0.85)
end

-- A joint's displacement from its rest pose, in root space (BlockBuilder records RestC0 at RestScale), so a point
-- placed in the rest pose follows the animated joint: rootSpacePoint = J() * restPoint.
local function jointOffset(kit: Kit, name: string?): () -> CFrame
	local m = if name then kit.root:FindFirstChild(name) else nil
	if not (m and m:IsA("Motor6D")) then
		return function()
			return CFrame.identity
		end
	end
	local motor = m :: Motor6D
	local rest = motor:GetAttribute("RestC0")
	local first = motor.C0
	return function()
		local base = first
		if typeof(rest) == "CFrame" then
			local at = kit.model:GetAttribute("RestScale")
			local k = kit.model:GetScale() / (if typeof(at) == "number" and at > 0 then at else 1)
			base = CFrame.new(rest.Position * k) * rest.Rotation
		end
		return motor.C0 * base:Inverse()
	end
end

-- A world point on a part ({part, tip?, at}); falls back to the model root.
local function anchor(kit: Kit, spec: { [string]: any }): () -> Vector3
	local p = kit.partNamed(spec.part)
	local off = kit.vec(spec.at, kit.s)
	return function()
		if p then
			local o = off
			if spec.tip then
				o += Vector3.new(0, p.Size.Y / 2, 0)
			end
			return p.CFrame:PointToWorldSpace(o)
		end
		return kit.root.CFrame:PointToWorldSpace(off)
	end
end

local function newBeam(kit: Kit, layer: Layer, a0: Attachment, a1: Attachment, faceCamera: boolean): Beam
	local b = Instance.new("Beam")
	b.Attachment0, b.Attachment1 = a0, a1
	b.Texture = kit.Sprites.get(layer.sprite)
	b.TextureMode = Enum.TextureMode.Stretch
	b.TextureSpeed = layer.scroll or 0
	b.Color = kit.colors(layer.color)
	b.Transparency = kit.seq(layer.alpha or 0, 1)
	b.LightEmission = layer.glow or 1
	b.LightInfluence = 0
	b.Brightness = layer.bright or 1
	b.FaceCamera = faceCamera
	b.Segments = layer.segments or 1
	b.Parent = kit.root
	table.insert(kit.state.made, b)
	return b
end

local function emitter(kit: Kit, spec: { [string]: any }, name: string, att: Attachment): ParticleEmitter
	local s = kit.s
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = kit.Sprites.get(spec.sprite)
	e.Rate = 0
	e.Lifetime = kit.num(spec.life or { 0.4, 0.7 }, 1)
	e.Size = kit.seq(spec.size or { 0.4, 0 }, s)
	e.Speed = kit.num(spec.speed or 0, s)
	e.SpreadAngle = Vector2.new(spec.spread or 180, spec.spread or 180)
	e.Acceleration = kit.vec(spec.accel, s)
	e.Drag = spec.drag or 0
	e.Color = kit.colors(spec.color)
	e.Transparency = kit.seq(spec.alpha or { 0, 1 }, 1)
	e.LightEmission = spec.glow or 1
	e.LightInfluence = 0
	e.Brightness = spec.bright or 2
	e.Orientation = if spec.flat
		then Enum.ParticleOrientation.VelocityPerpendicular
		else Enum.ParticleOrientation.FacingCamera
	e.Parent = att
	table.insert(kit.state.emitters, e)
	return e
end

function Signature.arc(kit: Kit, layer: Layer, i: number, _at: Vector3)
	local s, rng = kit.s, kit.rng
	local A, B = anchor(kit, layer.from or {}), anchor(kit, layer.to or {})
	local n = layer.segments or 7
	local atts: { Attachment } = {}
	for k = 0, n do
		atts[k + 1] = kit.attachment(`Arc{i}_{k}`, Vector3.zero)
	end
	local beams: { Beam } = {}
	for k = 1, n do
		local b = newBeam(kit, {
			sprite = layer.sprite or "v3_arc",
			color = layer.color,
			alpha = layer.alpha,
			glow = layer.glow,
			bright = layer.bright,
		}, atts[k], atts[k + 1], true)
		b.Enabled = false
		beams[k] = b
		table.insert(kit.state.toggles, b)
	end
	local light: PointLight? = nil
	if layer.light then
		local l = Instance.new("PointLight")
		l.Color = if typeof(layer.color) == "Color3" then layer.color else Color3.new(1, 0.8, 0.4)
		l.Range = (layer.light.range or 8) * s
		l.Brightness = 0
		l.Shadows = false
		l.Parent = atts[math.floor(n / 2) + 1]
		light = l
	end
	local offsets: { Vector3 } = table.create(n + 1, Vector3.zero)
	local nextRoll, visible, boostUntil, boostJitter = 0, false, -1, 1.8
	local width = (layer.width or 0.3) * s
	if type(layer.every) == "table" then -- its own surge
		kit.timed(layer, i, function()
			boostUntil = math.max(boostUntil, os.clock() + (layer.time or 0.35))
		end)
	end
	for _, boost in layer.boosts or {} do
		kit.timed({ on = boost.on, delay = boost.delay }, i, function()
			boostJitter = boost.jitter or 1.8
			boostUntil = math.max(boostUntil, os.clock() + (boost.time or 1))
		end)
	end
	local duty, rate, jitter = layer.duty or 0.5, layer.rate or 14, (layer.jitter or 0.35) * s
	table.insert(kit.state.movers, function(t: number, r: CFrame)
		local a, b = A(), B()
		local boosted = os.clock() < boostUntil
		if t >= nextRoll then
			nextRoll = t + 1 / (rate * (if boosted then 1.6 else 1))
			visible = boosted or rng:NextNumber() < duty
			local d = b - a
			if d.Magnitude < 1e-3 then
				d = Vector3.yAxis
			end
			local side = d:Cross(Vector3.yAxis)
			side = if side.Magnitude < 1e-3 then Vector3.xAxis else side.Unit
			local up = side:Cross(d.Unit)
			local amp = jitter * (if boosted then boostJitter else 1)
			for k = 1, n - 1 do
				local env = math.sin(k / n * math.pi)
				offsets[k + 1] = (side * rng:NextNumber(-1, 1) + up * rng:NextNumber(-1, 1)) * amp * env
			end
			local w = width * rng:NextNumber(0.6, 1.2) * (if boosted then 1.5 else 1)
			for _, beam in beams do
				beam.Enabled = visible
				beam.Width0, beam.Width1 = w, w
			end
			if light then
				light.Brightness = if visible then (layer.light.brightness or 1.5) * rng:NextNumber(0.6, 1.2) else 0
			end
		end
		if visible then
			for k = 0, n do
				atts[k + 1].Position = r:PointToObjectSpace(a:Lerp(b, k / n) + offsets[k + 1])
			end
		end
	end)
end

function Signature.blades(kit: Kit, layer: Layer, i: number, at: Vector3)
	local s = kit.s
	local J = jointOffset(kit, layer.joint)
	local count = layer.count or 12
	local size = kit.vec(layer.size or { 0.22, 1.5, 0.08 }, s)
	local radius = (layer.radius or 3) * s
	local long = layer.long or 1
	local cols = if type(layer.color) == "table" then layer.color else { layer.color or Color3.new(1, 0.9, 0.5) }
	local parts: { BasePart } = {}
	for k = 1, count do
		local p = kit.fxPart(`Blade{i}_{k}`, size, kit.folder)
		p.Transparency = layer.alpha or 0
		p.Material = (Enum.Material :: any)[layer.material or "Neon"]
		p.Color = cols[(k - 1) % #cols + 1]
		parts[k] = p
		table.insert(kit.state.parts, p)
	end
	local boost = layer.boost
	local boostAt = -1
	if boost then
		kit.timed({ on = boost.on, delay = boost.delay }, i, function()
			boostAt = os.clock()
		end)
	end
	local spin = layer.spin or 0.15
	local angle, last = 0, -1
	table.insert(kit.state.movers, function(t: number, r: CFrame)
		local dt = if last < 0 then 0 else math.min(t - last, 0.1)
		last = t
		local e = if boost then boostEnv(boostAt, boost.time or 1.2, os.clock()) else 0
		angle += dt * spin * (1 + e * (if boost then boost.spin or 6 else 0))
		local rad = radius + e * (if boost then (boost.radius or 1.2) * s else 0)
		local frame = r * J() * CFrame.new(at)
		for k, p in parts do
			local a = angle + (k - 1) * TAU / count
			local len = size.Y * (if k % 2 == 0 then long else 1) * (1 + e * (if boost then boost.len or 0.6 else 0))
			p.Size = Vector3.new(size.X, len, size.Z)
			p.CFrame = frame * CFrame.Angles(0, 0, a - math.pi / 2) * CFrame.new(0, rad + len / 2, 0)
		end
	end)
end

function Signature.strike(kit: Kit, layer: Layer, i: number, _at: Vector3)
	local s = kit.s
	local count, radius, height = layer.count or 8, (layer.radius or 7) * s, (layer.height or 40) * s
	local width, life, stagger = (layer.width or 2.4) * s, layer.life or 0.7, layer.stagger or 0.05
	local pillars: { Pillar } = {}
	for k = 1, count do
		local a0 = kit.attachment(`Strike{i}_{k}a`, Vector3.zero)
		local a1 = kit.attachment(`Strike{i}_{k}b`, Vector3.zero)
		local b = newBeam(
			kit,
			{ sprite = layer.sprite or "v3_shaft", color = layer.color, glow = layer.glow, bright = layer.bright },
			a0,
			a1,
			true
		)
		b.Enabled = false
		pillars[k] = { beam = b, a0 = a0, a1 = a1, at = -1, hit = false }
	end
	local impactAt = kit.attachment(`Strike{i}_impact`, Vector3.zero)
	local ring = if layer.impact then emitter(kit, layer.impact, `Strike{i}Ring`, impactAt) else nil
	local sparks = if layer.sparks then emitter(kit, layer.sparks, `Strike{i}Sparks`, impactAt) else nil
	kit.timed(layer, i, function()
		local now = os.clock()
		for k, pl in pillars do
			pl.at, pl.hit = now + (k - 1) * stagger, false
		end
	end)
	table.insert(kit.state.movers, function(_t: number, _r: CFrame)
		local now = os.clock()
		for k, pl in pillars do
			if pl.at < 0 then
				continue
			end
			local u = (now - pl.at) / life
			if u < 0 then
				continue
			elseif u >= 1 then
				pl.beam.Enabled, pl.at = false, -1
				continue
			end
			local a = (k - 1) / count * TAU + (layer.phase or 0)
			local ground = Vector3.new(math.cos(a) * radius, 0.05 * s, math.sin(a) * radius)
			local drop = ease(u / 0.14) -- the light slams down from the sky
			pl.a0.Position = ground + Vector3.new(0, height * (1 - drop), 0)
			pl.a1.Position = ground + Vector3.new(0, height, 0)
			local w = width * (if u < 0.2 then 1.5 else 1.5 * (1 - ease((u - 0.2) / 0.8)) + 0.05)
			pl.beam.Width0, pl.beam.Width1 = w * 0.7, w * 1.3
			pl.beam.Transparency = NumberSequence.new(math.clamp(0.05 + u * 0.9, 0, 1))
			pl.beam.Enabled = true
			if drop >= 1 and not pl.hit then
				pl.hit = true
				impactAt.Position = ground
				if ring then
					ring:Emit(layer.impact.count or 1)
				end
				if sparks then
					sparks:Emit(layer.sparks.count or 8)
				end
			end
		end
	end)
end

function Signature.dial(kit: Kit, layer: Layer, i: number, at: Vector3)
	local s = kit.s
	local size, life, turns = (layer.size or 6) * s, layer.life or 1.2, layer.turns or 4
	local p = kit.fxPart(`Dial{i}`, Vector3.new(size, size, 0.05), kit.folder)
	local guis: { SurfaceGui } = {}
	local imgs: { ImageLabel } = {}
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local g = Instance.new("SurfaceGui")
		g.Face = face
		g.LightInfluence = 0
		g.Brightness = layer.glow or 2
		g.CanvasSize = Vector2.new(256, 256)
		g.Enabled = false
		g.Parent = p
		table.insert(guis, g)
		table.insert(imgs, kit.sprite(g, layer, s))
	end
	local startAt = -1
	kit.timed(layer, i, function()
		startAt = os.clock()
	end)
	local alpha = layer.alpha or 0
	table.insert(kit.state.movers, function(_t: number, r: CFrame)
		if startAt < 0 then
			return
		end
		local u = (os.clock() - startAt) / life
		if u >= 1 then
			startAt = -1
			for _, g in guis do
				g.Enabled = false
			end
			return
		end
		local k = if u < 0.18 then u / 0.18 else 1
		local grow = 1 + 2.7 * (k - 1) ^ 3 + 1.7 * (k - 1) ^ 2 -- ease-out-back: a little overshoot
		local sz = math.max(0.05, size * grow)
		p.Size = Vector3.new(sz, sz, 0.05)
		p.CFrame = r * CFrame.new(at)
		for _, img in imgs do
			img.Rotation = -turns * 360 * u ^ 1.8 -- spins up faster and faster
			img.ImageTransparency = alpha + (1 - alpha) * math.max(0, (u - 0.7) / 0.3)
		end
		for _, g in guis do
			g.Enabled = true
		end
	end)
end

function Signature.ribbon(kit: Kit, layer: Layer, i: number, _at: Vector3)
	local s = kit.s
	local host = kit.partNamed(layer.part)
	local a0 = kit.attachment(`Ribbon{i}a`, kit.vec(layer.from, s), host)
	local a1 = kit.attachment(`Ribbon{i}b`, Vector3.zero)
	local b = newBeam(kit, layer, a0, a1, true)
	b.Segments = layer.segments or 16
	b.Width0 = (layer.width or 1.4) * s
	b.Width1 = (layer.width1 or 0.4) * s
	table.insert(kit.state.toggles, b)
	local to = kit.vec(layer.to, s)
	local sway = kit.vec(layer.sway or { 0.6, 0.4, 0.4 }, s)
	local hz, phase, curve = layer.hz or 0.35, layer.phase or 0, (layer.curve or 1.5) * s
	table.insert(kit.state.movers, function(t: number, _r: CFrame)
		local w = t * TAU * hz + phase
		a1.Position = to
			+ Vector3.new(sway.X * math.sin(w), sway.Y * math.sin(w * 1.3 + 1), sway.Z * math.sin(w * 0.7 + 2))
		b.CurveSize0 = curve * math.sin(w + 0.5)
		b.CurveSize1 = curve * math.sin(w * 1.2 + 2)
	end)
end

function Signature.trail(kit: Kit, layer: Layer, i: number, _at: Vector3)
	local s = kit.s
	local host = kit.partNamed(layer.part) or kit.root
	local a0 = kit.attachment(`Trail{i}a`, kit.vec(layer.a0, s), host)
	local a1 = kit.attachment(`Trail{i}b`, kit.vec(layer.a1, s), host)
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = layer.life or 0.6
	tr.Color = kit.colors(layer.color)
	tr.Transparency = kit.seq(layer.alpha or { 0.2, 1 }, 1)
	tr.LightEmission = layer.glow or 1
	tr.LightInfluence = 0
	tr.Brightness = layer.bright or 1
	tr.FaceCamera = layer.faceCamera == true
	tr.MinLength = 0.05
	tr.WidthScale = kit.seq(layer.width or { 1, 0.3 }, 1)
	if layer.sprite then
		tr.Texture = kit.Sprites.get(layer.sprite)
		tr.TextureMode = Enum.TextureMode.Stretch
	end
	tr.Parent = host
	table.insert(kit.state.made, tr)
	table.insert(kit.state.toggles, tr)
end

function Signature.curtain(kit: Kit, layer: Layer, i: number, _at: Vector3)
	local s = kit.s
	local count, radius, height = layer.count or 14, (layer.radius or 5.5) * s, (layer.height or 9) * s
	local life, rise, fade = layer.life or 2.6, layer.rise or 0.6, layer.fade or 0.7
	local ripple = (layer.ripple or 1.2) * s
	-- the ring's corners: X points out from the pet (CurveSize bends the veils outward), Y up (the veil's width)
	local fill = layer.fill or 0.7
	local cols = if type(layer.color) == "table" then layer.color else { layer.color or Color3.new(1, 1, 1) }
	local ends: { { Attachment } } = {}
	local dirs: { { Vector3 } } = {}
	local veils: { Beam } = {}
	for k = 1, count do
		local a0 = (k - 1) / count * TAU
		local a1 = a0 + fill * TAU / count
		dirs[k] = { Vector3.new(math.cos(a0), 0, math.sin(a0)), Vector3.new(math.cos(a1), 0, math.sin(a1)) }
		ends[k] = { kit.attachment(`Curtain{i}_{k}a`, Vector3.zero), kit.attachment(`Curtain{i}_{k}b`, Vector3.zero) }
		local b = newBeam(kit, layer, ends[k][1], ends[k][2], false)
		b.Color = ColorSequence.new(cols[(k - 1) % #cols + 1], cols[k % #cols + 1])
		b.Segments = 10
		b.Enabled = false
		veils[k] = b
	end
	local alpha = layer.alpha or 0.2
	local startAt = -1
	kit.timed(layer, i, function()
		startAt = os.clock()
	end)
	table.insert(kit.state.movers, function(t: number, _r: CFrame)
		if startAt < 0 then
			return
		end
		local u = os.clock() - startAt
		if u >= life then
			startAt = -1
			for _, b in veils do
				b.Enabled = false
			end
			return
		end
		local h = height * ease(u / rise)
		local vis = 1 - math.max(0, (u - (life - fade)) / fade)
		for k, pair in ends do
			for e = 1, 2 do
				local d = dirs[k][e]
				pair[e].CFrame = CFrame.fromMatrix(d * radius + Vector3.new(0, h / 2, 0), d, Vector3.yAxis)
			end
		end
		for k, b in veils do
			b.CurveSize0 = ripple * math.sin(t * 3 + k * 1.7)
			b.CurveSize1 = -ripple * math.sin(t * 3 + k * 1.7 + 1.1)
			b.Width0, b.Width1 = math.max(0.05, h), math.max(0.05, h)
			b.Transparency = NumberSequence.new(1 - (1 - alpha) * vis)
			b.Enabled = true
		end
	end)
end

return Signature
