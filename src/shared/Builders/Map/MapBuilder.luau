--!strict
-- Partner A. Builds the whole map from Config (call once on server start, or from the command bar):
--   require(game.ReplicatedStorage.Shared.Builders.Map.MapBuilder).build()
-- Layout follows the world axes in Config/Chase: kick pad at the origin, safe line at Z = SafeLineZ,
-- the safe zone with up to 8 player bases at Z < SafeLineZ, and the 20 zone strips along +Z.
--
-- Stable names for Partner B:
--   workspace.Map.KickPad                         Part; players stand on it (top at y = MapBuilder.KickPadTop)
--   workspace.Map.SafeZone.Bases.Base<i>          Model, attribute BaseIndex = i (1..8)
--     .SpawnPoint                                 invisible Part where the owner (re)spawns
--     .Sign.Board.SurfaceGui.OwnerLabel           TextLabel: set Text to the owner's name
--     .Pedestals.Pedestal<n>                      Model, attribute Slot = n (1 = closest to the aisle),
--                                                 PrimaryPart = Top (egg sits at Top.Position + up * 0.15)
--   workspace.Map.Runway.Zone<id>                 Folder per zone (ground, walls, arch, props)
local Builder = require(script.Parent.Parent.BlockBuilder)
local Props = require(script.Parent.Props)
local Config = script.Parent.Parent.Parent.Config
local Chase = require(Config.Chase)
local Zones = require(Config.Zones)
local Economy = require(Config.Economy)

local MapBuilder = {}

local STUD_TEXTURE = "rbxassetid://6372755229" -- same studs as BlockBuilder
local HALF = Chase.RunwayWidth / 2
local SAFE_Z = Chase.SafeLineZ
local FIELD = 56 -- grass field beside the runway walls, per side
local EDGE = HALF + FIELD -- outer edge of the playable area (x = ±EDGE)
local SAFE_DEPTH = 140 -- safe zone runs from Z = SafeLineZ back to SafeLineZ - SAFE_DEPTH
local BASE_COUNT = 8
local BASE_X, BASE_W, BASE_D = 48, 40, 28
local BASE_ROWS = { -26, -58, -90, -122 }
local PROP_BAND = { 15, 20.5 } -- |x| range for runway props: outside the middle 24 studs
MapBuilder.KickPadTop = 0.5

local rgb = Color3.fromRGB
local BASE_COLORS = {
	rgb(255, 85, 85),
	rgb(255, 160, 50),
	rgb(255, 215, 60),
	rgb(90, 210, 90),
	rgb(60, 200, 220),
	rgb(70, 130, 255),
	rgb(170, 100, 255),
	rgb(255, 120, 200),
}

type BlockOpts = {
	material: Enum.Material?,
	studs: boolean?,
	collide: boolean?,
	transparency: number?,
	shape: Enum.PartType?,
}

local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, o: BlockOpts?): Part
	local opts: BlockOpts = o or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.material or Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide = if opts.collide == nil then true else opts.collide
	p.Transparency = opts.transparency or 0
	if opts.shape then
		p.Shape = opts.shape
	end
	if opts.studs ~= false and not opts.shape and p.Material == Enum.Material.SmoothPlastic and p.Transparency < 1 then
		local t = Instance.new("Texture")
		t.Texture = STUD_TEXTURE
		t.Face = Enum.NormalId.Top
		t.StudsPerTileU, t.StudsPerTileV = 1, 1
		t.Transparency = 0.6
		t.Parent = p
	end
	p.Parent = parent
	return p
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- SurfaceGui with a big title and an optional small subtitle, Fredoka + thick stroke.
local function signText(part: BasePart, face: Enum.NormalId, title: string, subtitle: string?, labelName: string?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	-- TextScaled caps at 100 px, so big surfaces get fewer pixels per stud to let the title fill them.
	-- (A Top-face gui's vertical axis is the part's X; side faces use Y.)
	local faceHeight = if face == Enum.NormalId.Top then part.Size.X else part.Size.Y
	local titleFrac = if subtitle then 0.58 else 0.76
	gui.PixelsPerStud = math.min(40, 95 / (faceHeight * titleFrac))
	gui.LightInfluence = 0
	local function label(name: string, text: string, y: number, h: number)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.05, y)
		l.Size = UDim2.fromScale(0.9, h)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.Text = text
		local s = Instance.new("UIStroke")
		s.Thickness = 4
		s.Parent = l
		l.Parent = gui
	end
	if subtitle then
		label("Subtitle", subtitle, 0.06, 0.3)
		label(labelName or "Title", title, 0.36, 0.58)
	else
		label(labelName or "Title", title, 0.12, 0.76)
	end
	gui.Parent = part
