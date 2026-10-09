--!strict
-- Partner A. Builds the whole map from Config (once on server start, or from the command bar):
--   require(game.ReplicatedStorage.Shared.Builders.Map.MapBuilder).build()
-- Layout (Config/Chase axes): a canyon of terraced studded cliffs. The runway (20 zones along +Z) runs
-- down the canyon floor; behind the kick pad (origin) a wide plaza holds 8 fenced pens, each with an
-- upgradeable training rack, plus shop/index stalls. No zone signs: the HUD's zone bar names zones.
--
-- Stable names for Partner B:
--   workspace.Map.KickPad                         Part; players stand on it (top at y = MapBuilder.KickPadTop)
--   workspace.Map.SafeZone.Bases.Base<i>          Model, attribute BaseIndex = i (1..8). The server sets
--                                                 OwnerUserId / RackLevel / PenLevel (Config/Upgrades) and the
--                                                 signs, rack look and unlocked slots follow automatically.
--     .SpawnPoint                                 invisible Part where the owner (re)spawns
--     .Sign.Board.SurfaceGui.OwnerLabel           TextLabel with the owner's name
--     .Pedestals.Pedestal<n>                      Model, attribute Slot = n, PrimaryPart = Top
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
local INNER = 80 -- canyon floor half-width along the runway
local PLAZA = 116 -- plaza half-width (= outer edge of the runway cliffs, so they meet seamlessly)
local PLAZA_BACK = -280
local TERRACE_W, TERRACE_H = 12, 14
local BASE_COUNT = 8
local PEN_W, PEN_D = 60, 48
local PEN_X = 30 -- inner (entrance) edge of the pens
local PEN_Z = { -48, -108, -168, -228 }
local PROP_BAND = { 15, 20.5 }
MapBuilder.KickPadTop = 0.5

local rgb = Color3.fromRGB
local DIRT = rgb(170, 110, 70)
local YELLOW = rgb(255, 220, 80)
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

