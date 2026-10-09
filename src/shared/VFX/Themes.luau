--!strict
-- Partner A. One look per avalanche theme in Config/Chase.Themes.
--   colors      3-colour boulder palette
--   material    boulder material (SmoothPlastic / Glass / ...)
--   neon        fraction of boulders that get a Neon accent colour (cracks, edges, shards)
--   neonColor   accent colour for those boulders, cracks and the light
--   dust        colour of the dust wall at the leading edge
--   extra       optional second emitter (embers, bubbles, powder, wisps, stars...)
--   light       PointLight colour inside the wall (nil = none)
--   flicker     lightning-style light flashes
--   rainbow     boulder colours cycle hue
--   shapes      pooled part kinds for boulders (default blocks + wedges)
local rgb = Color3.fromRGB

export type Extra = {
	texture: string,
	color: Color3,
	size: number,
	rate: number,
	lifetime: number,
	speed: number,
	light: boolean?,
}
export type Theme = {
	colors: { Color3 },
	material: Enum.Material,
	neon: number,
	neonColor: Color3,
	dust: Color3,
	crack: Color3,
	extra: Extra?,
	light: Color3?,
	flicker: boolean?,
	rainbow: boolean?,
	shapes: { string }?,
}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local SM = Enum.Material.SmoothPlastic

