--!strict
-- Zone 1: Meadow pets. Keys match Config/Pets `model`. Feet at y = 0, facing -Z.
-- First part of each joint group = hinge (see Models/Kit.luau). Quadrupeds: front legs = ArmL/ArmR.
-- `pair`/`mirror` take +X positions and the LEFT part's rotation; the right side is mirrored.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Parent.Kit)

local P, rgb = Kit.part, Color3.fromRGB

local CREAM, INK = rgb(245, 238, 195), rgb(40, 35, 35)
local BEE, BEE_DK, WING, PINK = rgb(255, 205, 40), rgb(240, 165, 30), rgb(225, 245, 255), rgb(255, 140, 190)

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

-- Premium hero spec (Models/Premium/SproutPup.luau, docs/EggPetPlan.md).
Pets.SproutPup = require(script.Parent.Parent.Premium.SproutPup).pet

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

-- Premium hero spec (Models/Premium/MeadowStag.luau, docs/EggPetPlan.md).
Pets.MeadowStag = require(script.Parent.Parent.Premium.MeadowStag).pet

return Pets
