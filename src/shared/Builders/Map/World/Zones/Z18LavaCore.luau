--!strict
-- Partner A. Zone 18, Lava Core (z 1700..1800): cooler and more geometric than the Volcano: obsidian slate banks,
-- ground slabs split by bright yellow-orange crack grids, the Molten Core (a floating molten cube in two crossed
-- rings on a stepped pedestal) on the right, stacked magma pillars with glowing seams, heat obelisks, floating
-- obsidian cubes bobbing, heat vents. Ambience: bright embers rising, ash.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local GEOMETRY = {
	{ "MagmaPillar", 3, 1.0, 1.6 },
	{ "HeatObelisk", 1, 1.0, 1.3 },
	{ "CrackedSlab", 2, 1.0, 1.4 },
	{ "HeatVent", 1, 1, 1.3 },
}
local COVER = { { "CrackedSlab", 2, 0.3, 0.5 }, { "RockC", 2, 0.6, 0.9 }, { "Obsidian", 1, 0.4, 0.6 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[18]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 10
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankC", "BankA" }, H)
		Valley.patches(ctx, side, { rgb(84, 76, 92), rgb(60, 54, 70), rgb(100, 86, 96) }, 5)
	end

	-- the Molten Core (right)
	local mx, mz = 124, 1752
	Valley.keepOut(ctx, mx, mz, 30)
	Kit.place(ctx.props, "MoltenCore", Kit.at(mx, H, mz, 0), 1.3, PAL)
	Parts.light(Parts.anchor(ctx.props, "CoreGlow", Vector3.one, Vector3.new(mx, H + 39, mz)), rgb(255, 170, 60), 60, 2)
	Fx.area(
		ctx.fx,
		"Embers",
		Vector3.new(14, 14, 14),
		Vector3.new(mx, H + 39, mz),
		{ rgb(255, 230, 120), rgb(255, 120, 40) },
		2,
		400
	)

	-- geometric heat structures in rows of three (deliberate avenues) and clusters
	for _, z in { 1716, 1752, 1788 } do
		Kit.place(ctx.props, "HeatObelisk", Kit.at(-66, H, z, 0), 1.4, PAL)
	end
	for _, c in
		{ { -110, 1730, 4 }, { -180, 1780, 4 }, { -220, 1720, 3 }, { 72, 1786, 3 }, { 200, 1720, 4 }, { 230, 1790, 3 } }
	do
		Valley.cluster(ctx, ctx.props, c[1], c[2], GEOMETRY, c[3], 10, PAL)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.props, side, GEOMETRY, 6, { Valley.INNER + 10, 220 }, 12, PAL)
	end
	-- floating cubes
	for _ = 1, 10 do
		local side = if ctx.rng:NextNumber() < 0.5 then -1 else 1
		local cube = Valley.put(
			ctx,
			ctx.props,
			"FloatingCube",
			side * ctx.rng:NextNumber(60, 240),
			ctx.rng:NextNumber(ctx.z0 + 6, ctx.z1 - 6),
			ctx.rng:NextNumber(0.8, 1.8),
			nil,
			PAL,
			H + ctx.rng:NextNumber(8, 30)
		)
		Valley.bob(cube, ctx.rng:NextNumber(0.8, 1.6), ctx.rng:NextNumber(0.12, 0.22))
	end
	Valley.shoulders(ctx, COVER, 14, PAL)

	-- far: dark geometric ridges
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "MagmaPillar", 280, 1730, 5 }, { "MagmaPillar", 330, 1780, 6 }, { "MountainC", 380, 1750, 1.2 } },
			PAL
		)
	end

	-- ambience
	Valley.fx(ctx, "Embers", -1, 100, 140, H + 2, 4, { rgb(255, 230, 120), rgb(255, 150, 40) }, 1.2)
	Valley.fx(ctx, "Embers", 1, 100, 140, H + 2, 4, { rgb(255, 230, 120), rgb(255, 150, 40) }, 1.2)
	Valley.fx(ctx, "Ash", 0, 0, 160, H + 30, 4, nil, 1)

	-- hand-over from the frozen aurora at the start
	Valley.blend(ctx, { { "IceSpikes", 1, 0.5, 0.7 } }, Palettes.zones[17], true, 2)
end
