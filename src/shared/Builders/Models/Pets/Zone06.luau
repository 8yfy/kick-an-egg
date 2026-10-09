--!strict
-- Zone 6 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	SnowBunny = C.build({
		kind = "Quadruped",
		rarity = "Uncommon",
		palette = { main = rgb(250, 252, 255), accent = rgb(170, 210, 245), belly = rgb(220, 235, 250) },
		ears = "long",
		tail = "stub",
	}),
	FrostPenguin = C.build({
		kind = "Biped",
		rarity = "Rare",
		palette = {
			main = rgb(40, 50, 70),
			accent = rgb(255, 170, 50),
			belly = rgb(245, 250, 255),
			eye = rgb(120, 200, 255),
		},
	}),
	YetiBrute = C.build({
		kind = "Biped",
		rarity = "Epic",
		palette = {
			main = rgb(235, 240, 250),
			accent = rgb(120, 170, 230),
			belly = rgb(180, 200, 230),
			eye = rgb(90, 200, 255),
			metal = rgb(150, 190, 230),
			glow = rgb(120, 220, 255),
		},
		mane = true,
		horns = "curl",
	}),
	IceDragon = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(150, 210, 250),
			accent = rgb(230, 250, 255),
			belly = rgb(210, 235, 255),
			eye = rgb(60, 230, 255),
			glow = rgb(120, 240, 255),
		},
		wings = "crystal",
		horns = "straight",
		spikes = true,
		tail = "spike",
		crystals = true,
	}),
}

return Pets
