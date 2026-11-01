--!strict
-- Partner A. Classic brick recipes for the hub: the Boxing Sack Shop pieces (striped barrel-vault roof, boxing glove,
-- awning, pillars, arched windows, gym props), the Pet Selling Stand pieces (striped canopy, paw board, carved
-- posts, pet props), the Golden Egg centrepiece fountain, pen fences, lamps,
-- benches and street props, and the village pieces (town houses, gazebo, well, hedges).
-- Asset space: origin = base centre, +Y up, front = -Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Hub = {}

local function rnd(rng: Random, a: number, b: number): number
	return rng:NextNumber(a, b)
end

-- Voxel disc of diameter d and thickness t facing -Z, centred at (x, y, z).
local function disc(m: Model, role: string, d: number, t: number, x: number, y: number, z: number, yaw: number?)
	local cf = CFrame.new(x, y, z) * CFrame.Angles(0, rad(yaw or 0), 0)
	B.at(m, role, V(d * 0.64, d, t), cf)
	B.at(m, role, V(d, d * 0.64, t - 0.02), cf)
	if d >= 6 then
		B.at(m, role, V(d * 0.66, d * 0.66, t - 0.04), cf * CFrame.Angles(0, 0, rad(45)))
	end
end

-- Gable triangle in the YZ plane at x (two wedges back to back): width w along Z, height h, thickness t.
local function gable(m: Model, role: string, x: number, y: number, z: number, w: number, h: number, t: number)
	B.wedge(m, role, V(t, h, w / 2), CFrame.new(x, y + h / 2, z + w / 4) * CFrame.Angles(0, math.pi, 0))
	B.wedge(m, role, V(t, h, w / 2), CFrame.new(x, y + h / 2, z - w / 4))
end

-- Gable roof along X: two wedge slopes meeting at a ridge over z, eaves at z +- depth / 2 at height y.
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
		B.box(m, ridge, V(len + 0.4, 0.6, 1.0), 0, y + rise - 0.15, z) -- sunk into the apex: no slit along the ridge
	end
end

local function egglet(m: Model, role: string, s: number, x: number, y: number, z: number)
	B.on(m, role, V(s, s * 1.15, s), x, y, z)
	B.on(m, role, V(s * 0.66, s * 0.4, s * 0.66), x, y + s * 1.15, z)
end

---------------------------------------------------------------- Boxing Sack Shop

local function shopRoof(m: Model)
	local span, rise, len = 35.4, 8, 29.9
	local Rr = (span * span / 4 + rise * rise) / (2 * rise)
	local cy = rise - Rr
	local a0 = math.atan2(-cy, span / 2)
	-- striped shell, then gold ribs at both ends and two in between
	B.arc(m, "Roof", CFrame.new(0, cy, 0), Rr + 0.45, a0, math.pi - a0, 10, Vector2.new(0.9, len), "Roof2")
	for _, z in { -len / 2 - 0.3, -len / 6, len / 6, len / 2 + 0.3 } do
		B.arc(m, "Trim", CFrame.new(0, cy, z), Rr + 1.05, a0 - 0.02, math.pi - a0 + 0.02, 10, Vector2.new(1.1, 1.2))
	end
	for _, s in { -1, 1 } do
		B.box(m, "Trim", V(1.4, 1.3, len + 2.6), s * (span / 2 + 0.3), 0.3, 0)
	end
	-- both gables closed exactly: under each of the shell's segments a block down to the base and a wedge for its
	-- slope, their edges inside the shell, so no sky shows between the infill and the roof; a round glowing window
	-- with a cross at each end
	local R, segs = Rr + 0.45, 10
	local step = (math.pi - 2 * a0) / segs
	for _, s in { -1, 1 } do
		local z = s * (len / 2 - 0.6)
		for k = 0, segs - 1 do
			local ta, tb = a0 + k * step, a0 + (k + 1) * step
			local xa, ya = R * math.cos(ta), cy + R * math.sin(ta)
			local xb, yb = R * math.cos(tb), cy + R * math.sin(tb)
			local x0, x1 = math.min(xa, xb), math.max(xa, xb)
			local lo, hi = math.min(ya, yb), math.max(ya, yb)
			if lo > 0.05 then
				B.box(m, "WallTop", V(x1 - x0, lo, 0.8), (x0 + x1) / 2, lo / 2, z)
			end
			if hi - lo > 0.05 then
				-- the wedge's high edge (+Z) points at the higher end of the segment
				local toward = if (if ya > yb then xa else xb) > (x0 + x1) / 2 then 1 else -1
				B.wedge(
					m,
					"WallTop",
					V(0.8, hi - lo, x1 - x0),
					CFrame.fromMatrix(
						Vector3.new((x0 + x1) / 2, (lo + hi) / 2, z),
						Vector3.new(0, 0, -toward),
						Vector3.yAxis
					)
				)
			end
		end
		disc(m, "Trim", 6.2, 0.7, 0, rise * 0.5, s * (len / 2 - 0.05))
		disc(m, "Glow", 4.8, 0.76, 0, rise * 0.5, s * (len / 2 - 0.02))
		B.box(m, "Trim", V(4.8, 0.4, 0.3), 0, rise * 0.5, s * (len / 2 + 0.42))
		B.box(m, "Trim", V(0.4, 4.8, 0.3), 0, rise * 0.5, s * (len / 2 + 0.42))
	end
	-- ridge crest with a glow strip
	B.on(m, "Trim", V(3.2, 1.0, len * 0.55), 0, rise + 0.6, 0)
	B.on(m, "Glow", V(2.2, 0.5, len * 0.5), 0, rise + 1.6, 0)
