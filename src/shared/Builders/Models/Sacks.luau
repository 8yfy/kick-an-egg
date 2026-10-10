--!strict
-- Kick Sacks (BlockBuilder data, Partner B): the 20 training sacks of Config/Upgrades.Sack.tiers.
-- Designs: Claude Design canvas "Kick the Egg — Kicking Sacks" with the rating fixes applied.
--
-- Conventions:
--   * Origin = the hang point (top of the hook). The sack hangs below it; its front faces -Z (the
--     kicker). Sacks.HANG = how high the hang point sits above the ground so the bag's middle is at
--     kicking height. The client extends the short chain on top up into the sky.
--   * Body = a vertical cylinder of radius RADIUS from y = TOP to y = BOTTOM (Ice Block is a cube).
--   * Part names the client animates: "Orbit" parts circle the body fast, "Halo" parts turn slowly
--     around it, the Robo Bag's "EyeL"/"EyeR"/"Mouth" wince on every hit. Everything below y = -1
--     squashes on hits; the chain and hook above don't.
local Builder = require(script.Parent.Parent.BlockBuilder)

type PartSpec = Builder.PartSpec
type Spec = Builder.Spec
type Opts = { material: string?, shape: string?, studs: boolean?, transparency: number?, light: Color3? }

export type Look = {
	chain: Color3, -- chain / rope colour (the client draws the rest of it up to the sky)
	rope: boolean, -- a rope instead of chain links
	fx: { Color3 }, -- VFX palette for bursts and auras, main colour first
	theme: string, -- VFX/Sack extra per hit: dust, chalk, sweat, stars, rubber, sparks, glint, sparkle,
	-- coins, frost, crystal, sprinkles, embers, lightning, goo, robo, fire, cosmic, holy, rainbow
}

local rgb = Color3.fromRGB
local RADIUS, TOP, BOTTOM = 1.6, -1.6, -6
local MID = (TOP + BOTTOM) / 2

local Sacks = {}
Sacks.HANG = 7.2
Sacks.RADIUS = RADIUS
Sacks.CENTER = MID

-- Builders (append to `cur`) ------------------------------------------------

local cur: { PartSpec } = {}

local function put(name: string, size: { number }, cf: CFrame, color: Color3, o: Opts?)
	local opts: Opts = o or {}
	local rx, ry, rz = cf:ToEulerAnglesXYZ()
	table.insert(cur, {
		name = name,
		size = size,
		pos = { cf.X, cf.Y, cf.Z },
		rot = { math.deg(rx), math.deg(ry), math.deg(rz) },
		color = color,
		material = opts.material,
		shape = opts.shape,
		studs = opts.studs,
		transparency = opts.transparency,
		light = opts.light,
	})
end

local function with(o: Opts?, shape: string): Opts
	local opts: Opts = table.clone(o or {})
	opts.shape = shape
	return opts
end

local function block(
	name: string,
	size: { number },
	x: number,
	y: number,
	z: number,
	color: Color3,
	o: Opts?,
	rz: number?
)
	put(name, size, CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(rz or 0)), color, o)
end

local function ball(name: string, d: number, x: number, y: number, z: number, color: Color3, o: Opts?)
	put(name, { d, d, d }, CFrame.new(x, y, z), color, with(o, "Ball"))
end

-- A vertical cylinder on the body axis (bands, caps, the body itself).
local function ring(name: string, radius: number, h: number, y: number, color: Color3, o: Opts?)
	put(
		name,
		{ h, radius * 2, radius * 2 },
		CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		with(o, "Cylinder")
	)
end

-- Frame on the body surface: `angle` degrees around from the front (+ = toward +X), local -Z outward.
local function surface(angle: number, y: number, r: number): CFrame
	return CFrame.new(0, y, 0) * CFrame.Angles(0, math.rad(-angle), 0) * CFrame.new(0, 0, -r)
end

-- A plate on the body surface; `tilt` turns it in its own plane; `radius` overrides the surface radius.
local function wrap(
	name: string,
	angle: number,
	y: number,
	w: number,
	h: number,
	d: number,
	color: Color3,
	o: Opts?,
	tilt: number?,
	radius: number?
)
	put(
		name,
		{ w, h, d },
		surface(angle, y, (radius or RADIUS) + d / 2 - 0.04) * CFrame.Angles(0, 0, math.rad(tilt or 0)),
		color,
		o
	)
end

-- Same, placed by its x offset on the front instead of an angle.
local function front(
	name: string,
	x: number,
	y: number,
	w: number,
	h: number,
	d: number,
	color: Color3,
	o: Opts?,
	tilt: number?
)
	wrap(name, math.deg(math.asin(math.clamp(x / RADIUS, -1, 1))), y, w, h, d, color, o, tilt)
end

-- A coin facing out of the body surface.
local function disc(
	name: string,
	angle: number,
	y: number,
	radius: number,
	d: number,
	color: Color3,
	o: Opts?,
	out: number?
)
	put(
		name,
		{ d, radius * 2, radius * 2 },
		surface(angle, y, RADIUS + d / 2 - 0.04 + (out or 0)) * CFrame.Angles(0, math.rad(90), 0),
		color,
		with(o, "Cylinder")
	)
end

-- A bar from a to b (straps, crystals, horns, icicles, straw).
local function beam(name: string, a: Vector3, b: Vector3, w: number, d: number, color: Color3, o: Opts?)
	local dir = b - a
	if math.abs(dir.Unit.Y) > 0.999 then
		b += Vector3.new(0.001, 0, 0)
	end
	put(name, { w, d, (b - a).Magnitude }, CFrame.lookAt((a + b) / 2, b), color, o)
end

-- Point on the body surface (for beams).
local function on(angle: number, y: number, r: number?): Vector3
	return surface(angle, y, r or RADIUS).Position
end

