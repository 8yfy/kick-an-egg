--!strict
-- Partner A. Zone 5, Desert Dunes (z 400..500): layered sandstone banks, the stepped Sun Pyramid with its golden
-- sun disc on the left, a wind-carved rock arch and a palm oasis on the right, broken columns, pottery, saguaros and
-- barrel cacti among stepped dunes; obelisks and far dunes. Ambience: sand swirls and heat glints.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local CACTI = { { "Saguaro", 3, 0.9, 1.3 }, { "BarrelCactus", 2, 1.0, 1.4 } }
local DESERT = {
	{ "Pottery", 2, 0.9, 1.2 },
	{ "Ruins", 1, 0.9, 1.1 },
	{ "RockA", 1, 0.8, 1.1 },
	{ "Saguaro", 2, 0.9, 1.2 },
	{ "BarrelCactus", 2, 1, 1.3 },
}
local COVER =
	{ { "BarrelCactus", 2, 0.6, 0.9 }, { "RockC", 2, 0.6, 0.9 }, { "GrassB", 2, 0.9, 1.2 }, { "Pottery", 1, 0.5, 0.7 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[5]
	local DUNE = Palettes.merge(PAL, { Ground = rgb(244, 214, 150), Stone = rgb(232, 190, 120) })
	local OASIS = Palettes.merge(PAL, {
		Leaf = rgb(70, 186, 84),
		LeafDark = rgb(40, 146, 72),
		LeafLight = rgb(140, 222, 92),
		Trunk = rgb(172, 122, 72),
		Wood = rgb(198, 152, 98),
	})
	local ctx = Valley.new(zone, parent, PAL)
	local H = 7
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankC", "BankA", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(246, 216, 150), rgb(226, 188, 116), rgb(214, 170, 104) }, 6)
	end

	-- the Sun Pyramid (left), stair facing the track
	local px, pz = -124, 452
	Valley.keepOut(ctx, px, pz, 40)
	Kit.place(ctx.props, "SunPyramid", Kit.at(px, H, pz, -90), 1.15, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "SunLight", Vector3.one, Vector3.new(px, H + 60, pz)),
		rgb(255, 214, 120),
		40,
		1.4
	)
	for _, z in { 414, 490 } do
		Kit.place(ctx.props, "Obelisk", Kit.at(-74, H, z, -90), 1.2, PAL)
	end

	-- the rock arch and the oasis (right)
	Valley.keepOut(ctx, 92, 424, 18)
	Kit.place(ctx.terrain, "RockArch", Kit.at(92, H, 424, 90 + 12), 1.5, PAL)
	local ox, oz = 130, 474
	Valley.keepOut(ctx, ox, oz, 20)
	Kit.place(ctx.props, "Pond", Kit.at(ox, H + 0.2, oz, 0), 1.1, PAL)
	for _, a in { 30, 120, 200, 290 } do
		local r = math.rad(a)
		local tree = Valley.put(
			ctx,
			ctx.nature,
			({ "PalmA", "PalmB", "PalmC" })[a % 3 + 1],
			ox + math.cos(r) * 14,
			oz + math.sin(r) * 14,
			ctx.rng:NextNumber(1.0, 1.25),
			a + 180,
			OASIS
		)
		Valley.sway(tree, 1.2, 0.2)
	end
	Valley.cluster(
		ctx,
		ctx.nature,
		ox - 4,
		oz - 16,
		{ { "TropicalPlant", 2, 1, 1.3 }, { "GrassA", 1, 1.2, 1.5 } },
		4,
		5,
		OASIS,
		{ shadow = false }
	)

	-- ruins, pottery and cacti among stepped dunes
	Valley.cluster(ctx, ctx.props, -70, 428, { { "Ruins", 1, 1.1, 1.3 }, { "Pottery", 1, 0.9, 1.1 } }, 3, 7, PAL)
	Valley.cluster(ctx, ctx.props, 72, 476, { { "Ruins", 1, 1.0, 1.2 }, { "Pottery", 1, 1, 1.2 } }, 3, 7, PAL)
	for _, d in
		{
			{ -190, 420, 1.2 },
			{ -200, 486, 1.0 },
			{ 196, 430, 1.1 },
			{ 210, 488, 0.9 },
			{ 64, 450, 0.45 },
			{ -60, 482, 0.4 },
		}
	do
		Kit.place(
			ctx.terrain,
			"HillB",
			Kit.at(d[1], H - 0.5, d[2], ctx.rng:NextNumber(0, 360)),
			Vector3.new(d[3], d[3] * 0.6, d[3] * 0.8),
			DUNE
		)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, CACTI, 9, { Valley.INNER + 8, 170 }, 9, PAL)
		Valley.scatter(ctx, ctx.props, side, DESERT, 5, { Valley.INNER + 10, 180 }, 12, PAL)
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: big dunes and a distant pyramid pair
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "HillB", 300, 420, 1.6 }, { "HillB", 360, 480, 1.4 }, { "HillA", 270, 470, 1.4 } },
			DUNE
		)
	end
	Valley.farRow(ctx, 1, { { "SunPyramid", 380, 450, 0.7, -90 } }, PAL)

	-- ambience
	Valley.fx(ctx, "SandSwirl", -1, 110, 140, H + 1.5, 2, nil, 1.2, 220)
	Valley.fx(ctx, "SandSwirl", 1, 110, 140, H + 1.5, 2, nil, 1.2, 220)
	Valley.fx(ctx, "HeatGlint", 0, 0, 70, 3, 2, nil, 1.2)

	-- hand-over: mushrooms at the start, snow at the end
	Valley.blend(ctx, { { "GlowShrooms", 2, 1, 1.2 }, { "MushroomSmallA", 2, 1.2, 1.5 } }, Palettes.zones[4], true, 3)
	Valley.blend(ctx, { { "SnowLumps", 2, 1, 1.3 }, { "PineSnowA", 1, 0.7, 0.9 } }, Palettes.zones[6], false, 3)
end
