--!strict
-- Partner A. Parametric creature specs so every pet is DATA:
--   Creatures.build({ kind = "Quadruped", rarity = "Epic", palette = {...}, ears = "pointy", wings = "bat", ... })
-- Archetypes (all face -Z, feet at y = 0, rigged with the standard joint groups):
--   Quadruped (pups, cats, foxes, dragons), Biped (golems, bears, mechs), Flyer (birds, bees, bats),
--   Floater (spirits, slimes, ghosts), Fish.
-- Features (all optional): ears, horns, tail, wings, mane, spikes, armor, crystals, flames, spots,
--   stripes, shell, ghost.
-- Rarity dressing is automatic: Rare+ coloured eyes, Epic+ Neon runes + core light, Legendary+ crown
-- and an "Orbit" ring of Neon cubes, Mythic+ a "Halo" and a second ring, Divine+ fairy wings,
-- Secret rainbow. The spec is padded with armour scales to the rarity's part budget and scaled so
-- its height goes from 3 studs (Common) to 9 (Secret). Orbit/Halo groups are spun by Anim.
local Builder = require(script.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Kit)
local Rarities = require(script.Parent.Parent.Parent.Config.Rarities)

type PartSpec = Builder.PartSpec

export type Palette = {
	main: Color3,
	accent: Color3,
	belly: Color3,
	eye: Color3?, -- Neon eye colour (default near-black)
	metal: Color3?, -- armour / horns (default darkened accent)
	glow: Color3?, -- runes, flames, crystal cores (default rarity colour)
}

export type Def = {
	kind: string,
	rarity: string,
	palette: Palette,
	ears: string?, -- "pointy" | "round" | "long" | "fin"
	horns: string?, -- "straight" | "curl" | "unicorn" | "antler"
	tail: string?, -- "stub" | "long" | "fluffy" | "spike" | "fan" | "flame"
	wings: string?, -- "feather" | "bat" | "crystal" | "fairy"
	mane: boolean?,
	spikes: boolean?,
	armor: boolean?,
	crystals: boolean?,
	flames: boolean?,
	spots: boolean?,
	stripes: boolean?,
	shell: boolean?,
	ghost: boolean?,
}

type Box = { c: Vector3, s: Vector3 }
type Anchors = {
	torso: Box,
	head: Box,
	faceZ: number,
	earX: number,
	tailBase: Vector3,
	headJoint: string,
}
type Eye = { x: number, y: number, z: number, w: number, h: number, joint: string }
type Ctx = { parts: { PartSpec }, def: Def, pal: Palette, a: Anchors, metal: Color3, glow: Color3, eye: Eye? }

local INK = Color3.fromRGB(30, 28, 40)
local GOLD = Color3.fromRGB(255, 205, 60)
local BUDGET: { [string]: { number } } = {
	Common = { 15, 25 },
	Uncommon = { 25, 40 },
	Rare = { 40, 60 },
	Epic = { 60, 90 },
	Legendary = { 90, 130 },
	Mythic = { 130, 200 },
	Divine = { 130, 200 },
	Secret = { 130, 200 },
}

local Creatures = {}

local function v(t: Vector3): { number }
	return { t.X, t.Y, t.Z }
end

local function add(ctx: Ctx, name: string, size: Vector3, pos: Vector3, color: Color3, o: Kit.Opts?)
	table.insert(ctx.parts, Kit.part(name, v(size), v(pos), color, o))
end

-- Left part (at -X) + mirrored right part. `pos` is given for the +X side, `o.rot` for the left side.
-- splitJoint: joint "Wing" -> "WingL"/"WingR".
local function pair(
	ctx: Ctx,
	name: string,
	size: Vector3,
	pos: Vector3,
	color: Color3,
	o: Kit.Opts?,
	splitJoint: boolean?
)
	local opts: Kit.Opts = o or {}
	for _, side in { -1, 1 } do
		local s = if side < 0 then "L" else "R"
		local copy: Kit.Opts = table.clone(opts)
		if splitJoint and opts.joint then
			copy.joint = opts.joint .. s
		end
		local rot = opts.rot
		copy.rot = if rot and side > 0 then { rot[1], -rot[2], -rot[3] } else rot
		add(ctx, name .. s, size, Vector3.new(side * pos.X, pos.Y, pos.Z), color, copy)
	end
end

local function eyes(ctx: Ctx, x: number, y: number, faceZ: number, w: number, h: number, joint: string)
	ctx.eye = { x = x, y = y, z = faceZ, w = w, h = h, joint = joint }
	for _, p in Kit.eye(-1, -x, y, faceZ, w, h, joint) do
		table.insert(ctx.parts, p)
	end
	for _, p in Kit.eye(1, x, y, faceZ, w, h, joint) do
		table.insert(ctx.parts, p)
	end
end

------------------------------------------------------------------ archetypes

local function quadruped(ctx: Ctx)
	local p = ctx.pal
	add(ctx, "Torso", Vector3.new(2.0, 1.2, 2.6), Vector3.new(0, 1.5, 0.05), p.main, { joint = "Body" })
	add(ctx, "Belly", Vector3.new(1.5, 0.15, 2.0), Vector3.new(0, 0.88, 0.05), p.belly, { joint = "Body" })
	add(ctx, "Head", Vector3.new(1.8, 1.4, 1.5), Vector3.new(0, 2.6, -1.35), p.main, { joint = "Head" })
	add(ctx, "Muzzle", Vector3.new(1.0, 0.6, 0.45), Vector3.new(0, 2.25, -2.3), p.belly, { joint = "Head" })
	add(ctx, "Nose", Vector3.new(0.4, 0.28, 0.2), Vector3.new(0, 2.45, -2.6), INK, { joint = "Head" })
	eyes(ctx, 0.45, 2.8, -2.1, 0.3, 0.42, "Head")
	pair(ctx, "Arm", Vector3.new(0.6, 0.5, 0.6), Vector3.new(0.6, 0.85, -0.8), p.main, { joint = "Arm" }, true)
	pair(ctx, "Paw", Vector3.new(0.7, 0.6, 0.75), Vector3.new(0.6, 0.3, -0.85), p.belly, { joint = "Arm" }, true)
	pair(ctx, "Leg", Vector3.new(0.6, 0.5, 0.6), Vector3.new(0.6, 0.85, 0.9), p.main, { joint = "Leg" }, true)
	pair(ctx, "Foot", Vector3.new(0.7, 0.6, 0.75), Vector3.new(0.6, 0.3, 0.85), p.belly, { joint = "Leg" }, true)
	ctx.a = {
		torso = { c = Vector3.new(0, 1.5, 0.05), s = Vector3.new(2.0, 1.2, 2.6) },
		head = { c = Vector3.new(0, 2.6, -1.35), s = Vector3.new(1.8, 1.4, 1.5) },
		faceZ = -2.1,
		earX = 0.75,
		tailBase = Vector3.new(0, 1.8, 1.35),
		headJoint = "Head",
	}