-- Hook, swivel, a short chain (or rope) above the origin and four straps down to the top cap.
local function hanger(look: Look, strap: Color3, metal: Color3?)
	local steel = metal or rgb(150, 155, 165)
	if look.rope then
		ring("Rope", 0.13, 1.9, 0.75, look.chain, { material = "Fabric" })
	else
		for i = 0, 3 do
			local cf = CFrame.new(0, 0.25 + i * 0.45, 0) * CFrame.Angles(0, if i % 2 == 0 then 0 else math.rad(90), 0)
			put("Link", { 0.12, 0.55, 0.36 }, cf, look.chain, { material = "Metal" })
		end
	end
	block("Hook", { 0.4, 0.45, 0.4 }, 0, -0.2, 0, steel, { material = "Metal", studs = false })
	ring("Swivel", 0.3, 0.2, -0.5, steel, { material = "Metal" })
	for _, a in { 45, 135, 225, 315 } do
		beam("Strap", Vector3.new(0, -0.5, 0), on(a, TOP + 0.35, 1.25), 0.22, 0.1, strap, { studs = false })
	end
end

-- Body cylinder, top cap and bottom cap.
local function body(color: Color3, o: Opts?, cap: Color3, base: Color3?, capO: Opts?)
	ring("Body", RADIUS, TOP - BOTTOM, MID, color, o)
	ring("Cap", RADIUS + 0.12, 0.5, TOP + 0.1, cap, capO)
	ring("Base", RADIUS + 0.06, 0.45, BOTTOM, base or cap, capO)
end

-- n rivets in a ring at height y.
local function rivets(n: number, y: number, color: Color3, d: number?)
	for i = 0, n - 1 do
		local p = on(i * 360 / n, y, RADIUS + 0.02)
		ball("Rivet", d or 0.24, p.X, p.Y, p.Z, color, { material = "Metal" })
	end
end

-- Thin plates around the body (scales, tread, stripes): `rows` heights x `n` columns.
local function scatter(
	name: string,
	n: number,
	rows: { number },
	w: number,
	h: number,
	d: number,
	color: Color3,
	o: Opts?,
	skip: number?,
	tilt: number?
)
	for r, y in rows do
		for i = 0, n - 1 do
			local a = i * 360 / n + (if r % 2 == 0 then 180 / n else 0)
			if not skip or math.abs(((a + 180) % 360) - 180) > skip then
				wrap(name, a, y, w, h, d, color, o, tilt)
			end
		end
	end
end

-- Tiers ---------------------------------------------------------------------

local LOOKS: { Look } = {
	{ chain = rgb(160, 122, 69), rope = true, fx = { rgb(232, 224, 210), rgb(201, 164, 106) }, theme = "dust" },
	{ chain = rgb(154, 160, 170), rope = false, fx = { rgb(255, 255, 255), rgb(200, 57, 47) }, theme = "chalk" },
	{ chain = rgb(140, 143, 153), rope = false, fx = { rgb(150, 210, 255), rgb(216, 180, 90) }, theme = "sweat" },
	{ chain = rgb(200, 204, 212), rope = false, fx = { rgb(255, 225, 77), rgb(214, 47, 58) }, theme = "stars" },
	{ chain = rgb(160, 122, 69), rope = true, fx = { rgb(240, 196, 25), rgb(42, 42, 46) }, theme = "rubber" },
	{ chain = rgb(184, 190, 200), rope = false, fx = { rgb(255, 170, 60), rgb(255, 230, 120) }, theme = "sparks" },
	{ chain = rgb(217, 160, 102), rope = false, fx = { rgb(224, 163, 94), rgb(255, 210, 150) }, theme = "glint" },
	{ chain = rgb(230, 235, 242), rope = false, fx = { rgb(220, 235, 255), rgb(58, 111, 214) }, theme = "sparkle" },
	{ chain = rgb(255, 224, 138), rope = false, fx = { rgb(255, 216, 77), rgb(255, 241, 176) }, theme = "coins" },
	{ chain = rgb(207, 233, 255), rope = false, fx = { rgb(168, 220, 255), rgb(255, 255, 255) }, theme = "frost" },
	{ chain = rgb(201, 168, 255), rope = false, fx = { rgb(210, 155, 255), rgb(143, 230, 255) }, theme = "crystal" },
	{
		chain = rgb(255, 90, 160),
		rope = false,
		fx = { rgb(255, 138, 196), rgb(125, 255, 138), rgb(255, 225, 77), rgb(72, 216, 255) },
		theme = "sprinkles",
	},
	{
		chain = rgb(90, 58, 48),
		rope = false,
		fx = { rgb(255, 122, 30), rgb(255, 176, 46), rgb(60, 30, 20) },
		theme = "embers",
	},
	{ chain = rgb(127, 216, 255), rope = false, fx = { rgb(72, 216, 255), rgb(255, 243, 107) }, theme = "lightning" },
	{ chain = rgb(154, 160, 170), rope = false, fx = { rgb(182, 255, 46), rgb(90, 160, 30) }, theme = "goo" },
	{ chain = rgb(230, 235, 242), rope = false, fx = { rgb(72, 255, 210), rgb(255, 74, 90) }, theme = "robo" },
	{
		chain = rgb(217, 160, 102),
		rope = false,
		fx = { rgb(255, 120, 30), rgb(255, 210, 80), rgb(179, 38, 30) },
		theme = "fire",
	},
	{
		chain = rgb(185, 140, 255),
		rope = false,
		fx = { rgb(185, 140, 255), rgb(208, 74, 160), rgb(72, 216, 255) },
		theme = "cosmic",
	},
	{
		chain = rgb(255, 224, 138),
		rope = false,
		fx = { rgb(255, 241, 176), rgb(255, 216, 77), rgb(255, 255, 255) },
		theme = "holy",
	},
	{
		chain = rgb(255, 216, 77),
		rope = false,
		fx = {
			rgb(255, 90, 90),
			rgb(255, 155, 61),
			rgb(255, 225, 77),
			rgb(98, 224, 107),
			rgb(72, 200, 255),
			rgb(107, 125, 255),
			rgb(180, 107, 255),
		},
		theme = "rainbow",
	},
}

local NEON: Opts = { material = "Neon" }
local METAL: Opts = { material = "Metal" }
local FABRIC: Opts = { material = "Fabric" }

