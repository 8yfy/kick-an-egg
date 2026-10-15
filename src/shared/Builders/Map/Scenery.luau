--!strict
-- Zone scenery (map overhaul 2026-10-14), added around each runway zone by MapBuilder.buildZone. Everything here is
-- decoration OUTSIDE the running lane (|x| <= Chase.RunwayWidth / 2 stays clear) and never tagged as a landing
-- surface:
--   * Ledges: themed strata on both canyon walls (2-3 broken rows), with the zone's edge treatment on the rim lip
--     (snow lumps, frosting, neon strips, lava cracks, crystals, grass...).
--   * Backdrop: two large, simple background silhouettes per side beyond the rim plateaus (rolling hills, dunes,
--     forest, giant mushrooms, peaks, candy hills, coral spires, volcanoes, crystal spires, jungle, skyline, dead
--     trees, floating islands, swamp, factory chimneys, forge spires, asteroids, cloud towers), slightly faded toward
--     the sky for depth, so every zone reads from the air and from the chase camera.
--   * Blend: the last ~10 studs of a zone's shoulders carry two props of the next zone (and its first ~10 studs two of
--     the previous one), so palettes hand over instead of switching at a hard line. Logical zone bounds don't move.
--   * Motion: a few models spin slowly through MapLifeController (attribute Spin, LOD by distance): factory gears,
--     a meadow windmill, drifting sky islands, an orbiting moon. Smoke / embers / bubbles use MapFx presets.
-- Deterministic per zone (Random seeded by the zone id).
local Bricks = require(script.Parent.Bricks)
local MapFx = require(script.Parent.MapFx)
local Props = require(script.Parent.Props)

local Scenery = {}

local rgb = Color3.fromRGB
local NEON = Enum.Material.Neon
local SKY = rgb(200, 225, 255)
local P = Bricks.part

