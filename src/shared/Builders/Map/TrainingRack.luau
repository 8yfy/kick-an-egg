--!strict
-- Partner A. Kick-training station (BlockBuilder data), treadmill-gate style:
-- a dark base with a glowing belt ("Plate", stand here) lined with saw-tooth spikes, a stone gate at
-- the back with a lattice and glowing lamps, a kick bag hanging in the gate ("Chain"/"Bag"...) and a
-- dark "SignBoard" on top (MapBuilder writes "+X / kick" on it). Faces -Z: you step on from -Z.
-- Tiers (Config/Upgrades): Wood, Stone, Iron, Gold, Crystal, Inferno.
local Builder = require(script.Parent.Parent.BlockBuilder)

type Spec = Builder.Spec
type Opts = {
	rot: { number }?,
	material: string?,
	shape: string?,
	transparency: number?,
	light: Color3?,
	studs: boolean?,
}
local rgb = Color3.fromRGB

local function P(name: string, size: { number }, pos: { number }, color: Color3, o: Opts?): Builder.PartSpec
	local opts: Opts = o or {}
	return {
		name = name,
		size = size,
		pos = pos,
		color = color,
		rot = opts.rot,
		material = opts.material,
		shape = opts.shape,
		transparency = opts.transparency,
		light = opts.light,
		studs = opts.studs,
	}
end

-- stone: gate/pillars, dark: base + lattice, glow: belt/lamps/spikes accent, bag: kick bag
type Look = { stone: Color3, dark: Color3, glow: Color3, spike: Color3, bag: Color3, lattice: Color3 }
local LOOKS: { [string]: Look } = {
	Wood = {
		stone = rgb(150, 100, 60),
		dark = rgb(85, 60, 40),
		glow = rgb(255, 200, 80),
		spike = rgb(200, 150, 70),
		bag = rgb(210, 60, 50),
		lattice = rgb(60, 42, 30),
	},
	Stone = {
		stone = rgb(95, 95, 105),
		dark = rgb(45, 48, 55),
		glow = rgb(110, 255, 90),
		spike = rgb(80, 200, 70),
		bag = rgb(60, 140, 60),
		lattice = rgb(30, 32, 38),
	},
	Iron = {
		stone = rgb(80, 90, 115),
		dark = rgb(35, 40, 55),
		glow = rgb(70, 220, 255),
		spike = rgb(60, 160, 230),
		bag = rgb(40, 100, 210),
		lattice = rgb(25, 28, 40),
	},
	Gold = {
		stone = rgb(220, 170, 60),
		dark = rgb(70, 55, 40),
		glow = rgb(255, 235, 110),
		spike = rgb(255, 200, 50),
		bag = rgb(250, 245, 230),
		lattice = rgb(110, 80, 30),
	},
	Crystal = {
		stone = rgb(120, 90, 190),
		dark = rgb(40, 30, 70),
		glow = rgb(230, 120, 255),
		spike = rgb(170, 110, 255),
		bag = rgb(120, 230, 255),
		lattice = rgb(30, 22, 55),
	},
	Inferno = {
		stone = rgb(70, 35, 30),
		dark = rgb(30, 20, 20),
		glow = rgb(255, 120, 30),
		spike = rgb(255, 80, 30),
		bag = rgb(170, 30, 25),
		lattice = rgb(20, 12, 12),
	},
}

local TrainingRack = {}

function TrainingRack.tiers(): { string }
	return { "Wood", "Stone", "Iron", "Gold", "Crystal", "Inferno" }
end

