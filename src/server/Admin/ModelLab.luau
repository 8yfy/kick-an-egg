--!strict
-- The Model Lab (server): a studded preview platform far off the map (built only when first used), temporary
-- copies of registered models, transforms within bounds, honest measurements, QA checks and an isolated test
-- pen. Models come only from Admin/Catalog sources; ServerStorage preview assets are cleaned to visual
-- instances only (scripts and anything interactive removed). Every part is non-collidable, untouchable and
-- unqueryable, so nothing in the lab can affect players or gameplay. Nothing here touches player data, pens,
-- income or ownership. Animation and VFX state is attributes; admin clients play it (Admin/Client/LabView).
--
-- workspace.AdminLab
--   Platform  slab, 8 numbered pads, compare pads A/B (identical spotlights), the fenced test pen, spawn point
--   Models    lab models (attributes LabId, LabSource, LabOwner, ... see apply())
--   Pen       test pen pets (Path* attributes, the same protocol PlotService uses for real pens)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Models = require(Shared.Builders.Models)
local SackGeometry = require(Shared.Builders.SackGeometry)
local Mutations = require(Shared.Config.Mutations)
local Rarities = require(Shared.Config.Rarities)

local Config = require(script.Parent.Config)
local Catalog = require(script.Parent.Catalog)
local Flags = require(script.Parent.Flags)
local PlotService = require(script.Parent.Parent.Services.PlotService)

local ModelLab = {}

local L = Config.Lab
local PAD_COUNT = 8
local PET_SPEED, IDLE_MIN, IDLE_MAX = 5, 2.5, 6 -- the same roaming feel as PlotService

export type Entry = {
	id: string,
	model: Model,
	owner: number,
	ownerName: string,
	source: string,
	kind: string,
	key: string,
	name: string,
	slot: string,
	anchor: CFrame,
	yaw: number,
	scale: number,
	sizeScale: number, -- size mutation scale (test pen), applied under `scale`
	offset: Vector3,
	created: number,
	pen: boolean,
	stripped: number,
	collidable: number,
	roam: { from: Vector3, to: Vector3, t0: number, t1: number, nextAt: number }?,
}

local entries: { [string]: Entry } = {}
local root: Folder? = nil
local pads: { [string]: BasePart } = {}
local penFloor: BasePart? = nil
local spawnPoint: CFrame = CFrame.new(L.origin + Vector3.new(0, 6, -52))

-- Instances a lab model may keep. Everything else (scripts, prompts, click detectors, seats, tools, sounds,
-- body movers, constraints that move things, ...) is destroyed before the model is parented.
local KEEP = {
	Model = true,
	Folder = true,
	Configuration = true,
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	Decal = true,
	Texture = true,
	SurfaceAppearance = true,
	MaterialVariant = false,
	Attachment = true,
	Bone = true,
	Motor6D = true,
	Weld = true,
	WeldConstraint = true,
	ManualWeld = true,
	Snap = true,
	ParticleEmitter = true,
	Beam = true,
	Trail = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	Highlight = true,
	AnimationController = true,
	Animator = true,
	WrapLayer = true,
	WrapTarget = true,
	UICorner = true,
	UIGradient = true,
	UIStroke = true,
	BillboardGui = true,
	SurfaceGui = true,
	Frame = true,
	TextLabel = true,
	ImageLabel = true,
}

local function keep(inst: Instance): boolean
	if inst:IsA("BasePart") then
		return not (inst:IsA("Seat") or inst:IsA("VehicleSeat") or inst:IsA("SpawnLocation") or inst:IsA("Terrain"))
	end
	if inst:IsA("ValueBase") then
		return true
	end
	return KEEP[inst.ClassName] == true
end