export type Ctx = {
	inner: number, -- canyon floor half-width (the canyon walls' inner faces)
	half: number, -- lane half-width
	wallT: number,
	wallH: number,
	rimW: number,
	rimTop: number,
	landmarkSide: number, -- +1 / -1: the rim the zone's landmark stands on
	stamp: (spec: any, cf: CFrame, scale: number, parent: Instance) -> Model,
}

type Theme = {
	wall: Color3, -- the canyon walls' face colour (replaces the old dirt blend)
	strata: { Color3 }, -- canyon-wall ledge colours, bottom row first
	edge: string, -- rim lip treatment
	edgeColor: Color3,
	backdrop: string,
	back: { Color3 }, -- backdrop colours (main, second, accent)
	fx: string?, -- one MapFx preset on the backdrop (smoke, embers...)
}

-- Per zone (Config/Zones order). Colours follow each zone's ground / accent.
local THEMES: { [number]: Theme } = {
	[1] = {
		wall = rgb(176, 150, 100),
		strata = { rgb(120, 195, 80), rgb(235, 225, 180) },
		edge = "grass",
		edgeColor = rgb(95, 195, 45),
		backdrop = "hills",
		back = { rgb(110, 200, 80), rgb(80, 165, 60), rgb(250, 240, 120) },
	},
	[2] = {
		wall = rgb(232, 204, 148),
		strata = { rgb(250, 238, 200), rgb(70, 190, 240) },
		edge = "grass",
		edgeColor = rgb(60, 185, 80),
		backdrop = "dunes",
		back = { rgb(245, 220, 160), rgb(225, 195, 130), rgb(70, 190, 240) },
	},
	[3] = {
		wall = rgb(168, 92, 44),
		strata = { rgb(235, 155, 60), rgb(110, 60, 30), rgb(250, 200, 80) },
		edge = "leaves",
		edgeColor = rgb(225, 95, 35),
		backdrop = "forest",
		back = { rgb(230, 110, 40), rgb(200, 60, 35), rgb(110, 70, 40) },
	},
	[4] = {
		wall = rgb(96, 70, 122),
		strata = { rgb(240, 70, 80), rgb(95, 175, 85), rgb(250, 235, 220) },
		edge = "moss",
		edgeColor = rgb(90, 170, 80),
		backdrop = "caps",
		back = { rgb(240, 70, 90), rgb(245, 235, 220), rgb(170, 110, 220) },
		fx = "Spores",
	},
	[5] = {
		wall = rgb(212, 158, 88),
		strata = { rgb(245, 205, 135), rgb(175, 105, 55), rgb(70, 190, 180) },
		edge = "rubble",
		edgeColor = rgb(200, 150, 90),
		backdrop = "dunes",
		back = { rgb(235, 190, 110), rgb(210, 160, 85), rgb(200, 120, 60) },
	},
	[6] = {
		wall = rgb(148, 168, 198),
		strata = { rgb(255, 255, 255), rgb(200, 225, 250) },
		edge = "snow",
		edgeColor = rgb(250, 252, 255),
		backdrop = "peaks",
		back = { rgb(150, 170, 200), rgb(245, 250, 255), rgb(140, 190, 240) },
	},
	[7] = {
		wall = rgb(250, 172, 204),
		strata = { rgb(255, 255, 255), rgb(140, 230, 225), rgb(235, 70, 130) },
		edge = "frosting",
		edgeColor = rgb(255, 250, 252),
		backdrop = "candy",
		back = { rgb(255, 160, 210), rgb(150, 230, 220), rgb(255, 230, 120) },
	},
	[8] = {
		wall = rgb(58, 138, 168),
		strata = { rgb(255, 125, 115), rgb(250, 230, 195), rgb(255, 175, 80) },
		edge = "coral",
		edgeColor = rgb(255, 120, 110),
		backdrop = "reef",
		back = { rgb(255, 120, 130), rgb(255, 170, 80), rgb(60, 200, 200) },
		fx = "Bubbles",
	},
	[9] = {
		wall = rgb(56, 40, 40),
		strata = { rgb(28, 20, 20), rgb(130, 65, 40) },
		edge = "lava",
		edgeColor = rgb(255, 110, 20),
		backdrop = "volcano",
		back = { rgb(60, 45, 45), rgb(40, 30, 30), rgb(255, 110, 20) },
		fx = "Embers",
	},
	[10] = {
		wall = rgb(76, 60, 122),
		strata = { rgb(120, 240, 255), rgb(180, 130, 255) },
		edge = "crystal",
		edgeColor = rgb(120, 240, 255),
		backdrop = "crystal",
		back = { rgb(110, 80, 190), rgb(120, 240, 255), rgb(220, 160, 255) },
		fx = "Sparkles",
	},
	[11] = {
		wall = rgb(96, 118, 70),
		strata = { rgb(175, 165, 125), rgb(50, 145, 55) },
		edge = "vines",
		edgeColor = rgb(50, 140, 55),
		backdrop = "jungle",
		back = { rgb(45, 125, 50), rgb(70, 160, 65), rgb(170, 160, 120) },
		fx = "Fireflies",
	},
	[12] = {
		wall = rgb(34, 34, 52),
		strata = { rgb(255, 40, 200), rgb(40, 220, 255) },
		edge = "neon",
		edgeColor = rgb(255, 40, 200),
		backdrop = "city",
		back = { rgb(35, 35, 55), rgb(55, 50, 80), rgb(40, 220, 255) },
	},
	[13] = {
		wall = rgb(70, 70, 80),
		strata = { rgb(36, 36, 42), rgb(130, 128, 140) },
		edge = "graves",
		edgeColor = rgb(150, 150, 160),
		backdrop = "spooky",
		back = { rgb(55, 50, 65), rgb(40, 38, 48), rgb(140, 255, 120) },
		fx = "Wisps",
	},
	[14] = {
		wall = rgb(214, 224, 240),
		strata = { rgb(255, 255, 255), rgb(185, 195, 215) },
		edge = "cloud",
		edgeColor = rgb(255, 255, 255),
		backdrop = "islands",
		back = { rgb(140, 120, 100), rgb(120, 200, 90), rgb(255, 255, 255) },
	},
	[15] = {
		wall = rgb(86, 80, 50),
		strata = { rgb(170, 255, 40), rgb(55, 46, 32) },
		edge = "slime",
		edgeColor = rgb(170, 255, 40),
		backdrop = "swamp",
		back = { rgb(70, 60, 45), rgb(90, 120, 45), rgb(170, 255, 40) },
		fx = "ToxicBubbles",
	},
	[16] = {
		wall = rgb(118, 104, 90),
		strata = { rgb(230, 180, 60), rgb(78, 78, 88) },
		edge = "rivets",
		edgeColor = rgb(230, 180, 60),
		backdrop = "factory",
		back = { rgb(110, 95, 85), rgb(150, 120, 80), rgb(230, 180, 60) },
		fx = "Steam",
	},
	[17] = {
		wall = rgb(168, 208, 230),
		strata = { rgb(255, 255, 255), rgb(120, 255, 200) },
		edge = "ice",
		edgeColor = rgb(210, 245, 255),
		backdrop = "peaks",
		back = { rgb(130, 180, 215), rgb(230, 248, 255), rgb(120, 255, 200) },
		fx = "Aurora",
	},
	[18] = {
		wall = rgb(56, 26, 20),
		strata = { rgb(255, 125, 40), rgb(25, 14, 12) },
		edge = "lava",
		edgeColor = rgb(255, 170, 40),
		backdrop = "forge",
		back = { rgb(30, 20, 20), rgb(70, 30, 20), rgb(255, 150, 30) },
		fx = "Magma",
	},
	[19] = {
		wall = rgb(36, 28, 64),
		strata = { rgb(130, 95, 230), rgb(70, 50, 125), rgb(220, 200, 255) },
		edge = "stars",
		edgeColor = rgb(200, 170, 255),
		backdrop = "cosmos",
		back = { rgb(70, 55, 120), rgb(40, 30, 80), rgb(170, 120, 255) },
		fx = "Stars",
	},
	[20] = {
		wall = rgb(244, 240, 250),
		strata = { rgb(255, 215, 120), rgb(255, 180, 222), rgb(175, 220, 255) },
		edge = "cloud",
		edgeColor = rgb(255, 255, 255),
		backdrop = "heaven",
		back = { rgb(255, 255, 255), rgb(255, 230, 160), rgb(255, 120, 200) },
	},
}
Scenery.THEMES = THEMES

-- The canyon wall face colour for zone `id` (nil = the builder's default).
function Scenery.wallColor(id: number): Color3?
	local t = THEMES[id]
	return t and t.wall
end

local function fade(c: Color3, k: number?): Color3
	return c:Lerp(SKY, k or 0.18) -- a little atmospheric depth for far shapes
end

local function model(parent: Instance, name: string): Model
	return Bricks.model(parent, name)
end

-- A model that MapLifeController spins (attribute Spin, deg/s) about `pivot`'s Y axis.
local function spinner(parent: Instance, name: string, pivot: CFrame, speed: number): Model
	local m = model(parent, name)
	local root = P(m, "Pivot", Vector3.one * 0.4, pivot, Color3.new(1, 1, 1), { transparency = 1, collide = false })
	m.PrimaryPart = root
	m:SetAttribute("Spin", speed)
	return m
end

------------------------------------------------------------------------------------------------- canyon walls

-- Broken horizontal ledges on both canyon walls + the rim lip treatment.
local function ledges(f: Instance, zone: any, ctx: Ctx, theme: Theme, rng: Random, z0: number, z1: number)
	local g = Instance.new("Folder")
	g.Name = "Ledges"
	g.Parent = f
	local heights = { 13, 27, 40 }
	for k = -1, 1, 2 do
		local face = k * ctx.inner -- the wall's inner face
		for row, y in heights do
			local color = theme.strata[(row - 1) % #theme.strata + 1]
			local z = z0 + rng:NextNumber(1, 6)
			while z < z1 - 6 do
				local len = math.min(rng:NextNumber(12, 30), z1 - 2 - z)
				local depth = rng:NextNumber(1.6, 3.2)
				if len > 4 then
					P(
						g,
						"Ledge",
						Vector3.new(depth, rng:NextNumber(1.2, 2.2), len),
						CFrame.new(face - k * (depth / 2 - 0.2), y, z + len / 2),
						color,
						{ collide = false }
					)
				end
				z += len + rng:NextNumber(3, 10)
			end
		end
		-- rim lip treatment along the wall top (inner edge of the cap)
		local lipX = face + k * 1.2
		local lipY = ctx.wallH + 2
		local e = theme.edge
		if e == "neon" or e == "lava" or e == "slime" then
			P(
				g,
				"LipGlow",
				Vector3.new(0.8, 0.6, z1 - z0 - 1),
				CFrame.new(face - k * 0.1, ctx.wallH - 0.6, (z0 + z1) / 2),
				theme.edgeColor,
				{
					material = NEON,
					collide = false,
				}
			)
		end
		local z = z0 + rng:NextNumber(3, 8)
		while z < z1 - 3 do
			local s = rng:NextNumber(1.4, 3)
			local at = CFrame.new(lipX, lipY, z) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 30), 0)
			if e == "snow" or e == "cloud" or e == "frosting" or e == "ice" then
				P(
					g,
					"Lump",
					Vector3.new(s * 1.6, s * 0.7, s * 1.6),
					at * CFrame.new(0, s * 0.35, 0),
					theme.edgeColor,
					{ collide = false }
				)
			elseif e == "crystal" or e == "stars" then
				P(
					g,
					"Shard",
					Vector3.new(s * 0.6, s * 2.2, s * 0.6),
					at * CFrame.new(0, s, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-20, 20))),
					theme.edgeColor,
					{
						material = NEON,
						collide = false,
					}
				)
			elseif e == "coral" then
				P(
					g,
					"Coral",
					Vector3.new(s * 0.7, s * 1.8, s * 0.7),
					at * CFrame.new(0, s * 0.9, 0),
					theme.edgeColor,
					{ collide = false }
				)
			elseif e == "graves" then
				P(
					g,
					"Grave",
					Vector3.new(0.6, s * 1.2, s * 0.9),
					at * CFrame.new(0, s * 0.6, 0),
					theme.edgeColor,
					{ collide = false }
				)
			elseif e == "rivets" then
				P(g, "Rivet", Vector3.new(1, 1, 1), at * CFrame.new(0, 0.5, 0), theme.edgeColor, { collide = false })
			elseif e == "rubble" then
				P(
					g,
					"Rubble",
					Vector3.new(s, s * 0.6, s * 1.2),
					at * CFrame.new(0, s * 0.3, 0),
					theme.edgeColor,
					{ collide = false }
				)
			elseif e ~= "neon" and e ~= "lava" and e ~= "slime" then -- grass, leaves, moss, vines
				P(
					g,
					"Tuft",
					Vector3.new(s * 1.3, s * 0.8, s * 1.3),
					at * CFrame.new(0, s * 0.4, 0),
					theme.edgeColor,
					{ collide = false }
				)
				if e == "vines" or e == "moss" then
					P(
						g,
						"Vine",
						Vector3.new(0.5, s * 4, 0.6),
						CFrame.new(face - k * 0.4, ctx.wallH - s * 2, z),
						theme.edgeColor:Lerp(rgb(0, 0, 0), 0.15),
						{
							collide = false,
						}
					)
				end
			end
			z += rng:NextNumber(8, 14)
		end
	end
