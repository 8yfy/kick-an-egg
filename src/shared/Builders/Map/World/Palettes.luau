--!strict
-- Partner A. Role palettes (World.Kit): deliberate 2-3 tone sets per place. Roles not listed fall back to
-- Kit.BASE. Zone palettes are keyed by Config/Zones id.
local Palettes = {}

local rgb = Color3.fromRGB
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass

type Look = Color3 | { color: Color3, material: Enum.Material?, transparency: number?, reflect: number? }
export type Palette = { [string]: Look }

local function merge(a: Palette, b: Palette): Palette
	local out: Palette = {}
	for k, v in a do
		out[k] = v
	end
	for k, v in b do
		out[k] = v
	end
	return out
end
Palettes.merge = merge

-- The hub: warm clay cliffs, bright lawn, cream stone, red / white shop, teal / cream stand.
Palettes.hub = {
	Ground = rgb(108, 198, 70),
	Leaf = rgb(98, 192, 72),
	LeafDark = rgb(64, 152, 60),
	LeafLight = rgb(156, 224, 96),
	Trunk = rgb(128, 86, 54),
	Stone = rgb(216, 158, 104),
	StoneDark = rgb(184, 124, 82),
	Trim = rgb(248, 236, 210),
	Wall = rgb(250, 246, 236),
	Wood = rgb(182, 122, 72),
	WoodDark = rgb(124, 80, 48),
	Water = { color = rgb(70, 178, 245), material = GLASS, transparency = 0.25 },
	Foam = rgb(236, 250, 255),
	Accent = rgb(90, 180, 255),
	Accent2 = rgb(255, 120, 170),
	Accent3 = rgb(150, 230, 100),
	Gold = rgb(255, 188, 28),
	Glow = { color = rgb(255, 226, 150), material = NEON },
	Roof = rgb(58, 64, 84), -- lamp caps
	Metal = { color = rgb(58, 64, 84), reflect = 0.08 },
	Cloth = rgb(225, 55, 62),
	Cloth2 = rgb(252, 248, 240),
}

-- The Boxing Sack Shop: gym red and white, gold trims.
Palettes.shop = merge(Palettes.hub, {
	Roof = rgb(222, 50, 56),
	Roof2 = rgb(252, 248, 242),
	WallTop = rgb(250, 244, 230),
	Trim = { color = rgb(255, 200, 60), reflect = 0.15 },
	Cloth = rgb(226, 44, 52),
	Cloth2 = rgb(252, 250, 246),
	Stone = rgb(214, 210, 222),
	StoneDark = rgb(160, 156, 172),
	Wall = rgb(250, 246, 238),
	Glass = { color = rgb(160, 215, 255), material = GLASS, transparency = 0.3 },
	Metal = { color = rgb(64, 68, 82), reflect = 0.1 },
	Dark = rgb(40, 42, 54),
	Glow = { color = rgb(255, 232, 170), material = NEON },
})

-- The Pet Selling Stand: teal and cream canopy, warm wood, pink paw.
Palettes.stand = merge(Palettes.hub, {
	Cloth = rgb(40, 196, 178),
	Cloth2 = rgb(252, 244, 224),
	Trim = rgb(252, 244, 224),
	WallTop = rgb(252, 244, 224),
	Wood = rgb(186, 126, 72),
	WoodDark = rgb(120, 76, 44),
	Accent = rgb(110, 200, 255),
	Accent2 = rgb(255, 128, 176),
	Accent3 = rgb(255, 214, 90),
	Gold = { color = rgb(255, 200, 70), reflect = 0.2 },
	Metal = rgb(210, 214, 224),
	Dark = rgb(54, 58, 70),
})

-- Pen fences by level: wood (start), white posts with blue rails, then dark posts with gold caps.
Palettes.penFences = {
	merge(Palettes.hub, { Wood = rgb(176, 112, 64), WoodDark = rgb(120, 76, 44), Trim = rgb(214, 160, 100) }),
	merge(Palettes.hub, {
		Wood = rgb(248, 248, 244),
		WoodDark = rgb(110, 185, 255),
		Trim = rgb(110, 185, 255),
		Wall = rgb(248, 248, 244),
	}),
	merge(
		Palettes.hub,
		{ Wood = rgb(52, 58, 76), WoodDark = rgb(255, 200, 60), Trim = { color = rgb(255, 205, 64), reflect = 0.3 } }
	),
}

