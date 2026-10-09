--!strict
-- Partner A helpers for egg/pet specs. Not a spec file (lives outside Eggs/ and Pets/).
--
-- Conventions every spec follows:
--   * Feet at y = 0, model faces -Z (Roblox LookVector), left = -X.
--   * The FIRST part listed in a joint group sits at that group's hinge (hip, neck, wing root),
--     because BlockBuilder puts the group's Motor6D on that part. Anim tweens Motor6D.C0.
--   * Eyes are named "EyeL"/"EyeR" (Neon) so Anim can blink them; glints are "GlintL"/"GlintR".
--   * Egg shells use joint "Body" so the shell can tilt/squash above the sprouted legs.
local Builder = require(script.Parent.Parent.BlockBuilder)
local Rarities = require(script.Parent.Parent.Parent.Config.Rarities)

type PartSpec = Builder.PartSpec
export type Opts = {
	rot: { number }?,
	material: string?,
	shape: string?,
	joint: string?,
	studs: boolean?,
	transparency: number?,
	light: Color3?,
}

local Kit = {}

-- Shorthand for one block.
function Kit.part(name: string, size: { number }, pos: { number }, color: Color3, o: Opts?): PartSpec
	local opts: Opts = o or {}
	return {
		name = name,
		size = size,
		pos = pos,
		color = color,
		rot = opts.rot,
		material = opts.material,
		shape = opts.shape,
		joint = opts.joint,
		studs = opts.studs,
		transparency = opts.transparency,
		light = opts.light,
	}
end

-- Neon eye with a white glint in its upper-outer corner. `side` = -1 (left) or 1 (right).
-- Eyes sit on a face whose front plane is z = `faceZ` (negative).
function Kit.eye(side: number, x: number, y: number, faceZ: number, w: number, h: number, joint: string): { PartSpec }
	local suffix = if side < 0 then "L" else "R"
	return {
		Kit.part(
			"Eye" .. suffix,
			{ w, h, 0.1 },
			{ x, y, faceZ - 0.03 },
			Color3.fromRGB(25, 25, 35),
			{ material = "Neon", joint = joint }
		),
		Kit.part(
			"Glint" .. suffix,
			{ w * 0.4, w * 0.4, 0.05 },
			{ x + side * w * 0.22, y + h * 0.25, faceZ - 0.09 },
			Color3.new(1, 1, 1),
			{ material = "Neon", joint = joint }
		),
	}
end

function Kit.rarityColor(rarity: string): Color3
	local r = Rarities[rarity]
	return if r then r.color else Color3.new(1, 1, 1)
end

-- Egg shell: 7 stacked square layers stepping in (~3.7 studs tall, 2.9 wide at the belly).
local EGG_LAYERS: { { number } } = { -- { width, height }
	{ 2.0, 0.4 },
	{ 2.6, 0.6 },
	{ 2.9, 0.8 },
	{ 2.7, 0.7 },
	{ 2.2, 0.6 },
	{ 1.5, 0.4 },
	{ 0.8, 0.2 },
}
Kit.EGG_HEIGHT = 3.7

-- Returns width, bottom y and center y of layer i.
function Kit.eggLayer(i: number): (number, number, number)
	local y = 0
	for j = 1, i - 1 do
		y += EGG_LAYERS[j][2]
	end
	local l = EGG_LAYERS[i]
	return l[1], y, y + l[2] / 2
end

local function widthAt(y: number): number
	for i = 1, #EGG_LAYERS do
		local w, bottom = Kit.eggLayer(i)
		if y < bottom + EGG_LAYERS[i][2] then
			return w
		end
	end
	return EGG_LAYERS[#EGG_LAYERS][1]
end

-- `colors[i]` paints layer i (cycles if shorter than 7).
function Kit.eggShell(colors: { Color3 }): { PartSpec }
	local parts = {}
	for i, l in EGG_LAYERS do
		local _, _, cy = Kit.eggLayer(i)
		local c = colors[(i - 1) % #colors + 1]
		table.insert(parts, Kit.part("Shell" .. i, { l[1], l[2], l[1] }, { 0, cy, 0 }, c, { joint = "Body" }))
	end
	return parts
end

-- Flat pattern plate flush on one face of the shell. side: "F" (-Z), "B" (+Z), "L" (-X), "R" (+X).
-- `along` is the horizontal offset across that face, `y` the plate's center height.
function Kit.onShell(
	name: string,
	side: string,
	along: number,
	y: number,
	sx: number,
	sy: number,
	color: Color3,
	o: Opts?
): PartSpec
	local d = widthAt(y) / 2 + 0.02
	local opts: Opts = o or {}
	opts.joint = opts.joint or "Body"
	if side == "F" then
		return Kit.part(name, { sx, sy, 0.12 }, { along, y, -d }, color, opts)
	elseif side == "B" then
		return Kit.part(name, { sx, sy, 0.12 }, { -along, y, d }, color, opts)
	elseif side == "L" then
		return Kit.part(name, { 0.12, sy, sx }, { -d, y, along }, color, opts)
	end
	return Kit.part(name, { 0.12, sy, sx }, { d, y, -along }, color, opts)
end

-- Rare+ eggs: a Neon ring around layer i in the rarity colour with a faint PointLight.
function Kit.eggBand(i: number, rarity: string): PartSpec
	local w, _, cy = Kit.eggLayer(i)
	local c = Kit.rarityColor(rarity)
	return Kit.part(
		"RarityBand",
		{ w + 0.12, 0.22, w + 0.12 },
		{ 0, cy, 0 },
		c,
		{ material = "Neon", joint = "Body", light = c }
	)
end

-- Concatenate part lists.
function Kit.join(...: { PartSpec }): { PartSpec }
	local out = {}
	for _, list in { ... } do
		for _, p in list do
			table.insert(out, p)
		end
	end
	return out
end

return Kit