end

local function biped(ctx: Ctx)
	local p = ctx.pal
	pair(ctx, "Leg", Vector3.new(0.8, 1.0, 0.8), Vector3.new(0.55, 0.55, 0), p.main, { joint = "Leg" }, true)
	pair(ctx, "Foot", Vector3.new(1.0, 0.3, 1.2), Vector3.new(0.55, 0.15, -0.15), p.belly, { joint = "Leg" }, true)
	add(ctx, "Torso", Vector3.new(2.2, 1.8, 1.6), Vector3.new(0, 1.95, 0), p.main, { joint = "Body" })
	add(ctx, "BellyPlate", Vector3.new(1.4, 1.2, 0.12), Vector3.new(0, 1.85, -0.83), p.belly, { joint = "Body" })
	add(ctx, "Head", Vector3.new(1.7, 1.3, 1.4), Vector3.new(0, 3.5, -0.1), p.main, { joint = "Head" })
	add(ctx, "Snout", Vector3.new(0.8, 0.4, 0.3), Vector3.new(0, 3.2, -0.9), p.belly, { joint = "Head" })
	eyes(ctx, 0.4, 3.6, -0.8, 0.3, 0.38, "Head")
	pair(ctx, "Arm", Vector3.new(0.6, 0.6, 0.6), Vector3.new(1.4, 2.55, 0), p.main, { joint = "Arm" }, true)
	pair(ctx, "Forearm", Vector3.new(0.6, 1.1, 0.6), Vector3.new(1.45, 1.8, -0.05), p.main, { joint = "Arm" }, true)
	pair(ctx, "Hand", Vector3.new(0.75, 0.5, 0.75), Vector3.new(1.45, 1.05, -0.05), p.belly, { joint = "Arm" }, true)
	ctx.a = {
		torso = { c = Vector3.new(0, 1.95, 0), s = Vector3.new(2.2, 1.8, 1.6) },
		head = { c = Vector3.new(0, 3.5, -0.1), s = Vector3.new(1.7, 1.3, 1.4) },
		faceZ = -0.8,
		earX = 0.7,
		tailBase = Vector3.new(0, 1.4, 0.8),
		headJoint = "Head",
	}
end

local function flyer(ctx: Ctx)
	local p = ctx.pal
	add(ctx, "Torso", Vector3.new(2.0, 2.0, 2.2), Vector3.new(0, 1.9, 0), p.main, { joint = "Body" })
	add(ctx, "Belly", Vector3.new(1.4, 1.4, 0.15), Vector3.new(0, 1.75, -1.1), p.belly, { joint = "Body" })
	add(ctx, "Head", Vector3.new(1.6, 1.3, 1.4), Vector3.new(0, 3.2, -0.4), p.main, { joint = "Head" })
	add(
		ctx,
		"Beak",
		Vector3.new(0.5, 0.4, 0.6),
		Vector3.new(0, 3.0, -1.35),
		p.accent,
		{ joint = "Head", shape = "Wedge" }
	)
	eyes(ctx, 0.42, 3.35, -1.1, 0.3, 0.38, "Head")
	pair(ctx, "Leg", Vector3.new(0.3, 0.6, 0.3), Vector3.new(0.5, 0.6, 0), p.accent, { joint = "Leg" }, true)
	pair(ctx, "Foot", Vector3.new(0.6, 0.2, 0.8), Vector3.new(0.5, 0.1, -0.2), p.accent, { joint = "Leg" }, true)
	ctx.a = {
		torso = { c = Vector3.new(0, 1.9, 0), s = Vector3.new(2.0, 2.0, 2.2) },
		head = { c = Vector3.new(0, 3.2, -0.4), s = Vector3.new(1.6, 1.3, 1.4) },
		faceZ = -1.1,
		earX = 0.55,
		tailBase = Vector3.new(0, 1.7, 1.1),
		headJoint = "Head",
	}
	if not ctx.def.wings then
		ctx.def.wings = "feather"
	end
	if not ctx.def.tail then
		ctx.def.tail = "fan"
	end
end

