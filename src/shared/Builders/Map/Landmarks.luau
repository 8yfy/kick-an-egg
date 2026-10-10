--!strict
-- One big set piece per zone, standing on the canyon rim so it rises over the wall and frames
-- the landing. Landmarks.build(zoneId, parent, origin): `origin` sits on the ground at the
-- landmark's centre with its LookVector (-Z) facing the canyon. Footprint stays within ~26 studs.
local Bricks = require(script.Parent.Bricks)
local MapFx = require(script.Parent.MapFx)

local rgb = Color3.fromRGB
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass

-- Reference style: every round shape is a voxel stand-in (Bricks.blockCyl / blockBall / voxelRound).
local P, cyl, ball, arc = Bricks.part, Bricks.blockCyl, Bricks.blockBall, Bricks.arc
local function glow(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: string?): BasePart
	if shape == "Ball" or shape == "Cylinder" then
		return Bricks.voxelRound(parent, name, size, cf, color, shape == "Ball", { material = NEON, collide = false })
	end
	return Bricks.glow(parent, name, size, cf, color, shape)
end

local Landmarks = {}

type Builder = (m: Model, at: (x: number, y: number, z: number) -> CFrame) -> ()

local function ring(
	m: Model,
	at: (number, number, number) -> CFrame,
	n: number,
	r: number,
	y: number,
	size: Vector3,
	color: Color3,
	tilt: number?
)
	for i = 0, n - 1 do
		local a = i / n * math.pi * 2
		P(m, "Ring", size, at(math.cos(a) * r, y, math.sin(a) * r) * CFrame.Angles(0, -a, math.rad(tilt or 0)), color)
	end
end

