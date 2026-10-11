--!strict
-- 63 Clockwork Titan (Clockwork Factory, Divine). Hero example 6/7 (docs/EggPetPlan.md): majestic endgame,
-- titan-like, ceremonial.
-- Egg: brass reactor egg: copper bands and rivets, a teal porthole core in a steel frame, side pipes, steam
--      stacks, a gear crown; a toothed gear ring turns around its waist and a small gear halo floats above.
-- Pet: a massive brass golem: steel pauldrons with gear emblems, piston arms and gauntlets, a teal reactor core,
--      visor eyes, chimney stacks; a sacred brass sun-gear frames its head, a gear crown spins above it and a
--      toothed gear ring turns around its waist.
local Builder = require(script.Parent.Parent.Parent.BlockBuilder)
local S = require(script.Parent.Parent.Sculpt)

local P, rgb = S.part, Color3.fromRGB
local BRASS, BRASS_DK, COPPER = rgb(212, 166, 72), rgb(152, 112, 46), rgb(192, 108, 62)
local STEEL, STEEL_DK, TEAL, GOLD = rgb(152, 162, 176), rgb(88, 96, 110), rgb(64, 234, 214), rgb(255, 214, 96)

local function cf(pos: { number }, rot: { number }?): CFrame
	return S.cf(pos, rot)
end
local function o(joint: string, extra: S.Opts?): S.Opts
	local t: S.Opts = table.clone(extra or {})
	t.joint = joint
	return t
end
local function core(joint: string, y: number): Builder.PartSpec
	return P(joint .. "Core", { 0.2, 0.2, 0.2 }, { 0, y, 0 }, BRASS, { joint = joint, transparency = 1, studs = false })
end
local function addTo(list: { Builder.PartSpec }, more: { Builder.PartSpec })
	for _, p in more do
		table.insert(list, p)
	end
end
-- Toothed ring lying flat at height y (spun as a group): teeth + a few teal markers so the turn reads.
local function toothRing(name: string, joint: string, y: number, r: number, teeth: number): { Builder.PartSpec }
	local parts = S.ring(name, CFrame.new(0, y, 0), teeth, r, { 0.36, 0.3, 0.42 }, BRASS, o(joint))
	addTo(
		parts,
		S.ring(
			name .. "Band",
			CFrame.new(0, y, 0),
			teeth,
			r - 0.22,
			{ r * 6.28 / teeth + 0.05, 0.22, 0.16 },
			BRASS_DK,
			o(joint)
		)
	)
	addTo(
		parts,
		S.ring(
			name .. "Mark",
			CFrame.new(0, y + 0.18, 0),
			3,
			r,
			{ 0.26, 0.12, 0.26 },
			TEAL,
			o(joint, { material = "Neon" }),
			15
		)
	)
	return parts
end
-- Round porthole facing -Z at (x, y, z): teal neon core, steel frame of rivets.
local function porthole(name: string, joint: string, pos: Vector3, r: number): { Builder.PartSpec }
	local face = CFrame.new(pos) * CFrame.Angles(math.rad(90), 0, 0)
	local parts = {
		S.at(
			name .. "Core",
			{ 0.18, r * 2, r * 2 },
			CFrame.new(pos) * CFrame.Angles(0, math.rad(90), 0),
			TEAL,
			o(joint, { material = "Neon", shape = "Cylinder" })
		),
	}
	addTo(parts, S.ring(name .. "Rivet", face, 8, r + 0.2, { 0.26, 0.26, 0.2 }, STEEL, o(joint), 22.5))
	return parts
end

-- Egg -------------------------------------------------------------------------------------------------------
local H, W = 5.2, 3.9
local eggParts = S.join(
	S.eggShell(H, W, 17, function(i, n)
		return if i <= 3 then STEEL_DK elseif i == 8 or i == 13 then COPPER elseif i >= n - 1 then BRASS_DK else BRASS
	end),
	{
		S.eggBand("SteelBand", H, W, 1.05, 0.2, 0.06, STEEL),
		S.eggBand("CopperBand", H, W, 3.95, 0.16, 0.06, COPPER),
	},
	porthole("Port", "Body", Vector3.new(0, 2.85, -S.eggRadius(H, W, 2.85) - 0.02), 0.62),
	toothRing("WaistGear", "Orbit", 2.15, S.eggRadius(H, W, 2.15) + 0.42, 18),
	{ core("Orbit", 2.15) }
)
-- rivet rows
for k = 1, 12 do
	table.insert(eggParts, S.plate("Rivet" .. k, H, W, k * 30 + 15, 1.45, { 0.18, 0.18, 0.18 }, STEEL_DK))
	table.insert(eggParts, S.plate("RivetHi" .. k, H, W, k * 30, 3.7, { 0.16, 0.16, 0.16 }, STEEL_DK))