local function floater(ctx: Ctx)
	local p = ctx.pal
	add(ctx, "Base", Vector3.new(2.6, 0.9, 2.6), Vector3.new(0, 0.95, 0), p.main, { joint = "Body" })
	add(ctx, "Middle", Vector3.new(2.2, 0.9, 2.2), Vector3.new(0, 1.85, 0), p.main, { joint = "Body" })
	add(ctx, "Top", Vector3.new(1.5, 0.6, 1.5), Vector3.new(0, 2.6, 0), p.accent, { joint = "Body" })
	add(ctx, "Cheeks", Vector3.new(1.6, 0.25, 0.08), Vector3.new(0, 1.62, -1.12), p.belly, { joint = "Body" })
	add(ctx, "Mouth", Vector3.new(0.4, 0.12, 0.06), Vector3.new(0, 1.55, -1.16), INK, { joint = "Body" })
	eyes(ctx, 0.45, 2.0, -1.1, 0.32, 0.42, "Body")
	for i, x in { -0.7, 0, 0.7 } do
		add(
			ctx,
			"Wisp" .. i,
			Vector3.new(0.55, 0.45, 0.55),
			Vector3.new(x, 0.3, 0.3 * i - 0.6),
			p.accent,
			{ joint = "Body" }
		)
	end
	ctx.a = {
		torso = { c = Vector3.new(0, 1.85, 0), s = Vector3.new(2.2, 0.9, 2.2) },
		head = { c = Vector3.new(0, 2.3, 0), s = Vector3.new(1.5, 1.1, 1.5) },
		faceZ = -1.1,
		earX = 0.6,
		tailBase = Vector3.new(0, 1.2, 1.2),
		headJoint = "Body",
	}
end

local function fish(ctx: Ctx)
	local p = ctx.pal
	add(ctx, "Torso", Vector3.new(1.4, 1.6, 2.6), Vector3.new(0, 1.9, 0), p.main, { joint = "Body" })
	add(ctx, "Belly", Vector3.new(1.2, 0.4, 2.2), Vector3.new(0, 1.15, 0), p.belly, { joint = "Body" })
	add(ctx, "Head", Vector3.new(1.3, 1.4, 0.8), Vector3.new(0, 1.9, -1.6), p.main, { joint = "Head" })
	add(ctx, "Lips", Vector3.new(0.6, 0.3, 0.2), Vector3.new(0, 1.6, -2.05), p.accent, { joint = "Head" })
	eyes(ctx, 0.38, 2.15, -2.0, 0.3, 0.4, "Head")
	add(
		ctx,
		"Dorsal",
		Vector3.new(0.15, 0.8, 1.2),
		Vector3.new(0, 3.0, 0.2),
		p.accent,
		{ joint = "Body", shape = "Wedge" }
	)
	pair(
		ctx,
		"Fin",
		Vector3.new(0.8, 0.12, 0.5),
		Vector3.new(0.85, 1.6, -0.4),
		p.accent,
		{ joint = "Wing", rot = { 0, 0, 25 } },
		true
	)
	ctx.a = {
		torso = { c = Vector3.new(0, 1.9, 0), s = Vector3.new(1.4, 1.6, 2.6) },
		head = { c = Vector3.new(0, 1.9, -1.6), s = Vector3.new(1.3, 1.4, 0.8) },
		faceZ = -2.0,
		earX = 0.5,
		tailBase = Vector3.new(0, 1.9, 1.3),
		headJoint = "Head",
	}
	if not ctx.def.tail then
		ctx.def.tail = "fin"
	end
end

local ARCHETYPES: { [string]: (Ctx) -> () } = {
	Quadruped = quadruped,
	Biped = biped,
	Flyer = flyer,
	Floater = floater,
	Fish = fish,
}

------------------------------------------------------------------ features

local function headTop(a: Anchors): number
	return a.head.c.Y + a.head.s.Y / 2
end

local function ears(ctx: Ctx, kind: string)
	local a, p, j = ctx.a, ctx.pal, ctx.a.headJoint
	local top, z = headTop(a), a.head.c.Z + 0.05
	if kind == "pointy" then
		pair(
			ctx,
			"Ear",
			Vector3.new(0.25, 0.8, 0.6),
			Vector3.new(a.earX, top + 0.25, z),
			p.accent,
			{ joint = j, shape = "Wedge", rot = { 0, 0, 20 } }
		)
	elseif kind == "round" then
		pair(
			ctx,
			"Ear",
			Vector3.new(0.65, 0.65, 0.3),
			Vector3.new(a.earX, top + 0.15, z),
			p.main,
			{ joint = j, shape = "Ball" }
		)
		pair(
			ctx,
			"EarIn",
			Vector3.new(0.4, 0.4, 0.1),
			Vector3.new(a.earX, top + 0.15, z - 0.17),
			p.belly,
			{ joint = j }
		)
	elseif kind == "long" then
		pair(
			ctx,
			"Ear",
			Vector3.new(0.3, 1.4, 0.5),
			Vector3.new(a.earX * 0.6, top + 0.6, z),
			p.main,
			{ joint = j, rot = { 0, 0, 8 } }
		)
		pair(
			ctx,
			"EarIn",
			Vector3.new(0.16, 1.0, 0.1),
			Vector3.new(a.earX * 0.6 + 0.05, top + 0.6, z - 0.27),
			p.belly,
			{ joint = j, rot = { 0, 0, 8 } }
		)
	elseif kind == "fin" then
		pair(
			ctx,
			"Ear",
			Vector3.new(0.15, 0.7, 0.8),
			Vector3.new(a.earX + 0.15, top - 0.1, z + 0.2),
			p.accent,
			{ joint = j, shape = "Wedge", rot = { 0, 0, 40 } }
		)
	end
end

