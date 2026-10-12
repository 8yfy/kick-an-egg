--!strict
-- Zone 2 Sandy Beach: egg + pet effect recipes (VFX/PetFx). One identity per egg and per pet (docs/EggPetPlan.md).
local rgb = Color3.fromRGB

local AQUA, CYAN, FOAM = rgb(90, 215, 245), rgb(140, 245, 255), rgb(235, 252, 255)

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local Recipes: { [string]: Pair } = {
	-- Epic: richer, layered. Egg = bubble trails rising off the shell, foam specks on the wave crest, a tide ring
	-- pulsing on the sand; pet = water mist, bubble streams from the tail, a glowing tide halo, foam glints.
	TideSpirit = {
		egg = {
			layers = {
				{
					kind = "emit",
					sprite = "bubble_aqua",
					y = 0.8,
					area = { 3.4, 0.3, 3.4 },
					shape = "Cylinder",
					surface = true,
					rate = 5,
					life = { 1.6, 2.4 },
					size = { 0.35, 0.6 },
					speed = { 0.8, 1.4 },
					spread = 12,
					drag = 0.4,
					accel = { 0, 0.4, 0 },
					alpha = { 0.1, 0.1, 1 },
					glow = 0.4,
				},
				{
					kind = "emit",
					sprite = "star_white",
					y = 2.2,
					area = { 3.5, 0.4, 3.5 },
					shape = "Cylinder",
					surface = true,
					rate = 6,
					life = { 0.4, 0.8 },
					size = { 0, 0.45, 0 },
					color = FOAM,
					glow = 1,
				},
				{
					kind = "emit",
					sprite = "halo_ring",
					y = 0.1,
					rate = 0.7,
					life = { 1.8, 1.8 },
					size = { 2, 10 },
					speed = 0.01,
					spread = 0,
					face = "flat",
					color = CYAN,
					alpha = { 0.2, 1 },
					glow = 1,
				},
				{
					kind = "orbit",
					sprite = "droplet_aqua",
					count = 4,
					radius = 2.6,
					y = 3.3,
					speed = -0.8,
					bob = 0.35,
					size = 0.7,
					glow = 1.6,
				},
				{ kind = "light", color = CYAN, y = 2.2, range = 7, brightness = 0.9 },
			},
		},
		pet = {
			layers = {
				{
					kind = "board",
					sprite = "soft_glow_white",
					y = 3.6,
					size = 12,
					alpha = 0.15,
					back = 1.5,
					color = AQUA,
					glow = 2.5,
				},
				{
					kind = "disc",
					sprite = "halo_ring",
					y = 6.05,
					size = 4.4,
					color = CYAN,
					alpha = 0,
					spin = 40,
					pulse = { 0.94, 1.06, 2 },
					glow = 5,
				},
				{
					kind = "emit",
					sprite = "smoke_gray",
					y = 1.3,
					area = { 3.6, 0.6, 3.6 },
					shape = "Cylinder",
					rate = 2.5,
					life = { 2.5, 3.5 },
					size = { 1, 2 },
					speed = 0.2,
					spin = { -20, 20 },
					color = rgb(150, 225, 255),
					alpha = { 1, 0.75, 1 },
					glow = 0.3,
				},
				{
					kind = "emit",
					sprite = "bubble_aqua",
					at = { 0, 0.9, 1.7 },
					area = { 1, 0.6, 1 },
					shape = "Sphere",
					rate = 6,
					life = { 1.6, 2.4 },
					size = { 0.3, 0.55 },
					speed = { 1, 1.6 },
					spread = 20,
					drag = 0.5,
					alpha = { 0.1, 0.1, 1 },
					glow = 0.4,
				},
				{
					kind = "emit",
					sprite = "prism_twinkle",
					y = 6.05,
					area = { 2.6, 0.2, 2.6 },
					shape = "Cylinder",
					surface = true,
					rate = 5,
					life = { 0.4, 0.7 },
					size = { 0, 0.6, 0 },
					color = FOAM,
					glow = 1,
				},
				{ kind = "light", color = CYAN, y = 3.5, range = 8, brightness = 1, pulse = { 0.8, 1.2, 3 } },
			},
		},
	},
}

return Recipes