end
-- side pipes with elbows, steam stacks, gear crown
for _, side in { -1, 1 } do
	local x = side * (S.eggRadius(H, W, 2.6) + 0.12)
	table.insert(
		eggParts,
		P("Pipe" .. side, { 0.3, 2.4, 0.3 }, { x, 2.6, 0.35 }, COPPER, { joint = "Body", shape = "Block" })
	)
	table.insert(
		eggParts,
		P("PipeElbow" .. side, { 0.42, 0.42, 0.42 }, { x, 3.85, 0.35 }, BRASS_DK, { joint = "Body" })
	)
	table.insert(
		eggParts,
		P(
			"Stack" .. side,
			{ 1.0, 0.5, 0.5 },
			{ side * 0.75, H - 0.25, 0.5 },
			STEEL_DK,
			{ joint = "Body", shape = "Cylinder", rot = { 0, 0, 90 } }
		)
	)
	table.insert(
		eggParts,
		P(
			"StackRim" .. side,
			{ 0.14, 0.62, 0.62 },
			{ side * 0.75, H + 0.27, 0.5 },
			COPPER,
			{ joint = "Body", shape = "Cylinder", rot = { 0, 0, 90 } }
		)
	)
end
addTo(eggParts, S.ring("Crown", CFrame.new(0, H - 0.05, 0), 8, 0.62, { 0.26, 0.42, 0.26 }, GOLD, o("Body")))
table.insert(eggParts, core("Halo", H + 1.05))
addTo(eggParts, S.gear("HaloGear", CFrame.new(0, H + 1.05, 0), 0.75, 0.18, 10, GOLD, o("Halo", { material = "Neon" })))
addTo(
	eggParts,
	S.ring(
		"HaloSpoke",
		CFrame.new(0, H + 1.18, 0),
		3,
		0.35,
		{ 0.14, 0.12, 0.62 },
		TEAL,
		o("Halo", { material = "Neon" })
	)
)
local egg: Builder.Spec = { parts = eggParts }

-- Pet -------------------------------------------------------------------------------------------------------
local petParts: { Builder.PartSpec } = {
	-- body (hinge first)
	P("Torso", { 3.4, 2.6, 2.4 }, { 0, 5.6, 0.1 }, BRASS, { joint = "Body" }),
	P("Pelvis", { 2.4, 0.85, 1.7 }, { 0, 3.95, 0.1 }, STEEL_DK, { joint = "Body" }),
	P("ChestPlate", { 2.7, 2.1, 0.22 }, { 0, 5.65, -1.16 }, COPPER, { joint = "Body" }),
	P("Belly", { 2.6, 0.7, 2.2 }, { 0, 4.55, 0.1 }, BRASS_DK, { joint = "Body" }),
	P("BackPlate", { 2.6, 2.2, 0.3 }, { 0, 5.7, 1.4 }, STEEL, { joint = "Body" }),
	P("Collar", { 2.0, 0.45, 1.8 }, { 0, 7.05, -0.05 }, STEEL_DK, { joint = "Body" }),
	-- head
	P("Head", { 1.55, 1.25, 1.45 }, { 0, 7.75, -0.35 }, BRASS, { joint = "Head" }),
	P("Visor", { 1.3, 0.42, 0.14 }, { 0, 7.75, -1.12 }, STEEL_DK, { joint = "Head" }),
	P("EyeL", { 0.48, 0.2, 0.1 }, { -0.32, 7.77, -1.22 }, TEAL, { joint = "Head", material = "Neon" }),
	P("EyeR", { 0.48, 0.2, 0.1 }, { 0.32, 7.77, -1.22 }, TEAL, { joint = "Head", material = "Neon" }),
	P("Jaw", { 1.2, 0.3, 0.3 }, { 0, 7.25, -1.0 }, STEEL, { joint = "Head" }),
	P("HeadFin", { 0.24, 0.6, 1.3 }, { 0, 8.6, -0.25 }, COPPER, { joint = "Head" }),
}
addTo(petParts, porthole("Reactor", "Body", Vector3.new(0, 5.75, -1.3), 0.62))
for k = 1, 3 do
	table.insert(
		petParts,
		P(
			"Vent" .. k,
			{ 1.6, 0.12, 0.1 },
			{ 0, 4.75 - (k - 2) * 0.2 - 0.2, -1.28 },
			TEAL,
			{ joint = "Body", material = "Neon" }
		)
	)
end
-- chimney stacks + back pipes
for _, side in { -1, 1 } do
	table.insert(
		petParts,
		P(
			"Chimney" .. side,
			{ 1.9, 0.62, 0.62 },
			{ side * 0.85, 7.6, 1.15 },
			STEEL_DK,
			{ joint = "Body", shape = "Cylinder", rot = { 0, 0, 90 } }
		)
	)
	table.insert(
		petParts,
		P(
			"ChimneyRim" .. side,
			{ 0.16, 0.8, 0.8 },
			{ side * 0.85, 8.58, 1.15 },
			COPPER,
			{ joint = "Body", shape = "Cylinder", rot = { 0, 0, 90 } }
		)
	)
	table.insert(
		petParts,
		P("BackPipe" .. side, { 0.28, 2.4, 0.28 }, { side * 1.4, 5.5, 1.62 }, COPPER, { joint = "Body" })
	)
