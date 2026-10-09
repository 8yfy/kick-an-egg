--!strict
-- Partner A. Builds the whole map from Config (once on server start, or from the command bar):
--   require(game.ReplicatedStorage.Shared.Builders.Map.MapBuilder).build()
-- Layout (Config/Chase axes): a compact grass plaza (the safe zone, Z < SafeLineZ) on a cliff above the
-- ocean, walled on three sides by plain studded dirt walls; the runway canyon leaves the plaza's wall at
-- the kick pad (origin) and runs +Z through the 20 zones. 8 fenced pens in two rows face a middle avenue
-- (fountain), each with a kick-training station beside its entrance; Shop/Index stalls by the spawn.
-- No zone signs: the HUD's zone bar names zones. Every part butts against its neighbours (no coplanar
-- overlaps), so nothing z-fights.
--
-- Stable names for Partner B:
--   workspace.Map.KickPad                         Part; players stand on it (top at y = MapBuilder.KickPadTop)
--   workspace.Map.SafeZone.Bases.Base<i>          Model, attribute BaseIndex = i (1..8). The server may set
--                                                 OwnerUserId / RackLevel / PenLevel (Config/Upgrades).
--     .SpawnPoint                                 invisible Part where the owner (re)spawns
--     .Sign.Board.SurfaceGui.OwnerLabel           TextLabel with the owner's name
--     .Pedestals.Pedestal<n>                      invisible egg spot on the open pen floor: attribute Slot = n,
--                                                 PrimaryPart = Top (egg sits at Top.Position + up * 0.15)
--     .TrainingRack                               Model with Plate (stand here) and Bag
--   workspace.Map.Runway.Zone<id>                 Folder per zone
-- ProximityPrompts carry an "Action" attribute the client UI handles:
--   "UpgradePen" | "UpgradeTraining" | "OpenMenu:Store" | "OpenMenu:Index"
local Builder = require(script.Parent.Parent.BlockBuilder)
local Props = require(script.Parent.Props)
local TrainingRack = require(script.Parent.TrainingRack)
local MapFx = require(script.Parent.MapFx)
local Config = script.Parent.Parent.Parent.Config
local Chase = require(Config.Chase)
local Zones = require(Config.Zones)
local Economy = require(Config.Economy)
local Upgrades = require(Config.Upgrades)
local Fx = require(script.Parent.Parent.Parent.VFX.Fx)

local MapBuilder = {}

local HALF = Chase.RunwayWidth / 2
local SAFE_Z = Chase.SafeLineZ
local INNER = 40 -- canyon floor half-width
local W = 170 -- plaza half-width
local DEPTH = 200 -- plaza runs from z = 0 to z = -DEPTH (open cliff edge)
local WALL_T, WALL_H = 24, 50
local CLIFF = 40 -- plaza height above the ocean
local PEN_W, PEN_D = 52, 44
local PROP_BAND = { 15, 20.5 }
MapBuilder.KickPadTop = 0.5

local rgb = Color3.fromRGB
local DIRT = rgb(205, 130, 80)
local GRASS, GRASS_DARK = rgb(120, 215, 75), rgb(104, 196, 64)
local YELLOW = rgb(255, 220, 80)
local SHIELD_ICON = "rbxassetid://77216163319959"
local SIGN = rgb(32, 38, 52)
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
-- Pens: back row flanks the canyon mouth (entrances face -Z), front row faces it across the avenue.
type PenSlot = { cx: number, zE: number, out: number }
local PENS: { PenSlot } = {
	{ cx = -136, zE = -56, out = -1 },
	{ cx = -76, zE = -56, out = -1 },
	{ cx = 76, zE = -56, out = -1 },
	{ cx = 136, zE = -56, out = -1 },
	{ cx = -99, zE = -100, out = 1 },
	{ cx = -33, zE = -100, out = 1 },
	{ cx = 33, zE = -100, out = 1 },
	{ cx = 99, zE = -100, out = 1 },
}

type River = { color: Color3, material: Enum.Material?, transparency: number? }
local WATER: River = { color = rgb(80, 170, 240), transparency = 0.15 }
local RIVERS: { [number]: River | string } = {
	[2] = WATER,
	[3] = WATER,
	[4] = { color = rgb(160, 90, 230), material = Enum.Material.Neon, transparency = 0.3 },
	[6] = { color = rgb(190, 230, 255), material = Enum.Material.Glass, transparency = 0.2 },
	[7] = { color = rgb(120, 70, 40) },
	[8] = WATER,
	[9] = { color = rgb(255, 110, 20), material = Enum.Material.Neon },
	[10] = { color = rgb(110, 240, 255), material = Enum.Material.Neon, transparency = 0.2 },
	[11] = WATER,
	[12] = { color = rgb(255, 40, 200), material = Enum.Material.Neon },
	[13] = { color = rgb(140, 255, 120), material = Enum.Material.Neon, transparency = 0.5 },
	[14] = { color = rgb(255, 255, 255), transparency = 0.1 },
	[15] = { color = rgb(170, 255, 40), material = Enum.Material.Neon, transparency = 0.2 },
	[16] = { color = rgb(60, 55, 50) },
	[17] = { color = rgb(170, 230, 250), material = Enum.Material.Glass, transparency = 0.2 },
	[18] = { color = rgb(255, 150, 30), material = Enum.Material.Neon },
	[19] = { color = rgb(170, 110, 255), material = Enum.Material.Neon, transparency = 0.2 },
	[20] = "rainbow",
}

