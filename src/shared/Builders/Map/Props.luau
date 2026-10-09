--!strict
-- Partner A. Themed prop specs for the map (BlockBuilder data, feet at y = 0).
-- Props.forZone(id) returns the zone's prop kinds; MapBuilder stamps them with random yaw/scale.
local Builder = require(script.Parent.Parent.BlockBuilder)

type Spec = Builder.Spec
type Opts = { rot: { number }?, material: string?, shape: string?, transparency: number?, light: Color3? }
local rgb = Color3.fromRGB

local function P(name: string, size: { number }, pos: { number }, color: Color3, o: Opts?): Builder.PartSpec
	local opts: Opts = o or {}
	return {
		name = name,
		size = size,
		pos = pos,
		color = color,
		rot = opts.rot,
		material = opts.material,
		shape = opts.shape,
		transparency = opts.transparency,
		light = opts.light,
	}
end
local WHITE, INK = rgb(250, 250, 250), rgb(40, 35, 35)

local function spec(parts: { Builder.PartSpec }): Spec
	return { parts = parts }
end

-- Chunky (reference-style) specs: real size, never upscaled.
local native: { [Spec]: boolean } = {}
local function chunky(parts: { Builder.PartSpec }): Spec
	local s = spec(parts)
	native[s] = true
	return s
end

local function pine(bark: Color3, leaf: Color3, cap: Color3?): Spec
	local parts = { P("Trunk", { 1, 2, 1 }, { 0, 1, 0 }, bark) }
	for i, w in { 4.5, 3.4, 2.2 } do
		local y = 1 + i * 1.4
		table.insert(parts, P("Tier" .. i, { w, 1.4, w }, { 0, y, 0 }, leaf, { rot = { 0, i * 15, 0 } }))
		if cap then
			table.insert(
				parts,
				P("Snow" .. i, { w * 0.8, 0.3, w * 0.8 }, { 0, y + 0.75, 0 }, cap, { rot = { 0, i * 15, 0 } })
			)
		end
	end
	table.insert(parts, P("Tip", { 0.9, 1.2, 0.9 }, { 0, 6.4, 0 }, cap or leaf))
	return spec(parts)
end

-- Chunky kit (approved reference style): whole-stud sizes, axis-aligned offset cubes, studs on every
-- face (Props.studAll), no coplanar faces between overlapping parts (no z-fighting). ~3x a character.
local function chunkyTree(bark: Color3, leaf: Color3, leaf2: Color3): Spec
	local barkDark = bark:Lerp(Color3.new(0, 0, 0), 0.15)
	return chunky({
		P("Trunk", { 3, 6, 3 }, { 0, 3, 0 }, bark),
		P("Root1", { 2, 2, 2 }, { 2, 1, 0.5 }, bark),
		P("Root1b", { 1.5, 1, 1.5 }, { 3.25, 0.5, 1 }, barkDark),
		P("Root2", { 2, 1, 2 }, { -2, 0.5, -1 }, barkDark),
		P("Root3", { 2, 1.5, 1.5 }, { 0.5, 0.75, -2 }, bark),
		P("Leaf1", { 10, 6, 9 }, { 0, 8.5, 0 }, leaf), -- y 5.5..11.5
		P("Leaf2", { 7, 5, 7 }, { 2.5, 11, -1.5 }, leaf), -- pokes out top-right
		P("Leaf3", { 6, 5, 6 }, { -3.5, 7.5, 2.5 }, leaf2), -- hangs lowest, left
		P("Leaf4", { 5, 3, 5 }, { -0.5, 12.75, 0.5 }, leaf2), -- crown
	})
end

local function stoneSlab(stone: Color3, stone2: Color3): Spec
	return chunky({
		P("Slab1", { 6, 1, 5 }, { 0, 0.5, 0 }, stone),
		P("Slab2", { 4, 1, 3 }, { -0.5, 1.5, 0.5 }, stone2),
		P("Chip", { 1.5, 1.4, 1.5 }, { 2.75, 0.7, -2.5 }, stone2),
	})
end