-- Village house variants (hub): red, blue and green roofs over cream / pastel walls.
Palettes.houses = {
	merge(Palettes.hub, {
		Roof = rgb(204, 62, 52),
		RoofDark = rgb(150, 40, 36),
		Wall = rgb(250, 242, 224),
		WallTop = rgb(250, 242, 224),
		Accent = rgb(90, 170, 240),
	}),
	merge(Palettes.hub, {
		Roof = rgb(64, 120, 200),
		RoofDark = rgb(44, 86, 150),
		Wall = rgb(255, 232, 196),
		WallTop = rgb(255, 232, 196),
		Accent = rgb(240, 110, 90),
	}),
	merge(Palettes.hub, {
		Roof = rgb(76, 160, 92),
		RoofDark = rgb(52, 118, 66),
		Wall = rgb(236, 244, 250),
		WallTop = rgb(236, 244, 250),
		Accent = rgb(250, 190, 60),
	}),
	merge(Palettes.hub, {
		Roof = rgb(150, 92, 200),
		RoofDark = rgb(108, 64, 150),
		Wall = rgb(255, 238, 232),
		WallTop = rgb(255, 238, 232),
		Accent = rgb(100, 200, 180),
	}),
}

Palettes.zones = {} :: { [number]: Palette }

-- 1 Meadow: lush green, warm dirt banks, red-roofed farm, yellow / pink flowers
Palettes.zones[1] = merge(Palettes.hub, {
	Ground = rgb(112, 204, 72),
	Stone = rgb(188, 124, 78),
	StoneDark = rgb(150, 96, 60),
	Leaf = rgb(96, 190, 70),
	LeafDark = rgb(60, 148, 58),
	LeafLight = rgb(160, 222, 92),
	Trunk = rgb(126, 84, 52),
	Accent = rgb(255, 214, 60),
	Accent2 = rgb(255, 120, 170),
	Wall = rgb(250, 244, 230),
	Roof = rgb(214, 58, 52),
	RoofDark = rgb(160, 38, 36),
	Wood = rgb(186, 128, 74),
	WoodDark = rgb(128, 84, 50),
	Gold = rgb(255, 196, 40),
	Sand = rgb(240, 206, 110),
	Dirt = rgb(176, 120, 60),
	Cloth = rgb(220, 60, 60),
	Cloth2 = rgb(252, 250, 244),
})

-- 2 Sandy Beach: golden sand, sandstone banks, palm greens, turquoise water, coral accents
Palettes.zones[2] = merge(Palettes.hub, {
	Ground = rgb(244, 220, 156),
	Stone = rgb(226, 192, 130),
	StoneDark = rgb(196, 158, 102),
	Leaf = rgb(70, 186, 84),
	LeafDark = rgb(40, 146, 72),
	LeafLight = rgb(140, 222, 92),
	Trunk = rgb(172, 122, 72),
	Wood = rgb(198, 152, 98),
	WoodDark = rgb(140, 96, 58),
	Cloth = rgb(60, 176, 240),
	Cloth2 = rgb(252, 250, 244),
	Accent = rgb(255, 122, 82),
	Accent2 = rgb(255, 172, 192),
	Trim = rgb(252, 240, 214),
	Sand = rgb(232, 200, 120),
	Dirt = rgb(190, 150, 90),
	Wall = rgb(250, 240, 220),
	Water = { color = rgb(60, 200, 230), material = GLASS, transparency = 0.25 },
})
Palettes.coastRock = merge(Palettes.zones[2], { Stone = rgb(150, 158, 170), StoneDark = rgb(112, 120, 134) })
Palettes.lighthouse = merge(Palettes.zones[2], {
	Cloth = rgb(222, 52, 52),
	Cloth2 = rgb(252, 250, 246),
	Stone = rgb(160, 164, 176),
	StoneDark = rgb(118, 124, 138),
	Metal = rgb(60, 66, 80),
})

-- 3 Autumn Forest: golden grass, orange / red / yellow canopies, rust roofs
Palettes.zones[3] = merge(Palettes.hub, {
	Ground = rgb(200, 172, 74),
	Stone = rgb(170, 108, 64),
	StoneDark = rgb(132, 82, 50),
	Leaf = rgb(242, 132, 40),
	LeafDark = rgb(208, 72, 40),
	LeafLight = rgb(255, 202, 70),
	Trunk = rgb(112, 70, 44),
	Accent = rgb(248, 140, 30),
	Accent2 = rgb(220, 60, 50),
	Roof = rgb(166, 62, 46),
	RoofDark = rgb(120, 44, 34),
	Wood = rgb(170, 110, 62),
	WoodDark = rgb(112, 70, 42),
	Wall = rgb(246, 232, 204),
	Glow = { color = rgb(255, 200, 120), material = NEON },
})
Palettes.evergreen =
	merge(Palettes.zones[3], { Leaf = rgb(52, 130, 70), LeafDark = rgb(36, 102, 58), LeafLight = rgb(90, 160, 80) })

