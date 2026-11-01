--!strict
-- 79 Prism Seraph (Rainbow Heaven, Secret). Premium hero spec (docs/EggPetPlan.md).
-- Pet: an armoured white-and-gold angel knight hovering (the user's reference): a helm with a dark visor, cyan eyes, a
--      gold spike crown and a prism crystal; a glowing star on the chest; layered pauldrons; gauntlets with gold rings
--      and stars; tabard panels ending in crystals; two great wings of armour plates and faceted crystal feathers
--      in six prism hues with glowing cores; a halo arc with stars, a spinning halo, floating diamond crystals and
--      stars.
-- Egg: pearl terraces, a band of prism crystals, gold bands, a glowing star on the front, prism crystals on top, the
--      Secret band, a halo arc with stars and orbiting shards.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/prism_seraph.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(245, 243, 250) -- #F5F3FA
local MAIN2 = rgb(220, 216, 230) -- #DCD8E6
local DARK = rgb(30, 26, 46) -- #1E1A2E
local LIGHT = rgb(255, 255, 255) -- #FFFFFF
local GLOW = rgb(255, 227, 138) -- #FFE38A
local GLASS = rgb(226, 214, 255) -- #E2D6FF
local TIP = rgb(255, 255, 255) -- #FFFFFF
local GOLD = rgb(224, 178, 78) -- #E0B24E
local GOLD2 = rgb(196, 147, 47) -- #C4932F
local EYE = rgb(127, 232, 255) -- #7FE8FF
local VISOR = rgb(30, 26, 46) -- #1E1A2E
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.7, 0.533, 1.7 }, { 0, 0.267, 0 }, MAIN, { joint = "Body" }),
		P("Shell2", { 2.69, 0.533, 2.69 }, { 0, 0.8, 0 }, MAIN2, { joint = "Body" }),
		P("Shell3", { 3.141, 0.533, 3.141 }, { 0, 1.333, 0 }, MAIN, { joint = "Body" }),
		P("Shell4", { 3.319, 0.533, 3.319 }, { 0, 1.867, 0 }, MAIN2, { joint = "Body" }),
		P("Shell5", { 3.301, 0.533, 3.301 }, { 0, 2.4, 0 }, MAIN, { joint = "Body" }),
		P("Shell6", { 3.118, 0.533, 3.118 }, { 0, 2.933, 0 }, MAIN2, { joint = "Body" }),
		P("Shell7", { 2.773, 0.533, 2.773 }, { 0, 3.467, 0 }, MAIN, { joint = "Body" }),
		P("Shell8", { 2.231, 0.533, 2.231 }, { 0, 4, 0 }, MAIN2, { joint = "Body" }),
		P("Shell9", { 1.324, 0.533, 1.324 }, { 0, 4.533, 0 }, MAIN, { joint = "Body" }),
		P(
			"RarityBand",
			{ 2.85, 0.2, 2.85 },
			{ 0, 0.9, 0 },
			GLINT,
			{ joint = "Body", material = "Neon", studs = false }
		),
		P("GoldBandHigh", { 3.298, 0.16, 3.298 }, { 0, 2.95, 0 }, GOLD, { joint = "Body", studs = false }),
		P("GoldBandLow", { 3.499, 0.16, 3.499 }, { 0, 1.6, 0 }, GOLD, { joint = "Body", studs = false }),
		P(
			"BandPrism1A",
			{ 0.3, 0.527, 0.3 },
			{ 0.442, 2.501, -1.844 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { -32.905, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism1B",
			{ 0.165, 0.357, 0.165 },
			{ 0.442, 2.844, -2.065 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { -32.905, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism2A",
			{ 0.3, 0.527, 0.3 },
			{ 1.844, 2.501, -1.45 },
			rgb(143, 200, 255),
			{ joint = "Body", rot = { 28.513, 36.418, -42.461 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism2B",
			{ 0.165, 0.357, 0.165 },
			{ 2.065, 2.844, -1.45 },
			rgb(143, 200, 255),
			{ joint = "Body", rot = { 28.513, 36.418, -42.461 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism3A",
			{ 0.3, 0.527, 0.3 },
			{ 1.844, 2.501, -0.442 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { 28.513, 36.418, -42.461 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism3B",
			{ 0.165, 0.357, 0.165 },
			{ 2.065, 2.844, -0.442 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { 28.513, 36.418, -42.461 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism4A",
			{ 0.3, 0.527, 0.3 },
			{ 1.844, 2.501, 0.442 },
			rgb(181, 155, 255),
			{ joint = "Body", rot = { 28.513, 36.418, -42.461 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism4B",
			{ 0.165, 0.357, 0.165 },
			{ 2.065, 2.844, 0.442 },
			rgb(181, 155, 255),
			{ joint = "Body", rot = { 28.513, 36.418, -42.461 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism5A",
			{ 0.3, 0.527, 0.3 },
			{ 1.45, 2.501, 1.844 },
			rgb(127, 240, 207),
			{ joint = "Body", rot = { 32.905, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism5B",
			{ 0.165, 0.357, 0.165 },
			{ 1.45, 2.844, 2.065 },
			rgb(127, 240, 207),
			{ joint = "Body", rot = { 32.905, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism6A",
			{ 0.3, 0.527, 0.3 },
			{ 0.442, 2.501, 1.844 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 32.905, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism6B",
			{ 0.165, 0.357, 0.165 },
			{ 0.442, 2.844, 2.065 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 32.905, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism7A",
			{ 0.3, 0.527, 0.3 },
			{ -0.442, 2.501, 1.844 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { 32.905, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism7B",
			{ 0.165, 0.357, 0.165 },
			{ -0.442, 2.844, 2.065 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { 32.905, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism8A",
			{ 0.3, 0.527, 0.3 },
			{ -1.844, 2.501, 1.45 },
			rgb(143, 200, 255),
			{ joint = "Body", rot = { -28.513, 36.418, 42.461 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism8B",
			{ 0.165, 0.357, 0.165 },
			{ -2.065, 2.844, 1.45 },
			rgb(143, 200, 255),
			{ joint = "Body", rot = { -28.513, 36.418, 42.461 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism9A",
			{ 0.3, 0.527, 0.3 },
			{ -1.844, 2.501, 0.442 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { -28.513, 36.418, 42.461 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism9B",
			{ 0.165, 0.357, 0.165 },
			{ -2.065, 2.844, 0.442 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { -28.513, 36.418, 42.461 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism10A",
			{ 0.3, 0.527, 0.3 },
			{ -1.844, 2.501, -0.442 },
			rgb(181, 155, 255),
			{ joint = "Body", rot = { -28.513, 36.418, 42.461 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism10B",
			{ 0.165, 0.357, 0.165 },
			{ -2.065, 2.844, -0.442 },
			rgb(181, 155, 255),
			{ joint = "Body", rot = { -28.513, 36.418, 42.461 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism11A",
			{ 0.3, 0.527, 0.3 },
			{ -1.45, 2.501, -1.844 },
			rgb(127, 240, 207),
			{ joint = "Body", rot = { -32.905, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism11B",
			{ 0.165, 0.357, 0.165 },
			{ -1.45, 2.844, -2.065 },
			rgb(127, 240, 207),
			{ joint = "Body", rot = { -32.905, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BandPrism12A",
			{ 0.3, 0.527, 0.3 },
			{ -0.442, 2.501, -1.844 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { -32.905, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"BandPrism12B",
			{ 0.165, 0.357, 0.165 },
			{ -0.442, 2.844, -2.065 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { -32.905, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"Star1a",
			{ 0.12, 0.243, 0.049 },
			{ 0, 3.6, -1.487 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star1b",
			{ 0.12, 0.243, 0.584 },
			{ -0.31, 3.662, -1.487 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star2a",
			{ 0.12, 0.243, 0.049 },
			{ 0, 3.6, -1.487 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star2b",
			{ 0.12, 0.243, 0.584 },
			{ 0.062, 3.91, -1.487 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star3a",
			{ 0.12, 0.243, 0.049 },
			{ 0, 3.6, -1.487 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star3b",
			{ 0.12, 0.243, 0.584 },
			{ 0.31, 3.538, -1.487 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star4a",
			{ 0.12, 0.243, 0.049 },
			{ 0, 3.6, -1.487 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star4b",
			{ 0.12, 0.243, 0.584 },
			{ -0.062, 3.29, -1.487 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"StarCore",
			{ 0.273, 0.273, 0.156 },
			{ 0, 3.6, -1.487 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"CrownPrism1A",
			{ 0.34, 0.93, 0.34 },
			{ 0, 5.165, 0 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { 0, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrism1B",
			{ 0.187, 0.63, 0.187 },
			{ 0, 5.885, 0 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"CrownPrism2A",
			{ 0.34, 0.589, 0.34 },
			{ 0.458, 4.989, 0.13 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { 12.999, 43.51, -15.679 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrism2B",
			{ 0.187, 0.399, 0.187 },
			{ 0.547, 5.435, 0.146 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { 12.999, 43.51, -15.679 }, material = "Neon", studs = false }
		),
		P(
			"CrownPrism3A",
			{ 0.34, 0.589, 0.34 },
			{ -0.458, 4.989, 0.13 },
			rgb(127, 240, 207),
			{ joint = "Body", rot = { -9.181, 44.288, 15.89 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrism3B",
			{ 0.187, 0.399, 0.187 },
			{ -0.547, 5.435, 0.146 },
			rgb(127, 240, 207),
			{ joint = "Body", rot = { -9.181, 44.288, 15.89 }, material = "Neon", studs = false }
		),
		P(
			"CrownPrism4A",
			{ 0.34, 0.527, 0.34 },
			{ 0.249, 4.961, -0.367 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { 0.523, 45.289, -8.895 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrism4B",
			{ 0.187, 0.357, 0.187 },
			{ 0.293, 5.364, -0.408 },
			rgb(255, 143, 203),
			{ joint = "Body", rot = { 0.523, 45.289, -8.895 }, material = "Neon", studs = false }
		),
		P(
			"CrownPrism5A",
			{ 0.34, 0.527, 0.34 },
			{ -0.249, 4.961, -0.367 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { -11.897, 44.033, 8.703 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrism5B",
			{ 0.187, 0.357, 0.187 },
			{ -0.293, 5.364, -0.408 },
			rgb(255, 229, 122),
			{ joint = "Body", rot = { -11.897, 44.033, 8.703 }, material = "Neon", studs = false }
		),
		P(
			"Arc1",
			{ 0.38, 0.12, 0.14 },
			{ 1.316, 4.771, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 90, 160, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc2",
			{ 0.38, 0.12, 0.14 },
			{ 1.399, 5.209, 0.45 },
			GOLD,
			{ joint = "Body", rot = { 90, 178.333, 0 }, studs = false }
		),
		P(
			"Arc3",
			{ 0.38, 0.12, 0.14 },
			{ 1.341, 5.652, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 90, -163.333, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc4",
			{ 0.38, 0.12, 0.14 },
			{ 1.147, 6.053, 0.45 },
			GOLD,
			{ joint = "Body", rot = { 90, -145, 0 }, studs = false }
		),
		P(
			"Arc5",
			{ 0.38, 0.12, 0.14 },
			{ 0.836, 6.373, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 90, -126.667, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc6",
			{ 0.38, 0.12, 0.14 },
			{ 0.44, 6.579, 0.45 },
			GOLD,
			{ joint = "Body", rot = { 90, -108.333, 0 }, studs = false }
		),
		P(
			"Arc7",
			{ 0.38, 0.12, 0.14 },
			{ 0, 6.65, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 0, -90, -90 }, material = "Neon", studs = false }
		),
		P(
			"Arc8",
			{ 0.38, 0.12, 0.14 },
			{ -0.44, 6.579, 0.45 },
			GOLD,
			{ joint = "Body", rot = { 90, -71.667, 0 }, studs = false }
		),
		P(
			"Arc9",
			{ 0.38, 0.12, 0.14 },
			{ -0.836, 6.373, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 90, -53.333, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc10",
			{ 0.38, 0.12, 0.14 },
			{ -1.147, 6.053, 0.45 },
			GOLD,
			{ joint = "Body", rot = { 90, -35, 0 }, studs = false }
		),
		P(
			"Arc11",
			{ 0.38, 0.12, 0.14 },
			{ -1.341, 5.652, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 90, -16.667, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc12",
			{ 0.38, 0.12, 0.14 },
			{ -1.399, 5.209, 0.45 },
			GOLD,
			{ joint = "Body", rot = { 90, 1.667, 0 }, studs = false }
		),
		P(
			"Arc13",
			{ 0.38, 0.12, 0.14 },
			{ -1.316, 4.771, 0.45 },
			GLOW,
			{ joint = "Body", rot = { 90, 20, 0 }, material = "Neon", studs = false }
		),
		P(
			"ArcStar11a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.65, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar11b",
			{ 0.12, 0.165, 0.395 },
			{ -0.21, 6.692, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar12a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.65, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar12b",
			{ 0.12, 0.165, 0.395 },
			{ 0.042, 6.86, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar13a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.65, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar13b",
			{ 0.12, 0.165, 0.395 },
			{ 0.21, 6.608, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar14a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.65, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar14b",
			{ 0.12, 0.165, 0.395 },
			{ -0.042, 6.44, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar1Core",
			{ 0.185, 0.185, 0.156 },
			{ 0, 6.65, 0.4 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"ArcStar21b",
			{ 0.12, 0.118, 0.282 },
			{ -1.466, 5.759, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar22b",
			{ 0.12, 0.118, 0.282 },
			{ -1.286, 5.879, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar23b",
			{ 0.12, 0.118, 0.282 },
			{ -1.166, 5.699, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar24b",
			{ 0.12, 0.118, 0.282 },
			{ -1.346, 5.579, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar2Core",
			{ 0.132, 0.132, 0.156 },
			{ -1.316, 5.729, 0.4 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"ArcStar31b",
			{ 0.12, 0.118, 0.282 },
			{ 1.166, 5.759, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar32b",
			{ 0.12, 0.118, 0.282 },
			{ 1.346, 5.879, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar33b",
			{ 0.12, 0.118, 0.282 },
			{ 1.466, 5.699, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar34b",
			{ 0.12, 0.118, 0.282 },
			{ 1.286, 5.579, 0.4 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar3Core",
			{ 0.132, 0.132, 0.156 },
			{ 1.316, 5.729, 0.4 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"HubOrbit",
			{ 0.2, 0.2, 0.2 },
			{ 0, 2.6, 0 },
			MAIN,
			{ joint = "Orbit", rot = { 0, 180, 0 }, transparency = 1, studs = false }
		),
		P(
			"Shard1A",
			{ 0.3, 0.496, 0.3 },
			{ 2.487, 2.639, 1.051 },
			rgb(143, 200, 255),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Shard1B",
			{ 0.165, 0.336, 0.165 },
			{ 2.487, 2.255, 1.051 },
			rgb(143, 200, 255),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
		P(
			"Shard2A",
			{ 0.3, 0.496, 0.3 },
			{ -1.051, 2.065, 2.487 },
			rgb(181, 155, 255),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Shard2B",
			{ 0.165, 0.336, 0.165 },
			{ -1.051, 1.681, 2.487 },
			rgb(181, 155, 255),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
		P(
			"Shard3A",
			{ 0.3, 0.496, 0.3 },
			{ -2.487, 2.639, -1.051 },
			rgb(255, 184, 138),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Shard3B",
			{ 0.165, 0.336, 0.165 },
			{ -2.487, 2.255, -1.051 },
			rgb(255, 184, 138),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
		P(
			"Shard4A",
			{ 0.3, 0.496, 0.3 },
			{ 1.051, 2.065, -2.487 },
			rgb(143, 200, 255),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Shard4B",
			{ 0.165, 0.336, 0.165 },
			{ 1.051, 1.681, -2.487 },
			rgb(143, 200, 255),
			{ joint = "Orbit", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P("HingeBody", { 0.22, 0.22, 0.22 }, { 0, 5.94, 0 }, MAIN, { joint = "Body", transparency = 1, studs = false }),
		P("Chest", { 2.2, 1.87, 1.43 }, { 0, 6.6, 0 }, MAIN, { joint = "Body" }),
		P("ChestUpper", { 2.42, 0.55, 1.54 }, { 0, 7.645, 0 }, MAIN2, { joint = "Body" }),
		P("Collar", { 1.43, 0.33, 1.21 }, { 0, 8.03, 0 }, GOLD, { joint = "Body", studs = false }),
		P("ChestTrimL", { 0.132, 1.76, 0.11 }, { -0.792, 6.6, -0.748 }, GOLD, { joint = "Body", studs = false }),
		P(
			"RibL",
			{ 0.55, 0.132, 0.088 },
			{ -0.605, 5.995, -0.748 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, -20 }, studs = false }
		),
		P("ChestTrimR", { 0.132, 1.76, 0.11 }, { 0.792, 6.6, -0.748 }, GOLD, { joint = "Body", studs = false }),
		P(
			"RibR",
			{ 0.55, 0.132, 0.088 },
			{ 0.605, 5.995, -0.748 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 20 }, studs = false }
		),
		P(
			"HeartPrismA",
			{ 0.462, 0.955, 0.462 },
			{ 0, 7.075, -0.557 },
			GLASS,
			{ joint = "Body", rot = { 5.711, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"HeartPrismB",
			{ 0.305, 0.462, 0.305 },
			{ 0, 7.734, -0.492 },
			GLASS,
			{ joint = "Body", rot = { 5.711, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"HeartPrismC",
			{ 0.157, 0.308, 0.157 },
			{ 0, 8.04, -0.461 },
			GLINT,
			{ joint = "Body", rot = { 5.711, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"HeartStar1a",
			{ 0.132, 0.41, 0.082 },
			{ 0, 6.765, -0.902 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar1b",
			{ 0.132, 0.41, 0.984 },
			{ -0.522, 6.87, -0.902 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar2a",
			{ 0.132, 0.41, 0.082 },
			{ 0, 6.765, -0.902 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar2b",
			{ 0.132, 0.41, 0.984 },
			{ 0.105, 7.288, -0.902 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar3a",
			{ 0.132, 0.41, 0.082 },
			{ 0, 6.765, -0.902 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar3b",
			{ 0.132, 0.41, 0.984 },
			{ 0.522, 6.661, -0.902 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar4a",
			{ 0.132, 0.41, 0.082 },
			{ 0, 6.765, -0.902 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStar4b",
			{ 0.132, 0.41, 0.984 },
			{ -0.105, 6.243, -0.902 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HeartStarCore",
			{ 0.46, 0.46, 0.172 },
			{ 0, 6.765, -0.902 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P("Waist", { 1.65, 0.77, 1.155 }, { 0, 5.335, 0 }, MAIN2, { joint = "Body" }),
		P("Belt", { 1.87, 0.242, 1.32 }, { 0, 5.698, 0 }, GOLD, { joint = "Body", studs = false }),
		P(
			"HipPlate1",
			{ 0.99, 0.99, 0.154 },
			{ 0, 4.895, -0.66 },
			MAIN,
			{ joint = "Body", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"HipPlate2",
			{ 0.99, 0.99, 0.154 },
			{ 0, 4.895, 0.66 },
			MAIN,
			{ joint = "Body", rot = { -12, 180, 0 }, studs = false }
		),
		P(
			"HipPlate3",
			{ 0.99, 0.99, 0.154 },
			{ -0.88, 4.895, 0 },
			MAIN,
			{ joint = "Body", rot = { 0, -90, 12 }, studs = false }
		),
		P(
			"HipPlate4",
			{ 0.99, 0.99, 0.154 },
			{ 0.88, 4.895, 0 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, -12 }, studs = false }
		),
		P("TabardFront", { 0.825, 3.41, 0.11 }, { 0, 3.41, -0.77 }, MAIN, { joint = "Body", studs = false }),
		P("TabardEdgeFront0", { 0.11, 3.41, 0.132 }, { -0.413, 3.41, -0.781 }, GOLD, { joint = "Body", studs = false }),
		P("TabardEdgeFront1", { 0.11, 3.41, 0.132 }, { 0.413, 3.41, -0.781 }, GOLD, { joint = "Body", studs = false }),
		P(
			"TabardTipFrontA",
			{ 0.454, 0.614, 0.454 },
			{ 0, 1.728, -0.77 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"TabardTipFrontB",
			{ 0.25, 0.416, 0.25 },
			{ 0, 1.253, -0.77 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
		P(
			"TabardStarFront1b",
			{ 0.132, 0.138, 0.331 },
			{ -0.176, 3.786, -0.858 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarFront2b",
			{ 0.132, 0.138, 0.331 },
			{ 0.035, 3.927, -0.858 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarFront3b",
			{ 0.132, 0.138, 0.331 },
			{ 0.176, 3.716, -0.858 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarFront4b",
			{ 0.132, 0.138, 0.331 },
			{ -0.035, 3.575, -0.858 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarFrontCore",
			{ 0.155, 0.155, 0.172 },
			{ 0, 3.751, -0.858 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"TabardSideL",
			{ 0.55, 2.97, 0.11 },
			{ -0.466, 3.674, -0.495 },
			MAIN,
			{ joint = "Body", rot = { 0, 0, 14 }, studs = false }
		),
		P(
			"TabardEdgeSideL0",
			{ 0.11, 2.97, 0.132 },
			{ -0.733, 3.608, -0.506 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 14 }, studs = false }
		),
		P(
			"TabardEdgeSideL1",
			{ 0.11, 2.97, 0.132 },
			{ -0.199, 3.741, -0.506 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 14 }, studs = false }
		),
		P(
			"TabardTipSideLA",
			{ 0.303, 0.614, 0.303 },
			{ -0.093, 2.258, -0.495 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"TabardTipSideLB",
			{ 0.166, 0.416, 0.166 },
			{ -0.093, 1.783, -0.495 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
		P(
			"TabardStarSideL1b",
			{ 0.132, 0.104, 0.249 },
			{ -0.67, 3.989, -0.583 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideL2a",
			{ 0.132, 0.104, 0.249 },
			{ -0.564, 4.094, -0.583 },
			GLOW,
			{ joint = "Body", rot = { 90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideL3b",
			{ 0.132, 0.104, 0.249 },
			{ -0.406, 3.936, -0.583 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideL4b",
			{ 0.132, 0.104, 0.249 },
			{ -0.564, 3.83, -0.583 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideLCore",
			{ 0.116, 0.116, 0.172 },
			{ -0.538, 3.962, -0.583 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"TabardSideR",
			{ 0.55, 2.97, 0.11 },
			{ 0.466, 3.674, -0.495 },
			MAIN,
			{ joint = "Body", rot = { 0, 0, -14 }, studs = false }
		),
		P(
			"TabardEdgeSideR0",
			{ 0.11, 2.97, 0.132 },
			{ 0.199, 3.741, -0.506 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, -14 }, studs = false }
		),
		P(
			"TabardEdgeSideR1",
			{ 0.11, 2.97, 0.132 },
			{ 0.733, 3.608, -0.506 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, -14 }, studs = false }
		),
		P(
			"TabardTipSideRA",
			{ 0.303, 0.614, 0.303 },
			{ 0.093, 2.258, -0.495 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 0, -45, -180 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"TabardTipSideRB",
			{ 0.166, 0.416, 0.166 },
			{ 0.093, 1.783, -0.495 },
			rgb(255, 184, 138),
			{ joint = "Body", rot = { 0, -45, -180 }, material = "Neon", studs = false }
		),
		P(
			"TabardStarSideR1b",
			{ 0.132, 0.104, 0.249 },
			{ 0.406, 3.989, -0.583 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideR2b",
			{ 0.132, 0.104, 0.249 },
			{ 0.564, 4.094, -0.583 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideR3b",
			{ 0.132, 0.104, 0.249 },
			{ 0.67, 3.936, -0.583 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideR4a",
			{ 0.132, 0.104, 0.249 },
			{ 0.564, 3.83, -0.583 },
			GLOW,
			{ joint = "Body", rot = { -90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"TabardStarSideRCore",
			{ 0.116, 0.116, 0.172 },
			{ 0.538, 3.962, -0.583 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"Arc1",
			{ 0.506, 0.154, 0.176 },
			{ 2.001, 7.92, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, 150, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc2",
			{ 0.506, 0.154, 0.176 },
			{ 2.231, 8.477, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, 165, 0 }, studs = false }
		),
		P(
			"Arc3",
			{ 0.506, 0.154, 0.176 },
			{ 2.31, 9.075, 0.715 },
			GLOW,
			{ joint = "Body", rot = { -90, 0, 180 }, material = "Neon", studs = false }
		),
		P(
			"Arc4",
			{ 0.506, 0.154, 0.176 },
			{ 2.231, 9.673, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, -165, 0 }, studs = false }
		),
		P(
			"Arc5",
			{ 0.506, 0.154, 0.176 },
			{ 2.001, 10.23, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, -150, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc6",
			{ 0.506, 0.154, 0.176 },
			{ 1.633, 10.708, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, -135, 0 }, studs = false }
		),
		P(
			"Arc7",
			{ 0.506, 0.154, 0.176 },
			{ 1.155, 11.076, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, -120, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc8",
			{ 0.506, 0.154, 0.176 },
			{ 0.598, 11.306, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, -105, 0 }, studs = false }
		),
		P(
			"Arc9",
			{ 0.506, 0.154, 0.176 },
			{ 0, 11.385, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 0, -90, -90 }, material = "Neon", studs = false }
		),
		P(
			"Arc10",
			{ 0.506, 0.154, 0.176 },
			{ -0.598, 11.306, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, -75, 0 }, studs = false }
		),
		P(
			"Arc11",
			{ 0.506, 0.154, 0.176 },
			{ -1.155, 11.076, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, -60, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc12",
			{ 0.506, 0.154, 0.176 },
			{ -1.633, 10.708, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, -45, 0 }, studs = false }
		),
		P(
			"Arc13",
			{ 0.506, 0.154, 0.176 },
			{ -2.001, 10.23, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, -30, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc14",
			{ 0.506, 0.154, 0.176 },
			{ -2.231, 9.673, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, -15, 0 }, studs = false }
		),
		P(
			"Arc15",
			{ 0.506, 0.154, 0.176 },
			{ -2.31, 9.075, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc16",
			{ 0.506, 0.154, 0.176 },
			{ -2.231, 8.477, 0.715 },
			GOLD,
			{ joint = "Body", rot = { 90, 15, 0 }, studs = false }
		),
		P(
			"Arc17",
			{ 0.506, 0.154, 0.176 },
			{ -2.001, 7.92, 0.715 },
			GLOW,
			{ joint = "Body", rot = { 90, 30, 0 }, material = "Neon", studs = false }
		),
		P(
			"ArcStar11a",
			{ 0.132, 0.259, 0.052 },
			{ 0, 11.385, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar11b",
			{ 0.132, 0.259, 0.621 },
			{ -0.33, 11.451, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar12a",
			{ 0.132, 0.259, 0.052 },
			{ 0, 11.385, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar12b",
			{ 0.132, 0.259, 0.621 },
			{ 0.066, 11.715, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar13a",
			{ 0.132, 0.259, 0.052 },
			{ 0, 11.385, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar13b",
			{ 0.132, 0.259, 0.621 },
			{ 0.33, 11.319, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar14a",
			{ 0.132, 0.259, 0.052 },
			{ 0, 11.385, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar14b",
			{ 0.132, 0.259, 0.621 },
			{ -0.066, 11.055, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar1Core",
			{ 0.29, 0.29, 0.172 },
			{ 0, 11.385, 0.66 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"ArcStar21a",
			{ 0.132, 0.181, 0.036 },
			{ -2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, -90.001 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar21b",
			{ 0.132, 0.181, 0.435 },
			{ -2.402, 9.911, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar22a",
			{ 0.132, 0.181, 0.036 },
			{ -2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar22b",
			{ 0.132, 0.181, 0.435 },
			{ -2.124, 10.096, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar23a",
			{ 0.132, 0.181, 0.036 },
			{ -2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar23b",
			{ 0.132, 0.181, 0.435 },
			{ -1.94, 9.819, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar24a",
			{ 0.132, 0.181, 0.036 },
			{ -2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar24b",
			{ 0.132, 0.181, 0.435 },
			{ -2.217, 9.634, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar2Core",
			{ 0.203, 0.203, 0.172 },
			{ -2.171, 9.865, 0.66 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"ArcStar31a",
			{ 0.132, 0.181, 0.036 },
			{ 2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar31b",
			{ 0.132, 0.181, 0.435 },
			{ 1.94, 9.911, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar32a",
			{ 0.132, 0.181, 0.036 },
			{ 2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar32b",
			{ 0.132, 0.181, 0.435 },
			{ 2.217, 10.096, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar33a",
			{ 0.132, 0.181, 0.036 },
			{ 2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar33b",
			{ 0.132, 0.181, 0.435 },
			{ 2.402, 9.819, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar34a",
			{ 0.132, 0.181, 0.036 },
			{ 2.171, 9.865, 0.66 },
			GOLD,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar34b",
			{ 0.132, 0.181, 0.435 },
			{ 2.124, 9.634, 0.66 },
			GOLD,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ArcStar3Core",
			{ 0.203, 0.203, 0.172 },
			{ 2.171, 9.865, 0.66 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"HubHalo",
			{ 0.22, 0.22, 0.22 },
			{ 0, 9.845, 0 },
			MAIN,
			{ joint = "Halo", rot = { 0, 180, 0 }, transparency = 1, studs = false }
		),
		P(
			"Halo1",
			{ 0.461, 0.11, 0.154 },
			{ 0, 9.845, -0.825 },
			GLOW,
			{ joint = "Halo", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo2",
			{ 0.461, 0.11, 0.154 },
			{ -0.413, 9.845, -0.714 },
			GLOW,
			{ joint = "Halo", rot = { 0, -150, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo3",
			{ 0.461, 0.11, 0.154 },
			{ -0.714, 9.845, -0.413 },
			GLOW,
			{ joint = "Halo", rot = { 0, -120, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo4",
			{ 0.461, 0.11, 0.154 },
			{ -0.825, 9.845, 0 },
			GLOW,
			{ joint = "Halo", rot = { 0, -90, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo5",
			{ 0.461, 0.11, 0.154 },
			{ -0.714, 9.845, 0.413 },
			GLOW,
			{ joint = "Halo", rot = { 0, -60, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo6",
			{ 0.461, 0.11, 0.154 },
			{ -0.413, 9.845, 0.714 },
			GLOW,
			{ joint = "Halo", rot = { 0, -30, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo7",
			{ 0.461, 0.11, 0.154 },
			{ 0, 9.845, 0.825 },
			GLOW,
			{ joint = "Halo", material = "Neon", studs = false }
		),
		P(
			"Halo8",
			{ 0.461, 0.11, 0.154 },
			{ 0.413, 9.845, 0.714 },
			GLOW,
			{ joint = "Halo", rot = { 0, 30, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo9",
			{ 0.461, 0.11, 0.154 },
			{ 0.714, 9.845, 0.413 },
			GLOW,
			{ joint = "Halo", rot = { 0, 60, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo10",
			{ 0.461, 0.11, 0.154 },
			{ 0.825, 9.845, 0 },
			GLOW,
			{ joint = "Halo", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo11",
			{ 0.461, 0.11, 0.154 },
			{ 0.714, 9.845, -0.413 },
			GLOW,
			{ joint = "Halo", rot = { 0, 120, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo12",
			{ 0.461, 0.11, 0.154 },
			{ 0.413, 9.845, -0.714 },
			GLOW,
			{ joint = "Halo", rot = { 0, 150, 0 }, material = "Neon", studs = false }
		),
		P("HingeHead", { 0.22, 0.22, 0.22 }, { 0, 8.14, 0 }, MAIN, { joint = "Head", transparency = 1, studs = false }),
		P("Helm", { 1.155, 1.265, 1.155 }, { 0, 8.8, 0 }, MAIN, { joint = "Head" }),
		P("Visor", { 0.858, 0.605, 0.11 }, { 0, 8.712, -0.583 }, VISOR, { joint = "Head", studs = false }),
		P("VisorRim", { 0.946, 0.11, 0.132 }, { 0, 9.042, -0.605 }, GOLD, { joint = "Head", studs = false }),
		P("Chin", { 0.792, 0.308, 0.44 }, { 0, 8.25, -0.462 }, MAIN2, { joint = "Head", studs = false }),
		P(
			"EyeL",
			{ 0.176, 0.132, 0.055 },
			{ -0.198, 8.756, -0.66 },
			EYE,
			{ joint = "Head", rot = { 0, 0, 12 }, material = "Neon", studs = false }
		),
		P(
			"PupilL",
			{ 0.066, 0.088, 0.044 },
			{ -0.176, 8.756, -0.693 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"GlintL",
			{ 0.044, 0.044, 0.033 },
			{ -0.264, 8.8, -0.704 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"HelmWingL",
			{ 0.154, 0.66, 0.55 },
			{ -0.66, 8.965, 0.055 },
			GOLD,
			{ joint = "Head", rot = { 0, 0, 25 }, shape = "Wedge", studs = false }
		),
		P(
			"EyeR",
			{ 0.176, 0.132, 0.055 },
			{ 0.198, 8.756, -0.66 },
			EYE,
			{ joint = "Head", rot = { 0, 0, -12 }, material = "Neon", studs = false }
		),
		P(
			"PupilR",
			{ 0.066, 0.088, 0.044 },
			{ 0.176, 8.756, -0.693 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"GlintR",
			{ 0.044, 0.044, 0.033 },
			{ 0.264, 8.8, -0.704 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"HelmWingR",
			{ 0.154, 0.66, 0.55 },
			{ 0.66, 8.965, 0.055 },
			GOLD,
			{ joint = "Head", rot = { 0, 0, -25 }, shape = "Wedge", studs = false }
		),
		P(
			"Crown1",
			{ 0.176, 0.277, 0.176 },
			{ -0.33, 9.544, -0.33 },
			GOLD,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown1Tip",
			{ 0.097, 0.208, 0.097 },
			{ -0.33, 9.775, -0.33 },
			GLOW,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown2",
			{ 0.176, 0.277, 0.176 },
			{ 0.33, 9.544, -0.33 },
			GOLD,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown2Tip",
			{ 0.097, 0.208, 0.097 },
			{ 0.33, 9.775, -0.33 },
			GLOW,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown3",
			{ 0.176, 0.198, 0.176 },
			{ -0.528, 9.504, -0.33 },
			GOLD,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown3Tip",
			{ 0.097, 0.149, 0.097 },
			{ -0.528, 9.669, -0.33 },
			GLOW,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown4",
			{ 0.176, 0.198, 0.176 },
			{ 0.528, 9.504, -0.33 },
			GOLD,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown4Tip",
			{ 0.097, 0.149, 0.097 },
			{ 0.528, 9.669, -0.33 },
			GLOW,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"CrownPrismA",
			{ 0.528, 1.023, 0.528 },
			{ 0, 9.861, -0.084 },
			rgb(255, 233, 255),
			{ joint = "Head", rot = { 2.862, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrismB",
			{ 0.348, 0.495, 0.348 },
			{ 0, 10.569, -0.049 },
			rgb(255, 233, 255),
			{ joint = "Head", rot = { 2.862, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownPrismC",
			{ 0.18, 0.33, 0.18 },
			{ 0, 10.899, -0.033 },
			rgb(255, 233, 255),
			{ joint = "Head", rot = { 2.862, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"HingeArmL",
			{ 0.22, 0.22, 0.22 },
			{ -1.375, 7.48, 0 },
			MAIN,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P("PauldronL", { 1.32, 0.935, 1.485 }, { -1.705, 7.755, 0 }, MAIN, { joint = "ArmL", rot = { 0, 0, 12 } }),
		P("Pauldron2L", { 1.1, 0.55, 1.265 }, { -1.87, 7.26, 0 }, MAIN2, { joint = "ArmL", rot = { 0, 0, 18 } }),
		P(
			"PauldronGoldL",
			{ 1.364, 0.132, 1.54 },
			{ -1.705, 8.25, 0 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 0, 12 }, studs = false }
		),
		P(
			"PauldronPrismLA",
			{ 0.286, 0.477, 0.286 },
			{ -1.849, 8.362, 0 },
			rgb(143, 200, 255),
			{ joint = "ArmL", rot = { -20.375, 41.036, 29.496 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"PauldronPrismLB",
			{ 0.157, 0.323, 0.157 },
			{ -1.986, 8.705, 0 },
			GLINT,
			{ joint = "ArmL", rot = { -20.375, 41.036, 29.496 }, material = "Neon", studs = false }
		),
		P("UpperArmL", { 0.682, 1.1, 0.726 }, { -1.98, 6.655, -0.11 }, MAIN2, { joint = "ArmL" }),
		P(
			"ElbowL",
			{ 0.638, 0.638, 0.638 },
			{ -2.035, 6.16, -0.22 },
			GOLD,
			{ joint = "ArmL", shape = "Ball", studs = false }
		),
		P("GauntletL", { 0.902, 1.265, 0.946 }, { -2.145, 5.335, -0.33 }, MAIN, { joint = "ArmL" }),
		P("GauntletPlateL", { 0.968, 0.55, 1.012 }, { -2.145, 5.665, -0.33 }, MAIN2, { joint = "ArmL" }),
		P("CuffL", { 1.012, 0.176, 1.056 }, { -2.145, 4.862, -0.33 }, GOLD, { joint = "ArmL", studs = false }),
		P("HandL", { 0.792, 0.682, 0.836 }, { -2.145, 4.378, -0.352 }, MAIN, { joint = "ArmL" }),
		P("FingerL1", { 0.198, 0.396, 0.22 }, { -2.387, 3.982, -0.605 }, MAIN2, { joint = "ArmL", studs = false }),
		P("FingerL2", { 0.198, 0.396, 0.22 }, { -2.145, 3.982, -0.605 }, MAIN2, { joint = "ArmL", studs = false }),
		P("FingerL3", { 0.198, 0.396, 0.22 }, { -1.903, 3.982, -0.605 }, MAIN2, { joint = "ArmL", studs = false }),
		P(
			"ArmRingL1",
			{ 0.602, 0.088, 0.132 },
			{ -2.145, 5.39, -1.232 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"ArmRingL2",
			{ 0.602, 0.088, 0.132 },
			{ -2.675, 5.39, -1.06 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -144, 0 }, studs = false }
		),
		P(
			"ArmRingL3",
			{ 0.602, 0.088, 0.132 },
			{ -3.003, 5.39, -0.609 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -108, 0 }, studs = false }
		),
		P(
			"ArmRingL4",
			{ 0.602, 0.088, 0.132 },
			{ -3.003, 5.39, -0.051 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -72, 0 }, studs = false }
		),
		P(
			"ArmRingL5",
			{ 0.602, 0.088, 0.132 },
			{ -2.675, 5.39, 0.4 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -36, 0 }, studs = false }
		),
		P("ArmRingL6", { 0.602, 0.088, 0.132 }, { -2.145, 5.39, 0.572 }, GOLD, { joint = "ArmL", studs = false }),
		P(
			"ArmRingL7",
			{ 0.602, 0.088, 0.132 },
			{ -1.615, 5.39, 0.4 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 36, 0 }, studs = false }
		),
		P(
			"ArmRingL8",
			{ 0.602, 0.088, 0.132 },
			{ -1.287, 5.39, -0.051 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 72, 0 }, studs = false }
		),
		P(
			"ArmRingL9",
			{ 0.602, 0.088, 0.132 },
			{ -1.287, 5.39, -0.609 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 108, 0 }, studs = false }
		),
		P(
			"ArmRingL10",
			{ 0.602, 0.088, 0.132 },
			{ -1.615, 5.39, -1.06 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 144, 0 }, studs = false }
		),
		P(
			"ArmStarL1b",
			{ 0.132, 0.129, 0.311 },
			{ -3.154, 5.423, -0.512 },
			GLOW,
			{ joint = "ArmL", rot = { -12.604, 153.99, 5.6 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarL2b",
			{ 0.132, 0.129, 0.311 },
			{ -3.065, 5.555, -0.69 },
			GLOW,
			{ joint = "ArmL", rot = { 79.858, -5.032, -153.882 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarL3b",
			{ 0.132, 0.129, 0.311 },
			{ -3.006, 5.357, -0.808 },
			GLOW,
			{ joint = "ArmL", rot = { -12.604, -26.01, 174.4 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarL4b",
			{ 0.132, 0.129, 0.311 },
			{ -3.095, 5.225, -0.63 },
			GLOW,
			{ joint = "ArmL", rot = { -100.142, 5.032, 153.882 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarLCore",
			{ 0.145, 0.145, 0.172 },
			{ -3.08, 5.39, -0.66 },
			GLINT,
			{ joint = "ArmL", rot = { 0, -116.565, 45 }, material = "Neon", studs = false }
		),
		P(
			"HingeArmR",
			{ 0.22, 0.22, 0.22 },
			{ 1.375, 7.48, 0 },
			MAIN,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P("PauldronR", { 1.32, 0.935, 1.485 }, { 1.705, 7.755, 0 }, MAIN, { joint = "ArmR", rot = { 0, 0, -12 } }),
		P("Pauldron2R", { 1.1, 0.55, 1.265 }, { 1.87, 7.26, 0 }, MAIN2, { joint = "ArmR", rot = { 0, 0, -18 } }),
		P(
			"PauldronGoldR",
			{ 1.364, 0.132, 1.54 },
			{ 1.705, 8.25, 0 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 0, -12 }, studs = false }
		),
		P(
			"PauldronPrismRA",
			{ 0.286, 0.477, 0.286 },
			{ 1.849, 8.362, 0 },
			rgb(181, 155, 255),
			{ joint = "ArmR", rot = { 20.375, 41.036, -29.496 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"PauldronPrismRB",
			{ 0.157, 0.323, 0.157 },
			{ 1.986, 8.705, 0 },
			GLINT,
			{ joint = "ArmR", rot = { 20.375, 41.036, -29.496 }, material = "Neon", studs = false }
		),
		P("UpperArmR", { 0.682, 1.1, 0.726 }, { 1.98, 6.655, -0.11 }, MAIN2, { joint = "ArmR" }),
		P(
			"ElbowR",
			{ 0.638, 0.638, 0.638 },
			{ 2.035, 6.16, -0.22 },
			GOLD,
			{ joint = "ArmR", shape = "Ball", studs = false }
		),
		P("GauntletR", { 0.902, 1.265, 0.946 }, { 2.145, 5.335, -0.33 }, MAIN, { joint = "ArmR" }),
		P("GauntletPlateR", { 0.968, 0.55, 1.012 }, { 2.145, 5.665, -0.33 }, MAIN2, { joint = "ArmR" }),
		P("CuffR", { 1.012, 0.176, 1.056 }, { 2.145, 4.862, -0.33 }, GOLD, { joint = "ArmR", studs = false }),
		P("HandR", { 0.792, 0.682, 0.836 }, { 2.145, 4.378, -0.352 }, MAIN, { joint = "ArmR" }),
		P("FingerR1", { 0.198, 0.396, 0.22 }, { 1.903, 3.982, -0.605 }, MAIN2, { joint = "ArmR", studs = false }),
		P("FingerR2", { 0.198, 0.396, 0.22 }, { 2.145, 3.982, -0.605 }, MAIN2, { joint = "ArmR", studs = false }),
		P("FingerR3", { 0.198, 0.396, 0.22 }, { 2.387, 3.982, -0.605 }, MAIN2, { joint = "ArmR", studs = false }),
		P(
			"ArmRingR1",
			{ 0.602, 0.088, 0.132 },
			{ 2.145, 5.39, -1.232 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"ArmRingR2",
			{ 0.602, 0.088, 0.132 },
			{ 1.615, 5.39, -1.06 },
			GOLD,
			{ joint = "ArmR", rot = { 0, -144, 0 }, studs = false }
		),
		P(
			"ArmRingR3",
			{ 0.602, 0.088, 0.132 },
			{ 1.287, 5.39, -0.609 },
			GOLD,
			{ joint = "ArmR", rot = { 0, -108, 0 }, studs = false }
		),
		P(
			"ArmRingR4",
			{ 0.602, 0.088, 0.132 },
			{ 1.287, 5.39, -0.051 },
			GOLD,
			{ joint = "ArmR", rot = { 0, -72, 0 }, studs = false }
		),
		P(
			"ArmRingR5",
			{ 0.602, 0.088, 0.132 },
			{ 1.615, 5.39, 0.4 },
			GOLD,
			{ joint = "ArmR", rot = { 0, -36, 0 }, studs = false }
		),
		P("ArmRingR6", { 0.602, 0.088, 0.132 }, { 2.145, 5.39, 0.572 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"ArmRingR7",
			{ 0.602, 0.088, 0.132 },
			{ 2.675, 5.39, 0.4 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 36, 0 }, studs = false }
		),
		P(
			"ArmRingR8",
			{ 0.602, 0.088, 0.132 },
			{ 3.003, 5.39, -0.051 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 72, 0 }, studs = false }
		),
		P(
			"ArmRingR9",
			{ 0.602, 0.088, 0.132 },
			{ 3.003, 5.39, -0.609 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 108, 0 }, studs = false }
		),
		P(
			"ArmRingR10",
			{ 0.602, 0.088, 0.132 },
			{ 2.675, 5.39, -1.06 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 144, 0 }, studs = false }
		),
		P(
			"ArmStarR1b",
			{ 0.132, 0.129, 0.311 },
			{ 3.006, 5.423, -0.808 },
			GLOW,
			{ joint = "ArmR", rot = { 12.604, 26.01, -5.6 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarR2b",
			{ 0.132, 0.129, 0.311 },
			{ 3.095, 5.555, -0.63 },
			GLOW,
			{ joint = "ArmR", rot = { 100.142, -5.032, -26.118 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarR3b",
			{ 0.132, 0.129, 0.311 },
			{ 3.154, 5.357, -0.512 },
			GLOW,
			{ joint = "ArmR", rot = { -167.396, -26.01, 5.6 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarR4b",
			{ 0.132, 0.129, 0.311 },
			{ 3.065, 5.225, -0.69 },
			GLOW,
			{ joint = "ArmR", rot = { -79.858, 5.032, 26.118 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArmStarRCore",
			{ 0.145, 0.145, 0.172 },
			{ 3.08, 5.39, -0.66 },
			GLINT,
			{ joint = "ArmR", rot = { 0, 116.565, 45 }, material = "Neon", studs = false }
		),
		P(
			"WingRootL",
			{ 0.55, 0.55, 0.55 },
			{ -0.66, 7.59, 0.715 },
			GOLD,
			{ joint = "WingL", shape = "Ball", studs = false }
		),
		P(
			"WingArmL1",
			{ 0.605, 1.871, 0.462 },
			{ -1.43, 8.085, 0.908 },
			MAIN,
			{ joint = "WingL", rot = { 6.488, 9.969, 56.698 } }
		),
		P(
			"WingPlateL1",
			{ 0.756, 1.871, 0.176 },
			{ -1.43, 8.327, 0.853 },
			MAIN2,
			{ joint = "WingL", rot = { 6.488, 9.969, 56.698 }, studs = false }
		),
		P(
			"WingGoldL1",
			{ 0.132, 1.871, 0.132 },
			{ -1.43, 7.821, 0.82 },
			GOLD,
			{ joint = "WingL", rot = { 6.488, 9.969, 56.698 }, studs = false }
		),
		P(
			"WingArmL2",
			{ 0.506, 1.561, 0.462 },
			{ -2.915, 8.883, 1.183 },
			MAIN,
			{ joint = "WingL", rot = { 2.371, 5.585, 66.952 } }
		),
		P(
			"WingPlateL2",
			{ 0.632, 1.561, 0.176 },
			{ -2.915, 9.125, 1.128 },
			MAIN2,
			{ joint = "WingL", rot = { 2.371, 5.585, 66.952 }, studs = false }
		),
		P(
			"WingGoldL2",
			{ 0.132, 1.561, 0.132 },
			{ -2.915, 8.619, 1.095 },
			GOLD,
			{ joint = "WingL", rot = { 2.371, 5.585, 66.952 }, studs = false }
		),
		P(
			"PlumeL1",
			{ 0.462, 1.155, 0.154 },
			{ -1.068, 6.879, 0.908 },
			MAIN,
			{ joint = "WingL", rot = { -10.103, 3.513, 161.021 }, studs = false }
		),
		P(
			"PlumeL2",
			{ 0.462, 1.067, 0.154 },
			{ -1.563, 7.145, 0.999 },
			MAIN2,
			{ joint = "WingL", rot = { -10.103, 3.513, 161.021 }, studs = false }
		),
		P(
			"PlumeL3",
			{ 0.462, 0.979, 0.154 },
			{ -2.058, 7.41, 1.091 },
			MAIN,
			{ joint = "WingL", rot = { -10.103, 3.513, 161.021 }, studs = false }
		),
		P(
			"PlumeL4",
			{ 0.462, 0.891, 0.154 },
			{ -2.553, 7.676, 1.183 },
			MAIN2,
			{ joint = "WingL", rot = { -10.103, 3.513, 161.021 }, studs = false }
		),
		P(
			"PlumeL5",
			{ 0.462, 0.803, 0.154 },
			{ -3.048, 7.942, 1.274 },
			MAIN,
			{ joint = "WingL", rot = { -10.103, 3.513, 161.021 }, studs = false }
		),
		P(
			"PlumeL6",
			{ 0.462, 0.715, 0.154 },
			{ -3.543, 8.208, 1.366 },
			MAIN2,
			{ joint = "WingL", rot = { -10.103, 3.513, 161.021 }, studs = false }
		),
		P("PrismL1Aa", { 0.22, 0.908, 0.536 }, { -3.439, 9.671, 1.332 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { -80.674, -38.152, -88.414 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL1Ab", { 0.22, 0.908, 0.518 }, { -3.764, 10.08, 1.399 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { 99.326, 38.152, -91.586 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL1Ba", { 0.22, 1.009, 1.743 }, { -4.165, 10.993, 1.542 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { 98.887, 23.472, 88.64 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL1Bb", { 0.22, 1.009, 0.271 }, { -3.764, 10.08, 1.399 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { -81.113, -23.472, 91.36 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismL1Core",
			{ 0.088, 2.099, 0.286 },
			{ -3.803, 10.341, 1.438 },
			rgb(255, 143, 203),
			{ joint = "WingL", rot = { 8.346, -178.753, -8.44 }, material = "Neon", studs = false }
		),
		P("PrismL2Aa", { 0.22, 0.937, 0.715 }, { -3.459, 9.697, 1.315 }, rgb(143, 200, 255), {
			joint = "WingL",
			rot = { -78.696, -52.554, -84.387 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL2Ab", { 0.22, 0.937, 0.463 }, { -3.926, 10.049, 1.386 }, rgb(143, 200, 255), {
			joint = "WingL",
			rot = { 101.304, 52.554, -95.613 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL2Ba", { 0.22, 1.018, 2.067 }, { -4.657, 10.926, 1.535 }, rgb(143, 200, 255), {
			joint = "WingL",
			rot = { 99.646, 39.385, 85.587 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL2Bb", { 0.22, 1.018, 0.237 }, { -3.926, 10.049, 1.386 }, rgb(143, 200, 255), {
			joint = "WingL",
			rot = { -80.354, -39.385, 94.413 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismL2Core",
			{ 0.088, 2.442, 0.286 },
			{ -4.058, 10.312, 1.425 },
			rgb(143, 200, 255),
			{ joint = "WingL", rot = { 6.843, -176.591, -26.361 }, material = "Neon", studs = false }
		),
		P("PrismL3Aa", { 0.22, 0.948, 0.802 }, { -3.497, 9.62, 1.295 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { -71.666, -69.078, -75.807 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL3Ab", { 0.22, 0.948, 0.44 }, { -4.077, 9.83, 1.365 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { -71.666, 110.922, 75.807 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL3Ba", { 0.22, 1.021, 2.227 }, { -5.102, 10.485, 1.513 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { 102.748, 56.754, 80.81 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL3Bb", { 0.22, 1.021, 0.223 }, { -4.077, 9.83, 1.365 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { -77.252, -56.754, 99.19 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismL3Core",
			{ 0.088, 2.614, 0.286 },
			{ -4.296, 10.049, 1.404 },
			rgb(255, 229, 122),
			{ joint = "WingL", rot = { 5.042, -174.977, -44.779 }, material = "Neon", studs = false }
		),
		P("PrismL4Aa", { 0.22, 0.937, 0.715 }, { -3.485, 9.42, 1.277 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 18.228, -82.652, 14.898 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL4Ab", { 0.22, 0.937, 0.463 }, { -4.069, 9.397, 1.349 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 18.228, 97.348, -14.898 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL4Ba", { 0.22, 1.018, 0.237 }, { -4.069, 9.397, 1.349 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { -77.649, -51.897, -78.446 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL4Bb", { 0.22, 1.018, 2.067 }, { -4.976, 10.091, 1.501 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 102.351, 51.897, -101.554 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismL4Core",
			{ 0.088, 2.442, 0.286 },
			{ -4.338, 9.517, 1.389 },
			rgb(181, 155, 255),
			{ joint = "WingL", rot = { 3.213, -172.901, -65.573 }, material = "Neon", studs = false }
		),
		P("PrismL5Aa", { 0.22, 0.908, 0.518 }, { -3.848, 8.94, 1.321 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 103.448, 56.41, 74.486 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL5Ab", { 0.22, 0.908, 0.536 }, { -3.409, 8.656, 1.254 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { -76.552, -56.41, 105.514 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL5Ba", { 0.22, 1.009, 1.743 }, { -4.821, 8.727, 1.465 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { -124.086, 75.208, -54.578 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL5Bb", { 0.22, 1.009, 0.271 }, { -3.848, 8.94, 1.321 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 55.914, -75.208, -125.422 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismL5Core",
			{ 0.088, 2.099, 0.286 },
			{ -4.111, 8.953, 1.361 },
			rgb(127, 240, 207),
			{ joint = "WingL", rot = { 0.429, -171.49, -87.106 }, material = "Neon", studs = false }
		),
		P("PrismL6Aa", { 0.22, 0.774, 0.523 }, { -3.058, 8.458, 1.224 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -90, -17.526, -81.438 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL6Ab", { 0.22, 0.774, 0.522 }, { -3.216, 8.956, 1.224 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { 90, 17.526, -98.562 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL6Ba", { 0.22, 0.996, 0.316 }, { -3.502, 8.591, 1.281 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -1.923, -81.837, 0.666 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismL6Bb", { 0.22, 0.996, 1.41 }, { -4.357, 8.596, 1.404 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -1.924, 98.163, -0.666 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismL6Core",
			{ 0.088, 1.756, 0.286 },
			{ -3.724, 8.521, 1.316 },
			rgb(255, 184, 138),
			{ joint = "WingL", rot = { 177.404, -8.162, 72.289 }, material = "Neon", studs = false }
		),
		P("InnerPrismL1Aa", { 0.22, 0.598, 0.385 }, { -3.185, 9.223, 0.922 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { -90, 73.301, -87.258 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL1Ab", { 0.22, 0.598, 0.385 }, { -2.816, 9.334, 0.922 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { 90, -73.301, -92.742 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL1Ba", { 0.22, 0.737, 1.105 }, { -3.454, 10.118, 0.967 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { 93.148, 33.522, 89.055 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL1Bb", { 0.22, 0.737, 0.223 }, { -3.087, 9.565, 0.936 }, rgb(255, 229, 122), {
			joint = "WingL",
			rot = { -86.852, -33.522, 90.945 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismL1Core",
			{ 0.088, 1.327, 0.286 },
			{ -3.143, 9.753, 0.946 },
			rgb(255, 229, 122),
			{ joint = "WingL", rot = { 2.626, -179.212, -16.681 }, material = "Neon", studs = false }
		),
		P("InnerPrismL2Aa", { 0.22, 0.667, 0.388 }, { -2.825, 9.314, 0.906 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { -84.251, -67.725, -85.931 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL2Ab", { 0.22, 0.667, 0.384 }, { -3.182, 9.459, 0.92 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 95.749, 67.725, -94.069 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL2Ba", { 0.22, 0.743, 1.271 }, { -3.77, 9.902, 0.951 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 94.027, 52.978, 87.44 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL2Bb", { 0.22, 0.743, 0.201 }, { -3.182, 9.459, 0.92 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { -85.973, -52.978, 92.56 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismL2Core",
			{ 0.088, 1.498, 0.286 },
			{ -3.312, 9.627, 0.93 },
			rgb(181, 155, 255),
			{ joint = "WingL", rot = { 1.983, -178.459, -37.848 }, material = "Neon", studs = false }
		),
		P("InnerPrismL3Aa", { 0.22, 0.667, 0.388 }, { -2.835, 9.197, 0.89 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 43.511, -86.813, 42.224 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL3Ab", { 0.22, 0.667, 0.384 }, { -3.22, 9.183, 0.906 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 43.511, 93.187, -42.224 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL3Ba", { 0.22, 0.743, 1.271 }, { -3.938, 9.343, 0.939 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 101.656, 77.158, 79.325 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL3Bb", { 0.22, 0.743, 0.201 }, { -3.22, 9.183, 0.906 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { -78.343, -77.158, 100.675 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismL3Core",
			{ 0.088, 1.498, 0.286 },
			{ -3.408, 9.281, 0.915 },
			rgb(127, 240, 207),
			{ joint = "WingL", rot = { 1.243, -177.64, -62.216 }, material = "Neon", studs = false }
		),
		P("InnerPrismL4Aa", { 0.22, 0.563, 0.385 }, { -2.777, 8.633, 0.872 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -90, 2.862, -87.141 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL4Ab", { 0.22, 0.563, 0.385 }, { -2.757, 9.017, 0.872 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { 90, -2.862, -92.859 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL4Ba", { 0.22, 0.733, 1.021 }, { -3.654, 8.677, 0.916 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -100.413, 74.77, -79.069 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL4Bb", { 0.22, 0.733, 0.236 }, { -3.048, 8.839, 0.886 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { 79.587, -74.77, -100.931 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismL4Core",
			{ 0.088, 1.241, 0.286 },
			{ -3.237, 8.849, 0.896 },
			rgb(255, 184, 138),
			{ joint = "WingL", rot = { 0.143, -177.145, -87.134 }, material = "Neon", studs = false }
		),
		P("InnerPrismL5Aa", { 0.22, 0.493, 0.385 }, { -2.484, 8.472, 0.855 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { -90, -25.201, -86.953 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL5Ab", { 0.22, 0.493, 0.385 }, { -2.648, 8.82, 0.855 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { 90, 25.201, -93.047 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL5Ba", { 0.22, 0.723, 0.266 }, { -2.788, 8.541, 0.868 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { 60.13, -84.251, 61.307 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismL5Bb", { 0.22, 0.723, 0.85 }, { -3.343, 8.493, 0.896 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { 60.13, 95.749, -61.307 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismL5Core",
			{ 0.088, 1.069, 0.286 },
			{ -2.945, 8.467, 0.877 },
			rgb(255, 143, 203),
			{ joint = "WingL", rot = { 178.702, -2.756, 64.768 }, material = "Neon", studs = false }
		),
		P("LowPrismL1Aa", { 0.22, 0.765, 0.456 }, { -2.625, 8.247, 1.172 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 80.409, -14.764, 82.213 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL1Ab", { 0.22, 0.765, 0.435 }, { -2.738, 7.822, 1.243 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { -99.591, 14.764, 97.787 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL1Ba", { 0.22, 0.85, 0.227 }, { -2.738, 7.822, 1.243 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 69.88, -58.642, 75.417 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL1Bb", { 0.22, 0.85, 1.476 }, { -3.465, 7.406, 1.396 }, rgb(181, 155, 255), {
			joint = "WingL",
			rot = { 69.88, 121.358, -75.417 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismL1Core",
			{ 0.088, 1.756, 0.286 },
			{ -2.902, 7.658, 1.287 },
			rgb(181, 155, 255),
			{ joint = "WingL", rot = { 172.405, -7.529, 44.5 }, material = "Neon", studs = false }
		),
		P("LowPrismL2Aa", { 0.22, 0.78, 0.546 }, { -2.152, 7.809, 1.067 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 81.013, 1.302, 85.482 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL2Ab", { 0.22, 0.78, 0.407 }, { -2.141, 7.339, 1.141 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { -98.987, -1.302, 94.518 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL2Ba", { 0.22, 0.855, 1.639 }, { -2.339, 6.45, 1.299 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { -100.085, 12.395, -85.375 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL2Bb", { 0.22, 0.855, 0.209 }, { -2.141, 7.339, 1.141 }, rgb(127, 240, 207), {
			joint = "WingL",
			rot = { 79.915, -12.395, -94.625 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismL2Core",
			{ 0.088, 1.927, 0.286 },
			{ -2.251, 7.118, 1.185 },
			rgb(127, 240, 207),
			{ joint = "WingL", rot = { 170.91, -4.517, 26.206 }, material = "Neon", studs = false }
		),
		P("LowPrismL3Aa", { 0.22, 0.704, 0.44 }, { -1.208, 7.417, 0.951 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -90, -75.964, -79.019 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL3Ab", { 0.22, 0.704, 0.44 }, { -1.635, 7.524, 0.951 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { 90, 75.964, -100.981 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL3Ba", { 0.22, 0.844, 1.311 }, { -1.47, 6.369, 1.161 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { -100.54, -2.598, -87.349 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL3Bb", { 0.22, 0.844, 0.248 }, { -1.505, 7.135, 1.018 }, rgb(255, 184, 138), {
			joint = "WingL",
			rot = { 79.46, 2.598, -92.651 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismL3Core",
			{ 0.088, 1.584, 0.286 },
			{ -1.558, 6.926, 1.06 },
			rgb(255, 184, 138),
			{ joint = "WingL", rot = { 169.34, -2.648, 13.789 }, material = "Neon", studs = false }
		),
		P("LowPrismL4Aa", { 0.22, 0.563, 0.44 }, { -0.7, 7.242, 0.832 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { -90, -87.138, -78.704 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL4Ab", { 0.22, 0.563, 0.44 }, { -1.14, 7.264, 0.832 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { -90, 92.862, 78.704 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL4Ba", { 0.22, 0.826, 0.971 }, { -0.744, 6.38, 1.004 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { -101.107, -17.378, -89.413 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismL4Bb", { 0.22, 0.826, 0.304 }, { -0.934, 6.977, 0.887 }, rgb(255, 143, 203), {
			joint = "WingL",
			rot = { 78.893, 17.378, -90.587 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismL4Core",
			{ 0.088, 1.241, 0.286 },
			{ -0.943, 6.791, 0.924 },
			rgb(255, 143, 203),
			{ joint = "WingL", rot = { 168.718, -0.56, 2.807 }, material = "Neon", studs = false }
		),
		P(
			"WingRootR",
			{ 0.55, 0.55, 0.55 },
			{ 0.66, 7.59, 0.715 },
			GOLD,
			{ joint = "WingR", shape = "Ball", studs = false }
		),
		P(
			"WingArmR1",
			{ 0.605, 1.871, 0.462 },
			{ 1.43, 8.085, 0.908 },
			MAIN,
			{ joint = "WingR", rot = { 6.488, -9.969, -56.698 } }
		),
		P(
			"WingPlateR1",
			{ 0.756, 1.871, 0.176 },
			{ 1.43, 8.327, 0.853 },
			MAIN2,
			{ joint = "WingR", rot = { 6.488, -9.969, -56.698 }, studs = false }
		),
		P(
			"WingGoldR1",
			{ 0.132, 1.871, 0.132 },
			{ 1.43, 7.821, 0.82 },
			GOLD,
			{ joint = "WingR", rot = { 6.488, -9.969, -56.698 }, studs = false }
		),
		P(
			"WingArmR2",
			{ 0.506, 1.561, 0.462 },
			{ 2.915, 8.883, 1.183 },
			MAIN,
			{ joint = "WingR", rot = { 2.371, -5.585, -66.952 } }
		),
		P(
			"WingPlateR2",
			{ 0.632, 1.561, 0.176 },
			{ 2.915, 9.125, 1.128 },
			MAIN2,
			{ joint = "WingR", rot = { 2.371, -5.585, -66.952 }, studs = false }
		),
		P(
			"WingGoldR2",
			{ 0.132, 1.561, 0.132 },
			{ 2.915, 8.619, 1.095 },
			GOLD,
			{ joint = "WingR", rot = { 2.371, -5.585, -66.952 }, studs = false }
		),
		P(
			"PlumeR1",
			{ 0.462, 1.155, 0.154 },
			{ 1.068, 6.879, 0.908 },
			MAIN,
			{ joint = "WingR", rot = { -10.103, -3.513, -161.021 }, studs = false }
		),
		P(
			"PlumeR2",
			{ 0.462, 1.067, 0.154 },
			{ 1.563, 7.145, 0.999 },
			MAIN2,
			{ joint = "WingR", rot = { -10.103, -3.513, -161.021 }, studs = false }
		),
		P(
			"PlumeR3",
			{ 0.462, 0.979, 0.154 },
			{ 2.058, 7.41, 1.091 },
			MAIN,
			{ joint = "WingR", rot = { -10.103, -3.513, -161.021 }, studs = false }
		),
		P(
			"PlumeR4",
			{ 0.462, 0.891, 0.154 },
			{ 2.553, 7.676, 1.183 },
			MAIN2,
			{ joint = "WingR", rot = { -10.103, -3.513, -161.021 }, studs = false }
		),
		P(
			"PlumeR5",
			{ 0.462, 0.803, 0.154 },
			{ 3.048, 7.942, 1.274 },
			MAIN,
			{ joint = "WingR", rot = { -10.103, -3.513, -161.021 }, studs = false }
		),
		P(
			"PlumeR6",
			{ 0.462, 0.715, 0.154 },
			{ 3.543, 8.208, 1.366 },
			MAIN2,
			{ joint = "WingR", rot = { -10.103, -3.513, -161.021 }, studs = false }
		),
		P("PrismR1Aa", { 0.22, 0.908, 0.518 }, { 3.764, 10.08, 1.399 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { 99.326, -38.152, 91.586 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR1Ab", { 0.22, 0.908, 0.536 }, { 3.439, 9.671, 1.332 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { -80.674, 38.152, 88.414 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR1Ba", { 0.22, 1.009, 0.271 }, { 3.764, 10.08, 1.399 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { -81.113, 23.472, -91.36 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR1Bb", { 0.22, 1.009, 1.743 }, { 4.165, 10.993, 1.542 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { 98.887, -23.472, -88.64 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismR1Core",
			{ 0.088, 2.099, 0.286 },
			{ 3.803, 10.341, 1.438 },
			rgb(255, 143, 203),
			{ joint = "WingR", rot = { 8.346, 178.753, 8.44 }, material = "Neon", studs = false }
		),
		P("PrismR2Aa", { 0.22, 0.937, 0.463 }, { 3.926, 10.049, 1.386 }, rgb(143, 200, 255), {
			joint = "WingR",
			rot = { 101.304, -52.554, 95.613 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR2Ab", { 0.22, 0.937, 0.715 }, { 3.459, 9.697, 1.315 }, rgb(143, 200, 255), {
			joint = "WingR",
			rot = { -78.696, 52.554, 84.387 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR2Ba", { 0.22, 1.018, 0.237 }, { 3.926, 10.049, 1.386 }, rgb(143, 200, 255), {
			joint = "WingR",
			rot = { -80.354, 39.385, -94.413 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR2Bb", { 0.22, 1.018, 2.067 }, { 4.657, 10.926, 1.535 }, rgb(143, 200, 255), {
			joint = "WingR",
			rot = { 99.646, -39.385, -85.587 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismR2Core",
			{ 0.088, 2.442, 0.286 },
			{ 4.058, 10.312, 1.425 },
			rgb(143, 200, 255),
			{ joint = "WingR", rot = { 6.843, 176.591, 26.361 }, material = "Neon", studs = false }
		),
		P("PrismR3Aa", { 0.22, 0.948, 0.44 }, { 4.077, 9.83, 1.365 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { -71.666, -110.922, -75.807 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR3Ab", { 0.22, 0.948, 0.802 }, { 3.497, 9.62, 1.295 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { -71.666, 69.078, 75.807 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR3Ba", { 0.22, 1.021, 0.223 }, { 4.077, 9.83, 1.365 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { -77.252, 56.754, -99.19 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR3Bb", { 0.22, 1.021, 2.227 }, { 5.102, 10.485, 1.513 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { 102.748, -56.754, -80.81 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismR3Core",
			{ 0.088, 2.614, 0.286 },
			{ 4.296, 10.049, 1.404 },
			rgb(255, 229, 122),
			{ joint = "WingR", rot = { 5.042, 174.977, 44.779 }, material = "Neon", studs = false }
		),
		P("PrismR4Aa", { 0.22, 0.937, 0.463 }, { 4.069, 9.397, 1.349 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 18.228, -97.348, 14.898 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR4Ab", { 0.22, 0.937, 0.715 }, { 3.485, 9.42, 1.277 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 18.228, 82.652, -14.898 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR4Ba", { 0.22, 1.018, 2.067 }, { 4.976, 10.091, 1.501 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 102.351, -51.897, 101.554 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR4Bb", { 0.22, 1.018, 0.237 }, { 4.069, 9.397, 1.349 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { -77.649, 51.897, 78.447 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismR4Core",
			{ 0.088, 2.442, 0.286 },
			{ 4.338, 9.517, 1.389 },
			rgb(181, 155, 255),
			{ joint = "WingR", rot = { 3.213, 172.901, 65.573 }, material = "Neon", studs = false }
		),
		P("PrismR5Aa", { 0.22, 0.908, 0.536 }, { 3.409, 8.656, 1.254 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { -76.552, 56.41, -105.514 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR5Ab", { 0.22, 0.908, 0.518 }, { 3.848, 8.94, 1.321 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 103.448, -56.41, -74.486 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR5Ba", { 0.22, 1.009, 0.271 }, { 3.848, 8.94, 1.321 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 55.914, 75.208, 125.422 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR5Bb", { 0.22, 1.009, 1.743 }, { 4.821, 8.727, 1.465 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { -124.086, -75.208, 54.578 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismR5Core",
			{ 0.088, 2.099, 0.286 },
			{ 4.111, 8.953, 1.361 },
			rgb(127, 240, 207),
			{ joint = "WingR", rot = { 0.429, 171.49, 87.106 }, material = "Neon", studs = false }
		),
		P("PrismR6Aa", { 0.22, 0.774, 0.522 }, { 3.216, 8.956, 1.224 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { 90, -17.526, 98.562 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR6Ab", { 0.22, 0.774, 0.523 }, { 3.058, 8.458, 1.224 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -90, 17.526, 81.438 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR6Ba", { 0.22, 0.996, 1.41 }, { 4.357, 8.596, 1.404 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -1.924, -98.163, 0.666 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("PrismR6Bb", { 0.22, 0.996, 0.316 }, { 3.502, 8.591, 1.281 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -1.923, 81.837, -0.666 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"PrismR6Core",
			{ 0.088, 1.756, 0.286 },
			{ 3.724, 8.521, 1.316 },
			rgb(255, 184, 138),
			{ joint = "WingR", rot = { 177.404, 8.162, -72.289 }, material = "Neon", studs = false }
		),
		P("InnerPrismR1Aa", { 0.22, 0.598, 0.385 }, { 2.816, 9.334, 0.922 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { 90, 73.301, 92.742 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR1Ab", { 0.22, 0.598, 0.385 }, { 3.185, 9.223, 0.922 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { -90, -73.301, 87.258 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR1Ba", { 0.22, 0.737, 0.223 }, { 3.087, 9.565, 0.936 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { -86.852, 33.522, -90.945 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR1Bb", { 0.22, 0.737, 1.105 }, { 3.454, 10.118, 0.967 }, rgb(255, 229, 122), {
			joint = "WingR",
			rot = { 93.148, -33.522, -89.055 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismR1Core",
			{ 0.088, 1.327, 0.286 },
			{ 3.143, 9.753, 0.946 },
			rgb(255, 229, 122),
			{ joint = "WingR", rot = { 2.626, 179.212, 16.681 }, material = "Neon", studs = false }
		),
		P("InnerPrismR2Aa", { 0.22, 0.667, 0.384 }, { 3.182, 9.459, 0.92 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 95.749, -67.725, 94.069 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR2Ab", { 0.22, 0.667, 0.388 }, { 2.825, 9.314, 0.906 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { -84.251, 67.725, 85.931 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR2Ba", { 0.22, 0.743, 0.201 }, { 3.182, 9.459, 0.92 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { -85.973, 52.978, -92.56 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR2Bb", { 0.22, 0.743, 1.271 }, { 3.77, 9.902, 0.951 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 94.027, -52.978, -87.44 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismR2Core",
			{ 0.088, 1.498, 0.286 },
			{ 3.312, 9.627, 0.93 },
			rgb(181, 155, 255),
			{ joint = "WingR", rot = { 1.983, 178.459, 37.848 }, material = "Neon", studs = false }
		),
		P("InnerPrismR3Aa", { 0.22, 0.667, 0.384 }, { 3.22, 9.183, 0.906 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 43.511, -93.187, 42.224 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR3Ab", { 0.22, 0.667, 0.388 }, { 2.835, 9.197, 0.89 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 43.511, 86.813, -42.224 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR3Ba", { 0.22, 0.743, 0.201 }, { 3.22, 9.183, 0.906 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { -78.343, 77.158, -100.675 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR3Bb", { 0.22, 0.743, 1.271 }, { 3.938, 9.343, 0.939 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 101.656, -77.158, -79.325 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismR3Core",
			{ 0.088, 1.498, 0.286 },
			{ 3.408, 9.281, 0.915 },
			rgb(127, 240, 207),
			{ joint = "WingR", rot = { 1.243, 177.64, 62.216 }, material = "Neon", studs = false }
		),
		P("InnerPrismR4Aa", { 0.22, 0.563, 0.385 }, { 2.757, 9.017, 0.872 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { 90, 2.862, 92.859 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR4Ab", { 0.22, 0.563, 0.385 }, { 2.777, 8.633, 0.872 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -90, -2.862, 87.141 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR4Ba", { 0.22, 0.733, 0.236 }, { 3.048, 8.839, 0.886 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { 79.587, 74.77, 100.931 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR4Bb", { 0.22, 0.733, 1.021 }, { 3.654, 8.677, 0.916 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -100.413, -74.77, 79.069 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismR4Core",
			{ 0.088, 1.241, 0.286 },
			{ 3.237, 8.849, 0.896 },
			rgb(255, 184, 138),
			{ joint = "WingR", rot = { 0.143, 177.145, 87.134 }, material = "Neon", studs = false }
		),
		P("InnerPrismR5Aa", { 0.22, 0.493, 0.385 }, { 2.648, 8.82, 0.855 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { 90, -25.201, 93.047 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR5Ab", { 0.22, 0.493, 0.385 }, { 2.484, 8.472, 0.855 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { -90, 25.201, 86.953 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR5Ba", { 0.22, 0.723, 0.85 }, { 3.343, 8.493, 0.896 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { 60.13, -95.749, 61.307 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("InnerPrismR5Bb", { 0.22, 0.723, 0.266 }, { 2.788, 8.541, 0.868 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { 60.13, 84.251, -61.307 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"InnerPrismR5Core",
			{ 0.088, 1.069, 0.286 },
			{ 2.945, 8.467, 0.877 },
			rgb(255, 143, 203),
			{ joint = "WingR", rot = { 178.702, 2.756, -64.768 }, material = "Neon", studs = false }
		),
		P("LowPrismR1Aa", { 0.22, 0.765, 0.456 }, { 2.313, 7.935, 1.172 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 57.699, 72.453, 115.759 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR1Ab", { 0.22, 0.765, 0.435 }, { 2.738, 7.822, 1.243 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { -122.301, -72.453, 64.241 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR1Ba", { 0.22, 0.85, 1.476 }, { 3.465, 7.406, 1.396 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 69.88, -121.358, 75.417 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR1Bb", { 0.22, 0.85, 0.227 }, { 2.738, 7.822, 1.243 }, rgb(181, 155, 255), {
			joint = "WingR",
			rot = { 69.88, 58.642, -75.417 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismR1Core",
			{ 0.088, 1.756, 0.286 },
			{ 2.902, 7.658, 1.287 },
			rgb(181, 155, 255),
			{ joint = "WingR", rot = { 172.405, 7.529, -44.5 }, material = "Neon", studs = false }
		),
		P("LowPrismR2Aa", { 0.22, 0.78, 0.407 }, { 2.141, 7.339, 1.141 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { -98.987, 1.302, -94.518 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR2Ab", { 0.22, 0.78, 0.546 }, { 2.152, 7.809, 1.067 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 81.013, -1.302, -85.482 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR2Ba", { 0.22, 0.855, 0.209 }, { 2.141, 7.339, 1.141 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { 79.915, 12.395, 94.625 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR2Bb", { 0.22, 0.855, 1.639 }, { 2.339, 6.45, 1.299 }, rgb(127, 240, 207), {
			joint = "WingR",
			rot = { -100.085, -12.395, 85.375 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismR2Core",
			{ 0.088, 1.927, 0.286 },
			{ 2.251, 7.118, 1.185 },
			rgb(127, 240, 207),
			{ joint = "WingR", rot = { 170.91, 4.517, -26.206 }, material = "Neon", studs = false }
		),
		P("LowPrismR3Aa", { 0.22, 0.704, 0.44 }, { 1.635, 7.524, 0.951 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { 90, -75.964, 100.981 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR3Ab", { 0.22, 0.704, 0.44 }, { 1.208, 7.417, 0.951 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -90, 75.964, 79.019 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR3Ba", { 0.22, 0.844, 0.248 }, { 1.505, 7.135, 1.018 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { 79.46, -2.598, 92.651 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR3Bb", { 0.22, 0.844, 1.311 }, { 1.47, 6.369, 1.161 }, rgb(255, 184, 138), {
			joint = "WingR",
			rot = { -100.54, 2.598, 87.349 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismR3Core",
			{ 0.088, 1.584, 0.286 },
			{ 1.558, 6.926, 1.06 },
			rgb(255, 184, 138),
			{ joint = "WingR", rot = { 169.34, 2.648, -13.789 }, material = "Neon", studs = false }
		),
		P("LowPrismR4Aa", { 0.22, 0.563, 0.44 }, { 1.14, 7.264, 0.832 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { -90, -92.862, -78.704 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR4Ab", { 0.22, 0.563, 0.44 }, { 0.7, 7.242, 0.832 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { -90, 87.138, 78.704 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR4Ba", { 0.22, 0.826, 0.304 }, { 0.934, 6.977, 0.887 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { 78.893, -17.378, 90.587 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("LowPrismR4Bb", { 0.22, 0.826, 0.971 }, { 0.744, 6.38, 1.004 }, rgb(255, 143, 203), {
			joint = "WingR",
			rot = { -101.107, 17.378, 89.413 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"LowPrismR4Core",
			{ 0.088, 1.241, 0.286 },
			{ 0.943, 6.791, 0.924 },
			rgb(255, 143, 203),
			{ joint = "WingR", rot = { 168.718, 0.56, -2.807 }, material = "Neon", studs = false }
		),
		P(
			"HubOrbit",
			{ 0.22, 0.22, 0.22 },
			{ 0, 5.72, 0 },
			MAIN,
			{ joint = "Orbit", rot = { 0, 180, 0 }, transparency = 1, studs = false }
		),
		P("Shard1Aa", { 0.22, 0.761, 0.534 }, { 4.054, 5.907, 1.041 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 62.995, 174.741, -10.196 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard1Ab", { 0.22, 0.761, 0.396 }, { 4.097, 6.32, 0.83 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 62.995, -5.259, 10.196 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard1Ba", { 0.22, 0.761, 0.396 }, { 4.097, 6.32, 0.83 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { -62.995, -5.259, 169.804 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard1Bb", { 0.22, 0.761, 0.534 }, { 4.054, 6.732, 1.041 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 117.005, 5.259, 10.196 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard1Core",
			{ 0.088, 1.155, 0.286 },
			{ 4.097, 6.204, 0.83 },
			rgb(255, 143, 203),
			{ joint = "Orbit", rot = { 0, 78.541, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar21b",
			{ 0.132, 0.129, 0.311 },
			{ 3.43, 6.576, 2.394 },
			GOLD,
			{ joint = "Orbit", rot = { 14.09, -36.334, 8.459 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar22b",
			{ 0.132, 0.129, 0.311 },
			{ 3.311, 6.708, 2.552 },
			GOLD,
			{ joint = "Orbit", rot = { 99.055, 6.805, 36.634 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar23b",
			{ 0.132, 0.129, 0.311 },
			{ 3.231, 6.51, 2.657 },
			GOLD,
			{ joint = "Orbit", rot = { -165.91, 36.334, -8.459 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar24b",
			{ 0.132, 0.129, 0.311 },
			{ 3.351, 6.378, 2.499 },
			GOLD,
			{ joint = "Orbit", rot = { -80.945, -6.805, -36.634 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar2Core",
			{ 0.145, 0.145, 0.172 },
			{ 3.331, 6.543, 2.526 },
			GLOW,
			{ joint = "Orbit", rot = { 0, 52.827, 45 }, studs = false }
		),
		P("Shard3Aa", { 0.22, 0.761, 0.534 }, { 1.714, 6.557, 3.818 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { -103.332, 24.246, 119.988 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard3Ab", { 0.22, 0.761, 0.396 }, { 1.905, 6.969, 3.721 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { 76.668, -24.246, 60.012 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard3Ba", { 0.22, 0.761, 0.396 }, { 1.905, 6.969, 3.721 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { -76.668, -24.246, 119.988 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard3Bb", { 0.22, 0.761, 0.534 }, { 1.714, 7.382, 3.818 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { 103.332, 24.246, 60.012 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard3Core",
			{ 0.088, 1.155, 0.286 },
			{ 1.905, 6.854, 3.721 },
			rgb(255, 229, 122),
			{ joint = "Orbit", rot = { 0, 27.112, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar41b",
			{ 0.132, 0.129, 0.311 },
			{ 0.267, 5.168, 4.175 },
			GOLD,
			{ joint = "Orbit", rot = { 83.045, -78.605, 82.906 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar42b",
			{ 0.132, 0.129, 0.311 },
			{ 0.069, 5.3, 4.18 },
			GOLD,
			{ joint = "Orbit", rot = { 90.28, 11.307, 88.574 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar43b",
			{ 0.132, 0.129, 0.311 },
			{ -0.063, 5.102, 4.183 },
			GOLD,
			{ joint = "Orbit", rot = { -96.955, 78.605, -82.906 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar44a",
			{ 0.132, 0.129, 0.311 },
			{ 0.069, 4.97, 4.18 },
			GOLD,
			{ joint = "Orbit", rot = { -90.28, 11.307, 91.426 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar4Core",
			{ 0.145, 0.145, 0.172 },
			{ 0.102, 5.135, 4.179 },
			GLOW,
			{ joint = "Orbit", rot = { 0, 1.398, 45 }, studs = false }
		),
		P("Shard5Aa", { 0.22, 0.761, 0.534 }, { -1.917, 4.152, 3.721 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { -77.914, 24.861, 63.01 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard5Ab", { 0.22, 0.761, 0.396 }, { -1.721, 4.564, 3.809 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { 102.086, -24.861, 116.99 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard5Ba", { 0.22, 0.761, 0.396 }, { -1.721, 4.564, 3.809 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { -102.086, -24.861, 63.01 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard5Bb", { 0.22, 0.761, 0.534 }, { -1.917, 4.977, 3.721 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { 77.914, 24.861, 116.99 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard5Core",
			{ 0.088, 1.155, 0.286 },
			{ -1.721, 4.449, 3.809 },
			rgb(127, 240, 207),
			{ joint = "Orbit", rot = { 0, -24.316, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar61b",
			{ 0.132, 0.129, 0.311 },
			{ -3.098, 3.577, 2.812 },
			GOLD,
			{ joint = "Orbit", rot = { -14.626, -140.957, -9.335 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar62b",
			{ 0.132, 0.129, 0.311 },
			{ -3.225, 3.709, 2.66 },
			GOLD,
			{ joint = "Orbit", rot = { 81.286, 7.237, 140.583 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar63b",
			{ 0.132, 0.129, 0.311 },
			{ -3.309, 3.511, 2.559 },
			GOLD,
			{ joint = "Orbit", rot = { -14.626, 39.043, -170.665 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar64b",
			{ 0.132, 0.129, 0.311 },
			{ -3.182, 3.379, 2.71 },
			GOLD,
			{ joint = "Orbit", rot = { -98.714, -7.237, -140.583 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar6Core",
			{ 0.145, 0.145, 0.172 },
			{ -3.203, 3.544, 2.685 },
			GLOW,
			{ joint = "Orbit", rot = { 0, -50.031, 45 }, studs = false }
		),
		P("Shard7Aa", { 0.22, 0.761, 0.534 }, { -4.104, 4.572, 0.821 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { -63.252, 6.523, 12.703 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard7Ab", { 0.22, 0.761, 0.396 }, { -4.051, 4.985, 1.029 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { -63.252, -173.477, -12.703 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard7Ba", { 0.22, 0.761, 0.396 }, { -4.051, 4.985, 1.029 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { -116.748, -6.523, 12.703 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard7Bb", { 0.22, 0.761, 0.534 }, { -4.104, 5.397, 0.821 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 63.252, 6.523, 167.297 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard7Core",
			{ 0.088, 1.155, 0.286 },
			{ -4.051, 4.869, 1.029 },
			rgb(255, 143, 203),
			{ joint = "Orbit", rot = { 0, -75.745, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar81b",
			{ 0.132, 0.129, 0.311 },
			{ -4.129, 5.693, -0.669 },
			GOLD,
			{ joint = "Orbit", rot = { -11.534, 168.766, 2.277 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar82b",
			{ 0.132, 0.129, 0.311 },
			{ -4.09, 5.825, -0.863 },
			GOLD,
			{ joint = "Orbit", rot = { 78.91, -2.233, -168.758 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar83b",
			{ 0.132, 0.129, 0.311 },
			{ -4.064, 5.627, -0.992 },
			GOLD,
			{ joint = "Orbit", rot = { -11.534, -11.234, 177.723 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar84b",
			{ 0.132, 0.129, 0.311 },
			{ -4.103, 5.495, -0.798 },
			GOLD,
			{ joint = "Orbit", rot = { 78.91, 177.767, -11.242 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar8Core",
			{ 0.145, 0.145, 0.172 },
			{ -4.097, 5.66, -0.83 },
			GLOW,
			{ joint = "Orbit", rot = { 0, -101.459, 45 }, studs = false }
		),
		P("Shard9Aa", { 0.22, 0.761, 0.534 }, { -3.201, 6.79, -2.697 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { -67.494, -16.186, -33.932 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard9Ab", { 0.22, 0.761, 0.396 }, { -3.331, 7.203, -2.526 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { -67.494, 163.814, 33.932 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard9Ba", { 0.22, 0.761, 0.396 }, { -3.331, 7.203, -2.526 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { -112.506, 16.186, -33.932 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard9Bb", { 0.22, 0.761, 0.534 }, { -3.201, 7.615, -2.697 }, rgb(255, 229, 122), {
			joint = "Orbit",
			rot = { 67.494, -16.186, -146.068 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard9Core",
			{ 0.088, 1.155, 0.286 },
			{ -3.331, 7.087, -2.526 },
			rgb(255, 229, 122),
			{ joint = "Orbit", rot = { 0, -127.173, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar101b",
			{ 0.132, 0.129, 0.311 },
			{ -2.052, 6.342, -3.645 },
			GOLD,
			{ joint = "Orbit", rot = { -23.694, 119.211, 20.959 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar102b",
			{ 0.132, 0.129, 0.311 },
			{ -1.876, 6.474, -3.736 },
			GOLD,
			{ joint = "Orbit", rot = { 84.792, -10.053, -117.571 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar103b",
			{ 0.132, 0.129, 0.311 },
			{ -1.758, 6.276, -3.796 },
			GOLD,
			{ joint = "Orbit", rot = { -23.694, -60.789, 159.041 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar104b",
			{ 0.132, 0.129, 0.311 },
			{ -1.934, 6.144, -3.706 },
			GOLD,
			{ joint = "Orbit", rot = { -95.208, 10.053, 117.571 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar10Core",
			{ 0.145, 0.145, 0.172 },
			{ -1.905, 6.309, -3.721 },
			GLOW,
			{ joint = "Orbit", rot = { 0, -152.888, 45 }, studs = false }
		),
		P("Shard11Aa", { 0.22, 0.761, 0.534 }, { 0.112, 5.383, -4.184 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { -89.273, -27.466, -88.424 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard11Ab", { 0.22, 0.761, 0.396 }, { -0.102, 5.795, -4.179 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { 90.727, 27.466, -91.576 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard11Ba", { 0.22, 0.761, 0.396 }, { -0.102, 5.795, -4.179 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { -90.727, 27.466, -88.424 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard11Bb", { 0.22, 0.761, 0.534 }, { 0.112, 6.208, -4.184 }, rgb(127, 240, 207), {
			joint = "Orbit",
			rot = { 89.273, -27.466, -91.576 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard11Core",
			{ 0.088, 1.155, 0.286 },
			{ -0.102, 5.68, -4.179 },
			rgb(127, 240, 207),
			{ joint = "Orbit", rot = { 0, -178.602, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar121b",
			{ 0.132, 0.129, 0.311 },
			{ 1.571, 3.937, -3.877 },
			GOLD,
			{ joint = "Orbit", rot = { 25.906, 63.328, -23.462 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar122b",
			{ 0.132, 0.129, 0.311 },
			{ 1.751, 4.069, -3.796 },
			GOLD,
			{ joint = "Orbit", rot = { 94.708, -10.295, -65.259 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar123b",
			{ 0.132, 0.129, 0.311 },
			{ 1.872, 3.871, -3.741 },
			GOLD,
			{ joint = "Orbit", rot = { -154.094, -63.328, 23.462 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar124b",
			{ 0.132, 0.129, 0.311 },
			{ 1.691, 3.739, -3.823 },
			GOLD,
			{ joint = "Orbit", rot = { -85.292, 10.295, 65.259 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar12Core",
			{ 0.145, 0.145, 0.172 },
			{ 1.721, 3.904, -3.809 },
			GLOW,
			{ joint = "Orbit", rot = { 0, 155.684, 45 }, studs = false }
		),
		P("Shard13Aa", { 0.22, 0.761, 0.534 }, { 3.341, 3.791, -2.521 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 68.272, -162.761, 36.637 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard13Ab", { 0.22, 0.761, 0.396 }, { 3.203, 4.204, -2.685 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 68.272, 17.239, -36.637 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard13Ba", { 0.22, 0.761, 0.396 }, { 3.203, 4.204, -2.685 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { -68.272, 17.239, -143.363 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P("Shard13Bb", { 0.22, 0.761, 0.534 }, { 3.341, 4.616, -2.521 }, rgb(255, 143, 203), {
			joint = "Orbit",
			rot = { 111.728, -17.239, -36.637 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"Shard13Core",
			{ 0.088, 1.155, 0.286 },
			{ 3.203, 4.088, -2.685 },
			rgb(255, 143, 203),
			{ joint = "Orbit", rot = { 0, 129.969, 0 }, material = "Neon", studs = false }
		),
		P(
			"FloatStar141b",
			{ 0.132, 0.129, 0.311 },
			{ 4.011, 4.358, -1.189 },
			GOLD,
			{ joint = "Orbit", rot = { 11.66, 13.973, -2.852 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar142b",
			{ 0.132, 0.129, 0.311 },
			{ 4.059, 4.49, -0.997 },
			GOLD,
			{ joint = "Orbit", rot = { 100.97, -2.768, -13.989 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar143b",
			{ 0.132, 0.129, 0.311 },
			{ 4.092, 4.292, -0.869 },
			GOLD,
			{ joint = "Orbit", rot = { -168.34, -13.973, 2.852 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar144b",
			{ 0.132, 0.129, 0.311 },
			{ 4.043, 4.16, -1.061 },
			GOLD,
			{ joint = "Orbit", rot = { -79.03, 2.768, 13.989 }, shape = "Wedge", studs = false }
		),
		P(
			"FloatStar14Core",
			{ 0.145, 0.145, 0.172 },
			{ 4.051, 4.325, -1.029 },
			GLOW,
			{ joint = "Orbit", rot = { 0, 104.255, 45 }, studs = false }
		),
	},
}

return { egg = egg, pet = pet }