local function grassTuft(g1: Color3, g2: Color3): Spec
	return chunky({
		P("Blade1", { 1, 2, 1 }, { 0, 1, 0 }, g1),
		P("Blade2", { 1, 1.5, 1 }, { 1.2, 0.75, 0.3 }, g2),
		P("Blade3", { 1, 1.8, 1 }, { -0.4, 0.9, 1.2 }, g2),
	})
end

local function bush(leaf: Color3, leaf2: Color3): Spec
	return chunky({
		P("Bush1", { 4, 3, 4 }, { 0, 1.5, 0 }, leaf),
		P("Bush2", { 3, 2.5, 3 }, { 1.8, 2.25, -1.2 }, leaf2),
		P("Bush3", { 2.5, 2, 2.5 }, { -1.6, 1, 1.6 }, leaf2),
	})
end

local function flowers(stem: Color3, petal: Color3, petal2: Color3): Spec
	local parts = {}
	for i, o in { { 0, 0, 1.6 }, { 1.2, 0.8, -0.6 }, { -1.1, 0.5, 0.2 } } do
		local x, z, h = o[1], o[2], o[3]
		local c = if i == 2 then petal2 else petal
		table.insert(parts, P("Stem" .. i, { 0.3, h, 0.3 }, { x, h / 2, z }, stem))
		table.insert(parts, P("PetalA" .. i, { 1.4, 0.3, 0.5 }, { x, h + 0.1, z }, c))
		table.insert(parts, P("PetalB" .. i, { 0.5, 0.3, 1.4 }, { x, h + 0.1, z }, c))
		table.insert(parts, P("Center" .. i, { 0.6, 0.4, 0.6 }, { x, h + 0.2, z }, rgb(255, 215, 60)))
	end
	return spec(parts)
end

local function palm(trunk: Color3, leaf: Color3): Spec
	return spec({
		P("Trunk1", { 1, 2, 1 }, { 0, 1, 0 }, trunk),
		P("Trunk2", { 0.9, 2, 0.9 }, { 0.3, 3, 0 }, trunk, { rot = { 0, 0, -6 } }),
		P("Trunk3", { 0.8, 2, 0.8 }, { 0.7, 5, 0 }, trunk, { rot = { 0, 0, -10 } }),
		P("LeafE", { 3.2, 0.3, 1 }, { 2.4, 6, 0 }, leaf, { rot = { 0, 0, -15 } }),
		P("LeafW", { 3.2, 0.3, 1 }, { -0.6, 6, 0 }, leaf, { rot = { 0, 0, 15 } }),
		P("LeafN", { 1, 0.3, 3.2 }, { 0.9, 6, 1.5 }, leaf, { rot = { 15, 0, 0 } }),
		P("LeafS", { 1, 0.3, 3.2 }, { 0.9, 6, -1.5 }, leaf, { rot = { -15, 0, 0 } }),
		P("Coconut1", { 0.6, 0.6, 0.6 }, { 0.6, 5.6, 0.4 }, rgb(120, 80, 45), { shape = "Ball" }),
		P("Coconut2", { 0.6, 0.6, 0.6 }, { 1.1, 5.6, -0.3 }, rgb(120, 80, 45), { shape = "Ball" }),
	})
end

local function mushroom(cap: Color3, stem: Color3): Spec
	return spec({
		P("Stem", { 1.2, 2.4, 1.2 }, { 0, 1.2, 0 }, stem),
		P("Cap", { 4, 1, 4 }, { 0, 2.9, 0 }, cap),
		P("CapTop", { 2.6, 0.6, 2.6 }, { 0, 3.7, 0 }, cap),
		P("Spot1", { 0.7, 0.12, 0.7 }, { 0.6, 4.05, 0.5 }, WHITE),
		P("Spot2", { 0.8, 0.12, 0.8 }, { 1.4, 3.45, -0.9 }, WHITE),
		P("Spot3", { 0.6, 0.12, 0.6 }, { -1.5, 3.45, 0.6 }, WHITE),
	})
end

