--!strict
-- Training station (BlockBuilder data): a compact studded TREADMILL. You step on from -Z and run
-- toward the console at +Z; the belt ("Plate", stand here) carries you back, so you keep running.
-- Map v3 rework (Partner B, at A's request; reference: a small wooden treadmill with a console):
-- footprint 6.6 x 14 studs (was 10 x 22), console 7 studs tall (was an 18-stud gate).
-- Stable part names MapBuilder / UI / client use:
--   Plate (belt top; conveyor), Slat (belt slats, scrolled by the client), SignBoard (console screen:
--   MapBuilder writes the gain / level), LampL / LampR (console lights), FxAnchor (belt rear: ambient
--   + per-step VFX), PopAnchor (above the console: "+X Power" pops).
-- Tiers (Config/Upgrades): Wood, Stone, Iron, Gold, Crystal, Inferno — each adds detail on top of
-- the last (glow strips, vents + hazard step, fins + gem, crystals, horns + flame vents).
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

-- frame: deck sides, rail: top trim, belt/slat: running belt, accent: glow, grip: handlebar
type Look = { frame: Color3, rail: Color3, belt: Color3, slat: Color3, accent: Color3, grip: Color3, screen: Color3 }
local LOOKS: { [string]: Look } = {
	Wood = {
		frame = rgb(205, 145, 85),
		rail = rgb(160, 105, 60),
		belt = rgb(55, 50, 55),
		slat = rgb(95, 88, 95),
		accent = rgb(255, 200, 80),
		grip = rgb(220, 60, 50),
		screen = rgb(30, 34, 42),
	},
	Stone = {
		frame = rgb(160, 160, 172),
		rail = rgb(110, 110, 124),
		belt = rgb(45, 48, 55),
		slat = rgb(80, 86, 94),
		accent = rgb(110, 255, 90),
		grip = rgb(60, 150, 60),
		screen = rgb(24, 36, 30),
	},
	Iron = {
		frame = rgb(100, 112, 138),
		rail = rgb(68, 76, 100),
		belt = rgb(35, 40, 55),
		slat = rgb(70, 220, 255),
		accent = rgb(70, 220, 255),
		grip = rgb(40, 100, 210),
		screen = rgb(18, 28, 44),
	},
	Gold = {
		frame = rgb(240, 190, 60),
		rail = rgb(255, 228, 120),
		belt = rgb(62, 50, 40),
		slat = rgb(255, 238, 150),
		accent = rgb(255, 245, 160),
		grip = rgb(250, 245, 230),
		screen = rgb(44, 34, 20),
	},
	Crystal = {
		frame = rgb(140, 105, 210),
		rail = rgb(100, 72, 170),
		belt = rgb(40, 30, 70),
		slat = rgb(230, 120, 255),
		accent = rgb(230, 120, 255),
		grip = rgb(120, 230, 255),
		screen = rgb(28, 20, 50),
	},
	Inferno = {
		frame = rgb(62, 34, 30),
		rail = rgb(38, 24, 24),
		belt = rgb(26, 18, 18),
		slat = rgb(255, 110, 30),
		accent = rgb(255, 120, 30),
		grip = rgb(170, 30, 25),
		screen = rgb(36, 14, 10),
	},
}

local TIERS = { "Wood", "Stone", "Iron", "Gold", "Crystal", "Inferno" }

-- Ambient MapFx preset per tier (MapBuilder emits it on FxAnchor).
local AMBIENT: { [string]: string } = {
	Wood = "TreadWood",
	Stone = "TreadStone",
	Iron = "TreadIron",
	Gold = "TreadGold",
	Crystal = "TreadCrystal",
	Inferno = "TreadInferno",
}

local TrainingRack = {}

TrainingRack.BELT = { width = 4.6, length = 10.4, z = -0.4 } -- Plate, in model space

function TrainingRack.tiers(): { string }
	return table.clone(TIERS)
end

function TrainingRack.look(tier: string): Look
	return LOOKS[tier] or LOOKS.Wood
end

function TrainingRack.ambient(tier: string): string
	return AMBIENT[tier] or AMBIENT.Wood
end

-- Conveyor speed (studs/s, toward -Z): faster belts on better treadmills, always below walk speed.
function TrainingRack.beltSpeed(tier: string): number
	local rank = table.find(TIERS, tier) or 1
	return 5 + rank * 1.2
end

function TrainingRack.spec(tier: string): Spec
	local L = LOOKS[tier] or LOOKS.Wood
	local rank = table.find(TIERS, tier) or 1
	local belt = TrainingRack.BELT
	local neonSlats = rank >= 3
	local parts = {
		-- deck: frame, side rails, front step, rollers, belt
		P("Base", { 6.6, 0.8, 12 }, { 0, 0.4, 0 }, L.frame),
		P("RailL", { 1, 0.6, 12 }, { -2.8, 1.1, 0 }, L.rail),
		P("RailR", { 1, 0.6, 12 }, { 2.8, 1.1, 0 }, L.rail),
		P("Step", { 6.6, 0.4, 1.6 }, { 0, 0.2, -6.8 }, L.rail),
		P("RollerBack", { 4.8, 1, 1 }, { 0, 0.95, -5.5 }, L.rail, { shape = "Cylinder" }),
		P("RollerFront", { 4.8, 1, 1 }, { 0, 0.95, 4.7 }, L.rail, { shape = "Cylinder" }),
		P("Plate", { belt.width, 0.3, belt.length }, { 0, 0.95, belt.z }, L.belt, { studs = false }),
		-- console at the +Z end: posts, handlebar, side handrails, tilted screen, lamps
		P("PostL", { 0.6, 4.4, 0.6 }, { -2.5, 3.2, 5.5 }, L.rail),
		P("PostR", { 0.6, 4.4, 0.6 }, { 2.5, 3.2, 5.5 }, L.rail),
		P("Handlebar", { 5.6, 0.5, 0.5 }, { 0, 4.5, 4.9 }, L.grip, { shape = "Cylinder" }),
		P("HandrailL", { 0.4, 0.4, 4.2 }, { -2.5, 3.9, 3.3 }, L.grip),
		P("HandrailR", { 0.4, 0.4, 4.2 }, { 2.5, 3.9, 3.3 }, L.grip),
		P("Console", { 5, 2.4, 0.9 }, { 0, 6.2, 5.7 }, L.frame, { rot = { 20, 0, 0 } }),
		P("SignBoard", { 4.4, 1.9, 0.2 }, { 0, 6.25, 5.2 }, L.screen, { rot = { 20, 0, 0 }, studs = false }),
		P("LampL", { 0.6, 0.6, 0.6 }, { -2.2, 7.6, 6 }, L.accent, { material = "Neon", light = L.accent }),
		P("LampR", { 0.6, 0.6, 0.6 }, { 2.2, 7.6, 6 }, L.accent, { material = "Neon" }),
		-- invisible anchors for effects
		P("FxAnchor", { 4, 0.2, 0.6 }, { 0, 1.3, -5.6 }, L.accent, { transparency = 1, studs = false }),
		P("PopAnchor", { 0.4, 0.4, 0.4 }, { 0, 8.6, 5.4 }, L.accent, { transparency = 1, studs = false }),
	}
	-- belt slats (the client scrolls them so the belt visibly runs)
	for k = 0, 6 do
		table.insert(
			parts,
			P(
				"Slat",
				{ belt.width - 0.1, 0.06, 0.35 },
				{ 0, 1.13, belt.z - belt.length / 2 + 0.75 + k * 1.5 },
				L.slat,
				{
					material = if neonSlats then "Neon" else nil,
					studs = false,
				}
			)
		)
	end

	-- Tier detail, cumulative
	if rank >= 2 then -- glowing strips along the deck
		for _, side in { -1, 1 } do
			table.insert(
				parts,
				P("GlowStrip", { 0.2, 0.3, 11.6 }, { side * 3.35, 0.55, 0 }, L.accent, { material = "Neon" })
			)
		end
	end
	if rank >= 3 then -- vented side panels and a hazard-striped step
		for _, side in { -1, 1 } do
			for k = -1, 1 do
				table.insert(parts, P("Vent", { 0.15, 0.25, 2.2 }, { side * 3.33, 0.28, k * 3.4 }, L.rail))
			end
		end
		for k = 0, 4 do
			table.insert(
				parts,
				P(
					"Hazard",
					{ 1.2, 0.05, 1.5 },
					{ -2.6 + k * 1.3, 0.42, -6.8 },
					if k % 2 == 0 then rgb(255, 210, 40) else rgb(30, 30, 35),
					{ studs = false }
				)
			)
		end
	end
	if rank >= 4 then -- console fins and a gem on top
		for _, side in { -1, 1 } do
			table.insert(
				parts,
				P("Fin", { 0.4, 2.2, 1.6 }, { side * 2.95, 6.4, 6 }, L.accent, { shape = "Wedge", rot = { 0, 180, 0 } })
			)
		end
		table.insert(
			parts,
			P(
				"Gem",
				{ 0.9, 0.9, 0.9 },
				{ 0, 8, 6 },
				L.accent,
				{ material = "Neon", rot = { 45, 0, 45 }, light = L.accent }
			)
		)
	end
	if rank >= 5 then -- crystal clusters at the deck corners
		for i, o in { { -3, -5.4 }, { 3, -5.4 }, { -3, 5.2 }, { 3, 5.2 } } do
			table.insert(
				parts,
				P(
					"Crystal" .. i,
					{ 0.7, 2.2, 0.7 },
					{ o[1], 1.9, o[2] },
					L.accent,
					{ material = "Glass", transparency = 0.15, rot = { 14, 30 * i, 10 } }
				)
			)
		end
	end
	if rank >= 6 then -- horns on the console and flame vents at the back
		for _, side in { -1, 1 } do
			table.insert(
				parts,
				P(
					"Horn",
					{ 0.5, 1.8, 0.5 },
					{ side * 2.4, 8.2, 6.1 },
					rgb(240, 225, 200),
					{ rot = { 0, 0, side * -25 } }
				)
			)
			table.insert(
				parts,
				P("FlameVent", { 0.9, 0.8, 0.9 }, { side * 2.2, 1.2, -6.2 }, rgb(255, 130, 30), { material = "Neon" })
			)
		end
	end
	return { parts = parts }
end

return TrainingRack
