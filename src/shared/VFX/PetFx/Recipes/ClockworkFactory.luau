--!strict
-- Zone 16 Clockwork Factory: egg + pet effect recipes (VFX/PetFx). One identity per egg and per pet
-- (docs/EggPetPlan.md).
local rgb = Color3.fromRGB

local TEAL, BRASS, STEAM, SPARK = rgb(70, 240, 220), rgb(255, 205, 110), rgb(236, 242, 248), rgb(255, 190, 90)

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local Recipes: { [string]: Pair } = {
	-- Divine: majestic and ceremonial: sigils, rays, framing light. Egg = steam puffing from its stacks, cog
	-- sparkles, a teal reactor glow and a turning divine sigil on the floor; pet = a giant sigil turning behind
	-- it, steam bursts from the chimneys, forge sparks off the fists, teal rays and a pulsing reactor light.
	ClockworkTitan = {
		egg = {
			layers = {
				{
					kind = "disc",
					sprite = "divine_sigil",
					y = 0.08,
					size = 8.5,
					color = BRASS,
					alpha = 0,
					spin = -15,
					glow = 3,
				},
				{
					kind = "board",
					sprite = "soft_glow_white",
					y = 2.8,
					size = 9,
					alpha = 0.25,
					back = 1.2,
					color = TEAL,
					glow = 2,
				},
				{
					kind = "emit",
					sprite = "smoke_gray",
					y = 5.55,
					area = { 1.9, 0.2, 0.5 },
					rate = 5,
					life = { 1.6, 2.4 },
					size = { 0.5, 1.6 },
					speed = { 1.4, 2.2 },
					spread = 10,
					drag = 0.6,
					spin = { -40, 40 },
					color = STEAM,
					alpha = { 0.3, 1 },
				},
				{
					kind = "emit",
					sprite = "prism_twinkle",
					y = 2.8,
					area = { 4.6, 3.6, 4.6 },
					shape = "Sphere",
					surface = true,
					rate = 5,
					life = { 0.3, 0.6 },
					size = { 0, 0.7, 0 },
					color = BRASS,
					glow = 1,
				},
				{ kind = "light", color = TEAL, y = 2.8, range = 9, brightness = 1.2, pulse = { 0.7, 1.2, 2 } },
			},
		},
		pet = {
			layers = {
				{
					kind = "disc",
					sprite = "divine_sigil",
					at = { 0, 7.7, 1.75 },
					size = 9,
					tilt = 90,
					color = rgb(255, 225, 140),
					alpha = 0,
					spin = 12,
					glow = 3,
				},
				{
					kind = "disc",
					sprite = "divine_sigil",
					y = 0.08,
					size = 12,
					color = BRASS,
					alpha = 0,
					spin = -10,
					glow = 2.5,
				},
				{
					kind = "board",
					sprite = "solar_rays",
					y = 6.5,
					size = 20,
					color = rgb(210, 255, 248),
					alpha = 0,
					spin = -6,
					back = 3,
					glow = 1.4,
				},
				{
					kind = "emit",
					sprite = "smoke_gray",
					at = { 0, 8.7, 1.15 },
					area = { 2.2, 0.2, 0.6 },
					rate = 7,
					life = { 1.8, 2.6 },
					size = { 0.7, 2.4 },
					speed = { 2, 3 },
					spread = 12,
					drag = 0.7,
					spin = { -40, 40 },
					color = STEAM,
					alpha = { 0.2, 1 },
				},
				{
					kind = "emit",
					sprite = "sack_spark",
					y = 3,
					area = { 5.4, 0.6, 1.6 },
					rate = 9,
					life = { 0.4, 0.8 },
					size = { 0.35, 0 },
					speed = { 3, 5 },
					spread = 55,
					accel = { 0, -12, 0 },
					color = SPARK,
					glow = 1,
					face = "vel",
				},
				{
					kind = "light",
					color = TEAL,
					at = { 0, 5.75, -1.8 },
					range = 12,
					brightness = 1.4,
					pulse = { 0.6, 1.2, 1.8 },
				},
				{ kind = "light", color = BRASS, y = 8, range = 10, brightness = 0.8 },
			},
		},
	},
}

return Recipes
