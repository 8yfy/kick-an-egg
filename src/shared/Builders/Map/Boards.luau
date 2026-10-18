--!strict
-- The two global boards on a plaza wall (Config/Leaderboards). Stable names (LeaderboardService fills them):
--   Leaderboard_<key>          Model (attribute Board = key)
--     .Screen.Rows             SurfaceGui; .List.Row<i> (i = 1..Rows) each with Rank, Avatar, Name, Value labels
--                              and .Footer (status text)
--     .Podium                  (Donations only) Part with the ProximityPrompt Action "OpenMenu:Donate"
-- Built from studded blocks: a coloured frame + title header with a crown, a dark screen and a light.
--     .Winners.Rank<1..3>      Podium models; .AvatarAnchor marks the winner's feet, facing the plaza
local Bricks = require(script.Parent.Bricks)
local Leaderboards = require(script.Parent.Parent.Parent.Config.Leaderboards)

local Boards = {}

local rgb = Color3.fromRGB
local SCREEN = rgb(24, 27, 44)
local W, H = 20, 26 -- the screen, in studs

local function label(
	parent: Instance,
	name: string,
	text: string,
	size: UDim2,
	pos: UDim2,
	align: Enum.TextXAlignment,
	color: Color3?
): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Font = Enum.Font.FredokaOne
	l.Text = text
	l.TextScaled = true
	l.TextXAlignment = align
	l.TextColor3 = color or Color3.new(1, 1, 1)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Parent = l
	l.Parent = parent
	return l
end

local function winners(model: Model, face: CFrame, groundY: number)
	local group = Instance.new("Folder")
	group.Name = "Winners"
	group.Parent = model
	local colors = { rgb(255, 205, 50), rgb(210, 220, 235), rgb(225, 140, 70) }
	local heights = { 4.8, 3.4, 2.5 }
	local positions = { 0, -7.5, 7.5 }
	for rank = 1, 3 do
		local podium = Instance.new("Model")
		podium.Name = "Rank" .. rank
		podium:SetAttribute("Rank", rank)
		podium:SetAttribute("AvatarStatus", "Empty")
		podium.Parent = group
		local center = face:PointToWorldSpace(Vector3.new(positions[rank], 0, 8))
		local origin = CFrame.new(center.X, groundY, center.Z) * face.Rotation
		local color, height = colors[rank], heights[rank]
		Bricks.part(podium, "Foot", Vector3.new(7.2, 0.6, 6.4), origin * CFrame.new(0, 0.3, 0), color)
		local body = Bricks.part(
			podium,
			"Body",
			Vector3.new(6.6, height - 0.6, 5.8),
			origin * CFrame.new(0, (height + 0.6) / 2, 0),
			color:Lerp(SCREEN, 0.65)
		)
		Bricks.part(podium, "Cap", Vector3.new(7.2, 0.5, 6.4), origin * CFrame.new(0, height + 0.25, 0), color)
		Bricks.glow(podium, "Trim", Vector3.new(6.8, 0.14, 5.95), origin * CFrame.new(0, height - 0.15, 0), color)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Display"
		gui.Face = Enum.NormalId.Back
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 45
		gui.LightInfluence = 0
		gui.Parent = body
		label(
			gui,
			"Rank",
			"#" .. rank,
			UDim2.fromScale(0.9, 0.56),
			UDim2.fromScale(0.05, 0.02),
			Enum.TextXAlignment.Center,
			color
		)
		label(
			gui,
			"PlayerName",
			"UNCLAIMED",
			UDim2.fromScale(0.94, 0.29),
			UDim2.fromScale(0.03, 0.65),
			Enum.TextXAlignment.Center
		)
		local anchor = Bricks.part(
			podium,
			"AvatarAnchor",
			Vector3.one * 0.1,
			origin * CFrame.new(0, height + 0.5, 0) * CFrame.Angles(0, math.pi, 0),
			color,
			{ transparency = 1, collide = false, studs = false }
		)
		anchor.CanQuery = false
		podium.PrimaryPart = anchor
	end
end

