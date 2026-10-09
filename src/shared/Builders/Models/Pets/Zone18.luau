--!strict
-- Zone 18 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	CinderHound = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(60, 40, 40),
			accent = rgb(255, 170, 40),
			belly = rgb(100, 70, 65),
			eye = rgb(255, 190, 40),
			glow = rgb(255, 160, 40),
		},
		ears = "pointy",
		tail = "flame",
		spikes = true,
	}),
	ObsidianGolem = C.build({
		kind = "Biped",
		rarity = "Legendary",
		palette = {
			main = rgb(40, 35, 45),
			accent = rgb(255, 140, 30),
			belly = rgb(70, 60, 75),
			eye = rgb(255, 160, 40),
			metal = rgb(30, 25, 35),
			glow = rgb(255, 140, 30),
		},
		armor = true,
		flames = true,
		crystals = true,
	}),
	PhoenixLord = C.build({
		kind = "Flyer",
		rarity = "Mythic",
		palette = {
			main = rgb(255, 110, 40),
			accent = rgb(255, 220, 80),
			belly = rgb(255, 180, 100),
			eye = rgb(255, 240, 150),
			glow = rgb(255, 180, 40),
		},
		tail = "flame",
		flames = true,
		mane = true,
	}),
	MagmaTitan = C.build({
		kind = "Biped",
		rarity = "Divine",
		palette = {
			main = rgb(90, 30, 20),
			accent = rgb(255, 170, 40),
			belly = rgb(140, 60, 40),
			eye = rgb(255, 220, 80),
			metal = rgb(60, 25, 20),
			glow = rgb(255, 170, 40),
		},
		flames = true,
		horns = "curl",
		armor = true,
		spikes = true,
	}),
}

return Pets