local function newPart(name: string, size: Vector3, cf: CFrame, color: Color3, parent: Instance, studs: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = if studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(parent: BasePart, text: string, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(130, 26)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 90
	gui.AlwaysOnTop = false
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = gui
	gui.Parent = parent
end

-- Builds the platform once (lazily: production servers never build it unless an admin uses the lab).
function ModelLab.ensure(): Folder
	if root and root.Parent then
		return root
	end
	local folder = Instance.new("Folder")
	folder.Name = "AdminLab"
	local platform = Instance.new("Model")
	platform.Name = "Platform"
	local o = L.origin
	local rgb = Color3.fromRGB
	newPart("Slab", Vector3.new(172, 4, 124), CFrame.new(o), rgb(163, 162, 165), platform, true)
	newPart("Trim", Vector3.new(176, 2, 128), CFrame.new(o - Vector3.new(0, 2.5, 0)), rgb(27, 42, 53), platform)
	local colors = {
		rgb(196, 40, 28),
		rgb(218, 133, 65),
		rgb(245, 205, 48),
		rgb(164, 189, 71),
		rgb(75, 151, 75),
		rgb(4, 175, 236),
		rgb(13, 105, 172),
		rgb(107, 50, 124),
	}
	for i = 1, PAD_COUNT do
		local x = -70 + (i - 1) * 20
		local pad = newPart(
			`Pad{i}`,
			Vector3.new(16, 1, 16),
			CFrame.new(o + Vector3.new(x, 2.5, -30)),
			colors[i],
			platform,
			true
		)
		label(pad, `PAD {i}`, -1.5)
		pads[`pad{i}`] = pad
	end
	for i, name in { "compareA", "compareB" } do
		local x = if i == 1 then -16 else 16
		local pad = newPart(
			name,
			Vector3.new(24, 1, 24),
			CFrame.new(o + Vector3.new(x, 2.5, 2)),
			rgb(242, 243, 243),
			platform,
			true
		)
		label(pad, if i == 1 then "COMPARE A" else "COMPARE B", -1.5)
		pads[name] = pad
		local lamp = Instance.new("Part")
		lamp.Name = "Lamp"
		lamp.Transparency = 1
		lamp.Anchored = true
		lamp.CanCollide = false
		lamp.CanQuery = false
		lamp.Size = Vector3.one
		lamp.CFrame = CFrame.new(pad.Position + Vector3.new(0, 26, 6)) * CFrame.Angles(-math.rad(90), 0, 0)
		local spot = Instance.new("SpotLight")
		spot.Angle = 70
		spot.Range = 40
		spot.Brightness = 2.2
		spot.Face = Enum.NormalId.Front
		spot.Parent = lamp
		lamp.Parent = platform
	end
	-- test pen: floor + fence (the usable half-size is L.penHalf; 3 studs of margin like a real pen)
	local penCenter = o + Vector3.new(0, 2.25, 38)
	local floor = newPart(
		"PenFloor",
		Vector3.new(L.penHalf * 2 + 6, 0.5, L.penHalf * 2 + 6),
		CFrame.new(penCenter),
		rgb(124, 156, 107),
		platform,
		true
	)
	penFloor = floor
	label(floor, "TEST PEN", -1)
	local half = L.penHalf + 3
	for _, side in
		{ { 0, half, half * 2, 1 }, { 0, -half, half * 2, 1 }, { half, 0, 1, half * 2 }, { -half, 0, 1, half * 2 } }
	do
		newPart(
			"Fence",
			Vector3.new(side[3], 2.4, side[4]),
			CFrame.new(penCenter + Vector3.new(side[1], 1.45, side[2])),
			rgb(124, 92, 70),
			platform,
			true
		)
	end
	local demo = newPart(
		"DemoAnchor",
		Vector3.new(2, 2, 2),
		CFrame.new(o + Vector3.new(0, 4, -12)),
		rgb(255, 255, 255),
		platform
	)
	demo.Transparency = 1
	demo.CanCollide = false
	demo.CanQuery = false
	spawnPoint = CFrame.lookAt(o + Vector3.new(0, 6, -52), o + Vector3.new(0, 6, 0))
	platform.Parent = folder
	local modelsFolder = Instance.new("Folder")
	modelsFolder.Name = "Models"
	modelsFolder.Parent = folder
	local penFolder = Instance.new("Folder")
	penFolder.Name = "Pen"
	penFolder.Parent = folder
	folder.Parent = workspace
	root = folder
	return folder
end

function ModelLab.spawnCFrame(): CFrame
	ModelLab.ensure()
	return spawnPoint
end

-- Measurements --------------------------------------------------------------------------------------------------

function ModelLab.measure(model: Model): { [string]: any }
	local info = {
		parts = 0,
		meshParts = 0,
		specialMeshes = 0,
		unions = 0,
		decals = 0,
		emitters = 0,
		lights = 0,
		motors = 0,
		welds = 0,
		attachments = 0,
		bones = 0,
	}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			info.parts += 1
			if d:IsA("MeshPart") then
				info.meshParts += 1
			elseif d:IsA("UnionOperation") then
				info.unions += 1
			end
		elseif d:IsA("SpecialMesh") then
			info.specialMeshes += 1
		elseif d:IsA("Decal") then
			info.decals += 1
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") then
			info.emitters += 1
		elseif d:IsA("Light") then
			info.lights += 1
		elseif d:IsA("Motor6D") then
			info.motors += 1
		elseif d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			info.welds += 1
		elseif d:IsA("Bone") then
			info.bones += 1
		elseif d:IsA("Attachment") then
			info.attachments += 1
		end
	end
	local _, size = model:GetBoundingBox()
	info.bbox = { math.floor(size.X * 100) / 100, math.floor(size.Y * 100) / 100, math.floor(size.Z * 100) / 100 }
	info.rigged = info.motors > 0 or info.bones > 0
	info.scale = math.floor(model:GetScale() * 1000) / 1000
	return info
end

-- QA checks used by the Pets & Eggs tab and the test pen. Severity: error | warn | info.
function ModelLab.inspect(entry: Entry): { { [string]: string } }
	local model = entry.model
	local issues = {}
	local function add(severity: string, code: string, message: string)
		table.insert(issues, { severity = severity, code = code, message = message })
	end
	local visible, parts = 0, {}
	local anchoredSet: { [BasePart]: boolean } = {}
	local adjacency: { [BasePart]: { BasePart } } = {}
	local function link(a: BasePart?, b: BasePart?)
		if a and b then
			adjacency[a] = adjacency[a] or {}
			adjacency[b] = adjacency[b] or {}
			table.insert(adjacency[a], b)
			table.insert(adjacency[b], a)
		end
	end
	local broken = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			if d.Transparency < 0.98 and d.Size.Magnitude > 0.05 then
				visible += 1
			end
			if d.Anchored then
				anchoredSet[d] = true
			end
		elseif d:IsA("JointInstance") then
			local p0, p1 = d.Part0, d.Part1
			if not (p0 and p1 and p0:IsDescendantOf(model) and p1:IsDescendantOf(model)) then
				broken += 1
			else
				link(p0, p1)
			end
		elseif d:IsA("WeldConstraint") then
			local p0, p1 = d.Part0, d.Part1
			if not (p0 and p1 and p0:IsDescendantOf(model) and p1:IsDescendantOf(model)) then
				broken += 1
			else
				link(p0, p1)
			end
		elseif d:IsA("Attachment") and not (d.Parent and (d.Parent:IsA("BasePart") or d.Parent:IsA("Bone"))) then
			broken += 1
		end
	end
	if visible == 0 then
		add("error", "invisible", "No visible parts (all transparent or zero-size).")
	end
	if broken > 0 then
		add("error", "broken_joints", `{broken} joint(s)/attachment(s) point outside the model or at nothing.`)
	end
	-- parts not held by an anchored part through joints would fall off / float apart
	local held: { [BasePart]: boolean } = {}
	local queue = {}
	for p in anchoredSet do
		held[p] = true
		table.insert(queue, p)
	end
	while #queue > 0 do
		local p = table.remove(queue) :: BasePart
		for _, q in adjacency[p] or {} do
			if not held[q] then
				held[q] = true
				table.insert(queue, q)
			end
		end
	end
	local loose = 0
	for _, p in parts do
		if not held[p] then
			loose += 1
		end
	end
	if loose > 0 then
		add("error", "detached", `{loose} part(s) aren't joined to the model and would fall or float apart.`)
	end
	local info = ModelLab.measure(model)
	if (entry.kind == "pet" or entry.kind == "asset") and not info.rigged then
		add("warn", "unrigged", "No Motor6D joints or bones: idle/walk animations can't move it.")
	end
	if entry.collidable > 0 then
		add("info", "collision", `Source has {entry.collidable} collidable part(s); the lab turns collisions off.`)
	end
	if entry.stripped > 0 then
		add("info", "stripped", `{entry.stripped} disallowed instance(s) (scripts, prompts, ...) were removed.`)
	end
	local cf, size = model:GetBoundingBox()
	local bottom = cf.Position.Y - size.Y / 2
	if bottom < entry.anchor.Position.Y + entry.offset.Y - 0.3 then
		add("warn", "floor_clip", "The model reaches below its pad (clipping into the floor).")
	end
	local biggest = math.max(size.X, size.Y, size.Z)
	if biggest > 60 then
		add("warn", "huge", string.format("Very large: %.0f studs across.", biggest))
	elseif biggest < 0.5 then
		add("warn", "tiny", "Smaller than half a stud.")
	end
	return issues
end

-- Spawning ------------------------------------------------------------------------------------------------------

local function build(e: Catalog.Entry): (Model?, string?)
	local ok, model = pcall(function(): Model?
		if e.kind == "pet" then
			return Models.pet(e.key)
		elseif e.kind == "egg" then
			return Models.egg(e.key)
		elseif e.kind == "sack" then
			local tier = tonumber(e.key)
			return if tier then (SackGeometry.build(tier)) else nil
		elseif e.kind == "asset" then
			local template = Catalog.assetModel(e.key)
			return if template then template:Clone() else nil
		end
		return nil
	end)
	if not ok or typeof(model) ~= "Instance" or not (model :: Instance):IsA("Model") then
		return nil, "The model failed to build."
	end
	return model :: Model, nil
end

-- Removes everything that isn't visual, makes it inert and returns (stripped, collidable).
local function sanitize(model: Model): (number, number)
	local stripped, collidable = 0, 0
	for _, d in model:GetDescendants() do
		if d.Parent and not keep(d) then
			stripped += 1
			d:Destroy()
		end
	end
	local jointed: { [BasePart]: boolean } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Part1 then
			jointed[d.Part1] = true
		end
	end
	local rigged = next(jointed) ~= nil
	local biggest: BasePart? = nil
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.CanCollide then
				collidable += 1
			end
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
			if not biggest or d.Size.Magnitude > biggest.Size.Magnitude then
				biggest = d
			end
		elseif d:IsA("Humanoid") then
			d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	if not model.PrimaryPart then
		model.PrimaryPart = biggest
	end
	if not rigged then
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
	elseif model.PrimaryPart then
		model.PrimaryPart.Anchored = true
	end
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return stripped, collidable
end

local function padTop(name: string): CFrame?
	local pad = pads[name]
	if not pad then
		return nil
	end
	local top = pad.Position + Vector3.new(0, pad.Size.Y / 2, 0)
	return CFrame.lookAt(top, top + Vector3.new(0, 0, -1)) -- models face the spawn point (-Z)
end

-- Places the model: absolute scale, yaw about its anchor, feet on the pad, then the offset.
local function apply(entry: Entry)
	local model = entry.model
	model:ScaleTo(math.clamp(entry.scale * entry.sizeScale, 0.05, 20))
	local base = entry.anchor * CFrame.Angles(0, math.rad(entry.yaw), 0)
	model:PivotTo(base)
	local cf, size = model:GetBoundingBox()
	local lift = entry.anchor.Position.Y - (cf.Position.Y - size.Y / 2)
	model:PivotTo(base + Vector3.new(0, lift, 0) + entry.offset)
	model:SetAttribute("LabYaw", entry.yaw)
	model:SetAttribute("LabScale", entry.scale)
	model:SetAttribute("LabOffset", entry.offset)
	model:SetAttribute("LabSlot", entry.slot)
end

local function tag(entry: Entry, e: Catalog.Entry)
	local m = entry.model
	m.Name = `Lab_{entry.id}`
	m:SetAttribute("LabId", entry.id)
	m:SetAttribute("LabSource", entry.source)
	m:SetAttribute("LabKind", entry.kind)
	m:SetAttribute("LabKey", entry.key)
	m:SetAttribute("LabName", entry.name)
	m:SetAttribute("LabOwner", entry.owner)
	m:SetAttribute("LabOwnerName", entry.ownerName)
	m:SetAttribute("LabRarity", e.rarity)
	m:SetAttribute("LabZone", e.zone)
	m:SetAttribute("LabVersion", e.version)
	m:SetAttribute("ModelKey", entry.key) -- PetFx / VFX read the same attribute as pen models
	m:SetAttribute("Rarity", if Rarities[e.rarity] then e.rarity else "Common")
	m:SetAttribute("PetName", e.name)
	m:SetAttribute("Rigged", ModelLab.measure(m).rigged)
	if entry.kind == "pet" then
		m:SetAttribute("Kind", "Pet")
	elseif entry.kind == "egg" then
		m:SetAttribute("Kind", "Egg")
	end
	if Flags.get("lab.labels") and m.PrimaryPart then
		local _, size = m:GetBoundingBox()
		label(m.PrimaryPart, `{e.name} · {e.version}`, size.Y + 1.5)
	end
end

function ModelLab.count(owner: number?): number
	local n = 0
	for _, entry in entries do
		if not entry.pen and (owner == nil or entry.owner == owner) then
			n += 1
		end
	end
	return n
end

function ModelLab.penCount(): number
	local n = 0
	for _, entry in entries do
		if entry.pen then
			n += 1
		end
	end
	return n
end

function ModelLab.freePad(): string?
	local used = {}
	for _, entry in entries do
		used[entry.slot] = true
	end
	for i = 1, PAD_COUNT do
		if not used[`pad{i}`] then
			return `pad{i}`
		end
	end
	return nil
end

local function remove(entry: Entry)
	entries[entry.id] = nil
	if entry.model.Parent then
		entry.model:Destroy()
	end
end

-- placement: "platform" (first free pad) | "pad1".."pad8" | "compareA" | "compareB" | "nearMe" | "pen"
function ModelLab.spawn(
	player: Player?,
	owner: number,
	ownerName: string,
	source: string,
	placement: string,
	sizeName: string?
): (Entry?, string?)
	local e = Catalog.get(source)
	if not e then
		return nil, "That model isn't in the registry."
	end
	local folder = ModelLab.ensure()
	local anchor: CFrame? = nil
	local slot = placement
	if placement == "platform" then
		local free = ModelLab.freePad()
		if not free then
			return nil, "All 8 pads are in use. Delete a model first."
		end
		slot = free
		anchor = padTop(free)
	elseif placement == "nearMe" then
		local char = player and player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not (hrp and hrp:IsA("BasePart")) then
			return nil, "You need a character to spawn near you."
		end
		local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
		look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
		local spot = hrp.Position + look * L.nearDistance
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char :: Instance, folder }
		local hit = workspace:Raycast(spot + Vector3.new(0, 8, 0), Vector3.new(0, -40, 0), params)
		local ground = if hit then hit.Position else spot - Vector3.new(0, 3, 0)
		anchor = CFrame.lookAt(ground, ground - look)
		slot = `near_{owner}_{HttpService:GenerateGUID(false):sub(1, 6)}`
	elseif placement == "pen" then
		local floor = penFloor :: BasePart
		local top = floor.Position + Vector3.new(0, floor.Size.Y / 2, 0)
		local spot = PlotService.pickSpot(L.penHalf, L.penHalf, ModelLab.penSpots(nil), nil)
		anchor = CFrame.lookAt(top + spot, top + spot + Vector3.new(0, 0, -1))
		slot = `pen_{HttpService:GenerateGUID(false):sub(1, 6)}`
	else
		for _, entry in entries do
			if entry.slot == placement then
				remove(entry) -- a fixed slot (pad / compare pad) holds one model: the new one replaces it
			end
		end
		anchor = padTop(placement)
	end
	if not anchor then
		return nil, "Unknown placement."
	end
	local model, err = build(e)
	if not model then
		return nil, err
	end
	local stripped, collidable = sanitize(model)
	local size = if sizeName then Mutations.Size[sizeName] else nil
	local entry: Entry = {
		id = string.sub(HttpService:GenerateGUID(false), 1, 8),
		model = model,
		owner = owner,
		ownerName = ownerName,
		source = source,
		kind = e.kind,
		key = e.key,
		name = e.name,
		slot = slot,
		anchor = anchor,
		yaw = 0,
		scale = 1,
		sizeScale = if size then size.scale else 1,
		offset = Vector3.zero,
		created = os.time(),
		pen = placement == "pen",
		stripped = stripped,
		collidable = collidable,
		roam = nil,
	}
	tag(entry, e)
	if sizeName and size then
		model:SetAttribute("Size", sizeName)
	end
	apply(entry)
	if entry.pen then
		local here = entry.anchor.Position
		local now = workspace:GetServerTimeNow()
		entry.roam = { from = here, to = here, t0 = now, t1 = now, nextAt = now + math.random() * 2 }
		model:SetAttribute("PathFrom", here)
		model:SetAttribute("PathTo", here)
		model:SetAttribute("PathStart", now)
		model:SetAttribute("PathEnd", now)
		model.Parent = folder:FindFirstChild("Pen")
	else
		model.Parent = folder:FindFirstChild("Models")
	end
	entries[entry.id] = entry
	return entry, nil
end

function ModelLab.get(id: string): Entry?
	return entries[id]
end

-- The admin's newest lab model (the command runner's "latest" target).
function ModelLab.latest(owner: number): Entry?
	local best: Entry? = nil
	for _, entry in entries do
		if entry.owner == owner and not entry.pen and (not best or entry.created >= best.created) then
			best = entry
		end
	end
	return best
