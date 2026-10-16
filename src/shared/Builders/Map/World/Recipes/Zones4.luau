--!strict
-- Partner A. Classic brick recipes for batch 4 zones: Toxic Swamp (Bog Cauldron landmark, stilt hut, twisted trees,
-- toxic pitcher plants, odd mushrooms, broken boardwalk, waste barrels, cattails), Clockwork Factory (Clock Tower
-- landmark, gears, pipe runs, boiler machines, chimney, conveyor, piston), Frozen Aurora (Ice Palace landmark,
-- frozen trees, ice spikes, snow crystal sculpture, igloo, ice arch) and Lava Core (Molten Core landmark, magma
-- pillars, floating cubes, heat obelisks, cracked slabs, heat vents).
-- Asset space: origin = base centre, +Y up, front = -Z. Wedges rise toward their local +Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Zones4 = {}

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

-- A gear standing upright (facing -Z) centred at height `y`: a hub, a rim ring of blocks and square teeth.
local function gearAt(m: Model, role: string, d: number, t: number, y: number, teeth: number)
	local c = CFrame.new(0, y, 0)
	B.at(m, "Metal", V(d * 0.3, d * 0.3, t + 0.4), c)
	local n = 8
	for i = 0, n - 1 do
		local a = rad(i * 360 / n)
		B.at(
			m,
			role,
			V(d * 0.42, d * 0.16, t),
			c * CFrame.Angles(0, 0, a) * CFrame.new(d * 0.38, 0, 0) * CFrame.Angles(0, 0, rad(90))
		)
		B.at(m, role, V(d * 0.08, d * 0.3, t - 0.1), c * CFrame.Angles(0, 0, a + rad(22.5)) * CFrame.new(d * 0.2, 0, 0))
	end
	for i = 0, teeth - 1 do
		local a = rad(i * 360 / teeth)
		B.at(m, role, V(d * 0.12, d * 0.14, t), c * CFrame.Angles(0, 0, a) * CFrame.new(d * 0.55, 0, 0))
	end
end

---------------------------------------------------------------- Toxic Swamp

local function bogCauldron(m: Model, rng: Random)
	-- three stone legs, a huge iron cauldron (stacked voxel rounds), a bubbling toxic brew, a fire glow beneath
	for i = 0, 2 do
		local a = rad(i * 120 + 30)
		B.on(m, "StoneDark", V(5, 9, 5), math.cos(a) * 11, -0.5, math.sin(a) * 11, i * 120)
	end
	B.round(m, "Lava", 1.2, 12, 0, 2, 0)
	B.round(m, "Metal", 3, 20, 0, 6, 0, 22.5)
	B.round(m, "Metal", 4, 28, 0, 9, 0)
	B.round(m, "Metal", 5, 30, 0, 13, 0, 22.5)
	B.round(m, "Metal", 2, 28, 0, 18, 0)
	B.round(m, "Trim", 1.2, 31, 0, 20, 0, 22.5)
	B.round(m, "Brew", 0.6, 26, 0, 19.4, 0)
	-- bubbles on the brew and drips down the side
	for i = 1, 6 do
		local a = rad(rnd(rng, 0, 360))
		local r = rnd(rng, 2, 10)
		B.on(
			m,
			"Brew",
			V(rnd(rng, 1.4, 3), rnd(rng, 1, 2.4), rnd(rng, 1.4, 3)),
			math.cos(a) * r,
			20,
			math.sin(a) * r,
			rnd(rng, 0, 45)
		)
	end
	for i = 0, 3 do
		local a = rad(i * 90 + rnd(rng, -20, 20))
		B.on(
			m,
			"Brew",
			V(1.6, rnd(rng, 3, 7), 0.6),
			math.cos(a) * 15.4,
			21 - rnd(rng, 3, 7),
			math.sin(a) * 15.4,
			90 - math.deg(a)
		)
	end
	-- a giant ladle leaning in
	B.box(m, "Wood", V(1.4, 30, 1.4), 6, 26, 2, 0, 0, -28)
	B.round(m, "Metal", 1.2, 5, 13, 38, 2)
end

