--!strict
-- Zone 11 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	VineMonkey = C.build({
		kind = "Biped",
		rarity = "Rare",
		palette = {
			main = rgb(130, 85, 55),
			accent = rgb(80, 170, 70),
			belly = rgb(225, 195, 160),
			eye = rgb(60, 40, 30),
		},
		ears = "round",
		tail = "long",
	}),
	JadeJaguar = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(70, 160, 110),
			accent = rgb(30, 70, 50),
			belly = rgb(200, 235, 210),
			eye = rgb(255, 220, 60),
			glow = rgb(120, 255, 170),
		},
		ears = "pointy",
		spots = true,
		tail = "long",
	}),
	TempleGuardian = C.build({
		kind = "Biped",
		rarity = "Legendary",
		palette = {
			main = rgb(170, 160, 120),
			accent = rgb(60, 140, 60),
			belly = rgb(210, 200, 160),
			eye = rgb(120, 255, 140),
			metal = rgb(200, 170, 70),
			glow = rgb(120, 255, 140),
		},
		armor = true,
		horns = "straight",
		crystals = true,
	}),
	QuetzalPhoenix = C.build({
		kind = "Flyer",
		rarity = "Mythic",
		palette = {
			main = rgb(40, 170, 120),
			accent = rgb(255, 80, 60),
			belly = rgb(250, 220, 120),
			eye = rgb(255, 230, 80),
			glow = rgb(255, 120, 50),
		},
		tail = "flame",
		mane = true,
	}),
}

return Pets
