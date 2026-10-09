--!strict
-- Partner A. Avalanche visuals — "Epic Doom Wall" (numbers in VFX/Recipes/Avalanche.luau).
-- Client only, OWNER ONLY: other players see nothing. Ownership comes from params.ownerUserId or an
-- "OwnerUserId" attribute on the target folder (no owner given = treated as ours).
-- The front position comes ONLY from Chase.frontZ(...) every frame, matching the server's catch check.
--   Warn  {theme, startZ, seconds, ownerUserId?}
--   Start {theme, startZ, speed, startTime, ownerUserId?}
--   Stop  {}                                   (same target as Start)
-- Beats: warn (geysers, chunks, glowing ground cracks, vignette, RUN!, shake ramp) -> burst (flash, ring,
-- dust, sparks, debris, FOV kick) -> roll (drum of tumbling boulders with glowing seams, dust wall,
-- debris, crack trail, wall light, red sky tint, distance shake) -> close call (vignette + speed lines)
-- -> slam at the safe line (flash, energy wall, ring, dust, debris, kick) -> crumble (cubes + embers).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Chase"))
local Pool = require(script.Parent.Pool)
local Shake = require(script.Parent.Shake)
local Popup = require(script.Parent.Popup)
local Themes = require(script.Parent.Themes)
local Player = require(script.Parent.Player)
local Recipe = require(script.Parent.Recipes.Avalanche)
local Clock = require(script.Parent.Clock)

type Theme = Themes.Theme

local WALL = Recipe.wall
local W = WALL.width
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local R = Chase.Avalanche.height * WALL.heightScale / 2 -- visual drum radius
local GRAVITY = Vector3.new(0, -70, 0)
local DEFAULT_SHAPES = { "Block", "Block", "Block", "Wedge" }
local rng = Random.new()

type Boulder = {
	part: BasePart,
	seam: BasePart?,
	phi: number,
	r: number,
	x: number,
	axis: Vector3,
	rate: number,
	hue: number,
	lastA: number,
}
type Debris = { part: BasePart, pos: Vector3, vel: Vector3, life: number }
type Wall = {
	theme: Theme,
	endZ: number,
	palette: Player.Palette,
	glow: Color3,
	startZ: number,
	speed: number,
	startTime: number,
	core: BasePart,
	boulders: { Boulder },
	debris: { Debris },
	pebbles: { Debris },
	riders: { { part: BasePart, offset: Vector3 } },
	cracks: { BasePart },
	crackIndex: number,
	lastCrackZ: number,
	dust: BasePart,
	extra: BasePart?,
	light: PointLight?,
	tint: ColorCorrectionEffect,
	conn: RBXScriptConnection?,
	burst: boolean,
	close: (() -> ())?,
	stopping: boolean,
	released: boolean,
}

local Avalanche = {}
local walls: { [any]: Wall } = {}
local warns: { [any]: () -> () } = {}

-- Owner only: anything that belongs to another player is not drawn at all.
local function isMine(target: Instance?, params: { [string]: any }): boolean
	local uid = params.ownerUserId
	if uid == nil and target then
		uid = target:GetAttribute("OwnerUserId")
	end
	local me = Players.LocalPlayer
	return uid == nil or (me ~= nil and uid == me.UserId)
end

local function lowDetail(): boolean
	local me = Players.LocalPlayer
	return me ~= nil and me:GetAttribute("LowDetail") == true
end

local function keyOf(target: Instance?): any
	return target or "default"
end

local function darker(c: Color3, k: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), k)
end

local function glowOf(theme: Theme): Color3
	return if theme.neon > 0 then theme.neonColor else WALL.defaultGlow
end

-- Dust must read against the (darkened) boulders: dark themes get a light ash, bright ones get darker.
local function dustOf(theme: Theme): Color3
	local c = theme.dust
	local lum = 0.3 * c.R + 0.59 * c.G + 0.11 * c.B
	return if lum < WALL.dust.darkBelow then c:Lerp(WALL.dust.ash, WALL.dust.lift) else darker(c, WALL.dust.darken)
end

local function paletteOf(theme: Theme): Player.Palette
	return {
		c1 = darker(theme.colors[1], WALL.darken),
		c2 = darker(theme.colors[2], WALL.darken),
		c3 = darker(theme.colors[3], WALL.darken),
		neon = glowOf(theme),
		dust = dustOf(theme),
		crack = theme.crack,
		light = theme.light or glowOf(theme),
	}