local function stiltHut(m: Model, rng: Random)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.on(m, "WoodDark", V(1, 7, 1), sx * 5, -1, sz * 4, 0, 0, rnd(rng, -6, 6))
		end
	end
	B.on(m, "Wood", V(13, 0.6, 11), 0, 6, 0, 3)
	B.on(m, "Wall", V(10, 7, 8), 0, 6.6, 0.5, 0, 0, -2)
	roof(m, "Roof", 12.4, 10.4, 5, 13.4, 0.5, "RoofDark")
	B.on(m, "WoodDark", V(2.4, 4, 0.5), -2, 6.6, -3.6)
	B.on(m, "Glow", V(2, 1.8, 0.4), 2.6, 9, -3.6)
	B.on(m, "Metal", V(1.4, 4, 1.4), 3, 15, 2, 0, 0, 8)
	for k = 0, 4 do
		B.box(m, "Wood", V(1.6, 0.25, 0.25), -4, 1 + k * 1.2, -6, 0, 0, 0)
	end
end

local function twistedTree(m: Model, rng: Random)
	local x, y = 0, -0.4
	for k = 0, 2 do
		local lean = rnd(rng, -20, 20)
		B.on(m, "Trunk", V(2.2 - k * 0.4, 5, 2.2 - k * 0.4), x, y, 0, k * 40, 0, lean)
		x += math.sin(rad(-lean)) * 5
		y += 4.7
	end
	B.on(m, "LeafDark", V(10, 2.4, 9), x, y - 1, 0, rnd(rng, 0, 45))
	B.on(m, "Leaf", V(6.4, 2, 6), x + rnd(rng, -1, 1), y + 1.2, rnd(rng, -1, 1), rnd(rng, 0, 45))
	for i = 0, 3 do
		local a = rad(i * 90 + rnd(rng, -20, 20))
		local len = rnd(rng, 3, 6)
		B.on(m, "Moss", V(0.6, len, 0.6), x + math.cos(a) * 4, y - 1 - len, math.sin(a) * 3.6)
	end
	for i = 0, 2 do
		local a = i * 120 + rnd(rng, -20, 20)
		local r = rad(a)
		B.on(m, "Trunk", V(0.8, 2.4, 3), math.cos(r) * 1.4, -0.6, math.sin(r) * 1.4, 90 - a)
	end
end

local function pitcherPlant(m: Model, rng: Random)
	for i = 0, 2 do
		local a = rad(i * 120 + rnd(rng, -20, 20))
		local h = rnd(rng, 3, 5)
		local x, z = math.cos(a) * 1.4, math.sin(a) * 1.4
		B.on(m, "Leaf", V(1.6, h, 1.6), x, -0.3, z, rnd(rng, 0, 45), rnd(rng, -8, 8), rnd(rng, -8, 8))
		B.on(m, "Brew", V(1.2, 0.4, 1.2), x, h - 0.2, z)
		B.on(m, "Accent", V(1.8, 0.5, 1.8), x, h - 0.5, z, 45)
	end
	B.on(m, "LeafDark", V(3.6, 0.8, 3), 0, -0.4, 0, rnd(rng, 0, 45))
end

local function oddMushroom(m: Model, rng: Random)
	B.on(m, "Stem", V(1.2, 4, 1.2), 0, -0.3, 0, 0, rnd(rng, -10, 10), rnd(rng, -10, 10))
	B.round(m, "Cap", 1, 5, 0, 3.6, 0, rnd(rng, 0, 45))
	B.on(m, "Cap", V(2.6, 1, 2.6), 0, 4.6, 0, 45)
	for i = 0, 2 do
		local a = rad(i * 120)
		B.on(m, "Brew", V(0.7, 0.4, 0.7), math.cos(a) * 1.6, 4.5, math.sin(a) * 1.6)
	end
end

local function boardwalk(m: Model, rng: Random)
	-- a broken plank walk along local Z on short posts, one plank missing, one tilted
	local n = 9
	for i = 0, n - 1 do
		if i ~= 5 then
			local tilt = if i == 6 then 14 else rnd(rng, -2, 2)
			B.box(
				m,
				if i % 3 == 0 then "WoodDark" else "Wood",
				V(5, 0.4, 1.6),
				rnd(rng, -0.2, 0.2),
				1.4 + (if i == 6 then -0.5 else 0),
				-n + i * 2 + 1,
				rnd(rng, -3, 3),
				tilt,
				0
			)
		end
	end
	for k = 0, 3 do
		for _, sx in { -1, 1 } do
			B.on(m, "WoodDark", V(0.6, 2.8, 0.6), sx * 2.4, -1.2, -n + 1 + k * 5.4)
		end
	end
