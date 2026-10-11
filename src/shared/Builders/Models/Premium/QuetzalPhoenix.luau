--!strict
-- 43 Quetzal Phoenix (Jungle Ruins, Mythic). Hero example 5/7 (docs/EggPetPlan.md): very elaborate, magical,
-- floating details.
-- Egg: jade relic egg on a carved temple-stone band, gold relic rings, a vine spiral, a feather-flame plume
--      crown and a medallion; a gold relic halo floats over it and jade shards orbit it.
-- Pet: a standing quetzal phoenix: layered radiant wings (jade coverts, teal secondaries, emerald primaries
--      with gold edges and flame tips), red breast, gold relic mask + beak, a feather crest, three long tail
--      streamers ending in flame; a spinning gold relic halo, orbiting jade shards and gold relic coins.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local JADE, EMERALD, TEAL = rgb(42, 172, 112), rgb(20, 128, 88), rgb(44, 192, 182)
local GOLD, GOLD_DK, STONE, STONE_DK = rgb(255, 202, 64), rgb(200, 142, 34), rgb(152, 152, 142), rgb(104, 104, 98)
local FLAME, FLAME_LT, RED, INK = rgb(255, 136, 40), rgb(255, 214, 84), rgb(226, 56, 50), rgb(36, 30, 28)

local function cf(pos: { number }, rot: { number }?): CFrame
	return S.cf(pos, rot)
end
local function o(joint: string, extra: S.Opts?): S.Opts
	local t: S.Opts = table.clone(extra or {})
	t.joint = joint
	return t
end
local function core(joint: string, y: number): Builder.PartSpec
	return P(joint .. "Core", { 0.2, 0.2, 0.2 }, { 0, y, 0 }, GOLD, { joint = joint, transparency = 1, studs = false })
end
local function addTo(list: { Builder.PartSpec }, more: { Builder.PartSpec })
	for _, p in more do
		table.insert(list, p)
	end
end

-- A feather: a shaft block plus a gold edge and (optionally) a neon flame tip, along cf's up axis.
local function feather(
	name: string,
	base: CFrame,
	len: number,
	w: number,
	color: Color3,
	joint: string,
	flame: boolean?
): { Builder.PartSpec }
	local parts = {
		S.at(name, { w, len, 0.14 }, base * CFrame.new(0, len / 2, 0), color, { joint = joint }),
		S.at(
			name .. "Edge",
			{ 0.1, len * 0.8, 0.16 },
			base * CFrame.new(w / 2, len * 0.55, 0),
			GOLD,
			{ joint = joint, studs = false }
		),
	}
	if flame then
		table.insert(
			parts,
			S.at(name .. "Flame", { w * 0.8, len * 0.22, 0.16 }, base * CFrame.new(0, len + len * 0.08, 0), FLAME, {
				joint = joint,
				material = "Neon",
			})
		)
	end
	return parts
end

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 5.0, 3.7
local eggParts = S.join(
	S.eggShell(H, W, 17, function(i, n)
		return if i <= 2
			then STONE_DK
			elseif i <= 4 then STONE
			elseif i >= n - 1 then TEAL
			elseif i % 4 == 0 then EMERALD
			else JADE
	end),
	{
		S.eggBand("TempleBand", H, W, 1.65, 0.55, 0.07, STONE_DK),
		S.eggBand("RelicLow", H, W, 1.28, 0.12, 0.1, GOLD, { studs = false }),
		S.eggBand("RelicHigh", H, W, 2.02, 0.12, 0.1, GOLD, { studs = false }),
		S.plate("Medallion", H, W, 0, 2.95, { 0.95, 0.95, 0.16 }, GOLD),
		S.plate("MedallionGem", H, W, 0, 2.95, { 0.45, 0.45, 0.22 }, TEAL, { material = "Neon" }),
	}
)
-- carved glyphs on the temple band
for k = 1, 8 do
	table.insert(
		eggParts,
		S.plate("Glyph" .. k, H, W, k * 45, 1.65, { 0.32, 0.32, 0.2 }, if k % 2 == 0 then GOLD else TEAL, {
			rot = { 0, 0, 45 },
			material = if k % 2 == 0 then "SmoothPlastic" else "Neon",
		})
	)
end
-- vine spiral with leaves
for k = 1, 14 do
	local a, y = k * 52, 2.2 + k * 0.17
	table.insert(
		eggParts,
		S.at(
			"Vine" .. k,
			{ 0.3, 0.22, 0.22 },
			S.onEgg(H, W, a, y, 0.06) * CFrame.Angles(0, 0, math.rad(35)),
			EMERALD,
			{ joint = "Body" }
		)
	)
	if k % 3 == 0 then
		table.insert(
			eggParts,
			S.at("VineLeaf" .. k, { 0.42, 0.12, 0.3 }, S.onEgg(H, W, a + 10, y + 0.1, 0.16), JADE, { joint = "Body" })
		)
	end