end

local function emitter(
	parent: BasePart,
	texture: string,
	color: Color3,
	size: NumberSequence,
	rate: number,
	lifetime: number,
	speed: number
): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = ColorSequence.new(color)
	e.Size = size
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Rate = rate
	e.Lifetime = NumberRange.new(lifetime * 0.7, lifetime)
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(35, 20)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.LightInfluence = 0.6
	e.Parent = parent
	return e
end

-- World style: studs on every face, so smooth themes become studded Plastic.
local function studded(m: Enum.Material): Enum.Material
	return if m == Enum.Material.SmoothPlastic then Enum.Material.Plastic else m
end

-- Where the wall slams: the foot of the launch ramp (map v3 raised the plaza), never past the
-- server's despawn line.
local function endZ(): number
	local map = workspace:FindFirstChild("Map")
	local ramp = map and map:GetAttribute("RampEnd")
	return math.max(Chase.Avalanche.despawnAtZ, if typeof(ramp) == "number" then ramp else -math.huge)
end

local function paintBoulder(b: Boulder, w: Wall)
	local p, theme = b.part, w.theme
	local glowing = rng:NextNumber() < math.max(theme.neon, WALL.minNeon)
	if glowing then
		Pool.stud(p, false)
		p.Size *= WALL.glowScale
		p.Material = Enum.Material.Neon
		p.Color = w.glow
		p.Transparency = 0
	else
		p.Material = studded(theme.material)
		Pool.stud(p, p.Material == Enum.Material.Plastic)
		p.Color = w.palette[({ "c1", "c2", "c3" })[rng:NextInteger(1, 3)]]
		p.Transparency = if theme.material == Enum.Material.Glass then 0.15 else 0
	end
	if b.seam then
		b.seam.Transparency = if glowing then 1 else 0
	end
end

local function reroll(b: Boulder, w: Wall)
	b.r = R * rng:NextNumber(0.5, 0.95)
	b.x = rng:NextNumber(-W / 2 + 3, W / 2 - 3)
	local s = rng:NextNumber(WALL.size[1], WALL.size[2])
	b.part.Size = Vector3.new(
		s * rng:NextNumber(0.75, 1.1),
		rng:NextNumber(WALL.size[1] * 0.7, math.min(WALL.size[2], s + 1.5)),
		s
	)
	b.axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
	b.rate = rng:NextNumber(2, 6) * (if rng:NextNumber() < 0.5 then -1 else 1)
	if b.seam then
		b.seam.Size = Vector3.new(b.part.Size.X * 0.85, 0.3, 0.12)
	end
	paintBoulder(b, w)
end

-- A rock shaken loose from the top of a canyon wall somewhere ahead of the front.
local function spawnPebble(d: Debris, front: number, w: Wall)
	local pc = WALL.pebbles
	local side = if rng:NextNumber() < 0.5 then -1 else 1
	d.pos = Vector3.new(
		side * (W / 2 - rng:NextNumber(0.5, 3)),
		rng:NextNumber(pc.height[1], pc.height[2]),
		front - rng:NextNumber(pc.ahead[1], pc.ahead[2])
	)
	d.vel = Vector3.new(-side * rng:NextNumber(2, 6), rng:NextNumber(-2, 4), 0)
	d.life = 3
	local s = rng:NextNumber(pc.size[1], pc.size[2])
	d.part.Size = Vector3.new(s, s * rng:NextNumber(0.6, 1), s)
	d.part.Color = w.palette[if rng:NextNumber() < 0.5 then "c2" else "c3"]
end

local function spawnDebris(d: Debris, front: number, w: Wall)
	d.pos = Vector3.new(rng:NextNumber(-W / 2, W / 2), rng:NextNumber(2, R * 1.6), front + 1)
	d.vel = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(16, 34), -rng:NextNumber(12, 26))
	d.life = rng:NextNumber(0.8, 1.4)
	local s = rng:NextNumber(0.7, 1.8)
	d.part.Size = Vector3.new(s, s, s)
	if rng:NextNumber() < 0.35 then
		d.part.Material = Enum.Material.Neon
		d.part.Color = w.glow
	else
		d.part.Material = Enum.Material.SmoothPlastic
		d.part.Color = w.palette[({ "c1", "c2", "c3" })[rng:NextInteger(1, 3)]]
	end