local function cactus(green: Color3, bloom: Color3): Spec
	return spec({
		P("Main", { 1.4, 5, 1.4 }, { 0, 2.5, 0 }, green),
		P("ArmL", { 1.4, 0.9, 0.9 }, { -1.3, 2.2, 0 }, green),
		P("ArmLUp", { 0.9, 1.8, 0.9 }, { -1.75, 3.1, 0 }, green),
		P("ArmR", { 1.2, 0.9, 0.9 }, { 1.2, 3, 0 }, green),
		P("ArmRUp", { 0.9, 1.4, 0.9 }, { 1.6, 3.8, 0 }, green),
		P("Bloom", { 0.7, 0.4, 0.7 }, { 0, 5.2, 0 }, bloom),
	})
end

local function snowman(): Spec
	local orange = rgb(255, 140, 30)
	return spec({
		P("Base", { 3, 3, 3 }, { 0, 1.4, 0 }, WHITE, { shape = "Ball" }),
		P("Middle", { 2.2, 2.2, 2.2 }, { 0, 3.3, 0 }, WHITE, { shape = "Ball" }),
		P("Head", { 1.6, 1.6, 1.6 }, { 0, 4.8, 0 }, WHITE, { shape = "Ball" }),
		P("Brim", { 1.6, 0.15, 1.6 }, { 0, 5.5, 0 }, INK),
		P("Hat", { 1.1, 1, 1.1 }, { 0, 6, 0 }, INK),
		P("Nose", { 0.25, 0.25, 0.7 }, { 0, 4.8, -0.95 }, orange),
		P("EyeL", { 0.2, 0.2, 0.1 }, { -0.3, 5.05, -0.76 }, INK),
		P("EyeR", { 0.2, 0.2, 0.1 }, { 0.3, 5.05, -0.76 }, INK),
	})
end

local function lollipop(candy: Color3, swirl: Color3): Spec
	return spec({
		P("Stick", { 0.4, 5, 0.4 }, { 0, 2.5, 0 }, WHITE),
		P("Candy", { 0.6, 3.4, 3.4 }, { 0, 6, 0 }, candy, { shape = "Cylinder", rot = { 0, 90, 0 } }),
		P("Swirl", { 0.7, 2.2, 2.2 }, { 0, 6, 0 }, swirl, { shape = "Cylinder", rot = { 0, 90, 0 } }),
		P("Dot", { 0.8, 0.9, 0.9 }, { 0, 6, 0 }, candy, { shape = "Cylinder", rot = { 0, 90, 0 } }),
	})
end

local function candyCane(red: Color3): Spec
	local parts = {}
	for i = 1, 5 do
		table.insert(
			parts,
			P("Seg" .. i, { 0.7, 0.8, 0.7 }, { 0, i * 0.8 - 0.4, 0 }, if i % 2 == 0 then WHITE else red)
		)
	end
	table.insert(parts, P("Hook", { 0.7, 0.7, 1.4 }, { 0, 4.35, -0.35 }, WHITE))
	table.insert(parts, P("HookTip", { 0.7, 1, 0.7 }, { 0, 3.85, -1.05 }, red))
	return spec(parts)
end

local function coral(c: Color3, tip: Color3): Spec
	return spec({
		P("Base", { 2, 0.6, 2 }, { 0, 0.3, 0 }, rgb(90, 80, 100)),
		P("Branch1", { 0.8, 3, 0.8 }, { 0, 1.8, 0 }, c, { rot = { 0, 0, 10 } }),
		P("Branch2", { 0.7, 2.4, 0.7 }, { 0.9, 1.6, 0.3 }, c, { rot = { 0, 0, -25 } }),
		P("Branch3", { 0.6, 2, 0.6 }, { -0.8, 1.3, -0.3 }, c, { rot = { 0, 0, 30 } }),
		P("Tip1", { 0.9, 0.9, 0.9 }, { -0.25, 3.3, 0 }, tip, { shape = "Ball" }),
		P("Tip2", { 0.8, 0.8, 0.8 }, { 1.4, 2.6, 0.3 }, tip, { shape = "Ball" }),
		P("Tip3", { 0.7, 0.7, 0.7 }, { -1.3, 2.1, -0.3 }, tip, { shape = "Ball" }),
	})
end

