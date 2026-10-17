--!strict
-- Partner A. Zone 10, Crystal Caves (z 900..1000): violet cave rock banks with crystal-studded rock spires along
-- the rims (a cave-mouth silhouette), the giant Crystal Spire with its floating shard halo on the right, crystal
-- arches beside the track, crystal clusters in blue and pink, geodes split open, glowing shrooms. Ambience:
-- crystal glimmers, cyan spores and violet ground mist.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local CRYSTALS = {
	{ "CrystalClusterA", 2, 1.0, 1.6 },
	{ "CrystalClusterB", 3, 1.0, 1.6 },
	{ "Geode", 1, 0.9, 1.2 },
	{ "GlowShrooms", 1, 1.2, 1.6 },
}
local COVER = { { "CrystalClusterB", 3, 0.6, 0.9 }, { "RockC", 2, 0.6, 0.9 }, { "GlowShrooms", 1, 0.8, 1.1 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[10]
	local PINK = Palettes.crystalPink
	local ctx = Valley.new(zone, parent, PAL)
	local function tone(): any
		return if ctx.rng:NextNumber() < 0.6 then PAL else PINK
	end
	local H = 10
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankC", "BankA" }, H)
		Valley.patches(ctx, side, { rgb(104, 90, 156), rgb(80, 68, 128), rgb(70, 110, 160) }, 5)
		-- cave spires along the rim
		for z = ctx.z0 + 8, ctx.z1 - 8, 22 do
			Valley.put(
				ctx,
				ctx.terrain,
				"CaveRock",
				side * (Valley.INNER + ctx.rng:NextNumber(14, 22)),
				z + ctx.rng:NextNumber(-5, 5),
				ctx.rng:NextNumber(1.1, 1.6),
				nil,
				tone()
			)
		end
	end

	-- the Crystal Spire (right)
	local sx, sz = 126, 952
	Valley.keepOut(ctx, sx, sz, 36)
	Kit.place(ctx.props, "CrystalSpire", Kit.at(sx, H, sz, 0), 1.3, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "SpireGlow", Vector3.one, Vector3.new(sx, H + 30, sz)),
		rgb(170, 140, 255),
		50,
		1.6
	)
	-- crystal arches on the left bank (spanning along the track) and geodes
	for _, z in { 926, 978 } do
		Kit.place(ctx.props, "CrystalArch", Kit.at(-62, H, z, 90), 1.2, tone())
		Valley.keepOut(ctx, -62, z, 14)
	end
	for _, c in
		{
			{ -100, 960, 4 },
			{ -160, 920, 4 },
			{ -190, 990, 3 },
			{ 80, 910, 3 },
			{ 190, 930, 4 },
			{ 200, 994, 3 },
			{ 76, 990, 3 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], CRYSTALS, c[3], 9, tone())
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, CRYSTALS, 6, { Valley.INNER + 28, 200 }, 12, tone())
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: giant crystal-studded spires
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "CaveRock", 280, 930, 3.5 }, { "CaveRock", 330, 990, 4 }, { "MountainC", 380, 950, 1.1 } },
			tone()
		)
	end

	-- ambience
	Valley.fx(ctx, "CrystalGlimmer", -1, 100, 140, H + 6, 10, nil, 1.5)
	Valley.fx(ctx, "CrystalGlimmer", 1, 100, 140, H + 6, 10, { rgb(255, 170, 240) }, 1.5)
	Valley.fx(ctx, "Spores", 0, 0, 70, 4, 6, { rgb(130, 230, 255) }, 1)
	Valley.fx(ctx, "GroundMist", 0, 0, 76, 1.5, 1, { rgb(170, 140, 255) }, 1.2)

	-- hand-over from the volcano at the start, to the jungle at the end
	Valley.blend(ctx, { { "BasaltColumns", 1, 0.7, 0.9 }, { "LavaRock", 1, 0.6, 0.8 } }, Palettes.zones[9], true, 2)
	Valley.blend(ctx, { { "Fern", 2, 1, 1.3 }, { "JungleTreeB", 1, 0.7, 0.9 } }, Palettes.zones[11], false, 3)
end
