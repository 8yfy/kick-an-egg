--!strict
-- Partner A. The building blocks of a weather look (client only). Each builder takes a spec from Registry and the
-- mixer's shared context and returns an Element:
--   apply(w)   w = the layer's eased weight 0..1 (crossfades drive emitter Rate, beam / part transparency, lights)
--   step(ctx)  per frame: follow the camera / ground, animate (optional)
--   linger     seconds to keep it alive after w reaches 0, so particles already in flight finish naturally
--   destroy()
-- Kinds: volume (a box emitter that follows the camera, the ground under it, or a fixed local storm region),
-- shafts (soft god-ray Beams near the camera), bolts (distant brick lightning + optional thunder), comets (Trail
-- shooting stars with an off-track burst), sky / prop (brick centrepieces from WeatherFx/Sky).
-- Nothing here collides, touches or blocks raycasts, and nothing changes physics or gameplay.
local Sky = require(script.Parent.Sky)

local Elements = {}

export type Ctx = {
	cam: Vector3, -- camera position
	look: Vector3, -- flat (XZ) camera look direction
	yaw: number, -- radians, heading of `look` (0 = +Z)
	ground: number, -- ground height under the camera
	q: number, -- quality 0.25..1 (LowDetail, graphics level, phones)
	reduced: boolean, -- Reduced Motion: no flicker, slower motion
	t: number,
	dt: number,
	folder: Instance,
	pulse: (ev: number, seconds: number) -> (),
	sound: (key: string, at: Vector3?, delay: number?) -> (),
}
export type Element = {
	apply: (w: number) -> (),
	step: ((ctx: Ctx) -> ())?,
	linger: number,
	destroy: () -> (),
}
export type Region = { center: Vector3, size: Vector3 }

local rng = Random.new()

