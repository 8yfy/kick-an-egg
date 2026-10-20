--!strict
-- Partner A. Classic brick recipes for batch 3 zones: Crystal Caves (Crystal Spire landmark, crystal clusters,
-- crystal arch, geode, cave rock), Jungle Ruins (Jungle Temple landmark, jungle trees, ferns, stone head, mossy
-- ruin wall, hanging vines), Neon City (Neon Tower landmark, city buildings, storefront, neon lamp, billboard,
-- hologram egg), Haunted Graveyard (Haunted Manor landmark, gravestones, crooked tree, iron fence, jack-o'-lantern,
-- crypt, ghost) and Sky Islands (Sky Temple island landmark, floating islands, floating rocks, rope bridge, cloud
-- pillars). Asset space: origin = base centre, +Y up, front = -Z. Wedges rise toward their local +Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Zones3 = {}

local function rnd(rng: Random, a: number, b: number): number
	return rng:NextNumber(a, b)
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

-- A pointed crystal: a tall block with a pyramid tip (4 corner wedges would be costly: a stepped tip instead).
local function crystal(
	m: Model,
	role: string,
	w: number,
	h: number,
	x: number,
	y: number,
	z: number,
	tiltX: number,
	tiltZ: number,
	yaw: number
)
	local base = CFrame.new(x, y, z) * CFrame.Angles(0, rad(yaw), 0) * CFrame.Angles(rad(tiltX), 0, rad(tiltZ))
	B.at(m, role, V(w, h, w), base * CFrame.new(0, h / 2, 0))
	B.at(m, role, V(w * 0.62, w * 0.7, w * 0.62), base * CFrame.new(0, h + w * 0.35, 0) * CFrame.Angles(0, rad(45), 0))
	B.at(m, role, V(w * 0.28, w * 0.5, w * 0.28), base * CFrame.new(0, h + w * 0.95, 0))
end

---------------------------------------------------------------- Crystal Caves

local function crystalSpire(m: Model, rng: Random)
	-- a rock mound split open, a ring of leaning crystals and one huge central crystal with a floating halo
	for i = 0, 6 do
		local a = rad(i * 51)
		B.on(
			m,
			if i % 2 == 0 then "Stone" else "StoneDark",
			V(rnd(rng, 10, 14), rnd(rng, 5, 9), rnd(rng, 8, 12)),
			math.cos(a) * 11,
			-1,
			math.sin(a) * 11,
			90 - i * 51
		)
	end
	B.on(m, "StoneDark", V(18, 4, 18), 0, -1, 0, 20)
	crystal(m, "Crystal", 7, 34, 0, 2, 0, 0, 0, 20)
	for i = 0, 7 do
		local a = i * 45 + rnd(rng, -10, 10)
		local r = rad(a)
		local h = rnd(rng, 10, 22)
		crystal(
			m,
			if i % 2 == 0 then "Crystal" else "Glow",
			rnd(rng, 2.6, 4),
			h,
			math.cos(r) * 8,
			1.5,
			math.sin(r) * 8,
			-math.sin(r) * 22,
			math.cos(r) * 22,
			rnd(rng, 0, 90)
		)
	end
	-- floating halo of crystal shards (a ring of small blocks)
	for i = 0, 11 do
		local a = rad(i * 30)
		B.box(
			m,
			if i % 2 == 0 then "Glow" else "Crystal",
			V(1.4, 2.4, 1.4),
			math.cos(a) * 9,
			50,
			math.sin(a) * 9,
			i * 30,
			0,
			20
		)
	end
end

local function crystalCluster(n: number, size: number)
	return function(m: Model, rng: Random)
		B.on(m, "StoneDark", V(size * 1.6, size * 0.5, size * 1.4), 0, -0.4, 0, rnd(rng, 0, 45))
		for i = 0, n - 1 do
			local a = i * 360 / n + rnd(rng, -20, 20)
			local r = rad(a)
			local d = if i == 0 then 0 else size * 0.45
			crystal(
				m,
				if i % 3 == 1 then "Glow" else "Crystal",
				size * rnd(rng, 0.35, 0.5),
				size * rnd(rng, 1.2, 2.4) * (if i == 0 then 1.3 else 1),
				math.cos(r) * d,
				-0.2,
				math.sin(r) * d,
				-math.sin(r) * 18,
				math.cos(r) * 18,
				rnd(rng, 0, 90)
			)
		end
	end
