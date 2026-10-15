--!strict
-- Partner A. Builds the whole map from Config (once on server start, or from the command bar):
--   require(game.ReplicatedStorage.Shared.Builders.Map.MapBuilder).build()
-- Layout (Config/Chase axes; map overhaul 2026-10-14): a grass hub (the safe zone, Z < SafeLineZ) on a cliff above
-- the ocean, walled on three sides by stepped, planted dirt walls; the runway canyon leaves the hub's wall at the
-- kick pad (origin) and runs straight +Z through the 20 zones. The hub: an open launch pad (no arch) with a side
-- "KICK THE EGG!" sign and two egg monuments, a clear central path (spine) from the pad to pen 5, the Boxing
-- Sack Shop and the Pet Selling Stand either side of it near the pad, an egg fountain off the spine, and FIVE large
-- pens (two each side, one at the end) that grow with their PenLevel inside a fixed reserve. The Prize Wheel and
-- the two global boards sit on the side walls between the pens.
-- No zone signs: the HUD's zone bar names zones. Every part butts against its neighbours (no coplanar
-- overlaps), so nothing z-fights.
-- Map v3 (Partner B, at A's request): the hub sits PLAZA_Y = 11 above the zones; a launch ramp (Map.Drop.Ramp,
-- z 10..76) is the climb home for steered eggs; Map.Drop.PlayerBarrier (collision group "PlayerBarrier") stops
-- characters ("Players") but not eggs ("Eggs"). Each zone has a rim plateau, a landmark (Landmarks.luau), themed
-- walls, background silhouettes and boundary blends (Scenery.luau), rim decor and lane lights. Lighting gets
-- Atmosphere, Bloom, SunRays and ColorCorrection.
--
-- Stable names for Partner B:
--   workspace.Map.KickPad                         Part; players stand on it (top at y = MapBuilder.KickPadTop)
--   workspace.Map.SafeZone.Bases.Base<i>          Model, attribute BaseIndex = i (1..MapBuilder.PenCount = 5). The
--                                                 server sets OwnerUserId / RackLevel / PenLevel (Config/Upgrades).
--     .PenArea                                    invisible floor frame (origin = pen centre, -Z toward the gate);
--                                                 its Size grows with PenLevel (MapBuilder.penSize), centre fixed
--     .Pen                                        the level's floor, fence and dressing (rebuilt on PenLevel)
--     .SpawnPoint / .OwnerAnchor / .PenSign       fixed, outside the largest pen
--   workspace.Map.SafeZone.BoxingSackShop         Model ("OpenMenu:Store"); .Approach = where to walk to
--   workspace.Map.SafeZone.PetSellingStand        Model ("OpenMenu:Inventory" = the Sell Pets screen); .Approach
--   workspace.Map.Runway.Zone<id>                 Folder per zone
-- ProximityPrompts carry an "Action" attribute the client UI handles:
--   "UpgradePen" | "UpgradeTraining" | "EquipSack" | "OpenMenu:Store" (Boxing Sack Shop)
--   | "OpenMenu:Inventory" (Pet Selling Stand)
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local Builder = require(script.Parent.Parent.BlockBuilder)
local Props = require(script.Parent.Props)
local Sacks = require(script.Parent.Parent.Models.Sacks)
local SackGeometry = require(script.Parent.Parent.SackGeometry)
local MapFx = require(script.Parent.MapFx)
local Bricks = require(script.Parent.Bricks)
local Landmarks = require(script.Parent.Landmarks)
local Merchants = require(script.Parent.Merchants)
local WheelBuilder = require(script.Parent.Wheel)
local Boards = require(script.Parent.Boards)
local Scenery = require(script.Parent.Scenery)
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
local W = 195 -- hub half-width
local DEPTH = 390 -- the hub runs from z = 0 to z = -DEPTH (open cliff edge)
local WALL_T, WALL_H = 24, 50
local CLIFF = 40 -- plaza height above the ocean
local PROP_BAND = { HALF + 5, HALF + 8 } -- low props on the shoulders: the 48-stud lane stays clear (map overhaul)
-- Map v3: the plaza and launch hub sit PLAZA_Y above the zones, so every kick dives into the
-- valley. The launch ramp (RAMP_START -> RAMP_END along +Z) is the climb home for steered eggs;
-- a player-only barrier across the canyon mouth keeps characters up top (eggs pass through).
local PLAZA_Y = 11 -- about two characters tall: a gentle climb home, not a cliff
local RAMP_START, RAMP_END = 10, 76
local RIM_W = 60 -- canyon rim plateau width beyond each wall
local RIM_TOP = WALL_H + 2 -- flush with the wall caps
MapBuilder.PlazaY = PLAZA_Y
MapBuilder.RampStart, MapBuilder.RampEnd = RAMP_START, RAMP_END
MapBuilder.KickPadTop = PLAZA_Y + 0.5
-- Collision groups: the barrier only stops characters (the server puts them in "Players").
MapBuilder.Groups = { players = "Players", eggs = "Eggs", barrier = "PlayerBarrier" }

local rgb = Color3.fromRGB
local DIRT = rgb(205, 130, 80)
local GRASS, GRASS_DARK = rgb(120, 215, 75), rgb(104, 196, 64)
local YELLOW = rgb(255, 220, 80)
local SHIELD_ICON = "rbxassetid://77216163319959"
local SIGN = rgb(32, 38, 52)
-- Pens (5, map overhaul 2026-10-14): two on each side of the central path, gates facing it, and one at the end
-- facing the pad. Each has the same size at the same level: width (along the gate side) x depth grows from
-- PEN_START (level 1) to PEN_MAX (the last level, Config/Upgrades.Pen) around a fixed centre, so saved pen-local
-- positions stay valid. PEN_MAX is the reserve kept free around every pen.
type PenSlot = { cx: number, cz: number, dir: Vector3 }
local PENS: { PenSlot } = {
	{ cx = -125, cz = -100, dir = Vector3.new(1, 0, 0) },
	{ cx = 125, cz = -100, dir = Vector3.new(-1, 0, 0) },
	{ cx = -125, cz = -210, dir = Vector3.new(1, 0, 0) },
	{ cx = 125, cz = -210, dir = Vector3.new(-1, 0, 0) },
	{ cx = 0, cz = -315, dir = Vector3.new(0, 0, 1) },
}
MapBuilder.PenCount = #PENS
MapBuilder.LandingTag = Chase.Landing.tag
local PEN_START = Vector2.new(64, 56)
local PEN_MAX = Vector2.new(76, 72)
local PEN_MAX_LEVEL = 1 + math.ceil((Economy.PlotSlots.max - Economy.PlotSlots.base) / Upgrades.Pen.slotsPerLevel)
MapBuilder.PenReserve = PEN_MAX
MapBuilder.PenMaxLevel = PEN_MAX_LEVEL

-- A pen's floor size (width along the gate side, depth) at `level`: monotonic, PEN_START .. PEN_MAX.
function MapBuilder.penSize(level: number): Vector2
	local t = math.clamp((level - 1) / math.max(1, PEN_MAX_LEVEL - 1), 0, 1)
	return Vector2.new(
		math.floor(PEN_START.X + (PEN_MAX.X - PEN_START.X) * t + 0.5),
		math.floor(PEN_START.Y + (PEN_MAX.Y - PEN_START.Y) * t + 0.5)
	)
end

-- Pen i's centre on the hub floor as built (before the lift), -Z (LookVector) toward its gate.
function MapBuilder.penFrame(i: number): CFrame
	local slot = PENS[i]
	local c = Vector3.new(slot.cx, 0, slot.cz)
	return CFrame.lookAt(c, c + slot.dir)
end

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

-- Egg statue on a plinth; the client spins models with a "Spin" attribute (degrees / second).
local function eggStatue(parent: Instance, x: number, z: number, color: Color3)
	local stone = rgb(200, 200, 212)
	block(parent, "Plinth", Vector3.new(7, 4, 7), CFrame.new(x, 2, z), stone, { sideStuds = true })
	block(parent, "PlinthTrim", Vector3.new(7.6, 0.6, 7.6), CFrame.new(x, 4.3, z), YELLOW)
	local m = Bricks.model(parent, "EggStatue")
	local pivot =
		Bricks.part(m, "Pivot", Vector3.one, CFrame.new(x, 9.4, z), color, { transparency = 1, collide = false })
	m.PrimaryPart = pivot
	local shiny = { material = Enum.Material.SmoothPlastic, reflect = 0.2 }
	Bricks.ball(m, "Base", 6, CFrame.new(x, 7.6, z), color, shiny)
	Bricks.cyl(m, "Middle", 3, 6, CFrame.new(x, 9.1, z), color, shiny)
	Bricks.ball(m, "Top", 5.4, CFrame.new(x, 10.9, z), color, shiny)
	Bricks.ball(m, "Crown", 3.4, CFrame.new(x, 12.9, z), color:Lerp(Color3.new(1, 1, 1), 0.25), shiny)
	m:SetAttribute("Spin", 30)
	MapFx.emit(anchor(parent, "StatueFx", Vector3.new(6, 1, 6), Vector3.new(x, 9, z)), "StallSparkle")
