--!strict
-- Zone 1 Meadow: egg + pet effect recipes (VFX/PetFx). One identity per egg and per pet, sized by rarity
-- (docs/EggPetPlan.md "Effects and motion by rarity": no ground glyph below Legendary). Original pixel sprites
-- meadow_leaf, meadow_blossom and meadow_honey (assets/pet-vfx, drawn by tools/blender/pets: zones/zone01_meadow.py)
-- plus the uploaded soft glow / ring / spark / star sprites.
local rgb = Color3.fromRGB

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local LEAF, SPRIG, GREEN = rgb(112, 204, 72), rgb(180, 238, 116), rgb(150, 255, 110)
local POLLEN, CREAM, PINK = rgb(255, 226, 92), rgb(255, 242, 210), rgb(255, 170, 205)
local HONEY, WARM = rgb(255, 165, 30), rgb(255, 190, 80)
local GLADE = rgb(140, 255, 106)

local Recipes: { [string]: Pair } = {
	-- Common: a soft glow and one soft particle family. Egg = a faint green aura on the ground and leaf motes
	-- rising off the shell; pet = a soft green glow behind it, leaves drifting down round it and a small light.
	SproutPup = {
		egg = {
			layers = {
				{ kind = "disc", sprite = "sack_glow", y = 0.06, size = 6.5, color = GREEN, alpha = 0.55, glow = 1.5 },
				{
					kind = "emit",
					sprite = "meadow_leaf",
					y = 1.4,
					area = { 3.4, 2.4, 3.4 },
					shape = "Cylinder",
					surface = true,
					rate = 2,
					life = { 2.5, 3.5 },
					size = { 0.32, 0.26 },
					speed = 0.15,
					accel = { 0, 0.25, 0 },
					spin = { -60, 60 },
					color = { LEAF, SPRIG },
					alpha = { 1, 0.05, 1 },
				},
			},
		},
		pet = {
			layers = {
				{
					kind = "board",
					sprite = "sack_glow",
					y = 2.5,
					size = 7,
					color = GREEN,
					alpha = 0.6,
					back = 1.2,
					glow = 1.5,
				},
				{
					kind = "emit",
					sprite = "meadow_leaf",
					y = 5.6,
					area = { 4.2, 0.3, 4.2 },
					rate = 1.6,
					life = { 3, 4 },
					size = { 0.4, 0.32 },
					accel = { 0, -0.6, 0 },
					drag = 0.6,
					spin = { -90, 90 },
					color = { LEAF, SPRIG },
					alpha = { 1, 0, 0, 1 },
				},
				{ kind = "light", color = GREEN, y = 2.5, range = 5, brightness = 0.5 },
			},
		},
	},
	-- Uncommon: one extra accent. Egg = a warm aura, honey drops falling off the drip line and two buzzing glints;
	-- pet = a warm glow, pollen balls orbiting with short trails and petals popping out every few seconds.
	BumbleBloc = {
		egg = {
			layers = {
				{ kind = "disc", sprite = "sack_glow", y = 0.06, size = 6.5, color = WARM, alpha = 0.55, glow = 1.5 },
				{
					kind = "emit",
					sprite = "meadow_honey",
					y = 2.3,
					area = { 3.4, 0.2, 3.4 },
					shape = "Cylinder",
					surface = true,
					rate = 1,
					life = { 1.4, 2 },
					size = { 0.26, 0.3 },
					accel = { 0, -2.5, 0 },
					color = HONEY,
					glow = 0.6,
					alpha = { 0, 0, 1 },
				},
				{
					kind = "orbit",
					sprite = "sack_star",
					count = 2,
					radius = 2.4,
					y = 3,
					speed = 2.2,
					bob = 0.5,
					tilt = 25,
					size = 0.8,
					color = POLLEN,
					glow = 1.5,
					trail = { color = POLLEN, life = 0.25, width = 0.1, alpha = { 0.4, 1 }, glow = 1 },
				},
			},
		},
		pet = {
			layers = {
				{
					kind = "board",
					sprite = "sack_glow",
					y = 2.6,
					size = 7,
					color = WARM,
					alpha = 0.6,
					back = 1.5,
					glow = 1.5,
				},
				{
					kind = "orbit",
					count = 3,
					radius = 2.8,
					y = 2.6,
					speed = 1.4,
					bob = 0.4,
					tilt = 18,
					part = { shape = "Ball", size = { 0.26, 0.26, 0.26 }, color = POLLEN, material = "Neon" },
					trail = { color = POLLEN, life = 0.4, width = 0.16, alpha = { 0.3, 1 }, glow = 1 },
				},
				{
					kind = "emit",
					sprite = "meadow_blossom",
					y = 2.8,
					area = { 3, 2, 3 },
					shape = "Sphere",
					surface = true,
					every = { 4, 6 },
					count = 7,
					life = { 0.8, 1.2 },
					size = { 0.2, 0.45, 0 },
					speed = { 1.5, 2.5 },
					spread = 180,
					drag = 2,
					accel = { 0, -1.5, 0 },
					spin = { -150, 150 },
					color = { PINK, CREAM },
					glow = 0.4,
				},
				{ kind = "light", color = WARM, y = 2.5, range = 5, brightness = 0.6 },
			},
		},
	},
	-- Rare: a clear signature effect. Egg = blossoms circling the crown, glints rising off the moss band and a green
	-- pulse ring (its rarity signal); pet = a leaf-wind swirl through the antlers, blossoms drifting off the tines
	-- and, every 9-13 s, its special: a burst of glints from the antlers while it tosses its head (Anim/Pet flourish).
	MeadowStag = {
		egg = {
			layers = {
				{
					kind = "orbit",
					sprite = "meadow_blossom",
					count = 5,
					radius = 2.3,
					y = 3.1,
					speed = 0.9,
					bob = 0.25,
					size = 0.6,
					color = CREAM,
					glow = 1.2,
				},
				{
					kind = "emit",
					sprite = "sack_spark",
					y = 3.05,
					area = { 3.4, 0.4, 3.4 },
					shape = "Cylinder",
					surface = true,
					rate = 3,
					life = { 1.2, 1.8 },
					size = { 0, 0.4, 0 },
					speed = 0.5,
					color = GLADE,
					glow = 1,
				},
				{
					kind = "emit",
					sprite = "sack_ring",
					y = 0.1,
					rate = 0.5,
					life = { 2.2, 2.2 },
					size = { 1.5, 8 },
					speed = 0.01,
					spread = 0,
					face = "flat",
					color = GLADE,
					alpha = { 0.4, 1 },
					glow = 1,
				},
				{ kind = "light", color = GLADE, y = 2.2, range = 6, brightness = 0.7 },
			},
		},
		pet = {
			layers = {
				{
					kind = "orbit",
					sprite = "meadow_leaf",
					count = 6,
					radius = 2.6,
					y = 6.6,
					speed = 1.1,
					bob = 0.4,
					tilt = 14,
					size = 0.7,
					color = SPRIG,
					glow = 1.2,
				},
				{
					kind = "emit",
					sprite = "meadow_blossom",
					at = { 0, 7.2, -2 },
					area = { 4.6, 0.8, 1.4 },
					rate = 2,
					life = { 2.5, 3.5 },
					size = { 0.45, 0.3 },
					accel = { 0, -0.7, 0 },
					drag = 0.8,
					spin = { -120, 120 },
					color = { CREAM, rgb(200, 255, 170) },
					alpha = { 0, 0, 1 },
					glow = 0.3,
				},
				{
					kind = "emit",
					sprite = "sack_star",
					at = { 0, 7, -2 },
					area = { 4.8, 1, 1.6 },
					every = { 9, 13 },
					sync = "bloom",
					count = 14,
					life = { 0.5, 0.9 },
					size = { 0, 0.8, 0 },
					speed = 0.6,
					color = GLADE,
					glow = 1,
				},
				{
					kind = "board",
					sprite = "sack_glow",
					y = 4.4,
					size = 9,
					color = GLADE,
					alpha = 0.65,
					back = 2,
					glow = 1.5,
				},
				{ kind = "light", color = GLADE, at = { 0, 5.2, -2.2 }, range = 7, brightness = 0.8 },
			},
		},
	},
}

return Recipes
