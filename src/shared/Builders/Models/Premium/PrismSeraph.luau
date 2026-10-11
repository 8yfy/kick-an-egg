--!strict
-- 79 Prism Seraph (Rainbow Heaven, Secret). Hero example 7/7 (docs/EggPetPlan.md): the most exclusive model,
-- an instantly iconic showcase silhouette.
-- Egg: pearl egg with a seven-band rainbow prism belt, gold filigree ribs, a prism-crystal crown, small prism
--      wings and a gold medallion, sitting in a cloud ring; a jewelled gold halo spins above it and seven
--      prism crystals (one per colour) orbit it.
-- Pet: a seraph hovering on a cloud: three pairs of prism-glass wings, a rainbow aureole behind it, a gold
--      breastplate with a prism core, a prism crown, a jewelled spinning halo, seven orbiting prism crystals
--      and a counter-orbit of star crystals.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local PEARL, CLOUD, GOLD = rgb(250, 247, 240), rgb(255, 255, 255), rgb(255, 214, 84)
local STARLIGHT, INK = rgb(225, 245, 255), rgb(60, 50, 90)
local RAINBOW = S.RAINBOW

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
-- A prism feather: rainbow glass blade with a white neon tip, along cf's up axis.
local function prismFeather(
	name: string,
	base: CFrame,
	len: number,
	w: number,
	color: Color3,
	joint: string
): { Builder.PartSpec }
	return {
		S.at(
			name,
			{ w, len, 0.12 },
			base * CFrame.new(0, len / 2, 0),
			color,
			o(joint, { material = "Glass", transparency = 0.12 })
		),
		S.at(
			name .. "Rib",
			{ 0.1, len * 0.9, 0.16 },
			base * CFrame.new(-w / 2 + 0.05, len * 0.5, 0),
			GOLD,
			o(joint, { studs = false })
		),
		S.at(
			name .. "Tip",
			{ w * 0.55, len * 0.16, 0.16 },
			base * CFrame.new(0, len + len * 0.06, 0) * CFrame.Angles(0, 0, math.rad(45)),
			STARLIGHT,
			o(joint, { material = "Neon" })
		),
	}
end

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 5.4, 4.0
local eggParts = S.eggShell(H, W, function(i, n)
	return if i >= n - 1 then CLOUD else PEARL
end)
-- seven-band rainbow prism belt
for k, c in RAINBOW do
	table.insert(eggParts, S.eggBand("Prism" .. k, H, W, 1.95 + (k - 1) * 0.15, 0.16, 0.06, c, { material = "Neon" }))
end
addTo(eggParts, {
	S.eggBand("BeltTop", H, W, 3.0, 0.12, 0.1, GOLD, { studs = false }),
	S.eggBand("BeltLow", H, W, 1.83, 0.12, 0.1, GOLD, { studs = false }),
	S.plate("Medallion", H, W, 0, 3.75, { 0.95, 0.95, 0.16 }, GOLD, { rot = { 0, 0, 45 } }),
	S.plate("MedallionGem", H, W, 0, 3.75, { 0.48, 0.48, 0.24 }, STARLIGHT, { material = "Neon", rot = { 0, 0, 45 } }),
})
-- gold filigree ribs above and below the belt
for k = 1, 8 do
	local a = k * 45 + 22.5
	table.insert(eggParts, S.plate("RibHi" .. k, H, W, a, 3.75, { 0.12, 1.15, 0.12 }, GOLD))
	table.insert(eggParts, S.plate("RibLo" .. k, H, W, a, 1.15, { 0.12, 0.85, 0.12 }, GOLD))
end
-- prism-crystal crown
for k = 1, 7 do
	local a = math.rad(k * 360 / 7)
	addTo(
		eggParts,
		S.shard(
			"CrownCrystal" .. k,
			cf({ math.sin(a) * 0.45, H - 0.3, -math.cos(a) * 0.45 }, { -math.cos(a) * 22, 0, -math.sin(a) * 22 }),
			1.05,
			0.3,
			RAINBOW[k],
			o("Body", { material = "Neon" })
		)
	)
end
-- small prism wings
for _, side in { -1, 1 } do
	local pivot = cf({ side * (S.eggRadius(H, W, 3.3) - 0.05), 3.3, 0.35 }, { 0, 0, -side * 52 })
	for k = 1, 4 do
		addTo(
			eggParts,
			prismFeather(
				"Wing" .. side .. "_" .. k,
				pivot * CFrame.Angles(0, 0, math.rad(-side * (k - 1) * 22)),
				1.45 - k * 0.12,
				0.42,
				RAINBOW[(k * 2 - 1) % 7 + 1],
				"Body"
			)
		)
	end
end
-- cloud ring at the base
for k = 1, 9 do
	local a = math.rad(k * 40)
	table.insert(
		eggParts,
		P(
			"Cloud" .. k,
			{ 0.95, 0.95, 0.95 },
			{ math.sin(a) * 1.75, 0.4, -math.cos(a) * 1.75 },
			CLOUD,
			{ joint = "Body", shape = "Ball" }
		)
	)
