--!strict
-- Floating owner display over every pen (replaces the old owner board): a rounded card with the owner's Roblox
-- avatar headshot (rbxthumb AvatarHeadShot, Roblox's supported thumbnail content), their display name and
-- @username. It follows Base<i>.OwnerUserId (PlotService): a new owner swaps the card, a player leaving (0)
-- clears it to "FREE PEN" straight away. If the headshot can't load, the owner's initial shows instead.
-- Gently bobs (one Heartbeat for all pens, only those within MAX_DISTANCE).

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX_DISTANCE = 160
local BOB = 0.35

local PenOwnerController = {}

type Card = {
	base: Model,
	gui: BillboardGui,
	photo: ImageLabel,
	initial: TextLabel,
	display: TextLabel,
	username: TextLabel,
	phase: number,
	shown: number?, -- userId on the card
}

local cards: { [Model]: Card } = {}

local function round(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function stroke(parent: Instance, thickness: number, color: Color3)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function label(parent: Instance, name: string, size: UDim2, pos: UDim2, font: Enum.Font): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Size, l.Position = size, pos
	l.Font = font
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Color3.new(1, 1, 1)
	local s = Instance.new("UIStroke")
	s.Thickness = 2
	s.Color = Color3.fromRGB(20, 24, 40)
	s.Parent = l
	l.Parent = parent
	return l
end

local function build(base: Model, anchor: BasePart): Card
	local gui = Instance.new("BillboardGui")
	gui.Name = "PenOwner"
	gui.Size = UDim2.fromOffset(300, 92)
	gui.StudsOffset = Vector3.zero
	gui.MaxDistance = MAX_DISTANCE
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.ResetOnSpawn = false
	gui.Adornee = anchor

	local cardFrame = Instance.new("Frame")
	cardFrame.Name = "Card"
	cardFrame.Size = UDim2.fromScale(1, 1)
	cardFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 60)
	cardFrame.BackgroundTransparency = 0.12
	round(cardFrame, 22)
	stroke(cardFrame, 3, Color3.fromRGB(255, 215, 70))
	cardFrame.Parent = gui

	local ring = Instance.new("Frame")
	ring.Name = "PhotoRing"
	ring.Size = UDim2.fromOffset(76, 76)
	ring.Position = UDim2.fromOffset(8, 8)
	ring.BackgroundColor3 = Color3.fromRGB(255, 215, 70)
	round(ring, 38)
	ring.Parent = cardFrame
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.Position = UDim2.fromOffset(4, 4)
	inner.BackgroundColor3 = Color3.fromRGB(90, 140, 230)
	round(inner, 34)
	inner.ClipsDescendants = true
	inner.Parent = ring
	local initial = label(inner, "Initial", UDim2.fromScale(1, 1), UDim2.new(), Enum.Font.FredokaOne)
	initial.TextXAlignment = Enum.TextXAlignment.Center
	local photo = Instance.new("ImageLabel")
	photo.Name = "Photo"
	photo.BackgroundTransparency = 1
	photo.Size = UDim2.fromScale(1, 1)
	photo.ScaleType = Enum.ScaleType.Crop
	round(photo, 34)
	photo.Parent = inner

	local display =
		label(cardFrame, "DisplayName", UDim2.new(1, -104, 0, 40), UDim2.fromOffset(96, 12), Enum.Font.FredokaOne)
	local username =
		label(cardFrame, "Username", UDim2.new(1, -104, 0, 26), UDim2.fromOffset(96, 54), Enum.Font.GothamBold)
	username.TextColor3 = Color3.fromRGB(190, 205, 235)

	gui.Parent = anchor
	return {
		base = base,
		gui = gui,
		photo = photo,
		initial = initial,
		display = display,
		username = username,
		phase = (tonumber(base:GetAttribute("BaseIndex")) or 1) * 1.3,
		shown = nil,
	}
end

local function paint(card: Card)
	local uid = card.base:GetAttribute("OwnerUserId")
	local userId = if typeof(uid) == "number" then uid else 0
	if card.shown == userId then
		return
	end
	card.shown = userId
	if userId <= 0 then
		card.photo.Image = ""
		card.initial.Text = "?"
		card.display.Text = "FREE PEN"
		card.username.Text = "waiting for a player"
		return
	end
	local owner = Players:GetPlayerByUserId(userId)
	local name = if owner then owner.Name else "Player"
	card.display.Text = if owner then owner.DisplayName else name
	card.username.Text = `@{name}`
	card.initial.Text = string.upper(string.sub(card.display.Text, 1, 1))
	local image = `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
	card.photo.Image = image
	task.spawn(function()
		-- a failed headshot leaves the initial visible underneath (ImageLabel stays empty)
		local ok = pcall(function()
			ContentProvider:PreloadAsync({ card.photo }, function(_, status)
				if status ~= Enum.AssetFetchStatus.Success and card.shown == userId then
					card.photo.Image = ""
				end
			end)
		end)
		if not ok and card.shown == userId then
			card.photo.Image = ""
		end
	end)
end

local function track(base: Instance)
	if not base:IsA("Model") or cards[base] then
		return
	end
	local anchor = base:WaitForChild("OwnerAnchor", 30)
	if not anchor or not anchor:IsA("BasePart") then
		return
	end
	local card = build(base, anchor)
	cards[base] = card
	paint(card)
	base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
		paint(card)
	end)
end

function PenOwnerController:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		local safeZone = map and map:WaitForChild("SafeZone", 30)
		local bases = safeZone and safeZone:WaitForChild("Bases", 30)
		if not bases then
			return
		end
		for _, base in bases:GetChildren() do
			task.spawn(track, base)
		end
		bases.ChildAdded:Connect(function(base)
			task.spawn(track, base)
		end)
	end)
	-- a player who leaves never stays on a card, even before the server clears OwnerUserId
	Players.PlayerRemoving:Connect(function(left)
		for _, card in cards do
			if card.shown == left.UserId then
				card.shown = nil
				card.photo.Image = ""
				card.display.Text = "FREE PEN"
				card.username.Text = "waiting for a player"
				card.initial.Text = "?"
			end
		end
	end)
	RunService.Heartbeat:Connect(function()
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local t = os.clock()
		for _, card in cards do
			local adornee = card.gui.Adornee
			if
				adornee
				and adornee:IsA("BasePart")
				and (adornee.Position - cam.CFrame.Position).Magnitude < MAX_DISTANCE
			then
				card.gui.StudsOffset = Vector3.new(0, math.sin(t * 1.6 + card.phase) * BOB, 0)
			end
		end
	end)
end

return PenOwnerController
