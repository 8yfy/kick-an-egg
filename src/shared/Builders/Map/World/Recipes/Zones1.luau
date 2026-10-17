--!strict
-- Partner A. Classic brick recipes for batch 1 zones: Meadow (windmill + sails, hay, beehive, sunflower, scarecrow,
-- farm cart), Sandy Beach (palms, lighthouse, dock, umbrella, shell, starfish, driftwood, beach hut, tropical
-- plant), Autumn Forest (maples, leaf pile, pumpkin, log cabin, the Hollow Oak with its treehouse), Mushroom Grove
-- (giant mushrooms, mushroom house, root arch, glow shrooms, the Mushroom Tower) and far scenery (forest and pine
-- bands, clouds). Asset space: origin = base centre, +Y up, front = -Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Zones1 = {}

local function rnd(rng: Random, a: number, b: number): number
	return rng:NextNumber(a, b)
end

-- Voxel disc of diameter d, thickness t, facing -Z (rotated by yaw), centred at (x, y, z).
local function disc(m: Model, role: string, d: number, t: number, x: number, y: number, z: number, yaw: number?)
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, rad(yaw or 0), 0)
	B.at(m, role, V(d * 0.64, d, t), cf)
	B.at(m, role, V(d, d * 0.64, t - 0.02), cf)
	if d >= 6 then
		B.at(m, role, V(d * 0.66, d * 0.66, t - 0.04), cf * CFrame.Angles(0, 0, rad(45)))
	end
end

local function gable(m: Model, role: string, x: number, y: number, z: number, w: number, h: number, t: number)
	B.wedge(m, role, V(t, h, w / 2), CFrame.new(x, y + h / 2, z + w / 4) * CFrame.Angles(0, math.pi, 0))
	B.wedge(m, role, V(t, h, w / 2), CFrame.new(x, y + h / 2, z - w / 4))
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

local function trunk(m: Model, rng: Random, th: number, tw: number, roots: number)
	B.on(m, "Trunk", V(tw, th + 0.5, tw), 0, -0.5, 0, rnd(rng, 0, 90))
	for i = 0, roots - 1 do
		local a = i * 360 / roots + rnd(rng, -20, 20)
		local r = rad(a)
		B.on(
			m,
			"Trunk",
			V(tw * 0.55, tw * 0.75, tw * 1.2),
			math.cos(r) * tw * 0.62,
			-0.4,
			math.sin(r) * tw * 0.62,
			90 - a
		)
	end
end

---------------------------------------------------------------- Meadow

local function windmill(m: Model, rng: Random)
	local h = 30
	B.round(m, "Stone", 4.5, 14, 0, -0.5, 0, 22.5)
	B.round(m, "StoneDark", 0.6, 14.6, 0, 3.9, 0, 22.5)
	B.stack(m, "Wall", 12, 8.4, h * 0.62, 5, 0, 4.4, 0, 22.5)
	for k = 0, 1 do
		local t = 0.3 + 0.36 * k
		B.round(m, "Wood", 0.6, 12.4 - 3.8 * t, 0, 4.4 + h * 0.62 * t, 0, 22.5)
	end
	local top = 4.4 + h * 0.62
	B.round(m, "WoodDark", 0.8, 11.2, 0, top - 0.2, 0, 22.5)
	B.round(m, "Wood", 0.3, 11.6, 0, top + 1.8, 0, 22.5)
	B.stack(m, "Roof", 10, 1.6, 7.0, 4, 0, top + 0.6, 0, 22.5)
	B.on(m, "Gold", V(0.6, 1.4, 0.6), 0, top + 7.6, 0, 45)
	B.on(m, "WoodDark", V(3, 5, 1), 0, 3.9, -6.3)
	B.on(m, "Trim", V(3.8, 0.6, 1.1), 0, 8.9, -6.3)
	for i, y in { h * 0.3, h * 0.48 } do
		local zr = -5.6 + (y - 4.4) / (h * 0.62) * 1.6
		B.on(m, "Glass", V(1.8, 2.2, 0.6), 0, y, zr - 0.2 * i)
		B.on(m, "Trim", V(2.4, 0.4, 0.7), 0, y - 0.3, zr - 0.2 * i)
	end
	B.box(m, "WoodDark", V(1.6, 1.6, 3.0), 0, h * 0.86, -4.6)
end

local function windmillSails(m: Model)
	local r = 14
	B.box(m, "Gold", V(1.6, 1.6, 1.4), 0, 0, 0.3)
	for i = 0, 3 do
		local a = i * 90 + 45
		local cf = CFrame.Angles(0, 0, rad(a))
		B.at(m, "WoodDark", V(r, 0.6, 0.5), cf * CFrame.new(r / 2, 0, 0))
		B.at(m, "Cloth2", V(r * 0.72, 3.0, 0.2), cf * CFrame.new(r * 0.58, 1.6, 0.15))
		for k = 0, 1 do
			B.at(m, "Wood", V(0.3, 3.2, 0.3), cf * CFrame.new(r * (0.38 + 0.36 * k), 1.6, -0.05))
		end
	end