local function horns(ctx: Ctx, kind: string)
	local a, j, c = ctx.a, ctx.a.headJoint, ctx.metal
	local top, z = headTop(a), a.head.c.Z - 0.1
	if kind == "straight" then
		pair(
			ctx,
			"Horn",
			Vector3.new(0.28, 0.9, 0.28),
			Vector3.new(a.earX * 0.6, top + 0.4, z),
			c,
			{ joint = j, rot = { 0, 0, 14 } }
		)
		pair(
			ctx,
			"HornTip",
			Vector3.new(0.18, 0.4, 0.18),
			Vector3.new(a.earX * 0.6 + 0.16, top + 0.95, z),
			ctx.pal.belly,
			{ joint = j, rot = { 0, 0, 14 } }
		)
	elseif kind == "curl" then
		pair(
			ctx,
			"Horn",
			Vector3.new(0.3, 0.6, 0.3),
			Vector3.new(a.earX * 0.65, top + 0.25, z),
			c,
			{ joint = j, rot = { 0, 0, 25 } }
		)
		pair(
			ctx,
			"HornCurl",
			Vector3.new(0.26, 0.55, 0.26),
			Vector3.new(a.earX * 0.65 + 0.32, top + 0.6, z + 0.15),
			c,
			{ joint = j, rot = { -30, 0, 60 } }
		)
		pair(
			ctx,
			"HornTip",
			Vector3.new(0.2, 0.35, 0.2),
			Vector3.new(a.earX * 0.65 + 0.62, top + 0.62, z + 0.42),
			ctx.pal.belly,
			{ joint = j, rot = { -60, 0, 100 } }
		)
	elseif kind == "unicorn" then
		local glow = Rarities[ctx.def.rarity].order >= 4
		for i, s in { 0.35, 0.26, 0.17 } do
			add(
				ctx,
				"Horn" .. i,
				Vector3.new(s, 0.45, s),
				Vector3.new(0, top + 0.2 + (i - 1) * 0.38, a.head.c.Z - 0.3 - (i - 1) * 0.1),
				if glow then ctx.glow else c,
				{
					joint = j,
					rot = { -15, 0, 0 },
					material = if glow then "Neon" else nil,
				}
			)
		end
	elseif kind == "antler" then
		pair(
			ctx,
			"Antler",
			Vector3.new(0.22, 1.0, 0.22),
			Vector3.new(a.earX * 0.6, top + 0.45, z),
			c,
			{ joint = j, rot = { 0, 0, 22 } }
		)
		pair(
			ctx,
			"AntlerBranch",
			Vector3.new(0.18, 0.7, 0.18),
			Vector3.new(a.earX * 0.6 + 0.45, top + 0.75, z),
			c,
			{ joint = j, rot = { 0, 0, 60 } }
		)
		pair(
			ctx,
			"AntlerTip",
			Vector3.new(0.18, 0.6, 0.18),
			Vector3.new(a.earX * 0.6 + 0.25, top + 1.05, z),
			c,
			{ joint = j, rot = { 0, 0, 5 } }
		)
	end
end

local function tail(ctx: Ctx, kind: string)
	local b, p = ctx.a.tailBase, ctx.pal
	local function at(dy: number, dz: number): Vector3
		return b + Vector3.new(0, dy, dz)
	end
	if kind == "stub" then
		add(ctx, "Tail", Vector3.new(0.6, 0.6, 0.6), at(0, 0.2), p.belly, { joint = "Tail", shape = "Ball" })
	elseif kind == "long" then
		add(ctx, "Tail", Vector3.new(0.35, 0.35, 1.3), at(0.3, 0.55), p.main, { joint = "Tail", rot = { -35, 0, 0 } })
		add(ctx, "TailTip", Vector3.new(0.45, 0.45, 0.45), at(0.75, 1.1), p.accent, { joint = "Tail" })
	elseif kind == "fluffy" then
		add(ctx, "Tail", Vector3.new(0.8, 0.8, 1.3), at(0.4, 0.6), p.main, { joint = "Tail", rot = { -30, 0, 0 } })
		add(
			ctx,
			"TailTip",
			Vector3.new(0.85, 0.6, 0.5),
			at(0.85, 1.15),
			p.belly,
			{ joint = "Tail", rot = { -30, 0, 0 } }
		)
	elseif kind == "spike" then
		add(ctx, "Tail", Vector3.new(0.6, 0.5, 0.9), at(-0.1, 0.45), p.main, { joint = "Tail" })
		add(ctx, "Tail2", Vector3.new(0.45, 0.4, 0.8), at(-0.2, 1.2), p.main, { joint = "Tail" })
		add(
			ctx,
			"TailBlade",
			Vector3.new(0.3, 0.6, 0.7),
			at(-0.15, 1.8),
			p.accent,
			{ joint = "Tail", shape = "Wedge", rot = { 0, 180, 0 } }
		)
	elseif kind == "fan" then
		add(ctx, "Tail", Vector3.new(0.5, 0.12, 1.2), at(0.2, 0.6), p.accent, { joint = "Tail", rot = { -20, 0, 0 } })
		pair(
			ctx,
			"TailSide",
			Vector3.new(0.45, 0.12, 1.1),
			Vector3.new(0.35, b.Y + 0.15, b.Z + 0.55),
			p.main,
			{ joint = "Tail", rot = { -15, 15, 0 } }
		)
	elseif kind == "flame" then
		add(
			ctx,
			"Tail",
			Vector3.new(0.6, 0.6, 0.9),
			at(0.3, 0.5),
			Color3.fromRGB(255, 120, 30),
			{ joint = "Tail", rot = { -40, 0, 0 }, material = "Neon" }
		)
		add(
			ctx,
			"TailFlame",
			Vector3.new(0.4, 0.4, 0.6),
			at(0.75, 0.95),
			Color3.fromRGB(255, 220, 80),
			{ joint = "Tail", rot = { -40, 0, 0 }, material = "Neon" }
		)
	elseif kind == "fin" then
		add(ctx, "Tail", Vector3.new(0.3, 0.6, 0.5), at(0, 0.15), p.main, { joint = "Tail" })
		add(ctx, "TailFin", Vector3.new(0.15, 1.6, 1.0), at(0, 0.75), p.accent, { joint = "Tail" })
	end
end

