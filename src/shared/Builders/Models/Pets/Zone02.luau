--!strict
-- Zone 2 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	ShellyTurtle = C.build({
		kind = "Quadruped",
		rarity = "Common",
		palette = { main = rgb(120, 200, 120), accent = rgb(60, 160, 150), belly = rgb(240, 225, 170) },
		shell = true,
		tail = "stub",
	}),
	GullBloc = C.build({
		kind = "Flyer",
		rarity = "Uncommon",
		palette = { main = rgb(245, 245, 250), accent = rgb(255, 170, 50), belly = rgb(210, 220, 230) },
		spots = true,
	}),
	SurfOtter = C.build({
		kind = "Quadruped",
		rarity = "Rare",
		palette = {
			main = rgb(150, 100, 70),
			accent = rgb(90, 190, 240),
			belly = rgb(235, 210, 175),
			eye = rgb(40, 120, 220),
		},
		ears = "round",
		tail = "fluffy",
		stripes = true,
	}),
	TideSpirit = C.build({
		kind = "Floater",
		rarity = "Epic",
		palette = {
			main = rgb(80, 190, 240),
			accent = rgb(230, 250, 255),
			belly = rgb(160, 230, 255),
			eye = rgb(20, 80, 200),
			glow = rgb(90, 230, 255),
		},
		ears = "fin",
		crystals = true,
	}),
}

return Pets
