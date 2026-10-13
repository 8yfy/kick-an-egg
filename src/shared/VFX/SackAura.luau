--!strict
-- Kick Sack idle VFX, tiers 1-20 (client). Ported from the "Kick Sacks VFX Remodel" bundle (SackVFX.lua,
-- matched to its web preview); the per-tier effect code below is the bundle's, unchanged apart from three
-- orbit `field`s written as the equivalent `spin` (tiers 8, 19, 20) for the native-particle path.
-- Changes for this game (Partner B):
--   * the sacks are BlockBuilder data (Builders/Models/Sacks, converted from the remodel), so effects are
--     placed from the sack's bag-bottom frame and scale (Sacks.vfxRoot / Sacks.SCALE), not a mesh's bounds;
--   * Apply(..., driven = true) leaves the stepping to the caller (SackController moves the sack every
--     frame, then calls ctx:step), otherwise the effect runs itself (the base stands);
--   * particle textures are the bundle's PNGs (assets/sack-vfx/), uploaded: ids in UPLOADED below.
-- Part names (glowParts, rigs) are the remodel's mesh names, kept by the converter.
local RunService = game:GetService("RunService")

local SackVFX = {}

-- Uploaded image ids for assets/sack-vfx/sackvfx_<name>.png (Krono808, 2026-10-12). Missing = built-in fallback.
local UPLOADED: { [string]: string } = {
	glow = "rbxassetid://71769032644460",
	spark = "rbxassetid://93549276919655",
	star = "rbxassetid://101074548689105",
	smoke = "rbxassetid://90864470326650",
	square = "rbxassetid://113457082493281",
	ring = "rbxassetid://98854133664400",
	sunburst = "rbxassetid://100264183171540",
	galaxy = "rbxassetid://126996644416188",
}
local BUILTIN: { [string]: string } = {
	glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	star = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	square = "rbxasset://textures/particles/SquareParticle.png",
	ring = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	sunburst = "rbxasset://textures/particles/explosion01_core_main.dds",
	galaxy = "rbxasset://textures/particles/forcefield_vortex_main.dds",
}
SackVFX.Textures = {} :: { [string]: string }
for name, id in BUILTIN do
	-- Studio only: the real sprite from the local content copy (tools/preview/stage-art.sh) until uploaded
	local studio = if RunService:IsStudio() then `rbxasset://textures/KickTheEggUI/sackvfx_{name}.png` else nil
	SackVFX.Textures[name] = UPLOADED[name] or studio or id
	if not UPLOADED[name] and not studio then -- never fall back silently
		warn(
			`[SackAura] sackvfx_{name}.png has no uploaded image id: using a built-in fallback (tools/sacks/IMPORT.md)`
		)
	end
end

local FRONT = 1
local TAU = math.pi * 2
SackVFX.Quality = 1
SackVFX.SizeScale = 1

local Shape = Enum.ParticleEmitterShape
local Style = Enum.ParticleEmitterShapeStyle
local InOut = Enum.ParticleEmitterShapeInOut
local Orient = Enum.ParticleOrientation

local function rnd(a: number, b: number): number
	return a + math.random() * (b - a)
end
local function hex(h: string): Color3
	return Color3.fromHex(h)
end
local function rgb(r: number, g: number, b: number): Color3
	return Color3.new(r, g, b)
end
local function hsl(h: number, s: number, l: number): Color3
	h = h % 1
	local a = s * math.min(l, 1 - l)
	local function f(n: number): number
		local k = (n + h * 12) % 12
		return l - a * math.max(-1, math.min(k - 3, 9 - k, 1))
	end
	return Color3.new(f(0), f(8), f(4))