local function wings(ctx: Ctx, kind: string)
	local t, p = ctx.a.torso, ctx.pal
	local x, y, z = t.s.X / 2, t.c.Y + t.s.Y / 2 - 0.1, t.c.Z + 0.2
	local w = { joint = "Wing" }
	pair(ctx, "WingRoot", Vector3.new(0.35, 0.35, 0.35), Vector3.new(x, y, z), p.accent, w, true)
	if kind == "feather" then
		pair(
			ctx,
			"Wing",
			Vector3.new(1.6, 0.14, 1.0),
			Vector3.new(x + 0.85, y + 0.3, z),
			p.main,
			{ joint = "Wing", rot = { 0, 0, -20 } },
			true
		)
		pair(
			ctx,
			"WingTip",
			Vector3.new(1.2, 0.12, 0.8),
			Vector3.new(x + 0.75, y + 0.15, z + 0.75),
			p.accent,
			{ joint = "Wing", rot = { 0, 0, -15 } },
			true
		)
		pair(
			ctx,
			"Feather",
			Vector3.new(0.9, 0.1, 0.4),
			Vector3.new(x + 1.5, y + 0.55, z - 0.35),
			p.belly,
			{ joint = "Wing", rot = { 0, 0, -25 } },
			true
		)
	elseif kind == "bat" then
		pair(
			ctx,
			"WingBone",
			Vector3.new(1.9, 0.22, 0.22),
			Vector3.new(x + 0.95, y + 0.45, z),
			ctx.metal,
			{ joint = "Wing", rot = { 0, 0, -25 } },
			true
		)
		pair(
			ctx,
			"Wing",
			Vector3.new(1.7, 0.08, 1.3),
			Vector3.new(x + 0.85, y + 0.3, z + 0.65),
			p.accent,
			{ joint = "Wing", rot = { 0, 0, -20 } },
			true
		)
		pair(
			ctx,
			"WingClaw",
			Vector3.new(0.2, 0.4, 0.2),
			Vector3.new(x + 1.85, y + 0.95, z),
			p.belly,
			{ joint = "Wing" },
			true
		)
	elseif kind == "crystal" then
		for i = 1, 3 do
			pair(
				ctx,
				"Shard" .. i,
				Vector3.new(0.35, 1.6 - i * 0.25, 0.5),
				Vector3.new(x + 0.35 + i * 0.4, y + 0.7 - i * 0.1, z + (i - 2) * 0.35),
				p.accent,
				{
					joint = "Wing",
					rot = { 0, 0, -35 - i * 10 },
					material = "Glass",
					transparency = 0.2,
				},
				true
			)
		end
		pair(
			ctx,
			"ShardCore",
			Vector3.new(0.12, 1.0, 0.12),
			Vector3.new(x + 0.75, y + 0.6, z),
			ctx.glow,
			{ joint = "Wing", rot = { 0, 0, -45 }, material = "Neon" },
			true
		)
	elseif kind == "fairy" then
		pair(
			ctx,
			"Wing",
			Vector3.new(1.4, 0.06, 1.0),
			Vector3.new(x + 0.7, y + 0.6, z - 0.1),
			Color3.fromRGB(235, 245, 255),
			{
				joint = "Wing",
				rot = { 0, 20, -35 },
				material = "Glass",
				transparency = 0.35,
			},
			true
		)
		pair(
			ctx,
			"WingLow",
			Vector3.new(1.0, 0.06, 0.7),
			Vector3.new(x + 0.55, y + 0.1, z + 0.6),
			Color3.fromRGB(235, 245, 255),
			{
				joint = "Wing",
				rot = { 0, -25, -10 },
				material = "Glass",
				transparency = 0.35,
			},
			true
		)
	end
end

local function mane(ctx: Ctx)
	local h, j = ctx.a.head, ctx.a.headJoint
	local back = h.c.Z + h.s.Z / 2
	for i, x in { -0.75, -0.25, 0.25, 0.75 } do
		add(
			ctx,
			"Mane" .. i,
			Vector3.new(0.5, 0.65, 0.45),
			Vector3.new(x * h.s.X / 1.8, h.c.Y + 0.35 - math.abs(x) * 0.3, back),
			ctx.pal.accent,
			{ joint = j, rot = { 20, 0, x * 20 } }
		)
	end
	add(
		ctx,
		"ManeTop",
		Vector3.new(0.7, 0.4, 0.8),
		Vector3.new(0, headTop(ctx.a) + 0.1, h.c.Z + 0.2),
		ctx.pal.accent,
		{ joint = j }
	)
	pair(
		ctx,
		"ManeSide",
		Vector3.new(0.3, 0.7, 0.6),
		Vector3.new(h.s.X / 2 + 0.05, h.c.Y - 0.1, h.c.Z + 0.35),
		ctx.pal.accent,
		{ joint = j }
	)
end

local function spikes(ctx: Ctx)
	local t = ctx.a.torso
	local top = t.c.Y + t.s.Y / 2
	for i = 1, 4 do
		local z = t.c.Z - t.s.Z / 2 + (i - 0.5) * t.s.Z / 4
		add(
			ctx,
			"Spike" .. i,
			Vector3.new(0.35, 0.55 - i * 0.05, 0.6),
			Vector3.new(0, top + 0.22, z),
			ctx.pal.accent,
			{ joint = "Body", shape = "Wedge" }
		)
	end
end

local function armor(ctx: Ctx)
	local t, h, m = ctx.a.torso, ctx.a.head, ctx.metal
	local top = t.c.Y + t.s.Y / 2
	add(
		ctx,
		"BackPlate",
		Vector3.new(t.s.X * 0.8, 0.22, t.s.Z * 0.55),
		Vector3.new(0, top + 0.08, t.c.Z + 0.1),
		m,
		{ joint = "Body" }
	)
	pair(
		ctx,
		"Pauldron",
		Vector3.new(0.7, 0.25, 0.9),
		Vector3.new(t.s.X / 2 - 0.05, top - 0.05, t.c.Z - t.s.Z / 4),
		m,
		{ joint = "Body", rot = { 0, 0, 22 } }
	)
	add(
		ctx,
		"Helmet",
		Vector3.new(h.s.X * 0.85, 0.22, h.s.Z * 0.8),
		Vector3.new(0, headTop(ctx.a) + 0.08, h.c.Z + 0.05),
		m,
		{ joint = ctx.a.headJoint }
	)
	add(
		ctx,
		"ChestPlate",
		Vector3.new(t.s.X * 0.6, t.s.Y * 0.5, 0.15),
		Vector3.new(0, t.c.Y, t.c.Z - t.s.Z / 2 - 0.05),
		m,
		{ joint = "Body" }
	)
	add(
		ctx,
		"Gem",
		Vector3.new(0.3, 0.3, 0.1),
		Vector3.new(0, t.c.Y, t.c.Z - t.s.Z / 2 - 0.15),
		ctx.glow,
		{ joint = "Body", material = "Neon" }
	)
