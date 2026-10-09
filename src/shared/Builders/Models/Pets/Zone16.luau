--!strict
-- Zone 16 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	GearPup = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(190, 140, 70),
			accent = rgb(120, 90, 60),
			belly = rgb(230, 200, 140),
			eye = rgb(255, 200, 80),
			metal = rgb(150, 110, 70),
			glow = rgb(255, 200, 80),
		},
		armor = true,
		ears = "round",
		tail = "stub",
	}),
	SteamGolem = C.build({
		kind = "Biped",
		rarity = "Legendary",
		palette = {
			main = rgb(150, 110, 70),
			accent = rgb(230, 180, 60),
			belly = rgb(200, 170, 130),
			eye = rgb(255, 200, 60),
			metal = rgb(110, 85, 60),
			glow = rgb(255, 190, 60),
		},
		armor = true,
		horns = "straight",
		spikes = true,
	}),
	BrassOwl = C.build({
		kind = "Flyer",
		rarity = "Mythic",
		palette = {
			main = rgb(205, 160, 70),
			accent = rgb(120, 85, 55),
			belly = rgb(240, 215, 150),
			eye = rgb(90, 220, 255),
			metal = rgb(160, 120, 60),
			glow = rgb(255, 200, 80),
		},
		armor = true,
		ears = "pointy",
	}),
	ClockworkTitan = C.build({
		kind = "Biped",
		rarity = "Divine",
		palette = {
			main = rgb(200, 160, 80),
			accent = rgb(90, 70, 50),
			belly = rgb(240, 215, 160),
			eye = rgb(255, 230, 120),
			metal = rgb(150, 115, 60),
			glow = rgb(255, 220, 100),
		},
		armor = true,
		horns = "curl",
		crystals = true,
		spikes = true,
	}),
}

return Pets