end

local function crystalArch(m: Model, rng: Random)
	-- two leaning crystal pillars meeting over a gap (decor on the banks, spanning along the track, never over it)
	for _, s in { -1, 1 } do
		crystal(m, "Crystal", 3.4, 20, s * 9, -0.5, 0, 0, s * 24, rnd(rng, 0, 30))
		B.on(m, "StoneDark", V(6, 3, 6), s * 9, -1, 0, rnd(rng, 0, 45))
	end
	B.box(m, "Glow", V(4, 4, 4), 0, 19, 0, 45, 0, 45)
end

local function geode(m: Model)
	B.on(m, "Stone", V(9, 7, 6), 0, -0.5, 1.5)
	B.on(m, "StoneDark", V(7, 5, 0.8), 0, 0.5, -1.6)
	B.on(m, "Accent", V(6, 4.4, 1), 0, 0.8, -1.2)
	for i = 0, 4 do
		B.box(m, if i % 2 == 0 then "Crystal" else "Glow", V(1, 2.2, 1), -2.4 + i * 1.2, 3, -1.8, 0, 45, 0)
	end
end

local function caveRock(m: Model, rng: Random)
	local y = -0.5
	for k = 0, 4 do
		local w = 9 - k * 1.5
		B.on(
			m,
			if k % 2 == 0 then "Stone" else "StoneDark",
			V(w, 5, w * 0.9),
			rnd(rng, -0.8, 0.8),
			y,
			rnd(rng, -0.8, 0.8),
			k * 17
		)
		y += 4.9
	end
	crystal(m, "Crystal", 1.8, 5, 3, 7, -2, 0, 30, 20)
	crystal(m, "Glow", 1.4, 4, -2.6, 12, 1.4, 25, -20, 50)
end

---------------------------------------------------------------- Jungle Ruins

local function jungleTemple(m: Model, rng: Random)
	local tiers, base, th = 5, 40, 7
	for i = 0, tiers - 1 do
		local w = base - i * 6.8
		B.on(m, if i % 2 == 0 then "Stone" else "StoneDark", V(w, th, w), 0, -0.5 + i * th, 0)
		-- moss lip on each tier
		B.on(m, "Leaf", V(w + 0.6, 0.6, w + 0.6), 0, -0.5 + (i + 1) * th - 0.3, 0)
	end
	local h = tiers * th - 0.5
	-- front stair (wedge) with stone edges
	B.wedge(
		m,
		"StoneDark",
		V(9, h, base / 2),
		CFrame.new(0, h / 2 - 0.5, -base / 4 - 1.5) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, math.pi, 0)
	)
	-- shrine on top with a glowing doorway and a carved face
	B.on(m, "Stone", V(12, 9, 10), 0, h, 0)
	B.on(m, "Dark", V(4, 6, 1), 0, h, -5.2)
	B.on(m, "Glow", V(3, 5, 0.4), 0, h + 0.3, -5.6)
	roof(m, "StoneDark", 13, 11, 4, h + 9, 0, "Leaf")
	for _, s in { -1, 1 } do
		B.box(m, "Gold", V(1.6, 1.6, 0.6), s * 3.4, h + 6.4, -5.3)
	end
	-- vines draped down the faces
	for i = 1, 8 do
		local side = rng:NextInteger(0, 3)
		local yaw = side * 90
		local r = rad(yaw)
		local tier = rng:NextInteger(0, tiers - 2)
		local w = base - tier * 6.8
		local len = rnd(rng, 4, 9)
		local off = rnd(rng, -w / 2 + 2, w / 2 - 2)
		local x = math.sin(r) * (w / 2 + 0.3) + math.cos(r) * off
		local z = -math.cos(r) * (w / 2 + 0.3) + math.sin(r) * off
		B.on(m, "LeafDark", V(1.2, len, 0.5), x, -0.5 + (tier + 1) * th - len, z, yaw)
	end
end