end

local function crystals(ctx: Ctx)
	local t = ctx.a.torso
	local top = t.c.Y + t.s.Y / 2
	for i, o in { { -0.4, 0.2, -10 }, { 0.3, -0.3, 12 }, { 0.05, 0.7, -4 } } do
		local pos = Vector3.new(o[1], top + 0.45, t.c.Z + o[2])
		add(
			ctx,
			"Crystal" .. i,
			Vector3.new(0.45, 1.1 - i * 0.15, 0.45),
			pos,
			ctx.pal.accent,
			{ joint = "Body", rot = { o[3], 20 * i, o[3] }, material = "Glass", transparency = 0.15 }
		)
		add(
			ctx,
			"CrystalCore" .. i,
			Vector3.new(0.16, 0.8 - i * 0.12, 0.16),
			pos,
			ctx.glow,
			{ joint = "Body", rot = { o[3], 20 * i, o[3] }, material = "Neon" }
		)
	end
end

local function flames(ctx: Ctx)
	local t = ctx.a.torso
	local top = t.c.Y + t.s.Y / 2
	local orange, yellow = Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 220, 80)
	for i, z in { -0.5, 0.3 } do
		add(
			ctx,
			"Flame" .. i,
			Vector3.new(0.7, 0.7, 0.7),
			Vector3.new(0, top + 0.3, t.c.Z + z),
			orange,
			{ joint = "Body", material = "Neon", rot = { 0, 45, 0 } }
		)
		add(
			ctx,
			"FlameTip" .. i,
			Vector3.new(0.4, 0.5, 0.4),
			Vector3.new(0, top + 0.8, t.c.Z + z),
			yellow,
			{ joint = "Body", material = "Neon", rot = { 0, 45, 0 } }
		)
	end
	add(
		ctx,
		"HeadFlame",
		Vector3.new(0.5, 0.6, 0.5),
		Vector3.new(0, headTop(ctx.a) + 0.3, ctx.a.head.c.Z),
		orange,
		{ joint = ctx.a.headJoint, material = "Neon", rot = { 0, 45, 0 } }
	)
end

local function spots(ctx: Ctx)
	local t = ctx.a.torso
	local top = t.c.Y + t.s.Y / 2
	for i, o in { { -0.45, -0.5 }, { 0.5, 0.1 }, { -0.3, 0.75 }, { 0.35, -0.9 } } do
		add(
			ctx,
			"Spot" .. i,
			Vector3.new(0.5, 0.06, 0.5),
			Vector3.new(o[1], top + 0.02, t.c.Z + o[2]),
			ctx.pal.accent,
			{ joint = "Body" }
		)
	end
	pair(
		ctx,
		"SideSpot",
		Vector3.new(0.06, 0.45, 0.6),
		Vector3.new(t.s.X / 2 + 0.02, t.c.Y + 0.1, t.c.Z + 0.3),
		ctx.pal.accent,
		{ joint = "Body" }
	)
end

local function stripes(ctx: Ctx)
	local t = ctx.a.torso
	for i, f in { -0.3, 0.05, 0.4 } do
		add(
			ctx,
			"Stripe" .. i,
			Vector3.new(t.s.X + 0.04, t.s.Y + 0.04, 0.28),
			Vector3.new(0, t.c.Y, t.c.Z + f * t.s.Z),
			ctx.pal.accent,
			{ joint = "Body" }
		)
	end
end

local function shell(ctx: Ctx)
	local t = ctx.a.torso
	local top = t.c.Y + t.s.Y / 2
	add(
		ctx,
		"Shell",
		Vector3.new(t.s.X + 0.4, 0.6, t.s.Z + 0.2),
		Vector3.new(0, top + 0.2, t.c.Z),
		ctx.pal.accent,
		{ joint = "Body" }
	)
	add(
		ctx,
		"ShellTop",
		Vector3.new(t.s.X * 0.75, 0.4, t.s.Z * 0.7),
		Vector3.new(0, top + 0.65, t.c.Z),
		ctx.pal.accent,
		{ joint = "Body" }
	)
	for i, o in { { -0.45, -0.45 }, { 0.45, -0.45 }, { -0.45, 0.45 }, { 0.45, 0.45 } } do
		add(
			ctx,
			"ShellPlate" .. i,
			Vector3.new(0.6, 0.12, 0.6),
			Vector3.new(o[1], top + 0.88, t.c.Z + o[2]),
			ctx.metal,
			{ joint = "Body", rot = { 0, 45, 0 } }
		)
	end
end

------------------------------------------------------------------ rarity dressing

local function crown(ctx: Ctx)
	local h, j = ctx.a.head, ctx.a.headJoint
	local y = headTop(ctx.a) + 0.15
	add(ctx, "CrownBand", Vector3.new(0.95, 0.22, 0.95), Vector3.new(0, y, h.c.Z), GOLD, { joint = j })
	for i, o in { { -0.38, -0.38 }, { 0.38, -0.38 }, { -0.38, 0.38 }, { 0.38, 0.38 } } do
		add(
			ctx,
			"CrownPoint" .. i,
			Vector3.new(0.18, 0.35, 0.18),
			Vector3.new(o[1], y + 0.25, h.c.Z + o[2]),
			GOLD,
			{ joint = j }
		)
	end
	add(
		ctx,
		"CrownGem",
		Vector3.new(0.25, 0.25, 0.1),
		Vector3.new(0, y, h.c.Z - 0.5),
		ctx.glow,
		{ joint = j, material = "Neon" }
	)