end

local function glove(m: Model)
	B.round(m, "Cloth", 2.6, 3.8, 0, 0, 0.3)
	B.round(m, "Trim", 0.5, 4.0, 0, -0.1, 0.3)
	B.round(m, "Cloth2", 0.6, 4.05, 0, 1.3, 0.3)
	B.round(m, "Cloth2", 0.8, 4.7, 0, 2.5, 0.2)
	B.blob(m, "Cloth", 6.0, 5.8, 5.4, 0, 5.8, 0)
	B.box(m, "Cloth", V(5.2, 2.6, 2.8), 0, 7.3, -1.9, 0, 25, 0)
	B.box(m, "Cloth", V(1.9, 3.4, 2.3), 2.8, 4.8, -1.5, 0, 20, -25)
	B.box(m, "Cloth2", V(3.2, 0.5, 0.4), 0, 7.9, -3.4, 0, 25, 0)
	for i = 0, 2 do
		B.box(m, "Dark", V(1.4, 0.25, 0.3), 0, 0.8 + i * 0.6, 2.25, 0, 0, if i % 2 == 0 then 20 else -20)
	end
end

local function awning(m: Model)
	local width, depth, drop, stripes, tabs = 26.4, 5.5, 2, 8, 10
	local pitch = -math.deg(math.atan2(drop, depth))
	local sw = width / stripes
	local ln = math.sqrt(depth * depth + drop * drop)
	for i = 0, stripes - 1 do
		B.box(
			m,
			if i % 2 == 0 then "Cloth" else "Cloth2",
			V(sw + 0.01, 0.35, ln),
			-width / 2 + (i + 0.5) * sw,
			-drop / 2,
			-depth / 2,
			0,
			pitch,
			0
		)
	end
	local tw = width / tabs
	for i = 0, tabs - 1 do
		B.box(
			m,
			if i % 2 == 0 then "Cloth" else "Cloth2",
			V(tw - 0.15, 1.1, 0.3),
			-width / 2 + (i + 0.5) * tw,
			-drop - 0.55,
			-depth - 0.05
		)
	end
	B.box(m, "Trim", V(width + 0.4, 0.4, 0.5), 0, -drop + 0.1, -depth - 0.05)
end

local function pillar(m: Model)
	local h, w = 12.3, 2.4
	B.on(m, "StoneDark", V(w * 1.45, 1.3, w * 1.45), 0, -0.3, 0)
	B.on(m, "Stone", V(w * 1.2, 0.6, w * 1.2), 0, 1.0, 0)
	B.on(m, "Wall", V(w, h - 3.2, w), 0, 1.6, 0)
	B.on(m, "Trim", V(w * 1.12, 0.6, w * 1.12), 0, h * 0.42, 0)
	B.on(m, "Stone", V(w * 1.25, 0.7, w * 1.25), 0, h - 1.8, 0)
	B.on(m, "Trim", V(w * 1.45, 1.1, w * 1.45), 0, h - 1.1, 0)
end

local function window(m: Model)
	local w, h = 6, 7
	B.on(m, "Trim", V(w + 1.4, 0.6, 1.2), 0, -0.2, -0.2)
	B.on(m, "Glass", V(w - 0.4, h - w / 2, 0.3), 0, 0.4, 0.1)
	disc(m, "Glass", w - 0.6, 0.3, 0, 0.4 + h - w / 2, 0.25)
	for _, s in { -1, 1 } do
		B.on(m, "Trim", V(0.7, h - w / 2, 0.8), s * w / 2, 0.4, -0.05)
	end
	B.arc(m, "Trim", CFrame.new(0, 0.4 + h - w / 2, -0.05), w / 2, 0, math.pi, 6, Vector2.new(0.7, 0.8))
	B.on(m, "Trim", V(0.3, h - 0.4, 0.5), 0, 0.4, -0.15)
	B.box(m, "Trim", V(w - 0.4, 0.3, 0.5), 0, 0.4 + (h - w / 2) * 0.55, -0.15)
