--!strict
-- Partner A. Builds the whole map from Config (once on server start, or from the command bar):
--   require(game.ReplicatedStorage.Shared.Builders.Map.MapBuilder).build()
-- Layout (Config/Chase axes): a big open grass plaza (the safe zone, Z < SafeLineZ) closed by plain
-- tall studded dirt walls with grass caps. The runway canyon leaves the plaza's front wall at the kick
-- pad (origin) and runs +Z through the 20 zones between the same plain walls. A row of 6 fenced pens
-- lines the plaza's back wall; each has an upgradeable kick-training station in front of it.
-- No zone signs: the HUD's zone bar names zones.
--
-- Stable names for Partner B:
--   workspace.Map.KickPad                         Part; players stand on it (top at y = MapBuilder.KickPadTop)
--   workspace.Map.SafeZone.Bases.Base<i>          Model, attribute BaseIndex = i (1..6). The server may set
--                                                 OwnerUserId / RackLevel / PenLevel (Config/Upgrades); signs
--                                                 and the station look follow automatically.
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
local Config = script.Parent.Parent.Parent.Config
local Chase = require(Config.Chase)
local Zones = require(Config.Zones)
local Economy = require(Config.Economy)
local Upgrades = require(Config.Upgrades)
local Fx = require(script.Parent.Parent.Parent.VFX.Fx)

local MapBuilder = {}

local HALF = Chase.RunwayWidth / 2
local SAFE_Z = Chase.SafeLineZ
local INNER = 80 -- canyon floor half-width
local PLAZA = 270 -- plaza half-width
local PLAZA_BACK = -270 -- plaza back wall (inner face)
local WALL_T = 24
local PLAZA_WALL_H, CANYON_WALL_H = 70, 56
local BASE_COUNT = 6
local PEN_W, PEN_D, PEN_GAP = 72, 60, 16
local PEN_BACK = PLAZA_BACK + 6
local PEN_FRONT = PEN_BACK + PEN_D
local PROP_BAND = { 15, 20.5 }
MapBuilder.KickPadTop = 0.5

local rgb = Color3.fromRGB
local DIRT, DIRT_DARK = rgb(205, 130, 80), rgb(185, 112, 66)
local GRASS, GRASS_DARK = rgb(110, 205, 70), rgb(95, 185, 60)
local YELLOW = rgb(255, 220, 80)
local SIGN = rgb(32, 38, 52)
local BASE_COLORS = {
	rgb(255, 85, 85),
	rgb(255, 160, 50),
	rgb(90, 210, 90),
	rgb(60, 200, 220),
	rgb(70, 130, 255),
	rgb(170, 100, 255),
}

-- River / stream across each zone's boundary (material, colour, transparency).
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
		if line[6] then -- green price bar behind the text
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

-- Builds a BlockBuilder spec as static scenery (anchored, no root/welds/motors).
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

-- Plain tall wall whose inner face runs along the ground line a -> b, with `inward` pointing into the
-- playable area. Studded dirt body, a grass cap overhanging the inner edge, grass drips hanging down the
-- face, and (optionally) a big two-tone checker on the face.
local function wall(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	inward: Vector3,
	h: number,
	face: Color3,
	top: Color3,
	seed: number,
	checker: boolean?
)
	local along = (b - a).Unit
	local len = (b - a).Magnitude
	local mid = (a + b) / 2
	local rot = CFrame.lookAt(Vector3.zero, along)
	local body = CFrame.new(mid - inward * (WALL_T / 2) + Vector3.new(0, h / 2, 0)) * rot
	block(parent, "Wall", Vector3.new(WALL_T, h, len), body, face, { sideStuds = true })
	block(
		parent,
		"WallCap",
		Vector3.new(WALL_T + 2, 2, len + 2),
		CFrame.new(mid - inward * (WALL_T / 2 - 1) + Vector3.new(0, h + 1, 0)) * rot,
		top
	)
	local rng = Random.new(seed)
	local s = rng:NextNumber(1, 6)
	while s < len - 2 do
		local w = rng:NextNumber(3, 7)
		local dh = rng:NextNumber(2, 9)
		local p = a + along * s + inward * 0.5
		block(
			parent,
			"Drip",
			Vector3.new(1, dh, w),
			CFrame.new(p.X, h - dh / 2 + 0.5, p.Z) * rot,
			top,
			{ studs = false }
		)
		s += w + rng:NextNumber(2, 7)
	end
	if checker then
		local tile = 24
		local cols, rows = math.floor(len / tile), math.floor(h / tile)
		local dark = face:Lerp(Color3.new(0, 0, 0), 0.08)
		for c = 0, cols - 1 do
			for r = 0, rows - 1 do
				if (c + r) % 2 == 0 then
					local p = a + along * ((c + 0.5) * (len / cols)) + inward * 0.1
					block(
						parent,
						"Checker",
						Vector3.new(0.2, h / rows, len / cols),
						CFrame.new(p.X, (r + 0.5) * (h / rows), p.Z) * rot,
						dark,
						{
							sideStuds = true,
							collide = false,
						}
					)
				end
			end
		end
	end