end

local function wasteBarrel(m: Model, rng: Random)
	local lean = rnd(rng, -10, 10)
	B.on(m, "Accent", V(2.4, 3.2, 2.4), 0, -0.3, 0, rnd(rng, 0, 45), lean, 0)
	B.on(m, "Metal", V(2.6, 0.4, 2.6), 0, 0.6, 0, 0, lean, 0)
	B.on(m, "Brew", V(1.6, 0.3, 1.6), 0, 2.8, 0, 0, lean, 0)
	B.on(m, "Brew", V(2, 0.2, 3), 0.6, -0.3, -1.8, 20)
end

local function cattails(m: Model, rng: Random)
	for i = 0, 5 do
		local a = rad(i * 60 + rnd(rng, -20, 20))
		local r = rnd(rng, 0.2, 1.4)
		local h = rnd(rng, 3, 5)
		B.on(m, "Leaf", V(0.25, h, 0.25), math.cos(a) * r, -0.3, math.sin(a) * r, 0, rnd(rng, -6, 6), rnd(rng, -6, 6))
		if i % 2 == 0 then
			B.on(m, "Trunk", V(0.5, 1.2, 0.5), math.cos(a) * r, h - 1.4, math.sin(a) * r)
		end
	end
end

---------------------------------------------------------------- Clockwork Factory

local function clockTower(m: Model, rng: Random)
	-- a brick factory hall with saw-tooth roofs, a tall clock tower with a giant clock face, two chimneys
	local W, D = 34, 22
	B.on(m, "Wall", V(W, 12, D), 0, -0.5, 0)
	for i = 0, 3 do
		local x = -W / 2 + (i + 0.5) * W / 4
		B.wedge(m, "Roof", V(W / 4, 5, D), CFrame.new(x, 11.5 + 2.5, 0) * CFrame.Angles(0, rad(90), 0))
		B.on(m, "Glass", V(0.4, 4.4, D - 2), x + W / 8 - 0.4, 11.5, 0)
	end
	for _, x in { -12, -4, 4, 12 } do
		B.on(m, "Glass", V(4, 6, 0.4), x, 2, -D / 2 - 0.1)
		B.on(m, "Trim", V(4.8, 0.6, 0.6), x, 1.7, -D / 2 - 0.2)
	end
	B.on(m, "Dark", V(7, 9, 0.6), 0, -0.5, -D / 2 - 0.2)
	-- the clock tower
	B.on(m, "Wall", V(12, 44, 12), W / 2 + 4, -0.5, 2)
	B.on(m, "Trim", V(13, 1, 13), W / 2 + 4, 43.5, 2)
	B.stack(m, "Roof", 13, 2, 8, 4, W / 2 + 4, 44.5, 2, 45)
	disc(m, "Trim", 10, 0.8, W / 2 + 4, 34, -4.2)
	disc(m, "Clock", 8.6, 0.9, W / 2 + 4, 34, -4.3)
	B.box(m, "Dark", V(0.6, 3.6, 0.3), W / 2 + 4, 35.4, -4.85)
	B.box(m, "Dark", V(2.8, 0.6, 0.3), W / 2 + 5.2, 34, -4.85)
	for _, s in { -1, 1 } do
		B.on(m, "StoneDark", V(4, 26, 4), s * 10, 11.5, 6)
		B.on(m, "Trim", V(4.6, 1, 4.6), s * 10, 37.5, 6)
	end
end

local function gear(d: number, teeth: number)
	return function(m: Model)
		gearAt(m, "Gear", d, 1.6, 0, teeth)
	end
end

local function pipeRun(m: Model, rng: Random)
	for k, y in { 2, 5 } do
		B.box(m, if k == 1 then "Pipe" else "Pipe2", V(20, 1.4, 1.4), 0, y, 0)
		for _, x in { -9, 0, 9 } do
			B.box(m, "Metal", V(0.8, 1.9, 1.9), x, y, 0)
		end
	end
	for _, x in { -10, 10 } do
		B.on(m, "Metal", V(1.2, 6, 1.2), x, -0.5, 0)
	end
	B.box(m, "Pipe", V(1.4, 4, 1.4), 4, 3.5, 0)
	disc(m, "Accent", 1.6, 0.3, -4, 6.2, -0.9)
end

