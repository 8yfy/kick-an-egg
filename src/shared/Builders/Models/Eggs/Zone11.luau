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
	-- Premium hero spec (Models/Premium/QuetzalPhoenix.luau, docs/EggPetPlan.md).
	QuetzalPhoenix = require(script.Parent.Parent.Premium.QuetzalPhoenix).egg,
}

return Eggs