end

------------------------------------------------------------------ plaza

local function buildKickPad(map: Instance)
	local sand, sandDark = rgb(240, 215, 160), rgb(215, 185, 125)
	block(map, "HubStep1", Vector3.new(28, 0.2, 18), CFrame.new(0, 0.1, SAFE_Z + 1 + 9), sandDark)
	block(map, "HubStep2", Vector3.new(18, 0.35, 12), CFrame.new(0, 0.175, SAFE_Z + 1 + 6), sand)
	local up = CFrame.Angles(0, 0, math.rad(90))
	block(
		map,
		"KickPadRim",
		Vector3.new(0.45, 13, 13),
		CFrame.new(0, 0.225, 0) * up,
		rgb(45, 45, 60),
		{ shape = Enum.PartType.Cylinder }
	)
	local pad = block(map, "KickPad", Vector3.new(0.5, 11, 11), CFrame.new(0, 0.25, 0) * up, rgb(255, 215, 60), {
		shape = Enum.PartType.Cylinder,
	})
	pad:SetAttribute("Top", MapBuilder.KickPadTop)
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
	for i, o in { { -12, 0 }, { 12, 0 }, { -12, 9 }, { 12, 9 } } do
		block(
			map,
			"HubCrate" .. i,
			Vector3.new(2, 2, 2),
			CFrame.new(o[1], 1.35, o[2]) * CFrame.Angles(0, math.rad(20 * i), 0),
			rgb(200, 140, 70)
		)
	end
end

local function buildSafeLine(map: Instance)
	local line = folder(map, "SafeLine")
	local tiles = 10
	local w = (2 * INNER) / tiles
	for i = 1, tiles do
		local x = -INNER + (i - 0.5) * w
		block(
			line,
			"Tile",
			Vector3.new(w, 0.12, 2),
			CFrame.new(x, 0.11, SAFE_Z - 1),
			if i % 2 == 0 then rgb(250, 250, 250) else rgb(60, 200, 255),
			{
				collide = false,
			}
		)
	end
	local paint = block(
		line,
		"Paint",
		Vector3.new(9, 0.06, 36),
		CFrame.new(0, 0.16, SAFE_Z - 9) * CFrame.Angles(0, math.rad(-90), 0),
		rgb(255, 255, 255),
		{
			transparency = 1,
			collide = false,
			studs = false,
		}
	)
	surface(paint, Enum.NormalId.Top, { { "Title", "SAFE ZONE", 0.12, 0.76 } }, 10)
	for _, side in { -1, 1 } do
		local cf = CFrame.new(side * 23, 0.16, SAFE_Z - 9)
		block(line, "Shield", Vector3.new(3.4, 0.1, 3), cf, rgb(60, 140, 255), { collide = false })
		block(
			line,
			"ShieldTip",
			Vector3.new(2.4, 0.1, 2.4),
			cf * CFrame.new(0, 0, 1.6) * CFrame.Angles(0, math.rad(45), 0),
			rgb(60, 140, 255),
			{
				collide = false,
			}
		)
		block(line, "ShieldStripe", Vector3.new(0.7, 0.12, 3), cf, rgb(255, 255, 255), { collide = false })
	end
end

