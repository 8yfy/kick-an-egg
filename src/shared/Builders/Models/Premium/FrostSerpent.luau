--!strict
-- 23 Frost Serpent (Snowy Peaks, Legendary). Replaces the Ice Dragon; the pet id stays `ice_dragon` (saves).
-- Hero model (docs/EggPetPlan.md): a glacier-blue serpent coiled on the ground and rising in an S to a long
-- studded head with antlers, a crystal mane, an almond-eyed "cool" face and two-tone glass wings.
-- Egg: blue shell under a white frost cap whose edge drips down the shell, a serpent coil spiralling up it with
--      crystal fins, a snow line at the base and two small antlers either side of a crown crystal.
-- BAKED FILE: modelled in Blender from Roblox primitives (assets/blender/FrostSerpent.blend) and exported by
-- tools/blender/pets (heroes/frost_serpent.py, see its README). Change the model there and re-export, not by hand.
-- Joints: Coil, Body, Head, ArmL/ArmR, WingL/WingR; each group starts with its hinge (Anim/Pet serpent poses).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local HIDE = rgb(47, 127, 224) -- #2F7FE0
local HIDE2 = rgb(42, 112, 204) -- #2A70CC
local ARMOR = rgb(22, 62, 154) -- #163E9A
local WHITE = rgb(230, 246, 255) -- #E6F6FF
local ICE = rgb(158, 235, 255) -- #9EEBFF
local TIP = rgb(214, 250, 255) -- #D6FAFF
local MEM_D = rgb(108, 194, 247) -- #6CC2F7
local MEM_L = rgb(203, 239, 255) -- #CBEFFF
local EYE = rgb(79, 232, 255) -- #4FE8FF
local SOCKET = rgb(10, 20, 48) -- #0A1430
local PUPIL = rgb(6, 16, 42) -- #06102A
local FANG = rgb(242, 250, 255) -- #F2FAFF
local SHELL = rgb(79, 176, 245) -- #4FB0F5
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.8, 0.533, 1.8 }, { 0, 0.267, 0 }, SHELL, { joint = "Body" }),
		P("Shell2", { 2.848, 0.533, 2.848 }, { 0, 0.8, 0 }, SHELL, { joint = "Body" }),
		P("Shell3", { 3.326, 0.533, 3.326 }, { 0, 1.333, 0 }, SHELL, { joint = "Body" }),
		P("Shell4", { 3.514, 0.533, 3.514 }, { 0, 1.867, 0 }, SHELL, { joint = "Body" }),
		P("Shell5", { 3.495, 0.533, 3.495 }, { 0, 2.4, 0 }, SHELL, { joint = "Body" }),
		P("Shell6", { 3.302, 0.533, 3.302 }, { 0, 2.933, 0 }, WHITE, { joint = "Body" }),
		P("Shell7", { 2.936, 0.533, 2.936 }, { 0, 3.467, 0 }, WHITE, { joint = "Body" }),
		P("Shell8", { 2.362, 0.533, 2.362 }, { 0, 4, 0 }, WHITE, { joint = "Body" }),
		P("Shell9", { 1.402, 0.533, 1.402 }, { 0, 4.533, 0 }, WHITE, { joint = "Body" }),
		P("Drip1", { 0.42, 0.79, 0.14 }, { -0.95, 2.512, -1.807 }, WHITE, { joint = "Body", studs = false }),
		P("Drip2", { 0.5, 1.19, 0.14 }, { 0, 2.312, -1.807 }, WHITE, { joint = "Body", studs = false }),
		P("Drip3", { 0.42, 0.69, 0.14 }, { 0.95, 2.562, -1.807 }, WHITE, { joint = "Body", studs = false }),
		P(
			"Drip4",
			{ 0.42, 1.04, 0.14 },
			{ 1.807, 2.387, -0.95 },
			WHITE,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"Drip5",
			{ 0.5, 0.74, 0.14 },
			{ 1.807, 2.537, 0 },
			WHITE,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"Drip6",
			{ 0.42, 1.29, 0.14 },
			{ 1.807, 2.262, 0.95 },
			WHITE,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"Drip7",
			{ 0.42, 0.84, 0.14 },
			{ 0.95, 2.487, 1.807 },
			WHITE,
			{ joint = "Body", rot = { 0, -180, 0 }, studs = false }
		),
		P(
			"Drip8",
			{ 0.5, 1.14, 0.14 },
			{ 0, 2.337, 1.807 },
			WHITE,
			{ joint = "Body", rot = { 0, -180, 0 }, studs = false }
		),
		P(
			"Drip9",
			{ 0.42, 0.64, 0.14 },
			{ -0.95, 2.587, 1.807 },
			WHITE,
			{ joint = "Body", rot = { 0, -180, 0 }, studs = false }
		),
		P(
			"Drip10",
			{ 0.42, 0.99, 0.14 },
			{ -1.807, 2.412, 0.95 },
			WHITE,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Drip11",
			{ 0.5, 0.79, 0.14 },
			{ -1.807, 2.512, 0 },
			WHITE,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Drip12",
			{ 0.42, 1.24, 0.14 },
			{ -1.807, 2.287, -0.95 },
			WHITE,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Coil1",
			{ 0.332, 0.288, 1.105 },
			{ 0.03, 0.593, 1.281 },
			HIDE,
			{ joint = "Body", rot = { -19.093, -50.008, -14.852 } }
		),
		P(
			"Coil2",
			{ 0.351, 0.305, 1.43 },
			{ -0.859, 0.792, 1.432 },
			HIDE2,
			{ joint = "Body", rot = { 42.013, -106.135, 40.871 } }
		),
		P(
			"Fin1",
			{ 0.14, 0.43, 0.14 },
			{ -0.786, 1.071, 1.56 },
			ICE,
			{ joint = "Body", rot = { 46.038, 33.641, -16.972 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Coil3",
			{ 0.371, 0.322, 1.391 },
			{ -1.608, 0.999, 0.804 },
			HIDE,
			{ joint = "Body", rot = { 11.152, -159.018, 4.038 } }
		),
		P(
			"Coil4",
			{ 0.39, 0.339, 1.47 },
			{ -1.803, 1.203, -0.285 },
			HIDE2,
			{ joint = "Body", rot = { 10.152, 179.617, -0.069 } }
		),
		P(
			"Coil5",
			{ 0.409, 0.356, 1.331 },
			{ -1.52, 1.394, -1.309 },
			HIDE,
			{ joint = "Body", rot = { 11.059, 148.448, -5.84 } }
		),
		P(
			"Fin2",
			{ 0.14, 0.51, 0.14 },
			{ -1.698, 1.723, -1.269 },
			ICE,
			{ joint = "Body", rot = { -30.738, 34.91, 52.558 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Coil6",
			{ 0.429, 0.373, 1.456 },
			{ -0.674, 1.576, -1.841 },
			HIDE2,
			{ joint = "Body", rot = { 47.455, 102.843, -46.731 } }
		),
		P(
			"Coil7",
			{ 0.448, 0.39, 1.47 },
			{ 0.474, 1.767, -1.916 },
			HIDE,
			{ joint = "Body", rot = { -82.38, 80.591, 82.278 } }
		),
		P(
			"Coil8",
			{ 0.468, 0.407, 1.326 },
			{ 1.467, 1.944, -1.581 },
			HIDE2,
			{ joint = "Body", rot = { -14.233, 51.185, 11.18 } }
		),
		P(
			"Fin3",
			{ 0.14, 0.59, 0.14 },
			{ 1.438, 2.326, -1.793 },
			ICE,
			{ joint = "Body", rot = { -43.295, 43.43, 2.393 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Coil9",
			{ 0.487, 0.423, 1.468 },
			{ 1.912, 2.117, -0.68 },
			HIDE,
			{ joint = "Body", rot = { -8.97, 3.125, 0.493 } }
		),
		P(
			"Coil10",
			{ 0.506, 0.44, 1.47 },
			{ 1.931, 2.303, 0.479 },
			HIDE2,
			{ joint = "Body", rot = { -9.28, -1.217, -0.199 } }
		),
		P(
			"Coil11",
			{ 0.526, 0.457, 1.335 },
			{ 1.596, 2.479, 1.477 },
			HIDE,
			{ joint = "Body", rot = { -11.017, -37.223, -6.717 } }
		),
		P(
			"Fin4",
			{ 0.14, 0.67, 0.14 },
			{ 1.836, 2.916, 1.444 },
			ICE,
			{ joint = "Body", rot = { 32.636, 32.935, -52.154 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Coil12",
			{ 0.545, 0.474, 1.453 },
			{ 0.699, 2.65, 1.882 },
			HIDE2,
			{ joint = "Body", rot = { 82.513, -98.918, 82.423 } }
		),
		P(
			"Coil13",
			{ 0.565, 0.491, 1.47 },
			{ -0.455, 2.838, 1.855 },
			HIDE,
			{ joint = "Body", rot = { 81.084, -99.745, 80.955 } }
		),
		P(
			"Coil14",
			{ 0.584, 0.508, 1.328 },
			{ -1.433, 3.021, 1.5 },
			HIDE2,
			{ joint = "Body", rot = { 14.005, -131.262, 10.619 } }
		),
		P(
			"Fin5",
			{ 0.14, 0.75, 0.14 },
			{ -1.402, 3.509, 1.775 },
			ICE,
			{ joint = "Body", rot = { 43.157, 44.21, -1.2 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Coil15",
			{ 0.603, 0.525, 1.431 },
			{ -1.773, 3.198, 0.599 },
			HIDE,
			{ joint = "Body", rot = { 9.346, 174.015, -0.983 } }
		),
		P(
			"Coil16",
			{ 0.623, 0.542, 1.469 },
			{ -1.685, 3.395, -0.541 },
			HIDE2,
			{ joint = "Body", rot = { 10.29, 177.291, -0.492 } }
		),
		P("CoilTipA", { 0.22, 0.341, 0.22 }, { 0.5, 0.532, 0.909 }, ICE, {
			joint = "Body",
			rot = { 46.116, 36.056, -107.904 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"CoilTipB",
			{ 0.121, 0.231, 0.121 },
			{ 0.703, 0.583, 0.748 },
			TIP,
			{ joint = "Body", rot = { 46.116, 36.056, -107.904 }, material = "Neon", studs = false }
		),
		P("SnowBand", { 2.988, 0.34, 2.988 }, { 0, 0.533, 0 }, WHITE, { joint = "Body" }),
		P(
			"EggAntlerL",
			{ 0.16, 0.7, 0.16 },
			{ -0.638, 4.979, 0.208 },
			WHITE,
			{ joint = "Body", rot = { 12.938, 6.76, 27.13 }, studs = false }
		),
		P(
			"EggTineL",
			{ 0.12, 0.38, 0.12 },
			{ -0.69, 5.175, 0.14 },
			ICE,
			{ joint = "Body", rot = { -33.425, 38.992, 14.836 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"EggAntlerTipLA",
			{ 0.16, 0.248, 0.16 },
			{ -0.835, 5.351, 0.317 },
			ICE,
			{ joint = "Body", rot = { -14.236, 45.086, 39.894 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"EggAntlerTipLB",
			{ 0.088, 0.168, 0.088 },
			{ -0.922, 5.515, 0.366 },
			TIP,
			{ joint = "Body", rot = { -14.236, 45.086, 39.894 }, material = "Neon", studs = false }
		),
		P(
			"EggAntlerR",
			{ 0.16, 0.7, 0.16 },
			{ 0.638, 4.979, 0.208 },
			WHITE,
			{ joint = "Body", rot = { 12.938, -6.76, -27.13 }, studs = false }
		),
		P("EggTineR", { 0.12, 0.38, 0.12 }, { 0.69, 5.175, 0.14 }, ICE, {
			joint = "Body",
			rot = { -10.595, 48.705, -17.551 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"EggAntlerTipRA",
			{ 0.16, 0.248, 0.16 },
			{ 0.835, 5.351, 0.317 },
			ICE,
			{ joint = "Body", rot = { 35.495, 32.799, -32.597 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"EggAntlerTipRB",
			{ 0.088, 0.168, 0.088 },
			{ 0.922, 5.515, 0.366 },
			TIP,
			{ joint = "Body", rot = { 35.495, 32.799, -32.597 }, material = "Neon", studs = false }
		),
		P(
			"CrownA",
			{ 0.3, 0.62, 0.3 },
			{ 0, 4.938, -0.087 },
			ICE,
			{ joint = "Body", rot = { -6.843, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownB",
			{ 0.198, 0.3, 0.198 },
			{ 0, 5.365, -0.138 },
			ICE,
			{ joint = "Body", rot = { -6.843, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrownC",
			{ 0.102, 0.2, 0.102 },
			{ 0, 5.563, -0.162 },
			TIP,
			{ joint = "Body", rot = { -6.843, 45, 0 }, material = "Neon", studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P(
			"HingeCoil",
			{ 0.23, 0.23, 0.23 },
			{ 0, 0.345, 0.632 },
			WHITE,
			{ joint = "Coil", transparency = 1, studs = false }
		),
		P(
			"HingeBody",
			{ 0.23, 0.23, 0.23 },
			{ -0.919, 0.546, -1.461 },
			WHITE,
			{ joint = "Body", transparency = 1, studs = false }
		),
		P(
			"HingeHead",
			{ 0.23, 0.23, 0.23 },
			{ 0, 4.349, -0.647 },
			WHITE,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P(
			"Seg0",
			{ 0.485, 0.437, 1.003 },
			{ -0.965, 0.233, -0.06 },
			HIDE,
			{ joint = "Coil", rot = { 2.403, 151.568, -1.145 } }
		),
		P(
			"Dorsal0",
			{ 0.146, 0.327, 0.658 },
			{ -0.971, 0.58, -0.049 },
			ARMOR,
			{ joint = "Coil", rot = { 2.403, -28.432, 1.145 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg1",
			{ 0.535, 0.482, 1.005 },
			{ -0.396, 0.262, -0.594 },
			HIDE2,
			{ joint = "Coil", rot = { 4.688, 114.763, -4.259 } }
		),
		P(
			"Dorsal1",
			{ 0.161, 0.337, 0.659 },
			{ -0.407, 0.636, -0.588 },
			ARMOR,
			{ joint = "Coil", rot = { 4.688, -65.237, 4.259 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg2",
			{ 0.585, 0.527, 1.007 },
			{ 0.385, 0.289, -0.695 },
			HIDE,
			{ joint = "Coil", rot = { -10.639, 79.999, 10.481 } }
		),
		P(
			"Dorsal2",
			{ 0.176, 0.347, 0.66 },
			{ 0.372, 0.691, -0.697 },
			ARMOR,
			{ joint = "Coil", rot = { -10.639, -100.001, -10.481 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg3",
			{ 0.635, 0.572, 1.009 },
			{ 1.097, 0.315, -0.347 },
			HIDE2,
			{ joint = "Coil", rot = { -2.58, 47.803, 1.912 } }
		),
		P(
			"Dorsal3",
			{ 0.191, 0.357, 0.662 },
			{ 1.088, 0.744, -0.356 },
			ARMOR,
			{ joint = "Coil", rot = { -2.58, -132.197, -1.912 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg4",
			{ 0.685, 0.617, 1.01 },
			{ 1.524, 0.339, 0.327 },
			HIDE,
			{ joint = "Coil", rot = { -1.718, 16.873, 0.499 } }
		),
		P(
			"Dorsal4",
			{ 0.206, 0.367, 0.663 },
			{ 1.52, 0.796, 0.314 },
			ARMOR,
			{ joint = "Coil", rot = { -1.718, -163.127, -0.499 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg5",
			{ 0.735, 0.662, 1.011 },
			{ 1.556, 0.362, 1.127 },
			HIDE2,
			{ joint = "Coil", rot = { -1.607, -12.338, -0.343 } }
		),
		P(
			"Dorsal5",
			{ 0.221, 0.377, 0.663 },
			{ 1.558, 0.847, 1.114 },
			ARMOR,
			{ joint = "Coil", rot = { -1.607, 167.662, 0.343 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg6",
			{ 0.785, 0.707, 1.012 },
			{ 1.199, 0.385, 1.848 },
			HIDE,
			{ joint = "Coil", rot = { -1.97, -40.251, -1.273 } }
		),
		P(
			"Dorsal6",
			{ 0.236, 0.387, 0.663 },
			{ 1.208, 0.897, 1.838 },
			ARMOR,
			{ joint = "Coil", rot = { -1.97, 139.749, 1.273 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg7",
			{ 0.835, 0.752, 1.013 },
			{ 0.549, 0.406, 2.326 },
			HIDE2,
			{ joint = "Coil", rot = { -3.695, -66.976, -3.402 } }
		),
		P(
			"Dorsal7",
			{ 0.251, 0.397, 0.664 },
			{ 0.562, 0.946, 2.321 },
			ARMOR,
			{ joint = "Coil", rot = { -3.695, 113.024, 3.402 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg8",
			{ 0.885, 0.797, 1.014 },
			{ -0.248, 0.427, 2.466 },
			HIDE,
			{ joint = "Coil", rot = { 24.084, -93.412, 24.046 } }
		),
		P(
			"Dorsal8",
			{ 0.266, 0.407, 0.665 },
			{ -0.234, 0.994, 2.467 },
			ARMOR,
			{ joint = "Coil", rot = { 24.084, 86.588, -24.046 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg9",
			{ 0.935, 0.842, 1.014 },
			{ -1.029, 0.446, 2.249 },
			HIDE2,
			{ joint = "Coil", rot = { 2.869, -117.983, 2.534 } }
		),
		P(
			"Dorsal9",
			{ 0.281, 0.417, 0.665 },
			{ -1.017, 1.041, 2.255 },
			ARMOR,
			{ joint = "Coil", rot = { 2.869, 62.017, -2.534 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg10",
			{ 0.985, 0.887, 1.014 },
			{ -1.651, 0.466, 1.726 },
			HIDE,
			{ joint = "Coil", rot = { 1.651, -142.131, 1.014 } }
		),
		P(
			"Dorsal10",
			{ 0.296, 0.427, 0.665 },
			{ -1.643, 1.088, 1.737 },
			ARMOR,
			{ joint = "Coil", rot = { 1.651, 37.869, -1.014 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg11",
			{ 1.035, 0.932, 1.015 },
			{ -2.012, 0.484, 0.996 },
			HIDE2,
			{ joint = "Coil", rot = { 1.307, -165.311, 0.331 } }
		),
		P(
			"Dorsal11",
			{ 0.311, 0.437, 0.666 },
			{ -2.008, 1.134, 1.009 },
			ARMOR,
			{ joint = "Coil", rot = { 1.307, 14.689, -0.331 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg12",
			{ 1.085, 0.977, 1.016 },
			{ -2.057, 0.502, 0.181 },
			HIDE,
			{ joint = "Coil", rot = { 1.242, 171.575, -0.182 } }
		),
		P(
			"Dorsal12",
			{ 0.326, 0.447, 0.666 },
			{ -2.059, 1.18, 0.196 },
			ARMOR,
			{ joint = "Coil", rot = { 1.242, -8.425, 0.182 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg13",
			{ 1.135, 1.022, 1.015 },
			{ -1.785, 0.52, -0.589 },
			HIDE2,
			{ joint = "Coil", rot = { 1.388, 149.582, -0.703 } }
		),
		P(
			"Dorsal13",
			{ 0.341, 0.457, 0.666 },
			{ -1.792, 1.225, -0.576 },
			ARMOR,
			{ joint = "Coil", rot = { 1.388, -30.418, 0.703 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg14",
			{ 1.185, 1.067, 1.015 },
			{ -1.247, 0.537, -1.204 },
			HIDE,
			{ joint = "Coil", rot = { 1.892, 128.086, -1.462 } }
		),
		P(
			"Dorsal14",
			{ 0.356, 0.467, 0.666 },
			{ -1.258, 1.269, -1.195 },
			ARMOR,
			{ joint = "Coil", rot = { 1.892, -51.914, 1.462 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg15",
			{ 1.233, 1.11, 0.998 },
			{ -0.598, 0.719, -1.644 },
			HIDE2,
			{ joint = "Body", rot = { 43.389, 128.152, -19.222 } }
		),
		P(
			"Belly15",
			{ 0.814, 0.184, 0.801 },
			{ -0.473, 0.19, -1.926 },
			WHITE,
			{ joint = "Body", rot = { 43.389, 128.152, -19.222 }, studs = false }
		),
		P(
			"Dorsal15",
			{ 0.37, 0.477, 0.654 },
			{ -0.752, 1.375, -1.295 },
			ARMOR,
			{ joint = "Body", rot = { 43.389, -51.848, 19.222 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg16",
			{ 1.275, 1.148, 1.007 },
			{ -0.053, 1.22, -1.946 },
			HIDE,
			{ joint = "Body", rot = { 70.215, 147.341, -0.506 } }
		),
		P(
			"Belly16",
			{ 0.842, 0.184, 0.809 },
			{ -0.049, 1.003, -2.539 },
			WHITE,
			{ joint = "Body", rot = { 70.215, 147.341, -0.506 }, studs = false }
		),
		P(
			"Dorsal16",
			{ 0.383, 0.485, 0.661 },
			{ -0.059, 1.488, -1.211 },
			ARMOR,
			{ joint = "Body", rot = { 70.215, -32.659, 0.506 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg17",
			{ 1.318, 1.186, 1.008 },
			{ 0.144, 1.958, -2.1 },
			HIDE2,
			{ joint = "Body", rot = { 84.85, -176.487, -0.31 } }
		),
		P(
			"Belly17",
			{ 0.87, 0.184, 0.81 },
			{ 0.148, 1.899, -2.748 },
			WHITE,
			{ joint = "Body", rot = { 84.85, -176.487, -0.31 }, studs = false }
		),
		P(
			"Dorsal17",
			{ 0.395, 0.494, 0.661 },
			{ 0.14, 2.03, -1.298 },
			ARMOR,
			{ joint = "Body", rot = { 84.85, 3.513, 0.31 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg18",
			{ 1.361, 1.225, 1.013 },
			{ 0.076, 2.729, -1.937 },
			HIDE,
			{ joint = "Body", rot = { -60.932, -5.976, -176.688 } }
		),
		P(
			"Belly18",
			{ 0.898, 0.184, 0.814 },
			{ 0.037, 3.051, -2.523 },
			WHITE,
			{ joint = "Body", rot = { -60.932, -5.976, -176.688 }, studs = false }
		),
		P(
			"Dorsal18",
			{ 0.408, 0.502, 0.664 },
			{ 0.123, 2.332, -1.211 },
			ARMOR,
			{ joint = "Body", rot = { 119.068, 5.976, -3.312 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg19",
			{ 1.403, 1.263, 1.02 },
			{ 0.012, 3.403, -1.459 },
			HIDE2,
			{ joint = "Body", rot = { -48.465, -2.791, -177.531 } }
		),
		P(
			"Belly19",
			{ 0.926, 0.184, 0.819 },
			{ -0.018, 3.858, -1.975 },
			WHITE,
			{ joint = "Body", rot = { -48.465, -2.791, -177.531 }, studs = false }
		),
		P(
			"Dorsal19",
			{ 0.421, 0.511, 0.669 },
			{ 0.049, 2.84, -0.82 },
			ARMOR,
			{ joint = "Body", rot = { 131.535, 2.791, -2.469 }, shape = "Wedge", studs = false }
		),
		P(
			"Seg20",
			{ 1.388, 1.249, 1.013 },
			{ -0.004, 4.032, -0.914 },
			HIDE,
			{ joint = "Body", rot = { -49.804, 0.578, 179.512 } }
		),
		P(
			"Belly20",
			{ 0.916, 0.184, 0.814 },
			{ 0.002, 4.473, -1.435 },
			WHITE,
			{ joint = "Body", rot = { -49.804, 0.578, 179.512 }, studs = false }
		),
		P(
			"Dorsal20",
			{ 0.416, 0.508, 0.664 },
			{ -0.011, 3.488, -0.27 },
			ARMOR,
			{ joint = "Body", rot = { 130.196, -0.578, 0.488 }, shape = "Wedge", studs = false }
		),
		P("Seg21", { 1.307, 1.176, 1.006 }, { 0, 4.76, -0.61 }, HIDE2, { joint = "Head", rot = { -84.965, 0, -180 } }),
		P(
			"Belly21",
			{ 0.862, 0.184, 0.808 },
			{ 0, 4.817, -1.253 },
			WHITE,
			{ joint = "Head", rot = { -84.965, 0, -180 }, studs = false }
		),
		P(
			"Mane1A",
			{ 0.253, 0.478, 0.253 },
			{ 0, 4.542, 0.047 },
			ICE,
			{ joint = "Head", rot = { 137.035, -45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Mane1B",
			{ 0.139, 0.324, 0.139 },
			{ 0, 4.271, 0.299 },
			TIP,
			{ joint = "Head", rot = { 137.035, -45, 0 }, material = "Neon", studs = false }
		),
		P("Seg22", { 1.226, 1.103, 1.011 }, { 0, 5.516, -0.803 }, HIDE, { joint = "Head", rot = { 56.43, 180, 0 } }),
		P(
			"Belly22",
			{ 0.809, 0.184, 0.812 },
			{ 0, 5.179, -1.311 },
			WHITE,
			{ joint = "Head", rot = { 56.43, 180, 0 }, studs = false }
		),
		P(
			"Mane2A",
			{ 0.253, 0.392, 0.253 },
			{ 0, 5.742, -0.226 },
			ICE,
			{ joint = "Head", rot = { 98.43, -45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Mane2B",
			{ 0.139, 0.266, 0.139 },
			{ 0, 5.697, 0.074 },
			TIP,
			{ joint = "Head", rot = { 98.43, -45, 0 }, material = "Neon", studs = false }
		),
		P("Seg23", { 1.145, 1.03, 1.017 }, { 0, 6.093, -1.379 }, HIDE2, { joint = "Head", rot = { 33.792, 180, 0 } }),
		P(
			"Belly23",
			{ 0.755, 0.184, 0.817 },
			{ 0, 5.617, -1.697 },
			WHITE,
			{ joint = "Head", rot = { 33.792, 180, 0 }, studs = false }
		),
		P(
			"Mane3A",
			{ 0.253, 0.478, 0.253 },
			{ 0, 6.503, -0.912 },
			ICE,
			{ joint = "Head", rot = { 75.792, -45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"Mane3B",
			{ 0.139, 0.324, 0.139 },
			{ 0, 6.594, -0.553 },
			TIP,
			{ joint = "Head", rot = { 75.792, -45, 0 }, material = "Neon", studs = false }
		),
		P(
			"TailTipA",
			{ 0.345, 0.606, 0.345 },
			{ -1.227, 0.389, 0.422 },
			ICE,
			{ joint = "Coil", rot = { 89.334, -53.898, 42.357 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"TailTipB",
			{ 0.19, 0.411, 0.19 },
			{ -1.413, 0.649, 0.765 },
			TIP,
			{ joint = "Coil", rot = { 89.334, -53.898, 42.357 }, material = "Neon", studs = false }
		),
		P(
			"CoreFrame",
			{ 0.713, 0.115, 0.713 },
			{ 0.003, 4.547, -1.523 },
			WHITE,
			{ joint = "Body", rot = { 129.712, -135.58, -0.683 }, studs = false }
		),
		P(
			"Core",
			{ 0.483, 0.138, 0.483 },
			{ 0.003, 4.576, -1.558 },
			EYE,
			{ joint = "Body", rot = { 129.712, -135.58, -0.683 }, material = "Neon" }
		),
		P(
			"HingeArmL",
			{ 0.23, 0.23, 0.23 },
			{ -0.64, 3.528, -1.601 },
			WHITE,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P(
			"UpperArmL",
			{ 0.345, 0.713, 0.345 },
			{ -0.851, 3.433, -1.873 },
			HIDE,
			{ joint = "ArmL", rot = { 25.771, -43.958, 124.82 } }
		),
		P(
			"ForearmL",
			{ 0.299, 0.644, 0.299 },
			{ -1.112, 3.517, -2.407 },
			HIDE,
			{ joint = "ArmL", rot = { -53.672, -12.711, 9.19 } }
		),
		P(
			"HandL",
			{ 0.391, 0.276, 0.414 },
			{ -1.176, 3.748, -2.745 },
			ARMOR,
			{ joint = "ArmL", rot = { 0, 10.808, 0 }, studs = false }
		),
		P(
			"ClawsL",
			{ 0.368, 0.161, 0.253 },
			{ -1.216, 3.842, -2.951 },
			FANG,
			{ joint = "ArmL", rot = { 0, -169.192, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"HingeArmR",
			{ 0.23, 0.23, 0.23 },
			{ 0.648, 3.528, -1.601 },
			WHITE,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P(
			"UpperArmR",
			{ 0.345, 0.713, 0.345 },
			{ 0.837, 3.428, -1.887 },
			HIDE,
			{ joint = "ArmR", rot = { 32.015, 45.05, -131.459 } }
		),
		P(
			"ForearmR",
			{ 0.299, 0.644, 0.299 },
			{ 1.046, 3.509, -2.438 },
			HIDE,
			{ joint = "ArmR", rot = { -55.381, 5.243, -3.609 } }
		),
		P(
			"HandR",
			{ 0.391, 0.276, 0.414 },
			{ 1.072, 3.742, -2.779 },
			ARMOR,
			{ joint = "ArmR", rot = { 0, -4.348, 0 }, studs = false }
		),
		P(
			"ClawsR",
			{ 0.368, 0.161, 0.253 },
			{ 1.088, 3.838, -2.988 },
			FANG,
			{ joint = "ArmR", rot = { 0, 175.652, 0 }, shape = "Wedge", studs = false }
		),
		P("Skull", { 1.719, 1.389, 1.852 }, { 0, 6.712, -2.594 }, HIDE, { joint = "Head", rot = { -8, 0, 0 } }),
		P("Snout", { 1.349, 0.82, 1.587 }, { 0, 6.246, -4.198 }, HIDE, { joint = "Head", rot = { -8, 0, 0 } }),
		P(
			"SnoutRidge",
			{ 0.608, 0.37, 1.521 },
			{ 0, 6.845, -4.215 },
			ARMOR,
			{ joint = "Head", rot = { -8, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"Nose",
			{ 1.137, 0.45, 0.291 },
			{ 0, 6.244, -5.065 },
			ARMOR,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"Jaw",
			{ 1.19, 0.37, 1.785 },
			{ 0, 5.772, -3.864 },
			WHITE,
			{ joint = "Head", rot = { -17, 0, 0 }, studs = false }
		),
		P(
			"Mouth",
			{ 1.111, 0.212, 1.389 },
			{ 0, 5.903, -3.976 },
			SOCKET,
			{ joint = "Head", rot = { -12, 0, 0 }, studs = false }
		),
		P(
			"NostrilL",
			{ 0.212, 0.132, 0.079 },
			{ -0.291, 6.366, -5.243 },
			SOCKET,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"BrowL",
			{ 0.555, 0.397, 1.256 },
			{ -0.555, 7.49, -3.237 },
			ARMOR,
			{ joint = "Head", rot = { -8, 0, 14 }, shape = "Wedge", studs = false }
		),
		P(
			"SocketL",
			{ 0.079, 0.45, 0.873 },
			{ -0.879, 6.861, -3.149 },
			SOCKET,
			{ joint = "Head", rot = { -24, 0, 0 }, studs = false }
		),
		P(
			"EyeL",
			{ 0.066, 0.344, 0.741 },
			{ -0.913, 6.831, -3.171 },
			EYE,
			{ joint = "Head", rot = { -24, 0, 0 }, material = "Neon" }
		),
		P(
			"PupilL",
			{ 0.053, 0.317, 0.119 },
			{ -0.946, 6.82, -3.25 },
			PUPIL,
			{ joint = "Head", rot = { -24, 0, 0 }, studs = false }
		),
		P(
			"GlintL",
			{ 0.04, 0.106, 0.106 },
			{ -0.959, 6.916, -3.424 },
			GLINT,
			{ joint = "Head", rot = { -8, 0, 0 }, material = "Neon" }
		),
		P(
			"FangL",
			{ 0.198, 0.45, 0.198 },
			{ -0.436, 5.783, -4.733 },
			FANG,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"ToothL",
			{ 0.159, 0.264, 0.159 },
			{ -0.503, 5.932, -4.153 },
			FANG,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"LowToothL",
			{ 0.159, 0.238, 0.159 },
			{ -0.344, 5.916, -4.458 },
			FANG,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"AntlerL",
			{ 0.253, 1.242, 0.253 },
			{ -0.768, 7.98, -2.029 },
			WHITE,
			{ joint = "Head", rot = { 17.474, 6.628, 20.137 }, studs = false }
		),
		P(
			"AntlerTopL",
			{ 0.207, 0.977, 0.207 },
			{ -1.063, 8.773, -1.513 },
			WHITE,
			{ joint = "Head", rot = { 43.458, 13.569, 13.907 }, studs = false }
		),
		P(
			"TineL",
			{ 0.184, 0.69, 0.184 },
			{ -0.842, 8.285, -2.19 },
			ICE,
			{ joint = "Head", rot = { -38.421, 37.578, 14.827 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"AntlerTipLA",
			{ 0.23, 0.392, 0.23 },
			{ -1.209, 9.19, -1.069 },
			ICE,
			{ joint = "Head", rot = { 25.563, 56.421, 24.987 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"AntlerTipLB",
			{ 0.126, 0.266, 0.126 },
			{ -1.28, 9.393, -0.854 },
			TIP,
			{ joint = "Head", rot = { 25.563, 56.421, 24.987 }, material = "Neon", studs = false }
		),
		P(
			"Tine2L",
			{ 0.161, 0.517, 0.161 },
			{ -1.14, 8.982, -1.622 },
			ICE,
			{ joint = "Head", rot = { -35.387, 35.428, 23.5 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P("FrillL1", { 0.161, 0.92, 0.161 }, { -1.095, 6.583, -1.939 }, ICE, {
			joint = "Head",
			rot = { -47.377, 48.653, 115.347 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"FrillL2",
			{ 0.161, 0.782, 0.161 },
			{ -1.041, 7.136, -1.928 },
			ICE,
			{ joint = "Head", rot = { -27.393, 55.433, 86.509 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"WhiskerL",
			{ 0.115, 1.092, 0.115 },
			{ -1.007, 6.071, -4.535 },
			WHITE,
			{ joint = "Head", rot = { -14.153, 34.18, 114.174 }, studs = false }
		),
		P(
			"BeadL",
			{ 0.276, 0.276, 0.276 },
			{ -1.42, 5.923, -4.209 },
			ICE,
			{ joint = "Head", shape = "Ball", material = "Neon" }
		),
		P(
			"NostrilR",
			{ 0.212, 0.132, 0.079 },
			{ 0.291, 6.366, -5.243 },
			SOCKET,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"BrowR",
			{ 0.555, 0.397, 1.256 },
			{ 0.555, 7.49, -3.237 },
			ARMOR,
			{ joint = "Head", rot = { -8, 0, -14 }, shape = "Wedge", studs = false }
		),
		P(
			"SocketR",
			{ 0.079, 0.45, 0.873 },
			{ 0.879, 6.861, -3.149 },
			SOCKET,
			{ joint = "Head", rot = { -24, 0, 0 }, studs = false }
		),
		P(
			"EyeR",
			{ 0.066, 0.344, 0.741 },
			{ 0.913, 6.831, -3.171 },
			EYE,
			{ joint = "Head", rot = { -24, 0, 0 }, material = "Neon" }
		),
		P(
			"PupilR",
			{ 0.053, 0.317, 0.119 },
			{ 0.946, 6.82, -3.25 },
			PUPIL,
			{ joint = "Head", rot = { -24, 0, 0 }, studs = false }
		),
		P(
			"GlintR",
			{ 0.04, 0.106, 0.106 },
			{ 0.959, 6.916, -3.424 },
			GLINT,
			{ joint = "Head", rot = { -8, 0, 0 }, material = "Neon" }
		),
		P(
			"FangR",
			{ 0.198, 0.45, 0.198 },
			{ 0.436, 5.783, -4.733 },
			FANG,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"ToothR",
			{ 0.159, 0.264, 0.159 },
			{ 0.503, 5.932, -4.153 },
			FANG,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"LowToothR",
			{ 0.159, 0.238, 0.159 },
			{ 0.344, 5.916, -4.458 },
			FANG,
			{ joint = "Head", rot = { -8, 0, 0 }, studs = false }
		),
		P(
			"AntlerR",
			{ 0.253, 1.242, 0.253 },
			{ 0.768, 7.98, -2.029 },
			WHITE,
			{ joint = "Head", rot = { 17.474, -6.628, -20.137 }, studs = false }
		),
		P(
			"AntlerTopR",
			{ 0.207, 0.977, 0.207 },
			{ 1.063, 8.773, -1.513 },
			WHITE,
			{ joint = "Head", rot = { 43.458, -13.569, -13.907 }, studs = false }
		),
		P("TineR", { 0.184, 0.69, 0.184 }, { 0.842, 8.285, -2.19 }, ICE, {
			joint = "Head",
			rot = { -14.957, 50.008, -18.395 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"AntlerTipRA",
			{ 0.23, 0.392, 0.23 },
			{ 1.209, 9.19, -1.069 },
			ICE,
			{ joint = "Head", rot = { 54.785, 30.087, -15.665 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"AntlerTipRB",
			{ 0.126, 0.266, 0.126 },
			{ 1.28, 9.393, -0.854 },
			TIP,
			{ joint = "Head", rot = { 54.785, 30.087, -15.665 }, material = "Neon", studs = false }
		),
		P(
			"Tine2R",
			{ 0.161, 0.517, 0.161 },
			{ 1.14, 8.982, -1.622 },
			ICE,
			{ joint = "Head", rot = { 1.486, 48.354, -29.271 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"FrillR1",
			{ 0.161, 0.92, 0.161 },
			{ 1.095, 6.583, -1.939 },
			ICE,
			{ joint = "Head", rot = { 62.2, -16.428, -38.494 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"FrillR2",
			{ 0.161, 0.782, 0.161 },
			{ 1.041, 7.136, -1.928 },
			ICE,
			{ joint = "Head", rot = { 59.732, 1.98, -34.517 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"WhiskerR",
			{ 0.115, 1.092, 0.115 },
			{ 1.007, 6.071, -4.535 },
			WHITE,
			{ joint = "Head", rot = { -14.153, -34.18, -114.174 }, studs = false }
		),
		P(
			"BeadR",
			{ 0.276, 0.276, 0.276 },
			{ 1.42, 5.923, -4.209 },
			ICE,
			{ joint = "Head", shape = "Ball", material = "Neon" }
		),
		P(
			"CrestA",
			{ 0.276, 0.428, 0.276 },
			{ 0, 7.567, -2.871 },
			ICE,
			{ joint = "Head", rot = { 22.466, 45, 0 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"CrestB",
			{ 0.152, 0.29, 0.152 },
			{ 0, 7.873, -2.745 },
			TIP,
			{ joint = "Head", rot = { 22.466, 45, 0 }, material = "Neon", studs = false }
		),
		P("ShoulderL", { 0.46, 0.46, 0.46 }, { -0.596, 4.729, -0.259 }, WHITE, { joint = "WingL", shape = "Ball" }),
		P(
			"UpperWingL",
			{ 0.299, 1.322, 0.299 },
			{ -0.924, 5.237, 0.01 },
			ARMOR,
			{ joint = "WingL", rot = { 20.464, 12.747, 30.595 }, studs = false }
		),
		P(
			"ForewingL",
			{ 0.253, 1.552, 0.253 },
			{ -1.921, 5.91, 0.123 },
			ARMOR,
			{ joint = "WingL", rot = { -2.678, -7.603, 70.532 }, studs = false }
		),
		P("WristL", { 0.368, 0.368, 0.368 }, { -2.646, 6.163, 0.014 }, WHITE, { joint = "WingL", shape = "Ball" }),
		P(
			"ThumbL",
			{ 0.161, 0.483, 0.161 },
			{ -2.719, 6.285, -0.181 },
			ICE,
			{ joint = "WingL", rot = { -63.996, 18.2, 18.603 }, material = "Glass", transparency = 0.2, studs = false }
		),
		P(
			"FingerL1",
			{ 0.172, 1.725, 0.172 },
			{ -3.101, 6.866, 0.221 },
			ARMOR,
			{ joint = "WingL", rot = { 11.712, 7.483, 32.137 }, studs = false }
		),
		P(
			"FingerL2",
			{ 0.161, 2.415, 0.161 },
			{ -3.758, 6.397, 0.423 },
			ARMOR,
			{ joint = "WingL", rot = { 4.248, 19.383, 77.386 }, studs = false }
		),
		P("WingTipL2", { 0.196, 0.575, 0.196 }, { -5.081, 6.676, 0.911 }, ICE, {
			joint = "WingL",
			rot = { -44.007, 22.355, 95.522 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"FingerL3",
			{ 0.149, 2.243, 0.149 },
			{ -3.433, 5.545, 0.52 },
			ARMOR,
			{ joint = "WingL", rot = { -17.344, 20.777, 131.36 }, studs = false }
		),
		P("WingTipL3", { 0.195, 0.575, 0.195 }, { -4.381, 4.8, 1.129 }, ICE, {
			joint = "WingL",
			rot = { -50.038, -10.721, 134.42 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"FingerL4",
			{ 0.138, 1.84, 0.138 },
			{ -2.873, 5.349, 0.376 },
			ARMOR,
			{ joint = "WingL", rot = { -22.421, 6.048, 165.676 }, studs = false }
		),
		P("MembraneL1a", { 0.115, 0.561, 1.448 }, { -1.921, 5.91, 0.123 }, MEM_L, {
			joint = "WingL",
			rot = { 100.77, 54.547, -56.609 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneL1b", { 0.115, 0.561, 1.069 }, { -0.896, 5.192, -0.014 }, MEM_L, {
			joint = "WingL",
			rot = { -79.23, -54.547, -123.391 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneL2a", { 0.115, 0.998, 0.978 }, { -3.962, 6.951, 0.532 }, MEM_D, {
			joint = "WingL",
			rot = { -29.745, 112.993, 31.292 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneL2b", { 0.115, 0.998, 1.05 }, { -3.028, 6.754, 0.188 }, MEM_D, {
			joint = "WingL",
			rot = { -29.745, -67.007, -31.292 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneL3a", { 0.115, 1.36, 1.304 }, { -3.307, 5.644, 0.439 }, MEM_L, {
			joint = "WingL",
			rot = { -29.745, -67.007, 166.754 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneL3b", { 0.115, 1.36, 0.725 }, { -4.241, 5.841, 0.783 }, MEM_L, {
			joint = "WingL",
			rot = { 150.255, 67.007, 13.246 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneL4a", { 0.115, 0.842, 1.296 }, { -2.836, 5.479, 0.318 }, MEM_D, {
			joint = "WingL",
			rot = { 50.711, -44.568, -118.056 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneL4b", { 0.115, 0.842, 0.588 }, { -3.497, 4.96, 0.743 }, MEM_D, {
			joint = "WingL",
			rot = { -129.289, 44.568, -61.944 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneL5a", { 0.115, 1.213, 2.729 }, { -1.84, 3.928, 0.354 }, MEM_L, {
			joint = "WingL",
			rot = { -91.333, -32.713, 118.373 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneL5b", { 0.115, 1.213, 0.958 }, { -2.836, 5.479, 0.318 }, MEM_L, {
			joint = "WingL",
			rot = { 88.667, 32.713, 61.627 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneL6a", { 0.115, 1.002, 2.309 }, { -1.621, 5.446, -0.123 }, MEM_D, {
			joint = "WingL",
			rot = { 88.667, 32.713, -107.796 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneL6b", { 0.115, 1.002, 1.378 }, { -0.625, 3.896, -0.086 }, MEM_D, {
			joint = "WingL",
			rot = { -91.333, -32.713, -72.204 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("ShoulderR", { 0.46, 0.46, 0.46 }, { 0.596, 4.729, -0.259 }, WHITE, { joint = "WingR", shape = "Ball" }),
		P(
			"UpperWingR",
			{ 0.299, 1.322, 0.299 },
			{ 0.924, 5.237, 0.01 },
			ARMOR,
			{ joint = "WingR", rot = { 20.464, -12.747, -30.595 }, studs = false }
		),
		P(
			"ForewingR",
			{ 0.253, 1.552, 0.253 },
			{ 1.921, 5.91, 0.123 },
			ARMOR,
			{ joint = "WingR", rot = { -2.678, 7.603, -70.532 }, studs = false }
		),
		P("WristR", { 0.368, 0.368, 0.368 }, { 2.646, 6.163, 0.014 }, WHITE, { joint = "WingR", shape = "Ball" }),
		P("ThumbR", { 0.161, 0.483, 0.161 }, { 2.719, 6.285, -0.181 }, ICE, {
			joint = "WingR",
			rot = { -16.856, 64.202, -44.135 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"FingerR1",
			{ 0.172, 1.725, 0.172 },
			{ 3.101, 6.866, 0.221 },
			ARMOR,
			{ joint = "WingR", rot = { 11.712, -7.483, -32.137 }, studs = false }
		),
		P(
			"FingerR2",
			{ 0.161, 2.415, 0.161 },
			{ 3.758, 6.397, 0.423 },
			ARMOR,
			{ joint = "WingR", rot = { 4.248, -19.383, -77.386 }, studs = false }
		),
		P("WingTipR2", { 0.196, 0.575, 0.196 }, { 5.081, 6.676, 0.911 }, ICE, {
			joint = "WingR",
			rot = { 48.099, -5.106, -67.551 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"FingerR3",
			{ 0.149, 2.243, 0.149 },
			{ 3.433, 5.545, 0.52 },
			ARMOR,
			{ joint = "WingR", rot = { -17.344, -20.777, -131.36 }, studs = false }
		),
		P("WingTipR3", { 0.195, 0.575, 0.196 }, { 4.381, 4.8, 1.129 }, ICE, {
			joint = "WingR",
			rot = { 29.63, -43.448, -104.847 },
			material = "Glass",
			transparency = 0.2,
			studs = false,
		}),
		P(
			"FingerR4",
			{ 0.138, 1.84, 0.138 },
			{ 2.873, 5.349, 0.376 },
			ARMOR,
			{ joint = "WingR", rot = { -22.421, -6.048, -165.676 }, studs = false }
		),
		P("MembraneR1a", { 0.115, 0.561, 1.448 }, { 1.921, 5.91, 0.123 }, MEM_L, {
			joint = "WingR",
			rot = { 100.77, -54.547, 56.609 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneR1b", { 0.115, 0.561, 1.069 }, { 0.896, 5.192, -0.014 }, MEM_L, {
			joint = "WingR",
			rot = { -79.23, 54.547, 123.391 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneR2a", { 0.115, 0.998, 0.978 }, { 3.962, 6.951, 0.532 }, MEM_D, {
			joint = "WingR",
			rot = { -29.745, -112.993, -31.292 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneR2b", { 0.115, 0.998, 1.05 }, { 3.028, 6.754, 0.188 }, MEM_D, {
			joint = "WingR",
			rot = { -29.745, 67.007, 31.292 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneR3a", { 0.115, 1.36, 1.304 }, { 3.307, 5.644, 0.439 }, MEM_L, {
			joint = "WingR",
			rot = { -29.745, 67.007, -166.754 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneR3b", { 0.115, 1.36, 0.725 }, { 4.241, 5.841, 0.783 }, MEM_L, {
			joint = "WingR",
			rot = { 150.255, -67.007, -13.246 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneR4a", { 0.115, 0.842, 1.296 }, { 2.836, 5.479, 0.318 }, MEM_D, {
			joint = "WingR",
			rot = { 50.711, 44.568, 118.056 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneR4b", { 0.115, 0.842, 0.588 }, { 3.497, 4.96, 0.743 }, MEM_D, {
			joint = "WingR",
			rot = { -129.289, -44.568, 61.944 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneR5a", { 0.115, 1.213, 2.729 }, { 1.84, 3.928, 0.354 }, MEM_L, {
			joint = "WingR",
			rot = { -91.333, 32.713, -118.373 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneR5b", { 0.115, 1.213, 0.958 }, { 2.836, 5.479, 0.318 }, MEM_L, {
			joint = "WingR",
			rot = { 88.667, -32.713, -61.627 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.05,
			studs = false,
		}),
		P("MembraneR6a", { 0.115, 1.002, 2.309 }, { 1.621, 5.446, -0.123 }, MEM_D, {
			joint = "WingR",
			rot = { 88.667, -32.713, 107.796 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
		P("MembraneR6b", { 0.115, 1.002, 1.378 }, { 0.625, 3.896, -0.086 }, MEM_D, {
			joint = "WingR",
			rot = { -91.333, 32.713, 72.204 },
			shape = "Wedge",
			material = "Glass",
			transparency = 0.1,
			studs = false,
		}),
	},
}

return { egg = egg, pet = pet }
