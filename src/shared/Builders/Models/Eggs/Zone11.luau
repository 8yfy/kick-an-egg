--!strict
-- Zone 11 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	VineMonkey = E.build({
		rarity = "Rare",
		colors = { rgb(244, 234, 221), rgb(130, 85, 55), rgb(80, 170, 70) },
		pattern = "spots",
		top = "sprout",
	}),
	JadeJaguar = E.build({
		rarity = "Epic",
		colors = { rgb(235, 248, 239), rgb(70, 160, 110), rgb(30, 70, 50) },
		pattern = "spots",
		top = "ears",
		glow = rgb(120, 255, 170),
	}),
	TempleGuardian = E.build({
		rarity = "Legendary",
		colors = { rgb(239, 235, 221), rgb(170, 160, 120), rgb(60, 140, 60) },
		pattern = "armor",
		top = "crown",
		glow = rgb(120, 255, 140),
		metal = rgb(200, 170, 70),
	}),
	QuetzalPhoenix = E.build({
		rarity = "Mythic",
		colors = { rgb(253, 242, 207), rgb(40, 170, 120), rgb(255, 80, 60) },
		pattern = "flames",
		top = "crown",
		glow = rgb(255, 120, 50),
	}),
}

return Eggs
