--!strict
-- Zone 19 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	StarCat = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(50, 40, 90),
			accent = rgb(255, 240, 150),
			belly = rgb(90, 80, 140),
			eye = rgb(255, 240, 150),
			glow = rgb(200, 160, 255),
		},
		ears = "pointy",
		tail = "long",
		spots = true,
	}),
	NebulaJelly = C.build({
		kind = "Floater",
		rarity = "Legendary",
		palette = {
			main = rgb(150, 90, 230),
			accent = rgb(255, 140, 220),
			belly = rgb(200, 170, 255),
			eye = rgb(255, 220, 255),
			glow = rgb(220, 150, 255),
		},
		ghost = true,
		crystals = true,
	}),
	CosmicDragon = C.build({
		kind = "Quadruped",
		rarity = "Mythic",
		palette = {
			main = rgb(40, 30, 80),
			accent = rgb(170, 110, 255),
			belly = rgb(90, 70, 150),
			eye = rgb(255, 240, 160),
			glow = rgb(190, 130, 255),
		},
		wings = "crystal",
		horns = "straight",
		crystals = true,
		spikes = true,
		tail = "spike",
	}),
	VoidEmperor = C.build({
		kind = "Biped",
		rarity = "Divine",
		palette = {
			main = rgb(25, 20, 45),
			accent = rgb(170, 90, 255),
			belly = rgb(60, 50, 90),
			eye = rgb(200, 140, 255),
			metal = rgb(50, 40, 80),
			glow = rgb(180, 100, 255),
		},
		armor = true,
		horns = "curl",
		wings = "bat",
		crystals = true,
	}),
}

return Pets
