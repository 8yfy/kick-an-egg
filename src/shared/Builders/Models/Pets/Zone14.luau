--!strict
-- Zone 14 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	CloudSheep = C.build({
		kind = "Quadruped",
		rarity = "Rare",
		palette = {
			main = rgb(250, 250, 255),
			accent = rgb(170, 200, 255),
			belly = rgb(225, 230, 250),
			eye = rgb(90, 140, 255),
		},
		mane = true,
		ears = "round",
		tail = "stub",
	}),
	SkyGriffin = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(210, 170, 90),
			accent = rgb(250, 250, 255),
			belly = rgb(240, 225, 180),
			eye = rgb(255, 200, 60),
			glow = rgb(255, 230, 120),
		},
		wings = "feather",
		ears = "pointy",
		tail = "long",
		mane = true,
	}),
	StormEagle = C.build({
		kind = "Flyer",
		rarity = "Legendary",
		palette = {
			main = rgb(70, 80, 120),
			accent = rgb(255, 240, 120),
			belly = rgb(200, 210, 240),
			eye = rgb(255, 240, 120),
			metal = rgb(150, 160, 200),
			glow = rgb(180, 220, 255),
		},
		mane = true,
		armor = true,
	}),
	CelestialWhale = C.build({
		kind = "Fish",
		rarity = "Mythic",
		palette = {
			main = rgb(90, 120, 220),
			accent = rgb(240, 245, 255),
			belly = rgb(190, 210, 255),
			eye = rgb(255, 255, 200),
			glow = rgb(180, 220, 255),
		},
		crystals = true,
		spots = true,
	}),
}

return Pets
