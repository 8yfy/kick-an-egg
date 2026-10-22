--!strict
-- Partner A. Builds the whole map from Config (once on server start, or from the command bar):
--   require(game.ReplicatedStorage.Shared.Builders.Map.MapBuilder).build()
-- Layout (Config/Chase axes; map overhaul 2026-10-14): a grass hub (the safe zone, Z < SafeLineZ) on a cliff above
-- the ocean, walled on three sides by stepped, planted dirt walls; the runway canyon leaves the hub's wall at the
-- kick pad (origin) and runs straight +Z through the 20 zones. The hub: a launch station at the pad (no arch; see
-- buildLaunch), a clear central path (spine) from the launch deck to pen 5, the Boxing
-- Sack Shop and the Pet Selling Stand either side of it near the pad, an egg fountain off the spine, and FIVE large
-- pens (two each side, one at the end) that grow with their PenLevel inside a fixed reserve. The Prize Wheel and
-- the two global boards sit on the side walls between the pens.
-- No zone signs: the HUD's zone bar names zones. Every part butts against its neighbours (no coplanar
-- overlaps), so nothing z-fights.
-- Flat start (2026-10-22, replaces map v3's raised plaza and launch ramp): the hub, the launch station and every
-- lane sit at track level (y = 0), so a steered egg runs home on flat ground and zone 1 keeps its whole lane;
-- Map.Drop.PlayerBarrier (collision group "PlayerBarrier") across the lane mouth stops characters ("Players") but
-- not eggs ("Eggs"). World remodel (2026-10-16, classic studded bricks): every zone is an
-- open valley around the unchanged lane / shoulders, with invisible collision walls on the old canyon wall planes
-- (x = +-INNER) and the scenery from World/Zones (landmarks, banks, vegetation, props, far silhouettes, ambience);
-- the hub's look comes from World/Hub and World/Shops, the models from World/Recipes via World/Kit. Lighting gets
-- Atmosphere, Bloom, SunRays and ColorCorrection.
--
-- Stable names for Partner B:
--   workspace.Map.KickPad                         Part; players stand on it (top at y = MapBuilder.KickPadTop)
--   workspace.Map.Launch                          the launch station around it (deck, kick spot, pylons, boards)
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
local MapFx = require(script.Parent.MapFx)
local Merchants = require(script.Parent.Merchants)
local WheelBuilder = require(script.Parent.Wheel)
local Boards = require(script.Parent.Boards)
local Kit = require(script.Parent.World.Kit)
local WorldParts = require(script.Parent.World.Parts)
local Palettes = require(script.Parent.World.Palettes)
local Shops = require(script.Parent.World.Shops)
local Hub = require(script.Parent.World.Hub)
local WorldZones = require(script.Parent.World.Zones)
local Coplanar = require(script.Parent.World.Coplanar)
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
local CLIFF = 40 -- ground height above the ocean
-- Flat start: no raised plaza, no ramp (the avalanche reads PlazaY = 0 and RampStart = RampEnd as flat ground).
local LAUNCH_DEPTH = 30 -- the launch deck runs from the lane mouth (z = 0) back to z = -LAUNCH_DEPTH
local BARRIER_Z = 9 -- the player-only barrier across the lane mouth, just past the kick spot
MapBuilder.PlazaY = 0
MapBuilder.RampStart, MapBuilder.RampEnd = 0, 0
MapBuilder.KickPadTop = 0.5
-- Collision groups: the barrier only stops characters (the server puts them in "Players").
MapBuilder.Groups = { players = "Players", eggs = "Eggs", barrier = "PlayerBarrier" }

local rgb = Color3.fromRGB
local YELLOW = rgb(255, 220, 80)
local HUB_CLIFF = rgb(190, 128, 84) -- clay under the hub
local LAWN = rgb(108, 198, 70)
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

------------------------------------------------------------------ plaza pieces

local function pulse(part: Instance, speed: number, phase: number, depth: number)
	CollectionService:AddTag(part, "WorldPulse") -- VFX/Ambient: a sine wave, `phase` (0..1) late, `depth` deep
	part:SetAttribute("Speed", speed)
	part:SetAttribute("Phase", phase)
	part:SetAttribute("Depth", depth)
end

-- The launch station (flat start, 2026-10-22): the kick pad on a stepped brick kick spot at the front of a studded
-- launch deck (x = +-INNER, z = -LAUNCH_DEPTH..0, flush with the lawn and the lane), framed by two red and white
-- launch pylons with blinking beacons: the KICK THE EGG! board on the +X one (left as seen from the pad), the 3-2-1
-- countdown board on the -X one. Hazard stripes run along the deck sides and chevron runway lights on the lane run
-- toward the zones. workspace.Map.KickPad keeps its name and contract (Top attribute).
local function buildLaunch(map: Instance)
	local launch = folder(map, "Launch")
	local steel, dark = rgb(70, 74, 92), rgb(44, 46, 60)
	block(
		launch,
		"LaunchDeck",
		Vector3.new(2 * INNER, 1, LAUNCH_DEPTH),
		CFrame.new(0, -0.5, -LAUNCH_DEPTH / 2),
		rgb(176, 182, 196),
		{ sideStuds = true }
	)
	-- hazard stripes along both deck sides (flat, walked over)
	local n = 10
	local seg = (LAUNCH_DEPTH - 2) / n
	for _, sx in { -1, 1 } do
		for k = 0, n - 1 do
			local h = block(
				launch,
				"Hazard",
				Vector3.new(2, 0.12, seg),
				CFrame.new(sx * (INNER - 1.6), 0.06, -1 - (k + 0.5) * seg),
				if k % 2 == 0 then YELLOW else dark,
				{ collide = false }
			)
			h.CanQuery = false
		end
	end

	-- the kick spot (World kit) and the pad itself
	local spot = Kit.place(
		launch,
		"KickSpot",
		Kit.at(0, 0, 0),
		1,
		Palettes.merge(Palettes.hub, {
			StoneDark = steel,
			Dark = dark,
			Glow = { color = rgb(255, 214, 60), material = Enum.Material.Neon },
			Glow2 = { color = rgb(255, 120, 40), material = Enum.Material.Neon },
			Arrow = rgb(255, 120, 40),
		})
	)
	if spot then
		for _, p in spot:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name == "Glow" or p.Name == "Glow2" then
					pulse(p, 0.6, if p.Name == "Glow" then 0 else 0.5, 0.6)
				elseif p.Name ~= "Arrow" then
					p.CanCollide, p.CanQuery = true, true -- the tiers are walked on and driven over
				end
			end
		end
	end
	local pad = block(map, "KickPad", Vector3.new(7, 0.5, 7), CFrame.new(0, 0.25, 0), rgb(255, 215, 60))
	pad:SetAttribute("Top", MapBuilder.KickPadTop)
	MapFx.emit(anchor(map, "PadFx", Vector3.new(7, 0.2, 7), Vector3.new(0, 0.6, 0)), "PadRise")

	-- launch pylons with the boards on their fronts (facing the pad and the hub)
	local pylonPal = Palettes.merge(Palettes.hub, {
		StoneDark = steel,
		Stone = rgb(176, 182, 196),
		Red = rgb(226, 54, 54),
		White = rgb(248, 248, 248),
		Frame = rgb(60, 62, 78),
		Glow = { color = rgb(255, 70, 60), material = Enum.Material.Neon },
		Glow2 = { color = rgb(255, 214, 60), material = Enum.Material.Neon },
	})
	for _, sx in { -1, 1 } do
		local x, z = sx * 34, -3
		local pylon = Kit.place(launch, "LaunchPylon", Kit.at(x, 0, z), 1, pylonPal)
		WorldParts.proxy(launch, "PylonProxy", Vector3.new(5.4, 28, 5.4), CFrame.new(x, 14, z))
		local beacon: BasePart? = nil
		for _, p in (if pylon then pylon:GetChildren() else {}) do
			if p:IsA("BasePart") and p.Name == "Glow" then
				beacon = p
				pulse(p, 0.7, if sx > 0 then 0 else 0.5, 0.75)
			elseif p:IsA("BasePart") and p.Name == "Glow2" then
				pulse(p, 0.5, (p.Position.Y / 24 + (if sx > 0 then 0 else 0.5)) % 1, 0.5)
			end
		end
		if beacon then
			pulse(WorldParts.light(beacon, rgb(255, 90, 70), 18, 1.2), 0.7, if sx > 0 then 0 else 0.5, 1)
		end
	end
	local sign = Kit.place(
		launch,
		"KickBoard",
		Kit.at(34, 12, -5.9),
		1,
		Palettes.merge(Palettes.hub, { Board = rgb(255, 120, 40), Sign = rgb(255, 120, 40), Trim = YELLOW })
	)
	local face = sign and sign:FindFirstChild("Sign")
	if face and face:IsA("BasePart") then
		WorldParts.text(face, Enum.NormalId.Front, { { "Title", "KICK THE EGG!", 0.1, 0.8 } }, 20)
		WorldParts.light(face, rgb(255, 170, 80), 16, 1)
	end
	local board = Kit.place(
		launch,
		"CountdownBoard",
		Kit.at(-34, 12, -5.6),
		1,
		Palettes.merge(Palettes.hub, {
			Sign = rgb(34, 36, 48),
			Frame = rgb(60, 62, 78),
			Glow = { color = rgb(255, 60, 50), material = Enum.Material.Neon },
			Glow2 = { color = rgb(255, 190, 40), material = Enum.Material.Neon },
			Glow3 = { color = rgb(70, 230, 90), material = Enum.Material.Neon },
		})
	)
	local LAMPS: { [string]: number } = { Glow = 0, Glow2 = 1, Glow3 = 2 }
	for _, p in (if board then board:GetChildren() else {}) do
		local k = LAMPS[p.Name]
		if k and p:IsA("BasePart") then
			pulse(p, 0.45, k / 3, 0.85)
		elseif p.Name == "Sign" and p:IsA("BasePart") then
			WorldParts.text(p, Enum.NormalId.Front, { { "Count", "3  -  2  -  1  -  KICK!", 0.62, 0.3 } }, 20)
		end
	end

	-- chevron runway lights on the lane, running toward the zones
	for i = 0, 4 do
		local z = 13 + i * 6
		for _, side in { -1, 1 } do
			local bar = block(
				launch,
				"Chevron",
				Vector3.new(6, 0.2, 1.4),
				CFrame.new(side * 2.3, 0.1, z) * CFrame.Angles(0, math.rad(side * 35), 0),
				YELLOW,
				{ material = Enum.Material.Neon, collide = false }
			)
			bar.CanQuery = false
			pulse(bar, 0.8, i / 5, 0.85)
		end
	end
end

-- The lane mouth: the player-only barrier (characters stay on the launch deck; eggs pass through).
local function buildDrop(map: Instance)
	local drop = folder(map, "Drop")
	local barrier = block(
		drop,
		"PlayerBarrier",
		Vector3.new(2 * INNER, 70, 2),
		CFrame.new(0, 35, BARRIER_Z),
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
	-- bloom only catches the brightest neon (lava, signs, lamps), so studded colours stay crisp; never blown out
	effect("BloomEffect", "MapBloom", { Intensity = 0.38, Size = 24, Threshold = 1.6 })
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

-- A fence from a to b (world points on the floor; works lifted too): chunky Kit posts every ~8 studs, two rails
-- per section, and one invisible collision proxy along the run (characters use the gate).
local function fenceRun(parent: Instance, a: Vector3, b: Vector3, pal: Kit.Palette)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local n = math.max(1, math.floor(len / 12 + 0.5))
	local seg = len / n
	for k = 0, n do
		local p = a + dir * (seg * k)
		Kit.place(parent, "FencePost", CFrame.lookAt(p, p + dir), 1, pal)
		if k < n then
			local q = a + dir * (seg * (k + 0.5))
			Kit.place(
				parent,
				"FenceRail",
				CFrame.lookAt(q, q + dir) * CFrame.Angles(0, math.rad(90), 0),
				Vector3.new((seg - 1) / 8, 1, 1),
				pal
			)
		end
	end
	WorldParts.proxy(
		parent,
		"FenceProxy",
		Vector3.new(0.9, 5, len),
		CFrame.lookAt((a + b) / 2, b) * CFrame.new(0, 2.5, 0)
	)
end

-- Parts the z-fight pass (World/Coplanar) may nudge by 0.1 stud: decoration only. Gameplay parts keep their exact
-- size: lanes and the ramp (LandingSurface), whatever collides in the kick pad / drop / safe line areas, pen floors
-- and areas, the hub ground, counters, signs, merchants, and anything with a prompt, click detector or SurfaceGui.
local FIXED_NAMES = {
	Lane = true,
	Field = true,
	KickPad = true,
	Floor = true,
	PenArea = true,
	Reserve = true,
	Top = true,
	Ramp = true,
	Spawn = true,
	SpawnPoint = true,
	OwnerAnchor = true,
	PenSign = true,
	Counter = true,
	Sign = true,
	Approach = true,
	Ocean = true,
	Cliff = true,
	CliffBase = true,
	GrassLayer = true,
	EdgeBarrier = true,
	PlayerBarrier = true,
}
local FIXED_AREAS = { Launch = true, Drop = true, SafeLine = true }
-- gameplay models whose parts other code moves (the wheel's rotor pivots from its rest pose)
local FIXED_MODELS = { SpinWheel = true }

local function decorative(map: Instance): Coplanar.Movable
	return function(p: BasePart): boolean
		if FIXED_NAMES[p.Name] or CollectionService:HasTag(p, Chase.Landing.tag) then
			return false
		end
		if
			p:FindFirstChildWhichIsA("ProximityPrompt", true)
			or p:FindFirstChildWhichIsA("SurfaceGui")
			or p:FindFirstChildWhichIsA("ClickDetector")
		then
			return false
		end
		local top: Instance = p
		while top.Parent and top.Parent ~= map do
			top = top.Parent
		end
		if FIXED_AREAS[top.Name] and p.CanCollide then
			return false -- the kick pad, ramp and safe line: only their non-colliding trim may move
		end
		local m = p:FindFirstAncestorWhichIsA("Model")
		while m and m ~= map do
			if FIXED_MODELS[m.Name] or m:FindFirstChildOfClass("Humanoid") then
				return false
			end
			m = m.Parent and m.Parent:FindFirstAncestorWhichIsA("Model")
		end
		return true
	end
end

-- (Re)builds a pen for `level` around its PenArea (whose CFrame never changes): resizes the area, then lays the
-- studded checker floor (parts named "Floor": PlacementController aims at them), a stone border, the fence with a
-- 12-stud gate on the -Z side between two gate posts, and the level's dressing: stepping stones from 2, lanterns on
-- the gate posts and flower planters on the back corners from 3, banners from 5, gold crowns at the last level.
-- Fence colours (Palettes.penFences): wood (1-2), white with blue rails (3-4), dark with gold (5+).
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
				if (tx + tz) % 2 == 0 then rgb(162, 230, 92) else rgb(144, 212, 78)
			)
		end
	end
	local border = rgb(226, 206, 168)
	for _, sx in { -1, 1 } do
		block(
			pen,
			"Border",
			Vector3.new(1.4, 0.36, size.Y + 2.8),
			at(sx * (hw + 0.7), 0.18, 0),
			border,
			{ collide = false }
		)
		block(pen, "Border", Vector3.new(size.X, 0.36, 1.4), at(0, 0.18, sx * (hd + 0.7)), border, { collide = false })
	end
	local style = if level >= 5 then 3 elseif level >= 3 then 2 else 1
	local pal = Palettes.penFences[style]
	local fence = folder(pen, "Fence")
	fenceRun(fence, pt(-hw, hd), pt(hw, hd), pal)
	fenceRun(fence, pt(-hw, -hd), pt(-hw, hd), pal)
	fenceRun(fence, pt(hw, -hd), pt(hw, hd), pal)
	fenceRun(fence, pt(-hw, -hd), pt(-6.5, -hd), pal)
	fenceRun(fence, pt(6.5, -hd), pt(hw, -hd), pal)
	local dress = folder(pen, "Dressing")
	for _, sx in { -7.4, 7.4 } do -- gate posts (taller, capped) either side of the opening
		Kit.place(dress, "GatePost", at(sx, 0, -hd), 1, pal)
		WorldParts.proxy(dress, "GateProxy", Vector3.new(2, 7, 2), at(sx, 3.5, -hd))
	end
	if level >= 2 then -- stepping stones into the pen (flat: nothing to trip over)
		for k = 0, 2 do
			block(
				dress,
				"Stone",
				Vector3.new(3.4, 0.12, 2.6),
				at(if k % 2 == 0 then -0.8 else 0.8, 0.36, -hd + 3 + k * 4),
				rgb(232, 220, 196),
				{ collide = false }
			)
		end
	end
	if level >= 3 then -- lanterns on the gate posts, flower planters on the back corners (outside the fence)
		for _, sx in { -7.4, 7.4 } do
			local lantern = Kit.place(dress, "Lantern", at(sx, 7.8, -hd), 1.1, pal)
			local glow = lantern and lantern:FindFirstChild("Glow")
			if glow and glow:IsA("BasePart") then
				WorldParts.light(glow, rgb(255, 220, 150), 14, 0.8)
			end
		end
		for _, sx in { -1, 1 } do
			Kit.place(dress, "Planter", at(sx * (hw - 2.5), 0, hd + 3.2), 0.8, pal)
			Kit.place(dress, "FlowersB", at(sx * (hw - 2.5), 1.5, hd + 3.2), 0.9, Palettes.hub, { shadow = false })
		end
	end
	if level >= 5 then -- banners on the back corners in the pen's colour
		local flag = Palettes.merge(pal, {
			Cloth = BANNER[((base:GetAttribute("BaseIndex") :: number?) or 1) % #BANNER + 1],
			Cloth2 = rgb(250, 246, 236),
		})
		for _, sx in { -1, 1 } do
			Kit.place(
				dress,
				"FlagPole",
				at(sx * (hw + 2.2), 0, hd + 2.2) * CFrame.Angles(0, math.rad(sx * 90), 0),
				0.85,
				flag
			)
		end
	end
	if level >= PEN_MAX_LEVEL then -- the top level: glowing gold crowns on the gate posts
		for _, sx in { -7.4, 7.4 } do
			block(
				dress,
				"Crown",
				Vector3.new(1.6, 1.6, 1.6),
				at(sx, 9.6, -hd) * CFrame.Angles(0, math.rad(45), 0),
				rgb(255, 214, 80),
				{ material = Enum.Material.Neon, collide = false }
			)
		end
	end
	Coplanar.separate(pen, 0.1, { movable = decorative(base), skipUndersides = true }) -- also after upgrades
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

local function buildSafeZone(map: Instance)
	local zone = folder(map, "SafeZone")
	-- Ground: the clay cliff under the hub and a lawn cut around the launch deck (World.Hub adds paths and gardens)
	block(
		zone,
		"Cliff",
		Vector3.new(2 * W, CLIFF - 1, DEPTH),
		CFrame.new(0, -1 - (CLIFF - 1) / 2, -DEPTH / 2),
		HUB_CLIFF,
		{ sideStuds = true }
	)
	for _, sx in { -1, 1 } do
		block(
			zone,
			"GrassLayer",
			Vector3.new(W - INNER, 1, DEPTH),
			CFrame.new(sx * (INNER + W) / 2, -0.5, -DEPTH / 2),
			LAWN,
			{ sideStuds = true }
		)
	end
	block(
		zone,
		"GrassLayer",
		Vector3.new(2 * INNER, 1, DEPTH - LAUNCH_DEPTH),
		CFrame.new(0, -0.5, -(DEPTH + LAUNCH_DEPTH) / 2),
		LAWN,
		{ sideStuds = true }
	)
	-- Keep players from walking off the cliff (the back edge is an open lookout over the ocean)
	block(zone, "EdgeBarrier", Vector3.new(2 * W, 14, 2), CFrame.new(0, 7, -DEPTH - 1), Color3.new(1, 1, 1), {
		transparency = 1,
		studs = false,
	})
	block(map, "Ocean", Vector3.new(2400, 2, 2400), CFrame.new(0, -CLIFF - 1, 600), rgb(40, 140, 225), {
		material = Enum.Material.SmoothPlastic,
		studs = false,
	})

	-- Shared arrival point on the central path, looking at the launch pad
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 0.25, -72), Vector3.new(0, 0.25, 0))
	spawn.Color = rgb(255, 226, 120)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Duration = 0
	spawn.Parent = zone

	-- set back toward the front, so the straight tutorial trail from the pad to pens 1 / 2 passes in front of them
	Shops.sackShop(zone, -58, -24, -1)
	Shops.petStand(zone, 58, -28, -1)

	local pens, dirs = {}, {}
	for _, slot in PENS do
		table.insert(pens, Vector3.new(slot.cx, 0, slot.cz))
		table.insert(dirs, slot.dir)
	end
	Hub.build(zone, {
		halfWidth = W,
		depth = DEPTH,
		sea = -CLIFF, -- the ocean surface, CLIFF below the ground
		launchDepth = LAUNCH_DEPTH,
		inner = INNER,
		pens = pens,
		penDirs = dirs,
		reserve = PEN_MAX + Vector2.new(4, 4),
		plaza = Vector3.new(0, 0, -155),
		shop = Vector3.new(-58, 0, -24),
		stand = Vector3.new(58, 0, -28),
		spawn = Vector3.new(0, 0, -72),
	})

	-- Prize Wheel on the +X side between pens 2 and 4: as tall as the cliffs behind it
	local wheelRadius = (WALL_H - 4) / 2
	WheelBuilder.build(
		zone,
		CFrame.fromMatrix(Vector3.new(W, wheelRadius + 3, -155), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0)),
		wheelRadius,
		0
	)
	-- Opposite side (-X), facing the wheel: the global Kick Power leaderboard and the top donators board
	local function westFace(z: number, y: number): CFrame
		return CFrame.fromMatrix(Vector3.new(-W, y, z), Vector3.new(0, 0, -1), Vector3.new(0, 1, 0))
	end
	Boards.build(zone, westFace(-141, 25), "Power", rgb(255, 190, 40), 0)
	Boards.build(zone, westFace(-169, 25), "Donations", rgb(200, 80, 255), 0)

	local bases = folder(zone, "Bases")
	for i = 1, #PENS do
		buildBase(bases, i)
	end
