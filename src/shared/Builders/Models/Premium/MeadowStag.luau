--!strict
-- 03 Meadow Stag (Meadow, Rare). Hero example 2/7 (docs/EggPetPlan.md): stronger shape change, clear theme.
-- Egg: fawn egg with cream dapples, a blossom crown band, two little branch antlers and the Rare neon band.
-- Pet: a forest stag: wide blossoming branch antlers (iconic feature), moss mantle with flowers, cream chest,
--      glowing leaf-green eyes, dark hooves.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Parent.Kit)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local FAWN, FAWN_DK, FAWN_LT = rgb(184, 122, 70), rgb(140, 88, 50), rgb(246, 226, 186)
local BARK, BARK_DK, MOSS, MOSS_LT = rgb(120, 82, 52), rgb(84, 56, 36), rgb(84, 168, 62), rgb(146, 214, 92)
local PINK, BUTTER, INK, GLOW = rgb(255, 150, 190), rgb(255, 226, 92), rgb(40, 34, 30), rgb(150, 255, 120)
local RARE = Kit.rarityColor("Rare")

local function cf(pos: { number }, rot: { number }?): CFrame
	return S.cf(pos, rot)
end

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 4.2, 3.2
local function antlerNub(side: number): { Builder.PartSpec }
	local base = cf({ side * 0.55, H - 0.35, 0 }, { 0, 0, side * -25 })
	return {
		S.at("Nub" .. side .. "A", { 0.2, 0.75, 0.2 }, base * CFrame.new(0, 0.35, 0), BARK, { joint = "Body" }),
		S.at(
			"Nub" .. side .. "B",
			{ 0.16, 0.45, 0.16 },
			base * CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.rad(side * -40)) * CFrame.new(0, 0.2, 0),
			BARK,
			{ joint = "Body" }
		),
		S.at("Nub" .. side .. "Leaf", { 0.34, 0.1, 0.24 }, base * CFrame.new(0, 0.78, 0), MOSS_LT, { joint = "Body" }),
	}
end

local eggParts = S.join(
	S.eggShell(H, W, 15, function(i, n)
		return if i <= 2 then FAWN_DK elseif i >= n - 2 then FAWN_LT else FAWN
	end),
	{
		S.eggBand("RareBand", H, W, 1.25, 0.18, 0.06, RARE, { material = "Neon" }),
		S.eggBand("CrownBand", H, W, 3.05, 0.34, 0.07, MOSS),
	},
	antlerNub(-1),
	antlerNub(1)
)
-- cream dapples (fawn spots) on every side
for k, spot in
	{ { -25, 2.1 }, { 20, 2.5 }, { 70, 1.9 }, { 120, 2.35 }, { 165, 2.0 }, { 215, 2.45 }, { 260, 1.95 }, { 310, 2.3 } }
do
	table.insert(eggParts, S.plate("Dapple" .. k, H, W, spot[1], spot[2], { 0.38, 0.32, 0.14 }, FAWN_LT))
end
-- blossoms on the crown band
for k = 1, 8 do
	local c = S.onEgg(H, W, k * 45 - 20, 3.05, 0.12)
	table.insert(
		eggParts,
		S.at(
			"Bloom" .. k,
			{ 0.32, 0.32, 0.18 },
			c * CFrame.Angles(0, 0, math.rad(45)),
			if k % 2 == 0 then PINK else BUTTER,
			{ joint = "Body" }
		)
	)
end
local egg: Builder.Spec = { parts = eggParts }