local function jungleTree(height: number)
	return function(m: Model, rng: Random)
		-- tall trunk with buttress roots, an umbrella canopy in two layers, hanging vines
		B.on(m, "Trunk", V(2.2, height, 2.2), 0, -0.5, 0, rnd(rng, 0, 90))
		for i = 0, 3 do
			local a = i * 90 + rnd(rng, -15, 15)
			local r = rad(a)
			B.on(m, "Trunk", V(0.8, 3.4, 3), math.cos(r) * 1.6, -0.5, math.sin(r) * 1.6, 90 - a)
		end
		local w = height * 0.75
		B.on(m, "LeafDark", V(w, 2.6, w * 0.9), 0, height - 1.5, 0, rnd(rng, 0, 45))
		B.on(m, "Leaf", V(w * 0.7, 2.4, w * 0.65), rnd(rng, -1, 1), height + 1, rnd(rng, -1, 1), rnd(rng, 0, 45))
		B.on(m, "LeafLight", V(w * 0.35, 1.6, w * 0.35), 0, height + 3.3, 0, 20)
		for i = 0, 3 do
			local a = rad(i * 90 + rnd(rng, -20, 20))
			local len = rnd(rng, 3, 7)
			B.on(m, "LeafDark", V(0.5, len, 0.5), math.cos(a) * w * 0.4, height - 1.5 - len, math.sin(a) * w * 0.4)
		end
	end
end

local function fern(m: Model, rng: Random)
	for i = 0, 5 do
		local a = i * 60 + rnd(rng, -12, 12)
		local cf = CFrame.new(0, 0.4, 0) * CFrame.Angles(0, rad(-a), 0) * CFrame.Angles(0, 0, rad(rnd(rng, 28, 42)))
		B.at(m, if i % 2 == 0 then "Leaf" else "LeafDark", V(4, 0.3, 1.2), cf * CFrame.new(2, 0, 0))
	end
	B.on(m, "LeafLight", V(1, 1, 1), 0, -0.2, 0, 45)
end

local function stoneHead(m: Model)
	B.on(m, "StoneDark", V(8, 2, 7), 0, -0.5, 0)
	B.on(m, "Stone", V(7, 10, 6), 0, 1.5, 0)
	B.on(m, "Stone", V(8, 2, 6.6), 0, 11.5, 0)
	for _, s in { -1, 1 } do
		B.box(m, "Dark", V(1.6, 1.2, 0.4), s * 1.8, 8.4, -3.1)
		B.box(m, "Glow", V(0.8, 0.6, 0.3), s * 1.8, 8.4, -3.25)
	end
	B.box(m, "StoneDark", V(1.6, 3, 1.4), 0, 6.4, -3.4)
	B.box(m, "Dark", V(4, 0.8, 0.4), 0, 3.8, -3.1)
	B.on(m, "Leaf", V(8.4, 1, 6.8), 0, 13.5, 0)
	B.on(m, "LeafDark", V(1, 4, 0.5), -3, 9.6, -3.2)
end

local function ruinWall(m: Model, rng: Random)
	local x = -8
	while x < 8 do
		local w = rnd(rng, 2.5, 4)
		local h = rnd(rng, 3, 8)
		B.on(m, if rng:NextNumber() < 0.5 then "Stone" else "StoneDark", V(w, h, 2.6), x + w / 2, -0.5, 0)
		if rng:NextNumber() < 0.6 then
			B.on(m, "Leaf", V(w + 0.2, 0.5, 2.8), x + w / 2, h - 0.5, 0)
		end
		x += w
	end
	B.box(m, "Glow", V(1.4, 1.4, 0.3), rnd(rng, -4, 4), 3, -1.4, 45, 0, 0)
end

local function vines(m: Model, rng: Random)
	for i = 0, 4 do
		local len = rnd(rng, 4, 10)
		B.on(m, if i % 2 == 0 then "Leaf" else "LeafDark", V(1, len, 0.4), -4 + i * 2, -len, 0)
		B.box(m, "LeafLight", V(1.4, 1, 0.5), -4 + i * 2 + 0.3, -len * rnd(rng, 0.3, 0.7), -0.1)
	end
	B.box(m, "LeafDark", V(10, 1, 1.2), 0, 0.3, 0)
end

---------------------------------------------------------------- Neon City