-- 4 Mushroom Grove: lavender ground, purple stone, red / violet / teal caps, cyan glow
Palettes.zones[4] = merge(Palettes.hub, {
	Ground = rgb(156, 116, 206),
	Stone = rgb(112, 82, 154),
	StoneDark = rgb(86, 62, 124),
	Leaf = rgb(92, 204, 146),
	LeafDark = rgb(52, 154, 116),
	LeafLight = rgb(150, 236, 180),
	Stem = rgb(246, 234, 214),
	Cap = rgb(228, 58, 74),
	Spot = rgb(252, 250, 246),
	Glow = { color = rgb(120, 255, 222), material = NEON },
	Trunk = rgb(112, 74, 64),
	Wood = rgb(172, 112, 72),
	WoodDark = rgb(112, 72, 48),
	Trim = rgb(250, 232, 196),
	Stone2 = rgb(112, 82, 154),
})
Palettes.caps = {
	merge(Palettes.zones[4], { Cap = rgb(228, 58, 74) }),
	merge(Palettes.zones[4], { Cap = rgb(160, 92, 230), Glow = { color = rgb(255, 150, 240), material = NEON } }),
	merge(Palettes.zones[4], { Cap = rgb(54, 196, 196) }),
	merge(Palettes.zones[4], { Cap = rgb(255, 150, 50), Glow = { color = rgb(255, 230, 120), material = NEON } }),
}

-- 5 Desert Dunes: golden sand, layered sandstone, cactus green, terracotta pots, gold
Palettes.zones[5] = merge(Palettes.hub, {
	Ground = rgb(238, 204, 132),
	Stone = rgb(226, 166, 100),
	StoneDark = rgb(192, 128, 76),
	Sand = rgb(244, 216, 154),
	Trim = rgb(248, 232, 196),
	Leaf = rgb(84, 172, 92),
	LeafDark = rgb(58, 138, 76),
	LeafLight = rgb(140, 206, 110),
	Trunk = rgb(150, 104, 64),
	Wood = rgb(204, 132, 80),
	WoodDark = rgb(150, 92, 56),
	Accent = rgb(214, 108, 64),
	Accent2 = rgb(255, 110, 150),
	Gold = rgb(255, 192, 40),
	Glow = { color = rgb(255, 214, 110), material = NEON },
})

-- 6 Snowy Peaks: snow, blue-grey rock, deep pine green, red lodge roofs, ice
Palettes.zones[6] = merge(Palettes.hub, {
	Ground = rgb(240, 246, 255),
	Stone = rgb(150, 164, 188),
	StoneDark = rgb(116, 130, 158),
	Snow = rgb(250, 252, 255),
	Leaf = rgb(52, 128, 96),
	LeafDark = rgb(34, 98, 78),
	LeafLight = rgb(96, 162, 124),
	Trunk = rgb(112, 76, 54),
	Wood = rgb(156, 100, 62),
	WoodDark = rgb(106, 66, 42),
	Roof = rgb(196, 60, 52),
	RoofDark = rgb(146, 40, 36),
	Cloth = rgb(220, 60, 60),
	Accent = rgb(255, 140, 40),
	Dark = rgb(44, 48, 60),
	Ice = { color = rgb(170, 225, 250), material = GLASS, transparency = 0.15 },
	Crystal = { color = rgb(130, 200, 255), material = GLASS, transparency = 0.1 },
	Glow = { color = rgb(255, 214, 140), material = NEON },
})