-- Pet -------------------------------------------------------------------------------------------------------
-- One antler (left side; mirrored): main beam sweeping up and out with three tines, leaves and blossoms.
local function antler(): { Builder.PartSpec }
	local o = { joint = "Head" }
	local base = cf({ -0.42, 5.35, -1.75 }, { -8, 0, 40 })
	local mid = base * CFrame.new(0, 1.0, 0) * CFrame.Angles(0, 0, math.rad(-12))
	local top = mid * CFrame.new(0, 0.95, 0) * CFrame.Angles(0, 0, math.rad(-14))
	local parts = {
		S.at("AntlerL1", { 0.26, 1.1, 0.26 }, base * CFrame.new(0, 0.5, 0), BARK, o),
		S.at("AntlerL2", { 0.24, 1.05, 0.24 }, mid * CFrame.new(0, 0.45, 0), BARK, o),
		S.at("AntlerL3", { 0.2, 0.9, 0.2 }, top * CFrame.new(0, 0.4, 0), BARK, o),
		S.at(
			"TineL1",
			{ 0.18, 0.75, 0.18 },
			base * CFrame.new(0, 0.75, 0) * CFrame.Angles(math.rad(-35), 0, math.rad(40)) * CFrame.new(0, 0.35, 0),
			BARK_DK,
			o
		),
		S.at(
			"TineL2",
			{ 0.18, 0.7, 0.18 },
			mid * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(30), 0, math.rad(45)) * CFrame.new(0, 0.32, 0),
			BARK_DK,
			o
		),
		S.at(
			"TineL3",
			{ 0.16, 0.6, 0.16 },
			top * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-45)) * CFrame.new(0, 0.28, 0),
			BARK_DK,
			o
		),
	}
	local tips = {
		base * CFrame.new(0, 0.75, 0) * CFrame.Angles(math.rad(-35), 0, math.rad(40)) * CFrame.new(0, 0.75, 0),
		mid * CFrame.new(0, 0.6, 0) * CFrame.Angles(math.rad(30), 0, math.rad(45)) * CFrame.new(0, 0.68, 0),
		top * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(-45)) * CFrame.new(0, 0.58, 0),
		top * CFrame.new(0, 0.9, 0),
	}
	for k, tip in tips do
		table.insert(
			parts,
			S.at(
				"LeafL" .. k,
				{ 0.5, 0.12, 0.36 },
				tip * CFrame.Angles(0, math.rad(30 * k), math.rad(20)),
				if k % 2 == 0 then MOSS_LT else MOSS,
				o
			)
		)
		table.insert(
			parts,
			S.at(
				"BloomL" .. k,
				{ 0.26, 0.26, 0.26 },
				tip * CFrame.new(0.12, 0.14, 0) * CFrame.Angles(0, 0, math.rad(45)),
				if k % 2 == 0 then PINK else BUTTER,
				o
			)
		)
	end
	return parts
end