-- A city building: a box with window rows (Glass or Glow), a coloured trim band per floor, a rooftop unit and an
-- optional neon sign strip down the front edge.
local function building(w: number, d: number, floors: number, sign: boolean)
	return function(m: Model, rng: Random)
		local fh = 4
		local h = floors * fh
		B.on(m, "Wall", V(w, h, d), 0, -0.5, 0)
		for f = 0, floors - 1 do
			local y = -0.5 + f * fh
			B.on(m, "Trim", V(w + 0.3, 0.5, d + 0.3), 0, y + fh - 0.5, 0)
			-- one window strip per floor, lit on some floors
			B.on(m, if rng:NextNumber() < 0.4 then "Glow" else "Glass", V(w - 1.6, 2, 0.3), 0, y + 1, -d / 2 - 0.1)
		end
		B.on(m, "Metal", V(w * 0.4, 2, d * 0.4), rnd(rng, -1, 1), h - 0.5, rnd(rng, -1, 1))
		B.on(m, "Metal", V(0.4, 4, 0.4), w * 0.3, h - 0.5, d * 0.2)
		if sign then
			B.on(m, "Neon", V(1, h * 0.6, 0.6), w / 2 - 0.6, h * 0.25, -d / 2 - 0.4)
			B.on(m, "Neon2", V(w * 0.7, 1.2, 0.5), 0, h - 2.6, -d / 2 - 0.4)
		end
	end
end

local function neonTower(m: Model, rng: Random)
	-- a stepped skyscraper: three setbacks, neon bands on every setback, glass faces, a spire with a glowing tip
	local y = -0.5
	for i, s in { { 22, 28 }, { 16, 24 }, { 11, 20 } } do
		local w, h = s[1], s[2]
		B.on(m, "Wall", V(w, h, w), 0, y, 0)
		for k = 0, 3 do
			local a = k * 90
			local r = rad(a)
			B.on(
				m,
				"Glass",
				V(w * 0.7, h - 3, 0.3),
				math.sin(r) * (w / 2 + 0.1),
				y + 1.5,
				-math.cos(r) * (w / 2 + 0.1),
				a
			)
		end
		B.on(m, if i % 2 == 0 then "Neon2" else "Neon", V(w + 0.6, 0.8, w + 0.6), 0, y + h - 0.6, 0)
		y += h
	end
	B.on(m, "Metal", V(3, 6, 3), 0, y, 0)
	B.on(m, "Metal", V(0.8, 14, 0.8), 0, y + 6, 0)
	B.on(m, "Glow", V(1.6, 1.6, 1.6), 0, y + 20, 0, 45)
	-- a rotating-looking billboard ring halfway up
	for k = 0, 3 do
		local r = rad(k * 90)
		B.on(m, "Neon3", V(8, 4, 0.5), math.sin(r) * 12.6, 26, -math.cos(r) * 12.6, k * 90)
	end
end

local function storefront(m: Model, rng: Random)
	local W, D = 14, 10
	B.on(m, "Wall", V(W, 9, D), 0, -0.5, 0)
	B.on(m, "Glass", V(W - 4, 4.4, 0.3), -1, 0, -D / 2 - 0.1)
	B.on(m, "Dark", V(3, 5, 0.4), W / 2 - 2.4, -0.5, -D / 2 - 0.1)
	-- striped awning
	for i = 0, 6 do
		B.box(
			m,
			if i % 2 == 0 then "Cloth" else "Cloth2",
			V(W / 7 + 0.01, 0.3, 3),
			-W / 2 + (i + 0.5) * W / 7,
			5.2,
			-D / 2 - 1.4,
			0,
			-14,
			0
		)
	end
	B.on(m, "Neon", V(W - 2, 1.6, 0.5), 0, 6.6, -D / 2 - 0.3)
	B.on(m, "Trim", V(W + 0.4, 0.6, D + 0.4), 0, 8.4, 0)
	B.on(m, "Metal", V(3, 1.6, 3), rnd(rng, -3, 3), 8.5, 1)
end

local function neonLamp(m: Model)
	B.on(m, "Metal", V(1.4, 0.6, 1.4), 0, -0.3, 0)
	B.on(m, "Metal", V(0.5, 11, 0.5), 0, 0.3, 0)
	B.box(m, "Metal", V(3.6, 0.4, 0.4), 1.6, 11.1, 0)
	B.on(m, "Neon", V(1.4, 0.5, 1), 3.2, 10.4, 0)
end

local function billboard(m: Model)
	for _, s in { -1, 1 } do
		B.on(m, "Metal", V(0.8, 10, 0.8), s * 5, -0.5, 0)
	end
	B.on(m, "Dark", V(14, 7, 0.8), 0, 9, 0)
	B.on(m, "Neon", V(14.6, 0.5, 1), 0, 8.8, 0)
	B.on(m, "Neon", V(14.6, 0.5, 1), 0, 15.8, 0)
	B.on(m, "Neon2", V(5, 4, 0.4), -3.5, 10.5, -0.5)
	B.on(m, "Neon3", V(5, 4, 0.4), 3.5, 10.5, -0.5)