end

local function frontAt(w: Wall, now: number): number
	return math.max(Chase.frontZ(w.startZ, w.startTime, w.speed, now), w.endZ)
end

local function playerZ(): number?
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return if hrp and hrp:IsA("BasePart") then hrp.Position.Z else nil
end

local function setClose(w: Wall, on: boolean)
	if on and not w.close then
		local stopV = Popup.vignette(Recipe.closeCall.vignette, 0.32)
		local stopS = if Recipe.closeCall.speedLines then Popup.speedLines() else function() end
		w.close = function()
			stopV()
			stopS()
		end
	elseif not on and w.close then
		w.close()
		w.close = nil
	end
end

local function release(w: Wall)
	if w.released then
		return
	end
	w.released = true
	if w.conn then
		w.conn:Disconnect()
		w.conn = nil
	end
	setClose(w, false)
	for _, b in w.boulders do
		Pool.release(b.part)
		if b.seam then
			Pool.release(b.seam)
		end
	end
	for _, d in w.debris do
		Pool.release(d.part)
	end
	for _, d in w.pebbles do
		Pool.release(d.part)
	end
	for _, c in w.cracks do
		Pool.release(c)
	end
	Pool.release(w.core)
	local dust, extra, tint, riders = w.dust, w.extra, w.tint, w.riders
	Clock.delay(1.7, function() -- let the last particles finish
		Pool.release(dust)
		for _, r in riders do
			Pool.release(r.part)
		end
		if extra then
			Pool.release(extra)
		end
	end)
	local fade = WALL.tint.fade
	game:GetService("TweenService")
		:Create(tint, TweenInfo.new(fade), { TintColor = Color3.new(1, 1, 1), Contrast = 0, Saturation = 0 })
		:Play()
	Clock.delay(fade + 0.05, function()
		tint:Destroy()
	end)
	Shake.set("Avalanche", 0)
end

-- Slam into the safe line (or Stop): one-shot slam recipe, then break into falling cubes + embers.
local function crumble(key: any, w: Wall, slam: boolean)
	if w.stopping then
		return
	end
	w.stopping = true
	if w.conn then
		w.conn:Disconnect()
		w.conn = nil
	end
	setClose(w, false)
	local front = frontAt(w, Clock.server())
	if slam then
		Player.play(Recipe.slam, CFrame.new(0, 0, w.endZ), w.palette, true)
	end
	Player.play({ Recipe.crumble.embers }, CFrame.new(0, 2, front + R), w.palette, true)
	local center = Vector3.new(0, R, front + R)
	local bits = {}
	for _, b in w.boulders do
		local p = b.part
		if b.seam then
			b.seam.Transparency = 1
		end
		local out = (p.Position - center) * Vector3.new(0.3, 1, 1)
		local vel = (if out.Magnitude > 0 then out.Unit else Vector3.yAxis) * rng:NextNumber(8, 22)
			+ Vector3.new(0, rng:NextNumber(6, 20), -w.speed)
		table.insert(bits, { part = p, vel = vel, size = p.Size, spin = CFrame.fromAxisAngle(b.axis, b.rate * 0.05) })
	end
	local dust = w.dust:FindFirstChildOfClass("ParticleEmitter")
	if dust then
		dust.Rate = 0
	end
	for _, r in w.riders do
		for _, e in r.part:GetChildren() do
			if e:IsA("ParticleEmitter") then
				e.Rate = 0
			end
		end
	end
	for _, d in w.pebbles do
		d.part.Transparency = 1
	end
	w.core.Transparency = 1
	local seconds = Recipe.crumble.seconds
	local t0 = Clock.now()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(rdt)
		local dt = Clock.dt(rdt)
		local k = (Clock.now() - t0) / seconds
		if k >= 1 then
			conn:Disconnect()
			release(w)
			if walls[key] == w then
				walls[key] = nil
			end
			return
		end
		local shrink = 1 - 0.65 * k
		local fade = math.clamp((k - 0.4) / 0.6, 0, 1)
		for _, bit in bits do
			bit.vel += GRAVITY * dt
			local pos = bit.part.Position + bit.vel * dt
			if pos.Y < bit.size.Y * shrink / 2 then
				pos = Vector3.new(pos.X, bit.size.Y * shrink / 2, pos.Z)
				bit.vel = Vector3.new(bit.vel.X * 0.6, -bit.vel.Y * 0.3, bit.vel.Z * 0.6)
			end
			bit.part.Size = bit.size * shrink
			bit.part.CFrame = CFrame.new(pos) * bit.part.CFrame.Rotation * bit.spin
			bit.part.Transparency = math.max(bit.part.Transparency, fade)
		end
		for _, c in w.cracks do
			c.Transparency = math.max(c.Transparency, fade)
		end
		for _, d in w.debris do
			d.part.Transparency = 1
		end
	end)
