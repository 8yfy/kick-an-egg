--!strict
-- Partner A. The open valley around the egg track (world remodel 2026-10-15). Gameplay stays exactly where it was:
-- the 48-stud lane (LandingSurface), the canyon floor out to x = +-40, and an invisible collision wall at x = +-40
-- (MapBuilder builds those). Everything this module adds is decoration that never collides, never takes touches and
-- never blocks raycasts:
--   * banks: stepped, themed terrain modules whose fronts sit on the x = +-40 line, varied in length, height and
--     depth (never a uniform row), with the zone's palette;
--   * plateau: the ground beyond the banks out to the horizon (a stone body + a ground cap, so its ends read as
--     cliffs), at a per-zone height;
--   * scatter / cluster helpers for vegetation, rocks and props with spacing and keep-outs;
--   * far silhouettes (forest bands, hills, mountains, clouds) to close the view;
--   * shoulders: low ground cover on the canyon floor beside the lane (|x| 26..39), never over the lane;
--   * seams: a cluster at each zone's far end so neighbouring zones hand over instead of switching at a line.
-- Zone compositions (World/Zones/*.luau) call these with their own palettes and hand-placed anchors.
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)
local Fx = require(script.Parent.Fx)

local Valley = {}

export type Pick = { string } | { { any } } -- names, or { name, weight, minScale, maxScale }
export type Ctx = {
	zone: any,
	z0: number,
	z1: number,
	zm: number,
	folder: Instance,
	terrain: Instance,
	nature: Instance,
	props: Instance,
	far: Instance,
	fx: Instance,
	rng: Random,
	palette: Kit.Palette,
	plateau: { [number]: number }, -- side (-1 / 1) -> plateau top height
	keep: { { x: number, z: number, r: number } },
	placed: { Vector3 },
}

local INNER = 40 -- canyon floor half width = the collision wall line
local HALF = 24 -- lane half width
local FAR_X = 430
-- Global density knob for scatter / cluster / shoulder counts (part budget: ~600 parts per zone).
local DENSITY = 0.42

local rgb = Color3.fromRGB

function Valley.new(zone: any, parent: Instance, palette: Kit.Palette, seed: number?): Ctx
	local folder = Parts.folder(parent, "Valley")
	local ctx: Ctx = {
		zone = zone,
		z0 = zone.start,
		z1 = zone.start + zone.length,
		zm = zone.start + zone.length / 2,
		folder = folder,
		terrain = Parts.folder(folder, "Terrain"),
		nature = Parts.folder(folder, "Nature"),
		props = Parts.folder(folder, "Props"),
		far = Parts.folder(folder, "Far"),
		fx = Parts.folder(folder, "Fx"),
		rng = Random.new(seed or zone.id * 9973),
		palette = palette,
		plateau = { [-1] = 8, [1] = 8 },
		keep = {},
		placed = {},
	}
	return ctx
end

-- Keep this circle free of scattered things (landmarks, paths, special builds).
function Valley.keepOut(ctx: Ctx, x: number, z: number, r: number)
	table.insert(ctx.keep, { x = x, z = z, r = r })
end

local function blocked(ctx: Ctx, x: number, z: number, pad: number): boolean
	for _, k in ctx.keep do
		local dx, dz = x - k.x, z - k.z
		if dx * dx + dz * dz < (k.r + pad) ^ 2 then
			return true
		end
	end
	return false
end

-- Ground height at (x, z) on a side: the plateau beyond the banks, 0 on the canyon floor.
function Valley.groundAt(ctx: Ctx, x: number, _z: number): number
	if math.abs(x) <= INNER + 4 then
		return 0
	end
	return ctx.plateau[if x < 0 then -1 else 1]
end

-- Places one kit asset. `yaw` in degrees; `y` defaults to the ground at (x, z).
function Valley.put(
	ctx: Ctx,
	parent: Instance,
	name: string,
	x: number,
	z: number,
	scale: (number | Vector3)?,
	yaw: number?,
	palette: Kit.Palette?,
	y: number?,
	opts: Kit.Opts?
): Model?
	local gy = y or Valley.groundAt(ctx, x, z)
	return Kit.place(
		parent,
		name,
		Kit.at(x, gy, z, yaw or ctx.rng:NextNumber(0, 360)),
		scale or 1,
		palette or ctx.palette,
		opts
	)
end

local function choose(ctx: Ctx, pick: Pick): (string, number)
	local first = pick[1]
	if typeof(first) == "string" then
		return (pick :: { string })[ctx.rng:NextInteger(1, #pick)], 1
	end
	local total = 0
	for _, e in pick :: { { any } } do
		total += e[2] or 1
	end
	local r = ctx.rng:NextNumber(0, total)
	for _, e in pick :: { { any } } do
		r -= e[2] or 1
		if r <= 0 then
			return e[1], ctx.rng:NextNumber(e[3] or 1, e[4] or e[3] or 1)
		end
	end
	local last = (pick :: { { any } })[#pick]
	return last[1], last[3] or 1
end

-- Tag a model for the client's gentle sway (VFX/Ambient).
function Valley.sway(model: Model?, amp: number?, speed: number?)
	if model then
		model:SetAttribute("Amp", amp or 1.2)
		model:SetAttribute("Speed", speed or 0.22)
		CollectionService:AddTag(model, "WorldSway")
	end
end

-- Tag a model to float up and down (VFX/Ambient).
function Valley.bob(model: Model?, amp: number?, speed: number?)
	if model then
		model:SetAttribute("Amp", amp or 1)
		model:SetAttribute("Speed", speed or 0.15)
		CollectionService:AddTag(model, "WorldBob")
	end
end

-- Spin a model around its pivot's look axis (windmill sails, gears) at `speed` degrees / second (VFX/Ambient).
function Valley.spin(model: Model?, speed: number, axisY: boolean?)
	if model then
		model:SetAttribute("Speed", speed)
		if axisY then
			model:SetAttribute("Axis", "Y")
		end
		CollectionService:AddTag(model, "WorldSpin")
	end
end

-- The plateau on one side: a cliff-coloured body from the sea up and a ground cap, from x0 out to FAR_X.
function Valley.plateau(ctx: Ctx, side: number, height: number, ground: Color3, body: Color3?, x0: number?)
	ctx.plateau[side] = height
	local xa = x0 or (INNER + 10)
	local w = FAR_X - xa
	local cx = side * (xa + w / 2)
	local len = ctx.z1 - ctx.z0
	Parts.block(
		ctx.terrain,
		"PlateauBody",
		Vector3.new(w, height + 40, len),
		CFrame.new(cx, (height - 2 - 42) / 2 + 0.0, ctx.zm),
		body or ground:Lerp(rgb(90, 70, 50), 0.45),
		{
			collide = false,
			query = false,
			shadow = false,
		}
	)
	Parts.block(
		ctx.terrain,
		"PlateauTop",
		Vector3.new(w, 2, len),
		CFrame.new(cx, height - 1, ctx.zm),
		ground,
		{ collide = false, query = false }
	)
end

-- Breaks up a flat plateau with studded ground-tone patches (lighter / darker, turned, never overlapping the bank
-- line). One part each; `tones` are colours to pick from.
function Valley.patches(ctx: Ctx, side: number, tones: { Color3 }, count: number)
	local rng = ctx.rng
	local h = ctx.plateau[side]
	for _ = 1, count do
		local x = side * rng:NextNumber(INNER + 30, 300)
		local z = rng:NextNumber(ctx.z0 + 8, ctx.z1 - 8)
		local w, d = rng:NextNumber(10, 26), rng:NextNumber(8, 20)
		Parts.block(
			ctx.terrain,
			"GroundPatch",
			Vector3.new(w, 0.2, d),
			CFrame.new(x, h + 0.1, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0),
			tones[rng:NextInteger(1, #tones)],
			{
				collide = false,
				query = false,
				shadow = false,
			}
		)
	end
end

-- Stepped banks along one side from z0 to z1: varied modules with fronts on the wall line (x = +-40), their tops
-- around the plateau height. `kinds` = bank asset names; heights scale the modules around `height`.
function Valley.banks(
	ctx: Ctx,
	side: number,
	kinds: { string },
	height: number,
	opts: { depth: number?, z0: number?, z1: number?, palette: Kit.Palette? }?
)
	local o = opts or {}
	local rng = ctx.rng
	local z = o.z0 or ctx.z0
	local stop = o.z1 or ctx.z1
	local yaw = if side > 0 then 90 else -90
	while z < stop - 2 do
		local kind = kinds[rng:NextInteger(1, #kinds)]
		local size = Kit.size(kind)
		local len = math.min(size.X * rng:NextNumber(1.6, 2.1), stop - z + 3)
		local sx = len / size.X
		local depth = (o.depth or 22) * rng:NextNumber(0.85, 1.2)
		local sz = depth / size.Z
		local sy = height * rng:NextNumber(0.85, 1.15) / math.max(size.Y - 0.8, 1)
		local inset = rng:NextNumber(-0.6, 0.8) -- small steps in and out along the wall line, never inside it
		local x = side * (INNER + 0.4 + inset + depth / 2)
		Kit.place(
			ctx.terrain,
			kind,
			Kit.at(x, 0, z + len / 2, yaw + rng:NextNumber(-3, 3)),
			Vector3.new(sx, sy, sz),
			o.palette or ctx.palette
		)
		z += len - rng:NextNumber(1.5, 3)
	end
end

-- Scatter `count` picks over an area (x from xa to xb on `side`, z from za to zb) with spacing; returns models.
function Valley.scatter(
	ctx: Ctx,
	parent: Instance,
	side: number,
	pick: Pick,
	count: number,
	area: { number },
	spacing: number?,
	palette: Kit.Palette?,
	opts: Kit.Opts?,
	swayIt: boolean?
): { Model }
	local out = {}
	local rng = ctx.rng
	local tries = 0
	local sp = spacing or 6
	count = math.max(1, math.floor(count * DENSITY + 0.5))
	while #out < count and tries < count * 12 do
		tries += 1
		local x = side * rng:NextNumber(area[1], area[2])
		local z = rng:NextNumber(area[3] or ctx.z0 + 2, area[4] or ctx.z1 - 2)
		if not blocked(ctx, x, z, sp * 0.5) then
			local ok = true
			for _, p in ctx.placed do
				if (p.X - x) ^ 2 + (p.Z - z) ^ 2 < sp * sp then
					ok = false
					break
				end
			end
			if ok then
				local name, scale = choose(ctx, pick)
				local m = Valley.put(ctx, parent, name, x, z, scale, nil, palette, nil, opts)
				if m then
					table.insert(out, m)
					table.insert(ctx.placed, Vector3.new(x, 0, z))
					if swayIt then
						Valley.sway(m, rng:NextNumber(0.8, 1.5), rng:NextNumber(0.16, 0.28))
					end
				end
			end
		end
	end
	return out
end

-- A deliberate cluster around (x, z): `n` picks within `radius`, the first one at the centre (the hero).
function Valley.cluster(
	ctx: Ctx,
	parent: Instance,
	x: number,
	z: number,
	pick: Pick,
	n: number,
	radius: number,
	palette: Kit.Palette?,
	opts: Kit.Opts?,
	swayIt: boolean?
): { Model }
	local out = {}
	local rng = ctx.rng
	n = if n <= 1 then n else math.max(1, math.floor(n * DENSITY + 0.5))
	for i = 1, n do
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = if i == 1 then 0 else radius * math.sqrt(rng:NextNumber(0.15, 1))
		local px, pz = x + math.cos(ang) * r, z + math.sin(ang) * r
		if math.abs(px) > INNER + 6 or math.abs(x) <= INNER then
			local name, scale = choose(ctx, pick)
			if i == 1 then
				scale *= 1.15
			end
			local m = Valley.put(ctx, parent, name, px, pz, scale, nil, palette, nil, opts)
			if m then
				table.insert(out, m)
				table.insert(ctx.placed, Vector3.new(px, 0, pz))
				if swayIt then
					Valley.sway(m, rng:NextNumber(0.8, 1.5), rng:NextNumber(0.16, 0.28))
				end
			end
		end
	end
	return out
end

-- Low ground cover on the canyon floor beside the lane (|x| 27..38): never over the lane, never tall.
function Valley.shoulders(ctx: Ctx, pick: Pick, count: number, palette: Kit.Palette?, z0: number?)
	local rng = ctx.rng
	for i = 1, math.floor(count * DENSITY + 0.5) do
		local side = if i % 2 == 0 then 1 else -1
		local x = side * rng:NextNumber(HALF + 3.5, INNER - 2)
		local z = rng:NextNumber((z0 or ctx.z0) + 3, ctx.z1 - 3)
		local name, scale = choose(ctx, pick)
		Valley.put(ctx, ctx.nature, name, x, z, scale, nil, palette, 0, { shadow = false })
	end
end

-- Far silhouettes on a side: { name, x, z, scale(number | Vector3), yaw? } (x is the absolute distance from 0).
function Valley.farRow(ctx: Ctx, side: number, items: { { any } }, palette: Kit.Palette?)
	for _, it in items do
		local x = side * it[2]
		Valley.put(
			ctx,
			ctx.far,
			it[1],
			x,
			it[3],
			it[4],
			it[5] or ctx.rng:NextNumber(0, 360),
			palette,
			ctx.plateau[side] - 1.5,
			{ shadow = false }
		)
	end
end

-- An ambience emitter box over the valley (x on `side`, centred at |x| = cx with width w) or the canyon (side 0).
function Valley.fx(
	ctx: Ctx,
	preset: string,
	side: number,
	cx: number,
	w: number,
	y: number,
	h: number,
	tint: { Color3 }?,
	rate: number?,
	cull: number?
)
	local x = if side == 0 then 0 else side * cx
	Fx.area(ctx.fx, preset, Vector3.new(w, h, ctx.z1 - ctx.z0 - 4), Vector3.new(x, y, ctx.zm), tint, rate, cull)
end

-- A water strip on the plateau (stream / channel) from a to b (y = plateau top + 0.1), with a scrolling texture.
function Valley.stream(ctx: Ctx, a: Vector3, b: Vector3, width: number, color: Color3?)
	local len = (b - a).Magnitude
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(mid, b) * CFrame.Angles(math.rad(-90), 0, 0)
	-- the sheet's front (-Z after the tilt) faces up
	Fx.waterSheet(ctx.props, cf, Vector3.new(width, len + width * 0.3, 0.2), -4, color)
	for _, s in { -1, 1 } do
		local edge = CFrame.lookAt(mid, b) * CFrame.new(s * (width / 2 + 0.4), -0.1, 0)
		Parts.block(
			ctx.props,
			"StreamBank",
			Vector3.new(1.4, 0.6, len + 1),
			edge,
			rgb(150, 132, 104),
			{ collide = false, query = false }
		)
	end
end

-- Gradual hand-over: `n` picks of a neighbouring zone (its palette) on the banks / plateau edge in this zone's
-- first (atStart) or last 16 studs, so palettes and props blend instead of switching at the boundary line.
function Valley.blend(ctx: Ctx, pick: Pick, palette: Kit.Palette, atStart: boolean, n: number)
	local rng = ctx.rng
	for i = 1, n do
		local side = if i % 2 == 0 then 1 else -1
		local x = side * rng:NextNumber(INNER + 8, INNER + 50)
		local z = if atStart then rng:NextNumber(ctx.z0 + 2, ctx.z0 + 16) else rng:NextNumber(ctx.z1 - 16, ctx.z1 - 2)
		local name, scale = choose(ctx, pick)
		Valley.put(ctx, ctx.nature, name, x, z, scale, nil, palette)
	end
end

Valley.INNER = INNER
Valley.HALF = HALF
Valley.FAR_X = FAR_X
return Valley
