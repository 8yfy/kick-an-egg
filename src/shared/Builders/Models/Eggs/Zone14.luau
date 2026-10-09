--!strict
-- Zone 14 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	CloudSheep = E.build({
		rarity = "Rare",
		colors = { rgb(244, 246, 253), rgb(250, 250, 255), rgb(170, 200, 255) },
		pattern = "frost",
		top = "ears",
	}),
	SkyGriffin = E.build({
		rarity = "Epic",
		colors = { rgb(249, 244, 228), rgb(210, 170, 90), rgb(250, 250, 255) },
		pattern = "scales",
		top = "fin",
		glow = rgb(255, 230, 120),
	}),
	StormEagle = E.build({
		rarity = "Legendary",
		colors = { rgb(235, 239, 249), rgb(70, 80, 120), rgb(255, 240, 120) },
		pattern = "stars",
		top = "crown",
		glow = rgb(180, 220, 255),
		metal = rgb(150, 160, 200),
	}),
	CelestialWhale = E.build({
		rarity = "Mythic",
		colors = { rgb(232, 239, 255), rgb(90, 120, 220), rgb(240, 245, 255) },
		pattern = "stars",
		top = "halo",
		glow = rgb(180, 220, 255),
	}),
}

return Eggs
