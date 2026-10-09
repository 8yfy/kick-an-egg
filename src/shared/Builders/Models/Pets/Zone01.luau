--!strict
-- Zone 1: Meadow pets. Keys match Config/Pets `model`. Feet at y = 0, facing -Z.
-- First part of each joint group = hinge (see Models/Kit.luau). Quadrupeds: front legs = ArmL/ArmR.
-- `pair`/`mirror` take +X positions and the LEFT part's rotation; the right side is mirrored.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Parent.Kit)

local P, rgb = Kit.part, Color3.fromRGB

local LEAF, LEAF_DK, CREAM, INK = rgb(110, 200, 70), rgb(55, 140, 50), rgb(245, 238, 195), rgb(40, 35, 35)
local BEE, BEE_DK, WING, PINK = rgb(255, 205, 40), rgb(240, 165, 30), rgb(225, 245, 255), rgb(255, 140, 190)
local FAWN, FAWN_LT, BARK, MOSS, BUTTER =
	rgb(195, 135, 78), rgb(245, 225, 180), rgb(115, 80, 50), rgb(95, 175, 65), rgb(255, 225, 80)

local Pets: { [string]: Builder.Spec } = {}

-- Left part + mirrored right twin. `splitJoint` suffixes the joint (Arm -> ArmL/ArmR).
local function twin(
	splitJoint: boolean,
	name: string,
	size: { number },
	pos: { number },
	color: Color3,
	o: Kit.Opts
): { Builder.PartSpec }
	local function side(s: string, sign: number): Builder.PartSpec
		local rot = o.rot
		local opts: Kit.Opts = table.clone(o)
		if splitJoint and o.joint then
			opts.joint = o.joint .. s
		end
		opts.rot = if rot then { rot[1], -sign * rot[2], -sign * rot[3] } else nil
		return P(name .. s, size, { sign * pos[1], pos[2], pos[3] }, color, opts)
	end
	return { side("L", -1), side("R", 1) }
end

-- One joint group per side (limbs, wings).
local function pair(name: string, size: { number }, pos: { number }, color: Color3, o: Kit.Opts): { Builder.PartSpec }
	return twin(true, name, size, pos, color, o)
end

