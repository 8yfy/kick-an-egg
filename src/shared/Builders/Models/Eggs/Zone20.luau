--!strict
-- Zone 20 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	RainbowPony = E.build({
		rarity = "Legendary",
		colors = { rgb(242, 248, 255), rgb(255, 250, 255), rgb(255, 150, 210) },
		pattern = "rainbow",
		top = "crown",
		glow = rgb(255, 160, 230),
	}),
	PrismPhoenix = E.build({
		rarity = "Mythic",
		colors = { rgb(255, 249, 235), rgb(255, 200, 240), rgb(150, 230, 255) },
		pattern = "rainbow",
		top = "flame",
		glow = rgb(255, 200, 255),
	}),
	HeavenLion = E.build({
		rarity = "Divine",
		colors = { rgb(255, 251, 242), rgb(255, 235, 180), rgb(255, 255, 255) },
		pattern = "rainbow",
		top = "halo",
		glow = rgb(255, 240, 180),
		metal = rgb(255, 210, 90),
	}),
	PrismSeraph = E.build({
		rarity = "Secret",
		colors = { rgb(255, 249, 253), rgb(255, 255, 255), rgb(200, 160, 255) },
		pattern = "rainbow",
		top = "halo",
		glow = rgb(255, 255, 255),
	}),
}

return Eggs
