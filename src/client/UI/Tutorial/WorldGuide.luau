--!strict
-- A small billboard, a focus ring, and six PNG ground chevrons along a real navigable path.
-- If a path is unavailable, show the destination/edge arrow instead of drawing through fences.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local GuiService = game:GetService("GuiService")
local Assets = require(script.Parent.Assets)
local Motion = require(script.Parent.Parent.System.Motion)
local WorldGuide = {}
local GOLD = Color3.fromRGB(255, 216, 74)

local function part(parent: Instance, name: string, size: Vector3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Transparency = 1
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	p.Parent = parent
	return p
end

local function surface(p: Part, image: string): ImageLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
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
	local ringArt = surface(ring, Assets.TargetRing)
	ringArt.Visible = false
	local markers: { Part } = {}
	for i = 1, 6 do
		local marker = part(folder, "PathMarker" .. i, Vector3.new(2, 0.04, 2.5))
		local art = surface(marker, Assets.PathMarker)
		art.Visible = false
		table.insert(markers, marker)
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "WorldFocus"
	highlight.FillColor = GOLD
	highlight.OutlineColor = GOLD
	highlight.FillTransparency = 0.9
	highlight.OutlineTransparency = 0.1
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
	local target: Vector3? = nil
	local ground: Vector3? = nil
	local trailOn = false
	local path: { Vector3 } = {}
	local version, elapsed = 0, 2
	local pending = false
	local lastFrom: Vector3? = nil
	local alive = true
	local api = {}
	function api:set(position: Vector3?, thing: Instance?, floor: Vector3?, showTrail: boolean?)
		if (position == nil) ~= (target == nil) or (position and target and (position - target).Magnitude > 2) then
			version += 1
			path = {}
			elapsed = 2
		end
		target, ground, trailOn = position, floor, showTrail == true
		highlight.Adornee = thing
		highlight.Enabled = thing ~= nil
	end
	function api:update(dt: number, t: number)
		local me = Players.LocalPlayer
		local character = me.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local reduced = Motion.reduced()
		billboard.Enabled = target ~= nil
		ringArt.Visible = target ~= nil and ground ~= nil
		if target then
			anchor.CFrame = CFrame.new(target + Vector3.new(0, if reduced then 0 else math.sin(t * 3.5) * 0.35, 0))
		end
		if ground then
			ring.CFrame = CFrame.new(ground + Vector3.new(0, 0.07, 0))
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
		elapsed += dt
		local walking = trailOn
			and ground ~= nil
			and root ~= nil
			and root:IsA("BasePart")
			and (root.Position - ground).Magnitude > 14
		if
			walking
			and elapsed > 1.5
			and not pending
			and (not lastFrom or (root.Position - lastFrom).Magnitude > 7 or #path == 0)
		then
			elapsed, pending = 0, true
			local from, goal, token = root.Position, ground :: Vector3, version
			lastFrom = from
			task.spawn(function()
				local route = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = true,
					WaypointSpacing = 4,
				})
				local ok = pcall(route.ComputeAsync, route, from, goal)
				local points: { Vector3 } = {}
				if ok and route.Status == Enum.PathStatus.Success then
					for _, waypoint in route:GetWaypoints() do
						table.insert(points, waypoint.Position)
					end
				end
				route:Destroy()
				if alive and token == version then
					path = points
				end
				pending = false
			end)
		end
		for i, marker in markers do
			local art = marker.SurfaceGui.ImageLabel
			local a, b = path[i], path[i + 1]
			art.Visible = walking == true and a ~= nil and b ~= nil
			if art.Visible then
				local at = (a :: Vector3) + Vector3.new(0, 0.08, 0)
				local toward = Vector3.new((b :: Vector3).X, at.Y, (b :: Vector3).Z)
				marker.CFrame = if (toward - at).Magnitude > 0.01 then CFrame.lookAt(at, toward) else CFrame.new(at)
				art.ImageTransparency = if reduced then 0.2 else 0.15 + 0.18 * (0.5 + math.sin(t * 4 - i * 0.7) * 0.5)
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
