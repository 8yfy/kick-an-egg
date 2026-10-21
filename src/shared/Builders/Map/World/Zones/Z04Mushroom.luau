--!strict
-- Partner A. Zone 4, Mushroom Grove (z 300..400): lavender ground and purple stone banks, a forest of giant
-- mushrooms with red / violet / teal / orange caps and glowing gills, three mushroom houses with lit portholes, the
-- towering Mushroom Tower with its spiral stair on the right, twisted root arches beside the track (never over it),
-- glow-shroom clusters lighting the shoulders. Far giant-mushroom silhouettes. Ambience: spores, ground mist,
-- fireflies.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local GIANTS = {
	{ "MushroomDome", 3, 0.9, 1.3 },
	{ "MushroomFlat", 2, 0.9, 1.2 },
	{ "MushroomCone", 2, 0.9, 1.2 },
	{ "MushroomBell", 3, 1.0, 1.4 },
}
local SMALL = {
	{ "GlowShrooms", 3, 1.0, 1.5 },
	{ "MushroomSmallA", 3, 1.2, 1.8 },
	{ "MushroomSmallB", 2, 1.2, 1.8 },
	{ "BushB", 1, 1, 1.2 },
}
local COVER = {
	{ "GlowShrooms", 3, 0.8, 1.2 },
	{ "MushroomSmallA", 2, 1, 1.4 },
	{ "MushroomSmallB", 2, 1, 1.4 },
	{ "GrassB", 1, 1, 1.3 },
}

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[4]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 8
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankA", "BankB", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(170, 130, 220), rgb(140, 100, 190), rgb(120, 210, 190) }, 6)
	end
	local function caps(): any
		return Palettes.caps[ctx.rng:NextInteger(1, #Palettes.caps)]
	end

	-- the Mushroom Tower (right)
	local tx, tz = 112, 352
	Valley.keepOut(ctx, tx, tz, 34)
	Kit.place(ctx.props, "MushroomTower", Kit.at(tx, H, tz, 90), 1.25, Palettes.caps[2])
	Parts.light(
		Parts.anchor(ctx.props, "TowerGlow", Vector3.one, Vector3.new(tx, H + 66, tz)),
		rgb(255, 150, 240),
		50,
		1.2
	)

	-- mushroom houses facing the track
	for _, hsp in { { -84, 322, -90, 1 }, { -132, 372, -60, 3 }, { 78, 314, 90, 4 } } do
		Valley.keepOut(ctx, hsp[1], hsp[2], 14)
		Kit.place(ctx.props, "MushroomHouse", Kit.at(hsp[1], H, hsp[2], hsp[3]), 1, Palettes.caps[hsp[4]])
		Parts.light(
			Parts.anchor(ctx.props, "HouseGlow", Vector3.one, Vector3.new(hsp[1], H + 6, hsp[2])),
			rgb(120, 255, 222),
			16,
			0.8
		)
	end

	-- giant mushroom clusters, each mushroom with its own cap colour
	for _, c in
		{
			{ -64, 352, 3 },
			{ -160, 316, 3 },
			{ -196, 384, 2 },
			{ -240, 340, 2 },
			{ 72, 372, 2 },
			{ 168, 316, 2 },
			{ 200, 388, 3 },
			{ 240, 340, 2 },
		}
	do
		for _ = 1, c[3] do
			Valley.cluster(
				ctx,
				ctx.nature,
				c[1] + ctx.rng:NextNumber(-8, 8),
				c[2] + ctx.rng:NextNumber(-8, 8),
				GIANTS,
				1,
				1,
				caps(),
				nil,
				true
			)
		end
	end
	-- root arches beside the track (spanning along it, on the banks), glow shrooms and small mushrooms
	for _, r in { { -54, 334 }, { 56, 386 }, { -56, 392 } } do
		Kit.place(ctx.props, "RootArch", Kit.at(r[1], H, r[2], 90 + ctx.rng:NextNumber(-8, 8)), 1, PAL)
	end
	for _, side in { -1, 1 } do
		local glows = Valley.scatter(
			ctx,
			ctx.nature,
			side,
			SMALL,
			10,
			{ Valley.INNER + 6, 140 },
			6,
			PAL,
			{ shadow = false }
		)
		for k, m in glows do
			if k % 4 == 0 then
				local g = m:FindFirstChild("Glow")
				if g and g:IsA("BasePart") then
					Parts.light(g, rgb(120, 255, 222), 12, 0.7)
				end
			end
		end
	end
	Valley.shoulders(ctx, COVER, 22, PAL)

	-- far: giant mushroom silhouettes and purple hills
	for _, side in { -1, 1 } do
		Valley.farRow(ctx, side, { { "HillB", 260, 330, 1.1 }, { "HillA", 330, 380, 1.4 } }, PAL)
		Valley.farRow(ctx, side, { { "MushroomDome", 300, 316, 3.2 }, { "MushroomCone", 360, 368, 2.8 } }, caps())
	end

	-- ambience: spores, ground mist, fireflies
	Valley.fx(ctx, "Spores", -1, 100, 140, H + 6, 10, nil, 1.4)
	Valley.fx(ctx, "Spores", 1, 100, 140, H + 6, 10, { rgb(255, 150, 240), rgb(120, 255, 222) }, 1.4)
	Valley.fx(ctx, "GroundMist", 0, 0, 76, 1.5, 1, nil, 1.2)
	Valley.fx(ctx, "Fireflies", -1, 90, 90, H + 3, 6, { rgb(140, 255, 230) }, 1.4)
	Valley.fx(ctx, "Fireflies", 1, 90, 90, H + 3, 6, { rgb(140, 255, 230) }, 1.4)

	-- hand-over from the autumn forest at the start
	Valley.blend(
		ctx,
		{ { "LeafPile", 2, 0.9, 1.2 }, { "Pumpkin", 1, 1, 1.2 }, { "MapleB", 1, 0.8, 1 } },
		Palettes.zones[3],
		true,
		4
	)
end