end

local function brazier(parent: Instance, x: number, z: number)
	Bricks.cyl(parent, "BrazierStand", 3, 1.6, CFrame.new(x, 1.5, z), rgb(60, 60, 72))
	Bricks.cyl(parent, "BrazierBowl", 1.2, 3.6, CFrame.new(x, 3.6, z), rgb(80, 80, 95))
	local coal = Bricks.glow(parent, "BrazierCoal", Vector3.new(2.4, 1, 2.4), CFrame.new(x, 4.1, z), rgb(255, 120, 30))
	Bricks.fire(coal, rgb(255, 120, 30), 6)
	Bricks.light(coal, rgb(255, 150, 60), 22, 2)
end

-- Launch hub on the plaza lip (built at plaza level 0, lifted with the plaza): tiered platform,
-- gold kick pad with a ring of lights, the launch arch with a banner per zone, egg statues,
-- braziers and a rail at the drop. workspace.Map.KickPad keeps its name and contract.
local function buildKickPad(map: Instance)
	local hub = folder(map, "Hub")
	local stone, stoneDark = rgb(205, 205, 218), rgb(150, 150, 168)
	block(hub, "Deck", Vector3.new(2 * INNER, 1, RAMP_START), CFrame.new(0, -0.5, RAMP_START / 2), stoneDark)
	cylinder(hub, "Tier1", 0.2, 20, Vector3.new(0, 0.1, 0), stoneDark) -- stays on the deck (z <= RAMP_START)
	cylinder(hub, "Tier2", 0.35, 16, Vector3.new(0, 0.175, 0), stone)
	cylinder(map, "KickPadRim", 0.45, 13, Vector3.new(0, 0.225, 0), rgb(45, 45, 60))
	local pad = cylinder(map, "KickPad", 0.5, 11, Vector3.new(0, 0.25, 0), rgb(255, 215, 60))
	pad:SetAttribute("Top", MapBuilder.KickPadTop)
	local glow = { material = Enum.Material.Neon, collide = false }
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		block(
			hub,
			"PadLight",
			Vector3.new(1.4, 0.12, 0.7),
			CFrame.new(math.cos(a) * 8.6, 0.4, math.sin(a) * 8.6) * CFrame.Angles(0, -a, 0),
			if i % 2 == 0 then rgb(255, 215, 60) else rgb(255, 120, 40),
			glow
		)
	end
	block(map, "ArrowShaft", Vector3.new(1.4, 0.1, 4), CFrame.new(0, 0.55, -0.8), rgb(255, 120, 40), glow)
	block(
		map,
		"ArrowHead",
		Vector3.new(2.8, 0.1, 2.8),
		CFrame.new(0, 0.55, 1.6) * CFrame.Angles(0, math.rad(45), 0),
		rgb(255, 120, 40),
		glow
	)
	MapFx.emit(anchor(map, "PadFx", Vector3.new(9, 0.2, 9), Vector3.new(0, 0.6, 0)), "PadRise")

	-- No arch over the launch (map overhaul): a side-mounted sign angled toward the arrival point instead
	local signAt = Vector3.new(30, 0, 3) -- on the deck, clear of the pad (radius 12) and the shops
	local signCF = CFrame.lookAt(signAt, Vector3.new(0, 0, -72))
	for _, sx in { -7, 7 } do
		block(
			hub,
			"SignPost",
			Vector3.new(1.6, 9, 1.6),
			signCF * CFrame.new(sx, 4.5, 0),
			stoneDark,
			{ sideStuds = true }
		)
	end
	local kickSign =
		block(hub, "KickSign", Vector3.new(17, 5.4, 1.2), signCF * CFrame.new(0, 10.2, 0), rgb(255, 120, 40))
	block(hub, "KickSignTrim", Vector3.new(18, 6.4, 0.8), signCF * CFrame.new(0, 10.2, 0.8), YELLOW)
	surface(kickSign, Enum.NormalId.Front, { { "Title", "KICK THE EGG!", 0.1, 0.8 } }, 20)
	Bricks.light(kickSign, rgb(255, 170, 80), 16, 1)

	eggStatue(hub, -24, -9, rgb(255, 200, 50))
	eggStatue(hub, 24, -9, rgb(180, 120, 255))
	brazier(hub, -15, 7)
	brazier(hub, 15, 7)

	-- Rail along the drop: decorative only (the player barrier does the blocking; eggs drive through)
	local railZ = RAMP_START - 0.6
	for x = -INNER + 2, INNER - 2, 6 do
		block(
			hub,
			"RailPost",
			Vector3.new(0.8, 3, 0.8),
			CFrame.new(x, 1.5, railZ),
			rgb(160, 105, 60),
			{ collide = false }
		)
	end
	block(hub, "Rail", Vector3.new(2 * INNER - 2, 0.6, 0.6), CFrame.new(0, 3.1, railZ), rgb(255, 215, 60), glow)
end

-- Moves every part under `root` up by `dy` (the plaza is built at 0, then raised to PLAZA_Y).
local function lift(root: Instance, dy: number)
	local offset = Vector3.new(0, dy, 0)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame += offset
		end
	end
	if root:IsA("BasePart") then
		root.CFrame += offset
	end
end

-- The climb home: a wedge from the hub (PLAZA_Y) down to the zone floor, chevrons pointing home,
-- solid fill under the hub deck, and the player-only barrier across the canyon mouth.
local function buildDrop(map: Instance)
	local drop = folder(map, "Drop")
	local len = RAMP_END - RAMP_START
	local ramp = Bricks.part(
		drop,
		"Ramp",
		Vector3.new(2 * INNER, PLAZA_Y, len),
		CFrame.new(0, PLAZA_Y / 2, (RAMP_START + RAMP_END) / 2) * CFrame.Angles(0, math.pi, 0), -- high end at RAMP_START
		Zones[1].ground,
		{ shape = "Wedge" }
	)
	ramp.Name = "Ramp"
	CollectionService:AddTag(ramp, Chase.Landing.tag)
	-- top at PLAZA_Y - 1: the hub deck (1 thick, lifted with the plaza) sits on it without z-fighting
	block(
		drop,
		"HubFill",
		Vector3.new(2 * INNER, PLAZA_Y - 1, RAMP_START),
		CFrame.new(0, (PLAZA_Y - 1) / 2, RAMP_START / 2),
		DIRT,
		{
			sideStuds = true,
		}
	)
	-- Chevrons and lane edges lying on the slope
	local slope = math.atan2(PLAZA_Y, len)
	local function onSlope(t: number, x: number, lift_: number): CFrame
		local z = RAMP_START + t * len
		local y = PLAZA_Y * (1 - t) + lift_
		return CFrame.new(x, y, z) * CFrame.Angles(-slope, 0, 0)
	end
	local glow = { material = Enum.Material.Neon, collide = false }
	for i = 1, 5 do
		local t = i / 6
		for _, side in { -1, 1 } do
			block(
				drop,
				"Chevron",
				Vector3.new(7, 0.2, 1.4),
				onSlope(t, side * 2.6, 0.12) * CFrame.Angles(0, math.rad(side * 35), 0),
				YELLOW,
				glow
			)
		end
	end
	for _, side in { -1, 1 } do
		block(
			drop,
			"RampEdge",
			Vector3.new(1.2, 0.3, len / math.cos(slope)),
			onSlope(0.5, side * (HALF + 0.6), 0.15),
			Zones[1].accent,
			glow
		)
	end

	local barrier = block(
		drop,
		"PlayerBarrier",
		Vector3.new(2 * INNER, 70, 2),
		CFrame.new(0, PLAZA_Y + 35, RAMP_START - 1),
		Color3.new(1, 1, 1),
		{ transparency = 1, studs = false }
	)
	barrier.CanQuery = false -- landing raycasts and the camera ignore it
	barrier.CanTouch = false
	barrier.CollisionGroup = MapBuilder.Groups.barrier
end