local function boiler(m: Model, rng: Random)
	B.on(m, "StoneDark", V(9, 1, 7), 0, -0.5, 0)
	B.log(m, "Pipe", 8, 6, 0, 4, 0)
	for _, x in { -2.6, 2.6 } do
		B.log(m, "Metal", 0.6, 6.3, x, 4, 0)
	end
	disc(m, "Trim", 2.2, 0.3, -1.8, 5.2, -3.2)
	disc(m, "Clock", 1.6, 0.34, -1.8, 5.2, -3.25)
	B.on(m, "Lava", V(2.4, 1.4, 0.4), 2, 1.2, -3.1)
	B.on(m, "Pipe2", V(1.2, 6, 1.2), 2.6, 7, 1)
	B.on(m, "Metal", V(1.8, 0.6, 1.8), 2.6, 13, 1)
end

local function conveyor(m: Model, rng: Random)
	B.on(m, "Dark", V(4, 0.6, 22), 0, 2.4, 0)
	B.on(m, "Metal", V(4.4, 0.4, 22.4), 0, 2, 0)
	for k = 0, 3 do
		for _, sx in { -1, 1 } do
			B.on(m, "Metal", V(0.6, 2.4, 0.6), sx * 1.8, -0.4, -9 + k * 6)
		end
	end
	for i = 0, 2 do
		B.on(
			m,
			if i % 2 == 0 then "Wood" else "Accent",
			V(2.4, 2.2, 2.4),
			rnd(rng, -0.4, 0.4),
			3,
			-7 + i * 7,
			rnd(rng, 0, 30)
		)
	end
end

local function piston(m: Model)
	B.on(m, "StoneDark", V(5, 1.4, 5), 0, -0.5, 0)
	B.on(m, "Metal", V(3, 6, 3), 0, 0.9, 0)
	B.on(m, "Pipe2", V(1.4, 5, 1.4), 0, 6.9, 0)
	B.on(m, "Gear", V(4, 1.4, 4), 0, 11.9, 0)
end

---------------------------------------------------------------- Frozen Aurora

local function icePalace(m: Model, rng: Random)
	-- an ice palace: a glacier base, a main hall of ice blocks, four ice towers with crystal spires, a great
	-- central spire and frosted arches
	B.on(m, "Snow", V(46, 3, 36), 0, -1, 0)
	B.on(m, "Ice", V(28, 16, 20), 0, 2, 2)
	B.on(m, "Snow", V(29, 1.4, 21), 0, 18, 2)
	for _, x in { -8, 0, 8 } do
		B.on(m, "Crystal", V(4, 9, 0.6), x, 3, -8.3)
		B.on(m, "Snow", V(5, 1, 1), x, 12, -8.4)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * 17, sz * 13
			B.round(m, "Ice", 24, 8, x, 2, z)
			B.round(m, "Snow", 1.2, 8.8, x, 26, z)
			B.stack(m, "Crystal", 7, 1.2, 12, 4, x, 27.2, z, 22.5)
		end
	end
	B.round(m, "Ice", 14, 10, 0, 19.4, 2, 22.5)
	B.stack(m, "Crystal", 9, 1.4, 20, 5, 0, 33.4, 2)
	B.on(m, "Glow", V(2, 2, 2), 0, 52, 2, 45)
	for i = 1, 6 do
		B.on(
			m,
			"Snow",
			V(rnd(rng, 4, 8), rnd(rng, 1, 2.4), rnd(rng, 3, 6)),
			rnd(rng, -20, 20),
			2,
			rnd(rng, -16, -12),
			rnd(rng, 0, 45)
		)
	end
end

local function frozenTree(m: Model, rng: Random)
	B.on(m, "Trunk", V(1.6, 8, 1.6), 0, -0.4, 0, rnd(rng, 0, 90))
	for i = 0, 2 do
		local a = i * 120 + rnd(rng, -20, 20)
		local r = rad(a)
		B.on(m, "Trunk", V(0.7, 4, 0.7), math.cos(r) * 0.6, 4, math.sin(r) * 0.6, 90 - a, 0, -38)
	end
	B.blob(m, "Ice", 8, 6, 7.4, 0, 9.6, 0, rnd(rng, 0, 45))
	B.blob(m, "Snow", 5, 2.4, 5, 0, 12.4, 0, rnd(rng, 0, 45))
	for i = 0, 3 do
		local a = rad(i * 90 + 30)
		B.on(m, "Crystal", V(0.4, 1.6, 0.4), math.cos(a) * 3.4, 6.4, math.sin(a) * 3.2)
	end
