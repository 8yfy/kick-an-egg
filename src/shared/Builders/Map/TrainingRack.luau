--!strict
-- Partner A. Kick-training rack spec (BlockBuilder data) for a Config/Upgrades tier.
-- Faces -Z; the player stands on "Plate" (front) and kicks "Bag" (hangs from "Chain" under the beam).
-- Tiers: Wood, Stone, Iron, Gold, Crystal, Inferno; higher tiers add ornaments and glow.
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

type Look = { frame: Color3, trim: Color3, bag: Color3, base: Color3, glow: Color3, material: string? }
local LOOKS: { [string]: Look } = {
	Wood = {
		frame = rgb(150, 95, 55),
		trim = rgb(105, 65, 40),
		bag = rgb(200, 60, 50),
		base = rgb(120, 120, 125),
		glow = rgb(255, 200, 90),
	},
	Stone = {
		frame = rgb(150, 150, 155),
		trim = rgb(100, 100, 110),
		bag = rgb(215, 180, 120),
		base = rgb(90, 90, 100),
		glow = rgb(140, 220, 255),
	},
	Iron = {
		frame = rgb(70, 75, 90),
		trim = rgb(150, 155, 170),
		bag = rgb(50, 110, 220),
		base = rgb(45, 48, 60),
		glow = rgb(90, 200, 255),
	},
	Gold = {
		frame = rgb(255, 200, 60),
		trim = rgb(200, 140, 40),
		bag = rgb(250, 248, 240),
		base = rgb(60, 55, 70),
		glow = rgb(255, 230, 120),
	},
	Crystal = {
		frame = rgb(140, 230, 255),
		trim = rgb(90, 140, 230),
		bag = rgb(170, 110, 255),
		base = rgb(50, 45, 90),
		glow = rgb(120, 245, 255),
		material = "Glass",
	},
	Inferno = {
		frame = rgb(40, 32, 36),
		trim = rgb(255, 120, 30),
		bag = rgb(180, 40, 30),
		base = rgb(30, 24, 28),
		glow = rgb(255, 140, 40),
	},
}

local TrainingRack = {}

function TrainingRack.tiers(): { string }
	return { "Wood", "Stone", "Iron", "Gold", "Crystal", "Inferno" }
end

function TrainingRack.spec(tier: string): Spec
	local L = LOOKS[tier] or LOOKS.Wood
	local rank = table.find(TrainingRack.tiers(), tier) or 1
	local fm = L.material
	local parts = {
		P("Platform", { 10, 1, 8 }, { 0, 0.5, 0 }, L.base),
		P("PlatformTrim", { 10.4, 0.4, 8.4 }, { 0, 0.2, 0 }, L.trim),
		P("Plate", { 4, 0.3, 3.4 }, { 0, 1.15, -2 }, L.glow, { material = "Neon" }),
		P("PlateRim", { 4.6, 0.25, 4 }, { 0, 1.05, -2 }, L.trim),
		P("UprightL", { 1.2, 10, 1.2 }, { -4, 6, 1.5 }, L.frame, { material = fm }),
		P("UprightR", { 1.2, 10, 1.2 }, { 4, 6, 1.5 }, L.frame, { material = fm }),
		P("FootL", { 2, 0.6, 3 }, { -4, 1.3, 1.5 }, L.trim),
		P("FootR", { 2, 0.6, 3 }, { 4, 1.3, 1.5 }, L.trim),
		P("Beam", { 9.6, 1.2, 1.4 }, { 0, 11.4, 1.5 }, L.frame, { material = fm }),
		P("BeamTrim", { 10, 0.4, 1.6 }, { 0, 12.2, 1.5 }, L.trim),
		P("Arm", { 1, 1, 3.4 }, { 0, 11.4, -0.2 }, L.frame, { material = fm }),
		P("Chain", { 0.3, 2.2, 0.3 }, { 0, 9.7, -1.4 }, rgb(70, 70, 80)),
		P("Bag", { 4.2, 2.2, 2.2 }, { 0, 6.6, -1.4 }, L.bag, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("BagCap", { 0.5, 2.4, 2.4 }, { 0, 8.6, -1.4 }, L.trim, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("BagBand", { 0.4, 2.3, 2.3 }, { 0, 6.6, -1.4 }, L.trim, { shape = "Cylinder", rot = { 0, 0, 90 } }),
		P("BagBottom", { 0.5, 2.0, 2.0 }, { 0, 4.55, -1.4 }, L.trim, { shape = "Cylinder", rot = { 0, 0, 90 } }),
	}
	-- weight plates on the uprights and level lamps on the beam
	for _, x in { -4, 4 } do
		table.insert(
			parts,
			P(
				"Weight",
				{ 0.5, 2.6, 2.6 },
				{ x + (if x < 0 then -0.85 else 0.85), 3.4, 1.5 },
				L.trim,
				{ shape = "Cylinder" }
			)
		)
		table.insert(
			parts,
			P("Lamp", { 0.8, 0.8, 0.8 }, { x, 12.2 + 0.6, 1.5 }, L.glow, { material = "Neon", shape = "Ball" })
		)
	end
	for i = 1, rank do
		table.insert(
			parts,
			P("Pip" .. i, { 0.5, 0.5, 0.15 }, { -3 + (i - 1) * 1.2, 11.4, 0.75 }, L.glow, { material = "Neon" })
		)
	end
	if rank >= 4 then -- Gold+: crown ornaments on the beam
		for i, x in { -2.5, 0, 2.5 } do
			table.insert(parts, P("Ornament" .. i, { 0.7, 1.2, 0.7 }, { x, 13.2, 1.5 }, L.trim, { rot = { 0, 45, 0 } }))
		end
	end
	if rank >= 5 then -- Crystal+: shards on the platform corners
		for i, o in { { -4.4, -3.4 }, { 4.4, -3.4 }, { -4.4, 3.4 }, { 4.4, 3.4 } } do
			table.insert(
				parts,
				P(
					"Shard" .. i,
					{ 0.8, 2.4, 0.8 },
					{ o[1], 2.1, o[2] },
					L.glow,
					{ material = "Neon", rot = { 10, 30 * i, 10 } }
				)
			)
		end
	end
	if rank >= 6 then -- Inferno: flames on the uprights
		for i, x in { -4, 4 } do
			table.insert(
				parts,
				P(
					"Flame" .. i,
					{ 1.4, 1.6, 1.4 },
					{ x, 13.6, 1.5 },
					rgb(255, 140, 30),
					{ material = "Neon", rot = { 0, 45, 0 } }
				)
			)
			table.insert(
				parts,
				P(
					"FlameTip" .. i,
					{ 0.8, 1.0, 0.8 },
					{ x, 14.7, 1.5 },
					rgb(255, 230, 90),
					{ material = "Neon", rot = { 0, 45, 0 } }
				)
			)
		end
	end
	return { parts = parts }
end

return TrainingRack