end

local function hologramEgg(m: Model)
	B.round(m, "Metal", 1, 6, 0, -0.4, 0, 22.5)
	B.round(m, "Neon", 0.3, 5, 0, 0.6, 0)
	B.egg(m, "Hologram", 4, 6, 0, 2, 0)
end

---------------------------------------------------------------- Haunted Graveyard

local function hauntedManor(m: Model, rng: Random)
	local W, D, H = 26, 18, 14
	B.on(m, "StoneDark", V(W + 2, 1.4, D + 2), 0, -0.5, 0)
	B.on(m, "Wall", V(W, H, D), 0, 0.9, 0, 0, 0, 1.5)
	B.on(m, "Trim", V(W + 0.4, 0.6, D + 0.4), 0, 0.9 + H, 0)
	roof(m, "Roof", W + 2, D + 2, 8, 1.5 + H, 0, "RoofDark")
	-- crooked tower with a pointy roof and a glowing window
	B.on(m, "Wall", V(8, H + 14, 8), -W / 2 + 3, 0.9, -D / 2 + 3, 6, 0, -3)
	B.stack(m, "Roof", 10, 1.4, 10, 5, -W / 2 + 2.4, H + 15, -D / 2 + 3, 6)
	B.on(m, "Glow", V(2.4, 3.4, 0.4), -W / 2 + 3, H + 6, -D / 2 - 1.1)
	-- windows (glowing purple-green), a door and steps
	for _, x in { -3, 3, 8 } do
		for _, y in { 3.2, 9.2 } do
			B.on(m, if rng:NextNumber() < 0.6 then "Glow" else "Dark", V(2.4, 3.2, 0.4), x, y, -D / 2 - 0.1)
			B.on(m, "Trim", V(3, 0.4, 0.6), x, y - 0.3, -D / 2 - 0.2)
		end
	end
	B.on(m, "WoodDark", V(4, 6, 0.6), 2.5, 0.9, -D / 2 - 0.2)
	B.on(m, "StoneDark", V(6, 0.9, 3), 2.5, -0.5, -D / 2 - 1.8)
	-- chimney and a glowing attic window
	B.on(m, "StoneDark", V(2.6, 9, 2.6), 7, H + 3, 3, 0, 0, -4)
	B.on(m, "Glow", V(2, 2, 0.4), 4, H + 4.4, -D / 2 - 0.9)
end

local function gravestone(kind: number)
	return function(m: Model, rng: Random)
		B.on(m, "StoneDark", V(3.4, 0.6, 2), 0, -0.3, 0)
		local tilt = rnd(rng, -8, 8)
		if kind == 1 then
			B.on(m, "Stone", V(2.6, 3.4, 0.8), 0, 0.3, 0, 0, 0, tilt)
			B.on(m, "Stone", V(1.8, 0.8, 0.8), 0, 3.7, 0, 0, 0, tilt)
		elseif kind == 2 then
			B.on(m, "Stone", V(0.8, 4.4, 0.8), 0, 0.3, 0, 0, 0, tilt)
			B.box(m, "Stone", V(2.8, 0.8, 0.8), 0, 3.4, 0, 0, 0, tilt)
		else
			B.on(m, "Stone", V(2.2, 2.2, 1.4), 0, 0.3, 0, 0, tilt, 0)
			B.on(m, "Stone", V(1.4, 1.6, 1.4), 0, 2.5, 0, 45)
		end
		B.on(m, "Leaf", V(1.2, 0.4, 1), rnd(rng, -1, 1), 0.3, -0.9)
	end
end

local function crookedTree(m: Model, rng: Random)
	local y, x = -0.4, 0
	for k = 0, 3 do
		local lean = rnd(rng, -14, 14)
		B.on(m, "Trunk", V(1.6 - k * 0.25, 4, 1.6 - k * 0.25), x, y, 0, k * 30, 0, lean)
		x += math.sin(rad(-lean)) * 4
		y += 3.8
	end
	for i = 0, 3 do
		local a = i * 90 + rnd(rng, -25, 25)
		local r = rad(a)
		local len = rnd(rng, 3, 5)
		B.on(
			m,
			"Trunk",
			V(0.5, len, 0.5),
			x * 0.6 + math.cos(r) * 0.4,
			rnd(rng, 7, 13),
			math.sin(r) * 0.4,
			90 - a,
			0,
			-50
		)
	end
	B.on(m, "Glow", V(0.8, 1.2, 0.8), x + 1.4, y - 2, 0)
