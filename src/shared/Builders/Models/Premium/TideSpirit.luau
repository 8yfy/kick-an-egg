--!strict
-- 07 Tide Spirit (Sandy Beach, Epic). Hero example 3/7 (docs/EggPetPlan.md): transformed silhouette, layered.
-- Egg: sand-bottomed sea egg with a foam wave crest, a seashell fan, a starfish, a floating water ring and
--      orbiting bubbles.
-- Pet: a floating water spirit (no legs): fin ears, foam mane, big cyan eyes, flipper fins, a tail that swoops
--      back and curls up, a glass water halo and orbiting droplets.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local AQUA, SEA, DEEP = rgb(72, 206, 236), rgb(38, 124, 208), rgb(26, 74, 152)
local FOAM, SAND, CORAL, CYAN = rgb(240, 252, 255), rgb(234, 214, 170), rgb(255, 150, 140), rgb(130, 242, 255)

local function cf(pos: { number }, rot: { number }?): CFrame
	return S.cf(pos, rot)
end

local function core(joint: string, y: number): Builder.PartSpec
	-- invisible hub: first part of a spin group (Anim/Spin turns the group about it)
	return P(joint .. "Core", { 0.2, 0.2, 0.2 }, { 0, y, 0 }, FOAM, { joint = joint, transparency = 1, studs = false })
end

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 4.4, 3.3
local eggParts = S.join(
	S.eggShell(H, W, function(i, n)
		return if i == 1 then SAND elseif i <= 3 then DEEP elseif i <= 5 then SEA elseif i < n then AQUA else FOAM
	end),
	{ S.eggBand("WaveBand", H, W, 1.95, 0.3, 0.05, FOAM, { studs = false }) },
	S.eggRing("Crest", H, W, 2.2, 3, { 0.42, 0.42, 0.2 }, FOAM, {
		joint = "Body",
		rot = { 0, 0, 45 },
	}),
	S.fan(
		"Seashell",
		S.onEgg(H, W, 0, 2.75, 0.08) * CFrame.new(0, -0.35, 0),
		7,
		-62,
		62,
		0.85,
		0.17,
		0.12,
		{ CORAL, FOAM },
		{
			joint = "Body",
		}
	),
	{ S.at("SeashellHinge", { 0.4, 0.22, 0.16 }, S.onEgg(H, W, 0, 2.38, 0.1), CORAL, { joint = "Body" }) },
	S.fan("Starfish", S.onEgg(H, W, 180, 1.2, 0.08), 5, 0, 288, 0.5, 0.2, 0.1, { CORAL }, { joint = "Body" }),
	{ core("Orbit", 2.35) },
	S.ring("WaterRing", CFrame.new(0, 2.35, 0), 14, 2.75, { 0.55, 0.16, 0.22 }, AQUA, {
		joint = "Orbit",
		material = "Glass",
		transparency = 0.25,
	}),
	{ core("Orbit2", 3.4) }
)
for k = 1, 5 do
	local a = math.rad(k * 72)
	table.insert(
		eggParts,
		P("Bubble" .. k, { 0.3, 0.3, 0.3 }, { math.sin(a) * 2.35, 3.0 + (k % 3) * 0.35, -math.cos(a) * 2.35 }, CYAN, {
			joint = "Orbit2",
			material = "Neon",
			shape = "Ball",
		})
	)
end
local egg: Builder.Spec = { parts = eggParts }

-- Pet -------------------------------------------------------------------------------------------------------
local FACE_Z = -1.27
local petParts = S.join({
	P("Torso", { 1.75, 1.7, 1.75 }, { 0, 2.95, 0.05 }, AQUA, { joint = "Body" }),
	P("Chest", { 1.3, 1.1, 0.15 }, { 0, 2.9, -0.86 }, FOAM, { joint = "Body", studs = false }),
	P("Belt", { 1.82, 0.32, 1.82 }, { 0, 2.2, 0.05 }, SEA, { joint = "Body" }),
	P("BackFin", { 0.22, 1.2, 1.0 }, { 0, 4.05, 0.85 }, SEA, { joint = "Body", rot = { 25, 0, 0 } }),
	P("Gem", { 0.4, 0.4, 0.12 }, { 0, 3.0, -0.96 }, CYAN, { joint = "Body", material = "Neon", rot = { 0, 0, 45 } }),
	-- head
	P("Head", { 2.3, 1.75, 1.9 }, { 0, 4.7, -0.3 }, AQUA, { joint = "Head" }),
	P("Mask", { 1.2, 0.5, 0.12 }, { 0, 4.12, FACE_Z }, FOAM, { joint = "Head", studs = false }),
	P("Snout", { 0.6, 0.32, 0.26 }, { 0, 4.1, FACE_Z - 0.16 }, FOAM, { joint = "Head" }),
	P("Nose", { 0.26, 0.16, 0.1 }, { 0, 4.24, FACE_Z - 0.31 }, DEEP, { joint = "Head", studs = false }),
	P("EyeL", { 0.55, 0.62, 0.1 }, { -0.55, 4.72, FACE_Z }, CYAN, { joint = "Head", material = "Neon" }),
	P("EyeR", { 0.55, 0.62, 0.1 }, { 0.55, 4.72, FACE_Z }, CYAN, { joint = "Head", material = "Neon" }),
	P(
		"GlintL",
		{ 0.18, 0.18, 0.05 },
		{ -0.67, 4.88, FACE_Z - 0.07 },
		Color3.new(1, 1, 1),
		{ joint = "Head", material = "Neon" }
	),
	P(
		"GlintR",
		{ 0.18, 0.18, 0.05 },
		{ 0.43, 4.88, FACE_Z - 0.07 },
		Color3.new(1, 1, 1),
		{ joint = "Head", material = "Neon" }
	),
}, S.fan("Crest", cf({ 0, 5.55, -0.2 }), 3, -24, 24, 1.0, 0.18, 0.55, { SEA, AQUA, SEA }, { joint = "Head" }, 0.3))
-- foam mane around the neck
for _, p in
	S.ring("Mane", CFrame.new(0, 3.85, 0.05), 7, 1.0, { 0.62, 0.5, 0.45 }, FOAM, { joint = "Body", studs = false }, 77)