end

function ModelLab.ids(): { string }
	local ids = { "latest" }
	for id in entries do
		table.insert(ids, id)
	end
	return ids
end

function ModelLab.transform(entry: Entry, op: string, p: { [string]: any }): (boolean, string?)
	if entry.pen then
		return false, "Test pen pets move on their own; use Clear pen instead."
	end
	if op == "rotate" then
		entry.yaw = (p.yaw or 0) % 360
	elseif op == "scale" then
		entry.scale = math.clamp(p.scale or 1, L.minScale, L.maxScale)
	elseif op == "move" then
		entry.offset = Vector3.new(p.dx or 0, p.dy or 0, p.dz or 0)
	elseif op == "center" then
		entry.offset = Vector3.zero
	elseif op == "reset" then
		entry.yaw, entry.scale, entry.offset = 0, 1, Vector3.zero
	else
		return false, "Unknown transform."
	end
	apply(entry)
	entry.model:SetAttribute("LabTransformRev", (entry.model:GetAttribute("LabTransformRev") or 0) + 1)
	return true, nil
end

function ModelLab.delete(entry: Entry)
	remove(entry)
end

-- Deletes models; `owner` nil = everyone's. `pen` true = test pen pets only, false = lab models only.
function ModelLab.clear(owner: number?, pen: boolean?): number
	local n = 0
	for _, entry in table.clone(entries) do
		if (owner == nil or entry.owner == owner) and (pen == nil or entry.pen == pen) then
			remove(entry)
			n += 1
		end
	end
	return n
