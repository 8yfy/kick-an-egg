--!strict
-- Zone 9 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	EmberPup = C.build({
		kind = "Quadruped",
		rarity = "Uncommon",
		palette = { main = rgb(70, 55, 55), accent = rgb(255, 120, 30), belly = rgb(110, 85, 80) },
		ears = "pointy",
		tail = "flame",
	}),
	MagmaGolem = C.build({
		kind = "Biped",
		rarity = "Rare",
		palette = {
			main = rgb(60, 45, 45),
			accent = rgb(255, 110, 20),
			belly = rgb(95, 70, 65),
			eye = rgb(255, 160, 40),
			metal = rgb(45, 35, 35),
			glow = rgb(255, 120, 30),
		},
		flames = true,
		armor = true,
	}),
	AshBat = C.build({
		kind = "Flyer",
		rarity = "Epic",
		palette = {
			main = rgb(80, 70, 75),
			accent = rgb(255, 90, 40),
			belly = rgb(130, 110, 110),
			eye = rgb(255, 80, 40),
			metal = rgb(50, 40, 40),
			glow = rgb(255, 110, 30),
		},
		wings = "bat",
		ears = "pointy",
		tail = "spike",
	}),
	InfernoDragon = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(170, 40, 30),
			accent = rgb(255, 150, 30),
			belly = rgb(255, 200, 100),
			eye = rgb(255, 220, 60),
			metal = rgb(60, 30, 25),
			glow = rgb(255, 140, 30),
		},
		wings = "bat",
		horns = "curl",
		spikes = true,
		flames = true,
		tail = "flame",
	}),
}

return Pets
