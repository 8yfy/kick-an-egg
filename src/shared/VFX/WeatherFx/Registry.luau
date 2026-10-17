--!strict
-- Partner A. Weather LOOKS: one entry per weather, keyed by the server's EXACT id (case-sensitive). Presentation only;
-- which weather runs, when, for how long and what it does to rolls is Config/Mutations + WeatherService (untouched).
--   * active = true: a real weather the server can send (Config/Mutations.Weather keys).
--   * active = false: an approved art concept that the game does NOT have. Kept ready (icon, look) for the day the
--     server adds it under this exact id, and previewable in Studio only. Never sent as a real event.
-- Fields: label (HUD / toast text), icon (uploaded image id, nil = no art yet -> visible MISSING ICON marker and a
-- warning, never a borrowed picture), accent (toast / timer colour), scope ("global" | "local"), priority (overlapping
-- local storms: higher wins), fadeIn / fadeOut (seconds; local enter / exit use localFade), lighting (LightingStack
-- target keys), elements (WeatherFx/Elements specs; where = "region" pieces belong to a local storm's area), sounds
-- (WeatherFx/Sound keys: a bed loop; only the rainy weathers have one, user decision 2026-10-17), region (default local
-- storm box for previews).
-- Icons: assets/KickAnEgg_WeatherProduction/UI_Icons (user's NEW package, alpha-only defringe), image ids in
-- Manifest/uploaded_icons.json (the uploads are Decals; these are their Image ids). Mapping decided by the user
-- 2026-10-17 (Manifest/Weather_Mapping_Report.md).
local S = require(script.Parent.Sprites)
local WS = require(script.Parent.Parent.WorldSprites)

local rgb = Color3.fromRGB
local v3 = Vector3.new

export type Entry = {
	id: string,
	label: string,
	active: boolean,
	scope: string,
	priority: number,
	icon: string?,
	iconFile: string?,
	accent: Color3,
	fadeIn: number,
	fadeOut: number,
	localFade: number,
	lighting: { [string]: any },
	elements: { { [string]: any } },
	sounds: { start: string?, bed: string?, accents: { { key: string, every: { number }, near: number } }? },
	region: { size: Vector3 }?,
	note: string?,
}

local Registry = {}

-- Shared recipe pieces -------------------------------------------------------------------------------------------
local FADE_TAIL = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.85, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
local RAINBOW =
	{ rgb(255, 80, 80), rgb(255, 160, 60), rgb(255, 235, 80), rgb(110, 230, 90), rgb(80, 180, 255), rgb(180, 110, 255) }

-- Streak rain. VelocityParallel lays the sprite's X axis along the motion, so the vertical streak sprite is turned 90
-- degrees back (bead leading). rain() is the wide layer, rainNear() a denser one close to the camera.
local function rain(o: { [string]: any }): { [string]: any }
	local orientation = o.orientation or Enum.ParticleOrientation.VelocityParallel
	return {
		kind = "volume",
		where = "camera",
		texture = o.texture or S.raindrop,
		color = o.color or { rgb(205, 225, 255), rgb(170, 200, 245) },
		size = o.size or 1,
		transparency = o.transparency or FADE_TAIL,
		lifetime = o.lifetime or { 0.68, 0.8 },
		speed = o.speed or { 90, 104 },
		rate = o.rate or 340,
		box = v3(150, 2, 150),
		offset = v3(0, 58, 0),
		lead = 25,
		direction = Enum.NormalId.Bottom,
		spread = Vector2.new(2, 2),
		accel = o.wind or Vector3.zero,
		orientation = orientation,
		rotation = o.rotation or (if orientation == Enum.ParticleOrientation.VelocityParallel then 90 else nil),
		rotSpeed = o.rotSpeed,
		lightInfluence = 0.6,
		lightEmission = o.lightEmission or 0.15,
	}
end

local function rainNear(o: { [string]: any }): { [string]: any }
	local r = rain(o)
	r.box = v3(46, 2, 46)
	r.offset = v3(0, 30, 0)
	r.lead = 8
	r.size = (o.size or 1) * 0.8
	r.rate = (o.rate or 340) * 0.6
	r.lifetime = { 0.32, 0.4 }
	return r
end

local function splashes(rate: number, color: Color3?): { { [string]: any } }
	return {
		{
			kind = "volume",
			where = "ground",
			texture = S.splash,
			flipbook = true,
			color = color or rgb(225, 238, 255),
			size = { 0.9, 1.5 },
			transparency = { 0.25, 0.35, 1 },
			lifetime = { 0.26, 0.32 },
			rate = rate,
			box = v3(90, 0.2, 90),
			offset = v3(0, 0.7, 0),
			lead = 15,
			lightInfluence = 0.7,
		},
		{
			kind = "volume",
			where = "ground",
			texture = WS.ring,
			color = color or rgb(225, 238, 255),
			size = { 0.3, 2.4 },
			transparency = { 0.35, 1 },
			lifetime = { 0.55, 0.7 },
			speed = 0.01,
			direction = Enum.NormalId.Top,
			orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			rate = rate * 0.35,
			box = v3(80, 0.2, 80),
			offset = v3(0, 0.25, 0),
			lead = 15,
			lightInfluence = 0.8,
		},
	}
end

local function overcast(color: Color3, rate: number, t: number): { [string]: any }
	return {
		kind = "volume",
		where = "camera",
		texture = S.billow,
		color = color,
		size = 80,
		transparency = { 1, t, t, 1 },
		lifetime = { 9, 13 },
		speed = { 0.5, 1.2 },
		direction = Enum.NormalId.Right,
		spread = Vector2.new(180, 10),
		rotation = { -8, 8 },
		rate = rate,
		box = v3(520, 24, 520),
		offset = v3(0, 120, 0),
		lightInfluence = 1,
	}
end

local function groundSparkle(texture: string, color: any, rate: number): { [string]: any }
	return {
		kind = "volume",
		where = "ground",
		texture = texture,
		color = color,
		size = { 0, 1.5, 0 },
		lifetime = { 0.45, 0.7 },
		rate = rate,
		box = v3(70, 0.5, 70),
		offset = v3(0, 0.9, 0),
		lead = 12,
		lightEmission = 1,
	}
end

local function motes(texture: string, color: any, rate: number, size: number?): { [string]: any }
	return {
		kind = "volume",
		where = "camera",
		texture = texture,
		color = color,
		size = { 0, size or 0.55, 0 },
		lifetime = { 2.5, 4 },
		speed = { 0.4, 1.4 },
		direction = Enum.NormalId.Top,
		spread = Vector2.new(180, 180),
		accel = v3(0, 0.3, 0),
		rotSpeed = { -60, 60 },
		rate = rate,
		box = v3(70, 26, 70),
		offset = v3(0, 6, 0),
		lead = 10,
		lightEmission = 1,
	}
end

local function skyTwinkles(colors: any, rate: number): { [string]: any }
	return {
		kind = "volume",
		where = "camera",
		texture = S.twinkle,
		color = colors,
		size = { 0, 3.4, 0 },
		lifetime = { 1.5, 3 },
		rate = rate,
		box = v3(700, 60, 700),
		offset = v3(0, 100, 0),
		lead = 200,
		lightEmission = 1,
	}
end

-- Entries ----------------------------------------------------------------------------------------------------------
local E: { [string]: Entry } = {}

local function add(e: any) -- (any: element specs are deliberately heterogeneous tables)
	e.fadeIn = e.fadeIn or 4.5
	e.fadeOut = e.fadeOut or 4.5
	e.localFade = e.localFade or 2
	e.priority = e.priority or 1
	e.sounds = e.sounds or {}
	E[e.id] = e :: any
end

-- REAL weathers (Config/Mutations.Weather) -------------------------------------------------------------------------

-- Sunny (31.6 % of events): a warm golden hour. Voxel sun with turning rays, soft god rays, drifting glitter.
add({
	id = "Sunny",
	label = "SUNNY",
	active = true,
	scope = "global",
	icon = nil, -- no sun icon supplied yet (user decision): MISSING ICON marker until one exists
	accent = rgb(255, 214, 90),
	fadeIn = 5,
	fadeOut = 5,
	lighting = {
		brightness = 3.0,
		exposure = 0.08,
		outdoorAmbient = rgb(165, 150, 128),
		colorShiftTop = rgb(70, 45, 10),
		tint = rgb(255, 243, 222),
		saturation = 0.12,
		contrast = 0.04,
		sunRays = 0.18,
		atmColor = rgb(255, 236, 205),
		atmDecay = rgb(255, 190, 130),
		atmGlare = 0.9,
		atmHaze = 1.6,
	},
	elements = {
		{ kind = "sky", prop = "sun", heading = 25, distance = 330, altitude = 78, billboard = true, scale = 1.1 },
		{
			kind = "shafts",
			texture = S.ray,
			count = 4,
			color = rgb(255, 214, 120),
			transparency = 0.66,
			width = { 20, 34 },
			length = 160,
			radius = { 35, 80 },
			heading = 25,
			elevation = 58,
			spreadDeg = 34,
		},
		motes(S.glitter, { rgb(255, 240, 170), rgb(255, 200, 80) }, 14),
		groundSparkle(S.twinkle, rgb(255, 226, 120), 7),
	},
})

-- Rainy (31.6 %): grey studded cloud ring, soft overcast, streak rain, splash crowns and ripples.
add({
	id = "Rainy",
	label = "RAINY",
	active = true,
	scope = "global",
	icon = nil, -- no plain rain icon supplied yet (user decision): MISSING ICON marker until one exists
	accent = rgb(140, 200, 255),
	lighting = {
		brightness = 1.75,
		exposure = -0.12,
		outdoorAmbient = rgb(118, 126, 145),
		tint = rgb(222, 230, 245),
		saturation = -0.18,
		contrast = 0.02,
		sunRays = 0.01,
		atmDensity = 0.42,
		atmHaze = 2.4,
		atmGlare = 0,
		atmColor = rgb(190, 200, 215),
		atmDecay = rgb(108, 118, 140),
		cloudCover = 0.8,
		cloudDensity = 0.55,
		cloudColor = rgb(205, 210, 222),
	},
	elements = {
		{
			kind = "sky",
			prop = "clouds",
			count = 9,
			radius = { 150, 250 },
			altitude = 62,
			top = rgb(214, 220, 232),
			bottom = rgb(150, 160, 182),
			scale = 1.1,
		},
		overcast(rgb(185, 192, 208), 3.5, 0.5),
		rain({ rate = 340 }),
		rainNear({ rate = 340 }),
		splashes(80)[1],
		splashes(80)[2],
	},
	sounds = { bed = "Rain_Light" }, -- WeatherFx/Sound: steady rain loop (user decision: only rainy weathers sound)
})

-- Snowy (21.1 %), the Frozen Aurora look: voxel snowflakes, aurora curtains both ways, icy glints, cold haze.
add({
	id = "Snowy",
	label = "SNOWY",
	active = true,
	scope = "global",
	icon = "rbxassetid://119621994750343", -- Frozen_Aurora.png
	iconFile = "Frozen_Aurora.png",
	accent = rgb(170, 230, 255),
	fadeIn = 5.5,
	fadeOut = 5,
	lighting = {
		brightness = 2.25,
		exposure = 0.02,
		outdoorAmbient = rgb(150, 168, 195),
		colorShiftTop = rgb(0, 15, 35),
		tint = rgb(232, 243, 255),
		saturation = -0.04,
		atmDensity = 0.36,
		atmHaze = 2.0,
		atmColor = rgb(212, 230, 255),
		atmDecay = rgb(150, 182, 232),
		atmGlare = 0.2,
		sunRays = 0.05,
		cloudCover = 0.62,
		cloudDensity = 0.4,
		cloudColor = rgb(236, 242, 252),
	},
	elements = {
		{ kind = "sky", prop = "aurora", heading = 0, distance = 270, altitude = 78, count = 3, height = 70 },
		{ kind = "sky", prop = "aurora", heading = 180, distance = 280, altitude = 86, count = 2, height = 60 },
		{
			kind = "sky",
			prop = "clouds",
			count = 7,
			radius = { 180, 280 },
			altitude = 78,
			top = rgb(246, 249, 255),
			bottom = rgb(196, 210, 230),
		},
		{
			kind = "volume",
			where = "camera",
			texture = S.voxelflake,
			color = { rgb(255, 255, 255), rgb(215, 238, 255) },
			size = 0.75,
			transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.08, 0.05),
				NumberSequenceKeypoint.new(0.85, 0.05),
				NumberSequenceKeypoint.new(1, 1),
			}),
			lifetime = { 6, 8 },
			speed = { 6, 9 },
			direction = Enum.NormalId.Bottom,
			spread = Vector2.new(20, 20),
			accel = v3(1.8, 0, 0.6),
			drag = 0.25,
			rotation = { 0, 360 },
			rotSpeed = { -50, 50 },
			rate = 120,
			box = v3(160, 2, 160),
			offset = v3(0, 42, 0),
			lead = 20,
			lightEmission = 0.3,
			lightInfluence = 0.5,
		},
		{
			kind = "volume",
			where = "camera",
			texture = WS.snowflake,
			color = rgb(240, 248, 255),
			size = 0.35,
			transparency = { 1, 0.1, 0.1, 1 },
			lifetime = { 3, 4 },
			speed = { 2, 4 },
			direction = Enum.NormalId.Bottom,
			spread = Vector2.new(180, 180),
			accel = v3(3, -1, 0),
			rotSpeed = { -90, 90 },
			rate = 26,
			box = v3(40, 24, 40),
			offset = v3(0, 6, 0),
			lead = 6,
			lightEmission = 0.4,
		},
		groundSparkle(S.twinkle, rgb(190, 240, 255), 8),
		{
			kind = "volume",
			where = "ground",
			texture = WS.mist,
			color = rgb(230, 240, 255),
			size = 26,
			transparency = { 1, 0.8, 0.8, 1 },
			lifetime = { 7, 9 },
			speed = { 1, 2 },
			direction = Enum.NormalId.Right,
			spread = Vector2.new(180, 0),
			rate = 3,
			box = v3(120, 4, 120),
			offset = v3(0, 3, 0),
			lightInfluence = 1,
		},
	},
})