local function setupCollisionGroups()
	local g = MapBuilder.Groups
	for _, name in { g.players, g.eggs, g.barrier } do
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end
	PhysicsService:CollisionGroupSetCollidable(g.barrier, "Default", false)
	PhysicsService:CollisionGroupSetCollidable(g.barrier, g.eggs, false)
	PhysicsService:CollisionGroupSetCollidable(g.barrier, g.players, true)
	-- steered eggs pass through characters: the kicker waits (hidden) on the kick pad, right on the way home
	PhysicsService:CollisionGroupSetCollidable(g.eggs, g.players, false)
end

-- Bright, punchy sky: atmosphere haze, bloom on neon, soft sun rays and a touch more colour.
local function applyLighting()
	local function effect(class: string, name: string, props: { [string]: any })
		local old = Lighting:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		local e = Instance.new(class)
		e.Name = name
		for k, v in props do
			(e :: any)[k] = v
		end
		e.Parent = Lighting
	end
	effect("Atmosphere", "MapAtmosphere", {
		Density = 0.3,
		Offset = 0.1,
		Color = rgb(200, 225, 255),
		Decay = rgb(120, 150, 210),
		Glare = 0.4,
		Haze = 1.4,
	})
	effect("BloomEffect", "MapBloom", { Intensity = 0.6, Size = 28, Threshold = 1.3 })
	effect("SunRaysEffect", "MapSunRays", { Intensity = 0.07, Spread = 0.55 })
	effect("ColorCorrectionEffect", "MapColor", { Saturation = 0.14, Contrast = 0.06, Brightness = 0.02 })
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

-- A Kick Sack hanging from its chain with its hub at `hang` (stands, the Boxing Sack Shop): the original
-- imported GLB sack when available (Builders/SackGeometry), else the part-built remodel. Anchored, no physics;
-- named "Sack" with a Tier attribute so MapLife spins it (`spin` deg/s) and shows its idle VFX.
local function hangSack(parent: Instance, tier: number, hang: CFrame, spin: number): Model
	local sack = SackGeometry.build(tier)
	sack:PivotTo(hang)
	for _, d in sack:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		elseif d:IsA("WeldConstraint") or d:IsA("Motor6D") then
			d:Destroy()
		end
	end
	if sack.PrimaryPart then
		sack.PrimaryPart:Destroy()
	end
	sack.Name = "Sack"
	sack.Parent = parent
	local pivot = Instance.new("Part")
	pivot.Name = "Pivot"
	pivot.Size = Vector3.one * 0.2
	pivot.Transparency = 1
	pivot.Anchored = true
	pivot.CanCollide = false
	pivot.CanQuery = false
	pivot.CanTouch = false
	pivot.CFrame = hang
	pivot.Parent = sack
	sack.PrimaryPart = pivot
	sack:SetAttribute("Tier", tier)
	sack:SetAttribute("Spin", spin)
	return sack
end

