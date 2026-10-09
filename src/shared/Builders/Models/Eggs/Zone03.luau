--!strict
-- Zone 3 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	AcornSquirrel = E.build({
		rarity = "Common",
		colors = { rgb(251, 242, 228), rgb(200, 110, 50), rgb(120, 70, 40) },
		pattern = "spots",
		top = "sprout",
	}),
	MapleFox = E.build({
		rarity = "Uncommon",
		colors = { rgb(253, 248, 241), rgb(235, 120, 40), rgb(200, 50, 40) },
		pattern = "spots",
		top = "ears",
	}),
	BarkOwl = E.build({
		rarity = "Rare",
		colors = { rgb(246, 237, 221), rgb(140, 95, 60), rgb(230, 150, 50) },
		pattern = "scales",
		top = "ears",
	}),
	HarvestBear = E.build({
		rarity = "Epic",
		colors = { rgb(249, 235, 218), rgb(160, 95, 50), rgb(230, 120, 40) },
		pattern = "armor",
		top = "ears",
		glow = rgb(255, 150, 40),
		metal = rgb(190, 120, 60),
	}),
}

return Eggs