-- Stormy (10.5 %), the Thunderstorm: dark cloud ring, heavy slanted rain, distant brick lightning with a soft
-- exposure lift (no full-screen strobe) and thunder that arrives with a distance delay. The ONLY weather with thunder.
add({
	id = "Stormy",
	label = "STORMY",
	active = true,
	scope = "global",
	icon = "rbxassetid://135869585822825", -- Thunderstorm.png
	iconFile = "Thunderstorm.png",
	accent = rgb(130, 200, 255),
	fadeIn = 5,
	fadeOut = 5,
	lighting = {
		brightness = 1.35,
		exposure = -0.28,
		outdoorAmbient = rgb(96, 102, 132),
		tint = rgb(200, 210, 240),
		saturation = -0.25,
		contrast = 0.08,
		sunRays = 0,
		atmDensity = 0.5,
		atmHaze = 3.0,
		atmGlare = 0,
		atmColor = rgb(140, 150, 185),
		atmDecay = rgb(70, 76, 110),
		cloudCover = 0.92,
		cloudDensity = 0.8,
		cloudColor = rgb(110, 116, 142),
	},
	elements = {
		{
			kind = "sky",
			prop = "clouds",
			count = 11,
			radius = { 140, 240 },
			altitude = 58,
			top = rgb(120, 128, 155),
			bottom = rgb(70, 76, 100),
			scale = 1.25,
		},
		overcast(rgb(105, 112, 135), 4.8, 0.4),
		rain({ rate = 480, speed = { 100, 115 }, wind = v3(14, 0, 4), size = 1.15 }),
		rainNear({ rate = 480, speed = { 100, 115 }, wind = v3(14, 0, 4), size = 1.15 }),
		splashes(120)[1],
		splashes(120)[2],
		{
			kind = "bolts",
			interval = { 4, 9 },
			distance = { 220, 360 },
			cone = 60,
			height = 150,
			color = rgb(205, 228, 255),
			width = 2.4,
			exposure = 0.16,
			light = 5,
			thunder = { "Thunder_Far" }, -- WeatherFx/Sound: distant thunder, arrives after the flash
		},
	},
	sounds = { bed = "Rain_Storm" }, -- WeatherFx/Sound: heavy rain loop (user decision: only rainy weathers sound)
})