end
-- jewelled gold halo + seven prism crystals in orbit
table.insert(eggParts, core("Halo", H + 1.0))
addTo(
	eggParts,
	S.ring("Halo", CFrame.new(0, H + 1.0, 0), 14, 1.1, { 0.38, 0.16, 0.2 }, GOLD, o("Halo", { material = "Neon" }))
)
for k, c in RAINBOW do
	local a = math.rad(k * 360 / 7)
	table.insert(
		eggParts,
		P(
			"HaloGem" .. k,
			{ 0.26, 0.26, 0.26 },
			{ math.sin(a) * 1.1, H + 1.12, -math.cos(a) * 1.1 },
			c,
			{ joint = "Halo", material = "Neon", rot = { 45, 0, 45 } }
		)
	)
end
table.insert(eggParts, core("Orbit", 2.8))
for k, c in RAINBOW do
	local a = math.rad(k * 360 / 7)
	addTo(
		eggParts,
		S.shard(
			"Orbiter" .. k,
			cf({ math.sin(a) * 3.3, 2.2 + (k % 3) * 0.55, -math.cos(a) * 3.3 }, { 0, 0, 12 }),
			0.8,
			0.3,
			c,
			o("Orbit", { material = "Neon" })
		)
	)
end
local egg: Builder.Spec = { parts = eggParts }

-- Pet -------------------------------------------------------------------------------------------------------
local FACE_Z = -0.72
local petParts: { Builder.PartSpec } = {
	-- body (hinge first): tapering robe, chest, gold breastplate + belt, prism core
	P("Chest", { 2.3, 1.5, 1.8 }, { 0, 4.65, 0.1 }, PEARL, { joint = "Body" }),
	P("RobeMid", { 1.9, 1.3, 1.6 }, { 0, 3.35, 0.1 }, PEARL, { joint = "Body" }),
	P("RobeLow", { 1.45, 1.15, 1.3 }, { 0, 2.15, 0.1 }, PEARL, { joint = "Body" }),
	P("RobeTip", { 0.9, 0.6, 0.9 }, { 0, 1.3, 0.1 }, STARLIGHT, { joint = "Body", material = "Neon" }),
	P("Breastplate", { 1.9, 1.25, 0.2 }, { 0, 4.7, -0.86 }, GOLD, { joint = "Body" }),
	P("Belt", { 1.98, 0.22, 1.68 }, { 0, 3.95, 0.1 }, GOLD, { joint = "Body", studs = false }),
	P("RobeTrim", { 1.5, 0.16, 1.36 }, { 0, 1.62, 0.1 }, GOLD, { joint = "Body", studs = false }),
	P(
		"PrismCore",
		{ 0.55, 0.55, 0.16 },
		{ 0, 4.75, -1.02 },
		STARLIGHT,
		{ joint = "Body", material = "Neon", rot = { 0, 0, 45 } }
	),
	-- head: pearl helm, glowing eyes, gold circlet, prism crown
	P("Head", { 1.4, 1.35, 1.35 }, { 0, 6.08, 0.05 }, PEARL, { joint = "Head" }),
	P("Faceplate", { 1.1, 0.6, 0.12 }, { 0, 5.95, FACE_Z }, STARLIGHT, { joint = "Head", studs = false }),
	P("EyeL", { 0.3, 0.16, 0.08 }, { -0.27, 6.0, FACE_Z - 0.08 }, INK, { joint = "Head", material = "Neon" }),
	P("EyeR", { 0.3, 0.16, 0.08 }, { 0.27, 6.0, FACE_Z - 0.08 }, INK, { joint = "Head", material = "Neon" }),
	P("Circlet", { 1.48, 0.2, 1.43 }, { 0, 6.5, 0.05 }, GOLD, { joint = "Head", studs = false }),
}
-- core rim: a little rainbow ring around the prism core
addTo(
	petParts,
	(function()
		local parts = {}
		for k, c in RAINBOW do
			local a = math.rad(k * 360 / 7)
			table.insert(
				parts,
				P(
					"CoreRim" .. k,
					{ 0.16, 0.16, 0.12 },
					{ math.sin(a) * 0.48, 4.75 + math.cos(a) * 0.48, -1.0 },
					c,
					{ joint = "Body", material = "Neon" }
				)
			)
		end
		return parts
	end)()
)
-- prism crown
for k = 1, 7 do
	local a = math.rad(k * 360 / 7)
	addTo(
		petParts,
		S.shard(
			"Crown" .. k,
			cf({ math.sin(a) * 0.55, 6.65, 0.05 - math.cos(a) * 0.55 }, { -math.cos(a) * 15, 0, -math.sin(a) * 15 }),
			0.75 + (if k == 7 then 0.35 else 0),
			0.24,
			RAINBOW[k],
			o("Head", { material = "Neon" })
		)
	)
