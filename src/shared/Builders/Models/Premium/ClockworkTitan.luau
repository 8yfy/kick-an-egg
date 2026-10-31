--!strict
-- 63 Clockwork Titan (Clockwork Factory, Divine). Premium hero spec (docs/EggPetPlan.md).
-- Pet: a massive brass and dark-iron golem (the user's reference): a glowing amber clock heart ringed by gears, boxed
--      pauldrons with clock faces and spires, a helm with a crown of spires and an amber visor, red banners with gear
--      emblems, pistons, elbow, hip and knee gears, amber vents, huge segmented fists and heavy boots.
-- Egg: iron and brass terraces, a glowing clock face ringed by a toothed rim, small gears, a red banner, spires on
--      top, amber vents, the Divine band.
-- BAKED FILE: modelled in Blender from Roblox primitives by tools/blender/pets (v3/clockwork_titan.py, v3/eggs_blocks.py).
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local MAIN = rgb(201, 162, 78) -- #C9A24E
local MAIN2 = rgb(168, 130, 58) -- #A8823A
local DARK = rgb(52, 48, 45) -- #34302D
local LIGHT = rgb(243, 217, 140) -- #F3D98C
local GLOW = rgb(255, 184, 74) -- #FFB84A
local FACE = rgb(241, 226, 182) -- #F1E2B6
local RED = rgb(142, 43, 43) -- #8E2B2B
local INK = rgb(26, 22, 20) -- #1A1614
local GLASS = rgb(255, 217, 154) -- #FFD99A
local TIP = rgb(255, 241, 200) -- #FFF1C8
local IRON2 = rgb(74, 68, 64) -- #4A4440
local GLINT = rgb(255, 255, 255) -- #FFFFFF

local egg: Builder.Spec = {
	parts = {
		P("Shell1", { 1.75, 0.533, 1.75 }, { 0, 0.267, 0 }, DARK, { joint = "Body" }),
		P("Shell2", { 2.769, 0.533, 2.769 }, { 0, 0.8, 0 }, MAIN2, { joint = "Body" }),
		P("Shell3", { 3.233, 0.533, 3.233 }, { 0, 1.333, 0 }, MAIN, { joint = "Body" }),
		P("Shell4", { 3.416, 0.533, 3.416 }, { 0, 1.867, 0 }, MAIN, { joint = "Body" }),
		P("Shell5", { 3.398, 0.533, 3.398 }, { 0, 2.4, 0 }, MAIN, { joint = "Body" }),
		P("Shell6", { 3.21, 0.533, 3.21 }, { 0, 2.933, 0 }, MAIN, { joint = "Body" }),
		P("Shell7", { 2.855, 0.533, 2.855 }, { 0, 3.467, 0 }, MAIN, { joint = "Body" }),
		P("Shell8", { 2.296, 0.533, 2.296 }, { 0, 4, 0 }, DARK, { joint = "Body" }),
		P("Shell9", { 1.363, 0.533, 1.363 }, { 0, 4.533, 0 }, MAIN2, { joint = "Body" }),
		P(
			"RarityBand",
			{ 2.929, 0.2, 2.929 },
			{ 0, 0.95, 0 },
			rgb(255, 250, 200),
			{ joint = "Body", material = "Neon", studs = false }
		),
		P("Rivet1", { 0.14, 0.14, 0.12 }, { -1.078, 1.45, -1.617 }, LIGHT, { joint = "Body", studs = false }),
		P("Rivet2", { 0.14, 0.14, 0.12 }, { 0, 1.45, -1.617 }, LIGHT, { joint = "Body", studs = false }),
		P("Rivet3", { 0.14, 0.14, 0.12 }, { 1.078, 1.45, -1.617 }, LIGHT, { joint = "Body", studs = false }),
		P(
			"Rivet4",
			{ 0.14, 0.14, 0.12 },
			{ 1.617, 1.45, -1.078 },
			LIGHT,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"Rivet5",
			{ 0.14, 0.14, 0.12 },
			{ 1.617, 1.45, 0 },
			LIGHT,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"Rivet6",
			{ 0.14, 0.14, 0.12 },
			{ 1.617, 1.45, 1.078 },
			LIGHT,
			{ joint = "Body", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"Rivet7",
			{ 0.14, 0.14, 0.12 },
			{ 1.078, 1.45, 1.617 },
			LIGHT,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"Rivet8",
			{ 0.14, 0.14, 0.12 },
			{ 0, 1.45, 1.617 },
			LIGHT,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"Rivet9",
			{ 0.14, 0.14, 0.12 },
			{ -1.078, 1.45, 1.617 },
			LIGHT,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"Rivet10",
			{ 0.14, 0.14, 0.12 },
			{ -1.617, 1.45, 1.078 },
			LIGHT,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Rivet11",
			{ 0.14, 0.14, 0.12 },
			{ -1.617, 1.45, 0 },
			LIGHT,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"Rivet12",
			{ 0.14, 0.14, 0.12 },
			{ -1.617, 1.45, -1.078 },
			LIGHT,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"ClockFace",
			{ 1.36, 1.36, 0.08 },
			{ 0, 2.55, -1.799 },
			GLOW,
			{ joint = "Body", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"ClockRim1",
			{ 0.327, 0.16, 0.16 },
			{ 0, 3.23, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"ClockRim2",
			{ 0.327, 0.16, 0.16 },
			{ 0.295, 3.163, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 25.714, 0 }, studs = false }
		),
		P(
			"ClockRim3",
			{ 0.327, 0.16, 0.16 },
			{ 0.532, 2.974, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 51.429, 0 }, studs = false }
		),
		P(
			"ClockRim4",
			{ 0.327, 0.16, 0.16 },
			{ 0.663, 2.701, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 77.143, 0 }, studs = false }
		),
		P(
			"ClockRim5",
			{ 0.327, 0.16, 0.16 },
			{ 0.663, 2.399, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 102.857, 0 }, studs = false }
		),
		P(
			"ClockRim6",
			{ 0.327, 0.16, 0.16 },
			{ 0.532, 2.126, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 128.571, 0 }, studs = false }
		),
		P(
			"ClockRim7",
			{ 0.327, 0.16, 0.16 },
			{ 0.295, 1.937, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, 154.286, 0 }, studs = false }
		),
		P(
			"ClockRim8",
			{ 0.327, 0.16, 0.16 },
			{ 0, 1.87, -1.819 },
			MAIN,
			{ joint = "Body", rot = { 90, 0, -180 }, studs = false }
		),
		P(
			"ClockRim9",
			{ 0.327, 0.16, 0.16 },
			{ -0.295, 1.937, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, -154.286, 0 }, studs = false }
		),
		P(
			"ClockRim10",
			{ 0.327, 0.16, 0.16 },
			{ -0.532, 2.126, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, -128.571, 0 }, studs = false }
		),
		P(
			"ClockRim11",
			{ 0.327, 0.16, 0.16 },
			{ -0.663, 2.399, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, -102.857, 0 }, studs = false }
		),
		P(
			"ClockRim12",
			{ 0.327, 0.16, 0.16 },
			{ -0.663, 2.701, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, -77.143, 0 }, studs = false }
		),
		P(
			"ClockRim13",
			{ 0.327, 0.16, 0.16 },
			{ -0.532, 2.974, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, -51.429, 0 }, studs = false }
		),
		P(
			"ClockRim14",
			{ 0.327, 0.16, 0.16 },
			{ -0.295, 3.163, -1.819 },
			MAIN,
			{ joint = "Body", rot = { -90, -25.714, 0 }, studs = false }
		),
		P(
			"ClockTick1",
			{ 0.08, 0.15, 0.06 },
			{ 0, 3.08, -1.859 },
			INK,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"ClockTick2",
			{ 0.05, 0.082, 0.06 },
			{ -0.265, 3.009, -1.859 },
			INK,
			{ joint = "Body", rot = { 0, 180, -30 }, studs = false }
		),
		P(
			"ClockTick3",
			{ 0.05, 0.082, 0.06 },
			{ -0.459, 2.815, -1.859 },
			INK,
			{ joint = "Body", rot = { 0, 180, -60 }, studs = false }
		),
		P(
			"ClockTick4",
			{ 0.08, 0.15, 0.06 },
			{ -0.53, 2.55, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, 90 }, studs = false }
		),
		P(
			"ClockTick5",
			{ 0.05, 0.082, 0.06 },
			{ -0.459, 2.285, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, 60 }, studs = false }
		),
		P(
			"ClockTick6",
			{ 0.05, 0.082, 0.06 },
			{ -0.265, 2.091, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, 30 }, studs = false }
		),
		P(
			"ClockTick7",
			{ 0.08, 0.15, 0.06 },
			{ 0, 2.02, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, 0 }, studs = false }
		),
		P(
			"ClockTick8",
			{ 0.05, 0.082, 0.06 },
			{ 0.265, 2.091, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"ClockTick9",
			{ 0.05, 0.082, 0.06 },
			{ 0.459, 2.285, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, -60 }, studs = false }
		),
		P(
			"ClockTick10",
			{ 0.08, 0.15, 0.06 },
			{ 0.53, 2.55, -1.859 },
			INK,
			{ joint = "Body", rot = { -180, 0, -90 }, studs = false }
		),
		P(
			"ClockTick11",
			{ 0.05, 0.082, 0.06 },
			{ 0.459, 2.815, -1.859 },
			INK,
			{ joint = "Body", rot = { 0, 180, 60 }, studs = false }
		),
		P(
			"ClockTick12",
			{ 0.05, 0.082, 0.06 },
			{ 0.265, 3.009, -1.859 },
			INK,
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"ClockHand1",
			{ 0.07, 0.34, 0.05 },
			{ 0.109, 2.68, -1.899 },
			INK,
			{ joint = "Body", rot = { 0, 180, 40 }, studs = false }
		),
		P(
			"ClockHand2",
			{ 0.07, 0.49, 0.05 },
			{ -0.23, 2.634, -1.899 },
			INK,
			{ joint = "Body", rot = { 0, 180, -70 }, studs = false }
		),
		P(
			"ClockTooth1",
			{ 0.16, 0.14, 0.16 },
			{ 0, 3.39, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"ClockTooth2",
			{ 0.16, 0.14, 0.16 },
			{ 0.42, 3.277, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, 30, 0 }, studs = false }
		),
		P(
			"ClockTooth3",
			{ 0.16, 0.14, 0.16 },
			{ 0.727, 2.97, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, 60, 0 }, studs = false }
		),
		P(
			"ClockTooth4",
			{ 0.16, 0.14, 0.16 },
			{ 0.84, 2.55, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"ClockTooth5",
			{ 0.16, 0.14, 0.16 },
			{ 0.727, 2.13, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, 120, 0 }, studs = false }
		),
		P(
			"ClockTooth6",
			{ 0.16, 0.14, 0.16 },
			{ 0.42, 1.823, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, 150, 0 }, studs = false }
		),
		P(
			"ClockTooth7",
			{ 0.16, 0.14, 0.16 },
			{ 0, 1.71, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { 90, 0, -180 }, studs = false }
		),
		P(
			"ClockTooth8",
			{ 0.16, 0.14, 0.16 },
			{ -0.42, 1.823, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, -150, 0 }, studs = false }
		),
		P(
			"ClockTooth9",
			{ 0.16, 0.14, 0.16 },
			{ -0.727, 2.13, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, -120, 0 }, studs = false }
		),
		P(
			"ClockTooth10",
			{ 0.16, 0.14, 0.16 },
			{ -0.84, 2.55, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"ClockTooth11",
			{ 0.16, 0.14, 0.16 },
			{ -0.727, 2.97, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, -60, 0 }, studs = false }
		),
		P(
			"ClockTooth12",
			{ 0.16, 0.14, 0.16 },
			{ -0.42, 3.277, -1.799 },
			MAIN2,
			{ joint = "Body", rot = { -90, -30, 0 }, studs = false }
		),
		P(
			"Gear1",
			{ 0.14, 0.48, 0.48 },
			{ -0.95, 3.4, -1.839 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear1T1",
			{ 0.101, 0.126, 0.6 },
			{ -0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear1T2",
			{ 0.101, 0.126, 0.6 },
			{ -0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear1T3",
			{ 0.101, 0.126, 0.6 },
			{ -0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear1T4",
			{ 0.101, 0.126, 0.6 },
			{ -0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear2",
			{ 0.14, 0.48, 0.48 },
			{ 0.95, 3.4, -1.839 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear2T1",
			{ 0.101, 0.126, 0.6 },
			{ 0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear2T2",
			{ 0.101, 0.126, 0.6 },
			{ 0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear2T3",
			{ 0.101, 0.126, 0.6 },
			{ 0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear2T4",
			{ 0.101, 0.126, 0.6 },
			{ 0.95, 3.4, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear3",
			{ 0.14, 0.4, 0.4 },
			{ -0.95, 1.8, -1.839 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear3T1",
			{ 0.084, 0.126, 0.5 },
			{ -0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear3T2",
			{ 0.084, 0.126, 0.5 },
			{ -0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear3T3",
			{ 0.084, 0.126, 0.5 },
			{ -0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear3T4",
			{ 0.084, 0.126, 0.5 },
			{ -0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear4",
			{ 0.14, 0.4, 0.4 },
			{ 0.95, 1.8, -1.839 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear4T1",
			{ 0.084, 0.126, 0.5 },
			{ 0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear4T2",
			{ 0.084, 0.126, 0.5 },
			{ 0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear4T3",
			{ 0.084, 0.126, 0.5 },
			{ 0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear4T4",
			{ 0.084, 0.126, 0.5 },
			{ 0.95, 1.8, -1.839 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Banner",
			{ 0.62, 1.5, 0.07 },
			{ 1.808, 2.35, 0 },
			RED,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"BannerTrimL",
			{ 0.08, 1.5, 0.09 },
			{ 1.818, 2.35, 0.29 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"BannerTrimR",
			{ 0.08, 1.5, 0.09 },
			{ 1.818, 2.35, -0.29 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"BannerTipa",
			{ 0.07, 0.31, 0.31 },
			{ 1.808, 1.445, 0.155 },
			RED,
			{ joint = "Body", rot = { -180, 0, 0 }, shape = "Wedge", studs = false }
		),
		P(
			"BannerTipb",
			{ 0.07, 0.31, 0.31 },
			{ 1.808, 1.445, -0.155 },
			RED,
			{ joint = "Body", rot = { 0, 0, -180 }, shape = "Wedge", studs = false }
		),
		P(
			"BannerEmblem",
			{ 0.14, 0.347, 0.347 },
			{ 1.858, 2.425, 0 },
			MAIN,
			{ joint = "Body", shape = "Cylinder", studs = false }
		),
		P(
			"BannerEmblemT1",
			{ 0.073, 0.126, 0.434 },
			{ 1.858, 2.425, 0 },
			MAIN,
			{ joint = "Body", rot = { -90, 0, -90 }, studs = false }
		),
		P(
			"BannerEmblemT2",
			{ 0.073, 0.126, 0.434 },
			{ 1.858, 2.425, 0 },
			MAIN,
			{ joint = "Body", rot = { -45, 0, -90 }, studs = false }
		),
		P(
			"BannerEmblemT3",
			{ 0.073, 0.126, 0.434 },
			{ 1.858, 2.425, 0 },
			MAIN,
			{ joint = "Body", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"BannerEmblemT4",
			{ 0.073, 0.126, 0.434 },
			{ 1.858, 2.425, 0 },
			MAIN,
			{ joint = "Body", rot = { 45, 0, -90 }, studs = false }
		),
		P(
			"Vent1",
			{ 0.1, 0.62, 0.06 },
			{ -1.789, 2.2, 0.22 },
			GLOW,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"Vent2",
			{ 0.1, 0.62, 0.06 },
			{ -1.789, 2.2, 0 },
			GLOW,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"Vent3",
			{ 0.1, 0.62, 0.06 },
			{ -1.789, 2.2, -0.22 },
			GLOW,
			{ joint = "Body", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P("Spire1", { 0.3, 0.57, 0.3 }, { 0, 4.965, 0 }, MAIN, { joint = "Body", rot = { 0, -135, 0 }, studs = false }),
		P(
			"Spire1Tip",
			{ 0.165, 0.428, 0.165 },
			{ 0, 5.44, 0 },
			LIGHT,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire2",
			{ 0.24, 0.372, 0.24 },
			{ -0.45, 4.866, 0.2 },
			MAIN,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire2Tip",
			{ 0.132, 0.279, 0.132 },
			{ -0.45, 5.176, 0.2 },
			LIGHT,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire3",
			{ 0.24, 0.372, 0.24 },
			{ 0.45, 4.866, 0.2 },
			MAIN,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire3Tip",
			{ 0.132, 0.279, 0.132 },
			{ 0.45, 5.176, 0.2 },
			LIGHT,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire4",
			{ 0.24, 0.3, 0.24 },
			{ -0.3, 4.83, -0.35 },
			MAIN,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire4Tip",
			{ 0.132, 0.225, 0.132 },
			{ -0.3, 5.08, -0.35 },
			LIGHT,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire5",
			{ 0.24, 0.3, 0.24 },
			{ 0.3, 4.83, -0.35 },
			MAIN,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Spire5Tip",
			{ 0.132, 0.225, 0.132 },
			{ 0.3, 5.08, -0.35 },
			LIGHT,
			{ joint = "Body", rot = { 0, -135, 0 }, studs = false }
		),
		P("BackClockFace", { 0.9, 0.9, 0.08 }, { 0, 2.4, 1.779 }, FACE, { joint = "Body", studs = false }),
		P(
			"BackClockRim1",
			{ 0.3, 0.16, 0.16 },
			{ 0, 2.85, 1.799 },
			MAIN,
			{ joint = "Body", rot = { -90, 0, 180 }, studs = false }
		),
		P(
			"BackClockRim2",
			{ 0.3, 0.16, 0.16 },
			{ -0.265, 2.764, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, -144, 0 }, studs = false }
		),
		P(
			"BackClockRim3",
			{ 0.3, 0.16, 0.16 },
			{ -0.428, 2.539, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, -108, 0 }, studs = false }
		),
		P(
			"BackClockRim4",
			{ 0.3, 0.16, 0.16 },
			{ -0.428, 2.261, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, -72, 0 }, studs = false }
		),
		P(
			"BackClockRim5",
			{ 0.3, 0.16, 0.16 },
			{ -0.265, 2.036, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, -36, 0 }, studs = false }
		),
		P(
			"BackClockRim6",
			{ 0.3, 0.16, 0.16 },
			{ 0, 1.95, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, 0, 0 }, studs = false }
		),
		P(
			"BackClockRim7",
			{ 0.3, 0.16, 0.16 },
			{ 0.265, 2.036, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, 36, 0 }, studs = false }
		),
		P(
			"BackClockRim8",
			{ 0.3, 0.16, 0.16 },
			{ 0.428, 2.261, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, 72, 0 }, studs = false }
		),
		P(
			"BackClockRim9",
			{ 0.3, 0.16, 0.16 },
			{ 0.428, 2.539, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, 108, 0 }, studs = false }
		),
		P(
			"BackClockRim10",
			{ 0.3, 0.16, 0.16 },
			{ 0.265, 2.764, 1.799 },
			MAIN,
			{ joint = "Body", rot = { 90, 144, 0 }, studs = false }
		),
		P("BackClockTick1", { 0.08, 0.099, 0.06 }, { 0, 2.751, 1.839 }, INK, { joint = "Body", studs = false }),
		P(
			"BackClockTick2",
			{ 0.05, 0.054, 0.06 },
			{ 0.175, 2.704, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, -30 }, studs = false }
		),
		P(
			"BackClockTick3",
			{ 0.05, 0.054, 0.06 },
			{ 0.304, 2.576, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, -60 }, studs = false }
		),
		P(
			"BackClockTick4",
			{ 0.08, 0.099, 0.06 },
			{ 0.351, 2.4, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"BackClockTick5",
			{ 0.05, 0.054, 0.06 },
			{ 0.304, 2.225, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, -120 }, studs = false }
		),
		P(
			"BackClockTick6",
			{ 0.05, 0.054, 0.06 },
			{ 0.175, 2.096, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, -150 }, studs = false }
		),
		P(
			"BackClockTick7",
			{ 0.08, 0.099, 0.06 },
			{ 0, 2.049, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, 180 }, studs = false }
		),
		P(
			"BackClockTick8",
			{ 0.05, 0.054, 0.06 },
			{ -0.175, 2.096, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, 150 }, studs = false }
		),
		P(
			"BackClockTick9",
			{ 0.05, 0.054, 0.06 },
			{ -0.304, 2.225, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, 120 }, studs = false }
		),
		P(
			"BackClockTick10",
			{ 0.08, 0.099, 0.06 },
			{ -0.351, 2.4, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"BackClockTick11",
			{ 0.05, 0.054, 0.06 },
			{ -0.304, 2.576, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, 60 }, studs = false }
		),
		P(
			"BackClockTick12",
			{ 0.05, 0.054, 0.06 },
			{ -0.175, 2.704, 1.839 },
			INK,
			{ joint = "Body", rot = { 0, 0, 30 }, studs = false }
		),
		P(
			"BackClockHand1",
			{ 0.07, 0.225, 0.05 },
			{ -0.097, 2.456, 1.879 },
			INK,
			{ joint = "Body", rot = { 0, 0, 60 }, studs = false }
		),
		P(
			"BackClockHand2",
			{ 0.07, 0.324, 0.05 },
			{ 0.104, 2.524, 1.879 },
			INK,
			{ joint = "Body", rot = { 0, 0, -40 }, studs = false }
		),
	},
}

local pet: Builder.Spec = {
	parts = {
		P("HingeBody", { 0.22, 0.22, 0.22 }, { 0, 3.3, 0 }, MAIN, { joint = "Body", transparency = 1, studs = false }),
		P("Waist", { 2.09, 1.1, 1.54 }, { 0, 3.025, 0.055 }, DARK, { joint = "Body" }),
		P("Belt", { 2.31, 0.352, 1.705 }, { 0, 3.575, 0.055 }, MAIN, { joint = "Body" }),
		P(
			"Buckle",
			{ 0.132, 0.55, 0.55 },
			{ 0, 3.575, -0.902 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"WaistBanner",
			{ 0.88, 1.87, 0.077 },
			{ 0, 2.475, -0.946 },
			RED,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"WaistBannerTrimL",
			{ 0.088, 1.87, 0.099 },
			{ 0.418, 2.475, -0.957 },
			MAIN,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"WaistBannerTrimR",
			{ 0.088, 1.87, 0.099 },
			{ -0.418, 2.475, -0.957 },
			MAIN,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"WaistBannerTipa",
			{ 0.077, 0.44, 0.44 },
			{ 0.22, 1.32, -0.946 },
			RED,
			{ joint = "Body", rot = { 0, -90, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"WaistBannerTipb",
			{ 0.077, 0.44, 0.44 },
			{ -0.22, 1.32, -0.946 },
			RED,
			{ joint = "Body", rot = { 0, 90, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"WaistBannerEmblem",
			{ 0.154, 0.493, 0.493 },
			{ 0, 2.569, -1.001 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"WaistBannerEmblemT1",
			{ 0.103, 0.139, 0.616 },
			{ 0, 2.569, -1.001 },
			MAIN,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"WaistBannerEmblemT2",
			{ 0.103, 0.139, 0.616 },
			{ 0, 2.569, -1.001 },
			MAIN,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"WaistBannerEmblemT3",
			{ 0.103, 0.139, 0.616 },
			{ 0, 2.569, -1.001 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"WaistBannerEmblemT4",
			{ 0.103, 0.139, 0.616 },
			{ 0, 2.569, -1.001 },
			MAIN,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P("Chest", { 3.3, 2.75, 2.2 }, { 0, 5.06, 0 }, DARK, { joint = "Body" }),
		P("ChestTop", { 2.97, 0.462, 1.98 }, { 0, 6.655, 0 }, MAIN, { joint = "Body" }),
		P("ChestPlateL", { 0.682, 2.42, 0.33 }, { -1.32, 5.06, -1.188 }, MAIN, { joint = "Body", studs = false }),
		P(
			"ChestPlateLInset",
			{ 0.491, 1.742, 0.088 },
			{ -1.32, 5.06, -1.375 },
			IRON2,
			{ joint = "Body", studs = false }
		),
		P("SidePlateL", { 0.33, 2.2, 1.76 }, { -1.738, 5.005, 0 }, MAIN, { joint = "Body", studs = false }),
		P("SidePlateLInset", { 0.088, 1.584, 1.267 }, { -1.925, 5.005, 0 }, IRON2, { joint = "Body", studs = false }),
		P(
			"ChestVentL1",
			{ 0.11, 0.44, 0.066 },
			{ -1.21, 4.125, -1.408 },
			GLOW,
			{ joint = "Body", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"ChestVentL2",
			{ 0.11, 0.44, 0.066 },
			{ -1.43, 4.125, -1.408 },
			GLOW,
			{ joint = "Body", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P("ChestPlateR", { 0.682, 2.42, 0.33 }, { 1.32, 5.06, -1.188 }, MAIN, { joint = "Body", studs = false }),
		P(
			"ChestPlateRInset",
			{ 0.491, 1.742, 0.088 },
			{ 1.32, 5.06, -1.375 },
			IRON2,
			{ joint = "Body", studs = false }
		),
		P("SidePlateR", { 0.33, 2.2, 1.76 }, { 1.738, 5.005, 0 }, MAIN, { joint = "Body", studs = false }),
		P("SidePlateRInset", { 0.088, 1.584, 1.267 }, { 1.925, 5.005, 0 }, IRON2, { joint = "Body", studs = false }),
		P(
			"ChestVentR1",
			{ 0.11, 0.44, 0.066 },
			{ 1.43, 4.125, -1.408 },
			GLOW,
			{ joint = "Body", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"ChestVentR2",
			{ 0.11, 0.44, 0.066 },
			{ 1.21, 4.125, -1.408 },
			GLOW,
			{ joint = "Body", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"HeartFace",
			{ 1.98, 1.98, 0.088 },
			{ 0, 5.17, -1.232 },
			GLOW,
			{ joint = "Body", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"HeartRim1",
			{ 0.371, 0.176, 0.176 },
			{ 0, 6.16, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"HeartRim2",
			{ 0.371, 0.176, 0.176 },
			{ 0.339, 6.1, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 20, 0 }, studs = false }
		),
		P(
			"HeartRim3",
			{ 0.371, 0.176, 0.176 },
			{ 0.636, 5.928, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 40, 0 }, studs = false }
		),
		P(
			"HeartRim4",
			{ 0.371, 0.176, 0.176 },
			{ 0.857, 5.665, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 60, 0 }, studs = false }
		),
		P(
			"HeartRim5",
			{ 0.371, 0.176, 0.176 },
			{ 0.975, 5.342, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 80, 0 }, studs = false }
		),
		P(
			"HeartRim6",
			{ 0.371, 0.176, 0.176 },
			{ 0.975, 4.998, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 100, 0 }, studs = false }
		),
		P(
			"HeartRim7",
			{ 0.371, 0.176, 0.176 },
			{ 0.857, 4.675, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 120, 0 }, studs = false }
		),
		P(
			"HeartRim8",
			{ 0.371, 0.176, 0.176 },
			{ 0.636, 4.412, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 140, 0 }, studs = false }
		),
		P(
			"HeartRim9",
			{ 0.371, 0.176, 0.176 },
			{ 0.339, 4.24, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, 160, 0 }, studs = false }
		),
		P(
			"HeartRim10",
			{ 0.371, 0.176, 0.176 },
			{ 0, 4.18, -1.254 },
			MAIN,
			{ joint = "Body", rot = { 90, 0, 180 }, studs = false }
		),
		P(
			"HeartRim11",
			{ 0.371, 0.176, 0.176 },
			{ -0.339, 4.24, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -160, 0 }, studs = false }
		),
		P(
			"HeartRim12",
			{ 0.371, 0.176, 0.176 },
			{ -0.636, 4.412, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -140, 0 }, studs = false }
		),
		P(
			"HeartRim13",
			{ 0.371, 0.176, 0.176 },
			{ -0.857, 4.675, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -120, 0 }, studs = false }
		),
		P(
			"HeartRim14",
			{ 0.371, 0.176, 0.176 },
			{ -0.975, 4.998, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -100, 0 }, studs = false }
		),
		P(
			"HeartRim15",
			{ 0.371, 0.176, 0.176 },
			{ -0.975, 5.342, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -80, 0 }, studs = false }
		),
		P(
			"HeartRim16",
			{ 0.371, 0.176, 0.176 },
			{ -0.857, 5.665, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -60, 0 }, studs = false }
		),
		P(
			"HeartRim17",
			{ 0.371, 0.176, 0.176 },
			{ -0.636, 5.928, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -40, 0 }, studs = false }
		),
		P(
			"HeartRim18",
			{ 0.371, 0.176, 0.176 },
			{ -0.339, 6.1, -1.254 },
			MAIN,
			{ joint = "Body", rot = { -90, -20, 0 }, studs = false }
		),
		P(
			"HeartTick1",
			{ 0.088, 0.218, 0.066 },
			{ 0, 5.942, -1.298 },
			INK,
			{ joint = "Body", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"HeartTick2",
			{ 0.055, 0.119, 0.066 },
			{ -0.386, 5.839, -1.298 },
			INK,
			{ joint = "Body", rot = { 0, 180, -30 }, studs = false }
		),
		P(
			"HeartTick3",
			{ 0.055, 0.119, 0.066 },
			{ -0.669, 5.556, -1.298 },
			INK,
			{ joint = "Body", rot = { 0, 180, -60 }, studs = false }
		),
		P(
			"HeartTick4",
			{ 0.088, 0.218, 0.066 },
			{ -0.772, 5.17, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, 90 }, studs = false }
		),
		P(
			"HeartTick5",
			{ 0.055, 0.119, 0.066 },
			{ -0.669, 4.784, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, 60 }, studs = false }
		),
		P(
			"HeartTick6",
			{ 0.055, 0.119, 0.066 },
			{ -0.386, 4.501, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, 30 }, studs = false }
		),
		P(
			"HeartTick7",
			{ 0.088, 0.218, 0.066 },
			{ 0, 4.398, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, 0 }, studs = false }
		),
		P(
			"HeartTick8",
			{ 0.055, 0.119, 0.066 },
			{ 0.386, 4.501, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, -30 }, studs = false }
		),
		P(
			"HeartTick9",
			{ 0.055, 0.119, 0.066 },
			{ 0.669, 4.784, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, -60 }, studs = false }
		),
		P(
			"HeartTick10",
			{ 0.088, 0.218, 0.066 },
			{ 0.772, 5.17, -1.298 },
			INK,
			{ joint = "Body", rot = { -180, 0, -90 }, studs = false }
		),
		P(
			"HeartTick11",
			{ 0.055, 0.119, 0.066 },
			{ 0.669, 5.556, -1.298 },
			INK,
			{ joint = "Body", rot = { 0, 180, 60 }, studs = false }
		),
		P(
			"HeartTick12",
			{ 0.055, 0.119, 0.066 },
			{ 0.386, 5.839, -1.298 },
			INK,
			{ joint = "Body", rot = { 0, 180, 30 }, studs = false }
		),
		P(
			"HeartHand1",
			{ 0.077, 0.495, 0.055 },
			{ 0.159, 5.36, -1.342 },
			INK,
			{ joint = "Body", rot = { 0, 180, 40 }, studs = false }
		),
		P(
			"HeartHand2",
			{ 0.077, 0.713, 0.055 },
			{ -0.335, 5.292, -1.342 },
			INK,
			{ joint = "Body", rot = { 0, 180, -70 }, studs = false }
		),
		P(
			"HeartTooth1",
			{ 0.22, 0.176, 0.22 },
			{ 0, 6.358, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"HeartTooth2",
			{ 0.22, 0.176, 0.22 },
			{ 0.455, 6.268, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 22.5, 0 }, studs = false }
		),
		P(
			"HeartTooth3",
			{ 0.22, 0.176, 0.22 },
			{ 0.84, 6.01, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"HeartTooth4",
			{ 0.22, 0.176, 0.22 },
			{ 1.098, 5.625, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 67.5, 0 }, studs = false }
		),
		P(
			"HeartTooth5",
			{ 0.22, 0.176, 0.22 },
			{ 1.188, 5.17, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"HeartTooth6",
			{ 0.22, 0.176, 0.22 },
			{ 1.098, 4.715, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 112.5, 0 }, studs = false }
		),
		P(
			"HeartTooth7",
			{ 0.22, 0.176, 0.22 },
			{ 0.84, 4.33, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"HeartTooth8",
			{ 0.22, 0.176, 0.22 },
			{ 0.455, 4.072, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, 157.5, 0 }, studs = false }
		),
		P(
			"HeartTooth9",
			{ 0.22, 0.176, 0.22 },
			{ 0, 3.982, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { 90, 0, 180 }, studs = false }
		),
		P(
			"HeartTooth10",
			{ 0.22, 0.176, 0.22 },
			{ -0.455, 4.072, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, -157.5, 0 }, studs = false }
		),
		P(
			"HeartTooth11",
			{ 0.22, 0.176, 0.22 },
			{ -0.84, 4.33, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, -135, 0 }, studs = false }
		),
		P(
			"HeartTooth12",
			{ 0.22, 0.176, 0.22 },
			{ -1.098, 4.715, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, -112.5, 0 }, studs = false }
		),
		P(
			"HeartTooth13",
			{ 0.22, 0.176, 0.22 },
			{ -1.188, 5.17, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"HeartTooth14",
			{ 0.22, 0.176, 0.22 },
			{ -1.098, 5.625, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, -67.5, 0 }, studs = false }
		),
		P(
			"HeartTooth15",
			{ 0.22, 0.176, 0.22 },
			{ -0.84, 6.01, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, -45, 0 }, studs = false }
		),
		P(
			"HeartTooth16",
			{ 0.22, 0.176, 0.22 },
			{ -0.455, 6.268, -1.254 },
			MAIN2,
			{ joint = "Body", rot = { -90, -22.5, 0 }, studs = false }
		),
		P(
			"HeartStar1a",
			{ 0.066, 0.216, 0.043 },
			{ 0, 5.17, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { -90, -78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar1b",
			{ 0.066, 0.216, 0.518 },
			{ -0.275, 5.225, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { 90, 78.69, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar2a",
			{ 0.066, 0.216, 0.043 },
			{ 0, 5.17, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { -90, 11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar2b",
			{ 0.066, 0.216, 0.518 },
			{ 0.055, 5.445, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { 90, -11.31, -90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar3a",
			{ 0.066, 0.216, 0.043 },
			{ 0, 5.17, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { 90, 78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar3b",
			{ 0.066, 0.216, 0.518 },
			{ 0.275, 5.115, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { -90, -78.69, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar4a",
			{ 0.066, 0.216, 0.043 },
			{ 0, 5.17, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { 90, -11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStar4b",
			{ 0.066, 0.216, 0.518 },
			{ -0.055, 4.895, -1.386 },
			LIGHT,
			{ joint = "Body", rot = { -90, 11.31, 90 }, shape = "Wedge", studs = false }
		),
		P(
			"HeartStarCore",
			{ 0.242, 0.242, 0.086 },
			{ 0, 5.17, -1.386 },
			FACE,
			{ joint = "Body", rot = { 0, 180, 45 }, studs = false }
		),
		P(
			"Gear1",
			{ 0.154, 0.66, 0.66 },
			{ -1.1, 6.105, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear1T1",
			{ 0.139, 0.139, 0.825 },
			{ -1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear1T2",
			{ 0.139, 0.139, 0.825 },
			{ -1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear1T3",
			{ 0.139, 0.139, 0.825 },
			{ -1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear1T4",
			{ 0.139, 0.139, 0.825 },
			{ -1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear2",
			{ 0.154, 0.66, 0.66 },
			{ 1.1, 6.105, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear2T1",
			{ 0.139, 0.139, 0.825 },
			{ 1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear2T2",
			{ 0.139, 0.139, 0.825 },
			{ 1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear2T3",
			{ 0.139, 0.139, 0.825 },
			{ 1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear2T4",
			{ 0.139, 0.139, 0.825 },
			{ 1.1, 6.105, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear3",
			{ 0.154, 0.572, 0.572 },
			{ -1.188, 4.345, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear3T1",
			{ 0.12, 0.139, 0.715 },
			{ -1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear3T2",
			{ 0.12, 0.139, 0.715 },
			{ -1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear3T3",
			{ 0.12, 0.139, 0.715 },
			{ -1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear3T4",
			{ 0.12, 0.139, 0.715 },
			{ -1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear4",
			{ 0.154, 0.572, 0.572 },
			{ 1.188, 4.345, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear4T1",
			{ 0.12, 0.139, 0.715 },
			{ 1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear4T2",
			{ 0.12, 0.139, 0.715 },
			{ 1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear4T3",
			{ 0.12, 0.139, 0.715 },
			{ 1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear4T4",
			{ 0.12, 0.139, 0.715 },
			{ 1.188, 4.345, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear5",
			{ 0.154, 0.528, 0.528 },
			{ 0, 6.402, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear5T1",
			{ 0.111, 0.139, 0.66 },
			{ 0, 6.402, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear5T2",
			{ 0.111, 0.139, 0.66 },
			{ 0, 6.402, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear5T3",
			{ 0.111, 0.139, 0.66 },
			{ 0, 6.402, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear5T4",
			{ 0.111, 0.139, 0.66 },
			{ 0, 6.402, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear6",
			{ 0.154, 0.484, 0.484 },
			{ -0.682, 4.015, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear6T1",
			{ 0.102, 0.139, 0.605 },
			{ -0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear6T2",
			{ 0.102, 0.139, 0.605 },
			{ -0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear6T3",
			{ 0.102, 0.139, 0.605 },
			{ -0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear6T4",
			{ 0.102, 0.139, 0.605 },
			{ -0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"Gear7",
			{ 0.154, 0.484, 0.484 },
			{ 0.682, 4.015, -1.298 },
			MAIN,
			{ joint = "Body", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"Gear7T1",
			{ 0.102, 0.139, 0.605 },
			{ 0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"Gear7T2",
			{ 0.102, 0.139, 0.605 },
			{ 0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"Gear7T3",
			{ 0.102, 0.139, 0.605 },
			{ 0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"Gear7T4",
			{ 0.102, 0.139, 0.605 },
			{ 0.682, 4.015, -1.298 },
			MAIN2,
			{ joint = "Body", rot = { -90, 135, 0 }, studs = false }
		),
		P("BackPlate", { 2.86, 2.42, 0.33 }, { 0, 5.06, 1.232 }, MAIN, { joint = "Body", studs = false }),
		P(
			"BackGear",
			{ 0.154, 1.54, 1.54 },
			{ 0, 5.06, 1.452 },
			MAIN2,
			{ joint = "Body", rot = { 0, -90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"BackGearT1",
			{ 0.323, 0.139, 1.925 },
			{ 0, 5.06, 1.452 },
			MAIN,
			{ joint = "Body", rot = { -90, 0, -180 }, studs = false }
		),
		P(
			"BackGearT2",
			{ 0.323, 0.139, 1.925 },
			{ 0, 5.06, 1.452 },
			MAIN,
			{ joint = "Body", rot = { 90, -135, 0 }, studs = false }
		),
		P(
			"BackGearT3",
			{ 0.323, 0.139, 1.925 },
			{ 0, 5.06, 1.452 },
			MAIN,
			{ joint = "Body", rot = { 0, -90, -90 }, studs = false }
		),
		P(
			"BackGearT4",
			{ 0.323, 0.139, 1.925 },
			{ 0, 5.06, 1.452 },
			MAIN,
			{ joint = "Body", rot = { 90, -45, 0 }, studs = false }
		),
		P(
			"HingeHead",
			{ 0.22, 0.22, 0.22 },
			{ 0, 6.82, -0.11 },
			MAIN,
			{ joint = "Head", transparency = 1, studs = false }
		),
		P("Helm", { 1.43, 1.265, 1.32 }, { 0, 7.535, -0.165 }, DARK, { joint = "Head" }),
		P("HelmFrame", { 1.54, 0.242, 1.408 }, { 0, 8.118, -0.165 }, MAIN, { joint = "Head", studs = false }),
		P("Cheeks", { 1.54, 0.682, 0.33 }, { 0, 7.26, -0.77 }, MAIN, { joint = "Head", studs = false }),
		P("Visor", { 1.1, 0.396, 0.11 }, { 0, 7.645, -0.858 }, INK, { joint = "Head", studs = false }),
		P(
			"EyeL",
			{ 0.352, 0.132, 0.066 },
			{ -0.264, 7.667, -0.924 },
			GLOW,
			{ joint = "Head", rot = { 0, 0, 8 }, material = "Neon", studs = false }
		),
		P(
			"PupilL",
			{ 0.11, 0.11, 0.044 },
			{ -0.231, 7.667, -0.968 },
			TIP,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"GlintL",
			{ 0.055, 0.055, 0.033 },
			{ -0.352, 7.711, -0.979 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"EyeR",
			{ 0.352, 0.132, 0.066 },
			{ 0.264, 7.667, -0.924 },
			GLOW,
			{ joint = "Head", rot = { 0, 0, -8 }, material = "Neon", studs = false }
		),
		P(
			"PupilR",
			{ 0.11, 0.11, 0.044 },
			{ 0.231, 7.667, -0.968 },
			TIP,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"GlintR",
			{ 0.055, 0.055, 0.033 },
			{ 0.352, 7.711, -0.979 },
			GLINT,
			{ joint = "Head", material = "Neon", studs = false }
		),
		P(
			"Crown1",
			{ 0.33, 0.726, 0.33 },
			{ 0, 8.591, -0.165 },
			MAIN,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown1Tip",
			{ 0.182, 0.544, 0.182 },
			{ 0, 9.196, -0.165 },
			LIGHT,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown2",
			{ 0.264, 0.495, 0.264 },
			{ -0.462, 8.476, -0.275 },
			MAIN,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown2Tip",
			{ 0.145, 0.371, 0.145 },
			{ -0.462, 8.888, -0.275 },
			LIGHT,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown3",
			{ 0.264, 0.495, 0.264 },
			{ 0.462, 8.476, -0.275 },
			MAIN,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown3Tip",
			{ 0.145, 0.371, 0.145 },
			{ 0.462, 8.888, -0.275 },
			LIGHT,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown4",
			{ 0.264, 0.363, 0.264 },
			{ -0.55, 8.41, 0.275 },
			MAIN,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown4Tip",
			{ 0.145, 0.272, 0.145 },
			{ -0.55, 8.712, 0.275 },
			LIGHT,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown5",
			{ 0.264, 0.363, 0.264 },
			{ 0.55, 8.41, 0.275 },
			MAIN,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"Crown5Tip",
			{ 0.145, 0.272, 0.145 },
			{ 0.55, 8.712, 0.275 },
			LIGHT,
			{ joint = "Head", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"BrowGear",
			{ 0.154, 0.44, 0.44 },
			{ 0, 8.03, -0.88 },
			MAIN,
			{ joint = "Head", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"BrowGearT1",
			{ 0.092, 0.139, 0.55 },
			{ 0, 8.03, -0.88 },
			MAIN2,
			{ joint = "Head", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"BrowGearT2",
			{ 0.092, 0.139, 0.55 },
			{ 0, 8.03, -0.88 },
			MAIN2,
			{ joint = "Head", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"BrowGearT3",
			{ 0.092, 0.139, 0.55 },
			{ 0, 8.03, -0.88 },
			MAIN2,
			{ joint = "Head", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"BrowGearT4",
			{ 0.092, 0.139, 0.55 },
			{ 0, 8.03, -0.88 },
			MAIN2,
			{ joint = "Head", rot = { -90, 135, 0 }, studs = false }
		),
		P(
			"HingeArmL",
			{ 0.22, 0.22, 0.22 },
			{ -2.035, 6.05, 0 },
			MAIN,
			{ joint = "ArmL", transparency = 1, studs = false }
		),
		P("PauldronL", { 1.925, 1.595, 1.925 }, { -2.475, 6.545, 0 }, MAIN, { joint = "ArmL" }),
		P("PauldronInsetL", { 0.088, 1.155, 1.43 }, { -3.454, 6.545, 0 }, DARK, { joint = "ArmL", studs = false }),
		P(
			"ShoulderClockLFace",
			{ 1.1, 1.1, 0.088 },
			{ -3.52, 6.545, 0 },
			FACE,
			{ joint = "ArmL", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"ShoulderClockLRim1",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 7.095, 0 },
			MAIN,
			{ joint = "ArmL", rot = { -90, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim2",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 7.021, -0.275 },
			MAIN,
			{ joint = "ArmL", rot = { -120, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim3",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.82, -0.476 },
			MAIN,
			{ joint = "ArmL", rot = { -150, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim4",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.545, -0.55 },
			MAIN,
			{ joint = "ArmL", rot = { -180, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim5",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.27, -0.476 },
			MAIN,
			{ joint = "ArmL", rot = { 150, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim6",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.069, -0.275 },
			MAIN,
			{ joint = "ArmL", rot = { 120, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim7",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 5.995, 0 },
			MAIN,
			{ joint = "ArmL", rot = { 90, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim8",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.069, 0.275 },
			MAIN,
			{ joint = "ArmL", rot = { 60, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim9",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.27, 0.476 },
			MAIN,
			{ joint = "ArmL", rot = { 30, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim10",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.545, 0.55 },
			MAIN,
			{ joint = "ArmL", rot = { 0, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim11",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 6.82, 0.476 },
			MAIN,
			{ joint = "ArmL", rot = { -30, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLRim12",
			{ 0.307, 0.176, 0.176 },
			{ -3.542, 7.021, 0.275 },
			MAIN,
			{ joint = "ArmL", rot = { -60, 0, 90 }, studs = false }
		),
		P(
			"ShoulderClockLTick1",
			{ 0.088, 0.121, 0.066 },
			{ -3.586, 6.974, 0 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 0 }, studs = false }
		),
		P(
			"ShoulderClockLTick2",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.917, 0.214 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, -30 }, studs = false }
		),
		P(
			"ShoulderClockLTick3",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.76, 0.372 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, -60 }, studs = false }
		),
		P(
			"ShoulderClockLTick4",
			{ 0.088, 0.121, 0.066 },
			{ -3.586, 6.545, 0.429 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, -90 }, studs = false }
		),
		P(
			"ShoulderClockLTick5",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.33, 0.372 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, -120 }, studs = false }
		),
		P(
			"ShoulderClockLTick6",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.173, 0.214 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, -150 }, studs = false }
		),
		P(
			"ShoulderClockLTick7",
			{ 0.088, 0.121, 0.066 },
			{ -3.586, 6.116, 0 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 180 }, studs = false }
		),
		P(
			"ShoulderClockLTick8",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.173, -0.214 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 150 }, studs = false }
		),
		P(
			"ShoulderClockLTick9",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.33, -0.372 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 120 }, studs = false }
		),
		P(
			"ShoulderClockLTick10",
			{ 0.088, 0.121, 0.066 },
			{ -3.586, 6.545, -0.429 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 90 }, studs = false }
		),
		P(
			"ShoulderClockLTick11",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.76, -0.372 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 60 }, studs = false }
		),
		P(
			"ShoulderClockLTick12",
			{ 0.055, 0.066, 0.066 },
			{ -3.586, 6.917, -0.214 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 30 }, studs = false }
		),
		P(
			"ShoulderClockLHand1",
			{ 0.077, 0.275, 0.055 },
			{ -3.63, 6.633, -0.105 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, 50 }, studs = false }
		),
		P(
			"ShoulderClockLHand2",
			{ 0.077, 0.396, 0.055 },
			{ -3.63, 6.716, 0.099 },
			INK,
			{ joint = "ArmL", rot = { 0, -90, -30 }, studs = false }
		),
		P("PauldronTopL", { 1.65, 0.264, 1.65 }, { -2.475, 7.48, 0 }, DARK, { joint = "ArmL", studs = false }),
		P(
			"ShoulderSpireL1",
			{ 0.242, 0.561, 0.242 },
			{ -3.08, 7.871, -0.605 },
			MAIN,
			{ joint = "ArmL", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireL1Tip",
			{ 0.133, 0.421, 0.133 },
			{ -3.08, 8.338, -0.605 },
			LIGHT,
			{ joint = "ArmL", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireL2",
			{ 0.242, 0.462, 0.242 },
			{ -3.08, 7.821, 0.605 },
			MAIN,
			{ joint = "ArmL", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireL2Tip",
			{ 0.133, 0.347, 0.133 },
			{ -3.08, 8.206, 0.605 },
			LIGHT,
			{ joint = "ArmL", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireL3",
			{ 0.242, 0.396, 0.242 },
			{ -2.255, 7.788, 0 },
			MAIN,
			{ joint = "ArmL", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireL3Tip",
			{ 0.133, 0.297, 0.133 },
			{ -2.255, 8.118, 0 },
			LIGHT,
			{ joint = "ArmL", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"BannerL",
			{ 0.77, 2.09, 0.077 },
			{ -2.53, 4.73, -1.012 },
			RED,
			{ joint = "ArmL", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"BannerLTrimL",
			{ 0.088, 2.09, 0.099 },
			{ -2.167, 4.73, -1.023 },
			MAIN,
			{ joint = "ArmL", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"BannerLTrimR",
			{ 0.088, 2.09, 0.099 },
			{ -2.893, 4.73, -1.023 },
			MAIN,
			{ joint = "ArmL", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"BannerLTipa",
			{ 0.077, 0.385, 0.385 },
			{ -2.338, 3.493, -1.012 },
			RED,
			{ joint = "ArmL", rot = { 0, -90, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"BannerLTipb",
			{ 0.077, 0.385, 0.385 },
			{ -2.722, 3.493, -1.012 },
			RED,
			{ joint = "ArmL", rot = { 0, 90, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"BannerLEmblem",
			{ 0.154, 0.431, 0.431 },
			{ -2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmL", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"BannerLEmblemT1",
			{ 0.091, 0.139, 0.539 },
			{ -2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmL", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"BannerLEmblemT2",
			{ 0.091, 0.139, 0.539 },
			{ -2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmL", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"BannerLEmblemT3",
			{ 0.091, 0.139, 0.539 },
			{ -2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmL", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"BannerLEmblemT4",
			{ 0.091, 0.139, 0.539 },
			{ -2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmL", rot = { -90, 135, 0 }, studs = false }
		),
		P("UpperArmL", { 0.88, 1.43, 0.88 }, { -2.612, 5.143, -0.055 }, DARK, { joint = "ArmL" }),
		P(
			"PistonL1",
			{ 1.21, 0.264, 0.264 },
			{ -3.135, 5.115, -0.275 },
			MAIN,
			{ joint = "ArmL", rot = { 0, -90, 90 }, shape = "Cylinder", studs = false }
		),
		P(
			"PistonL2",
			{ 1.21, 0.264, 0.264 },
			{ -3.135, 5.115, 0.275 },
			MAIN,
			{ joint = "ArmL", rot = { 0, -90, 90 }, shape = "Cylinder", studs = false }
		),
		P(
			"ElbowL",
			{ 0.77, 0.935, 0.935 },
			{ -2.64, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmL", shape = "Cylinder", studs = false }
		),
		P(
			"ElbowGearL",
			{ 0.154, 0.836, 0.836 },
			{ -3.058, 4.235, -0.11 },
			MAIN,
			{ joint = "ArmL", rot = { 0, 180, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"ElbowGearLT1",
			{ 0.176, 0.139, 1.045 },
			{ -3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmL", rot = { -90, 0, 90 }, studs = false }
		),
		P(
			"ElbowGearLT2",
			{ 0.176, 0.139, 1.045 },
			{ -3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmL", rot = { -135, 0, 90 }, studs = false }
		),
		P(
			"ElbowGearLT3",
			{ 0.176, 0.139, 1.045 },
			{ -3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmL", rot = { -180, 0, 90 }, studs = false }
		),
		P(
			"ElbowGearLT4",
			{ 0.176, 0.139, 1.045 },
			{ -3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmL", rot = { 135, 0, 90 }, studs = false }
		),
		P("ForearmL", { 1.265, 1.65, 1.265 }, { -2.695, 3.135, -0.165 }, MAIN, { joint = "ArmL" }),
		P("ForearmLInset", { 0.911, 1.188, 0.088 }, { -2.695, 3.135, -0.82 }, DARK, { joint = "ArmL", studs = false }),
		P(
			"ArmVentL1",
			{ 0.11, 0.77, 0.066 },
			{ -3.377, 3.19, -0.275 },
			GLOW,
			{ joint = "ArmL", rot = { 0, -90, 0 }, material = "Neon", studs = false }
		),
		P(
			"ArmVentL2",
			{ 0.11, 0.77, 0.066 },
			{ -3.377, 3.19, -0.055 },
			GLOW,
			{ joint = "ArmL", rot = { 0, -90, 0 }, material = "Neon", studs = false }
		),
		P("ArmBandL", { 1.32, 0.176, 1.32 }, { -2.695, 3.85, -0.165 }, MAIN2, { joint = "ArmL", studs = false }),
		P("FistL", { 1.375, 1.1, 1.375 }, { -2.695, 1.815, -0.275 }, DARK, { joint = "ArmL" }),
		P("KnuckleL1", { 0.286, 0.33, 0.33 }, { -3.157, 2.145, -1.012 }, MAIN, { joint = "ArmL", studs = false }),
		P("FingerL1", { 0.286, 0.462, 0.264 }, { -3.157, 1.562, -1.012 }, IRON2, { joint = "ArmL", studs = false }),
		P("KnuckleL2", { 0.286, 0.33, 0.33 }, { -2.849, 2.145, -1.012 }, MAIN, { joint = "ArmL", studs = false }),
		P("FingerL2", { 0.286, 0.462, 0.264 }, { -2.849, 1.562, -1.012 }, IRON2, { joint = "ArmL", studs = false }),
		P("KnuckleL3", { 0.286, 0.33, 0.33 }, { -2.541, 2.145, -1.012 }, MAIN, { joint = "ArmL", studs = false }),
		P("FingerL3", { 0.286, 0.462, 0.264 }, { -2.541, 1.562, -1.012 }, IRON2, { joint = "ArmL", studs = false }),
		P("KnuckleL4", { 0.286, 0.33, 0.33 }, { -2.233, 2.145, -1.012 }, MAIN, { joint = "ArmL", studs = false }),
		P("FingerL4", { 0.286, 0.462, 0.264 }, { -2.233, 1.562, -1.012 }, IRON2, { joint = "ArmL", studs = false }),
		P(
			"ThumbL",
			{ 0.33, 0.55, 0.33 },
			{ -2.046, 1.925, -0.77 },
			IRON2,
			{ joint = "ArmL", rot = { 0, 0, -20 }, studs = false }
		),
		P(
			"HingeArmR",
			{ 0.22, 0.22, 0.22 },
			{ 2.035, 6.05, 0 },
			MAIN,
			{ joint = "ArmR", transparency = 1, studs = false }
		),
		P("PauldronR", { 1.925, 1.595, 1.925 }, { 2.475, 6.545, 0 }, MAIN, { joint = "ArmR" }),
		P("PauldronInsetR", { 0.088, 1.155, 1.43 }, { 3.454, 6.545, 0 }, DARK, { joint = "ArmR", studs = false }),
		P(
			"ShoulderClockRFace",
			{ 1.1, 1.1, 0.088 },
			{ 3.52, 6.545, 0 },
			FACE,
			{ joint = "ArmR", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"ShoulderClockRRim1",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 7.095, 0 },
			MAIN,
			{ joint = "ArmR", rot = { -90, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim2",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 7.021, 0.275 },
			MAIN,
			{ joint = "ArmR", rot = { -60, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim3",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.82, 0.476 },
			MAIN,
			{ joint = "ArmR", rot = { -30, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim4",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.545, 0.55 },
			MAIN,
			{ joint = "ArmR", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim5",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.27, 0.476 },
			MAIN,
			{ joint = "ArmR", rot = { 30, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim6",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.069, 0.275 },
			MAIN,
			{ joint = "ArmR", rot = { 60, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim7",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 5.995, 0 },
			MAIN,
			{ joint = "ArmR", rot = { 90, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim8",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.069, -0.275 },
			MAIN,
			{ joint = "ArmR", rot = { 120, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim9",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.27, -0.476 },
			MAIN,
			{ joint = "ArmR", rot = { 150, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim10",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.545, -0.55 },
			MAIN,
			{ joint = "ArmR", rot = { 180, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim11",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 6.82, -0.476 },
			MAIN,
			{ joint = "ArmR", rot = { -150, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRRim12",
			{ 0.307, 0.176, 0.176 },
			{ 3.542, 7.021, -0.275 },
			MAIN,
			{ joint = "ArmR", rot = { -120, 0, -90 }, studs = false }
		),
		P(
			"ShoulderClockRTick1",
			{ 0.088, 0.121, 0.066 },
			{ 3.586, 6.974, 0 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 0 }, studs = false }
		),
		P(
			"ShoulderClockRTick2",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.917, -0.214 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, -30 }, studs = false }
		),
		P(
			"ShoulderClockRTick3",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.76, -0.372 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, -60 }, studs = false }
		),
		P(
			"ShoulderClockRTick4",
			{ 0.088, 0.121, 0.066 },
			{ 3.586, 6.545, -0.429 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"ShoulderClockRTick5",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.33, -0.372 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, -120 }, studs = false }
		),
		P(
			"ShoulderClockRTick6",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.173, -0.214 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, -150 }, studs = false }
		),
		P(
			"ShoulderClockRTick7",
			{ 0.088, 0.121, 0.066 },
			{ 3.586, 6.116, 0 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 180 }, studs = false }
		),
		P(
			"ShoulderClockRTick8",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.173, 0.214 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 150 }, studs = false }
		),
		P(
			"ShoulderClockRTick9",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.33, 0.372 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 120 }, studs = false }
		),
		P(
			"ShoulderClockRTick10",
			{ 0.088, 0.121, 0.066 },
			{ 3.586, 6.545, 0.429 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 90 }, studs = false }
		),
		P(
			"ShoulderClockRTick11",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.76, 0.372 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 60 }, studs = false }
		),
		P(
			"ShoulderClockRTick12",
			{ 0.055, 0.066, 0.066 },
			{ 3.586, 6.917, 0.214 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 30 }, studs = false }
		),
		P(
			"ShoulderClockRHand1",
			{ 0.077, 0.275, 0.055 },
			{ 3.63, 6.633, 0.105 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, 50 }, studs = false }
		),
		P(
			"ShoulderClockRHand2",
			{ 0.077, 0.396, 0.055 },
			{ 3.63, 6.716, -0.099 },
			INK,
			{ joint = "ArmR", rot = { 0, 90, -30 }, studs = false }
		),
		P("PauldronTopR", { 1.65, 0.264, 1.65 }, { 2.475, 7.48, 0 }, DARK, { joint = "ArmR", studs = false }),
		P(
			"ShoulderSpireR1",
			{ 0.242, 0.561, 0.242 },
			{ 3.08, 7.871, -0.605 },
			MAIN,
			{ joint = "ArmR", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireR1Tip",
			{ 0.133, 0.421, 0.133 },
			{ 3.08, 8.338, -0.605 },
			LIGHT,
			{ joint = "ArmR", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireR2",
			{ 0.242, 0.462, 0.242 },
			{ 3.08, 7.821, 0.605 },
			MAIN,
			{ joint = "ArmR", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireR2Tip",
			{ 0.133, 0.347, 0.133 },
			{ 3.08, 8.206, 0.605 },
			LIGHT,
			{ joint = "ArmR", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireR3",
			{ 0.242, 0.396, 0.242 },
			{ 2.255, 7.788, 0 },
			MAIN,
			{ joint = "ArmR", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"ShoulderSpireR3Tip",
			{ 0.133, 0.297, 0.133 },
			{ 2.255, 8.118, 0 },
			LIGHT,
			{ joint = "ArmR", rot = { 0, -135, 0 }, studs = false }
		),
		P(
			"BannerR",
			{ 0.77, 2.09, 0.077 },
			{ 2.53, 4.73, -1.012 },
			RED,
			{ joint = "ArmR", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"BannerRTrimL",
			{ 0.088, 2.09, 0.099 },
			{ 2.893, 4.73, -1.023 },
			MAIN,
			{ joint = "ArmR", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"BannerRTrimR",
			{ 0.088, 2.09, 0.099 },
			{ 2.167, 4.73, -1.023 },
			MAIN,
			{ joint = "ArmR", rot = { 0, 180, 0 }, studs = false }
		),
		P(
			"BannerRTipa",
			{ 0.077, 0.385, 0.385 },
			{ 2.722, 3.493, -1.012 },
			RED,
			{ joint = "ArmR", rot = { 0, -90, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"BannerRTipb",
			{ 0.077, 0.385, 0.385 },
			{ 2.338, 3.493, -1.012 },
			RED,
			{ joint = "ArmR", rot = { 0, 90, 180 }, shape = "Wedge", studs = false }
		),
		P(
			"BannerREmblem",
			{ 0.154, 0.431, 0.431 },
			{ 2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmR", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"BannerREmblemT1",
			{ 0.091, 0.139, 0.539 },
			{ 2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmR", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"BannerREmblemT2",
			{ 0.091, 0.139, 0.539 },
			{ 2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmR", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"BannerREmblemT3",
			{ 0.091, 0.139, 0.539 },
			{ 2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmR", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"BannerREmblemT4",
			{ 0.091, 0.139, 0.539 },
			{ 2.53, 4.835, -1.067 },
			MAIN,
			{ joint = "ArmR", rot = { -90, 135, 0 }, studs = false }
		),
		P("UpperArmR", { 0.88, 1.43, 0.88 }, { 2.612, 5.143, -0.055 }, DARK, { joint = "ArmR" }),
		P(
			"PistonR1",
			{ 1.21, 0.264, 0.264 },
			{ 3.135, 5.115, -0.275 },
			MAIN,
			{ joint = "ArmR", rot = { 0, -90, 90 }, shape = "Cylinder", studs = false }
		),
		P(
			"PistonR2",
			{ 1.21, 0.264, 0.264 },
			{ 3.135, 5.115, 0.275 },
			MAIN,
			{ joint = "ArmR", rot = { 0, -90, 90 }, shape = "Cylinder", studs = false }
		),
		P(
			"ElbowR",
			{ 0.77, 0.935, 0.935 },
			{ 2.64, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmR", shape = "Cylinder", studs = false }
		),
		P(
			"ElbowGearR",
			{ 0.154, 0.836, 0.836 },
			{ 3.058, 4.235, -0.11 },
			MAIN,
			{ joint = "ArmR", shape = "Cylinder", studs = false }
		),
		P(
			"ElbowGearRT1",
			{ 0.176, 0.139, 1.045 },
			{ 3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmR", rot = { -90, 0, -90 }, studs = false }
		),
		P(
			"ElbowGearRT2",
			{ 0.176, 0.139, 1.045 },
			{ 3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmR", rot = { -45, 0, -90 }, studs = false }
		),
		P(
			"ElbowGearRT3",
			{ 0.176, 0.139, 1.045 },
			{ 3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmR", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"ElbowGearRT4",
			{ 0.176, 0.139, 1.045 },
			{ 3.058, 4.235, -0.11 },
			MAIN2,
			{ joint = "ArmR", rot = { 45, 0, -90 }, studs = false }
		),
		P("ForearmR", { 1.265, 1.65, 1.265 }, { 2.695, 3.135, -0.165 }, MAIN, { joint = "ArmR" }),
		P("ForearmRInset", { 0.911, 1.188, 0.088 }, { 2.695, 3.135, -0.82 }, DARK, { joint = "ArmR", studs = false }),
		P(
			"ArmVentR1",
			{ 0.11, 0.77, 0.066 },
			{ 3.377, 3.19, -0.055 },
			GLOW,
			{ joint = "ArmR", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P(
			"ArmVentR2",
			{ 0.11, 0.77, 0.066 },
			{ 3.377, 3.19, -0.275 },
			GLOW,
			{ joint = "ArmR", rot = { 0, 90, 0 }, material = "Neon", studs = false }
		),
		P("ArmBandR", { 1.32, 0.176, 1.32 }, { 2.695, 3.85, -0.165 }, MAIN2, { joint = "ArmR", studs = false }),
		P("FistR", { 1.375, 1.1, 1.375 }, { 2.695, 1.815, -0.275 }, DARK, { joint = "ArmR" }),
		P("KnuckleR1", { 0.286, 0.33, 0.33 }, { 2.233, 2.145, -1.012 }, MAIN, { joint = "ArmR", studs = false }),
		P("FingerR1", { 0.286, 0.462, 0.264 }, { 2.233, 1.562, -1.012 }, IRON2, { joint = "ArmR", studs = false }),
		P("KnuckleR2", { 0.286, 0.33, 0.33 }, { 2.541, 2.145, -1.012 }, MAIN, { joint = "ArmR", studs = false }),
		P("FingerR2", { 0.286, 0.462, 0.264 }, { 2.541, 1.562, -1.012 }, IRON2, { joint = "ArmR", studs = false }),
		P("KnuckleR3", { 0.286, 0.33, 0.33 }, { 2.849, 2.145, -1.012 }, MAIN, { joint = "ArmR", studs = false }),
		P("FingerR3", { 0.286, 0.462, 0.264 }, { 2.849, 1.562, -1.012 }, IRON2, { joint = "ArmR", studs = false }),
		P("KnuckleR4", { 0.286, 0.33, 0.33 }, { 3.157, 2.145, -1.012 }, MAIN, { joint = "ArmR", studs = false }),
		P("FingerR4", { 0.286, 0.462, 0.264 }, { 3.157, 1.562, -1.012 }, IRON2, { joint = "ArmR", studs = false }),
		P(
			"ThumbR",
			{ 0.33, 0.55, 0.33 },
			{ 2.046, 1.925, -0.77 },
			IRON2,
			{ joint = "ArmR", rot = { 0, 0, 20 }, studs = false }
		),
		P(
			"HingeLegL",
			{ 0.22, 0.22, 0.22 },
			{ -0.825, 2.64, 0.055 },
			MAIN,
			{ joint = "LegL", transparency = 1, studs = false }
		),
		P("ThighL", { 1.1, 1.1, 1.21 }, { -0.88, 2.2, 0.055 }, MAIN, { joint = "LegL" }),
		P("ThighInsetL", { 0.77, 0.77, 0.088 }, { -0.88, 2.2, -0.583 }, DARK, { joint = "LegL", studs = false }),
		P(
			"HipGearL",
			{ 0.154, 1.1, 1.1 },
			{ -1.485, 2.53, 0.055 },
			MAIN,
			{ joint = "LegL", rot = { 0, 180, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"HipGearLT1",
			{ 0.231, 0.139, 1.375 },
			{ -1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegL", rot = { -90, 0, 90 }, studs = false }
		),
		P(
			"HipGearLT2",
			{ 0.231, 0.139, 1.375 },
			{ -1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegL", rot = { -135, 0, 90 }, studs = false }
		),
		P(
			"HipGearLT3",
			{ 0.231, 0.139, 1.375 },
			{ -1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegL", rot = { -180, 0, 90 }, studs = false }
		),
		P(
			"HipGearLT4",
			{ 0.231, 0.139, 1.375 },
			{ -1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegL", rot = { 135, 0, 90 }, studs = false }
		),
		P("ShinL", { 1.155, 1.32, 1.265 }, { -0.902, 1.045, 0.055 }, DARK, { joint = "LegL" }),
		P(
			"ShinVentL1",
			{ 0.11, 0.605, 0.066 },
			{ -0.792, 1.078, -0.616 },
			GLOW,
			{ joint = "LegL", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"ShinVentL2",
			{ 0.11, 0.605, 0.066 },
			{ -1.012, 1.078, -0.616 },
			GLOW,
			{ joint = "LegL", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"KneeGearL",
			{ 0.154, 0.66, 0.66 },
			{ -0.902, 1.705, -0.682 },
			MAIN,
			{ joint = "LegL", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"KneeGearLT1",
			{ 0.139, 0.139, 0.825 },
			{ -0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegL", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"KneeGearLT2",
			{ 0.139, 0.139, 0.825 },
			{ -0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegL", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"KneeGearLT3",
			{ 0.139, 0.139, 0.825 },
			{ -0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegL", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"KneeGearLT4",
			{ 0.139, 0.139, 0.825 },
			{ -0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegL", rot = { -90, 135, 0 }, studs = false }
		),
		P("BootL", { 1.43, 0.462, 1.76 }, { -0.924, 0.231, -0.132 }, MAIN, { joint = "LegL" }),
		P("BootToeL", { 1.32, 0.33, 0.44 }, { -0.924, 0.165, -1.078 }, DARK, { joint = "LegL", studs = false }),
		P(
			"HingeLegR",
			{ 0.22, 0.22, 0.22 },
			{ 0.825, 2.64, 0.055 },
			MAIN,
			{ joint = "LegR", transparency = 1, studs = false }
		),
		P("ThighR", { 1.1, 1.1, 1.21 }, { 0.88, 2.2, 0.055 }, MAIN, { joint = "LegR" }),
		P("ThighInsetR", { 0.77, 0.77, 0.088 }, { 0.88, 2.2, -0.583 }, DARK, { joint = "LegR", studs = false }),
		P(
			"HipGearR",
			{ 0.154, 1.1, 1.1 },
			{ 1.485, 2.53, 0.055 },
			MAIN,
			{ joint = "LegR", shape = "Cylinder", studs = false }
		),
		P(
			"HipGearRT1",
			{ 0.231, 0.139, 1.375 },
			{ 1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegR", rot = { -90, 0, -90 }, studs = false }
		),
		P(
			"HipGearRT2",
			{ 0.231, 0.139, 1.375 },
			{ 1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegR", rot = { -45, 0, -90 }, studs = false }
		),
		P(
			"HipGearRT3",
			{ 0.231, 0.139, 1.375 },
			{ 1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegR", rot = { 0, 0, -90 }, studs = false }
		),
		P(
			"HipGearRT4",
			{ 0.231, 0.139, 1.375 },
			{ 1.485, 2.53, 0.055 },
			MAIN2,
			{ joint = "LegR", rot = { 45, 0, -90 }, studs = false }
		),
		P("ShinR", { 1.155, 1.32, 1.265 }, { 0.902, 1.045, 0.055 }, DARK, { joint = "LegR" }),
		P(
			"ShinVentR1",
			{ 0.11, 0.605, 0.066 },
			{ 1.012, 1.078, -0.616 },
			GLOW,
			{ joint = "LegR", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"ShinVentR2",
			{ 0.11, 0.605, 0.066 },
			{ 0.792, 1.078, -0.616 },
			GLOW,
			{ joint = "LegR", rot = { 0, 180, 0 }, material = "Neon", studs = false }
		),
		P(
			"KneeGearR",
			{ 0.154, 0.66, 0.66 },
			{ 0.902, 1.705, -0.682 },
			MAIN,
			{ joint = "LegR", rot = { 0, 90, 0 }, shape = "Cylinder", studs = false }
		),
		P(
			"KneeGearRT1",
			{ 0.139, 0.139, 0.825 },
			{ 0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegR", rot = { -90, 0, 0 }, studs = false }
		),
		P(
			"KneeGearRT2",
			{ 0.139, 0.139, 0.825 },
			{ 0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegR", rot = { -90, 45, 0 }, studs = false }
		),
		P(
			"KneeGearRT3",
			{ 0.139, 0.139, 0.825 },
			{ 0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegR", rot = { 0, 90, -90 }, studs = false }
		),
		P(
			"KneeGearRT4",
			{ 0.139, 0.139, 0.825 },
			{ 0.902, 1.705, -0.682 },
			MAIN2,
			{ joint = "LegR", rot = { -90, 135, 0 }, studs = false }
		),
		P("BootR", { 1.43, 0.462, 1.76 }, { 0.924, 0.231, -0.132 }, MAIN, { joint = "LegR" }),
		P("BootToeR", { 1.32, 0.33, 0.44 }, { 0.924, 0.165, -1.078 }, DARK, { joint = "LegR", studs = false }),
	},
}

return { egg = egg, pet = pet }