-- Starfall (4.2 %), the Meteor Shower look on Starfall's purple: a dusky sky, Trail comets with far bursts, slanted
-- meteor streaks, twinkling stars and violet stardust. Silent (user decision).
add({
	id = "Starfall",
	label = "STARFALL",
	active = true,
	scope = "global",
	icon = "rbxassetid://77179766552714", -- Meteor_Shower.png
	iconFile = "Meteor_Shower.png",
	accent = rgb(255, 150, 90),
	fadeIn = 6,
	fadeOut = 5.5,
	lighting = {
		clockTime = 17.85, -- dusk: a violet evening sky so the meteors pop
		brightness = 1.9,
		exposure = -0.05,
		outdoorAmbient = rgb(128, 108, 160),
		colorShiftTop = rgb(90, 30, 90),
		tint = rgb(232, 214, 255),
		saturation = 0.12,
		contrast = 0.05,
		atmColor = rgb(190, 140, 235),
		atmDecay = rgb(110, 60, 190),
		atmHaze = 1.9,
		atmGlare = 0.8,
		sunRays = 0.12,
	},
	elements = {
		{
			kind = "comets",
			interval = { 0.7, 1.8 },
			distance = { 230, 380 },
			cone = 55,
			height = { 55, 115 },
			size = 2.6,
			headColor = rgb(255, 214, 140),
			trail = { rgb(255, 240, 190), rgb(255, 140, 60), rgb(255, 80, 170), rgb(160, 90, 255) },
			burst = S.glitter,
			trailLife = 0.6,
		},
		{
			kind = "volume",
			where = "camera",
			texture = S.comet,
			color = { rgb(255, 230, 170), rgb(255, 120, 60), rgb(200, 90, 255) },
			orientation = Enum.ParticleOrientation.VelocityParallel,
			rotation = 90,
			size = 6,
			transparency = { 0, 0, 0, 1 },
			lifetime = { 2.2, 2.8 },
			speed = { 130, 160 },
			direction = Enum.NormalId.Bottom,
			spread = Vector2.new(8, 8),
			tilt = v3(0, 0, 32),
			rate = 5,
			box = v3(700, 10, 700),
			offset = v3(0, 135, 0),
			lead = 260,
			lightEmission = 1,
		},
		skyTwinkles({ rgb(255, 255, 255), rgb(220, 200, 255) }, 30),
		motes(S.mote, { rgb(220, 180, 255), rgb(160, 110, 255) }, 14, 0.5),
	},
})

