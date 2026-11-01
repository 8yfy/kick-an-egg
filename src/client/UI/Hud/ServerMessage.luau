--!strict
-- Server messages (admin announcements) for every player, as one line at the top centre (no panel):
--   [HEADSHOT] USERNAME: message
-- The headshot is Roblox's rendered avatar thumbnail (rbxthumb AvatarHeadShot PNG).
-- In: the line drops in with a bouncy pop, the headshot spins up, the name pops, the message types itself out,
-- and the "Announcement" chime plays (Audio/SoundBank). While it shows it bobs gently. Out: it lifts, shrinks and
-- fades. Reduced Motion: fades only. Sized for desktop, scaled down on small screens.
-- The server writes each message as attributes on ReplicatedStorage.ServerMessage (Id last): MsgText, UserId,
-- Username, At (server time). Clients only read it, so there is nothing for a client to fire.
-- Messages queue and show one at a time; one sent more than a few seconds before you joined is skipped.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Theme = require(System.Theme)

local Audio = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Audio")) :: any

local ServerMessage = {}

local MAX_WIDTH = 760 -- message column, before the small-screen scale
local HEADSHOT = 76
local NAME_SIZE, TEXT_SIZE = 32, 30
local TOP = 14
local LATE_JOIN = 8 -- seconds: a message this fresh still shows to someone who just joined

type Message = { text: string, userId: number, username: string }

