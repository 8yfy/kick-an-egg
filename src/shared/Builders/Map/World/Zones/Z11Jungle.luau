--!strict
-- Partner A. Zone 11, Jungle Ruins (z 1000..1100): mossy stone banks draped with hanging vines, the stepped Jungle
-- Temple with its glowing shrine on the left, a giant carved stone head on the right, broken mossy ruin walls, a
-- jungle river, dense tall jungle trees with umbrella canopies and ferns underneath. Ambience: jungle mist,
-- fireflies and drifting green leaves.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local TREES = { { "JungleTreeA", 3, 1.2, 1.7 }, { "JungleTreeB", 3, 1.1, 1.5 }, { "PalmB", 1, 1.0, 1.2 } }
local UNDER =
	{ { "Fern", 4, 1.0, 1.6 }, { "TropicalPlant", 2, 1.0, 1.5 }, { "BushC", 1, 1.0, 1.3 }, { "RockA", 1, 0.8, 1.1 } }
local COVER = { { "Fern", 3, 0.7, 1.0 }, { "GrassA", 2, 1.1, 1.5 }, { "RockC", 1, 0.6, 0.9 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[11]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 9
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankC", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(84, 168, 72), rgb(58, 132, 58), rgb(110, 120, 90) }, 5)
		-- vines hanging over the bank fronts
		for z = ctx.z0 + 10, ctx.z1 - 10, 18 do
			Kit.place(
				ctx.terrain,
				"Vines",
				Kit.at(
					side * (Valley.INNER + 0.8),
					H + 0.2,
					z + ctx.rng:NextNumber(-4, 4),
					if side > 0 then -90 else 90
				),
				ctx.rng:NextNumber(0.6, 0.9),
				PAL
			)
		end
	end

	-- the Jungle Temple (left) and the stone head (right)
	local tx, tz = -124, 1052
	Valley.keepOut(ctx, tx, tz, 36)
	Kit.place(ctx.props, "JungleTemple", Kit.at(tx, H, tz, -90), 1.3, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "ShrineGlow", Vector3.one, Vector3.new(tx + 12, H + 40, tz)),
		rgb(140, 255, 160),
		30,
		1.2
	)
	Valley.keepOut(ctx, 92, 1020, 12)
	Kit.place(ctx.props, "StoneHead", Kit.at(92, H, 1020, 90 + 15), 1.5, PAL)
	for _, p in { { -70, 1014, -80 }, { 76, 1080, 95 }, { 150, 1050, 120 } } do
		Kit.place(ctx.props, "RuinWall", Kit.at(p[1], H, p[2], p[3]), 1, PAL)
		Valley.keepOut(ctx, p[1], p[2], 10)
	end

	-- the jungle river (right) with stepping stones
	Valley.stream(ctx, Vector3.new(60, H + 0.08, 1096), Vector3.new(140, H + 0.08, 1070), 8, rgb(70, 180, 170))
	Valley.stream(ctx, Vector3.new(140, H + 0.08, 1070), Vector3.new(260, H + 0.08, 1088), 8, rgb(70, 180, 170))

	-- dense jungle in clusters, ferns underneath
	for _, c in
		{
			{ -66, 1080, 5 },
			{ -76, 1006, 5 },
			{ -110, 1092, 5 },
			{ -170, 1010, 5 },
			{ -190, 1080, 5 },
			{ -250, 1040, 4 },
			{ 70, 1050, 5 },
			{ 110, 1004, 5 },
			{ 180, 1010, 5 },
			{ 196, 1074, 4 },
			{ 250, 1040, 4 },
			{ 120, 1094, 4 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], TREES, c[3], 14, PAL, nil, true)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, UNDER, 22, { Valley.INNER + 8, 200 }, 6, PAL, { shadow = false })
		Valley.scatter(ctx, ctx.nature, side, TREES, 5, { Valley.INNER + 12, 220 }, 14, PAL, nil, true)
	end
	Valley.shoulders(ctx, COVER, 20, PAL)

	-- far: jungle forest bands and green hills
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "ForestFar", 290, 1030, 1.3 }, { "ForestFar", 320, 1080, 1.4 }, { "HillB", 360, 1050, 1.3 } },
			PAL
		)
	end

	-- ambience
	Valley.fx(ctx, "JungleMist", -1, 110, 160, H + 2, 2, nil, 1.2)
	Valley.fx(ctx, "JungleMist", 1, 110, 160, H + 2, 2, nil, 1.2)
	Valley.fx(ctx, "Fireflies", 0, 0, 70, 6, 6, { rgb(200, 255, 140) }, 1.4)
	Valley.fx(ctx, "Leaves", 0, 0, 160, H + 22, 4, { rgb(90, 190, 80) }, 1)

	-- hand-over: crystals at the start, neon city at the end
	Valley.blend(ctx, { { "CrystalClusterB", 2, 0.8, 1.1 } }, Palettes.zones[10], true, 3)
	Valley.blend(ctx, { { "NeonLamp", 1, 0.8, 1 }, { "Billboard", 1, 0.6, 0.7 } }, Palettes.zones[12], false, 2)
end
