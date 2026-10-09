--!strict
-- Zone 9 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	EmberPup = E.build({
		rarity = "Uncommon",
		colors = { rgb(204, 195, 193), rgb(70, 55, 55), rgb(255, 120, 30) },
		pattern = "flames",
		top = "flame",
	}),
	MagmaGolem = E.build({
		rarity = "Rare",
		colors = { rgb(199, 190, 188), rgb(60, 45, 45), rgb(255, 110, 20) },
		pattern = "flames",
		top = "horns",
		glow = rgb(255, 120, 30),
		metal = rgb(45, 35, 35),
	}),
	AshBat = E.build({
		rarity = "Epic",
		colors = { rgb(211, 204, 204), rgb(80, 70, 75), rgb(255, 90, 40) },
		pattern = "flames",
		top = "ears",
		glow = rgb(255, 110, 30),
		metal = rgb(50, 40, 40),
	}),
	InfernoDragon = E.build({
		rarity = "Legendary",
		colors = { rgb(255, 235, 200), rgb(170, 40, 30), rgb(255, 150, 30) },
		pattern = "flames",
		top = "horns",
		glow = rgb(255, 140, 30),
		metal = rgb(60, 30, 25),
	}),
}

return Eggs