end
local function NS(t: { { number } }): NumberSequence
	local k = {}
	for _, p in ipairs(t) do
		k[#k + 1] = NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0)
	end
	return NumberSequence.new(k)
end
local function CS(t: { { any } }): ColorSequence
	local k = {}
	for _, p in ipairs(t) do
		k[#k + 1] = ColorSequenceKeypoint.new(p[1], p[2])
	end
	return ColorSequence.new(k)
end
local function starts(n: string, p: string): boolean
	return string.sub(n, 1, #p) == p
end
local function prefix(...: string): (string) -> boolean
	local list = { ... }
	return function(n: string)
		for _, p in ipairs(list) do
			if starts(n, p) then
				return true
			end
		end
		return false
	end
end

local FADE = NS({ { 0, 1 }, { 0.15, 0 }, { 0.6, 0.1 }, { 1, 1 } })
local TWINKLE = NS({ { 0, 1 }, { 0.15, 0.1 }, { 0.3, 0.7 }, { 0.45, 0.05 }, { 0.6, 0.6 }, { 0.8, 0.15 }, { 1, 1 } })
local RAINBOW = CS({
	{ 0, hex("ff3b4f") },
	{ 0.17, hex("ff9a2e") },
	{ 0.33, hex("ffe94a") },
	{ 0.5, hex("4ff07a") },
	{ 0.67, hex("3fb4ff") },
	{ 0.83, hex("9a5bff") },
	{ 1, hex("ff4fd0") },
})

----------------------------------------------------------------- context
-- Performance (Boxing Sack VFX optimization, docs/SackVfxPerformance.md). The look of every tier is unchanged;
-- what changed is who does the work:
--   * swarms (the preview's hand-simulated particles) used to be moved by Lua every frame: one attachment
--     position, one size and one transparency write per particle per frame, each allocating a new sequence.
--     Now every particle whose path is a straight / falling / dragged line (most of them) is launched once per
--     life as a real particle: its spawn spot, velocity, gravity, drag, size growth, fades, twinkle and colour
--     over life are baked into that one particle and the engine moves it. Lua only respawns it. Swarms that
--     orbit the sack (`spin`) or turn in a `frame` ride an invisible part that is turned once per frame. Only
--     swarms with a free-form `field` are still moved by Lua, and they now write a property only when its
--     (quantised, cached) value changes.
--   * rings, orbiters, wings and turning frames are moved with one workspace:BulkMoveTo per step.
--   * levels of detail and quality profiles (VFX/SackLod) park particles, slow the Lua updates, turn lights and
--     lightning off, and hide everything far away, without destroying and rebuilding the effect.
local SackLod = require(script.Parent.SackLod)

local LN2 = math.log(2)
local WHITE = Color3.new(1, 1, 1)
local SEG_STRETCH = 1.15 -- a launched particle outlives its segment by 15%, so a respawn a frame late never gaps
local STREAM_FLOOR = 0.3 -- streaming emitters keep at least this share of their rate at any visible level
local ACTIVATE_BUDGET = 64 -- particles brought in per step: a new / nearer sack fills in over a few frames, no spike
-- Density boost for the top sacks, so Galaxy Void, Sun Guardian and Rainbow God stay premium further out.
local PREMIUM: { [number]: number } = { [18] = 1.3, [19] = 1.3, [20] = 1.3 }

-- shared, allocated once: transparency in 1/64 steps, constant sizes by 1/400 stud, colours by 6 bits a channel
local ALPHA_STEPS = 64
local ALPHA_SEQ: { [number]: NumberSequence } = {}
for i = 0, ALPHA_STEPS do
	ALPHA_SEQ[i] = NumberSequence.new(1 - i / ALPHA_STEPS)
end
local SIZE_SEQ: { [number]: NumberSequence } = {}
local function constSize(studs: number): (NumberSequence, number)
	local key = math.max(1, math.floor(studs * 400 + 0.5))
	local s = SIZE_SEQ[key]
	if not s then
		s = NumberSequence.new(key / 400)
		SIZE_SEQ[key] = s
	end
	return s, key
end
local COLOR_SEQ: { [number]: ColorSequence } = {}
local function q6(x: number): number
	return math.floor(math.clamp(x, 0, 1) * 63 + 0.5)
end
local function colorSeq(c: Color3): (ColorSequence, number)
	local key = q6(c.R) * 4096 + q6(c.G) * 64 + q6(c.B)
	local s = COLOR_SEQ[key]
	if not s then
		s = ColorSequence.new(c)
		COLOR_SEQ[key] = s
	end
	return s, key
end
local function alphaLevel(a: number): number
	return math.floor(math.clamp(a, 0, 1) * ALPHA_STEPS + 0.5)
end

-- Position and velocity after `a` seconds with constant gravity `g` and drag `d` (v' = g - d v), exactly.
local function motion(p0: Vector3, v0: Vector3, g: Vector3, d: number, a: number): (Vector3, Vector3)
	if d > 1e-6 then
		local k = math.exp(-d * a)
		local term = g / d
		return p0 + term * a + (v0 - term) * ((1 - k) / d), term + (v0 - term) * k
	end
	return p0 + v0 * a + g * (0.5 * a * a), v0 + g * a
end

-- Attachment frame at `pos` whose +Y (the emitter's Top) points along the unit vector `dir`.
local function aim(pos: Vector3, dir: Vector3): CFrame
	local axis = Vector3.yAxis:Cross(dir)
	local m = axis.Magnitude
	if m < 1e-5 then
		return if dir.Y >= 0 then CFrame.new(pos) else CFrame.new(pos) * CFrame.Angles(math.pi, 0, 0)
	end
	return CFrame.new(pos) * CFrame.fromAxisAngle(axis / m, math.acos(math.clamp(dir.Y, -1, 1)))
end

local function scaled(f: CFrame, S: number): CFrame
	return CFrame.new(f.Position * S) * f.Rotation
end

local active: { [Model]: any } = {}

local Ctx: any = {}
Ctx.__index = Ctx

-- `rootCF`: world CFrame of the bag bottom with the remodel's front (+Z) turned to face the sack's front;
-- `S`: studs per metre of the remodel.
function Ctx.new(model: Model, rootCF: CFrame, S: number)
	local self = setmetatable({
		model = model,
		loops = {},
		t = 0,
		S = S,
		tier = 0,
		swarms = {},
		emitters = {}, -- { e, rate, keep }: engine emitters (keep = glows / pulses, never thinned)
		lights = {}, -- { l, a }
		neons = {},
		boltList = {},
		moveParts = {},
		moveCFs = {},
		pending = {}, -- { swarm, particle } waiting to be brought in (ACTIVATE_BUDGET per step)
		lod = SackLod.FULL,
		visible = true,
		hidden = false,
		density = 0, -- particles start parked; the first setLod brings in the right share
		stride = 1,
		lightsOn = true,
		boltShare = 1,
		frameNo = 0,
		loopDt = 0,
	}, Ctx)
	self.folder = Instance.new("Folder")
	self.folder.Name = "SackVFX"
	local root = Instance.new("Part")
	root.Name = "SackVFX_Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.CanCollide, root.CanQuery, root.CanTouch, root.Massless = false, false, false, true
	root.CFrame = rootCF
	root.Anchored = true
	root.Parent = self.folder
	self.root = root
	self.folder.Parent = model
	return self
end

function Ctx:cf(x, y, z)
	local S = self.S
	return CFrame.new(x * S, y * S, z * S * FRONT)
end
function Ctx:world(x, y, z)
	return self.root.CFrame * self:cf(x, y, z)
end

-- Bounding sphere for SackLod (centre on the bag, radius covering the effects).
function Ctx:bounds(): (Vector3, number)
	return (self.root.CFrame * CFrame.new(0, 0.6 * self.S, 0)).Position, 1.5 * self.S
end

-- Queues a part move; flush() sends the whole step's moves in one BulkMoveTo.
function Ctx:move(part: BasePart, cf: CFrame)
	local n = #self.moveParts + 1
	self.moveParts[n] = part
	self.moveCFs[n] = cf
end
function Ctx:flush()
	if #self.moveParts > 0 then
		workspace:BulkMoveTo(self.moveParts, self.moveCFs, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(self.moveParts)
		table.clear(self.moveCFs)
	end
end

function Ctx:attach(x, y, z, rot)
	local a = Instance.new("Attachment")
	a.CFrame = self:cf(x, y, z) * (rot or CFrame.new())
	a.Parent = self.root
	return a
end

function Ctx:fix(p)
	if self.root.Anchored then
		p.Anchored = true
	else
		p.Anchored = false
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1, w.Parent = self.root, p, p
	end
end

-- invisible emission volume, sizes in metres
function Ctx:volume(sx, sy, sz, x, y, z)
	local S = self.S
	local p = Instance.new("Part")
	p.Name = "SackVFX_Volume"
	p.Size = Vector3.new(sx * S, sy * S, sz * S)
	p.Transparency = 1
	p.CanCollide, p.CanQuery, p.CanTouch, p.Massless, p.CastShadow = false, false, false, true, false
	p.CFrame = self:world(x, y, z)
	self:fix(p)
	p.Parent = self.folder
	return p
end

-- ParticleEmitter; sizes, speeds and acceleration are in metres. `o.keep`: never thinned by the level of detail.
function Ctx:emit(parent, o)
	local S = self.S
	local e = Instance.new("ParticleEmitter")
	e.Texture = SackVFX.Textures[o.tex or "glow"]
	e.Color = o.color or ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = o.light or 1
	e.LightInfluence = o.influence or 0
	e.Brightness = o.brightness or 1
	local rate = o.rate or 20
	e.Rate = rate >= 5 and not o.keep and rate * SackVFX.Quality or rate
	e.Lifetime = NumberRange.new(o.life[1], o.life[2])
	local sp = o.speed or { 0, 0 }
	e.Speed = NumberRange.new(sp[1] * S, sp[2] * S)
	e.SpreadAngle = o.spread or Vector2.new(0, 0)
	e.Acceleration = (o.accel or Vector3.zero) * S
	e.Drag = o.drag or 0
	e.Rotation = o.rot or NumberRange.new(0, 360)
	e.RotSpeed = o.rotSpeed or NumberRange.new(0, 0)
	e.Orientation = o.orient or Orient.FacingCamera
	e.EmissionDirection = o.dir or Enum.NormalId.Top
	e.LockedToPart = o.locked or false
	e.ZOffset = o.z or 0
	if o.shape then
		e.Shape = o.shape
		e.ShapeStyle = o.style or Style.Volume
		e.ShapeInOut = o.inout or InOut.Outward
	end
	local sz = {}
	for _, p in ipairs(o.size) do
		sz[#sz + 1] = { p[1], p[2] * S * SackVFX.SizeScale }
	end
	e.Size = NS(sz)
	e.Transparency = o.alpha or FADE
	e.Parent = parent
	table.insert(self.emitters, { e = e, rate = e.Rate, keep = o.keep == true or rate < 5 })
	return e
end

-- soft additive glow that stays put (or follows its parent part)
function Ctx:sprite(parent, color, size, transparency)
	return self:emit(parent, {
		tex = "glow",
		keep = true,
		color = ColorSequence.new(color),
		rate = 5,
		life = { 0.8, 0.8 },
		size = { { 0, size }, { 1, size } },
		rot = NumberRange.new(0, 0),
		locked = true,
		alpha = NS({ { 0, 1 }, { 0.3, transparency }, { 0.7, transparency }, { 1, 1 } }),
	})
end

function Ctx:light(x, y, z, color, brightness, range)
	local a = self:attach(x, y, z)
	local l = Instance.new("PointLight")
	l.Color, l.Brightness, l.Range, l.Shadows = color, brightness, range * self.S, false
	l.Parent = a
	table.insert(self.lights, { l = l, a = a })
	return l
end

function Ctx:neon(shape, sx, sy, sz, color, transparency)
	local S = self.S
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = Vector3.new(sx * S, sy * S, sz * S)
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency or 0
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Anchored = false, false, false, false, true
	p:SetAttribute("SackVFX_Placed", true) -- placed by the effect every step: sack movers leave it alone
	p.Parent = self.folder
	table.insert(self.neons, p)
	return p
end

-- horizontal ring built from neon segments
function Ctx:ring(radius, thick, height, n, color, transparency)
	local segs = {}
	local len = TAU * radius / n * 1.1
	for i = 1, n do
		segs[i] = self:neon(nil, len, height, thick, color, transparency)
	end
	local ring = {}
	local colorKey = -1
	function ring.place(cf: CFrame, r: number?)
		local rr = (r or radius) * self.S
		for i, s in ipairs(segs) do
			self:move(s, cf * CFrame.Angles(0, (i / n) * TAU, 0) * CFrame.new(0, 0, rr))
		end
	end
	function ring.color(c: Color3)
		local _, key = colorSeq(c)
		if key == colorKey then
			return
		end
		colorKey = key
		for _, s in ipairs(segs) do
			s.Color = c
		end
	end
	return ring
end

function Ctx:find(match)
	local out = {}
	for _, d in ipairs(self.model:GetDescendants()) do
		if d:IsA("BasePart") and not d:IsDescendantOf(self.folder) and match(d.Name) then
			out[#out + 1] = d
		end
	end
	-- parity checks (tools/perf/SackParity): how many named parts this tier's effects found on this model
	self.found = (self.found or 0) + #out
	self.lookups = (self.lookups or 0) + 1
	if #out == 0 then
		self.missed = (self.missed or 0) + 1
	end
	return out
end

function Ctx:glowParts(match, color)
	local list = self:find(match)
	for _, p in ipairs(list) do
		p.Material = Enum.Material.Neon
		if color then
			p.Color = color
		end
	end
	return list
end

-- free imported parts so they can swing around a pivot (model-space metres)
function Ctx:rig(parts, px, py, pz)
	local pivot = self:world(px, py, pz)
	local list = {}
	for _, p in ipairs(parts) do
		for _, j in ipairs(p:GetJoints()) do
			j:Destroy()
		end
		p.Anchored = true
		local rel = p:GetAttribute("SackVFX_Rest")
		if not rel then
			rel = pivot:ToObjectSpace(p.CFrame)
			p:SetAttribute("SackVFX_Rest", rel)
		end
		list[#list + 1] = { part = p, rel = rel }
	end
	return { list = list, px = px, py = py, pz = pz }
end

function Ctx:pose(rig, rot)
	local pivot = self:world(rig.px, rig.py, rig.pz)
	for _, e in ipairs(rig.list) do
		self:move(e.part, pivot * rot * e.rel)
	end
end

function Ctx:orbit(part, o)
	local spin = CFrame.new()
	local ph = o.phase or 0
	self:every(function(t: number, dt: number)
		local S, a = self.S, t * o.speed + ph
		if o.spin then
			spin = spin * CFrame.Angles(dt * o.spin, dt * o.spin * 1.3, 0)
		end
		self:move(
			part,
			self.root.CFrame
				* CFrame.new(0, o.y * S, 0)
				* CFrame.Angles(o.tilt or 0, 0, o.tiltZ or 0)
				* CFrame.new(math.cos(a) * o.r * S, math.sin(t * 1.3 + ph) * (o.bob or 0) * S, math.sin(a) * o.r * S)
				* spin
		)
	end)
end

function Ctx:every(fn)
	self.loops[#self.loops + 1] = fn
end

-- swarms -------------------------------------------------------------------------------------------------------
-- Port of the preview's emit(): every particle runs the same spawn / fade code, one particle per emitter so it
-- keeps Roblox's additive glow. Units are metres in sack space. Options as before, plus `spin` (rad/s): the
-- particles orbit the sack's axis at that rate (what the old `field` V3(-z * w, vy, x * w) did, now exact and
-- done by turning one part).

local function spawnParticle(sw: any, p: any, t: number)
	local o = sw.o
	local q = { p = Vector3.zero, v = Vector3.zero, c = o.color or WHITE, s = o.size or 0.04, life = 1, a = 1 }
	o.spawn(q, p.i)
	p.pos, p.vel, p.s0, p.life, p.am, p.col, p.born = q.p, q.v, q.s, q.life, q.a, q.c, t
	if sw.spinOnly then
		-- in the turning frame: the spawn spot as it is right now, moving only up / down from here
		p.pos = sw.frame(t):PointToObjectSpace(q.p)
		p.vel = Vector3.new(0, q.v.Y, 0)
	end
end

local function sizeAt(sw: any, p: any, k: number): number
	local o = sw.o
	local f = if sw.sizeMode == 1 then 1 + k * o.grow elseif sw.sizeMode == 2 then 1 - k * o.shrink else 1
	return p.s0 * math.max(f, 0)
end

local function alphaAt(sw: any, p: any, age: number): number
	local k = age / p.life
	if k > 1 then
		return 0
	end
	local o = sw.o
	local a = if o.alphaFn
		then o.alphaFn(k)
		else ((k < sw.fi and k / sw.fi) or (k > 1 - sw.fo and (1 - k) / sw.fo) or 1)
	if o.twinkle then
		a *= 0.45 + 0.55 * math.abs(math.sin((p.born + age) * o.twinkle + p.i * 7.31))
	end
	return math.clamp(a * sw.A * p.am, 0, 1)
end

-- Size over one launched segment [age, age + dur] (straight lines in k, so 2-3 keypoints are exact).
local function sizeSeqFor(sw: any, p: any, age: number, dur: number, SS: number, fresh: boolean): NumberSequence
	if sw.sizeMode == 0 then
		return (constSize(p.s0 * SS))
	end
	local key = math.floor(p.s0 * SS * 400 + 0.5)
	if fresh and sw.sizeCache[key] then
		return sw.sizeCache[key]
	end
	local L = p.life
	local kps = { NumberSequenceKeypoint.new(0, sizeAt(sw, p, age / L) * SS) }
	local uEnd = (L - age) / dur
	if uEnd < 1 then
		kps[#kps + 1] = NumberSequenceKeypoint.new(uEnd, sizeAt(sw, p, 1) * SS)
	end
	kps[#kps + 1] = NumberSequenceKeypoint.new(1, sizeAt(sw, p, math.min((age + dur) / L, 1)) * SS)
	local seq = NumberSequence.new(kps)
	if fresh then
		sw.sizeCache[key] = seq
	end
	return seq
end

-- Transparency over a segment: exact corner points for plain fades, sampled for twinkle / alphaFn.
local function alphaSeqFor(sw: any, p: any, age: number, dur: number, fresh: boolean): NumberSequence
	local o = sw.o
	local kps = {}
	if o.twinkle or o.alphaFn then
		local n = if o.twinkle then 20 else 12
		for j = 0, n - 1 do
			local u = j / (n - 1)
			kps[j + 1] = NumberSequenceKeypoint.new(u, 1 - alphaAt(sw, p, age + u * dur))
		end
		return NumberSequence.new(kps)
	end
	local key = math.floor(p.am * 64 + 0.5)
	if fresh and sw.alphaCache[key] then
		return sw.alphaCache[key]
	end
	local L, last = p.life, -1
	local ages = { age, sw.fi * L, (1 - sw.fo) * L, L, L + dur * 1e-3, age + dur }
	table.sort(ages)
	for _, a in ages do
		local u = (a - age) / dur
		if u >= 0 and u <= 1 and u > last + 1e-4 then
			kps[#kps + 1] = NumberSequenceKeypoint.new(u, 1 - alphaAt(sw, p, a))
			last = u
		end
	end
	if kps[#kps].Time < 1 then
		kps[#kps + 1] = NumberSequenceKeypoint.new(1, 1 - alphaAt(sw, p, age + dur))
	end
	local seq = NumberSequence.new(kps)
	if fresh then
		sw.alphaCache[key] = seq
	end
	return seq
end

local function colorSeqFor(sw: any, p: any, age: number, dur: number): ColorSequence
	local o = sw.o
	if not o.colorLife then
		return (colorSeq(p.col))
	end
	local kps = table.create(10)
	for j = 0, 9 do
		local u = j / 9
		local a = age + u * dur
		kps[j + 1] = ColorSequenceKeypoint.new(u, o.colorLife(math.min(a / p.life, 1), p.i, p.born + a))
	end
	return ColorSequence.new(kps)
end

-- (Re)launches particle `p` as a real particle at `age` into its life, for one segment.
local function launch(self: any, sw: any, p: any, age: number)
	local S = self.S
	local pos, vel = motion(p.pos, p.vel, sw.g, sw.drag, age)
	local seg = math.min(p.life - age, sw.segMax)
	local dur = seg * SEG_STRETCH
	local fresh = age == 0 and seg == p.life
	local vs = vel * S
	local speed = vs.Magnitude
	local frame = aim(pos * S, if speed > 1e-4 then vs / speed else Vector3.yAxis)
	p.a.CFrame = frame
	local e = p.e
	-- a locked particle's acceleration is in its attachment's space (checked in Studio): undo the aim
	e.Acceleration = frame:VectorToObjectSpace(sw.g * S)
	e.Speed = NumberRange.new(speed)
	e.Lifetime = NumberRange.new(dur)
	e.Size = sizeSeqFor(sw, p, age, dur, S * SackVFX.SizeScale, fresh)
	e.Transparency = alphaSeqFor(sw, p, age, dur, fresh)
	e.Color = colorSeqFor(sw, p, age, dur)
	e:Clear()
	e:Emit(1)
	p.due = p.born + age + seg
end

local function activate(self: any, sw: any, p: any)
	p.active = true
	local t = self.t
	spawnParticle(sw, p, t)
	local age = math.random() * math.min(p.life, 1e4) -- start mid-life, like the preview's warm start
	p.born = t - age
	if sw.sim then
		p.last, p.emitted, p.alphaLevel, p.sizeKey = t, -math.huge, -1, -1
		local _, key = colorSeq(p.col)
		p.colorKey = key
		p.e.Color = (colorSeq(p.col))
	else
		launch(self, sw, p, age)
	end
end

local function park(p: any)
	p.active, p.queued = false, false
	p.e:Clear()
end

-- Brings in up to ACTIVATE_BUDGET queued particles.
local function activatePending(self: any)
	local pending = self.pending
	local n = #pending
	if n == 0 then
		return
	end
	local done = 0
	while n > 0 and done < ACTIVATE_BUDGET do
		local item = pending[n]
		pending[n] = nil
		n -= 1
		local p = item[2]
		if p.queued then
			p.queued = false
			activate(self, item[1], p)
			done += 1
		end
	end
end

-- Native swarms: respawn / continue the particles whose segment is over (cheap: most frames do nothing).
local function serviceNative(self: any, sw: any, t: number)
	for _, p in sw.list do
		if p.active and t >= p.due then
			local age = t - p.born
			if age >= p.life - 1e-3 then
				spawnParticle(sw, p, t)
				launch(self, sw, p, 0)
			else
				launch(self, sw, p, age)
			end
		end
	end
end

-- Lua-moved swarms (`field`): every `stride`-th particle each frame, writing only what changed.
local function stepSim(self: any, sw: any, t: number, now: number, stride: number)
	local o, S, SS = sw.o, self.S, self.S * SackVFX.SizeScale
	local frame = sw.frame and sw.frame(t)
	local gravity, drag, field = sw.gravity, sw.drag, o.field
	local fno = self.frameNo
	for _, p in sw.list do
		if not p.active or (stride > 1 and (p.i + fno) % stride ~= 0) then
			continue
		end
		local dt = t - p.last
		p.last = t
		local e = p.e
		if t - p.born >= p.life then
			spawnParticle(sw, p, t)
			local seq, key = colorSeq(p.col)
			if key ~= p.colorKey then
				p.colorKey = key
				e.Color = seq
			end
		end
		p.vel += gravity * dt
		if drag > 0 then
			p.vel *= math.max(0, 1 - drag * dt)
		end
		local k = (t - p.born) / p.life
		p.vel = field(p, t, dt, k)
		p.pos += p.vel * dt
		local w = if frame then frame * p.pos else p.pos
		p.a.Position = Vector3.new(w.X * S, w.Y * S, w.Z * S * FRONT)
		local sseq, skey = constSize(sizeAt(sw, p, k) * SS)
		if skey ~= p.sizeKey then
			p.sizeKey = skey
			e.Size = sseq
		end
		local level = alphaLevel(alphaAt(sw, p, t - p.born))
		if level ~= p.alphaLevel then
			p.alphaLevel = level
			e.Transparency = ALPHA_SEQ[level]
		end
		if o.colorLife then
			local cseq, ckey = colorSeq(o.colorLife(k, p.i, t))
			if ckey ~= p.colorKey then
				p.colorKey = ckey
				e.Color = cseq
			end
		end
		if now - p.emitted > 18 then
			e:Clear()
			e:Emit(1)
			p.emitted = now
		end
	end
end

function Ctx:swarm(o)
	local n = math.max(1, math.floor(o.count * SackVFX.Quality + 0.5))
	local S = self.S
	local sw: any = {
		o = o,
		sim = o.field ~= nil, -- a free-form velocity field still needs Lua every frame
		gravity = o.gravity or Vector3.zero,
		drag = o.drag or 0,
		fi = o.fadeIn or 0.15,
		fo = o.fadeOut or 0.45,
		A = o.alpha or 1,
		frame = o.frame,
		sizeMode = (o.grow and 1) or (o.shrink and 2) or 0,
		segMax = if o.twinkle then 3 * math.pi / o.twinkle else 30, -- twinkle is baked a few periods at a time
		sizeCache = {},
		alphaCache = {},
		list = {},
	}
	if o.spin then
		local w = o.spin
		sw.frame = function(t: number): CFrame
			return CFrame.Angles(0, -w * t, 0)
		end
		sw.spinOnly = true
	end
	sw.g = if sw.spinOnly then Vector3.new(0, sw.gravity.Y, 0) else sw.gravity
	sw.host = self.root
	if sw.frame and not sw.sim then
		local f = Instance.new("Part")
		f.Name = "SackVFX_Frame"
		f.Size = Vector3.new(0.2, 0.2, 0.2)
		f.Transparency = 1
		f.CanCollide, f.CanQuery, f.CanTouch, f.Massless, f.CastShadow = false, false, false, true, false
		f.Anchored = true
		f.CFrame = self.root.CFrame * scaled(sw.frame(0), S)
		f:SetAttribute("SackVFX_Placed", true)
		f.Parent = self.folder
		sw.host = f
	end
	-- stratified ranks: any density keeps an even, random share of the particles (tiny swarms always run)
	local order = table.create(n)
	for i = 1, n do
		order[i] = i
	end
	for i = n, 2, -1 do
		local j = math.random(1, i)
		order[i], order[j] = order[j], order[i]
	end
	for i = 1, n do
		local a = Instance.new("Attachment")
		a.Parent = sw.host
		local e = Instance.new("ParticleEmitter")
		e.Texture = SackVFX.Textures[o.tex or "glow"]
		e.LightEmission = o.normal and 0 or 1
		e.LightInfluence = 0
		e.Brightness = o.brightness or 1
		e.Rate = 0
		e.Rotation = o.rotRange or NumberRange.new(o.rot or 0)
		e.RotSpeed = o.rotSpeed or NumberRange.new(0)
		e.LockedToPart = true
		e.ZOffset = o.z or 0
		if sw.sim then
			e.Lifetime = NumberRange.new(20)
			e.Speed = NumberRange.new(0)
			e.Transparency = ALPHA_SEQ[0]
		else
			e.EmissionDirection = Enum.NormalId.Top
			e.SpreadAngle = Vector2.zero
			e.Drag = sw.drag / LN2 -- Roblox drag halves the speed every 1 / Drag seconds (checked in Studio)
		end
		e.Parent = a
		sw.list[i] = { i = i, a = a, e = e, active = false, rank = if n <= 3 then 0 else (order[i] - 0.5) / n }
	end
	table.insert(self.swarms, sw)
	return sw.list
end

-- lightning ----------------------------------------------------------------------------------------------------
local V3 = Vector3.new

-- expanding ring wave (preview pulseRing)
function Ctx:pulse(o)
	local sp = (o.rise or 0) / o.period + 0.001
	local op = o.op or 1
	return self:emit(self:attach(0, o.y, 0), {
		tex = "ring",
		keep = true,
		orient = Orient.VelocityPerpendicular,
		rate = 1 / o.period,
		life = { o.period, o.period },
		speed = { sp, sp },
		size = { { 0, o.r0 * 2.2 }, { 1, o.r1 * 2.2 } },
		color = ColorSequence.new(o.color),
		rot = NumberRange.new(0, 0),
		alpha = NS({ { 0, 1 - op }, { 0.5, 1 - op * 0.25 }, { 1, 1 } }),
	})
end

-- jagged lightning, re-randomised every min..max seconds (preview bolts); beams are written only on change
function Ctx:bolts(o)
	local SEG, S = 8, self.S
	for index = 1, o.n do
		local atts, beams = {}, {}
		for k = 0, SEG do
			atts[k] = Instance.new("Attachment")
			atts[k].Parent = self.root
		end
		for k = 1, SEG do
			for layer = 1, 2 do
				local b = Instance.new("Beam")
				b.Attachment0, b.Attachment1 = atts[k - 1], atts[k]
				b.FaceCamera, b.Segments = true, 1
				b.LightEmission, b.LightInfluence = 1, 0
				local w
				if layer == 1 then
					b.Color, b.Brightness, w = ColorSequence.new(Color3.new(1, 1, 1)), 2, 0.007
				else
					b.Texture, b.TextureMode, b.TextureLength = SackVFX.Textures.glow, Enum.TextureMode.Stretch, 1
					b.Color, w = ColorSequence.new(o.color), (o.size or 0.05) * 1.6
				end
				b.Width0, b.Width1 = w * S * SackVFX.SizeScale, w * S * SackVFX.SizeScale
				b.Parent = self.root
				beams[#beams + 1] = b
			end
		end
		local bolt = { beams = beams, index = index, n = o.n, active = true, level = -1, on = true }
		table.insert(self.boltList, bolt)
		local nextAt, born = 0, -1
		self:every(function(t: number)
			if not bolt.active then
				return
			end
			if t > nextAt then
				local a, b = o.ends()
				local L = (b - a).Magnitude
				for k = 0, SEG do
					local f = k / SEG
					local p = a:Lerp(b, f)
						+ V3(rnd(-1, 1), rnd(-1, 1), rnd(-1, 1)) * (math.sin(f * math.pi) * L * (o.jag or 0.18))
					atts[k].Position = V3(p.X * S, p.Y * S, p.Z * S * FRONT)
				end
				born, nextAt = t, t + rnd(o.min or 0.06, o.max or 0.4)
			end
			local k = math.min(1, (t - born) / 0.12)
			local level = alphaLevel((1 - k) * (math.random() > 0.15 and 1 or 0.3))
			if level == bolt.level then
				return
			end
			bolt.level = level
			local on = level > 0
			for _, beam in ipairs(beams) do
				if on then
					beam.Transparency = ALPHA_SEQ[level]
				end
				if on ~= bolt.on then
					beam.Enabled = on
				end
			end
			bolt.on = on
		end)
	end
end

-- driving ------------------------------------------------------------------------------------------------------

-- Runs every animation once now (first placement of rings / orbiters / wings), whatever the level.
function Ctx:prime()
	for _, f in ipairs(self.loops) do
		f(self.t, 0)
	end
	for _, sw in self.swarms do
		if sw.host ~= self.root then
			self:move(sw.host, self.root.CFrame * scaled(sw.frame(self.t), self.S))
		end
	end
	self:flush()
end

-- Applies a level of detail (SackLod): 1 Full .. 4 Disabled, on / off screen, under quality profile `prof`.
function Ctx:setLod(level: number, visible: boolean, prof: any)
	self.visible = visible
	local off = level >= SackLod.DISABLED
	local density = if off then 0 else math.min(1, prof.density[level] * (PREMIUM[self.tier] or 1))
	local lightsOn = not off and level <= prof.lights
	local boltShare = if off then 0 else prof.bolts[level]
	self.stride = if off then 1 else prof.stride[level]
	if level == self.lod and density == self.density and lightsOn == self.lightsOn and boltShare == self.boltShare then
		return
	end
	self.lod = level
	if off ~= self.hidden then
		self.hidden = off
		for _, em in self.emitters do
			em.e.Enabled = not off
			if off then
				em.e:Clear()
			end
		end
		for _, p in self.neons do
			p.LocalTransparencyModifier = if off then 1 else 0
		end
	end
	if density ~= self.density then
		self.density = density
		for _, em in self.emitters do
			if not em.keep then
				em.e.Rate = em.rate * math.max(density, STREAM_FLOOR)
			end
		end
		for _, sw in self.swarms do
			for _, p in sw.list do
				local want = p.rank < density
				if want and not p.active and not p.queued then
					p.queued = true
					table.insert(self.pending, { sw, p })
				elseif not want and (p.active or p.queued) then
					park(p)
				end
			end
		end
	end
	if lightsOn ~= self.lightsOn then
		self.lightsOn = lightsOn
		for _, L in self.lights do
			L.l.Parent = if lightsOn then L.a else nil
		end
	end
	if boltShare ~= self.boltShare then
		self.boltShare = boltShare
		for _, b in self.boltList do
			local on = (b.index - 1) / b.n < boltShare
			if on ~= b.active then
				b.active, b.level = on, -1
				if not on then
					for _, beam in ipairs(b.beams) do
						beam.Enabled = false
					end
					b.on = false
				end
			end
		end
	end
	if not off and self.primeOnShow then
		self.primeOnShow = false
		self:prime()
	end
	if off then
		self.primeOnShow = true
	end
end

-- Advances the effect by `dt` (driven effects: the caller moves the sack first; others: SackLod / start()).
function Ctx:step(dt: number)
	self.t += dt
	if self.hidden then
		return
	end
	local t = self.t
	activatePending(self)
	for _, sw in self.swarms do
		if not sw.sim then
			serviceNative(self, sw, t) -- also off screen, so the particles are alive when it comes back
		end
	end
	self.loopDt += dt
	if not self.visible then
		return
	end
	self.frameNo += 1
	local stride = self.stride
	if stride <= 1 or self.frameNo % stride == 0 then
		local ldt = math.min(self.loopDt, 0.25)
		self.loopDt = 0
		for _, f in ipairs(self.loops) do
			f(t, ldt)
		end
		for _, sw in self.swarms do
			if sw.host ~= self.root then
				self:move(sw.host, self.root.CFrame * scaled(sw.frame(t), self.S))
			end
		end
	end
	local now = os.clock()
	for _, sw in self.swarms do
		if sw.sim then
			stepSim(self, sw, t, now, stride)
		end
	end
	self:flush()
end

-- Unmanaged, self-running effect (no SackLod): its own RenderStepped.
function Ctx:start()
	self.conn = RunService.RenderStepped:Connect(function(dt)
		self:step(dt)
	end)
end

function Ctx:destroy()
	if self.dead then
		return
	end
	self.dead = true
	SackLod.unregister(self)
	if active[self.model] == self then
		active[self.model] = nil
	end
	if self.destroyConn then
		self.destroyConn:Disconnect()
	end
	if self.conn then
		self.conn:Disconnect()
		self.conn = nil
	end
	self.folder:Destroy()
end

local function wingRigs(c: any, match: (string, number) -> boolean, px: number, py: number, pz: number): { any }
	local out = {}
	for _, s in ipairs({ -1, 1 }) do
		out[#out + 1] = {
			s = s,
			rig = c:rig(
				c:find(function(n: string)
					return match(n, s)
				end),
				s * px,
				py,
				pz
			),
		}
	end
	return out
end

----------------------------------------------------------------- tiers
local TIERS: { [number]: (any) -> () } = {}

local function pick(t: { any }): any
	return t[math.random(1, #t)]
end
local function onSurf(q: any, R: number, y0: number, y1: number): number
	local th = rnd(0, TAU)
	q.p = V3(math.sin(th) * R, rnd(y0, y1), math.cos(th) * R)
	return th
end
local lastAlpha: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local function setAlpha(e: any, a: number)
	local level = alphaLevel(a)
	if lastAlpha[e] ~= level then
		lastAlpha[e] = level
		e.Transparency = ALPHA_SEQ[level]
	end
end

-- 1 Burlap Sack: drifting dust, falling fibres
TIERS[1] = function(c)
	c:swarm({
		count = 40,
		tex = "smoke",
		normal = true,
		alpha = 0.5,
		size = 0.08,
		grow = 1,
		gravity = V3(0, -0.02, 0),
		spawn = function(q: any)
			q.p = V3(rnd(-0.35, 0.35), rnd(-0.05, 1.0), rnd(-0.35, 0.35))
			q.v = V3(rnd(-0.02, 0.02), rnd(-0.03, 0.01), rnd(-0.02, 0.02))
			q.c, q.life = hsl(0.09, 0.35, rnd(0.45, 0.6)), rnd(4, 7)
		end,
	})
	c:swarm({
		count = 18,
		tex = "spark",
		normal = true,
		alpha = 0.9,
		size = 0.014,
		gravity = V3(0, -0.25, 0),
		drag = 1.5,
		spawn = function(q: any)
			q.p = V3(rnd(-0.18, 0.18), -0.05, rnd(-0.18, 0.18))
			q.v = V3(rnd(-0.05, 0.05), 0, rnd(-0.05, 0.05))
			q.c, q.life = hex("c8a070"), rnd(2, 3)
		end,
	})
end

-- 2 Gym Canvas: chalk puffs off the glove every 3 s, sweat sparkles
TIERS[2] = function(c)
	c:swarm({
		count = 36,
		tex = "smoke",
		normal = true,
		alpha = 0.45,
		size = 0.09,
		grow = 2.2,
		drag = 1.2,
		spawn = function(q: any)
			local th = rnd(-0.9, 0.9)
			q.p = V3(math.sin(th) * 0.21, rnd(0.25, 0.8), math.cos(th) * 0.21)
			q.v = V3(math.sin(th) * 0.25, rnd(0, 0.06), math.cos(th) * 0.25)
			q.life = rnd(1.8, 3)
			q.a = (c.t % 3) < 1.2 and 1 or 0.25
		end,
	})
	c:swarm({
		count = 30,
		tex = "spark",
		normal = true,
		size = 0.012,
		gravity = V3(0, -0.15, 0),
		spawn = function(q: any)
			onSurf(q, 0.22, 0.2, 0.9)
			q.life = rnd(2, 4)
		end,
	})
end

-- 3 Leather Classic: sweat drips, gold glint running up the seam
TIERS[3] = function(c)
	c:swarm({
		count = 30,
		size = 0.02,
		alpha = 0.8,
		gravity = V3(0, -1.4, 0),
		fadeIn = 0.05,
		spawn = function(q: any)
			onSurf(q, 0.21, 0.3, 0.88)
			q.c, q.life = rgb(0.6, 0.8, 1), rnd(0.9, 1.6)
			q.a = math.random() < 0.5 and 1 or 0
		end,
	})
	c:swarm({
		count = 1,
		size = 0.12,
		alpha = 0.9,
		alphaFn = function(k: number)
			return math.sin(k * math.pi)
		end,
		spawn = function(q: any)
			q.p = V3(math.sin(0.85) * 0.21, 0.15, math.cos(0.85) * 0.21)
			q.v = V3(0, 0.66 * 0.35, 0)
			q.c, q.life = hex("fff0c8"), 1 / 0.35
		end,
	})
end

-- 4 Pro Red: star glints on the gold bands, warm motes
TIERS[4] = function(c)
	c:swarm({
		count = 26,
		tex = "star",
		fadeIn = 0.4,
		fadeOut = 0.6,
		spawn = function(q: any)
			local y, th = pick({ 0.22, 0.74 }), rnd(-1.4, 1.4)
			q.p = V3(math.sin(th) * 0.22, y, math.cos(th) * 0.22)
			q.c, q.life, q.s = rgb(1, 0.85, 0.45), rnd(0.5, 1.2), rnd(0.04, 0.09)
		end,
	})
	c:swarm({
		count = 30,
		size = 0.015,
		alpha = 0.7,
		spawn = function(q: any)
			onSurf(q, 0.3, 0, 1)
			q.v, q.c, q.life = V3(0, 0.04, 0), rgb(1, 0.6, 0.5), rnd(3, 5)
		end,
	})
end

-- 5 Tire Stack: rubber smoke, flying rubber bits
TIERS[5] = function(c)
	c:swarm({
		count = 46,
		tex = "smoke",
		normal = true,
		alpha = 0.55,
		size = 0.12,
		grow = 2.5,
		gravity = V3(0, 0.05, 0),
		drag = 0.4,
		spawn = function(q: any)
			onSurf(q, 0.26, 0.05, 0.3)
			q.v = V3(rnd(-0.04, 0.04), rnd(0.02, 0.08), rnd(-0.04, 0.04))
			q.c, q.life = rgb(0.22, 0.22, 0.24), rnd(3, 5)
		end,
	})
	c:swarm({
		count = 16,
		tex = "square",
		normal = true,
		size = 0.018,
		gravity = V3(0, -0.6, 0),
		rotRange = NumberRange.new(0, 360),
		rotSpeed = NumberRange.new(-180, 180),
		spawn = function(q: any)
			onSurf(q, 0.25, 0.1, 0.8)
			q.v = V3(q.p.X * 0.8, rnd(0, 0.2), q.p.Z * 0.8)
			q.c, q.life = hex("2a2a2c"), rnd(1, 2)
			q.a = math.random() < 0.4 and 1 or 0
		end,
	})
end

-- 6 Iron Plate: welding spark bursts with flicker light and smoke
TIERS[6] = function(c)
	c:glowParts(prefix("warning_light"), hex("ff3020"))
	local src = V3(0.08, 0.56, 0.2)
	local function burst()
		return (c.t % 2.4) < 0.7
	end
	c:swarm({
		count = 90,
		tex = "spark",
		size = 0.02,
		fadeIn = 0.02,
		gravity = V3(0, -3, 0),
		drag = 0.3,
		colorLife = function(k: number)
			return rgb(1, 0.9 - k * 0.5, math.max(0, 0.5 - k * 0.45))
		end,
		spawn = function(q: any)
			q.p = src
			q.v = V3(rnd(-0.4, 0.8), rnd(0.2, 1.4), rnd(0.3, 1.1))
			q.life = rnd(0.35, 0.8)
			q.a = burst() and 1 or 0
		end,
	})
	c:swarm({
		count = 14,
		tex = "smoke",
		normal = true,
		alpha = 0.35,
		size = 0.08,
		grow = 2,
		gravity = V3(0, 0.08, 0),
		spawn = function(q: any)
			q.p, q.v, q.c, q.life = src, V3(0.02, 0.05, 0.05), hex("6a6a70"), rnd(2, 3)
		end,
	})
	local L = c:light(0.12, 0.56, 0.35, hex("ffa040"), 0, 1.6)
	local gl = c:sprite(c:attach(src.X, src.Y, src.Z + 0.01), hex("ffb050"), 0.18, 0)
	c:every(function()
		local on = burst() and (0.6 + math.random() * 0.4) or 0
		L.Brightness = on * 3
		setAlpha(gl, on)
	end)
end

-- 7 Bronze Statue: light sweep, warm twinkling motes, glints
TIERS[7] = function(c)
	c:swarm({
		count = 1,
		size = 0.5,
		alpha = 0.45,
		alphaFn = function(k: number)
			return math.sin(k * math.pi)
		end,
		spawn = function(q: any)
			q.p, q.v, q.c, q.life = V3(0.14, 0.1, 0.18), V3(0, 0.8 * 0.28, 0), hex("ffd8a0"), 1 / 0.28
		end,
	})
	c:swarm({
		count = 50,
		size = 0.018,
		alpha = 0.8,
		twinkle = 3,
		spawn = function(q: any)
			onSurf(q, rnd(0.24, 0.4), 0, 0.9)
			q.v, q.c, q.life = V3(0, rnd(0.03, 0.08), 0), rgb(1, 0.65, 0.3), rnd(3, 6)
		end,
	})
	c:swarm({
		count = 12,
		tex = "star",
		size = 0.06,
		fadeIn = 0.4,
		fadeOut = 0.6,
		spawn = function(q: any)
			onSurf(q, 0.21, 0.1, 0.9)
			q.c, q.life = rgb(1, 0.8, 0.55), rnd(0.5, 1)
		end,
	})
end

-- 8 Silver Knight: glints, blue spiral aura, ground pulse
TIERS[8] = function(c)
	c:swarm({
		count = 22,
		tex = "star",
		fadeIn = 0.45,
		fadeOut = 0.55,
		spawn = function(q: any)
			onSurf(q, 0.215, 0.1, 0.95)
			q.c, q.life, q.s = rgb(0.85, 0.92, 1), rnd(0.5, 1.1), rnd(0.05, 0.1)
		end,
	})
	c:swarm({
		count = 70,
		size = 0.02,
		alpha = 0.9,
		spin = 0.8, -- was field V(-z * 0.8, vy, x * 0.8): orbit the axis
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0.28, 0.34)
			q.p = V3(math.cos(a) * r, 0.02, math.sin(a) * r)
			q.v, q.c, q.life = V3(0, rnd(0.05, 0.12), 0), rgb(0.4, 0.6, 1), rnd(1.5, 2.5)
		end,
	})
	c:pulse({ y = 0.01, color = hex("5080ff"), r0 = 0.24, r1 = 0.42, period = 2.2, op = 0.7 })
	c:light(0.3, 0.4, 0.4, hex("5a7cff"), 0.6, 2)
end

-- 9 Gold Champion: floating halo, gem glow, rising gold, star glints
TIERS[9] = function(c)
	c:glowParts(prefix("center_gem"), hex("e01840"))
	c:glowParts(prefix("side_gem_"), hex("2a8ce0"))
	local halo = c:ring(0.16, 0.016, 0.016, 32, hex("ffd060"), 0)
	local haloSoft = c:ring(0.16, 0.05, 0.03, 32, hex("ffa020"), 0.75)
	c:sprite(c:attach(0, 0.5, -0.05), hex("ffb030"), 1.4, 0.78)
	c:swarm({
		count = 90,
		size = 0.022,
		twinkle = 4,
		spawn = function(q: any)
			onSurf(q, rnd(0.22, 0.42), 0, 0.6)
			q.v, q.c, q.life = V3(0, rnd(0.08, 0.2), 0), rgb(1, rnd(0.6, 0.85), 0.25), rnd(2, 4)
		end,
	})
	c:swarm({
		count = 24,
		tex = "star",
		fadeIn = 0.4,
		fadeOut = 0.6,
		spawn = function(q: any)
			onSurf(q, 0.215, 0.05, 0.95)
			q.c, q.life, q.s = rgb(1, 0.9, 0.6), rnd(0.5, 1), rnd(0.06, 0.12)
		end,
	})
	c:light(0, 0.6, 0.5, hex("ffb040"), 1.4, 2.5)
	c:every(function(t: number)
		local cf = c:world(0, 1.08 + math.sin(t * 1.5) * 0.015, 0)
		halo.place(cf)
		haloSoft.place(cf)
	end)
end

-- 10 Ice Block: frost mist, falling snow, icicle drips, cold core glow
TIERS[10] = function(c)
	c:glowParts(prefix("flake_"), hex("bff0ff"))
	c:sprite(c:attach(0, 0.5, 0), hex("7fd0ff"), 0.9, 0.65)
	c:light(0, 0.5, 0.4, hex("7fd0ff"), 1.2, 2)
	c:swarm({
		count = 50,
		tex = "smoke",
		normal = true,
		alpha = 0.4,
		size = 0.14,
		grow = 2,
		gravity = V3(0, -0.04, 0),
		drag = 0.5,
		spawn = function(q: any)
			q.p = V3(rnd(-0.2, 0.2), rnd(-0.02, 0.15), rnd(-0.2, 0.2))
			q.v = V3(q.p.X * 0.4, rnd(-0.06, -0.01), q.p.Z * 0.4)
			q.c, q.life = rgb(0.85, 0.95, 1), rnd(2.5, 4)
		end,
	})
	c:swarm({
		count = 70,
		tex = "star",
		size = 0.035,
		alpha = 0.9,
		twinkle = 5,
		field = function(p: any, t: number)
			return V3(math.sin(t * 1.3 + p.i) * 0.05, p.vel.Y, p.vel.Z)
		end,
		spawn = function(q: any)
			q.p = V3(rnd(-0.5, 0.5), rnd(0.9, 1.4), rnd(-0.5, 0.5))
			q.v, q.c, q.life = V3(0, rnd(-0.12, -0.06), 0), rgb(0.85, 0.95, 1), rnd(6, 10)
		end,
	})
	c:swarm({
		count = 14,
		size = 0.02,
		gravity = V3(0, -1.2, 0),
		fadeIn = 0.05,
		spawn = function(q: any)
			q.p = V3(rnd(-0.18, 0.18), 0.79, pick({ -0.2, 0.2 }))
			q.c, q.life = rgb(0.7, 0.9, 1), rnd(0.8, 1.6)
		end,
	})
end

-- 11 Crystal Geode: pulsing core, orbiting shards, energy pulled into the core
TIERS[11] = function(c)
	c:glowParts(prefix("core_gem"), hex("f0d8ff"))
	c:glowParts(prefix("crystal_", "cavity_crystal_", "crown_crystal_"))
	local core = c:sprite(c:attach(0, 0.48, 0.24), hex("c080ff"), 0.5, 0.1)
	c:sprite(c:attach(0, 0.48, 0.24), Color3.new(1, 1, 1), 0.14, 0)
	local L = c:light(0, 0.48, 0.35, hex("a060ff"), 2, 2.2)
	for i = 0, 11 do
		local s = rnd(0.018, 0.032)
		local col = (i % 3 ~= 0) and hex("b070ff") or hex("60f0ff")
		local shard = c:neon(nil, s, s * rnd(3.6, 5.6), s, col)
		c:sprite(shard, col, 0.12, 0.3)
		c:orbit(shard, {
			r = rnd(0.32, 0.42),
			y = 0.48,
			speed = rnd(0.6, 0.9),
			phase = i / 12 * TAU,
			tilt = rnd(-0.35, 0.35),
			tiltZ = rnd(-0.25, 0.25),
			bob = 0.04,
			spin = 1.5,
		})
	end
	c:swarm({
		count = 140,
		size = 0.02,
		field = function(p: any)
			local dx, dy, dz = -p.pos.X, 0.48 - p.pos.Y, 0.24 - p.pos.Z
			return V3(dx * 1.2 - dz * 1.5, dy * 1.2, dz * 1.2 + dx * 1.5)
		end,
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0.35, 0.6)
			q.p = V3(math.cos(a) * r, rnd(0.2, 0.8), 0.24 + math.sin(a) * r)
			q.c, q.life = hsl(rnd(0.72, 0.82), 1, 0.65), rnd(1.2, 2)
		end,
	})
	c:swarm({
		count = 30,
		tex = "star",
		size = 0.06,
		fadeIn = 0.4,
		fadeOut = 0.6,
		spawn = function(q: any)
			onSurf(q, 0.2, 0.1, 0.95)
			q.c, q.life = rgb(0.8, 0.7, 1), rnd(0.4, 0.9)
		end,
	})
	c:every(function(t: number)
		local p = 0.75 + 0.25 * math.sin(t * 3)
		setAlpha(core, p)
		L.Brightness = 1.5 + p
	end)
end

-- 12 Candy Smash: confetti pop every 3.5 s, sparkles, orbiting candies
TIERS[12] = function(c)
	local CONF = { hex("ff4f8a"), hex("48c8ff"), hex("ffe04a"), hex("6ef08a"), hex("b880ff"), hex("ffffff") }
	c:swarm({
		count = 110,
		tex = "square",
		normal = true,
		size = 0.03,
		fadeIn = 0.05,
		gravity = V3(0, -0.35, 0),
		drag = 1.2,
		rotRange = NumberRange.new(0, 360),
		rotSpeed = NumberRange.new(-240, 240),
		field = function(p: any, t: number)
			return p.vel + V3(math.sin(t * 4 + p.i) * 0.01, 0, 0)
		end,
		spawn = function(q: any)
			local a, s = rnd(0, TAU), rnd(0.5, 1.2)
			q.p = V3(0, 1.01, 0)
			q.v = V3(math.cos(a) * s, rnd(0.8, 1.6), math.sin(a) * s)
			q.c, q.life, q.s = pick(CONF), rnd(2.5, 3.5), rnd(0.02, 0.035)
			q.a = (c.t % 3.5) < 0.35 and 1 or 0
		end,
	})
	c:swarm({
		count = 50,
		tex = "star",
		size = 0.05,
		twinkle = 6,
		spawn = function(q: any)
			onSurf(q, rnd(0.24, 0.45), 0, 1.1)
			q.v, q.c, q.life = V3(0, 0.03, 0), hsl(rnd(0.85, 1), 0.9, 0.8), rnd(2, 3)
		end,
	})
	for i = 0, 3 do
		local candy = c:neon(Enum.PartType.Ball, 0.065, 0.05, 0.05, CONF[i + 1])
		candy.Material = Enum.Material.SmoothPlastic
		c:orbit(candy, { r = 0.38, y = 0.55, speed = 0.8, phase = i / 4 * TAU, tilt = 0.25, bob = 0.06, spin = 1 })
	end
	c:light(0.3, 0.6, 0.4, hex("ff70b0"), 1, 2)
end

-- 13 Lava Core: flickering magma cracks, swirling embers, smoke, lava drops
TIERS[13] = function(c)
	local magma = c:glowParts(prefix("crack_", "molten_rim_", "lava_drip_"), hex("ff6a18"))
	local DIM, HOT = hex("c83a08"), hex("ffa040")
	local L = c:light(0, 0.4, 0.4, hex("ff5010"), 3, 2.5)
	local L2 = c:light(0, -0.05, 0, hex("ff7020"), 2, 1.5)
	local bottom = c:sprite(c:attach(0, 0, 0), hex("ff5010"), 0.8, 0.4)
	c:sprite(c:attach(0, 0.45, -0.1), hex("ff3000"), 1.6, 0.82)
	c:swarm({
		count = 160,
		tex = "spark",
		fadeIn = 0.05,
		gravity = V3(0, 0.25, 0),
		drag = 0.4,
		field = function(p: any, t: number, dt: number)
			local y = p.pos.Y
			return p.vel + V3(math.sin(t * 3 + y * 9 + p.i) * 0.4 * dt, 0, math.cos(t * 2.7 + y * 7 + p.i) * 0.4 * dt)
		end,
		colorLife = function(k: number)
			return rgb(1, 0.75 - k * 0.55, math.max(0, 0.25 - k * 0.22))
		end,
		spawn = function(q: any)
			onSurf(q, 0.21, 0.05, 0.95)
			q.v = V3(q.p.X * 0.4, rnd(0.1, 0.35), q.p.Z * 0.4)
			q.life, q.s = rnd(1.5, 3), rnd(0.012, 0.03)
		end,
	})
	c:swarm({
		count = 40,
		tex = "smoke",
		normal = true,
		alpha = 0.45,
		size = 0.14,
		grow = 2.5,
		gravity = V3(0, 0.1, 0),
		spawn = function(q: any)
			q.p = V3(rnd(-0.15, 0.15), 0.98, rnd(-0.15, 0.15))
			q.v = V3(rnd(-0.03, 0.03), 0.1, rnd(-0.03, 0.03))
			q.c, q.life = rgb(0.12, 0.09, 0.08), rnd(3, 5)
		end,
	})
	c:swarm({
		count = 24,
		size = 0.035,
		gravity = V3(0, -1.6, 0),
		fadeIn = 0.02,
		fadeOut = 0.3,
		colorLife = function(k: number)
			return rgb(1, 0.55 - k * 0.3, 0.1)
		end,
		spawn = function(q: any)
			local a = rnd(0, TAU)
			q.p, q.life = V3(math.sin(a) * 0.17, -0.02, math.cos(a) * 0.17), rnd(0.5, 0.9)
		end,
	})
	c:every(function(t: number)
		local f = 0.75 + 0.25 * math.sin(t * 2.2) + math.random() * 0.12
		local col = DIM:Lerp(HOT, math.clamp((f - 0.5) / 0.62, 0, 1))
		for _, p in ipairs(magma) do
			p.Color = col
		end
		L.Brightness = 2 + f * 2
		L2.Brightness = 1 + f
		setAlpha(bottom, 0.4 + f * 0.3)
	end)
end

-- 14 Thunder Cell: arcs between terminals, coils to air, sky strikes, pulse, sparks
TIERS[14] = function(c)
	local core = c:glowParts(prefix("plasma_core"), hex("30c8ff"))
	local rings = {}
	for i = 0, 3 do
		rings[i] = c:glowParts(function(n: string)
			return n == "neon_ring_" .. i
		end, hex("20d8ff"))
	end
	c:glowParts(prefix("bolt_emblem"), hex("ffe860"))
	local RING_DIM, RING_HOT = hex("0a6a90"), hex("bff8ff")
	local CORE_DIM, CORE_HOT = hex("1890d0"), hex("a0f4ff")
	local term = { V3(-0.15, 1.09, 0.04), V3(0.15, 1.09, 0.04) }
	c:bolts({
		n = 2,
		color = hex("bff8ff"),
		size = 0.05,
		jag = 0.12,
		ends = function()
			return term[1], term[2]
		end,
	})
	c:bolts({
		n = 4,
		color = hex("60e8ff"),
		size = 0.045,
		ends = function()
			local s = math.random() < 0.5 and -1 or 1
			local a, r = rnd(0, TAU), rnd(0.25, 0.5)
			return V3(s * 0.225, rnd(0.15, 0.8), 0), V3(math.cos(a) * r, rnd(0.05, 1.0), math.sin(a) * r)
		end,
	})
	c:bolts({
		n = 2,
		color = hex("9fd8ff"),
		size = 0.04,
		min = 0.2,
		max = 0.9,
		ends = function()
			return pick(term), V3(rnd(-0.4, 0.4), 1.66, rnd(-0.2, 0.2))
		end,
	})
	for _, p in ipairs(term) do
		c:sprite(c:attach(p.X, p.Y, p.Z), hex("80f0ff"), 0.2, 0.1)
	end
	c:sprite(c:attach(0, 0.5, -0.05), hex("30c8ff"), 1.3, 0.8)
	c:pulse({ y = 0.47, color = hex("40e8ff"), r0 = 0.22, r1 = 0.6, period = 1.6, op = 0.9 })
	c:swarm({
		count = 70,
		tex = "spark",
		size = 0.016,
		gravity = V3(0, -1, 0),
		fadeIn = 0.02,
		spawn = function(q: any)
			onSurf(q, 0.215, 0.1, 0.9)
			q.v = V3(q.p.X * rnd(1, 4), rnd(0, 0.6), q.p.Z * rnd(1, 4))
			q.c, q.life = rgb(0.7, 0.95, 1), rnd(0.25, 0.6)
			q.a = math.random() < 0.5 and 1 or 0
		end,
	})
	local L = c:light(0, 0.5, 0.4, hex("50e0ff"), 2, 2.4)
	c:every(function(t: number)
		local fl = math.random() > 0.85 and 1.8 or 1
		L.Brightness = 1.5 * fl + math.sin(t * 9) * 0.3
		local cc = CORE_DIM:Lerp(CORE_HOT, math.clamp(0.5 + math.sin(t * 6) * 0.3 + (fl - 1) * 0.5, 0, 1))
		for _, p in ipairs(core) do
			p.Color = cc
		end
		for i = 0, 3 do
			local rc = RING_DIM:Lerp(RING_HOT, math.max(0, math.sin(t * 4 - i * 0.9)))
			for _, p in ipairs(rings[i]) do
				p.Color = rc
			end
		end
	end)
end

-- 15 Toxic Barrel: glowing ooze, wobbling bubbles, fumes, drips
TIERS[15] = function(c)
	local ooze = c:glowParts(prefix("ooze_"), hex("9cff3a"))
	local DIM, HOT = hex("4cc010"), hex("c8ff70")
	local L = c:light(0, 0.7, 0.4, hex("70ff30"), 2, 2.2)
	local gl = c:sprite(c:attach(0, 1.0, 0), hex("70ff30"), 0.8, 0.5)
	c:swarm({
		count = 70,
		size = 0.03,
		field = function(p: any, t: number)
			return V3(math.sin(t * 3 + p.i) * 0.04, p.vel.Y, math.cos(t * 2.6 + p.i) * 0.04)
		end,
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0, 0.16)
			q.p = V3(math.cos(a) * r, 0.98, math.sin(a) * r)
			q.v = V3(0, rnd(0.12, 0.3), 0)
			q.c, q.life, q.s = rgb(0.55, 1, 0.25), rnd(1.2, 2.5), rnd(0.015, 0.045)
		end,
	})
	c:swarm({
		count = 40,
		tex = "smoke",
		alpha = 0.35,
		size = 0.16,
		grow = 2,
		gravity = V3(0, 0.05, 0),
		spawn = function(q: any)
			q.p = V3(rnd(-0.15, 0.15), 1.01, rnd(-0.15, 0.15))
			q.v = V3(rnd(-0.04, 0.04), 0.08, rnd(-0.04, 0.04))
			q.c, q.life = rgb(0.15, 0.4, 0.05), rnd(3, 4.5)
		end,
	})
	c:swarm({
		count = 20,
		size = 0.035,
		gravity = V3(0, -1.5, 0),
		fadeIn = 0.02,
		spawn = function(q: any)
			local a = rnd(0, TAU)
			q.p, q.c, q.life = V3(math.sin(a) * 0.21, 0.71, math.cos(a) * 0.21), rgb(0.55, 1, 0.2), rnd(0.8, 1.4)
		end,
	})
	c:every(function(t: number)
		local p = 0.7 + 0.3 * math.sin(t * 2)
		local col = DIM:Lerp(HOT, (p - 0.4) / 0.6)
		for _, o in ipairs(ooze) do
			o.Color = col
		end
		L.Brightness = 1.2 + p * 1.4
		setAlpha(gl, 0.3 + p * 0.3)
	end)
end

-- 16 Robo Bag: holo scan ring, data bits, blinking eyes/LEDs/antenna, moving arms
TIERS[16] = function(c)
	local CYAN = hex("40f0ff")
	c:glowParts(prefix("eye_", "mouth"), CYAN)
	local eyes = c:find(prefix("eye_"))
	local LED_ON = { [0] = hex("ff3030"), [1] = hex("ffc020"), [2] = hex("30ff60") }
	local LED_OFF = { [0] = hex("4a1010"), [1] = hex("4a3a10"), [2] = hex("104a1c") }
	local leds = {}
	for i = 0, 2 do
		leds[i] = c:glowParts(function(n: string)
			return n == "status_led_" .. i
		end)
	end
	local TIP_ON, TIP_OFF = hex("ff3030"), hex("501010")
	local tip = c:glowParts(prefix("antenna_tip"), TIP_ON)

	local line = c:ring(0.25, 0.012, 0.012, 36, CYAN, 0)
	local band = c:ring(0.245, 0.004, 0.06, 36, CYAN, 0.82)

	c:swarm({
		count = 80,
		tex = "square",
		alpha = 0.9,
		twinkle = 8,
		spawn = function(q: any)
			local th, r = rnd(0, TAU), rnd(0.27, 0.36)
			q.p = Vector3.new(math.sin(th) * r, rnd(0, 0.9), math.cos(th) * r)
			q.v = Vector3.new(0, rnd(0.08, 0.18), 0)
			q.c, q.life, q.s = rgb(0.25, rnd(0.8, 1), 1), rnd(1.5, 3), rnd(0.012, 0.025)
		end,
	})
	c:sprite(c:attach(0, 0.62, 0.24), CYAN, 0.5, 0.8)
	c:light(0, 0.62, 0.4, CYAN, 2, 2)
	local tipLight = c:light(0.13, 1.17, 0.06, TIP_ON, 3, 0.6)

	local arms = {}
	for _, s in ipairs({ -1, 1 }) do
		arms[#arms + 1] = {
			s = s,
			sh = c:rig(
				c:find(function(n: string)
					return n == "shoulder_" .. s or n == "upper_arm_" .. s or n == "elbow_" .. s
				end),
				s * 0.215,
				0.66,
				0
			),
			fore = c:rig(
				c:find(function(n: string)
					return n == "forearm_" .. s or starts(n, "claw_" .. s .. "_")
				end),
				s * 0.255,
				0.48,
				0
			),
		}
	end

	c:every(function(t: number)
		local y = 0.48 + math.sin(t * 1.4) * 0.42
		line.place(c:world(0, y, 0))
		band.place(c:world(0, y - math.cos(t * 1.4) * 0.03, 0))
		local blink = (t % 3.2) < 0.12
		for _, e in ipairs(eyes) do
			e.Transparency = blink and 1 or 0
		end
		local on = math.floor(t * 3) % 3
		for i = 0, 2 do
			for _, p in ipairs(leds[i]) do
				p.Color = (i == on) and LED_ON[i] or LED_OFF[i]
			end
		end
		local tipOn = math.sin(t * 5) > 0
		tipLight.Enabled = tipOn
		for _, p in ipairs(tip) do
			p.Color = tipOn and TIP_ON or TIP_OFF
		end
		for _, a in ipairs(arms) do
			local rs = CFrame.Angles(math.sin(t * 1.6 + a.s) * 0.18, 0, 0)
			c:pose(a.sh, rs)
			local shPivot = c:world(a.s * 0.215, 0.66, 0)
			local forePivot = shPivot * rs * shPivot:ToObjectSpace(c:world(a.s * 0.255, 0.48, 0))
			local rf = CFrame.Angles(math.sin(t * 2.2 + a.s) * 0.2, 0, 0)
			for _, e in ipairs(a.fore.list) do
				e.part.CFrame = forePivot * rf * e.rel
			end
		end
	end)
end

-- 17 Dragon Hide: crown + base fire, embers, smoke, flicker light, flapping wings
TIERS[17] = function(c)
	c:glowParts(prefix("eye_"), hex("ffc020"))
	local FIRE = CS({
		{ 0, rgb(1, 0.95, 0.6) },
		{ 0.25, rgb(1, 0.55, 0.12) },
		{ 0.6, rgb(0.7, 0.15, 0.04) },
		{ 1, rgb(0.25, 0.05, 0.02) },
	})
	c:swarm({
		count = 150,
		size = 0.07,
		grow = 0.6,
		fadeIn = 0.08,
		fadeOut = 0.5,
		gravity = Vector3.new(0, 0.6, 0),
		drag = 1,
		colorLife = function(k: number)
			if k < 0.25 then
				return rgb(1, 0.95, 0.6)
			end
			if k < 0.55 then
				return rgb(1, 0.55, 0.12)
			end
			return rgb(0.8 - (k - 0.55), 0.15, 0.04)
		end,
		field = function(p: any, _t: number, dt: number)
			return p.vel + Vector3.new(-p.pos.X * 2 * dt, 0, -p.pos.Z * 2 * dt)
		end,
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0.12, 0.22)
			q.p = Vector3.new(math.cos(a) * r, 0.96 + rnd(-0.02, 0.02), math.sin(a) * r)
			q.v = Vector3.new(math.cos(a) * 0.05, rnd(0.25, 0.5), math.sin(a) * 0.05)
			q.life, q.s = rnd(0.6, 1.1), rnd(0.05, 0.09)
		end,
	})
	c:emit(c:volume(0.36, 0.02, 0.36, 0, 0.0, 0), {
		rate = 80,
		life = { 0.4, 0.8 },
		speed = { 0.05, 0.15 },
		spread = Vector2.new(70, 70),
		accel = Vector3.new(0, 0.4, 0),
		color = FIRE,
		rotSpeed = NumberRange.new(-90, 90),
		size = { { 0, 0.06 }, { 0.5, 0.08 }, { 1, 0.02 } },
		alpha = NS({ { 0, 1 }, { 0.08, 0.2 }, { 0.5, 0.4 }, { 1, 1 } }),
	})
	c:emit(c:volume(0.48, 1.0, 0.48, 0, 0.6, 0), {
		tex = "spark",
		shape = Shape.Cylinder,
		style = Style.Surface,
		rate = 35,
		life = { 1.2, 2.4 },
		speed = { 0.02, 0.08 },
		accel = Vector3.new(0, 0.3, 0),
		color = CS({ { 0, rgb(1, 0.75, 0.25) }, { 1, rgb(1, 0.25, 0.1) } }),
		size = { { 0, 0.02 }, { 1, 0.01 } },
		alpha = NS({ { 0, 1 }, { 0.05, 0 }, { 0.6, 0.2 }, { 1, 1 } }),
	})
	c:emit(c:volume(0.24, 0.02, 0.24, 0, 1.26, 0), {
		tex = "smoke",
		light = 0,
		influence = 1,
		rate = 10,
		life = { 2, 3 },
		speed = { 0.1, 0.14 },
		color = ColorSequence.new(rgb(0.12, 0.08, 0.08)),
		rotSpeed = NumberRange.new(-20, 20),
		size = { { 0, 0.16 }, { 1, 0.45 } },
		alpha = NS({ { 0, 1 }, { 0.2, 0.6 }, { 1, 1 } }),
	})
	c:sprite(c:attach(0, 1.06, 0), hex("ff4010"), 0.9, 0.75)
	local L = c:light(0, 1.16, 0.3, hex("ff6020"), 3, 2.5)
	local wings = wingRigs(c, function(n: string, s: number)
		return n == "wing_" .. s or starts(n, "wing_bone_" .. s .. "_")
	end, 0.14, 0.56, -0.14)
	local nextFlicker = 0
	c:every(function(t: number)
		local fl = math.sin(t * 3.2)
		for _, w in ipairs(wings) do
			c:pose(w.rig, CFrame.Angles(0, w.s * fl * 0.45, 0))
		end
		if t > nextFlicker then
			L.Brightness = rnd(2.4, 3.8)
			nextFlicker = t + 0.08
		end
	end)
end

-- 18 Galaxy Void: spinning galaxy disk + rings, orbiting planets and cubes, inflowing matter
TIERS[18] = function(c)
	c:glowParts(prefix("nebula_band_"), hex("7a40ff"))
	c:glowParts(prefix("body_star_"), Color3.new(1, 1, 1))
	local disk = c:attach(0, 0.48, 0, CFrame.Angles(0.42, 0, 0.18))
	local flat = { orient = Orient.VelocityPerpendicular, speed = { 0.001, 0.001 }, locked = true }
	local function flatEmit(o)
		for k, v in pairs(flat) do
			if o[k] == nil then
				o[k] = v
			end
		end
		return c:emit(disk, o)
	end
	flatEmit({
		tex = "galaxy",
		rate = 0.4,
		life = { 7.5, 7.5 },
		size = { { 0, 1.55 }, { 1, 1.55 } },
		rotSpeed = NumberRange.new(14, 14),
		alpha = NS({ { 0, 1 }, { 0.2, 0.6 }, { 0.8, 0.6 }, { 1, 1 } }),
	})
	local WHITE = Color3.new(1, 1, 1)
	c:swarm({
		count = 450,
		fadeIn = 0,
		fadeOut = 0,
		twinkle = 1.5,
		frame = function(t: number)
			return CFrame.new(0, 0.48, 0) * CFrame.Angles(0.42, t * 0.25, 0.18)
		end,
		spawn = function(q: any)
			local arm = math.random(0, 2)
			local r = 0.24 + math.random() ^ 0.7 * 0.5
			local a = arm * TAU / 3 + r * 6 + rnd(-0.35, 0.35) * (1 - r)
			q.p = Vector3.new(math.cos(a) * r, rnd(-0.015, 0.015) * (1.2 - r), math.sin(a) * r)
			q.c = math.random() < 0.12 and WHITE or hsl(0.78 - (r - 0.24) * 0.5 + rnd(-0.04, 0.04), 1, rnd(0.55, 0.75))
			q.s, q.life = rnd(0.012, 0.04), 1e9
		end,
	})
	flatEmit({
		tex = "ring",
		rate = 0.5,
		life = { 4, 4 },
		size = { { 0, 0.74 }, { 1, 0.74 } },
		rot = NumberRange.new(0, 0),
		color = ColorSequence.new(hex("ffd080")),
		alpha = NS({ { 0, 1 }, { 0.25, 0.2 }, { 0.75, 0.2 }, { 1, 1 } }),
	})
	flatEmit({
		tex = "ring",
		rate = 0.5,
		life = { 4, 4 },
		size = { { 0, 0.8 }, { 1, 0.8 } },
		rot = NumberRange.new(0, 0),
		color = ColorSequence.new(hex("c090ff")),
		alpha = NS({ { 0, 1 }, { 0.25, 0.45 }, { 0.75, 0.45 }, { 1, 1 } }),
	})

	local moons: { { any } } = {
		{ "40d0ff", 0.03, 0.46, 0.7, 0.2 },
		{ "ff70d0", 0.022, 0.55, -0.5, -0.3 },
		{ "ffd060", 0.018, 0.38, 1.1, 0.5 },
	}
	for i, p in ipairs(moons) do
		local col = hex(p[1])
		local ball = c:neon(Enum.PartType.Ball, p[2] * 2, p[2] * 2, p[2] * 2, col)
		c:sprite(ball, col, p[2] * 8, 0.55)
		c:orbit(ball, { r = p[3], y = 0.48, speed = p[4], phase = (i - 1) * 2, tilt = p[5], bob = 0.03 })
	end
	local CUBE = { hex("a060ff"), hex("5080ff"), hex("ff60c0") }
	for _ = 1, 8 do
		local cube = c:neon(nil, 0.035, 0.035, 0.035, CUBE[math.random(1, 3)], 0.15)
		c:orbit(cube, {
			r = rnd(0.26, 0.32),
			y = rnd(0.2, 0.9),
			speed = rnd(0.3, 0.6),
			phase = rnd(0, TAU),
			bob = 0.05,
			spin = 1.2,
		})
	end
	c:emit(c:volume(2, 1.6, 2, 0, 0.7, 0), {
		tex = "star",
		shape = Shape.Cylinder,
		rate = 25,
		life = { 2, 5 },
		alpha = TWINKLE,
		color = CS({ { 0, hex("c8b8ff") }, { 1, hex("a0d8ff") } }),
		size = { { 0, 0.05 }, { 1, 0.03 } },
	})
	c:swarm({
		count = 60,
		size = 0.03,
		field = function(p: any)
			local x, z = p.pos.X, p.pos.Z
			local r = math.sqrt(x * x + z * z)
			if r < 1e-3 then
				r = 1
			end
			return Vector3.new(-z / r * 0.3 - x / r * 0.12, p.vel.Y, x / r * 0.3 - z / r * 0.12)
		end,
		spawn = function(q: any)
			local a = rnd(0, TAU)
			q.p = Vector3.new(math.cos(a) * 0.7, 0.48 + rnd(-0.08, 0.08), math.sin(a) * 0.7)
			q.c, q.life = hsl(rnd(0.7, 0.9), 1, 0.65), rnd(2.5, 4)
		end,
	})
	c:sprite(c:attach(0, 0.48, -0.1), hex("8040ff"), 1.8, 0.85)
	c:light(0.3, 0.5, 0.4, hex("9050ff"), 2.2, 2.4)
	c:light(-0.4, 0.3, -0.2, hex("40a0ff"), 1.4, 2)
end

-- 19 Sun Guardian: rotating sunburst rays, rising solar motes, sparkles, pulse ring, wings
TIERS[19] = function(c)
	local GOLD = hex("ffc23a")
	local SUN_A, SUN_B = hex("ffc020"), hex("fff2a0")
	local sun = c:glowParts(function(n: string)
		return n == "sun_disc"
	end, SUN_A)
	c:glowParts(function(n: string)
		return n == "halo"
	end, hex("ffd34a"))
	c:glowParts(function(n: string)
		local k = tonumber(string.match(n, "^sun_ray_(%d+)$"))
		return k ~= nil and k % 2 == 0
	end, hex("ffd34a"))
	local center = c:attach(0, 0.48, -0.05)
	local burstAlpha = NS({ { 0, 1 }, { 0.25, 0.45 }, { 0.75, 0.45 }, { 1, 1 } })
	c:emit(center, {
		tex = "sunburst",
		rate = 0.5,
		life = { 4, 4 },
		size = { { 0, 1.8 }, { 1, 1.8 } },
		color = ColorSequence.new(hex("ffd060")),
		alpha = burstAlpha,
		rotSpeed = NumberRange.new(9, 9),
		locked = true,
		z = -1,
	})
	c:emit(center, {
		tex = "sunburst",
		rate = 0.5,
		life = { 4, 4 },
		size = { { 0, 1.25 }, { 1, 1.25 } },
		color = ColorSequence.new(hex("ffa020")),
		alpha = burstAlpha,
		rotSpeed = NumberRange.new(-6, -6),
		locked = true,
		z = -1,
	})
	c:sprite(center, GOLD, 1.6, 0.6)
	c:sprite(c:attach(0, 0.48, 0.26), hex("fff0c0"), 0.35, 0.3)
	c:sprite(c:attach(0, 1.24, 0), hex("ffd060"), 0.5, 0.6)
	c:emit(c:volume(1.0, 0.65, 1.0, 0, 0.27, 0), {
		shape = Shape.Cylinder,
		rate = 45,
		life = { 2, 3.5 },
		accel = Vector3.new(0, 0.18, 0),
		color = CS({ { 0, rgb(1, 0.85, 0.4) }, { 1, rgb(1, 0.55, 0.1) } }),
		size = { { 0, 0.035 }, { 1, 0.015 } },
	})
	c:swarm({
		count = 50,
		tex = "star",
		twinkle = 4,
		fadeIn = 0.3,
		fadeOut = 0.5,
		spin = 0.6, -- was field V(-z * 0.6, vy, x * 0.6): orbit the axis
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0.35, 0.6)
			q.p = Vector3.new(math.cos(a) * r, rnd(0.1, 1.1), math.sin(a) * r)
			q.c, q.life, q.s = rgb(1, 0.92, 0.65), rnd(2, 4), rnd(0.04, 0.1)
		end,
	})
	c:emit(c:attach(0, 0.48, 0), {
		tex = "ring",
		orient = Orient.VelocityPerpendicular,
		rate = 0.4,
		life = { 2.5, 2.5 },
		speed = { 0.001, 0.001 },
		size = { { 0, 0.55 }, { 1, 1.65 } },
		color = ColorSequence.new(GOLD),
		rot = NumberRange.new(0, 0),
		alpha = NS({ { 0, 0.2 }, { 1, 1 } }),
	})
	c:light(0, 0.55, 0.45, hex("ffc050"), 3, 2.6)
	c:light(0, 1.2, 0, hex("ffa030"), 1.5, 2)
	local wings = wingRigs(c, function(n: string, s: number)
		return starts(n, "feather_" .. s .. "_")
	end, 0.18, 0.62, -0.1)
	c:every(function(t: number)
		local fl = math.sin(t * 1.8)
		for _, w in ipairs(wings) do
			c:pose(w.rig, CFrame.Angles(0, w.s * fl * 0.3, 0))
		end
		local k = 0.5 + 0.5 * math.sin(t * 3)
		for _, p in ipairs(sun) do
			p.Color = SUN_A:Lerp(SUN_B, k)
		end
	end)
end

-- 20 Rainbow God: hue-cycling bands/wings/lights, rainbow sunburst, helix aura, ring waves, prisms
TIERS[20] = function(c)
	local HUES = { 0, 0.07, 0.14, 0.33, 0.55, 0.68, 0.8 }
	local bands, feathers = {}, {}
	for i = 0, 6 do
		bands[i] = c:glowParts(function(n: string)
			return n == "rainbow_band_" .. i
		end)
		feathers[i] = c:glowParts(function(n: string)
			return n == "prism_feather_-1_" .. i or n == "prism_feather_1_" .. i
		end)
	end
	c:glowParts(prefix("crown_gem_", "band_gem_"))
	local halo = c:ring(0.15, 0.02, 0.02, 32, Color3.new(1, 1, 1), 0)
	local center = c:attach(0, 0.5, -0.06)
	c:emit(center, {
		tex = "sunburst",
		rate = 0.5,
		life = { 4, 4 },
		size = { { 0, 2.2 }, { 1, 2.2 } },
		color = RAINBOW,
		alpha = NS({ { 0, 1 }, { 0.25, 0.4 }, { 0.75, 0.4 }, { 1, 1 } }),
		rotSpeed = NumberRange.new(11, 11),
		locked = true,
		z = -1,
	})
	c:sprite(c:attach(0, 0.48, 0.26), Color3.new(1, 1, 1), 0.4, 0.4)
	c:sprite(center, hex("c080ff"), 2, 0.85)
	local AURA_N = math.max(1, math.floor(220 * SackVFX.Quality + 0.5))
	c:swarm({
		count = 220,
		colorLife = function(k: number, i: number, t: number)
			return hsl(i / AURA_N + t * 0.2 + k * 0.3, 1, 0.62)
		end,
		spin = 1.4, -- was field V(-z * 1.4, vy, x * 1.4): orbit the axis
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0.25, 0.4)
			q.p = Vector3.new(math.cos(a) * r, rnd(-0.05, 0.2), math.sin(a) * r)
			q.v = Vector3.new(0, rnd(0.25, 0.45), 0)
			q.life, q.s = rnd(2, 3.2), rnd(0.015, 0.04)
		end,
	})
	c:swarm({
		count = 80,
		tex = "star",
		twinkle = 6,
		fadeIn = 0.3,
		fadeOut = 0.5,
		colorLife = function(_k: number, i: number, t: number)
			return hsl(i * 0.13 + t * 0.3, 0.8, 0.8)
		end,
		spawn = function(q: any)
			local a, r = rnd(0, TAU), rnd(0.3, 0.8)
			q.p = Vector3.new(math.cos(a) * r, rnd(0, 1.5), math.sin(a) * r)
			q.life, q.s = rnd(1, 2.5), rnd(0.04, 0.12)
		end,
	})
	c:emit(c:attach(0, 0.02, 0), {
		tex = "ring",
		orient = Orient.VelocityPerpendicular,
		rate = 1.25,
		life = { 2.4, 2.4 },
		speed = { 0.06, 0.06 },
		size = { { 0, 0.5 }, { 1, 1.8 } },
		color = RAINBOW,
		rot = NumberRange.new(0, 0),
		alpha = NS({ { 0, 0.05 }, { 1, 1 } }),
	})
	c:emit(c:attach(0, 0.48, 0), {
		tex = "ring",
		orient = Orient.VelocityPerpendicular,
		rate = 0.55,
		life = { 1.8, 1.8 },
		speed = { 0.001, 0.001 },
		size = { { 0, 0.55 }, { 1, 1.35 } },
		color = RAINBOW,
		rot = NumberRange.new(0, 0),
		alpha = NS({ { 0, 0.4 }, { 1, 1 } }),
	})
	for i = 1, 9 do
		local col = Color3.fromHSV(HUES[(i - 1) % 7 + 1], 0.85, 1)
		local p = c:neon(nil, 0.03, 0.045, 0.03, col)
		c:sprite(p, col, 0.16, 0.6)
		c:orbit(p, {
			r = rnd(0.36, 0.48),
			y = rnd(0.3, 0.8),
			speed = 0.7 * (i % 2 == 0 and 1 or -1),
			phase = (i - 1) / 9 * TAU,
			tilt = rnd(-0.3, 0.3),
			bob = 0.05,
			spin = 2,
		})
	end
	local lights = {
		c:light(0.4, 0.6, 0.3, Color3.new(1, 0, 0), 2.5, 2.4),
		c:light(-0.4, 0.4, 0.3, Color3.new(0, 1, 0), 2.5, 2.4),
		c:light(0, 0.8, -0.4, Color3.new(0, 0, 1), 2.5, 2.4),
	}
	local wings = wingRigs(c, function(n: string, s: number)
		return starts(n, "prism_feather_" .. s .. "_")
	end, 0.18, 0.64, -0.1)
	c:every(function(t: number)
		for i = 0, 6 do
			local col = Color3.fromHSV((HUES[i + 1] + t * 0.12) % 1, 0.9, 1)
			for _, p in ipairs(bands[i]) do
				p.Color = col
			end
			for _, p in ipairs(feathers[i]) do
				p.Color = col
			end
		end
		for k, l in ipairs(lights) do
			l.Color = Color3.fromHSV((t * 0.15 + k / 3) % 1, 1, 1)
		end
		halo.place(c:world(0, 1.26 + math.sin(t * 1.6) * 0.02, 0))
		halo.color(Color3.fromHSV((t * 0.2) % 1, 0.6, 1))
		local fl = math.sin(t * 2)
		for _, w in ipairs(wings) do
			c:pose(w.rig, CFrame.Angles(0, w.s * fl * 0.35, 0))
		end
	end)
end

-- Starts tier `tier`'s effects on `model`. `driven`: the caller moves the sack and calls ctx:step(dt) every
-- frame after it; otherwise VFX/SackLod steps it. Either way SackLod sets its level of detail, unless
-- `unmanaged` (full detail, the caller may ctx:setLod itself; a non-driven effect then runs on its own
-- RenderStepped). Returns the context.
function SackVFX.Apply(
	model: Model,
	tier: number,
	rootCF: CFrame,
	S: number,
	driven: boolean?,
	unmanaged: boolean?
): any
	assert(TIERS[tier], "SackVFX: no effects for tier " .. tostring(tier) .. " (1-20 available)")
	SackVFX.Remove(model)
	local c = Ctx.new(model, rootCF, S)
	c.tier = tier
	c.driven = driven == true
	TIERS[tier](c)
	active[model] = c
	c.destroyConn = model.Destroying:Connect(function()
		SackVFX.Remove(model)
	end)
	if unmanaged then
		c:setLod(SackLod.FULL, true, SackLod.PROFILES.HIGH)
		if not driven then
			c:start()
		end
	else
		SackLod.register(c)
	end
	c:prime()
	activatePending(c)
	return c
end

function SackVFX.Remove(model: Model)
	local c = active[model]
	if c then
		c:destroy()
	end
end

return SackVFX