end

--------------------------------------------------------------------------------------------------- backdrops

type Back = (m: Model, at: (x: number, y: number, z: number) -> CFrame, theme: Theme, rng: Random) -> ()

local function stack(
	m: Model,
	at: (number, number, number) -> CFrame,
	widths: { number },
	h: number,
	color: Color3,
	top: Color3?
)
	for i, w in widths do
		P(m, "Step", Vector3.new(w, h, w * 0.9), at(0, (i - 0.5) * h, 0), if top and i == #widths then top else color)
	end
end

local BACKDROPS: { [string]: Back } = {
	hills = function(m, at, theme, rng)
		stack(m, at, { 40, 30, 20, 11 }, 6, fade(theme.back[1]), fade(theme.back[1]:Lerp(rgb(255, 255, 255), 0.15)))
		for _ = 1, 6 do -- flower dots on the slopes
			P(
				m,
				"Flower",
				Vector3.one * 1.6,
				at(rng:NextNumber(-14, 14), rng:NextInteger(1, 3) * 6 + 0.8, rng:NextNumber(-10, 10)),
				theme.back[3]
			)
		end
	end,
	dunes = function(m, at, theme, rng)
		for i = 0, 2 do
			local w, h = rng:NextNumber(26, 40), rng:NextNumber(10, 18)
			local x, z = (i - 1) * 16, rng:NextNumber(-6, 6)
			Bricks.part(
				m,
				"Dune",
				Vector3.new(w, h, w * 0.5),
				at(x, h / 2, z) * CFrame.Angles(0, math.rad(rng:NextNumber(-20, 20)), 0),
				fade(theme.back[(i % 2) + 1]),
				{
					shape = "Wedge",
				}
			)
		end
	end,
	forest = function(m, at, theme, rng)
		for i = 0, 3 do
			local x, z, h = (i - 1.5) * 12 + rng:NextNumber(-2, 2), rng:NextNumber(-8, 8), rng:NextNumber(14, 22)
			P(m, "Trunk", Vector3.new(3, h, 3), at(x, h / 2, z), fade(theme.back[3]))
			stack(m, function(a, b, c)
				return at(x + a, h + b - 2, z + c)
			end, { 14, 11, 7 }, 4.5, fade(theme.back[(i % 2) + 1]))
		end
	end,
	caps = function(m, at, theme, rng)
		for i = 0, 1 do
			local x, h = (i - 0.5) * 22, rng:NextNumber(22, 34)
			P(m, "Stalk", Vector3.new(5, h, 5), at(x, h / 2, 0), fade(theme.back[2]))
			stack(m, function(a, b, c)
				return at(x + a, h + b, c)
			end, { 22, 18, 11 }, 2.6, fade(theme.back[(i % 2) * 2 + 1]))
			for _ = 1, 4 do
				P(
					m,
					"Spot",
					Vector3.new(2.6, 0.6, 2.6),
					at(x + rng:NextNumber(-7, 7), h + 2.9, rng:NextNumber(-6, 6)),
					rgb(250, 245, 240)
				)
			end
		end
	end,
	peaks = function(m, at, theme, rng)
		for i = 0, 1 do
			local x = (i - 0.5) * 26 + rng:NextNumber(-3, 3)
			local widths = { 30, 24, 17, 11, 6 }
			for k, w in widths do
				P(
					m,
					"Peak",
					Vector3.new(w, 9, w),
					at(x, (k - 0.5) * 9, 0) * CFrame.Angles(0, math.rad(45), 0),
					if k >= 4 then fade(theme.back[2], 0.05) else fade(theme.back[1])
				)
			end
			if theme.fx == "Aurora" then -- the aurora ribbon behind the spires
				P(
					m,
					"Aurora",
					Vector3.new(36, 4, 0.4),
					at(x, 52 + i * 6, 12) * CFrame.Angles(0, 0, math.rad(i * 8 - 4)),
					theme.back[3],
					{
						material = NEON,
						collide = false,
						transparency = 0.45,
					}
				)
			end
		end
	end,
	candy = function(m, at, theme, rng)
		for i = 0, 2 do
			local x = (i - 1) * 15
			stack(m, function(a, b, c)
				return at(x + a, b, c + rng:NextNumber(-2, 2))
			end, { 16, 13, 9 }, 5, fade(theme.back[(i % 2) + 1], 0.1), rgb(255, 250, 252))
		end
		for k = 0, 7 do -- a giant candy cane
			P(
				m,
				"Cane",
				Vector3.new(3, 4, 3),
				at(22, k * 4 + 2, -4),
				if k % 2 == 0 then rgb(235, 50, 60) else rgb(255, 255, 255)
			)
		end
		P(m, "CaneHook", Vector3.new(8, 3, 3), at(19.5, 33.5, -4), rgb(235, 50, 60))
	end,
	reef = function(m, at, theme, rng)
		for i = 0, 4 do
			local x, h = (i - 2) * 9 + rng:NextNumber(-2, 2), rng:NextNumber(18, 36)
			local c = fade(theme.back[(i % 3) + 1], 0.1)
			P(m, "Coral", Vector3.new(4, h, 4), at(x, h / 2, rng:NextNumber(-5, 5)), c)
			P(m, "Branch", Vector3.new(9, 3, 3), at(x + 3, h * 0.65, 0) * CFrame.Angles(0, 0, math.rad(35)), c)
		end
	end,
	volcano = function(m, at, theme, rng)
		stack(m, at, { 44, 34, 24, 15 }, 8, fade(theme.back[1], 0.08), fade(theme.back[2], 0.05))
		for k = -1, 1, 2 do
			P(
				m,
				"LavaFlow",
				Vector3.new(3, 24, 1.2),
				at(k * 8, 16, -12) * CFrame.Angles(0, 0, math.rad(k * 25)),
				theme.back[3],
				{
					material = NEON,
					collide = false,
				}
			)
		end
		P(m, "Crater", Vector3.new(10, 1, 10), at(0, 32.6, 0), theme.back[3], { material = NEON, collide = false })
	end,
	crystal = function(m, at, theme, rng)
		for i = 0, 4 do
			local h = rng:NextNumber(20, 44)
			local x = (i - 2) * 8
			P(
				m,
				"Spire",
				Vector3.new(5, h, 5),
				at(x, h / 2, rng:NextNumber(-4, 4)) * CFrame.Angles(0, math.rad(45), math.rad(rng:NextNumber(-14, 14))),
				fade(theme.back[(i % 3) + 1], 0.06),
				{
					material = if i % 2 == 0 then NEON else Enum.Material.Plastic,
					transparency = if i % 2 == 0 then 0.15 else 0,
				}
			)
		end
	end,
	jungle = function(m, at, theme, rng)
		for i = 0, 3 do
			local x, h = (i - 1.5) * 13, rng:NextNumber(16, 26)
			P(m, "Trunk", Vector3.new(3, h, 3), at(x, h / 2, rng:NextNumber(-4, 4)), fade(rgb(90, 65, 40)))
			P(m, "Canopy", Vector3.new(16, 7, 14), at(x, h + 2, 0), fade(theme.back[(i % 2) + 1]))
		end
		stack(m, function(a, b, c)
			return at(a, b, c + 10)
		end, { 18, 14, 10, 6 }, 5, fade(theme.back[3]))
	end,
	city = function(m, at, theme, rng)
		for i = 0, 4 do
			local x, h, w = (i - 2) * 9, rng:NextNumber(24, 58), rng:NextNumber(6, 8)
			P(m, "Tower", Vector3.new(w, h, w), at(x, h / 2, rng:NextNumber(-4, 4)), theme.back[(i % 2) + 1])
			for row = 1, math.floor(h / 8) do
				P(
					m,
					"Windows",
					Vector3.new(w + 0.2, 0.8, w + 0.2),
					at(x, row * 8 - 2, 0),
					if row % 2 == 0 then theme.back[3] else rgb(255, 40, 200),
					{
						material = NEON,
						collide = false,
					}
				)
			end
		end
	end,
	spooky = function(m, at, theme, rng)
		for i = 0, 2 do
			local x, h = (i - 1) * 14, rng:NextNumber(18, 28)
			P(
				m,
				"DeadTrunk",
				Vector3.new(3, h, 3),
				at(x, h / 2, 0) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-8, 8))),
				theme.back[2]
			)
			P(
				m,
				"Branch",
				Vector3.new(10, 1.6, 1.6),
				at(x + 3, h * 0.7, 0) * CFrame.Angles(0, 0, math.rad(30)),
				theme.back[2]
			)
			P(
				m,
				"Branch",
				Vector3.new(8, 1.4, 1.4),
				at(x - 3, h * 0.55, 0) * CFrame.Angles(0, 0, math.rad(-35)),
				theme.back[2]
			)
		end
		stack(m, function(a, b, c)
			return at(a + 22, b, c)
		end, { 9, 7, 5, 3 }, 9, theme.back[1]) -- a crooked spire
		P(
			m,
			"Moon",
			Vector3.one * 12,
			at(-8, 58, 16),
			rgb(235, 240, 220),
			{ shape = "Ball", material = NEON, collide = false }
		)
	end,
	islands = function(m, at, theme, rng)
		for i = 0, 1 do
			local x, y = (i - 0.5) * 30, rng:NextNumber(18, 34)
			local isle = spinner(m, "Island", at(x, y, 0), if i == 0 then 4 else -3)
			local function iat(a: number, b: number, c: number): CFrame
				return at(x + a, y + b, c)
			end
			P(isle, "Rock", Vector3.new(16, 4, 14), iat(0, 0, 0), theme.back[1])
			P(isle, "Rock", Vector3.new(10, 4, 9), iat(0, -4, 0), theme.back[1]:Lerp(rgb(0, 0, 0), 0.1))
			P(isle, "Rock", Vector3.new(4, 4, 4), iat(0, -8, 0), theme.back[1]:Lerp(rgb(0, 0, 0), 0.2))
			P(isle, "Grass", Vector3.new(16.4, 1.2, 14.4), iat(0, 2.6, 0), theme.back[2])
			P(
				isle,
				"Cloud",
				Vector3.new(9, 3, 7),
				iat(rng:NextNumber(-12, 12), -6, 8),
				rgb(255, 255, 255),
				{ collide = false }
			)
		end
	end,
	swamp = function(m, at, theme, rng)
		for i = 0, 2 do
			local x, h = (i - 1) * 14, rng:NextNumber(14, 24)
			P(m, "DeadTrunk", Vector3.new(4, h, 4), at(x, h / 2, rng:NextNumber(-4, 4)), theme.back[1])
			P(m, "Root", Vector3.new(10, 2, 3), at(x, 1, 0) * CFrame.Angles(0, math.rad(i * 50), 0), theme.back[1])
		end
		P(m, "Mound", Vector3.new(34, 6, 20), at(0, 3, 8), fade(theme.back[2]))
		P(
			m,
			"Pool",
			Vector3.new(24, 0.6, 12),
			at(0, 6.4, 8),
			theme.back[3],
			{ material = NEON, collide = false, transparency = 0.25 }
		)
	end,
	factory = function(m, at, theme, rng)
		for i = 0, 1 do
			local x, h = (i - 0.5) * 20, rng:NextNumber(30, 44)
			P(m, "Chimney", Vector3.new(6, h, 6), at(x, h / 2, 6), theme.back[1])
			P(m, "ChimneyBand", Vector3.new(6.6, 1.4, 6.6), at(x, h - 2, 6), theme.back[3])
			MapFx.emit(
				P(
					m,
					"SmokeFx",
					Vector3.new(3, 1, 3),
					at(x, h + 1, 6),
					rgb(255, 255, 255),
					{ transparency = 1, collide = false }
				),
				"Steam"
			)
		end
		P(m, "Hall", Vector3.new(34, 16, 14), at(0, 8, -6), theme.back[2])
		-- a big gear on the hall's face, turning (its pivot's Y axis = the gear axis, facing the canyon)
		local face = at(0, 12, -13.4)
		local gear = spinner(m, "Gear", face * CFrame.Angles(math.rad(90), 0, 0), 20)
		local function g(a: number, c: number): CFrame
			return face * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(a, 0, c)
		end
		P(gear, "GearBody", Vector3.new(9, 1.2, 9), g(0, 0), theme.back[3])
		P(gear, "GearBody", Vector3.new(9, 1.2, 9), g(0, 0) * CFrame.Angles(0, math.rad(45), 0), theme.back[3])
		for t = 0, 7 do
			local a = t / 8 * math.pi * 2
			P(
				gear,
				"Tooth",
				Vector3.new(2, 1.2, 2),
				g(math.cos(a) * 5.4, math.sin(a) * 5.4) * CFrame.Angles(0, -a, 0),
				theme.back[3]
			)
		end
		P(gear, "Axle", Vector3.new(2.4, 1.6, 2.4), g(0, 0), rgb(90, 80, 70))
	end,
	forge = function(m, at, theme, rng)
		for i = 0, 3 do
			local x, h = (i - 1.5) * 11, rng:NextNumber(22, 46)
			P(
				m,
				"Spire",
				Vector3.new(6, h, 6),
				at(x, h / 2, rng:NextNumber(-3, 3)) * CFrame.Angles(0, math.rad(45), 0),
				theme.back[1]
			)
			P(
				m,
				"Crack",
				Vector3.new(1, h * 0.6, 0.6),
				at(x, h * 0.4, -4.3),
				theme.back[3],
				{ material = NEON, collide = false }
			)
		end
	end,
	cosmos = function(m, at, theme, rng)
		local center = at(0, 34, 0)
		local orbit = spinner(m, "Orbit", center, 8)
		P(orbit, "Planet", Vector3.one * 14, center, theme.back[1], { shape = "Ball" })
		P(orbit, "Ring", Vector3.new(26, 0.6, 26), center * CFrame.Angles(math.rad(20), 0, 0), theme.back[3], {
			material = NEON,
			collide = false,
			transparency = 0.3,
		})
		P(orbit, "Moon", Vector3.one * 4, center * CFrame.new(18, 3, 0), rgb(220, 220, 235), { shape = "Ball" })
		for _ = 1, 5 do -- asteroids
			local s = rng:NextNumber(3, 6)
			P(
				m,
				"Asteroid",
				Vector3.new(s, s * 0.8, s),
				at(rng:NextNumber(-22, 22), rng:NextNumber(8, 24), rng:NextNumber(-8, 8))
					* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 1), 0),
				theme.back[2]
			)
		end
	end,
	heaven = function(m, at, theme, rng)
		for i = 0, 2 do
			local x = (i - 1) * 15
			stack(m, function(a, b, c)
				return at(x + a, b, c)
			end, { 14, 11, 8, 5 }, 7, theme.back[1], theme.back[2])
		end
		for k = 0, 5 do -- a rainbow band behind
			P(
				m,
				"Rainbow",
				Vector3.new(44 - k * 4, 1.6, 0.6),
				at(0, 36 - k * 1.6, 14),
				Color3.fromHSV(k / 6, 0.55, 1),
				{
					material = NEON,
					collide = false,
				}
			)
		end
	end,
}