end

local function ironFence(m: Model)
	B.box(m, "Dark", V(8, 0.3, 0.3), 0, 1.0, 0)
	B.box(m, "Dark", V(8, 0.3, 0.3), 0, 3.0, 0)
	for i = 0, 2 do
		local x = -4 + (i + 0.5) * 8 / 3
		B.on(m, "Dark", V(0.3, 4.2, 0.3), x, -0.3, 0)
	end
end

local function jackOLantern(m: Model)
	B.round(m, "Accent", 2.4, 3.6, 0, -0.2, 0)
	B.round(m, "Accent", 0.6, 2.4, 0, 2.2, 0, 20)
	B.on(m, "Trunk", V(0.4, 0.8, 0.4), 0, 2.8, 0)
	for _, s in { -1, 1 } do
		B.box(m, "Glow", V(0.7, 0.7, 0.2), s * 0.7, 1.5, -1.82)
	end
	B.box(m, "Glow", V(1.6, 0.4, 0.2), 0, 0.6, -1.82)
end

local function crypt(m: Model)
	B.on(m, "StoneDark", V(10, 1, 8), 0, -0.5, 0)
	B.on(m, "Stone", V(8, 6, 7), 0, 0.5, 0.5)
	roof(m, "StoneDark", 9, 8, 3, 6.5, 0.5, "Stone")
	B.on(m, "Dark", V(3, 4.4, 0.4), 0, 0.5, -3.1)
	for _, s in { -1, 1 } do
		B.on(m, "Stone", V(1.2, 6, 1.2), s * 3, 0.5, -3.4)
	end
	B.on(m, "Glow", V(0.8, 1, 0.8), 0, 9.5, 0.5)
end

local function ghost(m: Model)
	B.blob(m, "Ghost", 3.2, 3.4, 3, 0, 4.4, 0)
	B.on(m, "Ghost", V(3, 1.6, 2.8), 0, 1.8, 0)
	for i = 0, 2 do
		B.on(m, "Ghost", V(0.9, 1, 0.9), -1 + i, 0.9, 0)
	end
	for _, s in { -1, 1 } do
		B.box(m, "Dark", V(0.5, 0.7, 0.2), s * 0.6, 4.8, -1.55)
	end
	B.box(m, "Dark", V(0.6, 0.6, 0.2), 0, 3.9, -1.55)
end

---------------------------------------------------------------- Sky Islands

-- A floating island: a grass cap on an inverted stepped rock cone, with a tree tuft (origin = the grass top centre).
local function island(w: number, depth: number)
	return function(m: Model, rng: Random)
		B.on(m, "Ground", V(w, 1.6, w * 0.9), 0, -1.6, 0, rnd(rng, 0, 30))
		local y = -1.6
		local s = 1
		for k = 0, 4 do
			s *= 0.78
			local h = depth / 5
			B.on(
				m,
				if k % 2 == 0 then "Stone" else "StoneDark",
				V(w * s, h, w * 0.9 * s),
				rnd(rng, -0.6, 0.6),
				y - h,
				rnd(rng, -0.6, 0.6),
				k * 20
			)
			y -= h
		end
		B.on(m, "Dirt", V(w * 0.94, 0.8, w * 0.84), 0, -2.4, 0)
	end
end

local function skyTemple(m: Model, rng: Random)
	-- the big island
	B.on(m, "Ground", V(44, 2, 40), 0, -2, 0)
	local y = -2
	local s = 1
	for k = 0, 5 do
		s *= 0.8
		B.on(
			m,
			if k % 2 == 0 then "Stone" else "StoneDark",
			V(44 * s, 4, 40 * s),
			rnd(rng, -1, 1),
			y - 4,
			rnd(rng, -1, 1),
			k * 15
		)
		y -= 4
	end
	-- the temple: a stepped base, a ring of columns, a dome of stacked rounds with a gold finial
	B.on(m, "Trim", V(26, 1.2, 26), 0, 0, 0)
	B.on(m, "Wall", V(23, 1.2, 23), 0, 1.2, 0)
	for i = 0, 9 do
		local a = rad(i * 36)
		B.on(m, "Wall", V(1.8, 12, 1.8), math.cos(a) * 9.5, 2.4, math.sin(a) * 9.5)
		B.on(m, "Trim", V(2.4, 0.8, 2.4), math.cos(a) * 9.5, 14.4, math.sin(a) * 9.5)
	end
	B.round(m, "Trim", 1.6, 22, 0, 15, 0, 22.5)
	B.stack(m, "Roof", 20, 4, 9, 5, 0, 16.6, 0, 0, "Wall")
	B.on(m, "Gold", V(1.4, 3, 1.4), 0, 25.6, 0, 45)
	B.on(m, "Glow", V(4, 4, 4), 0, 6, 0, 45, 0, 45)
	-- a small waterfall pouring off the island edge
	B.on(m, "Water", V(4, 18, 0.8), 0, -18, -20.2)
