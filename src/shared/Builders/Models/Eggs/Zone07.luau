--!strict
-- Zone 7 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	GummyBear = E.build({
		rarity = "Uncommon",
		colors = { rgb(255, 232, 239), rgb(255, 120, 150), rgb(255, 220, 120) },
		pattern = "drips",
		top = "ears",
	}),
	LolliPup = E.build({
		rarity = "Rare",
		colors = { rgb(255, 249, 253), rgb(255, 170, 210), rgb(140, 230, 230) },
		pattern = "stripes",
		top = "ears",
	}),
	CottonSheep = E.build({
		rarity = "Epic",
		colors = { rgb(255, 239, 248), rgb(255, 230, 245), rgb(180, 150, 255) },
		pattern = "drips",
		top = "horns",
		glow = rgb(255, 140, 220),
	}),
	SugarUnicorn = E.build({
		rarity = "Legendary",
		colors = { rgb(235, 249, 255), rgb(255, 245, 250), rgb(255, 150, 210) },
		pattern = "stripes",
		top = "crown",
		glow = rgb(255, 140, 220),
	}),
}

return Eggs
