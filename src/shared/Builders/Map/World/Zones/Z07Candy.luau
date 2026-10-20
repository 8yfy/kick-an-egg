--!strict
-- Partner A. Zone 7, Candy Land (z 600..700): pink frosting ground over mint / pink layered banks, the
-- Gingerbread Castle with candy towers on the left, lollipop groves, candy-cane fences along the banks, gumdrops,
-- cupcakes, a giant donut and ice-cream cones, rounded candy hills in pastel tones. Ambience: falling sprinkles and
-- star sparkles.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local TREATS = {
	{ "Gumdrop", 3, 1.0, 1.4 },
	{ "Cupcake", 2, 0.9, 1.2 },
	{ "IceCream", 1, 0.9, 1.1 },
	{ "LollipopTree", 2, 0.8, 1.0 },
}
local COVER = { { "Gumdrop", 3, 0.5, 0.8 }, { "FlowersA", 2, 1, 1.2 }, { "CandyCane", 1, 0.4, 0.6 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[7]
	local VARIANTS = { PAL, Palettes.candyMint, Palettes.candyLemon }
	local ctx = Valley.new(zone, parent, PAL)
	local function v(): any
		return VARIANTS[ctx.rng:NextInteger(1, #VARIANTS)]
	end
	local H = 8
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankD", "BankB" }, H)
		Valley.patches(ctx, side, { rgb(255, 204, 226), rgb(255, 160, 204), rgb(170, 236, 214) }, 6)
	end

	-- the Gingerbread Castle (left)
	local cx, cz = -122, 652
	Valley.keepOut(ctx, cx, cz, 38)
	Kit.place(ctx.props, "GingerbreadCastle", Kit.at(cx, H, cz, -90), 1.3, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "CastleGlow", Vector3.one, Vector3.new(cx + 20, H + 20, cz)),
		rgb(255, 200, 240),
		30,
		1
	)

	-- the giant donut and ice creams (right), candy-cane fences along both banks
	Valley.keepOut(ctx, 104, 626, 14)
	Kit.place(ctx.props, "Donut", Kit.at(104, H, 626, 90 - 20), 2.2, PAL)
	Kit.place(ctx.props, "IceCream", Kit.at(130, H, 668, 0), 2.4, Palettes.candyMint)
	Kit.place(ctx.props, "IceCream", Kit.at(150, H, 640, 30), 1.8, PAL)
	for _, side in { -1, 1 } do
		for z = ctx.z0 + 6, ctx.z1 - 6, 7 do
			Kit.place(
				ctx.props,
				"CandyCane",
				Kit.at(side * (Valley.INNER + 21), H, z, if side > 0 then 180 else 0),
				0.75,
				PAL
			)
		end
	end

	-- lollipop groves, treats and pastel candy hills
	for _, c in
		{
			{ -72, 612, 3 },
			{ -80, 690, 3 },
			{ -190, 620, 4 },
			{ -196, 690, 3 },
			{ 76, 690, 3 },
			{ 190, 620, 4 },
			{ 220, 684, 3 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], { { "LollipopTree", 1, 0.9, 1.3 } }, c[3], 8, v(), nil, true)
	end
	for _, h in { { -250, 640, 1.2 }, { 260, 650, 1.3 }, { 170, 694, 0.7 }, { -160, 606, 0.6 } } do
		Kit.place(
			ctx.terrain,
			"HillB",
			Kit.at(h[1], H - 0.5, h[2], ctx.rng:NextNumber(0, 360)),
			Vector3.new(h[3], h[3] * 0.7, h[3] * 0.8),
			v()
		)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.props, side, TREATS, 10, { Valley.INNER + 26, 170 }, 9, v())
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: candy hills and giant lollipops
	for _, side in { -1, 1 } do
		Valley.farRow(ctx, side, { { "HillB", 320, 630, 1.5 }, { "HillB", 360, 690, 1.3 } }, v())
		Valley.farRow(ctx, side, { { "LollipopTree", 290, 660, 4 }, { "Cupcake", 330, 610, 5 } }, v())
	end

	-- ambience
	Valley.fx(ctx, "CandySprinkles", -1, 110, 160, H + 22, 4, nil, 1.3)
	Valley.fx(ctx, "CandySprinkles", 1, 110, 160, H + 22, 4, { rgb(140, 230, 255), rgb(255, 150, 210) }, 1.3)
	Valley.fx(ctx, "CandySparkle", 0, 0, 70, 6, 6, nil, 1.5)

	-- hand-over: snow at the start, coral at the end
	Valley.blend(ctx, { { "SnowLumps", 2, 0.8, 1 }, { "PineSnowA", 1, 0.7, 0.9 } }, Palettes.zones[6], true, 3)
	Valley.blend(ctx, { { "BrainCoral", 2, 0.8, 1 }, { "Shell", 2, 1.2, 1.6 } }, Palettes.corals[1], false, 3)
end