end
-- rainbow aureole behind the body (vertical ring)
for k = 1, 21 do
	local a = math.rad(k * 360 / 21)
	table.insert(
		petParts,
		S.at(
			"Aureole" .. k,
			{ 0.8, 0.3, 0.2 },
			cf({ math.sin(a) * 2.7, 5.0 + math.cos(a) * 2.7, 1.45 }) * CFrame.Angles(0, 0, -a + math.rad(90)),
			RAINBOW[(k - 1) % 7 + 1],
			{
				joint = "Body",
				material = "Neon",
			}
		)
	)
end
-- left side (mirrored): arm, three wings
local left: { Builder.PartSpec } = {
	P("ArmL", { 0.5, 1.6, 0.5 }, { -1.38, 4.4, 0.05 }, PEARL, { joint = "ArmL", rot = { 0, 0, -12 } }),
	P("BracerL", { 0.6, 0.45, 0.6 }, { -1.5, 3.85, 0.05 }, GOLD, { joint = "ArmL", rot = { 0, 0, -12 } }),
	P("HandL", { 0.5, 0.45, 0.5 }, { -1.6, 3.4, 0.0 }, STARLIGHT, { joint = "ArmL", material = "Neon" }),
	P("ShoulderL", { 0.75, 0.55, 0.9 }, { -1.3, 5.3, 0.1 }, GOLD, { joint = "Body" }),
}
local shoulder = cf({ -0.85, 5.1, 0.85 }, { 0, -15, 0 })
local wings = {
	{ from = 8, to = 62, count = 6, len = 3.9 }, -- upper pair, rising
	{ from = 72, to = 112, count = 5, len = 3.3 }, -- middle pair, out
	{ from = 122, to = 160, count = 4, len = 2.5 }, -- lower pair, sweeping down
}
for wi, wing in wings do
	for k = 1, wing.count do
		local f = (k - 1) / (wing.count - 1)
		local a = wing.from + (wing.to - wing.from) * f
		local len = wing.len * (1 - 0.18 * math.abs(f - 0.5) * 2)
		local base = shoulder
			* CFrame.new(0, 0, (wi - 2) * 0.22)
			* CFrame.Angles(0, 0, math.rad(a))
			* CFrame.new(0, 0.35, 0)
		addTo(left, prismFeather("WingL" .. wi .. "_" .. k, base, len, 0.5, RAINBOW[(k + wi * 2 - 2) % 7 + 1], "WingL"))
	end
end
addTo(petParts, S.both(left))
-- cloud the seraph hovers on (stays still while the body bobs)
for k, c in
	{
		{ 0, 0.55, 0, 1.6 },
		{ -1.0, 0.45, 0.3, 1.25 },
		{ 1.0, 0.45, 0.3, 1.25 },
		{ -0.5, 0.4, -0.75, 1.1 },
		{ 0.6, 0.4, -0.7, 1.05 },
		{ 0.2, 0.45, 1.1, 1.2 },
		{ -1.6, 0.3, -0.2, 0.8 },
		{ 1.65, 0.3, -0.15, 0.85 },
	}
do
	table.insert(petParts, P("Cloud" .. k, { c[4], c[4], c[4] }, { c[1], c[2], c[3] }, CLOUD, { shape = "Ball" }))
end
-- jewelled spinning halo, seven prism crystals in orbit, counter-orbiting star crystals
table.insert(petParts, core("Halo", 7.55))
addTo(
	petParts,
	S.ring("Halo", CFrame.new(0, 7.55, 0.05), 16, 1.2, { 0.38, 0.18, 0.2 }, GOLD, o("Halo", { material = "Neon" }))
)
for k, c in RAINBOW do
	local a = math.rad(k * 360 / 7)
	table.insert(
		petParts,
		P(
			"HaloGem" .. k,
			{ 0.3, 0.3, 0.3 },
			{ math.sin(a) * 1.2, 7.7, 0.05 - math.cos(a) * 1.2 },
			c,
			{ joint = "Halo", material = "Neon", rot = { 45, 0, 45 } }
		)
	)
end
table.insert(petParts, core("Orbit", 4.6))
for k, c in RAINBOW do
	local a = math.rad(k * 360 / 7)
	addTo(
		petParts,
		S.shard(
			"Prism" .. k,
			cf({ math.sin(a) * 4.4, 3.8 + (k % 3) * 0.75, -math.cos(a) * 4.4 }, { 0, 0, 14 }),
			1.1,
			0.38,
			c,
			o("Orbit", { material = "Neon" })
		)
	)
end
table.insert(petParts, core("Orbit2", 2.2))
for k = 1, 4 do
	local a = math.rad(k * 90 + 45)
	addTo(
		petParts,
		S.shard(
			"Star" .. k,
			cf({ math.sin(a) * 2.6, 2.1, -math.cos(a) * 2.6 }),
			0.6,
			0.26,
			STARLIGHT,
			o("Orbit2", { material = "Neon" })
		)
	)
end
local pet: Builder.Spec = { parts = petParts }

return { egg = egg, pet = pet }
