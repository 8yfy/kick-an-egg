--!strict
-- Zone 4 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	SporeSlime = E.build({
		rarity = "Common",
		colors = { rgb(253, 242, 253), rgb(190, 110, 230), rgb(240, 70, 70) },
		pattern = "spots",
	}),
	CapBunny = E.build({
		rarity = "Uncommon",
		colors = { rgb(255, 235, 239), rgb(245, 235, 225), rgb(230, 70, 70) },
		pattern = "spots",
		top = "ears",
	}),
	ToadKnight = E.build({
		rarity = "Rare",
		colors = { rgb(246, 249, 232), rgb(110, 180, 80), rgb(230, 70, 70) },
		pattern = "armor",
		top = "crown",
		metal = rgb(170, 170, 185),
	}),
	FungalDragon = E.build({
		rarity = "Epic",
		colors = { rgb(249, 239, 249), rgb(140, 80, 170), rgb(240, 80, 90) },
		pattern = "spots",
		top = "horns",
		glow = rgb(170, 255, 120),
	}),
}

return Eggs