local BUILD: { () -> () } = {
	-- 1 Burlap Sack: rope-tied burlap, stitched patches, straw poking out of the bottom
	function()
		local dark = rgb(122, 90, 48)
		hanger(LOOKS[1], rgb(139, 106, 62))
		body(rgb(201, 164, 106), FABRIC, rgb(139, 106, 62), nil, FABRIC)
		ring("Tie", RADIUS + 0.07, 0.22, -2.25, dark, FABRIC)
		ring("Tie", RADIUS + 0.07, 0.22, -5.45, dark, FABRIC)
		front("Patch", -0.55, -3.3, 0.95, 0.85, 0.08, rgb(168, 132, 78), FABRIC, -8)
		front("Patch", 0.65, -4.6, 0.8, 0.7, 0.08, rgb(184, 141, 85), FABRIC, 10)
		for _, s in { { -0.55, -2.95, -8 }, { -0.55, -3.65, -8 }, { 0.65, -4.3, 10 }, { 0.65, -4.9, 10 } } do
			front("Stitch", s[1], s[2], 0.7, 0.07, 0.12, dark, nil, s[3])
		end
		wrap("Patch", 150, -3.9, 0.9, 0.8, 0.08, rgb(168, 132, 78), FABRIC, 6)
		for i, x in { -0.8, -0.35, 0.1, 0.5, 0.85 } do
			local z = (i % 2) * 0.5 - 0.25
			beam(
				"Straw",
				Vector3.new(x * 0.8, -6.1, z),
				Vector3.new(x * 1.3, -6.85 + (i % 3) * 0.12, z * 1.6),
				0.1,
				0.1,
				rgb(232, 207, 106)
			)
		end
	end,
	-- 2 Gym Canvas: off-white canvas, red bands, side seams and the red egg emblem over a label
	function()
		local red, navy = rgb(200, 57, 47), rgb(45, 51, 64)
		hanger(LOOKS[2], navy)
		body(rgb(241, 235, 220), FABRIC, red)
		ring("Band", RADIUS + 0.05, 0.45, -1.95, red)
		ring("Band", RADIUS + 0.05, 0.45, -5.6, red)
		for _, a in { 90, -90 } do
			wrap("Seam", a, MID, 0.12, 3.2, 0.08, rgb(221, 213, 194))
		end
		-- egg emblem, stacked like pixels (wide in the middle, narrow on top)
		for i, w in { 0.45, 0.75, 0.95, 1.05, 1.05, 0.95, 0.7 } do
			front("Egg", 0, -2.55 - i * 0.2, w, 0.21, 0.08, red, { studs = false })
		end
		front("Crack", -0.15, -3.05, 0.5, 0.07, 0.12, rgb(241, 235, 220), nil, 25)
		front("Crack", 0.17, -3.1, 0.45, 0.07, 0.12, rgb(241, 235, 220), nil, -25)
		front("Label", 0, -4.45, 1.9, 0.5, 0.08, navy)
		for _, x in { -0.55, -0.18, 0.18, 0.55 } do
			front("Letter", x, -4.45, 0.22, 0.28, 0.12, rgb(255, 255, 255), { studs = false })
		end
	end,
	-- 3 Leather Classic: black leather, gold trim and rivets, a red boxing glove emblem
	function()
		local gold, black = rgb(216, 180, 90), rgb(32, 30, 36)
		hanger(LOOKS[3], black)
		body(black, nil, rgb(22, 22, 26), nil)
		ring("Trim", RADIUS + 0.13, 0.12, TOP - 0.12, gold, METAL)
		ring("Trim", RADIUS + 0.07, 0.12, BOTTOM + 0.3, gold, METAL)
		rivets(10, -2.15, gold)
		rivets(10, -5.45, gold)
		for _, a in { 35, -35, 145, -145 } do
			wrap("Seam", a, MID, 0.07, 3, 0.08, rgb(150, 120, 60))
		end
		front("Glove", 0, -3.6, 0.85, 0.75, 0.12, rgb(214, 47, 58))
		front("Glove", 0, -3.13, 0.7, 0.25, 0.14, rgb(214, 47, 58))
		front("Thumb", -0.5, -3.5, 0.25, 0.42, 0.16, rgb(190, 36, 46))
		front("Cuff", 0, -4.12, 0.75, 0.3, 0.14, rgb(255, 255, 255))
		front("Shine", 0.22, -3.3, 0.15, 0.3, 0.18, rgb(255, 140, 140), { studs = false })
		front("Plate", 0, -4.85, 1.2, 0.3, 0.08, gold, METAL)
	end,
	-- 4 Pro Red: glossy red, white caps, gold straps, a white star and a shine stripe
	function()
		local gold = rgb(242, 195, 58)
		hanger(LOOKS[4], rgb(244, 244, 244))
		body(rgb(214, 47, 58), nil, rgb(244, 244, 244))
		ring("Strap", RADIUS + 0.06, 0.35, -2.55, gold)
		ring("Strap", RADIUS + 0.06, 0.35, -5.05, gold)
		front("Star", 0, -3.8, 0.9, 0.9, 0.1, rgb(255, 255, 255), { studs = false })
		front("Star", 0, -3.8, 0.9, 0.9, 0.1, rgb(255, 255, 255), { studs = false }, 45)
		front("StarCore", 0, -3.8, 0.45, 0.45, 0.14, gold, { studs = false }, 22)
		wrap("Shine", -40, MID, 0.25, 3.6, 0.06, rgb(239, 95, 106), { studs = false })
		wrap("Shine", -28, MID + 0.4, 0.1, 2.4, 0.06, rgb(255, 160, 165), { studs = false })
		for _, a in { 0, 180 } do
			wrap("Buckle", a + 90, -2.55, 0.35, 0.45, 0.12, rgb(255, 230, 120), METAL)
			wrap("Buckle", a + 90, -5.05, 0.35, 0.45, 0.12, rgb(255, 230, 120), METAL)
		end
	end,
	-- 5 Tire Stack: four street-gym tyres on a rope, yellow rims, chunky tread
	function()
		local tyre, tread, yellow = rgb(42, 42, 46), rgb(69, 69, 76), rgb(240, 196, 25)
		ring("Rope", 0.14, 7.4, -2.3, LOOKS[5].chain, FABRIC)
		block("Hook", { 0.4, 0.45, 0.4 }, 0, -0.2, 0, rgb(150, 155, 165), { material = "Metal", studs = false })
		for i = 0, 3 do
			local y = -1.9 - i * 1.12
			ring("Tyre", 1.75, 1, y, tyre)
			ring("Rim", 1.79, 0.12, y + 0.36, yellow)
			ring("Rim", 1.79, 0.12, y - 0.36, yellow)
			ring("Hub", 0.75, 1.02, y, rgb(28, 28, 32))
			for k = 0, 7 do
				wrap("Tread", k * 45 + i * 22, y, 0.35, 0.7, 0.12, tread, nil, 0, 1.75)
			end
		end
		ball("Knot", 0.6, 0, -6.1, 0, LOOKS[5].chain, FABRIC)
	end,
	-- 6 Iron Plate: diamond-plate steel, hazard belt, rivets, rust patches
	function()
		local steel, dark, rust = rgb(124, 134, 150), rgb(58, 65, 80), rgb(183, 92, 46)
		hanger(LOOKS[6], dark, rgb(184, 190, 200))
		body(steel, { material = "DiamondPlate" }, dark, nil, METAL)
		ring("Hazard", RADIUS + 0.05, 0.8, MID, rgb(242, 195, 58))
		scatter("Stripe", 12, { MID }, 0.22, 0.7, 0.2, rgb(27, 29, 34), { studs = false }, nil, 30)
		rivets(12, -2.1, rgb(184, 190, 200))
		rivets(12, -5.5, rgb(184, 190, 200))
		wrap("Rust", 30, -2.75, 0.6, 0.5, 0.06, rust, { material = "CorrodedMetal" }, 12)
		wrap("Rust", -50, -4.95, 0.5, 0.4, 0.06, rust, { material = "CorrodedMetal" }, -8)
		wrap("Rust", 160, -2.9, 0.7, 0.45, 0.06, rust, { material = "CorrodedMetal" })
		wrap("Plate", 0, -2.75, 1.1, 0.55, 0.1, dark, METAL)
	end,
	-- 7 Bronze Statue: cast bronze on a stepped plinth, a raised fist emblem, green patina
	function()
		local bronze, darkB, light, patina = rgb(192, 122, 60), rgb(110, 67, 32), rgb(224, 163, 94), rgb(90, 160, 140)
		hanger(LOOKS[7], darkB)
		body(bronze, METAL, darkB, darkB, METAL)
		ring("Plinth", RADIUS + 0.22, 0.3, BOTTOM - 0.3, rgb(138, 84, 40), METAL)
		ring("Molding", RADIUS + 0.05, 0.18, -2.2, light, METAL)
		ring("Molding", RADIUS + 0.05, 0.18, -5.4, light, METAL)
		front("Fist", 0, -3.95, 1, 0.8, 0.16, light, METAL)
		for i, x in { -0.36, -0.12, 0.12, 0.36 } do
			front("Knuckle", x, -3.42 + (if i == 1 or i == 4 then -0.04 else 0), 0.22, 0.28, 0.2, light, METAL)
		end
		front("Thumb", -0.15, -3.75, 0.55, 0.2, 0.22, rgb(240, 185, 120), METAL, -10)
		front("Wrist", 0, -4.55, 0.7, 0.45, 0.12, light, METAL)
		for _, p in { { 50, -2.6 }, { -70, -4.9 }, { 130, -3.4 }, { 200, -5 }, { -150, -2.5 } } do
			wrap("Patina", p[1], p[2], 0.35, 0.28, 0.06, patina, { studs = false })
		end
	end,
	-- 8 Silver Knight: plate armour, visor slits, blue crest shield with a chevron, pauldrons
	function()
		local silver, plate, blue = rgb(201, 209, 220), rgb(138, 149, 168), rgb(58, 111, 214)
		hanger(LOOKS[8], plate, rgb(230, 235, 242))
		body(silver, METAL, rgb(125, 135, 152), nil, METAL)
		ring("Plate", RADIUS + 0.05, 0.14, -2.6, plate, METAL)
		ring("Plate", RADIUS + 0.05, 0.14, -5.2, plate, METAL)
		front("Visor", 0, -2.05, 1.5, 0.12, 0.12, rgb(28, 30, 38))
		front("Visor", 0, -2.3, 1.5, 0.12, 0.12, rgb(28, 30, 38))
		front("ShieldRim", 0, -3.7, 1.35, 1.25, 0.1, rgb(242, 195, 58), METAL)
		front("Shield", 0, -3.7, 1.15, 1.05, 0.14, blue)
		front("ShieldTip", 0, -4.45, 0.62, 0.62, 0.12, blue, nil, 45)
		front("Chevron", -0.22, -3.85, 0.6, 0.16, 0.18, rgb(242, 244, 248), nil, 40)
		front("Chevron", 0.22, -3.85, 0.6, 0.16, 0.18, rgb(242, 244, 248), nil, -40)
		for _, side in { -1, 1 } do
			local a = Vector3.new(side * 1.5, TOP + 0.1, 0)
			beam("Pauldron", a, a + Vector3.new(side * 0.6, -0.5, 0), 0.9, 0.8, plate, METAL)
			beam(
				"Spike",
				a + Vector3.new(side * 0.3, 0.2, 0),
				a + Vector3.new(side * 0.75, 0.75, 0),
				0.22,
				0.22,
				rgb(230, 235, 242),
				METAL
			)
		end
		rivets(8, -5.5, rgb(125, 135, 152))
	end,
	-- 9 Gold Champion: solid gold with a champion belt and a jewelled buckle
	function()
		local gold, darkG = rgb(242, 195, 58), rgb(184, 134, 11)
		hanger(LOOKS[9], darkG, rgb(255, 224, 138))
		body(gold, METAL, darkG, nil, METAL)
		ring("Belt", RADIUS + 0.1, 1, MID - 0.1, rgb(28, 28, 34))
		ring("BeltEdge", RADIUS + 0.12, 0.1, MID + 0.38, gold, METAL)
		ring("BeltEdge", RADIUS + 0.12, 0.1, MID - 0.58, gold, METAL)
		wrap("Buckle", 0, MID - 0.1, 1.5, 1.05, 0.22, rgb(255, 216, 77), METAL, 0, RADIUS + 0.08)
		wrap("BuckleRim", 0, MID - 0.1, 1.2, 0.8, 0.26, rgb(255, 241, 176), METAL, 0, RADIUS + 0.08)
		local c = surface(0, MID - 0.1, RADIUS + 0.5).Position
		ball("Jewel", 0.42, c.X, c.Y, c.Z, rgb(232, 65, 74), NEON)
		for _, x in { -0.45, 0.45 } do
			local p = surface(math.deg(math.asin(x / RADIUS)), MID - 0.1, RADIUS + 0.38).Position
			ball("Jewel", 0.26, p.X, p.Y, p.Z, rgb(58, 111, 214), NEON)
		end
		for _, a in { 60, -60, 120, -120 } do
			wrap("Plaque", a, MID - 0.1, 0.5, 0.6, 0.3, gold, METAL)
		end
		wrap("Shine", -45, MID + 0.9, 0.18, 1.2, 0.06, rgb(255, 241, 176), { studs = false })
		wrap("Shine", -45, MID - 1.25, 0.18, 0.9, 0.06, rgb(255, 241, 176), { studs = false })
	end,
	-- 10 Ice Block: a frozen glass cube with a snowflake inside, cracks, a snow cap and icicles
	function()
		local ice, snow, frost = rgb(168, 220, 255), rgb(240, 250, 255), rgb(207, 233, 255)
		local half = 1.55
		hanger(LOOKS[10], frost, frost)
		block(
			"Body",
			{ half * 2, TOP - BOTTOM, half * 2 },
			0,
			MID,
			0,
			ice,
			{ material = "Glass", transparency = 0.3, studs = false }
		)
		block("Cap", { half * 2 + 0.3, 0.5, half * 2 + 0.3 }, 0, TOP + 0.1, 0, snow, { material = "Snow" })
		block("Base", { half * 2 + 0.1, 0.3, half * 2 + 0.1 }, 0, BOTTOM - 0.05, 0, frost, { material = "Ice" })
		for _, x in { -1.2, -0.5, 0.3, 1.1 } do
			block(
				"Drip",
				{ 0.3, 0.35 + math.abs(x) * 0.2, 0.3 },
				x,
				TOP - 0.3,
				-half - 0.05,
				snow,
				{ material = "Snow" }
			)
		end
		for k = 0, 2 do
			block("Flake", { 1.9, 0.18, 0.18 }, 0, MID, -0.2, rgb(255, 255, 255), NEON, k * 60)
		end
		ball("FlakeCore", 0.45, 0, MID, -0.2, frost, { material = "Neon", light = frost })
		block("Crack", { 1.1, 0.07, 0.06 }, -0.7, -2.6, -half - 0.03, rgb(255, 255, 255), { studs = false }, -30)
		block("Crack", { 0.8, 0.07, 0.06 }, 0.75, -4.9, -half - 0.03, rgb(255, 255, 255), { studs = false }, 25)
		block("Crack", { 0.6, 0.07, 0.06 }, -0.9, -5.2, -half - 0.03, rgb(255, 255, 255), { studs = false }, 60)
		for _, p in
			{ { -1.1, -0.6, 0.85 }, { -0.2, 0.7, 1.15 }, { 0.6, -0.9, 0.7 }, { 1.15, 0.4, 0.95 }, { 0, 0, 1.3 } }
		do
			beam(
				"Icicle",
				Vector3.new(p[1], BOTTOM - 0.15, p[2]),
				Vector3.new(p[1], BOTTOM - 0.15 - p[3], p[2]),
				0.28,
				0.28,
				frost,
				{ material = "Ice" }
			)
		end
	end,
	-- 11 Crystal Geode: cracked-open rock, purple and cyan crystals, a glowing core
	function()
		local rock, purple, cyan = rgb(86, 58, 128), rgb(210, 155, 255), rgb(143, 230, 255)
		hanger(LOOKS[11], rgb(60, 40, 90), LOOKS[11].chain)
		body(rock, { material = "Slate" }, rgb(58, 38, 88), nil, { material = "Slate" })
		disc("Hollow", 0, MID, 0.95, 0.12, rgb(30, 15, 51))
		local c = on(0, MID, RADIUS + 0.35)
		ball("Core", 0.9, c.X, c.Y, c.Z, rgb(242, 216, 255), { material = "Neon", light = purple })
		for i, a in { 0, 60, 120, 180, 240, 300 } do
			local root = surface(0, MID, RADIUS + 0.1) * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(0, 0.85, 0)
			local tip = root * CFrame.new(0, 0.7, -0.45)
			beam(
				"Crystal",
				root.Position,
				tip.Position,
				0.34,
				0.34,
				if i % 2 == 0 then cyan else purple,
				{ material = "Glass", transparency = 0.1 }
			)
		end
		for _, p in { { 70, -2.5, 1 }, { -80, -4.6, 0.8 }, { 150, -3.2, 0.9 }, { -140, -5.1, 0.7 } } do
			local base = on(p[1], p[2], RADIUS - 0.1)
			beam(
				"Crystal",
				base,
				on(p[1], p[2] + 0.4, RADIUS + p[3]),
				0.42,
				0.42,
				purple,
				{ material = "Glass", transparency = 0.1 }
			)
		end
		for i, x in { -0.6, 0, 0.55 } do
			local base = Vector3.new(x, TOP + 0.3, (i - 2) * 0.4)
			beam(
				"Crystal",
				base,
				base + Vector3.new(x * 0.4, 0.9 + (i % 2) * 0.35, 0),
				0.4,
				0.4,
				if i == 2 then cyan else purple,
				NEON
			)
		end
	end,
	-- 12 Candy Smash: peppermint stripes, sprinkles, icing drips and a gumdrop on top
	function()
		local pink, white, green = rgb(255, 138, 196), rgb(255, 255, 255), rgb(125, 255, 138)
		hanger(LOOKS[12], rgb(255, 90, 160))
		body(pink, nil, white, rgb(255, 90, 160))
		for i = 0, 4 do
			ring("Stripe", RADIUS + 0.03, 0.32, -2.15 - i * 0.82, white)
		end
		for i, a in { 0, 40, 80, 125, 160, 200, 245, 285, 320 } do
			wrap("Icing", a, TOP - 0.25 - (i % 3) * 0.2, 0.35, 0.45 + (i % 3) * 0.4, 0.1, white, { studs = false })
		end
		local colors = { rgb(72, 216, 255), rgb(255, 225, 77), rgb(125, 255, 138), rgb(185, 140, 255) }
		for i = 0, 15 do
			wrap(
				"Sprinkle",
				i * 47 % 360,
				-2.6 - (i * 0.37) % 3,
				0.32,
				0.1,
				0.1,
				colors[i % 4 + 1],
				{ studs = false },
				i * 53 % 180
			)
		end
		-- the gumdrop sits on the front of the lid, clear of the straps
		ball("Gumdrop", 1, 0, TOP + 0.65, -0.8, green, { material = "Glass", transparency = 0.1 })
		for _, p in { { -0.25, 0.95, -1.05 }, { 0.3, 0.8, -1.15 }, { 0.05, 1.12, -0.7 } } do
			block("Sugar", { 0.12, 0.12, 0.12 }, p[1], TOP + p[2], p[3], white, { studs = false })
		end
	end,
	-- 13 Lava Core: obsidian split by glowing magma cracks, dripping lava
	function()
		local rock, lava, hot = rgb(42, 26, 26), rgb(255, 122, 30), rgb(255, 176, 46)
		hanger(LOOKS[13], rgb(58, 31, 24), LOOKS[13].chain)
		body(rock, { material = "Basalt" }, rgb(58, 31, 24), nil, { material = "Basalt" })
		ring("Seam", RADIUS + 0.13, 0.1, TOP - 0.18, lava, NEON)
		local cracks = {
			{ 0, -2.6, 25 },
			{ 25, -3.5, -40 },
			{ -30, -4.4, 15 },
			{ 10, -5.1, -20 },
			{ 110, -3, 35 },
			{ 160, -4.6, -25 },
			{ -110, -2.9, -30 },
			{ -170, -4.2, 20 },
		}
		for _, c in cracks do
			wrap("Crack", c[1], c[2], 1.3, 0.12, 0.06, lava, NEON, c[3])
		end
		for _, s in { { -20, -3 }, { 15, -4.8 }, { 135, -2.4 }, { -140, -5.2 } } do
			wrap("Glow", s[1], s[2], 0.3, 0.3, 0.07, hot, NEON, 45)
		end
		local c = on(0, MID, RADIUS - 0.5)
		ball("Core", 0.4, c.X, c.Y, c.Z, lava, { material = "Neon", light = lava, transparency = 1 })
		for _, d in { { -0.7, 0.45, -0.6 }, { 0.2, 0.8, -1.2 }, { 0.8, 0.35, 0.4 } } do
			block("Drip", { 0.28, d[2], 0.28 }, d[1], BOTTOM - 0.2 - d[2] / 2, d[3], hot, NEON)
		end
	end,
	-- 14 Thunder Cell: battery bag with neon coils, a lightning bolt and a terminal on top
	function()
		local navy, cyan, bolt = rgb(31, 35, 64), rgb(72, 216, 255), rgb(255, 243, 107)
		hanger(LOOKS[14], rgb(58, 63, 106), rgb(200, 204, 212))
		body(navy, nil, rgb(58, 63, 106), rgb(200, 204, 212), METAL)
		for i = 0, 3 do
			ring("Coil", RADIUS + 0.04, 0.1, -2.3 - i * 1.05, cyan, NEON)
		end
		front("Bolt", 0.18, -3.05, 0.42, 1.15, 0.12, bolt, NEON, -18)
		front("Bolt", 0, -3.75, 0.9, 0.3, 0.12, bolt, NEON, -18)
		front("Bolt", -0.18, -4.4, 0.42, 1.15, 0.12, bolt, NEON, -18)
		ring("Terminal", 0.55, 0.45, TOP + 0.55, rgb(200, 204, 212), METAL)
		block("TerminalCap", { 0.5, 0.25, 0.5 }, 0.7, TOP + 0.48, 0, rgb(232, 65, 74))
		for _, a in { 90, -90 } do
			wrap("Coilbox", a, MID, 0.6, 2.6, 0.3, rgb(200, 120, 60), METAL)
			for k = 0, 3 do
				wrap("Spark", a, -2.9 - k * 0.6, 0.2, 0.2, 0.36, cyan, NEON)
			end
		end
	end,
	-- 15 Toxic Barrel: leaky green drum on crossed straps, hazard sign, glowing goo over the rim
	function()
		local green, dark, goo, strap = rgb(61, 107, 31), rgb(42, 42, 46), rgb(182, 255, 46), rgb(70, 45, 30)
		hanger(LOOKS[15], strap)
		body(green, METAL, dark, dark, METAL)
		ring("Rib", RADIUS + 0.1, 0.25, -2.6, dark, METAL)
		ring("Rib", RADIUS + 0.1, 0.25, -5, dark, METAL)
		for _, a in { 90, -90 } do
			wrap("Strap", a, MID, 0.4, TOP - BOTTOM + 0.6, 0.1, strap, nil, 0, RADIUS + 0.1)
		end
		disc("Sign", 0, -3.8, 0.75, 0.08, rgb(255, 225, 77))
		disc("SignDot", 0, -3.8, 0.16, 0.12, dark)
		for k = 0, 2 do
			local cf = surface(0, -3.8, RADIUS + 0.06)
				* CFrame.Angles(0, 0, math.rad(k * 120 + 90))
				* CFrame.new(0, 0.42, 0)
			put("Blade", { 0.4, 0.42, 0.06 }, cf, dark)
		end
		for i, a in { -50, -10, 30, 75, 140, 200, 260 } do
			wrap("Goo", a, TOP - 0.3 - (i % 3) * 0.3, 0.38, 0.6 + (i % 3) * 0.55, 0.1, goo, NEON)
		end
		block("Drip", { 0.3, 0.6, 0.3 }, 0.6, BOTTOM - 0.5, -0.9, goo, NEON)
		ball("Drop", 0.35, 0.6, BOTTOM - 1, -0.9, goo, NEON)
	end,
	-- 16 Robo Bag: a screen face that winces, status lights, piston arms and an antenna
	function()
		local steel, screen, teal, dark = rgb(200, 204, 212), rgb(18, 24, 42), rgb(72, 255, 210), rgb(58, 63, 80)
		hanger(LOOKS[16], dark, rgb(230, 235, 242))
		body(steel, METAL, dark, dark, METAL)
		wrap("Screen", 0, -3, 2.1, 1.55, 0.8, dark, METAL, 0, RADIUS - 0.32)
		wrap("Face", 0, -3, 1.8, 1.25, 0.84, screen, nil, 0, RADIUS - 0.32)
		local z = -(RADIUS - 0.32 + 0.84 - 0.04) - 0.03
		block("EyeL", { 0.38, 0.38, 0.06 }, -0.45, -2.8, z, teal, NEON)
		block("EyeR", { 0.38, 0.38, 0.06 }, 0.45, -2.8, z, teal, NEON)
		block("Mouth", { 0.9, 0.12, 0.06 }, 0, -3.3, z, teal, NEON)
		for i, c in { rgb(255, 74, 90), rgb(255, 225, 77), teal } do
			local p = surface(math.deg(math.asin((i - 2) * 0.4 / RADIUS)), -4.45, RADIUS + 0.06).Position
			ball("Light", 0.3, p.X, p.Y, p.Z, c, NEON)
		end
		front("Panel", 0, -5.1, 1.8, 0.07, 0.08, dark)
		front("Vent", 0, -5.4, 1.2, 0.07, 0.08, dark)
		for _, side in { -1, 1 } do
			local a = Vector3.new(side * RADIUS, -4, 0)
			beam("Arm", a, a + Vector3.new(side * 1.1, 0, 0), 0.4, 0.4, rgb(154, 160, 170), METAL)
			block("Joint", { 0.6, 0.6, 0.6 }, side * (RADIUS + 1.2), -4, 0, dark, METAL)
			beam(
				"Piston",
				Vector3.new(side * (RADIUS + 1.2), -4.3, 0),
				Vector3.new(side * (RADIUS + 1.2), -5.1, 0),
				0.3,
				0.3,
				rgb(154, 160, 170),
				METAL
			)
			block("Claw", { 0.55, 0.3, 0.55 }, side * (RADIUS + 1.2), -5.25, 0, dark, METAL)
		end
		beam(
			"Antenna",
			Vector3.new(0.6, TOP + 0.3, 0.3),
			Vector3.new(0.75, TOP + 1.5, 0.3),
			0.1,
			0.1,
			rgb(154, 160, 170),
			METAL
		)
		ball("Blink", 0.32, 0.76, TOP + 1.6, 0.3, rgb(255, 74, 90), { material = "Neon", light = rgb(255, 74, 90) })
	end,
	-- 17 Dragon Hide: scaled red hide, a gold belly, a slit eye, horns, wing fins and back spikes
	function()
		local red, scale, gold, bone = rgb(179, 38, 30), rgb(138, 26, 20), rgb(242, 195, 58), rgb(242, 230, 208)
		hanger(LOOKS[17], rgb(58, 13, 10))
		body(red, nil, rgb(58, 13, 10))
		scatter("Scale", 9, { -2.3, -3.1, -3.9, -4.7, -5.5 }, 0.55, 0.38, 0.1, scale, { studs = false }, 35, 45)
		for i = 0, 4 do
			front("Belly", 0, -2.8 - i * 0.58, 1.2 - math.abs(i - 2) * 0.12, 0.46, 0.12, gold, METAL)
		end
		front("Eye", 0, -2.05, 0.95, 0.42, 0.14, rgb(255, 225, 77), NEON)
		front("Slit", 0, -2.05, 0.12, 0.4, 0.18, rgb(20, 4, 4))
		for _, side in { -1, 1 } do
			local a = Vector3.new(side * 0.9, TOP + 0.3, -0.3)
			beam("Horn", a, a + Vector3.new(side * 0.5, 1.1, 0.25), 0.4, 0.4, bone)
			beam(
				"Horn",
				a + Vector3.new(side * 0.5, 1.1, 0.25),
				a + Vector3.new(side * 0.95, 1.5, 0.6),
				0.24,
				0.24,
				bone
			)
			for k = 0, 2 do
				local root = on(180 - side * 55, -2.5 - k * 0.7, RADIUS - 0.1)
				beam(
					"Wing",
					root,
					root + Vector3.new(side * (1.6 - k * 0.35), 0.5 - k * 0.2, 0.9),
					0.12,
					1.05 - k * 0.2, -- a tall membrane (beam width x height)
					scale
				)
			end
		end
		for k = 0, 4 do
			local root = on(180, -2.2 - k * 0.8, RADIUS - 0.05)
			beam("Spike", root, root + Vector3.new(0, 0.2, 0.5), 0.26, 0.26, bone)
		end
	end,
	-- 18 Galaxy Void: a pocket universe with nebula clouds, stars, a ring and two moons
	function()
		local void, purple, pink, blue = rgb(26, 15, 58), rgb(90, 46, 168), rgb(208, 74, 160), rgb(58, 111, 214)
		hanger(LOOKS[18], rgb(42, 26, 90), LOOKS[18].chain)
		body(void, nil, rgb(42, 26, 90))
		for _, n in
			{
				{ -25, -2.6, 1.3, 1, purple },
				{ 30, -4.1, 1.2, 0.9, pink },
				{ -15, -5.1, 0.9, 0.7, blue },
				{ 140, -3.2, 1.3, 1, purple },
				{ -130, -4.6, 1.1, 0.8, pink },
			} :: { { any } }
		do
			wrap(
				"Nebula",
				n[1],
				n[2],
				n[3],
				n[4],
				0.06,
				n[5],
				{ material = "Neon", transparency = 0.45, studs = false },
				20
			)
		end
		for i = 0, 13 do
			wrap("Star", i * 83 % 360, -2.1 - (i * 0.29) % 3.7, 0.12, 0.12, 0.1, rgb(255, 255, 255), NEON, 45)
		end
		for k = 0, 15 do
			local cf = CFrame.new(0, MID + 0.6, 0)
				* CFrame.Angles(math.rad(12), math.rad(k * 22.5), 0)
				* CFrame.new(0, 0, -2.5)
			put("Halo", { 0.95, 0.1, 0.3 }, cf, rgb(255, 200, 122), NEON)
		end
		ball("Orbit", 0.7, 2.7, -2.6, 0, rgb(72, 216, 255), { material = "Neon", light = rgb(72, 216, 255) })
		ball("Orbit", 0.45, -2.4, -5, 1, rgb(255, 138, 196), NEON)
		local c = on(0, MID, 0)
		ball("Core", 0.3, c.X, c.Y, c.Z, purple, { material = "Neon", transparency = 1, light = rgb(185, 140, 255) })
	end,
	-- 19 Sun Guardian: white and gold, a radiant sun emblem, rune trim, feathered wings, a halo
	function()
		local white, gold, glow = rgb(251, 247, 238), rgb(242, 195, 58), rgb(255, 216, 77)
		hanger(LOOKS[19], gold, rgb(255, 224, 138))
		body(white, nil, gold, gold, METAL)
		ring("Band", RADIUS + 0.05, 0.3, -2.1, gold, METAL)
		ring("Band", RADIUS + 0.05, 0.3, -5.5, gold, METAL)
		scatter("Rune", 12, { -2.1, -5.5 }, 0.16, 0.16, 0.12, rgb(255, 241, 176), NEON)
		disc("Sun", 0, -3.75, 0.55, 0.12, glow, NEON)
		for k = 0, 7 do
			local cf = surface(0, -3.75, RADIUS + 0.02) * CFrame.Angles(0, 0, math.rad(k * 45)) * CFrame.new(0, 0.85, 0)
			put("Ray", { 0.16, if k % 2 == 0 then 0.55 else 0.35, 0.08 }, cf, gold, METAL)
		end
		for _, side in { -1, 1 } do
			for row = 0, 2 do
				for k = 0, 2 do
					local root = on(180 - side * 60, -2.6 - row * 0.5, RADIUS - 0.05)
					local tip = root
						+ Vector3.new(side * (1.7 - row * 0.3 - k * 0.15), 0.9 - k * 0.55 - row * 0.15, 0.6 + k * 0.2)
					beam(
						"Feather",
						root,
						tip,
						0.1,
						0.4,
						if row == 0 then white else rgb(255, 241, 176),
						{ studs = false }
					)
				end
			end
		end
		for k = 0, 11 do
			local cf = CFrame.new(0, TOP + 1, 0) * CFrame.Angles(0, math.rad(k * 30), 0) * CFrame.new(0, 0, -1.2)
			put("Halo", { 0.55, 0.14, 0.18 }, cf, glow, { material = "Neon", light = if k == 0 then glow else nil })
		end
	end,
	-- 20 Rainbow God: rainbow bands, a tall crown, rainbow wings and four orbiting gems
	function()
		local look = LOOKS[20]
		local gold = rgb(255, 216, 77)
		hanger(look, gold, gold)
		body(rgb(255, 255, 255), nil, gold, gold, METAL)
		for i, c in look.fx do
			ring("Rainbow", RADIUS + 0.03, (TOP - BOTTOM) / 7 - 0.02, TOP - (i - 0.5) * (TOP - BOTTOM) / 7, c)
			if i < 7 then
				ring("Glow", RADIUS + 0.05, 0.05, TOP - i * (TOP - BOTTOM) / 7, rgb(255, 255, 255), NEON)
			end
		end
		front("Gem", 0, -3.8, 0.8, 0.8, 0.14, rgb(255, 255, 255), { material = "Neon", light = rgb(255, 138, 240) }, 45)
		ring("Crown", 1.3, 0.45, TOP + 0.5, gold, METAL)
		for k = 0, 4 do
			local cf = CFrame.new(0, TOP + 1.05, 0) * CFrame.Angles(0, math.rad(k * 72), 0) * CFrame.new(0, 0, -1.15)
			put("Point", { 0.45, if k == 0 then 1.25 else 0.9, 0.2 }, cf, gold, METAL)
			put("CrownGem", { 0.24, 0.24, 0.24 }, cf * CFrame.new(0, 0, -0.12), look.fx[k + 1], NEON)
		end
		for _, side in { -1, 1 } do
			for k = 1, 4 do
				local root = on(180 - side * 65, -2.4 - k * 0.35, RADIUS - 0.05)
				local tip = root + Vector3.new(side * (2.3 - k * 0.3), 1.2 - k * 0.45, 0.7)
				beam("Wing", root, tip, 0.1, 0.45, look.fx[k * 2 - 1], NEON)
			end
		end
		for k = 0, 3 do
			local cf = CFrame.new(0, MID + (if k % 2 == 0 then 0.5 else -0.5), 0)
				* CFrame.Angles(0, math.rad(k * 90), 0)
				* CFrame.new(0, 0, -2.7)
			put("Orbit", { 0.5, 0.5, 0.5 }, cf * CFrame.Angles(math.rad(45), 0, math.rad(45)), look.fx[k * 2 + 1], NEON)
		end
	end,
}

-- API -----------------------------------------------------------------------

Sacks.count = #BUILD

function Sacks.look(tier: number): Look
	return LOOKS[math.clamp(tier, 1, #LOOKS)]
end

function Sacks.spec(tier: number): Spec
	cur = {}
	BUILD[math.clamp(tier, 1, #BUILD)]()
	local parts = cur
	cur = {}
	return { parts = parts }
end

return Sacks
