--!strict
-- Zone 1: Meadow eggs. Keys match Config/Pets `model`. Patterns hint at the pet inside.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Parent.Kit)

local P, rgb = Kit.part, Color3.fromRGB

-- Palettes
local BEE, BEE_DK, INK, WING = rgb(255, 205, 40), rgb(240, 165, 30), rgb(40, 35, 35), rgb(225, 245, 255)

local Eggs: { [string]: Builder.Spec } = {}

-- Premium hero spec (Models/Premium/SproutPup.luau, docs/EggPetPlan.md).
Eggs.SproutPup = require(script.Parent.Parent.Premium.SproutPup).egg

-- Uncommon: bumblebee stripes, glassy wing nubs and antennae.
Eggs.BumbleBloc = {
	parts = Kit.join(Kit.eggShell({ BEE_DK, BEE, INK, BEE, INK, BEE, BEE }), {
		P(
			"WingL",
			{ 0.1, 1.0, 1.3 },
			{ -1.45, 2.35, 0.35 },
			WING,
			{ joint = "Body", rot = { 0, 0, 15 }, material = "Glass", transparency = 0.35 }
		),
		P(
			"WingR",
			{ 0.1, 1.0, 1.3 },
			{ 1.45, 2.35, 0.35 },
			WING,
			{ joint = "Body", rot = { 0, 0, -15 }, material = "Glass", transparency = 0.35 }
		),
		P("AntennaL", { 0.1, 0.6, 0.1 }, { -0.25, 3.9, 0 }, INK, { joint = "Body", rot = { 0, 0, 20 } }),
		P("AntennaR", { 0.1, 0.6, 0.1 }, { 0.25, 3.9, 0 }, INK, { joint = "Body", rot = { 0, 0, -20 } }),
		P("AntTipL", { 0.3, 0.3, 0.3 }, { -0.38, 4.22, 0 }, INK, { joint = "Body", shape = "Ball" }),
		P("AntTipR", { 0.3, 0.3, 0.3 }, { 0.38, 4.22, 0 }, INK, { joint = "Body", shape = "Ball" }),
		Kit.onShell("Honey", "F", 0.55, 1.15, 0.3, 0.45, rgb(255, 170, 20)),
	}),
}

-- Premium hero spec (Models/Premium/MeadowStag.luau, docs/EggPetPlan.md).
Eggs.MeadowStag = require(script.Parent.Parent.Premium.MeadowStag).egg

return Eggs