end

local function sunflower(m: Model)
	local h = 7
	B.on(m, "Leaf", V(0.4, h + 0.3, 0.4), 0, -0.3, 0)
	B.box(m, "LeafDark", V(1.8, 0.3, 0.8), 0.9, h * 0.4, 0, 0, 0, 20)
	B.box(m, "LeafDark", V(1.8, 0.3, 0.8), -0.9, h * 0.6, 0, 0, 0, -20)
	disc(m, "Gold", 3.6, 0.35, 0, h + 0.6, -0.3)
	disc(m, "Trunk", 1.8, 0.4, 0, h + 0.6, -0.5)
end

local function scarecrow(m: Model)
	B.on(m, "WoodDark", V(0.5, 7.4, 0.5), 0, -0.4, 0)
	B.box(m, "WoodDark", V(5.2, 0.4, 0.4), 0, 5.0, 0)
	B.on(m, "Cloth", V(2.0, 2.6, 1.2), 0, 3.0, 0)
	for _, sx in { -1, 1 } do
		B.box(m, "Cloth", V(1.4, 0.8, 0.8), sx * 1.6, 5.0, 0)
		B.box(m, "Sand", V(0.6, 0.6, 0.6), sx * 2.5, 5.0, 0, 30)
	end
	B.on(m, "Sand", V(1.5, 1.5, 1.5), 0, 5.6, 0)
	B.on(m, "Wood", V(2.6, 0.25, 2.6), 0, 7.0, 0)
	B.on(m, "Wood", V(1.4, 1.0, 1.4), 0, 7.2, 0)
	B.box(m, "Dark", V(0.25, 0.25, 0.1), -0.35, 6.5, -0.78)
	B.box(m, "Dark", V(0.25, 0.25, 0.1), 0.35, 6.5, -0.78)
end

local function farmCart(m: Model)
	B.on(m, "Wood", V(4, 0.4, 6), 0, 1.4, 0)
	for _, sx in { -1, 1 } do
		B.on(m, "Wood", V(0.3, 1.4, 6), sx * 1.9, 1.8, 0)
		disc(m, "WoodDark", 2.6, 0.35, sx * 2.3, 1.3, -1.4, 90)
	end
	B.on(m, "Wood", V(4, 1.4, 0.3), 0, 1.8, 2.9)
	B.on(m, "Wood", V(4, 1.4, 0.3), 0, 1.8, -2.9)
	for _, sx in { -0.6, 0.6 } do
		B.box(m, "WoodDark", V(0.3, 0.3, 3.4), sx, 1.6, -4.6, 0, -14, 0)
	end
	B.blob(m, "Accent", 2.6, 1.6, 2.2, 0, 2.6, 0.8)
	B.blob(m, "Accent2", 2.0, 1.4, 1.8, 0.4, 2.5, -1.4)
end

---------------------------------------------------------------- Sandy Beach

local function palm(h: number, lean: number, fronds: number)
	return function(m: Model, rng: Random)
		local seg = 6
		local pos = V(0, -0.4, 0)
		local ang = 0
		for i = 0, seg - 1 do
			local t = i / seg
			local w = 1.7 * (1 - 0.3 * t)
			ang = lean * (t ^ 1.5) * 60
			local sl = h / seg
			B.on(m, if i % 2 == 0 then "Trunk" else "Wood", V(w, sl + 0.4, w), pos.X, pos.Y, pos.Z, 0, 0, -ang)
			pos += V(math.sin(rad(ang)), math.cos(rad(ang)), 0) * sl
		end
		local top = pos
		for i = 0, 1 do
			local a = rad(i * 180 + 30)
			B.box(m, "WoodDark", V(0.9, 0.9, 0.9), top.X + math.cos(a) * 0.7, top.Y - 0.6, top.Z + math.sin(a) * 0.7)
		end
		for i = 0, fronds - 1 do
			local fa = i * 360 / fronds + rnd(rng, -14, 14)
			local cf = CFrame.new(top) * CFrame.Angles(0, rad(-fa), 0)
			local L = rnd(rng, 7, 8.5)
			-- inner half rises a little, the outer half droops
			B.at(
				m,
				if i % 2 == 0 then "Leaf" else "LeafDark",
				V(L * 0.55, 0.3, 1.9),
				cf * CFrame.Angles(0, 0, rad(12)) * CFrame.new(L * 0.27, 0, 0)
			)
			B.at(
				m,
				if i % 2 == 0 then "LeafDark" else "Leaf",
				V(L * 0.55, 0.3, 1.4),
				cf * CFrame.new(L * 0.5, 0.6, 0) * CFrame.Angles(0, 0, rad(-38)) * CFrame.new(L * 0.25, 0, 0)
			)
		end
		B.on(m, "LeafLight", V(1.2, 1.6, 1.2), top.X, top.Y - 0.2, top.Z, 45)
	end