-- Rainbow (1.05 %, the rarest), the Rainbow Storm look: two voxel rainbows (ahead and behind), prism rain that shifts
-- colour as it falls, floating prism shards and rainbow ground sparkles. Bright, never blinding. Silent (user decision).
add({
	id = "Rainbow",
	label = "RAINBOW",
	active = true,
	scope = "global",
	icon = "rbxassetid://97917982557914", -- Rainbow_Storm.png
	iconFile = "Rainbow_Storm.png",
	accent = rgb(255, 140, 220),
	fadeIn = 6,
	fadeOut = 6,
	lighting = {
		brightness = 2.85,
		exposure = 0.06,
		outdoorAmbient = rgb(160, 145, 175),
		colorShiftTop = rgb(50, 25, 60),
		tint = rgb(255, 246, 255),
		saturation = 0.3,
		contrast = 0.04,
		sunRays = 0.14,
		atmColor = rgb(255, 225, 245),
		atmDecay = rgb(195, 170, 255),
		atmGlare = 1.0,
		atmHaze = 1.3,
	},
	elements = {
		{ kind = "sky", prop = "rainbow", heading = 0, distance = 330, altitude = -25, radius = 150, billboard = true },
		{
			kind = "sky",
			prop = "rainbow",
			heading = 180,
			distance = 300,
			altitude = -25,
			radius = 110,
			band = 7,
			blockLen = 12,
			billboard = true,
		},
		rain({
			rate = 170,
			speed = { 75, 88 },
			color = RAINBOW,
			size = 0.95,
			lightEmission = 0.6,
			lifetime = { 0.75, 0.9 },
		}),
		rainNear({ rate = 170, speed = { 75, 88 }, color = RAINBOW, size = 0.95, lightEmission = 0.6 }),
		{
			kind = "volume",
			where = "camera",
			texture = S.prism,
			color = rgb(255, 255, 255),
			size = { 0, 0.9, 0 },
			lifetime = { 3, 5 },
			speed = { 0.5, 1.5 },
			direction = Enum.NormalId.Top,
			spread = Vector2.new(180, 180),
			rotation = { 0, 360 },
			rotSpeed = { -90, 90 },
			rate = 12,
			box = v3(70, 28, 70),
			offset = v3(0, 7, 0),
			lead = 10,
			lightEmission = 0.4,
			lightInfluence = 0.3,
		},
		groundSparkle(S.glitter, RAINBOW, 10),
	},
})

