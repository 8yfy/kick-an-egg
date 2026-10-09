--!strict
-- CONTRACT FILE (API). Turns a block table into a Model. Used for every egg, pet and prop.
--
-- Spec format:
--   {
--     size = 1,                         -- optional global scale
--     parts = {
--       { name = "Body", size = {4,4,4}, pos = {0,2,0}, rot = {0,0,0},
--         color = Color3.., material = "SmoothPlastic"|"Neon"|"Glass"|..., shape = "Block"|"Wedge"|"Ball"|"Cylinder",
--         studs = true, transparency = 0, joint = "Root"|"LegL"|... (rig group), light = Color3? },
--     },
--   }
-- Parts sharing a `joint` are welded together; each joint group is attached to Root with a
-- Motor6D named after the group, so animators tween `Motor6D.C0` per group.

local STUD_TEXTURE = "rbxassetid://6372755229" -- generic studs; swap if needed
local Builder = {}

export type PartSpec = {
	name: string?,
	size: { number },
	pos: { number },
	rot: { number }?,
	color: Color3,
	material: string?,
	shape: string?,
	studs: boolean?,
	transparency: number?,
	joint: string?,
	light: Color3?,
}
export type Spec = { size: number?, parts: { PartSpec } }

local function v3(t: { number }, s: number): Vector3
	return Vector3.new(t[1] * s, t[2] * s, t[3] * s)
end

local function makePart(p: PartSpec, s: number): BasePart
	local part: BasePart
	if p.shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local bp = Instance.new("Part")
		if p.shape == "Ball" then
			bp.Shape = Enum.PartType.Ball
		elseif p.shape == "Cylinder" then
			bp.Shape = Enum.PartType.Cylinder
		end
		part = bp
	end
	part.Name = p.name or "Block"
	part.Size = v3(p.size, s)
	part.Color = p.color
	part.Material = (Enum.Material :: any)[p.material or "SmoothPlastic"]
	part.Transparency = p.transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.Anchored = false
	part.CastShadow = true
	if p.studs ~= false and part.Material == Enum.Material.SmoothPlastic then
		local tex = Instance.new("Texture")
		tex.Texture = STUD_TEXTURE
		tex.Face = Enum.NormalId.Top
		tex.StudsPerTileU, tex.StudsPerTileV = 1, 1
		tex.Transparency = 0.55
		tex.Parent = part
	end
	if p.light then
		local l = Instance.new("PointLight")
		l.Color = p.light
		l.Range = 8 * s
		l.Brightness = 1.5
		l.Parent = part
	end
	return part
end

function Builder.build(spec: Spec, name: string?): Model
	local s = spec.size or 1
	local model = Instance.new("Model")
	model.Name = name or "Built"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root

	local groups: { [string]: BasePart } = {}
	for _, p in spec.parts do
		local part = makePart(p, s)
		local cf = CFrame.new(v3(p.pos, s))
		if p.rot then
			cf *= CFrame.Angles(math.rad(p.rot[1]), math.rad(p.rot[2]), math.rad(p.rot[3]))
		end
		part.CFrame = root.CFrame * cf
		part.Parent = model

		local g = p.joint or "Root"
		local anchor = groups[g]
		if g == "Root" then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = root, part
			w.Parent = part
		elseif anchor == nil then
			groups[g] = part
			local m = Instance.new("Motor6D")
			m.Name = g
			m.Part0, m.Part1 = root, part
			m.C0 = root.CFrame:ToObjectSpace(part.CFrame)
			m.Parent = root
		else
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = anchor, part
			w.Parent = part
		end
	end
	return model
end

-- Scale an already-built model (size mutations). Keeps the Root's pivot on the ground.
function Builder.scale(model: Model, factor: number)
	model:ScaleTo(model:GetScale() * factor)
end

return Builder