-- How long a message stays (after it has typed out): long enough to read, never forever.
function ServerMessage.holdSeconds(text: string): number
	return math.clamp(4 + #text / 18, 5, 10)
end

-- Seconds the message takes to type itself out.
function ServerMessage.typeSeconds(text: string): number
	return math.clamp(utf8.len(text) or #text, 1, 120) * 0.018 + 0.15
end

function ServerMessage.thumbnail(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

local function tween(
	obj: Instance,
	seconds: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
): Tween
	local t = TweenService:Create(
		obj,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		goal
	)
	t:Play()
	return t
end

local function label(parent: Instance, name: string, size: number, color: Color3, order: number): (TextLabel, UIStroke)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.LayoutOrder = order
	l.Font = Theme.Font
	l.TextSize = size
	l.TextColor3 = color
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.AutomaticSize = Enum.AutomaticSize.XY
	l.Size = UDim2.new()
	local outline = Instance.new("UIStroke") -- readable over any sky or map
	outline.Thickness = 3
	outline.Color = Theme.Colors.border
	outline.LineJoinMode = Enum.LineJoinMode.Round
	outline.Parent = l
	l.Parent = parent
	return l, outline
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

	-- holder: small-screen scale; row: the animated line (its own scale and position)
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 0)
	holder.Size = UDim2.fromScale(1, 0)
	local fitScale = Instance.new("UIScale")
	fitScale.Parent = holder
	holder.Parent = gui

	local row = Instance.new("Frame")
	row.Name = "Line"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, TOP)
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.new()
	row.Visible = false
	local pop = Instance.new("UIScale")
	pop.Parent = row
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	row.Parent = holder

	local headshot = Instance.new("ImageLabel")
	headshot.Name = "Headshot"
	headshot.BackgroundTransparency = 1
	headshot.Size = UDim2.fromOffset(HEADSHOT, HEADSHOT)
	headshot.LayoutOrder = 1
	local headPop = Instance.new("UIScale")
	headPop.Parent = headshot
	headshot.Parent = row

	local name, nameStroke = label(row, "Name", NAME_SIZE, Theme.Colors.power, 2)
	local namePop = Instance.new("UIScale")
	namePop.Parent = name
	local text, textStroke = label(row, "Text", TEXT_SIZE, Color3.new(1, 1, 1), 3)
	text.TextWrapped = true
	local width = Instance.new("UISizeConstraint")
	width.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	width.Parent = text

	local function fit()
		local cam = workspace.CurrentCamera
		local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		fitScale.Scale = math.clamp(math.min(vp.X / 1100, vp.Y / 620), 0.6, 1)
		local room = vp.X / fitScale.Scale - HEADSHOT - 200
		width.MaxSize = Vector2.new(math.clamp(room, 220, MAX_WIDTH), math.huge)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	local function fade(alpha: number, seconds: number)
		local goal = { TextTransparency = alpha }
		local strokeGoal = { Transparency = alpha }
		if seconds <= 0 then
			name.TextTransparency, text.TextTransparency = alpha, alpha
			nameStroke.Transparency, textStroke.Transparency = alpha, alpha
			headshot.ImageTransparency = alpha
			return
		end
		tween(name, seconds, goal)
		tween(text, seconds, goal)
		tween(nameStroke, seconds, strokeGoal)
		tween(textStroke, seconds, strokeGoal)
		tween(headshot, seconds, { ImageTransparency = alpha })
	end

	local bob: Tween? = nil
	local queue: { Message } = {}
	local showing = false

	local function animateIn(m: Message): number
		local reduced = Motion.reduced()
		row.Visible = true
		Audio.play("Announcement")
		if reduced then
			row.Position, row.Rotation, pop.Scale = UDim2.new(0.5, 0, 0, TOP), 0, 1
			headshot.Rotation, headPop.Scale, namePop.Scale = 0, 1, 1
			text.MaxVisibleGraphemes = -1
			fade(1, 0)
			fade(0, 0.25)
			return 0.25
		end
		-- line: drops in with a bounce
		fade(1, 0)
		row.Position = UDim2.new(0.5, 0, 0, TOP - 70)
		pop.Scale = 0.6
		tween(row, 0.5, { Position = UDim2.new(0.5, 0, 0, TOP) }, Enum.EasingStyle.Back)
		tween(pop, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
		fade(0, 0.2)
		-- headshot: spins up and overshoots
		headshot.Rotation, headPop.Scale = -35, 0.2
		tween(headshot, 0.55, { Rotation = 0 }, Enum.EasingStyle.Back)
		tween(headPop, 0.55, { Scale = 1 }, Enum.EasingStyle.Elastic)
		-- name: a little pop just after
		namePop.Scale = 0.4
		task.delay(0.12, function()
			tween(namePop, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		-- message: types itself out
		text.MaxVisibleGraphemes = 0
		local total = utf8.len(m.text) or #m.text
		local seconds = ServerMessage.typeSeconds(m.text)
		task.delay(0.25, function()
			local started = os.clock()
			while row.Visible and text.MaxVisibleGraphemes ~= -1 do
				local shown = math.floor((os.clock() - started) / seconds * total)
				if shown >= total then
					text.MaxVisibleGraphemes = -1
				else
					text.MaxVisibleGraphemes = shown
				end
				task.wait()
			end
		end)
		-- then a gentle bob while it shows
		task.delay(0.55, function()
			if row.Visible then
				bob = TweenService:Create(
					row,
					TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Position = UDim2.new(0.5, 0, 0, TOP + 4) }
				)
				bob:Play()
			end
		end)
		return 0.25 + seconds
	end

	local function animateOut()
		if bob then
			bob:Cancel()
			bob = nil
		end
		if Motion.reduced() then
			fade(1, 0.25)
			task.wait(0.25)
		else
			tween(
				row,
				0.35,
				{ Position = UDim2.new(0.5, 0, 0, TOP - 50) },
				Enum.EasingStyle.Back,
				Enum.EasingDirection.In
			)
			tween(pop, 0.35, { Scale = 0.7 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			fade(1, 0.3)
			task.wait(0.36)
		end
		row.Visible = false
	end

	local function showNext()
		if showing or #queue == 0 then
			return
		end
		showing = true
		local m = table.remove(queue, 1) :: Message
		headshot.Image = ServerMessage.thumbnail(m.userId)
		name.Text = `{m.username}:` -- plain text (no RichText): a name or message can never inject markup
		text.Text = m.text
		local typing = animateIn(m)
		task.delay(typing + ServerMessage.holdSeconds(m.text), function()
			animateOut()
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
		local msg, userId = channel:GetAttribute("MsgText"), channel:GetAttribute("UserId")
		local username = channel:GetAttribute("Username")
		if typeof(msg) ~= "string" or msg == "" or typeof(userId) ~= "number" or typeof(username) ~= "string" then
			return
		end
		table.insert(queue, { text = msg, userId = userId, username = username })
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