-- INACTIVE concepts (not in the game; previews only) ------------------------------------------------------------------
-- When the server adds one, rename its key and `id` to the server's exact id and set active = true.

add({
	id = "GoldenRain",
	label = "GOLDEN RAIN",
	active = false,
	scope = "global",
	icon = "rbxassetid://106634932546598", -- Golden_Rain.png
	iconFile = "Golden_Rain.png",
	accent = rgb(255, 205, 70),
	note = "concept: not a Config/Mutations weather",
	lighting = {
		brightness = 2.8,
		outdoorAmbient = rgb(170, 150, 110),
		tint = rgb(255, 240, 205),
		saturation = 0.14,
		atmColor = rgb(255, 230, 180),
		atmDecay = rgb(230, 170, 80),
		sunRays = 0.15,
	},
	elements = {
		{
			kind = "sky",
			prop = "clouds",
			count = 8,
			radius = { 160, 250 },
			altitude = 66,
			top = rgb(255, 222, 110),
			bottom = rgb(225, 165, 50),
		},
		rain({
			texture = S.goldrop,
			color = { rgb(255, 225, 110), rgb(255, 180, 40) },
			size = 0.75,
			speed = { 55, 65 },
			rate = 110,
			lifetime = { 1.1, 1.3 },
			orientation = Enum.ParticleOrientation.FacingCamera,
			rotation = { -15, 15 },
			lightEmission = 0.5,
		}),
		groundSparkle(S.glitter, rgb(255, 215, 90), 12),
	},
})

