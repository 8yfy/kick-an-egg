--!strict
-- Partner A. Zone 15, Toxic Swamp (z 1400..1500): low murky olive banks, the giant bubbling Bog Cauldron on the
-- left, a crooked stilt hut over a murky pool on the right, broken boardwalks between pools, twisted mossy trees,
-- toxic pitcher plants, odd purple mushrooms, leaking waste barrels and cattails. Ambience: toxic bubbles rising
-- from the pools and the cauldron, green mist.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local TREES = { { "TwistedTree", 1, 1.0, 1.5 } }
local PLANTS = {
	{ "PitcherPlant", 3, 1.0, 1.5 },
	{ "OddMushroom", 3, 1.0, 1.6 },
	{ "Cattails", 3, 1.0, 1.4 },
	{ "WasteBarrel", 1, 1, 1.2 },
}
local COVER = { { "Cattails", 3, 0.8, 1.1 }, { "OddMushroom", 1, 0.5, 0.7 }, { "GrassA", 2, 1, 1.3 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[15]
	local ctx = Valley.new(zone, parent, PAL)
	local H = 5
	for _, side in { -1, 1 } do
		Valley.plateau(ctx, side, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
		Valley.banks(ctx, side, { "BankB", "BankD" }, H)
		Valley.patches(ctx, side, { rgb(84, 104, 54), rgb(112, 130, 70), rgb(76, 90, 62) }, 5)
	end

	-- murky pools with bubbles
	local pools = { { -80, 1440, 1.2 }, { -170, 1480, 1.5 }, { 140, 1470, 1.3 }, { 80, 1416, 0.9 }, { 210, 1420, 1.1 } }
	for _, p in pools do
		Valley.keepOut(ctx, p[1], p[2], 10 * p[3])
		Kit.place(ctx.terrain, "Pond", Kit.at(p[1], H + 0.2, p[2], ctx.rng:NextNumber(0, 360)), p[3], PAL)
		Fx.area(
			ctx.fx,
			"ToxicBubbles",
			Vector3.new(12 * p[3], 0.5, 12 * p[3]),
			Vector3.new(p[1], H + 0.6, p[2]),
			nil,
			0.8,
			220
		)
	end
	-- boardwalks linking the pools
	Kit.place(ctx.props, "Boardwalk", CFrame.lookAt(Vector3.new(-125, H, 1460), Vector3.new(-170, H, 1480)), 1, PAL)
	Kit.place(ctx.props, "Boardwalk", CFrame.lookAt(Vector3.new(110, H, 1444), Vector3.new(140, H, 1470)), 1, PAL)

	-- the Bog Cauldron (left)
	local cx, cz = -128, 1420
	Valley.keepOut(ctx, cx, cz, 26)
	Kit.place(ctx.props, "BogCauldron", Kit.at(cx, H, cz, -90), 1.15, PAL)
	Fx.area(ctx.fx, "ToxicBubbles", Vector3.new(20, 1, 20), Vector3.new(cx, H + 24, cz), nil, 2, 400)
	Fx.area(ctx.fx, "Steam", Vector3.new(16, 1, 16), Vector3.new(cx, H + 25, cz), { rgb(170, 230, 120) }, 1, 400)
	Parts.light(
		Parts.anchor(ctx.props, "BrewGlow", Vector3.one, Vector3.new(cx, H + 28, cz)),
		rgb(150, 255, 80),
		40,
		1.4
	)
	-- the stilt hut over the right pool
	Kit.place(ctx.props, "StiltHut", Kit.at(140, H, 1470, 90 + 20), 1.3, PAL)

	-- twisted groves and toxic plants
	for _, c in
		{ { -66, 1470, 3 }, { -200, 1430, 4 }, { -230, 1490, 3 }, { 70, 1490, 3 }, { 180, 1440, 3 }, { 250, 1480, 4 } }
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], TREES, c[3], 10, PAL, nil, true)
	end
	for _, side in { -1, 1 } do
		Valley.scatter(ctx, ctx.nature, side, PLANTS, 12, { Valley.INNER + 8, 220 }, 7, PAL)
	end
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: dark swamp tree lines
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "ForestFar", 290, 1430, 1.2 }, { "ForestFar", 330, 1480, 1.3 }, { "TwistedTree", 260, 1460, 3 } },
			PAL
		)
	end

	-- ambience
	Valley.fx(ctx, "GhostMist", -1, 110, 160, H + 1.5, 2, { rgb(190, 230, 150) }, 1.2)
	Valley.fx(ctx, "GhostMist", 1, 110, 160, H + 1.5, 2, { rgb(190, 230, 150) }, 1.2)
	Valley.fx(ctx, "Fireflies", 0, 0, 70, 5, 6, { rgb(180, 255, 90) }, 1.2)

	-- hand-over: sky at the start, factory at the end
	Valley.blend(ctx, { { "CloudPillar", 1, 0.4, 0.6 } }, Palettes.zones[14], true, 1)
	Valley.blend(ctx, { { "GearSmall", 1, 0.8, 1 }, { "PipeRun", 1, 0.6, 0.8 } }, Palettes.zones[16], false, 2)
end