type BlockOpts = {
	material: Enum.Material?,
	studs: boolean?,
	sideStuds: boolean?,
	collide: boolean?,
	transparency: number?,
	shape: Enum.PartType?,
}

-- Anchored part. Default material gets real Roblox studs (Plastic + Studs surfaces).
local function block(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, o: BlockOpts?): Part
	local opts: BlockOpts = o or {}
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = opts.material or Enum.Material.Plastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CanCollide = if opts.collide == nil then true else opts.collide
	p.Transparency = opts.transparency or 0
	if opts.shape then
		p.Shape = opts.shape
	end
	if p.Material == Enum.Material.Plastic and not opts.shape and opts.studs ~= false then
		p.TopSurface = Enum.SurfaceType.Studs
		if opts.sideStuds then
			p.FrontSurface, p.BackSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Studs
			p.LeftSurface, p.RightSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Studs
		end
	end
	p.Parent = parent
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- cylinders are X-axis; stand them up

local function cylinder(
	parent: Instance,
	name: string,
	height: number,
	diameter: number,
	pos: Vector3,
	color: Color3,
	o: BlockOpts?
): Part
	local opts: BlockOpts = o or {}
	opts.shape = Enum.PartType.Cylinder
	return block(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * UP, color, opts)
end

-- Invisible, non-colliding anchor for emitters/lights.
local function anchor(parent: Instance, name: string, size: Vector3, pos: Vector3): Part
	return block(
		parent,
		name,
		size,
		CFrame.new(pos),
		Color3.new(1, 1, 1),
		{ transparency = 1, collide = false, studs = false }
	)
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- SurfaceGui text lines: { name, text, yScale, hScale, color?, bar color? }
local function surface(part: BasePart, face: Enum.NormalId, lines: { { any } }, pixelsPerStud: number?): SurfaceGui
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

local function stamp(
	spec: Builder.Spec,
	cf: CFrame,
	scale: number,
	parent: Instance,
	collide: boolean?,
	name: string?
): Model
	local m = Builder.build(spec, name or "Prop")
	if scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide == true
			d.CanTouch = false
		elseif d:IsA("WeldConstraint") or d:IsA("Motor6D") then
			d:Destroy()
		end
	end
	if m.PrimaryPart then
		m.PrimaryPart:Destroy()
	end
	m.Parent = parent
	return m
end

local function prompt(parent: BasePart, action: string, text: string, object: string): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = text
	p.ObjectText = object
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p:SetAttribute("Action", action)
	p.Parent = parent
	return p
end

local function setText(gui: Instance?, name: string, text: string)
	local l = gui and gui:FindFirstChild(name)
	if l and l:IsA("TextLabel") then
		l.Text = text
	end
end

------------------------------------------------------------------ walls

-- Plain wall: inner face along the ground line a -> b, `inward` points into the playable area.
-- The body may extend past the face span (extA / extB) to fill corners; the grass cap sits exactly on
-- the body (no overlap with neighbours); drips and the checker stay 3 studs clear of the face ends.
local function wall(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	inward: Vector3,
	face: Color3,
	top: Color3,
	seed: number,
	extA: number?,
	extB: number?
)
	local along = (b - a).Unit
	local len = (b - a).Magnitude
	local ea, eb = extA or 0, extB or 0
	local rot = CFrame.lookAt(Vector3.zero, along)
	local mid = (a + b) / 2 + along * ((eb - ea) / 2) - inward * (WALL_T / 2)
	local bodyLen = len + ea + eb
	block(
		parent,
		"Wall",
		Vector3.new(WALL_T, WALL_H, bodyLen),
		CFrame.new(mid + Vector3.new(0, WALL_H / 2, 0)) * rot,
		face,
		{ sideStuds = true }
	)
	block(
		parent,
		"WallCap",
		Vector3.new(WALL_T, 2, bodyLen),
		CFrame.new(mid + Vector3.new(0, WALL_H + 1, 0)) * rot,
		top
	)
	local rng = Random.new(seed)
	local s = 3 + rng:NextNumber(0, 3)
	while true do
		local w = rng:NextNumber(3, 7)
		if s + w > len - 3 then
			break
		end
		local dh = rng:NextNumber(2, 8)
		local p = a + along * (s + w / 2) + inward * 0.5
		block(
			parent,
			"Drip",
			Vector3.new(1, dh, w),
			CFrame.new(p.X, WALL_H - dh / 2 + 0.6, p.Z) * rot,
			top,
			{ studs = false }
		)
		s += w + rng:NextNumber(2, 6)
	end
	-- Two-tone checker on the face (plates 0.2 in front of it, darker squares only)
	local cols, rows = math.max(1, math.floor(len / 25)), 2
	local tw, th = len / cols, WALL_H / rows
	local dark = face:Lerp(Color3.new(0, 0, 0), 0.08)
	for c = 0, cols - 1 do
		for r = 0, rows - 1 do
			if (c + r) % 2 == 0 then
				local p = a + along * ((c + 0.5) * tw) + inward * 0.1
				block(
					parent,
					"Checker",
					Vector3.new(0.2, th, tw),
					CFrame.new(p.X, (r + 0.5) * th, p.Z) * rot,
					dark,
					{ sideStuds = true, collide = false }
				)
			end
		end
	end