add({
	id = "VoidEclipse",
	label = "VOID ECLIPSE",
	active = false,
	scope = "global",
	icon = "rbxassetid://125430568731489", -- Void_Eclipse.png
	iconFile = "Void_Eclipse.png",
	accent = rgb(190, 120, 255),
	fadeIn = 7,
	note = "concept: not a Config/Mutations weather",
	lighting = {
		brightness = 1.3,
		exposure = -0.25,
		outdoorAmbient = rgb(110, 95, 160),
		tint = rgb(205, 190, 255),
		saturation = -0.08,
		atmColor = rgb(150, 120, 210),
		atmDecay = rgb(80, 50, 150),
		atmHaze = 2.2,
		sunRays = 0,
	},
	elements = {
		{ kind = "sky", prop = "eclipse", heading = 15, distance = 300, altitude = 160, billboard = true },
		skyTwinkles({ rgb(230, 210, 255), rgb(170, 120, 255) }, 22),
		motes(S.mote, { rgb(200, 150, 255), rgb(120, 70, 220) }, 12, 0.5),
		{
			kind = "volume",
			where = "camera",
			texture = S.shard,
			color = { rgb(150, 90, 230), rgb(80, 40, 150) },
			size = { 0, 1.1, 0 },
			lifetime = { 4, 6 },
			speed = { 0.5, 1.5 },
			spread = Vector2.new(180, 180),
			rotation = { 0, 360 },
			rotSpeed = { -30, 30 },
			rate = 6,
			box = v3(80, 30, 80),
			offset = v3(0, 8, 0),
			lightEmission = 0.3,
		},
	},
})

