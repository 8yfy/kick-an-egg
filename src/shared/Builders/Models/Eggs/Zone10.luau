--!strict
-- Zone 10 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	GemMole = E.build({
		rarity = "Uncommon",
		colors = { rgb(235, 228, 242), rgb(110, 90, 140), rgb(120, 240, 255) },
		pattern = "crystal",
	}),
	QuartzGolem = E.build({
		rarity = "Rare",
		colors = { rgb(246, 244, 253), rgb(180, 170, 230), rgb(130, 240, 255) },
		pattern = "crystal",
		top = "crystal",
		metal = rgb(120, 110, 170),
	}),
	PrismOwl = E.build({
		rarity = "Epic",
		colors = { rgb(239, 235, 253), rgb(120, 100, 200), rgb(150, 240, 255) },
		pattern = "crystal",
		top = "ears",
		glow = rgb(140, 240, 255),
	}),
	CrystalDrake = E.build({
		rarity = "Legendary",
		colors = { rgb(235, 232, 249), rgb(90, 70, 160), rgb(140, 240, 255) },
		pattern = "crystal",
		top = "crystal",
		glow = rgb(130, 240, 255),
	}),
}

return Eggs