-- 7 Candy Land: pink frosting ground, mint / pink layered banks, gingerbread, icing, bright candy accents
Palettes.zones[7] = merge(Palettes.hub, {
	Ground = rgb(255, 184, 214),
	Stone = rgb(150, 230, 206),
	StoneDark = rgb(255, 144, 192),
	Wood = rgb(198, 124, 70),
	WoodDark = rgb(112, 64, 42),
	Trim = rgb(255, 250, 250),
	Accent = rgb(255, 88, 140),
	Accent2 = rgb(170, 120, 255),
	Accent3 = rgb(110, 226, 196),
	Gold = rgb(255, 222, 84),
	Cloth = rgb(240, 52, 72),
	Cloth2 = rgb(255, 250, 250),
	Cap = rgb(236, 30, 60),
	Leaf = rgb(255, 150, 200),
	LeafDark = rgb(240, 110, 170),
	LeafLight = rgb(255, 214, 236),
	Trunk = rgb(150, 92, 60),
	Glow = { color = rgb(255, 210, 240), material = NEON },
})
Palettes.candyMint = merge(Palettes.zones[7], {
	Leaf = rgb(140, 236, 200),
	LeafDark = rgb(90, 206, 170),
	LeafLight = rgb(210, 255, 236),
	Accent = rgb(110, 226, 196),
	Accent2 = rgb(255, 222, 84),
})
Palettes.candyLemon = merge(
	Palettes.zones[7],
	{ Accent = rgb(255, 222, 84), Accent2 = rgb(255, 120, 60), Leaf = rgb(255, 230, 120), LeafDark = rgb(255, 200, 80) }
)

-- 8 Coral Reef: pale sea sand, blue-grey reef rock, coral pinks / oranges / purples, kelp green, cyan glow
Palettes.zones[8] = merge(Palettes.hub, {
	Ground = rgb(232, 214, 172),
	Stone = rgb(112, 172, 194),
	StoneDark = rgb(82, 138, 164),
	Accent = rgb(255, 112, 104),
	Accent2 = rgb(255, 170, 64),
	Leaf = rgb(62, 172, 112),
	LeafDark = rgb(40, 132, 98),
	LeafLight = rgb(120, 214, 150),
	Wood = rgb(126, 92, 66),
	WoodDark = rgb(86, 60, 46),
	Gold = rgb(255, 202, 60),
	Cloth = rgb(196, 52, 52),
	Cloth2 = rgb(222, 226, 220),
	Trim = rgb(250, 236, 220),
	Glow = { color = rgb(110, 240, 255), material = NEON },
	Water = { color = rgb(40, 176, 222), material = GLASS, transparency = 0.35 },
})
Palettes.corals = {
	merge(Palettes.zones[8], { Accent = rgb(255, 112, 104), Accent2 = rgb(255, 170, 64) }),
	merge(Palettes.zones[8], { Accent = rgb(176, 100, 240), Accent2 = rgb(255, 214, 80) }),
	merge(Palettes.zones[8], { Accent = rgb(64, 210, 220), Accent2 = rgb(255, 92, 140) }),
	merge(Palettes.zones[8], { Accent = rgb(255, 150, 200), Accent2 = rgb(120, 220, 140) }),
}

-- 9 Volcano: warm dark basalt (not black), ash ground, glowing lava, charcoal trees
Palettes.zones[9] = merge(Palettes.hub, {
	Ground = rgb(104, 86, 80),
	Stone = rgb(96, 78, 74),
	StoneDark = rgb(66, 54, 54),
	Trunk = rgb(56, 46, 44),
	Dark = rgb(36, 30, 44),
	Leaf = rgb(120, 110, 80),
	LeafDark = rgb(90, 80, 64),
	Lava = { color = rgb(255, 112, 24), material = NEON },
	Glow = { color = rgb(255, 150, 60), material = NEON },
})

-- 10 Crystal Caves: deep violet rock, blue / purple / cyan crystals, cool glow
Palettes.zones[10] = merge(Palettes.hub, {
	Ground = rgb(92, 78, 140),
	Stone = rgb(104, 92, 156),
	StoneDark = rgb(70, 60, 116),
	Crystal = { color = rgb(130, 220, 255), material = GLASS, transparency = 0.12 },
	Glow = { color = rgb(190, 130, 255), material = NEON },
	Accent = rgb(150, 110, 230),
	Leaf = rgb(110, 210, 200),
	LeafDark = rgb(70, 170, 170),
	Trunk = rgb(80, 66, 110),
})
Palettes.crystalPink = merge(Palettes.zones[10], {
	Crystal = { color = rgb(255, 150, 230), material = GLASS, transparency = 0.12 },
	Glow = { color = rgb(120, 230, 255), material = NEON },
})

