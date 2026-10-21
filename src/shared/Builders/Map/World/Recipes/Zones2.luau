--!strict
-- Partner A. Classic brick recipes for batch 2 zones: Desert Dunes (Sun Pyramid, rock arch, cacti, pottery,
-- ruined columns, obelisk), Snowy Peaks (Summit Lodge, snowman, ice rocks, sled, snow lumps), Candy Land
-- (Gingerbread Castle, lollipop trees, candy canes, gumdrops, cupcake, donut, ice-cream cone), Coral Reef
-- (Sunken Galleon, giant clam, brain / branch / fan coral, kelp, anemone, treasure chest) and Volcano (the
-- volcano, basalt columns, lava rocks, charred trees, steam vents, obsidian shards).
-- Asset space: origin = base centre, +Y up, front = -Z. Wedges rise toward their local +Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Zones2 = {}

local function rnd(rng: Random, a: number, b: number): number
	return rng:NextNumber(a, b)
end

local function disc(m: Model, role: string, d: number, t: number, x: number, y: number, z: number, yaw: number?)
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, rad(yaw or 0), 0)
	B.at(m, role, V(d * 0.64, d, t), cf)
	B.at(m, role, V(d, d * 0.64, t - 0.02), cf)
	if d >= 6 then
		B.at(m, role, V(d * 0.66, d * 0.66, t - 0.04), cf * CFrame.Angles(0, 0, rad(45)))
	end
end

local function roof(
	m: Model,
	role: string,
	len: number,
	depth: number,
	rise: number,
	y: number,
	z: number,
	ridge: string?
)
	B.wedge(m, role, V(len, rise, depth / 2), CFrame.new(0, y + rise / 2, z - depth / 4))
	B.wedge(m, role, V(len, rise, depth / 2), CFrame.new(0, y + rise / 2, z + depth / 4) * CFrame.Angles(0, math.pi, 0))
	if ridge then
		B.box(m, ridge, V(len + 0.4, 0.6, 1.0), 0, y + rise + 0.05, z)
	end
end

local function gable(m: Model, role: string, x: number, y: number, z: number, w: number, h: number, t: number)
	B.wedge(m, role, V(t, h, w / 2), CFrame.new(x, y + h / 2, z + w / 4) * CFrame.Angles(0, math.pi, 0))
	B.wedge(m, role, V(t, h, w / 2), CFrame.new(x, y + h / 2, z - w / 4))
end

---------------------------------------------------------------- Desert Dunes

-- The Sun Pyramid: a stepped sandstone pyramid with a central stair, a columned shrine on top and a glowing
-- golden sun disc; flanked by two sphinx-like guardian blocks.
local function sunPyramid(m: Model)
	local tiers, base, th = 6, 46, 6.5
	for i = 0, tiers - 1 do
		local w = base - i * 7.2
		B.on(m, if i % 2 == 0 then "Stone" else "StoneDark", V(w, th, w), 0, i * th - 0.5, 0)
		B.on(m, "Trim", V(w + 0.6, 0.5, w + 0.6), 0, (i + 1) * th - 0.9, 0)
	end
	-- the central stair up the front (a long wedge with gold edges)
	local h = tiers * th
	local run = base / 2 + 1
	B.wedge(
		m,
		"Sand",
		V(8, h - 0.5, run - 7),
		CFrame.new(0, (h - 0.5) / 2 - 0.5, -run / 2 - 3.5) * CFrame.Angles(0, 0, 0)
	)
	for _, sx in { -1, 1 } do
		B.wedge(m, "Gold", V(1, h - 0.4, run - 7), CFrame.new(sx * 4.5, (h - 0.4) / 2 - 0.5, -run / 2 - 3.5))
	end
	-- shrine: four columns, a lintel, the sun disc
	local top = h - 0.5
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.on(m, "Trim", V(1.6, 7, 1.6), sx * 4, top, sz * 4)
		end
	end
	B.on(m, "StoneDark", V(11, 1.4, 11), 0, top + 7, 0)
	B.on(m, "Stone", V(7, 1.2, 7), 0, top + 8.4, 0)
	disc(m, "Gold", 8, 0.8, 0, top + 14, -0.4)
	disc(m, "Glow", 5.4, 0.9, 0, top + 14, -0.45)
	for i = 0, 7 do
		local a = rad(i * 45)
		B.box(m, "Gold", V(0.8, 2.2, 0.6), math.cos(a) * 5.4, top + 14 + math.sin(a) * 5.4, -0.3, 0, 0, i * 45 - 90)
	end
	-- guardian statues by the stair foot
	for _, sx in { -1, 1 } do
		local x = sx * 9
		B.on(m, "StoneDark", V(4, 2, 7), x, -0.5, -run - 5)
		B.on(m, "Stone", V(3.2, 3, 5.4), x, 1.5, -run - 5)
		B.on(m, "Stone", V(2.6, 3, 2.6), x, 4.5, -run - 6.6)
		B.on(m, "Gold", V(3.0, 1, 1.2), x, 7.2, -run - 6.6)
	end
