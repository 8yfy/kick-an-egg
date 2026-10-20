--!strict
-- Partner A. Classic brick recipes: shared nature (recoloured per zone by role). Trees with layered studded
-- canopies, pines, bushes, flowers, grass tufts, stepped rocks and slabs, terrain banks (dirt / stone sides,
-- ground cap, drips), stepped hills and mountains with snow caps, stumps, logs, small mushrooms.
-- Each recipe builds into `m` in asset space (origin = base centre, +Y up, front = -Z); roles name the parts.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new

local Nature = {}

local function rnd(rng: Random, a: number, b: number): number
	return rng:NextNumber(a, b)
end

-- radial yaw: a block's long local Z axis pointing along angle `a` (degrees, 0 = +X, 90 = +Z)
local function radial(a: number): number
	return 90 - a
end

local function trunk(m: Model, rng: Random, th: number, tw: number, roots: number)
	B.on(m, "Trunk", V(tw, th + 0.5, tw), 0, -0.5, 0, rnd(rng, 0, 90))
	for i = 0, roots - 1 do
		local a = i * 360 / roots + rnd(rng, -20, 20)
		local r = math.rad(a)
		B.on(
			m,
			"Trunk",
			V(tw * 0.55, tw * 0.75, tw * 1.2),
			math.cos(r) * tw * 0.62,
			-0.4,
			math.sin(r) * tw * 0.62,
			radial(a)
		)
	end
end

-- Layered tree: trunk with roots and a branch, a wide dark canopy with side clumps, a mid layer, a light crown.
local function layered(height: number, width: number, tw: number, layers: number)
	return function(m: Model, rng: Random)
		local th = height * 0.42
		trunk(m, rng, th, tw, 2)
		local ba = rnd(rng, 0, 360)
		local br = math.rad(ba)
		B.on(
			m,
			"Trunk",
			V(tw * 0.5, th * 0.55, tw * 0.5),
			math.cos(br) * tw * 0.3,
			th * 0.5,
			math.sin(br) * tw * 0.3,
			radial(ba),
			0,
			35
		)
		local roles = { "LeafDark", "Leaf", "LeafLight" }
		local base = th * 0.88
		local lh = (height - base) / (layers + 0.35)
		for i = 0, layers - 1 do
			local f = 1 - 0.36 * i
			local w = width * f
			local y = base + i * lh * 0.92
			local yaw = rnd(rng, -20, 20)
			B.on(m, roles[i + 1], V(w * 0.82, lh, w * 0.72), rnd(rng, -0.5, 0.5), y, rnd(rng, -0.5, 0.5), yaw)
			local clumps = if i == 0 then 2 elseif i == 1 then 1 else 0
			for k = 1, clumps do
				local a = rnd(rng, 0, 360)
				local r = math.rad(a)
				local s = w * rnd(rng, 0.34, 0.42)
				B.on(
					m,
					roles[math.min(i + 2, 3)],
					V(s, lh * 0.85, s),
					math.cos(r) * w * 0.38,
					y - lh * 0.12,
					math.sin(r) * w * 0.32,
					a
				)
			end
		end
		B.on(m, "LeafLight", V(width * 0.2, lh * 0.6, width * 0.2), 0, base + layers * lh * 0.92 - 0.1, 0, 30)
	end
end

-- Blob tree: a round trunk and two or three stacked voxel blobs (a classic "lollipop" tree).
local function blobby(height: number, width: number, tw: number, balls: number)
	return function(m: Model, rng: Random)
		local th = height * 0.45
		trunk(m, rng, th, tw, 2)
		local r = width / 2
		B.blob(m, "LeafDark", width, r * 1.5, width, 0, th + r * 0.55, 0, rnd(rng, 0, 90))
		if balls >= 2 then
			B.blob(
				m,
				"Leaf",
				width * 0.75,
				r * 1.2,
				width * 0.75,
				rnd(rng, -1, 1),
				th + r * 1.35,
				rnd(rng, -1, 1),
				rnd(rng, 0, 90)
			)
		end
		if balls >= 3 then
			B.blob(
				m,
				"LeafLight",
				width * 0.45,
				r * 0.8,
				width * 0.45,
				rnd(rng, -0.6, 0.6),
				th + r * 1.95,
				rnd(rng, -0.6, 0.6),
				rnd(rng, 0, 90)
			)
		end
	end
end

-- Poplar: short trunk, stacked narrowing blocks.
local function poplar(height: number, width: number)
	return function(m: Model, rng: Random)
		trunk(m, rng, height * 0.28, 1.2, 0)
		local seg = height * 0.8 / 4.4
		local y = height * 0.2
		for i = 0, 3 do
			local w = width * (1 - 0.17 * i)
			B.on(
				m,
				if i % 2 == 0 then "LeafDark" else "Leaf",
				V(w, seg * 1.15, w * 0.9),
				rnd(rng, -0.3, 0.3),
				y,
				rnd(rng, -0.3, 0.3),
				rnd(rng, 0, 90)
			)
			y += seg
		end
		B.on(m, "LeafLight", V(width * 0.38, seg * 0.8, width * 0.38), 0, y - 0.1, 0, 20)
	end
