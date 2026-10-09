--!strict
-- Zone 8 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	ClownFish = C.build({
		kind = "Fish",
		rarity = "Uncommon",
		palette = { main = rgb(255, 140, 50), accent = rgb(250, 250, 255), belly = rgb(255, 200, 140) },
		stripes = true,
	}),
	PufferBloc = C.build({
		kind = "Fish",
		rarity = "Rare",
		palette = {
			main = rgb(250, 220, 110),
			accent = rgb(120, 90, 60),
			belly = rgb(255, 245, 210),
			eye = rgb(40, 120, 220),
		},
		spikes = true,
		spots = true,
	}),
	CoralTurtle = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(80, 190, 170),
			accent = rgb(255, 120, 140),
			belly = rgb(220, 245, 220),
			eye = rgb(255, 120, 160),
			metal = rgb(255, 150, 160),
			glow = rgb(255, 140, 170),
		},
		shell = true,
		crystals = true,
		tail = "stub",
	}),
	TideLeviathan = C.build({
		kind = "Fish",
		rarity = "Legendary",
		palette = {
			main = rgb(40, 90, 170),
			accent = rgb(60, 220, 220),
			belly = rgb(180, 230, 245),
			eye = rgb(90, 255, 230),
			metal = rgb(60, 160, 190),
			glow = rgb(90, 255, 230),
		},
		horns = "curl",
		armor = true,
		spikes = true,
	}),
}

return Pets