-- `face`: the board centre on the wall surface; local Z points out of the wall, X to the viewer's right.
function Boards.build(parent: Instance, face: CFrame, key: string, accent: Color3, groundY: number): Model
	local board = Leaderboards.Boards[key]
	local model = Instance.new("Model")
	model.Name = "Leaderboard_" .. key
	model:SetAttribute("Board", key)
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return face * CFrame.new(x, y, z)
	end
	local dark = accent:Lerp(Color3.new(0, 0, 0), 0.35)

	-- frame + screen
	Bricks.part(model, "Frame", Vector3.new(W + 2.4, H + 2.4, 1), at(0, 0, 1.6), accent)
	local screen = Bricks.part(model, "Screen", Vector3.new(W, H, 0.4), at(0, 0, 2.3), SCREEN, {
		studs = false,
		collide = false,
	})
	-- header with the title and a crown
	local header = Bricks.part(model, "Header", Vector3.new(W + 4, 5, 1.8), at(0, H / 2 + 3.6, 2), dark)
	Bricks.part(model, "HeaderTrim", Vector3.new(W + 4.6, 0.8, 2.2), at(0, H / 2 + 1.1, 2), accent)
	local crown = rgb(255, 205, 50)
	Bricks.part(model, "CrownBase", Vector3.new(6, 1.4, 1.4), at(0, H / 2 + 6.8, 2), crown)
	for _, x in { -2.3, 0, 2.3 } do
		Bricks.part(
			model,
			"CrownPoint",
			Vector3.new(1.4, if x == 0 then 2.4 else 1.8, 1.4),
			at(x, H / 2 + 8.3 + (if x == 0 then 0.3 else 0), 2),
			crown
		)
		Bricks.glow(
			model,
			"CrownGem",
			Vector3.one * 0.8,
			at(x, H / 2 + 6.8, 2.8),
			if x == 0 then rgb(255, 60, 90) else rgb(80, 220, 255),
			"Ball"
		)
	end
	Bricks.light(screen, accent, 24, 0.8)
	local title = Instance.new("SurfaceGui")
	title.Name = "Title"
	title.Face = Enum.NormalId.Back -- +Z faces the plaza
	title.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- (default FixedSize stretches 800x600)
	title.PixelsPerStud = 30
	title.LightInfluence = 0
	title.Parent = header
	label(
		title,
		"Text",
		board.title,
		UDim2.fromScale(0.94, 0.8),
		UDim2.fromScale(0.03, 0.1),
		Enum.TextXAlignment.Center
	)

	-- the rows
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Rows"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- (default FixedSize stretches 800x600)
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = screen
	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromScale(0.03, 0.02)
	list.Size = UDim2.fromScale(0.94, 0.9)
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0.008, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local n = Leaderboards.Rows
	local medal = { rgb(255, 205, 50), rgb(210, 220, 235), rgb(225, 140, 70) }
	for i = 1, n do
		local row = Instance.new("Frame")
		row.Name = "Row" .. i
		row.LayoutOrder = i
		row.Size = UDim2.fromScale(1, 1 / n - 0.008)
		row.BackgroundColor3 = if i % 2 == 1 then rgb(40, 44, 66) else rgb(32, 36, 56)
		row.BorderSizePixel = 0
		row.Parent = list
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.2, 0)
		corner.Parent = row
		label(
			row,
			"Rank",
			"#" .. i,
			UDim2.fromScale(0.13, 0.8),
			UDim2.fromScale(0.01, 0.1),
			Enum.TextXAlignment.Center,
			medal[i]
		)
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.BackgroundColor3 = rgb(60, 66, 96)
		avatar.Size = UDim2.fromScale(0.86, 0.86) -- square: both from the row height
		avatar.SizeConstraint = Enum.SizeConstraint.RelativeYY
		avatar.Position = UDim2.fromScale(0.15, 0.07)
		avatar.Image = ""
		avatar.Parent = row
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(0.5, 0)
		round.Parent = avatar
		label(row, "Name", "---", UDim2.fromScale(0.42, 0.7), UDim2.fromScale(0.28, 0.15), Enum.TextXAlignment.Left)
		label(
			row,
			"Value",
			"",
			UDim2.fromScale(0.28, 0.7),
			UDim2.fromScale(0.7, 0.15),
			Enum.TextXAlignment.Right,
			accent:Lerp(Color3.new(1, 1, 1), 0.3)
		)
	end
	label(
		gui,
		"Footer",
		"Loading...",
		UDim2.fromScale(0.94, 0.05),
		UDim2.fromScale(0.03, 0.935),
		Enum.TextXAlignment.Center,
		rgb(184, 192, 212)
	)

	winners(model, face, groundY)
	if key == "Donations" then
		-- Beside #3, with a 2.6-stud gap: keep the whole three-winner display clear from the plaza.
		local position = face:PointToWorldSpace(Vector3.new(19, 0, 8))
		local podiumCF = CFrame.new(position.X, groundY + 1.5, position.Z) * face.Rotation
		local podium = Bricks.part(model, "Podium", Vector3.new(10, 3, 6), podiumCF, dark)
		Bricks.part(model, "PodiumTrim", Vector3.new(10.6, 0.6, 6.6), podiumCF * CFrame.new(0, 1.8, 0), accent)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DonatePrompt"
		prompt.ActionText = "Donate"
		prompt.ObjectText = "Support the game"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("Action", "OpenMenu:Donate")
		prompt.Parent = podium
		local sign = Instance.new("SurfaceGui")
		sign.Name = "Sign"
		sign.Face = Enum.NormalId.Back -- the podium looks at the wall: its back faces the plaza
		sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- (default FixedSize stretches 800x600)
		sign.PixelsPerStud = 40
		sign.LightInfluence = 0
		sign.Parent = podium
		label(sign, "Text", "DONATE", UDim2.fromScale(1, 1), UDim2.new(), Enum.TextXAlignment.Center)
	end
	return model
end

return Boards
