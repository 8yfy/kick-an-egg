--!strict
-- Partner A. Classic brick primitives for the world's model recipes (World/Recipes): every piece is a native
-- Plastic part with studs on the top and sides and inlets underneath (old-school Roblox), except the smooth roles
-- (glass, water, neon glow, ice, signs). Round shapes are voxel crosses of studded blocks (no balls / cylinders).
-- Parts are named by their colour role (Kit recolours them per zone) and never collide, touch or block raycasts:
-- gameplay geometry is separate. Recipes build in asset space: origin = base centre, +Y up, front = -Z.
local Brick = {}

local STUDS, INLET, SMOOTH = Enum.SurfaceType.Studs, Enum.SurfaceType.Inlet, Enum.SurfaceType.Smooth

-- Roles rendered smooth (no studs): see-through, glowing or text-bearing surfaces.
Brick.SMOOTH = {
	Glass = true,
	Water = true,
	Glow = true,
	Ice = true,
	Crystal = true,
	Sign = true,
	Neon = true,
	Lava = true,
	Hologram = true,
	Ghost = true,
	Brew = true,
	Clock = true,
	Core = true,
	Energy = true,
}

local function finish(p: BasePart, role: string)
	p.Name = role
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Plastic
	if Brick.SMOOTH[string.gsub(role, "%d+$", "")] then
		p.TopSurface, p.BottomSurface = SMOOTH, SMOOTH
		p.FrontSurface, p.BackSurface, p.LeftSurface, p.RightSurface = SMOOTH, SMOOTH, SMOOTH, SMOOTH
	else
		p.TopSurface, p.BottomSurface = STUDS, INLET
		p.FrontSurface, p.BackSurface, p.LeftSurface, p.RightSurface = STUDS, STUDS, STUDS, STUDS
	end
end

local function rot(yaw: number?, pitch: number?, roll: number?): CFrame
	return CFrame.Angles(0, math.rad(yaw or 0), 0) * CFrame.Angles(math.rad(pitch or 0), 0, math.rad(roll or 0))
end
Brick.rot = rot

