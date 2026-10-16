--!strict
-- Partner A. Zone 9, Volcano (z 800..900): banded basalt banks, the great stepped volcano on the left with a lava
-- lake and lava rivers, glowing lava channels across the dark plateau with stone banks, basalt column clusters,
-- lava rocks with glowing cracks, charred trees, steam vents and obsidian spikes; warm point lights near the lava,
-- a smaller far volcano. Ambience: rising embers, falling ash and steam (kept off the bloom: few neon pieces).
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local ROCKS = {
	{ "BasaltColumns", 3, 0.9, 1.4 },
	{ "LavaRock", 2, 0.9, 1.3 },
	{ "Obsidian", 2, 0.9, 1.3 },
	{ "CharredTree", 2, 1, 1.3 },
}
local COVER = { { "RockC", 3, 0.6, 0.9 }, { "Obsidian", 1, 0.4, 0.6 }, { "LavaRock", 1, 0.3, 0.5 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[9]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 12
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankC", "BankA", "BankC" }, H)
		Valley.patches(ctx, side, { rgb(84, 70, 66), rgb(120, 98, 90), rgb(70, 58, 58) }, 6)
	end

	-- the volcano (left)
	local vx, vz = -150, 852
	Valley.keepOut(ctx, vx, vz, 52)
	Kit.place(ctx.terrain, "VolcanoPeak", Kit.at(vx, H, vz, -90), 1.15, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "CraterGlow", Vector3.one, Vector3.new(vx, H + 78, vz)),
		rgb(255, 120, 40),
		60,
		2
	)
	Fx.area(ctx.fx, "Embers", Vector3.new(18, 2, 18), Vector3.new(vx, H + 76, vz), nil, 2.2, 420)
	Fx.area(ctx.fx, "Steam", Vector3.new(14, 2, 14), Vector3.new(vx, H + 78, vz), { rgb(120, 110, 108) }, 1.2, 420)

	-- lava channels across the plateau (right and left), glowing, with stone banks and a warm light each
	local function channel(a: Vector3, b: Vector3, w: number)
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		Parts.block(ctx.props, "LavaChannel", Vector3.new(w, 0.4, len), cf * CFrame.new(0, 0.1, 0), rgb(255, 112, 24), {
			material = Enum.Material.Neon,
			collide = false,
			query = false,
			shadow = false,
		})
		for _, s in { -1, 1 } do
			Parts.block(
				ctx.props,
				"LavaBank",
				Vector3.new(1.6, 1, len + 1),
				cf * CFrame.new(s * (w / 2 + 0.8), 0.3, 0),
				PAL.StoneDark :: Color3,
				{
					collide = false,
					query = false,
				}
			)
		end
		Parts.light(
			Parts.anchor(ctx.props, "LavaLight", Vector3.one, (a + b) / 2 + Vector3.new(0, 4, 0)),
			rgb(255, 120, 50),
			22,
			1.2
		)
	end
	channel(Vector3.new(70, H, 812), Vector3.new(150, H, 840), 5)
	channel(Vector3.new(150, H, 840), Vector3.new(240, H, 826), 5)
	channel(Vector3.new(-96, H, 812), Vector3.new(-70, H, 888), 4)
	Valley.keepOut(ctx, 150, 840, 8)

	-- steam vents with plumes
	for _, p in { { 96, 868 }, { 180, 880 }, { -80, 830 } } do
		Kit.place(ctx.props, "SteamVent", Kit.at(p[1], H, p[2], 0), 1.2, PAL)
		Fx.area(ctx.fx, "Steam", Vector3.new(2, 1, 2), Vector3.new(p[1], H + 1, p[2]), nil, 0.8, 260)
		Valley.keepOut(ctx, p[1], p[2], 6)
	end

	-- basalt, lava rocks, obsidian and charred trees in clusters
	for _, c in
		{
			{ -70, 870, 3 },
			{ -100, 808, 3 },
			{ -230, 820, 4 },
			{ 70, 840, 3 },
			{ 120, 892, 3 },
			{ 200, 808, 4 },
			{ 240, 870, 4 },
		}
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], ROCKS, c[3], 9, PAL)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, ROCKS, 6, { Valley.INNER + 8, 180 }, 11, PAL)
	end
	Valley.shoulders(ctx, COVER, 16, PAL)

	-- far: dark ridges and a smaller volcano
	Valley.farRow(ctx, 1, { { "VolcanoPeak", 350, 860, 0.7, 90 }, { "MountainC", 300, 820, 1.2 } }, PAL)
	Valley.farRow(ctx, -1, { { "MountainC", 340, 880, 1.3 }, { "MountainC", 380, 820, 1.0 } }, PAL)

	-- ambience: embers rising, ash drifting
	Valley.fx(ctx, "Embers", -1, 100, 140, H + 2, 4, nil, 1.2)
	Valley.fx(ctx, "Embers", 1, 100, 140, H + 2, 4, nil, 1.2)
	Valley.fx(ctx, "Embers", 0, 0, 70, 1, 1, nil, 0.8)
	Valley.fx(ctx, "Ash", 0, 0, 160, H + 30, 4, nil, 1.2)

	-- hand-over from the reef at the start
	Valley.blend(ctx, { { "BrainCoral", 1, 0.6, 0.8 }, { "Shell", 2, 1, 1.3 } }, Palettes.corals[2], true, 2)
end
