--!strict
-- Partner A. Zone 2, Sandy Beach (z 100..200): on the left a low sandy shore with palm clusters, beach huts,
-- umbrellas and towels, driftwood, shells and dunes; on the right the open sea to the horizon (rippling water over a
-- sandy floor) with a striped lighthouse on a rocky islet (its beam sweeps), a wooden dock and coastal rocks.
-- Ambience: sea mist and sparkles over the water, sand gusts on the shore.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)
local Fx = require(script.Parent.Parent.Fx)

local rgb = Color3.fromRGB

local PALMS = { { "PalmA", 3, 1.0, 1.25 }, { "PalmB", 2, 1.0, 1.2 }, { "PalmC", 2, 0.9, 1.1 } }
local SHORE = {
	{ "TropicalPlant", 3, 1.0, 1.4 },
	{ "Driftwood", 1, 0.8, 1.0 },
	{ "Shell", 2, 1.2, 1.6 },
	{ "Starfish", 2, 1.2, 1.5 },
	{ "RockC", 1, 0.8, 1.1 },
}
local COVER = {
	{ "Shell", 3, 1.0, 1.3 },
	{ "Starfish", 2, 1.0, 1.3 },
	{ "GrassB", 3, 1.0, 1.4 },
	{ "TropicalPlant", 1, 0.6, 0.8 },
}

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[2]
	local ROCK = Palettes.coastRock
	local ctx = Valley.new(zone, parent, PAL)
	local H = 4
	-- left: the shore
	Valley.plateau(ctx, -1, H, PAL.Ground :: Color3, PAL.StoneDark :: Color3)
	Valley.banks(ctx, -1, { "BankB", "BankD", "BankB" }, H)
	-- right: low beach banks, then the sea (sandy floor under rippling water)
	Valley.banks(ctx, 1, { "BankB" }, 2.6, { depth = 16 })
	Valley.plateau(ctx, 1, -3, rgb(226, 204, 150), rgb(196, 170, 120), Valley.INNER + 14)
	local len = ctx.z1 - ctx.z0
	local sea = Parts.block(
		ctx.terrain,
		"Sea",
		Vector3.new(Valley.FAR_X - 52, 0.6, len),
		CFrame.new((52 + Valley.FAR_X) / 2, 0.3, ctx.zm),
		rgb(54, 196, 230),
		{
			smooth = true,
			collide = false,
			query = false,
			transparency = 0.22,
			material = Enum.Material.Glass,
		}
	)
	local tex = Instance.new("Texture")
	tex.Texture = "rbxassetid://90860129869797" -- VFX/WorldSprites.streak: ripple lines
	tex.Face = Enum.NormalId.Top
	tex.StudsPerTileU, tex.StudsPerTileV = 18, 7
	tex.Transparency = 0.55
	tex:SetAttribute("SpeedU", 1.6)
	game:GetService("CollectionService"):AddTag(tex, "WorldScroll")
	tex.Parent = sea

	-- the lighthouse on its islet, its beam sweeping
	local lx, lz = 122, 152
	Valley.keepOut(ctx, lx, lz, 30)
	Kit.place(ctx.terrain, "SlabB", Kit.at(lx, -3, lz, 20), Vector3.new(2.3, 0.95, 2.1), ROCK)
	Kit.place(ctx.terrain, "RockD", Kit.at(lx - 14, -1.5, lz + 10, 60), 0.9, ROCK)
	Kit.place(ctx.terrain, "RockB", Kit.at(lx + 12, -1.5, lz - 12, 140), 1.1, ROCK)
	local base = 5.4
	Kit.place(ctx.props, "Lighthouse", Kit.at(lx, base, lz, -90), 1.15, Palettes.lighthouse)
	local lamp = Vector3.new(lx, base + (3.4 + 46 * 0.7 + 3.2) * 1.15, lz)
	local beam = Instance.new("Model")
	beam.Name = "LighthouseBeam"
	for _, s in { -1, 1 } do
		Parts.block(
			beam,
			"Beam",
			Vector3.new(1.6, 1.6, 34),
			CFrame.new(lamp) * CFrame.new(0, 0, s * 17.5),
			rgb(255, 240, 170),
			{
				material = Enum.Material.Neon,
				transparency = 0.6,
				collide = false,
				query = false,
				shadow = false,
			}
		)
	end
	beam.WorldPivot = CFrame.new(lamp)
	beam.Parent = ctx.props
	Valley.spin(beam, 40, true)
	Parts.light(Parts.anchor(ctx.props, "LampLight", Vector3.one, lamp), rgb(255, 236, 170), 40, 1.4)

	-- the dock from the beach into the sea, coastal rocks, a buoy line
	Kit.place(ctx.props, "Dock", Kit.at(Valley.INNER + 14, 0, 124, -90), 1, PAL)
	Valley.keepOut(ctx, 62, 124, 14)
	for _, r in
		{ { 84, 108, "RockB", 1.0 }, { 96, 186, "RockD", 0.8 }, { 160, 118, "RockA", 1.4 }, { 200, 176, "RockB", 1.6 } }
	do
		Kit.place(
			ctx.terrain,
			r[3] :: string,
			Kit.at(r[1] :: number, -2.6, r[2] :: number, ctx.rng:NextNumber(0, 360)),
			r[4] :: number,
			ROCK
		)
	end

	-- the shore: palm clusters, two huts, umbrellas with towels, dunes
	for _, c in
		{ { -60, 112, 3 }, { -92, 160, 4 }, { -58, 188, 2 }, { -150, 130, 4 }, { -170, 186, 3 }, { -230, 150, 5 } }
	do
		Valley.cluster(ctx, ctx.nature, c[1], c[2], PALMS, c[3], 10, PAL, nil, true)
	end
	Kit.place(ctx.props, "BeachHut", Kit.at(-110, H, 122, -90), 1, PAL)
	Kit.place(ctx.props, "BeachHut", Kit.at(-128, H, 176, -70), 0.9, Palettes.merge(PAL, { Wall = rgb(150, 220, 240) }))
	Valley.keepOut(ctx, -110, 122, 10)
	Valley.keepOut(ctx, -128, 176, 10)
	for i, p in { { -70, 136 }, { -82, 146 }, { -66, 172 } } do
		Kit.place(
			ctx.props,
			"BeachUmbrella",
			Kit.at(p[1], H, p[2], i * 50),
			1,
			Palettes.merge(PAL, { Cloth = ({ rgb(255, 92, 92), rgb(60, 176, 240), rgb(255, 196, 40) })[i] })
		)
	end
	Valley.scatter(ctx, ctx.nature, -1, SHORE, 14, { Valley.INNER + 8, 140 }, 6, PAL, { shadow = false })
	Kit.place(ctx.terrain, "HillC", Kit.at(-190, H, 112, 30), Vector3.new(1.4, 0.8, 1.2), PAL)
	Kit.place(ctx.terrain, "HillA", Kit.at(-250, H, 170, 70), Vector3.new(1, 0.7, 1), PAL)
	Valley.shoulders(ctx, COVER, 18, PAL)

	-- far: dunes on the land side, clouds over the open sea
	Valley.farRow(
		ctx,
		-1,
		{ { "HillB", 320, 120, 1.2 }, { "HillB", 380, 180, 1.0 }, { "ForestFar", 300, 160, 0.9 } },
		Palettes.merge(PAL, { Leaf = rgb(60, 170, 80), LeafDark = rgb(40, 140, 70) })
	)
	for i, c in { { 180, 130, "CloudB" }, { 300, 170, "CloudA" }, { 380, 110, "CloudB" } } do
		Kit.place(
			ctx.far,
			c[3] :: string,
			Kit.at(c[1] :: number, 60 + i * 12, c[2] :: number, i * 40),
			1.4,
			PAL,
			{ shadow = false }
		)
	end

	-- ambience
	Valley.fx(ctx, "SeaMist", 1, 170, 220, 3, 4, nil, 1.5, 300)
	Fx.area(
		ctx.fx,
		"Sparkle",
		Vector3.new(200, 1, len - 6),
		Vector3.new(160, 1.2, ctx.zm),
		{ rgb(230, 250, 255) },
		3,
		260
	)
	Valley.fx(ctx, "SandGust", -1, 90, 90, H + 1.5, 2, nil, 1, 200)

	-- hand-over: meadow at the start, autumn at the end
	Valley.blend(ctx, { { "TreeBallB", 1, 0.9, 1.1 }, { "FlowersA", 2, 1, 1.3 } }, Palettes.zones[1], true, 3)
	Valley.blend(ctx, { { "MapleB", 1, 0.9, 1.1 }, { "LeafPile", 2, 1, 1.2 } }, Palettes.zones[3], false, 3)
end