local function lamp(parent: Instance, pos: Vector3)
	block(parent, "LampBase", Vector3.new(1.6, 0.6, 1.6), CFrame.new(pos + Vector3.new(0, 0.3, 0)), rgb(60, 60, 70))
	block(parent, "LampPole", Vector3.new(0.6, 8, 0.6), CFrame.new(pos + Vector3.new(0, 4, 0)), rgb(60, 60, 70))
	local bulb = block(
		parent,
		"LampBulb",
		Vector3.new(1.4, 1.4, 1.4),
		CFrame.new(pos + Vector3.new(0, 8.6, 0)),
		rgb(255, 230, 150),
		{
			material = Enum.Material.Neon,
			collide = false,
		}
	)
	local l = Instance.new("PointLight")
	l.Range, l.Brightness, l.Color = 14, 0.8, rgb(255, 220, 150)
	l.Parent = bulb
end

-- Market stall facing -Z (toward the plaza), striped awning, title board, "Open" prompt.
local function stall(parent: Instance, x: number, z: number, title: string, colors: { Color3 }, action: string)
	local m = Instance.new("Model")
	m.Name = title .. "Stall"
	m.Parent = parent
	local wood = rgb(160, 105, 60)
	block(m, "Floor", Vector3.new(14, 0.4, 10), CFrame.new(x, 0.3, z), rgb(200, 170, 120))
	local counter = block(m, "Counter", Vector3.new(12, 3, 2), CFrame.new(x, 2, z - 3), wood)
	block(m, "CounterTop", Vector3.new(12.6, 0.4, 2.6), CFrame.new(x, 3.7, z - 3), rgb(235, 225, 210))
	for i, c in { rgb(255, 90, 90), rgb(255, 210, 60), rgb(90, 200, 255) } do -- goods on the counter
		block(
			m,
			"Goods" .. i,
			Vector3.new(1.4, 1.4, 1.4),
			CFrame.new(x - 4 + i * 2, 4.6, z - 3) * CFrame.Angles(0, math.rad(20 * i), 0),
			c
		)
	end
	for _, ox in { -6, 6 } do
		for _, oz in { -4.5, 4.5 } do
			block(m, "Post", Vector3.new(0.7, 9, 0.7), CFrame.new(x + ox, 4.5, z + oz), wood)
		end
	end
	for i = 1, 7 do
		local ax = x - 7 + (i - 0.5) * 2
		block(
			m,
			"Awning" .. i,
			Vector3.new(2, 0.4, 11),
			CFrame.new(ax, 9.4, z) * CFrame.Angles(math.rad(-12), 0, 0),
			colors[(i % 2) + 1]
		)
	end
	local board = block(m, "Board", Vector3.new(11, 2.8, 0.5), CFrame.new(x, 11.2, z - 5.6), colors[1])
	surface(board, Enum.NormalId.Front, { { "Title", string.upper(title), 0.08, 0.84 } })
	prompt(counter, action, "Open", title)
end

-- Station level look + "+X / kick" board; rebuilt when RackLevel changes tier.
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
			surface(board, Enum.NormalId.Front, {
				{ "Gain", "", 0.08, 0.5, YELLOW },
				{ "Level", "", 0.6, 0.32 },
			}, 24)
		end
		rack = m
	end
	local board = rack and rack:FindFirstChild("SignBoard")
	local gui = board and board:FindFirstChildOfClass("SurfaceGui")
	setText(gui, "Gain", `+{info.gain} Power / kick`)
	setText(gui, "Level", `Training · Lv {level}`)
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
	local gui = board and board:FindFirstChildOfClass("SurfaceGui")
	local owner = if uid > 0 then game:GetService("Players"):GetPlayerByUserId(uid) else nil
	setText(gui, "OwnerLabel", if owner then `{owner.DisplayName}'s Pen` else "Empty Pen")
end

-- Upgrade panel in the reference style: dark board, title, "Level a > Level b", green price bar.
local function upgradeSign(base: Model, name: string, title: string, pos: Vector3, action: string, object: string)
	local board = block(base, name, Vector3.new(6, 4, 0.6), CFrame.new(pos + Vector3.new(0, 3.4, 0)), SIGN)
	block(base, name .. "Post", Vector3.new(0.8, 1.6, 0.8), CFrame.new(pos + Vector3.new(0, 0.8, 0)), SIGN)
	surface(board, Enum.NormalId.Back, {
		{ "Title", title, 0.06, 0.28 },
		{ "Level", "Level 1 > Level 2", 0.36, 0.2, rgb(140, 255, 120) },
		{ "Cost", "$0", 0.62, 0.3, Color3.new(1, 1, 1), rgb(70, 200, 60) },
	})
	prompt(board, action, title, object)
end

