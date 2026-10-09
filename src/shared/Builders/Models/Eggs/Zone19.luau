--!strict
-- Zone 19 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	StarCat = E.build({
		rarity = "Epic",
		colors = { rgb(197, 193, 214), rgb(50, 40, 90), rgb(255, 240, 150) },
		pattern = "stars",
		top = "ears",
		glow = rgb(200, 160, 255),
	}),
	NebulaJelly = E.build({
		rarity = "Legendary",
		colors = { rgb(235, 225, 255), rgb(150, 90, 230), rgb(255, 140, 220) },
		pattern = "stars",
		top = "halo",
		glow = rgb(220, 150, 255),
	}),
	CosmicDragon = E.build({
		rarity = "Mythic",
		colors = { rgb(197, 190, 218), rgb(40, 30, 80), rgb(170, 110, 255) },
		pattern = "stars",
		top = "horns",
		glow = rgb(190, 130, 255),
	}),
	VoidEmperor = E.build({
		rarity = "Divine",
		colors = { rgb(186, 183, 197), rgb(25, 20, 45), rgb(170, 90, 255) },
		pattern = "stars",
		top = "crown",
		glow = rgb(180, 100, 255),
		metal = rgb(50, 40, 80),
	}),
}

return Eggs
