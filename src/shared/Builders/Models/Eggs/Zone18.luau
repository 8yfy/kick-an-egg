--!strict
-- Zone 18 eggs (data). Generated from Models/EggStyles; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local E = require(script.Parent.Parent.EggStyles)
local rgb = Color3.fromRGB

local Eggs: { [string]: Builder.Spec } = {
	CinderHound = E.build({
		rarity = "Epic",
		colors = { rgb(200, 190, 188), rgb(60, 40, 40), rgb(255, 170, 40) },
		pattern = "flames",
		top = "ears",
		glow = rgb(255, 160, 40),
	}),
	ObsidianGolem = E.build({
		rarity = "Legendary",
		colors = { rgb(190, 186, 192), rgb(40, 35, 45), rgb(255, 140, 30) },
		pattern = "flames",
		top = "horns",
		glow = rgb(255, 140, 30),
		metal = rgb(30, 25, 35),
	}),
	PhoenixLord = E.build({
		rarity = "Mythic",
		colors = { rgb(255, 228, 200), rgb(255, 110, 40), rgb(255, 220, 80) },
		pattern = "flames",
		top = "flame",
		glow = rgb(255, 180, 40),
	}),
	MagmaTitan = E.build({
		rarity = "Divine",
		colors = { rgb(214, 186, 179), rgb(90, 30, 20), rgb(255, 170, 40) },
		pattern = "flames",
		top = "crown",
		glow = rgb(255, 170, 40),
		metal = rgb(60, 25, 20),
	}),
}

return Eggs
