--!strict
-- Partner A. The hub's look (world remodel, classic brick style 2026-10-16), built at plaza level 0 inside
-- workspace.Map.SafeZone and lifted with it by MapBuilder. Every gameplay object (pens, shop, stand, wheel, boards,
-- spawn, safe line, kick pad) keeps its MapBuilder position and name; this adds the village around them:
--   * Paths: studded pale stone with darker borders: the spine from the launch plaza to pen 5, walks to the four
--     side pen gates, the shop and the stand; a round (octagonal) plaza with the Golden Egg centrepiece fountain.
--   * Terraces: raised grass terraces with brick retaining walls and stairs (walkable, safe heights) in the four
--     corners, carrying town houses, a gazebo and a well; a row of houses along the back wall.
--   * Boundary: one plain, thick, closed dirt wall with grass on top along both sides and the back, from the sea
--     to WALL_H above the lawn, so nobody can look out of the hub; the front edge (toward the valley) is a low
--     balustrade so the plaza overlooks the track.
--   * Greenery: tree groves (some on knolls), hedges along the spine, flower beds, benches and lamps.
-- Nothing goes in the pen reserves, on paths, at the spawn or in front of the wheel / boards. Decorative pieces
-- never collide; walkable terraces and stairs do, and trees, lamps, houses and hedges get invisible proxies.
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Kit)
local Parts = require(script.Parent.Parts)
local Palettes = require(script.Parent.Palettes)
local Fx = require(script.Parent.Fx)

local Hub = {}

export type Ctx = {
	halfWidth: number, -- W: the hub's inner half width (the wall's inner face at x = +-W)
	depth: number, -- the hub runs from z = 0 to z = -depth
	sea: number, -- the ocean surface, relative to the lawn (the wall starts there)
	inner: number, -- canyon half width at the mouth (x = +-inner)
	pens: { Vector3 }, -- pen centres (y = 0)
	reserve: Vector2, -- largest pen size (+ margin), for keep-outs
	penDirs: { Vector3 },
	plaza: Vector3, -- centre of the round plaza
	shop: Vector3,
	stand: Vector3,
	spawn: Vector3,
}

local rgb = Color3.fromRGB
local PAL = Palettes.hub
local PATH = rgb(238, 226, 200)
local PATH_EDGE = rgb(196, 176, 142)
local PLAZA_A = rgb(246, 236, 214)
local PLAZA_B = rgb(222, 200, 164)
local BRICK = rgb(198, 120, 86) -- terrace retaining walls
local BRICK_CAP = rgb(236, 222, 196)
local GRASS = rgb(108, 198, 70)
local WALL_DIRT = rgb(156, 104, 64) -- the hub wall: plain thick dirt with a grass top
local WALL_H = 46 -- above the lawn: higher than the leaderboards, so nothing pokes over it but the Prize Wheel
local WALL_T = 12 -- thickness, outward from the lawn edge
local WALL_GRASS = 2 -- the grass slab on top
local WALL_LIP = 0.6 -- the grass overhangs the dirt this much on both sides
local WALL_FRONT = 2 -- the side walls run this far past the hub's front edge, closing the corner

type Box = { cx: number, cz: number, hx: number, hz: number }

local function inBox(boxes: { Box }, x: number, z: number, pad: number): boolean
	for _, b in boxes do
		if math.abs(x - b.cx) < b.hx + pad and math.abs(z - b.cz) < b.hz + pad then
			return true
		end
	end
	return false
end

-- A straight studded path from a to b (on the ground), with darker borders.
local function path(parent: Instance, a: Vector3, b: Vector3, width: number)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b)
	Parts.block(parent, "Path", Vector3.new(width, 0.3, len), cf * CFrame.new(0, 0.15, 0), PATH)
	for _, s in { -1, 1 } do
		Parts.block(
			parent,
			"PathEdge",
			Vector3.new(1, 0.4, len),
			cf * CFrame.new(s * (width / 2 + 0.5), 0.2, 0),
			PATH_EDGE,
			{
				collide = false,
			}
		)
	end
end

