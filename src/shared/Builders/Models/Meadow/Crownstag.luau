--!strict
-- Crownstag (Zone 1 Meadow, Rare). Zone 1 Meadow roster (Config/Pets).
-- Pet: a sturdy chestnut stag with cream patches, a big shaggy cream ruff down the throat and chest, cream socks and
--      gold hooves, a leafy mantle with pink flowers, a fluffy cream tail carried up, glowing gold eyes, big ears, a
--      gold crown with a pink gem and wide branching antlers flowering pink among green leaves.
--      Joints: Body, Neck, Head, ArmL/R, LegL/R, Tail.
-- Egg: a cream egg wrapped by chestnut branches with pink flowers and leaves, a gold crown with a pink gem on top.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/crownstag.py, zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(140, 74, 36) -- #8C4A24
local DARK = rgb(90, 46, 20) -- #5A2E14
local LIGHT = rgb(244, 227, 196) -- #F4E3C4
local GLOW = rgb(255, 224, 102) -- #FFE066
local CREAM = rgb(244, 227, 196) -- #F4E3C4
local CREAM2 = rgb(230, 207, 164) -- #E6CFA4
local GOLD = rgb(240, 185, 58) -- #F0B93A
local GOLD2 = rgb(196, 142, 34) -- #C48E22
local GEM = rgb(255, 79, 160) -- #FF4FA0
local LEAF = rgb(95, 181, 68) -- #5FB544
local LEAF2 = rgb(62, 142, 52) -- #3E8E34
local BLOSSOM = rgb(255, 126, 182) -- #FF7EB6
local BLOSSOM2 = rgb(255, 166, 207) -- #FFA6CF
local BLOOMCORE = rgb(255, 201, 60) -- #FFC93C
local MAIN2 = rgb(122, 63, 30) -- #7A3F1E
local ANTLER = rgb(107, 62, 34) -- #6B3E22
local ANTLER2 = rgb(90, 50, 25) -- #5A3219
local NOSE = rgb(36, 26, 22) -- #241A16
local EYE = rgb(255, 210, 74) -- #FFD24A
local INK = rgb(30, 20, 14) -- #1E140E
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.688, 0.538, 1.688 }, { 0, 0.269, 0 }, MAIN2, { joint = "Body" }),
		P("Shell2", { 2.637, 0.538, 2.637 }, { 0, 0.806, 0 }, rgb(233, 211, 172), { joint = "Body" }),
		P("Shell3", { 3.031, 0.538, 3.031 }, { 0, 1.344, 0 }, CREAM, { joint = "Body" }),
		P("Shell4", { 3.136, 0.538, 3.136 }, { 0, 1.881, 0 }, rgb(233, 211, 172), { joint = "Body" }),
		P("Shell5", { 3.028, 0.538, 3.028 }, { 0, 2.419, 0 }, CREAM, { joint = "Body" }),
		P("Shell6", { 2.729, 0.538, 2.729 }, { 0, 2.956, 0 }, rgb(233, 211, 172), { joint = "Body" }),
		P("Shell7", { 2.213, 0.538, 2.213 }, { 0, 3.494, 0 }, CREAM, { joint = "Body" }),
		P("Shell8", { 1.32, 0.538, 1.32 }, { 0, 4.031, 0 }, rgb(233, 211, 172), { joint = "Body" }),
		P(
			"RarityBand",
			{ 2.797, 0.18, 2.797 },
			{ 0, 0.85, 0 },
			rgb(60, 150, 255),
			{ joint = "Body", material = "Neon", studs = false }
		),
		P(
			"ArchTrunk11",
			{ 0.3, 1.151, 0.3 },
			{ 0, 1.45, -1.523 },
			MAIN2,
			{ joint = "Body", rot = { -14.007, 0, 0 }, studs = false }
		),
		P(
			"ArchArm1A1",
			{ 0.24, 1.014, 0.24 },
			{ -0.306, 2.275, -1.621 },
			MAIN2,
			{ joint = "Body", rot = { 2.52, 2.369, 43.214 }, studs = false }
		),
		P(
			"ArchArm1A2",
			{ 0.24, 0.888, 0.24 },
			{ -0.625, 2.925, -1.39 },
			MAIN2,
			{ joint = "Body", rot = { 32.054, 1.265, 2.02 }, studs = false }
		),
		P(
			"Bloom1APetal1",
			{ 0.253, 0.1, 0.275 },
			{ -0.722, 3.094, -1.34 },
			BLOSSOM2,
			{ joint = "Body", rot = { -72.872, 9.01, 26.939 }, studs = false }
		),
		P(
			"Bloom1APetal2",
			{ 0.253, 0.1, 0.275 },
			{ -0.566, 3.202, -1.381 },
			BLOSSOM,
			{ joint = "Body", rot = { -28.341, -52.092, 46.743 }, studs = false }
		),
		P(
			"Bloom1APetal3",
			{ 0.253, 0.1, 0.275 },
			{ -0.589, 3.376, -1.299 },
			BLOSSOM2,
			{ joint = "Body", rot = { -93.248, -139.892, -35.806 }, studs = false }
		),
		P(
			"Bloom1APetal4",
			{ 0.253, 0.1, 0.275 },
			{ -0.76, 3.376, -1.207 },
			BLOSSOM,
			{ joint = "Body", rot = { -56.056, 156.993, -29.086 }, studs = false }
		),
		P(
			"Bloom1APetal5",
			{ 0.253, 0.1, 0.275 },
			{ -0.842, 3.202, -1.233 },
			BLOSSOM2,
			{ joint = "Body", rot = { 38.937, 117.652, -105.387 }, studs = false }
		),
		P(
			"Bloom1ACentre",
			{ 0.187, 0.14, 0.187 },
			{ -0.709, 3.26, -1.317 },
			BLOOMCORE,
			{ joint = "Body", rot = { -100.985, 47.167, 41.159 }, material = "Neon", studs = false }
		),
		P(
			"ArchArm1B1",
			{ 0.24, 1.014, 0.24 },
			{ 0.306, 2.275, -1.621 },
			MAIN2,
			{ joint = "Body", rot = { 2.52, -2.369, -43.214 }, studs = false }
		),
		P(
			"ArchArm1B2",
			{ 0.24, 0.888, 0.24 },
			{ 0.625, 2.925, -1.39 },
			MAIN2,
			{ joint = "Body", rot = { 32.054, -1.265, -2.02 }, studs = false }
		),
		P(
			"Bloom1BPetal1",
			{ 0.253, 0.1, 0.275 },
			{ 0.722, 3.094, -1.34 },
			BLOSSOM2,
			{ joint = "Body", rot = { -72.872, -9.01, -26.939 }, studs = false }
		),
		P(
			"Bloom1BPetal2",
			{ 0.253, 0.1, 0.275 },
			{ 0.842, 3.202, -1.233 },
			BLOSSOM,
			{ joint = "Body", rot = { 38.937, -117.652, 105.387 }, studs = false }
		),
		P(
			"Bloom1BPetal3",
			{ 0.253, 0.1, 0.275 },
			{ 0.76, 3.376, -1.207 },
			BLOSSOM2,
			{ joint = "Body", rot = { -56.056, -156.993, 29.086 }, studs = false }
		),
		P(
			"Bloom1BPetal4",
			{ 0.253, 0.1, 0.275 },
			{ 0.589, 3.376, -1.299 },
			BLOSSOM,
			{ joint = "Body", rot = { -93.248, 139.892, 35.806 }, studs = false }
		),
		P(
			"Bloom1BPetal5",
			{ 0.253, 0.1, 0.275 },
			{ 0.566, 3.202, -1.381 },
			BLOSSOM2,
			{ joint = "Body", rot = { -28.341, 52.092, -46.743 }, studs = false }
		),
		P(
			"Bloom1BCentre",
			{ 0.187, 0.14, 0.187 },
			{ 0.709, 3.26, -1.317 },
			BLOOMCORE,
			{ joint = "Body", rot = { -50.977, 30.788, -31.39 }, material = "Neon", studs = false }
		),
		P(
			"ArchTrunk21",
			{ 0.3, 1.151, 0.3 },
			{ 1.523, 1.45, 0 },
			MAIN2,
			{ joint = "Body", rot = { 0, 0, -14.007 }, studs = false }
		),
		P(
			"ArchArm2A1",
			{ 0.24, 1.014, 0.24 },
			{ 1.621, 2.275, -0.306 },
			MAIN2,
			{ joint = "Body", rot = { -43.069, -3.244, 3.464 }, studs = false }
		),
		P(
			"ArchArm2A2",
			{ 0.24, 0.888, 0.24 },
			{ 1.39, 2.925, -0.625 },
			MAIN2,
			{ joint = "Body", rot = { -1.711, -1.073, 32.083 }, studs = false }
		),
		P(
			"Bloom2APetal1",
			{ 0.253, 0.1, 0.275 },
			{ 1.34, 3.094, -0.722 },
			BLOSSOM2,
			{ joint = "Body", rot = { -80.579, -16.91, -60.297 }, studs = false }
		),
		P(
			"Bloom2APetal2",
			{ 0.253, 0.1, 0.275 },
			{ 1.381, 3.202, -0.566 },
			BLOSSOM,
			{ joint = "Body", rot = { 20.288, -147.265, 81.1 }, studs = false }
		),
		P(
			"Bloom2APetal3",
			{ 0.253, 0.1, 0.275 },
			{ 1.299, 3.376, -0.589 },
			BLOSSOM2,
			{ joint = "Body", rot = { 130.154, -2.484, -123.712 }, studs = false }
		),
		P(
			"Bloom2APetal4",
			{ 0.253, 0.1, 0.275 },
			{ 1.207, 3.376, -0.76 },
			BLOSSOM,
			{ joint = "Body", rot = { 62.895, 30.929, -104.347 }, studs = false }
		),
		P(
			"Bloom2APetal5",
			{ 0.253, 0.1, 0.275 },
			{ 1.233, 3.202, -0.842 },
			BLOSSOM2,
			{ joint = "Body", rot = { -18.225, 21.161, -63.017 }, studs = false }
		),
		P(
			"Bloom2ACentre",
			{ 0.187, 0.14, 0.187 },
			{ 1.317, 3.26, -0.709 },
			BLOOMCORE,
			{ joint = "Body", rot = { -42.305, 7.443, -56.942 }, material = "Neon", studs = false }
		),
		P(
			"ArchArm2B1",
			{ 0.24, 1.014, 0.24 },
			{ 1.621, 2.275, 0.306 },
			MAIN2,
			{ joint = "Body", rot = { 43.069, 3.244, 3.464 }, studs = false }
		),
		P(
			"ArchArm2B2",
			{ 0.24, 0.888, 0.24 },
			{ 1.39, 2.925, 0.625 },
			MAIN2,
			{ joint = "Body", rot = { 1.711, 1.073, 32.083 }, studs = false }
		),
		P(
			"Bloom2BPetal1",
			{ 0.253, 0.1, 0.275 },
			{ 1.34, 3.094, 0.722 },
			BLOSSOM2,
			{ joint = "Body", rot = { -99.421, -16.91, -119.703 }, studs = false }
		),
		P(
			"Bloom2BPetal2",
			{ 0.253, 0.1, 0.275 },
			{ 1.233, 3.202, 0.842 },
			BLOSSOM,
			{ joint = "Body", rot = { 18.225, 158.839, 63.017 }, studs = false }
		),
		P(
			"Bloom2BPetal3",
			{ 0.253, 0.1, 0.275 },
			{ 1.207, 3.376, 0.76 },
			BLOSSOM2,
			{ joint = "Body", rot = { 117.105, 30.929, -75.653 }, studs = false }
		),
		P(
			"Bloom2BPetal4",
			{ 0.253, 0.1, 0.275 },
			{ 1.299, 3.376, 0.589 },
			BLOSSOM,
			{ joint = "Body", rot = { 49.846, -2.484, -56.288 }, studs = false }
		),
		P(
			"Bloom2BPetal5",
			{ 0.253, 0.1, 0.275 },
			{ 1.381, 3.202, 0.566 },
			BLOSSOM2,
			{ joint = "Body", rot = { -20.288, -32.735, -81.1 }, studs = false }
		),
		P(
			"Bloom2BCentre",
			{ 0.187, 0.14, 0.187 },
			{ 1.317, 3.26, 0.709 },
			BLOOMCORE,
			{ joint = "Body", rot = { -52.514, -32.745, -98.86 }, material = "Neon", studs = false }
		),
		P(
			"ArchTrunk31",
			{ 0.3, 1.151, 0.3 },
			{ 0, 1.45, 1.523 },
			MAIN2,
			{ joint = "Body", rot = { 14.007, 0, 0 }, studs = false }
		),
		P(
			"ArchArm3A1",
			{ 0.24, 1.014, 0.24 },
			{ 0.306, 2.275, 1.621 },
			MAIN2,
			{ joint = "Body", rot = { -2.52, 2.369, -43.214 }, studs = false }
		),
		P(
			"ArchArm3A2",
			{ 0.24, 0.888, 0.24 },
			{ 0.625, 2.925, 1.39 },
			MAIN2,
			{ joint = "Body", rot = { -32.054, 1.265, -2.02 }, studs = false }
		),
		P(
			"Bloom3APetal1",
			{ 0.253, 0.1, 0.275 },
			{ 0.722, 3.094, 1.34 },
			BLOSSOM2,
			{ joint = "Body", rot = { -107.128, -9.01, -153.061 }, studs = false }
		),
		P(
			"Bloom3APetal2",
			{ 0.253, 0.1, 0.275 },
			{ 0.566, 3.202, 1.381 },
			BLOSSOM,
			{ joint = "Body", rot = { 28.341, 127.908, 46.743 }, studs = false }
		),
		P(
			"Bloom3APetal3",
			{ 0.253, 0.1, 0.275 },
			{ 0.589, 3.376, 1.299 },
			BLOSSOM2,
			{ joint = "Body", rot = { 93.248, 40.108, -35.806 }, studs = false }
		),
		P(
			"Bloom3APetal4",
			{ 0.253, 0.1, 0.275 },
			{ 0.76, 3.376, 1.207 },
			BLOSSOM,
			{ joint = "Body", rot = { 56.056, -23.007, -29.086 }, studs = false }
		),
		P(
			"Bloom3APetal5",
			{ 0.253, 0.1, 0.275 },
			{ 0.842, 3.202, 1.233 },
			BLOSSOM2,
			{ joint = "Body", rot = { -38.937, -62.348, -105.387 }, studs = false }
		),
		P(
			"Bloom3ACentre",
			{ 0.187, 0.14, 0.187 },
			{ 0.709, 3.26, 1.317 },
			BLOOMCORE,
			{ joint = "Body", rot = { -79.015, -47.167, -138.84 }, material = "Neon", studs = false }
		),
		P(
			"ArchArm3B1",
			{ 0.24, 1.014, 0.24 },
			{ -0.306, 2.275, 1.621 },
			MAIN2,
			{ joint = "Body", rot = { -2.52, -2.369, 43.214 }, studs = false }
		),
		P(
			"ArchArm3B2",
			{ 0.24, 0.888, 0.24 },
			{ -0.625, 2.925, 1.39 },
			MAIN2,
			{ joint = "Body", rot = { -32.054, -1.265, 2.02 }, studs = false }
		),
		P(
			"Bloom3BPetal1",
			{ 0.253, 0.1, 0.275 },
			{ -0.722, 3.094, 1.34 },
			BLOSSOM2,
			{ joint = "Body", rot = { -107.128, 9.01, 153.061 }, studs = false }
		),
		P(
			"Bloom3BPetal2",
			{ 0.253, 0.1, 0.275 },
			{ -0.842, 3.202, 1.233 },
			BLOSSOM,
			{ joint = "Body", rot = { -38.937, 62.348, 105.387 }, studs = false }
		),
		P(
			"Bloom3BPetal3",
			{ 0.253, 0.1, 0.275 },
			{ -0.76, 3.376, 1.207 },
			BLOSSOM2,
			{ joint = "Body", rot = { 56.056, 23.007, 29.086 }, studs = false }
		),
		P(
			"Bloom3BPetal4",
			{ 0.253, 0.1, 0.275 },
			{ -0.589, 3.376, 1.299 },
			BLOSSOM,
			{ joint = "Body", rot = { 93.248, -40.108, 35.806 }, studs = false }
		),
		P(
			"Bloom3BPetal5",
			{ 0.253, 0.1, 0.275 },
			{ -0.566, 3.202, 1.381 },
			BLOSSOM2,
			{ joint = "Body", rot = { 28.341, -127.908, -46.743 }, studs = false }
		),
		P(
			"Bloom3BCentre",
			{ 0.187, 0.14, 0.187 },
			{ -0.709, 3.26, 1.317 },
			BLOOMCORE,
			{ joint = "Body", rot = { 50.977, -149.212, -31.39 }, material = "Neon", studs = false }
		),
		P(
			"ArchTrunk41",
			{ 0.3, 1.151, 0.3 },
			{ -1.523, 1.45, 0 },
			MAIN2,
			{ joint = "Body", rot = { 0, 0, 14.007 }, studs = false }
		),
		P(
			"ArchArm4A1",
			{ 0.24, 1.014, 0.24 },
			{ -1.621, 2.275, 0.306 },
			MAIN2,
			{ joint = "Body", rot = { 43.069, -3.244, -3.464 }, studs = false }
		),
		P(
			"ArchArm4A2",
			{ 0.24, 0.888, 0.24 },
			{ -1.39, 2.925, 0.625 },
			MAIN2,
			{ joint = "Body", rot = { 1.711, -1.073, -32.083 }, studs = false }
		),
		P(
			"Bloom4APetal1",
			{ 0.253, 0.1, 0.275 },
			{ -1.34, 3.094, 0.722 },
			BLOSSOM2,
			{ joint = "Body", rot = { -99.421, 16.91, 119.703 }, studs = false }
		),
		P(
			"Bloom4APetal2",
			{ 0.253, 0.1, 0.275 },
			{ -1.381, 3.202, 0.566 },
			BLOSSOM,
			{ joint = "Body", rot = { -20.288, 32.735, 81.1 }, studs = false }
		),
		P(
			"Bloom4APetal3",
			{ 0.253, 0.1, 0.275 },
			{ -1.299, 3.376, 0.589 },
			BLOSSOM2,
			{ joint = "Body", rot = { 49.846, 2.484, 56.288 }, studs = false }
		),
		P(
			"Bloom4APetal4",
			{ 0.253, 0.1, 0.275 },
			{ -1.207, 3.376, 0.76 },
			BLOSSOM,
			{ joint = "Body", rot = { 117.105, -30.929, 75.653 }, studs = false }
		),
		P(
			"Bloom4APetal5",
			{ 0.253, 0.1, 0.275 },
			{ -1.233, 3.202, 0.842 },
			BLOSSOM2,
			{ joint = "Body", rot = { 18.225, -158.839, -63.017 }, studs = false }
		),
		P(
			"Bloom4ACentre",
			{ 0.187, 0.14, 0.187 },
			{ -1.317, 3.26, 0.709 },
			BLOOMCORE,
			{ joint = "Body", rot = { -137.695, -7.443, 123.058 }, material = "Neon", studs = false }
		),
		P(
			"ArchArm4B1",
			{ 0.24, 1.014, 0.24 },
			{ -1.621, 2.275, -0.306 },
			MAIN2,
			{ joint = "Body", rot = { -43.069, 3.244, -3.464 }, studs = false }
		),
		P(
			"ArchArm4B2",
			{ 0.24, 0.888, 0.24 },
			{ -1.39, 2.925, -0.625 },
			MAIN2,
			{ joint = "Body", rot = { -1.711, 1.073, -32.083 }, studs = false }
		),
		P(
			"Bloom4BPetal1",
			{ 0.253, 0.1, 0.275 },
			{ -1.34, 3.094, -0.722 },
			BLOSSOM2,
			{ joint = "Body", rot = { -80.579, 16.91, 60.297 }, studs = false }
		),
		P(
			"Bloom4BPetal2",
			{ 0.253, 0.1, 0.275 },
			{ -1.233, 3.202, -0.842 },
			BLOSSOM,
			{ joint = "Body", rot = { -18.225, -21.161, 63.017 }, studs = false }
		),
		P(
			"Bloom4BPetal3",
			{ 0.253, 0.1, 0.275 },
			{ -1.207, 3.376, -0.76 },
			BLOSSOM2,
			{ joint = "Body", rot = { 62.895, -30.929, 104.347 }, studs = false }
		),
		P(
			"Bloom4BPetal4",
			{ 0.253, 0.1, 0.275 },
			{ -1.299, 3.376, -0.589 },
			BLOSSOM,
			{ joint = "Body", rot = { 130.154, 2.484, 123.712 }, studs = false }
		),
		P(
			"Bloom4BPetal5",
			{ 0.253, 0.1, 0.275 },
			{ -1.381, 3.202, -0.566 },
			BLOSSOM2,
			{ joint = "Body", rot = { 20.288, 147.265, -81.1 }, studs = false }
		),
		P(
			"Bloom4BCentre",
			{ 0.187, 0.14, 0.187 },
			{ -1.317, 3.26, -0.709 },
			BLOOMCORE,
			{ joint = "Body", rot = { -127.486, 32.745, 81.14 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf1",
			{ 0.46, 0.672, 0.12 },
			{ 0.628, 1.068, -1.864 },
			LEAF2,
			{ joint = "Body", rot = { -113.199, 0, 0 }, studs = false }
		),
		P(
			"BaseLeaf1Tip",
			{ 0.325, 0.325, 0.115 },
			{ 0.628, 0.935, -2.173 },
			LEAF2,
			{ joint = "Body", rot = { -113.199, 0, 45 }, studs = false }
		),
		P(
			"BaseFlower1Petal1",
			{ 0.304, 0.1, 0.33 },
			{ 0.628, 1.166, -1.879 },
			BLOSSOM2,
			{ joint = "Body", rot = { -68.199, 0, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal2",
			{ 0.304, 0.1, 0.33 },
			{ 0.816, 1.293, -1.828 },
			BLOSSOM,
			{ joint = "Body", rot = { -68.199, -72, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal3",
			{ 0.304, 0.1, 0.33 },
			{ 0.744, 1.499, -1.746 },
			BLOSSOM2,
			{ joint = "Body", rot = { -68.199, -144, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal4",
			{ 0.304, 0.1, 0.33 },
			{ 0.511, 1.499, -1.746 },
			BLOSSOM,
			{ joint = "Body", rot = { -68.199, 144, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal5",
			{ 0.304, 0.1, 0.33 },
			{ 0.439, 1.293, -1.828 },
			BLOSSOM2,
			{ joint = "Body", rot = { -68.199, 72, 0 }, studs = false }
		),
		P(
			"BaseFlower1Centre",
			{ 0.224, 0.14, 0.224 },
			{ 0.628, 1.361, -1.833 },
			BLOOMCORE,
			{ joint = "Body", rot = { -68.199, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf2",
			{ 0.46, 0.672, 0.12 },
			{ 1.864, 1.068, -0.628 },
			LEAF,
			{ joint = "Body", rot = { -90, 23.199, -90 }, studs = false }
		),
		P(
			"BaseLeaf2Tip",
			{ 0.325, 0.325, 0.115 },
			{ 2.173, 0.935, -0.628 },
			LEAF,
			{ joint = "Body", rot = { -90, 23.199, -45 }, studs = false }
		),
		P(
			"BaseLeaf3",
			{ 0.46, 0.672, 0.12 },
			{ 1.864, 1.068, 0.628 },
			LEAF2,
			{ joint = "Body", rot = { -90, 23.199, -90 }, studs = false }
		),
		P(
			"BaseLeaf3Tip",
			{ 0.325, 0.325, 0.115 },
			{ 2.173, 0.935, 0.628 },
			LEAF2,
			{ joint = "Body", rot = { -90, 23.199, -45 }, studs = false }
		),
		P(
			"BaseFlower2Petal1",
			{ 0.304, 0.1, 0.33 },
			{ 1.879, 1.166, 0.628 },
			BLOSSOM2,
			{ joint = "Body", rot = { -90, -21.801, -90 }, studs = false }
		),
		P(
			"BaseFlower2Petal2",
			{ 0.304, 0.1, 0.33 },
			{ 1.828, 1.293, 0.816 },
			BLOSSOM,
			{ joint = "Body", rot = { 16.788, -173.41, 69.172 }, studs = false }
		),
		P(
			"BaseFlower2Petal3",
			{ 0.304, 0.1, 0.33 },
			{ 1.746, 1.499, 0.744 },
			BLOSSOM2,
			{ joint = "Body", rot = { 128.044, 17.485, -103.231 }, studs = false }
		),
		P(
			"BaseFlower2Petal4",
			{ 0.304, 0.1, 0.33 },
			{ 1.746, 1.499, 0.511 },
			BLOSSOM,
			{ joint = "Body", rot = { 51.956, 17.485, -76.769 }, studs = false }
		),
		P(
			"BaseFlower2Petal5",
			{ 0.304, 0.1, 0.33 },
			{ 1.828, 1.293, 0.439 },
			BLOSSOM2,
			{ joint = "Body", rot = { -16.788, -6.59, -69.172 }, studs = false }
		),
		P(
			"BaseFlower2Centre",
			{ 0.224, 0.14, 0.224 },
			{ 1.833, 1.361, 0.628 },
			BLOOMCORE,
			{ joint = "Body", rot = { -42.876, -15.225, -74.207 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf4",
			{ 0.46, 0.672, 0.12 },
			{ 0.628, 1.068, 1.864 },
			LEAF,
			{ joint = "Body", rot = { -66.801, 0, 180 }, studs = false }
		),
		P(
			"BaseLeaf4Tip",
			{ 0.325, 0.325, 0.115 },
			{ 0.628, 0.935, 2.173 },
			LEAF,
			{ joint = "Body", rot = { -66.801, 0, -135 }, studs = false }
		),
		P(
			"BaseLeaf5",
			{ 0.46, 0.672, 0.12 },
			{ -0.628, 1.068, 1.864 },
			LEAF2,
			{ joint = "Body", rot = { -66.801, 0, 180 }, studs = false }
		),
		P(
			"BaseLeaf5Tip",
			{ 0.325, 0.325, 0.115 },
			{ -0.628, 0.935, 2.173 },
			LEAF2,
			{ joint = "Body", rot = { -66.801, 0, -135 }, studs = false }
		),
		P(
			"BaseFlower3Petal1",
			{ 0.304, 0.1, 0.33 },
			{ -0.628, 1.166, 1.879 },
			BLOSSOM2,
			{ joint = "Body", rot = { 68.199, 180, 0 }, studs = false }
		),
		P(
			"BaseFlower3Petal2",
			{ 0.304, 0.1, 0.33 },
			{ -0.816, 1.293, 1.828 },
			BLOSSOM,
			{ joint = "Body", rot = { 68.199, 108, 0 }, studs = false }
		),
		P(
			"BaseFlower3Petal3",
			{ 0.304, 0.1, 0.33 },
			{ -0.744, 1.499, 1.746 },
			BLOSSOM2,
			{ joint = "Body", rot = { 68.199, 36, 0 }, studs = false }
		),
		P(
			"BaseFlower3Petal4",
			{ 0.304, 0.1, 0.33 },
			{ -0.511, 1.499, 1.746 },
			BLOSSOM,
			{ joint = "Body", rot = { 68.199, -36, 0 }, studs = false }
		),
		P(
			"BaseFlower3Petal5",
			{ 0.304, 0.1, 0.33 },
			{ -0.439, 1.293, 1.828 },
			BLOSSOM2,
			{ joint = "Body", rot = { 68.199, -108, 0 }, studs = false }
		),
		P(
			"BaseFlower3Centre",
			{ 0.224, 0.14, 0.224 },
			{ -0.628, 1.361, 1.833 },
			BLOOMCORE,
			{ joint = "Body", rot = { 68.199, -135, 0 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf6",
			{ 0.46, 0.672, 0.12 },
			{ -1.864, 1.068, 0.628 },
			LEAF,
			{ joint = "Body", rot = { -90, -23.199, 90 }, studs = false }
		),
		P(
			"BaseLeaf6Tip",
			{ 0.325, 0.325, 0.115 },
			{ -2.173, 0.935, 0.628 },
			LEAF,
			{ joint = "Body", rot = { -90, -23.199, 135 }, studs = false }
		),
		P(
			"BaseLeaf7",
			{ 0.46, 0.672, 0.12 },
			{ -1.864, 1.068, -0.628 },
			LEAF2,
			{ joint = "Body", rot = { -90, -23.199, 90 }, studs = false }
		),
		P(
			"BaseLeaf7Tip",
			{ 0.325, 0.325, 0.115 },
			{ -2.173, 0.935, -0.628 },
			LEAF2,
			{ joint = "Body", rot = { -90, -23.199, 135 }, studs = false }
		),
		P(
			"BaseFlower4Petal1",
			{ 0.304, 0.1, 0.33 },
			{ -1.879, 1.166, -0.628 },
			BLOSSOM2,
			{ joint = "Body", rot = { -90, 21.801, 90 }, studs = false }
		),
		P(
			"BaseFlower4Petal2",
			{ 0.304, 0.1, 0.33 },
			{ -1.828, 1.293, -0.816 },
			BLOSSOM,
			{ joint = "Body", rot = { -16.788, 6.59, 69.172 }, studs = false }
		),
		P(
			"BaseFlower4Petal3",
			{ 0.304, 0.1, 0.33 },
			{ -1.746, 1.499, -0.744 },
			BLOSSOM2,
			{ joint = "Body", rot = { 51.956, -17.485, 76.769 }, studs = false }
		),
		P(
			"BaseFlower4Petal4",
			{ 0.304, 0.1, 0.33 },
			{ -1.746, 1.499, -0.511 },
			BLOSSOM,
			{ joint = "Body", rot = { 128.044, -17.485, 103.231 }, studs = false }
		),
		P(
			"BaseFlower4Petal5",
			{ 0.304, 0.1, 0.33 },
			{ -1.828, 1.293, -0.439 },
			BLOSSOM2,
			{ joint = "Body", rot = { 16.788, 173.41, -69.172 }, studs = false }
		),
		P(
			"BaseFlower4Centre",
			{ 0.224, 0.14, 0.224 },
			{ -1.833, 1.361, -0.628 },
			BLOOMCORE,
			{ joint = "Body", rot = { -137.124, 15.225, 105.793 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf8",
			{ 0.46, 0.672, 0.12 },
			{ -0.628, 1.068, -1.864 },
			LEAF,
			{ joint = "Body", rot = { -113.199, 0, 0 }, studs = false }
		),
		P(
			"BaseLeaf8Tip",
			{ 0.325, 0.325, 0.115 },
			{ -0.628, 0.935, -2.173 },
			LEAF,
			{ joint = "Body", rot = { -113.199, 0, 45 }, studs = false }
		),
		P("Circlet", { 2.393, 0.2, 2.393 }, { 0, 3.75, 0 }, GOLD, { joint = "Body", studs = false }),
		P("CircletTrim", { 2.433, 0.06, 2.433 }, { 0, 3.62, 0 }, GOLD2, { joint = "Body", studs = false }),
		P(
			"CrownPoint1",
			{ 0.24, 0.44, 0.24 },
			{ 0, 4.05, -1.187 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"CrownPoint2",
			{ 0.24, 0.3, 0.24 },
			{ 0.839, 4.05, -0.839 },
			GOLD,
			{ joint = "Body", rot = { 0, -45, 45 }, studs = false }
		),
		P(
			"CrownPoint3",
			{ 0.24, 0.44, 0.24 },
			{ 1.187, 4.05, 0 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
		),
		P(
			"CrownPoint4",
			{ 0.24, 0.3, 0.24 },
			{ 0.839, 4.05, 0.839 },
			GOLD,
			{ joint = "Body", rot = { 0, -135, 45 }, studs = false }
		),
		P(
			"CrownPoint5",
			{ 0.24, 0.44, 0.24 },
			{ 0, 4.05, 1.187 },
			GOLD,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"CrownPoint6",
			{ 0.24, 0.3, 0.24 },
			{ -0.839, 4.05, 0.839 },
			GOLD,
			{ joint = "Body", rot = { 0, 135, 45 }, studs = false }
		),
		P(
			"CrownPoint7",
			{ 0.24, 0.44, 0.24 },
			{ -1.187, 4.05, 0 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
		),
		P(
			"CrownPoint8",
			{ 0.24, 0.3, 0.24 },
			{ -0.839, 4.05, -0.839 },
			GOLD,
			{ joint = "Body", rot = { 0, 45, 45 }, studs = false }
		),
		P(
			"CircletGem",
			{ 0.36, 0.36, 0.14 },
			{ 0, 3.75, -1.287 },
			GEM,
			{ joint = "Body", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"CrownFlower1Petal1",
			{ 0.253, 0.1, 0.275 },
			{ -0.431, 4.448, 0.038 },
			BLOSSOM2,
			{ joint = "Body", rot = { 9.782, 3.888, 21.469 }, studs = false }
		),
		P(
			"CrownFlower1Petal2",
			{ 0.253, 0.1, 0.275 },
			{ -0.278, 4.487, 0.15 },
			BLOSSOM,
			{ joint = "Body", rot = { 53.164, -59.551, 46.099 }, studs = false }
		),
		P(
			"CrownFlower1Petal3",
			{ 0.253, 0.1, 0.275 },
			{ -0.321, 4.433, 0.331 },
			BLOSSOM2,
			{ joint = "Body", rot = { -5.826, -143.087, -27.174 }, studs = false }
		),
		P(
			"CrownFlower1Petal4",
			{ 0.253, 0.1, 0.275 },
			{ -0.501, 4.361, 0.331 },
			BLOSSOM,
			{ joint = "Body", rot = { 24.078, 150.601, -24.779 }, studs = false }
		),
		P(
			"CrownFlower1Petal5",
			{ 0.253, 0.1, 0.275 },
			{ -0.569, 4.37, 0.15 },
			BLOSSOM2,
			{ joint = "Body", rot = { -44.716, 64.687, 58.653 }, studs = false }
		),
		P(
			"CrownFlower1Centre",
			{ 0.187, 0.14, 0.187 },
			{ -0.431, 4.447, 0.205 },
			BLOOMCORE,
			{ joint = "Body", rot = { -11.603, 44.787, 30.964 }, material = "Neon", studs = false }
		),
		P(
			"CrownFlower2Petal1",
			{ 0.253, 0.1, 0.275 },
			{ 0.439, 4.392, -0.262 },
			BLOSSOM2,
			{ joint = "Body", rot = { -9.782, 3.888, -21.469 }, studs = false }
		),
		P(
			"CrownFlower2Petal2",
			{ 0.253, 0.1, 0.275 },
			{ 0.592, 4.353, -0.15 },
			BLOSSOM,
			{ joint = "Body", rot = { -53.164, -59.551, -46.099 }, studs = false }
		),
		P(
			"CrownFlower2Petal3",
			{ 0.253, 0.1, 0.275 },
			{ 0.549, 4.407, 0.031 },
			BLOSSOM2,
			{ joint = "Body", rot = { 5.826, -143.087, 27.174 }, studs = false }
		),
		P(
			"CrownFlower2Petal4",
			{ 0.253, 0.1, 0.275 },
			{ 0.369, 4.479, 0.031 },
			BLOSSOM,
			{ joint = "Body", rot = { -24.078, 150.601, 24.779 }, studs = false }
		),
		P(
			"CrownFlower2Petal5",
			{ 0.253, 0.1, 0.275 },
			{ 0.301, 4.47, -0.15 },
			BLOSSOM2,
			{ joint = "Body", rot = { 44.716, 64.687, -58.653 }, studs = false }
		),
		P(
			"CrownFlower2Centre",
			{ 0.187, 0.14, 0.187 },
			{ 0.461, 4.447, -0.105 },
			BLOOMCORE,
			{ joint = "Body", rot = { 11.603, 44.787, -30.964 }, material = "Neon", studs = false }
		),
		P(
			"CrownFlower3Petal1",
			{ 0.253, 0.1, 0.275 },
			{ 0, 4.446, 0.598 },
			BLOSSOM2,
			{ joint = "Body", rot = { 26.565, -180, 0 }, studs = false }
		),
		P(
			"CrownFlower3Petal2",
			{ 0.253, 0.1, 0.275 },
			{ -0.157, 4.497, 0.496 },
			BLOSSOM,
			{ joint = "Body", rot = { 26.565, 108, 0 }, studs = false }
		),
		P(
			"CrownFlower3Petal3",
			{ 0.253, 0.1, 0.275 },
			{ -0.097, 4.58, 0.331 },
			BLOSSOM2,
			{ joint = "Body", rot = { 26.565, 36, 0 }, studs = false }
		),
		P(
			"CrownFlower3Petal4",
			{ 0.253, 0.1, 0.275 },
			{ 0.097, 4.58, 0.331 },
			BLOSSOM,
			{ joint = "Body", rot = { 26.565, -36, 0 }, studs = false }
		),
		P(
			"CrownFlower3Petal5",
			{ 0.253, 0.1, 0.275 },
			{ 0.157, 4.497, 0.496 },
			BLOSSOM2,
			{ joint = "Body", rot = { 26.565, -108, 0 }, studs = false }
		),
		P(
			"CrownFlower3Centre",
			{ 0.187, 0.14, 0.187 },
			{ 0, 4.547, 0.463 },
			BLOOMCORE,
			{ joint = "Body", rot = { 26.565, -135, 0 }, material = "Neon", studs = false }
		),
		P(
			"CrownLeaf1",
			{ 0.34, 0.504, 0.1 },
			{ -0.228, 4.554, -0.454 },
			LEAF,
			{ joint = "Body", rot = { -59.452, 22.955, 33.458 }, studs = false }
		),
		P(
			"CrownLeaf1Tip",
			{ 0.24, 0.24, 0.096 },
			{ -0.356, 4.707, -0.607 },
			LEAF,
			{ joint = "Body", rot = { -59.452, 22.955, 78.458 }, studs = false }
		),
		P(
			"CrownLeaf2",
			{ 0.34, 0.504, 0.1 },
			{ 0.304, 4.554, 0.378 },
			LEAF2,
			{ joint = "Body", rot = { 63.812, -152.095, 43.58 }, studs = false }
		),
		P(
			"CrownLeaf2Tip",
			{ 0.24, 0.24, 0.096 },
			{ 0.457, 4.707, 0.506 },
			LEAF2,
			{ joint = "Body", rot = { -116.188, -27.905, -91.42 }, studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P(
			"HingeBody",
			{ 0.23, 0.23, 0.23 },
			{ 0, 2.645, 0.23 },
			MAIN,
			{ joint = "Body", transparency = 1, studs = false }
		),
		P("Chest", { 1.725, 1.725, 1.553 }, { 0, 2.76, -1.092 }, MAIN, { joint = "Body" }),
		P("Barrel", { 1.553, 1.438, 1.61 }, { 0, 2.818, 0.345 }, MAIN2, { joint = "Body" }),
		P("Hips", { 1.668, 1.61, 1.38 }, { 0, 2.932, 1.668 }, MAIN, { joint = "Body" }),
		P("Withers", { 1.265, 0.402, 1.322 }, { 0, 3.737, -0.978 }, MAIN2, { joint = "Body", studs = false }),
		P("Belly", { 1.15, 0.287, 3.105 }, { 0, 1.978, 0.287 }, CREAM, { joint = "Body", studs = false }),
		P("Patch1_1", { 0.069, 0.483, 0.805 }, { -0.794, 3.105, 0.402 }, CREAM, { joint = "Body", studs = false }),
		P("Patch1_2", { 0.069, 0.517, 0.632 }, { -0.851, 3.22, 1.782 }, CREAM, { joint = "Body", studs = false }),
		P("Patch3_1", { 0.069, 0.483, 0.805 }, { 0.794, 3.105, 0.402 }, CREAM, { joint = "Body", studs = false }),
		P("Patch3_2", { 0.069, 0.517, 0.632 }, { 0.851, 3.22, 1.782 }, CREAM, { joint = "Body", studs = false }),
		P("RumpPatch", { 0.92, 0.092, 0.632 }, { 0, 3.76, 1.84 }, CREAM, { joint = "Body", studs = false }),
		P(
			"Ruff1_1",
			{ 0.867, 0.552, 0.391 },
			{ -0.329, 3.45, -1.932 },
			CREAM,
			{ joint = "Body", rot = { 20, 0, -10 }, studs = false }
		),
		P(
			"Ruff1_3",
			{ 0.867, 0.552, 0.391 },
			{ 0.329, 3.45, -1.932 },
			CREAM2,
			{ joint = "Body", rot = { 20, 0, 10 }, studs = false }
		),
		P(
			"Ruff2_1",
			{ 0.907, 0.552, 0.391 },
			{ -0.344, 3.013, -1.978 },
			CREAM2,
			{ joint = "Body", rot = { 20, 0, -10 }, studs = false }
		),
		P(
			"Ruff2_3",
			{ 0.907, 0.552, 0.391 },
			{ 0.344, 3.013, -1.978 },
			CREAM,
			{ joint = "Body", rot = { 20, 0, 10 }, studs = false }
		),
		P(
			"Ruff3_1",
			{ 0.8, 0.552, 0.391 },
			{ -0.304, 2.587, -1.955 },
			CREAM,
			{ joint = "Body", rot = { 20, 0, -10 }, studs = false }
		),
		P(
			"Ruff3_3",
			{ 0.8, 0.552, 0.391 },
			{ 0.304, 2.587, -1.955 },
			CREAM2,
			{ joint = "Body", rot = { 20, 0, 10 }, studs = false }
		),
		P(
			"Ruff4_1",
			{ 0.6, 0.552, 0.391 },
			{ -0.228, 2.185, -1.863 },
			CREAM2,
			{ joint = "Body", rot = { 20, 0, -10 }, studs = false }
		),
		P(
			"Ruff4_3",
			{ 0.6, 0.552, 0.391 },
			{ 0.228, 2.185, -1.863 },
			CREAM,
			{ joint = "Body", rot = { 20, 0, 10 }, studs = false }
		),
		P(
			"Ruff5_1",
			{ 0.367, 0.552, 0.391 },
			{ -0.139, 1.84, -1.725 },
			CREAM,
			{ joint = "Body", rot = { 20, 0, -10 }, studs = false }
		),
		P(
			"Ruff5_3",
			{ 0.367, 0.552, 0.391 },
			{ 0.139, 1.84, -1.725 },
			CREAM2,
			{ joint = "Body", rot = { 20, 0, 10 }, studs = false }
		),
		P(
			"Mantle1",
			{ 0.69, 0.966, 0.138 },
			{ -1.001, 3.594, -1.163 },
			LEAF,
			{ joint = "Body", rot = { -86.864, -27.464, 96.776 }, studs = false }
		),
		P(
			"Mantle1Tip",
			{ 0.488, 0.488, 0.132 },
			{ -1.426, 3.37, -1.118 },
			LEAF,
			{ joint = "Body", rot = { -86.864, -27.464, 141.776 }, studs = false }
		),
		P(
			"Mantle2",
			{ 0.69, 0.966, 0.138 },
			{ 1.001, 3.594, -1.163 },
			LEAF2,
			{ joint = "Body", rot = { -86.864, 27.464, -96.776 }, studs = false }
		),
		P(
			"Mantle2Tip",
			{ 0.488, 0.488, 0.132 },
			{ 1.426, 3.37, -1.118 },
			LEAF2,
			{ joint = "Body", rot = { -86.864, 27.464, -51.776 }, studs = false }
		),
		P(
			"Mantle3",
			{ 0.69, 0.966, 0.138 },
			{ -0.88, 3.562, -0.326 },
			LEAF2,
			{ joint = "Body", rot = { -73.728, -27.891, 121.964 }, studs = false }
		),
		P(
			"Mantle3Tip",
			{ 0.488, 0.488, 0.132 },
			{ -1.242, 3.307, -0.134 },
			LEAF2,
			{ joint = "Body", rot = { -73.728, -27.891, 166.964 }, studs = false }
		),
		P(
			"Mantle4",
			{ 0.69, 0.966, 0.138 },
			{ 0.88, 3.562, -0.326 },
			LEAF,
			{ joint = "Body", rot = { -73.728, 27.891, -121.964 }, studs = false }
		),
		P(
			"Mantle4Tip",
			{ 0.488, 0.488, 0.132 },
			{ 1.242, 3.307, -0.134 },
			LEAF,
			{ joint = "Body", rot = { -73.728, 27.891, -76.964 }, studs = false }
		),
		P(
			"Mantle5",
			{ 0.69, 0.966, 0.138 },
			{ 0, 3.746, 0.305 },
			LEAF,
			{ joint = "Body", rot = { -81.469, 0, 180 }, studs = false }
		),
		P(
			"Mantle5Tip",
			{ 0.488, 0.488, 0.132 },
			{ 0, 3.675, 0.783 },
			LEAF,
			{ joint = "Body", rot = { -81.469, 0, -135 }, studs = false }
		),
		P(
			"Mantle6",
			{ 0.69, 0.966, 0.138 },
			{ 0, 3.639, -2.058 },
			LEAF2,
			{ joint = "Body", rot = { -111.801, 0, 0 }, studs = false }
		),
		P(
			"Mantle6Tip",
			{ 0.488, 0.488, 0.132 },
			{ 0, 3.459, -2.507 },
			LEAF2,
			{ joint = "Body", rot = { -111.801, 0, 45 }, studs = false }
		),
		P(
			"Mantle7",
			{ 0.69, 0.966, 0.138 },
			{ -0.971, 3.585, 0.484 },
			LEAF,
			{ joint = "Body", rot = { -71.737, -22.677, 130.562 }, studs = false }
		),
		P(
			"Mantle7Tip",
			{ 0.488, 0.488, 0.132 },
			{ -1.31, 3.352, 0.738 },
			LEAF,
			{ joint = "Body", rot = { -71.737, -22.677, 175.562 }, studs = false }
		),
		P(
			"Mantle8",
			{ 0.69, 0.966, 0.138 },
			{ 0.971, 3.585, 0.484 },
			LEAF2,
			{ joint = "Body", rot = { -71.737, 22.677, -130.562 }, studs = false }
		),
		P(
			"Mantle8Tip",
			{ 0.488, 0.488, 0.132 },
			{ 1.31, 3.352, 0.738 },
			LEAF2,
			{ joint = "Body", rot = { -71.737, 22.677, -85.562 }, studs = false }
		),
		P(
			"MantleFlower1Petal1",
			{ 0.328, 0.115, 0.356 },
			{ -0.581, 4.022, -1.305 },
			BLOSSOM2,
			{ joint = "Body", rot = { 5.242, 1.57, 16.627 }, studs = false }
		),
		P(
			"MantleFlower1Petal2",
			{ 0.328, 0.115, 0.356 },
			{ -0.382, 4.066, -1.158 },
			BLOSSOM,
			{ joint = "Body", rot = { 44.426, -64.486, 41.612 }, studs = false }
		),
		P(
			"MantleFlower1Petal3",
			{ 0.328, 0.115, 0.356 },
			{ -0.45, 4.022, -0.92 },
			BLOSSOM2,
			{ joint = "Body", rot = { -6.729, -144.186, -20.655 }, studs = false }
		),
		P(
			"MantleFlower1Petal4",
			{ 0.328, 0.115, 0.356 },
			{ -0.691, 3.95, -0.92 },
			BLOSSOM,
			{ joint = "Body", rot = { 16.776, 147.26, -19.881 }, studs = false }
		),
		P(
			"MantleFlower1Petal5",
			{ 0.328, 0.115, 0.356 },
			{ -0.772, 3.95, -1.158 },
			BLOSSOM2,
			{ joint = "Body", rot = { -38.543, 66.84, 46.66 }, studs = false }
		),
		P(
			"MantleFlower1Centre",
			{ 0.242, 0.161, 0.242 },
			{ -0.585, 4.035, -1.089 },
			BLOOMCORE,
			{ joint = "Body", rot = { -11.14, 44.16, 23.498 }, material = "Neon", studs = false }
		),
		P(
			"MantleFlower2Petal1",
			{ 0.307, 0.115, 0.334 },
			{ 0.523, 4.021, -0.832 },
			BLOSSOM2,
			{ joint = "Body", rot = { 5.325, -1.435, -15.043 }, studs = false }
		),
		P(
			"MantleFlower2Petal2",
			{ 0.307, 0.115, 0.334 },
			{ 0.703, 3.958, -0.694 },
			BLOSSOM,
			{ joint = "Body", rot = { -35.48, -67.807, -43.385 }, studs = false }
		),
		P(
			"MantleFlower2Petal3",
			{ 0.307, 0.115, 0.334 },
			{ 0.627, 3.956, -0.471 },
			BLOSSOM2,
			{ joint = "Body", rot = { 15.826, -146.825, 18.058 }, studs = false }
		),
		P(
			"MantleFlower2Petal4",
			{ 0.307, 0.115, 0.333 },
			{ 0.4, 4.018, -0.471 },
			BLOSSOM,
			{ joint = "Body", rot = { -5.544, 144.004, 18.705 }, studs = false }
		),
		P(
			"MantleFlower2Petal5",
			{ 0.307, 0.115, 0.334 },
			{ 0.335, 4.057, -0.694 },
			BLOSSOM2,
			{ joint = "Body", rot = { 41.961, 65.566, -38.847 }, studs = false }
		),
		P(
			"MantleFlower2Centre",
			{ 0.227, 0.161, 0.227 },
			{ 0.526, 4.035, -0.629 },
			BLOOMCORE,
			{ joint = "Body", rot = { 19.549, 41.678, -20.328 }, material = "Neon", studs = false }
		),
		P(
			"MantleFlower3Petal1",
			{ 0.265, 0.115, 0.287 },
			{ 0.058, 4.019, -1.667 },
			BLOSSOM2,
			{ joint = "Body", rot = { 5.705, -0.171, -1.71 }, studs = false }
		),
		P(
			"MantleFlower3Petal2",
			{ 0.264, 0.115, 0.287 },
			{ 0.222, 4.002, -1.548 },
			BLOSSOM,
			{ joint = "Body", rot = { 0.41, -72.092, -5.569 }, studs = false }
		),
		P(
			"MantleFlower3Petal3",
			{ 0.265, 0.115, 0.288 },
			{ 0.158, 3.985, -1.356 },
			BLOSSOM2,
			{ joint = "Body", rot = { 6.945, -144.189, 2.109 }, studs = false }
		),
		P(
			"MantleFlower3Petal4",
			{ 0.265, 0.115, 0.287 },
			{ -0.044, 3.991, -1.356 },
			BLOSSOM,
			{ joint = "Body", rot = { 4.461, 143.848, 2.118 }, studs = false }
		),
		P(
			"MantleFlower3Petal5",
			{ 0.265, 0.115, 0.288 },
			{ -0.106, 4.012, -1.548 },
			BLOSSOM2,
			{ joint = "Body", rot = { 10.905, 71.751, -5.468 }, studs = false }
		),
		P(
			"MantleFlower3Centre",
			{ 0.195, 0.161, 0.195 },
			{ 0.059, 4.036, -1.492 },
			BLOOMCORE,
			{ joint = "Body", rot = { 7.41, 44.804, -2.41 }, material = "Neon", studs = false }
		),
		P(
			"HingeNeck",
			{ 0.23, 0.23, 0.23 },
			{ 0, 3.392, -1.38 },
			MAIN,
			{ joint = "Neck", transparency = 1, studs = false }
		),
		P("NeckLow", { 0.978, 1.08, 1.035 }, { 0, 3.651, -1.552 }, MAIN, { joint = "Neck", rot = { -25.201, 0, 0 } }),
		P("NeckHigh", { 0.805, 0.876, 0.874 }, { 0, 4.37, -1.897 }, MAIN2, { joint = "Neck", rot = { -23.199, 0, 0 } }),
		P(
			"NeckRuff1",
			{ 0.805, 0.517, 0.345 },
			{ 0, 3.852, -2.128 },
			CREAM2,
			{ joint = "Neck", rot = { 25, 0, 0 }, studs = false }
		),
		P(
			"NeckRuff2",
			{ 0.69, 0.517, 0.345 },
			{ 0, 4.312, -2.323 },
			CREAM,
			{ joint = "Neck", rot = { 25, 0, 0 }, studs = false }
		),
		P(
			"NeckRuff3",
			{ 0.575, 0.517, 0.345 },
			{ 0, 4.658, -2.438 },
			CREAM2,
			{ joint = "Neck", rot = { 25, 0, 0 }, studs = false }
		),
		P(
			"HingeHead",
			{ 0.23, 0.23, 0.23 },
			{ 0, 4.715, -2.07 },
			MAIN,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P("Skull", { 0.966, 0.869, 1.026 }, { 0, 5.002, -2.357 }, MAIN, { joint = "Head", rot = { -12, 0, 0 } }),
		P(
			"Forehead",
			{ 0.773, 0.266, 0.664 },
			{ 0, 5.426, -2.571 },
			MAIN2,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P("Muzzle", { 0.676, 0.604, 0.906 }, { 0, 4.68, -3.178 }, MAIN, { joint = "Head", rot = { -12, 0, 0 } }),
		P(
			"MuzzleTip",
			{ 0.58, 0.507, 0.362 },
			{ 0, 4.525, -3.676 },
			CREAM,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"Nose",
			{ 0.362, 0.217, 0.145 },
			{ 0, 4.624, -3.907 },
			NOSE,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"Jaw",
			{ 0.604, 0.242, 0.906 },
			{ 0, 4.354, -3.084 },
			CREAM,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"Cheek1",
			{ 0.145, 0.435, 0.664 },
			{ -0.459, 4.63, -2.834 },
			CREAM,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"Cheek3",
			{ 0.145, 0.435, 0.664 },
			{ 0.459, 4.63, -2.834 },
			CREAM,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"SocketL",
			{ 0.072, 0.283, 0.399 },
			{ -0.495, 5.018, -2.632 },
			INK,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"EyeL",
			{ 0.06, 0.217, 0.338 },
			{ -0.531, 5.018, -2.632 },
			EYE,
			{ joint = "Head", rot = { -12, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"PupilL",
			{ 0.048, 0.2, 0.061 },
			{ -0.555, 5.01, -2.672 },
			INK,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"GlintL",
			{ 0.036, 0.065, 0.065 },
			{ -0.574, 5.057, -2.744 },
			GLINT,
			{ joint = "Head", rot = { -12, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"SocketR",
			{ 0.072, 0.283, 0.399 },
			{ 0.495, 5.018, -2.632 },
			INK,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"EyeR",
			{ 0.06, 0.217, 0.338 },
			{ 0.531, 5.018, -2.632 },
			EYE,
			{ joint = "Head", rot = { -12, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"PupilR",
			{ 0.048, 0.2, 0.061 },
			{ 0.555, 5.01, -2.672 },
			INK,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"GlintR",
			{ 0.036, 0.065, 0.065 },
			{ 0.574, 5.057, -2.744 },
			GLINT,
			{ joint = "Head", rot = { -12, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"EarL",
			{ 0.46, 0.753, 0.138 },
			{ -0.81, 5.482, -1.972 },
			MAIN,
			{ joint = "Head", rot = { 9.578, -170.911, -61.617 }, studs = false }
		),
		P(
			"EarLTip",
			{ 0.325, 0.325, 0.132 },
			{ -1.138, 5.65, -1.891 },
			MAIN,
			{ joint = "Head", rot = { 9.578, -170.911, -16.617 }, studs = false }
		),
		P(
			"EarLVein",
			{ 0.074, 0.718, 0.057 },
			{ -0.823, 5.483, -1.899 },
			CREAM,
			{ joint = "Head", rot = { 9.578, -170.911, -61.617 }, studs = false }
		),
		P(
			"EarR",
			{ 0.46, 0.753, 0.138 },
			{ 0.81, 5.482, -1.972 },
			MAIN,
			{ joint = "Head", rot = { 9.578, 170.911, 61.617 }, studs = false }
		),
		P(
			"EarRTip",
			{ 0.325, 0.325, 0.132 },
			{ 1.138, 5.65, -1.891 },
			MAIN,
			{ joint = "Head", rot = { -170.422, 9.089, -73.383 }, studs = false }
		),
		P(
			"EarRVein",
			{ 0.074, 0.718, 0.057 },
			{ 0.823, 5.483, -1.899 },
			CREAM,
			{ joint = "Head", rot = { 9.578, 170.911, 61.617 }, studs = false }
		),
		P(
			"Crown",
			{ 1.087, 0.193, 1.147 },
			{ 0, 5.428, -2.448 },
			GOLD,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"CrownTrim",
			{ 1.159, 0.072, 1.207 },
			{ 0, 5.333, -2.428 },
			GOLD2,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"CrownPoint1",
			{ 0.193, 0.338, 0.193 },
			{ -0.411, 5.574, -2.923 },
			GOLD,
			{ joint = "Head", rot = { -12, 0, 45 }, studs = false }
		),
		P(
			"CrownPoint2",
			{ 0.193, 0.435, 0.193 },
			{ -0.205, 5.601, -3.028 },
			GOLD,
			{ joint = "Head", rot = { -12, 0, 45 }, studs = false }
		),
		P(
			"CrownPoint3",
			{ 0.193, 0.555, 0.193 },
			{ 0, 5.65, -3.088 },
			GOLD,
			{ joint = "Head", rot = { -12, 0, 45 }, studs = false }
		),
		P(
			"CrownPoint4",
			{ 0.193, 0.435, 0.193 },
			{ 0.205, 5.601, -3.028 },
			GOLD,
			{ joint = "Head", rot = { -12, 0, 45 }, studs = false }
		),
		P(
			"CrownPoint5",
			{ 0.193, 0.338, 0.193 },
			{ 0.411, 5.574, -2.923 },
			GOLD,
			{ joint = "Head", rot = { -12, 0, 45 }, studs = false }
		),
		P(
			"CrownGem",
			{ 0.314, 0.314, 0.145 },
			{ 0, 5.522, -3.11 },
			GEM,
			{ joint = "Head", rot = { -12, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"AntlerL1",
			{ 0.299, 0.897, 0.299 },
			{ -0.519, 5.861, -2.317 },
			ANTLER,
			{ joint = "Head", rot = { 6.294, 3.763, 30.757 }, studs = false }
		),
		P(
			"AntlerL2",
			{ 0.257, 1.012, 0.257 },
			{ -1.122, 6.422, -2.186 },
			ANTLER,
			{ joint = "Head", rot = { 4.827, 8.699, 60.822 }, studs = false }
		),
		P(
			"AntlerL3",
			{ 0.221, 0.955, 0.221 },
			{ -1.859, 6.905, -2.088 },
			ANTLER,
			{ joint = "Head", rot = { 1.542, 1.982, 52.098 }, studs = false }
		),
		P(
			"AntlerL4",
			{ 0.19, 0.782, 0.19 },
			{ -2.514, 7.307, -2.089 },
			ANTLER,
			{ joint = "Head", rot = { -1.315, -3.002, 66.336 }, studs = false }
		),
		P(
			"TineL1",
			{ 0.184, 0.69, 0.184 },
			{ -0.783, 6.495, -2.441 },
			ANTLER2,
			{ joint = "Head", rot = { -29.982, -5.707, 9.78 }, studs = false }
		),
		P(
			"TineL2",
			{ 0.184, 0.748, 0.184 },
			{ -1.572, 6.994, -2.001 },
			ANTLER2,
			{ joint = "Head", rot = { 16.352, 2.418, 8.183 }, studs = false }
		),
		P(
			"TineL3",
			{ 0.184, 0.632, 0.184 },
			{ -2.284, 7.452, -2.182 },
			ANTLER2,
			{ joint = "Head", rot = { -20.152, -5.901, 15.65 }, studs = false }
		),
		P(
			"AntlerFlowerL1Petal1",
			{ 0.317, 0.115, 0.345 },
			{ -0.892, 6.75, -2.831 },
			BLOSSOM2,
			{ joint = "Head", rot = { -34.083, 9.84, 6.596 }, studs = false }
		),
		P(
			"AntlerFlowerL1Petal2",
			{ 0.317, 0.115, 0.345 },
			{ -0.675, 6.829, -2.755 },
			BLOSSOM,
			{ joint = "Head", rot = { -20.887, -61.408, 13.68 }, studs = false }
		),
		P(
			"AntlerFlowerL1Petal3",
			{ 0.317, 0.115, 0.345 },
			{ -0.709, 6.957, -2.551 },
			BLOSSOM2,
			{ joint = "Head", rot = { -39.614, -134.474, -9.297 }, studs = false }
		),
		P(
			"AntlerFlowerL1Petal4",
			{ 0.317, 0.115, 0.345 },
			{ -0.947, 6.957, -2.501 },
			BLOSSOM,
			{ joint = "Head", rot = { -29.778, 154.085, -7.229 }, studs = false }
		),
		P(
			"AntlerFlowerL1Petal5",
			{ 0.317, 0.115, 0.345 },
			{ -1.061, 6.829, -2.674 },
			BLOSSOM2,
			{ joint = "Head", rot = { -71.461, 79.632, 38.971 }, studs = false }
		),
		P(
			"AntlerFlowerL1Centre",
			{ 0.235, 0.161, 0.235 },
			{ -0.861, 6.893, -2.681 },
			BLOOMCORE,
			{ joint = "Head", rot = { -42.101, 54.384, 11.207 }, material = "Neon", studs = false }
		),
		P(
			"AntlerFlowerL2Petal1",
			{ 0.265, 0.115, 0.288 },
			{ -1.638, 7.434, -2.041 },
			BLOSSOM2,
			{ joint = "Head", rot = { -0.655, -0.069, 6.022 }, studs = false }
		),
		P(
			"AntlerFlowerL2Petal2",
			{ 0.264, 0.115, 0.288 },
			{ -1.475, 7.453, -1.921 },
			BLOSSOM,
			{ joint = "Head", rot = { 17.301, -71.117, 18.913 }, studs = false }
		),
		P(
			"AntlerFlowerL2Petal3",
			{ 0.264, 0.115, 0.288 },
			{ -1.537, 7.448, -1.729 },
			BLOSSOM2,
			{ joint = "Head", rot = { -5.009, -144.298, -7.422 }, studs = false }
		),
		P(
			"AntlerFlowerL2Petal4",
			{ 0.265, 0.115, 0.288 },
			{ -1.739, 7.427, -1.729 },
			BLOSSOM,
			{ joint = "Head", rot = { 3.708, 144.161, -7.435 }, studs = false }
		),
		P(
			"AntlerFlowerL2Petal5",
			{ 0.265, 0.115, 0.288 },
			{ -1.801, 7.418, -1.921 },
			BLOSSOM2,
			{ joint = "Head", rot = { -18.486, 70.985, 18.783 }, studs = false }
		),
		P(
			"AntlerFlowerL2Centre",
			{ 0.196, 0.161, 0.195 },
			{ -1.642, 7.47, -1.869 },
			BLOOMCORE,
			{ joint = "Head", rot = { -6.636, 44.616, 8.475 }, material = "Neon", studs = false }
		),
		P(
			"AntlerFlowerL3Petal1",
			{ 0.317, 0.115, 0.345 },
			{ -2.462, 7.717, -2.496 },
			BLOSSOM2,
			{ joint = "Head", rot = { -30.656, 19.337, 11.104 }, studs = false }
		),
		P(
			"AntlerFlowerL3Petal2",
			{ 0.317, 0.115, 0.345 },
			{ -2.232, 7.786, -2.455 },
			BLOSSOM,
			{ joint = "Head", rot = { -13.696, -51.103, 16.823 }, studs = false }
		),
		P(
			"AntlerFlowerL3Petal3",
			{ 0.317, 0.115, 0.345 },
			{ -2.225, 7.898, -2.238 },
			BLOSSOM2,
			{ joint = "Head", rot = { -41.843, -125.695, -18.147 }, studs = false }
		),
		P(
			"AntlerFlowerL3Petal4",
			{ 0.317, 0.115, 0.345 },
			{ -2.451, 7.898, -2.146 },
			BLOSSOM,
			{ joint = "Head", rot = { -23.892, 163.957, -10.9 }, studs = false }
		),
		P(
			"AntlerFlowerL3Petal5",
			{ 0.317, 0.115, 0.345 },
			{ -2.597, 7.786, -2.306 },
			BLOSSOM2,
			{ joint = "Head", rot = { 53.905, 100.602, -80.996 }, studs = false }
		),
		P(
			"AntlerFlowerL3Centre",
			{ 0.235, 0.161, 0.235 },
			{ -2.4, 7.847, -2.344 },
			BLOOMCORE,
			{ joint = "Head", rot = { -47.948, 62.731, 23.368 }, material = "Neon", studs = false }
		),
		P(
			"AntlerFlowerL4Petal1",
			{ 0.317, 0.115, 0.345 },
			{ -3.036, 7.321, -2.161 },
			BLOSSOM2,
			{ joint = "Head", rot = { -73.49, 36.046, 63.264 }, studs = false }
		),
		P(
			"AntlerFlowerL4Petal2",
			{ 0.317, 0.115, 0.345 },
			{ -2.88, 7.432, -2.312 },
			BLOSSOM,
			{ joint = "Head", rot = { -14.054, -9.445, 47.057 }, studs = false }
		),
		P(
			"AntlerFlowerL4Petal3",
			{ 0.317, 0.115, 0.345 },
			{ -2.771, 7.612, -2.189 },
			BLOSSOM2,
			{ joint = "Head", rot = { 60.032, -43.619, 85.913 }, studs = false }
		),
		P(
			"AntlerFlowerL4Petal4",
			{ 0.317, 0.115, 0.345 },
			{ -2.86, 7.612, -1.962 },
			BLOSSOM,
			{ joint = "Head", rot = { -40.534, -164.796, -48.443 }, studs = false }
		),
		P(
			"AntlerFlowerL4Petal5",
			{ 0.317, 0.115, 0.345 },
			{ -3.023, 7.432, -1.945 },
			BLOSSOM2,
			{ joint = "Head", rot = { 16.381, 148.145, -58.228 }, studs = false }
		),
		P(
			"AntlerFlowerL4Centre",
			{ 0.235, 0.161, 0.235 },
			{ -2.939, 7.504, -2.124 },
			BLOOMCORE,
			{ joint = "Head", rot = { 47.848, 137.678, -77.591 }, material = "Neon", studs = false }
		),
		P(
			"AntlerLeafL1",
			{ 0.391, 0.58, 0.115 },
			{ -0.94, 6.265, -2.081 },
			LEAF2,
			{ joint = "Head", rot = { -90.971, 15.171, 129.755 }, studs = false }
		),
		P(
			"AntlerLeafL1Tip",
			{ 0.276, 0.276, 0.11 },
			{ -1.155, 6.326, -1.897 },
			LEAF2,
			{ joint = "Head", rot = { 89.029, 164.829, -5.245 }, studs = false }
		),
		P(
			"AntlerLeafL2",
			{ 0.391, 0.58, 0.115 },
			{ -1.642, 6.548, -2.353 },
			LEAF,
			{ joint = "Head", rot = { -104.18, -13.345, 25.834 }, studs = false }
		),
		P(
			"AntlerLeafL2Tip",
			{ 0.276, 0.276, 0.11 },
			{ -1.765, 6.456, -2.598 },
			LEAF,
			{ joint = "Head", rot = { -104.18, -13.345, 70.834 }, studs = false }
		),
		P(
			"AntlerLeafL3",
			{ 0.391, 0.58, 0.115 },
			{ -2.378, 7.259, -1.86 },
			LEAF2,
			{ joint = "Head", rot = { -98.448, 17.91, 139.43 }, studs = false }
		),
		P(
			"AntlerLeafL3Tip",
			{ 0.276, 0.276, 0.11 },
			{ -2.558, 7.348, -1.651 },
			LEAF2,
			{ joint = "Head", rot = { 81.552, 162.09, 4.431 }, studs = false }
		),
		P(
			"AntlerLeafL4",
			{ 0.391, 0.58, 0.115 },
			{ -2.893, 7.319, -2.362 },
			LEAF,
			{ joint = "Head", rot = { -114.444, -9.398, 12.779 }, studs = false }
		),
		P(
			"AntlerLeafL4Tip",
			{ 0.276, 0.276, 0.11 },
			{ -2.957, 7.192, -2.615 },
			LEAF,
			{ joint = "Head", rot = { -114.444, -9.398, 57.779 }, studs = false }
		),
		P(
			"AntlerR1",
			{ 0.299, 0.897, 0.299 },
			{ 0.519, 5.861, -2.317 },
			ANTLER,
			{ joint = "Head", rot = { 6.294, -3.763, -30.757 }, studs = false }
		),
		P(
			"AntlerR2",
			{ 0.257, 1.012, 0.257 },
			{ 1.122, 6.422, -2.186 },
			ANTLER,
			{ joint = "Head", rot = { 4.827, -8.699, -60.822 }, studs = false }
		),
		P(
			"AntlerR3",
			{ 0.221, 0.955, 0.221 },
			{ 1.859, 6.905, -2.088 },
			ANTLER,
			{ joint = "Head", rot = { 1.542, -1.982, -52.098 }, studs = false }
		),
		P(
			"AntlerR4",
			{ 0.19, 0.782, 0.19 },
			{ 2.514, 7.307, -2.089 },
			ANTLER,
			{ joint = "Head", rot = { -1.315, 3.002, -66.336 }, studs = false }
		),
		P(
			"TineR1",
			{ 0.184, 0.69, 0.184 },
			{ 0.783, 6.495, -2.441 },
			ANTLER2,
			{ joint = "Head", rot = { -29.982, 5.707, -9.78 }, studs = false }
		),
		P(
			"TineR2",
			{ 0.184, 0.748, 0.184 },
			{ 1.572, 6.994, -2.001 },
			ANTLER2,
			{ joint = "Head", rot = { 16.352, -2.418, -8.183 }, studs = false }
		),
		P(
			"TineR3",
			{ 0.184, 0.632, 0.184 },
			{ 2.284, 7.452, -2.182 },
			ANTLER2,
			{ joint = "Head", rot = { -20.152, 5.901, -15.65 }, studs = false }
		),
		P(
			"AntlerFlowerR1Petal1",
			{ 0.317, 0.115, 0.345 },
			{ 0.892, 6.75, -2.831 },
			BLOSSOM2,
			{ joint = "Head", rot = { -34.083, -9.84, -6.596 }, studs = false }
		),
		P(
			"AntlerFlowerR1Petal2",
			{ 0.317, 0.115, 0.345 },
			{ 1.061, 6.829, -2.674 },
			BLOSSOM,
			{ joint = "Head", rot = { -71.461, -79.632, -38.971 }, studs = false }
		),
		P(
			"AntlerFlowerR1Petal3",
			{ 0.317, 0.115, 0.345 },
			{ 0.947, 6.957, -2.501 },
			BLOSSOM2,
			{ joint = "Head", rot = { -29.778, -154.085, 7.229 }, studs = false }
		),
		P(
			"AntlerFlowerR1Petal4",
			{ 0.317, 0.115, 0.345 },
			{ 0.709, 6.957, -2.551 },
			BLOSSOM,
			{ joint = "Head", rot = { -39.614, 134.474, 9.297 }, studs = false }
		),
		P(
			"AntlerFlowerR1Petal5",
			{ 0.317, 0.115, 0.345 },
			{ 0.675, 6.829, -2.755 },
			BLOSSOM2,
			{ joint = "Head", rot = { -20.887, 61.408, -13.68 }, studs = false }
		),
		P(
			"AntlerFlowerR1Centre",
			{ 0.235, 0.161, 0.235 },
			{ 0.861, 6.893, -2.681 },
			BLOOMCORE,
			{ joint = "Head", rot = { -28.404, 34.837, -7.926 }, material = "Neon", studs = false }
		),
		P(
			"AntlerFlowerR2Petal1",
			{ 0.265, 0.115, 0.288 },
			{ 1.638, 7.434, -2.041 },
			BLOSSOM2,
			{ joint = "Head", rot = { -0.655, 0.069, -6.022 }, studs = false }
		),
		P(
			"AntlerFlowerR2Petal2",
			{ 0.264, 0.115, 0.288 },
			{ 1.801, 7.418, -1.921 },
			BLOSSOM,
			{ joint = "Head", rot = { -18.486, -70.985, -18.783 }, studs = false }
		),
		P(
			"AntlerFlowerR2Petal3",
			{ 0.265, 0.115, 0.288 },
			{ 1.739, 7.427, -1.729 },
			BLOSSOM2,
			{ joint = "Head", rot = { 3.708, -144.16, 7.435 }, studs = false }
		),
		P(
			"AntlerFlowerR2Petal4",
			{ 0.264, 0.115, 0.288 },
			{ 1.537, 7.448, -1.729 },
			BLOSSOM,
			{ joint = "Head", rot = { -5.009, 144.298, 7.422 }, studs = false }
		),
		P(
			"AntlerFlowerR2Petal5",
			{ 0.265, 0.115, 0.287 },
			{ 1.475, 7.453, -1.921 },
			BLOSSOM2,
			{ joint = "Head", rot = { 17.301, 71.117, -18.913 }, studs = false }
		),
		P(
			"AntlerFlowerR2Centre",
			{ 0.196, 0.161, 0.196 },
			{ 1.642, 7.47, -1.869 },
			BLOOMCORE,
			{ joint = "Head", rot = { 5.341, 44.753, -8.495 }, material = "Neon", studs = false }
		),
		P(
			"AntlerFlowerR3Petal1",
			{ 0.317, 0.115, 0.345 },
			{ 2.462, 7.717, -2.496 },
			BLOSSOM2,
			{ joint = "Head", rot = { -30.656, -19.337, -11.104 }, studs = false }
		),
		P(
			"AntlerFlowerR3Petal2",
			{ 0.317, 0.115, 0.345 },
			{ 2.597, 7.786, -2.306 },
			BLOSSOM,
			{ joint = "Head", rot = { 53.905, -100.602, 80.996 }, studs = false }
		),
		P(
			"AntlerFlowerR3Petal3",
			{ 0.317, 0.115, 0.345 },
			{ 2.451, 7.898, -2.146 },
			BLOSSOM2,
			{ joint = "Head", rot = { -23.891, -163.957, 10.9 }, studs = false }
		),
		P(
			"AntlerFlowerR3Petal4",
			{ 0.317, 0.115, 0.345 },
			{ 2.225, 7.898, -2.238 },
			BLOSSOM,
			{ joint = "Head", rot = { -41.843, 125.695, 18.147 }, studs = false }
		),
		P(
			"AntlerFlowerR3Petal5",
			{ 0.317, 0.115, 0.345 },
			{ 2.232, 7.786, -2.455 },
			BLOSSOM2,
			{ joint = "Head", rot = { -13.696, 51.103, -16.823 }, studs = false }
		),
		P(
			"AntlerFlowerR3Centre",
			{ 0.235, 0.161, 0.235 },
			{ 2.4, 7.847, -2.344 },
			BLOOMCORE,
			{ joint = "Head", rot = { -22.023, 24.871, -11.555 }, material = "Neon", studs = false }
		),
		P(
			"AntlerFlowerR4Petal1",
			{ 0.317, 0.115, 0.345 },
			{ 3.036, 7.321, -2.161 },
			BLOSSOM2,
			{ joint = "Head", rot = { -73.49, -36.046, -63.264 }, studs = false }
		),
		P(
			"AntlerFlowerR4Petal2",
			{ 0.317, 0.115, 0.345 },
			{ 3.023, 7.432, -1.945 },
			BLOSSOM,
			{ joint = "Head", rot = { 16.381, -148.145, 58.228 }, studs = false }
		),
		P(
			"AntlerFlowerR4Petal3",
			{ 0.317, 0.115, 0.345 },
			{ 2.86, 7.612, -1.962 },
			BLOSSOM2,
			{ joint = "Head", rot = { -40.534, 164.796, 48.443 }, studs = false }
		),
		P(
			"AntlerFlowerR4Petal4",
			{ 0.317, 0.115, 0.345 },
			{ 2.771, 7.612, -2.189 },
			BLOSSOM,
			{ joint = "Head", rot = { 60.032, 43.619, -85.913 }, studs = false }
		),
		P(
			"AntlerFlowerR4Petal5",
			{ 0.317, 0.115, 0.345 },
			{ 2.88, 7.432, -2.312 },
			BLOSSOM2,
			{ joint = "Head", rot = { -14.054, 9.445, -47.057 }, studs = false }
		),
		P(
			"AntlerFlowerR4Centre",
			{ 0.235, 0.161, 0.235 },
			{ 2.939, 7.504, -2.124 },
			BLOOMCORE,
			{ joint = "Head", rot = { -33.725, -9.142, -47.003 }, material = "Neon", studs = false }
		),
		P(
			"AntlerLeafR1",
			{ 0.391, 0.58, 0.115 },
			{ 0.94, 6.265, -2.081 },
			LEAF2,
			{ joint = "Head", rot = { -90.971, -15.171, -129.755 }, studs = false }
		),
		P(
			"AntlerLeafR1Tip",
			{ 0.276, 0.276, 0.11 },
			{ 1.155, 6.326, -1.897 },
			LEAF2,
			{ joint = "Head", rot = { -90.971, -15.171, -84.755 }, studs = false }
		),
		P(
			"AntlerLeafR2",
			{ 0.391, 0.58, 0.115 },
			{ 1.642, 6.548, -2.353 },
			LEAF,
			{ joint = "Head", rot = { -104.18, 13.345, -25.834 }, studs = false }
		),
		P(
			"AntlerLeafR2Tip",
			{ 0.276, 0.276, 0.11 },
			{ 1.765, 6.456, -2.598 },
			LEAF,
			{ joint = "Head", rot = { -104.18, 13.345, 19.166 }, studs = false }
		),
		P(
			"AntlerLeafR3",
			{ 0.391, 0.58, 0.115 },
			{ 2.378, 7.259, -1.86 },
			LEAF2,
			{ joint = "Head", rot = { -98.448, -17.91, -139.43 }, studs = false }
		),
		P(
			"AntlerLeafR3Tip",
			{ 0.276, 0.276, 0.11 },
			{ 2.558, 7.348, -1.651 },
			LEAF2,
			{ joint = "Head", rot = { -98.448, -17.91, -94.43 }, studs = false }
		),
		P(
			"AntlerLeafR4",
			{ 0.391, 0.58, 0.115 },
			{ 2.893, 7.319, -2.362 },
			LEAF,
			{ joint = "Head", rot = { -114.444, 9.398, -12.779 }, studs = false }
		),
		P(
			"AntlerLeafR4Tip",
			{ 0.276, 0.276, 0.11 },
			{ 2.957, 7.192, -2.615 },
			LEAF,
			{ joint = "Head", rot = { -114.444, 9.398, 32.221 }, studs = false }
		),
		P(
			"HingeArmL",
			{ 0.23, 0.23, 0.23 },
			{ -0.517, 2.357, -1.092 },
			MAIN,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P(
			"UpperArmL",
			{ 0.529, 1.175, 0.529 },
			{ -0.535, 1.84, -1.121 },
			MAIN,
			{ joint = "ArmL", rot = { 3.176, -0.106, 178.094 } }
		),
		P(
			"LowerArmL",
			{ 0.414, 1.025, 0.414 },
			{ -0.552, 0.88, -1.179 },
			CREAM,
			{ joint = "ArmL", rot = { 3.715, 0, -180 } }
		),
		P("ArmKneeL", { 0.483, 0.276, 0.483 }, { -0.552, 1.322, -1.15 }, CREAM2, { joint = "ArmL", studs = false }),
		P("ArmHoofL", { 0.575, 0.414, 0.644 }, { -0.552, 0.207, -1.265 }, GOLD, { joint = "ArmL", studs = false }),
		P("ArmHoofFrontL", { 0.483, 0.23, 0.138 }, { -0.552, 0.138, -1.61 }, GOLD2, { joint = "ArmL", studs = false }),
		P(
			"HingeLegL",
			{ 0.23, 0.23, 0.23 },
			{ -0.552, 2.587, 1.668 },
			MAIN,
			{ joint = "LegL", transparency = 1, studs = false }
		),
		P(
			"UpperLegL",
			{ 0.667, 1.087, 0.667 },
			{ -0.575, 2.128, 1.553 },
			MAIN,
			{ joint = "LegL", rot = { 14.003, -0.693, 177.223 } }
		),
		P(
			"MidLegL",
			{ 0.46, 0.912, 0.46 },
			{ -0.598, 1.38, 1.696 },
			MAIN2,
			{ joint = "LegL", rot = { -41.987, 0, 180 } }
		),
		P(
			"LowerLegL",
			{ 0.414, 0.804, 0.414 },
			{ -0.598, 0.765, 1.898 },
			CREAM,
			{ joint = "LegL", rot = { 9.951, 0, -180 } }
		),
		P("LegHoofL", { 0.575, 0.414, 0.644 }, { -0.598, 0.207, 1.782 }, GOLD, { joint = "LegL", studs = false }),
		P("LegHoofFrontL", { 0.483, 0.23, 0.138 }, { -0.598, 0.138, 1.438 }, GOLD2, { joint = "LegL", studs = false }),
		P(
			"HingeArmR",
			{ 0.23, 0.23, 0.23 },
			{ 0.517, 2.357, -1.092 },
			MAIN,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P(
			"UpperArmR",
			{ 0.529, 1.175, 0.529 },
			{ 0.535, 1.84, -1.121 },
			MAIN,
			{ joint = "ArmR", rot = { 3.176, 0.106, -178.094 } }
		),
		P(
			"LowerArmR",
			{ 0.414, 1.025, 0.414 },
			{ 0.552, 0.88, -1.179 },
			CREAM,
			{ joint = "ArmR", rot = { 3.715, 0, -180 } }
		),
		P("ArmKneeR", { 0.483, 0.276, 0.483 }, { 0.552, 1.322, -1.15 }, CREAM2, { joint = "ArmR", studs = false }),
		P("ArmHoofR", { 0.575, 0.414, 0.644 }, { 0.552, 0.207, -1.265 }, GOLD, { joint = "ArmR", studs = false }),
		P("ArmHoofFrontR", { 0.483, 0.23, 0.138 }, { 0.552, 0.138, -1.61 }, GOLD2, { joint = "ArmR", studs = false }),
		P(
			"HingeLegR",
			{ 0.23, 0.23, 0.23 },
			{ 0.552, 2.587, 1.668 },
			MAIN,
			{ joint = "LegR", transparency = 1, studs = false }
		),
		P(
			"UpperLegR",
			{ 0.667, 1.087, 0.667 },
			{ 0.575, 2.128, 1.553 },
			MAIN,
			{ joint = "LegR", rot = { 14.003, 0.693, -177.223 } }
		),
		P(
			"MidLegR",
			{ 0.46, 0.912, 0.46 },
			{ 0.598, 1.38, 1.696 },
			MAIN2,
			{ joint = "LegR", rot = { -41.987, 0, 180 } }
		),
		P(
			"LowerLegR",
			{ 0.414, 0.804, 0.414 },
			{ 0.598, 0.765, 1.898 },
			CREAM,
			{ joint = "LegR", rot = { 9.951, 0, -180 } }
		),
		P("LegHoofR", { 0.575, 0.414, 0.644 }, { 0.598, 0.207, 1.782 }, GOLD, { joint = "LegR", studs = false }),
		P("LegHoofFrontR", { 0.483, 0.23, 0.138 }, { 0.598, 0.138, 1.438 }, GOLD2, { joint = "LegR", studs = false }),
		P(
			"HingeTail",
			{ 0.23, 0.23, 0.23 },
			{ 0, 3.392, 2.3 },
			MAIN,
			{ joint = "Tail", transparency = 1, studs = false }
		),
		P(
			"Tail1",
			{ 0.604, 0.575, 0.575 },
			{ 0, 3.45, 2.473 },
			MAIN,
			{ joint = "Tail", rot = { 20, 0, 0 }, studs = false }
		),
		P(
			"Tail2",
			{ 0.749, 0.713, 0.713 },
			{ 0, 3.795, 2.76 },
			CREAM,
			{ joint = "Tail", rot = { 35, 0, 0 }, studs = false }
		),
		P(
			"Tail3",
			{ 0.7, 0.667, 0.667 },
			{ 0, 4.232, 2.932 },
			CREAM2,
			{ joint = "Tail", rot = { 15, 0, 0 }, studs = false }
		),
		P(
			"Tail4",
			{ 0.555, 0.529, 0.529 },
			{ 0, 4.6, 2.852 },
			CREAM,
			{ joint = "Tail", rot = { -10, 0, 0 }, studs = false }
		),
		P(
			"Tail5",
			{ 0.386, 0.368, 0.368 },
			{ 0, 4.853, 2.645 },
			CREAM2,
			{ joint = "Tail", rot = { -30, 0, 0 }, studs = false }
		),
		P(
			"TailTuft1",
			{ 0.345, 0.46, 0.391 },
			{ -0.345, 4.025, 2.932 },
			CREAM,
			{ joint = "Tail", rot = { 0, 0, -25 }, studs = false }
		),
		P(
			"TailTuft3",
			{ 0.345, 0.46, 0.391 },
			{ 0.345, 4.025, 2.932 },
			CREAM,
			{ joint = "Tail", rot = { 0, 0, 25 }, studs = false }
		),
	},
}

return { egg = egg, pet = pet }