end

-- Classic pine: trunk, square tiers alternating 45 degrees, a pointed top; snow puts a white slab on each tier.
local function pine(height: number, width: number, tiers: number, snow: boolean)
	return function(m: Model, rng: Random)
		trunk(m, rng, height * 0.2, 1.4, 0)
		local y = height * 0.14
		local th = (height - y) / (tiers + 0.8)
		for i = 0, tiers - 1 do
			local t = i / math.max(tiers - 1, 1)
			local w = width * (1 - 0.72 * t)
			local yaw = (i % 2) * 45 + rnd(rng, -4, 4)
			B.on(m, if i % 2 == 0 then "LeafDark" else "Leaf", V(w, th * 1.05, w), 0, y, 0, yaw)
			if snow then
				B.on(m, "Snow", V(w * 0.72, 0.5, w * 0.72), 0, y + th * 1.05, 0, yaw)
			end
			y += th
		end
		B.on(m, if snow then "Snow" else "LeafLight", V(width * 0.16, th * 1.4, width * 0.16), 0, y - 0.1, 0, 45)
	end
end

local function bush(width: number, height: number, n: number, flowers: number)
	return function(m: Model, rng: Random)
		B.on(m, "Leaf", V(width * 0.62, height, width * 0.55), 0, -0.4, 0, rnd(rng, 0, 90))
		for i = 1, n - 1 do
			local a = i * 360 / (n - 1) + rnd(rng, -25, 25)
			local r = math.rad(a)
			local s = width * rnd(rng, 0.36, 0.46)
			B.on(
				m,
				if i % 2 == 0 then "Leaf" else "LeafDark",
				V(s, height * rnd(rng, 0.55, 0.82), s),
				math.cos(r) * width * 0.3,
				-0.4,
				math.sin(r) * width * 0.26,
				a
			)
		end
		B.on(
			m,
			"LeafLight",
			V(width * 0.3, height * 0.32, width * 0.3),
			rnd(rng, -0.4, 0.4),
			height * 0.55,
			rnd(rng, -0.4, 0.4),
			30
		)
		for i = 1, flowers do
			local a = rnd(rng, 0, 360)
			local r = math.rad(a)
			B.box(
				m,
				if i % 2 == 0 then "Accent" else "Accent2",
				V(0.8, 0.8, 0.8),
				math.cos(r) * width * 0.32,
				height * rnd(rng, 0.55, 0.85),
				math.sin(r) * width * 0.28,
				a
			)
		end
	end
end

local function rock(w: number, h: number, d: number, extra: number)
	return function(m: Model, rng: Random)
		B.on(m, "Stone", V(w, h * 0.55, d), 0, -0.4, 0, rnd(rng, -15, 15))
		B.on(
			m,
			"StoneDark",
			V(w * 0.7, h * 0.35, d * 0.7),
			rnd(rng, -0.6, 0.6),
			h * 0.55 - 0.4,
			rnd(rng, -0.6, 0.6),
			rnd(rng, -30, 30)
		)
		B.on(
			m,
			"Stone",
			V(w * 0.4, h * 0.25, d * 0.42),
			rnd(rng, -0.5, 0.5),
			h * 0.9 - 0.4,
			rnd(rng, -0.5, 0.5),
			rnd(rng, 0, 90)
		)
		B.wedge(
			m,
			"Stone",
			V(d * 0.8, h * 0.4, w * 0.35),
			CFrame.new(w * 0.62, h * 0.2 - 0.4, 0) * CFrame.Angles(0, math.rad(-90), 0)
		)
		for i = 1, extra do
			local a = rnd(rng, 0, 360)
			local r = math.rad(a)
			local s = rnd(rng, 0.25, 0.4)
			B.on(m, "StoneDark", V(w * s, h * s * 0.8, d * s), math.cos(r) * w * 0.6, -0.3, math.sin(r) * d * 0.6, a)
		end
	end
end

local function slabs(w: number, d: number, h: number, layers: number)
	return function(m: Model, rng: Random)
		local lh = (h + 0.4) / layers
		local y = -0.4
		for i = 0, layers - 1 do
			local s = 1 - 0.17 * i
			B.on(
				m,
				if i % 2 == 0 then "Stone" else "StoneDark",
				V(w * s * rnd(rng, 0.92, 1.05), lh, d * s * rnd(rng, 0.92, 1.05)),
				rnd(rng, -0.6, 0.6),
				y,
				rnd(rng, -0.6, 0.6),
				rnd(rng, -8, 8)
			)
			y += lh
		end
	end