add({
	id = "DivineAscension",
	label = "DIVINE ASCENSION",
	active = false,
	scope = "global",
	icon = "rbxassetid://105976103999037", -- Divine_Ascension.png
	iconFile = "Divine_Ascension.png",
	accent = rgb(255, 230, 150),
	note = "concept: not a Config/Mutations weather",
	lighting = {
		brightness = 2.9,
		exposure = 0.12,
		tint = rgb(255, 248, 232),
		sunRays = 0.22,
		atmColor = rgb(255, 244, 225),
		atmGlare = 1.1,
		saturation = 0.05,
	},
	elements = {
		{ kind = "sky", prop = "halo", heading = 20, distance = 260, altitude = 150, billboard = true },
		{
			kind = "shafts",
			texture = S.ray,
			count = 5,
			color = rgb(255, 245, 210),
			transparency = 0.78,
			width = { 16, 28 },
			length = 170,
			radius = { 30, 75 },
			heading = 20,
			elevation = 62,
			spreadDeg = 30,
		},
		{
			kind = "volume",
			where = "camera",
			texture = S.feather,
			color = { rgb(255, 255, 255), rgb(255, 236, 170) },
			size = 1.1,
			transparency = { 1, 0.1, 0.1, 1 },
			lifetime = { 6, 8 },
			speed = { 3, 5 },
			direction = Enum.NormalId.Bottom,
			spread = Vector2.new(25, 25),
			accel = v3(1.2, 0, 0),
			rotation = { -30, 30 },
			rotSpeed = { -25, 25 },
			rate = 14,
			box = v3(110, 2, 110),
			offset = v3(0, 32, 0),
			lead = 15,
			lightEmission = 0.6,
		},
		skyTwinkles({ rgb(255, 250, 220), rgb(255, 225, 140) }, 18),
	},
})

add({
	id = "VoidRift",
	label = "VOID RIFT",
	active = false,
	scope = "local",
	priority = 3,
	icon = "rbxassetid://71616011979445", -- Void_Rift.png
	iconFile = "Void_Rift.png",
	accent = rgb(190, 120, 255),
	note = "local concept: the game has no local storms",
	region = { size = v3(80, 60, 90) },
	lighting = {
		tint = rgb(222, 205, 255),
		outdoorAmbient = rgb(130, 112, 182),
		saturation = -0.05,
		atmColor = rgb(170, 140, 230),
		exposure = -0.1,
	},
	elements = {
		{ kind = "sky", where = "region", prop = "portal", radius = 9, offset = v3(0, -30, 0) },
		{
			kind = "volume",
			where = "region",
			texture = S.shard,
			color = { rgb(170, 110, 255), rgb(80, 40, 160) },
			size = { 0, 1.3, 0 },
			lifetime = { 4, 6 },
			speed = { 1, 2.5 },
			direction = Enum.NormalId.Top,
			spread = Vector2.new(180, 180),
			rotation = { 0, 360 },
			rotSpeed = { -45, 45 },
			rate = 16,
			lightEmission = 0.5,
		},
		{
			kind = "volume",
			where = "region",
			texture = S.mote,
			color = { rgb(210, 160, 255), rgb(140, 80, 255) },
			size = { 0, 0.6, 0 },
			lifetime = { 2, 3.5 },
			speed = { 0.5, 1.5 },
			spread = Vector2.new(180, 180),
			rate = 24,
			lightEmission = 1,
		},
		motes(S.mote, { rgb(210, 160, 255), rgb(140, 80, 255) }, 10, 0.5),
	},
})