end

local function floatingRock(m: Model, rng: Random)
	B.on(m, "Stone", V(5, 3, 4.4), 0, 0, 0, rnd(rng, 0, 45))
	B.on(m, "StoneDark", V(3, 2.6, 3), rnd(rng, -0.5, 0.5), -2.4, rnd(rng, -0.5, 0.5), rnd(rng, 0, 45))
	B.on(m, "Ground", V(4, 0.6, 3.6), 0, 3, 0, rnd(rng, 0, 45))
end

local function ropeBridge(m: Model)
	-- planks along local Z (length 24), rope rails, sagging a little
	local L, n = 24, 10
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local sag = -1.4 * math.sin(math.pi * t)
		B.box(m, if i % 3 == 0 then "WoodDark" else "Wood", V(4, 0.3, L / n - 0.2), 0, sag, -L / 2 + t * L)
	end
	for _, s in { -1, 1 } do
		for k = 0, 3 do
			local t0, t1 = k / 4, (k + 1) / 4
			local z0, z1 = -L / 2 + t0 * L, -L / 2 + t1 * L
			local y0, y1 = 2 - 1.4 * math.sin(math.pi * t0), 2 - 1.4 * math.sin(math.pi * t1)
			B.box(
				m,
				"Cloth2",
				V(0.2, 0.2, math.sqrt((z1 - z0) ^ 2 + (y1 - y0) ^ 2) + 0.2),
				s * 2,
				(y0 + y1) / 2,
				(z0 + z1) / 2,
				0,
				-math.deg(math.atan2(y1 - y0, z1 - z0)),
				0
			)
		end
		for _, e in { -1, 1 } do
			B.on(m, "WoodDark", V(0.5, 3, 0.5), s * 2, -0.5, e * L / 2)
		end
	end
end

local function cloudPillar(m: Model, rng: Random)
	local y = -2
	for k = 0, 4 do
		local w = rnd(rng, 7, 11) * (1 - k * 0.1)
		B.on(
			m,
			if k % 2 == 0 then "Snow" else "Trim",
			V(w, 4, w * 0.8),
			rnd(rng, -1.5, 1.5),
			y,
			rnd(rng, -1, 1),
			rnd(rng, 0, 45)
		)
		y += 3.6
	end
end

Zones3.recipes = {
	CrystalSpire = crystalSpire,
	CrystalClusterA = crystalCluster(5, 4),
	CrystalClusterB = crystalCluster(3, 2.6),
	CrystalArch = crystalArch,
	Geode = geode,
	CaveRock = caveRock,
	JungleTemple = jungleTemple,
	JungleTreeA = jungleTree(20),
	JungleTreeB = jungleTree(15),
	Fern = fern,
	StoneHead = stoneHead,
	RuinWall = ruinWall,
	Vines = vines,
	NeonTower = neonTower,
	BuildingA = building(14, 12, 6, true),
	BuildingB = building(10, 10, 9, true),
	BuildingC = building(18, 12, 4, false),
	Storefront = storefront,
	NeonLamp = neonLamp,
	Billboard = billboard,
	HologramEgg = hologramEgg,
	HauntedManor = hauntedManor,
	GravestoneA = gravestone(1),
	GravestoneB = gravestone(2),
	GravestoneC = gravestone(3),
	CrookedTree = crookedTree,
	IronFence = ironFence,
	JackOLantern = jackOLantern,
	Crypt = crypt,
	Ghost = ghost,
	IslandA = island(16, 12),
	IslandB = island(26, 18),
	SkyTemple = skyTemple,
	FloatingRock = floatingRock,
	RopeBridge = ropeBridge,
	CloudPillar = cloudPillar,
}

return Zones3
