--!strict
-- Honeyback Beetle (Zone 1 Meadow, Uncommon). Zone 1 Meadow roster (Config/Pets).
-- Pet: a dark brown beetle under a big round dome tiled with gold honeycomb cells (some glowing amber), white flowers
--      and leaves on the dome, gold hex plates on the thorax and head, glowing white eyes, yellow-tipped antennae, six
--      chunky legs with green leaf pads and yellow feet, two big amber wings raised behind. Joints: Body, Head,
--      AntennaL/R, ShellL/R, WingL/R, LegL1-3, LegR1-3.
-- Egg: a golden honeycomb egg glowing amber between the cells, white flowers and leaves at the base.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (zone1/honeyback_beetle.py,
-- zone1/eggs.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(107, 64, 34) -- #6B4022
local DARK = rgb(74, 44, 22) -- #4A2C16
local LIGHT = rgb(246, 227, 180) -- #F6E3B4
local GLOW = rgb(255, 176, 46) -- #FFB02E
local GOLD = rgb(247, 197, 49) -- #F7C531
local HONEY = rgb(247, 197, 49) -- #F7C531
local AMBER = rgb(255, 154, 28) -- #FF9A1C
local AMBER2 = rgb(242, 138, 16) -- #F28A10
local LEAF = rgb(95, 181, 68) -- #5FB544
local LEAF2 = rgb(62, 142, 52) -- #3E8E34
local FLOWER = rgb(255, 255, 255) -- #FFFFFF
local FLOWER2 = rgb(242, 242, 234) -- #F2F2EA
local POLLEN = rgb(255, 201, 60) -- #FFC93C
local HONEY2 = rgb(184, 115, 12) -- #B8730C
local YELLOW = rgb(245, 199, 46) -- #F5C72E
local LEAF3 = rgb(143, 212, 74) -- #8FD44A
local EYE = rgb(255, 248, 224) -- #FFF8E0
local GLASS = rgb(255, 176, 46) -- #FFB02E
local VEIN = rgb(217, 128, 15) -- #D9800F
local INK = rgb(26, 15, 8) -- #1A0F08
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.741, 0.525, 1.741 }, { 0, 0.262, 0 }, AMBER2, { joint = "Body" }),
		P("Shell2", { 2.72, 0.525, 2.72 }, { 0, 0.788, 0 }, AMBER, { joint = "Body" }),
		P("Shell3", { 3.126, 0.525, 3.126 }, { 0, 1.312, 0 }, AMBER2, { joint = "Body" }),
		P("Shell4", { 3.234, 0.525, 3.234 }, { 0, 1.837, 0 }, AMBER, { joint = "Body" }),
		P("Shell5", { 3.123, 0.525, 3.123 }, { 0, 2.362, 0 }, AMBER2, { joint = "Body" }),
		P("Shell6", { 2.814, 0.525, 2.814 }, { 0, 2.888, 0 }, AMBER, { joint = "Body" }),
		P("Shell7", { 2.282, 0.525, 2.282 }, { 0, 3.412, 0 }, AMBER2, { joint = "Body" }),
		P("Shell8", { 1.361, 0.525, 1.361 }, { 0, 3.938, 0 }, AMBER, { joint = "Body" }),
		P(
			"PlateHex11",
			{ 1.12, 0.646, 0.13 },
			{ -0.569, 1.25, -1.643 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex12",
			{ 1.12, 0.646, 0.13 },
			{ -0.569, 1.25, -1.643 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex13",
			{ 1.12, 0.646, 0.13 },
			{ -0.569, 1.25, -1.643 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex21",
			{ 1.12, 0.646, 0.13 },
			{ 0.569, 1.25, -1.643 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex22",
			{ 1.12, 0.646, 0.13 },
			{ 0.569, 1.25, -1.643 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex23",
			{ 1.12, 0.646, 0.13 },
			{ 0.569, 1.25, -1.643 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex31",
			{ 1.12, 0.646, 0.13 },
			{ 1.643, 1.25, -0.569 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex32",
			{ 1.12, 0.646, 0.13 },
			{ 1.643, 1.25, -0.569 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex33",
			{ 1.12, 0.646, 0.13 },
			{ 1.643, 1.25, -0.569 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex41",
			{ 1.12, 0.646, 0.13 },
			{ 1.643, 1.25, 0.569 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex42",
			{ 1.12, 0.646, 0.13 },
			{ 1.643, 1.25, 0.569 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex43",
			{ 1.12, 0.646, 0.13 },
			{ 1.643, 1.25, 0.569 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex4Core",
			{ 0.56, 0.323, 0.15 },
			{ 1.663, 1.25, 0.569 },
			AMBER,
			{ joint = "Body", rot = { 0, -90, 0 }, material = "Neon", studs = false }
		),
		P(
			"PlateHex51",
			{ 1.12, 0.646, 0.13 },
			{ 0.569, 1.25, 1.643 },
			HONEY,
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex52",
			{ 1.12, 0.646, 0.13 },
			{ 0.569, 1.25, 1.643 },
			HONEY,
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex53",
			{ 1.12, 0.646, 0.13 },
			{ 0.569, 1.25, 1.643 },
			HONEY,
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex61",
			{ 1.12, 0.646, 0.13 },
			{ -0.569, 1.25, 1.643 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex62",
			{ 1.12, 0.646, 0.13 },
			{ -0.569, 1.25, 1.643 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex63",
			{ 1.12, 0.646, 0.13 },
			{ -0.569, 1.25, 1.643 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex71",
			{ 1.12, 0.646, 0.13 },
			{ -1.643, 1.25, 0.569 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex72",
			{ 1.12, 0.646, 0.13 },
			{ -1.643, 1.25, 0.569 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex73",
			{ 1.12, 0.646, 0.13 },
			{ -1.643, 1.25, 0.569 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex81",
			{ 1.12, 0.646, 0.13 },
			{ -1.643, 1.25, -0.569 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex82",
			{ 1.12, 0.646, 0.13 },
			{ -1.643, 1.25, -0.569 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex83",
			{ 1.12, 0.646, 0.13 },
			{ -1.643, 1.25, -0.569 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex8Core",
			{ 0.56, 0.323, 0.15 },
			{ -1.663, 1.25, -0.569 },
			AMBER,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"PlateHex91",
			{ 1.12, 0.646, 0.13 },
			{ 0, 2.05, -1.697 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex92",
			{ 1.12, 0.646, 0.13 },
			{ 0, 2.05, -1.697 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex93",
			{ 1.12, 0.646, 0.13 },
			{ 0, 2.05, -1.697 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex101",
			{ 1.12, 0.646, 0.13 },
			{ 1.357, 2.05, -1.697 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex102",
			{ 1.12, 0.646, 0.13 },
			{ 1.357, 2.05, -1.697 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex103",
			{ 1.12, 0.646, 0.13 },
			{ 1.357, 2.05, -1.697 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex111",
			{ 1.12, 0.646, 0.13 },
			{ 1.697, 2.05, 0 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex112",
			{ 1.12, 0.646, 0.13 },
			{ 1.697, 2.05, 0 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex113",
			{ 1.12, 0.646, 0.13 },
			{ 1.697, 2.05, 0 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex121",
			{ 1.12, 0.646, 0.13 },
			{ 1.697, 2.05, 1.357 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex122",
			{ 1.12, 0.646, 0.13 },
			{ 1.697, 2.05, 1.357 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex123",
			{ 1.12, 0.646, 0.13 },
			{ 1.697, 2.05, 1.357 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex12Core",
			{ 0.56, 0.323, 0.15 },
			{ 1.717, 2.05, 1.357 },
			AMBER,
			{ joint = "Body", rot = { 0, -90, 0 }, material = "Neon", studs = false }
		),
		P(
			"PlateHex131",
			{ 1.12, 0.646, 0.13 },
			{ 0, 2.05, 1.697 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex132",
			{ 1.12, 0.646, 0.13 },
			{ 0, 2.05, 1.697 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex133",
			{ 1.12, 0.646, 0.13 },
			{ 0, 2.05, 1.697 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex141",
			{ 1.12, 0.646, 0.13 },
			{ -1.357, 2.05, 1.697 },
			HONEY,
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex142",
			{ 1.12, 0.646, 0.13 },
			{ -1.357, 2.05, 1.697 },
			HONEY,
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex143",
			{ 1.12, 0.646, 0.13 },
			{ -1.357, 2.05, 1.697 },
			HONEY,
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex151",
			{ 1.12, 0.646, 0.13 },
			{ -1.697, 2.05, 0 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex152",
			{ 1.12, 0.646, 0.13 },
			{ -1.697, 2.05, 0 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex153",
			{ 1.12, 0.646, 0.13 },
			{ -1.697, 2.05, 0 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex161",
			{ 1.12, 0.646, 0.13 },
			{ -1.697, 2.05, -1.357 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex162",
			{ 1.12, 0.646, 0.13 },
			{ -1.697, 2.05, -1.357 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex163",
			{ 1.12, 0.646, 0.13 },
			{ -1.697, 2.05, -1.357 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex16Core",
			{ 0.56, 0.323, 0.15 },
			{ -1.717, 2.05, -1.357 },
			AMBER,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"PlateHex171",
			{ 1.12, 0.646, 0.13 },
			{ -0.512, 2.85, -1.487 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex172",
			{ 1.12, 0.646, 0.13 },
			{ -0.512, 2.85, -1.487 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex173",
			{ 1.12, 0.646, 0.13 },
			{ -0.512, 2.85, -1.487 },
			HONEY,
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex181",
			{ 1.12, 0.646, 0.13 },
			{ 0.512, 2.85, -1.487 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex182",
			{ 1.12, 0.646, 0.13 },
			{ 0.512, 2.85, -1.487 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex183",
			{ 1.12, 0.646, 0.13 },
			{ 0.512, 2.85, -1.487 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex191",
			{ 1.12, 0.646, 0.13 },
			{ 1.487, 2.85, -0.512 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex192",
			{ 1.12, 0.646, 0.13 },
			{ 1.487, 2.85, -0.512 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex193",
			{ 1.12, 0.646, 0.13 },
			{ 1.487, 2.85, -0.512 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex201",
			{ 1.12, 0.646, 0.13 },
			{ 1.487, 2.85, 0.512 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex202",
			{ 1.12, 0.646, 0.13 },
			{ 1.487, 2.85, 0.512 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex203",
			{ 1.12, 0.646, 0.13 },
			{ 1.487, 2.85, 0.512 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex20Core",
			{ 0.56, 0.323, 0.15 },
			{ 1.507, 2.85, 0.512 },
			AMBER,
			{ joint = "Body", rot = { 0, -90, 0 }, material = "Neon", studs = false }
		),
		P(
			"PlateHex211",
			{ 1.12, 0.646, 0.13 },
			{ 0.512, 2.85, 1.487 },
			HONEY,
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex212",
			{ 1.12, 0.646, 0.13 },
			{ 0.512, 2.85, 1.487 },
			HONEY,
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex213",
			{ 1.12, 0.646, 0.13 },
			{ 0.512, 2.85, 1.487 },
			HONEY,
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex221",
			{ 1.12, 0.646, 0.13 },
			{ -0.512, 2.85, 1.487 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex222",
			{ 1.12, 0.646, 0.13 },
			{ -0.512, 2.85, 1.487 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex223",
			{ 1.12, 0.646, 0.13 },
			{ -0.512, 2.85, 1.487 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex231",
			{ 1.12, 0.646, 0.13 },
			{ -1.487, 2.85, 0.512 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex232",
			{ 1.12, 0.646, 0.13 },
			{ -1.487, 2.85, 0.512 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex233",
			{ 1.12, 0.646, 0.13 },
			{ -1.487, 2.85, 0.512 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex241",
			{ 1.12, 0.646, 0.13 },
			{ -1.487, 2.85, -0.512 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex242",
			{ 1.12, 0.646, 0.13 },
			{ -1.487, 2.85, -0.512 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex243",
			{ 1.12, 0.646, 0.13 },
			{ -1.487, 2.85, -0.512 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex24Core",
			{ 0.56, 0.323, 0.15 },
			{ -1.507, 2.85, -0.512 },
			AMBER,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"PlateHex251",
			{ 1.02, 0.589, 0.13 },
			{ 0, 3.6, -1.221 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"PlateHex252",
			{ 1.02, 0.589, 0.13 },
			{ 0, 3.6, -1.221 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"PlateHex253",
			{ 1.02, 0.589, 0.13 },
			{ 0, 3.6, -1.221 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"PlateHex261",
			{ 1.02, 0.589, 0.13 },
			{ 1.221, 3.6, 0 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"PlateHex262",
			{ 1.02, 0.589, 0.13 },
			{ 1.221, 3.6, 0 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"PlateHex263",
			{ 1.02, 0.589, 0.13 },
			{ 1.221, 3.6, 0 },
			HONEY,
			{ joint = "Body", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"PlateHex271",
			{ 1.02, 0.589, 0.13 },
			{ 0, 3.6, 1.221 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"PlateHex272",
			{ 1.02, 0.589, 0.13 },
			{ 0, 3.6, 1.221 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"PlateHex273",
			{ 1.02, 0.589, 0.13 },
			{ 0, 3.6, 1.221 },
			rgb(255, 217, 90),
			{ joint = "Body", rot = { 180, 0, -30 }, studs = false }
		),
		P(
			"PlateHex281",
			{ 1.02, 0.589, 0.13 },
			{ -1.221, 3.6, 0 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"PlateHex282",
			{ 1.02, 0.589, 0.13 },
			{ -1.221, 3.6, 0 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"PlateHex283",
			{ 1.02, 0.589, 0.13 },
			{ -1.221, 3.6, 0 },
			HONEY,
			{ joint = "Body", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"PlateHex28Core",
			{ 0.51, 0.294, 0.15 },
			{ -1.241, 3.6, 0 },
			AMBER,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P("CapHex", { 0.7, 0.18, 0.4 }, { 0, 4.2, 0 }, HONEY, { joint = "Body", studs = false }),
		P("CapHex2", { 0.7, 0.18, 0.4 }, { 0, 4.2, 0 }, HONEY, { joint = "Body", rot = { 0, 60, 0 }, studs = false }),
		P("CapHex3", { 0.7, 0.18, 0.4 }, { 0, 4.2, 0 }, HONEY, { joint = "Body", rot = { 0, 120, 0 }, studs = false }),
		P(
			"BaseLeaf1",
			{ 0.5, 0.756, 0.12 },
			{ 0.364, 0.863, -1.961 },
			LEAF2,
			{ joint = "Body", rot = { -72.646, -180, 0 }, studs = false }
		),
		P(
			"BaseLeaf1Tip",
			{ 0.354, 0.354, 0.115 },
			{ 0.364, 0.975, -2.322 },
			LEAF2,
			{ joint = "Body", rot = { 107.354, 0, -135 }, studs = false }
		),
		P(
			"BaseFlower1Petal1",
			{ 0.345, 0.1, 0.375 },
			{ 0.364, 0.866, -2.129 },
			FLOWER2,
			{ joint = "Body", rot = { -55.008, 0, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal2",
			{ 0.345, 0.1, 0.375 },
			{ 0.578, 0.993, -2.04 },
			GLINT,
			{ joint = "Body", rot = { -55.008, -72, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal3",
			{ 0.345, 0.1, 0.375 },
			{ 0.497, 1.199, -1.896 },
			FLOWER2,
			{ joint = "Body", rot = { -55.008, -144, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal4",
			{ 0.345, 0.1, 0.375 },
			{ 0.232, 1.199, -1.896 },
			GLINT,
			{ joint = "Body", rot = { -55.008, 144, 0 }, studs = false }
		),
		P(
			"BaseFlower1Petal5",
			{ 0.345, 0.1, 0.375 },
			{ 0.15, 0.993, -2.04 },
			FLOWER2,
			{ joint = "Body", rot = { -55.008, 72, 0 }, studs = false }
		),
		P(
			"BaseFlower1Centre",
			{ 0.255, 0.14, 0.255 },
			{ 0.364, 1.067, -2.025 },
			POLLEN,
			{ joint = "Body", rot = { -55.008, 45, 0 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf2",
			{ 0.5, 0.756, 0.12 },
			{ 1.961, 0.863, -0.364 },
			LEAF,
			{ joint = "Body", rot = { 90, 17.354, -90 }, studs = false }
		),
		P(
			"BaseLeaf2Tip",
			{ 0.354, 0.354, 0.115 },
			{ 2.322, 0.975, -0.364 },
			LEAF,
			{ joint = "Body", rot = { 90, 17.354, -45 }, studs = false }
		),
		P(
			"BaseLeaf3",
			{ 0.5, 0.756, 0.12 },
			{ 1.16, 0.863, 1.961 },
			LEAF2,
			{ joint = "Body", rot = { 72.646, 0, 0 }, studs = false }
		),
		P(
			"BaseLeaf3Tip",
			{ 0.354, 0.354, 0.115 },
			{ 1.16, 0.975, 2.322 },
			LEAF2,
			{ joint = "Body", rot = { 72.646, 0, 45 }, studs = false }
		),
		P(
			"BaseFlower2Petal1",
			{ 0.345, 0.1, 0.375 },
			{ 1.16, 0.866, 2.129 },
			FLOWER2,
			{ joint = "Body", rot = { 55.008, 180, 0 }, studs = false }
		),
		P(
			"BaseFlower2Petal2",
			{ 0.345, 0.1, 0.375 },
			{ 0.946, 0.993, 2.04 },
			GLINT,
			{ joint = "Body", rot = { 55.008, 108, 0 }, studs = false }
		),
		P(
			"BaseFlower2Petal3",
			{ 0.345, 0.1, 0.375 },
			{ 1.028, 1.199, 1.896 },
			FLOWER2,
			{ joint = "Body", rot = { 55.008, 36, 0 }, studs = false }
		),
		P(
			"BaseFlower2Petal4",
			{ 0.345, 0.1, 0.375 },
			{ 1.292, 1.199, 1.896 },
			GLINT,
			{ joint = "Body", rot = { 55.008, -36, 0 }, studs = false }
		),
		P(
			"BaseFlower2Petal5",
			{ 0.345, 0.1, 0.375 },
			{ 1.374, 0.993, 2.04 },
			FLOWER2,
			{ joint = "Body", rot = { 55.008, -108, 0 }, studs = false }
		),
		P(
			"BaseFlower2Centre",
			{ 0.255, 0.14, 0.255 },
			{ 1.16, 1.067, 2.025 },
			POLLEN,
			{ joint = "Body", rot = { 55.008, -135, 0 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf4",
			{ 0.5, 0.756, 0.12 },
			{ -0.364, 0.863, 1.961 },
			LEAF,
			{ joint = "Body", rot = { 72.646, 0, 0 }, studs = false }
		),
		P(
			"BaseLeaf4Tip",
			{ 0.354, 0.354, 0.115 },
			{ -0.364, 0.975, 2.322 },
			LEAF,
			{ joint = "Body", rot = { 72.646, 0, 45 }, studs = false }
		),
		P(
			"BaseLeaf5",
			{ 0.5, 0.756, 0.12 },
			{ -1.961, 0.863, 0.364 },
			LEAF2,
			{ joint = "Body", rot = { 90, -17.354, 90 }, studs = false }
		),
		P(
			"BaseLeaf5Tip",
			{ 0.354, 0.354, 0.115 },
			{ -2.322, 0.975, 0.364 },
			LEAF2,
			{ joint = "Body", rot = { 90, -17.354, 135 }, studs = false }
		),
		P(
			"BaseFlower3Petal1",
			{ 0.345, 0.1, 0.375 },
			{ -2.129, 0.866, 0.364 },
			FLOWER2,
			{ joint = "Body", rot = { -90, 34.992, 90 }, studs = false }
		),
		P(
			"BaseFlower3Petal2",
			{ 0.345, 0.1, 0.375 },
			{ -2.04, 0.993, 0.15 },
			GLINT,
			{ joint = "Body", rot = { -14.906, 10.207, 56.347 }, studs = false }
		),
		P(
			"BaseFlower3Petal3",
			{ 0.345, 0.1, 0.375 },
			{ -1.896, 1.199, 0.232 },
			FLOWER2,
			{ joint = "Body", rot = { 48.432, -27.642, 67.635 }, studs = false }
		),
		P(
			"BaseFlower3Petal4",
			{ 0.345, 0.1, 0.375 },
			{ -1.896, 1.199, 0.497 },
			GLINT,
			{ joint = "Body", rot = { -48.432, -152.358, -67.635 }, studs = false }
		),
		P(
			"BaseFlower3Petal5",
			{ 0.345, 0.1, 0.375 },
			{ -2.04, 0.993, 0.578 },
			FLOWER2,
			{ joint = "Body", rot = { 14.906, 169.793, -56.347 }, studs = false }
		),
		P(
			"BaseFlower3Centre",
			{ 0.255, 0.14, 0.255 },
			{ -2.025, 1.067, 0.364 },
			POLLEN,
			{ joint = "Body", rot = { 39.325, 156.078, -63.666 }, material = "Neon", studs = false }
		),
		P(
			"BaseLeaf6",
			{ 0.5, 0.756, 0.12 },
			{ -1.16, 0.863, -1.961 },
			LEAF,
			{ joint = "Body", rot = { -72.646, -180, 0 }, studs = false }
		),
		P(
			"BaseLeaf6Tip",
			{ 0.354, 0.354, 0.115 },
			{ -1.16, 0.975, -2.322 },
			LEAF,
			{ joint = "Body", rot = { 107.354, 0, -135 }, studs = false }
		),
		P(
			"SideFlowerPetal1",
			{ 0.285, 0.1, 0.31 },
			{ -0.589, 1.822, 1.891 },
			FLOWER2,
			{ joint = "Body", rot = { 73.301, 180, 0 }, studs = false }
		),
		P(
			"SideFlowerPetal2",
			{ 0.285, 0.1, 0.31 },
			{ -0.766, 1.945, 1.854 },
			GLINT,
			{ joint = "Body", rot = { 73.301, 108, 0 }, studs = false }
		),
		P(
			"SideFlowerPetal3",
			{ 0.285, 0.1, 0.31 },
			{ -0.698, 2.144, 1.794 },
			FLOWER2,
			{ joint = "Body", rot = { 73.301, 36, 0 }, studs = false }
		),
		P(
			"SideFlowerPetal4",
			{ 0.285, 0.1, 0.31 },
			{ -0.479, 2.144, 1.794 },
			GLINT,
			{ joint = "Body", rot = { 73.301, -36, 0 }, studs = false }
		),
		P(
			"SideFlowerPetal5",
			{ 0.285, 0.1, 0.31 },
			{ -0.412, 1.945, 1.854 },
			FLOWER2,
			{ joint = "Body", rot = { 73.301, -108, 0 }, studs = false }
		),
		P(
			"SideFlowerCentre",
			{ 0.211, 0.14, 0.211 },
			{ -0.589, 2.009, 1.866 },
			POLLEN,
			{ joint = "Body", rot = { 73.301, -135, 0 }, material = "Neon", studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P(
			"HingeBody",
			{ 0.22, 0.22, 0.22 },
			{ 0, 1.65, 0.33 },
			MAIN,
			{ joint = "Body", transparency = 1, studs = false }
		),
		P("Underbody", { 3.19, 0.99, 4.07 }, { 0, 1.54, 0.495 }, DARK, { joint = "Body" }),
		P("Belly", { 2.42, 0.33, 3.3 }, { 0, 0.99, 0.55 }, MAIN, { joint = "Body", studs = false }),
		P("Thorax", { 2.31, 1.265, 1.21 }, { 0, 1.925, -1.76 }, MAIN, { joint = "Body" }),
		P(
			"ThoraxHex1",
			{ 0.99, 0.571, 0.22 },
			{ 0, 2.574, -1.76 },
			HONEY,
			{ joint = "Body", rot = { -98.531, 0, 0 }, studs = false }
		),
		P(
			"ThoraxHex2",
			{ 0.99, 0.571, 0.22 },
			{ 0, 2.574, -1.76 },
			HONEY,
			{ joint = "Body", rot = { -98.531, 0, 60 }, studs = false }
		),
		P(
			"ThoraxHex3",
			{ 0.99, 0.571, 0.22 },
			{ 0, 2.574, -1.76 },
			HONEY,
			{ joint = "Body", rot = { -98.531, 0, 120 }, studs = false }
		),
		P(
			"ThoraxHexCore",
			{ 0.495, 0.286, 0.165 },
			{ 0, 2.596, -1.763 },
			AMBER,
			{ joint = "Body", rot = { -98.531, 0, 90 }, material = "Neon", studs = false }
		),
		P(
			"HingeShellL",
			{ 0.22, 0.22, 0.22 },
			{ -0.33, 3.52, -0.44 },
			MAIN,
			{ joint = "ShellL", transparency = 1, studs = false }
		),
		P(
			"DomeL1",
			{ 3.3, 3.3, 3.3 },
			{ -0.495, 2.145, 0 },
			HONEY2,
			{ joint = "ShellL", shape = "Ball", studs = false }
		),
		P(
			"DomeL2",
			{ 3.3, 3.3, 3.3 },
			{ -0.495, 2.145, 0.99 },
			HONEY2,
			{ joint = "ShellL", shape = "Ball", studs = false }
		),
		P(
			"CombL11",
			{ 1.078, 0.622, 0.22 },
			{ 0, 2.563, 2.625 },
			HONEY,
			{ joint = "ShellL", rot = { -14.971, 0, 0 }, studs = false }
		),
		P(
			"CombL12",
			{ 1.078, 0.622, 0.22 },
			{ 0, 2.563, 2.625 },
			HONEY,
			{ joint = "ShellL", rot = { -14.971, 0, 60 }, studs = false }
		),
		P(
			"CombL13",
			{ 1.078, 0.622, 0.22 },
			{ 0, 2.563, 2.625 },
			HONEY,
			{ joint = "ShellL", rot = { -14.971, 0, 120 }, studs = false }
		),
		P(
			"CombL21",
			{ 1.078, 0.622, 0.22 },
			{ -1.065, 2.563, 2.34 },
			HONEY,
			{ joint = "ShellL", rot = { -17.16, -28.883, -8.483 }, studs = false }
		),
		P(
			"CombL22",
			{ 1.078, 0.622, 0.22 },
			{ -1.065, 2.563, 2.34 },
			HONEY,
			{ joint = "ShellL", rot = { -17.16, -28.883, 51.517 }, studs = false }
		),
		P(
			"CombL23",
			{ 1.078, 0.622, 0.22 },
			{ -1.065, 2.563, 2.34 },
			HONEY,
			{ joint = "ShellL", rot = { -17.16, -28.883, 111.517 }, studs = false }
		),
		P(
			"CombL31",
			{ 1.078, 0.622, 0.22 },
			{ -1.845, 2.563, 1.56 },
			HONEY,
			{ joint = "ShellL", rot = { -28.139, -56.786, -24.106 }, studs = false }
		),
		P(
			"CombL32",
			{ 1.078, 0.622, 0.22 },
			{ -1.845, 2.563, 1.56 },
			HONEY,
			{ joint = "ShellL", rot = { -28.139, -56.786, 35.894 }, studs = false }
		),
		P(
			"CombL33",
			{ 1.078, 0.622, 0.22 },
			{ -1.845, 2.563, 1.56 },
			HONEY,
			{ joint = "ShellL", rot = { -28.139, -56.786, 95.894 }, studs = false }
		),
		P(
			"CombL3Core",
			{ 0.539, 0.311, 0.165 },
			{ -1.863, 2.569, 1.571 },
			AMBER,
			{ joint = "ShellL", rot = { -28.139, -56.786, 65.894 }, material = "Neon", studs = false }
		),
		P(
			"CombL41",
			{ 1.078, 0.622, 0.22 },
			{ -2.13, 2.563, 0.495 },
			HONEY,
			{ joint = "ShellL", rot = { -90, -75.029, -90 }, studs = false }
		),
		P(
			"CombL42",
			{ 1.078, 0.622, 0.22 },
			{ -2.13, 2.563, 0.495 },
			HONEY,
			{ joint = "ShellL", rot = { -90, -75.029, -30 }, studs = false }
		),
		P(
			"CombL43",
			{ 1.078, 0.622, 0.22 },
			{ -2.13, 2.563, 0.495 },
			HONEY,
			{ joint = "ShellL", rot = { -90, -75.029, 30 }, studs = false }
		),
		P(
			"CombL51",
			{ 1.078, 0.622, 0.22 },
			{ -1.845, 2.563, -0.57 },
			HONEY,
			{ joint = "ShellL", rot = { 28.139, -123.214, 24.106 }, studs = false }
		),
		P(
			"CombL52",
			{ 1.078, 0.622, 0.22 },
			{ -1.845, 2.563, -0.57 },
			HONEY,
			{ joint = "ShellL", rot = { 28.139, -123.214, 84.106 }, studs = false }
		),
		P(
			"CombL53",
			{ 1.078, 0.622, 0.22 },
			{ -1.845, 2.563, -0.57 },
			HONEY,
			{ joint = "ShellL", rot = { -151.861, -56.786, -35.894 }, studs = false }
		),
		P(
			"CombL61",
			{ 1.078, 0.622, 0.22 },
			{ -1.065, 2.563, -1.35 },
			HONEY,
			{ joint = "ShellL", rot = { 17.16, -151.117, 8.483 }, studs = false }
		),
		P(
			"CombL62",
			{ 1.078, 0.622, 0.22 },
			{ -1.065, 2.563, -1.35 },
			HONEY,
			{ joint = "ShellL", rot = { 17.16, -151.117, 68.483 }, studs = false }
		),
		P(
			"CombL63",
			{ 1.078, 0.622, 0.22 },
			{ -1.065, 2.563, -1.35 },
			HONEY,
			{ joint = "ShellL", rot = { -162.84, -28.883, -51.517 }, studs = false }
		),
		P(
			"CombL6Core",
			{ 0.539, 0.311, 0.165 },
			{ -1.076, 2.569, -1.368 },
			AMBER,
			{ joint = "ShellL", rot = { 17.16, -151.117, 98.483 }, material = "Neon", studs = false }
		),
		P(
			"CombL71",
			{ 1.045, 0.603, 0.22 },
			{ -0.551, 3.2, 2.19 },
			HONEY,
			{ joint = "ShellL", rot = { -42.807, -13.408, -12.122 }, studs = false }
		),
		P(
			"CombL72",
			{ 1.045, 0.603, 0.22 },
			{ -0.551, 3.2, 2.19 },
			HONEY,
			{ joint = "ShellL", rot = { -42.807, -13.408, 47.878 }, studs = false }
		),
		P(
			"CombL73",
			{ 1.045, 0.603, 0.22 },
			{ -0.551, 3.2, 2.19 },
			HONEY,
			{ joint = "ShellL", rot = { -42.807, -13.408, 107.878 }, studs = false }
		),
		P(
			"CombL81",
			{ 1.045, 0.603, 0.22 },
			{ -1.442, 3.2, 1.542 },
			HONEY,
			{ joint = "ShellL", rot = { -56.287, -37.378, -42.296 }, studs = false }
		),
		P(
			"CombL82",
			{ 1.045, 0.603, 0.22 },
			{ -1.442, 3.2, 1.542 },
			HONEY,
			{ joint = "ShellL", rot = { -56.287, -37.378, 17.704 }, studs = false }
		),
		P(
			"CombL83",
			{ 1.045, 0.603, 0.22 },
			{ -1.442, 3.2, 1.542 },
			HONEY,
			{ joint = "ShellL", rot = { -56.287, -37.378, 77.704 }, studs = false }
		),
		P(
			"CombL91",
			{ 1.045, 0.603, 0.22 },
			{ -1.782, 3.2, 0.495 },
			HONEY,
			{ joint = "ShellL", rot = { -90, -48.623, -90 }, studs = false }
		),
		P(
			"CombL92",
			{ 1.045, 0.603, 0.22 },
			{ -1.782, 3.2, 0.495 },
			HONEY,
			{ joint = "ShellL", rot = { -90, -48.623, -30 }, studs = false }
		),
		P(
			"CombL93",
			{ 1.045, 0.603, 0.22 },
			{ -1.782, 3.2, 0.495 },
			HONEY,
			{ joint = "ShellL", rot = { -90, -48.623, 30 }, studs = false }
		),
		P(
			"CombL9Core",
			{ 0.523, 0.301, 0.165 },
			{ -1.798, 3.214, 0.495 },
			AMBER,
			{ joint = "ShellL", rot = { -90, -48.623, 0 }, material = "Neon", studs = false }
		),
		P(
			"CombL101",
			{ 1.045, 0.603, 0.22 },
			{ -1.442, 3.2, -0.552 },
			HONEY,
			{ joint = "ShellL", rot = { 56.287, -142.622, 42.296 }, studs = false }
		),
		P(
			"CombL102",
			{ 1.045, 0.603, 0.22 },
			{ -1.442, 3.2, -0.552 },
			HONEY,
			{ joint = "ShellL", rot = { -123.713, -37.378, -77.704 }, studs = false }
		),
		P(
			"CombL103",
			{ 1.045, 0.603, 0.22 },
			{ -1.442, 3.2, -0.552 },
			HONEY,
			{ joint = "ShellL", rot = { -123.713, -37.378, -17.704 }, studs = false }
		),
		P(
			"CombL111",
			{ 0.968, 0.559, 0.22 },
			{ -1.154, 3.659, 0.758 },
			HONEY,
			{ joint = "ShellL", rot = { -83.447, -26.564, -75.595 }, studs = false }
		),
		P(
			"CombL112",
			{ 0.968, 0.559, 0.22 },
			{ -1.154, 3.659, 0.758 },
			HONEY,
			{ joint = "ShellL", rot = { -83.447, -26.564, -15.595 }, studs = false }
		),
		P(
			"CombL113",
			{ 0.968, 0.559, 0.22 },
			{ -1.154, 3.659, 0.758 },
			HONEY,
			{ joint = "ShellL", rot = { -83.447, -26.564, 44.405 }, studs = false }
		),
		P(
			"CombL121",
			{ 0.968, 0.559, 0.22 },
			{ -0.925, 3.659, -0.243 },
			HONEY,
			{ joint = "ShellL", rot = { -107.84, -21.015, -131.906 }, studs = false }
		),
		P(
			"CombL122",
			{ 0.968, 0.559, 0.22 },
			{ -0.925, 3.659, -0.243 },
			HONEY,
			{ joint = "ShellL", rot = { -107.84, -21.015, -71.906 }, studs = false }
		),
		P(
			"CombL123",
			{ 0.968, 0.559, 0.22 },
			{ -0.925, 3.659, -0.243 },
			HONEY,
			{ joint = "ShellL", rot = { -107.84, -21.015, -11.906 }, studs = false }
		),
		P(
			"CombL12Core",
			{ 0.484, 0.279, 0.165 },
			{ -0.933, 3.679, -0.249 },
			AMBER,
			{ joint = "ShellL", rot = { -107.84, -21.015, -41.906 }, material = "Neon", studs = false }
		),
		P(
			"CombL131",
			{ 0.814, 0.47, 0.22 },
			{ -0.371, 3.887, 0.866 },
			HONEY,
			{ joint = "ShellL", rot = { -82.023, -7.901, -44.448 }, studs = false }
		),
		P(
			"CombL132",
			{ 0.814, 0.47, 0.22 },
			{ -0.371, 3.887, 0.866 },
			HONEY,
			{ joint = "ShellL", rot = { -82.023, -7.901, 15.552 }, studs = false }
		),
		P(
			"CombL133",
			{ 0.814, 0.47, 0.22 },
			{ -0.371, 3.887, 0.866 },
			HONEY,
			{ joint = "ShellL", rot = { -82.023, -7.901, 75.552 }, studs = false }
		),
		P(
			"CombL141",
			{ 0.814, 0.47, 0.22 },
			{ -0.371, 3.887, 0.124 },
			HONEY,
			{ joint = "ShellL", rot = { -97.977, -7.901, -135.552 }, studs = false }
		),
		P(
			"CombL142",
			{ 0.814, 0.47, 0.22 },
			{ -0.371, 3.887, 0.124 },
			HONEY,
			{ joint = "ShellL", rot = { -97.977, -7.901, -75.552 }, studs = false }
		),
		P(
			"CombL143",
			{ 0.814, 0.47, 0.22 },
			{ -0.371, 3.887, 0.124 },
			HONEY,
			{ joint = "ShellL", rot = { -97.977, -7.901, -15.552 }, studs = false }
		),
		P(
			"FlowerL1Petal1",
			{ 0.43, 0.11, 0.467 },
			{ -0.87, 3.411, -1.012 },
			FLOWER2,
			{ joint = "ShellL", rot = { -39.571, 23.991, 18.573 }, studs = false }
		),
		P(
			"FlowerL1Petal2",
			{ 0.43, 0.11, 0.468 },
			{ -0.56, 3.524, -1.009 },
			GLINT,
			{ joint = "ShellL", rot = { -14.546, -44.266, 23.977 }, studs = false }
		),
		P(
			"FlowerL1Petal3",
			{ 0.43, 0.11, 0.468 },
			{ -0.521, 3.706, -0.737 },
			FLOWER2,
			{ joint = "ShellL", rot = { -59.636, -123.073, -32.226 }, studs = false }
		),
		P(
			"FlowerL1Petal4",
			{ 0.43, 0.11, 0.468 },
			{ -0.807, 3.706, -0.572 },
			GLINT,
			{ joint = "ShellL", rot = { -28.599, 169.625, -17.208 }, studs = false }
		),
		P(
			"FlowerL1Petal5",
			{ 0.43, 0.11, 0.468 },
			{ -1.022, 3.524, -0.742 },
			FLOWER2,
			{ joint = "ShellL", rot = { 34.89, 108.326, -67.746 }, studs = false }
		),
		P(
			"FlowerL1Centre",
			{ 0.318, 0.154, 0.318 },
			{ -0.766, 3.601, -0.831 },
			POLLEN,
			{ joint = "ShellL", rot = { -70.663, 64.142, 41.853 }, material = "Neon", studs = false }
		),
		P(
			"FlowerLeafL1_1",
			{ 0.462, 0.693, 0.11 },
			{ -0.472, 3.472, -0.614 },
			LEAF3,
			{ joint = "ShellL", rot = { -100.481, 22.93, -119.471 }, studs = false }
		),
		P(
			"FlowerLeafL1_1Tip",
			{ 0.327, 0.327, 0.106 },
			{ -0.194, 3.387, -0.425 },
			LEAF3,
			{ joint = "ShellL", rot = { -100.481, 22.93, -74.471 }, studs = false }
		),
		P(
			"FlowerLeafL1_2",
			{ 0.462, 0.693, 0.11 },
			{ -1.08, 3.481, -0.732 },
			LEAF,
			{ joint = "ShellL", rot = { -121.782, -17.067, 93.526 }, studs = false }
		),
		P(
			"FlowerLeafL1_2Tip",
			{ 0.327, 0.327, 0.106 },
			{ -1.411, 3.406, -0.66 },
			LEAF,
			{ joint = "ShellL", rot = { 58.218, -162.933, -41.474 }, studs = false }
		),
		P(
			"FlowerL3Petal1",
			{ 0.43, 0.11, 0.468 },
			{ -0.83, 3.639, 1.68 },
			FLOWER2,
			{ joint = "ShellL", rot = { 31.23, 149.089, -17.301 }, studs = false }
		),
		P(
			"FlowerL3Petal2",
			{ 0.43, 0.11, 0.468 },
			{ -0.949, 3.726, 1.385 },
			GLINT,
			{ joint = "ShellL", rot = { -23.325, 69.686, 47.302 }, studs = false }
		),
		P(
			"FlowerL3Petal3",
			{ 0.43, 0.11, 0.468 },
			{ -0.704, 3.865, 1.213 },
			FLOWER2,
			{ joint = "ShellL", rot = { 21.141, 3.778, 14.815 }, studs = false }
		),
		P(
			"FlowerL3Petal4",
			{ 0.43, 0.11, 0.468 },
			{ -0.434, 3.865, 1.402 },
			GLINT,
			{ joint = "ShellL", rot = { 54.533, -63.777, 35.27 }, studs = false }
		),
		P(
			"FlowerL3Petal5",
			{ 0.43, 0.11, 0.468 },
			{ -0.512, 3.726, 1.691 },
			FLOWER2,
			{ joint = "ShellL", rot = { 10.094, -141.661, -18.984 }, studs = false }
		),
		P(
			"FlowerL3Centre",
			{ 0.318, 0.154, 0.318 },
			{ -0.694, 3.794, 1.486 },
			POLLEN,
			{ joint = "ShellL", rot = { 18.793, -167.527, -15.148 }, material = "Neon", studs = false }
		),
		P(
			"FlowerLeafL3_1",
			{ 0.462, 0.693, 0.11 },
			{ -0.457, 3.689, 1.726 },
			LEAF3,
			{ joint = "ShellL", rot = { -66.269, -13.431, -138.61 }, studs = false }
		),
		P(
			"FlowerLeafL3_1Tip",
			{ 0.327, 0.327, 0.106 },
			{ -0.234, 3.633, 1.985 },
			LEAF3,
			{ joint = "ShellL", rot = { -66.269, -13.431, -93.61 }, studs = false }
		),
		P(
			"FlowerLeafL3_2",
			{ 0.462, 0.693, 0.11 },
			{ -0.972, 3.688, 1.643 },
			LEAF,
			{ joint = "ShellL", rot = { -75.964, -2.381, 122.353 }, studs = false }
		),
		P(
			"FlowerLeafL3_2Tip",
			{ 0.327, 0.327, 0.106 },
			{ -1.265, 3.631, 1.82 },
			LEAF,
			{ joint = "ShellL", rot = { -75.964, -2.381, 167.353 }, studs = false }
		),
		P(
			"HingeShellR",
			{ 0.22, 0.22, 0.22 },
			{ 0.33, 3.52, -0.44 },
			MAIN,
			{ joint = "ShellR", transparency = 1, studs = false }
		),
		P(
			"DomeR1",
			{ 3.3, 3.3, 3.3 },
			{ 0.495, 2.145, 0 },
			HONEY2,
			{ joint = "ShellR", shape = "Ball", studs = false }
		),
		P(
			"DomeR2",
			{ 3.3, 3.3, 3.3 },
			{ 0.495, 2.145, 0.99 },
			HONEY2,
			{ joint = "ShellR", shape = "Ball", studs = false }
		),
		P(
			"CombR11",
			{ 1.078, 0.622, 0.22 },
			{ 1.065, 2.563, -1.35 },
			HONEY,
			{ joint = "ShellR", rot = { 17.16, 151.117, -8.483 }, studs = false }
		),
		P(
			"CombR12",
			{ 1.078, 0.622, 0.22 },
			{ 1.065, 2.563, -1.35 },
			HONEY,
			{ joint = "ShellR", rot = { 17.16, 151.117, 51.517 }, studs = false }
		),
		P(
			"CombR13",
			{ 1.078, 0.622, 0.22 },
			{ 1.065, 2.563, -1.35 },
			HONEY,
			{ joint = "ShellR", rot = { -162.84, 28.883, -68.483 }, studs = false }
		),
		P(
			"CombR21",
			{ 1.078, 0.622, 0.22 },
			{ 1.845, 2.563, -0.57 },
			HONEY,
			{ joint = "ShellR", rot = { 28.139, 123.214, -24.106 }, studs = false }
		),
		P(
			"CombR22",
			{ 1.078, 0.622, 0.22 },
			{ 1.845, 2.563, -0.57 },
			HONEY,
			{ joint = "ShellR", rot = { 28.139, 123.214, 35.894 }, studs = false }
		),
		P(
			"CombR23",
			{ 1.078, 0.622, 0.22 },
			{ 1.845, 2.563, -0.57 },
			HONEY,
			{ joint = "ShellR", rot = { 28.139, 123.214, 95.894 }, studs = false }
		),
		P(
			"CombR31",
			{ 1.078, 0.622, 0.22 },
			{ 2.13, 2.563, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { -90, 75.029, 90 }, studs = false }
		),
		P(
			"CombR32",
			{ 1.078, 0.622, 0.22 },
			{ 2.13, 2.563, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { 90, 104.971, -30 }, studs = false }
		),
		P(
			"CombR33",
			{ 1.078, 0.622, 0.22 },
			{ 2.13, 2.563, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { 90, 104.971, 30 }, studs = false }
		),
		P(
			"CombR3Core",
			{ 0.539, 0.311, 0.165 },
			{ 2.151, 2.569, 0.495 },
			AMBER,
			{ joint = "ShellR", rot = { 90, 104.971, 0 }, material = "Neon", studs = false }
		),
		P(
			"CombR41",
			{ 1.078, 0.622, 0.22 },
			{ 1.845, 2.563, 1.56 },
			HONEY,
			{ joint = "ShellR", rot = { -28.139, 56.786, 24.106 }, studs = false }
		),
		P(
			"CombR42",
			{ 1.078, 0.622, 0.22 },
			{ 1.845, 2.563, 1.56 },
			HONEY,
			{ joint = "ShellR", rot = { -28.139, 56.786, 84.106 }, studs = false }
		),
		P(
			"CombR43",
			{ 1.078, 0.622, 0.22 },
			{ 1.845, 2.563, 1.56 },
			HONEY,
			{ joint = "ShellR", rot = { -28.139, 56.786, 144.106 }, studs = false }
		),
		P(
			"CombR51",
			{ 1.078, 0.622, 0.22 },
			{ 1.065, 2.563, 2.34 },
			HONEY,
			{ joint = "ShellR", rot = { -17.16, 28.883, 8.483 }, studs = false }
		),
		P(
			"CombR52",
			{ 1.078, 0.622, 0.22 },
			{ 1.065, 2.563, 2.34 },
			HONEY,
			{ joint = "ShellR", rot = { -17.16, 28.883, 68.483 }, studs = false }
		),
		P(
			"CombR53",
			{ 1.078, 0.622, 0.22 },
			{ 1.065, 2.563, 2.34 },
			HONEY,
			{ joint = "ShellR", rot = { -17.16, 28.883, 128.483 }, studs = false }
		),
		P(
			"CombR61",
			{ 1.045, 0.603, 0.22 },
			{ 0.551, 3.2, -1.2 },
			HONEY,
			{ joint = "ShellR", rot = { 42.807, 166.592, -12.122 }, studs = false }
		),
		P(
			"CombR62",
			{ 1.045, 0.603, 0.22 },
			{ 0.551, 3.2, -1.2 },
			HONEY,
			{ joint = "ShellR", rot = { 42.807, 166.592, 47.878 }, studs = false }
		),
		P(
			"CombR63",
			{ 1.045, 0.603, 0.22 },
			{ 0.551, 3.2, -1.2 },
			HONEY,
			{ joint = "ShellR", rot = { -137.193, 13.408, -72.122 }, studs = false }
		),
		P(
			"CombR6Core",
			{ 0.523, 0.301, 0.165 },
			{ 0.556, 3.214, -1.215 },
			AMBER,
			{ joint = "ShellR", rot = { -137.193, 13.408, -102.122 }, material = "Neon", studs = false }
		),
		P(
			"CombR71",
			{ 1.045, 0.603, 0.22 },
			{ 1.442, 3.2, -0.552 },
			HONEY,
			{ joint = "ShellR", rot = { 56.287, 142.622, -42.296 }, studs = false }
		),
		P(
			"CombR72",
			{ 1.045, 0.603, 0.22 },
			{ 1.442, 3.2, -0.552 },
			HONEY,
			{ joint = "ShellR", rot = { 56.287, 142.622, 17.704 }, studs = false }
		),
		P(
			"CombR73",
			{ 1.045, 0.603, 0.22 },
			{ 1.442, 3.2, -0.552 },
			HONEY,
			{ joint = "ShellR", rot = { -123.713, 37.378, -102.296 }, studs = false }
		),
		P(
			"CombR81",
			{ 1.045, 0.603, 0.22 },
			{ 1.782, 3.2, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { -90, 48.623, 90 }, studs = false }
		),
		P(
			"CombR82",
			{ 1.045, 0.603, 0.22 },
			{ 1.782, 3.2, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { 90, 131.377, -30 }, studs = false }
		),
		P(
			"CombR83",
			{ 1.045, 0.603, 0.22 },
			{ 1.782, 3.2, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { 90, 131.377, 30 }, studs = false }
		),
		P(
			"CombR91",
			{ 1.045, 0.603, 0.22 },
			{ 0.551, 3.2, 2.19 },
			HONEY,
			{ joint = "ShellR", rot = { -42.807, 13.408, 12.122 }, studs = false }
		),
		P(
			"CombR92",
			{ 1.045, 0.603, 0.22 },
			{ 0.551, 3.2, 2.19 },
			HONEY,
			{ joint = "ShellR", rot = { -42.807, 13.408, 72.122 }, studs = false }
		),
		P(
			"CombR93",
			{ 1.045, 0.603, 0.22 },
			{ 0.551, 3.2, 2.19 },
			HONEY,
			{ joint = "ShellR", rot = { -42.807, 13.408, 132.122 }, studs = false }
		),
		P(
			"CombR9Core",
			{ 0.523, 0.301, 0.165 },
			{ 0.556, 3.214, 2.205 },
			AMBER,
			{ joint = "ShellR", rot = { -42.807, 13.408, 102.122 }, material = "Neon", studs = false }
		),
		P(
			"CombR101",
			{ 0.968, 0.559, 0.22 },
			{ 0, 3.659, -0.688 },
			HONEY,
			{ joint = "ShellR", rot = { 62.697, -180, 0 }, studs = false }
		),
		P(
			"CombR102",
			{ 0.968, 0.559, 0.22 },
			{ 0, 3.659, -0.688 },
			HONEY,
			{ joint = "ShellR", rot = { -117.303, 0, -120 }, studs = false }
		),
		P(
			"CombR103",
			{ 0.968, 0.559, 0.22 },
			{ 0, 3.659, -0.688 },
			HONEY,
			{ joint = "ShellR", rot = { -117.303, 0, -60 }, studs = false }
		),
		P(
			"CombR111",
			{ 0.968, 0.559, 0.22 },
			{ 0.925, 3.659, -0.243 },
			HONEY,
			{ joint = "ShellR", rot = { -107.84, 21.015, 131.906 }, studs = false }
		),
		P(
			"CombR112",
			{ 0.968, 0.559, 0.22 },
			{ 0.925, 3.659, -0.243 },
			HONEY,
			{ joint = "ShellR", rot = { 72.16, 158.985, 11.906 }, studs = false }
		),
		P(
			"CombR113",
			{ 0.968, 0.559, 0.22 },
			{ 0.925, 3.659, -0.243 },
			HONEY,
			{ joint = "ShellR", rot = { -107.84, 21.015, -108.094 }, studs = false }
		),
		P(
			"CombR121",
			{ 0.968, 0.559, 0.22 },
			{ 1.154, 3.659, 0.758 },
			HONEY,
			{ joint = "ShellR", rot = { -83.447, 26.564, 75.595 }, studs = false }
		),
		P(
			"CombR122",
			{ 0.968, 0.559, 0.22 },
			{ 1.154, 3.659, 0.758 },
			HONEY,
			{ joint = "ShellR", rot = { -83.447, 26.564, 135.595 }, studs = false }
		),
		P(
			"CombR123",
			{ 0.968, 0.559, 0.22 },
			{ 1.154, 3.659, 0.758 },
			HONEY,
			{ joint = "ShellR", rot = { 96.553, 153.436, 15.595 }, studs = false }
		),
		P(
			"CombR12Core",
			{ 0.484, 0.279, 0.165 },
			{ 1.164, 3.679, 0.761 },
			AMBER,
			{ joint = "ShellR", rot = { 96.553, 153.436, -14.405 }, material = "Neon", studs = false }
		),
		P(
			"CombR131",
			{ 0.968, 0.559, 0.22 },
			{ 0.513, 3.659, 1.561 },
			HONEY,
			{ joint = "ShellR", rot = { -65.058, 11.48, 23.167 }, studs = false }
		),
		P(
			"CombR132",
			{ 0.968, 0.559, 0.22 },
			{ 0.513, 3.659, 1.561 },
			HONEY,
			{ joint = "ShellR", rot = { -65.058, 11.48, 83.167 }, studs = false }
		),
		P(
			"CombR133",
			{ 0.968, 0.559, 0.22 },
			{ 0.513, 3.659, 1.561 },
			HONEY,
			{ joint = "ShellR", rot = { -65.058, 11.48, 143.167 }, studs = false }
		),
		P(
			"CombR141",
			{ 0.814, 0.47, 0.22 },
			{ 0.371, 3.887, 0.124 },
			HONEY,
			{ joint = "ShellR", rot = { -97.977, 7.901, 135.552 }, studs = false }
		),
		P(
			"CombR142",
			{ 0.814, 0.47, 0.22 },
			{ 0.371, 3.887, 0.124 },
			HONEY,
			{ joint = "ShellR", rot = { 82.023, 172.099, 15.552 }, studs = false }
		),
		P(
			"CombR143",
			{ 0.814, 0.47, 0.22 },
			{ 0.371, 3.887, 0.124 },
			HONEY,
			{ joint = "ShellR", rot = { -97.977, 7.901, -104.448 }, studs = false }
		),
		P(
			"CombR151",
			{ 0.814, 0.47, 0.22 },
			{ 0.371, 3.887, 0.866 },
			HONEY,
			{ joint = "ShellR", rot = { -82.023, 7.901, 44.448 }, studs = false }
		),
		P(
			"CombR152",
			{ 0.814, 0.47, 0.22 },
			{ 0.371, 3.887, 0.866 },
			HONEY,
			{ joint = "ShellR", rot = { -82.023, 7.901, 104.448 }, studs = false }
		),
		P(
			"CombR153",
			{ 0.814, 0.47, 0.22 },
			{ 0.371, 3.887, 0.866 },
			HONEY,
			{ joint = "ShellR", rot = { -82.023, 7.901, 164.448 }, studs = false }
		),
		P(
			"CombR15Core",
			{ 0.407, 0.235, 0.165 },
			{ 0.374, 3.908, 0.869 },
			AMBER,
			{ joint = "ShellR", rot = { -82.023, 7.901, 134.448 }, material = "Neon", studs = false }
		),
		P(
			"CombR161",
			{ 0.77, 0.444, 0.22 },
			{ 0, 3.938, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"CombR162",
			{ 0.77, 0.444, 0.22 },
			{ 0, 3.938, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { -90, 0, 60 }, studs = false }
		),
		P(
			"CombR163",
			{ 0.77, 0.444, 0.22 },
			{ 0, 3.938, 0.495 },
			HONEY,
			{ joint = "ShellR", rot = { -90, 0, 120 }, studs = false }
		),
		P(
			"FlowerR2Petal1",
			{ 0.43, 0.11, 0.468 },
			{ 1.867, 3.025, 1.366 },
			FLOWER2,
			{ joint = "ShellR", rot = { -109.729, -35.902, -121.449 }, studs = false }
		),
		P(
			"FlowerR2Petal2",
			{ 0.43, 0.11, 0.468 },
			{ 1.641, 3.173, 1.555 },
			GLINT,
			{ joint = "ShellR", rot = { 13.98, 167.248, 45.114 }, studs = false }
		),
		P(
			"FlowerR2Petal3",
			{ 0.43, 0.11, 0.468 },
			{ 1.5, 3.412, 1.376 },
			FLOWER2,
			{ joint = "ShellR", rot = { 116.793, 46.287, -90.23 }, studs = false }
		),
		P(
			"FlowerR2Petal4",
			{ 0.43, 0.11, 0.468 },
			{ 1.639, 3.412, 1.078 },
			GLINT,
			{ joint = "ShellR", rot = { 39.289, 13.061, -45.185 }, studs = false }
		),
		P(
			"FlowerR2Petal5",
			{ 0.43, 0.11, 0.468 },
			{ 1.866, 3.173, 1.071 },
			FLOWER2,
			{ joint = "ShellR", rot = { -16.86, -35.672, -58.282 }, studs = false }
		),
		P(
			"FlowerR2Centre",
			{ 0.318, 0.154, 0.318 },
			{ 1.726, 3.26, 1.3 },
			POLLEN,
			{ joint = "ShellR", rot = { -50.307, -45.519, -80.486 }, material = "Neon", studs = false }
		),
		P(
			"FlowerLeafR2_1",
			{ 0.462, 0.693, 0.11 },
			{ 1.961, 3.155, 1.484 },
			LEAF3,
			{ joint = "ShellR", rot = { -92.11, 15.752, -125.062 }, studs = false }
		),
		P(
			"FlowerLeafR2_1Tip",
			{ 0.327, 0.327, 0.106 },
			{ 2.234, 3.085, 1.685 },
			LEAF3,
			{ joint = "ShellR", rot = { -92.11, 15.752, -80.062 }, studs = false }
		),
		P(
			"FlowerLeafR2_2",
			{ 0.462, 0.693, 0.11 },
			{ 1.459, 3.105, 1.513 },
			LEAF,
			{ joint = "ShellR", rot = { -37.544, 25.708, 132.898 }, studs = false }
		),
		P(
			"FlowerLeafR2_2Tip",
			{ 0.327, 0.327, 0.106 },
			{ 1.23, 2.985, 1.744 },
			LEAF,
			{ joint = "ShellR", rot = { -37.544, 25.708, 177.898 }, studs = false }
		),
		P(
			"HingeWingL",
			{ 0.22, 0.22, 0.22 },
			{ -0.495, 3.41, 0.22 },
			MAIN,
			{ joint = "WingL", transparency = 1, studs = false }
		),
		P("WingL", { 1.65, 2.86, 0.088 }, { -1.358, 4.666, 0.691 }, GLASS, {
			joint = "WingL",
			rot = { 20.185, -179.424, -32.772 },
			material = "Glass",
			transparency = 0.25,
			studs = false,
		}),
		P("WingTipL", { 1.166, 1.166, 0.088 }, { -2.132, 5.792, 1.113 }, GLASS, {
			joint = "WingL",
			rot = { 20.185, -179.424, 12.228 },
			material = "Glass",
			transparency = 0.25,
			studs = false,
		}),
		P("WingRootL", { 0.99, 0.66, 0.088 }, { -0.644, 3.627, 0.301 }, GLASS, {
			joint = "WingL",
			rot = { 20.185, -179.424, -32.772 },
			material = "Glass",
			transparency = 0.25,
			studs = false,
		}),
		P(
			"WingVeinL1",
			{ 0.077, 2.97, 0.11 },
			{ -1.418, 4.756, 0.713 },
			VEIN,
			{ joint = "WingL", rot = { 20.185, -179.424, -32.772 }, studs = false }
		),
		P(
			"WingVeinL2",
			{ 0.077, 1.98, 0.11 },
			{ -1.094, 4.953, 0.782 },
			VEIN,
			{ joint = "WingL", rot = { 20.185, -179.424, -20.772 }, studs = false }
		),
		P(
			"WingVeinL3",
			{ 0.077, 1.87, 0.11 },
			{ -1.769, 4.543, 0.638 },
			VEIN,
			{ joint = "WingL", rot = { 20.185, -179.424, -44.772 }, studs = false }
		),
		P(
			"WingEdgeL",
			{ 0.11, 2.86, 0.132 },
			{ -2.061, 4.242, 0.531 },
			VEIN,
			{ joint = "WingL", rot = { 20.185, -179.424, -32.772 }, studs = false }
		),
		P(
			"HingeWingR",
			{ 0.22, 0.22, 0.22 },
			{ 0.495, 3.41, 0.22 },
			MAIN,
			{ joint = "WingR", transparency = 1, studs = false }
		),
		P("WingR", { 1.65, 2.86, 0.088 }, { 1.358, 4.666, 0.691 }, GLASS, {
			joint = "WingR",
			rot = { 20.185, 179.424, 32.772 },
			material = "Glass",
			transparency = 0.25,
			studs = false,
		}),
		P("WingTipR", { 1.166, 1.166, 0.088 }, { 2.132, 5.792, 1.113 }, GLASS, {
			joint = "WingR",
			rot = { -159.815, 0.576, -102.228 },
			material = "Glass",
			transparency = 0.25,
			studs = false,
		}),
		P("WingRootR", { 0.99, 0.66, 0.088 }, { 0.644, 3.627, 0.301 }, GLASS, {
			joint = "WingR",
			rot = { 20.185, 179.424, 32.772 },
			material = "Glass",
			transparency = 0.25,
			studs = false,
		}),
		P(
			"WingVeinR1",
			{ 0.077, 2.97, 0.11 },
			{ 1.418, 4.756, 0.713 },
			VEIN,
			{ joint = "WingR", rot = { 20.185, 179.424, 32.772 }, studs = false }
		),
		P(
			"WingVeinR2",
			{ 0.077, 1.98, 0.11 },
			{ 1.742, 4.559, 0.644 },
			VEIN,
			{ joint = "WingR", rot = { 20.185, 179.424, 44.772 }, studs = false }
		),
		P(
			"WingVeinR3",
			{ 0.077, 1.87, 0.11 },
			{ 1.067, 4.97, 0.788 },
			VEIN,
			{ joint = "WingR", rot = { 20.185, 179.424, 20.772 }, studs = false }
		),
		P(
			"WingEdgeR",
			{ 0.11, 2.86, 0.132 },
			{ 2.061, 4.242, 0.531 },
			VEIN,
			{ joint = "WingR", rot = { 20.185, 179.424, 32.772 }, studs = false }
		),
		P(
			"HingeHead",
			{ 0.22, 0.22, 0.22 },
			{ 0, 1.87, -2.31 },
			MAIN,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P("Head", { 1.65, 1.265, 1.155 }, { 0, 1.76, -2.805 }, DARK, { joint = "Head" }),
		P("Brow", { 1.43, 0.308, 0.44 }, { 0, 2.42, -3.025 }, MAIN, { joint = "Head", studs = false }),
		P(
			"HeadHex1",
			{ 0.935, 0.539, 0.22 },
			{ 0, 2.42, -2.695 },
			HONEY,
			{ joint = "Head", rot = { -114.228, 0, 0 }, studs = false }
		),
		P(
			"HeadHex2",
			{ 0.935, 0.539, 0.22 },
			{ 0, 2.42, -2.695 },
			HONEY,
			{ joint = "Head", rot = { -114.228, 0, 60 }, studs = false }
		),
		P(
			"HeadHex3",
			{ 0.935, 0.539, 0.22 },
			{ 0, 2.42, -2.695 },
			HONEY,
			{ joint = "Head", rot = { -114.228, 0, 120 }, studs = false }
		),
		P(
			"HeadHexCore",
			{ 0.468, 0.27, 0.165 },
			{ 0, 2.44, -2.704 },
			AMBER,
			{ joint = "Head", rot = { -114.228, 0, 90 }, material = "Neon", studs = false }
		),
		P("EyeRimL", { 0.44, 0.616, 0.066 }, { -0.418, 1.782, -3.41 }, INK, { joint = "Head", studs = false }),
		P(
			"EyeL",
			{ 0.308, 0.484, 0.066 },
			{ -0.418, 1.782, -3.454 },
			EYE,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"MandibleL",
			{ 0.22, 0.46, 0.176 },
			{ -0.231, 1.155, -3.493 },
			MAIN,
			{ joint = "Head", rot = { 43.299, 41.404, -144.937 }, studs = false }
		),
		P("EyeRimR", { 0.44, 0.616, 0.066 }, { 0.418, 1.782, -3.41 }, INK, { joint = "Head", studs = false }),
		P(
			"EyeR",
			{ 0.308, 0.484, 0.066 },
			{ 0.418, 1.782, -3.454 },
			EYE,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"MandibleR",
			{ 0.22, 0.46, 0.176 },
			{ 0.231, 1.155, -3.493 },
			MAIN,
			{ joint = "Head", rot = { 43.299, -41.404, 144.937 }, studs = false }
		),
		P(
			"HingeAntennaL",
			{ 0.22, 0.22, 0.22 },
			{ -0.44, 2.365, -3.025 },
			MAIN,
			{ joint = "AntennaL", transparency = 1, studs = false }
		),
		P(
			"AntennaL1",
			{ 0.198, 0.968, 0.198 },
			{ -0.541, 2.769, -3.166 },
			MAIN,
			{ joint = "AntennaL", rot = { -18.232, -4.472, 13.318 }, studs = false }
		),
		P(
			"AntennaL2",
			{ 0.178, 0.858, 0.178 },
			{ -0.796, 3.346, -3.616 },
			MAIN,
			{ joint = "AntennaL", rot = { -44.802, -32.061, 28.125 }, studs = false }
		),
		P(
			"AntennaTipL",
			{ 0.352, 0.352, 0.418 },
			{ -0.95, 3.519, -3.923 },
			YELLOW,
			{ joint = "AntennaL", rot = { -65.772, 11.595, 24.068 }, studs = false }
		),
		P(
			"HingeAntennaR",
			{ 0.22, 0.22, 0.22 },
			{ 0.44, 2.365, -3.025 },
			MAIN,
			{ joint = "AntennaR", transparency = 1, studs = false }
		),
		P(
			"AntennaR1",
			{ 0.198, 0.968, 0.198 },
			{ 0.541, 2.769, -3.166 },
			MAIN,
			{ joint = "AntennaR", rot = { -18.232, 4.472, -13.318 }, studs = false }
		),
		P(
			"AntennaR2",
			{ 0.178, 0.858, 0.178 },
			{ 0.796, 3.346, -3.616 },
			MAIN,
			{ joint = "AntennaR", rot = { -44.802, 32.061, -28.125 }, studs = false }
		),
		P(
			"AntennaTipR",
			{ 0.352, 0.352, 0.418 },
			{ 0.95, 3.519, -3.923 },
			YELLOW,
			{ joint = "AntennaR", rot = { -65.772, -11.595, -24.068 }, studs = false }
		),
		P(
			"HingeLegL1",
			{ 0.22, 0.22, 0.22 },
			{ -1.43, 1.375, -1.375 },
			MAIN,
			{ joint = "LegL1", transparency = 1, studs = false }
		),
		P(
			"FemurLegL1",
			{ 0.616, 0.993, 0.616 },
			{ -1.815, 1.567, -1.623 },
			MAIN,
			{ joint = "LegL1", rot = { -14.421, -26.477, 60.025 } }
		),
		P(
			"TibiaLegL1",
			{ 0.506, 1.488, 0.506 },
			{ -2.365, 1.045, -1.994 },
			DARK,
			{ joint = "LegL1", rot = { 9.332, -2.143, 167.18 } }
		),
		P("PadLegL1", { 0.616, 0.352, 0.66 }, { -1.854, 1.917, -1.647 }, LEAF, { joint = "LegL1" }),
		P("PadTopLegL1", { 0.44, 0.154, 0.462 }, { -1.854, 2.137, -1.647 }, LEAF3, { joint = "LegL1", studs = false }),
		P("FootLegL1", { 0.55, 0.33, 0.66 }, { -2.53, 0.165, -2.118 }, YELLOW, { joint = "LegL1", studs = false }),
		P(
			"HingeLegL2",
			{ 0.22, 0.22, 0.22 },
			{ -1.43, 1.375, 0.275 },
			MAIN,
			{ joint = "LegL2", transparency = 1, studs = false }
		),
		P(
			"FemurLegL2",
			{ 0.616, 0.861, 0.616 },
			{ -1.815, 1.567, 0.275 },
			MAIN,
			{ joint = "LegL2", rot = { 0, 0, 63.435 } }
		),
		P(
			"TibiaLegL2",
			{ 0.506, 1.468, 0.506 },
			{ -2.365, 1.045, 0.275 },
			DARK,
			{ joint = "LegL2", rot = { 0, 0, 167.005 } }
		),
		P("PadLegL2", { 0.616, 0.352, 0.66 }, { -1.854, 1.917, 0.275 }, LEAF, { joint = "LegL2" }),
		P("PadTopLegL2", { 0.44, 0.154, 0.462 }, { -1.854, 2.137, 0.275 }, LEAF3, { joint = "LegL2", studs = false }),
		P("FootLegL2", { 0.55, 0.33, 0.66 }, { -2.53, 0.165, 0.275 }, YELLOW, { joint = "LegL2", studs = false }),
		P(
			"HingeLegL3",
			{ 0.22, 0.22, 0.22 },
			{ -1.43, 1.375, 1.705 },
			MAIN,
			{ joint = "LegL3", transparency = 1, studs = false }
		),
		P(
			"FemurLegL3",
			{ 0.616, 0.993, 0.616 },
			{ -1.815, 1.567, 1.952 },
			MAIN,
			{ joint = "LegL3", rot = { 14.421, 26.477, 60.025 } }
		),
		P(
			"TibiaLegL3",
			{ 0.506, 1.488, 0.506 },
			{ -2.365, 1.045, 2.324 },
			DARK,
			{ joint = "LegL3", rot = { -9.332, 2.143, 167.18 } }
		),
		P("PadLegL3", { 0.616, 0.352, 0.66 }, { -1.854, 1.917, 1.977 }, LEAF, { joint = "LegL3" }),
		P("PadTopLegL3", { 0.44, 0.154, 0.462 }, { -1.854, 2.137, 1.977 }, LEAF3, { joint = "LegL3", studs = false }),
		P("FootLegL3", { 0.55, 0.33, 0.66 }, { -2.53, 0.165, 2.447 }, YELLOW, { joint = "LegL3", studs = false }),
		P(
			"HingeLegR1",
			{ 0.22, 0.22, 0.22 },
			{ 1.43, 1.375, -1.375 },
			MAIN,
			{ joint = "LegR1", transparency = 1, studs = false }
		),
		P(
			"FemurLegR1",
			{ 0.616, 0.993, 0.616 },
			{ 1.815, 1.567, -1.623 },
			MAIN,
			{ joint = "LegR1", rot = { -14.421, 26.477, -60.025 } }
		),
		P(
			"TibiaLegR1",
			{ 0.506, 1.488, 0.506 },
			{ 2.365, 1.045, -1.994 },
			DARK,
			{ joint = "LegR1", rot = { 9.332, 2.143, -167.18 } }
		),
		P("PadLegR1", { 0.616, 0.352, 0.66 }, { 1.854, 1.917, -1.647 }, LEAF, { joint = "LegR1" }),
		P("PadTopLegR1", { 0.44, 0.154, 0.462 }, { 1.854, 2.137, -1.647 }, LEAF3, { joint = "LegR1", studs = false }),
		P("FootLegR1", { 0.55, 0.33, 0.66 }, { 2.53, 0.165, -2.118 }, YELLOW, { joint = "LegR1", studs = false }),
		P(
			"HingeLegR2",
			{ 0.22, 0.22, 0.22 },
			{ 1.43, 1.375, 0.275 },
			MAIN,
			{ joint = "LegR2", transparency = 1, studs = false }
		),
		P(
			"FemurLegR2",
			{ 0.616, 0.861, 0.616 },
			{ 1.815, 1.567, 0.275 },
			MAIN,
			{ joint = "LegR2", rot = { 0, 0, -63.435 } }
		),
		P(
			"TibiaLegR2",
			{ 0.506, 1.468, 0.506 },
			{ 2.365, 1.045, 0.275 },
			DARK,
			{ joint = "LegR2", rot = { 0, 0, -167.005 } }
		),
		P("PadLegR2", { 0.616, 0.352, 0.66 }, { 1.854, 1.917, 0.275 }, LEAF, { joint = "LegR2" }),
		P("PadTopLegR2", { 0.44, 0.154, 0.462 }, { 1.854, 2.137, 0.275 }, LEAF3, { joint = "LegR2", studs = false }),
		P("FootLegR2", { 0.55, 0.33, 0.66 }, { 2.53, 0.165, 0.275 }, YELLOW, { joint = "LegR2", studs = false }),
		P(
			"HingeLegR3",
			{ 0.22, 0.22, 0.22 },
			{ 1.43, 1.375, 1.705 },
			MAIN,
			{ joint = "LegR3", transparency = 1, studs = false }
		),
		P(
			"FemurLegR3",
			{ 0.616, 0.993, 0.616 },
			{ 1.815, 1.567, 1.952 },
			MAIN,
			{ joint = "LegR3", rot = { 14.421, -26.477, -60.025 } }
		),
		P(
			"TibiaLegR3",
			{ 0.506, 1.488, 0.506 },
			{ 2.365, 1.045, 2.324 },
			DARK,
			{ joint = "LegR3", rot = { -9.332, -2.143, -167.18 } }
		),
		P("PadLegR3", { 0.616, 0.352, 0.66 }, { 1.854, 1.917, 1.977 }, LEAF, { joint = "LegR3" }),
		P("PadTopLegR3", { 0.44, 0.154, 0.462 }, { 1.854, 2.137, 1.977 }, LEAF3, { joint = "LegR3", studs = false }),
		P("FootLegR3", { 0.55, 0.33, 0.66 }, { 2.53, 0.165, 2.447 }, YELLOW, { joint = "LegR3", studs = false }),
	},
}

return { egg = egg, pet = pet }