end

------------------------------------------------------------------ runway zones

-- A remodelled zone (world remodel 2026-10-16): the same gameplay floor as before (the 48-stud lane tagged
-- LandingSurface, the studded shoulders out to x = +-40, the accent lane edges and lane lights), the canyon walls
-- replaced by invisible collision walls on exactly the same planes (x = +-40, 50 tall), and the open valley around it
-- from World/Zones (decoration only: nothing there collides, takes touches or blocks raycasts).
local function buildWorldZone(parent: Instance, zone: Zones.Zone, art: (any, Instance) -> ())
	local f = folder(parent, "Zone" .. zone.id)
	local z0, len = zone.start, zone.length
	local field = zone.ground:Lerp(Color3.new(0, 0, 0), 0.08)
	local fz0 = z0
	local flen = z0 + len - fz0
	local fmid = fz0 + flen / 2
	local lane = block(f, "Lane", Vector3.new(Chase.RunwayWidth, 2, flen), CFrame.new(0, -1, fmid), zone.ground, {
		sideStuds = true,
	})
	CollectionService:AddTag(lane, Chase.Landing.tag) -- eggs land only on lanes and the ramp (KickService)
	for k = -1, 1, 2 do
		block(
			f,
			"Field",
			Vector3.new(INNER - HALF, 2, flen),
			CFrame.new(k * (HALF + (INNER - HALF) / 2), -1, fmid),
			field,
			{
				sideStuds = true,
			}
		)
		block(f, "LaneEdge", Vector3.new(1.2, 0.4, flen), CFrame.new(k * (HALF + 0.6), 0.2, fmid), zone.accent, {
			sideStuds = true,
		})
		-- the canyon walls' collision, unchanged planes: inner face at x = +-INNER, from the ground up to WALL_H
		local wz = if zone.id == 1 then 0.5 else z0
		local wlen = z0 + len - wz
		WorldParts.proxy(
			f,
			"Wall",
			Vector3.new(WALL_T, WALL_H, wlen),
			CFrame.new(k * (INNER + WALL_T / 2), WALL_H / 2, wz + wlen / 2)
		)
	end
	for lz = fz0 + 6, z0 + len - 4, 16 do
		for k = -1, 1, 2 do
			block(f, "LaneLight", Vector3.new(0.8, 1.2, 0.8), CFrame.new(k * (HALF + 1.6), 0.6, lz), zone.accent, {
				material = Enum.Material.Neon,
				collide = false,
			})
		end
	end
	art(zone, f)
