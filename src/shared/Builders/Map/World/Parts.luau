--!strict
-- Partner A. Native-part helpers for the world builders: studded blocks (classic Roblox studs only where we ask
-- for them: paths, plinths, platforms, borders), smooth blocks, cylinders, invisible collision proxies, anchors,
-- lights and SurfaceGui text.
local Parts = {}

export type Opts = {
	studs: boolean?, -- (default) classic studs on the top and sides, inlets underneath
	sideStuds: boolean?, -- kept for old callers: same as the default
	smooth: boolean?, -- SmoothPlastic, no studs (water sheets, signs, invisible helpers)
	collide: boolean?, -- default true
	query: boolean?, -- default = collide
	transparency: number?,
	material: Enum.Material?, -- a non-Plastic material is always smooth (Neon, Glass...)
	reflect: number?,
	shadow: boolean?,
}

local STUDS, INLET, SMOOTH = Enum.SurfaceType.Studs, Enum.SurfaceType.Inlet, Enum.SurfaceType.Smooth

function Parts.block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, o: Opts?): Part
	local opts: Opts = o or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	local studded = not opts.smooth and (opts.material == nil or opts.material == Enum.Material.Plastic)
	p.Material = if studded then Enum.Material.Plastic else (opts.material or Enum.Material.SmoothPlastic)
	if studded then
		p.TopSurface, p.BottomSurface = STUDS, INLET
		p.FrontSurface, p.BackSurface, p.LeftSurface, p.RightSurface = STUDS, STUDS, STUDS, STUDS
	else
		p.TopSurface, p.BottomSurface = SMOOTH, SMOOTH
	end
	p.CanCollide = if opts.collide == nil then true else opts.collide
	p.CanQuery = if opts.query == nil then p.CanCollide else opts.query
	p.CanTouch = false
	p.Transparency = opts.transparency or 0
	p.Reflectance = opts.reflect or 0
	if opts.shadow == false then
		p.CastShadow = false
	end
	p.Parent = parent
	return p
end

-- Upright cylinder (Roblox cylinders run along X) with its base at `base`.
function Parts.cyl(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	base: Vector3,
	color: Color3,
	o: Opts?
): Part
	local p = Parts.block(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(base + Vector3.new(0, height / 2, 0)) * UP,
		color,
		o
	)
	p.Shape = Enum.PartType.Cylinder
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	return p
end

-- Invisible collision proxy: stops characters (and eggs unless `noEggs`), invisible to raycasts and the camera.
function Parts.proxy(parent: Instance, name: string, size: Vector3, cf: CFrame): Part
	local p =
		Parts.block(parent, name, size, cf, Color3.new(1, 1, 1), { transparency = 1, query = false, smooth = true })
	p.CastShadow = false
	return p
end

-- Invisible, non-colliding anchor for emitters / lights / tutorial targets.
function Parts.anchor(parent: Instance, name: string, size: Vector3, pos: Vector3): Part
	local p = Parts.block(
		parent,
		name,
		size,
		CFrame.new(pos),
		Color3.new(1, 1, 1),
		{ transparency = 1, collide = false, query = false, smooth = true }
	)
	p.CastShadow = false
	return p
end

function Parts.light(part: BasePart, color: Color3, range: number, brightness: number?, shadows: boolean?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1
	l.Shadows = shadows == true
	l.Parent = part
	return l
end

-- SurfaceGui text lines: { name, text, yScale, hScale, color?, bar colour? }
function Parts.text(part: BasePart, face: Enum.NormalId, lines: { { any } }, pixelsPerStud: number?): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud or 20
	gui.LightInfluence = 0
	for _, line in lines do
		local l = Instance.new("TextLabel")
		l.Name = line[1]
		l.Text = line[2]
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.06, line[3])
		l.Size = UDim2.fromScale(0.88, line[4])
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = line[5] or Color3.new(1, 1, 1)
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Parent = l
		if line[6] then
			l.BackgroundTransparency = 0
			l.BackgroundColor3 = line[6]
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0.2, 0)
			c.Parent = l
			local b = Instance.new("UIStroke")
			b.Thickness = 3
			b.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			b.Parent = l
		end
		l.Parent = gui
	end
	gui.Parent = part
	return gui
end

function Parts.folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

return Parts