end

local function dumbbellRack(m: Model)
	local len = 7
	for _, s in { -1, 1 } do
		B.on(m, "Metal", V(0.5, 3.3, 2.2), s * len / 2, -0.3, 0)
	end
	for k, y in { 1.2, 2.5 } do
		B.box(m, "Metal", V(len + 0.5, 0.25, 1.8), 0, y, 0, 0, 14, 0)
		for i = 0, 2 do
			local x = -len / 2 + 1.4 + i * (len - 2.8) / 2
			local s = 1 - 0.1 * (i + k - 1)
			for _, e in { -0.7, 0.7 } do
				B.box(m, "Dark", V(0.4, 1.1 * s, 1.1 * s), x + e, y + 0.65, 0)
			end
			B.box(m, "Metal", V(1.4, 0.25, 0.25), x, y + 0.65, 0)
		end
	end
end

local function tireStack(m: Model, rng: Random)
	local y = -0.2
	for _ = 1, 3 do
		local ox, oz = rnd(rng, -0.25, 0.25), rnd(rng, -0.25, 0.25)
		B.round(m, "Dark", 0.95, 3.8, ox, y, oz, rnd(rng, 0, 40))
		y += 0.95
	end
	B.round(m, "StoneDark", 0.06, 2.0, 0, y, 0)
end

local function speedBag(m: Model)
	B.on(m, "WoodDark", V(3, 3, 0.4), 0, 0, 0.6)
	B.box(m, "Metal", V(0.35, 0.35, 2.4), 0, 2.6, -0.6)
	B.round(m, "Wood", 0.4, 4.0, 0, 2.65, -1.5)
	B.box(m, "Metal", V(0.2, 0.5, 0.2), 0, 2.4, -1.5)
	B.blob(m, "Cloth", 1.4, 2.0, 1.4, 0, 1.2, -1.5)
end

---------------------------------------------------------------- Pet Selling Stand

local function standCanopy(m: Model)
	local width, depth, rise, stripes = 22, 16, 4.5, 10
	local ang = math.deg(math.atan2(rise, depth / 2))
	local ln = math.sqrt(rise * rise + depth * depth / 4)
	local sw = width / stripes
	for _, side in { -1, 1 } do
		for i = 0, stripes - 1 do
			local role = if (i + (if side > 0 then 1 else 0)) % 2 == 0 then "Cloth" else "Cloth2"
			B.box(
				m,
				role,
				V(sw + 0.01, 0.35, ln + 0.6),
				-width / 2 + (i + 0.5) * sw,
				rise / 2 + 0.1,
				side * depth / 4,
				0,
				side * ang,
				0
			)
		end
		local tabs = 11
		local tw = (width + 0.6) / tabs
		for i = 0, tabs - 1 do
			B.box(
				m,
				if i % 2 == 0 then "Cloth" else "Cloth2",
				V(tw - 0.15, 1.0, 0.3),
				-width / 2 - 0.3 + (i + 0.5) * tw,
				-0.45,
				side * (depth / 2 + 0.35)
			)
		end
		B.box(m, "Trim", V(width + 0.8, 0.5, 0.35), 0, 0.05, side * (depth / 2 + 0.3))
	end
	for _, sx in { -1, 1 } do
		gable(m, "WallTop", sx * (width / 2 + 0.05), 0.05, 0, depth, rise, 0.4)
		B.on(m, "Gold", V(0.9, 1.2, 0.9), sx * (width / 2 + 0.6), rise + 0.1, 0)
	end
	B.box(m, "Trim", V(width + 1.4, 0.8, 0.8), 0, rise + 0.3, 0)
end

local function pawSign(m: Model)
	B.on(m, "WoodDark", V(0.8, 1.8, 0.8), 0, -0.4, 0)
	disc(m, "Trim", 7.6, 0.4, 0, 4.2, 0.45)
	disc(m, "Wood", 6.8, 0.7, 0, 4.2, 0.1)
	disc(m, "Accent2", 2.4, 0.4, 0, 3.6, -0.35)
	for _, p in { { -1.35, 1.25 }, { -0.5, 1.95 }, { 0.5, 1.95 }, { 1.35, 1.25 } } do
		B.box(m, "Accent2", V(1.0, 1.0, 0.4), p[1], 3.6 + p[2] - 0.2, -0.35)
	end