end

local function buildZone(parent: Instance, zone: Zones.Zone)
	local art = WorldZones[zone.id]
	assert(art, `no world composition for zone {zone.id}`)
	buildWorldZone(parent, zone, art)
end

-- Builds (or rebuilds) workspace.Map. Returns the Map model.
function MapBuilder.build(): Model
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	local map = Instance.new("Model")
	map.Name = "Map"
	-- read by client effects (VFX/Avalanche follows the ground; flat start: PlazaY 0, no ramp)
	map:SetAttribute("PlazaY", MapBuilder.PlazaY)
	map:SetAttribute("RampStart", MapBuilder.RampStart)
	map:SetAttribute("RampEnd", MapBuilder.RampEnd)
	map:SetAttribute("CanyonWidth", 2 * INNER)
	setupCollisionGroups()
	applyLighting()

	-- The hub (launch station, safe line, pens, market) and the lanes all sit at track level.
	buildLaunch(map)
	buildSafeLine(map)
	buildSafeZone(map)
	buildDrop(map)

	local runway = folder(map, "Runway")
	for _, zone in Zones do
		buildZone(runway, zone)
	end
	-- The end of the track: the same collision plane as the old end wall (inner face at TRACK_END, WALL_T thick,
	-- WALL_H tall), invisible, behind the Heaven Gate with the Golden Egg trophy on top (World kit).
	local last = Zones[#Zones]
	local endZ = last.start + last.length
	local finale = folder(map, "Finale")
	WorldParts.proxy(
		finale,
		"EndWall",
		Vector3.new(2 * INNER + 2 * WALL_T, WALL_H, WALL_T),
		CFrame.new(0, WALL_H / 2, endZ + WALL_T / 2)
	)
	local heaven = Palettes.zones[last.id] or Palettes.hub
	Kit.place(finale, "HeavenGate", Kit.at(0, 0, endZ + 3, 0), 1, heaven)
	Kit.place(finale, "GoldenEgg", Kit.at(0, 46.4, endZ + 2, 0), 1.05, heaven)
	WorldParts.light(
		WorldParts.anchor(finale, "EggGlow", Vector3.one, Vector3.new(0, 62, endZ - 6)),
		Color3.fromRGB(255, 220, 140),
		50,
		1.4
	)

	Coplanar.separate(map, 0.1, { movable = decorative(map), skipUndersides = true }) -- where pieces meet
	map.Parent = workspace
	return map
end

return MapBuilder