local Themes: { [string]: Theme } = {
	Rock = {
		colors = { rgb(130, 125, 120), rgb(105, 90, 75), rgb(160, 150, 135) },
		material = SM,
		neon = 0,
		neonColor = rgb(255, 255, 255),
		dust = rgb(170, 160, 145),
		crack = rgb(70, 60, 50),
	},
	Sand = {
		colors = { rgb(235, 205, 140), rgb(210, 170, 100), rgb(245, 225, 175) },
		material = SM,
		neon = 0,
		neonColor = rgb(255, 255, 255),
		dust = rgb(240, 215, 160),
		crack = rgb(175, 135, 80),
		extra = { texture = SMOKE, color = rgb(250, 225, 170), size = 3, rate = 40, lifetime = 0.8, speed = 30 },
	},
	Snow = {
		shapes = { "Ball", "Ball", "Block" },
		colors = { rgb(250, 252, 255), rgb(215, 235, 250), rgb(190, 215, 240) },
		material = SM,
		neon = 0,
		neonColor = rgb(255, 255, 255),
		dust = rgb(250, 252, 255),
		crack = rgb(170, 200, 230),
		extra = { texture = SMOKE, color = rgb(255, 255, 255), size = 6, rate = 35, lifetime = 1.4, speed = 14 },
	},
	Candy = {
		shapes = { "Ball", "Block", "Wedge" },
		colors = { rgb(255, 160, 205), rgb(150, 230, 230), rgb(255, 240, 150) },
		material = SM,
		neon = 0.1,
		neonColor = rgb(255, 120, 200),
		dust = rgb(255, 210, 235),
		crack = rgb(240, 120, 170),
		extra = { texture = SPARK, color = rgb(255, 255, 255), size = 1.2, rate = 30, lifetime = 1, speed = 18 },
	},
	Coral = {
		shapes = { "Ball", "Block", "Block" },
		colors = { rgb(255, 120, 140), rgb(60, 200, 200), rgb(255, 180, 120) },
		material = SM,
		neon = 0,
		neonColor = rgb(255, 255, 255),
		dust = rgb(170, 230, 240),
		crack = rgb(40, 130, 160),
		extra = { texture = SPARK, color = rgb(200, 245, 255), size = 1.6, rate = 30, lifetime = 1.6, speed = 6 },
	},
	Lava = {
		colors = { rgb(45, 35, 35), rgb(70, 50, 45), rgb(30, 25, 25) },
		material = SM,
		neon = 0.35,
		neonColor = rgb(255, 120, 30),
		dust = rgb(80, 55, 50),
		crack = rgb(255, 110, 20),
		extra = {
			texture = FIRE,
			color = rgb(255, 150, 40),
			size = 1.4,
			rate = 45,
			lifetime = 1.2,
			speed = 16,
			light = true,
		},
		light = rgb(255, 120, 40),
	},
	Crystal = {
		colors = { rgb(120, 230, 255), rgb(170, 140, 255), rgb(200, 250, 255) },
		material = Enum.Material.Glass,
		neon = 0.3,
		neonColor = rgb(90, 240, 255),
		dust = rgb(190, 240, 255),
		crack = rgb(90, 220, 255),
		extra = { texture = SPARK, color = rgb(150, 245, 255), size = 1.5, rate = 35, lifetime = 1, speed = 14 },
		light = rgb(110, 230, 255),
	},
	Neon = {
		colors = { rgb(30, 30, 45), rgb(45, 40, 70), rgb(20, 20, 30) },
		material = SM,
		neon = 0.35,
		neonColor = rgb(255, 40, 200),
		dust = rgb(70, 50, 90),
		crack = rgb(255, 40, 200),
		extra = { texture = SPARK, color = rgb(80, 230, 255), size = 1.2, rate = 30, lifetime = 0.8, speed = 20 },
		light = rgb(255, 40, 200),
	},
	Bone = {
		shapes = { "Cylinder", "Block" },
		colors = { rgb(240, 235, 215), rgb(215, 205, 180), rgb(190, 180, 160) },
		material = SM,
		neon = 0.1,
		neonColor = rgb(140, 255, 120),
		dust = rgb(170, 175, 160),
		crack = rgb(90, 95, 85),
		extra = { texture = SMOKE, color = rgb(140, 255, 120), size = 3, rate = 20, lifetime = 1.6, speed = 6 },
	},
	Cloud = {
		shapes = { "Ball" },
		colors = { rgb(255, 255, 255), rgb(225, 230, 245), rgb(200, 205, 225) },
		material = SM,
		neon = 0,
		neonColor = rgb(255, 255, 210),
		dust = rgb(240, 242, 255),
		crack = rgb(180, 190, 220),
		light = rgb(230, 235, 255),
		flicker = true,
	},
	Sludge = {
		shapes = { "Ball", "Ball", "Block" },
		colors = { rgb(110, 170, 40), rgb(80, 120, 30), rgb(150, 210, 60) },
		material = SM,
		neon = 0.15,
		neonColor = rgb(170, 255, 40),
		dust = rgb(120, 160, 60),
		crack = rgb(150, 230, 40),
		extra = { texture = SPARK, color = rgb(190, 255, 80), size = 1.8, rate = 30, lifetime = 1.2, speed = 8 },
	},
	Scrap = {
		shapes = { "Cylinder", "Block", "Wedge" },
		colors = { rgb(150, 90, 50), rgb(110, 105, 100), rgb(185, 130, 70) },
		material = SM,
		neon = 0.05,
		neonColor = rgb(255, 200, 60),
		dust = rgb(130, 110, 90),
		crack = rgb(80, 60, 45),
		extra = { texture = SPARK, color = rgb(255, 200, 80), size = 0.8, rate = 40, lifetime = 0.6, speed = 26 },
	},
	Void = {
		colors = { rgb(20, 15, 35), rgb(35, 25, 60), rgb(10, 8, 20) },
		material = SM,
		neon = 0.3,
		neonColor = rgb(170, 90, 255),
		dust = rgb(45, 30, 80),
		crack = rgb(170, 90, 255),
		extra = { texture = SPARK, color = rgb(255, 255, 255), size = 1, rate = 40, lifetime = 1.4, speed = 10 },
		light = rgb(160, 90, 255),
	},
	Rainbow = {
		colors = { rgb(255, 120, 120), rgb(120, 200, 255), rgb(255, 230, 120) },
		material = SM,
		neon = 0.2,
		neonColor = rgb(255, 255, 255),
		dust = rgb(255, 235, 250),
		crack = rgb(255, 150, 220),
		extra = { texture = SPARK, color = rgb(255, 255, 255), size = 1.4, rate = 40, lifetime = 1, speed = 16 },
		rainbow = true,
	},
}

local M = {}

M.SMOKE = SMOKE
M.SPARK = SPARK

function M.get(name: string?): Theme
	return Themes[name or "Rock"] or Themes.Rock
end

return M