-- Two backdrop shapes per side, beyond the rim plateaus, alternating left / right and staggered in z.
local function backdrops(f: Instance, zone: any, ctx: Ctx, theme: Theme, rng: Random, z0: number, len: number)
	local build = BACKDROPS[theme.backdrop]
	if not build then
		return
	end
	local g = Instance.new("Folder")
	g.Name = "Backdrop"
	g.Parent = f
	local rimOuter = ctx.inner + ctx.wallT + ctx.rimW
	for k = -1, 1, 2 do
		for i = 0, 1 do
			local z = z0 + (i + 0.5) * len / 2 + (if k > 0 then 12 else -12)
			local x = k * (rimOuter + rng:NextNumber(14, 34))
			local base = CFrame.lookAt(Vector3.new(x, ctx.rimTop - 4, z), Vector3.new(0, ctx.rimTop - 4, z))
			local m = model(g, "Backdrop")
			build(m, function(a: number, b: number, c: number): CFrame
				return base * CFrame.new(a, b, c)
			end, theme, rng)
			if theme.fx and i == 0 then
				MapFx.emit(
					P(m, "BackFx", Vector3.new(30, 1, 20), base * CFrame.new(0, 10, 0), rgb(255, 255, 255), {
						transparency = 1,
						collide = false,
					}),
					theme.fx
				)
			end
		end
	end
