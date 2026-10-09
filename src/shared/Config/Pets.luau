--!strict
-- CONTRACT FILE (schema). Partner B adds entries freely; renaming fields needs a `contract:` PR.
-- Every pet has a matching egg. `model` is the key in Builders/Models/Pets and Builders/Models/Eggs.
-- Weights are relative within a zone. Target: 3–5 pets per zone, 60–100 total.

export type Pet = {
	id: string,
	name: string,
	zone: number,
	rarity: string,
	weight: number,
	income: number, -- $/s before multipliers
	hatchSeconds: number,
	model: string,
}

local Pets: { Pet } = {
	-- Zone 1: Meadow (examples; Partner B fills the rest)
	{ id = "sprout_pup", name = "Sprout Pup", zone = 1, rarity = "Common", weight = 60, income = 1, hatchSeconds = 10, model = "SproutPup" },
	{ id = "bumble_bloc", name = "Bumble Bloc", zone = 1, rarity = "Uncommon", weight = 30, income = 3, hatchSeconds = 20, model = "BumbleBloc" },
	{ id = "meadow_stag", name = "Meadow Stag", zone = 1, rarity = "Rare", weight = 10, income = 8, hatchSeconds = 45, model = "MeadowStag" },

	-- Zone 20: Rainbow Heaven (example top end)
	{ id = "prism_seraph", name = "Prism Seraph", zone = 20, rarity = "Secret", weight = 1, income = 250000, hatchSeconds = 1800, model = "PrismSeraph" },
}

return Pets
