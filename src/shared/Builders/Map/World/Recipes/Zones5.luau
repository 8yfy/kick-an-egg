--!strict
-- Partner A. Classic brick recipes for batch 5 zones: Galaxy Void (Ringed Planet landmark, cosmic portal,
-- meteors, celestial crystals, star lamps, floating void platforms) and Rainbow Heaven (Rainbow Palace landmark,
-- rainbow arc, cloud pavilion, the Golden Egg trophy, the Heaven Gate end colonnade, golden lamps).
-- Asset space: origin = base centre, +Y up, front = -Z. Wedges rise toward their local +Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Zones5 = {}

local function rnd(rng: Random, a: number, b: number): number
	return rng:NextNumber(a, b)
end

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

---------------------------------------------------------------- Galaxy Void

-- A ringed planet (origin = its centre): a voxel ball of stacked rounds in two tones and a tilted ring of blocks.
local function ringedPlanet(m: Model, rng: Random)
	local r = 18
	local layers = { 0.45, 0.78, 0.94, 1.0, 0.94, 0.78, 0.45 }
	local lh = 2 * r / #layers
	for i, f in layers do
		B.round(m, if i % 2 == 0 then "Planet" else "Planet2", lh + 0.05, 2 * r * f, 0, -r + (i - 1) * lh, 0, i * 13)
	end
	local tilt = CFrame.Angles(rad(18), 0, rad(-12))
	for i = 0, 23 do
		local a = rad(i * 15)
		B.at(
			m,
			if i % 3 == 0 then "Glow" else "Ring",
			V(7.4, 1, 3.4),
			tilt * CFrame.Angles(0, a, 0) * CFrame.new(r + 8, 0, 0) * CFrame.Angles(0, rad(90), 0)
		)
	end
	-- a little moon
	B.blob(m, "Moon", 6, 6, 6, r + 16, r * 0.6, 6, rnd(rng, 0, 45))
end

local function cosmicPortal(m: Model)
	B.on(m, "StoneDark", V(18, 2, 8), 0, -0.5, 0)
	B.on(m, "Stone", V(14, 1.4, 6), 0, 1.5, 0)
	local c = CFrame.new(0, 13, 0)
	for i = 0, 15 do
		local a = rad(i * 22.5)
		B.at(
			m,
			if i % 2 == 0 then "Stone" else "Glow",
			V(2.4, 4.4, 3),
			c * CFrame.Angles(0, 0, a) * CFrame.new(0, 10, 0)
		)
	end
	-- the swirling energy inside: concentric translucent discs
	for k, d in { 17, 11, 5 } do
		local cf = c * CFrame.Angles(0, 0, rad(k * 20))
		B.at(m, if k == 2 then "Energy2" else "Energy", V(d * 0.64, d, 0.4 + k * 0.1), cf)
		B.at(m, if k == 2 then "Energy2" else "Energy", V(d, d * 0.64, 0.38 + k * 0.1), cf)
	end
end

local function meteor(m: Model, rng: Random)
	B.blob(m, "Stone", 8, 7, 7.4, 0, 0, 0, rnd(rng, 0, 90))
	B.blob(m, "StoneDark", 5, 4.6, 5, rnd(rng, -2, 2), rnd(rng, 1, 2.6), rnd(rng, -2, 2), rnd(rng, 0, 90))
	for i = 0, 2 do
		B.box(m, "Glow", V(rnd(rng, 3, 6), 0.4, 0.5), 0, rnd(rng, -2, 2), -3.6, 0, 0, rnd(rng, 0, 180))
	end
	-- a short burning trail behind
	B.box(m, "Energy", V(2.6, 2.6, 8), 0, 0, 7, 0, 0, 45)
end

