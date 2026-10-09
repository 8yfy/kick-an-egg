--!strict
-- Zone 16 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	GearPup = E.build({
		rarity = "Epic",
		colors = { rgb(246, 235, 214), rgb(190, 140, 70), rgb(120, 90, 60) },
		pattern = "armor",
		top = "antennae",
		glow = rgb(255, 200, 80),
		metal = rgb(150, 110, 70),
	}),
	SteamGolem = E.build({
		rarity = "Legendary",
		colors = { rgb(235, 225, 211), rgb(150, 110, 70), rgb(230, 180, 60) },
		pattern = "armor",
		top = "horns",
		glow = rgb(255, 190, 60),
		metal = rgb(110, 85, 60),
	}),
	BrassOwl = E.build({
		rarity = "Mythic",
		colors = { rgb(249, 241, 218), rgb(205, 160, 70), rgb(120, 85, 55) },
		pattern = "armor",
		top = "ears",
		glow = rgb(255, 200, 80),
		metal = rgb(160, 120, 60),
	}),
	ClockworkTitan = E.build({
		rarity = "Divine",
		colors = { rgb(249, 241, 221), rgb(200, 160, 80), rgb(90, 70, 50) },
		pattern = "armor",
		top = "crown",
		glow = rgb(255, 220, 100),
		metal = rgb(150, 115, 60),
	}),
}

return Eggs