end

local function lighthouse(m: Model, rng: Random)
	local h = 46
	for k = 0, 3 do
		local a = rad(k * 95 + 20)
		B.on(
			m,
			if k % 2 == 0 then "Stone" else "StoneDark",
			V(rnd(rng, 6, 9), rnd(rng, 3, 5), rnd(rng, 5, 7)),
			math.cos(a) * 7,
			-1,
			math.sin(a) * 7,
			k * 40
		)
	end
	B.round(m, "Stone", 4.2, 17, 0, -0.8, 0, 22.5)
	local th = h * 0.7
	local bands = 6
	for k = 0, bands - 1 do
		local t = k / bands
		B.round(
			m,
			if k % 2 == 0 then "Cloth" else "Cloth2",
			th / bands + 0.02,
			12.4 - 4.4 * t,
			0,
			3.4 + th * t,
			0,
			22.5
		)
	end
	local top = 3.4 + th
	B.round(m, "Trim", 0.9, 11.2, 0, top, 0, 22.5)
	for i = 0, 7 do
		local a = rad(i * 45)
		B.on(m, "Metal", V(0.3, 2, 0.3), math.cos(a) * 5.2, top + 0.9, math.sin(a) * 5.2)
	end
	B.round(m, "Metal", 0.3, 10.8, 0, top + 2.8, 0, 22.5)
	B.round(m, "Glass", 4.6, 6, 0, top + 0.9, 0)
	B.round(m, "Glow", 3, 3.2, 0, top + 1.6, 0)
	B.stack(m, "Cloth", 7.4, 1.4, 3.6, 3, 0, top + 5.5, 0, 22.5)
	B.on(m, "Gold", V(0.6, 1.6, 0.6), 0, top + 9.1, 0, 45)
	B.on(m, "WoodDark", V(2.6, 4.2, 1.2), 0, 3.3, -6.3)
	for _, y in { th * 0.35, th * 0.65 } do
		local rr = 6.2 - 2.2 * (y / th)
		B.on(m, "Glass", V(1.4, 2, 0.6), 0, 3.4 + y, -rr + 0.1)
	end
end

local function dock(m: Model)
	local length, width = 24, 6
	for i = 0, 7 do
		B.on(m, if i % 2 == 0 then "Wood" else "WoodDark", V(width, 0.4, 2.9), 0, 1.0, -i * 3 - 1.5, (i % 3 - 1) * 1.2)
	end
	for k = 0, 4 do
		for _, sx in { -1, 1 } do
			B.on(m, "WoodDark", V(0.9, 5.4, 0.9), sx * width * 0.46, -4.0, -k * 6)
		end
	end
	for _, sx in { -1, 1 } do
		B.box(m, "WoodDark", V(0.4, 0.4, length), sx * width * 0.5, 1.6, -length / 2)
		B.on(m, "Metal", V(0.8, 0.9, 0.8), sx * width * 0.35, 1.4, -length + 1.2)
	end
end

local function beachUmbrella(m: Model)
	B.on(m, "Trim", V(0.3, 7.2, 0.3), 0, -0.5, 0, 0, 7, 0)
	B.round(m, "Cloth", 0.8, 7.6, 0, 6.0, 0.8, 22.5)
	B.round(m, "Cloth2", 0.6, 4.8, 0, 6.8, 0.8)
	B.on(m, "Cloth", V(1.2, 0.5, 1.2), 0, 7.4, 0.8)
	B.on(m, "Cloth2", V(2.4, 0.3, 4.6), 2.4, -0.2, -1.2, 18)
end

local function shell(m: Model)
	for i = 0, 4 do
		local a = (i - 2) * 22
		B.box(
			m,
			if i % 2 == 0 then "Accent2" else "Trim",
			V(0.5, 0.45, 1.9),
			math.sin(rad(a)) * 0.9,
			0.3,
			-math.cos(rad(a)) * 0.3,
			a
		)
	end
	B.on(m, "Trim", V(0.9, 0.6, 0.6), 0, -0.1, 0.7)
end

local function starfish(m: Model)
	for i = 0, 4 do
		local a = i * 72
		B.on(m, "Accent", V(0.7, 0.45, 1.9), math.cos(rad(a)) * 0.9, -0.05, math.sin(rad(a)) * 0.9, 90 - a)
	end
	B.on(m, "Accent", V(1.2, 0.55, 1.2), 0, -0.05, 0, 36)
