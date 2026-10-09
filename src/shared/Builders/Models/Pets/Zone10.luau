--!strict
-- Zone 10 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	GemMole = C.build({
		kind = "Quadruped",
		rarity = "Uncommon",
		palette = { main = rgb(110, 90, 140), accent = rgb(120, 240, 255), belly = rgb(200, 180, 220) },
		crystals = true,
		ears = "round",
	}),
	QuartzGolem = C.build({
		kind = "Biped",
		rarity = "Rare",
		palette = {
			main = rgb(180, 170, 230),
			accent = rgb(130, 240, 255),
			belly = rgb(230, 225, 250),
			eye = rgb(110, 240, 255),
			metal = rgb(120, 110, 170),
		},
		crystals = true,
		armor = true,
	}),
	PrismOwl = C.build({
		kind = "Flyer",
		rarity = "Epic",
		palette = {
			main = rgb(120, 100, 200),
			accent = rgb(150, 240, 255),
			belly = rgb(210, 200, 250),
			eye = rgb(140, 250, 255),
			glow = rgb(140, 240, 255),
		},
		wings = "crystal",
		ears = "pointy",
	}),
	CrystalDrake = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(90, 70, 160),
			accent = rgb(140, 240, 255),
			belly = rgb(200, 190, 240),
			eye = rgb(120, 250, 255),
			glow = rgb(130, 240, 255),
		},
		wings = "crystal",
		horns = "straight",
		crystals = true,
		tail = "spike",
		spikes = true,
	}),
}

return Pets
