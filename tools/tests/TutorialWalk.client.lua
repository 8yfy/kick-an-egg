--!strict
-- Studio test actor ONLY. Walks at the real humanoid speed along navigation waypoints; no teleport,
-- rewards or gameplay edits. Not imported by the game. Set player.TutorialWalkTarget to Kick/ Pen.
local p = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local queue: { PathWaypoint } = {}
local walking = false
local index = 1
local function plan()
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local kind = p:GetAttribute("TutorialWalkTarget")
	local target: Vector3? = nil
	if kind == "Kick" then
		target = workspace.Map.KickPad.Position
	elseif kind == "Pen" then
		local base = workspace.Map.SafeZone.Bases:FindFirstChild("Base" .. p:GetAttribute("BaseIndex"))
		local area = base.PenArea
		target = area.CFrame:PointToWorldSpace(Vector3.new(0, 0, -area.Size.Z / 2 + 8))
	end
	if not target then
		return
	end
	local route =
		PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
	local ok = pcall(route.ComputeAsync, route, root.Position, target)
	if not ok or route.Status ~= Enum.PathStatus.Success then
		p:SetAttribute("TutorialWalkStatus", "NoPath")
		return
	end
	queue, index, walking = route:GetWaypoints(), 1, true
	route:Destroy()
	p:SetAttribute("TutorialWalkStatus", "Walking")
end
p:GetAttributeChangedSignal("TutorialWalkTarget"):Connect(plan)
RunService:BindToRenderStep("TutorialWalkTestActor", Enum.RenderPriority.Character.Value + 1, function()
	if not walking then
		return
	end
	local c = p.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not (root and h) then
		walking = false
		return
	end
	local waypoint = queue[index]
	if not waypoint then
		h:Move(Vector3.zero, false)
		walking = false
		p:SetAttribute("TutorialWalkStatus", "Arrived")
		return
	end
	local difference = waypoint.Position - root.Position
	local flat = Vector3.new(difference.X, 0, difference.Z)
	if flat.Magnitude < 2.5 then
		index += 1
		return
	end
	if waypoint.Action == Enum.PathWaypointAction.Jump then
		h.Jump = true
	end
	h:Move(flat.Unit, false)
end)