local function celestialCrystal(m: Model, rng: Random)
	B.on(m, "StoneDark", V(6, 1.4, 6), 0, -0.4, 0, 45)
	for i = 0, 3 do
		local a = i * 90 + rnd(rng, -20, 20)
		local r = rad(a)
		local d = if i == 0 then 0 else 1.6
		crystal(
			m,
			if i == 2 then "Glow" else "Crystal",
			rnd(rng, 1.6, 2.6),
			rnd(rng, 5, 12) * (if i == 0 then 1.4 else 1),
			math.cos(r) * d,
			0.6,
			math.sin(r) * d,
			-math.sin(r) * 16,
			math.cos(r) * 16,
			rnd(rng, 0, 90)
		)
	end
end

local function starLamp(m: Model)
	B.on(m, "StoneDark", V(2, 0.8, 2), 0, -0.4, 0)
	B.on(m, "Metal", V(0.5, 8, 0.5), 0, 0.4, 0)
	B.box(m, "Glow", V(2, 2, 0.6), 0, 9.6, 0, 0, 0, 45)
	B.box(m, "Glow", V(1.2, 3, 0.5), 0, 9.6, 0)
	B.box(m, "Glow", V(3, 1.2, 0.5), 0, 9.6, 0)
end

local function voidPlatform(m: Model, rng: Random)
	B.on(m, "Stone", V(16, 1.6, 14), 0, -1.6, 0, rnd(rng, 0, 30))
	B.on(m, "Ring", V(16.4, 0.3, 14.4), 0, -0.25, 0, 0)
	local y = -1.6
	local s = 1
	for k = 0, 3 do
		s *= 0.72
		B.on(
			m,
			if k % 2 == 0 then "StoneDark" else "Stone",
			V(16 * s, 3, 14 * s),
			rnd(rng, -0.6, 0.6),
			y - 3,
			rnd(rng, -0.6, 0.6),
			k * 25
		)
		y -= 3
	end
end

---------------------------------------------------------------- Rainbow Heaven

-- A rainbow: six concentric arcs of blocks in the R1..R6 roles (red to violet), standing in the XY plane.
local function rainbowArc(m: Model)
	local R, band = 30, 2.4
	for k = 1, 6 do
		B.arc(m, "R" .. k, CFrame.new(0, 0, 0), R - (k - 1) * band, 0, math.pi, 14, Vector2.new(band, 3))
	end
	-- cloud puffs at both feet
	for _, s in { -1, 1 } do
		B.blob(m, "Cloud", 14, 7, 9, s * (R - 6), 2, 0)
		B.blob(m, "Cloud2", 9, 5, 7, s * (R - 1), 5, 1.5)
	end
end

local function rainbowPalace(m: Model)
	-- a cloud base, a white hall with gold trims, five towers with gold domes, a great central dome, banners
	B.blob(m, "Cloud", 54, 8, 40, 0, 1, 0)
	B.on(m, "Wall", V(34, 16, 22), 0, 3, 2)
	B.on(m, "Trim", V(35, 1.2, 23), 0, 19, 2)
	for _, x in { -12, -6, 0, 6, 12 } do
		B.on(m, "Glass", V(3, 8, 0.4), x, 6, -9.2)
		B.arc(m, "Trim", CFrame.new(x, 14, -9.3), 1.6, 0, math.pi, 4, Vector2.new(0.5, 0.6))
	end
	B.on(m, "Gold", V(8, 11, 1), 0, 3, -9.4)
	for _, p in { { -19, -9 }, { 19, -9 }, { -19, 13 }, { 19, 13 } } do
		B.round(m, "Wall", 26, 8, p[1], 3, p[2])
		B.round(m, "Trim", 1, 9, p[1], 29, p[2])
		B.stack(m, "Gold", 8, 1.4, 7, 4, p[1], 30, p[2])
		B.on(m, "Glow", V(1, 1.6, 1), p[1], 37, p[2], 45)
	end
	B.round(m, "Wall", 10, 14, 0, 20.2, 2, 22.5)
	B.stack(m, "Gold", 14, 3, 12, 5, 0, 30.2, 2, 0, "Trim")
	B.on(m, "Glow", V(2.4, 3, 2.4), 0, 42.2, 2, 45)
	-- rainbow banners on the front towers
	for i, x in { -19, 19 } do
		for k = 1, 3 do
			B.box(m, "R" .. (k + (i - 1) * 3), V(2.6, 1.2, 0.3), x, 22 - k * 1.2, -13.2)
		end
	end
