--!strict
-- Zone 7 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	GummyBear = C.build({
		kind = "Biped",
		rarity = "Uncommon",
		palette = { main = rgb(255, 120, 150), accent = rgb(255, 220, 120), belly = rgb(255, 190, 210) },
		ears = "round",
		ghost = true,
	}),
	LolliPup = C.build({
		kind = "Quadruped",
		rarity = "Rare",
		palette = {
			main = rgb(255, 170, 210),
			accent = rgb(140, 230, 230),
			belly = rgb(255, 240, 250),
			eye = rgb(255, 80, 160),
		},
		ears = "pointy",
		tail = "long",
		spots = true,
	}),
	CottonSheep = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(255, 230, 245),
			accent = rgb(180, 150, 255),
			belly = rgb(255, 210, 235),
			eye = rgb(160, 110, 255),
			glow = rgb(255, 140, 220),
		},
		mane = true,
		horns = "curl",
		ears = "round",
	}),
	SugarUnicorn = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(255, 245, 250),
			accent = rgb(255, 150, 210),
			belly = rgb(200, 240, 255),
			eye = rgb(255, 100, 200),
			glow = rgb(255, 140, 220),
		},
		horns = "unicorn",
		mane = true,
		wings = "fairy",
		tail = "fluffy",
	}),
}

return Pets