end

-- Ring of Neon cubes around a hub; the hub (first part) is the joint's pivot so Anim can spin it.
local function ring(
	ctx: Ctx,
	joint: string,
	center: Vector3,
	radius: number,
	count: number,
	size: number,
	color: Color3
)
	add(
		ctx,
		joint .. "Hub",
		Vector3.new(0.2, 0.2, 0.2),
		center,
		color,
		{ joint = joint, transparency = 1, studs = false }
	)
	for i = 1, count do
		local a = (i - 1) / count * 2 * math.pi
		add(
			ctx,
			joint .. "Cube" .. i,
			Vector3.new(size, size, size),
			center + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius),
			color,
			{
				joint = joint,
				material = "Neon",
				rot = { 45, i * 30, 45 },
			}
		)
	end
end

local function dress(ctx: Ctx)
	local def, a = ctx.def, ctx.a
	local order = Rarities[def.rarity].order
	local rc = Rarities[def.rarity].color
	local t = a.torso
	-- Eyes: coloured Neon from the palette (dark by default).
	for _, p in ctx.parts do
		if p.name == "EyeL" or p.name == "EyeR" then
			p.color = if ctx.pal.eye and order >= 3 then ctx.pal.eye else INK
		end
	end
	if order >= 4 then
		pair(
			ctx,
			"Rune",
			Vector3.new(0.06, 0.25, t.s.Z * 0.55),
			Vector3.new(t.s.X / 2 + 0.03, t.c.Y + 0.1, t.c.Z),
			ctx.glow,
			{ joint = "Body", material = "Neon" }
		)
		pair(
			ctx,
			"RuneDot",
			Vector3.new(0.06, 0.25, 0.25),
			Vector3.new(t.s.X / 2 + 0.03, t.c.Y - 0.25, t.c.Z - t.s.Z * 0.2),
			ctx.glow,
			{ joint = "Body", material = "Neon" }
		)
		local core = ctx.parts[1]
		for _, p in ctx.parts do
			if p.name == "Torso" or p.name == "Middle" then
				core = p
			end
		end
		core.light = rc -- soft rarity light inside the body
	end
	if order >= 5 then
		crown(ctx)
		ring(ctx, "Orbit", Vector3.new(0, t.c.Y + 0.2, t.c.Z), math.max(t.s.X, t.s.Z) * 0.85 + 0.4, 4, 0.4, rc)
	end
	if order >= 6 then
		ring(ctx, "Halo", Vector3.new(0, headTop(a) + 1.0, a.head.c.Z), 0.75, 8, 0.25, GOLD)
		ring(ctx, "Orbit2", Vector3.new(0, t.c.Y + 1.0, t.c.Z), math.max(t.s.X, t.s.Z) * 0.7 + 0.6, 6, 0.3, ctx.glow)
	end
	if order >= 7 and not def.wings then
		wings(ctx, "fairy")
	end
end

-- Small cute details, added in priority order while the rarity's max part budget has room:
-- blush cheeks, brows, toes/claws on every foot, a back stripe.
local function details(ctx: Ctx)
	local budget = BUDGET[ctx.def.rarity] or BUDGET.Common
	local room = budget[2] - #ctx.parts
	local function fits(n: number): boolean
		if room >= n then
			room -= n
			return true
		end
		return false
	end
	local e = ctx.eye
	if e and fits(2) then
		pair(
			ctx,
			"Cheek",
			Vector3.new(e.w * 1.1, e.h * 0.4, 0.06),
			Vector3.new(e.x + e.w * 0.6, e.y - e.h * 0.85, e.z - 0.04),
			Color3.fromRGB(255, 150, 175),
			{ joint = e.joint }
		)
	end
	if e and fits(2) then
		local brow = ctx.pal.main:Lerp(Color3.new(0, 0, 0), 0.45)
		pair(
			ctx,
			"Brow",
			Vector3.new(e.w * 1.2, 0.08, 0.06),
			Vector3.new(e.x, e.y + e.h * 0.75, e.z - 0.04),
			brow,
			{ joint = e.joint, rot = { 0, 0, -12 } }
		)
	end
	local claw = ctx.pal.belly:Lerp(Color3.new(0, 0, 0), 0.55)
	local feet = {}
	for _, p in ctx.parts do
		if string.match(p.name or "", "^Paw") or string.match(p.name or "", "^Foot") then
			table.insert(feet, p)
		end
	end
	for _, f in feet do
		if not fits(2) then
			break
		end
		for _, dx in { -0.18, 0.18 } do
			add(
				ctx,
				"Toe",
				Vector3.new(0.14, 0.12, 0.1),
				Vector3.new(f.pos[1] + dx, f.pos[2] - f.size[2] / 2 + 0.1, f.pos[3] - f.size[3] / 2 - 0.03),
				claw,
				{ joint = f.joint }
			)
		end
	end
	local t = ctx.a.torso
	if fits(1) then
		add(
			ctx,
			"BackStripe",
			Vector3.new(0.35, 0.06, t.s.Z * 0.8),
			Vector3.new(0, t.c.Y + t.s.Y / 2 + 0.03, t.c.Z),
			ctx.pal.accent,
			{ joint = "Body" }
		)
	end
end

