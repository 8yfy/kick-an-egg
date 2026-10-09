--!strict
-- Partner A. Avalanche visuals (client). Position comes ONLY from Chase.frontZ(...) every frame,
-- so the wall matches the server's catch check exactly.
--   Warn  {theme, startZ, seconds, ownerUserId?}
--   Start {theme, startZ, speed, startTime, ownerUserId?}   (ownerUserId absent = treat as ours)
--   Stop  {}                                               (same target as Start)
-- The wall is a rolling drum: pooled boulders packed on its FRONT half (the face players see) roll
-- over the top and down the face, then recycle to the top with a new size/colour/spot. A small dark
-- core fills gaps, a dust wall sits at the leading edge, plus flying debris cubes and a ring of ground
-- cracks. Budget: <= 60 parts, <= 300 particles.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chase = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Chase"))
local Pool = require(script.Parent.Pool)
local Shake = require(script.Parent.Shake)
local Popup = require(script.Parent.Popup)
local Themes = require(script.Parent.Themes)

type Theme = Themes.Theme

local W = Chase.RunwayWidth
local H = Chase.Avalanche.height
local R = H / 2 -- drum radius
local BOULDERS_OWNER, BOULDERS_OTHER = 40, 20
local DEBRIS = 6
local CRACKS = 8
local CRACK_EVERY = 6 -- studs of travel between ground cracks
local EMERGE = 0.6 -- seconds to burst out of the ground
local CRUMBLE = 1.2
local GRAVITY = Vector3.new(0, -70, 0)
local DEFAULT_SHAPES = { "Block", "Block", "Block", "Wedge" }
local rng = Random.new()

type Boulder = {
	part: BasePart,
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
	startZ: number,
	speed: number,
	startTime: number,
	owner: boolean,
	core: BasePart,
	boulders: { Boulder },
	debris: { Debris },
	cracks: { BasePart },
	crackIndex: number,
	lastCrackZ: number,
	dust: BasePart,
	extra: BasePart?,
	light: PointLight?,
	conn: RBXScriptConnection?,
	stopping: boolean,
	released: boolean,
}

local Avalanche = {}
local walls: { [any]: Wall } = {}
local warns: { [any]: () -> () } = {}

local function isOwner(params: { [string]: any }): boolean
	local uid = params.ownerUserId
	local me = Players.LocalPlayer
	return uid == nil or (me ~= nil and uid == me.UserId)
end

-- Settings > Low detail effects: the owner's wall also uses the low-detail boulder/particle counts.
local function lowDetail(): boolean
	local me = Players.LocalPlayer
	return me ~= nil and me:GetAttribute("LowDetail") == true
end

local function keyOf(target: Instance?): any
	return target or "default"
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
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.7, 0.5),
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