end

-- Builds a BlockBuilder spec as static, non-colliding scenery (no root, welds or motors).
local function stamp(spec: Builder.Spec, cf: CFrame, scale: number, parent: Instance)
	local m = Builder.build(spec, "Prop")
	if scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
		elseif d:IsA("WeldConstraint") or d:IsA("Motor6D") then
			d:Destroy()
		end
	end
	if m.PrimaryPart then
		m.PrimaryPart:Destroy()
	end
	m.Parent = parent
end

local function buildKickPad(map: Instance)
	local up = CFrame.Angles(0, 0, math.rad(90)) -- cylinders are X-axis; stand them up
	block(
		map,
		"KickPadRim",
		Vector3.new(0.3, 13, 13),
		CFrame.new(0, 0.15, 0) * up,
		rgb(45, 45, 60),
		{ shape = Enum.PartType.Cylinder }
	)
	local pad = block(map, "KickPad", Vector3.new(0.5, 11, 11), CFrame.new(0, 0.25, 0) * up, rgb(255, 215, 60), {
		shape = Enum.PartType.Cylinder,
	})
	pad:SetAttribute("Top", MapBuilder.KickPadTop)
	-- Neon arrow pointing down the runway (+Z)
	local glow = { material = Enum.Material.Neon, collide = false }
	block(map, "ArrowShaft", Vector3.new(1.4, 0.1, 4), CFrame.new(0, 0.52, -0.8), rgb(255, 120, 40), glow)
	block(
		map,
		"ArrowHead",
		Vector3.new(2.8, 0.1, 2.8),
		CFrame.new(0, 0.52, 1.6) * CFrame.Angles(0, math.rad(45), 0),
		rgb(255, 120, 40),
		glow
	)
end

local function buildSafeLine(map: Instance)
	local line = folder(map, "SafeLine")
	local tiles = 20
	local w = (2 * EDGE) / tiles
	for i = 1, tiles do
		local x = -EDGE + (i - 0.5) * w
		for row = 0, 1 do
			local white = (i + row) % 2 == 0
			block(
				line,
				"Tile",
				Vector3.new(w, 0.1, 1),
				CFrame.new(x, 0.05, SAFE_Z - 0.5 + row),
				if white then rgb(250, 250, 250) else rgb(60, 220, 110),
				{ studs = false, collide = false }
			)
		end
	end
	-- "SAFE ZONE" painted on the ground, readable while running back toward -Z.
	-- A Top-face SurfaceGui runs along the part's Z axis, so the 30-stud side is Z, turned to face X.
	local paintCf = CFrame.new(0, 0.13, SAFE_Z - 7) * CFrame.Angles(0, math.rad(-90), 0)
	local paint = block(line, "Paint", Vector3.new(9, 0.06, 36), paintCf, Color3.new(1, 1, 1), {
		transparency = 1,
		collide = false,
		studs = false,
	})
	signText(paint, Enum.NormalId.Top, "SAFE ZONE")
end

