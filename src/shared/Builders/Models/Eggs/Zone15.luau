--!strict
-- Zone 15 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	SludgeSlime = E.build({
		rarity = "Rare",
		colors = { rgb(232, 249, 200), rgb(120, 190, 40), rgb(90, 60, 120) },
		pattern = "drips",
	}),
	BogToad = E.build({
		rarity = "Epic",
		colors = { rgb(232, 239, 207), rgb(90, 120, 50), rgb(170, 255, 40) },
		pattern = "spots",
		top = "fin",
		glow = rgb(170, 255, 40),
	}),
	ToxicHydra = E.build({
		rarity = "Legendary",
		colors = { rgb(218, 232, 204), rgb(70, 110, 60), rgb(170, 255, 40) },
		pattern = "drips",
		top = "horns",
		glow = rgb(170, 255, 40),
	}),
	PlagueWyrm = E.build({
		rarity = "Mythic",
		colors = { rgb(218, 207, 225), rgb(90, 60, 110), rgb(170, 255, 40) },
		pattern = "drips",
		top = "crystal",
		glow = rgb(170, 255, 40),
	}),
}

return Eggs