end

local function rockArch(m: Model, rng: Random)
	for _, sx in { -1, 1 } do
		local y = -0.5
		for k = 0, 3 do
			local w = 6 - k * 0.6
			B.on(
				m,
				if k % 2 == 0 then "Stone" else "StoneDark",
				V(w + rnd(rng, -0.5, 0.5), 4.2, w * 0.9),
				sx * (8 + rnd(rng, -0.4, 0.4)),
				y,
				0,
				rnd(rng, -6, 6)
			)
			y += 4.1
		end
	end
	B.on(m, "Stone", V(24, 3.2, 5.4), 0, 16, 0, rnd(rng, -3, 3))
	B.on(m, "StoneDark", V(19, 2.6, 4.6), 0.5, 19.1, 0.2)
	B.on(m, "Stone", V(10, 1.6, 4), -1, 21.6, 0)
end

local function saguaro(m: Model, rng: Random)
	B.on(m, "Leaf", V(2, 11, 2), 0, -0.4, 0)
	B.on(m, "LeafDark", V(2.1, 0.6, 2.1), 0, 4, 0)
	for _, s in { -1, 1 } do
		local y = rnd(rng, 3.5, 5.5)
		B.on(m, "Leaf", V(2.8, 1.4, 1.4), s * 1.8, y, 0)
		B.on(m, "Leaf", V(1.4, rnd(rng, 3, 4.5), 1.4), s * 2.5, y + 1.2, 0)
	end
	B.on(m, "Accent2", V(0.8, 0.6, 0.8), 0, 10.6, 0)
end

local function barrelCactus(m: Model)
	B.round(m, "Leaf", 2, 3, 0, -0.3, 0)
	B.round(m, "LeafDark", 0.6, 2.2, 0, 1.6, 0, 20)
	B.on(m, "Accent2", V(0.7, 0.5, 0.7), 0, 2.2, 0, 45)
end

local function pottery(m: Model, rng: Random)
	for i, p in { { 0, 0, 2.8, 4 }, { 2.6, 0.8, 2.0, 2.8 }, { -2.2, 1.2, 1.8, 2.4 } } do
		local x, z, d, h = p[1], p[2], p[3], p[4]
		B.round(m, if i % 2 == 0 then "Accent" else "Wood", h * 0.6, d, x, -0.2, z, rnd(rng, 0, 45))
		B.round(m, "WoodDark", h * 0.25, d * 0.62, x, h * 0.6 - 0.2, z)
		B.round(m, "Trim", 0.3, d * 0.8, x, h * 0.85 - 0.2, z)
	end
end

local function ruins(m: Model, rng: Random)
	for i, p in { { -4, 9 }, { 0, 4.5 }, { 4, 7 } } do
		B.on(m, "StoneDark", V(2.6, 0.8, 2.6), p[1], -0.4, 0)
		B.on(m, "Trim", V(1.8, p[2], 1.8), p[1], 0.4, 0, rnd(rng, -3, 3), rnd(rng, -3, 3), 0)
		if i ~= 2 then
			B.on(m, "StoneDark", V(2.4, 0.7, 2.4), p[1], 0.4 + p[2], 0)
		end
	end
	B.on(m, "Stone", V(10, 0.9, 2.6), 0, 9.6, 0, 0, 0, -6)
	B.log(m, "Trim", 3, 1.8, 2.6, 0.5, -3.4, 60)
	B.on(m, "Stone", V(4, 3, 1.6), -2, -0.4, 3.4)
end

local function obelisk(m: Model)
	B.on(m, "StoneDark", V(5, 1.6, 5), 0, -0.4, 0)
	B.on(m, "Stone", V(3.4, 14, 3.4), 0, 1.2, 0)
	B.on(m, "Stone", V(2.6, 5, 2.6), 0, 15.2, 0)
	B.on(m, "Gold", V(2, 2.2, 2), 0, 20.2, 0, 45)
	B.box(m, "Gold", V(0.4, 6, 0.3), 0, 7, -1.75)
end

---------------------------------------------------------------- Snowy Peaks