function TrainingRack.spec(tier: string): Spec
	local L = LOOKS[tier] or LOOKS.Wood
	local rank = table.find(TrainingRack.tiers(), tier) or 1
	local parts = {
		-- base + belt
		P("Base", { 10, 1.2, 20 }, { 0, 0.6, 0 }, L.dark),
		P("Plate", { 6.4, 0.3, 15 }, { 0, 1.35, -1.5 }, L.glow, { material = "Neon", transparency = 0.15 }),
		P("FrontStep", { 8, 0.6, 2.2 }, { 0, 0.3, -11 }, L.dark),
		P("RollerFront", { 7, 1.1, 1.1 }, { 0, 1.2, -9.3 }, L.stone, { shape = "Cylinder" }),
		-- gate at the back
		P("PillarL", { 2.2, 13, 2.2 }, { -4.6, 7.7, 8.4 }, L.stone),
		P("PillarR", { 2.2, 13, 2.2 }, { 4.6, 7.7, 8.4 }, L.stone),
		P("PillarBaseL", { 2.8, 1.2, 2.8 }, { -4.6, 1.8, 8.4 }, L.dark),
		P("PillarBaseR", { 2.8, 1.2, 2.8 }, { 4.6, 1.8, 8.4 }, L.dark),
		P("CapL", { 2.8, 0.8, 2.8 }, { -4.6, 14.6, 8.4 }, L.dark),
		P("CapR", { 2.8, 0.8, 2.8 }, { 4.6, 14.6, 8.4 }, L.dark),
		P("LampL", { 1.6, 1.6, 1.6 }, { -4.6, 15.8, 8.4 }, L.glow, { material = "Neon", light = L.glow }),
		P("LampR", { 1.6, 1.6, 1.6 }, { 4.6, 15.8, 8.4 }, L.glow, { material = "Neon" }),
		P("Beam", { 11.6, 1.6, 2.4 }, { 0, 13.6, 8.4 }, L.stone),
		-- kick bag hanging in front of the lattice
		P("Chain", { 0.3, 3, 0.3 }, { 0, 11.3, 6.6 }, rgb(60, 60, 70)),
		P("Bag", { 4, 2.4, 2.4 }, { 0, 7.8, 6.6 }, L.bag, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("BagCap", { 0.5, 2.6, 2.6 }, { 0, 9.8, 6.6 }, L.dark, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("BagBand", { 0.4, 2.5, 2.5 }, { 0, 7.8, 6.6 }, L.dark, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("BagBottom", { 0.5, 2.2, 2.2 }, { 0, 5.8, 6.6 }, L.dark, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		-- sign board above the gate (MapBuilder adds the text)
		P("SignPostL", { 0.5, 2.2, 0.5 }, { -3, 15.5, 8.4 }, L.dark),
		P("SignPostR", { 0.5, 2.2, 0.5 }, { 3, 15.5, 8.4 }, L.dark),
		P("SignBoard", { 9, 2.6, 0.5 }, { 0, 17.6, 8.4 }, rgb(30, 34, 42)),
	}
	-- lattice filling the gate behind the bag
	for i = -1, 1 do
		table.insert(parts, P("LatticeV", { 0.45, 11.6, 0.45 }, { i * 1.75, 7, 9.2 }, L.lattice))
	end
	for j = 0, 3 do
		table.insert(parts, P("LatticeH", { 7.2, 0.45, 0.45 }, { 0, 3.6 + j * 2.9, 9.2 }, L.lattice))
	end
	-- belt slats and saw-tooth spikes along both rails
	for k = 0, 4 do
		table.insert(parts, P("Slat", { 6.5, 0.32, 0.5 }, { 0, 1.36, -7.5 + k * 3 }, L.dark))
	end
	for _, side in { -1, 1 } do
		table.insert(parts, P("Rail", { 1.2, 1, 17 }, { side * 4.1, 1.6, -0.5 }, L.dark))
		for k = 0, 5 do
			table.insert(
				parts,
				P("Spike", { 0.8, 1.6, 2.4 }, { side * 4.1, 2.9, -7.8 + k * 2.6 }, L.spike, { shape = "Wedge" })
			)
		end
	end
	-- higher tiers: more glow and ornaments
	if rank >= 3 then
		for _, side in { -1, 1 } do
			table.insert(
				parts,
				P("RailGlow", { 0.2, 0.3, 16 }, { side * 4.75, 1.75, -0.5 }, L.glow, { material = "Neon" })
			)
		end
	end
	if rank >= 4 then
		for i, x in { -3, 0, 3 } do
			table.insert(
				parts,
				P("Crown" .. i, { 0.8, 1.4, 0.8 }, { x, 14.9, 9.3 }, L.glow, { rot = { 0, 45, 0 }, material = "Neon" })
			)
		end
	end
	if rank >= 5 then
		for i, o in { { -4.6, -8 }, { 4.6, -8 }, { -4.6, 2 }, { 4.6, 2 } } do
			table.insert(
				parts,
				P(
					"Shard" .. i,
					{ 0.9, 2.6, 0.9 },
					{ o[1], 2.4, o[2] },
					L.glow,
					{ material = "Neon", rot = { 12, 30 * i, 12 } }
				)
			)
		end
	end
	if rank >= 6 then
		for i, x in { -4.6, 4.6 } do
			table.insert(
				parts,
				P(
					"Flame" .. i,
					{ 1.6, 1.8, 1.6 },
					{ x, 17.2, 8.4 },
					rgb(255, 140, 30),
					{ material = "Neon", rot = { 0, 45, 0 } }
				)
			)
			table.insert(
				parts,
				P(
					"FlameTip" .. i,
					{ 0.9, 1.1, 0.9 },
					{ x, 18.4, 8.4 },
					rgb(255, 230, 90),
					{ material = "Neon", rot = { 0, 45, 0 } }
				)
			)
		end
	end
	return { parts = parts }
end

return TrainingRack
