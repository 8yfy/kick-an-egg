--!strict
-- Zone 1 Meadow: egg + pet effect recipes (VFX/PetFx). One identity per egg and per pet (docs/EggPetPlan.md).
local rgb = Color3.fromRGB

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local Recipes: { [string]: Pair } = {
	-- Common: soft and minimal. Egg = leaf motes rising off a faint green ground aura; pet = leaves falling
	-- around it, pollen sparkles and a soft green glow behind the body.
	SproutPup = {
		egg = {
			layers = {
				{ kind = "disc", sprite = "soft_glow_green", y = 0.06, size = 8, alpha = 0.1, glow = 2.5 },
				{
					kind = "emit",
					sprite = "leaf_green",
					y = 1.4,
					area = { 3.6, 2.6, 3.6 },
					shape = "Cylinder",
					surface = true,
					rate = 2.2,
					life = { 3, 4 },
					size = { 0.34, 0.3 },
					speed = 0.15,
					accel = { 0, 0.18, 0 },
					spin = { -60, 60 },
					alpha = { 1, 0.05, 1 },
				},
				{
					kind = "emit",
					sprite = "pollen_gold",
					y = 2,
					area = { 3.8, 4, 3.8 },
					shape = "Sphere",
					surface = true,
					rate = 4,
					life = { 1, 1.6 },
					size = { 0.5, 0 },
					glow = 1,
					alpha = { 0.2, 0, 1 },
				},
			},
		},
		pet = {
			layers = {
				{ kind = "board", sprite = "soft_glow_green", y = 2.6, size = 10, alpha = 0.15, back = 1.4, glow = 2 },
				{
					kind = "emit",
					sprite = "leaf_green",
					y = 5.4,
					area = { 3.6, 0.3, 3.6 },
					rate = 1.4,
					life = { 3.5, 4.5 },
					size = { 0.4, 0.34 },
					accel = { 0, -0.55, 0 },
					drag = 0.6,
					spin = { -90, 90 },
					alpha = { 1, 0, 0, 1 },
				},
				{
					kind = "emit",
					sprite = "pollen_gold",
					y = 2.4,
					area = { 3.8, 4, 4 },
					shape = "Sphere",
					surface = true,
					rate = 4,
					life = { 1.2, 1.8 },
					size = { 0.55, 0 },
					speed = 0.2,
					accel = { 0, 0.3, 0 },
					glow = 0.8,
					alpha = { 0.1, 1 },
				},
				{ kind = "light", color = rgb(150, 255, 110), y = 2.5, range = 5, brightness = 0.6 },
			},
		},
	},
	-- Rare: a clear signature. Egg = blossom petals circling the crown, pollen rising, a soft green pulse ring
	-- on the ground; pet = a leaf-wind swirl through the antlers, blossoms drifting off the tines, glints.
	MeadowStag = {
		egg = {
			layers = {
				{
					kind = "orbit",
					sprite = "star_pastel",
					count = 5,
					radius = 2.3,
					y = 3.1,
					speed = 0.9,
					bob = 0.25,
					size = 0.7,
					glow = 1.5,
				},
				{
					kind = "emit",
					sprite = "pollen_gold",
					y = 3.05,
					area = { 3.4, 0.4, 3.4 },
					shape = "Cylinder",
					surface = true,
					rate = 3,
					life = { 1.4, 2 },
					size = { 0.45, 0 },
					speed = 0.4,
					glow = 1,
					alpha = { 0.1, 1 },
				},
				{
					kind = "emit",
					sprite = "halo_ring",
					y = 0.1,
					rate = 0.5,
					life = { 2.2, 2.2 },
					size = { 1.5, 9 },
					speed = 0.01,
					spread = 0,
					face = "flat",
					color = rgb(170, 255, 140),
					alpha = { 0.3, 1 },
					glow = 1,
				},
				{ kind = "light", color = rgb(170, 255, 140), y = 2.2, range = 6, brightness = 0.7 },
			},
		},
		pet = {
			layers = {
				{ kind = "board", sprite = "soft_glow_green", y = 4, size = 13, alpha = 0.2, back = 2, glow = 2 },
				{
					kind = "orbit",
					sprite = "leaf_green",
					count = 6,
					radius = 3,
					y = 4.3,
					speed = 1.1,
					bob = 0.5,
					tilt = 14,
					size = 0.75,
					glow = 1.2,
				},
				{
					kind = "emit",
					sprite = "star_pastel",
					y = 6.4,
					area = { 4.8, 0.8, 1.6 },
					rate = 2.2,
					life = { 2.5, 3.5 },
					size = { 0.5, 0.35 },
					accel = { 0, -0.7, 0 },
					drag = 0.8,
					spin = { -120, 120 },
					color = { rgb(255, 170, 205), rgb(255, 235, 140) },
					alpha = { 0, 0, 1 },
				},
				{
					kind = "emit",
					sprite = "star_white",
					y = 6.6,
					area = { 4.6, 1.2, 1.4 },
					rate = 3,
					life = { 0.5, 0.9 },
					size = { 0.1, 0.55, 0 },
					glow = 1,
					color = rgb(220, 255, 170),
				},
				{ kind = "light", color = rgb(160, 255, 130), y = 3.4, range = 6, brightness = 0.7 },
			},
		},
	},
}

return Recipes
