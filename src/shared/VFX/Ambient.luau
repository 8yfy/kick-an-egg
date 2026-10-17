--!strict
-- Partner A. World ambient motion on the client, one shared loop instead of hundreds of scripts (world remodel
-- 2026-10-15). Everything here is local, decorative and anchored; gameplay surfaces never move.
--   * Textures tagged "WorldScroll" (attributes SpeedU / SpeedV, studs per second) scroll: waterfalls, rivers, neon.
--   * ParticleEmitters tagged "WorldFx" (Builders/Map/World/Fx: attributes BaseRate, CullDist) switch off past their
--     cull distance and run at a lower rate on low graphics quality.
--   * Models tagged "WorldSway" (attributes Amp = degrees, Speed = Hz) lean back and forth around their base
--     (trees, flowers, banners); "WorldBob" models (Amp = studs, Speed = Hz) float up and down (islands, crystals).
--     "WorldSpin" models (Speed = degrees / second) turn around their pivot's look axis (windmill sails, gears), or
--     around Y with attribute Axis = "Y" (a lighthouse beam, the shop's roof glove).
--     Only models within SWAY_RANGE of the camera move, a budgeted slice of them per frame, with one BulkMoveTo.
--   * PointLights and Neon parts tagged "WorldPulse" (attribute Speed) breathe in brightness.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Ambient = {}

local SWAY_RANGE = 220
local CULL_EVERY = 0.5
local MOVERS_PER_FRAME = 60

type Mover = {
	model: Model,
	kind: string,
	base: CFrame,
	parts: { BasePart },
	rel: { CFrame },
	amp: number,
	speed: number,
	phase: number,
	near: boolean,
	axisY: boolean, -- spin: around Y instead of the look axis
}

local movers: { Mover } = {}
local spinners: { Mover } = {} -- updated every frame (fast motion), not in the budgeted slices
local moverIndex: { [Model]: Mover } = {}
local scrolls: { Texture } = {}
local pulses: { Instance } = {}
local started = false

local function quality(): number
	local ok, level = pcall(function()
		local gs = UserSettings():GetService("UserGameSettings")
		return gs.SavedQualityLevel.Value -- 0 = automatic, 1..10
	end)
	if not ok or typeof(level) ~= "number" or level == 0 then
		return 0.75
	end
	return math.clamp(0.35 + 0.65 * (level / 10), 0.35, 1)
end

local function addMover(model: Instance, kind: string)
	if not model:IsA("Model") or moverIndex[model] then
		return
	end
	local base = model:GetPivot()
	local parts, rel = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(rel, base:ToObjectSpace(d.CFrame))
		end
	end
	local amp = model:GetAttribute("Amp")
	local speed = model:GetAttribute("Speed")
	local m: Mover = {
		model = model,
		kind = kind,
		base = base,
		parts = parts,
		rel = rel,
		amp = if typeof(amp) == "number" then amp else (if kind == "sway" then 2.5 else 1),
		speed = if typeof(speed) == "number" then speed else 0.25,
		phase = (base.X * 0.37 + base.Z * 0.23) % (math.pi * 2),
		near = false,
		axisY = model:GetAttribute("Axis") == "Y",
	}
	table.insert(if kind == "spin" then spinners else movers, m)
	moverIndex[model] = m
end

local function removeMover(model: Instance)
	local m = moverIndex[model :: any]
	if not m then
		return
	end
	moverIndex[model :: any] = nil
	local list = if m.kind == "spin" then spinners else movers
	local i = table.find(list, m)
	if i then
		table.remove(list, i)
	end
end

local function track(tag: string, onAdd: (Instance) -> (), onRemove: ((Instance) -> ())?)
	for _, inst in CollectionService:GetTagged(tag) do
		onAdd(inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdd)
	if onRemove then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(onRemove)
	end
end

local function cull(camPos: Vector3, q: number)
	for _, e in CollectionService:GetTagged("WorldFx") do
		if e:IsA("ParticleEmitter") then
			local p = e.Parent
			local pos = if p and p:IsA("BasePart")
				then p.Position
				elseif p and p:IsA("Attachment") then p.WorldPosition
				else nil
			if pos then
				local cullDist = e:GetAttribute("CullDist")
				local base = e:GetAttribute("BaseRate")
				local on = (pos - camPos).Magnitude < (if typeof(cullDist) == "number" then cullDist else 200)
				e.Enabled = on
				if on and typeof(base) == "number" then
					e.Rate = base * q
				end
			end
		end
	end
	for _, m in movers do
		m.near = (m.base.Position - camPos).Magnitude < SWAY_RANGE
	end
	for _, m in spinners do
		m.near = (m.base.Position - camPos).Magnitude < SWAY_RANGE * 2
	end
end

function Ambient.start()
	if started then
		return
	end
	started = true
	track("WorldSway", function(i)
		addMover(i, "sway")
	end, removeMover)
	track("WorldBob", function(i)
		addMover(i, "bob")
	end, removeMover)
	track("WorldSpin", function(i)
		addMover(i, "spin")
	end, removeMover)
	track("WorldScroll", function(i)
		if i:IsA("Texture") then
			table.insert(scrolls, i)
		end
	end, function(i)
		local k = table.find(scrolls, i :: any)
		if k then
			table.remove(scrolls, k)
		end
	end)
	track("WorldPulse", function(i)
		table.insert(pulses, i)
	end)

	local acc, cursor, t = CULL_EVERY, 1, 0
	local q = quality()
	RunService.RenderStepped:Connect(function(dt: number)
		t += dt
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		acc += dt
		if acc >= CULL_EVERY then
			acc = 0
			q = quality()
			cull(cam.CFrame.Position, q)
		end
		for _, tex in scrolls do
			local su, sv = tex:GetAttribute("SpeedU"), tex:GetAttribute("SpeedV")
			if typeof(su) == "number" then
				tex.OffsetStudsU = (tex.OffsetStudsU + su * dt) % math.max(tex.StudsPerTileU, 0.01)
			end
			if typeof(sv) == "number" then
				tex.OffsetStudsV = (tex.OffsetStudsV + sv * dt) % math.max(tex.StudsPerTileV, 0.01)
			end
		end
		for _, p in pulses do
			local sp = p:GetAttribute("Speed")
			local s = 0.5 + 0.5 * math.sin(t * math.pi * 2 * (if typeof(sp) == "number" then sp else 0.4))
			if p:IsA("PointLight") then
				local b = p:GetAttribute("BaseBrightness")
				if typeof(b) ~= "number" then
					b = p.Brightness
					p:SetAttribute("BaseBrightness", b)
				end
				p.Brightness = (b :: number) * (0.6 + 0.4 * s)
			elseif p:IsA("BasePart") then
				p.Transparency = 0.15 * (1 - s)
			end
		end
		-- sway / bob: a budgeted slice of the movers each frame (quality levels 1-2 = no motion)
		if q < 0.5 then
			return
		end
		local parts, cfs = {}, {}
		for _, m in spinners do
			if m.near and m.model.Parent then
				local a = math.rad(m.speed * t)
				local pivot = if m.axisY then m.base * CFrame.Angles(0, a, 0) else m.base * CFrame.Angles(0, 0, a)
				for k, part in m.parts do
					table.insert(parts, part)
					table.insert(cfs, pivot * m.rel[k])
				end
			end
		end
		local n = #movers
		for _ = 1, math.min(MOVERS_PER_FRAME, n) do
			if n == 0 then
				break
			end
			if cursor > n then
				cursor = 1
			end
			local m = movers[cursor]
			cursor += 1
			if m.near and m.model.Parent then
				local w = math.sin(t * math.pi * 2 * m.speed + m.phase)
				local pivot: CFrame
				if m.kind == "sway" then
					pivot = m.base
						* CFrame.Angles(
							math.rad(m.amp) * w,
							0,
							math.rad(m.amp * 0.6) * math.cos(t * 1.7 * m.speed + m.phase)
						)
				else
					pivot = m.base + Vector3.new(0, m.amp * w, 0)
				end
				for k, part in m.parts do
					table.insert(parts, part)
					table.insert(cfs, pivot * m.rel[k])
				end
			end
		end
		if #parts > 0 then
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return Ambient