end

local function beachHut(m: Model)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.on(m, "WoodDark", V(0.8, 4.4, 0.8), sx * 4.2, -0.4, sz * 3.6)
		end
	end
	B.on(m, "Wood", V(10, 0.6, 8.6), 0, 3.8, 0)
	B.on(m, "Wall", V(8.6, 5.4, 6.6), 0, 4.4, 0.6)
	B.on(m, "WoodDark", V(2.6, 4, 0.6), 0, 4.4, -2.8)
	for _, sx in { -1, 1 } do
		B.on(m, "Glass", V(0.3, 1.8, 2.2), sx * 4.35, 6.2, 0.6)
	end
	roof(m, "Sand", 11.4, 9.4, 3.4, 9.8, 0.6, "Dirt")
	for _, sx in { -1, 1 } do
		gable(m, "Sand", sx * 4.3, 9.8, 0.6, 6.6, 3.2, 0.4)
	end
	for i = 0, 3 do
		B.box(m, "Wood", V(1.8, 0.3, 0.25), 2.2, 0.6 + i * 0.9, -5.0)
	end
	for _, sx in { 1.3, 3.1 } do
		B.on(m, "WoodDark", V(0.25, 4.2, 0.25), sx, -0.4, -5.0)
	end
end

local function tropicalPlant(m: Model, rng: Random)
	B.on(m, "LeafDark", V(0.8, 1.2, 0.8), 0, -0.3, 0)
	for i = 0, 4 do
		local a = i * 72 + rnd(rng, -12, 12)
		local cf = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, rad(-a), 0) * CFrame.Angles(0, 0, rad(rnd(rng, 30, 45)))
		B.at(m, if i % 2 == 0 then "Leaf" else "LeafLight", V(3.6, 0.25, 1.4), cf * CFrame.new(1.8, 0, 0))
	end
end

---------------------------------------------------------------- Autumn Forest

local function maple(height: number, width: number, tw: number)
	return function(m: Model, rng: Random)
		trunk(m, rng, height * 0.42, tw, 2)
		local base = height * 0.38
		for k, l in { { 1.0, "LeafDark" }, { 0.8, "Leaf" }, { 0.55, "LeafLight" } } do
			B.round(
				m,
				l[2] :: string,
				height * 0.18,
				width * (l[1] :: number),
				rnd(rng, -0.4, 0.4),
				base + (k - 1) * height * 0.17,
				rnd(rng, -0.4, 0.4),
				rnd(rng, 0, 45)
			)
		end
		B.on(m, "LeafLight", V(width * 0.2, height * 0.1, width * 0.2), 0, base + 3 * height * 0.17, 0, 30)
	end
end

local function leafPile(m: Model, rng: Random)
	B.on(m, "Leaf", V(5.6, 1.3, 4.6), 0, -0.4, 0, rnd(rng, 0, 45))
	B.on(m, "LeafDark", V(3.4, 0.9, 3.0), 0.3, 0.9, -0.2, rnd(rng, 0, 45))
	B.on(m, "LeafLight", V(1.2, 0.3, 1.0), -1.4, 0.9, 0.8, 30)
end

local function pumpkin(m: Model)
	B.round(m, "Accent", 2.2, 3.4, 0, -0.2, 0)
	B.round(m, "Accent", 0.6, 2.2, 0, 2.0, 0, 20)
	B.on(m, "Trunk", V(0.4, 0.9, 0.4), 0, 2.4, 0, 0, 10, 0)
	B.box(m, "Leaf", V(1.0, 0.2, 0.7), 0.6, 2.7, 0.2, 30)
end

local function cabin(m: Model)
	local W, D, hh = 13, 10, 7
	B.on(m, "Stone", V(15, 1.4, 12), 0, -0.5, 0)
	B.on(m, "Wood", V(W, hh, D), 0, 0.9, 0)
	for k = 0, 3 do
		local y = 1.6 + k * 1.7
		B.log(m, "Trunk", W + 1.2, 1.0, 0, y, -D / 2 - 0.1)
		B.log(m, "Trunk", W + 1.2, 1.0, 0, y, D / 2 + 0.1)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.on(m, "WoodDark", V(1.2, hh, 1.2), sx * (W / 2 + 0.2), 0.9, sz * (D / 2 + 0.2))
		end
	end
	local top = 0.9 + hh
	roof(m, "Roof", W + 2.4, D + 2.4, 5.4, top, 0, "RoofDark")
	for _, sx in { -1, 1 } do
		gable(m, "Wood", sx * W / 2, top, 0, D, 5.0, 0.6)
	end
	B.on(m, "Stone", V(2, 7, 2), W * 0.3, top, 2.0)
	B.on(m, "StoneDark", V(2.4, 0.6, 2.4), W * 0.3, top + 6.8, 2.0)
	B.on(m, "WoodDark", V(2.8, 4.6, 0.6), 0, 0.9, -D / 2 - 0.5)
	for _, sx in { -1, 1 } do
		B.on(m, "Glass", V(2.2, 2.2, 0.4), sx * 3.8, 2.9, -D / 2 - 0.55)
		B.on(m, "Trim", V(2.8, 0.4, 0.5), sx * 3.8, 2.6, -D / 2 - 0.65)
	end
	B.on(m, "Wood", V(6, 0.4, 3.6), 0, 0.2, -D / 2 - 2.4)
	B.on(m, "Glow", V(0.6, 0.8, 0.6), 1.9, 4.2, -D / 2 - 0.9)