end

function ModelLab.list(): { Entry }
	local list = {}
	for _, entry in entries do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return a.created < b.created
	end)
	return list
end

function ModelLab.activeFx(): number
	local n = 0
	for _, entry in entries do
		local fx = entry.model:GetAttribute("LabFx")
		if typeof(fx) == "string" and fx ~= "" then
			n += 1
		end
	end
	return n
end

-- Test pen ------------------------------------------------------------------------------------------------------

local function roamPos(r: { from: Vector3, to: Vector3, t0: number, t1: number }, now: number): Vector3
	if now >= r.t1 or r.t1 <= r.t0 then
		return r.to
	end
	return r.from:Lerp(r.to, (now - r.t0) / (r.t1 - r.t0))
end

-- Pen-local (x, 0, z) spots of the pen pets except `except` (for spacing).
function ModelLab.penSpots(except: string?): { Vector3 }
	local list = {}
	local floor = penFloor
	if not floor then
		return list
	end
	local now = workspace:GetServerTimeNow()
	for id, entry in entries do
		local r = entry.roam
		if entry.pen and id ~= except and r then
			for _, p in { r.to, roamPos(r, now) } do
				local l = p - floor.Position
				table.insert(list, Vector3.new(l.X, 0, l.Z))
			end
		end
	end
	return list