local function lavaRock(stone: Color3, glow: Color3, light: boolean): Spec
	return spec({
		P("Rock1", { 3, 2.4, 3 }, { 0, 1.2, 0 }, stone, { rot = { 0, 20, 0 } }),
		P("Rock2", { 2, 1.6, 2 }, { 1.6, 0.8, 1 }, stone, { rot = { 0, 50, 0 } }),
		P(
			"Crack1",
			{ 3.08, 0.18, 3.08 },
			{ 0, 1.3, 0 },
			glow,
			{ rot = { 0, 20, 0 }, material = "Neon", light = if light then glow else nil }
		),
		P("Crack2", { 2.06, 0.15, 2.06 }, { 1.6, 0.7, 1 }, glow, { rot = { 0, 50, 0 }, material = "Neon" }),
		P("Ember", { 0.5, 0.5, 0.5 }, { 0.4, 2.65, 0.3 }, glow, { rot = { 30, 30, 0 }, material = "Neon" }),
	})
end

local function crystal(c: Color3, core: Color3): Spec
	return spec({
		P("Base", { 2.4, 0.4, 2.4 }, { 0, 0.2, 0 }, rgb(60, 55, 80)),
		P("Shard1", { 1.2, 4, 1.2 }, { 0, 2.2, 0 }, c, { rot = { 10, 0, 8 }, material = "Glass", transparency = 0.25 }),
		P("Core", { 0.5, 2.8, 0.5 }, { 0, 2.2, 0 }, core, { rot = { 10, 0, 8 }, material = "Neon" }),
		P(
			"Shard2",
			{ 0.9, 2.8, 0.9 },
			{ 1, 1.4, 0.4 },
			c,
			{ rot = { -8, 0, -20 }, material = "Glass", transparency = 0.25 }
		),
		P(
			"Shard3",
			{ 0.8, 2.2, 0.8 },
			{ -0.9, 1.1, -0.3 },
			c,
			{ rot = { 5, 0, 22 }, material = "Glass", transparency = 0.25 }
		),
	})
end

local function neonLamp(pole: Color3, glow: Color3): Spec
	return spec({
		P("Base", { 1.6, 0.6, 1.6 }, { 0, 0.3, 0 }, pole),
		P("Pole", { 0.8, 8, 0.8 }, { 0, 4, 0 }, pole),
		P("Strip", { 0.2, 6, 0.85 }, { 0.42, 4, 0 }, glow, { material = "Neon" }),
		P("Head", { 2.6, 0.6, 1.2 }, { 0.9, 8.2, 0 }, pole),
		P("Bulb", { 2.2, 0.2, 0.8 }, { 0.9, 7.85, 0 }, glow, { material = "Neon" }),
	})
end

local function tombstone(stone: Color3, moss: Color3): Spec
	return spec({
		P("Base", { 3, 0.4, 1.4 }, { 0, 0.2, 0 }, stone),
		P("Slab", { 2.4, 3, 0.6 }, { 0, 1.9, 0 }, stone, { rot = { -5, 0, 3 } }),
		P("Top", { 1.6, 0.5, 0.6 }, { 0.1, 3.6, 0.15 }, stone, { rot = { -5, 0, 3 } }),
		P("Moss", { 1, 0.15, 0.64 }, { 0.5, 3.3, 0.12 }, moss, { rot = { -5, 0, 3 } }),
		P("Mound", { 2.2, 0.4, 3.2 }, { 0, 0.2, 1.9 }, rgb(70, 60, 50)),
	})
end

local function deadTree(bark: Color3): Spec
	return spec({
		P("Trunk", { 1, 5, 1 }, { 0, 2.5, 0 }, bark, { rot = { 0, 0, 5 } }),
		P("Branch1", { 0.5, 2.6, 0.5 }, { 0.8, 4.6, 0 }, bark, { rot = { 0, 0, -40 } }),
		P("Branch2", { 0.5, 2, 0.5 }, { -0.8, 3.8, 0.2 }, bark, { rot = { 0, 0, 45 } }),
		P("Branch3", { 0.4, 1.6, 0.4 }, { 0.1, 5.6, -0.6 }, bark, { rot = { -30, 0, 0 } }),
	})
end