end

------------------------------------------------------------------ plaza pieces

local function buildKickPad(map: Instance)
	local sand, sandDark = rgb(240, 215, 160), rgb(215, 185, 125)
	block(map, "HubStep1", Vector3.new(28, 0.2, 18), CFrame.new(0, 0.1, 4), sandDark)
	block(map, "HubStep2", Vector3.new(18, 0.35, 12), CFrame.new(0, 0.175, 1), sand)
	cylinder(map, "KickPadRim", 0.45, 13, Vector3.new(0, 0.225, 0), rgb(45, 45, 60))
	local pad = cylinder(map, "KickPad", 0.5, 11, Vector3.new(0, 0.25, 0), rgb(255, 215, 60))
	pad:SetAttribute("Top", MapBuilder.KickPadTop)
	local glow = { material = Enum.Material.Neon, collide = false }
	block(map, "ArrowShaft", Vector3.new(1.4, 0.1, 4), CFrame.new(0, 0.55, -0.8), rgb(255, 120, 40), glow)
	block(
		map,
		"ArrowHead",
		Vector3.new(2.8, 0.1, 2.8),
		CFrame.new(0, 0.55, 1.6) * CFrame.Angles(0, math.rad(45), 0),
		rgb(255, 120, 40),
		glow
	)
	for i, o in { { -11.5, 0 }, { 11.5, 0 }, { -11.5, 9 }, { 11.5, 9 } } do -- crates sit on step 1 (top 0.2)
		block(
			map,
			"HubCrate" .. i,
			Vector3.new(2, 2, 2),
			CFrame.new(o[1], 1.2, o[2]) * CFrame.Angles(0, math.rad(20 * i), 0),
			rgb(200, 140, 70)
		)
	end
	MapFx.emit(anchor(map, "PadFx", Vector3.new(9, 0.2, 9), Vector3.new(0, 0.6, 0)), "PadRise")
end

local function buildSafeLine(map: Instance)
	local line = folder(map, "SafeLine")
	local tiles = 8
	local w = (2 * INNER) / tiles
	for i = 1, tiles do
		block(
			line,
			"Tile",
			Vector3.new(w, 0.1, 2),
			CFrame.new(-INNER + (i - 0.5) * w, 0.19, SAFE_Z - 1),
			if i % 2 == 0 then rgb(250, 250, 250) else rgb(60, 200, 255),
			{
				collide = false,
			}
		)
	end
	local paint = anchor(line, "Paint", Vector3.new(8, 0.05, 44), Vector3.new(0, 0.2, SAFE_Z - 8))
	paint.CFrame *= CFrame.Angles(0, math.rad(-90), 0) -- reads upright when running back home
	local gui = surface(paint, Enum.NormalId.Top, { { "Title", "SAFE ZONE", 0.1, 0.8 } }, 10)
	local title = gui:FindFirstChild("Title") :: TextLabel
	title.Position, title.Size = UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.6, 0.8)
	for _, x in { 0.02, 0.84 } do -- glossy shield icons either side (assets/ui-icons/Shield.png)
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = SHIELD_ICON
		img.ScaleType = Enum.ScaleType.Fit
		img.Position, img.Size = UDim2.fromScale(x, 0.02), UDim2.fromScale(0.14, 0.96)
		img.Parent = gui
	end
	MapFx.emit(
		anchor(line, "ShimmerFx", Vector3.new(2 * INNER, 0.2, 1), Vector3.new(0, 0.3, SAFE_Z - 1)),
		"SafeShimmer"
	)
end

local function lamp(parent: Instance, pos: Vector3)
	block(parent, "LampBase", Vector3.new(1.6, 0.6, 1.6), CFrame.new(pos + Vector3.new(0, 0.3, 0)), rgb(60, 60, 70))
	block(parent, "LampPole", Vector3.new(0.6, 8, 0.6), CFrame.new(pos + Vector3.new(0, 4.6, 0)), rgb(60, 60, 70))
	local bulb = block(
		parent,
		"LampBulb",
		Vector3.new(1.4, 1.4, 1.4),
		CFrame.new(pos + Vector3.new(0, 9.3, 0)),
		rgb(255, 230, 150),
		{
			material = Enum.Material.Neon,
			collide = false,
		}
	)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 14, 0.8, rgb(255, 220, 150)
	l.Parent = bulb
	MapFx.emit(bulb, "Firefly")
