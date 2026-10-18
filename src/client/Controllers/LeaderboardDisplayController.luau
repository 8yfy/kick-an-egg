--!strict
-- Near-only, locally faded medal badges above the six server-owned leaderboard avatars.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Controller = {}
local BINDING = "KickTheEggLeaderboardBadges"
local RANGE = 80
local COLORS = { Color3.fromRGB(255, 205, 50), Color3.fromRGB(210, 225, 245), Color3.fromRGB(240, 156, 83) }
type Badge = {
	gui: BillboardGui,
	panel: Frame,
	border: UIStroke,
	title: TextLabel,
	caption: TextLabel,
	alpha: number,
	head: BasePart,
}
local badges: { [Model]: Badge } = {}
local started = false

local function text(parent: Instance, name: string, value: string, y: number, height: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, height)
	label.Position = UDim2.fromScale(0, y)
	label.Text = value
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.Parent = parent
	return label
end

local function build(avatar: Model, head: BasePart, rank: number): Badge
	local color = COLORS[rank]
	local gui = Instance.new("BillboardGui")
	gui.Name = "LeaderboardRankBadge"
	gui.Adornee = head
	gui.Size = UDim2.fromScale(4.6, 2.3)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 2.3, 0)
	gui.MaxDistance = RANGE + 5
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.Enabled = false
	local panel = Instance.new("Frame")
	panel.Name = "Medal"
	panel.Size = UDim2.fromScale(0.96, 0.9)
	panel.Position = UDim2.fromScale(0.02, 0.05)
	panel.BackgroundColor3 = Color3.fromRGB(24, 27, 44)
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.25, 0)
	corner.Parent = panel
	local border = Instance.new("UIStroke")
	border.Color = color
	border.Thickness = 2.5
	border.Parent = panel
	local title = text(panel, "Rank", "#" .. rank, 0.03, 0.64, Color3.new(1, 1, 1))
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 245), color)
	gradient.Rotation = 90
	gradient.Parent = title
	local caption = text(panel, "Caption", ({ "1ST PLACE", "2ND PLACE", "3RD PLACE" })[rank], 0.7, 0.19, color)
	gui.Parent = head
	local badge =
		{ gui = gui, panel = panel, border = border, title = title, caption = caption, head = head, alpha = 0 }
	badges[avatar] = badge
	return badge
end

local function discover()
	local map = workspace:FindFirstChild("Map")
	local zone = map and map:FindFirstChild("SafeZone")
	if not zone then
		return
	end
	for _, key in { "Power", "Donations" } do
		local board = zone:FindFirstChild("Leaderboard_" .. key)
		local winners = board and board:FindFirstChild("Winners")
		if not winners then
			continue
		end
		for rank = 1, 3 do
			local podium = winners:FindFirstChild("Rank" .. rank)
			local avatar = podium and podium:FindFirstChild("Avatar")
			local head = avatar and avatar:FindFirstChild("Head")
			if avatar and avatar:IsA("Model") and head and head:IsA("BasePart") and not badges[avatar] then
				build(avatar, head, rank)
			end
		end
	end
end

function Controller:Start()
	if started then
		return
	end
	started = true
	local elapsed = 0.5
	RunService:BindToRenderStep(BINDING, Enum.RenderPriority.Camera.Value + 4, function(dt)
		for avatar, badge in badges do
			if not avatar:IsDescendantOf(workspace) or not badge.head.Parent or not badge.gui.Parent then
				badge.gui:Destroy()
				badges[avatar] = nil
			end
		end
		elapsed += dt
		if elapsed >= 0.5 then
			elapsed = 0
			discover()
		end
		local camera = workspace.CurrentCamera
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for _, badge in badges do
			local target = 0
			if camera and root and root:IsA("BasePart") then
				local position = badge.head.Position + badge.gui.StudsOffsetWorldSpace
				local point, inView = camera:WorldToViewportPoint(position)
				if inView and point.Z > 0 then
					local distance = math.max(
						(root.Position - badge.head.Position).Magnitude,
						(camera.CFrame.Position - position).Magnitude
					)
					target = math.clamp((RANGE - distance) / 10, 0, 1)
				end
			end
			badge.alpha += (target - badge.alpha) * (1 - math.exp(-12 * dt))
			badge.gui.Enabled = badge.alpha > 0.01
			badge.panel.BackgroundTransparency = 1 - badge.alpha * 0.88
			badge.border.Transparency = 1 - badge.alpha
			badge.title.TextTransparency = 1 - badge.alpha
			badge.caption.TextTransparency = 1 - badge.alpha
		end
	end)
end

function Controller:Destroy()
	RunService:UnbindFromRenderStep(BINDING)
	for avatar, badge in badges do
		badge.gui:Destroy()
		badges[avatar] = nil
	end
	started = false
end

return Controller
