--!strict
-- Partner A. Zone 17, Frozen Aurora (z 1600..1700): glacier-blue banks under snow, the Ice Palace with crystal
-- spires on the left, ice arches beside the track, frozen crystal trees, ice spikes, a giant snowflake sculpture,
-- igloos with warm doorways, and great green / violet aurora ribbons across the sky. Ambience: snow, aurora
-- sparkles.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local FROZEN = { { "FrozenTree", 3, 1.0, 1.5 }, { "IceSpikes", 2, 1.0, 1.5 }, { "SnowLumps", 2, 1, 1.4 } }
local COVER = { { "SnowLumps", 3, 0.6, 0.9 }, { "IceSpikes", 1, 0.4, 0.6 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[17]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 12
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankC", "BankA" }, H)
		Valley.patches(ctx, side, { rgb(236, 246, 255), rgb(190, 222, 246), rgb(170, 240, 230) }, 5)
	end

	-- the Ice Palace (left)
	local px, pz = -126, 1652
	Valley.keepOut(ctx, px, pz, 38)
	Kit.place(ctx.props, "IcePalace", Kit.at(px, H, pz, -90), 1.25, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "PalaceGlow", Vector3.one, Vector3.new(px, H + 40, pz)),
		rgb(140, 255, 220),
		50,
		1.4
	)

	-- ice arches along the right bank, a snowflake sculpture, igloos
	for _, z in { 1618, 1676 } do
		Kit.place(ctx.props, "IceArch", Kit.at(64, H, z, 90), 1.2, PAL)
		Valley.keepOut(ctx, 64, z, 14)
	end
	Valley.keepOut(ctx, 110, 1650, 10)
	Kit.place(ctx.props, "SnowCrystal", Kit.at(110, H, 1650, 90), 1.6, PAL)
	for _, ig in { { -72, 1690, -70 }, { 150, 1620, 120 }, { 170, 1690, 80 } } do
		Kit.place(ctx.props, "Igloo", Kit.at(ig[1], H, ig[2], ig[3]), 1.2, PAL)
		Valley.keepOut(ctx, ig[1], ig[2], 8)
	end

	-- frozen groves
	for _, c in
		{ { -70, 1610, 3 }, { -190, 1620, 4 }, { -200, 1690, 3 }, { 90, 1600, 3 }, { 210, 1650, 4 }, { 240, 1700, 3 } }
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], FROZEN, c[3], 9, PAL)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, FROZEN, 8, { Valley.INNER + 8, 220 }, 10, PAL)
	end
	Valley.shoulders(ctx, COVER, 16, PAL)

	-- far: icy massifs
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "MountainB", 360, 1640, 1.2 }, { "MountainA", 300, 1690, 1.0 } },
			Palettes.merge(PAL, { Stone = rgb(170, 210, 236), StoneDark = rgb(130, 176, 214) })
		)
	end

	-- the aurora: three long ribbons high over the zone
	Fx.aurora(
		ctx.fx,
		Vector3.new(-260, 150, 1590),
		Vector3.new(260, 170, 1660),
		60,
		rgb(90, 255, 180),
		rgb(150, 120, 255)
	)
	Fx.aurora(
		ctx.fx,
		Vector3.new(-240, 185, 1640),
		Vector3.new(240, 160, 1710),
		46,
		rgb(120, 220, 255),
		rgb(90, 255, 160)
	)
	Fx.aurora(
		ctx.fx,
		Vector3.new(-200, 130, 1680),
		Vector3.new(220, 145, 1620),
		34,
		rgb(200, 120, 255),
		rgb(120, 255, 200)
	)

	-- ambience
	Valley.fx(ctx, "Snow", -1, 110, 160, H + 26, 4, nil, 1)
	Valley.fx(ctx, "Snow", 1, 110, 160, H + 26, 4, nil, 1)
	Valley.fx(ctx, "AuroraSparkle", 0, 0, 160, H + 10, 10, nil, 1.4)

	-- hand-over: factory at the start, lava core at the end
	Valley.blend(ctx, { { "Crate", 1, 0.7, 0.9 } }, Palettes.zones[16], true, 1)
	Valley.blend(ctx, { { "CrackedSlab", 1, 0.6, 0.8 }, { "HeatVent", 1, 0.8, 1 } }, Palettes.zones[18], false, 2)
end