end

-- The meadow's windmill on the rim opposite its landmark (blades turn).
local function windmill(f: Instance, ctx: Ctx, side: number, z: number)
	local x = side * (ctx.inner + ctx.wallT + 30)
	local y = ctx.rimTop
	local base = CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(0, y, z))
	local m = model(f, "Windmill")
	for k, w in { 10, 9, 8, 7 } do
		P(
			m,
			"Tower",
			Vector3.new(w, 6, w),
			base * CFrame.new(0, (k - 0.5) * 6, 0),
			if k % 2 == 0 then rgb(245, 240, 230) else rgb(230, 225, 215)
		)
	end
	P(m, "Roof", Vector3.new(8, 4, 8), base * CFrame.new(0, 26, 0), rgb(200, 70, 60))
	local hub = base * CFrame.new(0, 22, -4.6)
	local blades = spinner(m, "Blades", hub * CFrame.Angles(math.rad(90), 0, 0), 30)
	for i = 0, 3 do
		local a = i * math.pi / 2
		P(
			blades,
			"Blade",
			Vector3.new(2.6, 0.6, 14),
			hub * CFrame.Angles(math.rad(90), 0, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 7.6),
			rgb(250, 248, 240),
			{
				collide = false,
			}
		)
	end
	P(blades, "Hub", Vector3.new(2, 2, 2), hub, rgb(120, 80, 50), { collide = false })