end

local function step(key: any, w: Wall, dt: number)
	local now = Clock.server()
	local front = frontAt(w, now)
	local since = now - w.startTime
	if since >= 0 and not w.burst then
		w.burst = true
		Player.play(Recipe.burst, CFrame.new(0, 0.5, front), w.palette, true)
	end
	local e = math.clamp(since / WALL.emerge, 0, 1)
	local s = 1.70158
	local eased = if e >= 1 then 1 else 1 + (s + 1) * (e - 1) ^ 3 + s * (e - 1) ^ 2
	local rise = (1 - eased) * -2.2 * R
	local theta = -(w.speed / R) * math.max(0, since)
	local center = Vector3.new(0, R + rise, front + R)
	w.core.CFrame = CFrame.new(center) * CFrame.Angles(theta, 0, 0)

	local t = Clock.now()
	for _, b in w.boulders do
		-- a runs 0 (top) -> -pi (front, at the ground), then wraps back to the top.
		local a = -(-(b.phi + theta) % math.pi)
		if a > b.lastA + 1 then
			reroll(b, w)
		end
		b.lastA = a
		local pos = center + Vector3.new(b.x, b.r * math.cos(a), b.r * math.sin(a))
		b.part.CFrame = CFrame.new(pos) * CFrame.fromAxisAngle(b.axis, b.rate * t)
		if b.seam then
			b.seam.CFrame = b.part.CFrame
				* CFrame.new(0, b.part.Size.Y * 0.1, -b.part.Size.Z / 2 - 0.04)
				* CFrame.Angles(0, 0, 0.35)
		end
		if w.theme.rainbow and b.part.Material ~= Enum.Material.Neon then
			b.part.Color = Color3.fromHSV((b.hue + t * 0.25) % 1, 0.55, 1)
		end
	end

	w.dust.CFrame = CFrame.new(0, 3 + rise, front - 1)
	for _, r in w.riders do
		r.part.CFrame = CFrame.new(r.offset.X, r.offset.Y + rise, front + r.offset.Z)
	end
	for _, d in w.pebbles do
		d.life -= dt
		d.vel += GRAVITY * dt
		d.pos += d.vel * dt
		if d.life <= 0 or d.pos.Y < 0.5 then
			spawnPebble(d, front, w)
		end
		d.part.CFrame = CFrame.new(d.pos) * CFrame.Angles(t * 5, t * 3, 0)
		d.part.Transparency = if since < 0 then 1 else 0
	end
	if w.extra then
		w.extra.CFrame = CFrame.new(0, 2 * R + rise, front + R)
	end
	if w.light then
		w.light.Brightness = if w.theme.flicker
			then (if rng:NextNumber() < 0.03 then 8 else math.max(0, w.light.Brightness - 0.6))
			else WALL.light.brightness * (0.85 + 0.15 * math.sin(t * 9))
	end

	for _, d in w.debris do
		d.life -= dt
		d.vel += GRAVITY * dt
		d.pos += d.vel * dt
		if d.life <= 0 or d.pos.Y < 0 then
			spawnDebris(d, front, w)
		end
		d.part.CFrame = CFrame.new(d.pos) * CFrame.Angles(t * 7, t * 5, 0)
		d.part.Transparency = if since < 0 then 1 else 0
	end

	if since > 0 and w.lastCrackZ - front >= WALL.crackEvery then
		w.lastCrackZ = front
		w.crackIndex = w.crackIndex % #w.cracks + 1
		local c = w.cracks[w.crackIndex]
		c.Size = Vector3.new(rng:NextNumber(0.8, 2.2), 0.06, rng:NextNumber(5, 11))
		c.CFrame = CFrame.new(rng:NextNumber(-W / 2 + 3, W / 2 - 3), 0.05, front + 2 * R + 2)
			* CFrame.Angles(0, math.rad(rng:NextNumber(-35, 35)), 0)
		c.Transparency = 0
	end

	local z = playerZ()
	local dist = if z then math.abs(front - z) else 999
	local sh = WALL.shake
	Shake.set("Avalanche", if since < 0 then 0 else sh.max * math.clamp((sh.far - dist) / (sh.far - sh.near), 0, 1))
	setClose(w, since > 0 and dist < Recipe.closeCall.distance)

	if front <= w.endZ + 0.01 and since > 0 then
		crumble(key, w, true)
	end
