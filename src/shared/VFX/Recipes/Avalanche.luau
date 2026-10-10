--!strict
-- Partner A. Avalanche "Epic Doom Wall" (approved mood B, strong screen effects, owner only).
-- Pure data: tune numbers here, not code. Played by VFX/Avalanche (wall + beats) and VFX/Player (one-shots).
-- Colour tokens resolve per theme: $c1 $c2 $c3 (boulders), $neon (glow), $dust, $crack, $light.
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local rgb = Color3.fromRGB

return {
	-- The rolling wall
	wall = {
		width = 78, -- wall to wall: canyon floor is 2 * MapBuilder INNER (80) (gameplay unaffected)
		boulders = 56, -- owner count (~100 parts total with seams, debris, cracks, pebbles, core)
		seams = 14, -- glowing crack seams riding on boulders (doom look)
		debris = 10,
		cracks = 8,
		heightScale = 1.7, -- visual height vs Config/Chase.Avalanche.height (gameplay unaffected)
		size = { 4, 9 }, -- boulder edge length
		darken = 0.18, -- boulder colours pushed toward black
		minNeon = 0.12, -- every theme gets at least this share of glowing boulders
		emerge = 0.6, -- seconds to burst out of the ground
		crackEvery = 5,
		-- dust contrasts with the boulders: dark themes (luminance < darkBelow) lerp toward ash by `lift`
		dust = {
			rate = 60,
			size = { 6, 15 },
			life = 1.6,
			speed = 12,
			darken = 0.25,
			darkBelow = 0.35,
			ash = rgb(205, 190, 180),
			lift = 0.55,
		},
		-- Emitters riding the front (particle budget: dust + these + theme extra stay under ~300 alive)
		scrape = { rate = 34, size = { 2.4, 0 }, life = 0.7, speed = 22, dustRate = 10, dustSize = { 5, 13 } }, -- grinding the canyon walls
		skirt = { rate = 40, size = { 3, 10 }, life = 0.7, speed = 20 }, -- dust thrown out ahead at ground level
		crest = { rate = 26, size = { 2.2, 0 }, life = 0.9, speed = 26 }, -- glowing sparks off the top
		-- Rocks shaken loose from the canyon walls ahead of the front
		pebbles = { count = 10, size = { 0.8, 2.2 }, ahead = { 8, 45 }, height = { 26, 46 } },
		light = { range = 56, brightness = 3 },
		shake = { far = 120, near = 10, max = 0.8 }, -- by distance to the front
		tint = { color = rgb(255, 215, 200), contrast = 0.12, saturation = 0.1, fade = 0.6 }, -- sky tint while it rolls
		defaultGlow = rgb(255, 110, 30), -- glow for themes without their own Neon colour
		glowDarken = 0.35, -- Neon blooms toward yellow-white; a deeper colour keeps it orange
		glowScale = 0.45, -- glowing boulders are smaller embers inside the dark wall
	},

	-- 0 .. warnSeconds: the ground rumbles
	warn = {
		geysers = 6,
		geyserRate = { 10, 40 },
		chunks = 10,
		shakeMax = 0.6,
		vignette = rgb(255, 30, 30),
		banner = { text = "RUN!", top = rgb(255, 240, 90), bottom = rgb(255, 50, 30) },
		crackGlow = true,
	},

	-- The wall bursts out of the ground (played at the front when it appears)
	burst = {
		{ kind = "flash", at = 0, size = { 4, 28 }, seconds = 0.14, color = rgb(255, 236, 200), light = 4 },
		{ kind = "ring", at = 0, radius = { 4, 54 }, seconds = 0.45, color = "$neon", thickness = 2.2, segments = 26 },
		{
			kind = "particles",
			at = 0,
			count = 60,
			texture = SMOKE,
			color = { "$dust" },
			size = { { 0, 5 }, { 1, 16 } },
			transparency = { { 0, 0.2 }, { 0.6, 0.5 }, { 1, 1 } },
			life = { 0.9, 1.4 },
			speed = { 14, 26 },
			spread = 70,
			accel = Vector3.new(0, 4, 0),
			area = Vector3.new(76, 1, 4),
		},
		{
			kind = "particles",
			at = 40,
			count = 40,
			texture = SPARK,
			color = { "$neon", rgb(255, 255, 255) },
			size = { { 0, 1.2 }, { 1, 0 } },
			life = { 0.5, 0.9 },
			speed = { 30, 50 },
			spread = 60,
			light = 1,
			area = Vector3.new(70, 1, 4),
		},
		{ kind = "debris", at = 0, count = 20, size = { 0.8, 2.4 }, power = 50, seconds = 1.4 },
		{ kind = "light", at = 0, color = "$neon", range = 44, brightness = 3.5, seconds = 0.8 },
		{ kind = "shake", at = 0, amount = 0.9, seconds = 0.45 },
		{ kind = "fov", at = 0, kick = 8, seconds = 0.4 },
	},

	-- Front within this many studs of the owner: close-call screen treatment
	closeCall = { distance = 22, vignette = rgb(255, 20, 40), speedLines = true },

	-- The wall slams into the safe line (played at the line)
	slam = {
		{ kind = "flash", at = 0, size = { 6, 32 }, seconds = 0.16, color = rgb(220, 240, 255), light = 5 },
		{ kind = "wall", at = 0, width = 84, height = 26, seconds = 0.7, color = rgb(60, 190, 255) },
		{
			kind = "ring",
			at = 30,
			radius = { 6, 52 },
			seconds = 0.5,
			color = rgb(120, 220, 255),
			thickness = 2.4,
			segments = 28,
		},
		{
			kind = "particles",
			at = 0,
			count = 70,
			texture = SMOKE,
			color = { "$dust" },
			size = { { 0, 6 }, { 1, 18 } },
			transparency = { { 0, 0.15 }, { 0.6, 0.5 }, { 1, 1 } },
			life = { 1, 1.6 },
			speed = { 16, 30 },
			spread = 80,
			accel = Vector3.new(0, 5, 0),
			area = Vector3.new(78, 2, 4),
		},
		{
			kind = "particles",
			at = 50,
			count = 40,
			texture = SPARK,
			color = { rgb(150, 230, 255), rgb(255, 255, 255) },
			size = { { 0, 1.4 }, { 1, 0 } },
			life = { 0.5, 1 },
			speed = { 24, 44 },
			light = 1,
			area = Vector3.new(78, 2, 4),
		},
		{ kind = "debris", at = 0, count = 16, size = { 0.8, 2.2 }, power = 40, seconds = 1.4 },
		{ kind = "shake", at = 0, amount = 1, seconds = 0.55 },
		{ kind = "fov", at = 0, kick = 10, seconds = 0.45 },
	},

	-- Lingering embers in the crumble
	crumble = {
		seconds = 1.2,
		embers = {
			kind = "particles",
			count = 30,
			texture = FIRE,
			color = { "$neon", rgb(255, 230, 150) },
			size = { { 0, 0.8 }, { 1, 0 } },
			life = { 1, 1.6 },
			speed = { 3, 8 },
			spread = 60,
			accel = Vector3.new(0, 4, 0),
			light = 1,
			area = Vector3.new(74, 4, 8),
		},
	},
}
