--!strict
-- Partner A. The world asset kit: classic studded brick models built from recipes (World/Recipes, using the
-- World/Brick primitives), cached once as templates, then cloned, scaled and coloured by role from a palette.
-- Every model is a Model of native parts named by colour role (Trunk, Leaf, LeafDark, Stone, Ground, Roof, Glow...)
-- with its pivot at its base centre and its front facing -Z, so one recipe serves every zone with a different
-- palette. Kit parts never collide, never take touches and never block raycasts (gameplay geometry is separate).
local Recipes = require(script.Parent.Recipes)
local Brick = require(script.Parent.Brick)
local Coplanar = require(script.Parent.Coplanar)

-- coplanar faces inside a recipe are pushed this far apart (scaled with the asset when placed)
local TEMPLATE_EPS = 0.12

local Kit = {}

export type Look = Color3 | { color: Color3, material: Enum.Material?, transparency: number?, reflect: number? }
export type Palette = { [string]: Look }
export type Opts = { shadow: boolean?, noRecolor: boolean?, name: string? }

local rgb = Color3.fromRGB
local PLASTIC = Enum.Material.Plastic

-- Default role looks (overridden per zone by Palettes.luau)
local BASE: Palette = {
	Trunk = rgb(124, 82, 52),
	Leaf = rgb(92, 182, 66),
	LeafDark = rgb(56, 140, 56),
	LeafLight = rgb(150, 214, 88),
	Stone = rgb(168, 164, 158),
	StoneDark = rgb(126, 122, 118),
	Ground = rgb(104, 192, 68),
	Dirt = rgb(176, 112, 70),
	Wood = rgb(182, 122, 72),
	WoodDark = rgb(124, 80, 48),
	Wall = rgb(246, 238, 220),
	WallTop = rgb(246, 238, 220),
	Trim = rgb(252, 244, 222),
	Roof = rgb(214, 58, 52),
	RoofDark = rgb(160, 38, 36),
	Roof2 = rgb(250, 246, 240),
	Cloth = rgb(222, 52, 58),
	Cloth2 = rgb(252, 250, 246),
	Metal = rgb(78, 82, 96),
	Gold = { color = rgb(255, 196, 46), reflect = 0.1 },
	Glow = { color = rgb(255, 226, 150), material = Enum.Material.Neon },
	Lava = { color = rgb(255, 112, 24), material = Enum.Material.Neon },
	Neon = { color = rgb(255, 60, 200), material = Enum.Material.Neon },
	Neon2 = { color = rgb(60, 230, 255), material = Enum.Material.Neon },
	Neon3 = { color = rgb(255, 230, 60), material = Enum.Material.Neon },
	Hologram = { color = rgb(120, 240, 255), material = Enum.Material.Glass, transparency = 0.45 },
	Ghost = { color = rgb(236, 248, 255), material = Enum.Material.SmoothPlastic, transparency = 0.3 },
	Brew = { color = rgb(140, 255, 60), material = Enum.Material.Neon },
	Moss = rgb(110, 150, 70),
	Gear = rgb(214, 160, 60),
	Pipe = rgb(196, 112, 70),
	Pipe2 = rgb(150, 156, 170),
	Clock = { color = rgb(252, 244, 220), material = Enum.Material.SmoothPlastic },
	Core = { color = rgb(255, 150, 40), material = Enum.Material.Glass, transparency = 0.45 },
	Energy = { color = rgb(170, 110, 255), material = Enum.Material.Neon, transparency = 0.35 },
	Planet = rgb(120, 90, 220),
	Planet2 = rgb(90, 150, 240),
	Ring = rgb(220, 200, 255),
	Moon = rgb(230, 230, 246),
	Cloud = rgb(255, 255, 255),
	Cloud2 = rgb(236, 242, 255),
	R1 = rgb(240, 70, 70),
	R2 = rgb(255, 150, 50),
	R3 = rgb(255, 222, 70),
	R4 = rgb(90, 210, 100),
	R5 = rgb(70, 150, 240),
	R6 = rgb(160, 100, 230),
	Glass = { color = rgb(170, 220, 255), material = Enum.Material.Glass, transparency = 0.3 },
	Water = { color = rgb(70, 170, 240), material = Enum.Material.Glass, transparency = 0.25 },
	Foam = rgb(236, 248, 255),
	Snow = rgb(246, 250, 255),
	Ice = { color = rgb(170, 225, 250), material = Enum.Material.Glass, transparency = 0.15 },
	Crystal = { color = rgb(120, 220, 255), material = Enum.Material.Glass, transparency = 0.1 },
	Sign = rgb(40, 44, 58),
	Accent = rgb(80, 170, 255),
	Accent2 = rgb(255, 120, 170),
	Accent3 = rgb(150, 230, 100),
	Cap = rgb(226, 56, 56),
	Spot = rgb(252, 250, 246),
	Stem = rgb(246, 232, 204),
	Sand = rgb(242, 216, 150),
	Dark = rgb(48, 50, 62),
}

