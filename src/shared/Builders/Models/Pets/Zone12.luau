--!strict
-- Zone 12 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	NeonCat = C.build({
		kind = "Quadruped",
		rarity = "Rare",
		palette = {
			main = rgb(40, 40, 60),
			accent = rgb(255, 40, 200),
			belly = rgb(70, 70, 95),
			eye = rgb(255, 60, 220),
		},
		ears = "pointy",
		tail = "long",
		stripes = true,
	}),
	CyberPup = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(60, 70, 90),
			accent = rgb(40, 220, 255),
			belly = rgb(110, 120, 140),
			eye = rgb(40, 230, 255),
			metal = rgb(90, 100, 120),
			glow = rgb(40, 230, 255),
		},
		armor = true,
		ears = "pointy",
		tail = "spike",
	}),
	MechTitan = C.build({
		kind = "Biped",
		rarity = "Legendary",
		palette = {
			main = rgb(90, 95, 115),
			accent = rgb(255, 60, 200),
			belly = rgb(140, 145, 165),
			eye = rgb(255, 60, 220),
			metal = rgb(60, 65, 80),
			glow = rgb(255, 60, 220),
		},
		armor = true,
		horns = "straight",
		spikes = true,
	}),
	HoloDragon = C.build({
		kind = "Quadruped",
		rarity = "Mythic",
		palette = {
			main = rgb(90, 220, 255),
			accent = rgb(255, 80, 220),
			belly = rgb(200, 245, 255),
			eye = rgb(255, 90, 230),
			glow = rgb(90, 230, 255),
		},
		wings = "crystal",
		horns = "curl",
		ghost = true,
		spikes = true,
		tail = "spike",
	}),
}

return Pets
