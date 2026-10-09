--!strict
-- Zone 5 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	DuneLizard = C.build({
		kind = "Quadruped",
		rarity = "Common",
		palette = { main = rgb(220, 170, 90), accent = rgb(180, 110, 50), belly = rgb(245, 225, 170) },
		tail = "spike",
	}),
	CactusPup = C.build({
		kind = "Quadruped",
		rarity = "Uncommon",
		palette = { main = rgb(90, 170, 80), accent = rgb(255, 110, 160), belly = rgb(200, 235, 150) },
		spikes = true,
		ears = "round",
	}),
	ScarabGolem = C.build({
		kind = "Biped",
		rarity = "Rare",
		palette = {
			main = rgb(40, 120, 140),
			accent = rgb(255, 200, 60),
			belly = rgb(90, 180, 190),
			eye = rgb(255, 210, 60),
			metal = rgb(200, 160, 60),
		},
		shell = true,
		horns = "straight",
	}),
	SandDjinn = C.build({
		kind = "Floater",
		rarity = "Epic",
		palette = {
			main = rgb(90, 140, 230),
			accent = rgb(255, 200, 70),
			belly = rgb(200, 220, 255),
			eye = rgb(255, 230, 120),
			glow = rgb(255, 200, 70),
		},
		flames = true,
		ears = "pointy",
	}),
}

return Pets
