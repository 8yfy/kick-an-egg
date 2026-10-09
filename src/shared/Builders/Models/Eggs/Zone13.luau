--!strict
-- Zone 13 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	GhostPup = E.build({
		rarity = "Rare",
		colors = { rgb(235, 242, 246), rgb(230, 240, 245), rgb(140, 255, 120) },
		pattern = "frost",
		top = "ears",
	}),
	PumpkinGolem = E.build({
		rarity = "Epic",
		colors = { rgb(255, 232, 197), rgb(240, 130, 30), rgb(70, 140, 50) },
		pattern = "stripes",
		top = "sprout",
		glow = rgb(255, 180, 40),
	}),
	BoneDragon = E.build({
		rarity = "Legendary",
		colors = { rgb(235, 234, 227), rgb(235, 230, 210), rgb(60, 60, 70) },
		pattern = "scales",
		top = "horns",
		glow = rgb(140, 255, 120),
		metal = rgb(80, 80, 90),
	}),
	ReaperSpirit = E.build({
		rarity = "Mythic",
		colors = { rgb(197, 193, 207), rgb(50, 45, 70), rgb(140, 255, 120) },
		pattern = "stars",
		top = "halo",
		glow = rgb(140, 255, 120),
	}),
}

return Eggs