end

function Avalanche.Warn(target: Instance?, params: { [string]: any })
	if not isMine(target, params) then
		return
	end
	local theme = Themes.get(params.theme)
	local palette = paletteOf(theme)
	local cfg = Recipe.warn
	local startZ: number = params.startZ or 0
	local seconds: number = params.seconds or Chase.Avalanche.warnSeconds
	local key = keyOf(target)
	if warns[key] then
		warns[key]()
	end

	local geysers = {}
	for i = 1, cfg.geysers do
		local x = -W / 2 + (i - 0.5) * W / cfg.geysers
		local a = Pool.anchor(CFrame.new(x, 0.5, startZ), Vector3.new(W / cfg.geysers, 1, 4))
		local e = emitter(a, Themes.SMOKE, palette.dust, NumberSequence.new(3, 10), 0, 1.2, 24)
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(15, 15)
		e.Acceleration = Vector3.new(0, -6, 0)
		table.insert(geysers, { part = a, emitter = e })
	end
	-- glowing cracks spreading across the ground where it will erupt
	local cracks = {}
	if cfg.crackGlow then
		for i = 1, 5 do
			local c = Pool.get("Block")
			c.Material = Enum.Material.Neon
			c.Color = palette.neon
			c.Transparency = 1
			c.CFrame = CFrame.new(-W / 2 + i * W / 6, 0.06, startZ + rng:NextNumber(-3, 3))
				* CFrame.Angles(0, math.rad(rng:NextNumber(-50, 50)), 0)
			c.Size = Vector3.new(0.6, 0.06, 0.1)
			table.insert(cracks, { part = c, len = rng:NextNumber(5, 10) })
		end
	end
	local chunks = {}
	for _ = 1, cfg.chunks do
		local p = Pool.get("Block")
		local s = rng:NextNumber(0.8, 2.2)
		p.Size = Vector3.new(s, s, s)
		p.Color = palette[({ "c1", "c2", "c3" })[rng:NextInteger(1, 3)]]
		table.insert(chunks, {
			part = p,
			pos = Vector3.new(rng:NextNumber(-W / 2, W / 2), -1, startZ + rng:NextNumber(-2, 2)),
			vel = Vector3.zero,
			wait = rng:NextNumber(0, seconds * 0.8),
		})
	end

	local stopVignette = Popup.vignette(cfg.vignette)
	Popup.banner(cfg.banner.text, { cfg.banner.top, cfg.banner.bottom }, seconds)

	local t0 = Clock.now()
	local alive = true
	local conn = RunService.RenderStepped:Connect(function(rdt)
		local dt = Clock.dt(rdt)
		local k = math.clamp((Clock.now() - t0) / seconds, 0, 1)
		for _, g in geysers do
			g.emitter.Rate = cfg.geyserRate[1] + (cfg.geyserRate[2] - cfg.geyserRate[1]) * k
		end
		for _, c in cracks do
			c.part.Size = Vector3.new(0.6, 0.06, math.max(0.1, c.len * k))
			c.part.Transparency = 1 - math.min(1, k * 2)
		end
		for _, c in chunks do
			if Clock.now() - t0 >= c.wait then
				if c.vel == Vector3.zero then
					c.vel = Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(18, 34), rng:NextNumber(-4, 4))
				end
				c.vel += GRAVITY * dt
				c.pos += c.vel * dt
				if c.pos.Y < -1 then
					c.pos, c.vel, c.wait =
						Vector3.new(c.pos.X, -1, c.pos.Z), Vector3.zero, Clock.now() - t0 + rng:NextNumber(0.1, 0.5)
				end
			end
			c.part.CFrame = CFrame.new(c.pos) * CFrame.Angles(Clock.now() * 4, Clock.now() * 3, 0)
		end
		Shake.set("AvalancheWarn", cfg.shakeMax * k)
	end)

	local function stop()
		if not alive then
			return
		end
		alive = false
		conn:Disconnect()
		Shake.set("AvalancheWarn", 0)
		for _, c in chunks do
			Pool.release(c.part)
		end
		for _, c in cracks do
			Pool.release(c.part)
		end
		for _, g in geysers do
			g.emitter.Rate = 0
		end
		Clock.delay(1.3, function()
			for _, g in geysers do
				Pool.release(g.part)
			end
		end)
		Clock.delay(1.5, stopVignette)
		if warns[key] == stop then
			warns[key] = nil
		end
	end
	warns[key] = stop
	Clock.delay(seconds + 0.3, stop)
