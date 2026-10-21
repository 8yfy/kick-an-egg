--!strict
-- Partner A. Zone 3, Autumn Forest (z 200..300): golden-grass banks under a dense orange / red / yellow forest with
-- dark evergreen accents, the giant Hollow Oak with its glowing door and treehouse on the left, a log cabin with a
-- smoking chimney and a pumpkin patch on the right, leaf piles, stumps, fallen logs and lantern posts. Far forest
-- bands and snowy peaks. Ambience: drifting orange and red leaves.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local TREES = {
	{ "MapleA", 3, 1.0, 1.3 },
	{ "MapleB", 3, 1.0, 1.3 },
	{ "TreeRoundA", 2, 1.0, 1.3 },
	{ "TreeRoundC", 1, 0.9, 1.1 },
	{ "TreeBallA", 2, 1.0, 1.3 },
}
local GROUND = {
	{ "LeafPile", 3, 0.9, 1.3 },
	{ "Stump", 2, 0.9, 1.2 },
	{ "LogA", 1, 0.9, 1.1 },
	{ "BushB", 2, 1, 1.3 },
	{ "Pumpkin", 1, 0.8, 1.1 },
}
local COVER =
	{ { "LeafPile", 3, 0.5, 0.8 }, { "GrassA", 2, 1, 1.3 }, { "MushroomSmallA", 1, 1, 1.3 }, { "RockC", 1, 0.6, 0.9 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[3]
	local GREEN = Palettes.evergreen
	local FAR = Palettes.merge(PAL, { Stone = rgb(150, 160, 184), StoneDark = rgb(120, 130, 156) })
	local ctx = Valley.new(zone, parent, PAL)
	local H = 10
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.Stone :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankC", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(214, 186, 84), rgb(186, 156, 64), rgb(226, 120, 50) }, 6)
	end

	-- the Hollow Oak (left), facing the track
	local ox, oz = -114, 252
	Valley.keepOut(ctx, ox, oz, 36)
	Kit.place(ctx.props, "HollowOak", Kit.at(ox, H, oz, -90), 1.3, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "OakDoorLight", Vector3.one, Vector3.new(ox + 6, H + 3, oz)),
		rgb(255, 200, 120),
		18,
		1.2
	)
	Valley.cluster(ctx, ctx.nature, ox + 26, oz + 24, GROUND, 4, 7, PAL, { shadow = false })

	-- the log cabin (right) with chimney smoke, a pumpkin patch and lantern posts on its path
	local cx, cz = 84, 226
	Valley.keepOut(ctx, cx, cz, 18)
	Kit.place(ctx.props, "Cabin", Kit.at(cx, H, cz, 90), 1.1, PAL)
	Fx.area(
		ctx.fx,
		"Dust",
		Vector3.new(1.4, 1, 1.4),
		Vector3.new(cx - 2.2, H + 25, cz - 4.3),
		{ rgb(200, 200, 205) },
		2,
		220
	)
	for i = 0, 5 do
		Kit.place(
			ctx.props,
			"Pumpkin",
			Kit.at(
				cx - 4 + (i % 3) * 3.4 + ctx.rng:NextNumber(-0.5, 0.5),
				H,
				cz + 14 + (i // 3) * 3.2,
				ctx.rng:NextNumber(0, 360)
			),
			ctx.rng:NextNumber(0.9, 1.2),
			PAL
		)
	end
	for i, z in { 212, 240 } do
		Kit.place(ctx.props, "FencePost", Kit.at(66, H, z, 0), 1.3, PAL)
		local lantern = Kit.place(ctx.props, "Lantern", Kit.at(66, H + 6.3, z, i * 20), 1.1, PAL)
		local glow = lantern and lantern:FindFirstChild("Glow")
		if glow and glow:IsA("BasePart") then
			Parts.light(glow, rgb(255, 196, 120), 14, 0.8)
		end
	end

	-- dense forest in clusters (evergreens mixed in), forest floor
	for _, c in
		{
			{ -64, 212, 3 },
			{ -70, 290, 3 },
			{ -160, 214, 5 },
			{ -172, 288, 4 },
			{ -232, 250, 5 },
			{ 120, 212, 4 },
			{ 150, 262, 5 },
			{ 92, 290, 3 },
			{ 214, 236, 5 },
			{ 236, 290, 4 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], TREES, c[3], 10, PAL, nil, true)
	end
	for _, c in { { -110, 206 }, { -200, 280 }, { 180, 210 }, { 120, 292 } } do
		Valley.cluster(
			ctx,
			ctx.nature,
			c[1],
			c[2],
			{ { "PineA", 1, 1, 1.3 }, { "PineB", 1, 0.9, 1.1 } },
			2,
			6,
			GREEN,
			nil,
			true
		)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, GROUND, 9, { Valley.INNER + 8, 150 }, 7, PAL)
		Valley.scatter(ctx, ctx.nature, side, { "RockA", "RockB" }, 3, { Valley.INNER + 10, 170 }, 12, PAL)
	end
	Valley.shoulders(ctx, COVER, 20, PAL)

	-- far: autumn forest bands, hills, snowy peaks
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "ForestFar", 290, 225, 1.1 }, { "ForestFar", 320, 280, 1.2 }, { "HillB", 250, 260, 1 } },
			PAL
		)
		Valley.farRow(ctx, side, { { "MountainA", 420, 250, 1.2 } }, FAR)
	end

	-- ambience: falling leaves over both sides and the canyon
	Valley.fx(ctx, "Leaves", -1, 100, 130, H + 18, 4, nil, 1.3)
	Valley.fx(ctx, "Leaves", 1, 100, 130, H + 18, 4, { rgb(255, 196, 60) }, 1.3)
	Valley.fx(ctx, "LeavesRed", 0, 0, 70, 22, 2, nil, 1.2)

	-- hand-over: beach at the start, mushrooms at the end
	Valley.blend(ctx, { { "TropicalPlant", 1, 1, 1.2 }, { "Driftwood", 1, 0.8, 1 } }, Palettes.zones[2], true, 3)
	Valley.blend(
		ctx,
		{ { "MushroomBell", 1, 0.7, 0.9 }, { "GlowShrooms", 2, 1, 1.3 }, { "MushroomSmallA", 2, 1.2, 1.6 } },
		Palettes.zones[4],
		false,
		4
	)
end