end

local function hollowOak(m: Model, rng: Random)
	local h = 48
	B.round(m, "Trunk", h * 0.5, 8, 0, -0.6, 0, 10)
	for i = 0, 5 do
		local a = i * 60 + rnd(rng, -10, 10)
		local r = rad(a)
		B.on(m, "Trunk", V(2.2, 4.5, 6.5), math.cos(r) * 4.6, -0.6, math.sin(r) * 4.6, 90 - a, 0, 0)
	end
	B.on(m, "Dark", V(3.4, 5.2, 1.2), 0, -0.2, -3.7)
	B.on(m, "Glow", V(2.6, 4.2, 0.6), 0, 0.3, -3.5)
	for _, a in { 30, 140, 250 } do
		local r = rad(a)
		B.on(m, "Trunk", V(2.4, h * 0.3, 2.4), math.cos(r) * 1.6, h * 0.36, math.sin(r) * 1.6, 90 - a, 0, 0)
	end
	-- treehouse on a thick branch at the front
	local tz, ty = h * 0.4, -12
	B.box(m, "Trunk", V(2.6, 2.2, 9), 0, tz - 1.2, -6, 0, 9, 0)
	B.on(m, "Wood", V(11, 0.6, 9), 0, tz, ty)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.on(m, "WoodDark", V(0.4, 1.8, 0.4), sx * 5, tz + 0.6, ty + sz * 4)
		end
	end
	B.box(m, "WoodDark", V(10.4, 0.3, 0.3), 0, tz + 2.3, ty - 4.3)
	B.on(m, "Wall", V(7.6, 4.6, 6), 0, tz + 0.6, ty + 0.8)
	B.on(m, "WoodDark", V(2, 3.3, 0.4), -1.6, tz + 0.6, ty - 2.3)
	B.on(m, "Glow", V(1.8, 1.5, 0.3), 2.2, tz + 2.2, ty - 2.25)
	roof(m, "Roof", 9.0, 7.4, 3.0, tz + 5.2, ty + 0.8, "RoofDark")
	for _, sx in { -1, 1 } do
		gable(m, "Wall", sx * 3.8, tz + 5.2, ty + 0.8, 6.0, 2.8, 0.4)
	end
	for k = 0, 5 do
		B.box(m, "Wood", V(1.8, 0.25, 0.25), -3.6, tz - 1.0 - k * 1.7, ty - 4.6)
	end
	-- canopy: three wide flat tiers and clumps around them
	local base = h * 0.55
	for k, l in { { 42, "LeafDark" }, { 34, "Leaf" }, { 22, "LeafLight" } } do
		B.round(
			m,
			l[2] :: string,
			h * 0.14,
			l[1] :: number,
			rnd(rng, -1, 1),
			base + (k - 1) * h * 0.12,
			rnd(rng, -1, 1),
			rnd(rng, 0, 45)
		)
	end
	for i = 0, 4 do
		local a = rad(i * 72 + rnd(rng, -15, 15))
		B.blob(
			m,
			if i % 2 == 0 then "Leaf" else "LeafDark",
			rnd(rng, 11, 15),
			rnd(rng, 7, 9),
			rnd(rng, 11, 15),
			math.cos(a) * 17,
			base + rnd(rng, 3, 7),
			math.sin(a) * 17 + 3
		)
	end
end

---------------------------------------------------------------- Mushroom Grove

