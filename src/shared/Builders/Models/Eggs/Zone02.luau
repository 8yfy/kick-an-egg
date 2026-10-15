--!strict
-- Zone 2 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	ShellyTurtle = E.build({
		rarity = "Common",
		colors = { rgb(249, 244, 225), rgb(120, 200, 120), rgb(60, 160, 150) },
		pattern = "scales",
	}),
	GullBloc = E.build({
		rarity = "Uncommon",
		colors = { rgb(239, 242, 246), rgb(245, 245, 250), rgb(255, 170, 50) },
		pattern = "spots",
		top = "fin",
	}),
	SurfOtter = E.build({
		rarity = "Rare",
		colors = { rgb(248, 239, 227), rgb(150, 100, 70), rgb(90, 190, 240) },
		pattern = "stripes",
		top = "ears",
	}),
	-- Premium hero spec (Models/Premium/TideSpirit.luau, docs/EggPetPlan.md).
	TideSpirit = require(script.Parent.Parent.Premium.TideSpirit).egg,
}

return Eggs
