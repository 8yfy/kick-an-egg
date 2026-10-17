--!strict
-- Partner A. The ONE writer of weather lighting on this client (Lighting, Atmosphere, map SunRays, terrain Clouds and
-- its own "WeatherGrade" ColorCorrection). Nothing else in the game animates these at runtime: MapBuilder sets the
-- map's look once at build, the avalanche and the UI blur use their own effect instances.
--   * The live values are captured as the baseline the first time a weather touches a property, so the clear state
--     is whatever the map really looks like (never a hard-coded sunny profile).
--   * compose(entries, pulse): baseline -> lerp toward each entry's target by its weight, in order (global weather
--     first, then a local accent), plus an additive exposure pulse (soft lightning). Only called while something
--     moves, so it never fights another script every frame.
--   * When no entry has weight left, every touched property returns to its baseline, the effects this module made
--     are destroyed and the baseline is dropped (the next weather re-captures the then-current look).
local Lighting = game:GetService("Lighting")

local LightingStack = {}

-- Flat target keys (Registry entries use these names) -> where they live.
export type Target = { [string]: any }
export type Entry = { target: Target, weight: number }

type Key = { obj: string, prop: string, neutral: any? }
local KEYS: { [string]: Key } = {
	brightness = { obj = "Lighting", prop = "Brightness" },
	exposure = { obj = "Lighting", prop = "ExposureCompensation" },
	outdoorAmbient = { obj = "Lighting", prop = "OutdoorAmbient" },
	ambient = { obj = "Lighting", prop = "Ambient" },
	colorShiftTop = { obj = "Lighting", prop = "ColorShift_Top" },
	clockTime = { obj = "Lighting", prop = "ClockTime" },
	atmDensity = { obj = "Atmosphere", prop = "Density" },
	atmOffset = { obj = "Atmosphere", prop = "Offset" },
	atmHaze = { obj = "Atmosphere", prop = "Haze" },
	atmGlare = { obj = "Atmosphere", prop = "Glare" },
	atmColor = { obj = "Atmosphere", prop = "Color" },
	atmDecay = { obj = "Atmosphere", prop = "Decay" },
	tint = { obj = "Grade", prop = "TintColor", neutral = Color3.new(1, 1, 1) },
	gradeBrightness = { obj = "Grade", prop = "Brightness", neutral = 0 },
	contrast = { obj = "Grade", prop = "Contrast", neutral = 0 },
	saturation = { obj = "Grade", prop = "Saturation", neutral = 0 },
	sunRays = { obj = "SunRays", prop = "Intensity" },
	cloudCover = { obj = "Clouds", prop = "Cover", neutral = 0 },
	cloudDensity = { obj = "Clouds", prop = "Density", neutral = 0 },
	cloudColor = { obj = "Clouds", prop = "Color", neutral = Color3.new(1, 1, 1) },
}
LightingStack.KEYS = KEYS

local baseline: { [string]: any } = {}
local touched: { [string]: boolean } = {}
local grade: ColorCorrectionEffect? = nil
local clouds: Clouds? = nil
local ownClouds = false

local function object(kind: string, create: boolean): Instance?
	if kind == "Lighting" then
		return Lighting
	elseif kind == "Atmosphere" then
		return Lighting:FindFirstChildOfClass("Atmosphere")
	elseif kind == "SunRays" then
		return Lighting:FindFirstChild("MapSunRays") or Lighting:FindFirstChildOfClass("SunRaysEffect")
	elseif kind == "Grade" then
		local g = grade
		if (not g or not g.Parent) and create then
			local n = Instance.new("ColorCorrectionEffect")
			n.Name = "WeatherGrade"
			n.Parent = Lighting
			g = n
			grade = n
		end
		return if g and g.Parent then g else nil
	elseif kind == "Clouds" then
		local c = clouds
		if not c or not c.Parent then
			c = workspace.Terrain:FindFirstChildOfClass("Clouds")
			ownClouds = false
			if not c and create then
				local n = Instance.new("Clouds")
				n.Name = "WeatherClouds"
				n.Cover = 0
				n.Density = 0
				n.Parent = workspace.Terrain
				c = n
				ownClouds = true
			end
			clouds = c
		end
		return c
	end
	return nil
end

local function read(name: string): any
	local k = KEYS[name]
	local o = object(k.obj, true)
	if k.obj == "Grade" or (k.obj == "Clouds" and ownClouds) then
		return k.neutral -- created by this module: its clear state is neutral
	end
	if not o then
		return nil
	end
	return (o :: any)[k.prop]
end

local function write(name: string, value: any)
	local k = KEYS[name]
	local o = object(k.obj, true)
	if o then
		(o :: any)[k.prop] = value
	end
end

local function lerp(a: any, b: any, t: number): any
	if typeof(a) == "number" then
		return a + (b - a) * t
	end
	return (a :: Color3):Lerp(b, t)
end

-- True while any weather property differs from the baseline (a restore is pending).
function LightingStack.busy(): boolean
	return next(touched) ~= nil
end

-- Blend `entries` (in order) over the baseline; `pulse` = extra exposure (EV) on top.
function LightingStack.compose(entries: { Entry }, pulse: number?)
	local used: { [string]: boolean } = {}
	for _, e in entries do
		if e.weight > 0.0005 then
			for name in e.target do
				if KEYS[name] then
					used[name] = true
				end
			end
		end
	end
	local p = pulse or 0
	if p ~= 0 then
		used.exposure = true
	end
	for name in used do
		if baseline[name] == nil then
			baseline[name] = read(name)
		end
		local v = baseline[name]
		if v ~= nil then
			for _, e in entries do
				local target = e.target[name]
				if target ~= nil and e.weight > 0.0005 then
					v = lerp(v, target, math.clamp(e.weight, 0, 1))
				end
			end
			if name == "exposure" then
				v += p
			end
			write(name, v)
			touched[name] = true
		end
	end
	-- properties no entry uses any more go straight back (their weight already faded to ~0)
	for name in touched do
		if not used[name] then
			if baseline[name] ~= nil then
				write(name, baseline[name])
			end
			touched[name] = nil
		end
	end
	if not next(touched) then
		LightingStack.restore()
	end
end

-- Everything back to the captured baseline; own effects removed.
function LightingStack.restore()
	for name in touched do
		if baseline[name] ~= nil then
			write(name, baseline[name])
		end
	end
	table.clear(touched)
	table.clear(baseline)
	if grade then
		grade:Destroy()
		grade = nil
	end
	if clouds and ownClouds then
		clouds:Destroy()
	end
	clouds = nil
	ownClouds = false
end

return LightingStack