end

-- Terrain bank (valley sides): runs along local X (length), its face toward the track is local -Z, climbs in
-- tiers toward +Z. Stone body with a darker band, a Ground cap per tier, Ground drips over each front edge.
local function bank(length: number, depth: number, height: number, tiers: number)
	return function(m: Model, rng: Random)
		local td = depth / tiers
		for t = 0, tiers - 1 do
			local h = height * (t + 1) / tiers
			local dd = depth - td * t
			local zc = -depth / 2 + td * t + dd / 2
			local band = h * 0.45
			B.on(m, "Stone", V(length, band + 0.6, dd - 0.4), 0, -0.6, zc + 0.2)
			B.on(m, "StoneDark", V(length - 0.4, h - band - 1.0, dd - 0.6), 0, band, zc + 0.3)
			B.on(m, "Ground", V(length + 0.2, 1.0, dd + 0.2), 0, h - 1.0, zc - 0.1)
			for _ = 1, 2 do
				local dw = rnd(rng, 1.8, 3.4)
				local dh = rnd(rng, 0.8, 2.4)
				B.on(
					m,
					"Ground",
					V(dw, dh, 1),
					rnd(rng, -length / 2 + 2, length / 2 - 2),
					h - 1.0 - dh,
					zc - dd / 2 - 0.1
				)
			end
		end
	end
end

-- Stepped hill: stacked ground plates shrinking upward, offset, with a rock step.
local function hill(w: number, d: number, h: number, steps: number)
	return function(m: Model, rng: Random)
		local sh = h / steps
		local ox, oz = 0, 0
		for i = 0, steps - 1 do
			local s = 1 - 0.75 * (i / steps)
			ox += rnd(rng, -w * 0.04, w * 0.04)
			oz += rnd(rng, -d * 0.04, d * 0.04)
			B.on(m, "Ground", V(w * s, sh + 0.3, d * s * rnd(rng, 0.9, 1.05)), ox, -1 + i * sh, oz, rnd(rng, -10, 10))
		end
		B.on(m, "Stone", V(w * 0.16, sh * 1.2, d * 0.12), w * 0.28, -0.5, -d * 0.3, 20)
		B.on(m, "StoneDark", V(w * 0.1, sh * 0.8, d * 0.08), w * 0.36, -0.5, -d * 0.24, 50)
	end
end

-- Stepped mountain massif: a main stepped pyramid and two lower shoulders, Snow on the top steps.
local function mountain(w: number, d: number, h: number, snow: boolean)
	return function(m: Model, rng: Random)
		local function peak(cx: number, cz: number, pw: number, pd: number, ph: number, steps: number)
			local sh = ph / steps
			for i = 0, steps - 1 do
				local t = i / steps
				local s = 1 - 0.86 * t
				local role = if snow and t >= 0.62 then "Snow" elseif i % 2 == 0 then "Stone" else "StoneDark"
				B.on(
					m,
					role,
					V(pw * s, sh + 0.4, pd * s * rnd(rng, 0.85, 1.05)),
					cx + rnd(rng, -pw * 0.03, pw * 0.03),
					-2 + i * sh,
					cz + rnd(rng, -pd * 0.03, pd * 0.03),
					rnd(rng, -6, 6) + i * 9
				)
			end
		end
		peak(0, 0, w * 0.62, d * 0.8, h, 7)
		peak(-w * 0.3, rnd(rng, -d * 0.1, d * 0.1), w * 0.42, d * 0.55, h * 0.62, 5)
		peak(w * 0.28, rnd(rng, -d * 0.1, d * 0.1), w * 0.36, d * 0.5, h * 0.5, 4)
	end
end

local function flowers(n: number, radius: number, height: number)
	return function(m: Model, rng: Random)
		B.on(m, "LeafDark", V(radius * 1.3, height * 0.45, radius * 1.0), 0, -0.3, 0, rnd(rng, 0, 90))
		if n > 3 then
			B.on(
				m,
				"Leaf",
				V(radius * 0.8, height * 0.3, radius * 0.7),
				rnd(rng, -0.3, 0.3),
				height * 0.15 - 0.3,
				rnd(rng, -0.3, 0.3),
				rnd(rng, 0, 90)
			)
		end
		for i = 1, n do
			local a = i * 360 / n + rnd(rng, -20, 20)
			local r = math.rad(a)
			local d = radius * rnd(rng, 0.25, 0.55)
			B.on(
				m,
				if i % 3 == 0 then "Accent2" else "Accent",
				V(0.9, 0.6, 0.9),
				math.cos(r) * d,
				height * rnd(rng, 0.35, 0.55) - 0.3,
				math.sin(r) * d,
				rnd(rng, 0, 90)
			)
		end
	end
end

