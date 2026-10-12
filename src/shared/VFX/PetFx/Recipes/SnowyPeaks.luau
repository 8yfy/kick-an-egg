--!strict
-- Zone 6 Snowy Peaks: egg + pet effect recipes (VFX/PetFx). One identity per egg and per pet (docs/EggPetPlan.md).
local rgb = Color3.fromRGB

local ICE, CYAN, SNOW = rgb(150, 215, 255), rgb(120, 235, 255), rgb(240, 248, 255)

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local Recipes: { [string]: Pair } = {
	-- Legendary: dramatic but readable; one major ring, one signature particle family, one accent light.
	-- Egg = snowflake sparks spiralling up, cold breath mist hugging the ground, a frost sigil ring under it;
	-- pet = a snow squall around the body, frost mist, ice-shard glints, a spinning white frost halo on the
	-- ground and a pulsing blue core light.
	IceDragon = {
		egg = {
			layers = {
				{
					kind = "disc",
					sprite = "halo_white",
					y = 0.08,
					size = 7.5,
					color = ICE,
					alpha = 0,
					spin = -25,
					glow = 3,
				},
				{
					kind = "emit",
					sprite = "snowflake_ice",
					y = 0.6,
					area = { 3.8, 0.4, 3.8 },
					shape = "Cylinder",
					surface = true,
					rate = 6,
					life = { 2.2, 3 },
					size = { 0.45, 0.25 },
					speed = { 1.2, 1.8 },
					spread = 15,
					drag = 0.6,
					spin = { 60, 140 },
					color = SNOW,
					glow = 0.8,
					alpha = { 0, 0, 1 },
				},
				{
					kind = "emit",
					sprite = "smoke_gray",
					y = 0.4,
					area = { 4, 0.3, 4 },
					shape = "Cylinder",
					rate = 3,
					life = { 2.5, 3.5 },
					size = { 1.2, 2.4 },
					speed = 0.3,
					spread = 80,
					color = rgb(200, 235, 255),
					alpha = { 1, 0.6, 1 },
					glow = 0.4,
				},
				{
					kind = "emit",
					sprite = "star_cross_large",
					y = 3.2,
					area = { 3.6, 2, 3.6 },
					shape = "Sphere",
					surface = true,
					rate = 3,
					life = { 0.3, 0.6 },
					size = { 0, 0.9, 0 },
					color = CYAN,
					glow = 1,
				},
				{ kind = "light", color = CYAN, y = 2, range = 8, brightness = 1.1, pulse = { 0.7, 1.2, 2.5 } },
			},
		},
		pet = {
			layers = {
				{
					kind = "disc",
					sprite = "halo_white",
					y = 0.08,
					size = 12,
					color = ICE,
					alpha = 0,
					spin = 18,
					pulse = { 0.96, 1.04, 3 },
					glow = 3,
				},
				{
					kind = "board",
					sprite = "soft_glow_white",
					y = 4,
					size = 15,
					alpha = 0.2,
					back = 2.5,
					color = ICE,
					glow = 2,
				},
				{
					kind = "emit",
					sprite = "snowflake_ice",
					y = 8,
					area = { 9, 0.5, 8 },
					rate = 9,
					life = { 3, 4 },
					size = { 0.4, 0.3 },
					speed = 0.6,
					accel = { 0.6, -1.2, 0 },
					drag = 0.5,
					spin = { -90, 90 },
					color = SNOW,
					glow = 0.6,
					alpha = { 1, 0, 0, 1 },
				},
				{
					kind = "emit",
					sprite = "smoke_gray",
					y = 0.5,
					area = { 6, 0.4, 6 },
					shape = "Cylinder",
					rate = 4,
					life = { 3, 4 },
					size = { 1.8, 3.2 },
					speed = 0.25,
					spread = 70,
					color = rgb(200, 235, 255),
					alpha = { 1, 0.65, 1 },
					glow = 0.4,
				},
				{
					kind = "orbit",
					sprite = "shard_ice",
					count = 6,
					radius = 4.6,
					y = 5,
					speed = -0.5,
					bob = 0.6,
					tilt = 10,
					size = 1.1,
					glow = 2,
				},
				{
					kind = "emit",
					sprite = "star_cross_large",
					y = 4.8,
					area = { 5, 3, 6 },
					shape = "Box",
					rate = 4,
					life = { 0.3, 0.6 },
					size = { 0, 1.1, 0 },
					color = CYAN,
					glow = 1,
				},
				{
					kind = "light",
					color = CYAN,
					at = { 0, 3, -2.4 },
					range = 10,
					brightness = 1.4,
					pulse = { 0.6, 1.2, 2.2 },
				},
			},
		},
	},
}

return Recipes