local FACE_Z = -2.62
local petParts = S.join(
	{
		-- body (hinge first), cream chest, rump patch, moss mantle with drips and blossoms
		P("Torso", { 1.9, 1.55, 3.3 }, { 0, 2.75, 0.2 }, FAWN, { joint = "Body" }),
		P("Chest", { 1.5, 1.25, 0.16 }, { 0, 2.65, -1.48 }, FAWN_LT, { joint = "Body", studs = false }),
		P("Belly", { 1.4, 0.14, 2.5 }, { 0, 1.97, 0.2 }, FAWN_LT, { joint = "Body", studs = false }),
		P("Rump", { 1.3, 0.9, 0.14 }, { 0, 2.95, 1.86 }, FAWN_LT, { joint = "Body", studs = false }),
		P("Mantle", { 2.25, 0.5, 1.7 }, { 0, 3.62, -0.55 }, MOSS, { joint = "Body" }),
		P("MantleTop", { 1.6, 0.3, 1.1 }, { 0, 3.95, -0.5 }, MOSS_LT, { joint = "Body" }),
		P("Scut", { 0.5, 0.55, 0.3 }, { 0, 3.3, 1.95 }, FAWN_LT, { joint = "Tail" }),
		P(
			"Pendant",
			{ 0.36, 0.36, 0.12 },
			{ 0, 3.05, -1.6 },
			GLOW,
			{ joint = "Body", material = "Neon", rot = { 0, 0, 45 } }
		),
		-- neck + head
		P("Neck", { 0.85, 1.5, 0.85 }, { 0, 4.05, -1.35 }, FAWN, { joint = "Head", rot = { -22, 0, 0 } }),
		P("Head", { 1.25, 1.05, 1.45 }, { 0, 4.85, -1.95 }, FAWN, { joint = "Head" }),
		P("Snout", { 0.78, 0.6, 0.75 }, { 0, 4.62, -2.85 }, FAWN_LT, { joint = "Head" }),
		P("Nose", { 0.42, 0.26, 0.12 }, { 0, 4.78, FACE_Z - 0.6 }, INK, { joint = "Head", studs = false }),
		P("Brow", { 1.3, 0.2, 0.3 }, { 0, 5.3, -2.5 }, FAWN_DK, { joint = "Head" }),
		P("EyeL", { 0.24, 0.26, 0.1 }, { -0.4, 5.05, FACE_Z }, GLOW, { joint = "Head", material = "Neon" }),
		P("EyeR", { 0.24, 0.26, 0.1 }, { 0.4, 5.05, FACE_Z }, GLOW, { joint = "Head", material = "Neon" }),
		P(
			"GlintL",
			{ 0.08, 0.08, 0.05 },
			{ -0.45, 5.12, FACE_Z - 0.06 },
			Color3.new(1, 1, 1),
			{ joint = "Head", material = "Neon" }
		),
		P(
			"GlintR",
			{ 0.08, 0.08, 0.05 },
			{ 0.35, 5.12, FACE_Z - 0.06 },
			Color3.new(1, 1, 1),
			{ joint = "Head", material = "Neon" }
		),
	},
	S.both(S.join({
		-- ears (head), mantle drips + blossoms (body), front legs = ArmL, back legs = LegL
		P("EarL", { 0.75, 0.32, 0.42 }, { -0.85, 5.25, -1.75 }, FAWN, { joint = "Head", rot = { 0, 20, 30 } }),
		P(
			"EarInL",
			{ 0.5, 0.18, 0.3 },
			{ -0.9, 5.3, -1.85 },
			PINK,
			{ joint = "Head", rot = { 0, 20, 30 }, studs = false }
		),
		P("DripL1", { 0.35, 0.55, 0.35 }, { -1.05, 3.25, -1.0 }, MOSS, { joint = "Body" }),
		P("DripL2", { 0.3, 0.4, 0.3 }, { -1.08, 3.3, 0.05 }, MOSS_LT, { joint = "Body" }),
		P("MantleBloomL1", { 0.3, 0.3, 0.3 }, { -0.7, 4.0, -1.1 }, PINK, { joint = "Body", rot = { 0, 0, 45 } }),
		P("MantleBloomL2", { 0.26, 0.26, 0.26 }, { -0.95, 3.85, 0.0 }, BUTTER, { joint = "Body", rot = { 0, 0, 45 } }),
		P("FrontThighL", { 0.6, 1.05, 0.7 }, { -0.62, 1.75, -1.0 }, FAWN, { joint = "ArmL" }),
		P("FrontShinL", { 0.42, 1.05, 0.45 }, { -0.62, 0.75, -1.05 }, FAWN_LT, { joint = "ArmL" }),
		P("FrontHoofL", { 0.5, 0.3, 0.58 }, { -0.62, 0.15, -1.1 }, INK, { joint = "ArmL" }),
		P("BackThighL", { 0.66, 1.15, 0.85 }, { -0.62, 1.8, 1.35 }, FAWN, { joint = "LegL" }),
		P("BackShinL", { 0.42, 1.05, 0.45 }, { -0.62, 0.75, 1.45 }, FAWN_LT, { joint = "LegL" }),
		P("BackHoofL", { 0.5, 0.3, 0.58 }, { -0.62, 0.15, 1.4 }, INK, { joint = "LegL" }),
	}, antler()))
)
local pet: Builder.Spec = { parts = petParts }

return { egg = egg, pet = pet }