add({
	id = "ThunderSurge",
	label = "THUNDER SURGE",
	active = false,
	scope = "local",
	priority = 2,
	icon = "rbxassetid://79107841943237", -- Thunder_Surge.png
	iconFile = "Thunder_Surge.png",
	accent = rgb(120, 220, 255),
	note = "local concept: the game has no local storms",
	region = { size = v3(80, 60, 90) },
	lighting = { tint = rgb(215, 235, 255), exposure = -0.08, outdoorAmbient = rgb(110, 130, 170), saturation = -0.06 },
	elements = {
		{ kind = "sky", where = "region", prop = "pylons", radius = 18, offset = v3(0, -30, 0) },
		{
			kind = "volume",
			where = "region",
			texture = S.twinkle,
			color = rgb(150, 230, 255),
			size = { 0, 1.2, 0 },
			lifetime = { 0.25, 0.45 },
			rate = 22,
			lightEmission = 1,
		},
		motes(S.mote, { rgb(170, 240, 255), rgb(90, 170, 255) }, 14, 0.45),
	},
})

add({
	id = "ToxicBloom",
	label = "TOXIC BLOOM",
	active = false,
	scope = "local",
	priority = 1,
	icon = "rbxassetid://108840165394834", -- Toxic_Bloom.png
	iconFile = "Toxic_Bloom.png",
	accent = rgb(170, 255, 90),
	note = "local concept: the game has no local storms",
	region = { size = v3(80, 60, 90) },
	lighting = {
		tint = rgb(228, 255, 222),
		outdoorAmbient = rgb(122, 150, 112),
		atmColor = rgb(190, 230, 170),
		saturation = 0.04,
	},
	elements = {
		{ kind = "sky", where = "region", prop = "blooms", spread = 28, count = 6, offset = v3(0, -30, 0) },
		{
			kind = "volume",
			where = "region",
			texture = S.toxicspore,
			color = { rgb(200, 255, 100), rgb(90, 220, 120) },
			size = { 0.3, 1.1 },
			transparency = { 1, 0.2, 1 },
			lifetime = { 4, 6 },
			speed = { 1, 2 },
			direction = Enum.NormalId.Top,
			spread = Vector2.new(40, 40),
			rate = 18,
			lightEmission = 0.8,
		},
		{
			kind = "volume",
			where = "region",
			texture = WS.mist,
			color = rgb(170, 230, 130),
			size = 24,
			transparency = { 1, 0.85, 0.85, 1 },
			lifetime = { 6, 8 },
			speed = { 0.5, 1 },
			spread = Vector2.new(180, 0),
			rate = 4,
			lightInfluence = 1,
		},
		motes(S.toxicspore, { rgb(200, 255, 100), rgb(90, 220, 120) }, 10, 0.6),
	},
})

-- API ----------------------------------------------------------------------------------------------------------------
Registry.entries = E

function Registry.get(id: string): Entry?
	return E[id]
end

-- Real weathers first (by id), then the inactive concepts.
function Registry.list(): { Entry }
	local out = {}
	for _, e in E do
		table.insert(out, e)
	end
	table.sort(out, function(a, b)
		if a.active ~= b.active then
			return a.active
		end
		return a.id < b.id
	end)
	return out
end

return Registry
