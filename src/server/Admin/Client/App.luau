--!strict
-- The admin window: a small admin-only button + a configurable hotkey open it; a header (title, server, players,
-- role, environment, action scope, close), a left sidebar of tabs and a page host. Pages are built the first time
-- they're opened and only the visible page refreshes, on its own interval (no per-frame polling, no rebuilds).
-- Desktop: a scaled 1180 x 720 window. Small screens (phones): full-screen with an icon-only sidebar.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local W = require(script.Parent.Widgets)
local Net = require(script.Parent.Net)
local State = require(script.Parent.State)

local Theme, Ui, Motion = W.Theme, W.Ui, W.Motion
local App = {}

type Page = { gui: GuiObject, onShow: (() -> ())?, onHide: (() -> ())?, refresh: (() -> ())?, every: number? }
type Tab = { id: string, label: string, icon: string, permission: string, module: string, color: { Color3 } }

local hex = Color3.fromHex
local TABS: { Tab } = {
	{
		id = "dashboard",
		label = "Dashboard",
		icon = "📊",
		permission = "dashboard.view",
		module = "Dashboard",
		color = Theme.Headers.index,
	},
	{
		id = "players",
		label = "Players",
		icon = "👥",
		permission = "players.view",
		module = "Players",
		color = Theme.Headers.shop,
	},
	{
		id = "lab",
		label = "Model Lab",
		icon = "🧪",
		permission = "lab.use",
		module = "ModelLab",
		color = Theme.Headers.training,
	},
	{
		id = "pets",
		label = "Pets & Eggs",
		icon = "🥚",
		permission = "lab.use",
		module = "PetsEggs",
		color = Theme.Headers.eggs,
	},
	{
		id = "anims",
		label = "Animations",
		icon = "🎞️",
		permission = "anim.play",
		module = "Animations",
		color = Theme.Headers.pets,
	},
	{ id = "vfx", label = "VFX", icon = "✨", permission = "vfx.play", module = "Vfx", color = Theme.Headers.rebirth },
	{
		id = "world",
		label = "Weather & Events",
		icon = "⛅",
		permission = "dashboard.view",
		module = "World",
		color = Theme.Headers.confirm,
	},
	{
		id = "commands",
		label = "Server Scripts",
		icon = "📜",
		permission = "commands.run",
		module = "Commands",
		color = { hex("FF7A5C"), hex("D83A2E") },
	},
	{
		id = "controls",
		label = "Game Controls",
		icon = "🎛️",
		permission = "panel.open",
		module = "Controls",
		color = Theme.Headers.sell,
	},
	{
		id = "logs",
		label = "Logs",
		icon = "🗂️",
		permission = "logs.view",
		module = "Logs",
		color = { hex("9AA6C4"), hex("5A6482") },
	},
	{
		id = "settings",
		label = "Settings",
		icon = "⚙️",
		permission = "settings.view",
		module = "Settings",
		color = Theme.Buttons.grey,
	},
}

local screen: ScreenGui
local pagesFolder: Instance
local window: Frame
local holder: Frame -- scaled; holds the drop shadow and the window
local scaler: UIScale
local sidebar: Frame
local content: Frame
local toggleButton: TextButton
local tabButtons: { [string]: { gui: TextButton, label: TextLabel, paint: (boolean) -> () } } = {}
local pages: { [string]: Page } = {}
local lastRefresh: { [string]: number } = {}
local refreshing: { [string]: boolean } = {}
local current: string? = nil
local isOpen = false
local compact = false
local playersChip: TextLabel
local headerParts: { [string]: GuiObject } = {} -- repositioned by layout() for desktop / compact
local scopeButtons: { [string]: any } = {}

local function ctxFor(tab: Tab): { [string]: any }
	return { W = W, Net = Net, State = State, App = App, tab = tab }
end

local function refreshPage(id: string)
	local page = pages[id]
	if not (page and page.refresh) or refreshing[id] then
		return
	end
	refreshing[id] = true
	lastRefresh[id] = os.clock()
	task.spawn(function()
		local ok, err = pcall(page.refresh :: any)
		if not ok then
			warn(`[Admin] {id} refresh failed: {err}`)
		end
		refreshing[id] = nil
	end)
end

