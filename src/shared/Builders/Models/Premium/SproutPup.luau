--!strict
-- 01 Sprout Pup (Meadow, Common). Hero example 1/7 (docs/EggPetPlan.md): simple, cute, minimal detail.
-- Egg: cream egg wearing a leafy cap with a pinked leaf edge, two paw prints, a sprout on top.
-- Pet: chibi leaf puppy: big cream-faced head, floppy leaf ears, sprout, paw pads, glowing leaf pendant.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local LEAF, LEAF_DK, LEAF_LT = rgb(112, 204, 72), rgb(58, 148, 56), rgb(176, 236, 112)
local CREAM, TAN, INK, PINK = rgb(250, 242, 210), rgb(214, 178, 128), rgb(42, 36, 34), rgb(255, 156, 176)
local GLOW = rgb(150, 255, 110)

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 3.9, 3.0
local function paw(name: string, a: number, y: number): { Builder.PartSpec }
	return {
		S.plate(name .. "Pad", H, W, a, y, { 0.62, 0.5, 0.14 }, LEAF_DK),
		S.plate(name .. "Toe1", H, W, a - 13, y + 0.45, { 0.2, 0.22, 0.14 }, LEAF_DK),
		S.plate(name .. "Toe2", H, W, a, y + 0.52, { 0.2, 0.22, 0.14 }, LEAF_DK),
		S.plate(name .. "Toe3", H, W, a + 13, y + 0.45, { 0.2, 0.22, 0.14 }, LEAF_DK),
	}
end

local egg: Builder.Spec = {
	parts = S.join(
		S.eggShell(H, W, 14, function(i)
			return if i <= 6 then CREAM elseif i >= 13 then LEAF_LT else LEAF
		end),
		-- pinked leaf edge where the cap meets the cream
		S.ring("CapEdge", CFrame.new(0, 1.72, 0), 10, S.eggRadius(H, W, 1.72) - 0.02, { 0.42, 0.42, 0.16 }, LEAF, {
			joint = "Body",
			rot = { 0, 0, 45 },
		}),
		paw("PawA", -30, 0.75),
		paw("PawB", 150, 0.85),
		{
			P("Stem", { 0.16, 0.55, 0.16 }, { 0, H + 0.2, 0 }, LEAF_DK, { joint = "Body" }),
			P(
				"SproutL",
				{ 0.62, 0.12, 0.34 },
				{ -0.32, H + 0.48, 0 },
				LEAF_LT,
				{ joint = "Body", rot = { 0, 0, -28 } }
			),
			P("SproutR", { 0.62, 0.12, 0.34 }, { 0.32, H + 0.48, 0 }, LEAF_LT, { joint = "Body", rot = { 0, 0, 28 } }),
		}
	),
}

-- Pet -------------------------------------------------------------------------------------------------------
local FACE_Z = -1.95
local pet: Builder.Spec = {
	parts = S.join(
		{
			-- body (hinge first), cream belly, collar + leaf pendant
			P("Torso", { 1.9, 1.25, 2.3 }, { 0, 1.32, 0.15 }, LEAF, { joint = "Body" }),
			P("Belly", { 1.4, 0.9, 0.12 }, { 0, 1.22, -1.02 }, CREAM, { joint = "Body", studs = false }),
			P("BackSpot", { 1.2, 0.12, 1.1 }, { 0, 1.98, 0.45 }, LEAF_DK, { joint = "Body" }),
			P("Collar", { 1.7, 0.22, 0.3 }, { 0, 1.85, -0.95 }, LEAF_DK, { joint = "Body", studs = false }),
			P("Pendant", { 0.34, 0.34, 0.12 }, { 0, 1.6, -1.12 }, GLOW, {
				joint = "Body",
				material = "Neon",
				rot = { 0, 0, 45 },
			}),
			-- head
			P("Head", { 2.5, 2.05, 2.0 }, { 0, 3.05, -0.95 }, LEAF, { joint = "Head" }),
			P("Face", { 1.95, 1.25, 0.12 }, { 0, 2.78, FACE_Z }, CREAM, { joint = "Head", studs = false }),
			P("Muzzle", { 0.95, 0.5, 0.35 }, { 0, 2.48, FACE_Z - 0.15 }, CREAM, { joint = "Head" }),
			P("Nose", { 0.38, 0.24, 0.12 }, { 0, 2.66, FACE_Z - 0.36 }, INK, { joint = "Head", studs = false }),
			P("Mouth", { 0.3, 0.08, 0.06 }, { 0, 2.36, FACE_Z - 0.34 }, INK, { joint = "Head", studs = false }),
			P("CheekL", { 0.34, 0.18, 0.06 }, { -0.72, 2.55, FACE_Z - 0.04 }, PINK, { joint = "Head", studs = false }),
			P("CheekR", { 0.34, 0.18, 0.06 }, { 0.72, 2.55, FACE_Z - 0.04 }, PINK, { joint = "Head", studs = false }),
			P("Brow", { 2.0, 0.3, 0.14 }, { 0, 3.55, FACE_Z + 0.02 }, LEAF_DK, { joint = "Head" }),
			-- sprout on the head
			P("Stem", { 0.18, 0.6, 0.18 }, { 0, 4.35, -0.95 }, LEAF_DK, { joint = "Head" }),
			P("SproutL", { 0.8, 0.14, 0.45 }, { -0.42, 4.7, -0.95 }, LEAF_LT, { joint = "Head", rot = { 0, 0, -26 } }),
			P("SproutR", { 0.8, 0.14, 0.45 }, { 0.42, 4.7, -0.95 }, LEAF_LT, { joint = "Head", rot = { 0, 0, 26 } }),
			-- leaf tail
			P("TailBase", { 0.36, 0.36, 0.5 }, { 0, 1.75, 1.45 }, LEAF_DK, { joint = "Tail" }),
			P("TailLeaf", { 0.5, 0.9, 0.16 }, { 0, 2.2, 1.62 }, LEAF_LT, { joint = "Tail", rot = { -25, 0, 0 } }),
		},
		S.eye(-1, -0.52, 3.05, FACE_Z, 0.42, 0.52, "Head"),
		S.eye(1, 0.52, 3.05, FACE_Z, 0.42, 0.52, "Head"),
		S.both({
			-- floppy leaf ears (head group), front legs = ArmL/ArmR, back legs = LegL/LegR
			P("EarL", { 0.36, 1.45, 1.05 }, { -1.5, 3.3, -0.85 }, LEAF_DK, { joint = "Head", rot = { 0, 0, -30 } }),
			P("EarTipL", { 0.34, 0.5, 0.8 }, { -1.92, 2.6, -0.85 }, LEAF_LT, { joint = "Head", rot = { 0, 0, -30 } }),
			P("FrontLegL", { 0.6, 0.6, 0.6 }, { -0.6, 0.62, -0.7 }, LEAF, { joint = "ArmL" }),
			P("FrontPawL", { 0.72, 0.32, 0.82 }, { -0.6, 0.16, -0.78 }, CREAM, { joint = "ArmL" }),
			P("FrontPadL", { 0.42, 0.06, 0.3 }, { -0.6, 0.33, -1.0 }, TAN, { joint = "ArmL", studs = false }),
			P("BackLegL", { 0.6, 0.6, 0.6 }, { -0.62, 0.62, 0.95 }, LEAF, { joint = "LegL" }),
			P("BackPawL", { 0.72, 0.32, 0.8 }, { -0.62, 0.16, 0.9 }, CREAM, { joint = "LegL" }),
		})
	),
}

return { egg = egg, pet = pet }
