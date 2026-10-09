--!strict
-- Zone 6 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	SnowBunny = E.build({
		rarity = "Uncommon",
		colors = { rgb(242, 248, 253), rgb(250, 252, 255), rgb(170, 210, 245) },
		pattern = "frost",
		top = "ears",
	}),
	FrostPenguin = E.build({
		rarity = "Rare",
		colors = { rgb(251, 253, 255), rgb(40, 50, 70), rgb(255, 170, 50) },
		pattern = "frost",
	}),
	YetiBrute = E.build({
		rarity = "Epic",
		colors = { rgb(228, 235, 246), rgb(235, 240, 250), rgb(120, 170, 230) },
		pattern = "frost",
		top = "horns",
		glow = rgb(120, 220, 255),
		metal = rgb(150, 190, 230),
	}),
	IceDragon = E.build({
		rarity = "Legendary",
		colors = { rgb(239, 248, 255), rgb(150, 210, 250), rgb(230, 250, 255) },
		pattern = "crystal",
		top = "horns",
		glow = rgb(120, 240, 255),
	}),
}

return Eggs
