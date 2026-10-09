--!strict
-- Zone 13 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	GhostPup = C.build({
		kind = "Floater",
		rarity = "Rare",
		palette = {
			main = rgb(230, 240, 245),
			accent = rgb(140, 255, 120),
			belly = rgb(200, 220, 230),
			eye = rgb(140, 255, 120),
		},
		ears = "pointy",
		ghost = true,
	}),
	PumpkinGolem = C.build({
		kind = "Biped",
		rarity = "Epic",
		palette = {
			main = rgb(240, 130, 30),
			accent = rgb(70, 140, 50),
			belly = rgb(255, 190, 90),
			eye = rgb(255, 220, 60),
			glow = rgb(255, 180, 40),
		},
		flames = true,
		stripes = true,
	}),
	BoneDragon = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(235, 230, 210),
			accent = rgb(60, 60, 70),
			belly = rgb(200, 195, 175),
			eye = rgb(140, 255, 120),
			metal = rgb(80, 80, 90),
			glow = rgb(140, 255, 120),
		},
		wings = "bat",
		spikes = true,
		horns = "curl",
		tail = "spike",
		stripes = true,
	}),
	ReaperSpirit = C.build({
		kind = "Floater",
		rarity = "Mythic",
		palette = {
			main = rgb(50, 45, 70),
			accent = rgb(140, 255, 120),
			belly = rgb(90, 80, 120),
			eye = rgb(140, 255, 120),
			glow = rgb(140, 255, 120),
		},
		horns = "curl",
		flames = true,
		ghost = true,
	}),
}

return Pets