end
-- feather-flame plume crown
for k = 1, 5 do
	local a = -40 + (k - 1) * 20
	addTo(
		eggParts,
		feather(
			"Plume" .. k,
			cf({ 0, H - 0.25, 0.15 }, { 12, 0, a }),
			1.25 - math.abs(k - 3) * 0.15,
			0.32,
			if k % 2 == 0 then TEAL else JADE,
			"Body",
			true
		)
	)
end
-- floating gold relic halo + orbiting jade shards
table.insert(eggParts, core("Halo", H + 1.0))
addTo(
	eggParts,
	S.ring(
		"RelicHalo",
		CFrame.new(0, H + 1.0, 0),
		12,
		1.15,
		{ 0.42, 0.16, 0.2 },
		GOLD,
		{ joint = "Halo", material = "Neon" }
	)
)
table.insert(eggParts, core("Orbit", 2.6))
for k = 1, 4 do
	local a = math.rad(k * 90)
	addTo(
		eggParts,
		S.shard(
			"Jade" .. k,
			cf({ math.sin(a) * 2.75, 2.2 + (k % 2) * 0.7, -math.cos(a) * 2.75 }, { 0, 0, 14 }),
			0.9,
			0.32,
			TEAL,
			o("Orbit", { material = "Neon" })
		)
	)
end
local egg: Builder.Spec = { parts = eggParts }

-- Pet -------------------------------------------------------------------------------------------------------
local FACE_Z = -1.06
local petParts: { Builder.PartSpec } = {
	P("Torso", { 2.3, 2.6, 2.1 }, { 0, 3.35, 0.2 }, JADE, { joint = "Body" }),
	P("Breast", { 1.75, 1.7, 0.2 }, { 0, 3.1, -0.9 }, RED, { joint = "Body" }),
	P("BellyScales", { 1.3, 0.9, 0.16 }, { 0, 2.3, -0.82 }, GOLD_DK, { joint = "Body" }),
	P("Collar", { 2.0, 0.28, 1.9 }, { 0, 4.55, 0.1 }, GOLD, { joint = "Body", studs = false }),
	P(
		"CollarGem",
		{ 0.42, 0.42, 0.14 },
		{ 0, 4.5, -0.88 },
		TEAL,
		{ joint = "Body", material = "Neon", rot = { 0, 0, 45 } }
	),
	P("Back", { 1.9, 0.5, 1.6 }, { 0, 4.45, 0.75 }, EMERALD, { joint = "Body" }),
	-- head
	P("Head", { 1.6, 1.5, 1.6 }, { 0, 5.4, -0.2 }, JADE, { joint = "Head" }),
	P("Mask", { 1.66, 0.42, 0.14 }, { 0, 5.55, FACE_Z }, GOLD, { joint = "Head" }),
	P("EyeL", { 0.3, 0.3, 0.1 }, { -0.42, 5.55, FACE_Z - 0.06 }, FLAME_LT, { joint = "Head", material = "Neon" }),
	P("EyeR", { 0.3, 0.3, 0.1 }, { 0.42, 5.55, FACE_Z - 0.06 }, FLAME_LT, { joint = "Head", material = "Neon" }),
	P("Beak", { 0.6, 0.42, 0.85 }, { 0, 5.12, -1.4 }, GOLD, { joint = "Head" }),
	P("BeakTip", { 0.36, 0.3, 0.4 }, { 0, 4.95, -1.88 }, GOLD_DK, { joint = "Head", rot = { 20, 0, 0 } }),
	P("Nostril", { 0.3, 0.08, 0.06 }, { 0, 5.28, -1.66 }, INK, { joint = "Head", studs = false }),
}
-- feather crest sweeping back over the head
for k = 1, 5 do
	addTo(
		petParts,
		feather(
			"Crest" .. k,
			cf({ 0, 6.0, -0.1 + k * 0.08 }, { 38 + k * 9, 0, (k - 3) * 9 }),
			1.8 - math.abs(k - 3) * 0.2,
			0.3,
			if k % 2 == 0 then TEAL else EMERALD,
			"Head",
			k == 3
		)
	)
end
-- left side, mirrored: wing (three feather layers), leg + talons
local left: { Builder.PartSpec } = {
	P("ThighL", { 0.62, 0.95, 0.66 }, { -0.6, 1.55, 0.25 }, JADE, { joint = "LegL" }),
	P("ShankL", { 0.3, 0.85, 0.3 }, { -0.6, 0.62, 0.15 }, GOLD, { joint = "LegL" }),
	P("FootL", { 0.72, 0.2, 0.9 }, { -0.6, 0.1, -0.05 }, GOLD, { joint = "LegL" }),
	P("TalonL", { 0.16, 0.18, 0.3 }, { -0.6, 0.1, -0.6 }, GOLD_DK, { joint = "LegL" }),
}
local shoulder = cf({ -1.2, 4.45, 0.35 }, { 0, -12, 0 })
local arm = shoulder * CFrame.Angles(0, 0, math.rad(58))
local wrist = arm * CFrame.new(0, 1.9, 0)
table.insert(left, S.at("WingArmL", { 0.5, 2.0, 0.45 }, arm * CFrame.new(0, 0.95, 0), EMERALD, { joint = "WingL" }))
for k = 1, 5 do -- coverts from the shoulder
	addTo(
		left,
		feather(
			"CovertL" .. k,
			shoulder * CFrame.Angles(0, 0, math.rad(48 + k * 18)) * CFrame.new(0, 0.2, 0.06),
			1.7,
			0.45,
			JADE,
			"WingL"
		)
	)
