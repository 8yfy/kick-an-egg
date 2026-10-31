--!strict
-- Zone 16 Clockwork Factory: egg + pet effect recipes (VFX/PetFx), one identity per egg and per pet
-- (docs/EggPetPlan.md). Clockwork Titan (Divine, 2026-10-31 remodel to the user's reference): amber clock
-- heart, a turning gear sigil, steam off the shoulders, a vent burst with its flourish.
-- Layer tables and reasoning: KickAnEgg_PremiumPets/RobloxIntegration/VFXSpecifications (LihFolk vault VFX notes):
-- a dark contrast layer under the bright stack, one floor sigil (Legendary+), brightness by screen area, specials
-- that open with a hot frame and sync to the pet's flourish (PetFxSpecial). Sprites: assets/pet-vfx/vfx_v3_*.png.
local rgb = Color3.fromRGB

local AMBER = rgb(255, 184, 74)
local BRASS = rgb(235, 205, 140)
local STEAM = rgb(225, 232, 236)
local IRON = rgb(36, 30, 26)
local WHITE = rgb(255, 255, 255)

type Layer = { [string]: any }
type Pair = { egg: { layers: { Layer } }, pet: { layers: { Layer } } }

local Recipes: { [string]: Pair } = {
	ClockworkTitan = {
		egg = {
			layers = {
				{ kind = "disc", sprite = "v3_shadow", y = 0.05, size = 6, color = IRON, alpha = 0.4, glow = 0.6 },
				{
					kind = "disc",
					sprite = "v3_gear_sigil",
					y = 0.07,
					size = 7,
					color = BRASS,
					alpha = 0.15,
					spin = -8,
					glow = 2,
				},
				{
					kind = "emit",
					sprite = "v3_steam",
					at = { 0, 5.45, 0 },
					area = { 0.9, 0.1, 0.7 },
					rate = 2,
					life = { 1.5, 2.2 },
					size = { 0.4, 1.4 },
					speed = 1.2,
					spread = 10,
					drag = 0.8,
					color = STEAM,
					alpha = { 0.35, 1 },
				},
				{
					kind = "emit",
					sprite = "v3_sparkle",
					at = { 0, 2.55, -1.95 },
					area = { 1.2, 1.2, 0.2 },
					rate = 1,
					life = { 0.3, 0.6 },
					size = { 0, 0.5, 0 },
					color = AMBER,
					glow = 1,
					bright = 8,
				},
				{ kind = "light", color = AMBER, at = { 0, 2.55, -2.3 }, range = 7, brightness = 0.9 },
			},
		},
		pet = {
			layers = {
				{ kind = "disc", sprite = "v3_shadow", y = 0.05, size = 10, color = IRON, alpha = 0.4, glow = 0.6 },
				{
					kind = "disc",
					sprite = "v3_gear_sigil",
					y = 0.08,
					size = 12,
					color = BRASS,
					alpha = 0.12,
					spin = -6,
					glow = 2.2,
				},
				{
					kind = "board",
					sprite = "v3_rays",
					y = 5.6,
					size = 14,
					color = AMBER,
					alpha = 0.5,
					back = 2.4,
					glow = 1.2,
				},
				{
					kind = "emit",
					sprite = "v3_steam",
					at = { 0, 7.6, 0.7 },
					area = { 5.2, 0.2, 0.4 },
					rate = 2.5,
					life = { 1.6, 2.6 },
					size = { 0.6, 2.2 },
					speed = 1.5,
					spread = 12,
					drag = 1,
					color = STEAM,
					alpha = { 0.3, 1 },
				},
				{
					kind = "emit",
					sprite = "v3_sparkle",
					at = { 0, 5.17, -1.4 },
					area = { 1.4, 1.4, 0.2 },
					every = { 9, 13 },
					sync = "vent",
					count = 3,
					life = { 0.1, 0.16 },
					size = { 0, 2.4, 0 },
					color = WHITE,
					glow = 1,
					bright = 25,
				},
				{
					kind = "emit",
					sprite = "v3_steam",
					at = { 0, 2.8, -1.5 },
					area = { 2.6, 3, 0.3 },
					every = { 9, 13 },
					sync = "vent",
					count = 16,
					life = { 0.8, 1.4 },
					size = { 0.5, 2 },
					speed = { 2, 4 },
					spread = 60,
					drag = 2,
					color = STEAM,
					alpha = { 0.25, 1 },
				},
				{ kind = "light", color = AMBER, at = { 0, 5.17, -1.7 }, range = 10, brightness = 1.1 },
			},
		},
	},
}

return Recipes