end

local function iceSpikes(m: Model, rng: Random)
	B.on(m, "Snow", V(7, 1.4, 6), 0, -0.5, 0, rnd(rng, 0, 45))
	for i = 0, 4 do
		local a = rad(i * 72 + rnd(rng, -15, 15))
		local r = if i == 0 then 0 else rnd(rng, 1.4, 2.6)
		local h = rnd(rng, 4, 11) * (if i == 0 then 1.3 else 1)
		B.on(
			m,
			if i % 2 == 0 then "Ice" else "Crystal",
			V(rnd(rng, 1.4, 2.2), h, rnd(rng, 1.4, 2.2)),
			math.cos(a) * r,
			0,
			math.sin(a) * r,
			rnd(rng, 0, 90),
			math.sin(a) * 14,
			-math.cos(a) * 14
		)
	end
end

local function snowCrystal(m: Model)
	-- a big six-armed snowflake sculpture standing on a plinth, facing -Z
	B.on(m, "Snow", V(5, 2, 5), 0, -0.5, 0)
	local c = CFrame.new(0, 10, 0)
	B.at(m, "Crystal", V(2.2, 2.2, 0.8), c * CFrame.Angles(0, 0, rad(45)))
	for i = 0, 5 do
		local a = rad(i * 60)
		local arm = c * CFrame.Angles(0, 0, a)
		B.at(m, "Ice", V(0.9, 8, 0.6), arm * CFrame.new(0, 4.4, 0))
		for _, k in { 3, 5.6 } do
			for _, s in { -1, 1 } do
				B.at(
					m,
					"Crystal",
					V(0.6, 2.4, 0.5),
					arm * CFrame.new(s * 0.9, k, 0) * CFrame.Angles(0, 0, rad(-s * 45))
				)
			end
		end
	end
	B.on(m, "Ice", V(1, 1.6, 0.8), 0, 1.5, 0)
end

local function igloo(m: Model)
	B.stack(m, "Snow", 10, 4, 6, 4, 0, -0.4, 0, 0)
	for k = 0, 2 do
		B.round(m, "Trim", 0.15, 10 - k * 2, 0, 0.9 + k * 1.5, 0)
	end
	B.on(m, "Snow", V(3.6, 3.2, 3.4), 0, -0.4, -5.6)
	B.on(m, "Dark", V(2, 2.4, 0.4), 0, -0.4, -7.3)
	B.on(m, "Glow", V(1.6, 1.8, 0.3), 0, -0.2, -7.2)
end

local function iceArch(m: Model, rng: Random)
	local span, h = 18, 12
	local n = 7
	for i = 0, n - 1 do
		local t = i / (n - 1)
		local x = -span / 2 + t * span
		local y = h * math.sin(math.pi * t)
		local ang = math.deg(math.atan(h * math.pi * math.cos(math.pi * t) / span))
		B.box(m, if i % 2 == 0 then "Ice" else "Crystal", V(span / (n - 1) + 1.2, 2.4, 3), x, y + 0.6, 0, 0, 0, ang)
		if i % 2 == 0 then
			B.box(m, "Snow", V(span / (n - 1) + 0.6, 0.6, 3.2), x, y + 2, 0, 0, 0, ang)
		end
	end
	for _, s in { -1, 1 } do
		B.on(m, "Snow", V(4, 2, 4), s * span / 2, -1, 0, rnd(rng, 0, 45))
	end
end

---------------------------------------------------------------- Lava Core