-- The Summit Lodge: a stone base, a big A-frame timber lodge with a deep snow-capped roof, a glass gable,
-- a balcony, twin chimneys, lanterns and a ski rack; a flag on top.
local function summitLodge(m: Model)
	local W, D = 22, 26
	B.on(m, "StoneDark", V(W + 4, 3, D + 4), 0, -0.5, 0)
	B.on(m, "Stone", V(W + 2, 0.6, D + 2), 0, 2.5, 0)
	B.on(m, "Wood", V(W, 8, D), 0, 3.1, 0)
	for _, sz in { -1, 1 } do
		for _, x in { -W / 2 + 1, -W / 6, W / 6, W / 2 - 1 } do
			B.on(m, "WoodDark", V(1, 8, 0.6), x, 3.1, sz * (D / 2 + 0.1))
		end
	end
	-- the A-frame roof (steep), snow on top, a glass gable at the front
	local y0, rise = 11.1, 14
	roof(m, "Roof", W + 3, D + 3, rise, y0, 0, "Snow")
	-- snow on the upper half of both slopes (a smaller roof lifted onto the big one)
	local f = 0.5
	B.wedge(
		m,
		"Snow",
		V(W + 3.6, rise * f, (D + 3) / 2 * f),
		CFrame.new(0, y0 + rise * (1 - f / 2) + 0.35, -(D + 3) / 4 * f)
	)
	B.wedge(
		m,
		"Snow",
		V(W + 3.6, rise * f, (D + 3) / 2 * f),
		CFrame.new(0, y0 + rise * (1 - f / 2) + 0.35, (D + 3) / 4 * f) * CFrame.Angles(0, math.pi, 0)
	)
	for _, sx in { -1, 1 } do
		gable(m, "Glass", sx * (W / 2 - 0.3), y0, 0, D, rise - 1, 0.4)
	end
	B.on(m, "Glass", V(8, 5, 0.4), 0, 4.5, -D / 2 - 0.2)
	B.on(m, "WoodDark", V(9, 0.6, 0.6), 0, 9.6, -D / 2 - 0.3)
	-- balcony on the front
	B.on(m, "Wood", V(W - 4, 0.6, 4), 0, 10.6, -D / 2 - 2)
	for x = -W / 2 + 3, W / 2 - 3, 4 do
		B.on(m, "WoodDark", V(0.4, 2, 0.4), x, 11.2, -D / 2 - 3.8)
	end
	B.box(m, "WoodDark", V(W - 4, 0.4, 0.4), 0, 13.2, -D / 2 - 3.8)
	B.on(m, "WoodDark", V(4, 4.6, 0.6), -6, 3.1, -D / 2 - 0.4)
	-- chimneys
	for _, x in { -5, 6 } do
		B.on(m, "Stone", V(2.6, 10, 2.6), x, y0 + 6, 4)
		B.on(m, "Snow", V(3.2, 0.8, 3.2), x, y0 + 16, 4)
	end
	for _, x in { -9, 3 } do
		B.on(m, "Glow", V(0.9, 1.2, 0.9), x, 6.4, -D / 2 - 0.5)
	end
	B.on(m, "Metal", V(0.4, 8, 0.4), 0, y0 + rise + 0.6, 0)
	B.box(m, "Cloth", V(3.4, 2, 0.2), 1.9, y0 + rise + 7.4, 0)
end

local function snowman(m: Model)
	B.blob(m, "Snow", 5, 4.6, 5, 0, 2.0, 0)
	B.blob(m, "Snow", 3.8, 3.4, 3.8, 0, 5.6, 0, 20)
	B.blob(m, "Snow", 2.8, 2.6, 2.8, 0, 8.3, 0, 40)
	B.on(m, "Dark", V(2.4, 0.3, 2.4), 0, 9.4, 0)
	B.on(m, "Dark", V(1.6, 1.6, 1.6), 0, 9.6, 0)
	B.box(m, "Accent", V(0.4, 0.4, 1.4), 0, 8.4, -1.8)
	B.box(m, "Cloth", V(3.0, 0.6, 3.0), 0, 7.0, 0, 15)
	for _, s in { -1, 1 } do
		B.box(m, "Trunk", V(3, 0.3, 0.3), s * 2.6, 6.2, 0, 0, 0, s * 25)
	end
end

local function iceRock(m: Model, rng: Random)
	for i = 0, 3 do
		local a = rad(i * 90 + rnd(rng, -25, 25))
		local h = rnd(rng, 3, 7)
		B.on(
			m,
			if i % 2 == 0 then "Ice" else "Crystal",
			V(rnd(rng, 1.6, 2.6), h, rnd(rng, 1.6, 2.6)),
			math.cos(a) * 1.3,
			-0.4,
			math.sin(a) * 1.3,
			rnd(rng, 0, 90),
			rnd(rng, -12, 12),
			rnd(rng, -12, 12)
		)
	end
	B.on(m, "Snow", V(4.6, 1.2, 4), 0, -0.4, 0, 20)
end

