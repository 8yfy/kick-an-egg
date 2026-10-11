--!strict
-- Zone 11 Jungle Ruins: egg + pet effect recipes (VFX/PetFx). One identity per egg and per pet (docs/EggPetPlan.md).
local rgb = Color3.fromRGB

local JADE, GOLD, FLAME, LEAF = rgb(80, 230, 160), rgb(255, 210, 90), rgb(255, 150, 50), rgb(120, 220, 110)

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local Recipes: { [string]: Pair } = {
	-- Mythic: several layered families, orbiting elements, richer light. Egg = vines spiralling up the shell,
	-- ruin dust at the base, jade glints, a spinning gold relic ring on the ground; pet = a leaf-wind swirl
	-- with trails, feather flames lifting off the wings, gold relic runes orbiting, warm sun rays behind it
	-- and a jade glow.
	QuetzalPhoenix = {
		egg = {
			layers = {
				{
					kind = "disc",
					sprite = "halo_gold",
					y = 0.08,
					size = 8,
					color = GOLD,
					alpha = 0,
					spin = 20,
					glow = 3,
				},
				{
					kind = "orbit",
					sprite = "leaf_green",
					count = 6,
					radius = 2.4,
					y = 2.6,
					speed = 1.3,
					bob = 1.2,
					size = 0.7,
					glow = 1.2,
					color = LEAF,
				},
				{
					kind = "emit",
					sprite = "sand_grain",
					y = 0.3,
					area = { 4.2, 0.3, 4.2 },
					shape = "Cylinder",
					rate = 10,
					life = { 1.2, 2 },
					size = { 0.35, 0.15 },
					speed = { 0.5, 1 },
					spread = 50,
					accel = { 0, -0.5, 0 },
					color = rgb(210, 190, 140),
					alpha = { 0.2, 1 },
				},
				{
					kind = "emit",
					sprite = "prism_glint",
					y = 3,
					area = { 3.8, 3.6, 3.8 },
					shape = "Sphere",
					surface = true,
					rate = 5,
					life = { 0.35, 0.7 },
					size = { 0, 0.8, 0 },
					color = JADE,
					glow = 1,
				},
				{ kind = "light", color = JADE, y = 2.6, range = 9, brightness = 1.1, pulse = { 0.8, 1.2, 3 } },
			},
		},
		pet = {
			layers = {
				{
					kind = "board",
					sprite = "solar_rays",
					y = 5.4,
					size = 16,
					color = GOLD,
					alpha = 0,
					spin = 8,
					back = 2.5,
					glow = 1.6,
				},
				{ kind = "board", sprite = "soft_glow_green", y = 4.5, size = 14, alpha = 0.1, back = 2, glow = 2 },
				{
					kind = "orbit",
					sprite = "leaf_green",
					count = 8,
					radius = 4.2,
					y = 3.4,
					speed = 1.4,
					bob = 1,
					tilt = 18,
					size = 0.8,
					glow = 1.2,
					color = LEAF,
					trail = { color = { JADE, GOLD }, life = 0.5, width = 0.35, alpha = { 0.3, 1 } },
				},
				{
					kind = "orbit",
					sprite = "rune_cyan",
					count = 4,
					radius = 2.4,
					y = 7.2,
					speed = -0.7,
					bob = 0.2,
					size = 0.85,
					glow = 2,
					color = GOLD,
				},
				{
					kind = "emit",
					sprite = "ember_orange",
					y = 7.2,
					area = { 9, 2.4, 1.2 },
					rate = 10,
					life = { 0.8, 1.3 },
					size = { 0.55, 0 },
					speed = { 0.8, 1.5 },
					spread = 25,
					accel = { 0, 1.2, 0 },
					spin = { -90, 90 },
					color = { FLAME, GOLD },
					glow = 1,
				},
				{ kind = "light", color = GOLD, y = 5.5, range = 11, brightness = 1.2, pulse = { 0.8, 1.2, 2.6 } },
				{ kind = "light", color = JADE, y = 2.5, range = 8, brightness = 0.8 },
			},
		},
	},
}

return Recipes
