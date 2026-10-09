--!strict
-- Zone 3 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	AcornSquirrel = C.build({
		kind = "Quadruped",
		rarity = "Common",
		palette = { main = rgb(200, 110, 50), accent = rgb(120, 70, 40), belly = rgb(245, 220, 180) },
		ears = "pointy",
		tail = "fluffy",
	}),
	MapleFox = C.build({
		kind = "Quadruped",
		rarity = "Uncommon",
		palette = { main = rgb(235, 120, 40), accent = rgb(200, 50, 40), belly = rgb(250, 235, 215) },
		ears = "pointy",
		tail = "fluffy",
		spots = true,
	}),
	BarkOwl = C.build({
		kind = "Flyer",
		rarity = "Rare",
		palette = {
			main = rgb(140, 95, 60),
			accent = rgb(230, 150, 50),
			belly = rgb(230, 205, 160),
			eye = rgb(255, 190, 40),
		},
		ears = "pointy",
		stripes = true,
	}),
	HarvestBear = C.build({
		kind = "Biped",
		rarity = "Epic",
		palette = {
			main = rgb(160, 95, 50),
			accent = rgb(230, 120, 40),
			belly = rgb(240, 200, 150),
			eye = rgb(255, 160, 40),
			metal = rgb(190, 120, 60),
			glow = rgb(255, 150, 40),
		},
		ears = "round",
		mane = true,
		armor = true,
	}),
}

return Pets