local function sled(m: Model)
	for _, s in { -1, 1 } do
		B.on(m, "Metal", V(0.3, 0.3, 5), s * 1.1, 0, 0)
		B.box(m, "Metal", V(0.3, 1, 0.3), s * 1.1, 0.9, -2.3, 0, -30, 0)
	end
	B.on(m, "Cloth", V(2.6, 0.4, 4.4), 0, 0.8, 0.2)
	B.on(m, "Wood", V(2.6, 1.4, 0.4), 0, 1.2, 2.2)
end

local function snowLumps(m: Model, rng: Random)
	B.on(m, "Snow", V(4.4, 1.6, 3.4), 0, -0.4, 0, rnd(rng, 0, 45))
	B.on(m, "Snow", V(2.6, 1.2, 2.2), rnd(rng, 1, 2), 0.8, rnd(rng, -1, 1), rnd(rng, 0, 45))
	B.on(m, "Snow", V(2, 1, 2), rnd(rng, -2.5, -1.5), -0.4, rnd(rng, 1, 2), rnd(rng, 0, 45))
end

---------------------------------------------------------------- Candy Land

-- The Gingerbread Castle: gingerbread walls with white icing trim and gumdrop studs, a candy-striped gate, four
-- round towers with frosted cone roofs and lollipop flags, a big central keep with a cupcake-swirl roof.
local function gingerbreadCastle(m: Model, rng: Random)
	local W, D, H = 34, 26, 12
	-- curtain walls (front split around the gate)
	B.on(m, "Wood", V(W, H, 2.4), 0, -0.5, D / 2)
	for _, sx in { -1, 1 } do
		B.on(m, "Wood", V(2.4, H, D), sx * W / 2, -0.5, 0)
		B.on(m, "Wood", V(W / 2 - 5, H, 2.4), sx * (W / 4 + 2.5), -0.5, -D / 2)
	end
	for _, p in { { 0, D / 2, W, 3 }, { -W / 2, 0, 3, D }, { W / 2, 0, 3, D } } do
		B.on(m, "Trim", V(p[3], 0.8, p[4]), p[1], H - 0.3, p[2])
	end
	-- crenellations as gumdrops
	local roles = { "Accent", "Accent2", "Accent3", "Gold" }
	for i = 0, 7 do
		B.on(m, roles[i % 4 + 1], V(1.6, 1.4, 1.6), -W / 2 + 2 + i * (W - 4) / 7, H + 0.5, D / 2, 45)
	end
	-- the gate: striped arch posts and a chocolate door
	for _, sx in { -1, 1 } do
		for k = 0, 4 do
			B.on(m, if k % 2 == 0 then "Cloth" else "Cloth2", V(2.4, 2.6, 2.6), sx * 4.6, -0.5 + k * 2.6, -D / 2)
		end
	end
	B.on(m, "Cloth", V(11.6, 2.4, 2.6), 0, 12.5, -D / 2)
	B.on(m, "WoodDark", V(7, 9, 1), 0, -0.5, -D / 2 + 0.6)
	-- corner towers
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * W / 2, sz * D / 2
			B.round(m, "Wood", H + 6, 7, x, -0.5, z)
			B.round(m, "Trim", 0.8, 7.6, x, H + 5.2, z)
			B.stack(m, if sz < 0 then "Accent2" else "Accent3", 8, 1.4, 7, 4, x, H + 6, z, 0, "Trim")
			B.on(m, "Metal", V(0.3, 3, 0.3), x, H + 13, z)
			disc(m, roles[(sx + sz + 4) % 4 + 1], 2.2, 0.4, x + 1.1, H + 15, z)
		end
	end
	-- the keep
	B.on(m, "Wood", V(16, H + 8, 12), 0, -0.5, 4)
	B.on(m, "Trim", V(16.6, 0.8, 12.6), 0, H + 7.2, 4)
	for _, x in { -4.5, 0, 4.5 } do
		B.on(m, "Glow", V(2, 3, 0.4), x, H + 1, -2.2)
		B.on(m, "Trim", V(2.6, 0.4, 0.6), x, H + 0.7, -2.3)
	end
	B.stack(m, "Accent2", 15, 3, 9, 5, 0, H + 8, 4, 0, "Trim")
	B.on(m, "Cap", V(2, 2, 2), 0, H + 17, 4, 45)
	-- gumdrop studs on the walls
	for i = 1, 8 do
		local sx = if i % 2 == 0 then 1 else -1
		B.on(m, roles[i % 4 + 1], V(1, 1, 0.6), sx * (W / 2 + 1.3), rnd(rng, 2, H - 2), rnd(rng, -D / 2 + 3, D / 2 - 3))
	end
end