function App.refreshNow(id: string?)
	local which = id or current
	if which then
		refreshPage(which)
	end
end

function App.show(id: string)
	if current == id then
		return
	end
	W.closePopover()
	if current and pages[current] then
		local old = pages[current]
		old.gui.Visible = false
		if old.onHide then
			task.spawn(old.onHide :: any)
		end
	end
	current = id
	for tid, b in tabButtons do
		b.paint(tid == id)
	end
	local page = pages[id]
	if not page then
		local tab: Tab? = nil
		for _, t in TABS do
			if t.id == id then
				tab = t
			end
		end
		local module = tab and pagesFolder:FindFirstChild(tab.module)
		if not (tab and module) then
			return
		end
		local holder = W.frame(content, tab.id)
		local ok, built = pcall(function()
			return (require(module :: ModuleScript) :: any)(holder, ctxFor(tab))
		end)
		if not ok then
			warn(`[Admin] page {id} failed to build: {built}`)
			W.text(holder, `This tab failed to load ({id}). See the output for details.`, 18, { wrap = true })
			built = { gui = holder }
		end
		page = built :: Page
		page.gui = holder
		pages[id] = page
	end
	local p = page :: Page
	p.gui.Visible = true
	if p.onShow then
		task.spawn(p.onShow :: any)
	end
	refreshPage(id)
end

local function layout()
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	compact = vp.X < 980 or vp.Y < 600
	local side = if compact then 64 else 208
	if compact then
		-- very short screens (phones in landscape) get a slightly smaller panel that still fills the screen
		local s = if vp.Y < 420 then 0.8 else 1
		holder.Position = UDim2.fromScale(0.5, 0.5)
		holder.Size = UDim2.fromOffset((vp.X - 12) / s, (vp.Y - 12) / s)
		scaler.Scale = s
	else
		holder.Size = UDim2.fromOffset(1180, 720)
		holder.Position = UDim2.fromScale(0.5, 0.5)
		local fit = math.min(1, (vp.X - 40) / 1180, (vp.Y - 40) / 720)
		scaler.Scale = math.clamp(fit * (State.prefs.scale or 1), 0.55, 1.25)
	end
	sidebar.Size = UDim2.new(0, side, 1, -84)
	content.Position = UDim2.fromOffset(side + 14, 82)
	content.Size = UDim2.new(1, -side - 24, 1, -92)
	for _, b in tabButtons do
		b.label.Visible = not compact
	end
	local h = headerParts
	if h.title then
		h.title.Visible = not compact
		h.sub.Visible = not compact
		h.chips.Position = if compact then UDim2.fromOffset(10, 6) else UDim2.fromOffset(330, 8)
		h.chips.Size = if compact then UDim2.new(1, -80, 0, 28) else UDim2.new(1, -460, 0, 30)
		h.scope.Position = if compact then UDim2.fromOffset(10, 38) else UDim2.new(1, -420, 0, 38)
		h.scope.Size = if compact then UDim2.new(1, -80, 0, 28) else UDim2.fromOffset(330, 30)
		local align = if compact then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Right
		for _, row in { h.chips, h.scope } do
			local list = row:FindFirstChildOfClass("UIListLayout")
			if list then
				list.HorizontalAlignment = align
			end
		end
	end
end

function App.setOpen(open: boolean)
	if open == isOpen then
		return
	end
	isOpen = open
	W.closePopover()
	if open then
		layout()
		holder.Visible = true
		toggleButton.Visible = false -- the window has its own close button
		if current == nil then
			App.show(TABS[1].id)
		else
			refreshPage(current)
		end
		if not (Motion.reduced() or State.prefs.reducedMotion) then
			local target = scaler.Scale
			scaler.Scale = target * 0.94
			TweenService
				:Create(
					scaler,
					TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = target }
				)
				:Play()
		end
	else
		holder.Visible = false
		toggleButton.Visible = true
	end
end

function App.toggle()
	App.setOpen(not isOpen)
end

function App.isOpen(): boolean
	return isOpen
end

function App.relayout()
	if isOpen then
		layout()
	end
end

local function paintScope()
	for scope, b in scopeButtons do
		b.setStyle(if State.scope == scope then (if scope == "global" then "orange" else "cyan") else "dark")
	end
end