-- River / stream across each zone's boundary (material, colour, transparency).
type River = { color: Color3, material: Enum.Material?, transparency: number? }
local WATER: River = { color = rgb(80, 170, 240), transparency = 0.15 }
local RIVERS: { [number]: River | string } = {
	[1] = WATER,
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

-- SurfaceGui text lines: { { name, text, yScale, hScale, color? } }
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
		l.Position = UDim2.fromScale(0.05, line[3])
		l.Size = UDim2.fromScale(0.9, line[4])
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = line[5] or Color3.new(1, 1, 1)
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Parent = l
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

------------------------------------------------------------------ canyon cliffs

-- Three studded terraces stepping away from the floor along X (side = -1/1), Z from z0 to z1,
-- each topped with a grass/snow cap and a few drips hanging over the inner edge.
local function cliffX(
	parent: Instance,
	side: number,
	inner: number,
	z0: number,
	z1: number,
	face: Color3,
	top: Color3,
	seed: number
)
	local len, mid = math.abs(z1 - z0), (z0 + z1) / 2
	local rng = Random.new(seed)
	for k = 1, 3 do
		local x0 = inner + (k - 1) * TERRACE_W
		local w = 3 * TERRACE_W - (k - 1) * TERRACE_W
		local h = k * TERRACE_H
		local cx = side * (x0 + w / 2)
		block(
			parent,
			"Terrace" .. k,
			Vector3.new(w, h, len),
			CFrame.new(cx, h / 2, mid),
			face:Lerp(Color3.new(0, 0, 0), (k - 1) * 0.06),
			{
				sideStuds = true,
			}
		)
		block(parent, "Cap" .. k, Vector3.new(w + 0.8, 1, len), CFrame.new(cx - side * 0.4, h + 0.5, mid), top)
		for _ = 1, 3 do
			local dh = rng:NextNumber(1.5, 4)
			local dz = rng:NextNumber(-len / 2 + 4, len / 2 - 4)
			block(
				parent,
				"Drip",
				Vector3.new(0.8, dh, rng:NextNumber(2, 5)),
				CFrame.new(side * (x0 - 0.2), h - dh / 2 + 0.2, mid + dz),
				top,
				{ studs = false }
			)
		end
	end
end

-- Same along Z (back walls), stepping toward `dir` (-1 = -Z, 1 = +Z) from `inner`.
local function cliffZ(parent: Instance, dir: number, inner: number, halfWidth: number, face: Color3, top: Color3)
	for k = 1, 3 do
		local z0 = inner + dir * (k - 1) * TERRACE_W
		local d = 3 * TERRACE_W - (k - 1) * TERRACE_W
		local h = k * TERRACE_H
		local cz = z0 + dir * d / 2
		local w = 2 * (halfWidth + 3 * TERRACE_W)
		block(
			parent,
			"Terrace" .. k,
			Vector3.new(w, h, d),
			CFrame.new(0, h / 2, cz),
			face:Lerp(Color3.new(0, 0, 0), (k - 1) * 0.06),
			{ sideStuds = true }
		)
		block(parent, "Cap" .. k, Vector3.new(w, 1, d + 0.8), CFrame.new(0, h + 0.5, cz - dir * 0.4), top)
	end
end

------------------------------------------------------------------ plaza

local function buildKickPad(map: Instance)
	local sand, sandDark = rgb(240, 215, 160), rgb(215, 185, 125)
	-- Stepped sand hub on the runway side of the safe line (the line is at z = SafeLineZ)
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
	for i, o in { { -12, 0 }, { 12, 0 }, { -12, 9 }, { 12, 9 } } do -- corner crates
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
	local tiles = 20
	local w = (2 * PLAZA) / tiles
	for i = 1, tiles do
		local x = -PLAZA + (i - 0.5) * w
		block(
			line,
			"Tile",
			Vector3.new(w, 0.12, 2),
			CFrame.new(x, 0.06, SAFE_Z - 1),
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
		CFrame.new(0, 0.16, SAFE_Z - 7) * CFrame.Angles(0, math.rad(-90), 0),
		rgb(255, 255, 255),
		{
			transparency = 1,
			collide = false,
			studs = false,
		}
	)
	surface(paint, Enum.NormalId.Top, { { "Title", "SAFE ZONE", 0.12, 0.76 } }, 10)
	for _, side in { -1, 1 } do -- blue shields either side of the text
		local cf = CFrame.new(side * 23, 0.16, SAFE_Z - 7)
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

local function stall(parent: Instance, x: number, z: number, title: string, colors: { Color3 }, action: string)
	local m = Instance.new("Model")
	m.Name = title .. "Stall"
	m.Parent = parent
	local wood = rgb(160, 105, 60)
	block(m, "Floor", Vector3.new(11, 0.4, 8), CFrame.new(x, 0.2, z), rgb(200, 170, 120))
	local counter = block(m, "Counter", Vector3.new(10, 3, 2), CFrame.new(x, 1.9, z + 2.5), wood)
	block(m, "CounterTop", Vector3.new(10.6, 0.4, 2.6), CFrame.new(x, 3.6, z + 2.5), rgb(235, 225, 210))
	for _, ox in { -5, 5 } do
		for _, oz in { -3.5, 3.5 } do
			block(m, "Post", Vector3.new(0.6, 8, 0.6), CFrame.new(x + ox, 4, z + oz), wood)
		end
	end
	for i = 1, 6 do -- striped awning, tilted toward the front
		local ax = x - 5.5 + (i - 0.5) * (11 / 6)
		block(
			m,
			"Awning" .. i,
			Vector3.new(11 / 6, 0.4, 9),
			CFrame.new(ax, 8.4, z) * CFrame.Angles(math.rad(12), 0, 0),
			colors[(i % 2) + 1]
		)
	end
	local board = block(m, "Board", Vector3.new(9, 2.4, 0.4), CFrame.new(x, 9.9, z + 4.6), colors[1])
	surface(board, Enum.NormalId.Back, { { "Title", string.upper(title), 0.08, 0.84 } })
	prompt(counter, action, "Open", title)
end

local function setText(gui: Instance?, name: string, text: string)
	local l = gui and gui:FindFirstChild(name)
	if l and l:IsA("TextLabel") then
		l.Text = text
	end
end

-- Rebuilds the rack model for the base's RackLevel and refreshes its sign and billboard.
local function refreshRack(base: Model, slot: CFrame)
	local level = math.clamp((base:GetAttribute("RackLevel") :: number?) or 1, 1, #Upgrades.Rack.levels)
	local info = Upgrades.Rack.levels[level]
	local rack = base:FindFirstChild("TrainingRack")
	if not (rack and rack:GetAttribute("Tier") == info.tier) then
		if rack then
			rack:Destroy()
		end
		local m = stamp(TrainingRack.spec(info.tier), slot, 1, base, true, "TrainingRack")
		m:SetAttribute("Tier", info.tier)
		local plate = m:FindFirstChild("Plate")
		if plate and plate:IsA("BasePart") then
			plate.CanCollide = true
			plate.CanQuery = true
			m.PrimaryPart = plate
		end
		local beam = m:FindFirstChild("Beam")
		if beam and beam:IsA("BasePart") then
			local gui = Instance.new("BillboardGui")
			gui.Name = "Info"
			gui.Size = UDim2.fromOffset(220, 70)
			gui.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
			gui.MaxDistance = 90
			gui.LightInfluence = 0
			gui.Parent = beam
			local lines: { { any } } = { { "Gain", 0, 0.6, YELLOW }, { "Level", 0.6, 0.4, Color3.new(1, 1, 1) } }
			for i, line in lines do
				local l = Instance.new("TextLabel")
				l.Name = line[1]
				l.BackgroundTransparency = 1
				l.Position = UDim2.fromScale(0, line[2])
				l.Size = UDim2.fromScale(1, line[3])
				l.Font = Enum.Font.FredokaOne
				l.TextScaled = true
				l.TextColor3 = line[4]
				local s = Instance.new("UIStroke")
				s.Thickness = 3
				s.Parent = l
				l.LayoutOrder = i
				l.Parent = gui
			end
		end
	end
	rack = base:FindFirstChild("TrainingRack")
	local beam = rack and rack:FindFirstChild("Beam")
	local info2 = beam and beam:FindFirstChild("Info")
	setText(info2, "Gain", `+{info.gain} Kick Power / kick`)
	setText(info2, "Level", `Training Rack · Lv {level}`)
	local sign = base:FindFirstChild("RackSign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	local nextInfo = Upgrades.Rack.levels[level + 1]
	setText(gui, "Level", if nextInfo then `Level {level} > Level {level + 1}` else `Level {level} (MAX)`)
	setText(gui, "Cost", if nextInfo then `${Fx.formatNumber(nextInfo.cost)}` else "MAXED")
end

local function penSlots(level: number): number
	return math.min(Economy.PlotSlots.base + (level - 1) * Upgrades.Pen.slotsPerLevel, Economy.PlotSlots.max)
end

local function refreshPen(base: Model)
	local level = math.max(1, (base:GetAttribute("PenLevel") :: number?) or 1)
	local slots = penSlots(level)
	local maxed = slots >= Economy.PlotSlots.max
	local sign = base:FindFirstChild("PenSign")
	local gui = sign and sign:FindFirstChildOfClass("SurfaceGui")
	setText(gui, "Level", if maxed then `Level {level} (MAX)` else `Level {level} > Level {level + 1}`)
	setText(
		gui,
		"Cost",
		if maxed then "MAXED" else `${Fx.formatNumber(Upgrades.Pen.costBase * Upgrades.Pen.costGrowth ^ (level - 1))}`
	)
	local peds = base:FindFirstChild("Pedestals")
	if peds then
		for _, ped in peds:GetChildren() do
			local n = ped:GetAttribute("Slot") :: number?
			local top = ped:FindFirstChild("Top")
			if n and top and top:IsA("BasePart") then
				local open = n <= slots
				top.Color = if open then rgb(250, 248, 240) else rgb(110, 110, 120)
				top.Material = if open then Enum.Material.Plastic else Enum.Material.Slate
			end
		end
	end
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

local function buildBase(parent: Instance, i: number)
	local side = if i <= BASE_COUNT / 2 then -1 else 1
	local cz = PEN_Z[(i - 1) % #PEN_Z + 1]
	local x0, x1 = side * PEN_X, side * (PEN_X + PEN_W) -- inner (entrance) and outer edges
	local cx = (x0 + x1) / 2
	local color = BASE_COLORS[i]
	local base = Instance.new("Model")
	base.Name = "Base" .. i
	base:SetAttribute("BaseIndex", i)
	base.Parent = parent

	-- Checker grass floor (12-stud tiles, real studs)
	local g1, g2 = rgb(120, 215, 80), rgb(100, 195, 70)
	for tx = 0, 4 do
		for tz = 0, 3 do
			local px = x0 + side * (tx + 0.5) * (PEN_W / 5)
			local pz = cz - PEN_D / 2 + (tz + 0.5) * (PEN_D / 4)
			block(
				base,
				"Floor",
				Vector3.new(PEN_W / 5, 0.3, PEN_D / 4),
				CFrame.new(px, 0.15, pz),
				if (tx + tz) % 2 == 0 then g1 else g2
			)
		end
	end

	-- Wooden fence: posts every ~8 studs, two rails, X braces; 10-stud entrance on the inner side.
	local post, rail = rgb(80, 60, 55), rgb(200, 120, 60)
	local fence = folder(base, "Fence")
	local function fenceRun(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		local dir = (b - a).Unit
		local cf = CFrame.lookAt((a + b) / 2, b)
		for _, y in { 1.4, 2.8 } do
			block(
				fence,
				"Rail",
				Vector3.new(0.4, 0.45, len),
				cf * CFrame.new(0, y - (a.Y + b.Y) / 2, 0),
				rail,
				{ studs = false }
			)
		end
		local n = math.max(1, math.floor(len / 8 + 0.5))
		for s = 0, n do
			local p = a + dir * (len * s / n)
			block(fence, "Post", Vector3.new(1, 3.8, 1), CFrame.new(p.X, 1.9, p.Z), post)
			block(
				fence,
				"PostCap",
				Vector3.new(1.3, 0.4, 1.3),
				CFrame.new(p.X, 3.95, p.Z),
				post:Lerp(rgb(0, 0, 0), 0.2)
			)
			if s < n then
				local q = a + dir * (len * (s + 0.5) / n)
				local seg = len / n
				local brace = math.sqrt(seg * seg + 1.4 * 1.4)
				local ang = math.atan2(1.4, seg)
				local look = CFrame.lookAt(Vector3.new(q.X, 2.1, q.Z), Vector3.new(q.X, 2.1, q.Z) + dir)
				block(
					fence,
					"Brace",
					Vector3.new(0.3, 0.3, brace),
					look * CFrame.Angles(ang, 0, 0),
					rail,
					{ studs = false }
				)
				block(
					fence,
					"Brace",
					Vector3.new(0.3, 0.3, brace),
					look * CFrame.Angles(-ang, 0, 0),
					rail,
					{ studs = false }
				)
			end
		end
	end
	local zf, zb = cz - PEN_D / 2, cz + PEN_D / 2
	fenceRun(Vector3.new(x0, 0, zf), Vector3.new(x1, 0, zf))
	fenceRun(Vector3.new(x0, 0, zb), Vector3.new(x1, 0, zb))
	fenceRun(Vector3.new(x1, 0, zf), Vector3.new(x1, 0, zb))
	fenceRun(Vector3.new(x0, 0, zf), Vector3.new(x0, 0, cz - 5))
	fenceRun(Vector3.new(x0, 0, cz + 5), Vector3.new(x0, 0, zb))

	-- Hatch slots: round stone pads in a 5 x 4 grid; slots 1..8 nearest the entrance.
	local pedestals = folder(base, "Pedestals")
	local rows = { -18, -6, 6, 18 }
	local up = CFrame.Angles(0, 0, math.rad(90))
	for n = 1, Economy.PlotSlots.max do
		local col, row = (n - 1) // #rows, (n - 1) % #rows + 1
		local x, z = side * (PEN_X + 10 + col * 10), cz + rows[row]
		local ped = Instance.new("Model")
		ped.Name = "Pedestal" .. n
		ped:SetAttribute("Slot", n)
		block(
			ped,
			"Base",
			Vector3.new(0.5, 4.4, 4.4),
			CFrame.new(x, 0.55, z) * up,
			color:Lerp(rgb(0, 0, 0), 0.35),
			{ shape = Enum.PartType.Cylinder }
		)
		ped.PrimaryPart =
			block(ped, "Top", Vector3.new(0.3, 3.4, 3.4), CFrame.new(x, 0.9, z) * up, rgb(250, 248, 240), {
				shape = Enum.PartType.Cylinder,
			})
		ped.Parent = pedestals
	end

	-- Owner sign arching over the entrance
	local sign = Instance.new("Model")
	sign.Name = "Sign"
	for _, dz in { -6, 6 } do
		block(sign, "Post", Vector3.new(1, 9, 1), CFrame.new(x0 - side * 0.5, 4.5, cz + dz), post)
	end
	local board = block(sign, "Board", Vector3.new(1, 3, 14), CFrame.new(x0 - side * 0.5, 9.5, cz), color)
	surface(board, if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left, {
		{ "Subtitle", `PEN {i}`, 0.04, 0.3 },
		{ "OwnerLabel", "Empty Pen", 0.34, 0.62 },
	})
	sign.Parent = base

	-- "Upgrade Pen" panel by the entrance
	local penSign =
		block(base, "PenSign", Vector3.new(0.6, 3.2, 4.6), CFrame.new(x0 - side * 1.4, 2.6, cz + 9), rgb(40, 45, 60))
	block(base, "PenSignPost", Vector3.new(0.5, 1.4, 0.5), CFrame.new(x0 - side * 1.4, 0.7, cz + 9), rgb(40, 45, 60))
	surface(penSign, if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left, {
		{ "Title", "Upgrade Pen", 0.04, 0.3 },
		{ "Level", "Level 1 > Level 2", 0.36, 0.22, rgb(140, 255, 120) },
		{ "Cost", "$0", 0.62, 0.32, rgb(120, 255, 110) },
	})
	prompt(penSign, "UpgradePen", "Upgrade Pen", `Pen {i}`)

	-- Training rack in the gap behind the pen, facing the avenue, with its upgrade panel.
	local rz = zb + 6
	local rackSlot = CFrame.new(side * 40, 0, rz)
		* CFrame.Angles(0, if side < 0 then math.rad(-90) else math.rad(90), 0)
	local rackSign =
		block(base, "RackSign", Vector3.new(0.6, 3.2, 4.6), CFrame.new(side * 32, 2.6, rz + 3), rgb(40, 45, 60))
	block(base, "RackSignPost", Vector3.new(0.5, 1.4, 0.5), CFrame.new(side * 32, 0.7, rz + 3), rgb(40, 45, 60))
	surface(rackSign, if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left, {
		{ "Title", "Upgrade Rack", 0.04, 0.3 },
		{ "Level", "Level 1 > Level 2", 0.36, 0.22, rgb(140, 255, 120) },
		{ "Cost", "$0", 0.62, 0.32, rgb(120, 255, 110) },
	})
	prompt(rackSign, "UpgradeTraining", "Upgrade Rack", `Rack {i}`)

	block(base, "SpawnPoint", Vector3.new(2, 1, 2), CFrame.new(side * (PEN_X + 4), 3, cz), Color3.new(1, 1, 1), {
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
	block(zone, "Grass", Vector3.new(2 * PLAZA, 2, depth), CFrame.new(0, -1, -depth / 2), rgb(115, 205, 80))
	block(
		zone,
		"Path",
		Vector3.new(Chase.RunwayWidth, 0.1, depth + SAFE_Z - 8),
		CFrame.new(0, 0.05, (SAFE_Z + PLAZA_BACK + 8) / 2),
		rgb(235, 215, 160),
		{
			collide = false,
		}
	)
	local dirtFace, grassTop = DIRT, rgb(110, 200, 70)
	cliffX(zone, -1, PLAZA, 0, PLAZA_BACK, dirtFace, grassTop, 11)
	cliffX(zone, 1, PLAZA, 0, PLAZA_BACK, dirtFace, grassTop, 12)
	cliffZ(zone, -1, PLAZA_BACK, PLAZA, dirtFace, grassTop)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.2, 10)
	spawn.CFrame = CFrame.new(0, 0.1, -40)
	spawn.Color = rgb(250, 250, 250)
	spawn.Material = Enum.Material.Plastic
	spawn.TopSurface = Enum.SurfaceType.Studs
	spawn.Duration = 0
	spawn.Parent = zone

	stall(zone, -40, -14, "Shop", { rgb(70, 190, 255), rgb(250, 250, 255) }, "OpenMenu:Store")
	stall(zone, 40, -14, "Index", { rgb(255, 210, 60), rgb(250, 250, 255) }, "OpenMenu:Index")

	local decor = folder(zone, "Decor")
	for z = -30, PLAZA_BACK + 20, -40 do
		lamp(decor, Vector3.new(-26, 0, z))
		lamp(decor, Vector3.new(26, 0, z))
	end
	for z = -20, PLAZA_BACK + 20, -36 do
		tree(decor, Vector3.new(-108, 0, z), 1.8, rgb(70, 170, 60))
		tree(decor, Vector3.new(108, 0, z - 14), 1.8, rgb(70, 170, 60))
	end
	-- Fountain at the end of the avenue
	local fz = PLAZA_BACK + 14
	local up = CFrame.Angles(0, 0, math.rad(90))
	block(
		decor,
		"FountainBase",
		Vector3.new(1.2, 16, 16),
		CFrame.new(0, 0.6, fz) * up,
		rgb(200, 200, 210),
		{ shape = Enum.PartType.Cylinder }
	)
	block(decor, "FountainWater", Vector3.new(0.4, 14, 14), CFrame.new(0, 1.1, fz) * up, rgb(90, 180, 245), {
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
	if not r or zone.id == 1 then
		return -- the kick pad sits on zone 1's boundary
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
	for _, x in { -54, -42, 42, 54 } do -- stepping stones
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
		cliffX(f, k, INNER, z0, z0 + len, face, zone.ground, zone.id * 31 + k)
	end
	buildRiver(f, zone)

	-- Ground detail: tufts, pebbles and patches (non-colliding)
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

	-- Props: runway edges, canyon fields, and up on the terraces.
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
		local tk = rng:NextInteger(1, 3)
		local tx = -sideSign * (INNER + (tk - 1) * TERRACE_W + TERRACE_W / 2)
		stamp(
			kinds[(k + 1) % #kinds + 1],
			CFrame.new(tx, tk * TERRACE_H + 1, z + 10) * yaw,
			rng:NextNumber(1.6, 2.4),
			props
		)
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
	cliffZ(map, 1, last.start + last.length, INNER, last.ground:Lerp(DIRT, 0.55), last.ground)

	map.Parent = workspace
	return map
end

return MapBuilder
