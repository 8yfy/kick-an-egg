--!strict
-- Zone 4 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	SporeSlime = C.build({
		kind = "Floater",
		rarity = "Common",
		palette = { main = rgb(190, 110, 230), accent = rgb(240, 70, 70), belly = rgb(250, 220, 250) },
		spots = true,
	}),
	CapBunny = C.build({
		kind = "Quadruped",
		rarity = "Uncommon",
		palette = { main = rgb(245, 235, 225), accent = rgb(230, 70, 70), belly = rgb(255, 200, 210) },
		ears = "long",
		tail = "stub",
		spots = true,
	}),
	ToadKnight = C.build({
		kind = "Biped",
		rarity = "Rare",
		palette = {
			main = rgb(110, 180, 80),
			accent = rgb(230, 70, 70),
			belly = rgb(230, 240, 190),
			eye = rgb(250, 220, 60),
			metal = rgb(170, 170, 185),
		},
		armor = true,
		spots = true,
	}),
	FungalDragon = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(140, 80, 170),
			accent = rgb(240, 80, 90),
			belly = rgb(240, 210, 240),
			eye = rgb(170, 255, 120),
			glow = rgb(170, 255, 120),
		},
		wings = "bat",
		horns = "curl",
		spikes = true,
		tail = "spike",
	}),
}

return Pets