function App.setScope(scope: string)
	if scope == "global" then
		local any = false
		for _, c in State.meta.commands or {} do
			if table.find(c.scopes, "global") then
				any = true
				break
			end
		end
		if not any then
			W.toast("Your role can't run anything on all servers.", "error")
			return
		end
	end
	State.scope = scope
	paintScope()
	State.emit("scope", scope)
	if scope == "global" then
		W.toast("Scope: ALL SERVERS. Weather, events, announcements and flags now go to every live server.", "info")
	end
end

local function buildHeader(meta: { [string]: any })
	local head = Instance.new("Frame")
	head.Name = "Header"
	head.Size = UDim2.new(1, 0, 0, 70)
	head.BorderSizePixel = 0
	head.ClipsDescendants = true
	Ui.corner(head, 10)
	Ui.fill(head, { hex("FFD43A"), hex("FF9512") })
	Ui.studs(head, Theme.Studs.header, 22)
	Ui.strips(head, 0.42)
	head.Parent = window
	Motion.shine(head)
	local title = W.text(head, "🥚 ADMIN PANEL", 30, { autoX = true, stroke = 3 })
	title.Position = UDim2.fromOffset(18, 6)
	title.ZIndex = 3
	local sub = W.text(head, "Kick the Egg · " .. tostring(meta.version), 15, { autoX = true })
	sub.Position = UDim2.fromOffset(20, 42)
	sub.ZIndex = 3
	local chips = W.frame(head, "Chips", UDim2.new(1, -460, 0, 30), UDim2.fromOffset(330, 8))
	chips.ZIndex = 3
	local list = Ui.list(chips, 6, true, Enum.HorizontalAlignment.Right)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	local roleColor = Theme.Buttons[meta.roleColor] or Theme.Buttons.grey
	local _, server = W.chip(chips, "🖥 " .. string.sub(tostring(meta.server), 1, 13), Color3.fromRGB(30, 34, 48))
	server.Parent.LayoutOrder = 1
	local pc, pcl = W.chip(chips, "👥 " .. tostring(#Players:GetPlayers()), Color3.fromRGB(30, 34, 48))
	pc.LayoutOrder = 2
	playersChip = pcl
	local env, _ = W.chip(
		chips,
		string.upper(tostring(meta.environment)),
		if meta.environment == "production"
			then hex("D3121F")
			elseif meta.environment == "staging" then hex("F07000")
			else hex("1199DD")
	)
	env.LayoutOrder = 3
	local role, _ = W.chip(chips, "🛡 " .. string.upper(tostring(meta.role)), roleColor[2])
	role.LayoutOrder = 4
	local scopeRow = W.frame(head, "Scope", UDim2.fromOffset(330, 30), UDim2.new(1, -420, 0, 38))
	scopeRow.ZIndex = 3
	local sl = Ui.list(scopeRow, 6, true, Enum.HorizontalAlignment.Right)
	sl.VerticalAlignment = Enum.VerticalAlignment.Center
	local label = W.text(scopeRow, "SCOPE", 14, { autoX = true })
	label.LayoutOrder = 0
	for i, scope in { "server", "global" } do
		local b = Ui.button(scopeRow, {
			text = if scope == "server" then "THIS SERVER" else "ALL SERVERS",
			style = "dark",
			size = UDim2.fromOffset(124, 28),
			textSize = 17,
			onClick = function()
				App.setScope(scope)
			end,
		})
		b.gui.LayoutOrder = i
		local stroke = b.gui:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = 2
		end
		scopeButtons[scope] = b
	end
	paintScope()
	local close = Ui.closeButton(head, function()
		App.setOpen(false)
	end, 50)
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -12, 0.5, 0)
	close.ZIndex = 4
	W.tooltip(close, `Close (hotkey {State.prefs.hotkey})`)
	headerParts.title, headerParts.sub, headerParts.chips, headerParts.scope = title, sub, chips, scopeRow
end

local function buildSidebar()
	sidebar = W.card(window, "Sidebar", Color3.fromRGB(20, 23, 33))
	sidebar.Position = UDim2.fromOffset(0, 82)
	local scroll = W.scroll(sidebar, "Tabs", UDim2.new(1, -8, 1, -12), UDim2.fromOffset(6, 6))
	scroll.ScrollBarThickness = 3
	for i, tab in TABS do
		if not State.can(tab.permission) then
			continue
		end
		local b = Instance.new("TextButton")
		b.Name = tab.id
		b.Text = ""
		b.AutoButtonColor = false
		b.LayoutOrder = i
		b.Size = UDim2.new(1, -4, 0, 44)
		b.BorderSizePixel = 0
		Ui.corner(b, 8)
		local stroke = Ui.stroke(b, 3)
		b.Parent = scroll
		local icon = W.text(b, tab.icon, 22, { align = Enum.TextXAlignment.Center, stroke = 0 })
		icon.Size = UDim2.fromOffset(44, 44)
		local label = W.text(b, tab.label, 17)
		label.Position = UDim2.fromOffset(46, 0)
		label.Size = UDim2.new(1, -50, 1, 0)
		local function paint(active: boolean)
			if active then
				Ui.fill(b, tab.color)
				stroke.Color = Theme.Colors.border
			else
				local g = b:FindFirstChild("Fill")
				if g then
					g:Destroy()
				end
				b.BackgroundColor3 = Color3.fromRGB(34, 38, 54)
				stroke.Color = Color3.fromRGB(14, 16, 24)
			end
		end
		paint(false)
		Motion.interactive(b)
		b.Activated:Connect(function()
			App.show(tab.id)
		end)
		W.tooltip(b, tab.label, function()
			return compact -- the labels are hidden on small screens
		end)
		tabButtons[tab.id] = { gui = b, label = label, paint = paint }
	end
end

local function buildToggle()
	local b = Instance.new("TextButton")
	b.Name = "AdminToggle"
	b.Text = ""
	b.AutoButtonColor = false
	-- right edge, under the HUD's sound toggle and above the Bag / Eggs / Pets column
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -12, 0, 140)
	b.Size = UDim2.fromOffset(46, 46)
	b.BorderSizePixel = 0
	Ui.corner(b, 12)
	Ui.fill(b, { hex("FFD43A"), hex("FF9512") })
	Ui.stroke(b, 4)
	Ui.studs(b, Theme.Studs.header, 18)
	local icon = W.text(b, "🛡", 26, { align = Enum.TextXAlignment.Center, stroke = 0 })
	icon.Size = UDim2.fromScale(1, 1)
	Motion.interactive(b)
	b.Activated:Connect(App.toggle)
	b.Parent = screen:FindFirstChild("Root")
	toggleButton = b
	W.tooltip(b, `Admin panel ({State.prefs.hotkey})`)
