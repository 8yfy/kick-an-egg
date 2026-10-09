--!strict
-- Zone 1: Meadow eggs. Keys match Config/Pets `model`. Patterns hint at the pet inside.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Parent.Kit)

local P, rgb = Kit.part, Color3.fromRGB

-- Palettes
local LEAF, LEAF_LT, LEAF_DK, CREAM = rgb(120, 205, 80), rgb(170, 232, 115), rgb(65, 145, 55), rgb(245, 238, 195)
local BEE, BEE_DK, INK, WING = rgb(255, 205, 40), rgb(240, 165, 30), rgb(40, 35, 35), rgb(225, 245, 255)
local FAWN, FAWN_LT, BARK, PINK = rgb(195, 135, 78), rgb(245, 225, 180), rgb(115, 80, 50), rgb(255, 140, 190)

local Eggs: { [string]: Builder.Spec } = {}

-- Common: leafy green egg with paw-print spots and a sprout on top.
Eggs.SproutPup = {
	parts = Kit.join(Kit.eggShell({ CREAM, LEAF, LEAF_LT, LEAF, LEAF_LT, LEAF, LEAF_DK }), {
		Kit.onShell("Spot1", "F", -0.5, 1.35, 0.55, 0.5, LEAF_DK),
		Kit.onShell("Spot2", "F", 0.55, 2.2, 0.45, 0.45, LEAF_DK),
		Kit.onShell("Spot3", "R", 0.3, 1.3, 0.5, 0.5, LEAF_DK),
		Kit.onShell("Spot4", "L", -0.25, 2.1, 0.45, 0.45, LEAF_DK),
		Kit.onShell("Spot5", "B", 0.4, 1.5, 0.55, 0.5, LEAF_DK),
		Kit.onShell("Spot6", "B", -0.5, 2.3, 0.4, 0.4, LEAF_DK),
		P("Stem", { 0.15, 0.45, 0.15 }, { 0, 3.9, 0 }, LEAF_DK, { joint = "Body" }),
		P("SproutL", { 0.55, 0.1, 0.3 }, { -0.3, 4.1, 0 }, LEAF_LT, { joint = "Body", rot = { 0, 0, -25 } }),
		P("SproutR", { 0.55, 0.1, 0.3 }, { 0.3, 4.1, 0 }, LEAF_LT, { joint = "Body", rot = { 0, 0, 25 } }),
	}),
}

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

-- Rare: fawn with cream spots, antler nubs, a blossom, and the Rare Neon band + glow.
Eggs.MeadowStag = {
	parts = Kit.join(Kit.eggShell({ FAWN_LT, FAWN, FAWN, FAWN, FAWN, FAWN, BARK }), {
		Kit.eggBand(3, "Rare"),
		Kit.onShell("Spot1", "F", -0.55, 2.2, 0.4, 0.35, FAWN_LT),
		Kit.onShell("Spot2", "F", 0.5, 2.75, 0.35, 0.3, FAWN_LT),
		Kit.onShell("Spot3", "L", 0.4, 2.2, 0.4, 0.35, FAWN_LT),
		Kit.onShell("Spot4", "R", -0.3, 2.75, 0.35, 0.3, FAWN_LT),
		Kit.onShell("Spot5", "B", 0.3, 2.2, 0.45, 0.35, FAWN_LT),
		Kit.onShell("Spot6", "B", -0.6, 0.7, 0.4, 0.35, FAWN_LT),
		P("AntlerL", { 0.2, 0.55, 0.2 }, { -0.35, 3.95, 0 }, BARK, { joint = "Body", rot = { 0, 0, 15 } }),
		P("AntlerL2", { 0.18, 0.35, 0.18 }, { -0.58, 4.12, 0 }, BARK, { joint = "Body", rot = { 0, 0, 55 } }),
		P("AntlerR", { 0.2, 0.55, 0.2 }, { 0.35, 3.95, 0 }, BARK, { joint = "Body", rot = { 0, 0, -15 } }),
		P("AntlerR2", { 0.18, 0.35, 0.18 }, { 0.58, 4.12, 0 }, BARK, { joint = "Body", rot = { 0, 0, -55 } }),
		P("Leaf", { 0.45, 0.1, 0.3 }, { -0.1, 3.75, -0.3 }, LEAF, { joint = "Body", rot = { 0, 30, 0 } }),
		P("Blossom", { 0.3, 0.3, 0.3 }, { 0.2, 3.78, 0.25 }, PINK, { joint = "Body", shape = "Ball" }),
	}),
}

return Eggs
