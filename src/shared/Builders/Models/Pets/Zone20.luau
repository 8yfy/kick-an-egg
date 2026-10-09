--!strict
-- Zone 20 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	RainbowPony = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(255, 250, 255),
			accent = rgb(255, 150, 210),
			belly = rgb(220, 235, 255),
			eye = rgb(255, 120, 200),
			glow = rgb(255, 160, 230),
		},
		horns = "unicorn",
		mane = true,
		tail = "fluffy",
	}),
	PrismPhoenix = C.build({
		kind = "Flyer",
		rarity = "Mythic",
		palette = {
			main = rgb(255, 200, 240),
			accent = rgb(150, 230, 255),
			belly = rgb(255, 240, 200),
			eye = rgb(255, 255, 255),
			glow = rgb(255, 200, 255),
		},
		tail = "flame",
		crystals = true,
		mane = true,
	}),
	HeavenLion = C.build({
		kind = "Quadruped",
		rarity = "Divine",
		palette = {
			main = rgb(255, 235, 180),
			accent = rgb(255, 255, 255),
			belly = rgb(255, 245, 220),
			eye = rgb(255, 220, 120),
			metal = rgb(255, 210, 90),
			glow = rgb(255, 240, 180),
		},
		mane = true,
		wings = "feather",
		ears = "round",
		tail = "long",
		armor = true,
	}),
	PrismSeraph = C.build({
		kind = "Flyer",
		rarity = "Secret",
		palette = {
			main = rgb(255, 255, 255),
			accent = rgb(200, 160, 255),
			belly = rgb(255, 240, 250),
			eye = rgb(255, 255, 255),
			glow = rgb(255, 255, 255),
		},
		wings = "fairy",
		crystals = true,
		mane = true,
	}),
}

return Pets
