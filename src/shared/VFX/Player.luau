--!strict
-- Partner A. Plays a data recipe: a list of layers, each starting `at` ms after play().
-- Everything is pooled and self-cleaning. Colours may be Color3 or a token ("$neon", "$dust",
-- "$c1".."$c3", "$crack", "$light") resolved from the `palette` passed to play().
--
-- Layer kinds (all fields optional unless noted):
--   flash     { size = {from, to}, seconds, color, light = brightness }          expanding Neon ball + light
--   ring      { radius = {from, to}, seconds, color, thickness, segments, y }    flat shockwave ring of Neon blocks
--   particles { count, texture, color = {c..}, size = {{t, v}..}, transparency = {{t, v}..}, life = {min, max},
--               speed = {min, max}, spread, accel = Vector3, light, drag, area = Vector3, dir = "Top" }
--   debris    { count, size = {min, max}, power, seconds, colors = {c..}, flat, neon }
--   light     { color, range, brightness, seconds }                              PointLight pulse
--   shake     { amount, seconds }                                                camera impulse (owner)
--   fov       { kick, seconds }                                                  FOV punch (owner)
--   wall      { width, height, seconds, color }                                  rising energy wall that fades
local RunService = game:GetService("RunService")
local Pool = require(script.Parent.Pool)
local Burst = require(script.Parent.Burst)
local Shake = require(script.Parent.Shake)
local Clock = require(script.Parent.Clock)

export type Layer = { [string]: any }
export type Recipe = { Layer }
export type Palette = { [string]: Color3 }

local Player = {}

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local rng = Random.new()

local function color(c: any, palette: Palette?): Color3
	if typeof(c) == "Color3" then
		return c
	end
	if typeof(c) == "string" and palette then
		local v = palette[string.sub(c, 2)]
		if v then
			return v
		end
	end
	return Color3.new(1, 1, 1)
end

local function curve(points: { { number } }?, default: number): NumberSequence
	if not points or #points == 0 then
		return NumberSequence.new(default)
	end
	local keys = {}
	for _, p in points do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

local function colorSeq(list: { any }?, palette: Palette?): ColorSequence
	if not list or #list == 0 then
		return ColorSequence.new(Color3.new(1, 1, 1))
	end
	if #list == 1 then
		return ColorSequence.new(color(list[1], palette))
	end
	local keys = {}
	for i, c in list do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#list - 1), color(c, palette)))
	end
	return ColorSequence.new(keys)
end

-- Per-frame driver that stops after `seconds`; fn(k) gets progress 0..1.
local function over(seconds: number, fn: (k: number) -> (), done: (() -> ())?)
	local t0 = Clock.now()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = math.clamp((Clock.now() - t0) / seconds, 0, 1)
		fn(k)
		if k >= 1 then
			conn:Disconnect()
			if done then
				done()
			end
		end
	end)
end

local KINDS: { [string]: (layer: Layer, cf: CFrame, palette: Palette?, owner: boolean) -> () } = {}

function KINDS.flash(l, cf, palette)
	local sizes = l.size or { 2, 14 }
	local seconds = l.seconds or 0.15
	local c = color(l.color, palette)
	local ball = Pool.get("Ball")
	ball.Material = Enum.Material.Neon
	ball.Color = c
	ball.CFrame = cf
	ball.Size = Vector3.one * sizes[1]
	ball.Transparency = 0.05
	local light = Instance.new("PointLight")
	light.Color = c
	light.Range = sizes[2] * 2
	light.Brightness = l.light or 6
	light.Parent = ball
	local bright = light.Brightness
	over(seconds * 1.5, function(k)
		local e = 1 - (1 - math.min(1, k * 1.5)) ^ 2
		ball.Size = Vector3.one * (sizes[1] + (sizes[2] - sizes[1]) * e)
		ball.Transparency = 0.05 + 0.95 * e
		light.Brightness = bright * (1 - k)
	end, function()
		Pool.release(ball)
	end)
end

function KINDS.ring(l, cf, palette)
	local radius = l.radius or { 2, 30 }
	local seconds = l.seconds or 0.4
	local n = l.segments or 16
	local thick = l.thickness or 1.2
	local c = color(l.color, palette)
	local segs = {}
	for i = 1, n do
		local p = Pool.get("Block")
		p.Material = Enum.Material.Neon
		p.Color = c
		segs[i] = p
	end
	local center = cf.Position + Vector3.new(0, l.y or 0.4, 0)
	over(seconds, function(k)
		local e = 1 - (1 - k) ^ 3
		local r = radius[1] + (radius[2] - radius[1]) * e
		local len = 2 * math.pi * r / n * 1.12 + 0.4 -- overlap so the ring has no gaps
		for i, p in segs do
			local a = (i - 0.5) / n * 2 * math.pi
			p.Size = Vector3.new(thick * (1 - k * 0.6), thick * 0.5 * (1 - k * 0.6), len)
			p.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, -a, 0)
			p.Transparency = k ^ 1.5
		end
	end, function()
		for _, p in segs do
			Pool.release(p)
		end
	end)
