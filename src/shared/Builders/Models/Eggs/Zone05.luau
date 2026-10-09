--!strict
-- Zone 5 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	DuneLizard = E.build({
		rarity = "Common",
		colors = { rgb(251, 244, 225), rgb(220, 170, 90), rgb(180, 110, 50) },
		pattern = "scales",
	}),
	CactusPup = E.build({
		rarity = "Uncommon",
		colors = { rgb(235, 248, 218), rgb(90, 170, 80), rgb(255, 110, 160) },
		pattern = "spots",
		top = "sprout",
	}),
	ScarabGolem = E.build({
		rarity = "Rare",
		colors = { rgb(197, 228, 232), rgb(40, 120, 140), rgb(255, 200, 60) },
		pattern = "armor",
		top = "horns",
		metal = rgb(200, 160, 60),
	}),
	SandDjinn = E.build({
		rarity = "Epic",
		colors = { rgb(235, 242, 255), rgb(90, 140, 230), rgb(255, 200, 70) },
		pattern = "stars",
		top = "flame",
		glow = rgb(255, 200, 70),
	}),
}

return Eggs