-- 11 Jungle Ruins: deep jungle greens, mossy grey-green stone, gold idols
Palettes.zones[11] = merge(Palettes.hub, {
	Ground = rgb(70, 150, 66),
	Stone = rgb(150, 156, 128),
	StoneDark = rgb(110, 120, 96),
	Leaf = rgb(58, 160, 66),
	LeafDark = rgb(34, 118, 52),
	LeafLight = rgb(120, 200, 80),
	Trunk = rgb(104, 72, 48),
	Gold = rgb(255, 198, 50),
	Dark = rgb(36, 40, 34),
	Glow = { color = rgb(140, 255, 160), material = NEON },
	Water = { color = rgb(60, 170, 170), material = GLASS, transparency = 0.25 },
})

-- 12 Neon City: dark slate street, coloured towers, magenta / cyan / yellow neon
Palettes.zones[12] = merge(Palettes.hub, {
	Ground = rgb(58, 60, 80),
	Stone = rgb(80, 84, 110),
	StoneDark = rgb(52, 54, 74),
	Wall = rgb(86, 90, 130),
	Trim = rgb(150, 156, 196),
	Metal = rgb(70, 74, 96),
	Glass = { color = rgb(120, 180, 255), material = GLASS, transparency = 0.25 },
	Glow = { color = rgb(255, 236, 170), material = NEON },
	Dark = rgb(30, 32, 44),
	Cloth = rgb(255, 70, 160),
	Cloth2 = rgb(250, 250, 255),
	Leaf = rgb(70, 200, 150),
	LeafDark = rgb(40, 160, 120),
})
Palettes.cityWalls = {
	merge(Palettes.zones[12], { Wall = rgb(96, 100, 150) }),
	merge(Palettes.zones[12], { Wall = rgb(150, 92, 170), Neon = { color = rgb(60, 230, 255), material = NEON } }),
	merge(Palettes.zones[12], { Wall = rgb(70, 130, 170), Neon = { color = rgb(255, 230, 60), material = NEON } }),
	merge(Palettes.zones[12], { Wall = rgb(190, 110, 110), Neon2 = { color = rgb(255, 60, 200), material = NEON } }),
}

-- 13 Haunted Graveyard: grey-green moss, slate stone, purple roofs, green ghost glow (kid-friendly, not too dark)
Palettes.zones[13] = merge(Palettes.hub, {
	Ground = rgb(92, 120, 96),
	Stone = rgb(150, 156, 162),
	StoneDark = rgb(104, 110, 120),
	Wall = rgb(120, 110, 140),
	Trim = rgb(196, 190, 210),
	Roof = rgb(96, 70, 140),
	RoofDark = rgb(70, 50, 110),
	Trunk = rgb(84, 70, 70),
	Leaf = rgb(96, 140, 90),
	LeafDark = rgb(70, 110, 72),
	Glow = { color = rgb(150, 255, 140), material = NEON },
	Accent = rgb(255, 140, 40),
	Dark = rgb(40, 38, 52),
	WoodDark = rgb(80, 60, 52),
})

-- 14 Sky Islands: bright sky grass, white / pale-blue stone, cloud white, gold, blue roofs
Palettes.zones[14] = merge(Palettes.hub, {
	Ground = rgb(130, 214, 96),
	Stone = rgb(210, 214, 228),
	StoneDark = rgb(170, 178, 200),
	Dirt = rgb(176, 136, 104),
	Wall = rgb(250, 250, 255),
	Trim = rgb(255, 214, 90),
	Roof = rgb(90, 150, 240),
	Snow = rgb(255, 255, 255),
	Gold = rgb(255, 204, 60),
	Leaf = rgb(110, 210, 90),
	LeafDark = rgb(70, 170, 80),
	Glow = { color = rgb(255, 240, 180), material = NEON },
	Water = { color = rgb(120, 210, 255), material = GLASS, transparency = 0.3 },
})

-- 15 Toxic Swamp: murky olive ground, mossy dark stone, sickly purple / green accents, neon-green brew
Palettes.zones[15] = merge(Palettes.hub, {
	Ground = rgb(98, 118, 62),
	Stone = rgb(96, 104, 80),
	StoneDark = rgb(70, 78, 60),
	Leaf = rgb(110, 150, 60),
	LeafDark = rgb(76, 110, 50),
	Trunk = rgb(86, 70, 54),
	Moss = rgb(132, 170, 70),
	Brew = { color = rgb(150, 255, 60), material = NEON },
	Glow = { color = rgb(170, 255, 90), material = NEON },
	Water = { color = rgb(90, 120, 60), material = GLASS, transparency = 0.2 },
	Cap = rgb(150, 80, 200),
	Stem = rgb(220, 230, 190),
	Accent = rgb(240, 200, 40),
	Metal = rgb(56, 60, 70),
	Wall = rgb(150, 132, 104),
	Roof = rgb(96, 110, 70),
	RoofDark = rgb(70, 82, 52),
})