local function giantMushroom(h: number, cap: number, style: string, bend: number, spots: number)
	return function(m: Model, rng: Random)
		local seg = 2
		local pos = V(0, -0.5, 0)
		local w0 = cap * 0.24
		for i = 0, seg - 1 do
			local t = i / seg
			local ang = bend * math.sin(t * math.pi * 0.8) * 30
			local sl = h / seg
			local w = w0 * (1.15 - 0.3 * t)
			B.on(m, "Stem", V(w, sl + 0.4, w), pos.X, pos.Y, pos.Z, 0, 0, -ang)
			pos += V(math.sin(rad(ang)), math.cos(rad(ang)), 0) * sl
		end
		local top = pos
		B.round(m, "Stem", 1.0, w0 * 1.9, top.X - math.sin(rad(bend * 20)) * h * 0.3, top.Y - h * 0.32, top.Z)
		local r = cap / 2
		B.round(m, "Stem", 0.5, cap * 0.86, top.X, top.Y - 0.3, top.Z)
		B.round(m, "Glow", 0.3, cap * 0.5, top.X, top.Y - 0.45, top.Z, 22.5)
		local crown: number
		if style == "dome" then
			B.round(m, "Cap", r * 0.45, cap, top.X, top.Y, top.Z)
			B.round(m, "Cap", r * 0.45, cap * 0.62, top.X, top.Y + r * 0.45, top.Z, 20)
			crown = r * 0.45
		elseif style == "flat" then
			B.round(m, "Cap", r * 0.3, cap, top.X, top.Y, top.Z)
			B.round(m, "Cap", r * 0.18, cap * 0.7, top.X, top.Y + r * 0.3, top.Z, 20)
			crown = r * 0.3
		elseif style == "cone" then
			B.stack(m, "Cap", cap, cap * 0.18, r * 1.3, 4, top.X, top.Y, top.Z)
			crown = r * 0.3
		else -- bell
			B.round(m, "Cap", r * 0.5, cap, top.X, top.Y - r * 0.3, top.Z)
			B.round(m, "Cap", r * 0.45, cap * 0.8, top.X, top.Y + r * 0.2, top.Z, 20)
			B.round(m, "Cap", r * 0.25, cap * 0.45, top.X, top.Y + r * 0.65, top.Z, 10)
			crown = r * 0.5
		end
		for i = 1, spots do
			local a = rad(i * 360 / spots + rnd(rng, -15, 15))
			local rr = r * rnd(rng, 0.62, 0.86)
			B.on(
				m,
				"Spot",
				V(r * 0.26, 0.5, r * 0.26),
				top.X + math.cos(a) * rr,
				top.Y + crown - 0.25,
				top.Z + math.sin(a) * rr,
				rnd(rng, 0, 45)
			)
		end
	end
end

local function mushroomHouse(m: Model, rng: Random)
	B.round(m, "StoneDark", 0.9, 13.2, 0, -0.6, 0)
	B.round(m, "Stem", 10.5, 11.4, 0, -0.5, 0, 22.5)
	disc(m, "WoodDark", 3.4, 0.6, 0, 2.2, -5.8)
	B.on(m, "WoodDark", V(3.4, 2.6, 1.0), 0, 0.2, -5.6)
	B.on(m, "Gold", V(0.3, 0.3, 0.3), 0.9, 1.6, -6.25)
	for _, w in { { -3.6, 6.0, -4.6 }, { 3.6, 6.6, -4.6 }, { 5.6, 5.2, 0.6 } } do
		B.box(m, "Trim", V(2.2, 2.2, 0.5), w[1], w[2], w[3], math.deg(math.atan2(w[1], -w[3])))
		B.box(m, "Glow", V(1.5, 1.5, 0.6), w[1] * 1.02, w[2], w[3] * 1.02, math.deg(math.atan2(w[1], -w[3])))
	end
	B.round(m, "Stem", 0.4, 18.8, 0, 9.0, 0)
	B.round(m, "Glow", 0.3, 10, 0, 8.85, 0, 22.5)
	B.round(m, "Cap", 3.4, 20, 0, 9.4, 0)
	B.round(m, "Cap", 3.0, 14.6, 0, 12.8, 0, 20)
	B.round(m, "Cap", 1.6, 8, 0, 15.8, 0, 10)
	for i = 1, 6 do
		local a = rad(i * 60 + rnd(rng, -15, 15))
		local rr = rnd(rng, 7.2, 8.6)
		B.on(m, "Spot", V(1.6, 0.4, 1.6), math.cos(a) * rr, 12.75, math.sin(a) * rr, rnd(rng, 0, 45))
	end
	B.on(m, "Stone", V(1.6, 5.2, 1.6), 3.5, 12.0, 2.0, 0, 6, 10)
	B.on(m, "StoneDark", V(2.0, 0.6, 2.0), 4.4, 17.0, 2.5)
end

local function rootArch(m: Model, rng: Random)
	local span, h = 14, 8
	local n = 7
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local x = -span / 2 + t * span
		local y = h * math.sin(math.pi * t)
		local ang = math.deg(math.atan(h * math.pi * math.cos(math.pi * t) / span))
		local w = 2.4 * (1.15 - 0.4 * math.sin(math.pi * t))
		B.box(
			m,
			if i % 2 == 0 then "Trunk" else "WoodDark",
			V(span / (n - 1) + 1.2, w, w),
			x,
			y + 0.4,
			rnd(rng, -0.3, 0.3),
			0,
			0,
			ang
		)
	end
	for _, sx in { -1, 1 } do
		B.on(m, "Trunk", V(1.0, 3.0, 1.0), sx * span / 2 + sx * 1.2, -0.5, 0.8, 0, 0, sx * -25)
	end
	B.blob(m, "Leaf", 3.2, 1.4, 2.4, rnd(rng, -2, 2), h + 1.2, 0)