-- Wooden fence with posts, caps, two rails and X braces between posts.
local function fenceRun(parent: Instance, a: Vector3, b: Vector3)
	local post, rail = rgb(80, 60, 55), rgb(205, 120, 60)
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local cf = CFrame.lookAt((a + b) / 2, b)
	for _, y in { 1.4, 3.0 } do
		block(parent, "Rail", Vector3.new(0.4, 0.5, len), cf * CFrame.new(0, y, 0), rail, { studs = false })
	end
	local n = math.max(1, math.floor(len / 8 + 0.5))
	for s = 0, n do
		local p = a + dir * (len * s / n)
		block(parent, "Post", Vector3.new(1.1, 4.2, 1.1), CFrame.new(p.X, 2.1, p.Z), post)
		block(parent, "PostCap", Vector3.new(1.4, 0.4, 1.4), CFrame.new(p.X, 4.35, p.Z), post:Lerp(rgb(0, 0, 0), 0.2))
		if s < n then
			local q = a + dir * (len * (s + 0.5) / n)
			local seg = len / n
			local brace = math.sqrt(seg * seg + 1.6 * 1.6)
			local ang = math.atan2(1.6, seg)
			local look = CFrame.lookAt(Vector3.new(q.X, 2.2, q.Z), Vector3.new(q.X, 2.2, q.Z) + dir)
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
	local cx = (i - (BASE_COUNT + 1) / 2) * (PEN_W + PEN_GAP)
	local x0, x1 = cx - PEN_W / 2, cx + PEN_W / 2
	local color = BASE_COLORS[i]
	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base:SetAttribute("BaseIndex", i)
	base.Parent = parent

	-- Open checker-grass floor (12-stud tiles)
	local tile = 12
	for tx = 0, PEN_W / tile - 1 do
		for tz = 0, PEN_D / tile - 1 do
			local px = x0 + (tx + 0.5) * tile
			local pz = PEN_BACK + (tz + 0.5) * tile
			block(
				base,
				"Floor",
				Vector3.new(tile, 0.3, tile),
				CFrame.new(px, 0.15, pz),
				if (tx + tz) % 2 == 0 then rgb(130, 225, 85) else rgb(112, 205, 72)
			)
		end
	end

	-- Fence with a 12-stud entrance in the front (toward the plaza)
	local fence = folder(base, "Fence")
	fenceRun(fence, Vector3.new(x0, 0, PEN_BACK), Vector3.new(x1, 0, PEN_BACK))
	fenceRun(fence, Vector3.new(x0, 0, PEN_BACK), Vector3.new(x0, 0, PEN_FRONT))
	fenceRun(fence, Vector3.new(x1, 0, PEN_BACK), Vector3.new(x1, 0, PEN_FRONT))
	fenceRun(fence, Vector3.new(x0, 0, PEN_FRONT), Vector3.new(cx - 6, 0, PEN_FRONT))
	fenceRun(fence, Vector3.new(cx + 6, 0, PEN_FRONT), Vector3.new(x1, 0, PEN_FRONT))

	-- Invisible egg spots on the open floor (5 x 4, slot 1 nearest the entrance)
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
			CFrame.new(cx + (col - 2) * 12, 0.15, PEN_FRONT - 9 - row * 12),
			Color3.new(1, 1, 1),
			{
				transparency = 1,
				collide = false,
				studs = false,
			}
		)
		ped.Parent = pedestals
	end

	-- Owner board on the back fence, facing the plaza
	local sign = Instance.new("Model")
	sign.Name = "Sign"
	for _, dx in { -7, 7 } do
		block(sign, "Post", Vector3.new(1, 10, 1), CFrame.new(cx + dx, 5, PEN_BACK - 0.8), rgb(80, 60, 55))
	end
	local board = block(sign, "Board", Vector3.new(16, 4, 0.8), CFrame.new(cx, 9.5, PEN_BACK - 0.8), color)
	surface(board, Enum.NormalId.Back, {
		{ "Subtitle", `PEN {i}`, 0.04, 0.3 },
		{ "OwnerLabel", "Empty Pen", 0.34, 0.62 },
	})
	sign.Parent = base

	upgradeSign(base, "PenSign", "Upgrade Pen", Vector3.new(cx - 10, 0, PEN_FRONT + 2), "UpgradePen", `Pen {i}`)

	-- Training station in front of the pen (step faces the plaza) with its upgrade sign
	local rackSlot = CFrame.new(cx + 20, 0, PEN_FRONT + 16) * CFrame.Angles(0, math.pi, 0)
	upgradeSign(
		base,
		"RackSign",
		"Upgrade Station",
		Vector3.new(cx + 10, 0, PEN_FRONT + 24),
		"UpgradeTraining",
		`Station {i}`
	)

	block(base, "SpawnPoint", Vector3.new(2, 1, 2), CFrame.new(cx, 3, PEN_FRONT + 10), Color3.new(1, 1, 1), {
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
	local depth = -PLAZA_BACK
	block(zone, "Base", Vector3.new(2 * PLAZA, 2, depth), CFrame.new(0, -1, -depth / 2), GRASS_DARK)
	-- Big two-tone grass checker
	local tile = 30
	for tx = 0, (2 * PLAZA) / tile - 1 do
		for tz = 0, depth / tile - 1 do
			local px = -PLAZA + (tx + 0.5) * tile
			local pz = -(tz + 0.5) * tile
			if (tx + tz) % 2 == 0 then
				block(zone, "Grass", Vector3.new(tile, 0.1, tile), CFrame.new(px, 0.05, pz), GRASS)
			end
		end
	end
	-- Sand strip along the front wall
	block(zone, "Sand", Vector3.new(2 * PLAZA, 0.14, 24), CFrame.new(0, 0.07, -12), rgb(240, 215, 160))
	-- Walls: front (two segments around the canyon mouth), sides, back
	wall(
		zone,
		Vector3.new(-PLAZA, 0, 0),
		Vector3.new(-INNER, 0, 0),
		Vector3.new(0, 0, -1),
		PLAZA_WALL_H,
		DIRT,
		GRASS,
		101,
		true
	)
	wall(
		zone,
		Vector3.new(INNER, 0, 0),
		Vector3.new(PLAZA, 0, 0),
		Vector3.new(0, 0, -1),
		PLAZA_WALL_H,
		DIRT,
		GRASS,
		102,
		true
	)
	wall(
		zone,
		Vector3.new(-PLAZA, 0, PLAZA_BACK),
		Vector3.new(-PLAZA, 0, WALL_T),
		Vector3.new(1, 0, 0),
		PLAZA_WALL_H,
		DIRT,
		GRASS,
		103,
		true
	)
	wall(
		zone,
		Vector3.new(PLAZA, 0, PLAZA_BACK),
		Vector3.new(PLAZA, 0, WALL_T),
		Vector3.new(-1, 0, 0),
		PLAZA_WALL_H,
		DIRT,
		GRASS,
		104,
		true
	)
	wall(
		zone,
		Vector3.new(-PLAZA - WALL_T, 0, PLAZA_BACK),
		Vector3.new(PLAZA + WALL_T, 0, PLAZA_BACK),
		Vector3.new(0, 0, 1),
		PLAZA_WALL_H,
		DIRT,
		GRASS,
		105,
		true
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(0, 0.1, -60)
	spawn.Color = rgb(250, 250, 250)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Duration = 0
	spawn.Parent = zone

	stall(zone, -110, -14, "Shop", { rgb(70, 190, 255), rgb(250, 250, 255) }, "OpenMenu:Store")
	stall(zone, 110, -14, "Index", { rgb(255, 210, 60), rgb(250, 250, 255) }, "OpenMenu:Index")

	local decor = folder(zone, "Decor")
	-- Path from the safe line to the pens, lamps along it
	block(
		decor,
		"Path",
		Vector3.new(16, 0.16, math.abs(PEN_FRONT + 24)),
		CFrame.new(0, 0.08, (PEN_FRONT - 24) / 2),
		rgb(235, 215, 160),
		{
			collide = false,
		}
	)
	for z = -40, PEN_FRONT + 40, -36 do
		lamp(decor, Vector3.new(-12, 0, z))
		lamp(decor, Vector3.new(12, 0, z))
	end
	for z = -40, PLAZA_BACK + 90, -46 do
		tree(decor, Vector3.new(-PLAZA + 16, 0, z), 2, rgb(70, 170, 60))
		tree(decor, Vector3.new(PLAZA - 16, 0, z - 20), 2, rgb(70, 170, 60))
	end
	-- Fountain in the middle of the plaza
	local fz = -110
	local up = CFrame.Angles(0, 0, math.rad(90))
	block(
		decor,
		"FountainBase",
		Vector3.new(1.2, 18, 18),
		CFrame.new(0, 0.6, fz) * up,
		rgb(200, 200, 210),
		{ shape = Enum.PartType.Cylinder }
	)
	block(decor, "FountainWater", Vector3.new(0.4, 16, 16), CFrame.new(0, 1.1, fz) * up, rgb(90, 180, 245), {
		shape = Enum.PartType.Cylinder,
		material = Enum.Material.Glass,
		transparency = 0.2,
	})
	block(decor, "FountainPillar", Vector3.new(2, 6, 2), CFrame.new(0, 3, fz), rgb(200, 200, 210))
	block(
		decor,
		"FountainBowl",
		Vector3.new(0.8, 6, 6),
		CFrame.new(0, 6.3, fz) * up,
		rgb(200, 200, 210),
		{ shape = Enum.PartType.Cylinder }
	)
	block(decor, "FountainSpout", Vector3.new(1.2, 2.2, 1.2), CFrame.new(0, 7.6, fz), rgb(120, 200, 255), {
		material = Enum.Material.Neon,
		transparency = 0.3,
		collide = false,
	})

	local bases = folder(zone, "Bases")
	for i = 1, BASE_COUNT do
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
				Vector3.new(w, 0.12, 1.2),
				CFrame.new(0, 0.06, z - 3 + i),
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
	for _, x in { -54, -42, 42, 54 } do
		block(
			parent,
			"SteppingStone",
			Vector3.new(3, 0.4, 3),
			CFrame.new(x, 0.2, z) * CFrame.Angles(0, math.rad(x), 0),
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
		wall(
			f,
			Vector3.new(k * INNER, 0, z0),
			Vector3.new(k * INNER, 0, z0 + len),
			Vector3.new(-k, 0, 0),
			CANYON_WALL_H,
			face,
			zone.ground,
			zone.id * 31 + k
		)
	end
	buildRiver(f, zone)

	local patch = zone.ground:Lerp(zone.accent, 0.18)
	for _ = 1, 4 do
		local s = rng:NextInteger(5, 9)
		block(
			f,
			"Patch",
			Vector3.new(s, 0.06, s),
			CFrame.new(rng:NextNumber(-HALF + 5, HALF - 5), 0.03, z0 + rng:NextNumber(10, len - 8))
				* CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 15), 0),
			patch,
			{
				collide = false,
			}
		)
	end
	for i = 1, 14 do
		local x = (if i % 2 == 0 then 1 else -1) * rng:NextNumber(4, INNER - 4)
		local tuft = rng:NextNumber() < 0.6
		local c = if tuft then zone.ground:Lerp(rgb(0, 0, 0), 0.25) else zone.accent:Lerp(rgb(255, 255, 255), 0.2)
		local s = rng:NextNumber(0.5, 1.1)
		block(
			f,
			if tuft then "Tuft" else "Pebble",
			Vector3.new(s, if tuft then s * 1.4 else s * 0.5, s),
			CFrame.new(x, s * 0.3, z0 + rng:NextNumber(8, len - 4))
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
		local z = z0 + 15 + k * 30 + rng:NextNumber(-6, 6)
		local yaw = CFrame.Angles(0, math.rad(rng:NextInteger(0, 7) * 45), 0)
		stamp(
			kinds[k % #kinds + 1],
			CFrame.new(sideSign * rng:NextNumber(PROP_BAND[1], PROP_BAND[2]), 0, z) * yaw,
			rng:NextNumber(0.85, 1.1),
			props
		)
		for _, s in { -1, 1 } do
			local fz = z0 + 10 + rng:NextNumber(0, len - 20)
			stamp(
				kinds[(k + (if s > 0 then 1 else 0)) % #kinds + 1],
				CFrame.new(s * rng:NextNumber(HALF + 10, INNER - 8), 0, fz) * yaw,
				rng:NextNumber(1.4, 2.1),
				props
			)
		end
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
	wall(
		map,
		Vector3.new(-INNER - WALL_T, 0, endZ),
		Vector3.new(INNER + WALL_T, 0, endZ),
		Vector3.new(0, 0, -1),
		CANYON_WALL_H,
		last.ground:Lerp(DIRT, 0.55),
		last.ground,
		999
	)

	map.Parent = workspace
	return map
end

return MapBuilder