-- 16 Clockwork Factory: brick red / brown, brass gears, copper pipes, steel
Palettes.zones[16] = merge(Palettes.hub, {
	Ground = rgb(150, 120, 92),
	Stone = rgb(170, 100, 72),
	StoneDark = rgb(124, 72, 54),
	Wall = rgb(176, 90, 64),
	Trim = rgb(232, 200, 140),
	Roof = rgb(84, 88, 100),
	Gear = rgb(220, 170, 64),
	Pipe = rgb(200, 116, 70),
	Pipe2 = rgb(160, 166, 180),
	Metal = rgb(92, 96, 110),
	Dark = rgb(48, 50, 60),
	Accent = rgb(80, 180, 230),
	Wood = rgb(176, 120, 70),
	Glass = { color = rgb(150, 210, 240), material = GLASS, transparency = 0.3 },
	Lava = { color = rgb(255, 150, 50), material = NEON },
})

-- 17 Frozen Aurora: ice blue and white, teal / violet crystals, aurora greens
Palettes.zones[17] = merge(Palettes.hub, {
	Ground = rgb(214, 236, 250),
	Stone = rgb(150, 190, 220),
	StoneDark = rgb(110, 150, 190),
	Snow = rgb(250, 253, 255),
	Ice = { color = rgb(160, 220, 250), material = GLASS, transparency = 0.15 },
	Crystal = { color = rgb(120, 255, 220), material = GLASS, transparency = 0.1 },
	Glow = { color = rgb(140, 255, 210), material = NEON },
	Trim = rgb(220, 240, 255),
	Trunk = rgb(120, 140, 170),
	Leaf = rgb(160, 210, 240),
	LeafDark = rgb(120, 180, 220),
})

-- 18 Lava Core: obsidian and dark slate (cooler and more geometric than the Volcano), bright yellow-orange seams
Palettes.zones[18] = merge(Palettes.hub, {
	Ground = rgb(70, 62, 74),
	Stone = rgb(84, 76, 92),
	StoneDark = rgb(56, 50, 64),
	Dark = rgb(34, 30, 42),
	Metal = rgb(110, 100, 120),
	Lava = { color = rgb(255, 176, 40), material = NEON },
	Core = { color = rgb(255, 120, 40), material = GLASS, transparency = 0.45 },
	Glow = { color = rgb(255, 190, 80), material = NEON },
})

-- 19 Galaxy Void: deep indigo ground with violet stone (readable, not black), cosmic purples / blues, white stars
Palettes.zones[19] = merge(Palettes.hub, {
	Ground = rgb(56, 46, 104),
	Stone = rgb(84, 70, 140),
	StoneDark = rgb(58, 48, 108),
	Metal = rgb(100, 96, 150),
	Crystal = { color = rgb(190, 140, 255), material = GLASS, transparency = 0.1 },
	Glow = { color = rgb(110, 150, 255), material = NEON },
	Ring = rgb(150, 130, 220),
	Energy = { color = rgb(170, 100, 240), material = NEON, transparency = 0.45 },
	Energy2 = { color = rgb(90, 220, 255), material = NEON, transparency = 0.3 },
})

-- 20 Rainbow Heaven: cloud white, soft gold, pastel sky ground, full rainbow accents
Palettes.zones[20] = merge(Palettes.hub, {
	Ground = rgb(250, 248, 255),
	Stone = rgb(240, 236, 255),
	StoneDark = rgb(214, 210, 240),
	Wall = rgb(255, 255, 255),
	Trim = rgb(255, 230, 150),
	Gold = { color = rgb(255, 204, 60), reflect = 0.1 },
	Glow = { color = rgb(255, 246, 200), material = NEON },
	Glass = { color = rgb(200, 230, 255), material = GLASS, transparency = 0.3 },
	Leaf = rgb(170, 230, 160),
	LeafDark = rgb(130, 210, 140),
	LeafLight = rgb(220, 250, 200),
	Accent = rgb(255, 150, 200),
	Accent2 = rgb(150, 200, 255),
})

return Palettes