-- Spec value helpers ---------------------------------------------------------------------------------------------
local function seq(v: any): NumberSequence
	if typeof(v) == "NumberSequence" then
		return v
	elseif typeof(v) == "number" then
		return NumberSequence.new(v)
	end
	local list = v :: { number }
	if #list == 1 then
		return NumberSequence.new(list[1])
	end
	local kps = {}
	for i, x in list do
		table.insert(kps, NumberSequenceKeypoint.new((i - 1) / (#list - 1), x))
	end
	return NumberSequence.new(kps)
end
Elements.seq = seq

local function cseq(v: any): ColorSequence
	if typeof(v) == "ColorSequence" then
		return v
	elseif typeof(v) == "Color3" then
		return ColorSequence.new(v)
	end
	local list = v :: { Color3 }
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local kps = {}
	for i, c in list do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#list - 1), c))
	end
	return ColorSequence.new(kps)
end
Elements.cseq = cseq

local function range(v: any): NumberRange
	if typeof(v) == "NumberRange" then
		return v
	elseif typeof(v) == "number" then
		return NumberRange.new(v)
	end
	return NumberRange.new(v[1], v[2])
end

local function maxOf(v: any): number
	local r = range(v)
	return r.Max
end

-- Transparency sequence `base` faded toward invisible by (1 - w).
local function fadeSeq(base: NumberSequence, w: number): NumberSequence
	local kps = {}
	for _, k in base.Keypoints do
		table.insert(kps, NumberSequenceKeypoint.new(k.Time, 1 - (1 - k.Value) * w, k.Envelope))
	end
	return NumberSequence.new(kps)
end
Elements.fadeSeq = fadeSeq

local function holder(size: Vector3, parent: Instance, name: string?): Part
	local p = Instance.new("Part")
	p.Name = name or "WeatherEmitter"
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.CastShadow = false
	p.Size = size
	p.Parent = parent
	return p
end
Elements.holder = holder

-- A ParticleEmitter from a spec (Rate starts at 0; apply() sets it).
function Elements.emitter(spec: { [string]: any }, parent: Instance): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = spec.name or "Weather"
	e.Texture = spec.texture
	e.Color = cseq(spec.color or Color3.new(1, 1, 1))
	e.Size = seq(spec.size or 1)
	e.Transparency = seq(spec.transparency or 0)
	e.Lifetime = range(spec.lifetime or 1)
	e.Speed = range(spec.speed or 0)
	e.Rate = 0
	e.EmissionDirection = spec.direction or Enum.NormalId.Bottom
	e.SpreadAngle = spec.spread or Vector2.zero
	e.Acceleration = spec.accel or Vector3.zero
	e.Drag = spec.drag or 0
	e.Orientation = spec.orientation or Enum.ParticleOrientation.FacingCamera
	e.Squash = seq(spec.squash or 0)
	e.Rotation = range(spec.rotation or 0)
	e.RotSpeed = range(spec.rotSpeed or 0)
	e.LightEmission = spec.lightEmission or 0
	e.LightInfluence = spec.lightInfluence or 0
	e.Brightness = spec.brightness or 1
	e.ZOffset = spec.zOffset or 0
	e.LockedToPart = spec.locked == true
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	if spec.flipbook then
		e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
		e.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
	end
	e.Parent = parent
	return e
end

-- volume ----------------------------------------------------------------------------------------------------------
-- spec: texture, color, size, transparency, lifetime, speed, rate (per second at full weight and quality), box,
-- offset (Vector3), lead (studs ahead of the camera), tilt (Vector3, degrees), where ("camera" | "ground" | "region"),
-- + emitter fields.
function Elements.volume(spec: { [string]: any }, ctx: Ctx, region: Region?): Element
	local where = spec.where or "camera"
	local box: Vector3 = spec.box or (if region then region.size else Vector3.new(100, 2, 100))
	local part = holder(box, ctx.folder, "WeatherVolume")
	local e = Elements.emitter(spec, part)
	local offset: Vector3 = spec.offset or Vector3.zero
	local lead: number = spec.lead or 0
	local rate: number = spec.rate or 10
	local tilt: CFrame = if spec.tilt
		then CFrame.Angles(math.rad(spec.tilt.X), math.rad(spec.tilt.Y), math.rad(spec.tilt.Z))
		else CFrame.identity -- slants the emission (diagonal meteors)
	local weight = 0
	if where == "region" and region then
		part.CFrame = CFrame.new(region.center + offset) * tilt
	end
	return {
		apply = function(w: number)
			weight = w
			e.Rate = rate * w * ctx.q
		end,
		step = if where == "region"
			then function(c: Ctx)
				e.Rate = rate * weight * c.q
			end
			else function(c: Ctx)
				local y = if where == "ground" then c.ground + offset.Y else c.cam.Y + offset.Y
				local pos = Vector3.new(c.cam.X + offset.X, y, c.cam.Z + offset.Z) + c.look * lead
				if (part.Position - pos).Magnitude > 0.25 then
					part.CFrame = CFrame.new(pos) * tilt
				end
			end,
		linger = maxOf(spec.lifetime or 1) + 0.2,
		destroy = function()
			part:Destroy()
		end,
	}
end

-- shafts: soft light shafts (Beams) slanting down from the sun's side, near the camera --------------------------
-- spec: count, color, transparency (mid opacity, 0..1), width {top, bottom}, length, radius {min,max},
-- heading (deg, where the sun is), elevation (deg)
function Elements.shafts(spec: { [string]: any }, ctx: Ctx): Element
	local count: number = spec.count or 3
	local base: number = spec.transparency or 0.8
	local width = spec.width or { 10, 18 }
	local length: number = spec.length or 140
	local r = spec.radius or { 30, 70 }
	local anchor = holder(Vector3.one, ctx.folder, "WeatherShafts")
	local heading = math.rad(spec.heading or 30)
	local elev = math.rad(spec.elevation or 55)
	local sunDir = Vector3.new(math.sin(heading) * math.cos(elev), math.sin(elev), math.cos(heading) * math.cos(elev))
	type Shaft = { a0: Attachment, a1: Attachment, beam: Beam, ang: number, dist: number, phase: number }
	local shafts: { Shaft } = {}
	for i = 1, count do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = anchor, anchor
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.Texture = spec.texture
		b.TextureMode = Enum.TextureMode.Stretch
		b.Width0, b.Width1 = width[1], width[2]
		b.FaceCamera = true
		b.LightEmission = spec.lightEmission or 0.5
		b.LightInfluence = 0
		b.Segments = 12 -- transparency is sampled per segment: 1 segment = only the (invisible) end keys
		b.Brightness = spec.brightness or 2
		b.Color = cseq(spec.color or Color3.fromRGB(255, 230, 160))
		b.Transparency = NumberSequence.new(1)
		b.Parent = anchor
		table.insert(shafts, {
			a0 = a0,
			a1 = a1,
			beam = b,
			ang = (i - (count + 1) / 2) * math.rad(spec.spreadDeg or 38) + rng:NextNumber(-0.15, 0.15),
			dist = rng:NextNumber(r[1], r[2]),
			phase = rng:NextNumber(0, 6.28),
		})
	end
	local weight, shown = 0, -1
	local function paint(t: number, reduced: boolean)
		for _, s in shafts do
			local breathe = if reduced then 1 else 0.75 + 0.25 * math.sin(t * 0.35 + s.phase)
			local mid = 1 - (1 - base) * weight * breathe
			s.beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, mid),
				NumberSequenceKeypoint.new(0.75, mid),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end
	return {
		apply = function(w: number)
			weight = w
		end,
		step = function(c: Ctx)
			anchor.CFrame = CFrame.new(c.cam)
			for _, s in shafts do
				local a = c.yaw + s.ang
				local foot = Vector3.new(math.sin(a) * s.dist, c.ground - c.cam.Y - 2, math.cos(a) * s.dist)
				s.a1.Position = foot
				s.a0.Position = foot + sunDir * length
			end
			-- transparency only while it fades or breathes (a few NumberSequences per frame at most)
			if math.abs(weight - shown) > 0.004 or (not c.reduced and weight > 0) then
				shown = weight
				paint(c.t, c.reduced)
			end
		end,
		linger = 0,
		destroy = function()
			anchor:Destroy()
		end,
	}
end

-- bolts: distant brick lightning (never full-screen strobe) ----------------------------------------------------------
-- spec: interval {min,max}, distance {min,max}, cone (deg either side of the view), height, color, width,
-- exposure (EV pulse, 0 = none), thunder ({sound keys}) played at the strike with a distance delay
function Elements.bolts(spec: { [string]: any }, ctx: Ctx): Element
	local SEGS = 6
	local color: Color3 = spec.color or Color3.fromRGB(200, 225, 255)
	local segs: { BasePart } = {}
	for i = 1, SEGS do
		local p = holder(Vector3.one, ctx.folder, "Bolt")
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = 1
		segs[i] = p
	end
	local glow = holder(Vector3.one, ctx.folder, "BoltGlow")
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 60
	light.Brightness = 0
	light.Shadows = false
	light.Parent = glow
	local interval = spec.interval or { 5, 10 }
	local dist = spec.distance or { 220, 360 }
	local cone = math.rad(spec.cone or 55)
	local weight = 0
	local nextAt = ctx.t + rng:NextNumber(1.5, 3)
	local struckAt = -math.huge
	local lastPulse = -math.huge
	local function strike(c: Ctx)
		local a = c.yaw + rng:NextNumber(-cone, cone)
		local d = rng:NextNumber(dist[1], dist[2])
		local foot = Vector3.new(c.cam.X + math.sin(a) * d, c.ground, c.cam.Z + math.cos(a) * d)
		local top = Vector3.new(foot.X, c.cam.Y + (spec.height or 150), foot.Z)
		local pts = { top }
		for i = 1, SEGS - 1 do
			local k = i / SEGS
			local side = Vector3.new(math.cos(a), 0, -math.sin(a))
			table.insert(
				pts,
				top:Lerp(foot, k) + side * rng:NextNumber(-9, 9) + Vector3.new(0, rng:NextNumber(-4, 4), 0)
			)
		end
		table.insert(pts, foot)
		local width: number = spec.width or 2.2
		for i = 1, SEGS do
			local p0, p1 = pts[i], pts[i + 1]
			local len = (p1 - p0).Magnitude
			segs[i].Size = Vector3.new(width, width, len + width)
			segs[i].CFrame = CFrame.lookAt(p0:Lerp(p1, 0.5), p1)
		end
		glow.CFrame = CFrame.new(top)
		struckAt = c.t
		if (spec.exposure or 0) > 0 and not c.reduced and c.t - lastPulse > 3 then
			lastPulse = c.t
			c.pulse(spec.exposure, 0.35)
		end
		local thunder = spec.thunder
		if thunder and #thunder > 0 then
			c.sound(thunder[rng:NextInteger(1, #thunder)], foot, 0.25 + d / 420)
		end
	end
	return {
		apply = function(w: number)
			weight = w
		end,
		step = function(c: Ctx)
			if weight > 0.45 and c.t >= nextAt then
				nextAt = c.t + rng:NextNumber(interval[1], interval[2]) / math.max(weight, 0.5)
				strike(c)
			end
			local k = c.t - struckAt
			local alpha: number -- 0 = fully visible
			if k > 0.7 then
				alpha = 1
			elseif c.reduced then
				alpha = 0.25 + 0.75 * (k / 0.7) -- one soft fade, no flicker
			elseif k < 0.06 then
				alpha = 0
			elseif k < 0.11 then
				alpha = 0.65
			elseif k < 0.18 then
				alpha = 0.05
			else
				alpha = math.clamp((k - 0.18) / 0.5, 0, 1)
			end
			alpha = 1 - (1 - alpha) * weight
			if segs[1].Transparency ~= alpha then
				for _, p in segs do
					p.Transparency = alpha
				end
				light.Brightness = (1 - alpha) * (spec.light or 4)
			end
		end,
		linger = 0.8,
		destroy = function()
			for _, p in segs do
				p:Destroy()
			end
			glow:Destroy()
		end,
	}
end

-- comets: shooting stars with Trails, ending in a small far burst ----------------------------------------------------
-- spec: interval {min,max}, distance {min,max}, cone, height {min,max}, size, headColor, trail (colours), burst
-- (texture), duration {min,max}, sound (key, played for some of them)
function Elements.comets(spec: { [string]: any }, ctx: Ctx): Element
	local POOL = 3
	type Comet = { part: BasePart, trail: Trail, p0: Vector3, p1: Vector3, t0: number, dur: number, live: boolean }
	local comets: { Comet } = {}
	local size: number = spec.size or 2.4
	for _ = 1, POOL do
		local p = holder(Vector3.one * size, ctx.folder, "Comet")
		p.Material = Enum.Material.Neon
		p.Color = spec.headColor or Color3.fromRGB(255, 220, 140)
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Position, a1.Position = Vector3.new(0, size * 0.45, 0), Vector3.new(0, -size * 0.45, 0)
		a0.Parent, a1.Parent = p, p
		local tr = Instance.new("Trail")
		tr.Attachment0, tr.Attachment1 = a0, a1
		tr.Lifetime = spec.trailLife or 0.55
		tr.FaceCamera = true
		tr.LightEmission = 1
		tr.LightInfluence = 0
		if spec.trailTexture then
			tr.Texture = spec.trailTexture
		end
		tr.Color = cseq(spec.trail or { Color3.fromRGB(255, 240, 200), Color3.fromRGB(255, 120, 200) })
		tr.Transparency = NumberSequence.new(0.1, 1)
		tr.WidthScale = NumberSequence.new(1, 0.1)
		tr.Enabled = false
		tr.Parent = p
		table.insert(
			comets,
			{ part = p, trail = tr, p0 = Vector3.zero, p1 = Vector3.zero, t0 = 0, dur = 1, live = false }
		)
	end
	local burstPart = holder(Vector3.one * 2, ctx.folder, "CometBurst")
	local burst = Elements.emitter({
		texture = spec.burst,
		color = spec.trail or Color3.fromRGB(255, 220, 160),
		size = { 2.5, 0 },
		transparency = { 0, 1 },
		lifetime = { 0.5, 0.9 },
		speed = { 10, 22 },
		spread = Vector2.new(180, 180),
		lightEmission = 1,
	}, burstPart)
	local interval = spec.interval or { 1, 2.5 }
	local dist = spec.distance or { 240, 380 }
	local cone = math.rad(spec.cone or 50)
	local heights = spec.height or { 150, 220 }
	local durs = spec.duration or { 1.1, 1.7 }
	local weight = 0
	local nextAt = ctx.t + 0.8
	local function launch(c: Ctx, cm: Comet)
		local a = c.yaw + rng:NextNumber(-cone, cone)
		local d = rng:NextNumber(dist[1], dist[2])
		local side = Vector3.new(math.cos(a), 0, -math.sin(a)) * (if rng:NextNumber() < 0.5 then -1 else 1)
		local start = Vector3.new(
			c.cam.X + math.sin(a) * d,
			c.cam.Y + rng:NextNumber(heights[1], heights[2]),
			c.cam.Z + math.cos(a) * d
		)
		cm.p0 = start - side * 70
		cm.p1 = start + side * rng:NextNumber(90, 150) - Vector3.new(0, rng:NextNumber(70, 120), 0)
		cm.t0, cm.dur, cm.live = c.t, rng:NextNumber(durs[1], durs[2]), true
		cm.trail.Enabled = false
		cm.part.CFrame = CFrame.new(cm.p0)
		cm.trail:Clear()
		cm.part.Transparency = 0
		if spec.sound and rng:NextNumber() < (spec.soundChance or 0.5) then
			c.sound(spec.sound, start, 0)
		end
	end
	return {
		apply = function(w: number)
			weight = w
		end,
		step = function(c: Ctx)
			if weight > 0.3 and c.t >= nextAt then
				nextAt = c.t + rng:NextNumber(interval[1], interval[2]) / (weight * math.max(c.q, 0.5))
				for _, cm in comets do
					if not cm.live then
						launch(c, cm)
						break
					end
				end
			end
			for _, cm in comets do
				if cm.live then
					local k = (c.t - cm.t0) / cm.dur
					if k >= 1 then
						cm.live = false
						cm.part.Transparency = 1
						cm.trail.Enabled = false
						burstPart.CFrame = CFrame.new(cm.p1)
						burst:Emit(math.max(4, math.floor(14 * c.q)))
					else
						cm.trail.Enabled = true
						local e = k * k * (3 - 2 * k) * 0.35 + k * 0.65
						cm.part.CFrame = CFrame.new(cm.p0:Lerp(cm.p1, e)) * CFrame.Angles(c.t * 3, c.t * 2, 0)
					end
				end
			end
		end,
		linger = 1.2,
		destroy = function()
			for _, cm in comets do
				cm.part:Destroy()
			end
			burstPart:Destroy()
		end,
	}
end

-- sky / prop: brick centrepieces (WeatherFx/Sky) ---------------------------------------------------------------------
-- spec: prop (Sky builder name), heading (deg from the camera's world +Z; "view" = in front of the camera), distance,
-- altitude (above the camera), billboard (face the camera), + builder params. For where = "region" the prop stands at
-- the region centre + offset instead.
function Elements.sky(spec: { [string]: any }, ctx: Ctx, region: Region?): Element
	local prop = Sky.build(spec.prop, spec, ctx.folder)
	local heading = math.rad(spec.heading or 0)
	local distance: number = spec.distance or 0
	local altitude: number = spec.altitude or 0
	local weight = 0
	local fixed: CFrame? = nil
	if spec.where == "region" and region then
		fixed = CFrame.new(region.center + (spec.offset or Vector3.zero)) * CFrame.Angles(0, math.rad(spec.yaw or 0), 0)
	end
	return {
		apply = function(w: number)
			weight = w
			prop.fade(w, ctx.q)
		end,
		step = function(c: Ctx)
			local root: CFrame
			if fixed then
				root = fixed
			else
				local dir = Vector3.new(math.sin(heading), 0, math.cos(heading))
				local pos = Vector3.new(c.cam.X, c.cam.Y + altitude, c.cam.Z) + dir * distance
				if spec.billboard then
					root = CFrame.lookAt(pos, Vector3.new(c.cam.X, pos.Y, c.cam.Z))
				else
					root = CFrame.new(pos) * CFrame.Angles(0, heading, 0)
				end
			end
			if weight > 0 then
				prop.place(root, c.t, c.reduced)
			end
		end,
		linger = prop.linger,
		destroy = prop.destroy,
	}
end

function Elements.build(spec: { [string]: any }, ctx: Ctx, region: Region?): Element?
	local kind = spec.kind
	if kind == "volume" then
		return Elements.volume(spec, ctx, region)
	elseif kind == "shafts" then
		return Elements.shafts(spec, ctx)
	elseif kind == "bolts" then
		return Elements.bolts(spec, ctx)
	elseif kind == "comets" then
		return Elements.comets(spec, ctx)
	elseif kind == "sky" then
		return Elements.sky(spec, ctx, region)
	end
	warn(`[WeatherFx] unknown element kind {kind}`)
	return nil
end

return Elements
