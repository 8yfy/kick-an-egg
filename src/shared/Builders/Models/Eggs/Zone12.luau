--!strict
-- Zone 12 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	NeonCat = E.build({
		rarity = "Rare",
		colors = { rgb(190, 190, 199), rgb(40, 40, 60), rgb(255, 40, 200) },
		pattern = "stripes",
		top = "ears",
	}),
	CyberPup = E.build({
		rarity = "Epic",
		colors = { rgb(204, 207, 214), rgb(60, 70, 90), rgb(40, 220, 255) },
		pattern = "armor",
		top = "antennae",
		glow = rgb(40, 230, 255),
		metal = rgb(90, 100, 120),
	}),
	MechTitan = E.build({
		rarity = "Legendary",
		colors = { rgb(214, 216, 223), rgb(90, 95, 115), rgb(255, 60, 200) },
		pattern = "armor",
		top = "antennae",
		glow = rgb(255, 60, 220),
		metal = rgb(60, 65, 80),
	}),
	HoloDragon = E.build({
		rarity = "Mythic",
		colors = { rgb(235, 251, 255), rgb(90, 220, 255), rgb(255, 80, 220) },
		pattern = "stars",
		top = "horns",
		glow = rgb(90, 230, 255),
	}),
}

return Eggs