end

-- Market stall; `dir` = +1 faces +Z, -1 faces -Z.
local function stall(
	parent: Instance,
	x: number,
	z: number,
	dir: number,
	title: string,
	colors: { Color3 },
	action: string
)
	local m = Instance.new("Model")
	m.Name = title .. "Stall"
	m.Parent = parent
	local wood = rgb(160, 105, 60)
	block(m, "Floor", Vector3.new(14, 0.4, 10), CFrame.new(x, 0.3, z), rgb(200, 170, 120))
	local counter = block(m, "Counter", Vector3.new(12, 3, 2), CFrame.new(x, 2, z + dir * 3), wood)
	block(m, "CounterTop", Vector3.new(12.6, 0.4, 2.6), CFrame.new(x, 3.7, z + dir * 3), rgb(235, 225, 210))
	for i, c in { rgb(255, 90, 90), rgb(255, 210, 60), rgb(90, 200, 255) } do
		block(
			m,
			"Goods" .. i,
			Vector3.new(1.4, 1.4, 1.4),
			CFrame.new(x - 4 + i * 2, 4.6, z + dir * 3) * CFrame.Angles(0, math.rad(20 * i), 0),
			c
		)
	end
	MapFx.emit(anchor(m, "GoodsFx", Vector3.new(8, 1, 2), Vector3.new(x, 5.6, z + dir * 3)), "StallSparkle")
	for _, ox in { -6, 6 } do
		for _, oz in { -4.5, 4.5 } do
			block(m, "Post", Vector3.new(0.7, 9, 0.7), CFrame.new(x + ox, 5, z + oz), wood)
		end
	end
	for i = 1, 7 do
		local ax = x - 7 + (i - 0.5) * 2
		block(
			m,
			"Awning" .. i,
			Vector3.new(2, 0.4, 11),
			CFrame.new(ax, 9.9, z) * CFrame.Angles(math.rad(dir * 12), 0, 0),
			colors[(i % 2) + 1]
		)
	end
	local board = block(m, "Board", Vector3.new(11, 2.8, 0.5), CFrame.new(x, 11.8, z + dir * 5.6), colors[1])
	surface(
		board,
		if dir > 0 then Enum.NormalId.Back else Enum.NormalId.Front,
		{ { "Title", string.upper(title), 0.08, 0.84 } }
	)
	prompt(counter, action, "Open", title)
end

-- Octagonal studded basin, water, tiered centre column, and VFX: water jet, splashes, sparkles, light.
local function fountain(parent: Instance, c: Vector3)
	local f = folder(parent, "Fountain")
	local R = 10
	local stone, stoneDark = rgb(215, 215, 225), rgb(175, 175, 190)
	cylinder(f, "BasinFloor", 0.4, 2 * R, c + Vector3.new(0, 0.2, 0), stoneDark)
	local water = cylinder(f, "Water", 0.8, 2 * R - 2.6, c + Vector3.new(0, 0.8, 0), rgb(80, 175, 245), {
		material = Enum.Material.Glass,
		transparency = 0.25,
		collide = false,
	})
	local side = 2 * R * math.tan(math.pi / 8)
	for i = 0, 7 do
		local a = i * math.pi / 4
		local p = c + Vector3.new(math.cos(a) * (R - 0.7), 1.2, math.sin(a) * (R - 0.7))
		block(f, "Rim", Vector3.new(1.4, 1.6, side + 0.05), CFrame.new(p) * CFrame.Angles(0, -a, 0), stone)
	end
	cylinder(f, "Pillar", 5, 2.6, c + Vector3.new(0, 2.9, 0), stone)
	cylinder(f, "Bowl", 0.8, 7, c + Vector3.new(0, 5.8, 0), stone)
	cylinder(
		f,
		"BowlWater",
		0.3,
		6,
		c + Vector3.new(0, 6.25, 0),
		rgb(120, 200, 255),
		{ material = Enum.Material.Neon, transparency = 0.2, collide = false }
	)
	cylinder(f, "Spout", 1.4, 1.2, c + Vector3.new(0, 7.1, 0), stoneDark)
	MapFx.emit(anchor(f, "JetFx", Vector3.new(0.6, 0.2, 0.6), c + Vector3.new(0, 7.9, 0)), "FountainJet")
	MapFx.emit(
		anchor(f, "SplashFx", Vector3.new(2 * R - 5, 0.2, 2 * R - 5), c + Vector3.new(0, 1.3, 0)),
		"FountainSplash"
	)
	MapFx.emit(water, "FountainSparkle")
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = rgb(130, 200, 255), 18, 1
	l.Parent = water
end

