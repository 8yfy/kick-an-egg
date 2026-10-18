--!strict
-- A continuous, bounded route from the player's CURRENT feet to the target.
-- Front-facing image planes avoid the Top SurfaceGui's sideways texture axes.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Assets = require(script.Parent.Assets)
local Route = require(script.Parent.Route)
local Motion = require(script.Parent.Parent.System.Motion)
local WorldGuide = {}
local GOLD = Color3.fromRGB(255, 216, 74)
local MAX_MARKERS, MAX_LINES = 40, 64

local function part(parent: Instance, name: string, size: Vector3): Part
	local p = Instance.new("Part")
	p.Name, p.Size = name, size
	p.Transparency = 1
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Parent = parent
	return p
end

local function surface(p: Part, image: string, face: Enum.NormalId): ImageLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.Parent = p
	local art = Instance.new("ImageLabel")
	art.BackgroundTransparency = 1
	art.Size = UDim2.fromScale(1, 1)
	art.Image = image
	art.Parent = gui
	return art
end

function WorldGuide.new(gui: ScreenGui)
	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuidance"
	folder.Parent = workspace
	local anchor = part(folder, "WorldTarget", Vector3.one * 0.1)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WorldArrow"
	billboard.Adornee = anchor
	billboard.Size = UDim2.fromOffset(54, 70)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 300
	billboard.Enabled = false
	billboard.Parent = anchor
	local arrow = Instance.new("ImageLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.Image = Assets.WorldArrow
	arrow.Parent = billboard
	local ring = part(folder, "TargetRing", Vector3.new(7, 0.05, 7))
	local ringArt = surface(ring, Assets.TargetRing, Enum.NormalId.Top)
	ringArt.Visible = false
	local markers: { Part } = {}
	local markerArt: { ImageLabel } = {}
	local heights: { number } = {}
	local lines: { Part } = {}
	for i = 1, MAX_MARKERS do
		local marker = part(folder, "PathMarker" .. i, Vector3.new(2.6, 2.9, 0.03))
		local art = surface(marker, Assets.PathMarker, Enum.NormalId.Front)
		art.Visible = false
		table.insert(markers, marker)
		table.insert(markerArt, art)
	end
	for i = 1, MAX_LINES do
		local line = part(folder, "RouteLine" .. i, Vector3.one)
		line.Material, line.Color = Enum.Material.Neon, GOLD
		table.insert(lines, line)
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "WorldFocus"
	highlight.FillColor, highlight.OutlineColor = GOLD, GOLD
	highlight.FillTransparency, highlight.OutlineTransparency = 0.9, 0.1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = folder
	local edge = Instance.new("ImageLabel")
	edge.Name = "OffscreenDirection"
	edge.BackgroundTransparency = 1
	edge.Image = Assets.Pointer
	edge.Size = UDim2.fromOffset(52, 52)
	edge.AnchorPoint = Vector2.new(0.5, 0.5)
	edge.ZIndex = 35
	edge.Visible = false
	edge.Parent = gui

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	params.IgnoreWater = true
	local character: Model? = nil
	local target: Vector3? = nil
	local ground: Vector3? = nil
	local trailOn, pending, alive = false, false, true
	local path: { Vector3 } = {}
	local version, nextRequest, checkAt, groundAt = 0, 0, 0, 0
	local originY = 0
	local connectorOK = false
	local function project(p: Vector3): Vector3
		local hit = workspace:Raycast(p + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), params)
		return if hit then hit.Position else p
	end
	local function clear(a: Vector3, b: Vector3): boolean
		local delta = b - a
		if delta.Magnitude < 0.1 then
			return true
		end
		-- A torso-width corridor above the floor, excluding triggers and the tutorial's own art.
		return workspace:Blockcast(CFrame.new(a + Vector3.new(0, 3, 0)), Vector3.new(3.2, 4.3, 3.2), delta, params)
			== nil
	end
	local function invalidate()
		version += 1
		path, heights = {}, {}
		for _, art in markerArt do
			art.Visible = false
		end
		nextRequest, checkAt, groundAt = 0, 0, 0
		connectorOK = false
	end
	local api = {}
	function api:set(position: Vector3?, thing: Instance?, floor: Vector3?, showTrail: boolean?)
		local changed = (floor == nil) ~= (ground == nil)
			or (floor and ground and (floor - ground).Magnitude > 0.75)
			or trailOn ~= (showTrail == true)
		if changed then
			invalidate()
		end
		target, ground, trailOn = position, floor, showTrail == true
		highlight.Adornee, highlight.Enabled = thing, thing ~= nil
	end
	function api:update(dt: number, t: number)
		local me = Players.LocalPlayer
		if character ~= me.Character then
			character = me.Character
			params.FilterDescendantsInstances = if character then { folder, character } else { folder }
			invalidate()
		end
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local reduced = Motion.reduced()
		billboard.Enabled = target ~= nil
		ringArt.Visible = target ~= nil and ground ~= nil
		if target then
			anchor.CFrame = CFrame.new(target + Vector3.new(0, if reduced then 0 else math.sin(t * 3.5) * 0.35, 0))
		end
		if ground then
			ring.CFrame = CFrame.new(project(ground) + Vector3.new(0, 0.08, 0))
		end
		local camera = workspace.CurrentCamera
		edge.Visible = false
		if target and camera then
			local point, visible = camera:WorldToViewportPoint(target)
			if not visible or point.Z <= 0 then
				local size = gui.AbsoluteSize
				local p = Vector2.new(point.X, point.Y) + GuiService:GetInsetArea(Enum.ScreenInsets.None).Min
				local direction = p - size / 2
				if point.Z <= 0 then
					direction = -direction
				end
				if direction.Magnitude < 0.01 then
					direction = Vector2.yAxis
				end
				local unit = direction.Unit
				local radius = math.min(
					(size.X / 2 - 45) / math.max(0.01, math.abs(unit.X)),
					(size.Y / 2 - 45) / math.max(0.01, math.abs(unit.Y))
				)
				edge.Position = UDim2.fromOffset(size.X / 2 + unit.X * radius, size.Y / 2 + unit.Y * radius)
				edge.Rotation = math.deg(math.atan2(unit.Y, unit.X))
				edge.Visible = true
			end
		end
		local tail: { Vector3 } = {}
		local walking = trailOn and ground ~= nil and root ~= nil and root:IsA("BasePart")
		if walking then
			local from = root.Position
			if t >= checkAt then
				originY = project(from).Y
			end
			local origin = Vector3.new(from.X, originY, from.Z)
			local goal = project(ground :: Vector3)
			walking = (origin - goal).Magnitude > 5
			local deviation: number
			tail, deviation = Route.ahead(origin, path)
			if walking and t >= checkAt then
				checkAt = t + 0.1
				connectorOK = #tail >= 2 and clear(origin, tail[2])
				if (#path == 0 or deviation > 2.5 or not connectorOK) and not pending and t >= nextRequest then
					nextRequest = t + 0.35
					if clear(origin, goal) then
						path, tail, connectorOK = { origin, goal }, { origin, goal }, true
					else
						pending = true
						local token = version
						task.spawn(function()
							local route = PathfindingService:CreatePath({
								AgentRadius = 2,
								AgentHeight = 5,
								AgentCanJump = false,
								WaypointSpacing = 4,
							})
							local ok = pcall(route.ComputeAsync, route, from, goal)
							local points: { Vector3 } = {}
							if ok and route.Status == Enum.PathStatus.Success then
								for _, waypoint in route:GetWaypoints() do
									table.insert(points, project(waypoint.Position))
								end
								points = Route.simplify(points, clear)
								if not Route.valid(points, clear) then
									points = {}
								end
							end
							route:Destroy()
							if alive and token == version then
								path = points
								heights = {}
								for _, art in markerArt do
									art.Visible = false
								end
								checkAt = 0
							end
							pending = false
						end)
					end
				end
			end
			if not connectorOK or not walking then
				tail = {}
			end
		end

		local length = Route.length(tail)
		local capacity = if me:GetAttribute("LowDetail")
			then 18
			elseif UserInputService.TouchEnabled then 24
			else MAX_MARKERS
		local lead, spacing = Route.spacing(length, capacity)
		local count = if length > 0.5 then math.min(capacity, math.ceil((length - lead) / spacing) + 1) else 0
		local snapGround = t >= groundAt
		if snapGround then
			groundAt = t + 0.1
		end
		local blend = 1 - math.exp(-22 * dt)
		for i, marker in markers do
			local art = markerArt[i]
			local wasVisible = art.Visible
			art.Visible = i <= count
			if art.Visible then
				local at, direction = Route.sample(tail, math.min(length, lead + (i - 1) * spacing))
				local forward = Vector3.new(direction.X, 0, direction.Z)
				if forward.Magnitude < 0.001 then
					forward = Vector3.zAxis
				end
				if snapGround or not heights[i] or not wasVisible then
					heights[i] = project(at).Y
				end
				local floor = Vector3.new(at.X, heights[i] + 0.12, at.Z)
				-- PNG up = part.UpVector. Its FRONT face looks upward; the arrow therefore points along the route.
				local cf = Route.frame(floor, forward)
				marker.CFrame = if wasVisible then marker.CFrame:Lerp(cf, blend) else cf
				local alpha = 0.1 + 0.12 * (0.5 + math.sin(t * 4 - i * 0.65) * 0.5)
				art.ImageTransparency = if reduced
					then 0.12
					else (if wasVisible then art.ImageTransparency else 1) * (1 - blend) + alpha * blend
			end
		end
		for i, line in lines do
			local a, b = tail[i], tail[i + 1]
			line.Transparency = 1
			if a and b then
				-- Stop the connector ahead of the feet as well; keep every corner on the collision-checked route.
				if i == 1 then
					a = a:Lerp(b, math.min(1, 2.5 / math.max(0.001, (b - a).Magnitude)))
				end
				local delta = b - a
				if delta.Magnitude > 0.1 then
					line.Size = Vector3.new(0.11, 0.025, delta.Magnitude)
					line.CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.1, 0), b + Vector3.new(0, 0.1, 0))
					line.Transparency = 0.55
				end
			end
		end
	end
	function api:destroy()
		alive = false
		version += 1
		folder:Destroy()
		edge:Destroy()
	end
	return api
end

return WorldGuide