local cache: { [string]: Model } = {}

local function seedOf(name: string): number
	local h = 7
	for i = 1, #name do
		h = (h * 31 + string.byte(name, i)) % 2147483647
	end
	return h
end

-- The template for `name` (built once from its recipe), or nil when there is no recipe.
local function template(name: string): Model?
	local t = cache[name]
	if t then
		return t
	end
	local recipe = Recipes[name]
	if not recipe then
		return nil
	end
	local m = Brick.new(name)
	recipe(m, Random.new(seedOf(name)))
	Coplanar.separate(m, TEMPLATE_EPS, { childrenOnly = true }) -- no z-fighting inside any asset
	local cf, size = m:GetBoundingBox()
	m:SetAttribute("Size", size)
	m:SetAttribute("Centre", cf.Position)
	m.WorldPivot = CFrame.new()
	cache[name] = m
	return m
end

-- True when a recipe exists for the asset.
function Kit.has(name: string): boolean
	return Recipes[name] ~= nil
end

-- The asset's bounding size at scale 1 (X, Y up, Z).
function Kit.size(name: string): Vector3
	local t = template(name)
	local s = t and t:GetAttribute("Size")
	return if typeof(s) == "Vector3" then s else Vector3.one
end

local function lookFor(role: string, palette: Palette?): Look?
	local found = palette and palette[role]
	if found == nil then
		local key = string.gsub(role, "%d+$", "")
		found = (palette and palette[key]) or BASE[role] or BASE[key]
	end
	return found
end

local function paint(p: BasePart, look: Look?)
	if look == nil then
		return
	end
	if typeof(look) == "Color3" then
		p.Color = look
		p.Material = PLASTIC
		return
	end
	local l = look :: any
	p.Color = l.color
	p.Material = l.material or PLASTIC
	p.Transparency = l.transparency or 0
	p.Reflectance = l.reflect or 0
end

-- Recolour an already placed asset (or any model of kit parts) with a palette.
function Kit.paint(model: Instance, palette: Palette?)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			paint(d, lookFor(d.Name, palette))
		end
	end
end

-- A part's size under a world-axis scale `s` (exact for unturned parts, close for turned ones).
local function scaled(rel: CFrame, size: Vector3, s: Vector3): Vector3
	local function k(v: Vector3): number
		return math.sqrt((v.X * s.X) ^ 2 + (v.Y * s.Y) ^ 2 + (v.Z * s.Z) ^ 2)
	end
	return size * Vector3.new(k(rel.RightVector), k(rel.UpVector), k(rel.LookVector))
end

local warned: { [string]: boolean } = {}

-- Clones asset `name` at `cf` (its base centre), scaled by `scale` (a number, or per-axis X/Y/Z), coloured by
-- `palette`, into `parent`. Returns nil (with one warning) when there is no recipe.
function Kit.place(
	parent: Instance,
	name: string,
	cf: CFrame,
	scale: (number | Vector3)?,
	palette: Palette?,
	opts: Opts?
): Model?
	local t = template(name)
	if not t then
		if not warned[name] then
			warned[name] = true
			warn(`[World.Kit] no recipe for {name}`)
		end
		return nil
	end
	local m = t:Clone()
	local s: Vector3 = if typeof(scale) == "Vector3"
		then scale
		elseif typeof(scale) == "number" then Vector3.one * scale
		else Vector3.one
	local o: Opts = opts or {}
	local uniform = s.X == s.Y and s.Y == s.Z
	for _, d in m:GetChildren() do
		if d:IsA("BasePart") then
			local rel = d.CFrame -- template space (the template sits at the origin)
			if s ~= Vector3.one then
				d.Size = if uniform then d.Size * s.X else scaled(rel, d.Size, s)
				d.CFrame = cf * (CFrame.new(rel.Position * s) * rel.Rotation)
			else
				d.CFrame = cf * rel
			end
			if not o.noRecolor then
				paint(d, lookFor(d.Name, palette))
			end
			if o.shadow == false then
				d.CastShadow = false
			end
		end
	end
	if o.name then
		m.Name = o.name
	end
	m.WorldPivot = cf
	m.Parent = parent
	return m
end

-- Base centre of an asset standing at (x, y, z) turned `yaw` degrees around Y.
function Kit.at(x: number, y: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

Kit.BASE = BASE
return Kit
