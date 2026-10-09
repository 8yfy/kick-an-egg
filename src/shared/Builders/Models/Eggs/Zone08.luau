--!strict
-- Zone 8 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	ClownFish = E.build({
		rarity = "Uncommon",
		colors = { rgb(255, 235, 214), rgb(255, 140, 50), rgb(250, 250, 255) },
		pattern = "stripes",
		top = "fin",
	}),
	PufferBloc = E.build({
		rarity = "Rare",
		colors = { rgb(255, 251, 239), rgb(250, 220, 110), rgb(120, 90, 60) },
		pattern = "spots",
		top = "fin",
	}),
	CoralTurtle = E.build({
		rarity = "Epic",
		colors = { rgb(242, 251, 242), rgb(80, 190, 170), rgb(255, 120, 140) },
		pattern = "scales",
		top = "crystal",
		glow = rgb(255, 140, 170),
		metal = rgb(255, 150, 160),
	}),
	TideLeviathan = E.build({
		rarity = "Legendary",
		colors = { rgb(228, 246, 251), rgb(40, 90, 170), rgb(60, 220, 220) },
		pattern = "scales",
		top = "horns",
		glow = rgb(90, 255, 230),
		metal = rgb(60, 160, 190),
	}),
}

return Eggs