-- Both sides stay in the same joint group (ears, eyes' neighbours, antennae).
local function mirror(name: string, size: { number }, pos: { number }, color: Color3, o: Kit.Opts): { Builder.PartSpec }
	return twin(false, name, size, pos, color, o)
end

-- Common (25 parts, ~3.7 tall): a leafy puppy with a sprout on its head.
Pets.SproutPup = {
	parts = Kit.join(
		{
			P("Torso", { 2.0, 1.2, 2.6 }, { 0, 1.5, 0.05 }, LEAF, { joint = "Body" }),
			P("Belly", { 1.5, 0.15, 2.0 }, { 0, 0.88, 0.05 }, CREAM, { joint = "Body" }),
			P("Saddle", { 1.1, 0.2, 1.1 }, { 0, 2.15, 0.45 }, LEAF_DK, { joint = "Body", rot = { 0, 45, 0 } }),

			P("Head", { 1.8, 1.4, 1.5 }, { 0, 2.6, -1.35 }, LEAF, { joint = "Head" }),
			P("Muzzle", { 1.0, 0.6, 0.45 }, { 0, 2.25, -2.3 }, CREAM, { joint = "Head" }),
			P("Nose", { 0.4, 0.28, 0.2 }, { 0, 2.45, -2.6 }, INK, { joint = "Head" }),
			P("Stem", { 0.15, 0.5, 0.15 }, { 0, 3.5, -1.4 }, LEAF_DK, { joint = "Head" }),
		},
		Kit.eye(-1, -0.45, 2.8, -2.1, 0.3, 0.42, "Head"),
		Kit.eye(1, 0.45, 2.8, -2.1, 0.3, 0.42, "Head"),
		mirror(
			"Ear",
			{ 0.25, 0.8, 0.6 },
			{ 0.8, 3.55, -1.3 },
			LEAF_DK,
			{ joint = "Head", shape = "Wedge", rot = { 0, 0, 20 } }
		),
		mirror("Leaf", { 0.55, 0.1, 0.3 }, { 0.28, 3.78, -1.4 }, LEAF, { joint = "Head", rot = { 0, 0, -25 } }),

		pair("Arm", { 0.6, 0.5, 0.6 }, { 0.6, 0.85, -0.8 }, LEAF, { joint = "Arm" }),
		pair("Paw", { 0.7, 0.6, 0.75 }, { 0.6, 0.3, -0.85 }, CREAM, { joint = "Arm" }),
		pair("Leg", { 0.6, 0.5, 0.6 }, { 0.6, 0.85, 0.9 }, LEAF, { joint = "Leg" }),
		pair("Foot", { 0.7, 0.6, 0.75 }, { 0.6, 0.3, 0.85 }, CREAM, { joint = "Leg" }),

		{
			P("Tail", { 0.35, 0.35, 0.8 }, { 0, 2.0, 1.55 }, LEAF, { joint = "Tail", rot = { -35, 0, 0 } }),
			P("TailLeaf", { 0.5, 0.1, 0.5 }, { 0, 2.3, 1.85 }, LEAF_DK, { joint = "Tail", rot = { 0, 45, 0 } }),
		}
	),
}

-- Uncommon (30 parts, ~4.5 tall): a chubby cube bumblebee with glassy wings.
Pets.BumbleBloc = {
	parts = Kit.join(
		{
			P("Abdomen", { 2.6, 2.4, 2.4 }, { 0, 2.3, 0.9 }, BEE, { joint = "Body" }),
			P("Stripe1", { 2.7, 2.5, 0.45 }, { 0, 2.3, 0.6 }, INK, { joint = "Body" }),
			P("Stripe2", { 2.7, 2.5, 0.45 }, { 0, 2.3, 1.5 }, INK, { joint = "Body" }),
			P(
				"Stinger",
				{ 0.5, 0.5, 0.6 },
				{ 0, 2.0, 2.4 },
				INK,
				{ joint = "Body", shape = "Wedge", rot = { 0, 180, 0 } }
			),
			P("Collar", { 2.35, 2.1, 0.5 }, { 0, 2.6, -0.35 }, CREAM, { joint = "Body" }),

			P("Head", { 2.2, 2.0, 2.0 }, { 0, 2.6, -1.3 }, BEE, { joint = "Head" }),
			P("Mouth", { 0.5, 0.1, 0.06 }, { 0, 2.3, -2.33 }, INK, { joint = "Head" }),
			P("FuzzTop", { 1.0, 0.3, 1.0 }, { 0, 3.72, -1.3 }, CREAM, { joint = "Head", rot = { 0, 45, 0 } }),
		},
		Kit.eye(-1, -0.5, 2.85, -2.3, 0.5, 0.65, "Head"),
		Kit.eye(1, 0.5, 2.85, -2.3, 0.5, 0.65, "Head"),
		mirror("Cheek", { 0.4, 0.22, 0.06 }, { 0.8, 2.35, -2.33 }, PINK, { joint = "Head" }),
		mirror("Antenna", { 0.12, 0.8, 0.12 }, { 0.45, 3.95, -1.5 }, INK, { joint = "Head", rot = { 0, 0, 15 } }),
		mirror("AntTip", { 0.35, 0.35, 0.35 }, { 0.56, 4.4, -1.5 }, INK, { joint = "Head", shape = "Ball" }),

		pair("WingRoot", { 0.3, 0.3, 0.3 }, { 1.0, 3.5, 0.6 }, INK, { joint = "Wing" }),
		pair(
			"Wing",
			{ 1.6, 0.1, 1.0 },
			{ 1.75, 3.8, 0.5 },
			WING,
			{ joint = "Wing", rot = { 0, 0, -20 }, material = "Glass", transparency = 0.35 }
		),
		pair(
			"WingTip",
			{ 1.0, 0.1, 0.7 },
			{ 1.55, 3.6, 1.3 },
			WING,
			{ joint = "Wing", rot = { 0, 0, -12 }, material = "Glass", transparency = 0.35 }
		),

		pair("Leg", { 0.5, 0.8, 0.5 }, { 0.6, 0.7, 0.7 }, INK, { joint = "Leg" }),
		pair("Foot", { 0.7, 0.3, 0.8 }, { 0.6, 0.15, 0.6 }, BEE_DK, { joint = "Leg" }),
		pair("Arm", { 0.35, 0.35, 0.7 }, { 1.0, 1.3, -0.1 }, INK, { joint = "Arm" })
	),
}

-- Rare (49 parts, ~7.7 tall with antlers): a fawn stag with a moss shawl and blossoming antlers.
local function antler(sign: number): { Builder.PartSpec }
	local s = if sign < 0 then "L" else "R"
	local function at(x: number, y: number, z: number): { number }
		return { sign * x, y, z }
	end
	return {
		P(
			"Antler" .. s .. "1",
			{ 0.25, 1.0, 0.25 },
			at(0.55, 6.2, -1.9),
			BARK,
			{ joint = "Head", rot = { 0, 0, -sign * 25 } }
		),
		P(
			"Antler" .. s .. "2",
			{ 0.2, 0.9, 0.2 },
			at(1.13, 6.74, -1.9),
			BARK,
			{ joint = "Head", rot = { 0, 0, -sign * 65 } }
		),
		P(
			"Antler" .. s .. "3",
			{ 0.2, 0.8, 0.2 },
			at(0.83, 7.01, -1.9),
			BARK,
			{ joint = "Head", rot = { 0, 0, -sign * 10 } }
		),
		P(
			"Antler" .. s .. "4",
			{ 0.18, 0.6, 0.18 },
			at(0.6, 6.45, -1.65),
			BARK,
			{ joint = "Head", rot = { 40, 0, -sign * 25 } }
		),
		P(
			"AntlerLeaf" .. s,
			{ 0.5, 0.1, 0.35 },
			at(1.6, 6.98, -1.9),
			MOSS,
			{ joint = "Head", rot = { 0, 0, sign * 20 } }
		),
		P("Blossom" .. s, { 0.35, 0.35, 0.35 }, at(0.9, 7.48, -1.9), PINK, { joint = "Head", shape = "Ball" }),
	}
end

local function stagLeg(name: string, joint: string, x: number, z: number): { Builder.PartSpec }
	return {
		P(name .. "Upper", { 0.6, 1.3, 0.7 }, { x, 1.85, z }, FAWN, { joint = joint }),
		P(name .. "Lower", { 0.45, 1.0, 0.45 }, { x, 0.75, z }, FAWN_LT, { joint = joint }),
		P(name .. "Hoof", { 0.55, 0.3, 0.6 }, { x, 0.15, z - 0.03 }, BARK, { joint = joint }),
	}
end

Pets.MeadowStag = {
	parts = Kit.join(
		{
			P("Torso", { 2.4, 1.8, 3.6 }, { 0, 3.0, 0.2 }, FAWN, { joint = "Body" }),
			P("Belly", { 2.0, 0.2, 3.0 }, { 0, 2.08, 0.2 }, FAWN_LT, { joint = "Body" }),
			P("Chest", { 1.6, 1.0, 0.35 }, { 0, 3.2, -1.72 }, FAWN_LT, { joint = "Body" }),
			P("Spot1", { 0.5, 0.06, 0.5 }, { -0.6, 3.92, 0.7 }, FAWN_LT, { joint = "Body" }),
			P("Spot2", { 0.5, 0.06, 0.5 }, { 0.6, 3.92, 1.1 }, FAWN_LT, { joint = "Body" }),
			P("Spot3", { 0.4, 0.06, 0.4 }, { -0.3, 3.92, 1.6 }, FAWN_LT, { joint = "Body" }),
			P("Spot4", { 0.4, 0.06, 0.4 }, { 0.5, 3.92, 1.75 }, FAWN_LT, { joint = "Body" }),
			P("Mantle", { 2.6, 0.3, 1.4 }, { 0, 4.0, -0.6 }, MOSS, { joint = "Body" }),
			P("Flower1", { 0.35, 0.35, 0.35 }, { -0.7, 4.2, -0.4 }, PINK, { joint = "Body", shape = "Ball" }),
			P("Flower2", { 0.35, 0.35, 0.35 }, { 0.6, 4.2, -0.8 }, BUTTER, { joint = "Body", shape = "Ball" }),

			P("Neck", { 1.0, 1.6, 1.0 }, { 0, 4.2, -1.6 }, FAWN, { joint = "Head", rot = { -20, 0, 0 } }),
			P("Head", { 1.4, 1.3, 1.6 }, { 0, 5.2, -2.1 }, FAWN, { joint = "Head" }),
			P("Snout", { 1.0, 0.8, 0.8 }, { 0, 4.95, -3.1 }, FAWN_LT, { joint = "Head" }),
			P("Nose", { 0.5, 0.3, 0.2 }, { 0, 5.2, -3.55 }, INK, { joint = "Head" }),
			P("Blaze", { 0.3, 0.5, 0.06 }, { 0, 5.6, -2.92 }, FAWN_LT, { joint = "Head" }),
		},
		mirror("Shawl", { 0.3, 0.9, 1.4 }, { 1.3, 3.6, -0.6 }, MOSS, { joint = "Body" }),
		Kit.eye(-1, -0.45, 5.55, -2.9, 0.28, 0.38, "Head"),
		Kit.eye(1, 0.45, 5.55, -2.9, 0.28, 0.38, "Head"),
		mirror("Ear", { 0.9, 0.2, 0.45 }, { 1.05, 5.6, -1.9 }, FAWN, { joint = "Head", rot = { 0, 0, -20 } }),
		antler(-1),
		antler(1),
		stagLeg("ArmL", "ArmL", -0.75, -1.0),
		stagLeg("ArmR", "ArmR", 0.75, -1.0),
		stagLeg("LegL", "LegL", -0.75, 1.3),
		stagLeg("LegR", "LegR", 0.75, 1.3),
		{
			P("Tail", { 0.6, 0.5, 0.4 }, { 0, 3.6, 2.15 }, FAWN_LT, { joint = "Tail" }),
			P(
				"TailTuft",
				{ 0.4, 0.4, 0.3 },
				{ 0, 3.85, 2.35 },
				Color3.new(1, 1, 1),
				{ joint = "Tail", rot = { 20, 0, 0 } }
			),
		}
	),
}

return Pets