local BUILDERS: { [number]: Builder } = {
	[1] = function(m, at) -- Meadow: giant sunflower
		cyl(m, "Stem", 34, 2.4, at(0, 17, 0), rgb(70, 160, 50))
		P(m, "Leaf", Vector3.new(7, 0.8, 3), at(3.5, 12, 0) * CFrame.Angles(0, 0, math.rad(25)), rgb(90, 190, 60))
		P(m, "Leaf", Vector3.new(7, 0.8, 3), at(-3.5, 20, 0) * CFrame.Angles(0, 0, math.rad(-25)), rgb(90, 190, 60))
		local head = at(0, 36, -1) * CFrame.Angles(math.rad(70), 0, 0)
		cyl(m, "Face", 2, 10, head, rgb(110, 70, 35))
		for i = 0, 13 do
			local a = i / 14 * math.pi * 2
			P(
				m,
				"Petal",
				Vector3.new(3, 0.8, 6),
				head * CFrame.new(math.cos(a) * 7, 0, math.sin(a) * 7) * CFrame.Angles(0, -a + math.pi / 2, 0),
				rgb(255, 215, 40)
			)
		end
		for i = 1, 6 do
			local a = i * 1.1
			cyl(m, "Bud", 3, 0.6, at(math.cos(a) * 9, 1.5, math.sin(a) * 9), rgb(70, 160, 50))
			ball(
				m,
				"Bloom",
				2.2,
				at(math.cos(a) * 9, 3.4, math.sin(a) * 9),
				if i % 2 == 0 then rgb(255, 120, 170) else rgb(255, 255, 255)
			)
		end
	end,
	[2] = function(m, at) -- Sandy Beach: sandcastle
		local sand, dark = rgb(240, 210, 140), rgb(215, 180, 110)
		P(m, "Base", Vector3.new(22, 8, 22), at(0, 4, 0), sand)
		for _, c in { { -9, -9 }, { 9, -9 }, { -9, 9 }, { 9, 9 } } do
			cyl(m, "Tower", 16, 6, at(c[1], 8, c[2]), dark)
			for k = 0, 3 do
				local a = k * math.pi / 2
				P(
					m,
					"Merlon",
					Vector3.new(1.4, 1.6, 1.4),
					at(c[1] + math.cos(a) * 2.4, 16.8, c[2] + math.sin(a) * 2.4),
					sand
				)
			end
		end
		P(m, "Keep", Vector3.new(10, 18, 10), at(0, 17, 0), sand)
		P(m, "Door", Vector3.new(3, 5, 0.6), at(0, 10.5, -5.2), rgb(110, 70, 40))
		cyl(m, "Pole", 6, 0.4, at(0, 29, 0), rgb(120, 80, 50))
		P(m, "Flag", Vector3.new(0.2, 2.4, 3.6), at(0, 30.6, -1.8), rgb(255, 80, 80))
		ball(m, "Ball", 3, at(13, 1.5, -12), rgb(255, 90, 90))
		P(m, "Bucket", Vector3.new(2.5, 3, 2.5), at(-13, 1.5, -12), rgb(70, 190, 240))
	end,
	[3] = function(m, at) -- Autumn Forest: giant oak
		cyl(m, "Trunk", 26, 6, at(0, 13, 0), rgb(110, 70, 40))
		P(m, "Branch", Vector3.new(12, 2.4, 2.4), at(5, 22, 0) * CFrame.Angles(0, 0, math.rad(30)), rgb(110, 70, 40))
		P(m, "Branch", Vector3.new(12, 2.4, 2.4), at(-5, 20, 0) * CFrame.Angles(0, 0, math.rad(-30)), rgb(110, 70, 40))
		local canopy: { { pos: Vector3, d: number, color: Color3 } } = {
			{ pos = Vector3.new(0, 34, 0), d = 18, color = rgb(235, 120, 40) },
			{ pos = Vector3.new(8, 28, 2), d = 13, color = rgb(220, 70, 40) },
			{ pos = Vector3.new(-8, 27, -2), d = 13, color = rgb(250, 190, 50) },
			{ pos = Vector3.new(3, 30, -7), d = 11, color = rgb(240, 150, 50) },
			{ pos = Vector3.new(-4, 31, 7), d = 11, color = rgb(200, 90, 40) },
		}
		for i, c in canopy do
			ball(m, "Canopy" .. i, c.d, at(c.pos.X, c.pos.Y, c.pos.Z), c.color)
		end
		for i = 1, 5 do
			P(
				m,
				"Leaves",
				Vector3.new(3, 0.3, 2),
				at(-10 + i * 4, 0.15, -8 + (i % 2) * 4) * CFrame.Angles(0, i, 0),
				rgb(235, 130, 50)
			)
		end
		MapFx.emit(
			P(
				m,
				"LeafFx",
				Vector3.new(16, 1, 16),
				at(0, 30, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Leaves"
		)
	end,
	[4] = function(m, at) -- Mushroom Grove: giant toadstool
		cyl(m, "Stem", 22, 6, at(0, 11, 0), rgb(245, 235, 220))
		cyl(m, "Gill", 1.5, 20, at(0, 22, 0), rgb(230, 200, 190))
		cyl(m, "Cap1", 3, 26, at(0, 24, 0), rgb(220, 40, 50))
		cyl(m, "Cap2", 3, 21, at(0, 27, 0), rgb(220, 40, 50))
		cyl(m, "Cap3", 3, 14, at(0, 30, 0), rgb(220, 40, 50))
		for i, s in { { 6, 25.6, 6 }, { -7, 25.6, 4 }, { 2, 28.6, -7 }, { -3, 31.6, 0 }, { 9, 25.6, -3 } } do
			ball(m, "Spot" .. i, 2.4, at(s[1], s[2], s[3]), rgb(255, 255, 255))
		end
		for i = 1, 4 do
			local a = i * 1.6
			cyl(m, "Small", 4, 1.4, at(math.cos(a) * 10, 2, math.sin(a) * 10), rgb(245, 235, 220))
			cyl(
				m,
				"SmallCap",
				1.4,
				5,
				at(math.cos(a) * 10, 4.4, math.sin(a) * 10),
				if i % 2 == 0 then rgb(170, 100, 255) else rgb(255, 120, 60)
			)
		end
		MapFx.emit(
			P(
				m,
				"SporeFx",
				Vector3.new(20, 1, 20),
				at(0, 26, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Spores"
		)
	end,
	[5] = function(m, at) -- Desert Dunes: stepped pyramid
		local sand = rgb(230, 190, 110)
		for i = 0, 5 do
			local s = 26 - i * 4
			P(m, "Step" .. i, Vector3.new(s, 4, s), at(0, 2 + i * 4, 0), sand:Lerp(rgb(200, 150, 80), i / 8))
		end
		local cap = glow(m, "Capstone", Vector3.new(2.5, 2.5, 2.5), at(0, 25.3, 0), rgb(255, 215, 60))
		Bricks.light(cap, rgb(255, 215, 60), 22, 2)
		P(m, "Door", Vector3.new(4, 5, 0.6), at(0, 2.5, -13.1), rgb(70, 50, 30))
		for _, x in { -11, 11 } do
			cyl(m, "Obelisk", 10, 1.6, at(x, 5, -15), rgb(210, 170, 100))
		end
	end,
	[6] = function(m, at) -- Snowy Peaks: ice castle
		local ice, snow = rgb(170, 220, 255), rgb(250, 252, 255)
		P(m, "Wall", Vector3.new(22, 10, 14), at(0, 5, 0), snow)
		for i, x in { -9, 0, 9 } do
			local h = if i == 2 then 26 else 18
			cyl(m, "Spire", h, 5, at(x, h / 2, 2), ice, { material = GLASS, transparency = 0.15 })
			cyl(m, "Roof1", 3, 6, at(x, h + 1.5, 2), rgb(90, 150, 230))
			cyl(m, "Roof2", 3, 4, at(x, h + 4.5, 2), rgb(90, 150, 230))
			cyl(m, "Roof3", 3, 2, at(x, h + 7.5, 2), rgb(90, 150, 230))
		end
		P(m, "Gate", Vector3.new(4, 6, 0.6), at(0, 3, -7.2), rgb(90, 150, 230))
		for i = 1, 5 do
			ball(m, "Drift", 6 + i % 3 * 2, at(-12 + i * 5, 0.5, -9), snow)
		end
		MapFx.emit(
			P(
				m,
				"SnowFx",
				Vector3.new(22, 1, 14),
				at(0, 30, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Snow"
		)
	end,
	[7] = function(m, at) -- Candy Land: lollipop tower + gumdrops
		cyl(m, "Stick", 30, 2, at(0, 15, 0), rgb(255, 255, 255))
		local head = at(0, 33, 0) * CFrame.Angles(math.rad(90), 0, 0)
		cyl(m, "Candy", 2, 16, head, rgb(255, 120, 190))
		for i = 0, 5 do
			-- each smaller ring is a little thicker so its faces sit proud of the one behind (no z-fighting)
			cyl(
				m,
				"Swirl" .. i,
				2.3 + i * 0.12,
				13 - i * 2.2,
				head,
				if i % 2 == 0 then rgb(255, 255, 255) else rgb(120, 220, 230)
			)
		end
		for i = 1, 7 do
			local a = i * 0.9
			ball(m, "Gumdrop", 4, at(math.cos(a) * 10, 1.4, math.sin(a) * 10), Color3.fromHSV(i / 7, 0.55, 1))
		end
		for k, x in { -8, 8 } do
			P(m, "Cane", Vector3.new(1.2, 14, 1.2), at(x, 7, -9), rgb(255, 255, 255))
			for s = 0, 3 do
				P(m, "Stripe", Vector3.new(1.3, 0.8, 1.3), at(x, 2 + s * 3.4, -9), rgb(240, 50, 60))
			end
			P(m, "Hook", Vector3.new(4, 1.2, 1.2), at(x + (if k == 1 then 1.4 else -1.4), 14, -9), rgb(240, 50, 60))
		end
	end,
	[8] = function(m, at) -- Coral Reef: coral arch
		local pink, orange = rgb(255, 120, 150), rgb(255, 150, 80)
		arc(m, "Arch", at(0, 0, 0), 11, 0, math.pi, 12, Vector2.new(4, 4), pink)
		for i = 1, 6 do
			local x = -11 + i * 3.6
			cyl(
				m,
				"Anemone",
				2 + i % 3 * 2,
				1.4,
				at(x, 1 + i % 3, 8),
				if i % 2 == 0 then orange else rgb(150, 110, 255)
			)
		end
		for i = 1, 5 do
			ball(
				m,
				"Bubble",
				1.4 + i * 0.4,
				at(-4 + i * 2, 12 + i * 3, -2),
				rgb(200, 240, 255),
				{ material = GLASS, transparency = 0.4, collide = false }
			)
		end
		ball(m, "Shell", 4, at(9, 1.5, -6), rgb(255, 230, 210))
		MapFx.emit(
			P(
				m,
				"BubbleFx",
				Vector3.new(16, 1, 10),
				at(0, 2, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Bubbles"
		)
	end,
	[9] = function(m, at) -- Volcano: smoking cone with lava streams
		local rock = rgb(70, 50, 45)
		for i = 0, 5 do
			cyl(m, "Cone" .. i, 5, 26 - i * 3.5, at(0, 2.5 + i * 5, 0), rock:Lerp(rgb(40, 30, 30), i / 6))
		end
		local lava = glow(
			m,
			"Crater",
			Vector3.new(0.6, 6, 6),
			at(0, 30.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			rgb(255, 110, 20),
			"Cylinder"
		)
		Bricks.light(lava, rgb(255, 120, 40), 30, 3)
		Bricks.fire(lava, rgb(255, 110, 20), 9)
		for _, a in { 0.3, 2.4, 4.2 } do
			for s = 0, 4 do
				local r = 3 + s * 2.2
				glow(
					m,
					"LavaFlow",
					Vector3.new(1.6, 1, 5),
					at(math.cos(a) * r, 28 - s * 5.5, math.sin(a) * r) * CFrame.Angles(0, -a, math.rad(-55)),
					rgb(255, 120 - s * 10, 30)
				)
			end
		end
		MapFx.emit(
			P(
				m,
				"EmberFx",
				Vector3.new(6, 1, 6),
				at(0, 31, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Embers"
		)
	end,
	[10] = function(m, at) -- Crystal Caves: crystal cluster
		local colors = { rgb(120, 240, 255), rgb(170, 120, 255), rgb(90, 200, 255), rgb(220, 160, 255) }
		for i, c in
			{
				{ 0, 30, 0, 0 },
				{ 6, 20, 2, 18 },
				{ -6, 22, -1, -15 },
				{ 3, 14, -6, 25 },
				{ -4, 12, 6, -22 },
				{ 9, 10, -5, 30 },
				{ -10, 11, 4, -30 },
			}
		do
			P(
				m,
				"Crystal" .. i,
				Vector3.new(4, c[2], 4),
				at(c[1], c[2] / 2 - 1, c[3]) * CFrame.Angles(math.rad(c[4] * 0.4), math.rad(45), math.rad(c[4])),
				colors[i % 4 + 1],
				{ material = GLASS, transparency = 0.1 }
			)
		end
		local core = glow(m, "Core", Vector3.new(3, 3, 3), at(0, 4, 0), rgb(150, 250, 255), "Ball")
		Bricks.light(core, rgb(130, 230, 255), 26, 3)
		MapFx.emit(
			P(
				m,
				"SparkFx",
				Vector3.new(14, 1, 14),
				at(0, 12, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Sparkles"
		)
	end,
	[11] = function(m, at) -- Jungle Ruins: stepped temple
		local stone, moss = rgb(150, 145, 120), rgb(80, 150, 70)
		for i = 0, 2 do
			local s = 24 - i * 6
			P(m, "Tier" .. i, Vector3.new(s, 6, s), at(0, 3 + i * 6, 0), stone:Lerp(rgb(110, 110, 95), i / 4))
			P(m, "Moss" .. i, Vector3.new(s + 0.2, 1, s + 0.2), at(0, 5.6 + i * 6, 0), moss)
		end
		P(m, "Shrine", Vector3.new(8, 7, 8), at(0, 21.5, 0), stone)
		P(m, "Doorway", Vector3.new(3, 4.5, 0.4), at(0, 20.3, -4.1), rgb(30, 30, 25))
		P(m, "Stairs", Vector3.new(5, 18, 2), at(0, 9, -12.5) * CFrame.Angles(math.rad(-34), 0, 0), stone)
		for _, x in { -3.4, 3.4 } do
			local t = P(m, "Torch", Vector3.new(0.8, 3, 0.8), at(x, 26.5, -3.4), rgb(110, 70, 40))
			Bricks.fire(t, nil, 3)
		end
		for i = 1, 6 do
			P(m, "Vine", Vector3.new(0.5, 6 + i % 3 * 2, 0.5), at(-11 + i * 3.6, 4, -12.2), moss)
		end
	end,
	[12] = function(m, at) -- Neon City: neon tower
		local body = rgb(30, 30, 45)
		P(m, "Tower", Vector3.new(9, 46, 9), at(0, 23, 0), body, { material = Enum.Material.SmoothPlastic })
		P(m, "Annex", Vector3.new(7, 24, 7), at(8, 12, 3), body, { material = Enum.Material.SmoothPlastic })
		for i = 1, 8 do
			glow(
				m,
				"Band",
				Vector3.new(9.4, 0.5, 9.4),
				at(0, i * 5.4, 0),
				if i % 2 == 0 then rgb(255, 40, 200) else rgb(60, 230, 255)
			)
		end
		cyl(m, "Antenna", 10, 0.6, at(0, 51, 0), rgb(200, 200, 210))
		local beacon = glow(m, "Beacon", Vector3.new(1.6, 1.6, 1.6), at(0, 56.5, 0), rgb(255, 40, 60), "Ball")
		Bricks.light(beacon, rgb(255, 40, 60), 20, 3)
		local sign = glow(m, "Sign", Vector3.new(12, 5, 0.6), at(0, 30, -4.9), rgb(255, 40, 200))
		Bricks.light(sign, rgb(255, 60, 210), 24, 2)
	end,
	[13] = function(m, at) -- Haunted Graveyard: mausoleum + graves
		local stone = rgb(120, 125, 120)
		P(m, "Crypt", Vector3.new(14, 10, 12), at(0, 5, 0), stone)
		P(m, "Roof", Vector3.new(16, 2, 14), at(0, 11, 0), rgb(80, 85, 80))
		P(m, "RoofTop", Vector3.new(10, 2, 9), at(0, 13, 0), rgb(80, 85, 80))
		for _, x in { -5.5, 5.5 } do
			cyl(m, "Pillar", 10, 1.6, at(x, 5, -6.6), rgb(150, 155, 150))
		end
		local door = glow(m, "Door", Vector3.new(4, 6, 0.4), at(0, 3, -6.2), rgb(140, 255, 120))
		Bricks.light(door, rgb(140, 255, 120), 20, 2)
		for i = 1, 6 do
			local x = -12 + i * 4
			P(
				m,
				"Grave",
				Vector3.new(2.4, 3.4, 0.8),
				at(x, 1.7, -11) * CFrame.Angles(0, 0, math.rad((i % 3 - 1) * 8)),
				stone
			)
		end
		P(m, "DeadTree", Vector3.new(1.4, 16, 1.4), at(10, 8, 6) * CFrame.Angles(0, 0, math.rad(8)), rgb(60, 50, 45))
		P(m, "Branch", Vector3.new(6, 0.8, 0.8), at(12, 14, 6) * CFrame.Angles(0, 0, math.rad(35)), rgb(60, 50, 45))
		MapFx.emit(
			P(
				m,
				"WispFx",
				Vector3.new(16, 1, 14),
				at(0, 2, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Wisps"
		)
	end,
	[14] = function(m, at) -- Sky Islands: floating islands
		for i, c in { { 0, 22, 0, 14 }, { -9, 34, 4, 9 }, { 8, 44, -3, 7 } } do
			P(m, "Grass" .. i, Vector3.new(c[4], 2, c[4]), at(c[1], c[2], c[3]), rgb(120, 215, 75))
			P(m, "Dirt" .. i, Vector3.new(c[4] - 2, 3, c[4] - 2), at(c[1], c[2] - 2.5, c[3]), rgb(170, 120, 80))
			P(m, "Rock" .. i, Vector3.new(c[4] - 6, 3, c[4] - 6), at(c[1], c[2] - 5.5, c[3]), rgb(150, 110, 75))
		end
		cyl(m, "Trunk", 5, 1, at(0, 25.5, 0), rgb(120, 80, 50))
		ball(m, "Leaves", 6, at(0, 29, 0), rgb(90, 200, 90))
		for i = 1, 7 do
			local a = i * 0.9
			ball(
				m,
				"Cloud",
				5 + i % 3 * 2,
				at(math.cos(a) * 14, 10 + i * 4, math.sin(a) * 10),
				rgb(255, 255, 255),
				{ collide = false }
			)
		end
	end,
	[15] = function(m, at) -- Toxic Swamp: dead tree over a toxic pool
		local pool = glow(
			m,
			"Pool",
			Vector3.new(0.6, 22, 22),
			at(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			rgb(170, 255, 40),
			"Cylinder"
		)
		Bricks.light(pool, rgb(170, 255, 40), 26, 2)
		local wood = rgb(70, 60, 45)
		P(m, "Trunk", Vector3.new(3, 22, 3), at(-2, 11, 3) * CFrame.Angles(0, 0, math.rad(-6)), wood)
		P(m, "BranchA", Vector3.new(10, 1.6, 1.6), at(2, 20, 3) * CFrame.Angles(0, 0, math.rad(28)), wood)
		P(m, "BranchB", Vector3.new(8, 1.4, 1.4), at(-7, 17, 3) * CFrame.Angles(0, 0, math.rad(-32)), wood)
		for i = 1, 5 do
			P(
				m,
				"Moss",
				Vector3.new(0.6, 4 + i % 2 * 2, 0.6),
				at(-6 + i * 2.6, 15, 3),
				rgb(110, 150, 60),
				{ collide = false }
			)
		end
		for i = 1, 6 do
			ball(
				m,
				"Bubble",
				1 + i % 3,
				at(-6 + i * 2, 0.8, -4 + (i % 2) * 6),
				rgb(200, 255, 120),
				{ material = NEON, collide = false }
			)
		end
		MapFx.emit(
			P(
				m,
				"ToxicFx",
				Vector3.new(18, 1, 18),
				at(0, 1, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"ToxicBubbles"
		)
	end,
	[16] = function(m, at) -- Clockwork Factory: giant gears
		local brass, copper = rgb(230, 180, 60), rgb(200, 110, 60)
		local function gear(name: string, c: CFrame, d: number, color: Color3)
			cyl(m, name, 3, d, c * CFrame.Angles(math.rad(90), 0, 0), color)
			for i = 0, 11 do
				local a = i / 12 * math.pi * 2
				P(
					m,
					name .. "Tooth",
					Vector3.new(2, 2.4, 3),
					c * CFrame.Angles(0, 0, a) * CFrame.new(d / 2 + 0.6, 0, 0),
					color
				)
			end
			cyl(m, name .. "Hub", 3.4, d * 0.3, c * CFrame.Angles(math.rad(90), 0, 0), rgb(80, 70, 60))
		end
		gear("GearA", at(0, 16, 0), 22, brass)
		gear("GearB", at(13, 9, 1), 12, copper)
		gear("GearC", at(-11, 30, 1), 10, copper)
		cyl(m, "Chimney", 18, 3, at(-10, 9, 6), rgb(90, 80, 70))
		MapFx.emit(
			P(
				m,
				"SteamFx",
				Vector3.new(3, 1, 3),
				at(-10, 19, 6),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Steam"
		)
	end,
	[17] = function(m, at) -- Frozen Aurora: ice spires with glowing tips
		local tips = { rgb(120, 255, 200), rgb(110, 190, 255), rgb(190, 130, 255) }
		for i, c in { { 0, 34 }, { -7, 24 }, { 7, 26 }, { -3, 16 }, { 4, 14 }, { -10, 12 }, { 10, 11 } } do
			local x, h = c[1], c[2]
			local z = (i % 3 - 1) * 4
			P(
				m,
				"Spire" .. i,
				Vector3.new(3, h, 3),
				at(x, h / 2, z) * CFrame.Angles(0, math.rad(45), 0),
				rgb(200, 235, 250),
				{ material = GLASS, transparency = 0.1 }
			)
			local tip = glow(
				m,
				"Tip" .. i,
				Vector3.new(2, 4, 2),
				at(x, h + 1.6, z) * CFrame.Angles(0, math.rad(45), 0),
				tips[i % 3 + 1]
			)
			if i <= 3 then
				Bricks.light(tip, tips[i % 3 + 1], 20, 2)
			end
		end
		for i = 1, 4 do
			ball(m, "Snow", 7, at(-9 + i * 4.5, 0, -6), rgb(250, 252, 255))
		end
		MapFx.emit(
			P(
				m,
				"AuroraFx",
				Vector3.new(20, 1, 10),
				at(0, 36, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Aurora"
		)
	end,
	[18] = function(m, at) -- Lava Core: obsidian forge
		local obsidian = rgb(35, 25, 35)
		for _, x in { -8, 8 } do
			P(m, "Pillar", Vector3.new(5, 24, 5), at(x, 12, 0), obsidian)
			for s = 1, 4 do
				glow(
					m,
					"Crack",
					Vector3.new(5.2, 0.4, 1),
					at(x, s * 5, -2.2) * CFrame.Angles(0, 0, math.rad(s * 13 - 30)),
					rgb(255, 130, 30)
				)
			end
		end
		P(m, "Lintel", Vector3.new(22, 4, 6), at(0, 26, 0), obsidian)
		P(m, "Hearth", Vector3.new(11, 4, 5), at(0, 2, 1.5), obsidian) -- the furnace sits on it
		local core = glow(m, "Furnace", Vector3.new(8, 8, 2), at(0, 8, 1), rgb(255, 150, 30))
		Bricks.light(core, rgb(255, 140, 40), 30, 3)
		Bricks.fire(core, rgb(255, 120, 30), 8)
		P(m, "Anvil", Vector3.new(5, 2, 3), at(0, 4, -8), rgb(70, 70, 80))
		P(m, "AnvilBase", Vector3.new(3, 3, 2), at(0, 1.5, -8), rgb(50, 50, 60))
		glow(
			m,
			"LavaPool",
			Vector3.new(0.6, 10, 10),
			at(-9, 0.3, -9) * CFrame.Angles(0, 0, math.rad(90)),
			rgb(255, 110, 20),
			"Cylinder"
		)
		MapFx.emit(
			P(
				m,
				"MagmaFx",
				Vector3.new(16, 1, 6),
				at(0, 2, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Magma"
		)
	end,
	[19] = function(m, at) -- Galaxy Void: ringed planet + moons
		local planet =
			ball(m, "Planet", 22, at(0, 30, 0), rgb(130, 80, 230), { material = Enum.Material.SmoothPlastic })
		Bricks.light(planet, rgb(170, 120, 255), 34, 2)
		glow(
			m,
			"Ring",
			Vector3.new(0.4, 36, 36),
			at(0, 30, 0) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(20), 0, 0),
			rgb(255, 200, 120),
			"Cylinder"
		)
		ball(m, "MoonA", 5, at(-14, 44, 4), rgb(220, 220, 240))
		ball(m, "MoonB", 3, at(15, 18, -6), rgb(255, 160, 200))
		cyl(m, "Plinth", 6, 8, at(0, 3, 0), rgb(40, 30, 70))
		glow(m, "Beam", Vector3.new(1.2, 13, 1.2), at(0, 12.5, 0), rgb(170, 120, 255))
		MapFx.emit(
			P(
				m,
				"StarFx",
				Vector3.new(26, 1, 26),
				at(0, 30, 0),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Stars"
		)
	end,
	[20] = function(m, at) -- Rainbow Heaven: rainbow arch over a cloud palace
		for i = 0, 6 do
			arc(
				m,
				"Band" .. i,
				at(0, 0, 4),
				24 - i * 1.6,
				0,
				math.pi,
				18,
				Vector2.new(1.6, 1.6),
				Color3.fromHSV(i / 7, 0.65, 1),
				{ material = NEON, collide = false }
			)
		end
		for i, c in { { 0, 4, -2, 12 }, { -8, 3, -4, 9 }, { 8, 3, -4, 9 }, { -14, 2, 2, 7 }, { 14, 2, 2, 7 } } do
			ball(m, "Cloud" .. i, c[4], at(c[1], c[2], c[3]), rgb(255, 255, 255))
		end
		P(m, "Palace", Vector3.new(8, 10, 8), at(0, 11, -2), rgb(255, 250, 240))
		for _, x in { -4.5, 4.5 } do
			cyl(m, "Turret", 12, 3, at(x, 12, -2), rgb(255, 250, 240))
			cyl(m, "Dome", 2, 3.6, at(x, 19, -2), rgb(255, 210, 60), { material = NEON })
		end
		local star = glow(m, "Star", Vector3.new(3, 3, 3), at(0, 18, -2), rgb(255, 230, 120), "Ball")
		Bricks.light(star, rgb(255, 230, 160), 30, 3)
		MapFx.emit(
			P(
				m,
				"RainbowFx",
				Vector3.new(30, 1, 10),
				at(0, 20, 4),
				rgb(255, 255, 255),
				{ transparency = 1, collide = false }
			),
			"Rainbow"
		)
	end,
}

-- Builds zone `zoneId`'s landmark. Returns the model, or nil if the zone has none.
function Landmarks.build(zoneId: number, parent: Instance, origin: CFrame): Model?
	local builder = BUILDERS[zoneId]
	if not builder then
		return nil
	end
	local m = Bricks.model(parent, "Landmark")
	builder(m, function(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end)
	return m
end

Landmarks.ring = ring -- exposed for other scenery builders

return Landmarks