end

function App.start(gui: ScreenGui, folder: Instance)
	screen = gui
	pagesFolder = folder:WaitForChild("Pages")
	State.prefs.hotkey = State.meta.hotkey or "F2"
	local root = W.frame(screen, "Root")
	holder = W.frame(root, "Holder")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Visible = false
	scaler = Instance.new("UIScale")
	scaler.Parent = holder
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 0.5
	shadow.Size = UDim2.new(1, 12, 1, 12)
	shadow.Position = UDim2.fromOffset(2, 8)
	Ui.corner(shadow, 14)
	shadow.Parent = holder
	window = W.card(holder, "Window", Theme.Colors.body, UDim2.fromScale(1, 1))
	Ui.padding(window, 8)
	content = W.frame(window, "Content")
	local overlay = W.frame(screen, "Overlay")
	overlay.ZIndex = 200
	W.init(overlay)
	buildHeader(State.meta)
	buildSidebar()
	buildToggle()
	layout()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(App.relayout)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		local key = (Enum.KeyCode :: any)[State.prefs.hotkey]
		if key and input.KeyCode == key then
			App.toggle()
		end
	end)
	-- the only background loop: refresh the visible page on its interval, and the header player count
	task.spawn(function()
		local headerAt = 0
		while screen.Parent do
			task.wait(0.5)
			if not isOpen or not current then
				continue
			end
			local page = pages[current]
			if page and page.every and os.clock() - (lastRefresh[current] or 0) >= page.every then
				refreshPage(current)
			end
			if os.clock() - headerAt > 10 then
				headerAt = os.clock()
				local res = Net.poll("session.players")
				if res and res.ok then
					playersChip.Text = "👥 " .. tostring(res.data.players)
				end
			end
		end
	end)
	toggleButton.Visible = true
end

return App