end

local function glowShrooms(m: Model, rng: Random)
	for i = 0, 3 do
		local a = rad(i * 90 + rnd(rng, -30, 30))
		local rr = rnd(rng, 0.3, 1.6)
		local hh = rnd(rng, 0.8, 2.4)
		local x, z = math.cos(a) * rr, math.sin(a) * rr
		B.on(m, "Stem", V(0.35, hh + 0.2, 0.35), x, -0.2, z)
		B.on(m, "Glow", V(rnd(rng, 1.0, 1.6), 0.5, rnd(rng, 1.0, 1.6)), x, hh, z, rnd(rng, 0, 45))
	end
end

local function mushroomTower(m: Model, rng: Random)
	local h = 58
	for i = 0, 5 do
		local a = i * 60 + rnd(rng, -10, 10)
		local r = rad(a)
		B.on(m, "Trunk", V(2.4, 3.2, 6.5), math.cos(r) * 6.4, -0.8, math.sin(r) * 6.4, 90 - a)
	end
	local seg = 5
	local pos = V(0, -0.6, 0)
	for i = 0, seg - 1 do
		local t = i / seg
		local ang = 6 * math.sin(t * math.pi)
		local sl = h * 0.8 / seg
		B.round(m, "Stem", sl + 0.3, 13 - 4.6 * t, pos.X, pos.Y, pos.Z, i * 9)
		pos += V(math.sin(rad(ang)), math.cos(rad(ang)), 0) * sl
	end
	local top = pos
	-- spiral stair
	local steps = 18
	for k = 0, steps - 1 do
		local t = k / steps
		local a = t * 360 * 2.2
		local rr = 7.2 - 2.2 * t
		local y = 1.0 + t * h * 0.72
		B.box(
			m,
			if k % 2 == 0 then "Wood" else "WoodDark",
			V(3.0, 0.5, 1.6),
			math.cos(rad(a)) * rr,
			y,
			math.sin(rad(a)) * rr,
			-a
		)
	end
	for _, w in { { -90, 0.2 }, { 20, 0.42 }, { 140, 0.6 }, { 230, 0.33 } } do
		local y = h * w[2]
		local rr = 6.6 - 2.2 * (y / (h * 0.8)) + 0.1
		local a = rad(w[1])
		B.box(m, "Trim", V(2.4, 2.4, 0.5), math.cos(a) * rr, y, math.sin(a) * rr, 90 - w[1])
		B.box(m, "Glow", V(1.6, 1.6, 0.6), math.cos(a) * (rr + 0.05), y, math.sin(a) * (rr + 0.05), 90 - w[1])
	end
	B.on(m, "WoodDark", V(3.6, 5.4, 1.6), 0, -0.4, -6.6)
	B.on(m, "Glow", V(2.6, 4.0, 0.4), 0, 0.2, -7.3)
	for _, sh in { { h * 0.35, 50 }, { h * 0.55, -125 } } do
		local y = sh[1]
		local a = rad(sh[2])
		local rr = 6.6 - 2.2 * (y / (h * 0.8)) + 2.6
		B.round(m, "Cap", 1.2, 8, math.cos(a) * rr, y, math.sin(a) * rr)
		B.round(m, "Glow", 0.3, 4, math.cos(a) * rr, y - 0.3, math.sin(a) * rr)
	end
	local r = 19
	B.round(m, "Stem", 0.8, 2 * r * 0.92, top.X, top.Y - 0.6, top.Z)
	B.round(m, "Glow", 0.4, 2 * r * 0.42, top.X, top.Y - 0.8, top.Z, 22.5)
	B.round(m, "Cap", r * 0.32, 2 * r, top.X, top.Y, top.Z)
	B.round(m, "Cap", r * 0.3, 2 * r * 0.74, top.X, top.Y + r * 0.32, top.Z, 20)
	B.round(m, "Cap", r * 0.2, 2 * r * 0.42, top.X, top.Y + r * 0.62, top.Z, 10)
	for i = 1, 8 do
		local a = rad(i * 45 + rnd(rng, -10, 10))
		local rr = r * rnd(rng, 0.78, 0.92)
		B.on(
			m,
			"Spot",
			V(r * 0.22, 0.8, r * 0.22),
			top.X + math.cos(a) * rr,
			top.Y + r * 0.32 - 0.4,
			top.Z + math.sin(a) * rr,
			rnd(rng, 0, 45)
		)
	end
