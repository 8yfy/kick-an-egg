--!strict
-- Small helpers for hand-built scenery (landmarks, merchants, the launch hub): anchored parts in
-- the classic studded brick look. Positions are CFrames so callers can build in local space:
--   local at = function(x, y, z) return origin * CFrame.new(x, y, z) end
local Bricks = {}

export type Opts = {
	material: Enum.Material?,
	shape: ("Block" | "Ball" | "Cylinder" | "Wedge" | "CornerWedge")?,
	collide: boolean?,
	transparency: number?,
	studs: boolean?,
	reflect: number?,
}

-- Cylinders stand up (Roblox cylinders run along X).
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

function Bricks.part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, o: Opts?): BasePart
	local opts: Opts = o or {}
	local shape = opts.shape or "Block"
	local p: BasePart
	if shape == "Wedge" then
		p = Instance.new("WedgePart")
	elseif shape == "CornerWedge" then
		p = Instance.new("CornerWedgePart")
	else
		local part = Instance.new("Part")
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
		p = part
	end
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.material or Enum.Material.Plastic
	p.CanCollide = if opts.collide == nil then true else opts.collide
	p.CanTouch = false
	p.Transparency = opts.transparency or 0
	p.Reflectance = opts.reflect or 0
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if p.Material == Enum.Material.Plastic and shape == "Block" and opts.studs ~= false then
		p.TopSurface = Enum.SurfaceType.Studs
	end
	p.Parent = parent
	return p
end

-- Upright cylinder: `cf` is its centre.
function Bricks.cyl(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	cf: CFrame,
	color: Color3,
	o: Opts?
): BasePart
	local opts: Opts = table.clone(o or {})
	opts.shape = "Cylinder"
	return Bricks.part(parent, name, Vector3.new(height, diameter, diameter), cf * UPRIGHT, color, opts)
end

function Bricks.ball(parent: Instance, name: string, diameter: number, cf: CFrame, color: Color3, o: Opts?): BasePart
	local opts: Opts = table.clone(o or {})
	opts.shape = "Ball"
	return Bricks.part(parent, name, Vector3.one * diameter, cf, color, opts)
end

-- Neon, non-colliding accent.
function Bricks.glow(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, shape: string?): BasePart
	return Bricks.part(parent, name, size, cf, color, {
		material = Enum.Material.Neon,
		collide = false,
		shape = shape :: any,
	})
end

function Bricks.light(part: BasePart, color: Color3, range: number, brightness: number?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1
	l.Parent = part
	return l
end

function Bricks.fire(part: BasePart, color: Color3?, size: number?): Fire
	local f = Instance.new("Fire")
	f.Color = color or Color3.fromRGB(255, 140, 40)
	f.SecondaryColor = (color or Color3.fromRGB(255, 140, 40)):Lerp(Color3.fromRGB(255, 230, 120), 0.6)
	f.Size = size or 5
	f.Heat = 9
	f.Parent = part
	return f
end

-- Arc of blocks from angle a0 to a1 (radians, 0 = +X, pi/2 = up) around `center` in its XY plane.
function Bricks.arc(
	parent: Instance,
	name: string,
	center: CFrame,
	radius: number,
	a0: number,
	a1: number,
	segments: number,
	thick: Vector2,
	color: Color3,
	o: Opts?
)
	local step = (a1 - a0) / segments
	local len = 2 * radius * math.sin(math.abs(step) / 2) + 0.4
	for i = 0, segments - 1 do
		local a = a0 + (i + 0.5) * step
		local cf = center * CFrame.Angles(0, 0, a) * CFrame.new(radius, 0, 0)
		Bricks.part(parent, name, Vector3.new(thick.X, len, thick.Y), cf, color, o)
	end
end

function Bricks.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

return Bricks
