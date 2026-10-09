--!strict
-- Zone 17 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	AuroraFox = E.build({
		rarity = "Epic",
		colors = { rgb(235, 244, 251), rgb(230, 245, 255), rgb(120, 255, 200) },
		pattern = "frost",
		top = "ears",
		glow = rgb(120, 255, 200),
	}),
	FrostWolf = E.build({
		rarity = "Legendary",
		colors = { rgb(246, 249, 253), rgb(170, 200, 230), rgb(120, 255, 220) },
		pattern = "frost",
		top = "ears",
		glow = rgb(120, 255, 220),
	}),
	GlacierMammoth = E.build({
		rarity = "Mythic",
		colors = { rgb(232, 239, 246), rgb(140, 170, 200), rgb(230, 245, 255) },
		pattern = "frost",
		top = "horns",
		glow = rgb(120, 255, 230),
		metal = rgb(200, 230, 250),
	}),
	AuroraSeraph = E.build({
		rarity = "Divine",
		colors = { rgb(235, 249, 255), rgb(240, 250, 255), rgb(120, 255, 200) },
		pattern = "crystal",
		top = "halo",
		glow = rgb(120, 255, 210),
	}),
}

return Eggs
