--!strict
-- Zone 20 pets (data). Built by Models/Creatures; keys match Config/Pets `model`.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local C = require(script.Parent.Parent.Creatures)
local rgb = Color3.fromRGB

local Pets: { [string]: Builder.Spec } = {
	RainbowPony = C.build({
		kind = "Quadruped",
		rarity = "Legendary",
		palette = {
			main = rgb(255, 250, 255),
			accent = rgb(255, 150, 210),
			belly = rgb(220, 235, 255),
			eye = rgb(255, 120, 200),
			glow = rgb(255, 160, 230),
		},
		horns = "unicorn",
		mane = true,
		tail = "fluffy",
	}),
	PrismPhoenix = C.build({
		kind = "Flyer",
		rarity = "Mythic",
		palette = {
			main = rgb(255, 200, 240),
			accent = rgb(150, 230, 255),
			belly = rgb(255, 240, 200),
			eye = rgb(255, 255, 255),
			glow = rgb(255, 200, 255),
		},
		tail = "flame",
		crystals = true,
		mane = true,
	}),
	-- Premium hero spec (Models/Premium/HeavenLion.luau, docs/EggPetPlan.md).
	HeavenLion = require(script.Parent.Parent.Premium.HeavenLion).pet,
	-- Premium hero spec (Models/Premium/PrismSeraph.luau, docs/EggPetPlan.md).
	PrismSeraph = require(script.Parent.Parent.Premium.PrismSeraph).pet,
}

return Pets