end

function Avalanche.Start(target: Instance?, params: { [string]: any })
	if not isMine(target, params) then
		return
	end
	local key = keyOf(target)
	local old = walls[key]
	if old and not old.stopping then
		release(old)
	end
	local theme = Themes.get(params.theme)
	local now = Clock.server()
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "AvalancheTint"
	tint.Parent = Lighting
	local w: Wall = {
		theme = theme,
		endZ = endZ(),
		palette = paletteOf(theme),
		glow = darker(glowOf(theme), WALL.glowDarken),
		startZ = params.startZ or 0,
		speed = params.speed or Chase.avalancheSpeed(1),
		startTime = params.startTime or now,
		core = Pool.get("Cylinder"),
		boulders = {},
		debris = {},
		pebbles = {},
		riders = {},
		cracks = {},
		crackIndex = 0,
		lastCrackZ = params.startZ or 0,
		dust = Pool.anchor(CFrame.new(0, -50, 0), Vector3.new(W, 4, 1)),
		extra = nil,
		light = nil,
		tint = tint,
		conn = nil,
		burst = false,
		close = nil,
		stopping = false,
		released = false,
	}
	game:GetService("TweenService")
		:Create(
			tint,
			TweenInfo.new(WALL.tint.fade),
			{ TintColor = WALL.tint.color, Contrast = WALL.tint.contrast, Saturation = WALL.tint.saturation }
		)
		:Play()
	w.core.Size = Vector3.new(W - 8, 2 * R * 0.6, 2 * R * 0.6)
	w.core.Color = darker(theme.colors[2], 0.45)
	w.core.Material = if theme.material == Enum.Material.Glass then Enum.Material.Plastic else studded(theme.material)
	Pool.stud(w.core, w.core.Material == Enum.Material.Plastic)

	local low = lowDetail()
	local count = if low then WALL.boulders // 2 else WALL.boulders
	local seams = if low then 0 else WALL.seams
	for i = 1, count do
		local shapes = theme.shapes or DEFAULT_SHAPES
		local b: Boulder = {
			part = Pool.get(shapes[i % #shapes + 1]),
			seam = nil,
			phi = -(i / count) * math.pi + rng:NextNumber(-0.1, 0.1),
			r = R,
			x = 0,
			axis = Vector3.yAxis,
			rate = 1,
			hue = rng:NextNumber(),
			lastA = 0,
		}
		if i <= seams then
			local seam = Pool.get("Block")
			seam.Material = Enum.Material.Neon
			seam.Color = w.glow
			b.seam = seam
		end
		reroll(b, w)
		b.part.CastShadow = true
		table.insert(w.boulders, b)
	end
	for _ = 1, WALL.debris do
		local d: Debris = { part = Pool.get("Block"), pos = Vector3.zero, vel = Vector3.zero, life = 0 }
		spawnDebris(d, w.startZ, w)
		table.insert(w.debris, d)
	end
	for _ = 1, if low then 0 else WALL.pebbles.count do
		local d: Debris = { part = Pool.get("Block"), pos = Vector3.zero, vel = Vector3.zero, life = 0 }
		d.part.Material = Enum.Material.Plastic
		Pool.stud(d.part, true)
		d.part.CastShadow = true
		spawnPebble(d, w.startZ, w)
		table.insert(w.pebbles, d)
	end
	for _ = 1, WALL.cracks do
		local c = Pool.get("Block")
		c.Color = w.glow
		c.Material = Enum.Material.Neon
		c.Transparency = 1
		c.Size = Vector3.new(1, 0.06, 6)
		table.insert(w.cracks, c)
	end

	local scale = if low then 0.5 else 1
	local dc = WALL.dust
	local dust = emitter(
		w.dust,
		Themes.SMOKE,
		w.palette.dust,
		NumberSequence.new(dc.size[1], dc.size[2]),
		dc.rate * scale,
		dc.life,
		dc.speed
	)
	dust.EmissionDirection = Enum.NormalId.Front
	dust.Acceleration = Vector3.new(0, 4, 0)

	-- Emitters that ride the front (offset from (0, rise, front); Front = toward the bases).
	local function rider(
		offset: Vector3,
		area: Vector3,
		dir: Enum.NormalId,
		texture: string,
		color: Color3,
		size: { number },
		rate: number,
		life: number,
		speed: number,
		glow: boolean
	): ParticleEmitter
		local a = Pool.anchor(CFrame.new(0, -50, 0), area)
		local e = emitter(a, texture, color, NumberSequence.new(size[1], size[2]), rate * scale, life, speed)
		e.EmissionDirection = dir
		if glow then
			e.LightEmission = 1
			e.LightInfluence = 0
		end
		table.insert(w.riders, { part = a, offset = offset })
		return e
	end
	local sc, sk, cr = WALL.scrape, WALL.skirt, WALL.crest
	for _, side in { -1, 1 } do
		local at, area = Vector3.new(side * (W / 2 - 0.5), R * 0.7, R * 0.4), Vector3.new(1, R * 1.2, R * 0.8)
		local sparks = rider(at, area, Enum.NormalId.Front, SPARK, w.glow, sc.size, sc.rate, sc.life, sc.speed, true)
		sparks.Acceleration = Vector3.new(0, -40, 0)
		sparks.SpreadAngle = Vector2.new(50, 50)
		if not low then
			local grind = rider(
				at,
				area,
				Enum.NormalId.Front,
				Themes.SMOKE,
				w.palette.dust,
				sc.dustSize,
				sc.dustRate,
				1.4,
				8,
				false
			)
			grind.Acceleration = Vector3.new(0, 3, 0)
		end
	end
	local skirt = rider(
		Vector3.new(0, 0.5, -0.5),
		Vector3.new(W - 2, 1, 1),
		Enum.NormalId.Front,
		Themes.SMOKE,
		w.palette.dust,
		sk.size,
		sk.rate,
		sk.life,
		sk.speed,
		false
	)
	skirt.SpreadAngle = Vector2.new(60, 10)
	local crest = rider(
		Vector3.new(0, 2 * R, R),
		Vector3.new(W - 8, 1, R * 0.6),
		Enum.NormalId.Top,
		SPARK,
		w.glow,
		cr.size,
		cr.rate,
		cr.life,
		cr.speed,
		true
	)
	crest.Acceleration = Vector3.new(0, -35, 0)
	crest.SpreadAngle = Vector2.new(40, 40)
	local ex = theme.extra
	if ex then
		local a = Pool.anchor(CFrame.new(0, -50, 0), Vector3.new(W - 4, 1, R))
		local e = emitter(
			a,
			ex.texture,
			ex.color,
			NumberSequence.new(ex.size, ex.size * 0.4),
			ex.rate * scale,
			ex.lifetime,
			ex.speed
		)
		e.EmissionDirection = Enum.NormalId.Top
		e.Acceleration = Vector3.new(0, -12, 0)
		if ex.light then
			e.LightEmission = 1
		end
		w.extra = a
	end
	local l = Instance.new("PointLight")
	l.Color = w.palette.light
	l.Range = WALL.light.range
	l.Brightness = if theme.flicker then 0 else WALL.light.brightness
	l.Shadows = false
	l.Parent = w.core
	w.light = l

	walls[key] = w
	w.conn = RunService.RenderStepped:Connect(function(dt)
		step(key, w, Clock.dt(math.min(dt, 0.1)))
	end)
	local stopWarn = warns[key]
	if stopWarn then
		Clock.delay(math.max(0, w.startTime - now), stopWarn)
	end
end

function Avalanche.Stop(target: Instance?, _params: { [string]: any })
	local key = keyOf(target)
	local w = walls[key]
	if w then
		crumble(key, w, false)
	end
	local stopWarn = warns[key]
	if stopWarn then
		stopWarn()
	end
end

-- Debug: number of live walls and their parts.
function Avalanche.stats(): (number, number)
	local n, parts = 0, 0
	for _, w in walls do
		n += 1
		parts += #w.boulders * 2 + #w.debris + #w.pebbles + #w.cracks + 1
	end
	return n, parts
end

return Avalanche