end

function KINDS.particles(l, cf, palette)
	local a = Pool.anchor(cf, l.area or Vector3.new(2, 1, 2))
	local e = Instance.new("ParticleEmitter")
	e.Texture = l.texture or SPARK
	e.Color = colorSeq(l.color, palette)
	e.Size = curve(l.size, 1)
	e.Transparency = curve(l.transparency or { { 0, 0 }, { 0.7, 0.3 }, { 1, 1 } }, 0)
	local life = l.life or { 0.5, 1 }
	e.Lifetime = NumberRange.new(life[1], life[2])
	local sp = l.speed or { 10, 20 }
	e.Speed = NumberRange.new(sp[1], sp[2])
	local spread = l.spread or 180
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Acceleration = l.accel or Vector3.zero
	e.LightEmission = l.light or 0
	e.LightInfluence = if (l.light or 0) > 0.5 then 0 else 1
	e.Drag = l.drag or 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-120, 120)
	e.EmissionDirection = (Enum.NormalId :: any)[l.dir or "Top"]
	e.Rate = 0
	e.TimeScale = if Clock.isFrozen() then 0 else 1
	e.Parent = a
	e:Emit(l.count or 20)
	Clock.delay(life[2] + 0.2, Pool.release, a)
end

function KINDS.debris(l, cf, palette)
	local colors = {}
	for _, c in l.colors or { "$c1", "$c2", "$c3" } do
		table.insert(colors, color(c, palette))
	end
	local sz = l.size or { 0.4, 1.2 }
	Burst.play(
		cf.Position,
		l.count or 10,
		colors,
		NumberRange.new(sz[1], sz[2]),
		l.power or 28,
		l.seconds or 1.2,
		l.flat,
		l.neon
	)
end

function KINDS.light(l, cf, palette)
	local a = Pool.anchor(cf)
	local light = Instance.new("PointLight")
	light.Color = color(l.color, palette)
	light.Range = l.range or 30
	light.Brightness = l.brightness or 5
	light.Shadows = false
	light.Parent = a
	local bright = light.Brightness
	over(l.seconds or 0.5, function(k)
		light.Brightness = bright * (1 - k) ^ 2
	end, function()
		Pool.release(a)
	end)
end

function KINDS.shake(l, _cf, _palette, owner)
	if owner then
		Shake.impulse("Recipe" .. tostring(rng:NextInteger(1, 1e6)), l.amount or 0.5, l.seconds or 0.3)
	end
end

function KINDS.fov(l, _cf, _palette, owner)
	local cam = workspace.CurrentCamera
	if not (owner and cam) then
		return
	end
	local base = cam:GetAttribute("BaseFOV") :: number? or cam.FieldOfView
	cam:SetAttribute("BaseFOV", base)
	local kick = l.kick or 6
	local seconds = l.seconds or 0.35
	over(seconds, function(k)
		cam.FieldOfView = base + kick * math.sin(k * math.pi) * (1 - k * 0.3)
	end, function()
		cam.FieldOfView = base
		cam:SetAttribute("BaseFOV", nil)
	end)
end

function KINDS.wall(l, cf, palette)
	local width = l.width or 60
	local height = l.height or 24
	local seconds = l.seconds or 0.6
	local p = Pool.get("Block")
	p.Material = Enum.Material.Neon
	p.Color = color(l.color, palette)
	over(seconds, function(k)
		local up = math.min(1, k * 4)
		p.Size = Vector3.new(width, height * up, 0.6)
		p.CFrame = cf * CFrame.new(0, height * up / 2, 0)
		p.Transparency = 0.25 + 0.75 * math.max(0, (k - 0.25) / 0.75)
	end, function()
		Pool.release(p)
	end)
end

-- Play `recipe` at `cf`. `owner` gates camera layers (shake, fov).
function Player.play(recipe: Recipe, cf: CFrame, palette: Palette?, owner: boolean?)
	for _, layer in recipe do
		local fn = KINDS[layer.kind]
		if fn then
			local at = (layer.at or 0) / 1000
			local offset = if layer.offset then cf * CFrame.new(layer.offset) else cf
			if at <= 0 then
				fn(layer, offset, palette, owner == true)
			else
				Clock.delay(at, fn, layer, offset, palette, owner == true)
			end
		end
	end
end

return Player
