--!strict
-- Server messages (admin announcements) for every player, as one plain line at the top centre:
--   [HEADSHOT] USERNAME: message
-- The headshot is Roblox's rendered avatar thumbnail (rbxthumb AvatarHeadShot PNG). No panel or background.
-- The server writes each message as attributes on ReplicatedStorage.ServerMessage (Id last): MsgText, UserId,
-- Username, At (server time). Clients only read it, so there is nothing for a client to fire.
-- Messages queue and show one at a time; one sent more than a few seconds before you joined is skipped.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.System.Theme)

local ServerMessage = {}

local MAX_WIDTH = 640
local LATE_JOIN = 8 -- seconds: a message this fresh still shows to someone who just joined

type Message = { text: string, userId: number, username: string }

-- How long a message stays: long enough to read, never forever.
function ServerMessage.holdSeconds(text: string): number
	return math.clamp(4 + #text / 18, 5, 10)
end

function ServerMessage.thumbnail(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

-- Plain text (no RichText), so a name or message can never inject markup.
function ServerMessage.line(username: string, text: string): string
	return `{username}: {text}`
end

function ServerMessage.start(playerGui: Instance)
	local channel = ReplicatedStorage:WaitForChild("ServerMessage", 30)
	if not channel then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ServerMessage"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 40 -- over the HUD and its menus, under the admin panel
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = playerGui

	local row = Instance.new("Frame")
	row.Name = "Line"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, 10)
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.new()
	row.Visible = false
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	row.Parent = gui

	local headshot = Instance.new("ImageLabel")
	headshot.Name = "Headshot"
	headshot.BackgroundTransparency = 1
	headshot.Size = UDim2.fromOffset(44, 44)
	headshot.LayoutOrder = 1
	headshot.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.LayoutOrder = 2
	label.Font = Theme.Font
	label.TextSize = 22
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Size = UDim2.new()
	local outline = Instance.new("UIStroke") -- readable over any sky or map
	outline.Thickness = 2
	outline.Color = Theme.Colors.border
	outline.Parent = label
	local width = Instance.new("UISizeConstraint")
	width.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	width.Parent = label
	label.Parent = row

	local function fit()
		local cam = workspace.CurrentCamera
		local w = if cam then cam.ViewportSize.X else 1280
		width.MaxSize = Vector2.new(math.max(160, math.min(MAX_WIDTH, w - 90)), math.huge)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	local queue: { Message } = {}
	local showing = false
	local function showNext()
		if showing or #queue == 0 then
			return
		end
		showing = true
		local m = table.remove(queue, 1) :: Message
		headshot.Image = ServerMessage.thumbnail(m.userId)
		label.Text = ServerMessage.line(m.username, m.text)
		row.Visible = true
		task.delay(ServerMessage.holdSeconds(m.text), function()
			row.Visible = false
			showing = false
			showNext()
		end)
	end

	local lastId: any = nil
	local function read(fresh: boolean)
		local id = channel:GetAttribute("Id")
		if id == nil or id == lastId then
			return
		end
		lastId = id
		local at = channel:GetAttribute("At")
		if not fresh and (typeof(at) ~= "number" or workspace:GetServerTimeNow() - at > LATE_JOIN) then
			return
		end
		local text, userId = channel:GetAttribute("MsgText"), channel:GetAttribute("UserId")
		local username = channel:GetAttribute("Username")
		if typeof(text) ~= "string" or text == "" or typeof(userId) ~= "number" or typeof(username) ~= "string" then
			return
		end
		table.insert(queue, { text = text, userId = userId, username = username })
		while #queue > 5 do
			table.remove(queue, 1) -- a burst never piles up for minutes
		end
		showNext()
	end
	read(false) -- a message from just before we joined
	channel:GetAttributeChangedSignal("Id"):Connect(function()
		read(true)
	end)
end

return ServerMessage