do
	table.insert(petParts, p)
end
-- pearl necklace + seashell clips at the base of the fin ears
for _, p in
	S.ring("Pearl", CFrame.new(0, 3.6, 0.05), 9, 0.97, { 0.24, 0.24, 0.24 }, FOAM, { joint = "Body", shape = "Ball" })
do
	table.insert(petParts, p)
end
for _, p in
	S.both(S.fan("ClipL", cf({ -1.18, 4.95, -0.85 }), 5, -60, 60, 0.5, 0.15, 0.12, { CORAL }, { joint = "Head" }))
do
	table.insert(petParts, p)
end
-- fin ears + flipper arms (left; mirrored)
for _, p in
	S.both(
		S.join(
			S.fan(
				"EarL",
				cf({ -1.1, 5.3, -0.3 }, { 0, 0, 40 }),
				3,
				-26,
				26,
				1.25,
				0.2,
				0.55,
				{ AQUA, FOAM, SEA },
				{ joint = "Head" },
				0.35
			),
			{
				P(
					"FlipperL",
					{ 0.26, 1.15, 0.8 },
					{ -1.05, 2.95, -0.2 },
					AQUA,
					{ joint = "ArmL", rot = { 0, 0, -32 } }
				),
				P(
					"FlipperTipL",
					{ 0.24, 0.45, 0.65 },
					{ -1.38, 2.45, -0.2 },
					FOAM,
					{ joint = "ArmL", rot = { 0, 0, -32 } }
				),
			}
		)
	)
do
	table.insert(petParts, p)
end
-- tail: swoops down and back, then curls up behind (each segment smaller), ends in a foam fluke
local c = cf({ 0, 2.25, 0.75 }, { -35, 0, 0 })
for i = 1, 7 do
	local w = 1.05 - i * 0.1
	table.insert(
		petParts,
		S.at(
			"Tail" .. i,
			{ w, 0.7, w },
			c * CFrame.new(0, -0.32, 0),
			if i % 2 == 0 then SEA else AQUA,
			{ joint = "Tail" }
		)
	)
	c = c * CFrame.new(0, -0.6, 0) * CFrame.Angles(math.rad(-24), 0, 0)
end
for _, p in
	S.fan(
		"Fluke",
		c * CFrame.Angles(math.rad(180), 0, 0),
		3,
		-40,
		40,
		0.8,
		0.22,
		0.5,
		{ FOAM, CYAN, FOAM },
		{ joint = "Tail" }
	)
do
	table.insert(petParts, p)
end
-- glass water halo (spins) + orbiting droplets (spin) + wisps under the body (counter-spin)
table.insert(petParts, core("Halo", 6.05))
for _, p in
	S.ring("Halo", CFrame.new(0, 6.05, -0.3), 12, 1.25, { 0.42, 0.16, 0.2 }, AQUA, {
		joint = "Halo",
		material = "Glass",
		transparency = 0.15,
	})
do
	table.insert(petParts, p)
end
table.insert(petParts, core("Orbit", 3.1))
for k = 1, 4 do
	local a = math.rad(k * 90 + 20)
	table.insert(
		petParts,
		P(
			"Droplet" .. k,
			{ 0.48, 0.48, 0.48 },
			{ math.sin(a) * 2.35, 3.1 + (k % 2) * 0.5, -math.cos(a) * 2.35 },
			CYAN,
			{
				joint = "Orbit",
				material = "Neon",
				shape = "Ball",
			}
		)
	)
end
table.insert(petParts, core("Orbit2", 1.4))
for k = 1, 3 do
	local a = math.rad(k * 120)
	table.insert(
		petParts,
		P("Wisp" .. k, { 0.55, 0.55, 0.55 }, { math.sin(a) * 1.5, 1.35, -math.cos(a) * 1.5 }, AQUA, {
			joint = "Orbit2",
			material = "Glass",
			shape = "Ball",
			transparency = 0.3,
		})
	)
end
local pet: Builder.Spec = { parts = petParts }

return { egg = egg, pet = pet }