local function lollipopTree(m: Model, rng: Random)
	local h = rnd(rng, 8, 11)
	B.on(m, "Cloth2", V(0.7, h, 0.7), 0, -0.4, 0)
	disc(m, "Accent", 6, 1, 0, h + 2.4, 0, rnd(rng, 0, 90))
	disc(m, "Accent2", 4, 1.06, 0, h + 2.4, 0, rnd(rng, 0, 90))
	disc(m, "Cloth2", 1.8, 1.1, 0, h + 2.4, 0)
end

local function candyCane(m: Model)
	for k = 0, 4 do
		B.on(m, if k % 2 == 0 then "Cloth" else "Cloth2", V(1.2, 1.8, 1.2), 0, -0.4 + k * 1.8, 0)
	end
	B.box(m, "Cloth", V(2.4, 1.2, 1.2), 0.6, 8.8, 0)
	B.box(m, "Cloth2", V(1.2, 1.4, 1.2), 2.4, 8.2, 0)
	B.box(m, "Cloth", V(1.2, 1.2, 1.2), 2.4, 7.0, 0)
end

local function gumdrop(m: Model, rng: Random)
	B.round(m, "Accent", 1.4, 4, 0, -0.3, 0, rnd(rng, 0, 45))
	B.round(m, "Accent", 1.0, 2.8, 0, 1.1, 0, rnd(rng, 0, 45))
	B.on(m, "Accent", V(1.2, 0.6, 1.2), 0, 2.1, 0, 45)
	B.box(m, "Trim", V(0.4, 0.3, 0.4), 0.8, 1.6, -0.9)
	B.box(m, "Trim", V(0.4, 0.3, 0.4), -0.9, 1.2, 0.6)
end

local function cupcake(m: Model)
	B.round(m, "Cloth", 3, 5, 0, -0.3, 0, 22.5)
	B.round(m, "Trim", 0.4, 5.4, 0, 2.6, 0, 22.5)
	B.stack(m, "Accent2", 5.6, 1.6, 3.4, 3, 0, 3.0, 0, 0)
	B.on(m, "Cap", V(1.4, 1.4, 1.4), 0, 6.4, 0, 45)
	for i = 0, 4 do
		local a = rad(i * 72)
		B.box(
			m,
			({ "Accent", "Accent3", "Gold" })[i % 3 + 1],
			V(0.6, 0.3, 0.3),
			math.cos(a) * 2.2,
			3.8,
			math.sin(a) * 2.2,
			i * 72
		)
	end
end

local function donut(m: Model, rng: Random)
	-- standing ring facing -Z: eight studded blocks round a hole, frosting on the front
	for i = 0, 7 do
		local a = i * 45
		local cf = CFrame.new(0, 4.4, 0) * CFrame.Angles(0, 0, rad(a)) * CFrame.new(3.2, 0, 0)
		B.at(m, "Wood", V(2.4, 2.8, 2.6), cf)
		B.at(m, "Accent2", V(2.2, 2.6, 0.4), cf * CFrame.new(0, 0, -1.4))
	end
	for i = 1, 6 do
		local a = rad(rnd(rng, 0, 360))
		B.box(
			m,
			({ "Accent", "Accent3", "Gold", "Cloth2" })[i % 4 + 1],
			V(0.6, 0.25, 0.25),
			math.cos(a) * 3.2,
			4.4 + math.sin(a) * 3.2,
			-1.7,
			0,
			0,
			rnd(rng, 0, 180)
		)
	end
	B.on(m, "WoodDark", V(3, 1, 2), 0, -0.4, 0)
end

local function iceCream(m: Model)
	B.stack(m, "Wood", 0.8, 3.6, 7, 4, 0, -0.4, 0, 0, "WoodDark")
	B.blob(m, "Accent2", 4, 3, 4, 0, 7.6, 0)
	B.blob(m, "Accent3", 3.2, 2.6, 3.2, 0, 9.8, 0, 30)
	B.on(m, "Cap", V(1, 1, 1), 0, 11, 0, 45)
end

---------------------------------------------------------------- Coral Reef

