--!strict
-- Zone 15 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	SludgeSlime = C.build({
		kind = "Floater",
		rarity = "Rare",
		palette = {
			main = rgb(120, 190, 40),
			accent = rgb(90, 60, 120),
			belly = rgb(190, 240, 100),
			eye = rgb(200, 255, 60),
		},
		spots = true,
		ghost = true,
	}),
	BogToad = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(90, 120, 50),
			accent = rgb(170, 255, 40),
			belly = rgb(190, 210, 120),
			eye = rgb(255, 240, 60),
			glow = rgb(170, 255, 40),
		},
		spots = true,
		spikes = true,
		ears = "fin",
	}),
	ToxicHydra = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(70, 110, 60),
			accent = rgb(170, 255, 40),
			belly = rgb(150, 190, 110),
			eye = rgb(200, 255, 60),
			glow = rgb(170, 255, 40),
		},
		spikes = true,
		horns = "curl",
		tail = "spike",
		crystals = true,
	}),
	PlagueWyrm = C.build({
		kind = "Quadruped",
		rarity = "Mythic",
		palette = {
			main = rgb(90, 60, 110),
			accent = rgb(170, 255, 40),
			belly = rgb(150, 120, 170),
			eye = rgb(170, 255, 40),
			glow = rgb(170, 255, 40),
		},
		wings = "bat",
		crystals = true,
		spikes = true,
		horns = "straight",
		tail = "spike",
	}),
}

return Pets