end

local function roamTick()
	local floor = penFloor
	if not floor then
		return
	end
	local top = floor.Position.Y + floor.Size.Y / 2
	local now = workspace:GetServerTimeNow()
	for id, entry in entries do
		local r = entry.roam
		if not (entry.pen and r) or now < r.nextAt or not entry.model.Parent then
			continue
		end
		local here = roamPos(r, now)
		local fromLocal = Vector3.new(here.X - floor.Position.X, 0, here.Z - floor.Position.Z)
		local to = PlotService.pickSpot(L.penHalf, L.penHalf, ModelLab.penSpots(id), fromLocal)
		local target = Vector3.new(floor.Position.X + to.X, top, floor.Position.Z + to.Z)
		local walk = (target - here).Magnitude / PET_SPEED
		r.from, r.to, r.t0, r.t1 = here, target, now, now + walk
		r.nextAt = r.t1 + IDLE_MIN + math.random() * (IDLE_MAX - IDLE_MIN)
		local m = entry.model
		m:SetAttribute("PathFrom", r.from)
		m:SetAttribute("PathTo", r.to)
		m:SetAttribute("PathStart", r.t0)
		m:SetAttribute("PathEnd", r.t1)
	end
end

-- Spacing check for the pen: pets whose current positions overlap their footprints.
function ModelLab.penOverlaps(): { string }
	local now = workspace:GetServerTimeNow()
	local list: { { id: string, pos: Vector3, radius: number } } = {}
	for id, entry in entries do
		if entry.pen and entry.roam then
			local _, size = entry.model:GetBoundingBox()
			table.insert(list, { id = id, pos = roamPos(entry.roam, now), radius = math.max(size.X, size.Z) / 2 })
		end
	end
	local out = {}
	for i = 1, #list do
		for j = i + 1, #list do
			local a, b = list[i], list[j]
			if (a.pos - b.pos).Magnitude < (a.radius + b.radius) * 0.6 then
				table.insert(out, `{a.id} overlaps {b.id}`)
			end
		end
	end
	return out
end

function ModelLab.start()
	Catalog.ensureAssetFolder()
	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(roamTick)
			if not ok then
				warn(`[ModelLab] roam tick failed: {err}`)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		ModelLab.clear(player.UserId) -- an admin's test models leave with them
	end)
	Flags.onChanged(function(id: string, value: any)
		if id == "lab.labels" then
			for _, entry in entries do
				local primary = entry.model.PrimaryPart
				local tagGui = primary and primary:FindFirstChild("Label")
				if tagGui then
					(tagGui :: BillboardGui).Enabled = value == true
				end
			end
		elseif id == "staging.labNight" and root then
			for _, d in root:GetDescendants() do
				if d:IsA("SpotLight") then
					d.Brightness = if value then 0.6 else 2.2
				end
			end
		end
	end)
end

return ModelLab
