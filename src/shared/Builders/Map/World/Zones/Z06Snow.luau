--!strict
-- Partner A. Zone 6, Snowy Peaks (z 500..600): tall blue-grey banks under thick snow, the red-roofed Summit Lodge on
-- a snowy hill on the right with lanterns and a chimney plume, snowy pine forests, a frozen pond with a sled and
-- snowmen, ice rocks, and great snow-capped massifs closing the view. Ambience: falling snow and icy wind.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local PINES = { { "PineSnowA", 3, 1.0, 1.4 }, { "PineSnowB", 2, 1.0, 1.3 }, { "PineA", 1, 0.9, 1.2 } }
local SNOWY =
	{ { "SnowLumps", 3, 1, 1.4 }, { "IceRock", 2, 0.9, 1.3 }, { "RockB", 1, 0.8, 1.1 }, { "Snowman", 1, 1, 1.1 } }
local COVER = { { "SnowLumps", 3, 0.6, 0.9 }, { "IceRock", 1, 0.5, 0.7 }, { "RockC", 1, 0.6, 0.9 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[6]
	local BANK = Palettes.merge(PAL, { Ground = rgb(246, 250, 255) })
	local ctx = Valley.new(zone, parent, PAL)
	local H = 14
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankC", "BankA", "BankC" }, H, { palette = BANK })
		Valley.patches(ctx, side, { rgb(250, 252, 255), rgb(224, 236, 250), rgb(206, 224, 244) }, 6)
	end

	-- the Summit Lodge on its hill (right)
	local lx, lz = 118, 552
	Valley.keepOut(ctx, lx, lz, 36)
	Kit.place(ctx.terrain, "HillB", Kit.at(lx, H - 1, lz, 20), Vector3.new(0.7, 0.42, 0.7), BANK)
	local top = H - 1 + 24 * 0.42
	Kit.place(ctx.props, "SummitLodge", Kit.at(lx, top - 1, lz, 90), 1.3, PAL)
	Fx.area(
		ctx.fx,
		"Steam",
		Vector3.new(2, 1, 2),
		Vector3.new(lx - 5.2, top + 33, lz + 6.5),
		{ rgb(230, 232, 240) },
		0.6,
		300
	)
	Parts.light(
		Parts.anchor(ctx.props, "LodgeGlow", Vector3.one, Vector3.new(lx - 18, top + 8, lz)),
		rgb(255, 200, 130),
		26,
		1.2
	)
	for _, z in { 528, 576 } do
		Kit.place(ctx.props, "LampPost", Kit.at(lx - 34, top - 4, z, 0), 1, PAL)
	end

	-- the frozen pond with a sled and snowmen (left)
	local fx, fz = -96, 536
	Valley.keepOut(ctx, fx, fz, 16)
	Kit.place(ctx.props, "Pond", Kit.at(fx, H + 0.2, fz, 0), 1.2, Palettes.merge(PAL, { Water = PAL.Ice }))
	Kit.place(ctx.props, "Sled", Kit.at(fx + 14, H, fz - 6, 40), 1, PAL)
	Kit.place(ctx.props, "Snowman", Kit.at(fx - 16, H, fz + 6, -70), 1.2, PAL)
	Kit.place(ctx.props, "Snowman", Kit.at(-70, H, 584, -110), 1, PAL)
	Kit.place(
		ctx.props,
		"Cabin",
		Kit.at(-150, H, 584, -90),
		1,
		Palettes.merge(PAL, { Roof = rgb(250, 252, 255), RoofDark = rgb(220, 232, 246) })
	)
	Valley.keepOut(ctx, -150, 584, 14)

	-- snowy pine forests in clusters
	for _, c in
		{
			{ -66, 510, 3 },
			{ -140, 520, 4 },
			{ -200, 560, 5 },
			{ -110, 596, 3 },
			{ 64, 516, 3 },
			{ 70, 590, 3 },
			{ 180, 520, 4 },
			{ 190, 590, 5 },
			{ 250, 556, 4 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], PINES, c[3], 10, PAL, nil, true)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, SNOWY, 8, { Valley.INNER + 8, 170 }, 10, PAL)
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: great snow-capped massifs
	Valley.farRow(ctx, -1, { { "MountainB", 360, 540, 1.3 }, { "MountainA", 300, 590, 1.0 } }, PAL)
	Valley.farRow(ctx, 1, { { "MountainB", 380, 520, 1.2 }, { "MountainA", 320, 580, 1.1 } }, PAL)

	-- ambience
	Valley.fx(ctx, "Snow", -1, 110, 160, H + 26, 4, nil, 1.3, 260)
	Valley.fx(ctx, "Snow", 1, 110, 160, H + 26, 4, nil, 1.3, 260)
	Valley.fx(ctx, "Snow", 0, 0, 80, 30, 2, nil, 1.2)
	Valley.fx(ctx, "IcyWind", 0, 0, 70, 6, 3, nil, 1)

	-- hand-over: desert at the start, candy at the end
	Valley.blend(ctx, { { "BarrelCactus", 2, 1, 1.2 }, { "RockA", 1, 0.8, 1 } }, Palettes.zones[5], true, 2)
	Valley.blend(ctx, { { "CandyCane", 2, 1, 1.2 }, { "Gumdrop", 2, 1, 1.3 } }, Palettes.zones[7], false, 4)
end