-- The Boxing Sack Shop (remodel 2026-10-14): an open gym storefront instead of a closed box with a small door.
-- Stone plinth, red back wall and white side walls with stripes, two chunky front pillars under a header beam and a
-- striped awning, a flat roof with the sign standing on its front edge (nothing overlaps it). Inside: the counter
-- right at the front with the Coach (the shop's avatar NPC, MerchantService) behind it, a mini boxing ring at the
-- back with four display sacks on a gantry and two more on wall brackets, gloves and a champion poster. The six
-- display sacks are props: attribute Display = true, so MapLifeController builds no effects / lights / sounds for
-- them (they only turn slowly); the sacks you own are untouched. Lighting is a few soft warm lights.
-- The counter's prompt ("OpenMenu:Store") opens the existing sack purchasing screen (UI/Screens/TrainingShop);
-- nothing is bought here. `dir` = +1 faces +Z, -1 faces -Z.
local SHOP_TIERS = { 9, 14, 18, 20, 1, 5 } -- gantry (premium) first, then the two wall brackets (burlap, tire)
local function sackShop(parent: Instance, x: number, z: number, dir: number)
	local m = Instance.new("Model")
	m.Name = "BoxingSackShop"
	m.Parent = parent
	local origin = Vector3.new(x, 0, z)
	local frame = CFrame.lookAt(origin, origin + Vector3.new(0, 0, dir))
	local function at(lx: number, ly: number, lz: number): CFrame
		return frame * CFrame.new(lx, ly, lz)
	end
	local red, redDark, white = rgb(215, 45, 50), rgb(150, 28, 34), rgb(250, 248, 244)
	local gold, wood, mat, stone = rgb(255, 200, 60), rgb(150, 98, 60), rgb(40, 110, 210), rgb(205, 205, 215)
	local W, D, H = 34, 24, 16 -- footprint and wall height
	local FLOOR = 1 -- top of the ring mat
	-- plinth, front step and the blue mat floor
	block(m, "Plinth", Vector3.new(W + 1, 0.8, D + 1), at(0, 0.4, 0), stone, { sideStuds = true })
	block(m, "Step", Vector3.new(W - 6, 0.4, 2), at(0, 0.2, -D / 2 - 1.5), stone)
	block(m, "Floor", Vector3.new(W - 2, 0.2, D - 2), at(0, 0.9, 0), mat)
	-- back wall (red, white stripe) and side walls (white, red stripe)
	block(m, "BackWall", Vector3.new(W, H, 1), at(0, 0.8 + H / 2, D / 2 - 0.5), red, { sideStuds = true })
	block(m, "BackStripe", Vector3.new(W + 0.1, 1.2, 1.2), at(0, 4.6, D / 2 - 0.5), white, { studs = false })
	for _, sx in { -1, 1 } do
		block(
			m,
			"SideWall",
			Vector3.new(1, H, D - 3),
			at(sx * (W / 2 - 0.5), 0.8 + H / 2, 1.5),
			white,
			{ sideStuds = true }
		)
		block(m, "SideStripe", Vector3.new(1.2, 1.2, D - 2.9), at(sx * (W / 2 - 0.5), 4.6, 1.5), red, { studs = false })
		-- chunky front pillars with a gold cap and a warm lantern each (soft)
		block(
			m,
			"Pillar",
			Vector3.new(2.6, H + 1.4, 2.6),
			at(sx * (W / 2 - 1.3), 0.8 + (H + 1.4) / 2, -D / 2 + 1.3),
			redDark
		)
		block(m, "PillarBand", Vector3.new(2.8, 0.8, 2.8), at(sx * (W / 2 - 1.3), 4.6, -D / 2 + 1.3), gold)
		local lantern = Bricks.glow(
			m,
			"Lantern",
			Vector3.new(1.4, 1.4, 1.4),
			at(sx * (W / 2 - 1.3), 11, -D / 2 - 0.4),
			rgb(255, 214, 150),
			"Ball"
		)
		Bricks.light(lantern, rgb(255, 205, 140), 14, 0.6)
		-- gloves hanging on the inside of the side walls
		for _, lz in { 0, 5 } do
			Bricks.ball(m, "Glove", 1.7, at(sx * (W / 2 - 1.6), 9, lz), rgb(230, 40, 40))
			block(m, "GloveCuff", Vector3.new(0.9, 0.9, 0.9), at(sx * (W / 2 - 1.6), 10.1, lz), white)
		end
	end
	-- header beam over the open front, the striped awning and the flat roof
	block(m, "Header", Vector3.new(W, 2.4, 2.2), at(0, 0.8 + H + 0.6, -D / 2 + 1.1), redDark)
	block(m, "HeaderTrim", Vector3.new(W + 0.2, 0.5, 2.4), at(0, 0.8 + H - 0.4, -D / 2 + 1.1), gold, { studs = false })
	for k = 0, 15 do
		local lx = -W / 2 + 1.05 + k * 2.13
		block(
			m,
			"Awning",
			Vector3.new(2.15, 0.4, 4.4),
			at(lx, 0.8 + H - 1.6, -D / 2 - 1.6) * CFrame.Angles(math.rad(-18), 0, 0),
			if k % 2 == 0 then red else white
		)
	end
	local roofTop = 0.8 + H + 1
	block(m, "Roof", Vector3.new(W + 1, 1, D + 1), at(0, roofTop - 0.5, 0.5), redDark) -- sits on the walls
	block(m, "RoofTrim", Vector3.new(W + 1.4, 0.6, D + 1.4), at(0, roofTop - 0.5, 0.5), gold, { studs = false })
	-- the sign stands on the roof's front edge, on two posts
	local signY = roofTop + 5.6
	for _, sx in { -9, 9 } do
		block(m, "SignPost", Vector3.new(1, 3, 1), at(sx, roofTop + 1.5, -D / 2 + 2.4), redDark)
	end
	local board = block(m, "Sign", Vector3.new(28, 6, 0.8), at(0, signY, -D / 2 + 1.6), red, { sideStuds = true })
	block(m, "SignFrame", Vector3.new(29.2, 7.2, 0.6), at(0, signY, -D / 2 + 2.3), gold)
	local signGui = surface(board, Enum.NormalId.Front, {
		{ "Title", "BOXING SACK SHOP", 0.08, 0.6, white },
		{ "Sub", "TRAIN STRONGER - KICK FARTHER", 0.68, 0.24, rgb(255, 225, 120) },
	}, 24)
	signGui.Name = "SignGui"
	-- the mini boxing ring at the back: corner posts and red / white / blue ropes on three sides (open to the front)
	local ringZ0, ringZ1, ringX = 0.5, D / 2 - 1.5, 11
	for _, px in { -ringX, ringX } do
		for _, pz in { ringZ0, ringZ1 } do
			block(m, "RingPost", Vector3.new(0.9, 5.4, 0.9), at(px, FLOOR + 2.7, pz), white)
		end
	end
	for k, c in { rgb(230, 50, 60), white, rgb(50, 110, 230) } do
		local y = FLOOR + 1.4 + k * 1.2
		block(m, "Rope", Vector3.new(2 * ringX, 0.3, 0.3), at(0, y, ringZ1), c, { collide = false, studs = false })
		for _, px in { -ringX, ringX } do
			block(
				m,
				"Rope",
				Vector3.new(0.3, 0.3, ringZ1 - ringZ0),
				at(px, y, (ringZ0 + ringZ1) / 2),
				c,
				{ collide = false, studs = false }
			)
		end
	end
	-- a champion poster on the back wall
	local poster =
		block(m, "Poster", Vector3.new(9, 4.6, 0.3), at(0, 12.4, D / 2 - 1.15), rgb(32, 38, 52), { studs = false })
	surface(poster, Enum.NormalId.Front, {
		{ "Top", "THE CHAMP", 0.08, 0.4, rgb(255, 215, 60) },
		{ "Bottom", "HIT HARDER", 0.55, 0.32 },
	}, 24)
	-- display sacks: four on a gantry inside the ring, two on wall brackets by the counter. Props only.
	local hubY = FLOOR + Sacks.HANG
	local beamY = hubY + Sacks.CHAIN_TOP + 0.45
	local ringMid = (ringZ0 + ringZ1) / 2
	block(m, "Gantry", Vector3.new(2 * ringX + 1, 0.9, 1.2), at(0, beamY, ringMid), wood)
	for _, gx in { -ringX, ringX } do
		block(
			m,
			"GantryPost",
			Vector3.new(0.9, beamY - FLOOR - 0.45, 0.9),
			at(gx, (beamY + FLOOR - 0.45) / 2, ringMid + 0.9),
			wood
		)
	end
	local displays = folder(m, "Displays")
	for i, tier in SHOP_TIERS do
		local d = Instance.new("Model")
		d.Name = "Display" .. i
		d:SetAttribute("Tier", tier)
		d.Parent = displays
		local hang: CFrame
		if i <= 4 then
			hang = at(-7.5 + (i - 1) * 5, hubY, ringMid)
		else
			local sx = if i == 5 then -1 else 1
			local bx = sx * (W / 2 - 4.2)
			block(d, "Bracket", Vector3.new(4.4, 0.7, 0.9), at(sx * (W / 2 - 2.2), beamY, -3.5), wood)
			hang = at(bx, hubY, -3.5)
		end
		local sack = hangSack(d, tier, hang, 8)
		sack:SetAttribute("Display", true) -- a prop: no idle effects (MapLifeController)
		if i <= 4 then -- a nameplate on the ring's front edge, under its sack
			local plateAt = hang * CFrame.new(0, -hubY + FLOOR + 0.7, -(ringMid - ringZ0) - 0.6)
			local plate = block(d, "Plate", Vector3.new(4, 1.2, 0.4), plateAt, rgb(32, 38, 52))
			surface(
				plate,
				Enum.NormalId.Front,
				{ { "Name", string.upper(Upgrades.Sack.tiers[tier].name), 0.1, 0.8 } },
				30
			)
		end
	end
	-- one soft ceiling light for the whole room
	local ceiling = anchor(m, "CeilingLight", Vector3.new(1, 0.4, 1), at(0, 0.8 + H - 1, 0).Position)
	Bricks.light(ceiling, rgb(255, 240, 220), 26, 0.7)
	-- the counter right at the front, with the Coach behind it; its prompt opens the existing sack screen
	local counter = block(m, "Counter", Vector3.new(18, 3, 2.6), at(0, FLOOR + 1.5, -6.5), wood)
	block(m, "CounterTop", Vector3.new(18.6, 0.4, 3.2), at(0, FLOOR + 3.2, -6.5), white)
	block(m, "CounterStripe", Vector3.new(18.1, 0.7, 0.1), at(0, FLOOR + 1.9, -7.85), red, { studs = false })
	Bricks.ball(m, "CounterGlove", 1.6, at(-6.5, FLOOR + 4.2, -6.5), rgb(230, 40, 40))
	Bricks.ball(m, "CounterGlove", 1.6, at(-4.8, FLOOR + 4.2, -6.3), rgb(230, 40, 40))
	block(m, "Bell", Vector3.new(1.2, 0.8, 1.2), at(6, FLOOR + 3.8, -6.5), gold)
	-- the Coach stands on a raised step behind the counter, so the whole avatar shows above it
	block(m, "MerchantStep", Vector3.new(12, 1.2, 3.6), at(0, FLOOR + 0.6, -3.2), wood)
	Merchants.build("Coach", m, at(0, FLOOR + 1.2, -3.2))
	local p = prompt(counter, "OpenMenu:Store", "Browse sacks", "Boxing Sack Shop")
	p.MaxActivationDistance = 14
	-- where to walk to (tutorial trail / arrow): in front of the storefront, on the ground
	anchor(m, "Approach", Vector3.new(2, 1, 2), at(0, 1.5, -D / 2 - 5).Position)
end

-- The Pet Selling Stand (map overhaul): a market stand, clearly not the sack shop - four chunky posts, a striped
-- canopy with a scalloped front, a "SELL PETS" sign with the approved paw icon, an open counter, crates of eggs,
-- lanterns and the pet merchant behind the counter. The counter prompt ("OpenMenu:Inventory") opens the existing
-- Sell Pets screen (UI/Screens/PetInventory): nothing is sold by walking up or opening it. `dir` as sackShop.
local PAW_ICON = "rbxassetid://84890738919357" -- UI/System/AssetIds hud_pets (the approved Pets icon)
local function petStand(parent: Instance, x: number, z: number, dir: number)
	local m = Instance.new("Model")
	m.Name = "PetSellingStand"
	m.Parent = parent
	local origin = Vector3.new(x, 0, z)
	local frame = CFrame.lookAt(origin, origin + Vector3.new(0, 0, dir))
	local function at(lx: number, ly: number, lz: number): CFrame
		return frame * CFrame.new(lx, ly, lz)
	end
	local wood, woodDark, cream = rgb(175, 115, 62), rgb(115, 72, 40), rgb(250, 242, 222)
	local teal, orange = rgb(40, 195, 175), rgb(255, 150, 40)
	block(m, "Deck", Vector3.new(24, 0.8, 18), at(0, 0.4, 0), rgb(205, 165, 112))
	for _, sx in { -10.5, 10.5 } do
		for _, sz in { -7.5, 7.5 } do
			block(m, "Post", Vector3.new(1.8, 12.4, 1.8), at(sx, 7, sz), woodDark)
		end
	end
	block(m, "BackBoard", Vector3.new(19.2, 7, 0.8), at(0, 4.3, 7.5), cream, { sideStuds = true })
	for row = 0, 1 do
		block(m, "Shelf", Vector3.new(16, 0.4, 1.2), at(0, 3.4 + row * 2.6, 6.6), wood)
		for col = 0, 5 do
			local zone = Zones[(row * 6 + col) % #Zones + 1]
			Bricks.ball(
				m,
				"ShelfEgg",
				1.3,
				at(-6.25 + col * 2.5, 4.25 + row * 2.6, 6.6),
				zone.ground:Lerp(zone.accent, 0.4)
			)
		end
	end
	-- striped canopy sloping to the front, with a scalloped valance
	for i = 0, 11 do
		local lx = -11 + i * 2
		block(
			m,
			"Canopy",
			Vector3.new(2.05, 0.5, 20),
			at(lx, 13.6, 0) * CFrame.Angles(math.rad(-9), 0, 0),
			if i % 2 == 0 then teal else cream
		)
		block(m, "Valance", Vector3.new(2, 1.3, 0.4), at(lx, 11.6, -10.1), if i % 2 == 0 then teal else cream)
	end
	-- the sign: SELL PETS between two paws
	local sign = block(m, "Sign", Vector3.new(17, 4.6, 0.8), at(0, 17.6, -8.6), orange, { sideStuds = true })
	block(m, "SignFrame", Vector3.new(18, 5.6, 0.6), at(0, 17.6, -7.9), woodDark)
	for _, sx in { -6, 6 } do
		block(m, "SignPost", Vector3.new(0.8, 2.4, 0.8), at(sx, 14.8, -8), woodDark)
	end
	local gui = surface(sign, Enum.NormalId.Front, { { "Title", "SELL PETS", 0.1, 0.8 } }, 24)
	local title = gui:FindFirstChild("Title") :: TextLabel
	title.Position, title.Size = UDim2.fromScale(0.2, 0.1), UDim2.fromScale(0.6, 0.8)
	for _, px in { 0.03, 0.81 } do
		local paw = Instance.new("ImageLabel")
		paw.BackgroundTransparency = 1
		paw.Image = PAW_ICON
		paw.ScaleType = Enum.ScaleType.Fit
		paw.Position, paw.Size = UDim2.fromScale(px, 0.05), UDim2.fromScale(0.16, 0.9)
		paw.Parent = gui
	end
	Bricks.light(sign, rgb(255, 190, 110), 18, 1)
	-- counter, crates of eggs either side of the front, lanterns on the front posts
	local counter = block(m, "Counter", Vector3.new(16, 3.4, 2.4), at(0, 2.5, -4.6), wood)
	block(m, "CounterTop", Vector3.new(16.6, 0.4, 3), at(0, 4.4, -4.6), cream)
	block(m, "CounterStripe", Vector3.new(16.1, 0.6, 0.1), at(0, 3.2, -5.85), teal, { studs = false })
	for _, sx in { -9.4, 9.4 } do
		block(m, "Crate", Vector3.new(3.6, 2.8, 3.6), at(sx, 2.2, -11.4), wood)
		block(m, "CrateBand", Vector3.new(3.7, 0.5, 3.7), at(sx, 2.2, -11.4), woodDark, { studs = false })
		for k = -1, 1 do
			local zone = Zones[(math.floor(sx) + k * 3) % #Zones + 1]
			Bricks.ball(m, "CrateEgg", 1.4, at(sx + k * 1.1, 4.2, -11.4), zone.ground:Lerp(Color3.new(1, 1, 1), 0.3))
		end
		local lantern =
			Bricks.glow(m, "Lantern", Vector3.new(1.4, 1.4, 1.4), at(sx * 1.12, 10.4, -8.6), rgb(255, 220, 140), "Ball")
		Bricks.light(lantern, rgb(255, 210, 140), 16, 1.1)
	end
	MapFx.emit(anchor(m, "GoodsFx", Vector3.new(12, 1, 2), at(0, 5.6, -4.6).Position), "StallSparkle")
	Merchants.build("PetSeller", m, at(0, 0.8, 1.2))
	local p = prompt(counter, "OpenMenu:Inventory", "Sell pets", "Pet Selling Stand")
	p.MaxActivationDistance = 14
	anchor(m, "Approach", Vector3.new(2, 1, 2), at(0, 1.5, -14).Position)
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
	-- a chunky block egg on the spout (MapLife spins models with a Spin attribute)
	local egg = Bricks.model(f, "FountainEgg")
	local pivot = Bricks.part(egg, "Pivot", Vector3.one, CFrame.new(c + Vector3.new(0, 9.6, 0)), Color3.new(1, 1, 1), {
		transparency = 1,
		collide = false,
	})
	egg.PrimaryPart = pivot
	local gold, shine = rgb(255, 205, 60), rgb(255, 240, 160)
	for k, w in { 2.4, 3.4, 3.8, 3.6, 3, 2 } do
		Bricks.part(
			egg,
			"Egg" .. k,
			Vector3.new(w, 1, w),
			CFrame.new(c + Vector3.new(0, 7.3 + k, 0)),
			if k == 4 then shine else gold,
			{
				collide = false,
			}
		)
	end
	egg:SetAttribute("Spin", 24)
	local l = Instance.new("PointLight")
	l.Color, l.Range, l.Brightness = rgb(130, 200, 255), 18, 1
	l.Parent = water
end

-- Upgrade panel: dark board, title, "Level a > Level b", green price bar. `cf` = the board's foot, its -Z (front, the
-- text side) facing the visitor.
local function upgradeSign(base: Model, name: string, title: string, cf: CFrame, action: string, object: string)
	block(base, name .. "Post", Vector3.new(0.8, 1.4, 0.8), cf * CFrame.new(0, 0.7, 0), SIGN)
	local board = block(base, name, Vector3.new(6, 4, 0.6), cf * CFrame.new(0, 3.4, 0), SIGN)
	surface(board, Enum.NormalId.Front, {
		{ "Title", title, 0.06, 0.28 },
		{ "Level", "Level 1 > Level 2", 0.36, 0.2, rgb(140, 255, 120) },
		{ "Cost", "$0", 0.62, 0.3, Color3.new(1, 1, 1), rgb(70, 200, 60) },
	})
	prompt(board, action, title, object)
end

-- Fence styles by pen level: wood (start), white posts with blue rails, then dark posts, gold rails and caps.
local FENCES = {
	{ post = rgb(80, 60, 55), rail = rgb(205, 120, 60), cap = rgb(64, 48, 44) },
	{ post = rgb(245, 245, 240), rail = rgb(110, 185, 255), cap = rgb(210, 215, 225) },
	{ post = rgb(45, 50, 66), rail = rgb(255, 200, 60), cap = rgb(255, 215, 80) },
}
type Fence = { post: Color3, rail: Color3, cap: Color3 }

-- A fence from a to b (world points on the floor; heights are relative to them, so it works lifted too).
local function fenceRun(parent: Instance, a: Vector3, b: Vector3, style: Fence)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local cf = CFrame.lookAt((a + b) / 2, b)
	for _, y in { 1.6, 3.2 } do
		block(parent, "Rail", Vector3.new(0.4, 0.5, len), cf * CFrame.new(0, y, 0), style.rail, { studs = false })
	end
	local n = math.max(1, math.floor(len / 8 + 0.5))
	for s = 0, n do
		local p = a + dir * (len * s / n)
		block(parent, "Post", Vector3.new(1.1, 4.4, 1.1), CFrame.new(p.X, p.Y + 2.2, p.Z), style.post)
		block(parent, "PostCap", Vector3.new(1.4, 0.4, 1.4), CFrame.new(p.X, p.Y + 4.6, p.Z), style.cap)
		if s < n then
			local q = a + dir * (len * (s + 0.5) / n)
			local seg = len / n - 1.1
			local brace = math.sqrt(seg * seg + 1.6 * 1.6)
			local ang = math.atan2(1.6, seg)
			local look = CFrame.lookAt(Vector3.new(q.X, q.Y + 2.4, q.Z), Vector3.new(q.X, q.Y + 2.4, q.Z) + dir)
			for _, sign in { 1, -1 } do
				block(
					parent,
					"Brace",
					Vector3.new(0.3, 0.3, brace),
					look * CFrame.Angles(sign * ang, 0, 0),
					style.rail,
					{ studs = false }
				)
			end
		end
	end
end

-- (Re)builds a pen for `level` around its PenArea (whose CFrame never changes): resizes the area, then lays the
-- checker floor, the fence with a 12-stud gate on the -Z side, and the level's dressing (stepping stones from 2,
-- gate lamps and corner planters from 3, banners and premium fence from 5, a gate arch at the last level).
local BANNER = { rgb(255, 90, 90), rgb(80, 170, 255), rgb(140, 220, 80), rgb(255, 190, 50), rgb(190, 110, 255) }
local function buildPen(base: Model, level: number)
	local area = base:FindFirstChild("PenArea")
	if not (area and area:IsA("BasePart")) then
		return
	end
	local old = base:FindFirstChild("Pen")
	if old then
		old:Destroy()
	end
	local pen = folder(base, "Pen")
	local size = MapBuilder.penSize(level)
	area.Size = Vector3.new(size.X, 0.2, size.Y)
	local f = area.CFrame * CFrame.new(0, -0.2, 0) -- the hub floor under the pen centre
	local hw, hd = size.X / 2, size.Y / 2
	local function at(x: number, y: number, z: number): CFrame
		return f * CFrame.new(x, y, z)
	end
	local function pt(x: number, z: number): Vector3
		return f:PointToWorldSpace(Vector3.new(x, 0, z))
	end
	local tw, td = size.X / 4, size.Y / 4
	for tx = 0, 3 do
		for tz = 0, 3 do
			block(
				pen,
				"Floor",
				Vector3.new(tw, 0.3, td),
				at(-hw + (tx + 0.5) * tw, 0.15, -hd + (tz + 0.5) * td),
				if (tx + tz) % 2 == 0 then rgb(165, 232, 92) else rgb(146, 214, 78)
			)
		end
	end
	local style: Fence = FENCES[if level >= 5 then 3 elseif level >= 3 then 2 else 1]
	local fence = folder(pen, "Fence")
	fenceRun(fence, pt(-hw, hd), pt(hw, hd), style)
	fenceRun(fence, pt(-hw, -hd), pt(-hw, hd), style)
	fenceRun(fence, pt(hw, -hd), pt(hw, hd), style)
	fenceRun(fence, pt(-hw, -hd), pt(-6, -hd), style)
	fenceRun(fence, pt(6, -hd), pt(hw, -hd), style)
	local dress = folder(pen, "Dressing")
	local stone = rgb(232, 220, 196)
	if level >= 2 then -- stepping stones into the pen (flat: nothing to trip over)
		for k = 0, 2 do
			block(
				dress,
				"Stone",
				Vector3.new(3.4, 0.12, 2.6),
				at(if k % 2 == 0 then -0.8 else 0.8, 0.36, -hd + 3 + k * 4),
				stone,
				{
					collide = false,
				}
			)
		end
	end
	if level >= 3 then -- lamps on the gate posts, planters on the back corners (outside the fence)
		for _, sx in { -7.5, 7.5 } do
			block(
				dress,
				"GateLampPole",
				Vector3.new(0.6, 6, 0.6),
				at(sx, 3.4, -hd - 1),
				rgb(60, 60, 70),
				{ collide = false }
			)
			local bulb = block(dress, "GateLamp", Vector3.new(1.3, 1.3, 1.3), at(sx, 7, -hd - 1), rgb(255, 230, 150), {
				material = Enum.Material.Neon,
				collide = false,
			})
			Bricks.light(bulb, rgb(255, 220, 150), 14, 0.8)
		end
		for _, sx in { -1, 1 } do
			block(dress, "Planter", Vector3.new(3, 1.6, 3), at(sx * (hw - 1.5), 0.8, hd + 2.2), rgb(150, 98, 60))
			stamp(Props.kit.bush, at(sx * (hw - 1.5), 1.6, hd + 2.2), 0.8, dress)
		end
	end
	if level >= 5 then -- banners on the back corners in the pen's colour
		for _, sx in { -1, 1 } do
			block(dress, "BannerPole", Vector3.new(0.6, 11, 0.6), at(sx * (hw - 0.2), 5.5, hd + 0.8), rgb(60, 60, 70), {
				collide = false,
			})
			block(
				dress,
				"Banner",
				Vector3.new(0.2, 4, 2.6),
				at(sx * (hw - 0.2), 8.6, hd + 0.8) * CFrame.Angles(0, math.rad(90), 0),
				BANNER[((base:GetAttribute("BaseIndex") :: number?) or 1) % #BANNER + 1],
				{ collide = false, studs = false }
			)
		end
	end
	if level >= PEN_MAX_LEVEL then -- the top level: a gold arch over the pen gate
		for _, sx in { -6.6, 6.6 } do
			block(dress, "ArchPost", Vector3.new(1.4, 8, 1.4), at(sx, 4, -hd), rgb(45, 50, 66))
		end
		block(dress, "ArchTop", Vector3.new(14.6, 1.4, 1.6), at(0, 8.7, -hd), rgb(255, 200, 60))
		Bricks.glow(dress, "ArchStar", Vector3.new(1.6, 1.6, 0.6), at(0, 10, -hd), rgb(255, 240, 160))
	end
	base:SetAttribute("PenBuiltLevel", level)
end

local function refreshPen(base: Model)
	local level = math.max(1, (base:GetAttribute("PenLevel") :: number?) or 1)
	if base:GetAttribute("PenBuiltLevel") ~= level then
		buildPen(base, level)
	end
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

local function buildBase(parent: Instance, i: number)
	local frame = MapBuilder.penFrame(i)
	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base:SetAttribute("BaseIndex", i)
	base.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local start = MapBuilder.penSize(1)
	-- The pen's floor and frame (PlotService / PlotController): origin = floor centre on top of the tiles, -Z toward
	-- the gate, Size = the fenced floor (grows with PenLevel; the centre never moves). Pets roam and eggs are placed
	-- inside it in pen-local coords.
	local area = block(base, "PenArea", Vector3.new(start.X, 0.2, start.Y), at(0, 0.2, 0), Color3.new(1, 1, 1), {
		transparency = 1,
		collide = false,
		studs = false,
	})
	area.CanQuery, area.CanTouch = false, false
	-- Fixed pieces sit outside the largest pen so upgrades never move them.
	local owner = block(base, "OwnerAnchor", Vector3.new(1, 1, 1), at(0, 13, PEN_MAX.Y / 2 - 2), Color3.new(1, 1, 1), {
		transparency = 1,
		collide = false,
		studs = false,
	})
	owner.CanQuery, owner.CanTouch = false, false
	upgradeSign(base, "PenSign", "Upgrade Pen", at(-15, 0, -PEN_MAX.Y / 2 - 4), "UpgradePen", `Pen {i}`)
	local spawnAt = at(6, 3, -PEN_MAX.Y / 2 - 10).Position
	block(
		base,
		"SpawnPoint",
		Vector3.new(2, 1, 2),
		CFrame.lookAt(spawnAt, Vector3.new(0, spawnAt.Y, 0)), -- spawn looking toward the kick pad
		Color3.new(1, 1, 1),
		{ transparency = 1, collide = false, studs = false }
	)
	-- The reserved lot the pen grows into: a darker grass plate with a low stone curb (open at the gate)
	local lot = folder(base, "Lot")
	local lw, ld = PEN_MAX.X + 4, PEN_MAX.Y + 4
	block(lot, "Reserve", Vector3.new(lw, 0.2, ld), at(0, 0.1, 0), rgb(92, 176, 60), { studs = false })
	local curb = rgb(214, 200, 172)
	block(lot, "Curb", Vector3.new(lw + 1.6, 0.6, 0.8), at(0, 0.3, ld / 2 + 0.4), curb, { collide = false })
	for _, sx in { -1, 1 } do
		block(lot, "Curb", Vector3.new(0.8, 0.6, ld), at(sx * (lw / 2 + 0.4), 0.3, 0), curb, { collide = false })
		local seg = (lw - 14) / 2
		block(
			lot,
			"Curb",
			Vector3.new(seg, 0.6, 0.8),
			at(sx * (7 + seg / 2), 0.3, -ld / 2 - 0.4),
			curb,
			{ collide = false }
		)
	end
	buildPen(base, 1)
	refreshPen(base)
	base:GetAttributeChangedSignal("PenLevel"):Connect(function()
		refreshPen(base)
	end)
end

local function tree(parent: Instance, pos: Vector3, scale: number) -- the approved chunky kit tree
	stamp(Props.kit.tree, CFrame.new(pos) * CFrame.Angles(0, math.rad(pos.Z * 7 % 360), 0), scale, parent)
end

-- Stepped, planted terrace against a hub wall: a low wide step and a taller narrow one (grass caps) with bushes,
-- along the wall face a -> b; `inward` points into the hub.
local function terrace(parent: Instance, a: Vector3, b: Vector3, inward: Vector3, seed: number)
	local along = (b - a).Unit
	local len = (b - a).Magnitude
	local rot = CFrame.lookAt(Vector3.zero, along)
	local mid = (a + b) / 2
	local soil, soilDark = DIRT:Lerp(Color3.new(1, 1, 1), 0.06), DIRT:Lerp(Color3.new(0, 0, 0), 0.1)
	local steps = { { depth = 11, height = 5, color = soil }, { depth = 5, height = 13, color = soilDark } }
	for k, st in steps do
		local c = mid + inward * (st.depth / 2) -- both steps start at the wall; the tall one is a little shorter
		local l = if k == 1 then len else len - 0.6 -- (no coplanar end faces)
		block(
			parent,
			"Terrace",
			Vector3.new(st.depth, st.height, l),
			CFrame.new(c.X, st.height / 2, c.Z) * rot,
			st.color,
			{
				sideStuds = true,
			}
		)
		block(parent, "TerraceCap", Vector3.new(st.depth, 0.8, l), CFrame.new(c.X, st.height + 0.4, c.Z) * rot, GRASS)
	end
	local rng = Random.new(seed)
	local d = 4
	while d < len - 4 do
		local p = a + along * d + inward * 8
		stamp(
			Props.kit.bush,
			CFrame.new(p.X, 5.8, p.Z) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90), 0),
			rng:NextNumber(0.9, 1.2),
			parent
		)
		d += rng:NextNumber(10, 16)
	end