local function grass(n: number, height: number)
	return function(m: Model, rng: Random)
		for i = 1, n do
			local a = i * 360 / n + rnd(rng, -20, 20)
			local r = math.rad(a)
			local h = height * rnd(rng, 0.6, 1)
			B.on(
				m,
				if i % 2 == 0 then "Leaf" else "LeafDark",
				V(0.5, h + 0.3, 0.5),
				math.cos(r) * 0.5,
				-0.3,
				math.sin(r) * 0.5,
				a,
				rnd(rng, -14, 14),
				rnd(rng, -14, 14)
			)
		end
	end
end

Nature.recipes = {
	TreeRoundA = layered(16, 12, 2, 3),
	TreeRoundB = layered(14, 11, 1.8, 3),
	TreeRoundC = layered(20, 15, 2.4, 3),
	TreeRoundD = layered(11, 9, 1.5, 2),
	TreeBallA = blobby(15, 10, 1.8, 2),
	TreeBallB = blobby(12, 8, 1.5, 2),
	TreeBallC = blobby(19, 12, 2.2, 3),
	TreeTallA = poplar(20, 7),
	TreeTallB = poplar(15, 6),
	PineA = pine(18, 10, 5, false),
	PineB = pine(25, 12, 6, false),
	PineC = pine(13, 8, 4, false),
	PineSnowA = pine(18, 10, 5, true),
	PineSnowB = pine(24, 12, 6, true),
	BushA = bush(6, 3.6, 5, 0),
	BushB = bush(4.5, 3, 4, 0),
	BushC = bush(8, 4.6, 6, 0),
	BushFlowerA = bush(6, 3.6, 4, 2),
	RockA = rock(6, 4, 5, 1),
	RockB = rock(9, 5.5, 7, 2),
	RockC = rock(4, 3, 3.5, 0),
	RockD = rock(14, 8, 11, 3),
	RockFlat = slabs(9, 7, 2.4, 2),
	SlabA = slabs(10, 8, 6, 3),
	SlabB = slabs(14, 10, 9, 4),
	SlabC = slabs(7, 6, 4, 2),
	BankA = bank(28, 18, 8, 2),
	BankB = bank(28, 14, 5, 1),
	BankC = bank(30, 22, 12, 3),
	BankD = bank(24, 16, 7, 2),
	HillA = hill(60, 50, 16, 4),
	HillB = hill(90, 70, 24, 5),
	HillC = hill(40, 34, 10, 3),
	MountainA = mountain(140, 110, 90, true),
	MountainB = mountain(180, 130, 125, true),
	MountainC = mountain(110, 90, 60, false),
	FlowersA = flowers(3, 1.6, 1.8),
	FlowersB = flowers(4, 2.2, 1.8),
	GrassA = grass(4, 1.8),
	GrassB = grass(3, 1.3),
	Stump = function(m: Model, rng: Random)
		B.round(m, "Trunk", 2.2, 3.4, 0, -0.4, 0)
		B.round(m, "Wood", 0.2, 2.6, 0, 1.8, 0)
		for i = 0, 2 do
			local a = i * 120 + rnd(rng, -20, 20)
			local r = math.rad(a)
			B.on(m, "Trunk", V(0.9, 1, 2), math.cos(r) * 1.8, -0.4, math.sin(r) * 1.8, radial(a))
		end
	end,
	LogA = function(m: Model, rng: Random)
		B.log(m, "Trunk", 8, 2.2, 0, 0.9, 0)
		B.box(m, "Wood", V(0.2, 1.6, 1.6), 4.05, 0.9, 0)
		B.box(m, "Wood", V(0.2, 1.6, 1.6), -4.05, 0.9, 0)
		B.on(m, "Trunk", V(0.6, 1.6, 0.6), 1.2, 1.8, 0, 0, 25)
		B.on(m, "Leaf", V(1, 0.4, 0.8), -1.5, 1.95, 0.2, rnd(rng, 0, 90))
	end,
	MushroomSmallA = function(m: Model, rng: Random)
		B.on(m, "Stem", V(0.7, 2, 0.7), 0, -0.3, 0)
		B.round(m, "Cap", 0.6, 2.4, 0, 1.6, 0, rnd(rng, 0, 45))
		B.on(m, "Cap", V(1.4, 0.5, 1.4), 0, 2.2, 0, 45)
		B.box(m, "Spot", V(0.4, 0.3, 0.4), 0.6, 2.2, 0.2)
	end,
	MushroomSmallB = function(m: Model, rng: Random)
		B.on(m, "Stem", V(0.5, 1.4, 0.5), 0, -0.3, 0)
		B.round(m, "Cap", 0.5, 1.7, 0, 1.0, 0, rnd(rng, 0, 45))
		B.on(m, "Cap", V(1, 0.4, 1), 0, 1.5, 0, 45)
	end,
}

return Nature
