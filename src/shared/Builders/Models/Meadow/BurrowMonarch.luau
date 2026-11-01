--!strict
-- The Burrow Monarch (Zone 1 Meadow, Mythic). Zone 1 Meadow roster (Config/Pets).
-- Pet: a massive mole-badger: a huge shoulder hump, colossal forelimbs with enormous cream digging claws, a broad head
--      with a burrowing snout, whiskers and glowing amber eyes, long ears lit amber inside, a crown of roots around a
--      gold band and an amber gem, green earthen armour plates with gold rims and leaf emblems, moss, a cream ruff and
--      glowing amber veins, floating rocks. Joints: Body, Head, EarL/R, ArmL/R, LegL/R, Tail, Rocks.
-- Egg: an imposing earthen egg of stone plates with roots, moss, glowing amber cracks and a root-and-gold crown.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/burrow_monarch.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(110, 65, 38) -- #6E4126
local MAIN2 = rgb(92, 54, 32) -- #5C3620
local DARK = rgb(58, 34, 20) -- #3A2214
local LIGHT = rgb(242, 228, 200) -- #F2E4C8
local GLOW = rgb(255, 174, 46) -- #FFAE2E
local STONE = rgb(140, 133, 120) -- #8C8578
local STONE2 = rgb(114, 108, 97) -- #726C61
local AMBER = rgb(255, 154, 31) -- #FF9A1F
local GOLD = rgb(227, 169, 51) -- #E3A933
local ROOT = rgb(90, 58, 34) -- #5A3A22
local MOSS = rgb(127, 181, 72) -- #7FB548
local LEAF = rgb(127, 194, 74) -- #7FC24A
local CLAW = rgb(244, 236, 216) -- #F4ECD8
local EAR = rgb(240, 168, 104) -- #F0A868
local ARMOUR = rgb(63, 126, 53) -- #3F7E35
local LIGHT2 = rgb(126, 76, 44) -- #7E4C2C
local FUR = rgb(242, 228, 200) -- #F2E4C8
local FUR2 = rgb(226, 207, 170) -- #E2CFAA
local CLAW2 = rgb(217, 203, 170) -- #D9CBAA
local ARMOUR2 = rgb(45, 94, 39) -- #2D5E27
local GOLD2 = rgb(184, 134, 42) -- #B8862A
local NOSE = rgb(58, 30, 24) -- #3A1E18
local EYE = rgb(255, 176, 46) -- #FFB02E
local INK = rgb(20, 10, 6) -- #140A06
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.794, 0.55, 1.794 }, { 0, 0.275, 0 }, DARK, { joint = "Body" }),
		P("Shell2", { 2.802, 0.55, 2.802 }, { 0, 0.825, 0 }, MAIN2, { joint = "Body" }),
		P("Shell3", { 3.221, 0.55, 3.221 }, { 0, 1.375, 0 }, MAIN, { joint = "Body" }),
		P("Shell4", { 3.332, 0.55, 3.332 }, { 0, 1.925, 0 }, MAIN2, { joint = "Body" }),
		P("Shell5", { 3.218, 0.55, 3.218 }, { 0, 2.475, 0 }, MAIN, { joint = "Body" }),
		P("Shell6", { 2.899, 0.55, 2.899 }, { 0, 3.025, 0 }, MAIN2, { joint = "Body" }),
		P("Shell7", { 2.351, 0.55, 2.351 }, { 0, 3.575, 0 }, MAIN, { joint = "Body" }),
		P("Shell8", { 1.402, 0.55, 1.402 }, { 0, 4.125, 0 }, MAIN2, { joint = "Body" }),
		P(
			"RarityBand",
			{ 2.962, 0.2, 2.962 },
			{ 0, 0.85, 0 },
			rgb(255, 60, 80),
			{ joint = "Body", material = "Neon", studs = false }
		),
		P("PlateBrick1", { 0.72, 0.58, 0.14 }, { -0.93, 1.45, -1.63 }, MAIN2, { joint = "Body", studs = false }),
		P("PlateBrick2", { 0.82, 0.5, 0.14 }, { 0.93, 1.45, -1.63 }, LIGHT2, { joint = "Body", studs = false }),
		P(
			"PlateBrick3",
			{ 0.62, 0.58, 0.14 },
			{ 1.63, 1.45, 0.93 },
			MAIN2,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateBrick4",
			{ 0.72, 0.5, 0.14 },
			{ 0.586, 1.45, 1.63 },
			LIGHT2,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateBrick5",
			{ 0.82, 0.58, 0.14 },
			{ -0.586, 1.45, 1.63 },
			MAIN2,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateBrick6",
			{ 0.62, 0.5, 0.14 },
			{ -1.63, 1.45, 0.93 },
			LIGHT2,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"PlateBrick7",
			{ 0.72, 0.58, 0.14 },
			{ -1.629, 2.3, -1.127 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"PlateBrick8",
			{ 0.82, 0.5, 0.14 },
			{ 1.629, 2.3, -1.127 },
			LIGHT2,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateBrick9",
			{ 0.62, 0.58, 0.14 },
			{ 1.629, 2.3, 0.284 },
			MAIN2,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateBrick10",
			{ 0.72, 0.5, 0.14 },
			{ 0.929, 2.3, 1.629 },
			LIGHT2,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateBrick11",
			{ 0.82, 0.58, 0.14 },
			{ -0.929, 2.3, 1.629 },
			MAIN2,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateBrick12",
			{ 0.62, 0.5, 0.14 },
			{ -1.629, 2.3, 0.284 },
			LIGHT2,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P("PlateBrick13", { 0.72, 0.58, 0.14 }, { -0.837, 3.15, -1.47 }, MAIN2, { joint = "Body", studs = false }),
		P("PlateBrick14", { 0.82, 0.5, 0.14 }, { 0.837, 3.15, -1.47 }, LIGHT2, { joint = "Body", studs = false }),
		P(
			"PlateBrick15",
			{ 0.62, 0.58, 0.14 },
			{ 1.47, 3.15, 0.528 },
			MAIN2,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"PlateBrick16",
			{ 0.72, 0.5, 0.14 },
			{ 0, 3.15, 1.47 },
			LIGHT2,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"PlateBrick17",
			{ 0.82, 0.58, 0.14 },
			{ -1.47, 3.15, 0.528 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Crack1",
			{ 0.16, 0.824, 0.08 },
			{ 0.085, 1.275, -1.606 },
			AMBER,
			{ joint = "Body", rot = { -16.775, 4.298, -13.961 }, material = "Neon", studs = false }
		),
		P(
			"Crack2",
			{ 0.16, 0.783, 0.08 },
			{ 0.028, 1.9, -1.71 },
			AMBER,
			{ joint = "Body", rot = { 0.116, 0.055, 25.155 }, material = "Neon", studs = false }
		),
		P(
			"Crack3",
			{ 0.16, 0.785, 0.08 },
			{ 0.007, 2.5, -1.629 },
			AMBER,
			{ joint = "Body", rot = { 12.891, -5.086, -21.172 }, material = "Neon", studs = false }
		),
		P(
			"Crack4",
			{ 0.16, 0.792, 0.08 },
			{ 0.063, 3.1, -1.413 },
			AMBER,
			{ joint = "Body", rot = { 23.615, 4.84, 10.924 }, material = "Neon", studs = false }
		),
		P(
			"Crack5",
			{ 0.16, 0.775, 0.08 },
			{ -0.018, 3.625, -1.038 },
			AMBER,
			{ joint = "Body", rot = { 46.329, 3.38, 3.222 }, material = "Neon", studs = false }
		),
		P(
			"CrackL1",
			{ 0.13, 0.761, 0.08 },
			{ -0.381, 2.375, -1.709 },
			AMBER,
			{ joint = "Body", rot = { 0, 0, 56.931 }, material = "Neon", studs = false }
		),
		P(
			"CrackL2",
			{ 0.13, 0.759, 0.08 },
			{ -0.954, 2.45, -1.709 },
			AMBER,
			{ joint = "Body", rot = { 0, 0, 108.237 }, material = "Neon", studs = false }
		),
		P(
			"CrackL3",
			{ 0.13, 0.88, 0.08 },
			{ -1.403, 2.55, -1.421 },
			AMBER,
			{ joint = "Body", rot = { 43.173, 26.597, 25.511 }, material = "Neon", studs = false }
		),
		P(
			"CrackR1",
			{ 0.13, 0.769, 0.08 },
			{ 0.456, 1.75, -1.738 },
			AMBER,
			{ joint = "Body", rot = { -2.295, 4.371, -62.26 }, material = "Neon", studs = false }
		),
		P(
			"CrackR2",
			{ 0.13, 0.781, 0.08 },
			{ 1.047, 1.775, -1.738 },
			AMBER,
			{ joint = "Body", rot = { -1.842, -4.481, -112.377 }, material = "Neon", studs = false }
		),
		P(
			"CrackR3",
			{ 0.13, 0.867, 0.08 },
			{ 1.559, 1.8, -1.439 },
			AMBER,
			{ joint = "Body", rot = { 31.887, -36.153, -43.479 }, material = "Neon", studs = false }
		),
		P(
			"CrackT1",
			{ 0.11, 0.729, 0.08 },
			{ 0.356, 3, -1.55 },
			AMBER,
			{ joint = "Body", rot = { 0, 0, -48.922 }, material = "Neon", studs = false }
		),
		P(
			"CrackT2",
			{ 0.11, 0.576, 0.08 },
			{ 0.689, 3.35, -1.413 },
			AMBER,
			{ joint = "Body", rot = { 31.728, -19.969, -28.914 }, material = "Neon", studs = false }
		),
		P(
			"CrackB1",
			{ 0.16, 0.904, 0.08 },
			{ 0.117, 1.35, 1.634 },
			AMBER,
			{ joint = "Body", rot = { 18.806, -6.155, -17.476 }, material = "Neon", studs = false }
		),
		P(
			"CrackB2",
			{ 0.16, 0.993, 0.08 },
			{ -0.025, 2.05, 1.738 },
			AMBER,
			{ joint = "Body", rot = { -3.029, -2.239, 36.435 }, material = "Neon", studs = false }
		),
		P(
			"CrackB3",
			{ 0.16, 0.912, 0.08 },
			{ -0.117, 2.75, 1.629 },
			AMBER,
			{ joint = "Body", rot = { -10.49, 4.969, -25.072 }, material = "Neon", studs = false }
		),
		P(
			"CrackB4",
			{ 0.16, 0.802, 0.08 },
			{ -0.036, 3.4, 1.413 },
			AMBER,
			{ joint = "Body", rot = { -22.842, -6.43, 14.889 }, material = "Neon", studs = false }
		),
		P(
			"CrackBL1",
			{ 0.12, 0.907, 0.08 },
			{ 0.598, 1.85, 1.766 },
			AMBER,
			{ joint = "Body", rot = { 0, 0, -67.599 }, material = "Neon", studs = false }
		),
		P(
			"CrackBL2",
			{ 0.12, 1.001, 0.08 },
			{ 1.364, 1.9, 1.616 },
			AMBER,
			{ joint = "Body", rot = { 4.993, 19.289, -104.815 }, material = "Neon", studs = false }
		),
		P(
			"CrackBR1",
			{ 0.12, 0.851, 0.08 },
			{ -0.595, 2.575, 1.629 },
			AMBER,
			{ joint = "Body", rot = { -6.238, -10.934, 60.043 }, material = "Neon", studs = false }
		),
		P(
			"CrackBR2",
			{ 0.12, 0.959, 0.08 },
			{ -1.307, 2.65, 1.479 },
			AMBER,
			{ joint = "Body", rot = { 2.355, -9.369, 104.179 }, material = "Neon", studs = false }
		),
		P(
			"MossBand1_1",
			{ 1.7, 0.42, 0.2 },
			{ -1.67, 1.5, 0 },
			rgb(95, 168, 58),
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"MossTuft1_1",
			{ 0.9, 0.2, 0.26 },
			{ -1.71, 1.74, -0.2 },
			LEAF,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"MossBand1_2",
			{ 1.7, 0.42, 0.2 },
			{ -1.669, 2.6, 0 },
			rgb(95, 168, 58),
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"MossTuft1_2",
			{ 0.9, 0.2, 0.26 },
			{ -1.709, 2.84, -0.2 },
			LEAF,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"MossBand3_1",
			{ 1.7, 0.42, 0.2 },
			{ 1.67, 1.5, 0 },
			rgb(95, 168, 58),
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"MossTuft3_1",
			{ 0.9, 0.2, 0.26 },
			{ 1.71, 1.74, 0.2 },
			LEAF,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"MossBand3_2",
			{ 1.7, 0.42, 0.2 },
			{ 1.669, 2.6, 0 },
			rgb(95, 168, 58),
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"MossTuft3_2",
			{ 0.9, 0.2, 0.26 },
			{ 1.709, 2.84, 0.2 },
			LEAF,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P("CrownBand", { 1.582, 0.24, 1.582 }, { 0, 3.85, 0 }, GOLD, { joint = "Body", studs = false }),
		P(
			"CrownGemSet",
			{ 0.7, 0.7, 0.14 },
			{ 0, 3.9, -0.881 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"CrownGem",
			{ 0.48, 0.48, 0.18 },
			{ 0, 3.9, -0.911 },
			AMBER,
			{ joint = "Body", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"CrownRoot11",
			{ 0.22, 0.63, 0.22 },
			{ 0.419, 4.213, -0.598 },
			ROOT,
			{ joint = "Body", rot = { -13.424, 2.288, -9.494 }, studs = false }
		),
		P(
			"CrownRoot12",
			{ 0.165, 0.48, 0.165 },
			{ 0.556, 4.597, -0.794 },
			ROOT,
			{ joint = "Body", rot = { -34.572, 23.459, -30.014 }, studs = false }
		),
		P(
			"CrownLeaf1",
			{ 0.4, 0.1, 0.26 },
			{ 0.717, 4.717, -1.023 },
			LEAF,
			{ joint = "Body", rot = { -35, -35, 0 }, studs = false }
		),
		P(
			"CrownRoot21",
			{ 0.22, 0.63, 0.22 },
			{ 0.73, 4.213, 0 },
			ROOT,
			{ joint = "Body", rot = { 0, 0, -16.699 }, studs = false }
		),
		P(
			"CrownRoot22",
			{ 0.165, 0.48, 0.165 },
			{ 0.969, 4.597, 0 },
			ROOT,
			{ joint = "Body", rot = { 0, 0, -53.13 }, studs = false }
		),
		P(
			"CrownLeaf2",
			{ 0.4, 0.1, 0.26 },
			{ 1.249, 4.717, 0 },
			LEAF,
			{ joint = "Body", rot = { 0, -90, 35 }, studs = false }
		),
		P(
			"CrownRoot31",
			{ 0.22, 0.63, 0.22 },
			{ 0.419, 4.213, 0.598 },
			ROOT,
			{ joint = "Body", rot = { 13.424, -2.288, -9.494 }, studs = false }
		),
		P(
			"CrownRoot32",
			{ 0.165, 0.48, 0.165 },
			{ 0.556, 4.597, 0.794 },
			ROOT,
			{ joint = "Body", rot = { 34.572, -23.459, -30.014 }, studs = false }
		),
		P(
			"CrownLeaf3",
			{ 0.4, 0.1, 0.26 },
			{ 0.717, 4.717, 1.023 },
			LEAF,
			{ joint = "Body", rot = { -35, -145, 0 }, studs = false }
		),
		P(
			"CrownRoot41",
			{ 0.22, 0.63, 0.22 },
			{ -0.419, 4.213, 0.598 },
			ROOT,
			{ joint = "Body", rot = { 13.424, 2.288, 9.494 }, studs = false }
		),
		P(
			"CrownRoot42",
			{ 0.165, 0.48, 0.165 },
			{ -0.556, 4.597, 0.794 },
			ROOT,
			{ joint = "Body", rot = { 34.572, 23.459, 30.014 }, studs = false }
		),
		P(
			"CrownLeaf4",
			{ 0.4, 0.1, 0.26 },
			{ -0.717, 4.717, 1.023 },
			LEAF,
			{ joint = "Body", rot = { -35, 145, 0 }, studs = false }
		),
		P(
			"CrownRoot51",
			{ 0.22, 0.63, 0.22 },
			{ -0.73, 4.213, 0 },
			ROOT,
			{ joint = "Body", rot = { 0, 0, 16.699 }, studs = false }
		),
		P(
			"CrownRoot52",
			{ 0.165, 0.48, 0.165 },
			{ -0.969, 4.597, 0 },
			ROOT,
			{ joint = "Body", rot = { 0, 0, 53.13 }, studs = false }
		),
		P(
			"CrownLeaf5",
			{ 0.4, 0.1, 0.26 },
			{ -1.249, 4.717, 0 },
			LEAF,
			{ joint = "Body", rot = { 0, 90, -35 }, studs = false }
		),
		P(
			"CrownRoot61",
			{ 0.22, 0.63, 0.22 },
			{ -0.419, 4.213, -0.598 },
			ROOT,
			{ joint = "Body", rot = { -13.424, -2.288, 9.494 }, studs = false }
		),
		P(
			"CrownRoot62",
			{ 0.165, 0.48, 0.165 },
			{ -0.556, 4.597, -0.794 },
			ROOT,
			{ joint = "Body", rot = { -34.572, -23.459, 30.014 }, studs = false }
		),
		P(
			"CrownLeaf6",
			{ 0.4, 0.1, 0.26 },
			{ -0.717, 4.717, -1.023 },
			LEAF,
			{ joint = "Body", rot = { -35, 35, 0 }, studs = false }
		),
		P(
			"CrownStem1",
			{ 0.24, 0.58, 0.24 },
			{ 0.049, 4.645, 0 },
			ROOT,
			{ joint = "Body", rot = { 0, 0, -11.31 }, studs = false }
		),
		P(
			"CrownStem2",
			{ 0.192, 0.43, 0.192 },
			{ 0.19, 5.038, 0.018 },
			ROOT,
			{ joint = "Body", rot = { 5.136, -3.203, -31.862 }, studs = false }
		),
		P(
			"CrownStemLeaf",
			{ 0.46, 0.1, 0.3 },
			{ 0.283, 5.185, 0.037 },
			LEAF,
			{ joint = "Body", rot = { 0, 0, -30 }, studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P(
			"HingeBody",
			{ 0.23, 0.23, 0.23 },
			{ 0, 2.76, 0.46 },
			MAIN,
			{ joint = "Body", transparency = 1, studs = false }
		),
		P("Shoulders", { 4.255, 2.875, 2.3 }, { 0, 3.45, -1.15 }, MAIN, { joint = "Body", rot = { -8, 0, 0 } }),
		P("Hump", { 3.335, 0.805, 1.955 }, { 0, 5.002, -0.978 }, MAIN2, { joint = "Body", rot = { -8, 0, 0 } }),
		P("Torso", { 3.565, 2.3, 2.76 }, { 0, 2.875, 1.092 }, MAIN2, { joint = "Body" }),
		P("Haunches", { 3.45, 2.185, 1.725 }, { 0, 2.645, 2.818 }, MAIN, { joint = "Body" }),
		P("Belly", { 2.76, 0.517, 4.14 }, { 0, 1.587, 0.69 }, FUR2, { joint = "Body", studs = false }),
		P(
			"Saddle",
			{ 2.875, 2.415, 0.345 },
			{ 0, 4.312, 0.978 },
			ARMOUR,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleInset",
			{ 2.3, 1.884, 0.368 },
			{ 0, 4.335, 0.98 },
			ARMOUR2,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleRimH0",
			{ 2.99, 0.161, 0.391 },
			{ 0, 4.191, 2.179 },
			GOLD,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleRimH2",
			{ 2.99, 0.161, 0.391 },
			{ 0, 4.479, -0.219 },
			GOLD,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleRimV0",
			{ 0.161, 2.415, 0.391 },
			{ -1.438, 4.335, 0.98 },
			GOLD,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleRimV2",
			{ 0.161, 2.415, 0.391 },
			{ 1.438, 4.335, 0.98 },
			GOLD,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleEmblemFrame",
			{ 1.207, 1.207, 0.138 },
			{ 0, 4.518, 1.002 },
			GOLD,
			{ joint = "Body", rot = { -83.157, 0, 45 }, studs = false }
		),
		P(
			"SaddleEmblemField",
			{ 0.942, 0.942, 0.161 },
			{ 0, 4.529, 1.004 },
			ARMOUR2,
			{ joint = "Body", rot = { -83.157, 0, 45 }, studs = false }
		),
		P(
			"SaddleEmblemLeaf",
			{ 0.386, 0.966, 0.184 },
			{ 0, 4.541, 1.005 },
			LEAF,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"SaddleEmblemVein",
			{ 0.072, 0.845, 0.207 },
			{ 0, 4.552, 1.006 },
			GOLD,
			{ joint = "Body", rot = { -83.157, 0, 0 }, studs = false }
		),
		P(
			"FlankL",
			{ 2.185, 1.725, 0.345 },
			{ -1.863, 3.162, 1.207 },
			ARMOUR,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLInset",
			{ 1.748, 1.345, 0.368 },
			{ -1.885, 3.169, 1.207 },
			ARMOUR2,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLRimH0",
			{ 2.3, 0.161, 0.391 },
			{ -2.133, 2.343, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLRimH2",
			{ 2.3, 0.161, 0.391 },
			{ -1.637, 3.995, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLRimV0",
			{ 0.161, 1.725, 0.391 },
			{ -1.885, 3.169, 0.115 },
			GOLD,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLRimV2",
			{ 0.161, 1.725, 0.391 },
			{ -1.885, 3.169, 2.3 },
			GOLD,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLEmblemFrame",
			{ 0.862, 0.862, 0.138 },
			{ -2.061, 3.222, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, -73.301, -45 }, studs = false }
		),
		P(
			"FlankLEmblemField",
			{ 0.673, 0.673, 0.161 },
			{ -2.072, 3.225, 1.207 },
			ARMOUR2,
			{ joint = "Body", rot = { -90, -73.301, -45 }, studs = false }
		),
		P(
			"FlankLEmblemLeaf",
			{ 0.276, 0.69, 0.184 },
			{ -2.083, 3.229, 1.207 },
			LEAF,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankLEmblemVein",
			{ 0.052, 0.604, 0.207 },
			{ -2.094, 3.232, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, -73.301, -90 }, studs = false }
		),
		P(
			"FlankR",
			{ 2.185, 1.725, 0.345 },
			{ 1.863, 3.162, 1.207 },
			ARMOUR,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankRInset",
			{ 1.748, 1.345, 0.368 },
			{ 1.885, 3.169, 1.207 },
			ARMOUR2,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankRRimH0",
			{ 2.3, 0.161, 0.391 },
			{ 2.133, 2.343, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankRRimH2",
			{ 2.3, 0.161, 0.391 },
			{ 1.637, 3.995, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankRRimV0",
			{ 0.161, 1.725, 0.391 },
			{ 1.885, 3.169, 2.3 },
			GOLD,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankRRimV2",
			{ 0.161, 1.725, 0.391 },
			{ 1.885, 3.169, 0.115 },
			GOLD,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankREmblemFrame",
			{ 0.862, 0.862, 0.138 },
			{ 2.061, 3.222, 1.207 },
			GOLD,
			{ joint = "Body", rot = { 90, 106.699, -45 }, studs = false }
		),
		P(
			"FlankREmblemField",
			{ 0.673, 0.673, 0.161 },
			{ 2.072, 3.225, 1.207 },
			ARMOUR2,
			{ joint = "Body", rot = { 90, 106.699, -45 }, studs = false }
		),
		P(
			"FlankREmblemLeaf",
			{ 0.276, 0.69, 0.184 },
			{ 2.083, 3.229, 1.207 },
			LEAF,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P(
			"FlankREmblemVein",
			{ 0.052, 0.604, 0.207 },
			{ 2.094, 3.232, 1.207 },
			GOLD,
			{ joint = "Body", rot = { -90, 73.301, 90 }, studs = false }
		),
		P("Moss1", { 0.805, 0.368, 0.69 }, { -1.265, 4.025, -0.23 }, MOSS, { joint = "Body", studs = false }),
		P(
			"Moss2",
			{ 0.805, 0.368, 0.69 },
			{ 1.322, 4.025, -0.402 },
			MOSS,
			{ joint = "Body", rot = { 0, 25, 0 }, studs = false }
		),
		P(
			"Moss3",
			{ 0.805, 0.368, 0.69 },
			{ -1.035, 3.737, 2.415 },
			MOSS,
			{ joint = "Body", rot = { 0, 50, 0 }, studs = false }
		),
		P(
			"Moss4",
			{ 0.805, 0.368, 0.69 },
			{ 1.15, 3.737, 2.53 },
			MOSS,
			{ joint = "Body", rot = { 0, 75, 0 }, studs = false }
		),
		P(
			"Moss5",
			{ 0.805, 0.368, 0.69 },
			{ 0, 3.737, 2.99 },
			MOSS,
			{ joint = "Body", rot = { 0, 100, 0 }, studs = false }
		),
		P(
			"Ruff1",
			{ 0.862, 0.862, 0.632 },
			{ 0, 4.025, -2.357 },
			FUR,
			{ joint = "Body", rot = { -118.811, 45, 0 }, studs = false }
		),
		P(
			"Ruff2",
			{ 0.862, 0.862, 0.632 },
			{ -0.978, 3.622, -2.185 },
			FUR2,
			{ joint = "Body", rot = { -144.754, 63.402, 28.55 }, studs = false }
		),
		P(
			"Ruff3",
			{ 0.862, 0.862, 0.632 },
			{ 0.978, 3.622, -2.185 },
			FUR,
			{ joint = "Body", rot = { -113.434, 23.159, -13.458 }, studs = false }
		),
		P(
			"Ruff4",
			{ 0.863, 0.863, 0.632 },
			{ -1.668, 2.99, -1.84 },
			FUR2,
			{ joint = "Body", rot = { 11.195, 113.66, -127.551 }, studs = false }
		),
		P(
			"Ruff5",
			{ 0.862, 0.863, 0.632 },
			{ 1.668, 2.99, -1.84 },
			FUR,
			{ joint = "Body", rot = { -113.955, 14.157, -19.156 }, studs = false }
		),
		P(
			"Ruff6",
			{ 0.863, 0.862, 0.632 },
			{ -0.575, 2.875, -2.415 },
			FUR2,
			{ joint = "Body", rot = { -128.499, 56.028, 11.632 }, studs = false }
		),
		P(
			"Ruff7",
			{ 0.862, 0.862, 0.632 },
			{ 0.575, 2.875, -2.415 },
			FUR,
			{ joint = "Body", rot = { -114.558, 33.183, -7.737 }, studs = false }
		),
		P(
			"Ruff8",
			{ 0.862, 0.862, 0.632 },
			{ 0, 2.415, -2.3 },
			FUR2,
			{ joint = "Body", rot = { -118.811, 45, 0 }, studs = false }
		),
		P(
			"Fur1_1",
			{ 0.828, 0.207, 1.092 },
			{ -1.092, 4.887, -2.013 },
			DARK,
			{ joint = "Body", rot = { -20.044, 20.732, 16.555 }, studs = false }
		),
		P(
			"Fur1_2",
			{ 0.828, 0.207, 1.092 },
			{ -0.368, 4.887, -2.013 },
			MAIN2,
			{ joint = "Body", rot = { -17.95, 36.234, 6.602 }, studs = false }
		),
		P(
			"Fur1_3",
			{ 0.828, 0.207, 1.092 },
			{ 0.368, 4.887, -2.013 },
			DARK,
			{ joint = "Body", rot = { -6.871, 53.251, -8.916 }, studs = false }
		),
		P(
			"Fur1_4",
			{ 0.828, 0.207, 1.092 },
			{ 1.092, 4.887, -2.013 },
			MAIN2,
			{ joint = "Body", rot = { 19.978, 63.698, -36.972 }, studs = false }
		),
		P(
			"Fur2_1",
			{ 0.828, 0.207, 1.092 },
			{ -1.265, 5.29, -1.38 },
			MAIN2,
			{ joint = "Body", rot = { -19.896, 17.687, 18.665 }, studs = false }
		),
		P(
			"Fur2_2",
			{ 0.828, 0.207, 1.092 },
			{ -0.426, 5.29, -1.38 },
			DARK,
			{ joint = "Body", rot = { -18.342, 34.882, 7.499 }, studs = false }
		),
		P(
			"Fur2_3",
			{ 0.828, 0.207, 1.092 },
			{ 0.426, 5.29, -1.38 },
			MAIN2,
			{ joint = "Body", rot = { -5.379, 54.421, -10.604 }, studs = false }
		),
		P(
			"Fur2_4",
			{ 0.828, 0.207, 1.092 },
			{ 1.265, 5.29, -1.38 },
			DARK,
			{ joint = "Body", rot = { 28.135, 64.505, -45.102 }, studs = false }
		),
		P(
			"Fur3_1",
			{ 0.828, 0.207, 1.092 },
			{ -0.978, 5.233, -0.69 },
			DARK,
			{ joint = "Body", rot = { -20.039, 22.916, 15.113 }, studs = false }
		),
		P(
			"Fur3_2",
			{ 0.828, 0.207, 1.092 },
			{ 0, 5.233, -0.69 },
			MAIN2,
			{ joint = "Body", rot = { -14.036, 45, 0 }, studs = false }
		),
		P(
			"Fur3_3",
			{ 0.828, 0.207, 1.092 },
			{ 0.978, 5.233, -0.69 },
			DARK,
			{ joint = "Body", rot = { 14.705, 62.775, -31.664 }, studs = false }
		),
		P(
			"PauldronL",
			{ 1.955, 1.61, 0.403 },
			{ -2.243, 4.312, -1.322 },
			ARMOUR,
			{ joint = "Body", rot = { -104.036, -58.265, -106.381 } }
		),
		P(
			"PauldronRimL",
			{ 2.127, 0.184, 0.46 },
			{ -1.856, 5.017, -1.264 },
			GOLD,
			{ joint = "Body", rot = { -104.036, -58.265, -106.381 }, studs = false }
		),
		P(
			"PauldronRim2L",
			{ 2.127, 0.184, 0.46 },
			{ -2.668, 3.632, -1.386 },
			GOLD,
			{ joint = "Body", rot = { -104.036, -58.265, -106.381 }, studs = false }
		),
		P(
			"PauldronGemL",
			{ 0.483, 0.483, 0.483 },
			{ -2.438, 4.43, -1.352 },
			AMBER,
			{ joint = "Body", rot = { -104.036, -58.265, -61.381 }, material = "Neon", studs = false }
		),
		P(
			"SideRuffL",
			{ 0.575, 1.15, 1.495 },
			{ -2.185, 2.645, -2.128 },
			FUR,
			{ joint = "Body", rot = { 0, 0, -15 }, studs = false }
		),
		P(
			"PauldronR",
			{ 1.955, 1.61, 0.403 },
			{ 2.243, 4.312, -1.322 },
			ARMOUR,
			{ joint = "Body", rot = { -104.036, 58.265, 106.381 } }
		),
		P(
			"PauldronRimR",
			{ 2.127, 0.184, 0.46 },
			{ 1.856, 5.017, -1.264 },
			GOLD,
			{ joint = "Body", rot = { -104.036, 58.265, 106.381 }, studs = false }
		),
		P(
			"PauldronRim2R",
			{ 2.127, 0.184, 0.46 },
			{ 2.668, 3.632, -1.386 },
			GOLD,
			{ joint = "Body", rot = { -104.036, 58.265, 106.381 }, studs = false }
		),
		P(
			"PauldronGemR",
			{ 0.483, 0.483, 0.483 },
			{ 2.438, 4.43, -1.352 },
			AMBER,
			{ joint = "Body", rot = { 75.964, 121.735, -28.619 }, material = "Neon", studs = false }
		),
		P(
			"SideRuffR",
			{ 0.575, 1.15, 1.495 },
			{ 2.185, 2.645, -2.128 },
			FUR,
			{ joint = "Body", rot = { 0, 0, 15 }, studs = false }
		),
		P("Stone1", { 0.632, 0.759, 0.632 }, { -0.92, 4.6, 2.53 }, STONE, { joint = "Body", rot = { 0, 35, 15 } }),
		P("Stone2", { 0.552, 0.662, 0.552 }, { 1.035, 4.543, 2.3 }, STONE, { joint = "Body", rot = { 20, 35, 15 } }),
		P("Stone3", { 0.483, 0.58, 0.483 }, { 0.23, 4.773, 2.818 }, STONE, { joint = "Body", rot = { 40, 35, 15 } }),
		P("Stone4", { 0.506, 0.607, 0.506 }, { -1.438, 4.082, 0 }, STONE, { joint = "Body", rot = { 60, 35, 15 } }),
		P(
			"ChestGemSet",
			{ 1.092, 1.092, 0.184 },
			{ 0, 3.277, -2.679 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"ChestGemRim",
			{ 0.92, 0.92, 0.207 },
			{ 0, 3.277, -2.702 },
			GOLD2,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"ChestGem",
			{ 0.713, 0.713, 0.23 },
			{ 0, 3.277, -2.737 },
			AMBER,
			{ joint = "Body", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"ChestGemCore",
			{ 0.299, 0.299, 0.253 },
			{ 0, 3.277, -2.772 },
			GLOW,
			{ joint = "Body", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"RumpFur1_1",
			{ 0.863, 0.805, 0.69 },
			{ -0.978, 3.565, 3.68 },
			FUR,
			{ joint = "Body", rot = { -20, 0, -15 }, studs = false }
		),
		P(
			"RumpFur1_2",
			{ 0.863, 0.805, 0.69 },
			{ -0.978, 2.76, 3.795 },
			FUR2,
			{ joint = "Body", rot = { -20, 0, -15 }, studs = false }
		),
		P(
			"RumpFur1_3",
			{ 0.863, 0.805, 0.69 },
			{ -0.978, 4.14, 3.392 },
			FUR,
			{ joint = "Body", rot = { -20, 0, -15 }, studs = false }
		),
		P(
			"RumpFur3_1",
			{ 0.863, 0.805, 0.69 },
			{ 0.978, 3.565, 3.68 },
			FUR,
			{ joint = "Body", rot = { -20, 0, 15 }, studs = false }
		),
		P(
			"RumpFur3_2",
			{ 0.863, 0.805, 0.69 },
			{ 0.978, 2.76, 3.795 },
			FUR2,
			{ joint = "Body", rot = { -20, 0, 15 }, studs = false }
		),
		P(
			"RumpFur3_3",
			{ 0.863, 0.805, 0.69 },
			{ 0.978, 4.14, 3.392 },
			FUR,
			{ joint = "Body", rot = { -20, 0, 15 }, studs = false }
		),
		P(
			"RumpPlate",
			{ 2.185, 1.38, 0.345 },
			{ 0, 3.967, 3.162 },
			ARMOUR,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateInset",
			{ 1.748, 1.076, 0.368 },
			{ 0, 3.983, 3.18 },
			ARMOUR2,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateRimH0",
			{ 2.3, 0.161, 0.391 },
			{ 0, 3.461, 3.632 },
			GOLD,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateRimH2",
			{ 2.3, 0.161, 0.391 },
			{ 0, 4.504, 2.728 },
			GOLD,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateRimV0",
			{ 0.161, 1.38, 0.391 },
			{ -1.092, 3.983, 3.18 },
			GOLD,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateRimV2",
			{ 0.161, 1.38, 0.391 },
			{ 1.092, 3.983, 3.18 },
			GOLD,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateEmblemFrame",
			{ 0.69, 0.69, 0.138 },
			{ 0, 4.103, 3.319 },
			GOLD,
			{ joint = "Body", rot = { -40.914, 0, 45 }, studs = false }
		),
		P(
			"RumpPlateEmblemField",
			{ 0.538, 0.538, 0.161 },
			{ 0, 4.111, 3.328 },
			ARMOUR2,
			{ joint = "Body", rot = { -40.914, 0, 45 }, studs = false }
		),
		P(
			"RumpPlateEmblemLeaf",
			{ 0.221, 0.552, 0.184 },
			{ 0, 4.118, 3.336 },
			LEAF,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"RumpPlateEmblemVein",
			{ 0.041, 0.483, 0.207 },
			{ 0, 4.126, 3.345 },
			GOLD,
			{ joint = "Body", rot = { -40.914, 0, 0 }, studs = false }
		),
		P(
			"VeinL1",
			{ 0.115, 1.886, 0.115 },
			{ -2.151, 3.737, -1.265 },
			AMBER,
			{ joint = "Body", rot = { -37.562, 0.537, 179.301 }, material = "Neon", studs = false }
		),
		P(
			"VeinL2",
			{ 0.115, 1.061, 0.115 },
			{ -2.145, 2.587, -1.035 },
			AMBER,
			{ joint = "Body", rot = { 40.549, 1.596, -178.136 }, material = "Neon", studs = false }
		),
		P(
			"VeinR1",
			{ 0.115, 1.886, 0.115 },
			{ 2.151, 3.737, -1.265 },
			AMBER,
			{ joint = "Body", rot = { -37.562, -0.537, -179.301 }, material = "Neon", studs = false }
		),
		P(
			"VeinR2",
			{ 0.115, 1.061, 0.115 },
			{ 2.145, 2.587, -1.035 },
			AMBER,
			{ joint = "Body", rot = { 40.549, -1.596, 178.136 }, material = "Neon", studs = false }
		),
		P(
			"HingeTail",
			{ 0.23, 0.23, 0.23 },
			{ 0, 3.22, 3.622 },
			MAIN,
			{ joint = "Tail", transparency = 1, studs = false }
		),
		P("Tail", { 1.495, 1.323, 1.035 }, { 0, 3.392, 3.91 }, FUR, { joint = "Tail", rot = { 20, 0, 0 } }),
		P("TailMid", { 1.15, 1.035, 0.805 }, { 0, 3.852, 4.37 }, FUR2, { joint = "Tail", rot = { 35, 0, 0 } }),
		P(
			"TailTip",
			{ 0.805, 0.69, 0.575 },
			{ 0, 4.255, 4.658 },
			FUR,
			{ joint = "Tail", rot = { 50, 0, 0 }, studs = false }
		),
		P(
			"TailTuft1",
			{ 0.632, 0.69, 0.632 },
			{ -0.632, 3.45, 4.198 },
			FUR2,
			{ joint = "Tail", rot = { 0, 0, -30 }, studs = false }
		),
		P(
			"TailTuft3",
			{ 0.632, 0.69, 0.632 },
			{ 0.632, 3.45, 4.198 },
			FUR2,
			{ joint = "Tail", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"HingeRocks",
			{ 0.23, 0.23, 0.23 },
			{ 0, 3.45, 0.46 },
			MAIN,
			{ joint = "Rocks", transparency = 1, studs = false }
		),
		P("Rock1", { 0.632, 0.538, 0.632 }, { -3.45, 5.06, -1.38 }, STONE, { joint = "Rocks", rot = { 0, 40, 20 } }),
		P(
			"RockChip1",
			{ 0.253, 0.253, 0.253 },
			{ -3.45, 5.326, -1.38 },
			AMBER,
			{ joint = "Rocks", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P("Rock2", { 0.517, 0.44, 0.517 }, { 3.565, 5.52, 0.23 }, STONE, { joint = "Rocks", rot = { 25, 55, 20 } }),
		P(
			"RockChip2",
			{ 0.207, 0.207, 0.207 },
			{ 3.565, 5.737, 0.23 },
			AMBER,
			{ joint = "Rocks", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P("Rock3", { 0.46, 0.391, 0.46 }, { -3.105, 3.68, 2.185 }, STONE, { joint = "Rocks", rot = { 50, 70, 20 } }),
		P(
			"RockChip3",
			{ 0.184, 0.184, 0.184 },
			{ -3.105, 3.873, 2.185 },
			AMBER,
			{ joint = "Rocks", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P("Rock4", { 0.575, 0.489, 0.575 }, { 2.99, 3.91, 2.76 }, STONE, { joint = "Rocks", rot = { 75, 85, 20 } }),
		P(
			"RockChip4",
			{ 0.23, 0.23, 0.23 },
			{ 2.99, 4.151, 2.76 },
			AMBER,
			{ joint = "Rocks", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"Rock5",
			{ 0.414, 0.352, 0.414 },
			{ 0.46, 6.44, 1.84 },
			STONE,
			{ joint = "Rocks", rot = { 100, 100, 20 }, studs = false }
		),
		P(
			"RockChip5",
			{ 0.166, 0.166, 0.166 },
			{ 0.46, 6.614, 1.84 },
			AMBER,
			{ joint = "Rocks", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P("Rock6", { 0.483, 0.411, 0.483 }, { -1.61, 5.98, -2.99 }, STONE, { joint = "Rocks", rot = { 125, 115, 20 } }),
		P(
			"RockChip6",
			{ 0.193, 0.193, 0.193 },
			{ -1.61, 6.183, -2.99 },
			AMBER,
			{ joint = "Rocks", rot = { 0, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"HingeHead",
			{ 0.23, 0.23, 0.23 },
			{ 0, 3.565, -2.185 },
			MAIN,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P("Skull", { 2.3, 1.725, 1.725 }, { 0, 3.736, -3.261 }, MAIN, { joint = "Head", rot = { 8, 0, 0 } }),
		P(
			"Brow",
			{ 2.185, 0.437, 0.575 },
			{ 0, 4.348, -3.896 },
			MAIN2,
			{ joint = "Head", rot = { 8, 0, 0 }, studs = false }
		),
		P("Muzzle", { 1.495, 1.035, 1.15 }, { 0, 3.433, -4.407 }, FUR2, { joint = "Head", rot = { 8, 0, 0 } }),
		P("Snout", { 0.92, 0.69, 0.69 }, { 0, 3.594, -5.14 }, FUR, { joint = "Head", rot = { 8, 0, 0 } }),
		P(
			"Nose",
			{ 0.69, 0.437, 0.299 },
			{ 0, 3.798, -5.517 },
			NOSE,
			{ joint = "Head", rot = { 8, 0, 0 }, studs = false }
		),
		P(
			"Mouth",
			{ 0.805, 0.092, 0.069 },
			{ 0, 3.157, -5.085 },
			INK,
			{ joint = "Head", rot = { 8, 0, 0 }, studs = false }
		),
		P(
			"ToothL",
			{ 0.23, 0.368, 0.115 },
			{ -0.138, 2.966, -5.054 },
			CLAW,
			{ joint = "Head", rot = { 8, 0, 0 }, studs = false }
		),
		P("CheekL", { 0.575, 1.092, 1.15 }, { -1.092, 3.41, -3.83 }, FUR, { joint = "Head", rot = { 8, 0, -12 } }),
		P(
			"SocketL",
			{ 0.598, 0.345, 0.092 },
			{ -0.598, 4.032, -4.126 },
			INK,
			{ joint = "Head", rot = { 8, 0, 16 }, studs = false }
		),
		P(
			"EyeL",
			{ 0.46, 0.207, 0.069 },
			{ -0.598, 4.04, -4.183 },
			EYE,
			{ joint = "Head", rot = { 8, 0, 16 }, material = "Neon", studs = false }
		),
		P(
			"PupilL",
			{ 0.138, 0.196, 0.057 },
			{ -0.529, 4.046, -4.228 },
			INK,
			{ joint = "Head", rot = { 8, 0, 16 }, studs = false }
		),
		P(
			"GlintL",
			{ 0.08, 0.08, 0.046 },
			{ -0.69, 4.107, -4.243 },
			FUR,
			{ joint = "Head", rot = { 8, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"BrowRidgeL",
			{ 0.805, 0.207, 0.345 },
			{ -0.598, 4.289, -4.055 },
			DARK,
			{ joint = "Head", rot = { 8, 0, -18 }, studs = false }
		),
		P(
			"WhiskerL1",
			{ 0.058, 1.161, 0.057 },
			{ -1.093, 3.617, -5.136 },
			CLAW,
			{ joint = "Head", rot = { -0.544, -4.803, 83.533 }, studs = false }
		),
		P(
			"WhiskerL2",
			{ 0.057, 1.152, 0.057 },
			{ -1.093, 3.422, -5.077 },
			CLAW,
			{ joint = "Head", rot = { -0.072, 2.674, 91.535 }, studs = false }
		),
		P(
			"WhiskerL3",
			{ 0.057, 1.184, 0.057 },
			{ -1.093, 3.228, -5.017 },
			CLAW,
			{ joint = "Head", rot = { -1.657, 9.853, 99.594 }, studs = false }
		),
		P(
			"ToothR",
			{ 0.23, 0.368, 0.115 },
			{ 0.138, 2.966, -5.054 },
			CLAW,
			{ joint = "Head", rot = { 8, 0, 0 }, studs = false }
		),
		P("CheekR", { 0.575, 1.092, 1.15 }, { 1.092, 3.41, -3.83 }, FUR, { joint = "Head", rot = { 8, 0, 12 } }),
		P(
			"SocketR",
			{ 0.598, 0.345, 0.092 },
			{ 0.598, 4.032, -4.126 },
			INK,
			{ joint = "Head", rot = { 8, 0, -16 }, studs = false }
		),
		P(
			"EyeR",
			{ 0.46, 0.207, 0.069 },
			{ 0.598, 4.04, -4.183 },
			EYE,
			{ joint = "Head", rot = { 8, 0, -16 }, material = "Neon", studs = false }
		),
		P(
			"PupilR",
			{ 0.138, 0.196, 0.057 },
			{ 0.529, 4.046, -4.228 },
			INK,
			{ joint = "Head", rot = { 8, 0, -16 }, studs = false }
		),
		P(
			"GlintR",
			{ 0.08, 0.08, 0.046 },
			{ 0.69, 4.107, -4.243 },
			FUR,
			{ joint = "Head", rot = { 8, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"BrowRidgeR",
			{ 0.805, 0.207, 0.345 },
			{ 0.598, 4.289, -4.055 },
			DARK,
			{ joint = "Head", rot = { 8, 0, 18 }, studs = false }
		),
		P(
			"WhiskerR1",
			{ 0.058, 1.161, 0.057 },
			{ 1.093, 3.617, -5.136 },
			CLAW,
			{ joint = "Head", rot = { -0.544, 4.803, -83.533 }, studs = false }
		),
		P(
			"WhiskerR2",
			{ 0.057, 1.152, 0.057 },
			{ 1.093, 3.422, -5.077 },
			CLAW,
			{ joint = "Head", rot = { -0.072, -2.674, -91.535 }, studs = false }
		),
		P(
			"WhiskerR3",
			{ 0.057, 1.184, 0.057 },
			{ 1.093, 3.228, -5.017 },
			CLAW,
			{ joint = "Head", rot = { -1.657, -9.853, -99.594 }, studs = false }
		),
		P(
			"CrownBand",
			{ 1.955, 0.276, 1.61 },
			{ 0, 4.582, -3.085 },
			GOLD,
			{ joint = "Head", rot = { 8, 0, 0 }, studs = false }
		),
		P(
			"CrownGemSet",
			{ 0.713, 0.713, 0.184 },
			{ 0, 4.927, -3.884 },
			GOLD,
			{ joint = "Head", rot = { 8, 0, 45 }, studs = false }
		),
		P(
			"CrownGem",
			{ 0.506, 0.506, 0.207 },
			{ 0, 4.933, -3.929 },
			AMBER,
			{ joint = "Head", rot = { 8, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"CrownRoot11",
			{ 0.23, 0.724, 0.23 },
			{ -0.946, 4.987, -3.522 },
			ROOT,
			{ joint = "Head", rot = { 10.939, 5.551, 26.586 }, studs = false }
		),
		P(
			"CrownRoot12",
			{ 0.172, 0.61, 0.172 },
			{ -1.265, 5.431, -3.375 },
			ROOT,
			{ joint = "Head", rot = { 12.625, 12.999, 45.122 }, studs = false }
		),
		P(
			"Sprout1",
			{ 0.391, 0.138, 0.299 },
			{ -1.444, 5.6, -3.294 },
			LEAF,
			{ joint = "Head", rot = { 6.39, 3.216, 56.61 }, studs = false }
		),
		P(
			"CrownRoot21",
			{ 0.23, 0.724, 0.23 },
			{ 0.946, 4.987, -3.522 },
			ROOT,
			{ joint = "Head", rot = { 10.939, -5.551, -26.586 }, studs = false }
		),
		P(
			"CrownRoot22",
			{ 0.172, 0.61, 0.172 },
			{ 1.265, 5.431, -3.375 },
			ROOT,
			{ joint = "Head", rot = { 12.625, -12.999, -45.122 }, studs = false }
		),
		P(
			"Sprout2",
			{ 0.391, 0.138, 0.299 },
			{ 1.444, 5.6, -3.294 },
			LEAF,
			{ joint = "Head", rot = { 6.39, -3.216, 3.39 }, studs = false }
		),
		P(
			"CrownRoot31",
			{ 0.23, 0.724, 0.23 },
			{ -0.813, 4.828, -2.559 },
			ROOT,
			{ joint = "Head", rot = { 9.154, 6.507, 35.117 }, studs = false }
		),
		P(
			"CrownRoot32",
			{ 0.172, 0.61, 0.172 },
			{ -1.201, 5.22, -2.432 },
			ROOT,
			{ joint = "Head", rot = { 8.458, 12.27, 55.02 }, studs = false }
		),
		P(
			"Sprout3",
			{ 0.391, 0.138, 0.299 },
			{ -1.408, 5.36, -2.365 },
			LEAF,
			{ joint = "Head", rot = { 5.354, 3.774, 65.079 }, studs = false }
		),
		P(
			"CrownRoot41",
			{ 0.23, 0.724, 0.23 },
			{ 0.813, 4.828, -2.559 },
			ROOT,
			{ joint = "Head", rot = { 9.154, -6.507, -35.117 }, studs = false }
		),
		P(
			"CrownRoot42",
			{ 0.172, 0.61, 0.172 },
			{ 1.201, 5.22, -2.432 },
			ROOT,
			{ joint = "Head", rot = { 8.458, -12.27, -55.02 }, studs = false }
		),
		P(
			"Sprout4",
			{ 0.391, 0.138, 0.299 },
			{ 1.408, 5.36, -2.365 },
			LEAF,
			{ joint = "Head", rot = { 5.354, -3.774, -5.079 }, studs = false }
		),
		P(
			"CrownRoot51",
			{ 0.23, 0.725, 0.23 },
			{ -0.334, 5.039, -3.686 },
			ROOT,
			{ joint = "Head", rot = { 13.406, 2.04, 8.494 }, studs = false }
		),
		P(
			"CrownRoot52",
			{ 0.172, 0.609, 0.172 },
			{ -0.452, 5.568, -3.505 },
			ROOT,
			{ joint = "Head", rot = { 23.298, 7.143, 16.107 }, studs = false }
		),
		P(
			"Sprout5",
			{ 0.391, 0.138, 0.299 },
			{ -0.523, 5.793, -3.398 },
			LEAF,
			{ joint = "Head", rot = { 7.823, 1.181, 38.533 }, studs = false }
		),
		P(
			"CrownRoot61",
			{ 0.23, 0.725, 0.23 },
			{ 0.334, 5.039, -3.686 },
			ROOT,
			{ joint = "Head", rot = { 13.406, -2.04, -8.494 }, studs = false }
		),
		P(
			"CrownRoot62",
			{ 0.172, 0.609, 0.172 },
			{ 0.452, 5.568, -3.505 },
			ROOT,
			{ joint = "Head", rot = { 23.298, -7.143, -16.107 }, studs = false }
		),
		P(
			"Sprout6",
			{ 0.391, 0.138, 0.299 },
			{ 0.523, 5.793, -3.398 },
			LEAF,
			{ joint = "Head", rot = { 7.823, -1.181, 21.467 }, studs = false }
		),
		P(
			"HingeEarL",
			{ 0.23, 0.23, 0.23 },
			{ -0.713, 4.648, -2.727 },
			MAIN,
			{ joint = "EarL", transparency = 1, studs = false }
		),
		P(
			"EarL",
			{ 0.713, 2.53, 0.322 },
			{ -1.098, 5.668, -2.084 },
			MAIN,
			{ joint = "EarL", rot = { 22.654, -152.477, -20.051 }, studs = false }
		),
		P(
			"EarTipL",
			{ 0.506, 0.506, 0.299 },
			{ -1.482, 6.687, -1.442 },
			MAIN,
			{ joint = "EarL", rot = { 22.654, -152.477, 24.949 }, studs = false }
		),
		P(
			"EarInnerL",
			{ 0.414, 2.07, 0.115 },
			{ -1.149, 5.686, -2.211 },
			EAR,
			{ joint = "EarL", rot = { 22.654, -152.477, -20.051 }, studs = false }
		),
		P(
			"EarGlowL",
			{ 0.115, 1.725, 0.092 },
			{ -1.175, 5.695, -2.275 },
			GLOW,
			{ joint = "EarL", rot = { 22.654, -152.477, -20.051 }, material = "Neon", studs = false }
		),
		P(
			"HingeEarR",
			{ 0.23, 0.23, 0.23 },
			{ 0.713, 4.648, -2.727 },
			MAIN,
			{ joint = "EarR", transparency = 1, studs = false }
		),
		P(
			"EarR",
			{ 0.713, 2.53, 0.322 },
			{ 1.098, 5.668, -2.084 },
			MAIN,
			{ joint = "EarR", rot = { 22.654, 152.477, 20.051 }, studs = false }
		),
		P(
			"EarTipR",
			{ 0.506, 0.506, 0.299 },
			{ 1.482, 6.687, -1.442 },
			MAIN,
			{ joint = "EarR", rot = { 22.654, 152.477, 65.051 }, studs = false }
		),
		P(
			"EarInnerR",
			{ 0.414, 2.07, 0.115 },
			{ 1.149, 5.686, -2.211 },
			EAR,
			{ joint = "EarR", rot = { 22.654, 152.477, 20.051 }, studs = false }
		),
		P(
			"EarGlowR",
			{ 0.115, 1.725, 0.092 },
			{ 1.175, 5.695, -2.275 },
			GLOW,
			{ joint = "EarR", rot = { 22.654, 152.477, 20.051 }, material = "Neon", studs = false }
		),
		P(
			"HingeArmL",
			{ 0.23, 0.23, 0.23 },
			{ -1.955, 3.335, -1.495 },
			MAIN,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P("ShoulderL", { 1.61, 1.84, 1.84 }, { -1.955, 3.335, -1.495 }, MAIN2, { joint = "ArmL" }),
		P(
			"UpperArmL",
			{ 1.495, 1.586, 1.495 },
			{ -2.156, 2.587, -1.668 },
			MAIN,
			{ joint = "ArmL", rot = { 12.143, -3.241, 165.276 } }
		),
		P(
			"ForearmL",
			{ 1.437, 1.368, 1.438 },
			{ -2.386, 1.207, -2.099 },
			MAIN2,
			{ joint = "ArmL", rot = { 22.208, -0.984, 177.591 } }
		),
		P("BracerL", { 1.633, 0.46, 1.633 }, { -2.392, 1.322, -2.07 }, GOLD, { joint = "ArmL", rot = { -20, 0, 0 } }),
		P(
			"BracerBandL",
			{ 1.679, 0.184, 1.679 },
			{ -2.392, 1.035, -2.162 },
			ARMOUR,
			{ joint = "ArmL", rot = { -20, 0, 0 }, studs = false }
		),
		P("PawL", { 1.84, 0.862, 1.84 }, { -2.415, 0.437, -2.53 }, MAIN, { joint = "ArmL" }),
		P(
			"ArmRootL1",
			{ 1.587, 0.184, 1.587 },
			{ -2.38, 1.782, -1.932 },
			ROOT,
			{ joint = "ArmL", rot = { -20, -18, 0 }, studs = false }
		),
		P(
			"ArmRootL2",
			{ 1.587, 0.184, 1.587 },
			{ -2.38, 2.151, -1.932 },
			ROOT,
			{ joint = "ArmL", rot = { -20, 18, 0 }, studs = false }
		),
		P(
			"ArmSproutL",
			{ 0.46, 0.138, 0.345 },
			{ -3.105, 2.243, -1.84 },
			LEAF,
			{ joint = "ArmL", rot = { 0, 0, 35 }, studs = false }
		),
		P(
			"MossBandL",
			{ 1.725, 0.368, 1.725 },
			{ -2.403, 0.862, -2.243 },
			MOSS,
			{ joint = "ArmL", rot = { -20, 0, 0 } }
		),
		P(
			"MossBandTopL",
			{ 1.265, 0.184, 1.265 },
			{ -2.403, 1.081, -2.208 },
			LEAF,
			{ joint = "ArmL", rot = { -20, 0, 0 }, studs = false }
		),
		P(
			"ArmCrackL1",
			{ 0.104, 0.656, 0.092 },
			{ -3.162, 1.409, -1.926 },
			AMBER,
			{ joint = "ArmL", rot = { 37.82, -1.561, 177.99 }, material = "Neon", studs = false }
		),
		P(
			"ArmCrackL2",
			{ 0.104, 0.532, 0.092 },
			{ -3.151, 0.891, -2.185 },
			AMBER,
			{ joint = "ArmL", rot = { 12.434, 1.096, -175.04 }, material = "Neon", studs = false }
		),
		P(
			"ArmCrackL3",
			{ 0.104, 0.56, 0.092 },
			{ -2.444, 1.38, -2.806 },
			AMBER,
			{ joint = "ArmL", rot = { 12.174, -7.508, 148.796 }, material = "Neon", studs = false }
		),
		P(
			"ArmCrackL4",
			{ 0.104, 0.532, 0.092 },
			{ -2.473, 0.92, -2.944 },
			AMBER,
			{ joint = "ArmL", rot = { 13.496, 6.656, -154.223 }, material = "Neon", studs = false }
		),
		P(
			"ClawL1",
			{ 0.345, 0.979, 0.368 },
			{ -3.036, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmL", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleL1", { 0.414, 0.253, 0.345 }, { -3.036, 0.725, -3.105 }, GOLD, { joint = "ArmL", studs = false }),
		P(
			"ClawTipL1",
			{ 0.23, 0.611, 0.253 },
			{ -3.036, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmL", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"ClawL2",
			{ 0.345, 0.979, 0.368 },
			{ -2.622, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmL", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleL2", { 0.414, 0.253, 0.345 }, { -2.622, 0.725, -3.105 }, GOLD, { joint = "ArmL", studs = false }),
		P(
			"ClawTipL2",
			{ 0.23, 0.611, 0.253 },
			{ -2.622, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmL", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"ClawL3",
			{ 0.345, 0.979, 0.368 },
			{ -2.208, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmL", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleL3", { 0.414, 0.253, 0.345 }, { -2.208, 0.725, -3.105 }, GOLD, { joint = "ArmL", studs = false }),
		P(
			"ClawTipL3",
			{ 0.23, 0.611, 0.253 },
			{ -2.208, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmL", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"ClawL4",
			{ 0.345, 0.979, 0.368 },
			{ -1.794, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmL", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleL4", { 0.414, 0.253, 0.345 }, { -1.794, 0.725, -3.105 }, GOLD, { joint = "ArmL", studs = false }),
		P(
			"ClawTipL4",
			{ 0.23, 0.611, 0.253 },
			{ -1.794, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmL", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"HingeArmR",
			{ 0.23, 0.23, 0.23 },
			{ 1.955, 3.335, -1.495 },
			MAIN,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P("ShoulderR", { 1.61, 1.84, 1.84 }, { 1.955, 3.335, -1.495 }, MAIN2, { joint = "ArmR" }),
		P(
			"UpperArmR",
			{ 1.495, 1.586, 1.495 },
			{ 2.156, 2.587, -1.668 },
			MAIN,
			{ joint = "ArmR", rot = { 12.143, 3.241, -165.276 } }
		),
		P(
			"ForearmR",
			{ 1.437, 1.368, 1.438 },
			{ 2.386, 1.207, -2.099 },
			MAIN2,
			{ joint = "ArmR", rot = { 22.208, 0.984, -177.591 } }
		),
		P("BracerR", { 1.633, 0.46, 1.633 }, { 2.392, 1.322, -2.07 }, GOLD, { joint = "ArmR", rot = { -20, 0, 0 } }),
		P(
			"BracerBandR",
			{ 1.679, 0.184, 1.679 },
			{ 2.392, 1.035, -2.162 },
			ARMOUR,
			{ joint = "ArmR", rot = { -20, 0, 0 }, studs = false }
		),
		P("PawR", { 1.84, 0.862, 1.84 }, { 2.415, 0.437, -2.53 }, MAIN, { joint = "ArmR" }),
		P(
			"ArmRootR1",
			{ 1.587, 0.184, 1.587 },
			{ 2.38, 1.782, -1.932 },
			ROOT,
			{ joint = "ArmR", rot = { -20, -18, 0 }, studs = false }
		),
		P(
			"ArmRootR2",
			{ 1.587, 0.184, 1.587 },
			{ 2.38, 2.151, -1.932 },
			ROOT,
			{ joint = "ArmR", rot = { -20, 18, 0 }, studs = false }
		),
		P(
			"ArmSproutR",
			{ 0.46, 0.138, 0.345 },
			{ 3.105, 2.243, -1.84 },
			LEAF,
			{ joint = "ArmR", rot = { 0, 0, -35 }, studs = false }
		),
		P(
			"MossBandR",
			{ 1.725, 0.368, 1.725 },
			{ 2.403, 0.862, -2.243 },
			MOSS,
			{ joint = "ArmR", rot = { -20, 0, 0 } }
		),
		P(
			"MossBandTopR",
			{ 1.265, 0.184, 1.265 },
			{ 2.403, 1.081, -2.208 },
			LEAF,
			{ joint = "ArmR", rot = { -20, 0, 0 }, studs = false }
		),
		P(
			"ArmCrackR1",
			{ 0.104, 0.656, 0.092 },
			{ 3.162, 1.409, -1.926 },
			AMBER,
			{ joint = "ArmR", rot = { 37.82, 1.561, -177.99 }, material = "Neon", studs = false }
		),
		P(
			"ArmCrackR2",
			{ 0.104, 0.532, 0.092 },
			{ 3.151, 0.891, -2.185 },
			AMBER,
			{ joint = "ArmR", rot = { 12.434, -1.096, 175.04 }, material = "Neon", studs = false }
		),
		P(
			"ArmCrackR3",
			{ 0.104, 0.56, 0.092 },
			{ 2.444, 1.38, -2.806 },
			AMBER,
			{ joint = "ArmR", rot = { 12.174, 7.508, -148.796 }, material = "Neon", studs = false }
		),
		P(
			"ArmCrackR4",
			{ 0.104, 0.532, 0.092 },
			{ 2.473, 0.92, -2.944 },
			AMBER,
			{ joint = "ArmR", rot = { 13.496, -6.656, 154.223 }, material = "Neon", studs = false }
		),
		P(
			"ClawR1",
			{ 0.345, 0.979, 0.368 },
			{ 1.794, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmR", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleR1", { 0.414, 0.253, 0.345 }, { 1.794, 0.725, -3.105 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"ClawTipR1",
			{ 0.23, 0.611, 0.253 },
			{ 1.794, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmR", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"ClawR2",
			{ 0.345, 0.979, 0.368 },
			{ 2.208, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmR", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleR2", { 0.414, 0.253, 0.345 }, { 2.208, 0.725, -3.105 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"ClawTipR2",
			{ 0.23, 0.611, 0.253 },
			{ 2.208, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmR", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"ClawR3",
			{ 0.345, 0.979, 0.368 },
			{ 2.622, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmR", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleR3", { 0.414, 0.253, 0.345 }, { 2.622, 0.725, -3.105 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"ClawTipR3",
			{ 0.23, 0.611, 0.253 },
			{ 2.622, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmR", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"ClawR4",
			{ 0.345, 0.979, 0.368 },
			{ 3.036, 0.489, -3.766 },
			CLAW,
			{ joint = "ArmR", rot = { 86.634, 0, -180 }, studs = false }
		),
		P("KnuckleR4", { 0.414, 0.253, 0.345 }, { 3.036, 0.725, -3.105 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"ClawTipR4",
			{ 0.23, 0.611, 0.253 },
			{ 3.036, 0.259, -4.542 },
			CLAW2,
			{ joint = "ArmR", rot = { 48.814, 0, -180 }, studs = false }
		),
		P(
			"HingeLegL",
			{ 0.23, 0.23, 0.23 },
			{ -1.553, 2.415, 2.76 },
			MAIN,
			{ joint = "LegL", transparency = 1, studs = false }
		),
		P("ThighL", { 1.38, 1.725, 1.84 }, { -1.725, 2.127, 2.76 }, MAIN, { joint = "LegL" }),
		P("ShinL", { 1.092, 1.15, 1.15 }, { -1.725, 0.862, 2.53 }, MAIN2, { joint = "LegL" }),
		P("FootL", { 1.265, 0.46, 1.61 }, { -1.725, 0.23, 2.243 }, MAIN, { joint = "LegL" }),
		P(
			"HindClawL1",
			{ 0.253, 0.487, 0.253 },
			{ -2.116, 0.172, 1.265 },
			CLAW,
			{ joint = "LegL", rot = { 70.71, 0, -180 }, studs = false }
		),
		P(
			"HindClawL2",
			{ 0.253, 0.487, 0.253 },
			{ -1.725, 0.172, 1.265 },
			CLAW,
			{ joint = "LegL", rot = { 70.71, 0, -180 }, studs = false }
		),
		P(
			"HindClawL3",
			{ 0.253, 0.487, 0.253 },
			{ -1.334, 0.172, 1.265 },
			CLAW,
			{ joint = "LegL", rot = { 70.71, 0, -180 }, studs = false }
		),
		P(
			"HingeLegR",
			{ 0.23, 0.23, 0.23 },
			{ 1.553, 2.415, 2.76 },
			MAIN,
			{ joint = "LegR", transparency = 1, studs = false }
		),
		P("ThighR", { 1.38, 1.725, 1.84 }, { 1.725, 2.127, 2.76 }, MAIN, { joint = "LegR" }),
		P("ShinR", { 1.092, 1.15, 1.15 }, { 1.725, 0.862, 2.53 }, MAIN2, { joint = "LegR" }),
		P("FootR", { 1.265, 0.46, 1.61 }, { 1.725, 0.23, 2.243 }, MAIN, { joint = "LegR" }),
		P(
			"HindClawR1",
			{ 0.253, 0.487, 0.253 },
			{ 1.334, 0.172, 1.265 },
			CLAW,
			{ joint = "LegR", rot = { 70.71, 0, -180 }, studs = false }
		),
		P(
			"HindClawR2",
			{ 0.253, 0.487, 0.253 },
			{ 1.725, 0.172, 1.265 },
			CLAW,
			{ joint = "LegR", rot = { 70.71, 0, -180 }, studs = false }
		),
		P(
			"HindClawR3",
			{ 0.253, 0.487, 0.253 },
			{ 2.116, 0.172, 1.265 },
			CLAW,
			{ joint = "LegR", rot = { 70.71, 0, -180 }, studs = false }
		),
	},
}

return { egg = egg, pet = pet }