end
for k = 1, 6 do -- secondaries from the wrist, hanging out and down
	addTo(
		left,
		feather(
			"SecondaryL" .. k,
			wrist * CFrame.Angles(0, 0, math.rad(62 + k * 17)) * CFrame.new(0, 0, 0.1),
			2.6 - k * 0.08,
			0.5,
			TEAL,
			"WingL",
			k <= 2
		)
	)
end
for k = 1, 5 do -- primaries from the wrist, reaching up and out (flame tipped)
	addTo(
		left,
		feather(
			"PrimaryL" .. k,
			wrist * CFrame.Angles(0, 0, math.rad(-18 + k * 16)) * CFrame.new(0, 0, 0.18),
			3.5 - math.abs(k - 3) * 0.35,
			0.5,
			EMERALD,
			"WingL",
			true
		)
	)
end
addTo(petParts, S.both(left))
-- tail: three long streamers (quetzal plumes) curving down and back, with flame tips, plus a short fan
for s = -1, 1 do
	local c = cf({ s * 0.38, 2.6, 1.15 }, { 100, 0, s * 14 })
	for i = 1, 5 do
		local color = if i <= 2 then EMERALD elseif i <= 4 then TEAL else GOLD
		table.insert(
			petParts,
			S.at(
				"Streamer" .. (s + 2) .. "_" .. i,
				{ 0.42 - i * 0.03, 1.15, 0.14 },
				c * CFrame.new(0, 0.55, 0),
				color,
				{ joint = "Tail" }
			)
		)
		c = c * CFrame.new(0, 1.1, 0) * CFrame.Angles(math.rad(4), 0, 0)
	end
	table.insert(
		petParts,
		S.at(
			"StreamerFlame" .. (s + 2),
			{ 0.32, 0.55, 0.16 },
			c * CFrame.new(0, 0.25, 0),
			FLAME,
			{ joint = "Tail", material = "Neon" }
		)
	)
end
addTo(
	petParts,
	S.fan(
		"TailFan",
		cf({ 0, 2.75, 1.2 }, { 140, 0, 0 }),
		5,
		-35,
		35,
		1.4,
		0.4,
		0.14,
		{ JADE, TEAL },
		{ joint = "Tail" }
	)
)
-- spinning gold relic halo behind the head, orbiting jade shards, counter-orbiting relic coins
table.insert(petParts, core("Halo", 7.0))
addTo(
	petParts,
	S.ring(
		"RelicHalo",
		CFrame.new(0, 7.0, 0.1),
		14,
		1.45,
		{ 0.45, 0.18, 0.22 },
		GOLD,
		{ joint = "Halo", material = "Neon" }
	)
)
for k = 1, 4 do
	local a = math.rad(k * 90 + 45)
	table.insert(
		petParts,
		P(
			"HaloGem" .. k,
			{ 0.34, 0.34, 0.34 },
			{ math.sin(a) * 1.45, 7.0, 0.1 - math.cos(a) * 1.45 },
			TEAL,
			{ joint = "Halo", material = "Neon", rot = { 45, 0, 45 } }
		)
	)
end
table.insert(petParts, core("Orbit", 3.9))
for k = 1, 5 do
	local a = math.rad(k * 72)
	addTo(
		petParts,
		S.shard(
			"Jade" .. k,
			cf({ math.sin(a) * 3.6, 3.4 + (k % 2) * 0.9, -math.cos(a) * 3.6 }, { 0, 0, 15 }),
			1.0,
			0.36,
			TEAL,
			o("Orbit", { material = "Neon" })
		)
	)
end
table.insert(petParts, core("Orbit2", 6.0))
for k = 1, 3 do
	local a = math.rad(k * 120 + 30)
	table.insert(
		petParts,
		P("Coin" .. k, { 0.12, 0.6, 0.6 }, { math.sin(a) * 2.7, 6.0, -math.cos(a) * 2.7 }, GOLD, {
			joint = "Orbit2",
			shape = "Cylinder",
			material = "Neon",
			rot = { 0, 90 - k * 120 - 30, 0 },
		})
	)
end
local pet: Builder.Spec = { parts = petParts }

return { egg = egg, pet = pet }