local function paintBoulder(b: Boulder, theme: Theme)
	local p = b.part
	if rng:NextNumber() < theme.neon then
		p.Material = Enum.Material.Neon
		p.Color = theme.neonColor
		p.Transparency = 0
	else
		p.Material = theme.material
		p.Color = theme.colors[rng:NextInteger(1, #theme.colors)]
		p.Transparency = if theme.material == Enum.Material.Glass then 0.15 else 0
	end
end

local function reroll(b: Boulder, theme: Theme)
	b.r = R * rng:NextNumber(0.5, 0.95)
	b.x = rng:NextNumber(-W / 2 + 2.5, W / 2 - 2.5)
	local s = rng:NextNumber(3, 7)
	b.part.Size = Vector3.new(s * rng:NextNumber(0.7, 1.1), rng:NextNumber(2, math.min(6, s + 1)), s)
	b.axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit
	b.rate = rng:NextNumber(2, 6) * (if rng:NextNumber() < 0.5 then -1 else 1)
	paintBoulder(b, theme)
end

-- Ground height under z (map v3): zones at 0, the launch ramp rises to the raised plaza
-- (workspace.Map attributes PlazaY / RampStart / RampEnd; flat 0 on older maps).
local function groundAt(z: number): number
	local map = workspace:FindFirstChild("Map")
	local plazaY = map and map:GetAttribute("PlazaY")
	local a = map and map:GetAttribute("RampStart")
	local b = map and map:GetAttribute("RampEnd")
	if typeof(plazaY) ~= "number" or typeof(a) ~= "number" or typeof(b) ~= "number" or b <= a then
		return 0
	end
	if z <= a then
		return plazaY
	elseif z >= b then
		return 0
	end
	return plazaY * (1 - (z - a) / (b - a))
end

local function spawnDebris(d: Debris, front: number, theme: Theme)
	d.pos = Vector3.new(rng:NextNumber(-W / 2, W / 2), groundAt(front + 1) + rng:NextNumber(2, H * 0.8), front + 1)
	d.vel = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(14, 30), -rng:NextNumber(10, 22))
	d.life = rng:NextNumber(0.8, 1.4)
	local s = rng:NextNumber(0.6, 1.5)
	d.part.Size = Vector3.new(s, s, s)
	d.part.Color = theme.colors[rng:NextInteger(1, #theme.colors)]
	d.part.Material = if theme.neon > 0.2 and rng:NextNumber() < 0.4
		then Enum.Material.Neon
		else Enum.Material.SmoothPlastic
	if d.part.Material == Enum.Material.Neon then
		d.part.Color = theme.neonColor
	end
end

local function frontAt(w: Wall, now: number): number
	return math.max(Chase.frontZ(w.startZ, w.startTime, w.speed, now), Chase.Avalanche.despawnAtZ)
end

-- Where the local player's attention is: the steered egg when the camera follows it (map v3),
-- otherwise the character.
local function playerZ(): number?
	local cam = workspace.CurrentCamera
	local subject = cam and cam.CameraSubject
	if subject and subject:IsA("BasePart") then
		return subject.Position.Z
	end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return if hrp and hrp:IsA("BasePart") then hrp.Position.Z else nil
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
	for _, b in w.boulders do
		Pool.release(b.part)
	end
	for _, d in w.debris do
		Pool.release(d.part)
	end
	for _, c in w.cracks do
		Pool.release(c)
	end
	Pool.release(w.core)
	local dust, extra = w.dust, w.extra
	task.delay(1.7, function() -- let the last particles finish
		Pool.release(dust)
		if extra then
			Pool.release(extra)
		end
	end)
	if w.owner then
		Shake.set("Avalanche", 0)
	end
end

-- Crumble into falling, shrinking cubes and fade out over CRUMBLE seconds.
local function crumble(key: any, w: Wall)
	if w.stopping then
		return
	end
	w.stopping = true
	if w.conn then
		w.conn:Disconnect()
		w.conn = nil
	end
	local front = frontAt(w, workspace:GetServerTimeNow())
	local center = Vector3.new(0, groundAt(front + R) + R, front + R)
	local bits = {}
	for _, b in w.boulders do
		local p = b.part
		local out = (p.Position - center) * Vector3.new(0.3, 1, 1)
		local vel = (if out.Magnitude > 0 then out.Unit else Vector3.yAxis) * rng:NextNumber(8, 20)
			+ Vector3.new(0, rng:NextNumber(6, 18), -w.speed)
		table.insert(bits, { part = p, vel = vel, size = p.Size, spin = CFrame.fromAxisAngle(b.axis, b.rate * 0.05) })
	end
	local dust = w.dust:FindFirstChildOfClass("ParticleEmitter")
	if dust then
		dust.Rate = 0
		dust:Emit(if w.owner then 60 else 30)
	end
	if w.owner then
		Shake.impulse("AvalancheStop", 0.7, 0.5)
	end
	w.core.Transparency = 1
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local k = (os.clock() - t0) / CRUMBLE
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
			local floor = groundAt(pos.Z) + bit.size.Y * shrink / 2
			if pos.Y < floor then
				pos = Vector3.new(pos.X, floor, pos.Z)
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
	local now = workspace:GetServerTimeNow()
	local front = frontAt(w, now)
	local since = now - w.startTime
	-- Burst out of the ground over EMERGE seconds (Back easing overshoot).
	local e = math.clamp(since / EMERGE, 0, 1)
	local s = 1.70158
	local eased = if e >= 1 then 1 else 1 + (s + 1) * (e - 1) ^ 3 + s * (e - 1) ^ 2
	local rise = (1 - eased) * -2.2 * R
	local theta = -(w.speed / R) * math.max(0, since)
	local ground = groundAt(front + R) -- rides up the launch ramp onto the hub (map v3)
	local center = Vector3.new(0, ground + R + rise, front + R)
	w.core.CFrame = CFrame.new(center) * CFrame.Angles(theta, 0, 0)

	local t = os.clock()
	for _, b in w.boulders do
		-- a runs 0 (top) -> -pi (front, at the ground), then wraps back to the top.
		local a = -(-(b.phi + theta) % math.pi)
		if a > b.lastA + 1 then
			reroll(b, w.theme) -- reached the ground: recycle to the top with a new look
		end
		b.lastA = a
		local pos = center + Vector3.new(b.x, b.r * math.cos(a), b.r * math.sin(a))
		b.part.CFrame = CFrame.new(pos) * CFrame.fromAxisAngle(b.axis, b.rate * t)
		if w.theme.rainbow and b.part.Material ~= Enum.Material.Neon then
			b.part.Color = Color3.fromHSV((b.hue + t * 0.25) % 1, 0.55, 1)
		end
	end

	-- Leading-edge emitters ride with the wall.
	w.dust.CFrame = CFrame.new(0, groundAt(front - 1) + 3 + rise, front - 1)
	if w.extra then
		w.extra.CFrame = CFrame.new(0, ground + H + rise, front + R)
	end
	if w.light and w.theme.flicker then
		w.light.Brightness = if rng:NextNumber() < 0.03 then 8 else math.max(0, w.light.Brightness - 0.6)
	end

	-- Debris cubes: ballistic, respawn at the front.
	for _, d in w.debris do
		d.life -= dt
		d.vel += GRAVITY * dt
		d.pos += d.vel * dt
		if d.life <= 0 or d.pos.Y < groundAt(d.pos.Z) then
			spawnDebris(d, front, w.theme)
		end
		d.part.CFrame = CFrame.new(d.pos) * CFrame.Angles(t * 7, t * 5, 0)
		d.part.Transparency = if since < 0 then 1 else 0
	end

	-- Ground cracks left behind the drum.
	local crackZ = front + 2 * R + 2
	local flat = groundAt(crackZ - 5) == groundAt(crackZ + 5) -- no flat cracks on the sloped ramp
	if since > 0 and w.lastCrackZ - front >= CRACK_EVERY and flat then
		w.lastCrackZ = front
		w.crackIndex = w.crackIndex % #w.cracks + 1
		local c = w.cracks[w.crackIndex]
		c.Size = Vector3.new(rng:NextNumber(0.8, 2), 0.06, rng:NextNumber(5, 10))
		c.CFrame = CFrame.new(rng:NextNumber(-W / 2 + 3, W / 2 - 3), groundAt(crackZ) + 0.04, crackZ)
			* CFrame.Angles(0, math.rad(rng:NextNumber(-35, 35)), 0)
		c.Transparency = 0
	end

	if w.owner then
		local z = playerZ()
		local d = if z then math.abs(front - z) else 999
		Shake.set("Avalanche", if since < 0 then 0 else 0.8 * math.clamp((120 - d) / 110, 0, 1))
	end

	-- Reached the safe line: slam and crumble on its own (B's AvalancheStop then just cleans up).
	if front <= Chase.Avalanche.despawnAtZ + 0.01 and since > 0 then
		crumble(key, w)
	end
end

function Avalanche.Warn(target: Instance?, params: { [string]: any })
	local theme = Themes.get(params.theme)
	local startZ: number = params.startZ or 0
	local seconds: number = params.seconds or Chase.Avalanche.warnSeconds
	local owner = isOwner(params)
	local key = keyOf(target)
	if warns[key] then
		warns[key]()
	end

	-- Dust geysers across the runway at startZ, with rock chunks popping out.
	local geysers = {}
	local n = if owner then 6 else 3
	for i = 1, n do
		local x = -W / 2 + (i - 0.5) * W / n
		local a = Pool.anchor(CFrame.new(x, 0.5, startZ), Vector3.new(W / n, 1, 4))
		local e = emitter(a, Themes.SMOKE, theme.dust, NumberSequence.new(3, 9), 0, 1.2, 22)
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(15, 15)
		e.Acceleration = Vector3.new(0, -6, 0)
		table.insert(geysers, { part = a, emitter = e })
	end
	local chunks = {}
	for _ = 1, if owner then 8 else 4 do
		local p = Pool.get("Block")
		local s = rng:NextNumber(0.8, 2)
		p.Size = Vector3.new(s, s, s)
		p.Color = theme.colors[rng:NextInteger(1, #theme.colors)]
		table.insert(chunks, {
			part = p,
			pos = Vector3.new(rng:NextNumber(-W / 2, W / 2), -1, startZ + rng:NextNumber(-2, 2)),
			vel = Vector3.zero,
			wait = rng:NextNumber(0, seconds * 0.8),
		})
	end

	local stopVignette = if owner then Popup.vignette(Color3.fromRGB(255, 40, 40)) else nil
	if owner then
		Popup.banner("RUN!", { Color3.fromRGB(255, 240, 90), Color3.fromRGB(255, 60, 40) }, seconds)
	end

	local t0 = os.clock()
	local alive = true
	local conn = RunService.RenderStepped:Connect(function(dt)
		local k = math.clamp((os.clock() - t0) / seconds, 0, 1)
		for _, g in geysers do
			g.emitter.Rate = 10 + 25 * k
		end
		for _, c in chunks do
			if os.clock() - t0 >= c.wait then
				if c.vel == Vector3.zero then
					c.vel = Vector3.new(rng:NextNumber(-4, 4), rng:NextNumber(18, 32), rng:NextNumber(-4, 4))
				end
				c.vel += GRAVITY * dt
				c.pos += c.vel * dt
				if c.pos.Y < -1 then
					c.pos, c.vel, c.wait =
						Vector3.new(c.pos.X, -1, c.pos.Z), Vector3.zero, os.clock() - t0 + rng:NextNumber(0.1, 0.5)
				end
			end
			c.part.CFrame = CFrame.new(c.pos) * CFrame.Angles(os.clock() * 4, os.clock() * 3, 0)
		end
		if owner then
			Shake.set("AvalancheWarn", 0.6 * k)
		end
	end)

	local function stop()
		if not alive then
			return
		end
		alive = false
		conn:Disconnect()
		if owner then
			Shake.set("AvalancheWarn", 0)
		end
		for _, c in chunks do
			Pool.release(c.part)
		end
		for _, g in geysers do
			g.emitter.Rate = 0
		end
		task.delay(1.3, function()
			for _, g in geysers do
				Pool.release(g.part)
			end
		end)
		if stopVignette then
			task.delay(1.5, stopVignette)
		end
		if warns[key] == stop then
			warns[key] = nil
		end
	end
	warns[key] = stop
	task.delay(seconds + 0.3, stop)
end

function Avalanche.Start(target: Instance?, params: { [string]: any })
	local key = keyOf(target)
	local old = walls[key]
	if old and not old.stopping then
		release(old)
	end
	local theme = Themes.get(params.theme)
	local owner = isOwner(params)
	local now = workspace:GetServerTimeNow()
	local w: Wall = {
		theme = theme,
		startZ = params.startZ or 0,
		speed = params.speed or Chase.avalancheSpeed(1),
		startTime = params.startTime or now,
		owner = owner,
		core = Pool.get("Cylinder"),
		boulders = {},
		debris = {},
		cracks = {},
		crackIndex = 0,
		lastCrackZ = math.huge,
		dust = Pool.anchor(CFrame.new(0, -50, 0), Vector3.new(W, 4, 1)),
		extra = nil,
		light = nil,
		conn = nil,
		stopping = false,
		released = false,
	}
	w.lastCrackZ = w.startZ
	w.core.Size = Vector3.new(W - 8, 2 * R * 0.6, 2 * R * 0.6) -- filler behind the boulders
	w.core.Color = theme.colors[2]:Lerp(Color3.new(0, 0, 0), 0.35)
	w.core.Material = if theme.material == Enum.Material.Glass then Enum.Material.SmoothPlastic else theme.material

	local full = owner and not lowDetail()
	local count = if full then BOULDERS_OWNER else BOULDERS_OTHER
	for i = 1, count do
		local shapes = theme.shapes or DEFAULT_SHAPES
		local kind = shapes[i % #shapes + 1]
		local b: Boulder = {
			part = Pool.get(kind),
			phi = -(i / count) * math.pi + rng:NextNumber(-0.1, 0.1),
			r = R,
			x = 0,
			axis = Vector3.yAxis,
			rate = 1,
			hue = rng:NextNumber(),
			lastA = 0,
		}
		reroll(b, theme)
		b.part.CastShadow = owner
		table.insert(w.boulders, b)
	end
	for _ = 1, if owner then DEBRIS else DEBRIS // 2 do
		local d: Debris = { part = Pool.get("Block"), pos = Vector3.zero, vel = Vector3.zero, life = 0 }
		spawnDebris(d, w.startZ, theme)
		table.insert(w.debris, d)
	end
	for _ = 1, CRACKS do
		local c = Pool.get("Block")
		c.Color = theme.crack
		c.Material = if theme.neon >= 0.2 then Enum.Material.Neon else Enum.Material.SmoothPlastic
		c.Transparency = 1
		c.Size = Vector3.new(1, 0.06, 6)
		table.insert(w.cracks, c)
	end

	local scale = if full then 1 else 0.5
	local dust = emitter(w.dust, Themes.SMOKE, theme.dust, NumberSequence.new(5, 13), 70 * scale, 1.6, 12)
	dust.EmissionDirection = Enum.NormalId.Front
	dust.Acceleration = Vector3.new(0, 4, 0)
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
	if theme.light then
		local l = Instance.new("PointLight")
		l.Color = theme.light
		l.Range = 40
		l.Brightness = if theme.flicker then 0 else 2.5
		l.Shadows = false
		l.Parent = w.core
		w.light = l
	end

	walls[key] = w
	w.conn = RunService.RenderStepped:Connect(function(dt)
		step(key, w, math.min(dt, 0.1))
	end)
	-- The warn effect ends when the wall appears.
	local stopWarn = warns[key]
	if stopWarn then
		task.delay(math.max(0, w.startTime - now), stopWarn)
	end
end

function Avalanche.Stop(target: Instance?, _params: { [string]: any })
	local key = keyOf(target)
	local w = walls[key]
	if w then
		crumble(key, w)
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
		parts += #w.boulders + #w.debris + #w.cracks + 1
	end
	return n, parts
end

return Avalanche
