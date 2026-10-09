--!strict
-- CONTRACT FILE: change only via a `contract:` PR.
-- A pet rolls at most one size AND at most one weather mutation.
-- Size: scales the model + income. Weather: VFX overlay + income multiplier.

export type SizeMutation = { scale: number, income: number, chance: number }
export type WeatherMutation = { income: number, chance: number, vfx: string, tint: Color3? }

local Mutations = {
	Size = {
		Tiny = { scale = 0.6, income = 0.8, chance = 0.10 },
		Big = { scale = 1.5, income = 1.5, chance = 0.08 },
		Huge = { scale = 2.2, income = 3, chance = 0.02 },
		Colossal = { scale = 3.2, income = 8, chance = 0.003 },
	} :: { [string]: SizeMutation },

	-- Weather mutations roll more often while that weather event is active (x5 chance),
	-- or in a zone whose `weather` matches (x2 chance).
	Weather = {
		Sunny = { income = 1.5, chance = 0.03, vfx = "SunRays", tint = Color3.fromRGB(255, 220, 120) },
		Rainy = { income = 1.5, chance = 0.03, vfx = "RainDrops" },
		Snowy = { income = 2, chance = 0.02, vfx = "Frost", tint = Color3.fromRGB(200, 235, 255) },
		Stormy = { income = 3, chance = 0.01, vfx = "Lightning" },
		Starfall = { income = 5, chance = 0.004, vfx = "Stardust", tint = Color3.fromRGB(190, 150, 255) },
		Rainbow = { income = 10, chance = 0.001, vfx = "RainbowShift" },
	} :: { [string]: WeatherMutation },

	WeatherEvent = { everySeconds = 600, durationSeconds = 180 },
}

return Mutations