local function refreshRack(base: Model, slot: CFrame)
	local levels = Upgrades.Rack.levels
	local level = math.clamp((base:GetAttribute("RackLevel") :: number?) or 1, 1, #levels)
	local info = levels[level]
	local rack = base:FindFirstChild("TrainingRack")
	if not (rack and rack:GetAttribute("Tier") == info.tier) then
		if rack then
			rack:Destroy()
		end
		local m = stamp(TrainingRack.spec(info.tier), slot, 1, base, true, "TrainingRack")
		m:SetAttribute("Tier", info.tier)
		local plate = m:FindFirstChild("Plate")
		if plate and plate:IsA("BasePart") then
			plate.CanQuery = true
			m.PrimaryPart = plate
		end
		local board = m:FindFirstChild("SignBoard")
		if board and board:IsA("BasePart") then
			surface(board, Enum.NormalId.Front, { { "Gain", "", 0.08, 0.5, YELLOW }, { "Level", "", 0.6, 0.32 } }, 24)
		end
		for _, n in { "LampL", "LampR" } do
			local lampPart = m:FindFirstChild(n)
			if lampPart and lampPart:IsA("BasePart") then
				MapFx.emit(
					lampPart,
					if info.tier == "Inferno" then "InfernoEmbers" else "LampGlow",
					if info.tier == "Inferno" then nil else lampPart.Color
				)
			end
		end
		rack = m
	end
	local board = rack and rack:FindFirstChild("SignBoard")
	setText(board and board:FindFirstChildOfClass("SurfaceGui"), "Gain", `+{info.gain} Power / kick`)
	setText(board and board:FindFirstChildOfClass("SurfaceGui"), "Level", `Training · Lv {level}`)
	local sign = base:FindFirstChild("RackSign")
	local sgui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	local nextInfo = levels[level + 1]
	setText(sgui, "Level", if nextInfo then `Level {level} > Level {level + 1}` else `Level {level} (MAX)`)
	setText(sgui, "Cost", if nextInfo then `${Fx.formatNumber(nextInfo.cost)}` else "MAXED")
end

local function refreshPen(base: Model)
	local level = math.max(1, (base:GetAttribute("PenLevel") :: number?) or 1)
	local slots = math.min(Economy.PlotSlots.base + (level - 1) * Upgrades.Pen.slotsPerLevel, Economy.PlotSlots.max)
	local maxed = slots >= Economy.PlotSlots.max
	local sign = base:FindFirstChild("PenSign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	setText(gui, "Level", if maxed then `Level {level} (MAX)` else `Level {level} > Level {level + 1}`)
	setText(
		gui,
		"Cost",
		if maxed then "MAXED" else `${Fx.formatNumber(Upgrades.Pen.costBase * Upgrades.Pen.costGrowth ^ (level - 1))}`
	)
end

local function refreshOwner(base: Model)
	local uid = base:GetAttribute("OwnerUserId") :: number?
	if not uid then
		return -- B's PlotService manages the label until it mirrors OwnerUserId
	end
	local sign = base:FindFirstChild("Sign")
	local board = sign and sign:FindFirstChild("Board")
	local owner = if uid > 0 then game:GetService("Players"):GetPlayerByUserId(uid) else nil
	setText(
		board and board:FindFirstChildOfClass("SurfaceGui"),
		"OwnerLabel",
		if owner then `{owner.DisplayName}'s Pen` else "Empty Pen"
	)
end

-- Upgrade panel: dark board, title, "Level a > Level b", green price bar; text faces `face`.
local function upgradeSign(
	base: Model,
	name: string,
	title: string,
	pos: Vector3,
	face: Enum.NormalId,
	action: string,
	object: string
)
	block(base, name .. "Post", Vector3.new(0.8, 1.4, 0.8), CFrame.new(pos + Vector3.new(0, 0.7, 0)), SIGN)
	local board = block(base, name, Vector3.new(6, 4, 0.6), CFrame.new(pos + Vector3.new(0, 3.4, 0)), SIGN)
	surface(board, face, {
		{ "Title", title, 0.06, 0.28 },
		{ "Level", "Level 1 > Level 2", 0.36, 0.2, rgb(140, 255, 120) },
		{ "Cost", "$0", 0.62, 0.3, Color3.new(1, 1, 1), rgb(70, 200, 60) },
	})
	prompt(board, action, title, object)
end

local function fenceRun(parent: Instance, a: Vector3, b: Vector3)
	local post, rail = rgb(80, 60, 55), rgb(205, 120, 60)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local cf = CFrame.lookAt((a + b) / 2, b)
	for _, y in { 1.6, 3.2 } do
		block(parent, "Rail", Vector3.new(0.4, 0.5, len), cf * CFrame.new(0, y, 0), rail, { studs = false })
	end
	local n = math.max(1, math.floor(len / 8 + 0.5))
	for s = 0, n do
		local p = a + dir * (len * s / n)
		block(parent, "Post", Vector3.new(1.1, 4.4, 1.1), CFrame.new(p.X, 2.2, p.Z), post)
		block(parent, "PostCap", Vector3.new(1.4, 0.4, 1.4), CFrame.new(p.X, 4.6, p.Z), post:Lerp(rgb(0, 0, 0), 0.2))
		if s < n then
			local q = a + dir * (len * (s + 0.5) / n)
			local seg = len / n - 1.1
			local brace = math.sqrt(seg * seg + 1.6 * 1.6)
			local ang = math.atan2(1.6, seg)
			local look = CFrame.lookAt(Vector3.new(q.X, 2.4, q.Z), Vector3.new(q.X, 2.4, q.Z) + dir)
			block(
				parent,
				"Brace",
				Vector3.new(0.3, 0.3, brace),
				look * CFrame.Angles(ang, 0, 0),
				rail,
				{ studs = false }
			)
			block(
				parent,
				"Brace",
				Vector3.new(0.3, 0.3, brace),
				look * CFrame.Angles(-ang, 0, 0),
				rail,
				{ studs = false }
			)
		end
	end
end

local function buildBase(parent: Instance, i: number)
	local slot = PENS[i]
	local cx, zE, out = slot.cx, slot.zE, slot.out
	local zB = zE - out * PEN_D -- back fence
	local x0, x1 = cx - PEN_W / 2, cx + PEN_W / 2
	local face = if out < 0 then Enum.NormalId.Front else Enum.NormalId.Back -- text faces the avenue
	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base:SetAttribute("BaseIndex", i)
	base.Parent = parent

	-- Open checker floor (4 x 4 tiles, top at 0.3)
	local tw, td = PEN_W / 4, PEN_D / 4
	for tx = 0, 3 do
		for tz = 0, 3 do
			block(
				base,
				"Floor",
				Vector3.new(tw, 0.3, td),
				CFrame.new(x0 + (tx + 0.5) * tw, 0.15, math.min(zE, zB) + (tz + 0.5) * td),
				if (tx + tz) % 2 == 0 then rgb(138, 230, 92) else rgb(118, 210, 76)
			)
		end
	end

	local fence = folder(base, "Fence")
	fenceRun(fence, Vector3.new(x0, 0, zB), Vector3.new(x1, 0, zB))
	fenceRun(fence, Vector3.new(x0, 0, zB), Vector3.new(x0, 0, zE))
	fenceRun(fence, Vector3.new(x1, 0, zB), Vector3.new(x1, 0, zE))
	fenceRun(fence, Vector3.new(x0, 0, zE), Vector3.new(cx - 6, 0, zE))
	fenceRun(fence, Vector3.new(cx + 6, 0, zE), Vector3.new(x1, 0, zE))

	-- Invisible egg spots (5 x 4, slot 1 nearest the entrance); egg bottom lands on the floor top (0.3)
	local pedestals = folder(base, "Pedestals")
	for n = 1, Economy.PlotSlots.max do
		local row, col = (n - 1) // 5, (n - 1) % 5
		local ped = Instance.new("Model")
		ped.Name = "Pedestal" .. n
		ped:SetAttribute("Slot", n)
		ped.PrimaryPart = block(
			ped,
			"Top",
			Vector3.new(3, 0.1, 3),
			CFrame.new(cx + (col - 2) * 9.5, 0.15, zE - out * (6 + row * 9.5)),
			Color3.new(1, 1, 1),
			{
				transparency = 1,
				collide = false,
				studs = false,
			}
		)
		ped.Parent = pedestals
	end

	-- Owner board above the back fence
	local sign = Instance.new("Model")
	sign.Name = "Sign"
	for _, dx in { -6, 6 } do
		block(sign, "Post", Vector3.new(0.9, 9, 0.9), CFrame.new(cx + dx, 4.5, zB - out * 0.9), rgb(80, 60, 55))
	end
	local board = block(sign, "Board", Vector3.new(14, 3.6, 0.8), CFrame.new(cx, 8.8, zB - out * 0.9), BASE_COLORS[i])
	surface(board, face, { { "Subtitle", `PEN {i}`, 0.04, 0.3 }, { "OwnerLabel", "Empty Pen", 0.34, 0.62 } })
	sign.Parent = base

	upgradeSign(base, "PenSign", "Upgrade Pen", Vector3.new(cx - 10, 0, zE + out * 2.5), face, "UpgradePen", `Pen {i}`)

	-- Training station on the avenue beside the entrance; step faces away from the pen
	local rackSlot = CFrame.new(cx + 16, 0, zE + out * 14)
		* (if out > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity)
	upgradeSign(
		base,
		"RackSign",
		"Upgrade Station",
		Vector3.new(cx + 5, 0, zE + out * 22),
		face,
		"UpgradeTraining",
		`Station {i}`
	)

	block(base, "SpawnPoint", Vector3.new(2, 1, 2), CFrame.new(cx - 4, 3, zE + out * 8), Color3.new(1, 1, 1), {
		transparency = 1,
		collide = false,
		studs = false,
	})

	refreshRack(base, rackSlot)
	refreshPen(base)
	base:GetAttributeChangedSignal("RackLevel"):Connect(function()
		refreshRack(base, rackSlot)
	end)
	base:GetAttributeChangedSignal("PenLevel"):Connect(function()
		refreshPen(base)
	end)
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		refreshOwner(base)
	end)
end

local function tree(parent: Instance, pos: Vector3, scale: number, leaf: Color3)
	stamp(
		Props.tree(rgb(120, 80, 50), leaf, leaf:Lerp(rgb(255, 255, 255), 0.25)),
		CFrame.new(pos) * CFrame.Angles(0, math.rad(pos.Z * 7 % 360), 0),
		scale,
		parent
	)
end

local function buildSafeZone(map: Instance)
	local zone = folder(map, "SafeZone")
	-- Ground: dirt cliff block + grass layer + light checker squares (20-stud tiles)
	block(
		zone,
		"Cliff",
		Vector3.new(2 * W, CLIFF - 1, DEPTH),
		CFrame.new(0, -1 - (CLIFF - 1) / 2, -DEPTH / 2),
		DIRT,
		{ sideStuds = true }
	)
	block(
		zone,
		"GrassLayer",
		Vector3.new(2 * W, 1, DEPTH),
		CFrame.new(0, -0.5, -DEPTH / 2),
		GRASS_DARK,
		{ sideStuds = true }
	)
	local tile = 20
	for tx = 0, (2 * W) / tile - 1 do
		for tz = 0, DEPTH / tile - 1 do
			if (tx + tz) % 2 == 0 then
				block(
					zone,
					"Grass",
					Vector3.new(tile, 0.1, tile),
					CFrame.new(-W + (tx + 0.5) * tile, 0.05, -(tz + 0.5) * tile),
					GRASS
				)
			end
		end
	end
	block(zone, "Sand", Vector3.new(2 * (INNER + 8), 0.14, 16), CFrame.new(0, 0.07, -8), rgb(240, 215, 160))
	-- Walls: back (canyon side, two segments around the mouth) and both sides; the far edge is an open cliff
	wall(zone, Vector3.new(-W, 0, 0), Vector3.new(-INNER, 0, 0), Vector3.new(0, 0, -1), DIRT, GRASS, 101, WALL_T, 0)
	wall(zone, Vector3.new(INNER, 0, 0), Vector3.new(W, 0, 0), Vector3.new(0, 0, -1), DIRT, GRASS, 102, 0, WALL_T)
	wall(zone, Vector3.new(-W, 0, -DEPTH), Vector3.new(-W, 0, 0), Vector3.new(1, 0, 0), DIRT, GRASS, 103)
	wall(zone, Vector3.new(W, 0, -DEPTH), Vector3.new(W, 0, 0), Vector3.new(-1, 0, 0), DIRT, GRASS, 104)
	-- Keep players from walking off the cliff
	block(
		zone,
		"EdgeBarrier",
		Vector3.new(2 * W, 14, 2),
		CFrame.new(0, 7, -DEPTH - 1),
		Color3.new(1, 1, 1),
		{ transparency = 1, studs = false }
	)
	block(map, "Ocean", Vector3.new(2400, 2, 2400), CFrame.new(0, -CLIFF - 1, 600), rgb(40, 120, 215), {
		material = Enum.Material.SmoothPlastic,
		studs = false,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(0, 0.2, -165)
	spawn.Color = rgb(250, 250, 250)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Duration = 0
	spawn.Parent = zone

	stall(zone, -40, -170, 1, "Shop", { rgb(70, 190, 255), rgb(250, 250, 255) }, "OpenMenu:Store")
	stall(zone, 40, -170, 1, "Index", { rgb(255, 210, 60), rgb(250, 250, 255) }, "OpenMenu:Index")

	local decor = folder(zone, "Decor")
	fountain(decor, Vector3.new(0, 0, -78))
	for _, x in { -162, 162 } do
		lamp(decor, Vector3.new(x, 0, -66))
		lamp(decor, Vector3.new(x, 0, -90))
	end
	for _, x in { -20, 20 } do
		lamp(decor, Vector3.new(x, 0, -150))
	end
	for _, p in
		{ Vector3.new(-150, 0, -175), Vector3.new(150, 0, -175), Vector3.new(-110, 0, -180), Vector3.new(110, 0, -180) }
	do
		tree(decor, p, 1.6, rgb(70, 170, 60))
	end

	local bases = folder(zone, "Bases")
	for i = 1, #PENS do
		buildBase(bases, i)
	end
end

------------------------------------------------------------------ runway zones

local function buildRiver(parent: Instance, zone: Zones.Zone)
	local r = RIVERS[zone.id]
	if not r then
		return
	end
	local z = zone.start + 4
	local w = 2 * INNER
	if r == "rainbow" then
		for i = 1, 6 do
			block(
				parent,
				"River",
				Vector3.new(w, 0.12, 1),
				CFrame.new(0, 0.06, z - 3.5 + i),
				Color3.fromHSV((i - 1) / 6, 0.6, 1),
				{
					material = Enum.Material.Neon,
					collide = false,
				}
			)
		end
		return
	end
	local river = r :: River
	block(parent, "River", Vector3.new(w, 0.12, 6), CFrame.new(0, 0.06, z), river.color, {
		material = river.material or Enum.Material.SmoothPlastic,
		transparency = river.transparency,
		collide = false,
		studs = false,
	})
	for _, x in { -(HALF + 9), -(HALF + 3), HALF + 3, HALF + 9 } do
		block(
			parent,
			"SteppingStone",
			Vector3.new(3, 0.4, 3),
			CFrame.new(x, 0.2, z) * CFrame.Angles(0, math.rad(x * 3), 0),
			rgb(150, 145, 140)
		)
	end
end

local function buildZone(parent: Instance, zone: Zones.Zone)
	local f = folder(parent, "Zone" .. zone.id)
	local z0, len = zone.start, zone.length
	local mid = z0 + len / 2
	local rng = Random.new(zone.id * 7919)
	local field = zone.ground:Lerp(Color3.new(0, 0, 0), 0.08)
	local face = zone.ground:Lerp(DIRT, 0.55)

	block(f, "Lane", Vector3.new(Chase.RunwayWidth, 2, len), CFrame.new(0, -1, mid), zone.ground)
	for k = -1, 1, 2 do
		block(
			f,
			"Field",
			Vector3.new(INNER - HALF, 2, len),
			CFrame.new(k * (HALF + (INNER - HALF) / 2), -1, mid),
			field
		)
		block(f, "LaneEdge", Vector3.new(1.2, 0.4, len), CFrame.new(k * (HALF + 0.6), 0.2, mid), zone.accent)
		-- zone 1's first WALL_T studs belong to the plaza wall around the canyon mouth
		local wz = if zone.id == 1 then WALL_T else z0
		wall(
			f,
			Vector3.new(k * INNER, 0, wz),
			Vector3.new(k * INNER, 0, z0 + len),
			Vector3.new(-k, 0, 0),
			face,
			zone.ground,
			zone.id * 31 + k
		)
	end
	buildRiver(f, zone)

	-- Patches in four separate slots (never overlap), then tufts and pebbles
	local patch = zone.ground:Lerp(zone.accent, 0.18)
	for k = 0, 3 do
		local s = rng:NextInteger(5, 9)
		local cz = z0 + (k + 0.5) * len / 4 + rng:NextNumber(-3, 3)
		block(
			f,
			"Patch",
			Vector3.new(s, 0.06, s),
			CFrame.new(rng:NextNumber(-HALF + 6, HALF - 6), 0.03, math.max(cz, z0 + 12))
				* CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 15), 0),
			patch,
			{
				collide = false,
			}
		)
	end
	for i = 1, 12 do
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(HALF + 2, INNER - 3)
		local tuft = rng:NextNumber() < 0.6
		local c = if tuft then zone.ground:Lerp(rgb(0, 0, 0), 0.25) else zone.accent:Lerp(rgb(255, 255, 255), 0.2)
		local s = rng:NextNumber(0.5, 1.1)
		block(
			f,
			if tuft then "Tuft" else "Pebble",
			Vector3.new(s, if tuft then s * 1.4 else s * 0.5, s),
			CFrame.new(x, s * 0.3, z0 + rng:NextNumber(10, len - 4))
				* CFrame.Angles(0, math.rad(rng:NextInteger(0, 89)), 0),
			c,
			{
				collide = false,
			}
		)
	end

	local kinds = Props.forZone(zone.id)
	local props = folder(f, "Props")
	for k = 0, 3 do
		local sideSign = if k % 2 == 0 then -1 else 1
		local z = z0 + 15 + k * (len - 30) / 3 + rng:NextNumber(-4, 4)
		local yaw = CFrame.Angles(0, math.rad(rng:NextInteger(0, 7) * 45), 0)
		stamp(
			kinds[k % #kinds + 1],
			CFrame.new(sideSign * rng:NextNumber(PROP_BAND[1], PROP_BAND[2]), 0, z) * yaw,
			rng:NextNumber(0.85, 1.1),
			props
		)
		stamp(
			kinds[(k + 1) % #kinds + 1],
			CFrame.new(-sideSign * (INNER - 7), 0, z + 10) * yaw,
			rng:NextNumber(1.2, 1.5),
			props
		)
	end

	-- Zone ambience (petals, snow, embers, bubbles... from Config/Zones.ambient)
	local rising = {
		Bubbles = true,
		Spores = true,
		Embers = true,
		Sparkles = true,
		Fireflies = true,
		Neon = true,
		Wisps = true,
		Clouds = true,
		ToxicBubbles = true,
		Steam = true,
		Aurora = true,
		Magma = true,
		Stars = true,
		Rainbow = true,
	}
	local y = if rising[zone.ambient] then 1 else 26
	MapFx.emit(anchor(f, "AmbientFx", Vector3.new(2 * INNER - 4, 0.2, len - 4), Vector3.new(0, y, mid)), zone.ambient)
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
	wall(
		map,
		Vector3.new(-INNER, 0, endZ),
		Vector3.new(INNER, 0, endZ),
		Vector3.new(0, 0, -1),
		last.ground:Lerp(DIRT, 0.55),
		last.ground,
		999,
		WALL_T,
		WALL_T
	)

	map.Parent = workspace
	return map
end

return MapBuilder
