--!strict
-- Partner A. Zone 20, Rainbow Heaven (z 1900..2000), the final reward: soft cloud banks and a white plateau,
-- the Rainbow Palace with golden domes on the left, a great rainbow standing beside the track on the right (along
-- it, never over it), cloud pavilions, golden lamps along the banks, pastel flowers and blossom trees, small cloud
-- islands floating. The track ends at the Heaven Gate (MapBuilder) with the Golden Egg trophy above it. Gentle,
-- not cluttered: wide open spaces between the set pieces. Ambience: rainbow sparkles and drifting clouds.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local GARDEN = { { "TreeBallB", 2, 1.0, 1.3 }, { "FlowersB", 3, 1.2, 1.6 }, { "BushFlowerA", 2, 1, 1.3 } }
local COVER = { { "FlowersA", 3, 0.9, 1.2 }, { "GrassB", 1, 1, 1.3 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[20]
	local BLOSSOM = Palettes.merge(PAL, {
		Leaf = rgb(255, 190, 220),
		LeafDark = rgb(250, 160, 200),
		LeafLight = rgb(255, 230, 240),
		Trunk = rgb(200, 170, 150),
	})
	local ctx = Valley.new(zone, parent, PAL)
	local H = 4
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankB", "BankA" }, H)
		Valley.patches(ctx, side, { rgb(255, 236, 246), rgb(236, 244, 255), rgb(255, 250, 230) }, 5)
		for z = ctx.z0 + 8, ctx.z1 - 6, 20 do
			local lamp = Valley.put(ctx, ctx.props, "GoldLamp", side * (Valley.INNER + 11), z, 1, 0, PAL, H)
			local g = lamp and lamp:FindFirstChild("Glow")
			if g and g:IsA("BasePart") then
				Parts.light(g, rgb(255, 236, 180), 14, 0.7)
			end
		end
	end

	-- the Rainbow Palace (left) and the great rainbow (right, along the track)
	local px, pz = -128, 1950
	Valley.keepOut(ctx, px, pz, 36)
	Kit.place(ctx.props, "RainbowPalace", Kit.at(px, H, pz, -90), 1.25, PAL)
	Parts.light(
		Parts.anchor(ctx.props, "PalaceGlow", Vector3.one, Vector3.new(px + 20, H + 40, pz)),
		rgb(255, 240, 200),
		40,
		1.2
	)
	Valley.keepOut(ctx, 96, 1946, 40)
	Kit.place(ctx.props, "RainbowArc", Kit.at(96, H - 1, 1946, 90), 1.3, PAL)

	-- cloud pavilions and blossom gardens, with wide open lawns between
	for _, p in { { -74, 1912, -60 }, { 160, 1990, 120 }, { -200, 1990, -80 } } do
		Kit.place(ctx.props, "CloudPavilion", Kit.at(p[1], H, p[2], p[3]), 1, PAL)
		Valley.keepOut(ctx, p[1], p[2], 12)
	end
	for _, c in { { -80, 1980, 3 }, { -190, 1916, 3 }, { 170, 1916, 3 }, { 230, 1970, 3 } } do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], GARDEN, c[3], 9, BLOSSOM, { shadow = false }, true)
	end
	Valley.shoulders(ctx, COVER, 16, PAL)

	-- small cloud islands floating, far cloud towers
	for _ = 1, 6 do
		local side = if ctx.rng:NextNumber() < 0.5 then -1 else 1
		local cloud = Valley.put(
			ctx,
			ctx.far,
			({ "CloudA", "CloudB" })[ctx.rng:NextInteger(1, 2)],
			side * ctx.rng:NextNumber(80, 260),
			ctx.rng:NextNumber(ctx.z0, ctx.z1),
			ctx.rng:NextNumber(0.6, 1.2),
			nil,
			PAL,
			ctx.rng:NextNumber(30, 70),
			{ shadow = false }
		)
		Valley.bob(cloud, 1.5, 0.08)
	end
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "CloudPillar", 300, 1920, 3 }, { "CloudPillar", 340, 1980, 3.6 }, { "CloudB", 380, 1950, 2.4 } },
			Palettes.merge(PAL, { Trim = rgb(240, 244, 255) })
		)
	end

	-- ambience
	Valley.fx(ctx, "RainbowSparkle", -1, 120, 160, H + 6, 10, nil, 1.3)
	Valley.fx(ctx, "RainbowSparkle", 1, 120, 160, H + 6, 10, nil, 1.3)
	Valley.fx(ctx, "CloudDrift", 0, 0, 120, H + 2, 2, nil, 0.8, 300)

	-- hand-over from the galaxy at the start
	Valley.blend(ctx, { { "CelestialCrystal", 1, 0.5, 0.7 }, { "StarLamp", 1, 0.8, 1 } }, Palettes.zones[19], true, 2)
end