function Brick.new(name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	return m
end

-- A block centred at (x, y, z), turned yaw / pitch / roll degrees.
function Brick.box(
	m: Instance,
	role: string,
	size: Vector3,
	x: number,
	y: number,
	z: number,
	yaw: number?,
	pitch: number?,
	roll: number?
): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = CFrame.new(x, y, z) * rot(yaw, pitch, roll)
	finish(p, role)
	p.Parent = m
	return p
end

-- A block standing on (x, y, z) (its bottom centre); the turn pivots on that base.
function Brick.on(
	m: Instance,
	role: string,
	size: Vector3,
	x: number,
	y: number,
	z: number,
	yaw: number?,
	pitch: number?,
	roll: number?
): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = CFrame.new(x, y, z) * rot(yaw, pitch, roll) * CFrame.new(0, size.Y / 2, 0)
	finish(p, role)
	p.Parent = m
	return p
end

-- A block at an arbitrary CFrame.
function Brick.at(m: Instance, role: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	finish(p, role)
	p.Parent = m
	return p
end

-- Roblox wedge: the high edge is at the back (+Z), the slope runs down to the front (-Z). `cf` = centre.
function Brick.wedge(m: Instance, role: string, size: Vector3, cf: CFrame): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	finish(p, role)
	p.Parent = m
	return p
end

function Brick.corner(m: Instance, role: string, size: Vector3, cf: CFrame): CornerWedgePart
	local p = Instance.new("CornerWedgePart")
	p.Size = size
	p.CFrame = cf
	finish(p, role)
	p.Parent = m
	return p
end

-- Upright voxel cylinder of height h and diameter d standing on (x, y, z): two crossed blocks, plus a 45-degree
-- one when it is wide (an octagon outline).
function Brick.round(m: Instance, role: string, h: number, d: number, x: number, y: number, z: number, yaw: number?)
	local a = yaw or 0
	if d < 2.6 then
		Brick.on(m, role, Vector3.new(d * 0.86, h, d * 0.86), x, y, z, a)
		return
	end
	Brick.on(m, role, Vector3.new(d * 0.64, h, d), x, y, z, a)
	Brick.on(m, role, Vector3.new(d, h - 0.04, d * 0.64), x, y, z, a)
	if d >= 10 then
		Brick.on(m, role, Vector3.new(d * 0.66, h - 0.08, d * 0.66), x, y, z, a + 45)
	end
end

-- A voxel cylinder lying along local X (logs, hay bales, barrels on their side) centred at (x, y, z).
function Brick.log(m: Instance, role: string, len: number, d: number, x: number, y: number, z: number, yaw: number?)
	local base = CFrame.new(x, y, z) * rot(yaw)
	Brick.at(m, role, Vector3.new(len, d * 0.64, d), base)
	Brick.at(m, role, Vector3.new(len - 0.04, d, d * 0.64), base)
end

-- Voxel blob (ellipsoid) of size w x h x d centred at (x, y, z): a core and three arms.
function Brick.blob(
	m: Instance,
	role: string,
	w: number,
	h: number,
	d: number,
	x: number,
	y: number,
	z: number,
	yaw: number?
)
	local a = yaw or 0
	Brick.box(m, role, Vector3.new(w * 0.8, h * 0.78, d * 0.8), x, y, z, a)
	Brick.box(m, role, Vector3.new(w, h * 0.5, d * 0.56), x, y, z, a)
	Brick.box(m, role, Vector3.new(w * 0.56, h, d), x, y, z, a)
end

-- Stepped dome / cone: `steps` stacked voxel rounds shrinking from d0 to d1 over height h, standing on (x, y, z).
function Brick.stack(
	m: Instance,
	role: string,
	d0: number,
	d1: number,
	h: number,
	steps: number,
	x: number,
	y: number,
	z: number,
	yaw: number?,
	roleAlt: string?
)
	local sh = h / steps
	for i = 0, steps - 1 do
		local t = if steps > 1 then i / (steps - 1) else 0
		local d = d0 + (d1 - d0) * t
		Brick.round(
			m,
			if roleAlt and i % 2 == 1 then roleAlt else role,
			sh + 0.02,
			d,
			x,
			y + i * sh,
			z,
			(yaw or 0) + i * 12
		)
	end
end

-- Voxel egg (wide base, rounded top) of width w and height h standing on (x, y, z).
function Brick.egg(m: Instance, role: string, w: number, h: number, x: number, y: number, z: number)
	local layers = if h >= 6
		then {
			{ 0.0, 0.55 },
			{ 0.07, 0.82 },
			{ 0.18, 0.96 },
			{ 0.32, 1.0 },
			{ 0.47, 0.95 },
			{ 0.61, 0.84 },
			{ 0.74, 0.68 },
			{ 0.85, 0.48 },
			{ 0.94, 0.26 },
		}
		else { { 0.0, 0.62 }, { 0.12, 0.92 }, { 0.3, 1.0 }, { 0.52, 0.9 }, { 0.72, 0.68 }, { 0.88, 0.38 } }
	for i, l in layers do
		local nxt = layers[i + 1]
		local lh = ((if nxt then nxt[1] else 1) - l[1]) * h
		Brick.round(m, role, lh + 0.02, w * l[2], x, y + l[1] * h, z, i * 15)
	end
end

-- Arc of blocks (an arch / vault rib) around `center` in its local XY plane from angle a0 to a1 (radians, 0 = +X,
-- pi/2 = up), `segments` blocks of thickness (radial, depth).
function Brick.arc(
	m: Instance,
	role: string,
	center: CFrame,
	radius: number,
	a0: number,
	a1: number,
	segments: number,
	thick: Vector2,
	roleAlt: string?
)
	local step = (a1 - a0) / segments
	local len = 2 * radius * math.sin(math.abs(step) / 2) + 0.3
	for i = 0, segments - 1 do
		local a = a0 + (i + 0.5) * step
		local cf = center * CFrame.Angles(0, 0, a) * CFrame.new(radius, 0, 0)
		Brick.at(m, if roleAlt and i % 2 == 1 then roleAlt else role, Vector3.new(thick.X, len, thick.Y), cf)
	end
end

return Brick
