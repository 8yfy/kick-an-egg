--!strict
-- Partner A. Zone 14, Sky Islands (z 1300..1400): the track runs on as a sky road between low cloud lips; beyond
-- them a sea of clouds far below, floating grass islands at different heights (bobbing gently) linked by rope
-- bridges, the Sky Temple on its great floating island with a waterfall pouring off its edge on the right, floating
-- rocks, towering cloud pillars. The real track stays continuous: islands only float beside it. Ambience: drifting
-- clouds and sparkles.
local Kit = require(script.Parent.Parent.Kit)
local Valley = require(script.Parent.Parent.Valley)
local Palettes = require(script.Parent.Parent.Palettes)
local Parts = require(script.Parent.Parent.Parts)

local rgb = Color3.fromRGB

local ISLAND_DRESS =
	{ { "TreeBallB", 2, 0.8, 1.1 }, { "TreeRoundD", 1, 0.8, 1 }, { "FlowersB", 2, 1, 1.2 }, { "BushA", 1, 0.8, 1 } }

return function(zone: any, parent: Instance)
	local PAL = Palettes.zones[14]
	local CLOUD = Palettes.merge(PAL, {
		Ground = rgb(255, 255, 255),
		Stone = rgb(236, 242, 255),
		StoneDark = rgb(214, 224, 246),
		Trim = rgb(226, 236, 252),
		Snow = rgb(255, 255, 255),
	})
	local ctx = Valley.new(zone, parent, PAL)
	local FLOOR = -14
	for _, side in { -1, 1 } do
		-- low cloud lips along the track, then the cloud sea far below
		Valley.banks(ctx, side, { "BankB" }, 3, { depth = 10, palette = CLOUD })
		Valley.plateau(ctx, side, FLOOR, rgb(250, 252, 255), rgb(226, 236, 252), Valley.INNER + 12)
	end

	-- the Sky Temple island (right), high up
	local tx, ty, tz = 120, 34, 1352
	local temple = Kit.place(ctx.props, "SkyTemple", Kit.at(tx, ty, tz, 90), 1.2, PAL)
	Valley.bob(temple, 1.2, 0.08)
	Parts.light(
		Parts.anchor(ctx.props, "TempleGlow", Vector3.one, Vector3.new(tx, ty + 12, tz)),
		rgb(255, 236, 170),
		44,
		1.2
	)

	-- floating islands at varied heights, each dressed, a few linked by rope bridges
	local isles = {
		{ -76, 16, 1322, "IslandB", 1.0 },
		{ -126, 28, 1372, "IslandB", 1.2 },
		{ -190, 20, 1330, "IslandA", 1.2 },
		{ -220, 40, 1388, "IslandA", 1.0 },
		{ 70, 12, 1388, "IslandA", 1.1 },
		{ 196, 22, 1312, "IslandB", 1.0 },
		{ 220, 44, 1384, "IslandA", 1.1 },
	}
	for i, it in isles do
		local x, y, z = it[1] :: number, it[2] :: number, it[3] :: number
		local isle =
			Kit.place(ctx.terrain, it[4] :: string, Kit.at(x, y, z, ctx.rng:NextNumber(0, 360)), it[5] :: number, PAL)
		local dress = Instance.new("Model")
		dress.Name = "IslandDress"
		dress.Parent = ctx.nature
		local n = if it[4] == "IslandB" then 3 else 2
		for _ = 1, n do
			local a = ctx.rng:NextNumber(0, math.pi * 2)
			local r = ctx.rng:NextNumber(0, 6) * (it[5] :: number)
			Valley.put(
				ctx,
				dress,
				ISLAND_DRESS[ctx.rng:NextInteger(1, #ISLAND_DRESS)][1] :: string,
				x + math.cos(a) * r,
				z + math.sin(a) * r,
				ctx.rng:NextNumber(0.8, 1.1),
				nil,
				PAL,
				y
			)
		end
		-- the island and its dressing float together
		if isle then
			for _, p in dress:GetChildren() do
				p.Parent = isle
			end
			Valley.bob(isle, 1 + (i % 3) * 0.4, 0.1 + i * 0.012)
		end
		dress:Destroy()
	end
	for _, b in { { 1, 2 }, { 3, 4 } } do
		local a, c = isles[b[1]], isles[b[2]]
		local pa = Vector3.new(a[1] :: number, a[2] :: number, a[3] :: number)
		local pc = Vector3.new(c[1] :: number, c[2] :: number, c[3] :: number)
		local mid = (pa + pc) / 2
		local len = (pc - pa).Magnitude
		Kit.place(ctx.props, "RopeBridge", CFrame.lookAt(mid, pc), Vector3.new(1, 1, len / 24), PAL)
	end

	-- floating rocks and cloud pillars rising from the cloud sea
	for _ = 1, 10 do
		local side = if ctx.rng:NextNumber() < 0.5 then -1 else 1
		local rock = Valley.put(
			ctx,
			ctx.props,
			"FloatingRock",
			side * ctx.rng:NextNumber(60, 260),
			ctx.rng:NextNumber(ctx.z0 + 6, ctx.z1 - 6),
			ctx.rng:NextNumber(0.8, 1.6),
			nil,
			PAL,
			ctx.rng:NextNumber(4, 48)
		)
		Valley.bob(rock, ctx.rng:NextNumber(0.6, 1.4), ctx.rng:NextNumber(0.12, 0.22))
	end
	for _, p in { { -60, 1394 }, { 66, 1316 }, { -260, 1350 }, { 280, 1340 } } do
		Valley.put(ctx, ctx.terrain, "CloudPillar", p[1], p[2], ctx.rng:NextNumber(1.4, 2.2), nil, CLOUD, FLOOR)
	end

	-- far: towering clouds
	for _, side in { -1, 1 } do
		Valley.farRow(
			ctx,
			side,
			{ { "CloudB", 300, 1330, 2.2 }, { "CloudA", 360, 1380, 2.6 }, { "CloudB", 260, 1390, 1.6 } },
			CLOUD
		)
	end

	-- ambience
	Valley.fx(ctx, "CloudDrift", -1, 150, 200, 4, 10, nil, 1.2, 400)
	Valley.fx(ctx, "CloudDrift", 1, 150, 200, 4, 10, nil, 1.2, 400)
	Valley.fx(ctx, "Sparkle", 0, 0, 80, 10, 10, { rgb(255, 250, 220) }, 1.5)

	-- hand-over from the graveyard at the start, to the swamp at the end
	Valley.blend(ctx, { { "GravestoneC", 1, 0.8, 1 } }, Palettes.zones[13], true, 1)
end
