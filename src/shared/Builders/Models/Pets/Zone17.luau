--!strict
-- Zone 17 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	AuroraFox = C.build({
		kind = "Quadruped",
		rarity = "Epic",
		palette = {
			main = rgb(230, 245, 255),
			accent = rgb(120, 255, 200),
			belly = rgb(200, 225, 245),
			eye = rgb(120, 255, 200),
			glow = rgb(120, 255, 200),
		},
		ears = "pointy",
		tail = "fluffy",
		stripes = true,
	}),
	FrostWolf = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(170, 200, 230),
			accent = rgb(120, 255, 220),
			belly = rgb(230, 240, 250),
			eye = rgb(120, 255, 220),
			glow = rgb(120, 255, 220),
		},
		ears = "pointy",
		mane = true,
		tail = "fluffy",
		crystals = true,
	}),
	GlacierMammoth = C.build({
		kind = "Quadruped",
		rarity = "Mythic",
		palette = {
			main = rgb(140, 170, 200),
			accent = rgb(230, 245, 255),
			belly = rgb(190, 210, 230),
			eye = rgb(120, 255, 230),
			metal = rgb(200, 230, 250),
			glow = rgb(120, 255, 230),
		},
		horns = "curl",
		mane = true,
		armor = true,
		ears = "round",
	}),
	AuroraSeraph = C.build({
		kind = "Flyer",
		rarity = "Divine",
		palette = {
			main = rgb(240, 250, 255),
			accent = rgb(120, 255, 200),
			belly = rgb(200, 240, 255),
			eye = rgb(120, 255, 210),
			glow = rgb(120, 255, 210),
		},
		wings = "fairy",
		mane = true,
		crystals = true,
	}),
}

return Pets
