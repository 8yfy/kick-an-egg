--!strict
-- 78 Heaven Lion (Rainbow Heaven, Divine). Premium hero spec (docs/EggPetPlan.md).
-- Pet: a heroic white-and-gold statue lion (the user's reference): pillar legs, broad shoulders and haunches, a fierce
--      lion face (wide short muzzle, heavy brow, glowing gold eyes, fangs, a diamond star crown), a sunburst mane of
--      layered rhombus scales with a crest, collar and chest bib, star and sun medallions, gold bracers, gold claws,
--      an S-curled banded tail ending in a feathered sun, a halo arc.
-- Egg: white and gold terraces, a band of rhombus scales, star medallions on four faces, a crown of sun rays, the
--      Divine band and a halo arc.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/heaven_lion.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(246, 242, 232) -- #F6F2E8
local MAIN2 = rgb(232, 225, 207) -- #E8E1CF
local LIGHT = rgb(255, 255, 255) -- #FFFFFF
local DARK = rgb(201, 147, 46) -- #C9932E
local GLOW = rgb(255, 217, 102) -- #FFD966
local GOLD = rgb(226, 176, 74) -- #E2B04A
local GLASS = rgb(255, 233, 166) -- #FFE9A6
local TIP = rgb(255, 247, 214) -- #FFF7D6
local GOLD2 = rgb(201, 147, 46) -- #C9932E
local INK = rgb(62, 42, 30) -- #3E2A1E
local NOSE = rgb(91, 58, 44) -- #5B3A2C
local EYE = rgb(255, 226, 122) -- #FFE27A
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.794, 0.575, 1.794 }, { 0, 0.287, 0 }, GOLD, { joint = "Body" }),
		P("Shell2", { 2.802, 0.575, 2.802 }, { 0, 0.863, 0 }, MAIN, { joint = "Body" }),
		P("Shell3", { 3.221, 0.575, 3.221 }, { 0, 1.438, 0 }, MAIN, { joint = "Body" }),
		P("Shell4", { 3.332, 0.575, 3.332 }, { 0, 2.013, 0 }, MAIN, { joint = "Body" }),
		P("Shell5", { 3.218, 0.575, 3.218 }, { 0, 2.588, 0 }, MAIN, { joint = "Body" }),
		P("Shell6", { 2.899, 0.575, 2.899 }, { 0, 3.162, 0 }, MAIN, { joint = "Body" }),
		P("Shell7", { 2.351, 0.575, 2.351 }, { 0, 3.737, 0 }, MAIN2, { joint = "Body" }),
		P("Shell8", { 1.402, 0.575, 1.402 }, { 0, 4.312, 0 }, GOLD, { joint = "Body" }),
		P(
			"RarityBand",
			{ 2.962, 0.2, 2.962 },
			{ 0, 0.85, 0 },
			rgb(255, 250, 200),
			{ joint = "Body", material = "Neon", studs = false }
		),
		P(
			"Scale1",
			{ 0.46, 0.46, 0.14 },
			{ -0.966, 3.05, -1.46 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"Scale2",
			{ 0.46, 0.46, 0.14 },
			{ 0, 3.05, -1.46 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"Scale3",
			{ 0.46, 0.46, 0.14 },
			{ 0.966, 3.05, -1.46 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"Scale4",
			{ 0.46, 0.46, 0.14 },
			{ 1.46, 3.05, -0.966 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
		),
		P(
			"Scale5",
			{ 0.46, 0.46, 0.14 },
			{ 1.46, 3.05, 0 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
		),
		P(
			"Scale6",
			{ 0.46, 0.46, 0.14 },
			{ 1.46, 3.05, 0.966 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
		),
		P(
			"Scale7",
			{ 0.46, 0.46, 0.14 },
			{ 0.966, 3.05, 1.46 },
			GOLD,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"Scale8",
			{ 0.46, 0.46, 0.14 },
			{ 0, 3.05, 1.46 },
			GOLD,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"Scale9",
			{ 0.46, 0.46, 0.14 },
			{ -0.966, 3.05, 1.46 },
			GOLD,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"Scale10",
			{ 0.46, 0.46, 0.14 },
			{ -1.46, 3.05, 0.966 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
		),
		P(
			"Scale11",
			{ 0.46, 0.46, 0.14 },
			{ -1.46, 3.05, 0 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
		),
		P(
			"Scale12",
			{ 0.46, 0.46, 0.14 },
			{ -1.46, 3.05, -0.966 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
		),
		P(
			"Frame11",
			{ 1.017, 0.14, 0.16 },
			{ -0.31, 2.26, -1.746 },
			GOLD,
			{ joint = "Body", rot = { -180, 0, -45 }, studs = false }
		),
		P(
			"Frame12",
			{ 1.017, 0.14, 0.16 },
			{ 0.31, 2.26, -1.746 },
			GOLD,
			{ joint = "Body", rot = { -180, 0, 45 }, studs = false }
		),
		P(
			"Frame13",
			{ 1.017, 0.14, 0.16 },
			{ 0.31, 1.64, -1.746 },
			GOLD,
			{ joint = "Body", rot = { 0, 180, -45 }, studs = false }
		),
		P(
			"Frame14",
			{ 1.017, 0.14, 0.16 },
			{ -0.31, 1.64, -1.746 },
			GOLD,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"Star11a",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, -1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star11b",
			{ 0.12, 0.216, 0.518 },
			{ -0.275, 2.005, -1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star12a",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, -1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star12b",
			{ 0.12, 0.216, 0.518 },
			{ 0.055, 2.225, -1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star13a",
			{ 0.12, 0.216, 0.518 },
			{ 0.275, 2.005, -1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star13b",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, -1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star14a",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, -1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star14b",
			{ 0.12, 0.216, 0.518 },
			{ -0.055, 1.675, -1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star1Core",
			{ 0.242, 0.242, 0.156 },
			{ 0, 1.95, -1.786 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"Frame21",
			{ 1.017, 0.14, 0.16 },
			{ 1.746, 2.26, -0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, 135 }, studs = false }
		),
		P(
			"Frame22",
			{ 1.017, 0.14, 0.16 },
			{ 1.746, 2.26, 0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, -135 }, studs = false }
		),
		P(
			"Frame23",
			{ 1.017, 0.14, 0.16 },
			{ 1.746, 1.64, 0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, -45 }, studs = false }
		),
		P(
			"Frame24",
			{ 1.017, 0.14, 0.16 },
			{ 1.746, 1.64, -0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, 90, 45 }, studs = false }
		),
		P(
			"Star21a",
			{ 0.12, 0.216, 0.043 },
			{ 1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { 11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star21b",
			{ 0.12, 0.216, 0.518 },
			{ 1.786, 2.005, -0.275 },
			GLOW,
			{ joint = "Body", rot = { 11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star22a",
			{ 0.12, 0.216, 0.043 },
			{ 1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { -78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star22b",
			{ 0.12, 0.216, 0.518 },
			{ 1.786, 2.225, 0.055 },
			GLOW,
			{ joint = "Body", rot = { 101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star23a",
			{ 0.12, 0.216, 0.518 },
			{ 1.786, 2.005, 0.275 },
			GLOW,
			{ joint = "Body", rot = { -11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star23b",
			{ 0.12, 0.216, 0.043 },
			{ 1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { -11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star24a",
			{ 0.12, 0.216, 0.043 },
			{ 1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { -78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star24b",
			{ 0.12, 0.216, 0.518 },
			{ 1.786, 1.675, -0.055 },
			GLOW,
			{ joint = "Body", rot = { -78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star2Core",
			{ 0.242, 0.242, 0.156 },
			{ 1.786, 1.95, 0 },
			GLINT,
			{ joint = "Body", rot = { 0, 90, 45 }, material = "Neon", studs = false }
		),
		P(
			"Frame31",
			{ 1.017, 0.14, 0.16 },
			{ 0.31, 2.26, 1.746 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 135 }, studs = false }
		),
		P(
			"Frame32",
			{ 1.017, 0.14, 0.16 },
			{ -0.31, 2.26, 1.746 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, -135 }, studs = false }
		),
		P(
			"Frame33",
			{ 1.017, 0.14, 0.16 },
			{ -0.31, 1.64, 1.746 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, -45 }, studs = false }
		),
		P(
			"Frame34",
			{ 1.017, 0.14, 0.16 },
			{ 0.31, 1.64, 1.746 },
			GOLD,
			{ joint = "Body", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"Star31a",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, 1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star31b",
			{ 0.12, 0.216, 0.518 },
			{ 0.275, 2.005, 1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star32a",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, 1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star32b",
			{ 0.12, 0.216, 0.518 },
			{ -0.055, 2.225, 1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star33a",
			{ 0.12, 0.216, 0.518 },
			{ -0.275, 2.005, 1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star33b",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, 1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star34a",
			{ 0.12, 0.216, 0.043 },
			{ 0, 1.95, 1.786 },
			GLOW,
			{ joint = "Body", rot = { 90, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star34b",
			{ 0.12, 0.216, 0.518 },
			{ 0.055, 1.675, 1.786 },
			GLOW,
			{ joint = "Body", rot = { -90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star3Core",
			{ 0.242, 0.242, 0.156 },
			{ 0, 1.95, 1.786 },
			GLINT,
			{ joint = "Body", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"Frame41",
			{ 1.017, 0.14, 0.16 },
			{ -1.746, 2.26, 0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, 135 }, studs = false }
		),
		P(
			"Frame42",
			{ 1.017, 0.14, 0.16 },
			{ -1.746, 2.26, -0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, -135 }, studs = false }
		),
		P(
			"Frame43",
			{ 1.017, 0.14, 0.16 },
			{ -1.746, 1.64, -0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, -45 }, studs = false }
		),
		P(
			"Frame44",
			{ 1.017, 0.14, 0.16 },
			{ -1.746, 1.64, 0.31 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, 45 }, studs = false }
		),
		P(
			"Star41a",
			{ 0.12, 0.216, 0.043 },
			{ -1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { -11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star41b",
			{ 0.12, 0.216, 0.518 },
			{ -1.786, 2.005, 0.275 },
			GLOW,
			{ joint = "Body", rot = { -11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star42a",
			{ 0.12, 0.216, 0.043 },
			{ -1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { -101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star42b",
			{ 0.12, 0.216, 0.518 },
			{ -1.786, 2.225, -0.055 },
			GLOW,
			{ joint = "Body", rot = { 78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star43a",
			{ 0.12, 0.216, 0.518 },
			{ -1.786, 2.005, -0.275 },
			GLOW,
			{ joint = "Body", rot = { 11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star43b",
			{ 0.12, 0.216, 0.043 },
			{ -1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { 11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star44a",
			{ 0.12, 0.216, 0.043 },
			{ -1.786, 1.95, 0 },
			GLOW,
			{ joint = "Body", rot = { 78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star44b",
			{ 0.12, 0.216, 0.518 },
			{ -1.786, 1.675, 0.055 },
			GLOW,
			{ joint = "Body", rot = { 78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Star4Core",
			{ 0.242, 0.242, 0.156 },
			{ -1.786, 1.95, 0 },
			GLINT,
			{ joint = "Body", rot = { 0, -90, 45 }, material = "Neon", studs = false }
		),
		P(
			"Ray1",
			{ 0.36, 1.15, 0.16 },
			{ 1.014, 4.68, 0.42 },
			GOLD,
			{ joint = "Body", rot = { 71.388, 37.614, -61.112 }, studs = false }
		),
		P(
			"Ray2",
			{ 0.36, 0.85, 0.16 },
			{ 0.377, 4.581, 0.91 },
			MAIN,
			{ joint = "Body", rot = { 50.888, 14.644, -17.273 }, studs = false }
		),
		P(
			"Ray3",
			{ 0.36, 1.15, 0.16 },
			{ -0.42, 4.68, 1.014 },
			GOLD,
			{ joint = "Body", rot = { 50.888, -14.644, 17.273 }, studs = false }
		),
		P(
			"Ray4",
			{ 0.36, 0.85, 0.16 },
			{ -0.91, 4.581, 0.377 },
			MAIN,
			{ joint = "Body", rot = { 71.388, -37.614, 61.112 }, studs = false }
		),
		P(
			"Ray5",
			{ 0.36, 1.15, 0.16 },
			{ -1.014, 4.68, -0.42 },
			GOLD,
			{ joint = "Body", rot = { 108.612, -37.614, 118.888 }, studs = false }
		),
		P(
			"Ray6",
			{ 0.36, 0.85, 0.16 },
			{ -0.377, 4.581, -0.91 },
			MAIN,
			{ joint = "Body", rot = { -50.888, -165.356, -17.273 }, studs = false }
		),
		P(
			"Ray7",
			{ 0.36, 1.15, 0.16 },
			{ 0.42, 4.68, -1.014 },
			GOLD,
			{ joint = "Body", rot = { -50.888, 165.356, 17.273 }, studs = false }
		),
		P(
			"Ray8",
			{ 0.36, 0.85, 0.16 },
			{ 0.91, 4.581, -0.377 },
			MAIN,
			{ joint = "Body", rot = { 108.612, 37.614, -118.888 }, studs = false }
		),
		P(
			"Arc1",
			{ 0.36, 0.12, 0.14 },
			{ 1.269, 4.488, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, 160, 0 }, studs = false }
		),
		P(
			"Arc2",
			{ 0.36, 0.12, 0.14 },
			{ 1.349, 4.911, 0.4 },
			GLOW,
			{ joint = "Body", rot = { 90, 178.333, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc3",
			{ 0.36, 0.12, 0.14 },
			{ 1.293, 5.337, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -163.333, 0 }, studs = false }
		),
		P(
			"Arc4",
			{ 0.36, 0.12, 0.14 },
			{ 1.106, 5.724, 0.4 },
			GLOW,
			{ joint = "Body", rot = { 90, -145, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc5",
			{ 0.36, 0.12, 0.14 },
			{ 0.806, 6.033, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -126.667, 0 }, studs = false }
		),
		P(
			"Arc6",
			{ 0.36, 0.12, 0.14 },
			{ 0.425, 6.231, 0.4 },
			GLOW,
			{ joint = "Body", rot = { 90, -108.333, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc7",
			{ 0.36, 0.12, 0.14 },
			{ 0, 6.3, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 0, -90, -90 }, studs = false }
		),
		P(
			"Arc8",
			{ 0.36, 0.12, 0.14 },
			{ -0.425, 6.231, 0.4 },
			GLOW,
			{ joint = "Body", rot = { 90, -71.667, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc9",
			{ 0.36, 0.12, 0.14 },
			{ -0.806, 6.033, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -53.333, 0 }, studs = false }
		),
		P(
			"Arc10",
			{ 0.36, 0.12, 0.14 },
			{ -1.106, 5.724, 0.4 },
			GLOW,
			{ joint = "Body", rot = { 90, -35, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc11",
			{ 0.36, 0.12, 0.14 },
			{ -1.293, 5.337, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, -16.667, 0 }, studs = false }
		),
		P(
			"Arc12",
			{ 0.36, 0.12, 0.14 },
			{ -1.349, 4.911, 0.4 },
			GLOW,
			{ joint = "Body", rot = { 90, 1.667, 0 }, material = "Neon", studs = false }
		),
		P(
			"Arc13",
			{ 0.36, 0.12, 0.14 },
			{ -1.269, 4.488, 0.4 },
			GOLD,
			{ joint = "Body", rot = { 90, 20, 0 }, studs = false }
		),
		P(
			"ArcStar1a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.45, 0.35 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar1b",
			{ 0.12, 0.165, 0.395 },
			{ -0.21, 6.492, 0.35 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar2a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.45, 0.35 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar2b",
			{ 0.12, 0.165, 0.395 },
			{ 0.042, 6.66, 0.35 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar3a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.45, 0.35 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar3b",
			{ 0.12, 0.165, 0.395 },
			{ 0.21, 6.408, 0.35 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar4a",
			{ 0.12, 0.165, 0.033 },
			{ 0, 6.45, 0.35 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStar4b",
			{ 0.12, 0.165, 0.395 },
			{ -0.042, 6.24, 0.35 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ArcStarCore",
			{ 0.185, 0.185, 0.156 },
			{ 0, 6.45, 0.35 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P(
			"HingeBody",
			{ 0.21, 0.21, 0.21 },
			{ 0, 3.57, 0.315 },
			MAIN,
			{ joint = "Body", transparency = 1, studs = false }
		),
		P("Chest", { 2.415, 2.625, 2.1 }, { 0, 3.675, -1.155 }, MAIN, { joint = "Body" }),
		P("Neck", { 1.68, 1.575, 1.47 }, { 0, 4.987, -1.837 }, MAIN2, { joint = "Body" }),
		P("Barrel", { 2.1, 1.942, 1.785 }, { 0, 3.727, 0.525 }, MAIN2, { joint = "Body" }),
		P("Hips", { 2.31, 2.31, 1.68 }, { 0, 3.622, 1.942 }, MAIN, { joint = "Body" }),
		P("Back", { 1.785, 0.336, 3.15 }, { 0, 4.83, 0.84 }, MAIN, { joint = "Body" }),
		P("Belly", { 1.68, 0.315, 1.68 }, { 0, 2.793, 0.525 }, MAIN2, { joint = "Body", studs = false }),
		P("TrimL", { 0.105, 0.21, 1.785 }, { -1.113, 4.515, 0.525 }, GOLD, { joint = "Body", studs = false }),
		P("TrimLowL", { 0.105, 0.168, 1.785 }, { -1.113, 2.887, 0.525 }, GOLD2, { joint = "Body", studs = false }),
		P("TrimBackL", { 0.105, 1.627, 0.168 }, { -1.113, 3.696, 1.365 }, GOLD, { joint = "Body", studs = false }),
		P(
			"FlankGemL",
			{ 0.105, 0.651, 0.651 },
			{ -1.113, 3.696, 0.525 },
			GOLD,
			{ joint = "Body", rot = { 45, 0, 0 }, studs = false }
		),
		P(
			"FlankCoreL",
			{ 0.084, 0.357, 0.357 },
			{ -1.176, 3.696, 0.525 },
			GLOW,
			{ joint = "Body", rot = { 45, 0, 0 }, material = "Neon", studs = false }
		),
		P("TrimR", { 0.105, 0.21, 1.785 }, { 1.113, 4.515, 0.525 }, GOLD, { joint = "Body", studs = false }),
		P("TrimLowR", { 0.105, 0.168, 1.785 }, { 1.113, 2.887, 0.525 }, GOLD2, { joint = "Body", studs = false }),
		P("TrimBackR", { 0.105, 1.627, 0.168 }, { 1.113, 3.696, 1.365 }, GOLD, { joint = "Body", studs = false }),
		P(
			"FlankGemR",
			{ 0.105, 0.651, 0.651 },
			{ 1.113, 3.696, 0.525 },
			GOLD,
			{ joint = "Body", rot = { 45, 0, 0 }, studs = false }
		),
		P(
			"FlankCoreR",
			{ 0.084, 0.357, 0.357 },
			{ 1.176, 3.696, 0.525 },
			GLOW,
			{ joint = "Body", rot = { 45, 0, 0 }, material = "Neon", studs = false }
		),
		P(
			"Mane1_1",
			{ 1.05, 0.189, 1.05 },
			{ 0, 7.025, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -77.505, 45, 0 }, studs = false }
		),
		P(
			"Mane1_2",
			{ 1.05, 0.189, 1.05 },
			{ 0.616, 6.875, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -61.879, 68.462, -18.238 }, studs = false }
		),
		P(
			"Mane1_3",
			{ 1.05, 0.189, 1.05 },
			{ 1.11, 6.455, -3.214 },
			MAIN,
			{ joint = "Body", rot = { 30.633, 77.528, -112.766 }, studs = false }
		),
		P(
			"Mane1_4",
			{ 1.05, 0.189, 1.05 },
			{ 1.384, 5.849, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -108.891, 124.117, 25.369 }, studs = false }
		),
		P(
			"Mane1_5",
			{ 1.05, 0.189, 1.05 },
			{ 1.384, 5.176, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -100.911, 149.549, 16.186 }, studs = false }
		),
		P(
			"Mane1_6",
			{ 1.05, 0.189, 1.05 },
			{ 1.11, 4.57, -3.214 },
			MAIN,
			{ joint = "Body", rot = { 81.649, 4.794, -168.473 }, studs = false }
		),
		P(
			"Mane1_7",
			{ 1.05, 0.189, 1.05 },
			{ 0.616, 4.15, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -98.614, -159.593, 7.042 }, studs = false }
		),
		P(
			"Mane1_8",
			{ 1.05, 0.189, 1.05 },
			{ 0, 4, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -102.495, -135, 0 }, studs = false }
		),
		P(
			"Mane1_9",
			{ 1.05, 0.189, 1.05 },
			{ -0.616, 4.15, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -118.121, -111.538, -18.238 }, studs = false }
		),
		P(
			"Mane1_10",
			{ 1.05, 0.189, 1.05 },
			{ -1.11, 4.57, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -30.633, -77.528, 67.234 }, studs = false }
		),
		P(
			"Mane1_11",
			{ 1.05, 0.189, 1.05 },
			{ -1.384, 5.176, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -71.109, -55.883, 25.369 }, studs = false }
		),
		P(
			"Mane1_12",
			{ 1.05, 0.189, 1.05 },
			{ -1.384, 5.849, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -79.089, -30.451, 16.186 }, studs = false }
		),
		P(
			"Mane1_13",
			{ 1.05, 0.189, 1.05 },
			{ -1.11, 6.455, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -81.649, -4.794, 11.527 }, studs = false }
		),
		P(
			"Mane1_14",
			{ 1.05, 0.189, 1.05 },
			{ -0.616, 6.875, -3.214 },
			MAIN,
			{ joint = "Body", rot = { -81.386, 20.407, 7.042 }, studs = false }
		),
		P(
			"Mane2_1",
			{ 1.176, 0.189, 1.176 },
			{ 0.339, 7.562, -2.68 },
			GOLD,
			{ joint = "Body", rot = { -52.373, 53.117, -9.452 }, studs = false }
		),
		P(
			"Mane2_2",
			{ 1.176, 0.189, 1.176 },
			{ 0.977, 7.315, -2.68 },
			MAIN,
			{ joint = "Body", rot = { -23.982, 65.307, -42.035 }, studs = false }
		),
		P(
			"Mane2_3",
			{ 1.176, 0.189, 1.176 },
			{ 1.497, 6.85, -2.68 },
			GOLD,
			{ joint = "Body", rot = { 21.448, 65.208, -91.183 }, studs = false }
		),
		P(
			"Mane2_4",
			{ 1.176, 0.189, 1.176 },
			{ 1.836, 6.224, -2.68 },
			MAIN,
			{ joint = "Body", rot = { 49.641, 53.154, -122.722 }, studs = false }
		),
		P(
			"Mane2_5",
			{ 1.176, 0.189, 1.176 },
			{ 1.954, 5.512, -2.68 },
			GOLD,
			{ joint = "Body", rot = { 61.949, 36.752, -138.314 }, studs = false }
		),
		P(
			"Mane2_6",
			{ 1.176, 0.189, 1.176 },
			{ 1.836, 4.801, -2.68 },
			MAIN,
			{ joint = "Body", rot = { 67.57, 18.915, -147.771 }, studs = false }
		),
		P(
			"Mane2_7",
			{ 1.176, 0.189, 1.176 },
			{ 1.497, 4.175, -2.68 },
			GOLD,
			{ joint = "Body", rot = { 69.626, 0.496, -155.212 }, studs = false }
		),
		P(
			"Mane2_8",
			{ 1.176, 0.189, 1.176 },
			{ 0.977, 3.71, -2.68 },
			MAIN,
			{ joint = "Body", rot = { 68.76, -18.077, -162.887 }, studs = false }
		),
		P(
			"Mane2_9",
			{ 1.176, 0.189, 1.176 },
			{ 0.339, 3.463, -2.68 },
			GOLD,
			{ joint = "Body", rot = { -115.869, -143.699, 7.025 }, studs = false }
		),
		P(
			"Mane2_10",
			{ 1.176, 0.189, 1.176 },
			{ -0.339, 3.463, -2.68 },
			MAIN,
			{ joint = "Body", rot = { -127.627, -126.883, -9.452 }, studs = false }
		),
		P(
			"Mane2_11",
			{ 1.176, 0.189, 1.176 },
			{ -0.977, 3.71, -2.68 },
			GOLD,
			{ joint = "Body", rot = { 23.982, -65.307, 137.965 }, studs = false }
		),
		P(
			"Mane2_12",
			{ 1.176, 0.189, 1.176 },
			{ -1.497, 4.175, -2.68 },
			MAIN,
			{ joint = "Body", rot = { -21.448, -65.208, 88.817 }, studs = false }
		),
		P(
			"Mane2_13",
			{ 1.176, 0.189, 1.176 },
			{ -1.836, 4.801, -2.68 },
			GOLD,
			{ joint = "Body", rot = { -49.641, -53.154, 57.278 }, studs = false }
		),
		P(
			"Mane2_14",
			{ 1.176, 0.189, 1.176 },
			{ -1.954, 5.512, -2.68 },
			MAIN,
			{ joint = "Body", rot = { -61.949, -36.752, 41.686 }, studs = false }
		),
		P(
			"Mane2_15",
			{ 1.176, 0.189, 1.176 },
			{ -1.836, 6.224, -2.68 },
			GOLD,
			{ joint = "Body", rot = { -67.57, -18.915, 32.229 }, studs = false }
		),
		P(
			"Mane2_16",
			{ 1.176, 0.189, 1.176 },
			{ -1.497, 6.85, -2.68 },
			MAIN,
			{ joint = "Body", rot = { -69.626, -0.496, 24.788 }, studs = false }
		),
		P(
			"Mane2_17",
			{ 1.176, 0.189, 1.176 },
			{ -0.977, 7.315, -2.68 },
			GOLD,
			{ joint = "Body", rot = { -68.76, 18.077, 17.113 }, studs = false }
		),
		P(
			"Mane2_18",
			{ 1.176, 0.189, 1.176 },
			{ -0.339, 7.562, -2.68 },
			MAIN,
			{ joint = "Body", rot = { -64.131, 36.301, 7.025 }, studs = false }
		),
		P(
			"Mane3_1",
			{ 1.26, 0.189, 1.26 },
			{ 0, 7.959, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -40.893, 45, 0 }, studs = false }
		),
		P(
			"Mane3_2",
			{ 1.26, 0.189, 1.26 },
			{ 0.71, 7.839, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -21.163, 54.354, -25.611 }, studs = false }
		),
		P(
			"Mane3_3",
			{ 1.26, 0.189, 1.26 },
			{ 1.35, 7.492, -2.006 },
			GLOW,
			{ joint = "Body", rot = { 6.057, 56.384, -58.318 }, material = "Neon", studs = false }
		),
		P(
			"Mane3_4",
			{ 1.26, 0.189, 1.26 },
			{ 1.858, 6.951, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 29.626, 50.492, -87.102 }, studs = false }
		),
		P(
			"Mane3_5",
			{ 1.26, 0.189, 1.26 },
			{ 2.184, 6.269, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 44.25, 39.815, -106.868 }, studs = false }
		),
		P(
			"Mane3_6",
			{ 1.26, 0.189, 1.26 },
			{ 2.297, 5.512, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 52.466, 26.913, -120.505 }, studs = false }
		),
		P(
			"Mane3_7",
			{ 1.26, 0.189, 1.26 },
			{ 2.184, 4.756, -2.006 },
			GLOW,
			{ joint = "Body", rot = { 56.737, 12.878, -131.059 }, material = "Neon", studs = false }
		),
		P(
			"Mane3_8",
			{ 1.26, 0.189, 1.26 },
			{ 1.858, 4.074, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 58.137, -1.843, -140.528 }, studs = false }
		),
		P(
			"Mane3_9",
			{ 1.26, 0.189, 1.26 },
			{ 1.35, 3.533, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 56.742, -16.904, -150.502 }, studs = false }
		),
		P(
			"Mane3_10",
			{ 1.26, 0.189, 1.26 },
			{ 0.71, 3.186, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 51.699, -31.703, -162.777 }, studs = false }
		),
		P(
			"Mane3_11",
			{ 1.26, 0.189, 1.26 },
			{ 0, 3.066, -2.006 },
			GLOW,
			{ joint = "Body", rot = { 40.893, -45, 180 }, material = "Neon", studs = false }
		),
		P(
			"Mane3_12",
			{ 1.26, 0.189, 1.26 },
			{ -0.71, 3.186, -2.006 },
			MAIN,
			{ joint = "Body", rot = { 21.163, -54.354, 154.389 }, studs = false }
		),
		P(
			"Mane3_13",
			{ 1.26, 0.189, 1.26 },
			{ -1.35, 3.533, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -6.057, -56.384, 121.682 }, studs = false }
		),
		P(
			"Mane3_14",
			{ 1.26, 0.189, 1.26 },
			{ -1.858, 4.074, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -29.626, -50.492, 92.898 }, studs = false }
		),
		P(
			"Mane3_15",
			{ 1.26, 0.189, 1.26 },
			{ -2.184, 4.756, -2.006 },
			GLOW,
			{ joint = "Body", rot = { -44.25, -39.815, 73.132 }, material = "Neon", studs = false }
		),
		P(
			"Mane3_16",
			{ 1.26, 0.189, 1.26 },
			{ -2.297, 5.512, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -52.466, -26.913, 59.495 }, studs = false }
		),
		P(
			"Mane3_17",
			{ 1.26, 0.189, 1.26 },
			{ -2.184, 6.269, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -56.737, -12.878, 48.941 }, studs = false }
		),
		P(
			"Mane3_18",
			{ 1.26, 0.189, 1.26 },
			{ -1.858, 6.951, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -58.137, 1.843, 39.472 }, studs = false }
		),
		P(
			"Mane3_19",
			{ 1.26, 0.189, 1.26 },
			{ -1.35, 7.492, -2.006 },
			GLOW,
			{ joint = "Body", rot = { -56.742, 16.904, 29.498 }, material = "Neon", studs = false }
		),
		P(
			"Mane3_20",
			{ 1.26, 0.189, 1.26 },
			{ -0.71, 7.839, -2.006 },
			MAIN,
			{ joint = "Body", rot = { -51.699, 31.703, 17.223 }, studs = false }
		),
		P(
			"Mane4_1",
			{ 1.281, 0.189, 1.281 },
			{ 0.378, 8.053, -1.26 },
			GOLD,
			{ joint = "Body", rot = { -12.147, 47.812, -13.297 }, studs = false }
		),
		P(
			"Mane4_2",
			{ 1.281, 0.189, 1.281 },
			{ 1.096, 7.805, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { 9.214, 48.309, -41.752 }, studs = false }
		),
		P(
			"Mane4_3",
			{ 1.281, 0.189, 1.281 },
			{ 1.708, 7.332, -1.26 },
			GOLD,
			{ joint = "Body", rot = { 27.088, 42.488, -66.63 }, studs = false }
		),
		P(
			"Mane4_4",
			{ 1.281, 0.189, 1.281 },
			{ 2.152, 6.68, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { 38.625, 32.822, -85.344 }, studs = false }
		),
		P(
			"Mane4_5",
			{ 1.281, 0.189, 1.281 },
			{ 2.385, 5.915, -1.26 },
			GOLD,
			{ joint = "Body", rot = { 45.185, 21.331, -99.626 }, studs = false }
		),
		P(
			"Mane4_6",
			{ 1.281, 0.189, 1.281 },
			{ 2.385, 5.11, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { 48.345, 8.961, -111.608 }, studs = false }
		),
		P(
			"Mane4_7",
			{ 1.281, 0.189, 1.281 },
			{ 2.152, 4.345, -1.26 },
			GOLD,
			{ joint = "Body", rot = { 48.848, -3.911, -122.908 }, studs = false }
		),
		P(
			"Mane4_14",
			{ 1.281, 0.189, 1.281 },
			{ -2.152, 4.345, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { -38.625, -32.822, 94.656 }, studs = false }
		),
		P(
			"Mane4_15",
			{ 1.281, 0.189, 1.281 },
			{ -2.385, 5.11, -1.26 },
			GOLD,
			{ joint = "Body", rot = { -45.185, -21.331, 80.374 }, studs = false }
		),
		P(
			"Mane4_16",
			{ 1.281, 0.189, 1.281 },
			{ -2.385, 5.915, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { -48.345, -8.961, 68.392 }, studs = false }
		),
		P(
			"Mane4_17",
			{ 1.281, 0.189, 1.281 },
			{ -2.152, 6.68, -1.26 },
			GOLD,
			{ joint = "Body", rot = { -48.848, 3.911, 57.092 }, studs = false }
		),
		P(
			"Mane4_18",
			{ 1.281, 0.189, 1.281 },
			{ -1.708, 7.332, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { -46.642, 17.008, 45.063 }, studs = false }
		),
		P(
			"Mane4_19",
			{ 1.281, 0.189, 1.281 },
			{ -1.096, 7.805, -1.26 },
			GOLD,
			{ joint = "Body", rot = { -40.87, 29.749, 30.673 }, studs = false }
		),
		P(
			"Mane4_20",
			{ 1.281, 0.189, 1.281 },
			{ -0.378, 8.053, -1.26 },
			GOLD2,
			{ joint = "Body", rot = { -29.839, 40.811, 11.776 }, studs = false }
		),
		P(
			"Mane5_1",
			{ 1.207, 0.189, 1.207 },
			{ 0, 7.959, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { -2.71, 45, 0 }, studs = false }
		),
		P(
			"Mane5_2",
			{ 1.207, 0.189, 1.207 },
			{ 0.879, 7.773, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { 20.013, 42.165, -32.499 }, studs = false }
		),
		P(
			"Mane5_3",
			{ 1.207, 0.189, 1.207 },
			{ 1.624, 7.243, -0.514 },
			GOLD,
			{ joint = "Body", rot = { 35.521, 31.716, -58.172 }, studs = false }
		),
		P(
			"Mane5_4",
			{ 1.207, 0.189, 1.207 },
			{ 2.122, 6.449, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { 43.034, 17.724, -77.031 }, studs = false }
		),
		P(
			"Mane5_5",
			{ 1.207, 0.189, 1.207 },
			{ 2.297, 5.512, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { 45.063, 2.687, -92.69 }, studs = false }
		),
		P(
			"Mane5_6",
			{ 1.207, 0.189, 1.207 },
			{ 2.122, 4.576, -0.514 },
			GOLD,
			{ joint = "Body", rot = { 42.955, -12.344, -108.157 }, studs = false }
		),
		P(
			"Mane5_12",
			{ 1.207, 0.189, 1.207 },
			{ -2.122, 4.576, -0.514 },
			GOLD,
			{ joint = "Body", rot = { -43.034, -17.724, 102.969 }, studs = false }
		),
		P(
			"Mane5_13",
			{ 1.207, 0.189, 1.207 },
			{ -2.297, 5.512, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { -45.063, -2.687, 87.31 }, studs = false }
		),
		P(
			"Mane5_14",
			{ 1.207, 0.189, 1.207 },
			{ -2.122, 6.449, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { -42.955, 12.344, 71.843 }, studs = false }
		),
		P(
			"Mane5_15",
			{ 1.207, 0.189, 1.207 },
			{ -1.624, 7.243, -0.514 },
			GOLD,
			{ joint = "Body", rot = { -36.408, 26.655, 53.969 }, studs = false }
		),
		P(
			"Mane5_16",
			{ 1.207, 0.189, 1.207 },
			{ -0.879, 7.773, -0.514 },
			MAIN2,
			{ joint = "Body", rot = { -23.489, 38.692, 30.679 }, studs = false }
		),
		P(
			"Mane6_1",
			{ 1.155, 0.189, 1.155 },
			{ 0.506, 7.523, 0.16 },
			MAIN,
			{ joint = "Body", rot = { 29.237, 39.898, -19.586 }, studs = false }
		),
		P(
			"Mane6_2",
			{ 1.155, 0.189, 1.155 },
			{ 1.382, 6.984, 0.16 },
			MAIN,
			{ joint = "Body", rot = { 44.412, 22.26, -48.615 }, studs = false }
		),
		P(
			"Mane6_3",
			{ 1.155, 0.189, 1.155 },
			{ 1.887, 6.051, 0.16 },
			MAIN,
			{ joint = "Body", rot = { 47.584, 0.778, -69.73 }, studs = false }
		),
		P(
			"Mane6_4",
			{ 1.155, 0.189, 1.155 },
			{ 1.887, 4.974, 0.16 },
			MAIN,
			{ joint = "Body", rot = { 42.128, -20.268, -90.829 }, studs = false }
		),
		P(
			"Mane6_9",
			{ 1.155, 0.189, 1.155 },
			{ -1.887, 4.974, 0.16 },
			MAIN,
			{ joint = "Body", rot = { -47.584, -0.778, 110.27 }, studs = false }
		),
		P(
			"Mane6_10",
			{ 1.155, 0.189, 1.155 },
			{ -1.887, 6.051, 0.16 },
			MAIN,
			{ joint = "Body", rot = { -42.128, 20.268, 89.171 }, studs = false }
		),
		P(
			"Mane6_11",
			{ 1.155, 0.189, 1.155 },
			{ -1.382, 6.984, 0.16 },
			MAIN,
			{ joint = "Body", rot = { -27.129, 37.723, 61.385 }, studs = false }
		),
		P(
			"Mane6_12",
			{ 1.155, 0.189, 1.155 },
			{ -0.506, 7.523, 0.16 },
			MAIN,
			{ joint = "Body", rot = { 0.219, 46.285, 21.848 }, studs = false }
		),
		P(
			"ManeSpike1a",
			{ 0.189, 0.739, 0.157 },
			{ 0.41, 7.991, -1.762 },
			GOLD,
			{ joint = "Body", rot = { -64.519, 21.103, -94.381 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike1b",
			{ 0.189, 0.739, 1.657 },
			{ 0.737, 8.755, -1.398 },
			GOLD,
			{ joint = "Body", rot = { 115.481, -21.103, -85.619 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike2a",
			{ 0.189, 0.738, 0.165 },
			{ 1.181, 7.692, -1.762 },
			GLOW,
			{ joint = "Body", rot = { -58.821, 39.321, -105.38 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike2b",
			{ 0.189, 0.738, 1.571 },
			{ 1.731, 8.266, -1.415 },
			GLOW,
			{ joint = "Body", rot = { 121.179, -39.321, -74.62 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike3a",
			{ 0.189, 0.734, 0.18 },
			{ 1.81, 7.13, -1.762 },
			MAIN,
			{ joint = "Body", rot = { -44.145, 56.261, -124.471 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike3b",
			{ 0.189, 0.734, 1.407 },
			{ 2.469, 7.437, -1.446 },
			MAIN,
			{ joint = "Body", rot = { 135.855, -56.261, -55.529 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike4a",
			{ 0.189, 0.727, 0.206 },
			{ 2.22, 6.373, -1.762 },
			GOLD,
			{ joint = "Body", rot = { -6.397, 66.588, -166.049 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike4b",
			{ 0.189, 0.727, 1.183 },
			{ 2.857, 6.404, -1.488 },
			GOLD,
			{ joint = "Body", rot = { 173.603, -66.588, -13.951 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike5a",
			{ 0.189, 0.715, 0.245 },
			{ 2.362, 5.512, -1.762 },
			GLOW,
			{ joint = "Body", rot = { 39.879, 59.613, 144.219 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike5b",
			{ 0.189, 0.715, 0.92 },
			{ 2.865, 5.323, -1.536 },
			GLOW,
			{ joint = "Body", rot = { -140.121, -59.613, 35.781 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike6a",
			{ 0.189, 0.715, 0.245 },
			{ 2.22, 4.652, -1.762 },
			MAIN,
			{ joint = "Body", rot = { 57.09, 44.401, 122.666 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike6b",
			{ 0.189, 0.715, 0.92 },
			{ 2.628, 4.302, -1.536 },
			MAIN,
			{ joint = "Body", rot = { -122.91, -44.401, 57.334 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike13a",
			{ 0.189, 0.715, 0.92 },
			{ -2.628, 4.302, -1.536 },
			GOLD,
			{ joint = "Body", rot = { -122.91, 44.401, -57.334 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike13b",
			{ 0.189, 0.715, 0.245 },
			{ -2.22, 4.652, -1.762 },
			GOLD,
			{ joint = "Body", rot = { 57.09, -44.401, -122.666 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike14a",
			{ 0.189, 0.715, 0.245 },
			{ -2.362, 5.512, -1.762 },
			GLOW,
			{ joint = "Body", rot = { -39.879, -59.613, -35.781 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike14b",
			{ 0.189, 0.715, 0.92 },
			{ -2.865, 5.701, -1.536 },
			GLOW,
			{ joint = "Body", rot = { -39.879, 120.387, 35.781 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike15a",
			{ 0.189, 0.727, 1.183 },
			{ -2.857, 6.404, -1.488 },
			MAIN,
			{ joint = "Body", rot = { 173.603, 66.588, 13.951 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike15b",
			{ 0.189, 0.727, 0.206 },
			{ -2.22, 6.373, -1.762 },
			MAIN,
			{ joint = "Body", rot = { -6.397, -66.588, 166.049 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike16a",
			{ 0.189, 0.734, 1.407 },
			{ -2.469, 7.437, -1.446 },
			GOLD,
			{ joint = "Body", rot = { 135.855, 56.261, 55.529 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike16b",
			{ 0.189, 0.734, 0.18 },
			{ -1.81, 7.13, -1.762 },
			GOLD,
			{ joint = "Body", rot = { -44.144, -56.261, 124.471 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike17a",
			{ 0.189, 0.738, 1.571 },
			{ -1.731, 8.266, -1.415 },
			GLOW,
			{ joint = "Body", rot = { 121.179, 39.321, 74.62 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike17b",
			{ 0.189, 0.738, 0.165 },
			{ -1.181, 7.692, -1.762 },
			GLOW,
			{ joint = "Body", rot = { -58.821, -39.321, 105.38 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ManeSpike18a",
			{ 0.189, 0.739, 1.657 },
			{ -0.737, 8.755, -1.398 },
			MAIN,
			{ joint = "Body", rot = { 115.481, 21.103, 85.619 }, shape = "Wedge", studs = false }
		),
		P(
			"ManeSpike18b",
			{ 0.189, 0.739, 0.157 },
			{ -0.41, 7.991, -1.762 },
			MAIN,
			{ joint = "Body", rot = { -64.519, -21.103, 94.381 }, shape = "Wedge", studs = false }
		),
		P(
			"Crest1a",
			{ 0.189, 0.746, 0.122 },
			{ 0, 7.622, -1.103 },
			GOLD,
			{ joint = "Body", rot = { -55.008, 9.293, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"Crest1b",
			{ 0.189, 0.746, 2.219 },
			{ 0.189, 8.568, -0.44 },
			GOLD,
			{ joint = "Body", rot = { 124.992, -9.293, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"Crest2a",
			{ 0.189, 0.742, 1.835 },
			{ -0.942, 8.275, -0.374 },
			GLOW,
			{ joint = "Body", rot = { 129.391, 21.637, 66.827 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crest2b",
			{ 0.189, 0.742, 0.144 },
			{ -0.577, 7.564, -0.958 },
			GLOW,
			{ joint = "Body", rot = { -50.609, -21.638, 113.173 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crest3a",
			{ 0.189, 0.742, 0.144 },
			{ 0.577, 7.564, -0.958 },
			GLOW,
			{ joint = "Body", rot = { -50.609, 21.637, -113.173 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crest3b",
			{ 0.189, 0.742, 1.835 },
			{ 0.942, 8.275, -0.374 },
			GLOW,
			{ joint = "Body", rot = { 129.391, -21.637, -66.827 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crest4a",
			{ 0.189, 0.735, 1.443 },
			{ -1.529, 8.004, -0.346 },
			MAIN,
			{ joint = "Body", rot = { 134.315, 31.785, 49.66 }, shape = "Wedge", studs = false }
		),
		P(
			"Crest4b",
			{ 0.189, 0.735, 0.176 },
			{ -1.102, 7.512, -0.827 },
			MAIN,
			{ joint = "Body", rot = { -45.685, -31.785, 130.34 }, shape = "Wedge", studs = false }
		),
		P(
			"Crest5a",
			{ 0.189, 0.735, 0.176 },
			{ 1.102, 7.512, -0.827 },
			MAIN,
			{ joint = "Body", rot = { -45.685, 31.785, -130.34 }, shape = "Wedge", studs = false }
		),
		P(
			"Crest5b",
			{ 0.189, 0.735, 1.443 },
			{ 1.529, 8.004, -0.346 },
			MAIN,
			{ joint = "Body", rot = { 134.315, -31.785, -49.66 }, shape = "Wedge", studs = false }
		),
		P(
			"Bib1",
			{ 0.892, 0.189, 0.892 },
			{ -0.577, 3.307, -2.436 },
			MAIN,
			{ joint = "Body", rot = { -104.036, -135, 0 }, studs = false }
		),
		P(
			"Bib2",
			{ 0.892, 0.189, 0.892 },
			{ 0.577, 3.307, -2.436 },
			MAIN,
			{ joint = "Body", rot = { -104.036, -135, 0 }, studs = false }
		),
		P(
			"ChestStarFrame1",
			{ 1.135, 0.168, 0.168 },
			{ -0.342, 3.332, -2.629 },
			GOLD,
			{ joint = "Body", rot = { 168.69, 0, -45 }, studs = false }
		),
		P(
			"ChestStarFrame2",
			{ 1.135, 0.168, 0.168 },
			{ 0.342, 3.332, -2.629 },
			GOLD,
			{ joint = "Body", rot = { 168.69, 0, 45 }, studs = false }
		),
		P(
			"ChestStarFrame3",
			{ 1.135, 0.168, 0.168 },
			{ 0.342, 2.661, -2.495 },
			GOLD,
			{ joint = "Body", rot = { -11.31, 180, -45 }, studs = false }
		),
		P(
			"ChestStarFrame4",
			{ 1.135, 0.168, 0.168 },
			{ -0.342, 2.661, -2.495 },
			GOLD,
			{ joint = "Body", rot = { -11.31, 180, 45 }, studs = false }
		),
		P(
			"ChestStarStar1a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 2.992, -2.583 },
			GLOW,
			{ joint = "Body", rot = { -101.31, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar1b",
			{ 0.126, 0.255, 0.613 },
			{ -0.325, 3.056, -2.596 },
			GLOW,
			{ joint = "Body", rot = { 78.69, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar2a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 2.992, -2.583 },
			GLOW,
			{ joint = "Body", rot = { -101.31, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar2b",
			{ 0.126, 0.255, 0.613 },
			{ 0.065, 3.312, -2.647 },
			GLOW,
			{ joint = "Body", rot = { 78.69, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar3a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 2.992, -2.583 },
			GLOW,
			{ joint = "Body", rot = { 78.69, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar3b",
			{ 0.126, 0.255, 0.613 },
			{ 0.325, 2.929, -2.57 },
			GLOW,
			{ joint = "Body", rot = { -101.31, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar4a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 2.992, -2.583 },
			GLOW,
			{ joint = "Body", rot = { 78.69, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStar4b",
			{ 0.126, 0.255, 0.613 },
			{ -0.065, 2.673, -2.519 },
			GLOW,
			{ joint = "Body", rot = { -101.31, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ChestStarStarCore",
			{ 0.286, 0.286, 0.164 },
			{ 0, 2.992, -2.583 },
			GLINT,
			{ joint = "Body", rot = { -11.31, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"ChestRay1a",
			{ 0.105, 0.182, 0.051 },
			{ 0.601, 3.242, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, 83.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay1b",
			{ 0.105, 0.182, 0.298 },
			{ 0.775, 3.262, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, -83.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay2a",
			{ 0.105, 0.182, 0.051 },
			{ 0.249, 3.594, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, 38.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay2b",
			{ 0.105, 0.182, 0.298 },
			{ 0.357, 3.731, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, -38.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay3a",
			{ 0.105, 0.182, 0.298 },
			{ -0.357, 3.731, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, 38.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay3b",
			{ 0.105, 0.182, 0.051 },
			{ -0.249, 3.594, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, -38.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay4a",
			{ 0.105, 0.182, 0.298 },
			{ -0.775, 3.262, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, 83.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay4b",
			{ 0.105, 0.182, 0.051 },
			{ -0.601, 3.242, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, -83.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay5a",
			{ 0.105, 0.182, 0.051 },
			{ -0.601, 2.743, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, -83.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay5b",
			{ 0.105, 0.182, 0.298 },
			{ -0.775, 2.723, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, 83.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay6a",
			{ 0.105, 0.182, 0.051 },
			{ -0.249, 2.391, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, -38.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay6b",
			{ 0.105, 0.182, 0.298 },
			{ -0.357, 2.254, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, 38.209, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay7a",
			{ 0.105, 0.182, 0.298 },
			{ 0.357, 2.254, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, -38.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay7b",
			{ 0.105, 0.182, 0.051 },
			{ 0.249, 2.391, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, 38.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay8a",
			{ 0.105, 0.182, 0.298 },
			{ 0.775, 2.723, -2.551 },
			GOLD,
			{ joint = "Body", rot = { -90, -83.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ChestRay8b",
			{ 0.105, 0.182, 0.051 },
			{ 0.601, 2.743, -2.551 },
			GOLD,
			{ joint = "Body", rot = { 90, 83.209, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingL1a",
			{ 0.168, 0.641, 1.753 },
			{ -1.835, 4.936, 0.119 },
			GOLD,
			{ joint = "Body", rot = { 153.782, 26.587, 14.084 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingL1b",
			{ 0.168, 0.641, 0.114 },
			{ -1.418, 4.567, -0.63 },
			GOLD,
			{ joint = "Body", rot = { -26.218, -26.587, 165.916 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingL2a",
			{ 0.168, 0.637, 0.136 },
			{ -1.418, 4.305, -0.262 },
			MAIN,
			{ joint = "Body", rot = { -36.359, -21.796, -26.042 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingL2b",
			{ 0.168, 0.637, 1.421 },
			{ -1.707, 4.734, 0.32 },
			MAIN,
			{ joint = "Body", rot = { -36.359, 158.204, 26.042 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingL3a",
			{ 0.168, 0.629, 1.081 },
			{ -1.758, 3.993, 0.627 },
			GLOW,
			{ joint = "Body", rot = { -174.597, 32.977, 13.47 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderWingL3b",
			{ 0.168, 0.629, 0.169 },
			{ -1.418, 4.042, 0.105 },
			GLOW,
			{ joint = "Body", rot = { 5.403, -32.977, 166.53 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderWingR1a",
			{ 0.168, 0.641, 0.114 },
			{ 1.418, 4.568, -0.63 },
			GOLD,
			{ joint = "Body", rot = { -26.218, 26.587, -165.916 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingR1b",
			{ 0.168, 0.641, 1.753 },
			{ 1.835, 4.936, 0.119 },
			GOLD,
			{ joint = "Body", rot = { 153.782, -26.587, -14.084 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingR2a",
			{ 0.168, 0.637, 1.421 },
			{ 1.707, 4.734, 0.32 },
			MAIN,
			{ joint = "Body", rot = { -36.359, -158.204, -26.042 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingR2b",
			{ 0.168, 0.637, 0.136 },
			{ 1.418, 4.305, -0.263 },
			MAIN,
			{ joint = "Body", rot = { -36.359, 21.796, 26.042 }, shape = "Wedge", studs = false }
		),
		P(
			"ShoulderWingR3a",
			{ 0.168, 0.629, 0.169 },
			{ 1.418, 4.042, 0.105 },
			GLOW,
			{ joint = "Body", rot = { 5.403, 32.977, -166.53 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderWingR3b",
			{ 0.168, 0.629, 1.081 },
			{ 1.758, 3.993, 0.627 },
			GLOW,
			{ joint = "Body", rot = { -174.597, -32.977, -13.47 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Halo1",
			{ 0.588, 0.189, 0.189 },
			{ 2.876, 6.214, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, 168, 0 }, studs = false }
		),
		P(
			"Halo2",
			{ 0.588, 0.189, 0.189 },
			{ 2.934, 7.014, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, -176.308, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo3",
			{ 0.588, 0.189, 0.189 },
			{ 2.773, 7.801, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, -160.615, 0 }, studs = false }
		),
		P(
			"Halo4",
			{ 0.588, 0.189, 0.189 },
			{ 2.406, 8.515, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, -144.923, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo5",
			{ 0.588, 0.189, 0.189 },
			{ 1.859, 9.102, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, -129.231, 0 }, studs = false }
		),
		P(
			"Halo6",
			{ 0.588, 0.189, 0.189 },
			{ 1.174, 9.52, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, -113.538, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo7",
			{ 0.588, 0.189, 0.189 },
			{ 0.401, 9.737, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, -97.846, 0 }, studs = false }
		),
		P(
			"Halo8",
			{ 0.588, 0.189, 0.189 },
			{ -0.401, 9.737, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, -82.154, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo9",
			{ 0.588, 0.189, 0.189 },
			{ -1.174, 9.52, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, -66.462, 0 }, studs = false }
		),
		P(
			"Halo10",
			{ 0.588, 0.189, 0.189 },
			{ -1.859, 9.102, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, -50.769, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo11",
			{ 0.588, 0.189, 0.189 },
			{ -2.406, 8.515, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, -35.077, 0 }, studs = false }
		),
		P(
			"Halo12",
			{ 0.588, 0.189, 0.189 },
			{ -2.773, 7.801, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, -19.385, 0 }, material = "Neon", studs = false }
		),
		P(
			"Halo13",
			{ 0.588, 0.189, 0.189 },
			{ -2.934, 7.014, -0.21 },
			GOLD,
			{ joint = "Body", rot = { 90, -3.692, 0 }, studs = false }
		),
		P(
			"Halo14",
			{ 0.588, 0.189, 0.189 },
			{ -2.876, 6.214, -0.21 },
			GLOW,
			{ joint = "Body", rot = { 90, 12, 0 }, material = "Neon", studs = false }
		),
		P(
			"HaloStar1a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 10.028, -0.262 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar1b",
			{ 0.126, 0.255, 0.613 },
			{ -0.325, 10.093, -0.262 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar2a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 10.027, -0.262 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar2b",
			{ 0.126, 0.255, 0.613 },
			{ 0.065, 10.353, -0.262 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar3a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 10.028, -0.262 },
			GLOW,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar3b",
			{ 0.126, 0.255, 0.613 },
			{ 0.325, 9.962, -0.262 },
			GLOW,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar4a",
			{ 0.126, 0.255, 0.051 },
			{ 0, 10.028, -0.262 },
			GLOW,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStar4b",
			{ 0.126, 0.255, 0.613 },
			{ -0.065, 9.702, -0.262 },
			GLOW,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HaloStarCore",
			{ 0.286, 0.286, 0.164 },
			{ 0, 10.028, -0.262 },
			GLINT,
			{ joint = "Body", rot = { 0, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"HingeHead",
			{ 0.21, 0.21, 0.21 },
			{ 0, 4.935, -2.1 },
			MAIN,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P("Skull", { 2.284, 1.827, 1.979 }, { 0, 5.433, -2.811 }, MAIN, { joint = "Head" }),
		P("Forehead", { 1.523, 0.7, 0.335 }, { 0, 5.981, -3.892 }, MAIN2, { joint = "Head", studs = false }),
		P("CheekL", { 0.761, 1.142, 1.066 }, { -1.157, 4.702, -3.436 }, MAIN, { joint = "Head" }),
		P(
			"BrowL",
			{ 1.127, 0.396, 0.487 },
			{ -0.563, 5.661, -4.045 },
			MAIN2,
			{ joint = "Head", rot = { 0, 0, 24 }, studs = false }
		),
		P("PadL", { 1.005, 0.792, 0.761 }, { -0.472, 4.611, -4.38 }, MAIN, { joint = "Head" }),
		P(
			"FangLa",
			{ 0.105, 0.233, 0.072 },
			{ -0.32, 4.306, -4.775 },
			GLINT,
			{ joint = "Head", rot = { 90, -17.103, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"FangLb",
			{ 0.105, 0.233, 0.343 },
			{ -0.381, 4.108, -4.775 },
			GLINT,
			{ joint = "Head", rot = { -90, 17.103, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"CanineLa",
			{ 0.105, 0.173, 0.058 },
			{ -0.518, 3.941, -4.745 },
			GLINT,
			{ joint = "Head", rot = { -90, -18.435, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"CanineLb",
			{ 0.105, 0.173, 0.231 },
			{ -0.563, 4.078, -4.745 },
			GLINT,
			{ joint = "Head", rot = { 90, 18.435, 90 }, shape = "Wedge", studs = false }
		),
		P("CheekR", { 0.761, 1.142, 1.066 }, { 1.157, 4.702, -3.436 }, MAIN, { joint = "Head" }),
		P(
			"BrowR",
			{ 1.127, 0.396, 0.487 },
			{ 0.563, 5.661, -4.045 },
			MAIN2,
			{ joint = "Head", rot = { 0, 0, -24 }, studs = false }
		),
		P("PadR", { 1.005, 0.792, 0.761 }, { 0.472, 4.611, -4.38 }, MAIN, { joint = "Head" }),
		P(
			"FangRa",
			{ 0.105, 0.233, 0.343 },
			{ 0.381, 4.108, -4.775 },
			GLINT,
			{ joint = "Head", rot = { -90, -17.103, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"FangRb",
			{ 0.105, 0.233, 0.072 },
			{ 0.32, 4.306, -4.775 },
			GLINT,
			{ joint = "Head", rot = { 90, 17.103, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"CanineRa",
			{ 0.105, 0.173, 0.231 },
			{ 0.563, 4.078, -4.745 },
			GLINT,
			{ joint = "Head", rot = { 90, -18.435, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"CanineRb",
			{ 0.105, 0.173, 0.058 },
			{ 0.518, 3.941, -4.745 },
			GLINT,
			{ joint = "Head", rot = { -90, 18.435, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"SocketL",
			{ 0.877, 0.396, 0.076 },
			{ -0.563, 5.326, -4.197 },
			INK,
			{ joint = "Head", rot = { 0, 0, 16 }, studs = false }
		),
		P(
			"EyeL",
			{ 0.731, 0.304, 0.091 },
			{ -0.563, 5.326, -4.243 },
			EYE,
			{ joint = "Head", rot = { 0, 0, 16 }, material = "Neon", studs = false }
		),
		P(
			"PupilL",
			{ 0.19, 0.28, 0.076 },
			{ -0.533, 5.326, -4.303 },
			INK,
			{ joint = "Head", rot = { 0, 0, 16 }, studs = false }
		),
		P(
			"GlintL",
			{ 0.161, 0.161, 0.061 },
			{ -0.739, 5.393, -4.349 },
			GLINT,
			{ joint = "Head", rot = { 0, 0, 16 }, material = "Neon", studs = false }
		),
		P(
			"SocketR",
			{ 0.877, 0.396, 0.076 },
			{ 0.563, 5.326, -4.197 },
			INK,
			{ joint = "Head", rot = { 0, 0, -16 }, studs = false }
		),
		P(
			"EyeR",
			{ 0.731, 0.304, 0.091 },
			{ 0.563, 5.326, -4.243 },
			EYE,
			{ joint = "Head", rot = { 0, 0, -16 }, material = "Neon", studs = false }
		),
		P(
			"PupilR",
			{ 0.19, 0.28, 0.076 },
			{ 0.533, 5.326, -4.303 },
			INK,
			{ joint = "Head", rot = { 0, 0, -16 }, studs = false }
		),
		P(
			"GlintR",
			{ 0.161, 0.161, 0.061 },
			{ 0.739, 5.393, -4.349 },
			GLINT,
			{ joint = "Head", rot = { 0, 0, -16 }, material = "Neon", studs = false }
		),
		P("Bridge", { 0.944, 0.518, 1.096 }, { 0, 5.341, -4.288 }, MAIN, { joint = "Head", rot = { -10, 0, 0 } }),
		P("Nose", { 0.761, 0.304, 0.274 }, { 0, 5.067, -4.806 }, NOSE, { joint = "Head", studs = false }),
		P(
			"NoseTipa",
			{ 0.126, 0.244, 0.381 },
			{ -0.19, 4.793, -4.836 },
			NOSE,
			{ joint = "Head", rot = { 0, 90, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"NoseTipb",
			{ 0.126, 0.244, 0.381 },
			{ 0.19, 4.793, -4.836 },
			NOSE,
			{ joint = "Head", rot = { 0, -90, -180 }, shape = "Wedge", studs = false }
		),
		P("Philtrum", { 0.091, 0.244, 0.061 }, { 0, 4.519, -4.775 }, INK, { joint = "Head", studs = false }),
		P("Mouth", { 1.309, 0.335, 0.457 }, { 0, 4.123, -4.501 }, INK, { joint = "Head", studs = false }),
		P("Jaw", { 1.523, 0.487, 0.944 }, { 0, 3.788, -4.288 }, MAIN2, { joint = "Head" }),
		P(
			"CrownFrame1",
			{ 0.922, 0.147, 0.168 },
			{ -0.274, 6.517, -4.088 },
			GOLD,
			{ joint = "Head", rot = { -163.301, 0, -45 }, studs = false }
		),
		P(
			"CrownFrame2",
			{ 0.922, 0.147, 0.168 },
			{ 0.274, 6.517, -4.088 },
			GOLD,
			{ joint = "Head", rot = { -163.301, 0, 45 }, studs = false }
		),
		P(
			"CrownFrame3",
			{ 0.922, 0.147, 0.168 },
			{ 0.274, 5.992, -4.245 },
			GOLD,
			{ joint = "Head", rot = { 16.699, 180, -45 }, studs = false }
		),
		P(
			"CrownFrame4",
			{ 0.922, 0.147, 0.168 },
			{ -0.274, 5.992, -4.245 },
			GOLD,
			{ joint = "Head", rot = { 16.699, -180, 45 }, studs = false }
		),
		P(
			"Crown1a",
			{ 0.126, 0.239, 0.048 },
			{ 0, 6.255, -4.227 },
			GLOW,
			{ joint = "Head", rot = { -73.301, -78.69, -90.001 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown1b",
			{ 0.126, 0.239, 0.573 },
			{ -0.304, 6.313, -4.21 },
			GLOW,
			{ joint = "Head", rot = { -73.301, 101.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown2a",
			{ 0.126, 0.239, 0.048 },
			{ 0, 6.255, -4.227 },
			GLOW,
			{ joint = "Head", rot = { -73.301, 11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown2b",
			{ 0.126, 0.239, 0.573 },
			{ 0.061, 6.547, -4.14 },
			GLOW,
			{ joint = "Head", rot = { 106.699, -11.31, -90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown3a",
			{ 0.126, 0.239, 0.048 },
			{ 0, 6.255, -4.227 },
			GLOW,
			{ joint = "Head", rot = { -73.301, 101.31, -89.999 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown3b",
			{ 0.126, 0.239, 0.573 },
			{ 0.304, 6.197, -4.245 },
			GLOW,
			{ joint = "Head", rot = { -73.301, -78.69, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown4a",
			{ 0.126, 0.239, 0.048 },
			{ 0, 6.255, -4.227 },
			GLOW,
			{ joint = "Head", rot = { 106.699, -11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"Crown4b",
			{ 0.126, 0.239, 0.573 },
			{ -0.061, 5.963, -4.315 },
			GLOW,
			{ joint = "Head", rot = { -73.301, 11.31, 90 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"CrownCore",
			{ 0.268, 0.268, 0.164 },
			{ 0, 6.255, -4.227 },
			GLINT,
			{ joint = "Head", rot = { 16.699, 180, 45 }, material = "Neon", studs = false }
		),
		P(
			"CrownSpikea",
			{ 0.168, 0.432, 0.091 },
			{ 0, 6.696, -4.014 },
			GOLD,
			{ joint = "Head", rot = { -98.531, 11.86, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"CrownSpikeb",
			{ 0.168, 0.432, 0.982 },
			{ 0.11, 7.216, -4.092 },
			GOLD,
			{ joint = "Head", rot = { 81.469, -11.86, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"HingeArmL",
			{ 0.21, 0.21, 0.21 },
			{ -1.029, 3.57, -1.312 },
			MAIN,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P("ShoulderArmL", { 1.26, 1.995, 1.575 }, { -1.029, 3.517, -1.312 }, MAIN, { joint = "ArmL" }),
		P(
			"ShoulderTopArmL",
			{ 0.126, 0.168, 1.575 },
			{ -1.68, 4.462, -1.312 },
			GOLD,
			{ joint = "ArmL", studs = false }
		),
		P(
			"ShoulderEdgeArmL",
			{ 0.126, 1.837, 0.168 },
			{ -1.68, 3.57, -2.069 },
			GOLD,
			{ joint = "ArmL", studs = false }
		),
		P(
			"ShoulderArmLFrame1",
			{ 1.026, 0.168, 0.168 },
			{ -1.722, 3.821, -0.957 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -90, 135 }, studs = false }
		),
		P(
			"ShoulderArmLFrame2",
			{ 1.026, 0.168, 0.168 },
			{ -1.722, 3.821, -1.563 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -90, -135 }, studs = false }
		),
		P(
			"ShoulderArmLFrame3",
			{ 1.026, 0.168, 0.168 },
			{ -1.722, 3.214, -1.563 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -90, -45 }, studs = false }
		),
		P(
			"ShoulderArmLFrame4",
			{ 1.026, 0.168, 0.168 },
			{ -1.722, 3.214, -0.957 },
			GOLD,
			{ joint = "ArmL", rot = { 0, -90, 45 }, studs = false }
		),
		P(
			"ShoulderArmLStar1a",
			{ 0.126, 0.227, 0.045 },
			{ -1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmL", rot = { -11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar1b",
			{ 0.126, 0.227, 0.544 },
			{ -1.743, 3.575, -0.971 },
			GLOW,
			{ joint = "ArmL", rot = { -11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar2a",
			{ 0.126, 0.227, 0.045 },
			{ -1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmL", rot = { -101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar2b",
			{ 0.126, 0.227, 0.544 },
			{ -1.743, 3.806, -1.318 },
			GLOW,
			{ joint = "ArmL", rot = { 78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar3a",
			{ 0.126, 0.227, 0.045 },
			{ -1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmL", rot = { 168.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar3b",
			{ 0.126, 0.227, 0.544 },
			{ -1.743, 3.46, -1.549 },
			GLOW,
			{ joint = "ArmL", rot = { -11.31, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar4a",
			{ 0.126, 0.227, 0.045 },
			{ -1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmL", rot = { 78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStar4b",
			{ 0.126, 0.227, 0.544 },
			{ -1.743, 3.229, -1.202 },
			GLOW,
			{ joint = "ArmL", rot = { 78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmLStarCore",
			{ 0.254, 0.254, 0.164 },
			{ -1.743, 3.517, -1.26 },
			GLINT,
			{ joint = "ArmL", rot = { 0, -90, 45 }, material = "Neon", studs = false }
		),
		P("ForearmArmL", { 1.449, 0.997, 1.491 }, { -1.029, 2.31, -1.365 }, MAIN, { joint = "ArmL" }),
		P("PillarArmL", { 1.26, 2.415, 1.312 }, { -1.029, 1.418, -1.365 }, MAIN2, { joint = "ArmL" }),
		P("BracerArmL", { 1.386, 0.462, 1.438 }, { -1.029, 1.312, -1.365 }, GOLD, { joint = "ArmL" }),
		P(
			"BracerTrimArmL",
			{ 1.438, 0.105, 1.491 },
			{ -1.029, 1.585, -1.365 },
			GOLD2,
			{ joint = "ArmL", studs = false }
		),
		P(
			"BracerGemArmL",
			{ 0.525, 0.525, 0.126 },
			{ -1.029, 1.312, -2.121 },
			GOLD,
			{ joint = "ArmL", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"BracerCoreArmL",
			{ 0.252, 0.252, 0.084 },
			{ -1.029, 1.312, -2.205 },
			GLOW,
			{ joint = "ArmL", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"BracerFlareArmLa",
			{ 0.168, 0.343, 0.557 },
			{ -1.459, 1.751, -0.836 },
			GOLD,
			{ joint = "ArmL", rot = { 133.101, 16.705, -4.878 }, shape = "Wedge", studs = false }
		),
		P(
			"BracerFlareArmLb",
			{ 0.168, 0.343, 0.097 },
			{ -1.365, 1.523, -1.05 },
			GOLD,
			{ joint = "ArmL", rot = { -46.899, -16.705, -175.122 }, shape = "Wedge", studs = false }
		),
		P("PawArmL", { 1.523, 0.462, 1.68 }, { -1.029, 0.231, -1.523 }, MAIN, { joint = "ArmL" }),
		P("ToeArmL1", { 0.325, 0.462, 0.462 }, { -1.564, 0.262, -2.478 }, MAIN2, { joint = "ArmL", studs = false }),
		P("ClawArmL1", { 0.325, 0.136, 0.231 }, { -1.564, 0.068, -2.625 }, GOLD, { joint = "ArmL", studs = false }),
		P("ToeArmL2", { 0.325, 0.462, 0.462 }, { -1.207, 0.262, -2.478 }, MAIN2, { joint = "ArmL", studs = false }),
		P("ClawArmL2", { 0.325, 0.136, 0.231 }, { -1.207, 0.068, -2.625 }, GOLD, { joint = "ArmL", studs = false }),
		P("ToeArmL3", { 0.325, 0.462, 0.462 }, { -0.85, 0.262, -2.478 }, MAIN2, { joint = "ArmL", studs = false }),
		P("ClawArmL3", { 0.325, 0.136, 0.231 }, { -0.85, 0.068, -2.625 }, GOLD, { joint = "ArmL", studs = false }),
		P("ToeArmL4", { 0.325, 0.462, 0.462 }, { -0.493, 0.262, -2.478 }, MAIN2, { joint = "ArmL", studs = false }),
		P("ClawArmL4", { 0.325, 0.136, 0.231 }, { -0.493, 0.068, -2.625 }, GOLD, { joint = "ArmL", studs = false }),
		P(
			"HingeArmR",
			{ 0.21, 0.21, 0.21 },
			{ 1.029, 3.57, -1.312 },
			MAIN,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P("ShoulderArmR", { 1.26, 1.995, 1.575 }, { 1.029, 3.517, -1.312 }, MAIN, { joint = "ArmR" }),
		P("ShoulderTopArmR", { 0.126, 0.168, 1.575 }, { 1.68, 4.462, -1.312 }, GOLD, { joint = "ArmR", studs = false }),
		P("ShoulderEdgeArmR", { 0.126, 1.837, 0.168 }, { 1.68, 3.57, -2.069 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"ShoulderArmRFrame1",
			{ 1.026, 0.168, 0.168 },
			{ 1.722, 3.821, -1.563 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 90, 135 }, studs = false }
		),
		P(
			"ShoulderArmRFrame2",
			{ 1.026, 0.168, 0.168 },
			{ 1.722, 3.821, -0.957 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 90, -135 }, studs = false }
		),
		P(
			"ShoulderArmRFrame3",
			{ 1.026, 0.168, 0.168 },
			{ 1.722, 3.214, -0.957 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 90, -45 }, studs = false }
		),
		P(
			"ShoulderArmRFrame4",
			{ 1.026, 0.168, 0.168 },
			{ 1.722, 3.214, -1.563 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 90, 45 }, studs = false }
		),
		P(
			"ShoulderArmRStar1a",
			{ 0.126, 0.227, 0.045 },
			{ 1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmR", rot = { 11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar1b",
			{ 0.126, 0.227, 0.544 },
			{ 1.743, 3.575, -1.549 },
			GLOW,
			{ joint = "ArmR", rot = { 11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar2a",
			{ 0.126, 0.227, 0.045 },
			{ 1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmR", rot = { -78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar2b",
			{ 0.126, 0.227, 0.544 },
			{ 1.743, 3.806, -1.202 },
			GLOW,
			{ joint = "ArmR", rot = { 101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar3a",
			{ 0.126, 0.227, 0.045 },
			{ 1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmR", rot = { 11.31, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar3b",
			{ 0.126, 0.227, 0.544 },
			{ 1.743, 3.46, -0.971 },
			GLOW,
			{ joint = "ArmR", rot = { -168.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar4a",
			{ 0.126, 0.227, 0.045 },
			{ 1.743, 3.517, -1.26 },
			GLOW,
			{ joint = "ArmR", rot = { -78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStar4b",
			{ 0.126, 0.227, 0.544 },
			{ 1.743, 3.229, -1.318 },
			GLOW,
			{ joint = "ArmR", rot = { -78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"ShoulderArmRStarCore",
			{ 0.254, 0.254, 0.164 },
			{ 1.743, 3.517, -1.26 },
			GLINT,
			{ joint = "ArmR", rot = { 0, 90, 45 }, material = "Neon", studs = false }
		),
		P("ForearmArmR", { 1.449, 0.997, 1.491 }, { 1.029, 2.31, -1.365 }, MAIN, { joint = "ArmR" }),
		P("PillarArmR", { 1.26, 2.415, 1.312 }, { 1.029, 1.418, -1.365 }, MAIN2, { joint = "ArmR" }),
		P("BracerArmR", { 1.386, 0.462, 1.438 }, { 1.029, 1.312, -1.365 }, GOLD, { joint = "ArmR" }),
		P(
			"BracerTrimArmR",
			{ 1.438, 0.105, 1.491 },
			{ 1.029, 1.585, -1.365 },
			GOLD2,
			{ joint = "ArmR", studs = false }
		),
		P(
			"BracerGemArmR",
			{ 0.525, 0.525, 0.126 },
			{ 1.029, 1.312, -2.121 },
			GOLD,
			{ joint = "ArmR", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"BracerCoreArmR",
			{ 0.252, 0.252, 0.084 },
			{ 1.029, 1.312, -2.205 },
			GLOW,
			{ joint = "ArmR", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"BracerFlareArmRa",
			{ 0.168, 0.343, 0.097 },
			{ 1.365, 1.523, -1.05 },
			GOLD,
			{ joint = "ArmR", rot = { -46.899, 16.705, 175.122 }, shape = "Wedge", studs = false }
		),
		P(
			"BracerFlareArmRb",
			{ 0.168, 0.343, 0.557 },
			{ 1.459, 1.751, -0.836 },
			GOLD,
			{ joint = "ArmR", rot = { 133.101, -16.705, 4.878 }, shape = "Wedge", studs = false }
		),
		P("PawArmR", { 1.523, 0.462, 1.68 }, { 1.029, 0.231, -1.523 }, MAIN, { joint = "ArmR" }),
		P("ToeArmR1", { 0.325, 0.462, 0.462 }, { 0.493, 0.262, -2.478 }, MAIN2, { joint = "ArmR", studs = false }),
		P("ClawArmR1", { 0.325, 0.136, 0.231 }, { 0.493, 0.068, -2.625 }, GOLD, { joint = "ArmR", studs = false }),
		P("ToeArmR2", { 0.325, 0.462, 0.462 }, { 0.85, 0.262, -2.478 }, MAIN2, { joint = "ArmR", studs = false }),
		P("ClawArmR2", { 0.325, 0.136, 0.231 }, { 0.85, 0.068, -2.625 }, GOLD, { joint = "ArmR", studs = false }),
		P("ToeArmR3", { 0.325, 0.462, 0.462 }, { 1.207, 0.262, -2.478 }, MAIN2, { joint = "ArmR", studs = false }),
		P("ClawArmR3", { 0.325, 0.136, 0.231 }, { 1.207, 0.068, -2.625 }, GOLD, { joint = "ArmR", studs = false }),
		P("ToeArmR4", { 0.325, 0.462, 0.462 }, { 1.564, 0.262, -2.478 }, MAIN2, { joint = "ArmR", studs = false }),
		P("ClawArmR4", { 0.325, 0.136, 0.231 }, { 1.564, 0.068, -2.625 }, GOLD, { joint = "ArmR", studs = false }),
		P(
			"HingeLegL",
			{ 0.21, 0.21, 0.21 },
			{ -1.029, 3.57, 1.942 },
			MAIN,
			{ joint = "LegL", transparency = 1, studs = false }
		),
		P("HaunchLegL", { 1.365, 2.31, 2.1 }, { -1.029, 3.465, 1.942 }, MAIN, { joint = "LegL" }),
		P("ThighLegL", { 1.26, 1.155, 1.68 }, { -1.029, 2.31, 2.047 }, MAIN2, { joint = "LegL" }),
		P(
			"HipLegLDisc",
			{ 0.126, 0.84, 0.84 },
			{ -1.743, 3.517, 1.942 },
			GLOW,
			{ joint = "LegL", shape = "Cylinder", material = "Neon", studs = false }
		),
		P(
			"HipLegLRim1",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 4.053, 1.942 },
			GOLD,
			{ joint = "LegL", rot = { -90, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim2",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 3.896, 1.564 },
			GOLD,
			{ joint = "LegL", rot = { -135, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim3",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 3.517, 1.407 },
			GOLD,
			{ joint = "LegL", rot = { -180, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim4",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 3.139, 1.564 },
			GOLD,
			{ joint = "LegL", rot = { 135, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim5",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 2.982, 1.942 },
			GOLD,
			{ joint = "LegL", rot = { 90, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim6",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 3.139, 2.321 },
			GOLD,
			{ joint = "LegL", rot = { 45, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim7",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 3.517, 2.478 },
			GOLD,
			{ joint = "LegL", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"HipLegLRim8",
			{ 0.443, 0.126, 0.168 },
			{ -1.743, 3.896, 2.321 },
			GOLD,
			{ joint = "LegL", rot = { -45, 0, 90 }, studs = false }
		),
		P(
			"HipLegLStar1a",
			{ 0.126, 0.196, 0.039 },
			{ -1.827, 3.517, 1.942 },
			GLINT,
			{ joint = "LegL", rot = { -11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar1b",
			{ 0.126, 0.196, 0.47 },
			{ -1.827, 3.567, 2.192 },
			GLINT,
			{ joint = "LegL", rot = { -11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar2a",
			{ 0.126, 0.196, 0.039 },
			{ -1.827, 3.517, 1.942 },
			GLINT,
			{ joint = "LegL", rot = { -101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar2b",
			{ 0.126, 0.196, 0.47 },
			{ -1.827, 3.767, 1.893 },
			GLINT,
			{ joint = "LegL", rot = { 78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar3a",
			{ 0.126, 0.196, 0.039 },
			{ -1.827, 3.517, 1.943 },
			GLINT,
			{ joint = "LegL", rot = { 168.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar3b",
			{ 0.126, 0.196, 0.47 },
			{ -1.827, 3.468, 1.693 },
			GLINT,
			{ joint = "LegL", rot = { -11.31, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar4a",
			{ 0.126, 0.196, 0.039 },
			{ -1.827, 3.517, 1.943 },
			GLINT,
			{ joint = "LegL", rot = { 78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStar4b",
			{ 0.126, 0.196, 0.47 },
			{ -1.827, 3.268, 1.992 },
			GLINT,
			{ joint = "LegL", rot = { 78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegLStarCore",
			{ 0.219, 0.219, 0.164 },
			{ -1.827, 3.517, 1.942 },
			GLOW,
			{ joint = "LegL", rot = { 0, -90, 45 }, material = "Neon", studs = false }
		),
		P("PillarLegL", { 1.26, 2.415, 1.312 }, { -1.029, 1.418, 2.152 }, MAIN, { joint = "LegL" }),
		P("BracerLegL", { 1.386, 0.462, 1.438 }, { -1.029, 1.312, 2.152 }, GOLD, { joint = "LegL" }),
		P(
			"BracerTrimLegL",
			{ 1.438, 0.105, 1.491 },
			{ -1.029, 1.585, 2.152 },
			GOLD2,
			{ joint = "LegL", studs = false }
		),
		P(
			"BracerGemLegL",
			{ 0.525, 0.525, 0.126 },
			{ -1.029, 1.312, 1.396 },
			GOLD,
			{ joint = "LegL", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"BracerCoreLegL",
			{ 0.252, 0.252, 0.084 },
			{ -1.029, 1.312, 1.312 },
			GLOW,
			{ joint = "LegL", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"BracerFlareLegLa",
			{ 0.168, 0.343, 0.097 },
			{ -1.365, 1.523, 2.467 },
			GOLD,
			{ joint = "LegL", rot = { -79.971, -16.705, -4.878 }, shape = "Wedge", studs = false }
		),
		P(
			"BracerFlareLegLb",
			{ 0.168, 0.343, 0.557 },
			{ -1.459, 1.831, 2.522 },
			GOLD,
			{ joint = "LegL", rot = { -79.971, 163.295, 4.878 }, shape = "Wedge", studs = false }
		),
		P("PawLegL", { 1.523, 0.462, 1.68 }, { -1.029, 0.231, 1.995 }, MAIN, { joint = "LegL" }),
		P("ToeLegL1", { 0.325, 0.462, 0.462 }, { -1.564, 0.262, 1.039 }, MAIN2, { joint = "LegL", studs = false }),
		P("ClawLegL1", { 0.325, 0.136, 0.231 }, { -1.564, 0.068, 0.892 }, GOLD, { joint = "LegL", studs = false }),
		P("ToeLegL2", { 0.325, 0.462, 0.462 }, { -1.207, 0.262, 1.039 }, MAIN2, { joint = "LegL", studs = false }),
		P("ClawLegL2", { 0.325, 0.136, 0.231 }, { -1.207, 0.068, 0.892 }, GOLD, { joint = "LegL", studs = false }),
		P("ToeLegL3", { 0.325, 0.462, 0.462 }, { -0.85, 0.262, 1.039 }, MAIN2, { joint = "LegL", studs = false }),
		P("ClawLegL3", { 0.325, 0.136, 0.231 }, { -0.85, 0.068, 0.892 }, GOLD, { joint = "LegL", studs = false }),
		P("ToeLegL4", { 0.325, 0.462, 0.462 }, { -0.493, 0.262, 1.039 }, MAIN2, { joint = "LegL", studs = false }),
		P("ClawLegL4", { 0.325, 0.136, 0.231 }, { -0.493, 0.068, 0.892 }, GOLD, { joint = "LegL", studs = false }),
		P(
			"HingeLegR",
			{ 0.21, 0.21, 0.21 },
			{ 1.029, 3.57, 1.942 },
			MAIN,
			{ joint = "LegR", transparency = 1, studs = false }
		),
		P("HaunchLegR", { 1.365, 2.31, 2.1 }, { 1.029, 3.465, 1.942 }, MAIN, { joint = "LegR" }),
		P("ThighLegR", { 1.26, 1.155, 1.68 }, { 1.029, 2.31, 2.047 }, MAIN2, { joint = "LegR" }),
		P(
			"HipLegRDisc",
			{ 0.126, 0.84, 0.84 },
			{ 1.743, 3.517, 1.942 },
			GLOW,
			{ joint = "LegR", shape = "Cylinder", material = "Neon", studs = false }
		),
		P(
			"HipLegRRim1",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 4.053, 1.942 },
			GOLD,
			{ joint = "LegR", rot = { -90, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim2",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 3.896, 2.321 },
			GOLD,
			{ joint = "LegR", rot = { -45, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim3",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 3.517, 2.478 },
			GOLD,
			{ joint = "LegR", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim4",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 3.139, 2.321 },
			GOLD,
			{ joint = "LegR", rot = { 45, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim5",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 2.982, 1.942 },
			GOLD,
			{ joint = "LegR", rot = { 90, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim6",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 3.139, 1.564 },
			GOLD,
			{ joint = "LegR", rot = { 135, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim7",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 3.517, 1.407 },
			GOLD,
			{ joint = "LegR", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"HipLegRRim8",
			{ 0.443, 0.126, 0.168 },
			{ 1.743, 3.896, 1.564 },
			GOLD,
			{ joint = "LegR", rot = { -135, 0, -90 }, studs = false }
		),
		P(
			"HipLegRStar1a",
			{ 0.126, 0.196, 0.039 },
			{ 1.827, 3.517, 1.943 },
			GLINT,
			{ joint = "LegR", rot = { 11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar1b",
			{ 0.126, 0.196, 0.47 },
			{ 1.827, 3.567, 1.693 },
			GLINT,
			{ joint = "LegR", rot = { 11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar2a",
			{ 0.126, 0.196, 0.039 },
			{ 1.827, 3.517, 1.943 },
			GLINT,
			{ joint = "LegR", rot = { -78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar2b",
			{ 0.126, 0.196, 0.47 },
			{ 1.827, 3.767, 1.992 },
			GLINT,
			{ joint = "LegR", rot = { 101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar3a",
			{ 0.126, 0.196, 0.039 },
			{ 1.827, 3.517, 1.942 },
			GLINT,
			{ joint = "LegR", rot = { 11.31, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar3b",
			{ 0.126, 0.196, 0.47 },
			{ 1.827, 3.468, 2.192 },
			GLINT,
			{ joint = "LegR", rot = { -168.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar4a",
			{ 0.126, 0.196, 0.039 },
			{ 1.827, 3.517, 1.942 },
			GLINT,
			{ joint = "LegR", rot = { -78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStar4b",
			{ 0.126, 0.196, 0.47 },
			{ 1.827, 3.268, 1.893 },
			GLINT,
			{ joint = "LegR", rot = { -78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"HipLegRStarCore",
			{ 0.219, 0.219, 0.164 },
			{ 1.827, 3.517, 1.942 },
			GLOW,
			{ joint = "LegR", rot = { 0, 90, 45 }, material = "Neon", studs = false }
		),
		P("PillarLegR", { 1.26, 2.415, 1.312 }, { 1.029, 1.418, 2.152 }, MAIN, { joint = "LegR" }),
		P("BracerLegR", { 1.386, 0.462, 1.438 }, { 1.029, 1.312, 2.152 }, GOLD, { joint = "LegR" }),
		P("BracerTrimLegR", { 1.438, 0.105, 1.491 }, { 1.029, 1.585, 2.152 }, GOLD2, { joint = "LegR", studs = false }),
		P(
			"BracerGemLegR",
			{ 0.525, 0.525, 0.126 },
			{ 1.029, 1.312, 1.396 },
			GOLD,
			{ joint = "LegR", rot = { 0, 0, 45 }, studs = false }
		),
		P(
			"BracerCoreLegR",
			{ 0.252, 0.252, 0.084 },
			{ 1.029, 1.312, 1.312 },
			GLOW,
			{ joint = "LegR", rot = { 0, 0, 45 }, material = "Neon", studs = false }
		),
		P(
			"BracerFlareLegRa",
			{ 0.168, 0.343, 0.557 },
			{ 1.459, 1.831, 2.522 },
			GOLD,
			{ joint = "LegR", rot = { -79.971, -163.295, -4.878 }, shape = "Wedge", studs = false }
		),
		P(
			"BracerFlareLegRb",
			{ 0.168, 0.343, 0.097 },
			{ 1.365, 1.523, 2.467 },
			GOLD,
			{ joint = "LegR", rot = { -79.971, 16.705, 4.878 }, shape = "Wedge", studs = false }
		),
		P("PawLegR", { 1.523, 0.462, 1.68 }, { 1.029, 0.231, 1.995 }, MAIN, { joint = "LegR" }),
		P("ToeLegR1", { 0.325, 0.462, 0.462 }, { 0.493, 0.262, 1.039 }, MAIN2, { joint = "LegR", studs = false }),
		P("ClawLegR1", { 0.325, 0.136, 0.231 }, { 0.493, 0.068, 0.892 }, GOLD, { joint = "LegR", studs = false }),
		P("ToeLegR2", { 0.325, 0.462, 0.462 }, { 0.85, 0.262, 1.039 }, MAIN2, { joint = "LegR", studs = false }),
		P("ClawLegR2", { 0.325, 0.136, 0.231 }, { 0.85, 0.068, 0.892 }, GOLD, { joint = "LegR", studs = false }),
		P("ToeLegR3", { 0.325, 0.462, 0.462 }, { 1.207, 0.262, 1.039 }, MAIN2, { joint = "LegR", studs = false }),
		P("ClawLegR3", { 0.325, 0.136, 0.231 }, { 1.207, 0.068, 0.892 }, GOLD, { joint = "LegR", studs = false }),
		P("ToeLegR4", { 0.325, 0.462, 0.462 }, { 1.564, 0.262, 1.039 }, MAIN2, { joint = "LegR", studs = false }),
		P("ClawLegR4", { 0.325, 0.136, 0.231 }, { 1.564, 0.068, 0.892 }, GOLD, { joint = "LegR", studs = false }),
		P(
			"HingeTail",
			{ 0.21, 0.21, 0.21 },
			{ 0, 4.253, 2.73 },
			MAIN,
			{ joint = "Tail", transparency = 1, studs = false }
		),
		P("Tail1", { 0.472, 0.472, 0.789 }, { 0, 3.947, 2.923 }, MAIN, { joint = "Tail", rot = { 45.795, 0, 0 } }),
		P("Tail2", { 0.451, 0.452, 0.742 }, { 0, 3.623, 3.492 }, MAIN2, { joint = "Tail", rot = { 12.523, 0, 0 } }),
		P("Tail3", { 0.43, 0.43, 0.772 }, { 0, 3.762, 4.088 }, MAIN, { joint = "Tail", rot = { -37.735, 0, 0 } }),
		P("Tail4", { 0.409, 0.409, 0.785 }, { 0, 4.31, 4.457 }, MAIN2, { joint = "Tail", rot = { -74.037, 0, 0 } }),
		P("Tail5", { 0.388, 0.388, 0.781 }, { 0, 4.994, 4.52 }, MAIN, { joint = "Tail", rot = { 84.422, 180, 0 } }),
		P("Tail6", { 0.367, 0.367, 0.789 }, { 0, 5.663, 4.343 }, MAIN2, { joint = "Tail", rot = { 66.059, 180, 0 } }),
		P(
			"TailBand2",
			{ 0.506, 0.506, 0.147 },
			{ 0, 3.623, 3.492 },
			GOLD,
			{ joint = "Tail", rot = { 12.523, 0, 0 }, studs = false }
		),
		P(
			"TailBand4",
			{ 0.459, 0.459, 0.147 },
			{ 0, 4.31, 4.457 },
			GOLD,
			{ joint = "Tail", rot = { -74.037, 0, 0 }, studs = false }
		),
		P(
			"TailBand6",
			{ 0.412, 0.412, 0.147 },
			{ 0, 5.663, 4.343 },
			GOLD,
			{ joint = "Tail", rot = { 66.059, 180, 0 }, studs = false }
		),
		P(
			"SunDisc",
			{ 0.147, 0.861, 0.861 },
			{ 0, 6.562, 3.99 },
			GLOW,
			{ joint = "Tail", shape = "Cylinder", material = "Neon", studs = false }
		),
		P(
			"SunRim1",
			{ 0.417, 0.126, 0.189 },
			{ 0, 7.066, 3.99 },
			GOLD,
			{ joint = "Tail", rot = { -90, 0, -90 }, studs = false }
		),
		P(
			"SunRim2",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.919, 4.346 },
			GOLD,
			{ joint = "Tail", rot = { -45, 0, -90 }, studs = false }
		),
		P(
			"SunRim3",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.562, 4.494 },
			GOLD,
			{ joint = "Tail", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"SunRim4",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.206, 4.346 },
			GOLD,
			{ joint = "Tail", rot = { 45, 0, -90 }, studs = false }
		),
		P(
			"SunRim5",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.058, 3.99 },
			GOLD,
			{ joint = "Tail", rot = { 90, 0, -90 }, studs = false }
		),
		P(
			"SunRim6",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.206, 3.634 },
			GOLD,
			{ joint = "Tail", rot = { 135, 0, -90 }, studs = false }
		),
		P(
			"SunRim7",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.562, 3.486 },
			GOLD,
			{ joint = "Tail", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"SunRim8",
			{ 0.417, 0.126, 0.189 },
			{ 0, 6.919, 3.634 },
			GOLD,
			{ joint = "Tail", rot = { -135, 0, -90 }, studs = false }
		),
		P(
			"SunStar1a",
			{ 0.126, 0.189, 0.038 },
			{ 0.105, 6.562, 3.99 },
			GLINT,
			{ joint = "Tail", rot = { 11.31, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar1b",
			{ 0.126, 0.189, 0.455 },
			{ 0.105, 6.611, 3.748 },
			GLINT,
			{ joint = "Tail", rot = { 11.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar2a",
			{ 0.126, 0.189, 0.038 },
			{ 0.105, 6.562, 3.99 },
			GLINT,
			{ joint = "Tail", rot = { -78.69, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar2b",
			{ 0.126, 0.189, 0.455 },
			{ 0.105, 6.804, 4.038 },
			GLINT,
			{ joint = "Tail", rot = { 101.31, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar3a",
			{ 0.126, 0.189, 0.038 },
			{ 0.105, 6.562, 3.99 },
			GLINT,
			{ joint = "Tail", rot = { 11.31, 0, -180 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar3b",
			{ 0.126, 0.189, 0.455 },
			{ 0.105, 6.514, 4.231 },
			GLINT,
			{ joint = "Tail", rot = { -168.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar4a",
			{ 0.126, 0.189, 0.038 },
			{ 0.105, 6.562, 3.99 },
			GLINT,
			{ joint = "Tail", rot = { -78.69, 180, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStar4b",
			{ 0.126, 0.189, 0.455 },
			{ 0.105, 6.321, 3.942 },
			GLINT,
			{ joint = "Tail", rot = { -78.69, 0, 0 }, shape = "Wedge", material = "Neon", studs = false }
		),
		P(
			"SunStarCore",
			{ 0.213, 0.213, 0.164 },
			{ 0.105, 6.562, 3.99 },
			GLOW,
			{ joint = "Tail", rot = { 0, 90, 45 }, material = "Neon", studs = false }
		),
		P(
			"SunBlade1a",
			{ 0.168, 0.431, 0.926 },
			{ 0, 6.934, 4.95 },
			GOLD,
			{ joint = "Tail", rot = { -27.465, 180, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade1b",
			{ 0.168, 0.431, 0.095 },
			{ 0, 6.698, 4.497 },
			GOLD,
			{ joint = "Tail", rot = { -27.465, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade2a",
			{ 0.168, 0.425, 0.119 },
			{ 0, 6.934, 4.361 },
			MAIN,
			{ joint = "Tail", rot = { -29.358, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade2b",
			{ 0.168, 0.425, 0.699 },
			{ 0, 7.134, 4.718 },
			MAIN,
			{ joint = "Tail", rot = { 150.642, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade3a",
			{ 0.168, 0.431, 0.095 },
			{ 0, 7.07, 4.126 },
			GOLD,
			{ joint = "Tail", rot = { -62.535, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade3b",
			{ 0.168, 0.431, 0.926 },
			{ 0, 7.523, 4.361 },
			GOLD,
			{ joint = "Tail", rot = { 117.465, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade4a",
			{ 0.168, 0.425, 0.699 },
			{ 0, 7.421, 3.646 },
			MAIN,
			{ joint = "Tail", rot = { 59.358, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade4b",
			{ 0.168, 0.425, 0.119 },
			{ 0, 7.07, 3.854 },
			MAIN,
			{ joint = "Tail", rot = { -120.642, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade5a",
			{ 0.168, 0.431, 0.095 },
			{ 0, 6.934, 3.619 },
			GOLD,
			{ joint = "Tail", rot = { 57.465, 180, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade5b",
			{ 0.168, 0.431, 0.926 },
			{ 0, 7.364, 3.344 },
			GOLD,
			{ joint = "Tail", rot = { 57.465, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade6a",
			{ 0.168, 0.425, 0.699 },
			{ 0, 6.694, 3.074 },
			MAIN,
			{ joint = "Tail", rot = { -0.642, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade6b",
			{ 0.168, 0.425, 0.119 },
			{ 0, 6.698, 3.483 },
			MAIN,
			{ joint = "Tail", rot = { 179.358, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade7a",
			{ 0.168, 0.431, 0.926 },
			{ 0, 6.191, 3.03 },
			GOLD,
			{ joint = "Tail", rot = { -27.465, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade7b",
			{ 0.168, 0.431, 0.095 },
			{ 0, 6.427, 3.483 },
			GOLD,
			{ joint = "Tail", rot = { 152.535, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade8a",
			{ 0.168, 0.425, 0.699 },
			{ 0, 5.835, 3.418 },
			MAIN,
			{ joint = "Tail", rot = { -60.642, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade8b",
			{ 0.168, 0.425, 0.119 },
			{ 0, 6.191, 3.619 },
			MAIN,
			{ joint = "Tail", rot = { 119.358, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade9a",
			{ 0.168, 0.431, 0.095 },
			{ 0, 6.055, 3.854 },
			GOLD,
			{ joint = "Tail", rot = { -62.535, 180, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade9b",
			{ 0.168, 0.431, 0.926 },
			{ 0, 5.602, 3.619 },
			GOLD,
			{ joint = "Tail", rot = { -62.535, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade10a",
			{ 0.168, 0.425, 0.699 },
			{ 0, 5.704, 4.334 },
			MAIN,
			{ joint = "Tail", rot = { 59.358, 180, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade10b",
			{ 0.168, 0.425, 0.119 },
			{ 0, 6.055, 4.126 },
			MAIN,
			{ joint = "Tail", rot = { 59.358, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade11a",
			{ 0.168, 0.431, 0.095 },
			{ 0, 6.191, 4.361 },
			GOLD,
			{ joint = "Tail", rot = { 57.465, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade11b",
			{ 0.168, 0.431, 0.926 },
			{ 0, 5.761, 4.636 },
			GOLD,
			{ joint = "Tail", rot = { -122.535, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade12a",
			{ 0.168, 0.425, 0.119 },
			{ 0, 6.427, 4.497 },
			MAIN,
			{ joint = "Tail", rot = { 30.642, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"SunBlade12b",
			{ 0.168, 0.425, 0.699 },
			{ 0, 6.218, 4.849 },
			MAIN,
			{ joint = "Tail", rot = { -149.358, 0, 0 }, shape = "Wedge", studs = false }
		),
	},
}

return { egg = egg, pet = pet }