-- The Sunken Galleon: a tilted hull with a broken bow, a gold trim stripe, gun ports, a stern castle with glowing
-- windows, two masts (one snapped) with tattered sails and a crow's nest, a treasure pile spilling out.
local function sunkenShip(m: Model, rng: Random)
	local ship = Instance.new("Model")
	local L, Wd = 40, 12
	-- hull: keel and planked sides, narrowing at the bow
	for i = 0, 7 do
		local z = -L / 2 + (i + 0.5) * L / 8
		local t = math.abs(z) / (L / 2)
		local w = Wd * (1 - 0.45 * t ^ 2)
		B.on(ship, if i % 2 == 0 then "Wood" else "WoodDark", V(w, 7, L / 8 + 0.1), 0, 0, z)
		B.on(ship, "Gold", V(w + 0.2, 0.6, L / 8 + 0.12), 0, 5.4, z)
	end
	B.on(ship, "WoodDark", V(Wd * 0.5, 2, L), 0, -1.6, 0)
	for k = 0, 4 do
		for _, sx in { -1, 1 } do
			B.box(ship, "Dark", V(0.3, 1, 1.2), sx * (Wd / 2 - 0.2), 3.2, -12 + k * 6)
		end
	end
	-- stern castle
	B.on(ship, "Wood", V(Wd - 1, 5, 9), 0, 7, L / 2 - 5)
	B.on(ship, "Gold", V(Wd - 0.6, 0.6, 9.4), 0, 11.6, L / 2 - 5)
	for _, x in { -3, 0, 3 } do
		B.on(ship, "Glow", V(1.6, 1.8, 0.4), x, 8.4, L / 2 - 0.4)
	end
	-- masts and sails
	B.on(ship, "WoodDark", V(1.2, 26, 1.2), 0, 7, 2)
	B.on(ship, "WoodDark", V(1.2, 9, 1.2), 0, 7, -10, 0, 18, 0)
	B.box(ship, "WoodDark", V(14, 0.6, 0.6), 0, 26, 2)
	B.box(ship, "Cloth2", V(12, 9, 0.3), 0.5, 21, 2.3, 0, 0, 3)
	B.box(ship, "Cloth2", V(5, 3, 0.3), -3.5, 15, 2.3, 0, 0, -8)
	B.round(ship, "Wood", 1.4, 3.2, 0, 31.5, 2)
	B.box(ship, "Cloth", V(3, 2, 0.2), 1.6, 34.6, 2)
	B.on(ship, "Metal", V(0.3, 2.2, 0.3), 0, 32.9, 2)
	ship:PivotTo(CFrame.Angles(rad(-6), 0, rad(14)))
	for _, p in ship:GetChildren() do
		p.Parent = m
	end
	ship:Destroy()
	-- treasure spilling out of the side, and rocks the hull rests on
	B.on(m, "Gold", V(5, 1.4, 4), 8, -0.4, -4, rnd(rng, 0, 30))
	B.on(m, "Gold", V(3, 1.2, 2.6), 9.6, 1, -4.6, rnd(rng, 0, 30))
	B.on(m, "Accent", V(1, 1, 1), 7, 1, -3, 45)
	for _, p in { { -6, 8 }, { 5, 12 }, { -4, -12 } } do
		B.on(m, "Stone", V(5, 2.4, 5), p[1], -1.2, p[2], rnd(rng, 0, 45))
	end
end

local function giantClam(m: Model)
	B.on(m, "Stone", V(9, 1, 7), 0, -0.4, 0)
	-- lower shell: ribbed (alternating) blocks; upper shell tilted open at the back
	for i = 0, 4 do
		B.on(m, if i % 2 == 0 then "Accent2" else "Trim", V(1.6, 1.6, 6), -3.2 + i * 1.6, 0.6, 0)
	end
	local lid = CFrame.new(0, 2.2, 3) * CFrame.Angles(rad(-55), 0, 0)
	for i = 0, 4 do
		B.at(m, if i % 2 == 0 then "Accent2" else "Trim", V(1.6, 1.0, 6), lid * CFrame.new(-3.2 + i * 1.6, 0, -3))
	end
	B.on(m, "Cloth", V(6.4, 0.4, 4.6), 0, 2.2, -0.2)
	B.blob(m, "Glow", 2.2, 2.2, 2.2, 0, 3.4, -0.2)
end

local function brainCoral(m: Model, rng: Random)
	B.blob(m, "Accent", 5, 3.6, 4.6, 0, 1.2, 0, rnd(rng, 0, 45))
	for i = 0, 2 do
		B.box(m, "Accent2", V(4.2 - i, 0.4, 0.5), 0, 2.9 + i * 0.1, -1.2 + i * 1.2, rnd(rng, -10, 10))
	end
end

local function branchCoral(m: Model, rng: Random)
	B.on(m, "Accent", V(1.4, 3, 1.4), 0, -0.4, 0)
	for i = 0, 4 do
		local a = i * 72 + rnd(rng, -15, 15)
		local r = rad(a)
		local h = rnd(rng, 3, 6)
		B.on(
			m,
			if i % 2 == 0 then "Accent" else "Accent2",
			V(0.9, h, 0.9),
			math.cos(r) * 1.2,
			2.2,
			math.sin(r) * 1.2,
			0,
			math.sin(r) * 18,
			-math.cos(r) * 18
		)
		B.on(m, "Glow", V(0.8, 0.6, 0.8), math.cos(r) * (1.2 + h * 0.3), 2.2 + h * 0.95, math.sin(r) * (1.2 + h * 0.3))
	end
end