end

local function standPost(m: Model)
	local h, w = 11.4, 1.5
	B.on(m, "StoneDark", V(w * 1.6, 1.2, w * 1.6), 0, -0.3, 0)
	B.on(m, "Wood", V(w, h - 0.9, w), 0, 0.9, 0)
	for _, y in { h * 0.35, h * 0.7 } do
		B.on(m, "WoodDark", V(w * 1.2, 0.4, w * 1.2), 0, y, 0)
	end
	B.on(m, "Trim", V(w * 1.35, 0.6, w * 1.35), 0, h - 0.5, 0)
end

local function eggCrate(m: Model)
	B.on(m, "Wood", V(4, 1.4, 3), 0, -0.2, 0)
	B.on(m, "WoodDark", V(4.15, 0.25, 3.15), 0, 1.1, 0)
	B.on(m, "Cloth2", V(3.6, 0.2, 2.6), 0, 1.1, 0)
	local roles = { "Accent", "Accent2", "Gold", "Accent3", "Accent", "Gold" }
	for i = 0, 5 do
		egglet(m, roles[i + 1], 0.85, -1.3 + (i % 3) * 1.3, 1.3, if i < 3 then -0.65 else 0.65)
	end
end

local function bunting(m: Model)
	local length, sag, flags = 20.1, 1.2, 12
	local roles = { "Accent", "Accent2", "Gold", "Accent3" }
	for i = 0, flags - 1 do
		local t = (i + 0.5) / flags
		local x = -length / 2 + t * length
		local y = -sag * math.sin(math.pi * t)
		B.wedge(
			m,
			roles[i % 4 + 1],
			V(0.12, 1.3, 1.1),
			CFrame.new(x, y - 0.65, 0) * CFrame.Angles(0, rad(90), 0) * CFrame.Angles(math.pi, 0, 0)
		)
	end
	local segs = 6
	for k = 0, segs - 1 do
		local t0, t1 = k / segs, (k + 1) / segs
		local x0, x1 = -length / 2 + t0 * length, -length / 2 + t1 * length
		local y0, y1 = -sag * math.sin(math.pi * t0), -sag * math.sin(math.pi * t1)
		B.box(
			m,
			"Dark",
			V(math.sqrt((x1 - x0) ^ 2 + (y1 - y0) ^ 2) + 0.05, 0.12, 0.12),
			(x0 + x1) / 2,
			(y0 + y1) / 2 + 0.06,
			0,
			0,
			0,
			math.deg(math.atan2(y1 - y0, x1 - x0))
		)
	end
end

---------------------------------------------------------------- plaza and launch pieces