-- Diamond scales on unique slots (torso sides/back/underside/faces, head sides) until the rarity's
-- minimum part count is reached.
local function pad(ctx: Ctx)
	local budget = BUDGET[ctx.def.rarity] or BUDGET.Common
	local need = budget[1] - #ctx.parts
	if need <= 0 then
		return
	end
	local t = ctx.a.torso
	local bottom, top = t.c.Y - t.s.Y / 2, t.c.Y + t.s.Y / 2
	local plateH = math.min(0.28, t.s.Y / 4 * 0.8)
	local slots: { { any } } = {}
	for k = 0, 3 do -- sides: 2 x 4 heights x 4 columns
		for col = 0, 3 do
			for _, side in { -1, 1 } do
				local y = bottom + (k + 0.5) * t.s.Y / 4
				local z = t.c.Z - t.s.Z / 2 + (col + 0.5) * t.s.Z / 4
				local d = math.min(plateH * 1.3, t.s.Z / 4 * 0.6)
				table.insert(
					slots,
					{ Vector3.new(0.06, d, d), Vector3.new(side * (t.s.X / 2 + 0.03), y, z), { 45, 0, 0 } }
				)
			end
		end
	end
	for row = 0, 3 do -- back and underside: 4 x 4 diamonds each
		for col = 0, 3 do
			local x = t.c.X - t.s.X / 2 + (col + 0.5) * t.s.X / 4
			local z = t.c.Z - t.s.Z / 2 + (row + 0.5) * t.s.Z / 4
			local w = math.min(t.s.X, t.s.Z) / 4 * 0.6
			table.insert(slots, { Vector3.new(w, 0.06, w), Vector3.new(x, top + 0.03, z), { 0, 45, 0 } })
			table.insert(slots, { Vector3.new(w, 0.06, w), Vector3.new(x, bottom - 0.03, z), { 0, 45, 0 } })
		end
	end
	local h = ctx.a.head
	local hj = ctx.a.headJoint
	for k = 0, 1 do -- head sides: 2 x 2 heights x 2 columns
		for col = 0, 1 do
			for _, side in { -1, 1 } do
				local y = h.c.Y - h.s.Y / 4 + k * h.s.Y / 2
				local z = h.c.Z - h.s.Z / 4 + col * h.s.Z / 2
				table.insert(slots, {
					Vector3.new(0.06, h.s.Y / 2 * 0.45, h.s.Y / 2 * 0.45),
					Vector3.new(side * (h.s.X / 2 + 0.03), y, z),
					{ 45, 0, 0 },
					hj,
				})
			end
		end
	end
	for _, face in { -1, 1 } do -- torso front/back faces: 3 x 3
		for r = 0, 2 do
			for c = 0, 2 do
				local x = t.c.X - t.s.X / 2 + (c + 0.5) * t.s.X / 3
				local y = bottom + (r + 0.5) * t.s.Y / 3
				table.insert(slots, {
					Vector3.new(math.min(t.s.X, t.s.Y) / 3 * 0.5, math.min(t.s.X, t.s.Y) / 3 * 0.5, 0.06),
					Vector3.new(x, y, t.c.Z + face * (t.s.Z / 2 + 0.03)),
					{ 0, 0, 45 },
				})
			end
		end
	end
	-- Scales: a shade darker than the body (metal for armoured pets) so they read as texture.
	local color = if ctx.def.armor then ctx.metal else ctx.pal.main:Lerp(Color3.new(0, 0, 0), 0.15)
	for i = 1, math.min(need, #slots) do
		local slot = slots[i]
		add(ctx, "Scale" .. i, slot[1], slot[2], color, { joint = slot[4] or "Body", rot = slot[3] })
	end
end

-- Secret pets: clean rainbow bands from feet (red) to head (violet).
local function rainbow(ctx: Ctx)
	local lo, hi = math.huge, -math.huge
	for _, p in ctx.parts do
		lo, hi = math.min(lo, p.pos[2]), math.max(hi, p.pos[2])
	end
	for _, p in ctx.parts do
		if p.material ~= "Neon" and p.transparency ~= 1 and p.name ~= "EyeL" and p.name ~= "EyeR" then
			local k = (p.pos[2] - lo) / math.max(hi - lo, 0.01)
			p.color = Color3.fromHSV(k * 0.8, 0.5, 1)
		end
	end
end

------------------------------------------------------------------ build

function Creatures.build(def: Def): Builder.Spec
	local rarity = Rarities[def.rarity] or Rarities.Common
	local pal = def.palette
	local ctx: Ctx = {
		parts = {},
		def = table.clone(def),
		pal = pal,
		a = nil :: any,
		metal = pal.metal or pal.accent:Lerp(Color3.new(0, 0, 0), 0.3),
		glow = pal.glow or rarity.color,
	}
	local arch = ARCHETYPES[def.kind] or quadruped
	arch(ctx)
	local d = ctx.def
	if d.ears then
		ears(ctx, d.ears)
	end
	if d.horns then
		horns(ctx, d.horns)
	end
	if d.tail then
		tail(ctx, d.tail)
	end
	if d.wings then
		wings(ctx, d.wings)
	end
	if d.mane then
		mane(ctx)
	end
	if d.spikes then
		spikes(ctx)
	end
	if d.armor then
		armor(ctx)
	end
	if d.crystals then
		crystals(ctx)
	end
	if d.flames then
		flames(ctx)
	end
	if d.spots then
		spots(ctx)
	end
	if d.stripes then
		stripes(ctx)
	end
	if d.shell then
		shell(ctx)
	end
	dress(ctx)
	details(ctx)
	pad(ctx)
	if d.ghost then
		for _, p in ctx.parts do
			if p.material == nil and p.transparency == nil then
				p.material = "Glass"
				p.transparency = 0.3
			end
		end
	end
	if def.rarity == "Secret" then
		rainbow(ctx)
	end

	-- Scale so the tallest point (excluding halo/orbit rings) reaches the rarity's target height.
	local top = 0
	for _, p in ctx.parts do
		local j = p.joint or ""
		if j ~= "Halo" and j ~= "Orbit" and j ~= "Orbit2" then
			top = math.max(top, p.pos[2] + p.size[2] / 2)
		end
	end
	local target = 3 + (rarity.order - 1) * (6 / 7)
	return { size = target / math.max(top, 1), parts = ctx.parts }
end

-- Part budget for a rarity: { min, max } (for tests / the showcase).
function Creatures.budget(rarity: string): { number }
	return BUDGET[rarity] or BUDGET.Common
end

return Creatures