local function fanCoral(m: Model, rng: Random)
	B.on(m, "Accent2", V(0.6, 2, 0.6), 0, -0.4, 0)
	disc(m, "Accent2", 6, 0.3, 0, 4.4, 0, rnd(rng, 0, 90))
	disc(m, "Accent", 3.6, 0.36, 0, 4.4, 0)
end

local function kelp(m: Model, rng: Random)
	local h = rnd(rng, 12, 18)
	local seg = 4
	for k = 0, seg - 1 do
		local off = math.sin(k * 1.3 + rnd(rng, 0, 1)) * 0.8
		B.on(
			m,
			if k % 2 == 0 then "Leaf" else "LeafDark",
			V(1.6, h / seg + 0.2, 0.4),
			off,
			-0.4 + k * h / seg,
			0,
			0,
			0,
			off * 6
		)
	end
	B.on(m, "LeafLight", V(1.2, 1.2, 0.4), 0.8, h - 0.6, 0, 0, 0, 20)
end

local function anemone(m: Model, rng: Random)
	B.round(m, "Accent", 1.6, 3.4, 0, -0.3, 0)
	for i = 0, 5 do
		local r = rad(i * 60 + rnd(rng, -10, 10))
		B.on(
			m,
			"Accent2",
			V(0.5, rnd(rng, 1.4, 2.4), 0.5),
			math.cos(r) * 1.2,
			1.2,
			math.sin(r) * 1.2,
			0,
			math.sin(r) * 20,
			-math.cos(r) * 20
		)
	end
	B.on(m, "Glow", V(1, 0.6, 1), 0, 1.3, 0, 45)
end

local function treasureChest(m: Model)
	B.on(m, "Wood", V(4, 2.4, 2.8), 0, -0.2, 0)
	B.on(m, "Gold", V(4.2, 0.4, 3), 0, 0.6, 0)
	B.on(m, "Gold", V(0.6, 2.5, 3), 0, -0.2, 0)
	local lid = CFrame.new(0, 2.2, 1.4) * CFrame.Angles(rad(-35), 0, 0)
	B.at(m, "Wood", V(4, 0.8, 2.8), lid * CFrame.new(0, 0.4, -1.4))
	B.on(m, "Gold", V(3.4, 0.6, 2.2), 0, 2.2, 0)
	B.on(m, "Glow", V(1, 0.6, 1), 0, 2.8, 0, 45)
end

---------------------------------------------------------------- Volcano

-- The volcano: a stepped cone of dark rock bands, a crater rim with a glowing lava lake, lava rivers running down
-- two sides in steps, and glowing cracks.
local function volcanoPeak(m: Model, rng: Random)
	local steps, base, h = 8, 74, 64
	local sh = h / steps
	for i = 0, steps - 1 do
		local t = i / steps
		local w = base * (1 - 0.7 * t)
		B.on(
			m,
			if i % 2 == 0 then "Stone" else "StoneDark",
			V(w, sh + 0.3, w * rnd(rng, 0.88, 1.0)),
			rnd(rng, -1, 1),
			-1 + i * sh,
			rnd(rng, -1, 1),
			i * 11
		)
	end
	local top = -1 + steps * sh
	local cw = base * 0.3
	-- crater rim ring and the lava lake
	for i = 0, 7 do
		local a = rad(i * 45)
		B.on(
			m,
			"StoneDark",
			V(cw * 0.45, 3.4, 5),
			math.cos(a) * cw * 0.42,
			top - 0.2,
			math.sin(a) * cw * 0.42,
			90 - i * 45
		)
	end
	B.round(m, "Lava", 0.6, cw * 0.72, 0, top + 1.8, 0)
	-- lava rivers: stepped neon strips down the front-left and front-right faces
	for _, side in { -1, 1 } do
		for i = 0, steps - 2 do
			local t = (i + 0.5) / steps
			local w = base * (1 - 0.7 * t)
			local y = top - (i + 1) * sh
			local a = rad(side * 35 - 90)
			local r = w / 2 + 0.15
			B.on(m, "Lava", V(2.4 + i * 0.25, sh + 0.4, 0.6), math.cos(a) * r * 0.6, y, math.sin(a) * r, side * -35)
		end
	end
	for i = 1, 6 do
		local a = rad(rnd(rng, 0, 360))
		local y = rnd(rng, 4, top - 8)
		local w = base * (1 - 0.7 * ((y + 1) / h)) / 2
		B.box(
			m,
			"Lava",
			V(rnd(rng, 3, 6), 0.4, 0.5),
			math.cos(a) * w,
			y,
			math.sin(a) * w,
			90 - math.deg(a),
			0,
			rnd(rng, -30, 30)
		)
	end
end