end
-- rivets across the chest plate
for k = 1, 8 do
	local x = if k <= 4 then -1.15 else 1.15
	table.insert(
		petParts,
		P(
			"Rivet" .. k,
			{ 0.16, 0.16, 0.08 },
			{ x, 4.85 + ((k - 1) % 4) * 0.5, -1.29 },
			STEEL_DK,
			{ joint = "Body", studs = false }
		)
	)
end
-- sacred sun-gear framing the head (vertical, behind the shoulders)
addTo(petParts, S.gear("SunGear", cf({ 0, 7.7, 1.45 }, { 90, 0, 0 }), 1.9, 0.22, 16, GOLD, o("Body")))
addTo(
	petParts,
	S.ring(
		"SunGearInner",
		cf({ 0, 7.7, 1.33 }, { 90, 0, 0 }),
		12,
		1.25,
		{ 0.2, 0.2, 0.2 },
		TEAL,
		o("Body", { material = "Neon" })
	)
)
-- left side, mirrored: pauldron, arm (ArmL), leg (LegL)
local left: { Builder.PartSpec } = {
	P("UpperArmL", { 0.95, 1.7, 0.95 }, { -2.4, 5.7, 0.1 }, BRASS_DK, { joint = "ArmL" }),
	P("PauldronL", { 1.75, 1.05, 2.0 }, { -2.45, 6.8, 0.1 }, STEEL, { joint = "ArmL" }),
	P("PauldronTrimL", { 1.8, 0.2, 2.05 }, { -2.45, 6.3, 0.1 }, BRASS, { joint = "ArmL", studs = false }),
	P("PistonL", { 0.22, 1.5, 0.22 }, { -2.0, 4.85, -0.42 }, STEEL, { joint = "ArmL" }),
	P("ForearmL", { 1.25, 1.65, 1.25 }, { -2.45, 4.15, 0.0 }, COPPER, { joint = "ArmL" }),
	P("ForearmBandL", { 1.32, 0.22, 1.32 }, { -2.45, 4.7, 0.0 }, BRASS, { joint = "ArmL", studs = false }),
	P("FistL", { 1.4, 1.15, 1.4 }, { -2.45, 2.9, -0.05 }, STEEL_DK, { joint = "ArmL" }),
	P("KnucklesL", { 1.42, 0.3, 0.3 }, { -2.45, 3.05, -0.78 }, BRASS, { joint = "ArmL", studs = false }),
	P("HipL", { 1.1, 0.9, 1.1 }, { -0.95, 3.45, 0.1 }, STEEL_DK, { joint = "LegL" }),
	P("ThighL", { 1.2, 1.4, 1.3 }, { -0.95, 2.55, 0.1 }, BRASS, { joint = "LegL" }),
	P("KneeL", { 0.3, 0.75, 0.75 }, { -1.6, 1.85, 0.05 }, COPPER, { joint = "LegL", shape = "Cylinder" }),
	P("ShinL", { 1.25, 1.45, 1.35 }, { -0.95, 1.15, 0.05 }, STEEL, { joint = "LegL" }),
	P("BootL", { 1.5, 0.5, 1.95 }, { -0.95, 0.25, -0.15 }, BRASS_DK, { joint = "LegL" }),
	P("ToeL", { 1.3, 0.3, 0.4 }, { -0.95, 0.3, -1.2 }, STEEL_DK, { joint = "LegL" }),
}
addTo(left, S.gear("EmblemL", cf({ -3.36, 6.8, 0.1 }, { 0, 0, 90 }), 0.55, 0.12, 8, GOLD, o("ArmL")))
table.insert(
	left,
	P(
		"EmblemCoreL",
		{ 0.16, 0.42, 0.42 },
		{ -3.42, 6.8, 0.1 },
		TEAL,
		{ joint = "ArmL", material = "Neon", shape = "Cylinder" }
	)
)
addTo(petParts, S.both(left))
-- gear crown spinning above the head; a toothed gear ring turning around the waist; three cogs orbiting
table.insert(petParts, core("Halo", 9.35))
addTo(petParts, S.gear("Crown", CFrame.new(0, 9.35, -0.3), 1.0, 0.22, 12, GOLD, o("Halo", { material = "Neon" })))
addTo(
	petParts,
	S.ring("CrownSpoke", CFrame.new(0, 9.5, -0.3), 3, 0.5, { 0.16, 0.14, 0.8 }, TEAL, o("Halo", { material = "Neon" }))
)
table.insert(petParts, core("Orbit2", 4.3))
addTo(petParts, toothRing("WaistGear", "Orbit2", 4.3, 2.7, 24))
table.insert(petParts, core("Orbit", 6.0))
for k = 1, 3 do
	local a = math.rad(k * 120)
	addTo(
		petParts,
		S.gear(
			"Cog" .. k,
			cf({ math.sin(a) * 4.0, 6.0 + (k - 2) * 0.8, -math.cos(a) * 4.0 }, { 90, 0, 0 }),
			0.45,
			0.16,
			8,
			BRASS,
			o("Orbit")
		)
	)
end
local pet: Builder.Spec = { parts = petParts }

return { egg = egg, pet = pet }