-- A flat octagonal pad (three crossed studded blocks, tops 0.04 apart so nothing z-fights), walkable.
local function octPad(parent: Instance, name: string, d: number, h: number, c: Vector3, color: Color3)
	Parts.block(parent, name, Vector3.new(d * 0.64, h, d), CFrame.new(c + Vector3.new(0, h / 2, 0)), color)
	Parts.block(
		parent,
		name,
		Vector3.new(d, h - 0.04, d * 0.64),
		CFrame.new(c + Vector3.new(0, (h - 0.04) / 2, 0)),
		color
	)
	Parts.block(
		parent,
		name,
		Vector3.new(d * 0.66, h - 0.08, d * 0.66),
		CFrame.new(c + Vector3.new(0, (h - 0.08) / 2, 0)) * CFrame.Angles(0, math.rad(45), 0),
		color
	)
end

local function lampAt(parent: Instance, proxies: Instance, pos: Vector3, yaw: number)
	local m = Kit.place(parent, "LampPost", Kit.at(pos.X, pos.Y, pos.Z, yaw), 1, PAL)
	if m then
		local glow = m:FindFirstChild("Glow")
		if glow and glow:IsA("BasePart") then
			Parts.light(glow, rgb(255, 214, 150), 16, 0.9)
		end
	end
	Parts.proxy(proxies, "LampProxy", Vector3.new(1.4, 10, 1.4), CFrame.new(pos + Vector3.new(0, 5, 0)))
end

local function sway(m: Model?, rng: Random)
	if m then
		m:SetAttribute("Amp", rng:NextNumber(0.6, 1.1))
		m:SetAttribute("Speed", rng:NextNumber(0.18, 0.28))
		CollectionService:AddTag(m, "WorldSway")
	end
end

local TREES =
	{ "TreeRoundA", "TreeRoundB", "TreeRoundC", "TreeBallA", "TreeBallC", "TreeRoundD", "TreeBallB", "TreeTallA" }
local GROUND_COVER = { "BushA", "BushB", "BushC", "BushFlowerA", "FlowersA", "FlowersB" }