local function basaltColumns(m: Model, rng: Random)
	for i = 0, 6 do
		local a = rad(i * 51 + rnd(rng, -10, 10))
		local r = if i == 0 then 0 else rnd(rng, 1.6, 3)
		local h = rnd(rng, 3, 10)
		B.on(
			m,
			if i % 2 == 0 then "Stone" else "StoneDark",
			V(1.8, h, 1.8),
			math.cos(a) * r,
			-0.5,
			math.sin(a) * r,
			rnd(rng, 0, 60)
		)
	end
end

local function lavaRock(m: Model, rng: Random)
	B.on(m, "StoneDark", V(6, 3, 5), 0, -0.4, 0, rnd(rng, 0, 45))
	B.on(m, "Stone", V(4, 2, 3.4), rnd(rng, -0.6, 0.6), 2.4, rnd(rng, -0.6, 0.6), rnd(rng, 0, 45))
	B.box(m, "Lava", V(4.6, 0.3, 0.4), 0, 1.4, -2.55, 0, 0, rnd(rng, -20, 20))
	B.box(m, "Lava", V(0.4, 0.3, 3.8), 3.05, 1.0, 0, 0, 0, 0)
end

local function charredTree(m: Model, rng: Random)
	B.on(m, "Trunk", V(1.4, 9, 1.4), 0, -0.4, 0, rnd(rng, 0, 90), rnd(rng, -5, 5), rnd(rng, -5, 5))
	for i = 0, 2 do
		local a = i * 120 + rnd(rng, -20, 20)
		local r = rad(a)
		B.on(
			m,
			"Trunk",
			V(0.6, rnd(rng, 3, 5), 0.6),
			math.cos(r) * 0.6,
			rnd(rng, 4, 7),
			math.sin(r) * 0.6,
			90 - a,
			0,
			-40
		)
	end
	B.on(m, "Lava", V(0.5, 1, 0.3), 0.2, 1.4, -0.72)
end

local function steamVent(m: Model)
	for i = 0, 5 do
		local a = rad(i * 60)
		B.on(m, "StoneDark", V(2.2, 1.6, 1.6), math.cos(a) * 2, -0.4, math.sin(a) * 2, 90 - i * 60)
	end
	B.round(m, "Lava", 0.3, 2.4, 0, 0.2, 0)
end

local function obsidian(m: Model, rng: Random)
	for i = 0, 3 do
		local a = rad(i * 90 + rnd(rng, -20, 20))
		B.on(
			m,
			"Dark",
			V(rnd(rng, 1.2, 2), rnd(rng, 4, 9), rnd(rng, 1.2, 2)),
			math.cos(a) * 1.2,
			-0.4,
			math.sin(a) * 1.2,
			rnd(rng, 0, 90),
			rnd(rng, -15, 15),
			rnd(rng, -15, 15)
		)
	end
end

-- A round pond (or frozen pond with an Ice palette): a water disc in a ring of rim stones.
local function pond(m: Model, rng: Random)
	local d = 18
	B.round(m, "Water", 0.5, d, 0, -0.3, 0)
	for i = 0, 9 do
		local a = i * 36 + rnd(rng, -8, 8)
		local r = rad(a)
		B.on(
			m,
			if i % 3 == 0 then "StoneDark" else "Stone",
			V(rnd(rng, 2.6, 3.8), rnd(rng, 0.8, 1.6), rnd(rng, 1.8, 2.6)),
			math.cos(r) * (d / 2 + 0.6),
			-0.4,
			math.sin(r) * (d / 2 + 0.6),
			90 - a
		)
	end
end

Zones2.recipes = {
	Pond = pond,
	SunPyramid = sunPyramid,
	RockArch = rockArch,
	Saguaro = saguaro,
	BarrelCactus = barrelCactus,
	Pottery = pottery,
	Ruins = ruins,
	Obelisk = obelisk,
	SummitLodge = summitLodge,
	Snowman = snowman,
	IceRock = iceRock,
	Sled = sled,
	SnowLumps = snowLumps,
	GingerbreadCastle = gingerbreadCastle,
	LollipopTree = lollipopTree,
	CandyCane = candyCane,
	Gumdrop = gumdrop,
	Cupcake = cupcake,
	Donut = donut,
	IceCream = iceCream,
	SunkenShip = sunkenShip,
	GiantClam = giantClam,
	BrainCoral = brainCoral,
	BranchCoral = branchCoral,
	FanCoral = fanCoral,
	Kelp = kelp,
	Anemone = anemone,
	TreasureChest = treasureChest,
	VolcanoPeak = volcanoPeak,
	BasaltColumns = basaltColumns,
	LavaRock = lavaRock,
	CharredTree = charredTree,
	SteamVent = steamVent,
	Obsidian = obsidian,
}

return Zones2