end

local function cloudPavilion(m: Model)
	B.blob(m, "Cloud", 18, 5, 16, 0, 0, 0)
	B.round(m, "Trim", 1, 13, 0, 1.8, 0, 22.5)
	for i = 0, 5 do
		local a = rad(i * 60 + 30)
		B.on(m, "Wall", V(1.2, 9, 1.2), math.cos(a) * 5.4, 2.8, math.sin(a) * 5.4)
	end
	B.round(m, "Trim", 1, 13.6, 0, 11.8, 0, 22.5)
	B.stack(m, "Gold", 12, 2, 5, 4, 0, 12.8, 0, 22.5)
	B.on(m, "Glow", V(1.2, 1.2, 1.2), 0, 18, 0, 45)
end

local function goldenEgg(m: Model)
	-- the reward trophy: a stepped white and gold pedestal, a giant golden egg with a rainbow band and a crown
	B.round(m, "Trim", 2, 22, 0, -0.5, 0, 22.5)
	B.round(m, "Wall", 3, 18, 0, 1.5, 0)
	B.round(m, "Gold", 1, 19, 0, 4.5, 0, 22.5)
	B.egg(m, "Gold", 14, 20, 0, 5.5, 0)
	for k = 1, 6 do
		B.round(m, "R" .. k, 0.6, 14.4, 0, 11 + k * 0.6, 0, k * 8)
	end
	for i = 0, 5 do
		local a = rad(i * 60)
		B.on(m, "Gold", V(1.4, 3, 1.4), math.cos(a) * 2.6, 25, math.sin(a) * 2.6)
		B.box(m, "Glow", V(0.8, 0.8, 0.8), math.cos(a) * 2.6, 28.6, math.sin(a) * 2.6, 45, 0, 45)
	end
end

local function heavenGate(m: Model)
	-- the end of the track: a white and gold colonnade on clouds, facing -Z (back toward the hub), with a plinth on its
	-- attic for the Golden Egg trophy (MapBuilder places it at y = 46.4)
	B.blob(m, "Cloud", 120, 12, 18, 0, 0, 0)
	for x = -40, 40, 10 do
		B.on(m, "Wall", V(3, 30, 3), x, 4, -2)
		B.on(m, "Trim", V(4, 1, 4), x, 4, -2)
		B.on(m, "Trim", V(4, 1.2, 4), x, 33.6, -2)
	end
	B.on(m, "Trim", V(88, 2.4, 6), 0, 34.8, -2)
	B.on(m, "Wall", V(84, 6, 4), 0, 37.2, -1)
	B.on(m, "Gold", V(86, 1, 5), 0, 43.2, -1)
	-- a broad stepped plinth on the attic for the Golden Egg trophy
	B.on(m, "Trim", V(30, 1.6, 12), 0, 44.2, -1)
	B.on(m, "Gold", V(26, 0.6, 10), 0, 45.8, -1)
end

local function goldLamp(m: Model)
	B.on(m, "Trim", V(2, 1, 2), 0, -0.4, 0)
	B.on(m, "Gold", V(0.6, 9, 0.6), 0, 0.6, 0)
	B.on(m, "Glow", V(1.4, 1.4, 1.4), 0, 9.6, 0, 45)
	B.on(m, "Gold", V(2, 0.4, 2), 0, 9.4, 0, 45)
end

Zones5.recipes = {
	RingedPlanet = ringedPlanet,
	CosmicPortal = cosmicPortal,
	Meteor = meteor,
	CelestialCrystal = celestialCrystal,
	StarLamp = starLamp,
	VoidPlatform = voidPlatform,
	RainbowArc = rainbowArc,
	RainbowPalace = rainbowPalace,
	CloudPavilion = cloudPavilion,
	GoldenEgg = goldenEgg,
	HeavenGate = heavenGate,
	GoldLamp = goldLamp,
}

return Zones5