-- A deliberate tree cluster: one hero tree, smaller ones around it, bushes and flowers at the feet, a rock;
-- optionally on a low stepped grass knoll.
local function grove(
	parent: Instance,
	proxies: Instance,
	c: Vector3,
	rng: Random,
	radius: number,
	n: number,
	knoll: boolean?
)
	local base = c.Y
	if knoll then
		Kit.place(
			parent,
			"HillC",
			Kit.at(c.X, c.Y - 1.0, c.Z, rng:NextNumber(0, 360)),
			Vector3.new(radius / 14, 0.42, radius / 14),
			PAL
		)
		base += 1.6
	end
	for i = 1, n do
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = if i == 1 then 0 else radius * rng:NextNumber(0.55, 1)
		local p = Vector3.new(c.X + math.cos(ang) * r, 0, c.Z + math.sin(ang) * r)
		local s = if i == 1 then rng:NextNumber(1.6, 1.9) else rng:NextNumber(1.1, 1.4)
		local y = if r < radius * 0.6 then base else c.Y + (base - c.Y) * 0.4
		sway(
			Kit.place(parent, TREES[rng:NextInteger(1, #TREES)], Kit.at(p.X, y, p.Z, rng:NextNumber(0, 360)), s, PAL),
			rng
		)
		Parts.proxy(proxies, "TreeProxy", Vector3.new(2.2 * s, 9 * s, 2.2 * s), CFrame.new(p.X, y + 4.5 * s, p.Z))
	end
	for _ = 1, rng:NextInteger(3, 5) do
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = radius * rng:NextNumber(0.6, 1.3)
		local p = Vector3.new(c.X + math.cos(ang) * r, c.Y, c.Z + math.sin(ang) * r)
		Kit.place(
			parent,
			GROUND_COVER[rng:NextInteger(1, #GROUND_COVER)],
			Kit.at(p.X, p.Y, p.Z, rng:NextNumber(0, 360)),
			rng:NextNumber(1.0, 1.4),
			PAL,
			{ shadow = false }
		)
	end
	if rng:NextNumber() < 0.6 then
		local ang = rng:NextNumber(0, math.pi * 2)
		Kit.place(
			parent,
			({ "RockA", "RockB", "RockC" })[rng:NextInteger(1, 3)],
			Kit.at(c.X + math.cos(ang) * radius * 1.1, c.Y, c.Z + math.sin(ang) * radius * 1.1, rng:NextNumber(0, 360)),
			rng:NextNumber(0.7, 1.0),
			PAL
		)
	end
end

-- A raised terrace: a brick retaining wall block with a grass top, walkable, with stairs on one side.
-- `c` = centre on the ground, `size` = (width X, height, depth Z), `stairs` = direction of the stair side.
-- Returns the centre of its top surface.
local function terrace(parent: Instance, c: Vector3, size: Vector3, stairs: Vector3, stairWidth: number?): Vector3
	local w, h, d = size.X, size.Y, size.Z
	Parts.block(
		parent,
		"TerraceWall",
		Vector3.new(w, h - 0.6, d),
		CFrame.new(c + Vector3.new(0, (h - 0.6) / 2, 0)),
		BRICK
	)
	Parts.block(
		parent,
		"TerraceCap",
		Vector3.new(w + 0.6, 0.4, d + 0.6),
		CFrame.new(c + Vector3.new(0, h - 0.4, 0)),
		BRICK_CAP
	)
	Parts.block(
		parent,
		"TerraceGrass",
		Vector3.new(w - 1.0, 0.6, d - 1.0),
		CFrame.new(c + Vector3.new(0, h - 0.1, 0)),
		GRASS
	)
	local sw = stairWidth or 7
	local steps = math.max(2, math.floor(h / 0.6 + 0.5))
	local rise = h / steps
	local half = if math.abs(stairs.X) > 0.5 then w / 2 else d / 2
	for k = 0, steps - 1 do
		local out = half + 0.6 + (steps - k - 1) * 1.2 + 0.6
		local top = (k + 1) * rise
		local p = c + stairs * out + Vector3.new(0, top / 2, 0)
		local size2 = if math.abs(stairs.X) > 0.5 then Vector3.new(1.2, top, sw) else Vector3.new(sw, top, 1.2)
		Parts.block(parent, "Stair", size2, CFrame.new(p), BRICK_CAP)
	end
	return c + Vector3.new(0, h, 0)
end

function Hub.build(zone: Instance, ctx: Ctx)
	local root = Parts.folder(zone, "HubArt")
	local ground = Parts.folder(root, "Ground")
	local paths = Parts.folder(root, "Paths")
	local nature = Parts.folder(root, "Nature")
	local props = Parts.folder(root, "Props")
	local village = Parts.folder(root, "Village")
	local edges = Parts.folder(root, "Edges")
	local proxies = Parts.folder(root, "Proxies")
	local rng = Random.new(20261016)
	local W, D = ctx.halfWidth, ctx.depth

	-- keep-outs: pen reserves, shop, stand, spawn, plaza, wheel and board fronts, launch plaza
	local keep: { Box } = {}
	for i, c in ctx.pens do
		local dir = ctx.penDirs[i]
		local along = math.abs(dir.X) > 0.5
		local rx = if along then ctx.reserve.Y / 2 + 2 else ctx.reserve.X / 2 + 2
		local rz = if along then ctx.reserve.X / 2 + 2 else ctx.reserve.Y / 2 + 2
		table.insert(
			keep,
			{ cx = c.X + dir.X * 8, cz = c.Z + dir.Z * 8, hx = rx + math.abs(dir.X) * 8, hz = rz + math.abs(dir.Z) * 8 }
		)
	end
	table.insert(keep, { cx = ctx.shop.X, cz = ctx.shop.Z - 4, hx = 20, hz = 22 })
	table.insert(keep, { cx = ctx.stand.X, cz = ctx.stand.Z - 4, hx = 15, hz = 18 })
	table.insert(keep, { cx = ctx.spawn.X, cz = ctx.spawn.Z, hx = 14, hz = 14 })
	table.insert(keep, { cx = ctx.plaza.X, cz = ctx.plaza.Z, hx = 42, hz = 42 })
	table.insert(keep, { cx = W - 20, cz = -155, hx = 22, hz = 30 }) -- Prize Wheel front
	table.insert(keep, { cx = -W + 20, cz = -155, hx = 22, hz = 26 }) -- boards front
	table.insert(keep, { cx = 0, cz = -14, hx = ctx.inner + 4, hz = 16 }) -- launch plaza
	for _, s in { -1, 1 } do -- terraces and the back row of houses
		table.insert(keep, { cx = s * 150, cz = -32, hx = 24, hz = 16 })
		table.insert(keep, { cx = s * 150, cz = -322, hx = 26, hz = 18 })
		table.insert(keep, { cx = s * 81, cz = -372, hx = 26, hz = 10 })
	end

	-- lawn patches: lighter / darker studded squares (turned), flush on the lawn
	for i = 1, 30 do
		local x, z = rng:NextNumber(-W + 20, W - 20), rng:NextNumber(-D + 20, -20)
		if not inBox(keep, x, z, 0) then
			local s = rng:NextNumber(8, 16)
			local col = if i % 2 == 0 then rgb(118, 206, 76) else rgb(96, 182, 62)
			Parts.block(
				ground,
				"LawnPatch",
				Vector3.new(s, 0.1, s * rng:NextNumber(0.6, 1)),
				CFrame.new(x, 0.05, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0),
				col,
				{
					collide = false,
					shadow = false,
				}
			)
		end
	end

	-- paths: launch plaza, spine, round plaza, side walks
	Parts.block(paths, "LaunchPlaza", Vector3.new(2 * ctx.inner, 0.3, 18), CFrame.new(0, 0.15, -15), PATH)
	for _, s in { -1, 1 } do
		Parts.block(
			paths,
			"LaunchPlazaEdge",
			Vector3.new(1, 0.4, 18),
			CFrame.new(s * (ctx.inner + 0.5), 0.2, -15),
			PATH_EDGE,
			{
				collide = false,
			}
		)
	end
	path(paths, Vector3.new(0, 0, -24), Vector3.new(0, 0, ctx.plaza.Z + 38), 20)
	path(paths, Vector3.new(0, 0, ctx.plaza.Z - 38), Vector3.new(0, 0, -D + 118), 20)
	octPad(paths, "PlazaRing", 82, 0.3, ctx.plaza, PLAZA_B)
	octPad(paths, "PlazaInner", 76, 0.42, ctx.plaza, PLAZA_A)
	octPad(paths, "PlazaBand", 52, 0.54, ctx.plaza, PLAZA_B)
	for i, c in ctx.pens do
		local dir = ctx.penDirs[i]
		if math.abs(dir.X) > 0.5 then -- side pens: a walk from the spine to the gate
			path(paths, Vector3.new(dir.X * -10, 0, c.Z), Vector3.new(c.X + dir.X * (ctx.reserve.Y / 2), 0, c.Z), 14)
		end
	end
	path(paths, Vector3.new(-10, 0, -46), Vector3.new(ctx.shop.X - 6, 0, -46), 12)
	path(paths, Vector3.new(ctx.shop.X, 0, -40), Vector3.new(ctx.shop.X, 0, -52), 14)
	path(paths, Vector3.new(10, 0, -46), Vector3.new(ctx.stand.X + 6, 0, -46), 12)
	path(paths, Vector3.new(ctx.stand.X, 0, -40), Vector3.new(ctx.stand.X, 0, -52), 14)

	-- the Golden Egg centrepiece (its pool rim is low enough for the tutorial trail to pen 5 to read over it)
	local CS = 1.45
	local pc = ctx.plaza + Vector3.new(0, 0.54, 0)
	if Kit.place(props, "EggCenterpiece", Kit.at(pc.X, pc.Y, pc.Z, 0), CS, PAL) then
		Fx.fountain(props, pc, CS)
	end
	local R = 15.5 * CS + 1
	for i = 0, 7 do
		local a = math.rad(i * 45)
		Parts.proxy(
			proxies,
			"PoolRim",
			Vector3.new(2.4, 3, 2 * R * math.tan(math.pi / 8) + 1),
			CFrame.new(pc + Vector3.new(math.cos(a) * R, 1.5, math.sin(a) * R)) * CFrame.Angles(0, -a, 0)
		)
	end
	Parts.proxy(proxies, "CentreCore", Vector3.new(9 * CS, 30, 9 * CS), CFrame.new(pc + Vector3.new(0, 15, 0)))
	-- benches facing the fountain between flower planters, a ring of lamps on the outer band
	local beds = { "FlowersA", "FlowersB", "BushFlowerA", "FlowersB" }
	for k = 0, 7 do
		local a = math.rad(22.5 + k * 45)
		local p = ctx.plaza + Vector3.new(math.cos(a) * 31.5, 0.42, math.sin(a) * 31.5)
		local face = CFrame.lookAt(p, Vector3.new(ctx.plaza.X, p.Y, ctx.plaza.Z))
		if k % 2 == 0 then
			if math.abs(p.X) > 10 then
				Kit.place(props, "Bench", face * CFrame.Angles(0, math.pi, 0), 1, PAL)
				Parts.proxy(proxies, "BenchProxy", Vector3.new(6, 2, 2), face + Vector3.new(0, 1, 0))
			end
		else
			Kit.place(props, "Planter", face, 1.1, PAL)
			Kit.place(props, beds[(k + 1) // 2], CFrame.new(p + Vector3.new(0, 1.9, 0)), 1.4, PAL, { shadow = false })
			Parts.proxy(proxies, "PlanterProxy", Vector3.new(6.6, 2, 3.3), face + Vector3.new(0, 1, 0))
		end
	end
	for k = 0, 7 do
		local a = math.rad(k * 45)
		local p = ctx.plaza + Vector3.new(math.cos(a) * 39.5, 0.3, math.sin(a) * 39.5)
		if math.abs(p.X) > 12 then
			lampAt(props, proxies, p, k * 45)
		end
	end
	for _, z in { -40, -96, -122, -190, -236 } do
		for _, s in { -1, 1 } do
			lampAt(props, proxies, Vector3.new(s * 13, 0, z), 0)
		end
	end
	-- hedges along the spine (in short runs, gaps at the junctions), with flowers at their ends
	for _, run in { { -54, -86 }, { -198, -204 }, { -218, -232 }, { -248, -268 } } do
		for _, s in { -1, 1 } do
			local z = run[1]
			while z > run[2] - 1 do
				Kit.place(nature, "Hedge", Kit.at(s * 17.5, 0, z - 4, 90), 1, PAL)
				Parts.proxy(proxies, "HedgeProxy", Vector3.new(2.2, 3, 8), CFrame.new(s * 17.5, 1.5, z - 4))
				z -= 8.2
			end
			Kit.place(
				nature,
				({ "FlowersA", "FlowersB" })[rng:NextInteger(1, 2)],
				Kit.at(s * 17.5, 0, run[1] + 1.5, rng:NextNumber(0, 90)),
				1.2,
				PAL,
				{ shadow = false }
			)
		end
	end

	-- launch plaza dressing: banners on poles at the corners (clear of the pad and the drop)
	for _, s in { -1, 1 } do
		Kit.place(props, "FlagPole", Kit.at(s * (ctx.inner - 3), 0.3, -22, if s < 0 then 0 else 180), 1, PAL)
	end

	-- village: terraces in the corners with houses, a gazebo and a well; a row of houses along the back
	local function houseProxy(c: Vector3, yaw: number, size: Vector3)
		Parts.proxy(
			proxies,
			"HouseProxy",
			size,
			CFrame.new(c + Vector3.new(0, size.Y / 2, 0)) * CFrame.Angles(0, math.rad(yaw), 0)
		)
	end
	for _, s in { -1, 1 } do
		-- front corner terrace, a town house facing the spine
		local top = terrace(village, Vector3.new(s * 150, 0, -32), Vector3.new(40, 2.4, 28), Vector3.new(-s, 0, 0), 8)
		local yaw = if s < 0 then -90 else 90
		Kit.place(
			village,
			if s < 0 then "TownHouseA" else "TownHouseB",
			Kit.at(s * 158, top.Y, -36, yaw),
			1,
			Palettes.houses[if s < 0 then 1 else 2]
		)
		houseProxy(Vector3.new(s * 158, top.Y, -36), yaw, Vector3.new(14, 16, 12))
		lampAt(props, proxies, Vector3.new(s * 133, top.Y, -22), 0)
		Kit.place(village, "Planter", Kit.at(s * 140, top.Y, -44, 90), 0.9, PAL)
		Kit.place(village, "FlowersB", Kit.at(s * 140, top.Y + 1.5, -44, 0), 1.2, PAL, { shadow = false })
		-- back corner: a two-level terrace with a gazebo (left) / a house (right), a well and a bench
		local low = terrace(village, Vector3.new(s * 150, 0, -322), Vector3.new(44, 2.4, 32), Vector3.new(-s, 0, 0), 8)
		local high =
			terrace(village, Vector3.new(s * 158, low.Y, -328), Vector3.new(26, 2.4, 18), Vector3.new(0, 0, 1), 6)
		if s < 0 then
			Kit.place(village, "Gazebo", Kit.at(s * 158, high.Y, -331, 0), 0.85, PAL)
			Parts.proxy(proxies, "GazeboCore", Vector3.new(2, 10, 2), CFrame.new(s * 158, high.Y + 5, -331))
		else
			Kit.place(village, "TownHouseA", Kit.at(s * 160, high.Y, -333, 180), 0.85, Palettes.houses[4])
			houseProxy(Vector3.new(s * 160, high.Y, -333), 180, Vector3.new(12, 14, 10))
		end
		Kit.place(village, "Well", Kit.at(s * 138, low.Y, -312, 20), 1, PAL)
		Parts.proxy(proxies, "WellProxy", Vector3.new(5, 3, 5), CFrame.new(s * 138, low.Y + 1.5, -312))
		Kit.place(village, "Bench", Kit.at(s * 140, low.Y, -334, if s < 0 then 90 else -90), 1, PAL)
		grove(nature, proxies, Vector3.new(s * 165, low.Y, -312), rng, 4, 2, false)
		-- the back row of houses, facing the hub
		for k, x in { 64, 98 } do
			local kind = if (k + (if s > 0 then 1 else 0)) % 2 == 0 then "TownHouseA" else "TownHouseB"
			Kit.place(
				village,
				kind,
				Kit.at(s * x, 0, -374, 0),
				1,
				Palettes.houses[(k + (if s > 0 then 2 else 0)) % 4 + 1]
			)
			houseProxy(
				Vector3.new(s * x, 0, -374),
				0,
				if kind == "TownHouseA" then Vector3.new(14, 16, 12) else Vector3.new(10, 20, 10)
			)
			Kit.place(village, "Planter", Kit.at(s * x + 9, 0, -366, 0), 0.8, PAL)
			Kit.place(
				village,
				({ "FlowersA", "BushFlowerA" })[k],
				Kit.at(s * x + 9, 1.5, -366, 0),
				1.1,
				PAL,
				{ shadow = false }
			)
		end
		lampAt(props, proxies, Vector3.new(s * 81, 0, -364), 0)
	end

	-- the hub wall: one plain, thick, closed dirt wall with grass on top along both sides and the back. Its inner face
	-- is the lawn edge (x = +-W, z = -D: the wheel and the boards stand right against it), it rises from the sea to
	-- WALL_H above the lawn and runs WALL_FRONT past the front edge, so there is no gap anywhere to look out through.
	-- It collides and stops the camera (CanQuery), so the camera never swings outside either. The front stays open.
	-- The back grass covers the corners; the side grass starts where it ends, so no two grass tops overlap.
	local T, g, o = WALL_T, WALL_GRASS, WALL_LIP
	local top, bottom = WALL_H, ctx.sea
	local dy, dh = (top - g + bottom) / 2, top - g - bottom
	local gy = top - g / 2
	Parts.block(
		edges,
		"HubWall",
		Vector3.new(2 * (W + T), dh, T),
		CFrame.new(0, dy, -D - T / 2),
		WALL_DIRT,
		{ query = true }
	)
	Parts.block(
		edges,
		"HubWallGrass",
		Vector3.new(2 * (W + T + o), g, T + 2 * o),
		CFrame.new(0, gy, -D - T / 2),
		GRASS,
		{ query = true }
	)
	for _, s in { -1, 1 } do
		local z0, z1 = -D, WALL_FRONT -- from the back wall's inner face to past the front edge
		Parts.block(
			edges,
			"HubWall",
			Vector3.new(T, dh, z1 - z0),
			CFrame.new(s * (W + T / 2), dy, (z0 + z1) / 2),
			WALL_DIRT,
			{ query = true }
		)
		local gz0, gz1 = -D + o, z1 + o
		Parts.block(
			edges,
			"HubWallGrass",
			Vector3.new(T + 2 * o, g, gz1 - gz0),
			CFrame.new(s * (W + T / 2), gy, (gz0 + gz1) / 2),
			GRASS,
			{ query = true }
		)
	end
	-- front edge over the valley: a low studded balustrade with posts and lanterns
	for _, s in { -1, 1 } do
		local x0, x1 = s * (ctx.inner + 0.1), s * W
		local len = math.abs(x1 - x0)
		local cx = (x0 + x1) / 2
		Parts.block(edges, "Balustrade", Vector3.new(len, 3, 2.4), CFrame.new(cx, 1.5, -1.2), rgb(226, 206, 168))
		Parts.block(edges, "BalustradeCap", Vector3.new(len, 0.8, 3.2), CFrame.new(cx, 3.4, -1.2), rgb(246, 236, 214))
		Parts.proxy(proxies, "FrontBarrier", Vector3.new(len, 30, 2), CFrame.new(cx, 18, -1.2))
		local n = math.floor(len / 18)
		for k = 0, n do
			local x = x0 + s * (k / n) * len
			Parts.block(
				edges,
				"BalustradePost",
				Vector3.new(2.6, 4.6, 3.6),
				CFrame.new(x, 2.3, -1.2),
				rgb(206, 186, 150)
			)
			if k % 2 == 1 then
				Kit.place(edges, "Lantern", Kit.at(x, 4.6, -1.2), 1, PAL)
			end
		end
	end

	-- groves: along the walls and in the open lawns (some on knolls), filtered by the keep-outs
	local spots = { -- x, z, radius, trees, knoll
		{ -176, -76, 8, 3, false },
		{ 176, -80, 8, 3, false },
		{ -108, -24, 8, 2, true },
		{ 112, -22, 8, 2, true },
		{ -174, -112, 7, 2, false },
		{ 172, -236, 9, 3, false },
		{ -172, -236, 9, 3, false },
		{ -58, -268, 10, 3, true },
		{ 60, -262, 10, 3, true },
		{ -112, -290, 9, 3, true },
		{ 112, -292, 9, 3, true },
		{ -132, -366, 8, 3, false },
		{ 136, -366, 8, 3, false },
		{ -170, -360, 8, 2, false },
		{ 170, -360, 8, 2, false },
		{ -152, -268, 7, 2, false },
		{ 154, -264, 7, 2, false },
		{ -44, -116, 6, 1, false },
		{ 46, -198, 6, 1, false },
		{ -176, -200, 6, 2, false },
		{ 176, -110, 6, 2, false },
	}
	for _, s in spots do
		local c = Vector3.new(s[1], 0, s[2])
		if not inBox(keep, c.X, c.Z, s[3] * 0.4) then
			grove(nature, proxies, c, rng, s[3], s[4], s[5])
		end
	end
	-- grass tufts and flowers sprinkled on the lawns
	for _ = 1, 40 do
		local x, z = rng:NextNumber(-W + 10, W - 10), rng:NextNumber(-D + 12, -12)
		if not inBox(keep, x, z, 2) and math.abs(x) > 14 then
			local kind = ({ "GrassA", "GrassB", "GrassA", "FlowersA" })[rng:NextInteger(1, 4)]
			Kit.place(
				nature,
				kind,
				Kit.at(x, 0, z, rng:NextNumber(0, 360)),
				rng:NextNumber(0.9, 1.3),
				PAL,
				{ shadow = false }
			)
		end
	end
	-- props by the shop and stand walks
	Kit.place(props, "Signpost", Kit.at(-16, 0.3, -52, 0), 1, PAL)
	Kit.place(props, "Barrel", Kit.at(ctx.shop.X - 20, 0, ctx.shop.Z - 16, 20), 1, PAL)
	Kit.place(props, "Crate", Kit.at(ctx.shop.X - 22, 0, ctx.shop.Z - 11, 10), 1, PAL)
	Kit.place(props, "Crate", Kit.at(ctx.stand.X + 18, 0, ctx.stand.Z - 14, -15), 0.9, PAL)
	Kit.place(props, "Barrel", Kit.at(ctx.stand.X + 19, 0, ctx.stand.Z - 9, 40), 1, PAL)

	Fx.hubAmbient(root, ctx)
end

return Hub
