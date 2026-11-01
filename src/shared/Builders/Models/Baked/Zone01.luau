--!strict
-- Zone 1 Meadow: egg + pet block data for Sprout Pup, Bumble Bloc and Meadow Stag (docs/EggPetPlan.md).
-- BAKED FILE: modelled in Blender from Roblox primitives (assets/blender/pets/Zone01.blend) by the pet kit in
-- tools/blender/pets (data: zones/zone01_meadow.py). Change the data there and re-bake instead of editing by hand.
-- Pets/Zone01.luau and Eggs/Zone01.luau point their entries here. Each joint group starts with its pivot part.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB

export type Pair = { egg: Builder.Spec, pet: Builder.Spec }
local Baked: { [string]: Pair } = {}

-- 01 Sprout Pup (Common, quadruped): a chibi leaf puppy with its head cocked, one leaf ear up and one
-- flopped, a seedling on its head, a leaf tail and a glowing leaf pendant. Egg: cream under a leafy cap with
-- a pinked leaf edge, a paw print and a sprout.
do
	local MAIN = rgb(112, 204, 72) -- #70CC48
	local DARK = rgb(58, 148, 56) -- #3A9438
	local LIGHT = rgb(250, 242, 210) -- #FAF2D2
	local GLOW = rgb(150, 255, 110) -- #96FF6E
	local SPRIG = rgb(180, 238, 116) -- #B4EE74
	local BLUSH = rgb(255, 156, 176) -- #FF9CB0
	local INK = rgb(16, 41, 16) -- #102910
	local GLINT = rgb(255, 255, 255) -- #FFFFFF
	Baked.SproutPup = {
		egg = {
			parts = {
				P("Shell1", { 1.68, 0.557, 1.68 }, { 0, 0.279, 0 }, LIGHT, { joint = "Body" }),
				P("Shell2", { 2.581, 0.557, 2.581 }, { 0, 0.836, 0 }, LIGHT, { joint = "Body" }),
				P("Shell3", { 2.903, 0.557, 2.903 }, { 0, 1.393, 0 }, LIGHT, { joint = "Body" }),
				P("Shell4", { 2.913, 0.557, 2.913 }, { 0, 1.95, 0 }, MAIN, { joint = "Body" }),
				P("Shell5", { 2.68, 0.557, 2.68 }, { 0, 2.507, 0 }, MAIN, { joint = "Body" }),
				P("Shell6", { 2.199, 0.557, 2.199 }, { 0, 3.064, 0 }, MAIN, { joint = "Body" }),
				P("Shell7", { 1.32, 0.557, 1.32 }, { 0, 3.621, 0 }, SPRIG, { joint = "Body" }),
				P(
					"Leaf1",
					{ 0.5, 0.5, 0.14 },
					{ -0.82, 1.521, -1.501 },
					MAIN,
					{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
				),
				P(
					"Leaf2",
					{ 0.42, 0.42, 0.14 },
					{ 0, 1.545, -1.501 },
					MAIN,
					{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
				),
				P(
					"Leaf3",
					{ 0.5, 0.5, 0.14 },
					{ 0.82, 1.521, -1.501 },
					MAIN,
					{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
				),
				P(
					"Leaf4",
					{ 0.5, 0.5, 0.14 },
					{ 1.501, 1.521, -0.82 },
					MAIN,
					{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
				),
				P(
					"Leaf5",
					{ 0.42, 0.42, 0.14 },
					{ 1.501, 1.545, 0 },
					MAIN,
					{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
				),
				P(
					"Leaf6",
					{ 0.5, 0.5, 0.14 },
					{ 1.501, 1.521, 0.82 },
					MAIN,
					{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
				),
				P(
					"Leaf7",
					{ 0.5, 0.5, 0.14 },
					{ 0.82, 1.521, 1.501 },
					MAIN,
					{ joint = "Body", rot = { 0, -180, 45 }, studs = false }
				),
				P(
					"Leaf8",
					{ 0.42, 0.42, 0.14 },
					{ 0, 1.545, 1.501 },
					MAIN,
					{ joint = "Body", rot = { 0, -180, 45 }, studs = false }
				),
				P(
					"Leaf9",
					{ 0.5, 0.5, 0.14 },
					{ -0.82, 1.521, 1.501 },
					MAIN,
					{ joint = "Body", rot = { 0, -180, 45 }, studs = false }
				),
				P(
					"Leaf10",
					{ 0.5, 0.5, 0.14 },
					{ -1.501, 1.521, 0.82 },
					MAIN,
					{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
				),
				P(
					"Leaf11",
					{ 0.42, 0.42, 0.14 },
					{ -1.501, 1.545, 0 },
					MAIN,
					{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
				),
				P(
					"Leaf12",
					{ 0.5, 0.5, 0.14 },
					{ -1.501, 1.521, -0.82 },
					MAIN,
					{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
				),
				P("PawPad1", { 0.651, 0.525, 0.14 }, { -0.521, 0.62, -1.281 }, DARK, { joint = "Body", studs = false }),
				P("PawToe1", { 0.21, 0.231, 0.14 }, { -0.904, 1.092, -1.281 }, DARK, { joint = "Body", studs = false }),
				P("PawToe2", { 0.21, 0.231, 0.14 }, { -0.586, 1.166, -1.441 }, DARK, { joint = "Body", studs = false }),
				P("PawToe3", { 0.21, 0.231, 0.14 }, { -0.204, 1.092, -1.281 }, DARK, { joint = "Body", studs = false }),
				P("Stem", { 0.16, 0.57, 0.16 }, { 0, 4.035, 0 }, DARK, { joint = "Body", studs = false }),
				P(
					"SproutL",
					{ 0.36, 0.554, 0.12 },
					{ -0.233, 4.421, 0 },
					SPRIG,
					{ joint = "Body", rot = { 0, 180, -57.095 }, studs = false }
				),
				P(
					"SproutR",
					{ 0.36, 0.554, 0.12 },
					{ 0.233, 4.421, 0 },
					SPRIG,
					{ joint = "Body", rot = { 0, 180, 57.095 }, studs = false }
				),
			},
		},
		pet = {
			parts = {
				P(
					"Body1",
					{ 1.788, 1.23, 1.16 },
					{ 0, 1.249, 0.611 },
					MAIN,
					{ joint = "Body", rot = { 5.682, 180, 0 } }
				),
				P(
					"Body2",
					{ 1.862, 1.29, 1.16 },
					{ 0, 1.374, -0.364 },
					MAIN,
					{ joint = "Body", rot = { 8.929, 180, 0 } }
				),
				P(
					"HingeArmL",
					{ 0.2, 0.2, 0.2 },
					{ -0.6, 1, -0.62 },
					MAIN,
					{ joint = "ArmL", transparency = 1, studs = false }
				),
				P(
					"LegArmL",
					{ 0.58, 0.8, 0.58 },
					{ -0.6, 0.66, -0.62 },
					MAIN,
					{ joint = "ArmL", rot = { 0, 0, -180 } }
				),
				P(
					"FootArmL",
					{ 0.72, 0.32, 0.84 },
					{ -0.6, 0.2, -0.72 },
					LIGHT,
					{ joint = "ArmL", rot = { 0, 180, 0 } }
				),
				P(
					"HingeArmR",
					{ 0.2, 0.2, 0.2 },
					{ 0.6, 1, -0.62 },
					MAIN,
					{ joint = "ArmR", transparency = 1, studs = false }
				),
				P("LegArmR", { 0.58, 0.8, 0.58 }, { 0.6, 0.66, -0.62 }, MAIN, { joint = "ArmR", rot = { 0, 0, -180 } }),
				P(
					"FootArmR",
					{ 0.72, 0.32, 0.84 },
					{ 0.6, 0.2, -0.72 },
					LIGHT,
					{ joint = "ArmR", rot = { 0, 180, 0 } }
				),
				P(
					"HingeLegL",
					{ 0.2, 0.2, 0.2 },
					{ -0.64, 1, 0.9 },
					MAIN,
					{ joint = "LegL", transparency = 1, studs = false }
				),
				P("LegLegL", { 0.6, 0.8, 0.6 }, { -0.64, 0.66, 0.9 }, MAIN, { joint = "LegL", rot = { 0, 0, -180 } }),
				P(
					"FootLegL",
					{ 0.72, 0.32, 0.8 },
					{ -0.64, 0.2, 0.84 },
					LIGHT,
					{ joint = "LegL", rot = { 0, 180, 0 } }
				),
				P(
					"HingeLegR",
					{ 0.2, 0.2, 0.2 },
					{ 0.64, 1, 0.9 },
					MAIN,
					{ joint = "LegR", transparency = 1, studs = false }
				),
				P("LegLegR", { 0.6, 0.8, 0.6 }, { 0.64, 0.66, 0.9 }, MAIN, { joint = "LegR", rot = { 0, 0, -180 } }),
				P("FootLegR", { 0.72, 0.32, 0.8 }, { 0.64, 0.2, 0.84 }, LIGHT, { joint = "LegR", rot = { 0, 180, 0 } }),
				P("Skull", { 2.5, 2.05, 2 }, { 0, 3, -1 }, MAIN, { joint = "Head", rot = { 0, -6, 8 } }),
				P(
					"Face",
					{ 2, 1.23, 0.1 },
					{ 0.146, 2.736, -2.03 },
					LIGHT,
					{ joint = "Head", rot = { 0, -6, 8 }, studs = false }
				),
				P("Muzzle", { 1, 0.56, 0.42 }, { 0.189, 2.505, -2.136 }, LIGHT, { joint = "Head", rot = { 0, -6, 8 } }),
				P(
					"Nose",
					{ 0.38, 0.22, 0.12 },
					{ 0.187, 2.723, -2.408 },
					INK,
					{ joint = "Head", rot = { 0, -6, 8 }, studs = false }
				),
				P(
					"EyeL",
					{ 0.5, 0.62, 0.08 },
					{ -0.45, 3.041, -2.184 },
					GLOW,
					{ joint = "Head", rot = { 0, -6, 8 }, material = "Neon", studs = false }
				),
				P(
					"PupilL",
					{ 0.31, 0.459, 0.06 },
					{ -0.4, 3.01, -2.229 },
					INK,
					{ joint = "Head", rot = { 0, -6, 8 }, studs = false }
				),
				P(
					"GlintL",
					{ 0.15, 0.15, 0.04 },
					{ -0.541, 3.152, -2.284 },
					GLINT,
					{ joint = "Head", rot = { 0, -6, 8 }, material = "Neon", studs = false }
				),
				P(
					"EyeR",
					{ 0.5, 0.62, 0.08 },
					{ 0.653, 3.197, -2.068 },
					GLOW,
					{ joint = "Head", rot = { 0, -6, 8 }, material = "Neon", studs = false }
				),
				P(
					"PupilR",
					{ 0.31, 0.459, 0.06 },
					{ 0.624, 3.154, -2.121 },
					INK,
					{ joint = "Head", rot = { 0, -6, 8 }, studs = false }
				),
				P(
					"GlintR",
					{ 0.15, 0.15, 0.04 },
					{ 0.729, 3.331, -2.15 },
					GLINT,
					{ joint = "Head", rot = { 0, -6, 8 }, material = "Neon", studs = false }
				),
				P(
					"CheekL",
					{ 0.36, 0.18, 0.06 },
					{ -0.685, 2.563, -2.208 },
					BLUSH,
					{ joint = "Head", rot = { 0, -6, 8 }, studs = false }
				),
				P(
					"CheekR",
					{ 0.36, 0.18, 0.06 },
					{ 1.009, 2.803, -2.03 },
					BLUSH,
					{ joint = "Head", rot = { 0, -6, 8 }, studs = false }
				),
				P(
					"TailStem",
					{ 0.24, 0.43, 0.24 },
					{ 0, 1.725, 1.375 },
					DARK,
					{ joint = "Tail", rot = { 35.538, 0, 0 }, studs = false }
				),
				P(
					"TailLeaf",
					{ 0.52, 0.84, 0.14 },
					{ 0, 2.175, 1.748 },
					SPRIG,
					{ joint = "Tail", rot = { 0, 90, 41.348 }, studs = false }
				),
				P(
					"TailLeafTip",
					{ 0.368, 0.368, 0.134 },
					{ 0, 2.49, 2.026 },
					SPRIG,
					{ joint = "Tail", rot = { 0, 90, 86.348 }, studs = false }
				),
				P(
					"EarL",
					{ 0.86, 1.26, 0.16 },
					{ -1.73, 4.055, -0.993 },
					DARK,
					{ joint = "Head", rot = { 2.719, 176.139, -38.407 }, studs = false }
				),
				P(
					"EarLTip",
					{ 0.608, 0.608, 0.154 },
					{ -2.12, 4.549, -0.996 },
					DARK,
					{ joint = "Head", rot = { 2.719, 176.139, 6.593 }, studs = false }
				),
				P(
					"EarR",
					{ 0.86, 1.26, 0.16 },
					{ 1.317, 3.316, -0.674 },
					DARK,
					{ joint = "Head", rot = { -76.24, 69.008, -108.325 }, studs = false }
				),
				P(
					"EarRTip",
					{ 0.608, 0.608, 0.154 },
					{ 1.532, 2.726, -0.614 },
					DARK,
					{ joint = "Head", rot = { -76.24, 69.008, -63.325 }, studs = false }
				),
				P(
					"Stem",
					{ 0.16, 0.65, 0.16 },
					{ -0.144, 4.215, -0.965 },
					DARK,
					{ joint = "Head", rot = { -0.008, 0, 0.076 }, studs = false }
				),
				P(
					"SproutL",
					{ 0.5, 0.798, 0.12 },
					{ -0.497, 4.672, -1.002 },
					SPRIG,
					{ joint = "Head", rot = { -86.934, 26.971, 83.265 }, studs = false }
				),
				P(
					"SproutR",
					{ 0.5, 0.798, 0.12 },
					{ 0.166, 4.739, -0.932 },
					SPRIG,
					{ joint = "Head", rot = { 85.252, 38.224, -82.354 }, studs = false }
				),
				P(
					"Collar",
					{ 1.937, 1.342, 0.26 },
					{ 0, 1.305, 0.073 },
					DARK,
					{ joint = "Body", rot = { 8.929, 180, 0 }, studs = false }
				),
				P(
					"Pendant",
					{ 0.34, 0.34, 0.1 },
					{ 0, 1.049, 0.205 },
					GLOW,
					{ joint = "Body", rot = { 8.929, 180, 45 }, material = "Neon", studs = false }
				),
			},
		},
	}
end

-- 02 Bumble Bloc (Uncommon, insect): a chubby hovering bumblebee with a fuzzy cream collar, a striped
-- abdomen curling down to a honey-dipper stinger, glass wings and dangling legs. Egg: honey stripes, a wax
-- honeycomb band, honey dripping off the top, glass wing nubs and antennae.
do
	local MAIN = rgb(255, 205, 40) -- #FFCD28
	local DARK = rgb(42, 34, 38) -- #2A2226
	local LIGHT = rgb(255, 242, 210) -- #FFF2D2
	local GLOW = rgb(255, 165, 30) -- #FFA51E
	local GLASS = rgb(221, 242, 255) -- #DDF2FF
	local BLUSH = rgb(255, 140, 190) -- #FF8CBE
	local WAX = rgb(245, 182, 58) -- #F5B63A
	local INK = rgb(12, 10, 11) -- #0C0A0B
	local GLINT = rgb(255, 255, 255) -- #FFFFFF
	Baked.BumbleBloc = {
		egg = {
			parts = {
				P("Shell1", { 1.736, 0.586, 1.736 }, { 0, 0.293, 0 }, DARK, { joint = "Body" }),
				P("Shell2", { 2.668, 0.586, 2.668 }, { 0, 0.879, 0 }, MAIN, { joint = "Body" }),
				P("Shell3", { 3, 0.586, 3 }, { 0, 1.464, 0 }, DARK, { joint = "Body" }),
				P("Shell4", { 3.01, 0.586, 3.01 }, { 0, 2.05, 0 }, MAIN, { joint = "Body" }),
				P("Shell5", { 2.769, 0.586, 2.769 }, { 0, 2.636, 0 }, DARK, { joint = "Body" }),
				P("Shell6", { 2.272, 0.586, 2.272 }, { 0, 3.221, 0 }, WAX, { joint = "Body" }),
				P("Shell7", { 1.364, 0.586, 1.364 }, { 0, 3.807, 0 }, WAX, { joint = "Body" }),
				P("Comb1", { 0.62, 0.36, 0.14 }, { 0, 2.05, -1.515 }, WAX, { joint = "Body", studs = false }),
				P(
					"Comb2",
					{ 0.62, 0.36, 0.14 },
					{ 1.515, 2.05, 0 },
					WAX,
					{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
				),
				P(
					"Comb3",
					{ 0.62, 0.36, 0.14 },
					{ 0, 2.05, 1.515 },
					WAX,
					{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
				),
				P(
					"Comb4",
					{ 0.62, 0.36, 0.14 },
					{ -1.515, 2.05, 0 },
					WAX,
					{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
				),
				P(
					"CombX1",
					{ 0.62, 0.36, 0.13 },
					{ 0, 2.05, -1.51 },
					WAX,
					{ joint = "Body", rot = { 0, 0, 60 }, studs = false }
				),
				P(
					"CombX2",
					{ 0.62, 0.36, 0.13 },
					{ 1.51, 2.05, 0 },
					WAX,
					{ joint = "Body", rot = { 0, -90, 60 }, studs = false }
				),
				P(
					"CombX3",
					{ 0.62, 0.36, 0.13 },
					{ 0, 2.05, 1.51 },
					WAX,
					{ joint = "Body", rot = { 0, 180, 60 }, studs = false }
				),
				P(
					"CombX4",
					{ 0.62, 0.36, 0.13 },
					{ -1.51, 2.05, 0 },
					WAX,
					{ joint = "Body", rot = { 0, 90, 60 }, studs = false }
				),
				P(
					"Honey1",
					{ 0.3, 0.69, 0.14 },
					{ 0, 2.874, -1.555 },
					GLOW,
					{ joint = "Body", material = "Neon", studs = false }
				),
				P(
					"HoneyDrop1",
					{ 0.36, 0.36, 0.36 },
					{ 0, 2.529, -1.585 },
					GLOW,
					{ joint = "Body", shape = "Ball", material = "Neon", studs = false }
				),
				P(
					"Honey2",
					{ 0.3, 1.04, 0.14 },
					{ 1.555, 2.699, 0 },
					GLOW,
					{ joint = "Body", rot = { 0, -90, 0 }, material = "Neon", studs = false }
				),
				P(
					"HoneyDrop2",
					{ 0.36, 0.36, 0.36 },
					{ 1.585, 2.179, 0 },
					GLOW,
					{ joint = "Body", shape = "Ball", material = "Neon", studs = false }
				),
				P(
					"Honey3",
					{ 0.3, 0.64, 0.14 },
					{ 0, 2.899, 1.555 },
					GLOW,
					{ joint = "Body", rot = { 0, -180, 0 }, material = "Neon", studs = false }
				),
				P(
					"HoneyDrop3",
					{ 0.36, 0.36, 0.36 },
					{ 0, 2.579, 1.585 },
					GLOW,
					{ joint = "Body", shape = "Ball", material = "Neon", studs = false }
				),
				P(
					"Honey4",
					{ 0.3, 0.94, 0.14 },
					{ -1.555, 2.749, 0 },
					GLOW,
					{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
				),
				P(
					"HoneyDrop4",
					{ 0.36, 0.36, 0.36 },
					{ -1.585, 2.279, 0 },
					GLOW,
					{ joint = "Body", shape = "Ball", material = "Neon", studs = false }
				),
				P(
					"WingL",
					{ 0.1, 1.2, 1.4 },
					{ -1.704, 2.7, 0.3 },
					GLASS,
					{ joint = "Body", rot = { 0, 0, 24 }, material = "Glass", transparency = 0.35, studs = false }
				),
				P(
					"WingR",
					{ 0.1, 1.2, 1.4 },
					{ 1.704, 2.7, 0.3 },
					GLASS,
					{ joint = "Body", rot = { 0, 0, -24 }, material = "Glass", transparency = 0.35, studs = false }
				),
				P(
					"AntennaL",
					{ 0.1, 0.75, 0.1 },
					{ -0.473, 4.293, 0 },
					INK,
					{ joint = "Body", rot = { 0, 0, 24 }, studs = false }
				),
				P(
					"AntTipL",
					{ 0.3, 0.3, 0.3 },
					{ -0.625, 4.635, 0 },
					GLOW,
					{ joint = "Body", shape = "Ball", studs = false }
				),
				P(
					"AntennaR",
					{ 0.1, 0.75, 0.1 },
					{ 0.473, 4.293, 0 },
					INK,
					{ joint = "Body", rot = { 0, 0, -24 }, studs = false }
				),
				P(
					"AntTipR",
					{ 0.3, 0.3, 0.3 },
					{ 0.625, 4.635, 0 },
					GLOW,
					{ joint = "Body", shape = "Ball", studs = false }
				),
			},
		},
		pet = {
			parts = {
				P("Thorax", { 1.7, 1.6, 1.5 }, { 0, 2.45, 0.15 }, MAIN, { joint = "Body" }),
				P(
					"Abdomen1",
					{ 1.575, 1.463, 0.496 },
					{ 0, 2.102, 2.344 },
					DARK,
					{ joint = "Body", rot = { 26.386, 180, 0 } }
				),
				P(
					"Abdomen2",
					{ 2.025, 1.887, 0.495 },
					{ 0, 2.29, 1.926 },
					MAIN,
					{ joint = "Body", rot = { 22.025, 180, 0 } }
				),
				P(
					"Abdomen3",
					{ 2.15, 2.013, 0.495 },
					{ 0, 2.405, 1.486 },
					DARK,
					{ joint = "Body", rot = { 7.28, 180, 0 } }
				),
				P(
					"Abdomen4",
					{ 1.95, 1.837, 0.496 },
					{ 0, 2.442, 1.029 },
					MAIN,
					{ joint = "Body", rot = { 1.982, 180, 0 } }
				),
				P(
					"WingRootL",
					{ 0.24, 0.24, 0.24 },
					{ -0.55, 3.2, 0.45 },
					INK,
					{ joint = "WingL", shape = "Ball", studs = false }
				),
				P("ForewingL", { 2.4, 0.08, 1.2 }, { -1.466, 3.866, 0.748 }, GLASS, {
					joint = "WingL",
					rot = { 0, -162, 36.618 },
					material = "Glass",
					transparency = 0.22,
					studs = false,
				}),
				P("ForewingCapL", { 1.008, 0.07, 1.416 }, { -1.942, 4.238, 0.902 }, GLASS, {
					joint = "WingL",
					rot = { 0, -162, 36.618 },
					material = "Glass",
					transparency = 0.22,
					studs = false,
				}),
				P(
					"VeinL",
					{ 2.304, 0.1, 0.09 },
					{ -1.616, 3.874, 0.266 },
					INK,
					{ joint = "WingL", rot = { 0, -162, 36.618 }, studs = false }
				),
				P("HindwingL", { 1.488, 0.08, 0.96 }, { -1.118, 3.594, 1.295 }, GLASS, {
					joint = "WingL",
					rot = { 0, -162, 36.618 },
					material = "Glass",
					transparency = 0.22,
					studs = false,
				}),
				P(
					"WingRootR",
					{ 0.24, 0.24, 0.24 },
					{ 0.55, 3.2, 0.45 },
					INK,
					{ joint = "WingR", shape = "Ball", studs = false }
				),
				P("ForewingR", { 2.4, 0.08, 1.2 }, { 1.466, 3.866, 0.748 }, GLASS, {
					joint = "WingR",
					rot = { 0, -18, 36.618 },
					material = "Glass",
					transparency = 0.22,
					studs = false,
				}),
				P("ForewingCapR", { 1.008, 0.07, 1.416 }, { 1.942, 4.238, 0.902 }, GLASS, {
					joint = "WingR",
					rot = { 0, -18, 36.618 },
					material = "Glass",
					transparency = 0.22,
					studs = false,
				}),
				P(
					"VeinR",
					{ 2.304, 0.1, 0.09 },
					{ 1.616, 3.874, 0.266 },
					INK,
					{ joint = "WingR", rot = { 0, -18, 36.618 }, studs = false }
				),
				P("HindwingR", { 1.488, 0.08, 0.96 }, { 1.118, 3.594, 1.295 }, GLASS, {
					joint = "WingR",
					rot = { 0, -18, 36.618 },
					material = "Glass",
					transparency = 0.22,
					studs = false,
				}),
				P(
					"HingeArmL",
					{ 0.2, 0.2, 0.2 },
					{ -0.55, 1.85, -0.2 },
					MAIN,
					{ joint = "ArmL", transparency = 1, studs = false }
				),
				P(
					"ArmFemurL",
					{ 0.14, 0.497, 0.14 },
					{ -0.66, 1.64, -0.275 },
					DARK,
					{ joint = "ArmL", rot = { 15.655, -8.046, 153.462 }, studs = false }
				),
				P(
					"ArmTibiaL",
					{ 0.119, 0.363, 0.119 },
					{ -0.795, 1.25, -0.35 },
					DARK,
					{ joint = "ArmL", rot = { 0, 0, 172.093 }, studs = false }
				),
				P(
					"HingeArmR",
					{ 0.2, 0.2, 0.2 },
					{ 0.55, 1.85, -0.2 },
					MAIN,
					{ joint = "ArmR", transparency = 1, studs = false }
				),
				P(
					"ArmFemurR",
					{ 0.14, 0.497, 0.14 },
					{ 0.66, 1.64, -0.275 },
					DARK,
					{ joint = "ArmR", rot = { 15.655, 8.046, -153.462 }, studs = false }
				),
				P(
					"ArmTibiaR",
					{ 0.119, 0.363, 0.119 },
					{ 0.795, 1.25, -0.35 },
					DARK,
					{ joint = "ArmR", rot = { 0, 0, -172.093 }, studs = false }
				),
				P(
					"HingeLegL",
					{ 0.2, 0.2, 0.2 },
					{ -0.5, 1.85, 0.3 },
					MAIN,
					{ joint = "LegL", transparency = 1, studs = false }
				),
				P(
					"LegFemurL1",
					{ 0.14, 0.543, 0.14 },
					{ -0.65, 1.625, 0.325 },
					DARK,
					{ joint = "LegL", rot = { -4.399, 2.927, 146.422 }, studs = false }
				),
				P(
					"LegTibiaL1",
					{ 0.119, 0.403, 0.119 },
					{ -0.825, 1.2, 0.35 },
					DARK,
					{ joint = "LegL", rot = { 0, 0, 172.875 }, studs = false }
				),
				P(
					"LegFemurL2",
					{ 0.14, 0.623, 0.14 },
					{ -0.6, 1.7, 0.86 },
					DARK,
					{ joint = "LegL", rot = { -17.928, 10.464, 150.691 }, studs = false }
				),
				P(
					"LegTibiaL2",
					{ 0.119, 0.453, 0.119 },
					{ -0.775, 1.225, 0.97 },
					DARK,
					{ joint = "LegL", rot = { 0, 0, 173.66 }, studs = false }
				),
				P(
					"HingeLegR",
					{ 0.2, 0.2, 0.2 },
					{ 0.5, 1.85, 0.3 },
					MAIN,
					{ joint = "LegR", transparency = 1, studs = false }
				),
				P(
					"LegFemurR1",
					{ 0.14, 0.543, 0.14 },
					{ 0.65, 1.625, 0.325 },
					DARK,
					{ joint = "LegR", rot = { -4.399, -2.927, -146.422 }, studs = false }
				),
				P(
					"LegTibiaR1",
					{ 0.119, 0.403, 0.119 },
					{ 0.825, 1.2, 0.35 },
					DARK,
					{ joint = "LegR", rot = { 0, 0, -172.875 }, studs = false }
				),
				P(
					"LegFemurR2",
					{ 0.14, 0.623, 0.14 },
					{ 0.6, 1.7, 0.86 },
					DARK,
					{ joint = "LegR", rot = { -17.928, -10.464, -150.691 }, studs = false }
				),
				P(
					"LegTibiaR2",
					{ 0.119, 0.453, 0.119 },
					{ 0.775, 1.225, 0.97 },
					DARK,
					{ joint = "LegR", rot = { 0, 0, -173.66 }, studs = false }
				),
				P(
					"HingeHead",
					{ 0.2, 0.2, 0.2 },
					{ 0, 2.4, -0.7 },
					MAIN,
					{ joint = "Head", transparency = 1, studs = false }
				),
				P("Skull", { 2.1, 1.9, 1.7 }, { 0, 2.75, -1.42 }, DARK, { joint = "Head" }),
				P("SkullRound", { 2.268, 1.33, 1.428 }, { 0, 2.712, -1.42 }, DARK, { joint = "Head" }),
				P("Face", { 1.68, 1.14, 0.1 }, { 0, 2.503, -2.31 }, MAIN, { joint = "Head", studs = false }),
				P(
					"EyeL",
					{ 0.62, 0.7, 0.08 },
					{ -0.5, 2.83, -2.4 },
					GLOW,
					{ joint = "Head", material = "Neon", studs = false }
				),
				P("PupilL", { 0.384, 0.518, 0.06 }, { -0.45, 2.788, -2.45 }, INK, { joint = "Head", studs = false }),
				P(
					"GlintL",
					{ 0.186, 0.186, 0.04 },
					{ -0.605, 2.97, -2.49 },
					GLINT,
					{ joint = "Head", material = "Neon", studs = false }
				),
				P(
					"EyeR",
					{ 0.62, 0.7, 0.08 },
					{ 0.5, 2.83, -2.4 },
					GLOW,
					{ joint = "Head", material = "Neon", studs = false }
				),
				P("PupilR", { 0.384, 0.518, 0.06 }, { 0.45, 2.788, -2.45 }, INK, { joint = "Head", studs = false }),
				P(
					"GlintR",
					{ 0.186, 0.186, 0.04 },
					{ 0.605, 2.97, -2.49 },
					GLINT,
					{ joint = "Head", material = "Neon", studs = false }
				),
				P("CheekL", { 0.34, 0.2, 0.06 }, { -0.8, 2.37, -2.4 }, BLUSH, { joint = "Head", studs = false }),
				P("CheekR", { 0.34, 0.2, 0.06 }, { 0.8, 2.37, -2.4 }, BLUSH, { joint = "Head", studs = false }),
				P("Mouth", { 0.4, 0.08, 0.06 }, { 0, 2.25, -2.4 }, INK, { joint = "Head", studs = false }),
				P(
					"AntennaL",
					{ 0.1, 0.85, 0.1 },
					{ -0.572, 4.05, -1.684 },
					INK,
					{ joint = "Head", rot = { -14.5, -5.719, 21.073 }, studs = false }
				),
				P(
					"AntTipL",
					{ 0.34, 0.34, 0.34 },
					{ -0.724, 4.43, -1.798 },
					GLOW,
					{ joint = "Head", shape = "Ball", studs = false }
				),
				P(
					"AntennaR",
					{ 0.1, 0.85, 0.1 },
					{ 0.572, 4.05, -1.684 },
					INK,
					{ joint = "Head", rot = { -14.5, 5.719, -21.073 }, studs = false }
				),
				P(
					"AntTipR",
					{ 0.34, 0.34, 0.34 },
					{ 0.724, 4.43, -1.798 },
					GLOW,
					{ joint = "Head", shape = "Ball", studs = false }
				),
				P("Fuzz", { 2.22, 2.22, 0.62 }, { 0, 2.6, -0.6 }, LIGHT, { joint = "Body" }),
				P("Fuzz2", { 2.087, 2.087, 0.558 }, { 0, 2.6, -0.6 }, LIGHT, { joint = "Body", rot = { 0, 0, 45 } }),
				P(
					"Stinger",
					{ 0.16, 1, 0.16 },
					{ 0, 1.822, 2.908 },
					DARK,
					{ joint = "Body", rot = { -63.614, 0, -180 }, studs = false }
				),
				P(
					"Ridge1",
					{ 0.56, 0.12, 0.56 },
					{ 0, 1.636, 3.285 },
					WAX,
					{ joint = "Body", rot = { -63.614, 0, -180 }, studs = false }
				),
				P(
					"Ridge2",
					{ 0.459, 0.12, 0.459 },
					{ 0, 1.707, 3.141 },
					DARK,
					{ joint = "Body", rot = { 116.386, -135, 0 }, studs = false }
				),
				P(
					"Ridge3",
					{ 0.56, 0.12, 0.56 },
					{ 0, 1.778, 2.998 },
					WAX,
					{ joint = "Body", rot = { -63.614, 0, -180 }, studs = false }
				),
			},
		},
	}
end

-- 03 Meadow Stag (Rare, quadruped): a proud forest stag mid-step, foreleg raised, with wide branching bark
-- antlers in glowing blossom, a moss mantle over its shoulders, a cream chest and glowing eyes. Egg: fawn
-- with cream dapples, a moss crown band in bloom, two little branch antlers and the Rare band.
do
	local MAIN = rgb(184, 122, 70) -- #B87A46
	local DARK = rgb(90, 58, 36) -- #5A3A24
	local LIGHT = rgb(246, 226, 186) -- #F6E2BA
	local GLOW = rgb(140, 255, 106) -- #8CFF6A
	local MOSS = rgb(90, 174, 64) -- #5AAE40
	local BLOSSOM = rgb(255, 242, 210) -- #FFF2D2
	local MAIN2 = rgb(166, 110, 63) -- #A66E3F
	local INK = rgb(25, 16, 10) -- #19100A
	local GLINT = rgb(255, 255, 255) -- #FFFFFF
	Baked.MeadowStag = {
		egg = {
			parts = {
				P("Shell1", { 1.688, 0.525, 1.688 }, { 0, 0.262, 0 }, DARK, { joint = "Body" }),
				P("Shell2", { 2.637, 0.525, 2.637 }, { 0, 0.788, 0 }, MAIN, { joint = "Body" }),
				P("Shell3", { 3.031, 0.525, 3.031 }, { 0, 1.312, 0 }, MAIN, { joint = "Body" }),
				P("Shell4", { 3.136, 0.525, 3.136 }, { 0, 1.837, 0 }, MAIN, { joint = "Body" }),
				P("Shell5", { 3.028, 0.525, 3.028 }, { 0, 2.362, 0 }, MAIN, { joint = "Body" }),
				P("Shell6", { 2.729, 0.525, 2.729 }, { 0, 2.888, 0 }, MAIN, { joint = "Body" }),
				P("Shell7", { 2.213, 0.525, 2.213 }, { 0, 3.412, 0 }, MAIN, { joint = "Body" }),
				P("Shell8", { 1.32, 0.525, 1.32 }, { 0, 3.938, 0 }, MAIN, { joint = "Body" }),
				P(
					"RarityBand",
					{ 3.191, 0.2, 3.191 },
					{ 0, 1.2, 0 },
					rgb(60, 150, 255),
					{ joint = "Body", material = "Neon", studs = false }
				),
				P("CrownBand", { 2.869, 0.34, 2.869 }, { 0, 3.05, 0 }, MOSS, { joint = "Body" }),
				P(
					"Bloom1",
					{ 0.4, 0.12, 0.4 },
					{ -0.497, 3.05, -1.484 },
					BLOSSOM,
					{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
				),
				P(
					"Bloom1Core",
					{ 0.168, 0.14, 0.168 },
					{ -0.497, 3.05, -1.524 },
					GLOW,
					{ joint = "Body", rot = { -90, 0, 0 }, material = "Neon", studs = false }
				),
				P(
					"Bloom2",
					{ 0.4, 0.12, 0.4 },
					{ 1.484, 3.05, -0.497 },
					BLOSSOM,
					{ joint = "Body", rot = { -45, 0, -90 }, studs = false }
				),
				P(
					"Bloom2Core",
					{ 0.168, 0.14, 0.168 },
					{ 1.524, 3.05, -0.497 },
					GLOW,
					{ joint = "Body", rot = { -90, 0, -90 }, material = "Neon", studs = false }
				),
				P(
					"Bloom3",
					{ 0.4, 0.12, 0.4 },
					{ 0.497, 3.05, 1.484 },
					BLOSSOM,
					{ joint = "Body", rot = { 90, -135, 0 }, studs = false }
				),
				P(
					"Bloom3Core",
					{ 0.168, 0.14, 0.168 },
					{ 0.497, 3.05, 1.524 },
					GLOW,
					{ joint = "Body", rot = { -90, 0, 180 }, material = "Neon", studs = false }
				),
				P(
					"Bloom4",
					{ 0.4, 0.12, 0.4 },
					{ -1.484, 3.05, 0.497 },
					BLOSSOM,
					{ joint = "Body", rot = { -135, 0, 90 }, studs = false }
				),
				P(
					"Bloom4Core",
					{ 0.168, 0.14, 0.168 },
					{ -1.524, 3.05, 0.497 },
					GLOW,
					{ joint = "Body", rot = { -90, 0, 90 }, material = "Neon", studs = false }
				),
				P("Dapple1", { 0.4, 0.34, 0.14 }, { -0.706, 2.1, -1.504 }, LIGHT, { joint = "Body", studs = false }),
				P("Dapple2", { 0.4, 0.34, 0.14 }, { 1.271, 2.45, -1.504 }, LIGHT, { joint = "Body", studs = false }),
				P(
					"Dapple3",
					{ 0.4, 0.34, 0.14 },
					{ 1.558, 1.95, 0.571 },
					LIGHT,
					{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
				),
				P(
					"Dapple4",
					{ 0.4, 0.34, 0.14 },
					{ -0.132, 2.35, 1.504 },
					LIGHT,
					{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
				),
				P(
					"Dapple5",
					{ 0.4, 0.34, 0.14 },
					{ -1.558, 2, 0.571 },
					LIGHT,
					{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
				),
				P("Dapple6", { 0.4, 0.34, 0.14 }, { -1.314, 2.4, -1.504 }, LIGHT, { joint = "Body", studs = false }),
				P(
					"NubL1",
					{ 0.2, 0.63, 0.2 },
					{ -0.627, 4.12, 0.042 },
					DARK,
					{ joint = "Body", rot = { 7.848, 4.135, 27.614 }, studs = false }
				),
				P(
					"NubL2",
					{ 0.15, 0.48, 0.15 },
					{ -0.905, 4.49, 0.106 },
					DARK,
					{ joint = "Body", rot = { 4.038, 4.696, 49.233 }, studs = false }
				),
				P(
					"NubBloomL1",
					{ 0.34, 0.12, 0.34 },
					{ -1.086, 4.645, 0.132 },
					BLOSSOM,
					{ joint = "Body", rot = { 35.186, 159.335, -53.778 }, studs = false }
				),
				P(
					"NubBloomL1Core",
					{ 0.143, 0.14, 0.143 },
					{ -1.117, 4.671, 0.137 },
					GLOW,
					{ joint = "Body", rot = { -96.843, 39.829, 100.612 }, material = "Neon", studs = false }
				),
				P(
					"NubR1",
					{ 0.2, 0.63, 0.2 },
					{ 0.627, 4.12, 0.042 },
					DARK,
					{ joint = "Body", rot = { 7.848, -4.135, -27.614 }, studs = false }
				),
				P(
					"NubR2",
					{ 0.15, 0.48, 0.15 },
					{ 0.905, 4.49, 0.106 },
					DARK,
					{ joint = "Body", rot = { 4.038, -4.696, -49.233 }, studs = false }
				),
				P(
					"NubBloomR1",
					{ 0.34, 0.12, 0.34 },
					{ 1.086, 4.645, 0.132 },
					BLOSSOM,
					{ joint = "Body", rot = { -40.32, -33.566, -64.943 }, studs = false }
				),
				P(
					"NubBloomR1Core",
					{ 0.143, 0.14, 0.143 },
					{ 1.117, 4.671, 0.137 },
					GLOW,
					{ joint = "Body", rot = { -96.843, -39.829, -100.612 }, material = "Neon", studs = false }
				),
			},
		},
		pet = {
			parts = {
				P(
					"HingeBody",
					{ 0.224, 0.224, 0.224 },
					{ 0, 2.934, -0.672 },
					MAIN,
					{ joint = "Body", transparency = 1, studs = false }
				),
				P(
					"Body1",
					{ 1.624, 1.396, 0.872 },
					{ 0, 2.666, 1.144 },
					MAIN,
					{ joint = "Body", rot = { 5.239, 180, 0 } }
				),
				P(
					"Body2",
					{ 1.557, 1.365, 0.872 },
					{ 0, 2.749, 0.41 },
					MAIN2,
					{ joint = "Body", rot = { 7.678, 180, 0 } }
				),
				P(
					"Body3",
					{ 1.579, 1.393, 0.872 },
					{ 0, 2.867, -0.319 },
					MAIN,
					{ joint = "Body", rot = { 10.793, 180, 0 } }
				),
				P(
					"Body4",
					{ 1.691, 1.554, 0.872 },
					{ 0, 3.025, -1.041 },
					MAIN2,
					{ joint = "Body", rot = { 13.855, 180, 0 } }
				),
				P(
					"Belly3",
					{ 1.105, 0.157, 0.724 },
					{ 0, 2.128, -0.46 },
					LIGHT,
					{ joint = "Body", rot = { 10.793, 180, 0 }, studs = false }
				),
				P(
					"Belly4",
					{ 1.184, 0.157, 0.724 },
					{ 0, 2.216, -1.241 },
					LIGHT,
					{ joint = "Body", rot = { 13.855, 180, 0 }, studs = false }
				),
				P(
					"HingeArmL",
					{ 0.224, 0.224, 0.224 },
					{ -0.493, 2.408, -1.064 },
					MAIN,
					{ joint = "ArmL", transparency = 1, studs = false }
				),
				P(
					"UpperArmL",
					{ 0.426, 1.197, 0.426 },
					{ -0.493, 1.877, -1.064 },
					MAIN,
					{ joint = "ArmL", rot = { 0, 0, -180 } }
				),
				P(
					"LowerArmL",
					{ 0.291, 1.144, 0.291 },
					{ -0.493, 0.841, -1.064 },
					MAIN,
					{ joint = "ArmL", rot = { 0, 0, -180 }, studs = false }
				),
				P(
					"HoofArmL",
					{ 0.381, 0.336, 0.47 },
					{ -0.493, 0.213, -1.064 },
					DARK,
					{ joint = "ArmL", rot = { 0, 180, 0 }, studs = false }
				),
				P(
					"HingeArmR",
					{ 0.224, 0.224, 0.224 },
					{ 0.493, 2.408, -1.064 },
					MAIN,
					{ joint = "ArmR", transparency = 1, studs = false }
				),
				P(
					"UpperArmR",
					{ 0.426, 1.197, 0.426 },
					{ 0.493, 2.053, -0.669 },
					MAIN,
					{ joint = "ArmR", rot = { -48, 0, -180 } }
				),
				P(
					"LowerArmR",
					{ 0.291, 1.144, 0.291 },
					{ 0.493, 1.46, -0.72 },
					MAIN,
					{ joint = "ArmR", rot = { 62, 0, -180 }, studs = false }
				),
				P(
					"HoofArmR",
					{ 0.381, 0.336, 0.47 },
					{ 0.493, 1.165, -1.274 },
					DARK,
					{ joint = "ArmR", rot = { 62, 180, 0 }, studs = false }
				),
				P(
					"HingeLegL",
					{ 0.224, 0.224, 0.224 },
					{ -0.493, 2.408, 1.288 },
					MAIN,
					{ joint = "LegL", transparency = 1, studs = false }
				),
				P(
					"UpperLegL",
					{ 0.56, 0.961, 0.56 },
					{ -0.493, 2.009, 1.395 },
					MAIN,
					{ joint = "LegL", rot = { -15, 0, -180 } }
				),
				P(
					"MidLegL",
					{ 0.358, 0.91, 0.358 },
					{ -0.493, 1.292, 1.28 },
					MAIN,
					{ joint = "LegL", rot = { 35, 0, -180 } }
				),
				P(
					"LowerLegL",
					{ 0.28, 0.775, 0.28 },
					{ -0.493, 0.655, 1.085 },
					MAIN,
					{ joint = "LegL", rot = { -5, 0, -180 }, studs = false }
				),
				P(
					"HoofLegL",
					{ 0.381, 0.336, 0.47 },
					{ -0.493, 0.213, 1.124 },
					DARK,
					{ joint = "LegL", rot = { -5, 180, 0 }, studs = false }
				),
				P(
					"HingeLegR",
					{ 0.224, 0.224, 0.224 },
					{ 0.493, 2.408, 1.288 },
					MAIN,
					{ joint = "LegR", transparency = 1, studs = false }
				),
				P(
					"UpperLegR",
					{ 0.56, 0.961, 0.56 },
					{ 0.493, 2.009, 1.395 },
					MAIN,
					{ joint = "LegR", rot = { -15, 0, -180 } }
				),
				P(
					"MidLegR",
					{ 0.358, 0.91, 0.358 },
					{ 0.493, 1.292, 1.28 },
					MAIN,
					{ joint = "LegR", rot = { 35, 0, -180 } }
				),
				P(
					"LowerLegR",
					{ 0.28, 0.775, 0.28 },
					{ 0.493, 0.655, 1.085 },
					MAIN,
					{ joint = "LegR", rot = { -5, 0, -180 }, studs = false }
				),
				P(
					"HoofLegR",
					{ 0.381, 0.336, 0.47 },
					{ 0.493, 0.213, 1.124 },
					DARK,
					{ joint = "LegR", rot = { -5, 180, 0 }, studs = false }
				),
				P(
					"HingeHead",
					{ 0.224, 0.224, 0.224 },
					{ 0, 3.304, -1.344 },
					MAIN,
					{ joint = "Head", transparency = 1, studs = false }
				),
				P(
					"Neck1",
					{ 0.874, 0.918, 0.939 },
					{ 0, 3.647, -1.532 },
					MAIN,
					{ joint = "Head", rot = { 61.278, 180, 0 } }
				),
				P(
					"Neck2",
					{ 0.874, 0.918, 0.937 },
					{ 0, 4.375, -1.784 },
					MAIN,
					{ joint = "Head", rot = { 80.557, 180, 0 } }
				),
				P("Skull", { 1.232, 1.12, 1.344 }, { 0, 5.152, -2.262 }, MAIN, { joint = "Head", rot = { -10, 0, 0 } }),
				P("Snout", { 0.788, 0.627, 1.064 }, { 0, 4.79, -3.285 }, MAIN, { joint = "Head", rot = { -10, 0, 0 } }),
				P(
					"Chin",
					{ 0.69, 0.179, 0.915 },
					{ 0, 4.543, -3.264 },
					LIGHT,
					{ joint = "Head", rot = { -10, 0, 0 }, studs = false }
				),
				P(
					"Nose",
					{ 0.419, 0.224, 0.157 },
					{ 0, 4.837, -3.856 },
					DARK,
					{ joint = "Head", rot = { -10, 0, 0 }, studs = false }
				),
				P(
					"EyeL",
					{ 0.056, 0.314, 0.515 },
					{ -0.672, 5.301, -2.448 },
					GLOW,
					{ joint = "Head", rot = { -10, 0, 0 }, material = "Neon", studs = false }
				),
				P(
					"PupilL",
					{ 0.045, 0.289, 0.093 },
					{ -0.694, 5.291, -2.509 },
					INK,
					{ joint = "Head", rot = { -10, 0, 0 }, studs = false }
				),
				P(
					"GlintL",
					{ 0.034, 0.094, 0.094 },
					{ -0.711, 5.361, -2.615 },
					GLINT,
					{ joint = "Head", rot = { -10, 0, 0 }, material = "Neon", studs = false }
				),
				P(
					"EyeR",
					{ 0.056, 0.314, 0.515 },
					{ 0.672, 5.301, -2.448 },
					GLOW,
					{ joint = "Head", rot = { -10, 0, 0 }, material = "Neon", studs = false }
				),
				P(
					"PupilR",
					{ 0.045, 0.289, 0.093 },
					{ 0.694, 5.291, -2.509 },
					INK,
					{ joint = "Head", rot = { -10, 0, 0 }, studs = false }
				),
				P(
					"GlintR",
					{ 0.034, 0.094, 0.094 },
					{ 0.711, 5.361, -2.615 },
					GLINT,
					{ joint = "Head", rot = { -10, 0, 0 }, material = "Neon", studs = false }
				),
				P(
					"TailStem",
					{ 0.336, 0.359, 0.336 },
					{ 0, 3.052, 2.184 },
					MAIN,
					{ joint = "Tail", rot = { 38.66, 0, 0 }, studs = false }
				),
				P(
					"TailTuft",
					{ 0.56, 0.694, 0.403 },
					{ 0, 3.382, 2.448 },
					LIGHT,
					{ joint = "Tail", rot = { 38.66, 45, 0 } }
				),
				P(
					"EarL",
					{ 0.47, 0.753, 0.134 },
					{ -0.835, 5.655, -1.906 },
					MAIN,
					{ joint = "Head", rot = { -4.656, -165.099, -70.011 }, studs = false }
				),
				P(
					"EarLTip",
					{ 0.333, 0.333, 0.129 },
					{ -1.176, 5.79, -1.826 },
					MAIN,
					{ joint = "Head", rot = { -4.656, -165.099, -25.011 }, studs = false }
				),
				P(
					"EarR",
					{ 0.47, 0.753, 0.134 },
					{ 0.835, 5.655, -1.906 },
					MAIN,
					{ joint = "Head", rot = { -4.656, 165.099, 70.011 }, studs = false }
				),
				P(
					"EarRTip",
					{ 0.333, 0.333, 0.129 },
					{ 1.176, 5.79, -1.826 },
					MAIN,
					{ joint = "Head", rot = { 175.344, 14.901, -64.989 }, studs = false }
				),
				P(
					"AntlerL1",
					{ 0.302, 1.21, 0.302 },
					{ -0.669, 6.181, -2.124 },
					DARK,
					{ joint = "Head", rot = { 2.792, 1.865, 33.722 }, studs = false }
				),
				P(
					"AntlerL2",
					{ 0.242, 1.21, 0.242 },
					{ -1.487, 6.883, -2.078 },
					DARK,
					{ joint = "Head", rot = { 0.611, 1.304, 64.892 }, studs = false }
				),
				P(
					"AntlerL3",
					{ 0.194, 0.986, 0.194 },
					{ -2.265, 7.459, -2.178 },
					DARK,
					{ joint = "Head", rot = { -11.66, -9.217, 37.817 }, studs = false }
				),
				P(
					"TineL1",
					{ 0.194, 0.784, 0.194 },
					{ -1.022, 6.959, -2.324 },
					DARK,
					{ joint = "Head", rot = { -36.081, -4.5, 6.145 }, studs = false }
				),
				P(
					"TineL2",
					{ 0.155, 0.694, 0.155 },
					{ -2.093, 7.443, -1.98 },
					DARK,
					{ joint = "Head", rot = { 13.336, 4.043, 16.565 }, studs = false }
				),
				P(
					"BloomL1",
					{ 0.627, 0.134, 0.627 },
					{ -2.57, 7.839, -2.307 },
					BLOSSOM,
					{ joint = "Head", rot = { 46.315, 129.979, -70.387 }, studs = false }
				),
				P(
					"BloomL1Core",
					{ 0.263, 0.157, 0.263 },
					{ -2.597, 7.872, -2.318 },
					GLOW,
					{ joint = "Head", rot = { -65.931, 43.975, 57.246 }, material = "Neon", studs = false }
				),
				P(
					"BloomL2",
					{ 0.627, 0.134, 0.627 },
					{ -1.07, 7.317, -2.589 },
					BLOSSOM,
					{ joint = "Head", rot = { -44.68, 52.753, 10.155 }, studs = false }
				),
				P(
					"BloomL2Core",
					{ 0.263, 0.157, 0.263 },
					{ -1.074, 7.352, -2.616 },
					GLOW,
					{ joint = "Head", rot = { -37.445, 8.14, 6.189 }, material = "Neon", studs = false }
				),
				P(
					"BloomL3",
					{ 0.627, 0.134, 0.627 },
					{ -2.207, 7.817, -1.883 },
					BLOSSOM,
					{ joint = "Head", rot = { -3.708, 46.546, 24.425 }, studs = false }
				),
				P(
					"BloomL3Core",
					{ 0.263, 0.157, 0.263 },
					{ -2.22, 7.859, -1.872 },
					GLOW,
					{ joint = "Head", rot = { 13.336, 4.043, 16.565 }, material = "Neon", studs = false }
				),
				P(
					"AntlerR1",
					{ 0.302, 1.21, 0.302 },
					{ 0.669, 6.181, -2.124 },
					DARK,
					{ joint = "Head", rot = { 2.792, -1.865, -33.722 }, studs = false }
				),
				P(
					"AntlerR2",
					{ 0.242, 1.21, 0.242 },
					{ 1.487, 6.883, -2.078 },
					DARK,
					{ joint = "Head", rot = { 0.611, -1.304, -64.892 }, studs = false }
				),
				P(
					"AntlerR3",
					{ 0.194, 0.986, 0.194 },
					{ 2.265, 7.459, -2.178 },
					DARK,
					{ joint = "Head", rot = { -11.66, 9.217, -37.817 }, studs = false }
				),
				P(
					"TineR1",
					{ 0.194, 0.784, 0.194 },
					{ 1.022, 6.959, -2.324 },
					DARK,
					{ joint = "Head", rot = { -36.081, 4.5, -6.145 }, studs = false }
				),
				P(
					"TineR2",
					{ 0.155, 0.694, 0.155 },
					{ 2.093, 7.443, -1.98 },
					DARK,
					{ joint = "Head", rot = { 13.336, -4.043, -16.565 }, studs = false }
				),
				P(
					"BloomR1",
					{ 0.627, 0.134, 0.627 },
					{ 2.57, 7.839, -2.307 },
					BLOSSOM,
					{ joint = "Head", rot = { -28.413, -12.454, -38.302 }, studs = false }
				),
				P(
					"BloomR1Core",
					{ 0.263, 0.157, 0.263 },
					{ 2.597, 7.872, -2.318 },
					GLOW,
					{ joint = "Head", rot = { -65.931, -43.975, -57.246 }, material = "Neon", studs = false }
				),
				P(
					"BloomR2",
					{ 0.627, 0.134, 0.627 },
					{ 1.07, 7.317, -2.589 },
					BLOSSOM,
					{ joint = "Head", rot = { -31.998, 36.568, -7.636 }, studs = false }
				),
				P(
					"BloomR2Core",
					{ 0.263, 0.157, 0.263 },
					{ 1.074, 7.352, -2.616 },
					GLOW,
					{ joint = "Head", rot = { -37.445, -8.14, -6.189 }, material = "Neon", studs = false }
				),
				P(
					"BloomR3",
					{ 0.627, 0.134, 0.627 },
					{ 2.207, 7.817, -1.883 },
					BLOSSOM,
					{ joint = "Head", rot = { 28.322, 38.771, -21.393 }, studs = false }
				),
				P(
					"BloomR3Core",
					{ 0.263, 0.157, 0.263 },
					{ 2.22, 7.859, -1.872 },
					GLOW,
					{ joint = "Head", rot = { 13.336, -4.043, -16.565 }, material = "Neon", studs = false }
				),
				P(
					"Mantle3",
					{ 1.895, 0.381, 0.776 },
					{ 0, 3.562, -0.187 },
					MOSS,
					{ joint = "Body", rot = { 10.793, 180, 0 } }
				),
				P(
					"Mantle4",
					{ 2.029, 0.381, 0.776 },
					{ 0, 3.791, -0.852 },
					MOSS,
					{ joint = "Body", rot = { 13.855, 180, 0 } }
				),
				P(
					"MantleBloom1",
					{ 0.56, 0.134, 0.56 },
					{ 0.507, 3.997, -0.801 },
					BLOSSOM,
					{ joint = "Body", rot = { 13.855, 45, 0 }, studs = false }
				),
				P(
					"MantleBloom1Core",
					{ 0.235, 0.157, 0.235 },
					{ 0.507, 4.041, -0.791 },
					GLOW,
					{ joint = "Body", rot = { 13.855, 0, 0 }, material = "Neon", studs = false }
				),
				P(
					"MantleBloom2",
					{ 0.56, 0.134, 0.56 },
					{ -0.474, 3.771, -0.147 },
					BLOSSOM,
					{ joint = "Body", rot = { 10.793, 45, 0 }, studs = false }
				),
				P(
					"MantleBloom2Core",
					{ 0.235, 0.157, 0.235 },
					{ -0.474, 3.815, -0.139 },
					GLOW,
					{ joint = "Body", rot = { 10.793, 0, 0 }, material = "Neon", studs = false }
				),
			},
		},
	}
end

return Baked