end

-- Hand-over props: the next zone's kit in this zone's last ~10 studs, the previous one's in its first ~10 studs.
local function blend(f: Instance, zone: any, ctx: Ctx, rng: Random, prevId: number?, nextId: number?, fz0: number)
	local g = Instance.new("Folder")
	g.Name = "Blend"
	g.Parent = f
	local function place(kitZone: number, z: number)
		local kinds = Props.forZone(kitZone)
		for k = -1, 1, 2 do
			local kind = kinds[rng:NextInteger(1, #kinds)]
			local x = k * rng:NextNumber(ctx.half + 5, ctx.inner - 4)
			local s = if Props.native[kind] then 0.85 else 1.05
			ctx.stamp(kind, CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 7) * 45), 0), s, g)
		end
	end
	if nextId then
		place(nextId, zone.start + zone.length - rng:NextNumber(3, 8))
	end
	if prevId then
		local z = zone.start + rng:NextNumber(3, 8)
		if z >= fz0 then
			place(prevId, z)
		end
	end
end

-- Dresses zone `zone` (folder `f`). `fz0` = where its flat floor starts (zone 1 starts after the launch ramp).
function Scenery.build(zone: any, f: Instance, ctx: Ctx, fz0: number, prevId: number?, nextId: number?)
	local theme = THEMES[zone.id]
	if not theme then
		return
	end
	local rng = Random.new(zone.id * 104729)
	local z0, len = zone.start, zone.length
	ledges(f, zone, ctx, theme, rng, math.max(z0, if zone.id == 1 then ctx.wallT else z0), z0 + len)
	backdrops(f, zone, ctx, theme, rng, z0, len)
	if zone.id == 1 then
		windmill(f, ctx, -ctx.landmarkSide, z0 + len * 0.62)
	end
	blend(f, zone, ctx, rng, prevId, nextId, fz0)
end

return Scenery
