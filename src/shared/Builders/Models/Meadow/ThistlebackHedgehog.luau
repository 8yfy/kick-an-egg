--!strict
-- Thistleback Hedgehog (Zone 1 Meadow, Epic). Zone 1 Meadow roster (Config/Pets).
-- Pet: a round brown hedgehog with a tan face, snout and belly, a determined look, big round ears, a dome coat of
--      layered green leaf plates with long cream thorn cones, brown vines with red berries and white flowers, short
--      legs wrapped in root bands, cream toes. Joints: Body, Quills, Head, ArmL/R, LegL/R.
-- Egg: a tan egg under green leaf plates and a brown vine net, cream thorns, white flowers and red berries.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/thistleback_hedgehog.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(122, 74, 38) -- #7A4A26
local MAIN2 = rgb(106, 62, 31) -- #6A3E1F
local DARK = rgb(78, 46, 22) -- #4E2E16
local LIGHT = rgb(232, 192, 138) -- #E8C08A
local GLOW = rgb(255, 224, 102) -- #FFE066
local LEAF = rgb(79, 168, 58) -- #4FA83A
local LEAF2 = rgb(108, 194, 58) -- #6CC23A
local LEAF4 = rgb(46, 122, 42) -- #2E7A2A
local VINE = rgb(122, 74, 38) -- #7A4A26
local THORN = rgb(244, 217, 156) -- #F4D99C
local THORN2 = rgb(232, 194, 122) -- #E8C27A
local BERRY = rgb(216, 40, 58) -- #D8283A
local BERRY2 = rgb(240, 74, 85) -- #F04A55
local FLOWER = rgb(255, 255, 255) -- #FFFFFF
local FLOWER2 = rgb(242, 242, 234) -- #F2F2EA
local POLLEN = rgb(255, 201, 60) -- #FFC93C
local TAN = rgb(232, 192, 138) -- #E8C08A
local TAN2 = rgb(217, 172, 114) -- #D9AC72
local CREAM = rgb(242, 226, 194) -- #F2E2C2
local LEAF3 = rgb(143, 212, 74) -- #8FD44A
local NOSE = rgb(42, 26, 18) -- #2A1A12
local EYE = rgb(255, 255, 255) -- #FFFFFF
local INK = rgb(26, 15, 8) -- #1A0F08
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.741, 0.525, 1.741 }, { 0, 0.262, 0 }, rgb(240, 210, 154), { joint = "Body" }),
		P("Shell2", { 2.72, 0.525, 2.72 }, { 0, 0.788, 0 }, rgb(226, 190, 126), { joint = "Body" }),
		P("Shell3", { 3.126, 0.525, 3.126 }, { 0, 1.312, 0 }, rgb(240, 210, 154), { joint = "Body" }),
		P("Shell4", { 3.234, 0.525, 3.234 }, { 0, 1.837, 0 }, rgb(226, 190, 126), { joint = "Body" }),
		P("Shell5", { 3.123, 0.525, 3.123 }, { 0, 2.362, 0 }, rgb(240, 210, 154), { joint = "Body" }),
		P("Shell6", { 2.814, 0.525, 2.814 }, { 0, 2.888, 0 }, rgb(226, 190, 126), { joint = "Body" }),
		P("Shell7", { 2.282, 0.525, 2.282 }, { 0, 3.412, 0 }, rgb(240, 210, 154), { joint = "Body" }),
		P("Shell8", { 1.361, 0.525, 1.361 }, { 0, 3.938, 0 }, rgb(226, 190, 126), { joint = "Body" }),
		P(
			"RarityBand",
			{ 2.88, 0.18, 2.88 },
			{ 0, 0.85, 0 },
			rgb(170, 85, 255),
			{ joint = "Body", material = "Neon", studs = false }
		),
		P(
			"PlateLeaf1a",
			{ 0.14, 1.299, 0.75 },
			{ 0, 3.9, -1.221 },
			LEAF2,
			{ joint = "Body", rot = { 90, -29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf1b",
			{ 0.14, 1.299, 0.751 },
			{ -0.375, 3.25, -1.221 },
			LEAF2,
			{ joint = "Body", rot = { -90, 29.982, 90 }, shape = "Wedge", studs = false }
		),
		P("PlateVein1", { 0.07, 0.91, 0.06 }, { 0, 3.25, -1.301 }, LEAF4, { joint = "Body", studs = false }),
		P(
			"PlateLeaf2a",
			{ 0.14, 1.299, 0.751 },
			{ 1.221, 3.25, 0.375 },
			LEAF4,
			{ joint = "Body", rot = { 60.018, 180, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf2b",
			{ 0.14, 1.299, 0.75 },
			{ 1.221, 3.9, 0 },
			LEAF4,
			{ joint = "Body", rot = { 60.018, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein2",
			{ 0.07, 0.91, 0.06 },
			{ 1.301, 3.25, 0 },
			LEAF4,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateLeaf3a",
			{ 0.14, 1.299, 0.751 },
			{ -0.375, 3.25, 1.221 },
			LEAF,
			{ joint = "Body", rot = { -90, 29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf3b",
			{ 0.14, 1.299, 0.75 },
			{ 0, 3.9, 1.221 },
			LEAF,
			{ joint = "Body", rot = { 90, -29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein3",
			{ 0.07, 0.91, 0.06 },
			{ 0, 3.25, 1.301 },
			LEAF4,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateLeaf4a",
			{ 0.14, 1.299, 0.751 },
			{ -1.221, 3.25, -0.375 },
			LEAF2,
			{ joint = "Body", rot = { -60.018, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf4b",
			{ 0.14, 1.299, 0.75 },
			{ -1.221, 3.9, 0 },
			LEAF2,
			{ joint = "Body", rot = { -60.018, 180, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein4",
			{ 0.07, 0.91, 0.06 },
			{ -1.301, 3.25, 0 },
			LEAF4,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"PlateLeaf5a",
			{ 0.14, 1.299, 0.751 },
			{ 1.642, 2.35, -0.987 },
			LEAF4,
			{ joint = "Body", rot = { 119.982, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf5b",
			{ 0.14, 1.299, 0.75 },
			{ 1.642, 1.7, -1.362 },
			LEAF4,
			{ joint = "Body", rot = { -60.018, 0, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein5",
			{ 0.07, 0.91, 0.06 },
			{ 1.722, 2.35, -1.362 },
			LEAF4,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateLeaf6a",
			{ 0.14, 1.299, 0.751 },
			{ 0.987, 2.35, 1.642 },
			LEAF,
			{ joint = "Body", rot = { 90, 29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf6b",
			{ 0.14, 1.299, 0.75 },
			{ 1.362, 1.7, 1.642 },
			LEAF,
			{ joint = "Body", rot = { -90, -29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein6",
			{ 0.07, 0.91, 0.06 },
			{ 1.362, 2.35, 1.722 },
			LEAF4,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateLeaf7a",
			{ 0.14, 1.299, 0.751 },
			{ -1.642, 2.35, 0.987 },
			LEAF2,
			{ joint = "Body", rot = { 60.018, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf7b",
			{ 0.14, 1.299, 0.75 },
			{ -1.642, 1.7, 1.362 },
			LEAF2,
			{ joint = "Body", rot = { -119.982, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein7",
			{ 0.07, 0.91, 0.06 },
			{ -1.722, 2.35, 1.362 },
			LEAF4,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"PlateLeaf8a",
			{ 0.14, 1.299, 0.75 },
			{ -1.362, 1.7, -1.642 },
			LEAF4,
			{ joint = "Body", rot = { -90, -29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf8b",
			{ 0.14, 1.299, 0.751 },
			{ -1.737, 2.35, -1.642 },
			LEAF4,
			{ joint = "Body", rot = { 90, 29.982, 90 }, shape = "Wedge", studs = false }
		),
		P("PlateVein8", { 0.07, 0.91, 0.06 }, { -1.362, 2.35, -1.722 }, LEAF4, { joint = "Body", studs = false }),
		P(
			"PlateLeaf9a",
			{ 0.14, 1.299, 0.75 },
			{ 0, 0.9, -1.643 },
			LEAF,
			{ joint = "Body", rot = { -90, -29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf9b",
			{ 0.14, 1.299, 0.751 },
			{ -0.375, 1.55, -1.643 },
			LEAF,
			{ joint = "Body", rot = { 90, 29.982, 90 }, shape = "Wedge", studs = false }
		),
		P("PlateVein9", { 0.07, 0.91, 0.06 }, { 0, 1.55, -1.723 }, LEAF4, { joint = "Body", studs = false }),
		P(
			"PlateLeaf10a",
			{ 0.14, 1.299, 0.751 },
			{ 1.643, 1.55, 0.375 },
			LEAF2,
			{ joint = "Body", rot = { 119.982, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf10b",
			{ 0.14, 1.299, 0.75 },
			{ 1.643, 0.9, 0 },
			LEAF2,
			{ joint = "Body", rot = { -60.018, 0, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein10",
			{ 0.07, 0.91, 0.06 },
			{ 1.723, 1.55, 0 },
			LEAF4,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateLeaf11a",
			{ 0.14, 1.299, 0.751 },
			{ -0.375, 1.55, 1.643 },
			LEAF4,
			{ joint = "Body", rot = { 90, 29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf11b",
			{ 0.14, 1.299, 0.75 },
			{ 0, 0.9, 1.643 },
			LEAF4,
			{ joint = "Body", rot = { -90, -29.982, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein11",
			{ 0.07, 0.91, 0.06 },
			{ 0, 1.55, 1.723 },
			LEAF4,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateLeaf12a",
			{ 0.14, 1.299, 0.751 },
			{ -1.643, 1.55, -0.375 },
			LEAF,
			{ joint = "Body", rot = { 60.018, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateLeaf12b",
			{ 0.14, 1.299, 0.75 },
			{ -1.643, 0.9, 0 },
			LEAF,
			{ joint = "Body", rot = { -119.982, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"PlateVein12",
			{ 0.07, 0.91, 0.06 },
			{ -1.723, 1.55, 0 },
			LEAF4,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Vine1_1",
			{ 0.22, 1.181, 0.22 },
			{ -0.535, 1.25, -1.569 },
			VINE,
			{ joint = "Body", rot = { -12.321, 6.761, -28.324 }, studs = false }
		),
		P(
			"Vine1_2",
			{ 0.22, 1.212, 0.22 },
			{ -0.593, 2.15, -1.669 },
			VINE,
			{ joint = "Body", rot = { 2.409, 1.649, 34.373 }, studs = false }
		),
		P(
			"Vine1_3",
			{ 0.22, 1.328, 0.22 },
			{ -0.501, 3, -1.431 },
			VINE,
			{ joint = "Body", rot = { 14.693, -14.262, -43.214 }, studs = false }
		),
		P(
			"Vine1_4",
			{ 0.22, 0.883, 0.22 },
			{ 0.074, 3.65, -0.991 },
			VINE,
			{ joint = "Body", rot = { 31.844, -20.139, -29.002 }, studs = false }
		),
		P(
			"Vine2_1",
			{ 0.22, 1.508, 0.22 },
			{ 1.286, 1.4, -1.241 },
			VINE,
			{ joint = "Body", rot = { -39.801, -11.138, 13.053 }, studs = false }
		),
		P(
			"Vine2_2",
			{ 0.22, 1.502, 0.22 },
			{ 1.31, 2.4, -1.255 },
			VINE,
			{ joint = "Body", rot = { 38.165, -12.363, -15.238 }, studs = false }
		),
		P(
			"Vine2_3",
			{ 0.22, 1.097, 0.22 },
			{ 1.214, 3.25, -1.017 },
			VINE,
			{ joint = "Body", rot = { -19.953, -14.904, 35.317 }, studs = false }
		),
		P(
			"Vine3_1",
			{ 0.22, 1.337, 0.22 },
			{ 0.463, 1.3, 1.569 },
			VINE,
			{ joint = "Body", rot = { 10.309, 6.571, 32.175 }, studs = false }
		),
		P(
			"Vine3_2",
			{ 0.22, 1.262, 0.22 },
			{ 0.477, 2.25, 1.592 },
			VINE,
			{ joint = "Body", rot = { -8.535, 6.313, -36.231 }, studs = false }
		),
		P(
			"Vine3_3",
			{ 0.22, 1.291, 0.22 },
			{ 0.406, 3.1, 1.354 },
			VINE,
			{ joint = "Body", rot = { -9.296, -9.316, 44.681 }, studs = false }
		),
		P(
			"Vine4_1",
			{ 0.22, 1.582, 0.22 },
			{ -1.286, 1.45, 1.241 },
			VINE,
			{ joint = "Body", rot = { 37.56, -9.673, -12.325 }, studs = false }
		),
		P(
			"Vine4_2",
			{ 0.22, 1.606, 0.22 },
			{ -1.31, 2.5, 1.177 },
			VINE,
			{ joint = "Body", rot = { -42.76, -13.54, 14.208 }, studs = false }
		),
		P(
			"Vine4_3",
			{ 0.22, 1.41, 0.22 },
			{ -0.984, 3.4, 0.708 },
			VINE,
			{ joint = "Body", rot = { 2.892, -3.633, -51.431 }, studs = false }
		),
		P(
			"Thorn1",
			{ 0.44, 0.42, 0.44 },
			{ -1.417, 2.069, -1.815 },
			THORN,
			{ joint = "Body", rot = { -70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn1Mid",
			{ 0.308, 0.36, 0.308 },
			{ -1.417, 2.182, -2.136 },
			THORN,
			{ joint = "Body", rot = { -70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn1Tip",
			{ 0.176, 0.3, 0.176 },
			{ -1.417, 2.277, -2.41 },
			THORN2,
			{ joint = "Body", rot = { -70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn2",
			{ 0.44, 0.446, 0.44 },
			{ 1.618, 2.874, -1.207 },
			THORN,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn2Mid",
			{ 0.308, 0.382, 0.308 },
			{ 1.959, 2.993, -1.207 },
			THORN,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn2Tip",
			{ 0.176, 0.319, 0.176 },
			{ 2.249, 3.095, -1.207 },
			THORN2,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn3",
			{ 0.44, 0.42, 0.44 },
			{ 1.815, 1.769, 0.285 },
			THORN,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn3Mid",
			{ 0.308, 0.36, 0.308 },
			{ 2.136, 1.882, 0.285 },
			THORN,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn3Tip",
			{ 0.176, 0.3, 0.176 },
			{ 2.41, 1.977, 0.285 },
			THORN2,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn4",
			{ 0.44, 0.446, 0.44 },
			{ 0.512, 2.974, 1.618 },
			THORN,
			{ joint = "Body", rot = { 70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn4Mid",
			{ 0.308, 0.383, 0.308 },
			{ 0.512, 3.093, 1.959 },
			THORN,
			{ joint = "Body", rot = { 70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn4Tip",
			{ 0.176, 0.319, 0.176 },
			{ 0.512, 3.195, 2.249 },
			THORN2,
			{ joint = "Body", rot = { 70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn5",
			{ 0.44, 0.42, 0.44 },
			{ -0.934, 1.969, 1.815 },
			THORN,
			{ joint = "Body", rot = { 70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn5Mid",
			{ 0.308, 0.36, 0.308 },
			{ -0.934, 2.082, 2.136 },
			THORN,
			{ joint = "Body", rot = { 70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn5Tip",
			{ 0.176, 0.3, 0.176 },
			{ -0.934, 2.177, 2.41 },
			THORN2,
			{ joint = "Body", rot = { 70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn6",
			{ 0.44, 0.446, 0.44 },
			{ -1.618, 2.774, -0.248 },
			THORN,
			{ joint = "Body", rot = { -43.346, 13.509, 76.099 }, studs = false }
		),
		P(
			"Thorn6Mid",
			{ 0.308, 0.382, 0.308 },
			{ -1.959, 2.893, -0.248 },
			THORN,
			{ joint = "Body", rot = { -43.346, 13.509, 76.099 }, studs = false }
		),
		P(
			"Thorn6Tip",
			{ 0.176, 0.319, 0.176 },
			{ -2.249, 2.995, -0.248 },
			THORN2,
			{ joint = "Body", rot = { -43.346, 13.509, 76.099 }, studs = false }
		),
		P(
			"Thorn7",
			{ 0.44, 0.472, 0.44 },
			{ 0, 3.978, -0.904 },
			THORN,
			{ joint = "Body", rot = { -70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn7Mid",
			{ 0.308, 0.405, 0.308 },
			{ 0, 4.104, -1.265 },
			THORN,
			{ joint = "Body", rot = { -70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn7Tip",
			{ 0.176, 0.338, 0.176 },
			{ 0, 4.212, -1.572 },
			THORN2,
			{ joint = "Body", rot = { -70.71, 135, 0 }, studs = false }
		),
		P(
			"Thorn8",
			{ 0.44, 0.394, 0.44 },
			{ 1.327, 3.665, 0.659 },
			THORN,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn8Mid",
			{ 0.308, 0.338, 0.308 },
			{ 1.628, 3.77, 0.659 },
			THORN,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn8Tip",
			{ 0.176, 0.281, 0.176 },
			{ 1.884, 3.86, 0.659 },
			THORN2,
			{ joint = "Body", rot = { 43.346, 13.509, -76.099 }, studs = false }
		),
		P(
			"Thorn9",
			{ 0.44, 0.394, 0.44 },
			{ -0.866, 3.765, -0.393 },
			THORN,
			{ joint = "Body", rot = { -43.346, 13.509, 76.099 }, studs = false }
		),
		P(
			"Thorn9Mid",
			{ 0.308, 0.338, 0.308 },
			{ -1.167, 3.87, -0.393 },
			THORN,
			{ joint = "Body", rot = { -43.346, 13.509, 76.099 }, studs = false }
		),
		P(
			"Thorn9Tip",
			{ 0.176, 0.281, 0.176 },
			{ -1.424, 3.96, -0.393 },
			THORN2,
			{ joint = "Body", rot = { -43.346, 13.509, 76.099 }, studs = false }
		),
		P(
			"Flower1Petal1",
			{ 0.304, 0.1, 0.33 },
			{ -1.664, 2.56, -0.985 },
			FLOWER2,
			{ joint = "Body", rot = { -90, 16.699, 90 }, studs = false }
		),
		P(
			"Flower1Petal2",
			{ 0.304, 0.1, 0.33 },
			{ -1.625, 2.691, -1.174 },
			GLINT,
			{ joint = "Body", rot = { -17.287, 5.094, 74.076 }, studs = false }
		),
		P(
			"Flower1Petal3",
			{ 0.304, 0.1, 0.33 },
			{ -1.561, 2.903, -1.102 },
			FLOWER2,
			{ joint = "Body", rot = { 52.819, -13.442, 80 }, studs = false }
		),
		P(
			"Flower1Petal4",
			{ 0.304, 0.1, 0.33 },
			{ -1.561, 2.903, -0.869 },
			GLINT,
			{ joint = "Body", rot = { 127.181, -13.442, 100 }, studs = false }
		),
		P(
			"Flower1Petal5",
			{ 0.304, 0.1, 0.33 },
			{ -1.625, 2.691, -0.797 },
			FLOWER2,
			{ joint = "Body", rot = { 17.287, 174.906, -74.076 }, studs = false }
		),
		P(
			"Flower1Centre",
			{ 0.224, 0.14, 0.224 },
			{ -1.636, 2.759, -0.985 },
			POLLEN,
			{ joint = "Body", rot = { -136.234, 11.723, 101.977 }, material = "Neon", studs = false }
		),
		P(
			"Flower2Petal1",
			{ 0.304, 0.1, 0.33 },
			{ -0.418, 2.16, 1.818 },
			FLOWER2,
			{ joint = "Body", rot = { 73.301, 180, 0 }, studs = false }
		),
		P(
			"Flower2Petal2",
			{ 0.304, 0.1, 0.33 },
			{ -0.607, 2.291, 1.779 },
			GLINT,
			{ joint = "Body", rot = { 73.301, 108, 0 }, studs = false }
		),
		P(
			"Flower2Petal3",
			{ 0.304, 0.1, 0.33 },
			{ -0.535, 2.503, 1.716 },
			FLOWER2,
			{ joint = "Body", rot = { 73.301, 36, 0 }, studs = false }
		),
		P(
			"Flower2Petal4",
			{ 0.304, 0.1, 0.33 },
			{ -0.302, 2.503, 1.716 },
			GLINT,
			{ joint = "Body", rot = { 73.301, -36, 0 }, studs = false }
		),
		P(
			"Flower2Petal5",
			{ 0.304, 0.1, 0.33 },
			{ -0.23, 2.291, 1.779 },
			FLOWER2,
			{ joint = "Body", rot = { 73.301, -108, 0 }, studs = false }
		),
		P(
			"Flower2Centre",
			{ 0.224, 0.14, 0.224 },
			{ -0.418, 2.359, 1.79 },
			POLLEN,
			{ joint = "Body", rot = { 73.301, -135, 0 }, material = "Neon", studs = false }
		),
		P("Berry1_1", { 0.26, 0.26, 0.26 }, { 1.593, 1.55, -1.094 }, BERRY, { joint = "Body", studs = false }),
		P(
			"Berry1_2",
			{ 0.26, 0.26, 0.26 },
			{ 1.763, 1.67, -0.994 },
			BERRY2,
			{ joint = "Body", rot = { 0, 20, 0 }, studs = false }
		),
		P(
			"Berry1_3",
			{ 0.26, 0.26, 0.26 },
			{ 1.933, 1.55, -1.094 },
			BERRY,
			{ joint = "Body", rot = { 0, 40, 0 }, studs = false }
		),
		P("Berry2_1", { 0.26, 0.26, 0.26 }, { -1.932, 2.25, 0.418 }, BERRY, { joint = "Body", studs = false }),
		P(
			"Berry2_2",
			{ 0.26, 0.26, 0.26 },
			{ -1.762, 2.37, 0.518 },
			BERRY2,
			{ joint = "Body", rot = { 0, 20, 0 }, studs = false }
		),
		P(
			"Berry2_3",
			{ 0.26, 0.26, 0.26 },
			{ -1.592, 2.25, 0.418 },
			BERRY,
			{ joint = "Body", rot = { 0, 40, 0 }, studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P(
			"HingeBody",
			{ 0.23, 0.23, 0.23 },
			{ 0, 1.61, 0.345 },
			VINE,
			{ joint = "Body", transparency = 1, studs = false }
		),
		P("Torso", { 2.99, 1.955, 3.45 }, { 0, 1.782, 0.46 }, VINE, { joint = "Body" }),
		P("Chest", { 2.415, 1.495, 0.69 }, { 0, 1.668, -1.438 }, TAN, { joint = "Body" }),
		P("Belly", { 2.3, 0.402, 2.875 }, { 0, 0.897, 0.46 }, TAN, { joint = "Body", studs = false }),
		P("Rump", { 2.53, 1.38, 0.575 }, { 0, 1.84, 2.357 }, MAIN2, { joint = "Body", studs = false }),
		P(
			"HingeQuills",
			{ 0.23, 0.23, 0.23 },
			{ 0, 2.53, -0.23 },
			VINE,
			{ joint = "Quills", transparency = 1, studs = false }
		),
		P("Coat1", { 3.795, 0.69, 4.485 }, { 0, 1.782, 0.632 }, LEAF4, { joint = "Quills" }),
		P("Coat2", { 4.025, 0.69, 4.715 }, { 0, 2.473, 0.632 }, LEAF4, { joint = "Quills" }),
		P("Coat3", { 3.565, 0.69, 4.255 }, { 0, 3.162, 0.632 }, LEAF4, { joint = "Quills" }),
		P("Coat4", { 2.76, 0.575, 3.335 }, { 0, 3.737, 0.632 }, LEAF4, { joint = "Quills" }),
		P("Coat5", { 1.725, 0.402, 2.185 }, { 0, 4.163, 0.632 }, LEAF4, { joint = "Quills" }),
		P(
			"CoatLeaf1",
			{ 0.828, 1.159, 0.161 },
			{ 1.967, 1.666, -0.571 },
			LEAF2,
			{ joint = "Quills", rot = { 170.503, 40.528, -56.17 }, studs = false }
		),
		P(
			"CoatLeaf1Tip",
			{ 0.585, 0.585, 0.155 },
			{ 2.333, 1.4, -0.209 },
			LEAF2,
			{ joint = "Quills", rot = { 170.503, 40.528, -11.17 }, studs = false }
		),
		P(
			"CoatLeaf2",
			{ 0.828, 1.159, 0.161 },
			{ 2.251, 1.706, 0.595 },
			LEAF4,
			{ joint = "Quills", rot = { -21.445, 116.593, 128.56 }, studs = false }
		),
		P(
			"CoatLeaf2Tip",
			{ 0.585, 0.585, 0.155 },
			{ 2.454, 1.518, 1.105 },
			LEAF4,
			{ joint = "Quills", rot = { 158.555, 63.407, -6.44 }, studs = false }
		),
		P(
			"CoatLeaf3",
			{ 0.828, 1.159, 0.161 },
			{ 2.015, 1.732, 1.781 },
			LEAF3,
			{ joint = "Quills", rot = { 94.406, 78.556, 9.442 }, studs = false }
		),
		P(
			"CoatLeaf3Tip",
			{ 0.585, 0.585, 0.155 },
			{ 1.996, 1.595, 2.344 },
			LEAF3,
			{ joint = "Quills", rot = { 94.407, 78.556, 54.442 }, studs = false }
		),
		P(
			"CoatLeaf4",
			{ 0.828, 1.159, 0.161 },
			{ 1.305, 1.757, 2.716 },
			LEAF,
			{ joint = "Quills", rot = { 30.527, 61.504, 71.384 }, studs = false }
		),
		P(
			"CoatLeaf4Tip",
			{ 0.585, 0.585, 0.155 },
			{ 1.043, 1.671, 3.226 },
			LEAF,
			{ joint = "Quills", rot = { 30.527, 61.504, 116.384 }, studs = false }
		),
		P(
			"CoatLeaf5",
			{ 0.828, 1.159, 0.161 },
			{ 0.285, 1.811, 3.178 },
			LEAF2,
			{ joint = "Quills", rot = { 22.739, 33.595, 74.536 }, studs = false }
		),
		P(
			"CoatLeaf5Tip",
			{ 0.585, 0.585, 0.155 },
			{ -0.181, 1.834, 3.523 },
			LEAF2,
			{ joint = "Quills", rot = { 22.739, 33.595, 119.536 }, studs = false }
		),
		P(
			"CoatLeaf6",
			{ 0.828, 1.159, 0.161 },
			{ -0.285, 1.811, 3.178 },
			LEAF4,
			{ joint = "Quills", rot = { 22.739, -33.595, -74.536 }, studs = false }
		),
		P(
			"CoatLeaf6Tip",
			{ 0.585, 0.585, 0.155 },
			{ 0.181, 1.834, 3.523 },
			LEAF4,
			{ joint = "Quills", rot = { 22.739, -33.595, -29.536 }, studs = false }
		),
		P(
			"CoatLeaf7",
			{ 0.828, 1.159, 0.161 },
			{ -1.305, 1.757, 2.716 },
			LEAF3,
			{ joint = "Quills", rot = { 30.527, -61.504, -71.384 }, studs = false }
		),
		P(
			"CoatLeaf7Tip",
			{ 0.585, 0.585, 0.155 },
			{ -1.043, 1.671, 3.226 },
			LEAF3,
			{ joint = "Quills", rot = { 30.527, -61.504, -26.384 }, studs = false }
		),
		P(
			"CoatLeaf8",
			{ 0.828, 1.159, 0.161 },
			{ -2.015, 1.732, 1.781 },
			LEAF,
			{ joint = "Quills", rot = { 94.406, -78.556, -9.442 }, studs = false }
		),
		P(
			"CoatLeaf8Tip",
			{ 0.585, 0.585, 0.155 },
			{ -1.996, 1.595, 2.344 },
			LEAF,
			{ joint = "Quills", rot = { 94.407, -78.556, 35.558 }, studs = false }
		),
		P(
			"CoatLeaf9",
			{ 0.828, 1.159, 0.161 },
			{ -2.251, 1.706, 0.595 },
			LEAF2,
			{ joint = "Quills", rot = { -21.445, -116.593, -128.56 }, studs = false }
		),
		P(
			"CoatLeaf9Tip",
			{ 0.585, 0.585, 0.155 },
			{ -2.454, 1.518, 1.105 },
			LEAF2,
			{ joint = "Quills", rot = { -21.445, -116.593, -83.56 }, studs = false }
		),
		P(
			"CoatLeaf10",
			{ 0.828, 1.159, 0.161 },
			{ -1.967, 1.666, -0.571 },
			LEAF4,
			{ joint = "Quills", rot = { 170.503, -40.528, 56.17 }, studs = false }
		),
		P(
			"CoatLeaf10Tip",
			{ 0.585, 0.585, 0.155 },
			{ -2.333, 1.4, -0.209 },
			LEAF4,
			{ joint = "Quills", rot = { -9.497, -139.472, -78.83 }, studs = false }
		),
		P(
			"CoatLeaf11",
			{ 0.828, 1.207, 0.161 },
			{ 1.753, 2.55, -1.104 },
			LEAF3,
			{ joint = "Quills", rot = { 13.536, 154.956, 91.182 }, studs = false }
		),
		P(
			"CoatLeaf11Tip",
			{ 0.585, 0.585, 0.155 },
			{ 2.3, 2.478, -0.858 },
			LEAF3,
			{ joint = "Quills", rot = { -166.464, 25.044, -43.818 }, studs = false }
		),
		P(
			"CoatLeaf12",
			{ 0.828, 1.207, 0.161 },
			{ 2.266, 2.543, -0.009 },
			LEAF,
			{ joint = "Quills", rot = { 19.402, 129.48, 83.062 }, studs = false }
		),
		P(
			"CoatLeaf12Tip",
			{ 0.585, 0.585, 0.155 },
			{ 2.647, 2.458, 0.452 },
			LEAF,
			{ joint = "Quills", rot = { -160.598, 50.52, -51.938 }, studs = false }
		),
		P(
			"CoatLeaf13",
			{ 0.828, 1.207, 0.161 },
			{ 2.277, 2.527, 1.232 },
			LEAF2,
			{ joint = "Quills", rot = { 45.879, 108.365, 56.8 }, studs = false }
		),
		P(
			"CoatLeaf13Tip",
			{ 0.585, 0.585, 0.155 },
			{ 2.436, 2.413, 1.803 },
			LEAF2,
			{ joint = "Quills", rot = { 45.879, 108.365, 101.8 }, studs = false }
		),
		P(
			"CoatLeaf14",
			{ 0.828, 1.207, 0.161 },
			{ 1.777, 2.498, 2.347 },
			LEAF4,
			{ joint = "Quills", rot = { 128.771, 109.846, -23.428 }, studs = false }
		),
		P(
			"CoatLeaf14Tip",
			{ 0.585, 0.585, 0.155 },
			{ 1.695, 2.327, 2.921 },
			LEAF4,
			{ joint = "Quills", rot = { 128.771, 109.846, 21.572 }, studs = false }
		),
		P(
			"CoatLeaf15",
			{ 0.828, 1.207, 0.161 },
			{ 0.892, 2.427, 3.075 },
			LEAF3,
			{ joint = "Quills", rot = { -28.996, 43.191, 143.753 }, studs = false }
		),
		P(
			"CoatLeaf15Tip",
			{ 0.585, 0.585, 0.155 },
			{ 0.632, 2.119, 3.525 },
			LEAF3,
			{ joint = "Quills", rot = { -28.996, 43.191, -171.247 }, studs = false }
		),
		P(
			"CoatLeaf16",
			{ 0.828, 1.207, 0.161 },
			{ 0, 2.312, 3.28 },
			LEAF,
			{ joint = "Quills", rot = { -29.086, 0, -180 }, studs = false }
		),
		P(
			"CoatLeaf16Tip",
			{ 0.585, 0.585, 0.155 },
			{ 0, 1.784, 3.574 },
			LEAF,
			{ joint = "Quills", rot = { -29.086, 0, -135 }, studs = false }
		),
		P(
			"CoatLeaf17",
			{ 0.828, 1.207, 0.161 },
			{ -0.892, 2.427, 3.075 },
			LEAF2,
			{ joint = "Quills", rot = { -28.996, -43.191, -143.753 }, studs = false }
		),
		P(
			"CoatLeaf17Tip",
			{ 0.585, 0.585, 0.155 },
			{ -0.632, 2.119, 3.525 },
			LEAF2,
			{ joint = "Quills", rot = { -28.996, -43.191, -98.753 }, studs = false }
		),
		P(
			"CoatLeaf18",
			{ 0.828, 1.207, 0.161 },
			{ -1.777, 2.498, 2.347 },
			LEAF4,
			{ joint = "Quills", rot = { 128.771, -109.846, 23.428 }, studs = false }
		),
		P(
			"CoatLeaf18Tip",
			{ 0.585, 0.585, 0.155 },
			{ -1.695, 2.327, 2.921 },
			LEAF4,
			{ joint = "Quills", rot = { -51.229, -70.154, -111.572 }, studs = false }
		),
		P(
			"CoatLeaf19",
			{ 0.828, 1.207, 0.161 },
			{ -2.277, 2.527, 1.232 },
			LEAF3,
			{ joint = "Quills", rot = { 45.879, -108.365, -56.8 }, studs = false }
		),
		P(
			"CoatLeaf19Tip",
			{ 0.585, 0.585, 0.155 },
			{ -2.436, 2.413, 1.803 },
			LEAF3,
			{ joint = "Quills", rot = { 45.879, -108.365, -11.8 }, studs = false }
		),
		P(
			"CoatLeaf20",
			{ 0.828, 1.207, 0.161 },
			{ -2.266, 2.543, -0.009 },
			LEAF,
			{ joint = "Quills", rot = { 19.402, -129.48, -83.062 }, studs = false }
		),
		P(
			"CoatLeaf20Tip",
			{ 0.585, 0.585, 0.155 },
			{ -2.647, 2.458, 0.452 },
			LEAF,
			{ joint = "Quills", rot = { 19.402, -129.48, -38.062 }, studs = false }
		),
		P(
			"CoatLeaf21",
			{ 0.828, 1.207, 0.161 },
			{ -1.753, 2.55, -1.104 },
			LEAF2,
			{ joint = "Quills", rot = { 13.536, -154.956, -91.182 }, studs = false }
		),
		P(
			"CoatLeaf21Tip",
			{ 0.585, 0.585, 0.155 },
			{ -2.3, 2.478, -0.858 },
			LEAF2,
			{ joint = "Quills", rot = { 13.536, -154.956, -46.182 }, studs = false }
		),
		P(
			"CoatLeaf22",
			{ 0.805, 1.159, 0.161 },
			{ 1.903, 3.322, -0.268 },
			LEAF4,
			{ joint = "Quills", rot = { 35.64, 144.852, 55.477 }, studs = false }
		),
		P(
			"CoatLeaf22Tip",
			{ 0.569, 0.569, 0.155 },
			{ 2.293, 3.429, 0.147 },
			LEAF4,
			{ joint = "Quills", rot = { -144.36, 35.148, -79.523 }, studs = false }
		),
		P(
			"CoatLeaf23",
			{ 0.805, 1.159, 0.161 },
			{ 2.082, 3.266, 0.902 },
			LEAF3,
			{ joint = "Quills", rot = { 58.767, 128.512, 38.304 }, studs = false }
		),
		P(
			"CoatLeaf23Tip",
			{ 0.569, 0.569, 0.155 },
			{ 2.306, 3.261, 1.437 },
			LEAF3,
			{ joint = "Quills", rot = { -121.233, 51.488, -96.696 }, studs = false }
		),
		P(
			"CoatLeaf24",
			{ 0.805, 1.159, 0.161 },
			{ 1.724, 3.211, 2.028 },
			LEAF,
			{ joint = "Quills", rot = { 96.689, 127.84, 5.814 }, studs = false }
		),
		P(
			"CoatLeaf24Tip",
			{ 0.569, 0.569, 0.155 },
			{ 1.76, 3.098, 2.595 },
			LEAF,
			{ joint = "Quills", rot = { -83.311, 52.16, -129.186 }, studs = false }
		),
		P(
			"CoatLeaf25",
			{ 0.805, 1.159, 0.161 },
			{ 0.945, 3.142, 2.815 },
			LEAF2,
			{ joint = "Quills", rot = { -58.582, 32.616, 170.423 }, studs = false }
		),
		P(
			"CoatLeaf25Tip",
			{ 0.569, 0.569, 0.155 },
			{ 0.864, 2.888, 3.33 },
			LEAF2,
			{ joint = "Quills", rot = { -58.582, 32.616, -144.577 }, studs = false }
		),
		P(
			"CoatLeaf26",
			{ 0.805, 1.159, 0.161 },
			{ 0, 3.092, 3.086 },
			LEAF4,
			{ joint = "Quills", rot = { -52.444, 0, -180 }, studs = false }
		),
		P(
			"CoatLeaf26Tip",
			{ 0.569, 0.569, 0.155 },
			{ 0, 2.739, 3.545 },
			LEAF4,
			{ joint = "Quills", rot = { -52.444, 0, -135 }, studs = false }
		),
		P(
			"CoatLeaf27",
			{ 0.805, 1.159, 0.161 },
			{ -0.945, 3.142, 2.815 },
			LEAF3,
			{ joint = "Quills", rot = { -58.582, -32.616, -170.423 }, studs = false }
		),
		P(
			"CoatLeaf27Tip",
			{ 0.569, 0.569, 0.155 },
			{ -0.864, 2.888, 3.33 },
			LEAF3,
			{ joint = "Quills", rot = { -58.582, -32.616, -125.423 }, studs = false }
		),
		P(
			"CoatLeaf28",
			{ 0.805, 1.159, 0.161 },
			{ -1.724, 3.211, 2.028 },
			LEAF,
			{ joint = "Quills", rot = { 96.689, -127.84, -5.814 }, studs = false }
		),
		P(
			"CoatLeaf28Tip",
			{ 0.569, 0.569, 0.155 },
			{ -1.76, 3.098, 2.595 },
			LEAF,
			{ joint = "Quills", rot = { 96.689, -127.84, 39.186 }, studs = false }
		),
		P(
			"CoatLeaf29",
			{ 0.805, 1.159, 0.161 },
			{ -2.082, 3.266, 0.902 },
			LEAF2,
			{ joint = "Quills", rot = { 58.767, -128.512, -38.304 }, studs = false }
		),
		P(
			"CoatLeaf29Tip",
			{ 0.569, 0.569, 0.155 },
			{ -2.306, 3.261, 1.437 },
			LEAF2,
			{ joint = "Quills", rot = { 58.767, -128.512, 6.696 }, studs = false }
		),
		P(
			"CoatLeaf30",
			{ 0.805, 1.159, 0.161 },
			{ -1.903, 3.322, -0.268 },
			LEAF4,
			{ joint = "Quills", rot = { 35.64, -144.852, -55.477 }, studs = false }
		),
		P(
			"CoatLeaf30Tip",
			{ 0.569, 0.569, 0.155 },
			{ -2.293, 3.429, 0.147 },
			LEAF4,
			{ joint = "Quills", rot = { 35.64, -144.852, -10.477 }, studs = false }
		),
		P(
			"CoatLeaf31",
			{ 0.759, 1.063, 0.161 },
			{ 0.53, 4.016, -0.822 },
			LEAF3,
			{ joint = "Quills", rot = { 36.226, 173.111, 16.387 }, studs = false }
		),
		P(
			"CoatLeaf31Tip",
			{ 0.537, 0.537, 0.155 },
			{ 0.678, 4.417, -0.506 },
			LEAF3,
			{ joint = "Quills", rot = { -143.774, 6.889, -118.613 }, studs = false }
		),
		P(
			"CoatLeaf32",
			{ 0.759, 1.063, 0.161 },
			{ 1.322, 3.938, -0.169 },
			LEAF,
			{ joint = "Quills", rot = { 47.233, 157.006, 30.838 }, studs = false }
		),
		P(
			"CoatLeaf32Tip",
			{ 0.537, 0.537, 0.155 },
			{ 1.573, 4.169, 0.239 },
			LEAF,
			{ joint = "Quills", rot = { -132.767, 22.994, -104.162 }, studs = false }
		),
		P(
			"CoatLeaf33",
			{ 0.759, 1.063, 0.161 },
			{ 1.571, 3.87, 0.86 },
			LEAF2,
			{ joint = "Quills", rot = { 66.762, 145.775, 23.174 }, studs = false }
		),
		P(
			"CoatLeaf33Tip",
			{ 0.537, 0.537, 0.155 },
			{ 1.744, 3.954, 1.355 },
			LEAF2,
			{ joint = "Quills", rot = { -113.238, 34.225, -111.826 }, studs = false }
		),
		P(
			"CoatLeaf34",
			{ 0.759, 1.063, 0.161 },
			{ 1.232, 3.813, 1.862 },
			LEAF4,
			{ joint = "Quills", rot = { 90.655, 148.726, 7.04 }, studs = false }
		),
		P(
			"CoatLeaf34Tip",
			{ 0.537, 0.537, 0.155 },
			{ 1.288, 3.773, 2.389 },
			LEAF4,
			{ joint = "Quills", rot = { -89.345, 31.274, -127.96 }, studs = false }
		),
		P(
			"CoatLeaf35",
			{ 0.759, 1.063, 0.161 },
			{ 0.46, 3.769, 2.467 },
			LEAF3,
			{ joint = "Quills", rot = { -74.852, 12.676, 179.756 }, studs = false }
		),
		P(
			"CoatLeaf35Tip",
			{ 0.537, 0.537, 0.155 },
			{ 0.458, 3.631, 2.98 },
			LEAF3,
			{ joint = "Quills", rot = { -74.852, 12.676, -135.244 }, studs = false }
		),
		P(
			"CoatLeaf36",
			{ 0.759, 1.063, 0.161 },
			{ -0.46, 3.769, 2.467 },
			LEAF,
			{ joint = "Quills", rot = { -74.852, -12.676, -179.756 }, studs = false }
		),
		P(
			"CoatLeaf36Tip",
			{ 0.537, 0.537, 0.155 },
			{ -0.458, 3.631, 2.98 },
			LEAF,
			{ joint = "Quills", rot = { -74.852, -12.676, -134.756 }, studs = false }
		),
		P(
			"CoatLeaf37",
			{ 0.759, 1.063, 0.161 },
			{ -1.232, 3.813, 1.862 },
			LEAF2,
			{ joint = "Quills", rot = { 90.655, -148.726, -7.04 }, studs = false }
		),
		P(
			"CoatLeaf37Tip",
			{ 0.537, 0.537, 0.155 },
			{ -1.288, 3.773, 2.389 },
			LEAF2,
			{ joint = "Quills", rot = { -89.345, -31.274, -142.04 }, studs = false }
		),
		P(
			"CoatLeaf38",
			{ 0.759, 1.063, 0.161 },
			{ -1.571, 3.87, 0.86 },
			LEAF4,
			{ joint = "Quills", rot = { 66.762, -145.775, -23.174 }, studs = false }
		),
		P(
			"CoatLeaf38Tip",
			{ 0.537, 0.537, 0.155 },
			{ -1.744, 3.954, 1.355 },
			LEAF4,
			{ joint = "Quills", rot = { 66.762, -145.775, 21.826 }, studs = false }
		),
		P(
			"CoatLeaf39",
			{ 0.759, 1.063, 0.161 },
			{ -1.322, 3.938, -0.169 },
			LEAF3,
			{ joint = "Quills", rot = { 47.233, -157.006, -30.838 }, studs = false }
		),
		P(
			"CoatLeaf39Tip",
			{ 0.537, 0.537, 0.155 },
			{ -1.573, 4.169, 0.239 },
			LEAF3,
			{ joint = "Quills", rot = { 47.233, -157.006, 14.162 }, studs = false }
		),
		P(
			"CoatLeaf40",
			{ 0.759, 1.063, 0.161 },
			{ -0.53, 4.016, -0.822 },
			LEAF,
			{ joint = "Quills", rot = { 36.226, -173.111, -16.387 }, studs = false }
		),
		P(
			"CoatLeaf40Tip",
			{ 0.537, 0.537, 0.155 },
			{ -0.678, 4.417, -0.506 },
			LEAF,
			{ joint = "Quills", rot = { 36.226, -173.111, 28.613 }, studs = false }
		),
		P(
			"CoatLeaf41",
			{ 0.713, 0.966, 0.161 },
			{ 0, 4.317, -0.195 },
			LEAF2,
			{ joint = "Quills", rot = { 51.65, -180, 0 }, studs = false }
		),
		P(
			"CoatLeaf41Tip",
			{ 0.504, 0.504, 0.155 },
			{ 0, 4.617, 0.183 },
			LEAF2,
			{ joint = "Quills", rot = { -128.35, 0, -135 }, studs = false }
		),
		P(
			"CoatLeaf42",
			{ 0.713, 0.966, 0.161 },
			{ 0.724, 4.287, 0.188 },
			LEAF4,
			{ joint = "Quills", rot = { 58.221, 166.933, 13.095 }, studs = false }
		),
		P(
			"CoatLeaf42Tip",
			{ 0.504, 0.504, 0.155 },
			{ 0.83, 4.514, 0.601 },
			LEAF4,
			{ joint = "Quills", rot = { -121.779, 13.067, -121.905 }, studs = false }
		),
		P(
			"CoatLeaf43",
			{ 0.713, 0.966, 0.161 },
			{ 0.882, 4.238, 1.039 },
			LEAF3,
			{ joint = "Quills", rot = { 74.053, 161.536, 10.355 }, studs = false }
		),
		P(
			"CoatLeaf43Tip",
			{ 0.504, 0.504, 0.155 },
			{ 0.964, 4.342, 1.503 },
			LEAF3,
			{ joint = "Quills", rot = { -105.947, 18.464, -124.645 }, studs = false }
		),
		P(
			"CoatLeaf44",
			{ 0.713, 0.966, 0.161 },
			{ 0.386, 4.202, 1.712 },
			LEAF,
			{ joint = "Quills", rot = { 87.76, 171.149, 2.572 }, studs = false }
		),
		P(
			"CoatLeaf44Tip",
			{ 0.504, 0.504, 0.155 },
			{ 0.408, 4.218, 2.194 },
			LEAF,
			{ joint = "Quills", rot = { -92.24, 8.851, -132.428 }, studs = false }
		),
		P(
			"CoatLeaf45",
			{ 0.713, 0.966, 0.161 },
			{ -0.386, 4.202, 1.712 },
			LEAF2,
			{ joint = "Quills", rot = { 87.76, -171.149, -2.572 }, studs = false }
		),
		P(
			"CoatLeaf45Tip",
			{ 0.504, 0.504, 0.155 },
			{ -0.408, 4.218, 2.194 },
			LEAF2,
			{ joint = "Quills", rot = { -92.24, -8.851, -137.572 }, studs = false }
		),
		P(
			"CoatLeaf46",
			{ 0.713, 0.966, 0.161 },
			{ -0.882, 4.238, 1.039 },
			LEAF4,
			{ joint = "Quills", rot = { 74.053, -161.536, -10.355 }, studs = false }
		),
		P(
			"CoatLeaf46Tip",
			{ 0.504, 0.504, 0.155 },
			{ -0.964, 4.342, 1.503 },
			LEAF4,
			{ joint = "Quills", rot = { -105.947, -18.464, -145.355 }, studs = false }
		),
		P(
			"CoatLeaf47",
			{ 0.713, 0.966, 0.161 },
			{ -0.724, 4.287, 0.188 },
			LEAF3,
			{ joint = "Quills", rot = { 58.221, -166.933, -13.095 }, studs = false }
		),
		P(
			"CoatLeaf47Tip",
			{ 0.504, 0.504, 0.155 },
			{ -0.83, 4.514, 0.601 },
			LEAF3,
			{ joint = "Quills", rot = { 58.221, -166.933, 31.905 }, studs = false }
		),
		P(
			"CoatLeaf48",
			{ 0.667, 0.869, 0.161 },
			{ 0.209, 4.401, 0.638 },
			LEAF,
			{ joint = "Quills", rot = { 68.217, 175.949, 2.919 }, studs = false }
		),
		P(
			"CoatLeaf48Tip",
			{ 0.472, 0.472, 0.155 },
			{ 0.231, 4.561, 1.042 },
			LEAF,
			{ joint = "Quills", rot = { -111.784, 4.051, -132.081 }, studs = false }
		),
		P(
			"CoatLeaf49",
			{ 0.667, 0.869, 0.161 },
			{ 0, 4.384, 1.037 },
			LEAF2,
			{ joint = "Quills", rot = { 75.6, 180, 0 }, studs = false }
		),
		P(
			"CoatLeaf49Tip",
			{ 0.472, 0.472, 0.155 },
			{ 0, 4.492, 1.458 },
			LEAF2,
			{ joint = "Quills", rot = { -104.4, 0, -135 }, studs = false }
		),
		P(
			"CoatLeaf50",
			{ 0.667, 0.869, 0.161 },
			{ -0.209, 4.401, 0.638 },
			LEAF4,
			{ joint = "Quills", rot = { 68.217, -175.949, -2.919 }, studs = false }
		),
		P(
			"CoatLeaf50Tip",
			{ 0.472, 0.472, 0.155 },
			{ -0.231, 4.561, 1.042 },
			LEAF4,
			{ joint = "Quills", rot = { -111.783, -4.051, -137.919 }, studs = false }
		),
		P(
			"Thorn1",
			{ 0.529, 0.555, 0.529 },
			{ 1.944, 3.15, -0.407 },
			THORN,
			{ joint = "Quills", rot = { 47.12, 7.503, -59.146 }, studs = false }
		),
		P(
			"Thorn1Mid",
			{ 0.37, 0.476, 0.37 },
			{ 2.327, 3.344, -0.272 },
			THORN,
			{ joint = "Quills", rot = { 47.12, 7.503, -59.146 }, studs = false }
		),
		P(
			"Thorn1Tip",
			{ 0.212, 0.397, 0.212 },
			{ 2.653, 3.509, -0.157 },
			THORN2,
			{ joint = "Quills", rot = { 47.12, 7.503, -59.146 }, studs = false }
		),
		P(
			"Thorn2",
			{ 0.598, 0.639, 0.598 },
			{ 1.993, 3.266, 1.604 },
			THORN,
			{ joint = "Quills", rot = { 59.984, -5.164, -38.048 }, studs = false }
		),
		P(
			"Thorn2Mid",
			{ 0.419, 0.548, 0.419 },
			{ 2.311, 3.444, 1.971 },
			THORN,
			{ joint = "Quills", rot = { 59.984, -5.164, -38.048 }, studs = false }
		),
		P(
			"Thorn2Tip",
			{ 0.239, 0.456, 0.239 },
			{ 2.581, 3.597, 2.284 },
			THORN2,
			{ joint = "Quills", rot = { 59.984, -5.164, -38.048 }, studs = false }
		),
		P(
			"Thorn3",
			{ 0.529, 0.583, 0.529 },
			{ 0.744, 3.037, 3.043 },
			THORN,
			{ joint = "Quills", rot = { 63.37, 136.302, 17.145 }, studs = false }
		),
		P(
			"Thorn3Mid",
			{ 0.37, 0.5, 0.37 },
			{ 0.845, 3.153, 3.489 },
			THORN,
			{ joint = "Quills", rot = { 63.37, 136.302, 17.145 }, studs = false }
		),
		P(
			"Thorn3Tip",
			{ 0.212, 0.417, 0.212 },
			{ 0.931, 3.252, 3.87 },
			THORN2,
			{ joint = "Quills", rot = { 63.37, 136.302, 17.145 }, studs = false }
		),
		P(
			"Thorn4",
			{ 0.529, 0.583, 0.529 },
			{ -0.734, 3.107, 3.013 },
			THORN,
			{ joint = "Quills", rot = { 85.867, 136.265, -16.903 }, studs = false }
		),
		P(
			"Thorn4Mid",
			{ 0.37, 0.5, 0.37 },
			{ -0.834, 3.234, 3.457 },
			THORN,
			{ joint = "Quills", rot = { 85.867, 136.265, -16.903 }, studs = false }
		),
		P(
			"Thorn4Tip",
			{ 0.212, 0.417, 0.212 },
			{ -0.918, 3.343, 3.835 },
			THORN2,
			{ joint = "Quills", rot = { 85.867, 136.265, -16.903 }, studs = false }
		),
		P(
			"Thorn5",
			{ 0.598, 0.639, 0.598 },
			{ -1.993, 3.266, 1.604 },
			THORN,
			{ joint = "Quills", rot = { -36.576, 51.656, 98.342 }, studs = false }
		),
		P(
			"Thorn5Mid",
			{ 0.419, 0.548, 0.419 },
			{ -2.311, 3.444, 1.971 },
			THORN,
			{ joint = "Quills", rot = { -36.576, 51.656, 98.342 }, studs = false }
		),
		P(
			"Thorn5Tip",
			{ 0.239, 0.456, 0.239 },
			{ -2.581, 3.597, 2.284 },
			THORN2,
			{ joint = "Quills", rot = { -36.576, 51.656, 98.342 }, studs = false }
		),
		P(
			"Thorn6",
			{ 0.529, 0.555, 0.529 },
			{ -1.944, 3.15, -0.407 },
			THORN,
			{ joint = "Quills", rot = { -38.42, 30.561, 81.278 }, studs = false }
		),
		P(
			"Thorn6Mid",
			{ 0.37, 0.476, 0.37 },
			{ -2.327, 3.344, -0.272 },
			THORN,
			{ joint = "Quills", rot = { -38.42, 30.561, 81.278 }, studs = false }
		),
		P(
			"Thorn6Tip",
			{ 0.212, 0.397, 0.212 },
			{ -2.653, 3.509, -0.157 },
			THORN2,
			{ joint = "Quills", rot = { -38.42, 30.561, 81.278 }, studs = false }
		),
		P(
			"Thorn7",
			{ 0.598, 0.639, 0.598 },
			{ 1.016, 4.069, -0.468 },
			THORN,
			{ joint = "Quills", rot = { 36.418, 32.795, -30.419 }, studs = false }
		),
		P(
			"Thorn7Mid",
			{ 0.419, 0.548, 0.419 },
			{ 1.236, 4.512, -0.317 },
			THORN,
			{ joint = "Quills", rot = { 36.418, 32.795, -30.419 }, studs = false }
		),
		P(
			"Thorn7Tip",
			{ 0.239, 0.456, 0.239 },
			{ 1.423, 4.89, -0.188 },
			THORN2,
			{ joint = "Quills", rot = { 36.418, 32.795, -30.419 }, studs = false }
		),
		P(
			"Thorn8",
			{ 0.598, 0.722, 0.598 },
			{ 1.455, 4.07, 1.116 },
			THORN,
			{ joint = "Quills", rot = { 54.167, 18.838, -28.601 }, studs = false }
		),
		P(
			"Thorn8Mid",
			{ 0.419, 0.619, 0.419 },
			{ 1.72, 4.444, 1.479 },
			THORN,
			{ joint = "Quills", rot = { 54.167, 18.838, -28.601 }, studs = false }
		),
		P(
			"Thorn8Tip",
			{ 0.239, 0.516, 0.239 },
			{ 1.946, 4.762, 1.789 },
			THORN2,
			{ joint = "Quills", rot = { 54.167, 18.838, -28.601 }, studs = false }
		),
		P(
			"Thorn9",
			{ 0.598, 0.667, 0.598 },
			{ 0, 3.926, 2.536 },
			THORN,
			{ joint = "Quills", rot = { 58.007, 45, 0 }, studs = false }
		),
		P(
			"Thorn9Mid",
			{ 0.419, 0.571, 0.419 },
			{ 0, 4.212, 2.993 },
			THORN,
			{ joint = "Quills", rot = { 58.007, 45, 0 }, studs = false }
		),
		P(
			"Thorn9Tip",
			{ 0.239, 0.476, 0.239 },
			{ 0, 4.455, 3.384 },
			THORN2,
			{ joint = "Quills", rot = { 58.007, 45, 0 }, studs = false }
		),
		P(
			"Thorn10",
			{ 0.598, 0.722, 0.598 },
			{ -1.455, 4.07, 1.116 },
			THORN,
			{ joint = "Quills", rot = { -5.198, 56.196, 54.522 }, studs = false }
		),
		P(
			"Thorn10Mid",
			{ 0.419, 0.619, 0.419 },
			{ -1.72, 4.444, 1.479 },
			THORN,
			{ joint = "Quills", rot = { -5.198, 56.196, 54.522 }, studs = false }
		),
		P(
			"Thorn10Tip",
			{ 0.239, 0.516, 0.239 },
			{ -1.946, 4.762, 1.789 },
			THORN2,
			{ joint = "Quills", rot = { -5.198, 56.196, 54.522 }, studs = false }
		),
		P(
			"Thorn11",
			{ 0.598, 0.639, 0.598 },
			{ -1.016, 4.069, -0.468 },
			THORN,
			{ joint = "Quills", rot = { -10.89, 46.461, 38.16 }, studs = false }
		),
		P(
			"Thorn11Mid",
			{ 0.419, 0.548, 0.419 },
			{ -1.236, 4.512, -0.317 },
			THORN,
			{ joint = "Quills", rot = { -10.89, 46.461, 38.16 }, studs = false }
		),
		P(
			"Thorn11Tip",
			{ 0.239, 0.456, 0.239 },
			{ -1.423, 4.89, -0.188 },
			THORN2,
			{ joint = "Quills", rot = { -10.89, 46.461, 38.16 }, studs = false }
		),
		P(
			"Thorn12",
			{ 0.598, 0.694, 0.598 },
			{ 0, 4.454, -0.059 },
			THORN,
			{ joint = "Quills", rot = { 23.452, 45, 0 }, studs = false }
		),
		P(
			"Thorn12Mid",
			{ 0.419, 0.595, 0.419 },
			{ 0, 4.97, 0.165 },
			THORN,
			{ joint = "Quills", rot = { 23.452, 45, 0 }, studs = false }
		),
		P(
			"Thorn12Tip",
			{ 0.239, 0.496, 0.239 },
			{ 0, 5.41, 0.356 },
			THORN2,
			{ joint = "Quills", rot = { 23.452, 45, 0 }, studs = false }
		),
		P(
			"Thorn13",
			{ 0.598, 0.694, 0.598 },
			{ 0.74, 4.431, 0.832 },
			THORN,
			{ joint = "Quills", rot = { 45.584, 34.136, -16.485 }, studs = false }
		),
		P(
			"Thorn13Mid",
			{ 0.419, 0.595, 0.419 },
			{ 0.872, 4.873, 1.154 },
			THORN,
			{ joint = "Quills", rot = { 45.584, 34.136, -16.485 }, studs = false }
		),
		P(
			"Thorn13Tip",
			{ 0.239, 0.496, 0.239 },
			{ 0.985, 5.249, 1.429 },
			THORN2,
			{ joint = "Quills", rot = { 45.584, 34.136, -16.485 }, studs = false }
		),
		P(
			"Thorn14",
			{ 0.598, 0.667, 0.598 },
			{ 0, 4.42, 1.531 },
			THORN,
			{ joint = "Quills", rot = { 43.598, 45, 0 }, studs = false }
		),
		P(
			"Thorn14Mid",
			{ 0.419, 0.571, 0.419 },
			{ 0, 4.811, 1.903 },
			THORN,
			{ joint = "Quills", rot = { 43.598, 45, 0 }, studs = false }
		),
		P(
			"Thorn14Tip",
			{ 0.239, 0.476, 0.239 },
			{ 0, 5.144, 2.22 },
			THORN2,
			{ joint = "Quills", rot = { 43.598, 45, 0 }, studs = false }
		),
		P(
			"Thorn15",
			{ 0.598, 0.694, 0.598 },
			{ -0.74, 4.431, 0.832 },
			THORN,
			{ joint = "Quills", rot = { 17.778, 52.531, 22.712 }, studs = false }
		),
		P(
			"Thorn15Mid",
			{ 0.419, 0.595, 0.419 },
			{ -0.872, 4.873, 1.154 },
			THORN,
			{ joint = "Quills", rot = { 17.778, 52.531, 22.712 }, studs = false }
		),
		P(
			"Thorn15Tip",
			{ 0.239, 0.496, 0.239 },
			{ -0.985, 5.249, 1.429 },
			THORN2,
			{ joint = "Quills", rot = { 17.778, 52.531, 22.712 }, studs = false }
		),
		P(
			"Thorn16",
			{ 0.598, 0.722, 0.598 },
			{ 0, 4.551, 0.84 },
			THORN,
			{ joint = "Quills", rot = { 34.992, 45, 0 }, studs = false }
		),
		P(
			"Thorn16Mid",
			{ 0.419, 0.619, 0.419 },
			{ 0, 5.03, 1.175 },
			THORN,
			{ joint = "Quills", rot = { 34.992, 45, 0 }, studs = false }
		),
		P(
			"Thorn16Tip",
			{ 0.239, 0.516, 0.239 },
			{ 0, 5.438, 1.461 },
			THORN2,
			{ joint = "Quills", rot = { 34.992, 45, 0 }, studs = false }
		),
		P(
			"Vine1_1",
			{ 0.23, 1.456, 0.23 },
			{ -1.183, 3.715, -0.792 },
			VINE,
			{ joint = "Quills", rot = { 57.667, 22.597, 13.67 }, studs = false }
		),
		P(
			"Vine1_2",
			{ 0.23, 1.468, 0.23 },
			{ -1.188, 4.135, 0.419 },
			VINE,
			{ joint = "Quills", rot = { 66.431, -44.787, -17.084 }, studs = false }
		),
		P(
			"Vine1_3",
			{ 0.23, 1.227, 0.23 },
			{ -0.741, 4.227, 1.504 },
			VINE,
			{ joint = "Quills", rot = { -9.551, -54.636, -101.658 }, studs = false }
		),
		P(
			"Vine1_4",
			{ 0.23, 1.285, 0.23 },
			{ 0.073, 4.037, 2.174 },
			VINE,
			{ joint = "Quills", rot = { -7.01, -21.826, -108.3 }, studs = false }
		),
		P("Berry1_1", { 0.299, 0.299, 0.299 }, { -1.596, 4.117, -0.256 }, BERRY, { joint = "Quills", studs = false }),
		P(
			"Berry1_2",
			{ 0.299, 0.299, 0.299 },
			{ -1.401, 4.255, -0.141 },
			BERRY2,
			{ joint = "Quills", rot = { 0, 20, 0 }, studs = false }
		),
		P(
			"Berry1_3",
			{ 0.299, 0.299, 0.299 },
			{ -1.205, 4.117, -0.256 },
			BERRY,
			{ joint = "Quills", rot = { 0, 40, 0 }, studs = false }
		),
		P(
			"Vine2_1",
			{ 0.23, 1.566, 0.23 },
			{ 1.361, 3.771, -0.442 },
			VINE,
			{ joint = "Quills", rot = { 65.777, -10.056, -4.492 }, studs = false }
		),
		P(
			"Vine2_2",
			{ 0.23, 1.292, 0.23 },
			{ 1.127, 4.193, 0.69 },
			VINE,
			{ joint = "Quills", rot = { 32.829, 48.603, 49.303 }, studs = false }
		),
		P(
			"Vine2_3",
			{ 0.23, 0.794, 0.23 },
			{ 0.517, 4.393, 1.202 },
			VINE,
			{ joint = "Quills", rot = { 1.056, 5.413, 78.948 }, studs = false }
		),
		P("Berry2_1", { 0.299, 0.299, 0.299 }, { 1.299, 4.167, 0.192 }, BERRY, { joint = "Quills", studs = false }),
		P(
			"Berry2_2",
			{ 0.299, 0.299, 0.299 },
			{ 1.495, 4.305, 0.307 },
			BERRY2,
			{ joint = "Quills", rot = { 0, 20, 0 }, studs = false }
		),
		P(
			"Berry2_3",
			{ 0.299, 0.299, 0.299 },
			{ 1.69, 4.167, 0.192 },
			BERRY,
			{ joint = "Quills", rot = { 0, 40, 0 }, studs = false }
		),
		P(
			"Vine3_1",
			{ 0.23, 1.478, 0.23 },
			{ -1.402, 3.342, 2.255 },
			VINE,
			{ joint = "Quills", rot = { -45.287, -35.431, 29.853 }, studs = false }
		),
		P(
			"Vine3_2",
			{ 0.23, 1.667, 0.23 },
			{ -1.855, 3.515, 0.97 },
			VINE,
			{ joint = "Quills", rot = { -120.43, -122.2, -26.43 }, studs = false }
		),
		P("Berry3_1", { 0.299, 0.299, 0.299 }, { -1.965, 3.7, 1.754 }, BERRY, { joint = "Quills", studs = false }),
		P(
			"Berry3_2",
			{ 0.299, 0.299, 0.299 },
			{ -1.77, 3.838, 1.869 },
			BERRY2,
			{ joint = "Quills", rot = { 0, 20, 0 }, studs = false }
		),
		P(
			"Berry3_3",
			{ 0.299, 0.299, 0.299 },
			{ -1.574, 3.7, 1.754 },
			BERRY,
			{ joint = "Quills", rot = { 0, 40, 0 }, studs = false }
		),
		P(
			"Flower1Petal1",
			{ 0.397, 0.115, 0.431 },
			{ -0.769, 4.11, -0.793 },
			FLOWER2,
			{ joint = "Quills", rot = { -32.148, 28.949, 16.92 }, studs = false }
		),
		P(
			"Flower1Petal2",
			{ 0.397, 0.115, 0.431 },
			{ -0.476, 4.193, -0.795 },
			GLINT,
			{ joint = "Quills", rot = { -10.873, -40.288, 19.503 }, studs = false }
		),
		P(
			"Flower1Petal3",
			{ 0.397, 0.115, 0.431 },
			{ -0.415, 4.328, -0.529 },
			FLOWER2,
			{ joint = "Quills", rot = { -53.583, -117.912, -32.958 }, studs = false }
		),
		P(
			"Flower1Petal4",
			{ 0.397, 0.115, 0.431 },
			{ -0.669, 4.328, -0.363 },
			GLINT,
			{ joint = "Quills", rot = { -22.248, 174.233, -14.831 }, studs = false }
		),
		P(
			"Flower1Petal5",
			{ 0.397, 0.115, 0.431 },
			{ -0.888, 4.193, -0.525 },
			FLOWER2,
			{ joint = "Quills", rot = { 26.293, 108.955, -51.629 }, studs = false }
		),
		P(
			"Flower1Centre",
			{ 0.293, 0.161, 0.293 },
			{ -0.652, 4.261, -0.614 },
			POLLEN,
			{ joint = "Quills", rot = { -67.387, 69.104, 45.564 }, material = "Neon", studs = false }
		),
		P(
			"Flower2Petal1",
			{ 0.397, 0.115, 0.431 },
			{ 1.968, 3.574, 1.206 },
			FLOWER2,
			{ joint = "Quills", rot = { -101.941, -41.146, -107.818 }, studs = false }
		),
		P(
			"Flower2Petal2",
			{ 0.397, 0.115, 0.431 },
			{ 1.794, 3.706, 1.418 },
			GLINT,
			{ joint = "Quills", rot = { 13.161, 179.094, 45.808 }, studs = false }
		),
		P(
			"Flower2Petal3",
			{ 0.397, 0.115, 0.431 },
			{ 1.625, 3.919, 1.281 },
			FLOWER2,
			{ joint = "Quills", rot = { -53.198, 138.106, 74.388 }, studs = false }
		),
		P(
			"Flower2Petal4",
			{ 0.397, 0.115, 0.431 },
			{ 1.695, 3.919, 0.985 },
			GLINT,
			{ joint = "Quills", rot = { 40.494, 23.383, -51.358 }, studs = false }
		),
		P(
			"Flower2Petal5",
			{ 0.397, 0.115, 0.431 },
			{ 1.907, 3.706, 0.939 },
			FLOWER2,
			{ joint = "Quills", rot = { -14.548, -24.991, -52.277 }, studs = false }
		),
		P(
			"Flower2Centre",
			{ 0.293, 0.161, 0.293 },
			{ 1.823, 3.788, 1.172 },
			POLLEN,
			{ joint = "Quills", rot = { -42.033, -38.917, -67.135 }, material = "Neon", studs = false }
		),
		P("Berry4_1", { 0.299, 0.299, 0.299 }, { 0.395, 4.392, 1.756 }, BERRY, { joint = "Quills", studs = false }),
		P(
			"Berry4_2",
			{ 0.299, 0.299, 0.299 },
			{ 0.59, 4.53, 1.871 },
			BERRY2,
			{ joint = "Quills", rot = { 0, 20, 0 }, studs = false }
		),
		P(
			"Berry4_3",
			{ 0.299, 0.299, 0.299 },
			{ 0.786, 4.392, 1.756 },
			BERRY,
			{ joint = "Quills", rot = { 0, 40, 0 }, studs = false }
		),
		P(
			"HingeHead",
			{ 0.23, 0.23, 0.23 },
			{ 0, 1.955, -1.61 },
			VINE,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P("Head", { 2.013, 1.668, 1.553 }, { 0, 2.243, -2.243 }, VINE, { joint = "Head" }),
		P("Face", { 1.668, 1.092, 0.138 }, { 0, 1.955, -3.048 }, TAN, { joint = "Head", studs = false }),
		P("Snout", { 0.897, 0.69, 0.978 }, { 0, 1.782, -3.45 }, TAN, { joint = "Head" }),
		P("SnoutTip", { 0.644, 0.517, 0.517 }, { 0, 1.817, -4.082 }, TAN2, { joint = "Head" }),
		P("Nose", { 0.483, 0.391, 0.322 }, { 0, 1.909, -4.462 }, NOSE, { joint = "Head", studs = false }),
		P("Mouth", { 0.529, 0.069, 0.069 }, { 0, 1.518, -3.91 }, INK, { joint = "Head", studs = false }),
		P(
			"EyeL",
			{ 0.437, 0.483, 0.092 },
			{ -0.483, 2.392, -3.105 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P("PupilL", { 0.271, 0.357, 0.069 }, { -0.483, 2.363, -3.162 }, INK, { joint = "Head", studs = false }),
		P(
			"GlintL",
			{ 0.131, 0.131, 0.046 },
			{ -0.557, 2.489, -3.208 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"EyeR",
			{ 0.437, 0.483, 0.092 },
			{ 0.483, 2.392, -3.105 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P("PupilR", { 0.271, 0.357, 0.069 }, { 0.483, 2.363, -3.162 }, INK, { joint = "Head", studs = false }),
		P(
			"GlintR",
			{ 0.131, 0.131, 0.046 },
			{ 0.557, 2.489, -3.208 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"BrowL",
			{ 0.575, 0.161, 0.115 },
			{ -0.483, 2.737, -3.082 },
			DARK,
			{ joint = "Head", rot = { 0, 0, -18 }, studs = false }
		),
		P(
			"EarL",
			{ 0.92, 0.92, 0.322 },
			{ -0.978, 3.048, -2.013 },
			VINE,
			{ joint = "Head", rot = { 0, -15, 20 }, studs = false }
		),
		P(
			"EarInnerL",
			{ 0.552, 0.552, 0.115 },
			{ -0.978, 3.013, -2.185 },
			TAN,
			{ joint = "Head", rot = { 0, -15, 20 }, studs = false }
		),
		P(
			"BrowR",
			{ 0.575, 0.161, 0.115 },
			{ 0.483, 2.737, -3.082 },
			DARK,
			{ joint = "Head", rot = { 0, 0, 18 }, studs = false }
		),
		P(
			"EarR",
			{ 0.92, 0.92, 0.322 },
			{ 0.978, 3.048, -2.013 },
			VINE,
			{ joint = "Head", rot = { 0, 15, -20 }, studs = false }
		),
		P(
			"EarInnerR",
			{ 0.552, 0.552, 0.115 },
			{ 0.978, 3.013, -2.185 },
			TAN,
			{ joint = "Head", rot = { 0, 15, -20 }, studs = false }
		),
		P(
			"HeadLeaf1",
			{ 0.69, 0.966, 0.161 },
			{ -0.508, 3.216, -1.893 },
			LEAF2,
			{ joint = "Head", rot = { 64.566, 176.843, -19.717 }, studs = false }
		),
		P(
			"HeadLeaf1Tip",
			{ 0.488, 0.488, 0.155 },
			{ -0.67, 3.42, -1.486 },
			LEAF2,
			{ joint = "Head", rot = { 64.566, 176.843, 25.283 }, studs = false }
		),
		P(
			"HeadLeaf2",
			{ 0.69, 0.966, 0.161 },
			{ 0.508, 3.216, -1.893 },
			LEAF,
			{ joint = "Head", rot = { 64.566, -176.843, 19.717 }, studs = false }
		),
		P(
			"HeadLeaf2Tip",
			{ 0.488, 0.488, 0.155 },
			{ 0.67, 3.42, -1.486 },
			LEAF,
			{ joint = "Head", rot = { -115.434, -3.157, -115.283 }, studs = false }
		),
		P(
			"HeadLeaf3",
			{ 0.69, 0.966, 0.161 },
			{ 0, 3.262, -1.886 },
			LEAF3,
			{ joint = "Head", rot = { 59.036, -180, 0 }, studs = false }
		),
		P(
			"HeadLeaf3Tip",
			{ 0.488, 0.488, 0.155 },
			{ 0, 3.51, -1.472 },
			LEAF3,
			{ joint = "Head", rot = { -120.964, 0, -135 }, studs = false }
		),
		P(
			"HingeArmL",
			{ 0.23, 0.23, 0.23 },
			{ -1.092, 1.38, -1.092 },
			VINE,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P("LegArmL", { 0.978, 1.265, 1.092 }, { -1.15, 0.747, -1.092 }, VINE, { joint = "ArmL" }),
		P(
			"BandArmL",
			{ 1.127, 0.253, 1.242 },
			{ -1.15, 0.862, -1.092 },
			DARK,
			{ joint = "ArmL", rot = { 0, 12, 0 }, studs = false }
		),
		P(
			"BandLeafArmL",
			{ 0.345, 0.092, 0.23 },
			{ -1.668, 0.978, -1.322 },
			LEAF3,
			{ joint = "ArmL", rot = { 0, 0, 30 }, studs = false }
		),
		P("ToeArmL1", { 0.299, 0.276, 0.414 }, { -1.472, 0.138, -1.644 }, CREAM, { joint = "ArmL", studs = false }),
		P("ToeArmL2", { 0.299, 0.276, 0.414 }, { -1.15, 0.138, -1.644 }, CREAM, { joint = "ArmL", studs = false }),
		P("ToeArmL3", { 0.299, 0.276, 0.414 }, { -0.828, 0.138, -1.644 }, CREAM, { joint = "ArmL", studs = false }),
		P(
			"HingeLegL",
			{ 0.23, 0.23, 0.23 },
			{ -1.092, 1.38, 1.782 },
			VINE,
			{ joint = "LegL", transparency = 1, studs = false }
		),
		P("LegLegL", { 0.978, 1.265, 1.092 }, { -1.15, 0.747, 1.782 }, VINE, { joint = "LegL" }),
		P(
			"BandLegL",
			{ 1.127, 0.253, 1.242 },
			{ -1.15, 0.862, 1.782 },
			DARK,
			{ joint = "LegL", rot = { 0, 12, 0 }, studs = false }
		),
		P(
			"BandLeafLegL",
			{ 0.345, 0.092, 0.23 },
			{ -1.668, 0.978, 1.553 },
			LEAF3,
			{ joint = "LegL", rot = { 0, 0, 30 }, studs = false }
		),
		P("ToeLegL1", { 0.299, 0.276, 0.414 }, { -1.472, 0.138, 1.23 }, CREAM, { joint = "LegL", studs = false }),
		P("ToeLegL2", { 0.299, 0.276, 0.414 }, { -1.15, 0.138, 1.23 }, CREAM, { joint = "LegL", studs = false }),
		P("ToeLegL3", { 0.299, 0.276, 0.414 }, { -0.828, 0.138, 1.23 }, CREAM, { joint = "LegL", studs = false }),
		P(
			"HingeArmR",
			{ 0.23, 0.23, 0.23 },
			{ 1.092, 1.38, -1.092 },
			VINE,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P("LegArmR", { 0.978, 1.265, 1.092 }, { 1.15, 0.747, -1.092 }, VINE, { joint = "ArmR" }),
		P(
			"BandArmR",
			{ 1.127, 0.253, 1.242 },
			{ 1.15, 0.862, -1.092 },
			DARK,
			{ joint = "ArmR", rot = { 0, 12, 0 }, studs = false }
		),
		P(
			"BandLeafArmR",
			{ 0.345, 0.092, 0.23 },
			{ 1.668, 0.978, -1.322 },
			LEAF3,
			{ joint = "ArmR", rot = { 0, 0, -30 }, studs = false }
		),
		P("ToeArmR1", { 0.299, 0.276, 0.414 }, { 0.828, 0.138, -1.644 }, CREAM, { joint = "ArmR", studs = false }),
		P("ToeArmR2", { 0.299, 0.276, 0.414 }, { 1.15, 0.138, -1.644 }, CREAM, { joint = "ArmR", studs = false }),
		P("ToeArmR3", { 0.299, 0.276, 0.414 }, { 1.472, 0.138, -1.644 }, CREAM, { joint = "ArmR", studs = false }),
		P(
			"HingeLegR",
			{ 0.23, 0.23, 0.23 },
			{ 1.092, 1.38, 1.782 },
			VINE,
			{ joint = "LegR", transparency = 1, studs = false }
		),
		P("LegLegR", { 0.978, 1.265, 1.092 }, { 1.15, 0.747, 1.782 }, VINE, { joint = "LegR" }),
		P(
			"BandLegR",
			{ 1.127, 0.253, 1.242 },
			{ 1.15, 0.862, 1.782 },
			DARK,
			{ joint = "LegR", rot = { 0, 12, 0 }, studs = false }
		),
		P(
			"BandLeafLegR",
			{ 0.345, 0.092, 0.23 },
			{ 1.668, 0.978, 1.553 },
			LEAF3,
			{ joint = "LegR", rot = { 0, 0, -30 }, studs = false }
		),
		P("ToeLegR1", { 0.299, 0.276, 0.414 }, { 0.828, 0.138, 1.23 }, CREAM, { joint = "LegR", studs = false }),
		P("ToeLegR2", { 0.299, 0.276, 0.414 }, { 1.15, 0.138, 1.23 }, CREAM, { joint = "LegR", studs = false }),
		P("ToeLegR3", { 0.299, 0.276, 0.414 }, { 1.472, 0.138, 1.23 }, CREAM, { joint = "LegR", studs = false }),
	},
}

return { egg = egg, pet = pet }