end

---------------------------------------------------------------- far scenery

local function forestFar(pines: boolean)
	return function(m: Model, rng: Random)
		local w, d = 120, 40
		for i = 1, 6 do
			local x, z = rnd(rng, -w / 2, w / 2), rnd(rng, -d / 2, d / 2)
			local s = rnd(rng, 0.8, 1.4)
			if pines then
				B.on(m, "LeafDark", V(9 * s, 8 * s, 9 * s), x, -1, z, 45)
				B.on(m, "Leaf", V(5 * s, 9 * s, 5 * s), x, -1 + 8 * s, z)
			else
				B.on(m, "Trunk", V(1.6 * s, 6 * s, 1.6 * s), x, -1, z)
				B.on(
					m,
					if i % 2 == 0 then "Leaf" else "LeafDark",
					V(10 * s, 8 * s, 9 * s),
					x,
					4 * s,
					z,
					rnd(rng, 0, 45)
				)
			end
		end
	end
end

local function cloud(w: number, n: number)
	return function(m: Model, rng: Random)
		B.on(m, "Snow", V(w, 4, w * 0.45), 0, 0, 0)
		for i = 1, n do
			local s = rnd(rng, w * 0.2, w * 0.32)
			B.on(
				m,
				if i % 2 == 0 then "Snow" else "Trim",
				V(s, s * 0.7, s * 0.8),
				rnd(rng, -w * 0.36, w * 0.36),
				3.5,
				rnd(rng, -w * 0.1, w * 0.1),
				rnd(rng, -10, 10)
			)
		end
	end
end

Zones1.recipes = {
	Windmill = windmill,
	WindmillSails = windmillSails,
	HayBale = function(m: Model)
		B.log(m, "Sand", 3.2, 3.6, 0, 1.6, 0, 90)
		for _, z in { -0.9, 0.9 } do
			B.log(m, "Dirt", 0.3, 3.7, 0, 1.6, z, 90)
		end
	end,
	HayStack = function(m: Model)
		B.on(m, "Sand", V(4.2, 2.4, 2.6), 0, -0.2, 0)
		B.on(m, "Sand", V(4.2, 2.4, 2.6), 2.3, -0.2, 0.4, 12)
		B.on(m, "Sand", V(4.2, 2.4, 2.6), 1.1, 2.2, 0.2, -6)
		for _, x in { -1.0, 1.0 } do
			B.on(m, "Dirt", V(0.25, 2.5, 2.7), x, -0.25, 0)
		end
	end,
	Beehive = function(m: Model)
		B.on(m, "WoodDark", V(2.4, 1.6, 2.4), 0, -0.3, 0)
		B.stack(m, "Gold", 2.8, 1.2, 3.8, 4, 0, 1.3, 0)
		B.on(m, "Dark", V(0.6, 0.5, 0.4), 0, 1.6, -1.25)
	end,
	Sunflower = sunflower,
	Scarecrow = scarecrow,
	FarmCart = farmCart,
	PalmA = palm(18, 0.35, 7),
	PalmB = palm(22, 0.5, 8),
	PalmC = palm(14, 0.2, 6),
	Lighthouse = lighthouse,
	Dock = dock,
	BeachUmbrella = beachUmbrella,
	Shell = shell,
	Starfish = starfish,
	Driftwood = function(m: Model)
		B.log(m, "Wood", 9, 1.3, 0, 0.6, 0, 6)
		B.box(m, "Wood", V(3.2, 0.6, 0.6), 2.5, 0.9, 1.2, 40, 10, 0)
		B.box(m, "WoodDark", V(2.6, 0.5, 0.5), -3.0, 0.9, -0.8, -30, 0, 12)
	end,
	BeachHut = beachHut,
	TropicalPlant = tropicalPlant,
	MapleA = maple(17, 14, 2.0),
	MapleB = maple(13, 11, 1.6),
	LeafPile = leafPile,
	Pumpkin = pumpkin,
	Cabin = cabin,
	HollowOak = hollowOak,
	MushroomDome = giantMushroom(22, 14, "dome", 0.25, 3),
	MushroomFlat = giantMushroom(16, 16, "flat", 0.35, 4),
	MushroomCone = giantMushroom(26, 10, "cone", 0.15, 4),
	MushroomBell = giantMushroom(12, 9, "bell", 0.4, 3),
	MushroomHouse = mushroomHouse,
	RootArch = rootArch,
	GlowShrooms = glowShrooms,
	MushroomTower = mushroomTower,
	ForestFar = forestFar(false),
	PineFar = forestFar(true),
	CloudA = cloud(30, 4),
	CloudB = cloud(46, 6),
}

return Zones1