local function buildBase(parent: Instance, i: number)
	local side = if i <= BASE_COUNT / 2 then -1 else 1
	local cx, cz = side * BASE_X, BASE_ROWS[(i - 1) % #BASE_ROWS + 1]
	local inner = side * (BASE_X - BASE_W / 2) -- edge facing the aisle
	local color = BASE_COLORS[i]
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)

	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base:SetAttribute("BaseIndex", i)
	base.Parent = parent

	block(
		base,
		"Floor",
		Vector3.new(BASE_W, 0.4, BASE_D),
		CFrame.new(cx, 0.2, cz),
		color:Lerp(Color3.new(1, 1, 1), 0.45)
	)
	-- Curb with an 8-stud entrance on the aisle side
	local curbH = 0.6
	block(base, "CurbBack", Vector3.new(BASE_W, curbH, 1), CFrame.new(cx, curbH / 2, cz - BASE_D / 2 + 0.5), dark)
	block(base, "CurbFront", Vector3.new(BASE_W, curbH, 1), CFrame.new(cx, curbH / 2, cz + BASE_D / 2 - 0.5), dark)
	block(
		base,
		"CurbOuter",
		Vector3.new(1, curbH, BASE_D),
		CFrame.new(cx + side * (BASE_W / 2 - 0.5), curbH / 2, cz),
		dark
	)
	local seg = (BASE_D - 8) / 2
	for k = -1, 1, 2 do
		block(
			base,
			"CurbInner",
			Vector3.new(1, curbH, seg),
			CFrame.new(inner + side * 0.5, curbH / 2, cz + k * (4 + seg / 2)),
			dark
		)
	end

	-- Pedestals: columns step away from the aisle so slots 1..8 are the most visible.
	local pedestals = folder(base, "Pedestals")
	local rows = { -9, -3, 3, 9 }
	for n = 1, Economy.PlotSlots.max do
		local col, row = (n - 1) // #rows, (n - 1) % #rows + 1
		local x, z = side * (BASE_X - BASE_W / 2 + 10 + col * 6), cz + rows[row]
		local ped = Instance.new("Model")
		ped.Name = "Pedestal" .. n
		ped:SetAttribute("Slot", n)
		block(ped, "Base", Vector3.new(3.6, 0.8, 3.6), CFrame.new(x, 0.8, z), dark)
		ped.PrimaryPart = block(ped, "Top", Vector3.new(2.8, 0.3, 2.8), CFrame.new(x, 1.35, z), rgb(250, 248, 240))
		ped.Parent = pedestals
	end

	-- Name sign facing the aisle
	local sign = Instance.new("Model")
	sign.Name = "Sign"
	local sx, sz = inner - side * 1.5, cz - 9
	for k = -1, 1, 2 do
		block(sign, "Post", Vector3.new(0.6, 5.6, 0.6), CFrame.new(sx, 2.8, sz + k * 4.2), rgb(120, 80, 50))
	end
	local board = block(sign, "Board", Vector3.new(0.6, 3, 10), CFrame.new(sx, 5, sz), color)
	signText(
		board,
		if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left,
		"Empty Base",
		"BASE " .. i,
		"OwnerLabel"
	)
	sign.Parent = base

	-- Mailbox by the entrance
	local mx, mz = inner - side * 1.5, cz + 7
	block(base, "MailPost", Vector3.new(0.4, 2.8, 0.4), CFrame.new(mx, 1.8, mz), rgb(120, 80, 50))
	block(base, "MailBox", Vector3.new(1.8, 1.2, 1.2), CFrame.new(mx, 3.6, mz), rgb(60, 120, 230))
	block(
		base,
		"MailFlagPole",
		Vector3.new(0.15, 1.1, 0.15),
		CFrame.new(mx - side * 0.4, 4.4, mz + 0.7),
		rgb(80, 80, 80)
	)
	block(base, "MailFlag", Vector3.new(0.15, 0.5, 0.6), CFrame.new(mx - side * 0.4, 4.75, mz + 1.05), rgb(240, 50, 50))

	block(base, "SpawnPoint", Vector3.new(2, 1, 2), CFrame.new(inner + side * 3, 3, cz), Color3.new(1, 1, 1), {
		transparency = 1,
		collide = false,
		studs = false,
	})
end

local function buildSafeZone(map: Instance)
	local zone = folder(map, "SafeZone")
	local depth = SAFE_DEPTH - SAFE_Z -- ground also covers SafeLineZ..0 in front of the kick pad
	block(zone, "Grass", Vector3.new(2 * EDGE, 2, depth), CFrame.new(0, -1, -depth / 2), rgb(110, 200, 80))
	block(
		zone,
		"Path",
		Vector3.new(Chase.RunwayWidth, 0.1, SAFE_DEPTH),
		CFrame.new(0, 0.05, SAFE_Z - SAFE_DEPTH / 2),
		rgb(235, 215, 160),
		{
			collide = false,
		}
	)
	local hedge = rgb(60, 150, 55)
	local back = SAFE_Z - SAFE_DEPTH
	block(zone, "HedgeBack", Vector3.new(2 * EDGE, 4, 2), CFrame.new(0, 2, back + 1), hedge)
	for k = -1, 1, 2 do
		block(zone, "HedgeSide", Vector3.new(2, 4, depth), CFrame.new(k * (EDGE - 1), 2, -depth / 2), hedge)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 0.2, 8)
	spawn.CFrame = CFrame.new(0, 0.1, SAFE_Z - 24)
	spawn.Color = rgb(250, 250, 250)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Parent = zone

	local bases = folder(zone, "Bases")
	for i = 1, BASE_COUNT do
		buildBase(bases, i)
	end
end