local function ruinPillar(stone: Color3, moss: Color3): Spec
	return spec({
		P("Base", { 2.4, 0.8, 2.4 }, { 0, 0.4, 0 }, stone),
		P("Column", { 1.6, 5, 1.6 }, { 0, 3.3, 0 }, stone),
		P("Top", { 1.8, 0.6, 1.8 }, { 0.1, 6, 0 }, stone, { rot = { 0, 0, 8 } }),
		P("Vines", { 0.2, 3, 1.65 }, { 0.82, 3, 0 }, moss),
		P("Fallen", { 1.6, 1.6, 1.6 }, { 2, 0.8, 1 }, stone, { rot = { 0, 30, 15 } }),
	})
end

local function cloud(c: Color3): Spec
	return spec({
		P("Puff1", { 4, 2, 3 }, { 0, 1, 0 }, c),
		P("Puff2", { 3, 1.6, 2.4 }, { 1.8, 1.6, 0.4 }, c),
		P("Puff3", { 2.4, 1.4, 2 }, { -1.6, 1.2, -0.2 }, c),
		P("Puff4", { 2, 1.2, 1.8 }, { 0.3, 2.4, 0 }, c),
	})
end

local function barrel(metal: Color3, goo: Color3): Spec
	return spec({
		P("Barrel", { 3, 2.4, 2.4 }, { 0, 1.5, 0 }, metal, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("Band1", { 0.3, 2.5, 2.5 }, { 0, 0.6, 0 }, INK, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("Band2", { 0.3, 2.5, 2.5 }, { 0, 2.4, 0 }, INK, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("Goo", { 0.2, 2, 2 }, { 0, 3.05, 0 }, goo, { shape = "Cylinder", rot = { 0, 0, 90 }, material = "Neon" }),
		P("Drip", { 0.4, 1.2, 0.2 }, { 0.5, 2.5, -1.22 }, goo, { material = "Neon" }),
	})
end

local function gear(metal: Color3, bolt: Color3): Spec
	local parts = {
		P("Stand", { 1.6, 0.6, 2 }, { 0, 0.3, 0 }, INK),
		P("Disc", { 0.8, 4, 4 }, { 0, 2.8, 0 }, metal, { shape = "Cylinder" }),
		P("Hub", { 1, 1.2, 1.2 }, { 0, 2.8, 0 }, bolt),
	}
	for i, a in { 0, 45, 90, 135 } do
		table.insert(parts, P("Teeth" .. i, { 0.8, 0.8, 5 }, { 0, 2.8, 0 }, metal, { rot = { a, 0, 0 } }))
	end
	return spec(parts)
end

local function pipe(metal: Color3, valve: Color3): Spec
	return spec({
		P("Riser", { 1.2, 5, 1.2 }, { 0, 2.5, 0 }, metal),
		P("Elbow", { 1.5, 1.5, 1.5 }, { 0, 5.4, 0 }, INK),
		P("Run", { 3, 1.2, 1.2 }, { 1.8, 5.4, 0 }, metal),
		P("Flange", { 0.3, 1.6, 1.6 }, { 3.2, 5.4, 0 }, INK),
		P("Valve", { 0.3, 1.8, 1.8 }, { 0, 3, -0.75 }, valve, { shape = "Cylinder", rot = { 0, 90, 0 } }),
	})
end

local function star(glow: Color3, stone: Color3): Spec
	return spec({
		P("Pedestal", { 1.4, 1, 1.4 }, { 0, 0.5, 0 }, stone),
		P("Ray1", { 3.2, 0.7, 0.4 }, { 0, 4, 0 }, glow, { material = "Neon" }),
		P("Ray2", { 3.2, 0.7, 0.4 }, { 0, 4, 0 }, glow, { material = "Neon", rot = { 0, 0, 60 } }),
		P("Ray3", { 3.2, 0.7, 0.4 }, { 0, 4, 0 }, glow, { material = "Neon", rot = { 0, 0, 120 } }),
	})
end

local function rainbowPillar(): Spec
	local parts = {}
	for i, c in
		{
			rgb(255, 80, 80),
			rgb(255, 160, 60),
			rgb(255, 230, 70),
			rgb(90, 220, 110),
			rgb(80, 170, 255),
			rgb(170, 110, 255),
		}
	do
		table.insert(parts, P("Band" .. i, { 1.6, 1, 1.6 }, { 0, i - 0.5, 0 }, c, { rot = { 0, i * 15, 0 } }))
	end
	table.insert(parts, P("Star", { 1, 1, 1 }, { 0, 7, 0 }, WHITE, { material = "Neon", rot = { 45, 0, 45 } }))
	return spec(parts)
end

local BARK, LEAF, LEAF_LT = rgb(120, 80, 50), rgb(70, 170, 60), rgb(130, 215, 80)
local SAND, STONE, DARK = rgb(225, 195, 135), rgb(150, 145, 140), rgb(55, 45, 45)
local LAVA, ICE, SNOW = rgb(255, 120, 30), rgb(170, 225, 255), rgb(245, 250, 255)

local MEADOW_TREE = chunkyTree(rgb(190, 55, 70), rgb(95, 195, 45), rgb(70, 165, 35)) -- approved kit colours

-- Two or more kinds per zone (index = zone id). Keep in sync with Config/Zones.
local byZone: { { Spec } } = {
	{ MEADOW_TREE, flowers(LEAF, rgb(255, 120, 170), rgb(250, 250, 255)) }, -- Meadow
	{ palm(rgb(170, 120, 70), rgb(60, 185, 80)), stoneSlab(SAND, rgb(240, 220, 170)) }, -- Sandy Beach
	{ chunkyTree(BARK, rgb(240, 130, 40), rgb(220, 70, 40)), stoneSlab(STONE, rgb(110, 150, 70)) }, -- Autumn Forest
	{ mushroom(rgb(230, 60, 60), rgb(245, 235, 210)), mushroom(rgb(160, 90, 230), rgb(240, 225, 250)) }, -- Mushroom Grove
	{ cactus(rgb(80, 165, 70), rgb(255, 110, 160)), stoneSlab(rgb(210, 150, 90), rgb(235, 190, 120)) }, -- Desert Dunes
	{ pine(BARK, rgb(40, 120, 70), SNOW), snowman() }, -- Snowy Peaks
	{ lollipop(rgb(255, 100, 170), WHITE), candyCane(rgb(240, 50, 70)) }, -- Candy Land
	{ coral(rgb(255, 110, 130), rgb(255, 200, 90)), coral(rgb(60, 200, 200), rgb(170, 120, 255)) }, -- Coral Reef
	{ lavaRock(DARK, LAVA, true), stoneSlab(DARK, rgb(85, 65, 60)) }, -- Volcano
	{ crystal(rgb(120, 240, 255), rgb(200, 255, 255)), crystal(rgb(220, 120, 255), rgb(255, 200, 255)) }, -- Crystal Caves
	{ ruinPillar(rgb(170, 160, 120), rgb(60, 140, 60)), chunkyTree(BARK, rgb(40, 130, 50), rgb(70, 170, 60)) }, -- Jungle Ruins
	{ neonLamp(rgb(35, 35, 50), rgb(255, 40, 200)), neonLamp(rgb(35, 35, 50), rgb(40, 220, 255)) }, -- Neon City
	{ tombstone(rgb(120, 125, 130), rgb(140, 255, 120)), deadTree(rgb(70, 60, 60)) }, -- Haunted Graveyard
	{ cloud(WHITE), ruinPillar(rgb(240, 240, 235), rgb(255, 210, 80)) }, -- Sky Islands
	{ barrel(rgb(90, 100, 70), rgb(170, 255, 40)), deadTree(rgb(80, 70, 50)) }, -- Toxic Swamp
	{ gear(rgb(200, 160, 70), rgb(120, 90, 60)), pipe(rgb(150, 110, 70), rgb(230, 60, 50)) }, -- Clockwork Factory
	{ crystal(ICE, rgb(120, 255, 200)), pine(rgb(90, 110, 140), rgb(130, 190, 220), SNOW) }, -- Frozen Aurora
	{ lavaRock(rgb(70, 30, 25), rgb(255, 170, 40), false), crystal(rgb(255, 150, 60), rgb(255, 230, 120)) }, -- Lava Core
	{ star(rgb(200, 160, 255), rgb(40, 30, 70)), crystal(rgb(150, 100, 255), rgb(230, 200, 255)) }, -- Galaxy Void
	{ cloud(rgb(255, 245, 250)), rainbowPillar() }, -- Rainbow Heaven
}

-- Reference style: no balls or cylinders anywhere. Older specs keep their shape data; this turns every
-- round part into a block (balls shrink a little so they don't look bigger than they were).
for _, list in byZone do
	for _, sp in list do
		for _, part in sp.parts do
			if part.shape == "Ball" then
				part.size = { part.size[1] * 0.85, part.size[2] * 0.85, part.size[3] * 0.85 }
			end
			if part.shape == "Ball" or part.shape == "Cylinder" then
				part.shape = nil
			end
		end
	end
end

local Props = {}

-- Zone 1 (Meadow) kit in the chunky reference style (approved); also the plaza trees.
Props.kit = {
	tree = MEADOW_TREE,
	slab = stoneSlab(rgb(115, 120, 135), rgb(140, 145, 160)),
	tuft = grassTuft(rgb(125, 215, 55), rgb(95, 185, 40)),
	bush = bush(rgb(95, 195, 45), rgb(70, 165, 35)),
}

-- Chunky specs are built at real size; the older small specs get upscaled by MapBuilder.
Props.native = native

local WHITE_ = Color3.new(1, 1, 1)
local GREY, GREY_LT = rgb(115, 120, 135), rgb(140, 145, 160)

-- Bush/tuft colours per zone (index = zone id): main + shade. Keep in sync with Config/Zones.
local FOLIAGE: { { Color3 } } = {
	{ rgb(95, 195, 45), rgb(70, 165, 35) }, -- Meadow
	{ rgb(60, 185, 80), rgb(40, 150, 60) }, -- Sandy Beach
	{ rgb(235, 105, 35), rgb(200, 60, 35) }, -- Autumn Forest
	{ rgb(150, 110, 200), rgb(120, 80, 170) }, -- Mushroom Grove
	{ rgb(110, 170, 70), rgb(80, 140, 55) }, -- Desert Dunes
	{ rgb(40, 120, 70), rgb(30, 95, 55) }, -- Snowy Peaks
	{ rgb(255, 120, 190), rgb(140, 230, 230) }, -- Candy Land
	{ rgb(255, 110, 130), rgb(60, 200, 200) }, -- Coral Reef
	{ rgb(90, 70, 65), rgb(60, 45, 45) }, -- Volcano
	{ rgb(120, 240, 255), rgb(170, 120, 255) }, -- Crystal Caves
	{ rgb(40, 130, 50), rgb(70, 170, 60) }, -- Jungle Ruins
	{ rgb(255, 40, 200), rgb(40, 220, 255) }, -- Neon City
	{ rgb(70, 80, 70), rgb(50, 60, 50) }, -- Haunted Graveyard
	{ rgb(255, 255, 255), rgb(220, 235, 255) }, -- Sky Islands
	{ rgb(130, 170, 40), rgb(90, 120, 30) }, -- Toxic Swamp
	{ rgb(150, 110, 70), rgb(110, 90, 70) }, -- Clockwork Factory
	{ rgb(130, 190, 220), rgb(170, 220, 240) }, -- Frozen Aurora
	{ rgb(110, 40, 30), rgb(80, 30, 20) }, -- Lava Core
	{ rgb(90, 60, 160), rgb(60, 40, 120) }, -- Galaxy Void
	{ rgb(255, 180, 220), rgb(180, 220, 255) }, -- Rainbow Heaven
}

-- Low props for the lane edges and fields: { slab, tuft, bush }. Never tall enough to block the runway view.
function Props.small(zone: number, ground: Color3): { Spec }
	local f = FOLIAGE[zone] or FOLIAGE[1]
	return {
		stoneSlab(GREY:Lerp(ground, 0.15), GREY_LT:Lerp(ground, 0.15)),
		grassTuft(f[1]:Lerp(WHITE_, 0.12), f[2]),
		bush(f[1], f[2]),
	}
end

local SIDES = { "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }

-- Reference style: studs on the sides too. Only studded Plastic parts change (Neon/glass stay clean).
function Props.studAll(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") and d.Material == Enum.Material.Plastic and d.TopSurface == Enum.SurfaceType.Studs then
			for _, face in SIDES do
				(d :: any)[face] = Enum.SurfaceType.Studs
			end
		end
	end
end

function Props.forZone(zone: number): { Spec }
	return byZone[zone] or byZone[1]
end

return Props
