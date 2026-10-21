--!strict
-- Partner A. WeatherFx: the weather visual controller (client only). Makes the weather the server runs FELT in the
-- world, with zero-snap transitions. Started by Controllers/WeatherVisualController.
--   * Layers (WeatherFx/Layer), one per live look: "global:<id>", "local:<key>" (you're in that local storm),
--     "region:<key>" (that storm's own area, for anyone near). Each has its own weight; a change of weather only
--     re-targets weights, so old and new overlap and crossfade (particles by Rate, props / beams by transparency,
--     beds by Volume). A twice-quick change simply turns the fades around mid-way. Faded-out layers are destroyed
--     after their particles finish (no leaks).
--   * Inside a local storm the global look dims to 40 % so the local one reads; Lighting gets the global target
--     first, then the local accent, through the ONE writer, WeatherFx/LightingStack, which restores the captured
--     baseline when everything has faded.
--   * One BindToRenderStep loop (after the camera) while anything is live or fading; unbound when idle.
-- Respects LowDetail / graphics level / phones (quality scales emitter rates and comet counts), Reduced Motion
-- (no flicker, no exposure pulse, props stay still) and the Ambience / UI volume settings (SoundGroups).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Elements = require(script.Elements)
local Layer = require(script.Layer)
local LightingStack = require(script.LightingStack)
local Registry = require(script.Registry)
local State = require(script.State)
local WeatherSound = require(script.Sound)

local WeatherFx = {}
WeatherFx.State = State
WeatherFx.Registry = Registry
WeatherFx.Sound = WeatherSound
WeatherFx.LightingStack = LightingStack

local GLOBAL_UNDER_LOCAL = 0.4 -- the global look's weight while you stand in a local storm
local REGION_VIEW = 350 -- a local storm's area shows within this many studs of its edge

local layers: { [string]: Layer.Layer } = {}
local bound = false
local folder: Folder? = nil
local pulse = { ev = 0, t0 = 0, dur = 1 }
local lastCompose: { [string]: number } = {}
local nextGround, nextQuality = 0, 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local ctx: Elements.Ctx = {
	cam = Vector3.zero,
	look = Vector3.zAxis,
	yaw = 0,
	ground = 0,
	q = 1,
	reduced = false,
	t = 0,
	dt = 0,
	folder = workspace,
	pulse = function(ev: number, seconds: number)
		pulse.ev, pulse.t0, pulse.dur = ev, os.clock(), seconds
	end,
	sound = function(key: string, at: Vector3?, delay: number?)
		WeatherSound.play(key, at, { delay = delay, far = 900 })
	end,
}

local function weatherFolder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local n = Instance.new("Folder")
	n.Name = "WeatherFx"
	n.Parent = workspace
	folder = n
	ctx.folder = n
	return n
end

function WeatherFx.quality(): number
	local q = 1
	local me = Players.LocalPlayer
	if me and me:GetAttribute("LowDetail") == true then
		q = 0.35
	end
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	if ok and typeof(level) == "number" and level > 0 then
		q = math.min(q, if level <= 3 then 0.4 elseif level <= 6 then 0.7 else 1)
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		q *= 0.75
	end
	return math.max(q, 0.25)
end

function WeatherFx.reduced(): boolean
	local me = Players.LocalPlayer
	local attr = if me then me:GetAttribute("ReducedMotion") else nil
	if typeof(attr) == "boolean" then
		return attr
	end
	local ok, on = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and on == true
end

type Want = { entry: Registry.Entry, kind: string, target: number, region: Elements.Region? }

-- What should be showing now, and how strongly.
local function wanted(): { [string]: Want }
	local want: { [string]: Want } = {}
	local inside = State.insideKey()
	local gid = State.globalWeather()
	local g = if gid then Registry.get(gid) else nil
	if g then
		want["global:" .. g.id] = { entry = g, kind = "global", target = if inside then GLOBAL_UNDER_LOCAL else 1 }
	end
	for key, l in State.locals() do
		local e = Registry.get(l.id)
		if e then
			local region = { center = l.center, size = l.size }
			local d = Vector3.new(ctx.cam.X - l.center.X, 0, ctx.cam.Z - l.center.Z).Magnitude
			local near = d < math.max(l.size.X, l.size.Z) / 2 + REGION_VIEW
			want["region:" .. key] = { entry = e, kind = "region", target = if near then 1 else 0, region = region }
			if inside == key then
				want["local:" .. key] = { entry = e, kind = "local", target = 1, region = region }
			end
		end
	end
	return want
end

local function updateCtx(dt: number)
	local cam = workspace.CurrentCamera
	local cf = if cam then cam.CFrame else CFrame.identity
	ctx.cam = cf.Position
	local lv = cf.LookVector
	local flat = Vector3.new(lv.X, 0, lv.Z)
	ctx.look = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zAxis
	ctx.yaw = math.atan2(ctx.look.X, ctx.look.Z)
	ctx.t = os.clock()
	ctx.dt = math.min(dt, 0.1)
	if ctx.t >= nextQuality then
		nextQuality = ctx.t + 1
		ctx.q = WeatherFx.quality()
		ctx.reduced = WeatherFx.reduced()
	end
	if ctx.t >= nextGround then
		nextGround = ctx.t + 0.25
		local ignore: { Instance } = { weatherFolder() }
		local char = Players.LocalPlayer and Players.LocalPlayer.Character
		if char then
			table.insert(ignore, char)
		end
		for _, name in { "Chases", "VFX" } do
			local f = workspace:FindFirstChild(name)
			if f then
				table.insert(ignore, f)
			end
		end
		rayParams.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(ctx.cam + Vector3.new(0, 2, 0), Vector3.new(0, -400, 0), rayParams)
		ctx.ground = if hit then hit.Position.Y else ctx.cam.Y - 10
	end
end

local function pulseValue(): number
	if pulse.ev == 0 then
		return 0
	end
	local k = (os.clock() - pulse.t0) / pulse.dur
	if k >= 1 then
		pulse.ev = 0
		return 0
	end
	return pulse.ev * (1 - k) * (1 - k)
end

local function step(dt: number)
	updateCtx(dt)
	local want = wanted()
	for key, w in want do
		local layer = layers[key]
		if not layer and w.target > 0 then
			layer = Layer.new(key, w.entry, w.kind, ctx, w.region)
			layers[key] = layer
		end
		if layer then
			layer.target = w.target
		end
	end
	for key, layer in layers do
		if not want[key] then
			layer.target = 0
		end
	end
	for key, layer in layers do
		if Layer.update(layer, ctx) then
			Layer.destroy(layer)
			layers[key] = nil
		end
	end
	-- Lighting: global layers first (oldest first), then local accents. Only composed while something moves.
	local list: { Layer.Layer } = {}
	for _, layer in layers do
		if layer.kind ~= "region" and next(layer.entry.lighting) then
			table.insert(list, layer)
		end
	end
	table.sort(list, function(a, b)
		if a.kind ~= b.kind then
			return a.kind == "global"
		end
		return a.seq < b.seq
	end)
	local entries: { LightingStack.Entry } = {}
	local changed = false
	local seen: { [string]: boolean } = {}
	for _, layer in list do
		table.insert(entries, { target = layer.entry.lighting, weight = layer.w })
		seen[layer.key] = true
		if lastCompose[layer.key] ~= layer.w then
			changed = true
			lastCompose[layer.key] = layer.w
		end
	end
	for key in lastCompose do
		if not seen[key] then
			lastCompose[key] = nil
			changed = true
		end
	end
	local pv = pulseValue()
	if changed or pv ~= 0 or pulse.ev ~= 0 then
		LightingStack.compose(entries, pv)
	end
	if not next(layers) and not next(State.locals()) and not LightingStack.busy() then
		RunService:UnbindFromRenderStep("WeatherFx")
		bound = false
		table.clear(lastCompose)
	end
end

local function ensureRunning()
	if bound then
		return
	end
	bound = true
	weatherFolder()
	RunService:BindToRenderStep("WeatherFx", Enum.RenderPriority.Camera.Value + 1, step)
end

-- Debug / test snapshot: live layers, weights, element and particle counts, lighting state.
function WeatherFx.debug(): { [string]: any }
	local out = { layers = {}, lighting = LightingStack.busy(), bound = bound, q = ctx.q, reduced = ctx.reduced }
	local emitters, particlesPerSec = 0, 0
	local f = folder
	if f then
		for _, d in f:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				emitters += 1
				particlesPerSec += d.Rate
			end
		end
	end
	for key, l in layers do
		table.insert(
			out.layers,
			{ key = key, w = math.floor(l.w * 1000) / 1000, target = l.target, elements = #l.elements }
		)
	end
	out.emitters = emitters
	out.particlesPerSec = math.floor(particlesPerSec)
	out.parts = if f then #f:GetDescendants() else 0
	return out
end

local started = false
function WeatherFx.start()
	if started or not RunService:IsClient() then
		return
	end
	started = true
	State.subscribe(function()
		ensureRunning()
	end)
	State.listen()
	if State.globalWeather() or next(State.locals()) then
		ensureRunning()
	end
end

return WeatherFx