end

-- Warm pale stone paths: the spine from the pad to pen 5, side paths to the four side gates, the walk linking the
-- shop and the stand, and the square around the fountain. No two paths overlap (no z-fighting).
local PATH = rgb(236, 222, 196)
local function paths(parent: Instance)
	local f = folder(parent, "Paths")
	local function slab(name: string, x0: number, x1: number, z0: number, z1: number)
		block(f, name, Vector3.new(x1 - x0, 0.15, z1 - z0), CFrame.new((x0 + x1) / 2, 0.075, (z0 + z1) / 2), PATH, {
			studs = false,
		})
	end
	slab("Spine", -12, 12, -287, -16)
	for _, k in { -1, 1 } do
		for _, z in { -100, -210 } do
			slab("SidePath", if k < 0 then -91 else 12, if k < 0 then -12 else 91, z - 8, z + 8)
		end
		slab("ShopWalk", if k < 0 then -72 else 12, if k < 0 then -12 else 72, -54, -42)
	end
	slab("FountainSquare", -44, -16, -164, -136)
end

local function buildSafeZone(map: Instance)
	local zone = folder(map, "SafeZone")
	-- Ground: dirt cliff block + grass layer + light checker squares (26-stud tiles)
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
	local tile = 26
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
	-- the front walls stop 0.1 short of the canyon (x = +-INNER): the canyon wall below shares that plane
	wall(
		zone,
		Vector3.new(-W, 0, 0),
		Vector3.new(-INNER - 0.1, 0, 0),
		Vector3.new(0, 0, -1),
		DIRT,
		GRASS,
		101,
		WALL_T,
		0
	)
	wall(zone, Vector3.new(INNER + 0.1, 0, 0), Vector3.new(W, 0, 0), Vector3.new(0, 0, -1), DIRT, GRASS, 102, 0, WALL_T)
	wall(zone, Vector3.new(-W, 0, -DEPTH), Vector3.new(-W, 0, 0), Vector3.new(1, 0, 0), DIRT, GRASS, 103)
	wall(zone, Vector3.new(W, 0, -DEPTH), Vector3.new(W, 0, 0), Vector3.new(-1, 0, 0), DIRT, GRASS, 104)
	-- Stepped planted terraces break up the walls (not behind the wheel / boards, not at the canyon mouth)
	local terraces = folder(zone, "Terraces")
	terrace(terraces, Vector3.new(-W + 11, 0, 0), Vector3.new(-INNER - 12, 0, 0), Vector3.new(0, 0, -1), 201)
	terrace(terraces, Vector3.new(INNER + 12, 0, 0), Vector3.new(W - 11, 0, 0), Vector3.new(0, 0, -1), 202)
	for k, x in { -W, W } do
		local inward = Vector3.new(if x < 0 then 1 else -1, 0, 0)
		terrace(terraces, Vector3.new(x, 0, -11), Vector3.new(x, 0, -118), inward, 210 + k)
		terrace(terraces, Vector3.new(x, 0, -192), Vector3.new(x, 0, -DEPTH + 4), inward, 220 + k)
	end
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

	-- Shared arrival point on the central path, looking at the launch pad
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 0.25, -72), Vector3.new(0, 0.25, 0))
	spawn.Color = rgb(250, 250, 250)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Duration = 0
	spawn.Parent = zone

	paths(zone)
	-- set back toward the wall, so the straight tutorial trail from the pad to pens 1 / 2 passes in front of them
	sackShop(zone, -58, -24, -1)
	petStand(zone, 58, -28, -1)

	local decor = folder(zone, "Decor")
	fountain(decor, Vector3.new(-30, 0, -150))
	for _, x in { -16, 16 } do -- lamps along the central path, clear of the side-path junctions
		for _, z in { -36, -70, -130, -170, -240, -272 } do
			lamp(decor, Vector3.new(x, 0, z))
		end
	end
	for _, p in
		{
			Vector3.new(-30, 0, -78),
			Vector3.new(30, 0, -78),
			Vector3.new(30, 0, -150),
			Vector3.new(-62, 0, -150),
			Vector3.new(36, 0, -255),
			Vector3.new(-36, 0, -255),
		}
	do
		block(decor, "FlowerBed", Vector3.new(7, 0.8, 4), CFrame.new(p + Vector3.new(0, 0.4, 0)), rgb(120, 82, 52))
		for _, dx in { -2, 0, 2 } do
			stamp(Props.kit.bush, CFrame.new(p + Vector3.new(dx, 0.8, 0)), 0.55, decor)
		end
	end
	-- garden islands in the open lawns: a low grass mound, a tree, bushes and flowers
	local FLOWERS = { rgb(255, 120, 170), rgb(255, 220, 80), rgb(150, 200, 255), rgb(255, 255, 255) }
	for k, p in
		{
			Vector3.new(-62, 0, -124),
			Vector3.new(62, 0, -140),
			Vector3.new(-58, 0, -262),
			Vector3.new(58, 0, -262),
			Vector3.new(-150, 0, -36),
			Vector3.new(150, 0, -36),
			Vector3.new(-150, 0, -300),
			Vector3.new(150, 0, -300),
			Vector3.new(-118, 0, -356),
			Vector3.new(118, 0, -356),
		}
	do
		local g = folder(decor, "Garden")
		block(
			g,
			"Mound",
			Vector3.new(18, 0.8, 13),
			CFrame.new(p + Vector3.new(0, 0.4, 0)),
			rgb(98, 186, 62),
			{ sideStuds = true }
		)
		block(g, "MoundTop", Vector3.new(12, 0.8, 8), CFrame.new(p + Vector3.new(0, 1.2, 0)), rgb(112, 200, 70))
		tree(g, p + Vector3.new(if k % 2 == 0 then 3 else -3, 1.6, 0), 0.9)
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			local q = p + Vector3.new(math.cos(a) * 7, 0.8, math.sin(a) * 4.6)
			if i % 2 == 0 then
				stamp(Props.kit.bush, CFrame.new(q), 0.5, g)
			else
				block(
					g,
					"Flower",
					Vector3.new(1, 1, 1),
					CFrame.new(q + Vector3.new(0, 0.5, 0)),
					FLOWERS[(i + k) % #FLOWERS + 1],
					{
						collide = false,
					}
				)
			end
		end
	end
	for _, p in
		{
			Vector3.new(-176, 0, -40),
			Vector3.new(176, 0, -40),
			Vector3.new(-176, 0, -262),
			Vector3.new(176, 0, -262),
			Vector3.new(-176, 0, -350),
			Vector3.new(176, 0, -350),
			Vector3.new(-82, 0, -352),
			Vector3.new(82, 0, -352),
			Vector3.new(-62, 0, -282),
			Vector3.new(62, 0, -282),
		}
	do
		tree(decor, p, 1)
	end

	-- Prize Wheel on the +X wall between pens 2 and 4: as tall as the wall
	local wheelRadius = (WALL_H - 4) / 2
	WheelBuilder.build(
		zone,
		CFrame.fromMatrix(Vector3.new(W, wheelRadius + 3, -155), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0)),
		wheelRadius,
		0
	)
	-- Opposite wall (-X), facing the wheel: the global Kick Power leaderboard and the top donators board
	local function westFace(z: number, y: number): CFrame
		return CFrame.fromMatrix(Vector3.new(-W, y, z), Vector3.new(0, 0, -1), Vector3.new(0, 1, 0))
	end
	Boards.build(zone, westFace(-141, 19), "Power", rgb(255, 190, 40), 0)
	Boards.build(zone, westFace(-169, 19), "Donations", rgb(200, 80, 255), 0)

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
	local face = Scenery.wallColor(zone.id) or zone.ground:Lerp(DIRT, 0.55)
	-- Zone 1 opens with the launch ramp: its flat floor and floor decor start at RAMP_END
	local fz0 = if zone.id == 1 then RAMP_END else z0
	local flen = z0 + len - fz0
	local fmid = fz0 + flen / 2
	local minZ = fz0 + 4

	local lane = block(f, "Lane", Vector3.new(Chase.RunwayWidth, 2, flen), CFrame.new(0, -1, fmid), zone.ground)
	CollectionService:AddTag(lane, Chase.Landing.tag) -- eggs land only on lanes and the ramp (KickService)
	for k = -1, 1, 2 do
		block(
			f,
			"Field",
			Vector3.new(INNER - HALF, 2, flen),
			CFrame.new(k * (HALF + (INNER - HALF) / 2), -1, fmid),
			field
		)
		block(f, "LaneEdge", Vector3.new(1.2, 0.4, flen), CFrame.new(k * (HALF + 0.6), 0.2, fmid), zone.accent)
		-- zone 1's walls run under the raised plaza wall to close the canyon mouth
		local wz = if zone.id == 1 then 0.5 else z0
		wall(
			f,
			Vector3.new(k * INNER, 0, wz),
			Vector3.new(k * INNER, 0, z0 + len),
			Vector3.new(-k, 0, 0),
			face,
			zone.ground,
			zone.id * 31 + k
		)
		-- Rim plateau beyond the wall, flush with the caps (zone 1's starts behind the plaza wall)
		local rz0 = if zone.id == 1 then WALL_T else z0
		local rlen = z0 + len - rz0
		block(
			f,
			"Rim",
			Vector3.new(RIM_W, 6, rlen),
			CFrame.new(k * (INNER + WALL_T + RIM_W / 2), RIM_TOP - 3, rz0 + rlen / 2),
			zone.ground:Lerp(DIRT, 0.3),
			{ sideStuds = true }
		)
	end
	buildRiver(f, zone)

	-- Glowing lane lights in the zone accent, so every zone reads at a glance from the air
	for lz = fz0 + 6, z0 + len - 4, 16 do
		for k = -1, 1, 2 do
			block(
				f,
				"LaneLight",
				Vector3.new(0.8, 1.2, 0.8),
				CFrame.new(k * (HALF + 1.6), 0.6, lz),
				zone.accent,
				{ material = Enum.Material.Neon, collide = false }
			)
		end
	end

	-- Patches in four separate slots (never overlap), then tufts and pebbles
	local patch = zone.ground:Lerp(zone.accent, 0.18)
	for k = 0, 3 do
		local s = rng:NextInteger(5, 9)
		local cz = z0 + (k + 0.5) * len / 4 + rng:NextNumber(-3, 3)
		local px, pyaw = rng:NextNumber(-HALF + 6, HALF - 6), rng:NextInteger(0, 3)
		if cz >= minZ then
			block(
				f,
				"Patch",
				Vector3.new(s, 0.06, s),
				CFrame.new(px, 0.03, math.max(cz, z0 + 12)) * CFrame.Angles(0, math.rad(pyaw * 15), 0),
				patch,
				{
					collide = false,
				}
			)
		end
	end
	local small = Props.small(zone.id, zone.ground)
	for i = 1, 12 do
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(HALF + 2, INNER - 3)
		local tuft = rng:NextNumber() < 0.6
		if tuft then
			local tz = z0 + rng:NextNumber(10, len - 4)
			if tz >= minZ then
				stamp(small[2], CFrame.new(x, 0, tz) * CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90), 0), 1, f)
			end
			continue
		end
		local c = if tuft then zone.ground:Lerp(rgb(0, 0, 0), 0.25) else zone.accent:Lerp(rgb(255, 255, 255), 0.2)
		local s = rng:NextNumber(0.5, 1.1)
		local tz, tyaw = z0 + rng:NextNumber(10, len - 4), rng:NextInteger(0, 89)
		if tz >= minZ then
			block(
				f,
				if tuft then "Tuft" else "Pebble",
				Vector3.new(s, if tuft then s * 1.4 else s * 0.5, s),
				CFrame.new(x, s * 0.3, tz) * CFrame.Angles(0, math.rad(tyaw), 0),
				c,
				{
					collide = false,
				}
			)
		end
	end

	local kinds = Props.forZone(zone.id)
	local props = folder(f, "Props")
	for k = 0, 3 do
		local sideSign = if k % 2 == 0 then -1 else 1
		local z = z0 + 15 + k * (len - 30) / 3 + rng:NextNumber(-4, 4)
		local yaw = CFrame.Angles(0, math.rad(rng:NextInteger(0, 7) * 45), 0)
		local bandX, s2 = rng:NextNumber(PROP_BAND[1], PROP_BAND[2]), rng:NextNumber(1.2, 1.5)
		if z >= minZ then
			local low = small[if k % 2 == 0 then 1 else 3]
			stamp(low, CFrame.new(sideSign * bandX, 0, z) * yaw, 1, props)
		end
		if z + 10 >= minZ then
			local kind = kinds[(k + 1) % #kinds + 1]
			local s = if Props.native[kind] then rng:NextNumber(0.95, 1.1) else s2
			stamp(kind, CFrame.new(-sideSign * (INNER - 5), 0, z + 10) * yaw, s, props)
		end
	end

	-- The zone's landmark on the rim (alternating sides), facing the canyon, plus rim decor
	local side = if zone.id % 2 == 0 then 1 else -1
	local landmarkPos = Vector3.new(side * (INNER + WALL_T + 24), RIM_TOP, mid)
	Landmarks.build(zone.id, f, CFrame.lookAt(landmarkPos, Vector3.new(0, RIM_TOP, mid)))
	local rimDecor = folder(f, "RimDecor")
	local rimStart = if zone.id == 1 then WALL_T + 6 else z0
	for k = -1, 1, 2 do
		for i = 0, 2 do
			local rz = z0 + 15 + i * (len - 30) / 2
			local rx = k * (INNER + WALL_T + rng:NextNumber(5, RIM_W - 8))
			local yaw = CFrame.Angles(0, math.rad(rng:NextInteger(0, 7) * 45), 0)
			local scale = rng:NextNumber(1.3, 1.8)
			local nearLandmark = k == side and math.abs(rz - mid) < 18
			if not nearLandmark and rz >= rimStart then
				local kind = kinds[(i + k + 3) % #kinds + 1]
				local s = if Props.native[kind] then 1 else scale
				stamp(kind, CFrame.new(rx, RIM_TOP, rz) * yaw, s, rimDecor)
			end
		end
	end

	-- Themed canyon ledges + rim lip, background silhouettes beyond the rims, and hand-over props at the boundaries
	Scenery.build(zone, f, {
		inner = INNER,
		half = HALF,
		wallT = WALL_T,
		wallH = WALL_H,
		rimW = RIM_W,
		rimTop = RIM_TOP,
		landmarkSide = side,
		stamp = function(spec: any, cf: CFrame, scale: number, parent: Instance): Model
			return stamp(spec, cf, scale, parent)
		end,
	}, fz0, if zone.id > 1 then zone.id - 1 else nil, if zone.id < #Zones then zone.id + 1 else nil)

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
	-- read by client effects (the avalanche follows the ground up the ramp)
	map:SetAttribute("PlazaY", PLAZA_Y)
	map:SetAttribute("RampStart", RAMP_START)
	map:SetAttribute("RampEnd", RAMP_END)
	map:SetAttribute("CanyonWidth", 2 * INNER)
	setupCollisionGroups()
	applyLighting()

	-- The plaza (hub, safe line, pens, market) is built at 0, then raised above the valley.
	buildKickPad(map)
	buildSafeLine(map)
	buildSafeZone(map)
	for _, child in map:GetChildren() do
		if child.Name ~= "Ocean" then
			lift(child, PLAZA_Y)
		end
	end
	local safeZone = map:FindFirstChild("SafeZone") :: Instance
	block(
		safeZone,
		"CliffBase",
		Vector3.new(2 * W, PLAZA_Y, DEPTH),
		CFrame.new(0, -CLIFF + PLAZA_Y / 2, -DEPTH / 2), -- ocean surface up to the plaza's cliff
		DIRT,
		{ sideStuds = true }
	)
	buildDrop(map)

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
		Scenery.wallColor(last.id) or last.ground:Lerp(DIRT, 0.55),
		last.ground,
		999,
		WALL_T,
		WALL_T
	)

	Props.studAll(map) -- reference style: studs on the sides too
	map.Parent = workspace
	return map
end

return MapBuilder