local function buildArch(parent: Instance, zone: Zones.Zone)
	local z = zone.start
	local dark = zone.accent:Lerp(Color3.new(0, 0, 0), 0.3)
	local x = HALF + 2.5
	for k = -1, 1, 2 do
		block(parent, "Pillar", Vector3.new(2.4, 16, 2.4), CFrame.new(k * x, 8, z), zone.accent)
		block(parent, "PillarCap", Vector3.new(3.2, 1, 3.2), CFrame.new(k * x, 0.5, z), dark)
	end
	block(parent, "Beam", Vector3.new(2 * x + 2.4, 2.6, 2.4), CFrame.new(0, 17.3, z), dark)
	block(parent, "Glow", Vector3.new(2 * x - 2.4, 0.3, 0.6), CFrame.new(0, 15.85, z), zone.accent, {
		material = Enum.Material.Neon,
		collide = false,
	})
	local board = block(parent, "Board", Vector3.new(30, 6, 0.8), CFrame.new(0, 21.6, z), zone.accent)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		signText(board, face, string.upper(zone.name), "ZONE " .. zone.id)
	end
end

local function buildZone(parent: Instance, zone: Zones.Zone)
	local f = folder(parent, "Zone" .. zone.id)
	local z0, len = zone.start, zone.length
	local mid = z0 + len / 2
	local rng = Random.new(zone.id * 7919)
	local field = zone.ground:Lerp(Color3.new(0, 0, 0), 0.12)

	block(f, "Lane", Vector3.new(Chase.RunwayWidth, 2, len), CFrame.new(0, -1, mid), zone.ground)
	for k = -1, 1, 2 do
		block(f, "Field", Vector3.new(FIELD, 2, len), CFrame.new(k * (HALF + FIELD / 2), -1, mid), field)
		block(f, "Wall", Vector3.new(1, 2.5, len), CFrame.new(k * (HALF + 0.5), 1.25, mid), zone.accent)
		block(
			f,
			"WallCap",
			Vector3.new(1.6, 0.4, len),
			CFrame.new(k * (HALF + 0.5), 2.7, mid),
			zone.accent:Lerp(Color3.new(1, 1, 1), 0.3)
		)
		block(f, "Barrier", Vector3.new(1, 40, len), CFrame.new(k * (EDGE + 0.5), 20, mid), Color3.new(1, 1, 1), {
			transparency = 1,
			studs = false,
		})
	end
	-- Painted patches on the lane for a bricky, hand-laid look
	local patch = zone.ground:Lerp(zone.accent, 0.18)
	for _ = 1, 4 do
		local s = rng:NextInteger(5, 9)
		local cf = CFrame.new(rng:NextNumber(-HALF + 5, HALF - 5), 0.03, z0 + rng:NextNumber(8, len - 8))
		block(
			f,
			"Patch",
			Vector3.new(s, 0.06, s),
			cf * CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 15), 0),
			patch,
			{
				collide = false,
			}
		)
	end
	if zone.id > 1 then -- zone 1's start line is the kick pad
		block(
			f,
			"StartLine",
			Vector3.new(Chase.RunwayWidth, 0.08, 1.2),
			CFrame.new(0, 0.04, z0),
			zone.accent,
			{ collide = false }
		)
	end
	buildArch(f, zone)

	-- Props: 4 on the runway edges (|x| in PROP_BAND) + 4 bigger ones out in the fields.
	local kinds = Props.forZone(zone.id)
	local props = folder(f, "Props")
	for k = 0, 3 do
		local sideSign = if k % 2 == 0 then -1 else 1
		local z = z0 + 15 + k * 30 + rng:NextNumber(-6, 6)
		local yaw = CFrame.Angles(0, math.rad(rng:NextInteger(0, 7) * 45), 0)
		local x = sideSign * rng:NextNumber(PROP_BAND[1], PROP_BAND[2])
		stamp(kinds[k % #kinds + 1], CFrame.new(x, 0, z) * yaw, rng:NextNumber(0.85, 1.1), props)
		local fx = -sideSign * rng:NextNumber(HALF + 10, EDGE - 8)
		stamp(kinds[(k + 1) % #kinds + 1], CFrame.new(fx, 0, z + 12) * yaw, rng:NextNumber(1.6, 2.2), props)
	end
end

-- Builds (or rebuilds) workspace.Map. Returns the Map model.
function MapBuilder.build(): Model
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	local map = Instance.new("Model")
	map.Name = "Map"

	buildKickPad(map)
	buildSafeLine(map)
	buildSafeZone(map)
	local runway = folder(map, "Runway")
	for _, zone in Zones do
		buildZone(runway, zone)
	end
	local last = Zones[#Zones]
	local endZ = last.start + last.length
	block(map, "EndWall", Vector3.new(2 * EDGE, 40, 2), CFrame.new(0, 20, endZ + 1), last.accent)

	map.Parent = workspace
	return map
end

return MapBuilder