local function moltenCore(m: Model)
	-- a stepped obsidian pedestal with glowing seams, a floating molten cube core inside two great rings
	for i = 0, 3 do
		local w = 34 - i * 7
		B.on(m, if i % 2 == 0 then "StoneDark" else "Dark", V(w, 3, w), 0, -0.5 + i * 3, 0, i * 45)
		B.on(m, "Lava", V(w + 0.2, 0.4, w + 0.2), 0, 2.2 + i * 3, 0, i * 45)
	end
	-- pillars holding the rings
	for i = 0, 3 do
		local a = rad(i * 90 + 45)
		B.on(m, "Dark", V(3, 26, 3), math.cos(a) * 13, 11.5, math.sin(a) * 13)
		B.on(m, "Lava", V(3.2, 1, 3.2), math.cos(a) * 13, 30, math.sin(a) * 13)
	end
	-- two rings around the core (vertical, crossed), and the core
	local cy = 30
	for k, yaw in { 0, 90 } do
		local c = CFrame.new(0, cy, 0) * CFrame.Angles(0, rad(yaw), 0)
		for i = 0, 11 do
			local a = rad(i * 30)
			B.at(
				m,
				if k == 1 then "Metal" else "Dark",
				V(5.6, 1.6, 1.6),
				c * CFrame.Angles(0, 0, a) * CFrame.new(0, 13, 0)
			)
		end
	end
	B.box(m, "Lava", V(6, 6, 6), 0, cy, 0, 45, 35, 0)
	B.box(m, "Core", V(9.5, 9.5, 9.5), 0, cy, 0, 45, 35, 0)
end

local function magmaPillar(m: Model, rng: Random)
	local y = -0.5
	local n = rng:NextInteger(3, 5)
	for k = 0, n - 1 do
		local w = 4.6 - k * 0.5
		local h = rnd(rng, 3, 5)
		B.on(m, if k % 2 == 0 then "StoneDark" else "Dark", V(w, h, w), 0, y, 0, k * 30)
		B.on(m, "Lava", V(w + 0.2, 0.4, w + 0.2), 0, y + h - 0.2, 0, k * 30)
		y += h + 0.2
	end
	B.on(m, "Lava", V(1.6, 1.6, 1.6), 0, y, 0, 45)
end

local function floatingCube(m: Model, rng: Random)
	local s = rnd(rng, 3, 5)
	B.box(m, "Dark", V(s, s, s), 0, 0, 0, rnd(rng, 0, 90), rnd(rng, 0, 90), rnd(rng, 0, 90))
	B.box(m, "Lava", V(s * 0.5, s * 1.04, s * 0.5), 0, 0, 0, rnd(rng, 0, 90), 0, 0)
end

local function heatObelisk(m: Model)
	B.on(m, "Dark", V(6, 1.4, 6), 0, -0.5, 0)
	B.on(m, "StoneDark", V(3.4, 16, 3.4), 0, 0.9, 0)
	for k = 0, 3 do
		B.box(m, "Lava", V(3.6, 0.4, 3.6), 0, 3 + k * 3.6, 0)
	end
	B.on(m, "Lava", V(2, 2, 2), 0, 17.4, 0, 45)
end

local function crackedSlab(m: Model, rng: Random)
	B.on(m, "StoneDark", V(12, 0.8, 12), 0, -0.4, 0, rnd(rng, 0, 45))
	for i = 0, 3 do
		B.box(m, "Lava", V(rnd(rng, 4, 10), 0.3, 0.5), rnd(rng, -3, 3), 0.42, rnd(rng, -4, 4), rnd(rng, 0, 180))
	end
end

local function heatVent(m: Model)
	for i = 0, 3 do
		local a = rad(i * 90)
		B.on(m, "Dark", V(3.6, 2.6, 1.4), math.cos(a) * 2.2, -0.4, math.sin(a) * 2.2, 90 - i * 90)
	end
	B.on(m, "Lava", V(3, 0.4, 3), 0, 0.6, 0, 45)
end

Zones4.recipes = {
	BogCauldron = bogCauldron,
	StiltHut = stiltHut,
	TwistedTree = twistedTree,
	PitcherPlant = pitcherPlant,
	OddMushroom = oddMushroom,
	Boardwalk = boardwalk,
	WasteBarrel = wasteBarrel,
	Cattails = cattails,
	ClockTower = clockTower,
	GearBig = gear(14, 12),
	GearSmall = gear(7, 8),
	PipeRun = pipeRun,
	Boiler = boiler,
	Conveyor = conveyor,
	Piston = piston,
	IcePalace = icePalace,
	FrozenTree = frozenTree,
	IceSpikes = iceSpikes,
	SnowCrystal = snowCrystal,
	Igloo = igloo,
	IceArch = iceArch,
	MoltenCore = moltenCore,
	MagmaPillar = magmaPillar,
	FloatingCube = floatingCube,
	HeatObelisk = heatObelisk,
	CrackedSlab = crackedSlab,
	HeatVent = heatVent,
}

return Zones4