-- The Golden Egg centrepiece: an octagonal pool with posts and little eggs, two tiered basins on pedestals and a
-- giant golden voxel egg in a cracked white shell, crowned with a glowing gem.
local function centrepiece(m: Model, rng: Random)
	local R = 15.5
	local seg = 2 * R * math.tan(math.pi / 8) + 0.6
	for i = 0, 7 do
		local a = i * 45
		local r = math.rad(a)
		local x, z = math.cos(r) * R, math.sin(r) * R
		B.on(m, "Stone", V(1.6, 2.2, seg), x, -0.2, z, -a)
		B.on(m, "Trim", V(2.2, 0.5, seg + 0.4), x, 2.0, z, -a)
		local pa = math.rad(a + 22.5)
		local px, pz = math.cos(pa) * (R + 0.2), math.sin(pa) * (R + 0.2)
		B.on(m, "StoneDark", V(2.4, 3.2, 2.4), px, -0.2, pz, -a)
		if i % 2 == 0 then
			egglet(m, ({ "Accent", "Accent2", "Accent3", "Gold" })[i // 2 + 1], 1.4, px, 3.0, pz)
		else
			B.on(m, "Gold", V(1.4, 1.4, 1.4), px, 3.0, pz, 45)
		end
	end
	B.round(m, "StoneDark", 0.6, 2 * R - 1, 0, -0.4, 0)
	B.round(m, "Water", 0.35, 2 * R - 2, 0, 1.2, 0)
	-- tier 1
	B.round(m, "Stone", 4.4, 8.6, 0, 0.2, 0, 22.5)
	B.round(m, "Trim", 0.6, 9.6, 0, 4.0, 0, 22.5)
	B.round(m, "StoneDark", 1.2, 17, 0, 4.6, 0)
	B.round(m, "Trim", 0.45, 18, 0, 5.75, 0)
	B.round(m, "Water", 0.25, 15.6, 0, 5.62, 0)
	-- tier 2
	B.round(m, "Stone", 4.0, 5.8, 0, 5.8, 0, 22.5)
	B.round(m, "StoneDark", 1.0, 10.4, 0, 9.6, 0)
	B.round(m, "Trim", 0.4, 11.2, 0, 10.55, 0)
	B.round(m, "Water", 0.25, 9.2, 0, 10.42, 0)
	-- the golden egg in its cracked shell
	for i = 0, 7 do
		local a = i * 45 + rnd(rng, -8, 8)
		local r = math.rad(a)
		B.on(
			m,
			"Spot",
			V(1.6, rnd(rng, 2.2, 3.6), 0.6),
			math.cos(r) * 3.6,
			10.6,
			math.sin(r) * 3.6,
			90 - a,
			rnd(rng, -14, -6),
			0
		)
	end
	B.egg(m, "Gold", 8.6, 11.5, 0, 10.6, 0)
	B.round(m, "Accent2", 0.9, 8.9, 0, 14.3, 0, 22.5)
	B.round(m, "Accent", 0.6, 8.0, 0, 16.4, 0, 10)
	B.on(m, "Glow", V(1.4, 1.4, 1.4), 0, 21.6, 0, 45)
	for i = 0, 3 do
		local r = math.rad(i * 90 + 45)
		B.on(m, "Gold", V(0.9, 1.2, 0.9), math.cos(r) * 1.3, 21.2, math.sin(r) * 1.3, 45)
	end
end

---------------------------------------------------------------- fences, lamps, street props

local function post(h: number, w: number)
	return function(m: Model)
		B.on(m, "Wood", V(w, h + 0.4, w), 0, -0.4, 0)
		B.on(m, "Trim", V(w * 1.35, 0.6, w * 1.35), 0, h, 0)
	end
end

local function lampPost(m: Model)
	local h = 10
	B.on(m, "StoneDark", V(2, 1.1, 2), 0, -0.4, 0)
	B.on(m, "Metal", V(0.6, h - 2.9, 0.6), 0, 0.7, 0)
	B.on(m, "Metal", V(1.5, 0.3, 1.5), 0, h - 2.6, 0)
	B.on(m, "Glow", V(1.1, 1.6, 1.1), 0, h - 2.3, 0)
	B.on(m, "Roof", V(2.0, 0.6, 2.0), 0, h - 0.7, 0)
	B.on(m, "Roof", V(1.2, 0.5, 1.2), 0, h - 0.1, 0, 45)
end

local function bench(m: Model)
	local len = 6
	for _, s in { -1, 1 } do
		B.on(m, "Metal", V(0.5, 1.6, 1.9), s * (len / 2 - 0.7), -0.3, 0)
		B.on(m, "Metal", V(0.4, 1.9, 0.4), s * (len / 2 - 0.7), 1.3, 0.75, 0, -8, 0)
	end
	for i = 0, 2 do
		B.on(m, "Wood", V(len, 0.3, 0.5), 0, 1.3, -0.6 + i * 0.6)
	end
	for i = 0, 1 do
		B.box(m, "Wood", V(len, 0.5, 0.25), 0, 2.4 + i * 0.7, 0.95, 0, -8, 0)
	end
end

local function lantern(m: Model)
	B.on(m, "Metal", V(1.1, 0.25, 1.1), 0, 0, 0)
	B.on(m, "Glow", V(0.8, 1.2, 0.8), 0, 0.25, 0)
	B.on(m, "Metal", V(0.16, 1.2, 0.16), 0.45, 0.25, 0.45)
	B.on(m, "Metal", V(0.16, 1.2, 0.16), -0.45, 0.25, -0.45)
	B.on(m, "Metal", V(1.2, 0.4, 1.2), 0, 1.45, 0)
	B.on(m, "Metal", V(0.6, 0.4, 0.6), 0, 1.85, 0, 45)
end

local function signpost(m: Model)
	local h = 6.5
	B.on(m, "Wood", V(0.7, h + 0.5, 0.7), 0, -0.5, 0)
	B.on(m, "WoodDark", V(0.95, 0.35, 0.95), 0, h, 0)
	for i, s in { 1, -1 } do
		local y = h - 1.0 - (i - 1) * 1.5
		B.box(m, "Trim", V(3.4, 1.0, 0.25), s * 1.9, y, 0, 0, 0, s * 4)
		B.box(m, "Trim", V(0.8, 0.8, 0.25), s * 3.7, y, 0, 0, 0, 45)
	end
end

local function flagPole(m: Model)
	local h = 12
	B.on(m, "StoneDark", V(1.8, 1, 1.8), 0, -0.4, 0)
	B.on(m, "Metal", V(0.4, h, 0.4), 0, 0.6, 0)
	B.on(m, "Gold", V(0.8, 0.8, 0.8), 0, h + 0.6, 0, 45)
	for i = 0, 3 do
		B.box(
			m,
			if i % 2 == 0 then "Cloth" else "Cloth2",
			V(1.02, 2.6, 0.18),
			0.8 + i,
			h - 1.3,
			0.15 * math.sin(i * 1.4),
			0,
			12 * math.cos(i * 1.4),
			0
		)
	end
end

local function plankBridge(m: Model, rng: Random)
	local length, width, arch = 16, 7, 1.6
	local n = 12
	for i = 0, n - 1 do
		local t = (i + 0.5) / n
		local z = -length / 2 + t * length
		local y = arch * math.sin(math.pi * t)
		local slope = math.deg(math.atan(arch * math.pi / length * math.cos(math.pi * t)))
		B.box(
			m,
			if i % 3 == 0 then "WoodDark" else "Wood",
			V(width * rnd(rng, 0.96, 1.02), 0.4, 1.3),
			0,
			y + 0.3,
			z,
			rnd(rng, -1.5, 1.5),
			-slope,
			0
		)
	end
	for _, s in { -1, 1 } do
		for k = 0, 4 do
			local t = k / 4
			local z = -length / 2 + t * length
			local y = arch * math.sin(math.pi * t)
			B.on(m, "WoodDark", V(0.6, 3.2, 0.6), s * width * 0.47, y - 0.6, z)
		end
		for k = 0, 3 do
			local t0, t1 = k / 4, (k + 1) / 4
			local z0, z1 = -length / 2 + t0 * length, -length / 2 + t1 * length
			local y0, y1 = arch * math.sin(math.pi * t0) + 2.5, arch * math.sin(math.pi * t1) + 2.5
			local len = math.sqrt((z1 - z0) ^ 2 + (y1 - y0) ^ 2)
			B.box(
				m,
				"Wood",
				V(0.4, 0.4, len + 0.4),
				s * width * 0.47,
				(y0 + y1) / 2,
				(z0 + z1) / 2,
				0,
				-math.deg(math.atan2(y1 - y0, z1 - z0)),
				0
			)
		end
	end
end

---------------------------------------------------------------- village pieces (decor only)

local function townHouse(m: Model, rng: Random)
	local W, D = 14, 12
	B.on(m, "StoneDark", V(W + 1, 1, D + 1), 0, -0.4, 0)
	B.on(m, "Wall", V(W, 7, D), 0, 0.6, 0)
	B.on(m, "Trim", V(W + 0.3, 0.7, D + 0.3), 0, 7.6, 0)
	B.on(m, "WallTop", V(W, 6, D), 0, 8.3, 0)
	-- timber frame on the upper floor front
	for _, x in { -W / 2 + 0.4, -2.3, 2.3, W / 2 - 0.4 } do
		B.on(m, "WoodDark", V(0.6, 6, 0.4), x, 8.3, -D / 2 - 0.1)
	end
	B.box(m, "WoodDark", V(W, 0.5, 0.4), 0, 11.3, -D / 2 - 0.12)
	-- door, step, lamp
	B.on(m, "WoodDark", V(3, 5, 0.5), -2.6, 0.6, -D / 2 - 0.1)
	B.on(m, "Trim", V(3.8, 0.6, 0.7), -2.6, 5.6, -D / 2 - 0.15)
	B.on(m, "Stone", V(4, 0.5, 1.6), -2.6, 0.1, -D / 2 - 0.9)
	B.on(m, "Glow", V(0.6, 0.8, 0.6), -0.4, 4.4, -D / 2 - 0.4)
	-- windows: one big one downstairs with shutters, three upstairs with flower boxes
	B.on(m, "Glass", V(3.2, 3, 0.3), 3.4, 2.8, -D / 2 - 0.05)
	B.on(m, "Trim", V(3.8, 0.5, 0.8), 3.4, 2.4, -D / 2 - 0.2)
	for _, s in { -1, 1 } do
		B.on(m, "Accent", V(0.8, 3, 0.3), 3.4 + s * 2.1, 2.8, -D / 2 - 0.15)
	end
	for _, x in { -4.6, 0, 4.6 } do
		B.on(m, "Glass", V(2.2, 2.4, 0.3), x, 9.4, -D / 2 - 0.05)
		B.on(m, "Wood", V(2.8, 0.7, 0.9), x, 8.8, -D / 2 - 0.45)
		B.on(m, if rng:NextNumber() < 0.5 then "Accent2" else "Gold", V(2.4, 0.5, 0.5), x, 9.5, -D / 2 - 0.45)
	end
	-- roof: gable with wedges, infill triangles, ridge, chimney
	roof(m, "Roof", W + 1.6, D + 1.6, 6, 14.3, 0, "RoofDark")
	for _, s in { -1, 1 } do
		gable(m, "WallTop", s * (W / 2 - 0.2), 14.3, 0, D, 5.6, 0.4)
	end
	B.on(m, "Stone", V(2, 6.5, 2), W * 0.28, 15, 2.4)
	B.on(m, "StoneDark", V(2.6, 0.7, 2.6), W * 0.28, 21.5, 2.4)
end

local function tallHouse(m: Model, rng: Random)
	local W, D = 10, 10
	B.on(m, "StoneDark", V(W + 1, 1, D + 1), 0, -0.4, 0)
	B.on(m, "Wall", V(W, 16, D), 0, 0.6, 0)
	for _, y in { 6, 11.2 } do
		B.on(m, "Trim", V(W + 0.3, 0.5, D + 0.3), 0, y, 0)
	end
	-- stepped (Dutch) gable front, in the wall colour with trim caps
	for i = 0, 3 do
		local w = W - i * 2.4
		B.on(m, "Wall", V(w, 1.6, 1.2), 0, 16.6 + i * 1.6, -D / 2 + 0.6)
		B.on(m, "Trim", V(w + 0.4, 0.35, 1.4), 0, 18.2 + i * 1.6, -D / 2 + 0.6)
	end
	roof(m, "Roof", W - 1.2, D + 0.8, 5.2, 16.6, 0.6, "RoofDark")
	B.on(m, "WoodDark", V(2.8, 4.8, 0.5), 0, 0.6, -D / 2 - 0.1)
	B.on(m, "Accent", V(4, 0.4, 1.8), 0, 5.6, -D / 2 - 0.9, 0, 10, 0)
	for row = 0, 1 do
		for _, x in { -2.6, 2.6 } do
			local y = 7 + row * 5
			B.on(m, "Glass", V(2.2, 3, 0.3), x, y, -D / 2 - 0.05)
			B.on(m, "Trim", V(2.8, 0.45, 0.7), x, y - 0.3, -D / 2 - 0.2)
		end
	end
	B.on(m, "Glass", V(2.4, 2.4, 0.3), 0, 17.4, -D / 2 - 0.05)
	B.on(m, "Gold", V(0.6, 1.2, 0.6), 0, 23.2, -D / 2 + 0.6, 45)
	if rng:NextNumber() < 0.5 then
		B.on(m, "Accent2", V(3.4, 0.5, 0.6), 2.6, 7.4, -D / 2 - 0.5)
	end
end

local function gazebo(m: Model)
	B.round(m, "Stone", 1.0, 15, 0, -0.4, 0, 22.5)
	B.round(m, "Trim", 0.3, 13.6, 0, 0.6, 0, 22.5)
	for i = 0, 7 do
		local r = math.rad(i * 45 + 22.5)
		local x, z = math.cos(r) * 6.2, math.sin(r) * 6.2
		B.on(m, "Wood", V(0.8, 8, 0.8), x, 0.6, z)
		if i ~= 6 then -- the entrance (toward -Z) stays open
			local r2 = math.rad(i * 45 + 45)
			B.on(m, "Trim", V(0.4, 0.4, 4.6), math.cos(r2) * 5.75, 2.4, math.sin(r2) * 5.75, -(i * 45 + 45))
		end
	end
	B.stack(m, "Roof", 17, 3, 5, 5, 0, 8.6, 0, 22.5, "Roof2")
	B.on(m, "Gold", V(0.8, 2, 0.8), 0, 13.6, 0, 45)
end

local function well(m: Model)
	B.round(m, "Stone", 2.6, 5.4, 0, -0.4, 0)
	B.round(m, "StoneDark", 0.4, 5.8, 0, 2.2, 0)
	B.round(m, "Water", 0.1, 3.6, 0, 2.25, 0)
	for _, s in { -1, 1 } do
		B.on(m, "Wood", V(0.6, 5, 0.6), s * 2.4, 2.2, 0)
	end
	B.log(m, "WoodDark", 4.4, 0.6, 0, 5.2, 0)
	roof(m, "Roof", 6.2, 5.2, 2, 7.2, 0, "RoofDark")
	B.on(m, "WoodDark", V(0.4, 1.4, 0.4), 0, 3.8, 0)
end

local function hedge(m: Model, rng: Random)
	B.on(m, "LeafDark", V(8, 2.6, 2.2), 0, -0.3, 0)
	B.on(m, "Leaf", V(7.6, 0.6, 1.8), 0, 2.3, 0)
	B.on(m, "Leaf", V(2.4, 1, 2.4), rnd(rng, -2.5, 2.5), 2.5, 0, rnd(rng, 0, 30))
end

Hub.recipes = {
	ShopRoof = shopRoof,
	BoxingGlove = glove,
	GloveSmall = function(m: Model)
		B.blob(m, "Cloth", 1.5, 1.4, 1.4, 0, 0.9, 0)
		B.on(m, "Cloth2", V(1.0, 0.5, 1.0), 0, -0.1, 0)
	end,
	ShopAwning = awning,
	ShopPillar = pillar,
	ShopWindow = window,
	DumbbellRack = dumbbellRack,
	TireStack = tireStack,
	SpeedBag = speedBag,
	StandCanopy = standCanopy,
	PawSign = pawSign,
	StandPost = standPost,
	EggCrate = eggCrate,
	PetBed = function(m: Model)
		B.round(m, "Cloth", 1.0, 4.4, 0, -0.2, 0)
		B.round(m, "Cloth2", 0.3, 3.2, 0, 0.8, 0)
	end,
	PetCarrier = function(m: Model)
		B.on(m, "Accent", V(3.2, 2.4, 2.4), 0, -0.2, 0)
		B.on(m, "Dark", V(2, 1.6, 0.1), 0, 0.3, -1.25)
		for i = 0, 3 do
			B.on(m, "Metal", V(0.15, 1.6, 0.15), -0.75 + i * 0.5, 0.3, -1.32)
		end
		B.on(m, "Metal", V(2, 0.3, 0.4), 0, 2.5, 0)
	end,
	Chalkboard = function(m: Model)
		for _, s in { -1, 1 } do
			B.box(m, "Wood", V(0.3, 4, 0.3), s * 1.3, 1.9, -0.4, 0, -10, 0)
			B.box(m, "Wood", V(0.3, 4, 0.3), s * 1.3, 1.9, 0.4, 0, 10, 0)
		end
		B.box(m, "Wood", V(2.95, 2.95, 0.12), 0, 2.4, -0.56, 0, -10, 0)
		B.box(m, "Sign", V(2.6, 2.6, 0.15), 0, 2.4, -0.62, 0, -10, 0)
	end,
	Bunting = bunting,
	EggCenterpiece = centrepiece,
	FencePost = post(4.2, 1.2),
	GatePost = post(6.5, 1.7),
	FenceRail = function(m: Model)
		for i = 0, 1 do
			B.box(m, "Wood", V(8, 0.6, 0.45), 0, 4.2 * (0.32 + 0.38 * i), 0)
		end
	end,
	PicketRail = function(m: Model)
		B.box(m, "Wood", V(8, 0.45, 0.3), 0, 1.2, 0.05)
		B.box(m, "Wood", V(8, 0.45, 0.3), 0, 2.5, 0.05)
		for i = 0, 3 do
			B.on(m, "Wall", V(0.8, 3.4, 0.22), -4 + (i + 0.5) * 8 / 4, -0.3, -0.15)
		end
	end,
	LampPost = lampPost,
	Bench = bench,
	Crate = function(m: Model)
		B.on(m, "Wood", V(3, 3, 3), 0, -0.2, 0)
		for _, y in { -0.2, 2.42 } do
			B.on(m, "WoodDark", V(3.12, 0.38, 3.12), 0, y, 0)
		end
		B.box(m, "WoodDark", V(0.12, 3.6, 0.5), 1.53, 1.3, 0, 0, 0, 45)
	end,
	Barrel = function(m: Model)
		B.round(m, "Wood", 3.6, 2.8, 0, -0.2, 0)
		for _, y in { 0.4, 2.6 } do
			B.round(m, "Metal", 0.35, 2.95, 0, y, 0)
		end
		B.round(m, "WoodDark", 0.1, 2.3, 0, 3.4, 0)
	end,
	Lantern = lantern,
	Signpost = signpost,
	Planter = function(m: Model)
		B.on(m, "Wood", V(6, 2.1, 3), 0, -0.3, 0)
		B.on(m, "WoodDark", V(6.3, 0.35, 3.3), 0, 1.6, 0)
		B.on(m, "Dirt", V(5.4, 0.2, 2.4), 0, 1.7, 0)
	end,
	FlagPole = flagPole,
	PlankBridge = plankBridge,
	TownHouseA = townHouse,
	TownHouseB = tallHouse,
	Gazebo = gazebo,
	Well = well,
	Hedge = hedge,
}

return Hub
