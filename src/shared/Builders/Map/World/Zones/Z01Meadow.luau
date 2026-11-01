--!strict
-- Partner A. Zone 1, Meadow (z 0..100, flat start: the lane runs from the launch deck): low rolling banks, a
-- red-roofed windmill on a stepped hill (sails turning) on the left, a fenced farm plot with hay, a scarecrow,
-- sunflowers, beehives and a cart on the right, a safe stream with a plank bridge and a pond, layered groves,
-- flowers everywhere, distant forest bands and hills. Ambience: pollen, butterflies, drifting blossoms.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)

local rgb = Color3.fromRGB

local TREES = {
	{ "TreeRoundA", 3, 1.1, 1.4 },
	{ "TreeRoundB", 3, 1.0, 1.3 },
	{ "TreeBallA", 2, 1.0, 1.3 },
	{ "TreeBallC", 2, 1.0, 1.2 },
	{ "TreeTallA", 1, 0.9, 1.1 },
}
local FLOWERS = {
	{ "FlowersA", 3, 1.0, 1.4 },
	{ "FlowersB", 3, 1.0, 1.4 },
	{ "BushFlowerA", 1, 0.9, 1.2 },
	{ "BushA", 1, 0.9, 1.2 },
}
local COVER = {
	{ "FlowersA", 3, 0.8, 1.1 },
	{ "FlowersB", 2, 0.8, 1.1 },
	{ "GrassA", 3, 1.0, 1.3 },
	{ "GrassB", 2, 1.0, 1.3 },
	{ "RockC", 1, 0.5, 0.8 },
}

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[1]
	local FAR =
		Palettes.merge(PAL, { Stone = rgb(150, 162, 186), StoneDark = rgb(122, 134, 160), Snow = rgb(246, 250, 255) })
	local ctx = Valley.new(zone, parent, PAL)
	local H = 3 -- just above the flat hub, so its front edge reads as a low bank, not a cliff
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.Stone :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankD", "BankA", "BankB" }, H)
		Valley.patches(ctx, side, { rgb(124, 214, 80), rgb(98, 186, 62), rgb(140, 220, 96) }, 6)
	end

	-- the windmill on its hill (left), sails turning around their axle
	local wx, wz = -112, 58
	Valley.keepOut(ctx, wx, wz, 34)
	Kit.place(ctx.terrain, "HillB", Kit.at(wx, H, wz, 15), Vector3.new(0.62, 0.55, 0.62), PAL)
	local top = H - 1 + 24 * 0.55
	local wcf = Kit.at(wx, top, wz, -90)
	Kit.place(ctx.props, "Windmill", wcf, 1.3, PAL)
	local sails = Kit.place(ctx.props, "WindmillSails", wcf * CFrame.new(0, 30 * 0.86 * 1.3, -6.4 * 1.3), 1.3, PAL)
	Valley.spin(sails, 28)
	Valley.cluster(ctx, ctx.nature, wx - 26, wz + 20, FLOWERS, 5, 9, PAL, { shadow = false })
	Valley.cluster(ctx, ctx.nature, wx + 24, wz - 22, TREES, 2, 6, PAL, nil, true)

	-- the farm (right): a picket-fenced plot with hay, a scarecrow and sunflowers; beehives and a cart outside
	local fx0, fx1, fz0, fz1 = 66, 112, 18, 60
	Valley.keepOut(ctx, (fx0 + fx1) / 2, (fz0 + fz1) / 2, 30)
	local function fenceRun(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		local n = math.max(1, math.floor(len / 8 + 0.5))
		local dir = (b - a).Unit
		for k = 0, n - 1 do
			local q = a + dir * (len * (k + 0.5) / n)
			Kit.place(
				ctx.props,
				"FenceRail",
				CFrame.lookAt(q, q + dir) * CFrame.Angles(0, math.rad(90), 0),
				Vector3.new(len / n / 8, 1, 1),
				PAL
			)
			local p = a + dir * (len * k / n)
			Kit.place(ctx.props, "FencePost", CFrame.new(p), 0.8, PAL)
		end
	end
	local y = H
	fenceRun(Vector3.new(fx0, y, fz0), Vector3.new(fx1, y, fz0))
	fenceRun(Vector3.new(fx1, y, fz0), Vector3.new(fx1, y, fz1))
	fenceRun(Vector3.new(fx1, y, fz1), Vector3.new(fx0, y, fz1))
	fenceRun(Vector3.new(fx0, y, fz1), Vector3.new(fx0, y, (fz0 + fz1) / 2 + 5))
	fenceRun(Vector3.new(fx0, y, (fz0 + fz1) / 2 - 5), Vector3.new(fx0, y, fz0))
	Kit.place(ctx.props, "Scarecrow", Kit.at(89, y, 40, -90), 1.2, PAL)
	for i, p in { { 76, 26 }, { 82, 30 }, { 102, 52 }, { 96, 24 } } do
		Kit.place(ctx.props, if i == 4 then "HayStack" else "HayBale", Kit.at(p[1], y, p[2], i * 37), 1, PAL)
	end
	for i = 0, 7 do
		Kit.place(
			ctx.props,
			"Sunflower",
			Kit.at(
				96 + (i % 4) * 3 + ctx.rng:NextNumber(-0.6, 0.6),
				y,
				38 + (i // 4) * 4 + ctx.rng:NextNumber(-0.8, 0.8),
				-90 + ctx.rng:NextNumber(-20, 20)
			),
			ctx.rng:NextNumber(0.9, 1.15),
			PAL
		)
	end
	Kit.place(ctx.props, "FarmCart", Kit.at(60, y, 46, 70), 1, PAL)
	for i = 0, 2 do
		Kit.place(ctx.props, "Beehive", Kit.at(122 + i * 4, y, 24 + (i % 2) * 3, i * 25), 1, PAL)
	end
	Valley.cluster(ctx, ctx.nature, 128, 30, FLOWERS, 6, 9, PAL, { shadow = false })

	-- the stream (right, beyond the farm) with a plank bridge and a pond near the banks
	Valley.keepOut(ctx, 150, 86, 18)
	Valley.stream(ctx, Vector3.new(78, H + 0.08, 88), Vector3.new(175, H + 0.08, 84), 7)
	Valley.stream(ctx, Vector3.new(175, H + 0.08, 84), Vector3.new(290, H + 0.08, 92), 7)
	Kit.place(ctx.props, "PlankBridge", Kit.at(150, H, 86, 4), 1, PAL)
	Kit.place(ctx.props, "RockA", Kit.at(78, H, 80, 20), 0.9, PAL)
	Kit.place(ctx.props, "RockC", Kit.at(74, H, 95, 70), 1, PAL)

	-- groves and meadow cover, both sides
	for _, c in
		{
			{ -66, 18, 3 },
			{ -150, 22, 4 },
			{ -78, 92, 3 },
			{ -182, 84, 4 },
			{ -240, 40, 5 },
			{ 146, 46, 3 },
			{ 208, 30, 4 },
			{ 236, 66, 3 },
			{ 120, 92, 2 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], TREES, c[3], 9, PAL, nil, true)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, FLOWERS, 12, { Valley.INNER + 8, 140 }, 7, PAL, { shadow = false })
		Valley.scatter(ctx, ctx.nature, side, { "RockA", "RockB", "RockFlat" }, 3, { Valley.INNER + 10, 160 }, 12, PAL)
	end
	Kit.place(ctx.terrain, "HillA", Kit.at(-190, H, 30, 40), 1, PAL)
	Kit.place(ctx.terrain, "HillC", Kit.at(180, H, 30, 10), 1.2, PAL)
	Valley.shoulders(ctx, COVER, 20, PAL, 44) -- clear of the chevron lights

	-- far: forest bands and blue-grey peaks closing the view
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "ForestFar", 300, 30, 1 }, { "ForestFar", 330, 82, 1.2 }, { "HillB", 260, 60, 1.1 } },
			PAL
		)
		Valley.farRow(ctx, side, { { "MountainC", 410, 50, 1.4 } }, FAR)
	end

	-- ambience
	Valley.fx(ctx, "Pollen", -1, 110, 140, H + 6, 10, nil, 1.2)
	Valley.fx(ctx, "Pollen", 1, 110, 140, H + 6, 10, nil, 1.2)
	Valley.fx(ctx, "Butterflies", -1, 90, 80, H + 4, 6, { rgb(255, 170, 60) }, 1.4)
	Valley.fx(ctx, "Butterflies", 1, 100, 80, H + 4, 6, { rgb(110, 190, 255) }, 1.4)
	Valley.fx(ctx, "Blossoms", 0, 0, 70, 24, 2, nil, 1)

	-- hand-over to the beach at the far end
	Valley.blend(
		ctx,
		{ { "PalmC", 1, 0.8, 1 }, { "Shell", 2, 1, 1.4 }, { "TropicalPlant", 2, 1, 1.2 } },
		Palettes.zones[2],
		false,
		4
	)
end
