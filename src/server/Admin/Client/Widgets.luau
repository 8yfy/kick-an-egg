--!strict
-- Compact admin widgets in the Kick the Egg look (UI/System Theme + Ui + Motion): Fredoka text with dark outlines,
-- gradient cards with quiet studs and near-black borders, chunky buttons, toggles, sliders, searchable dropdowns,
-- text inputs, status lights, tooltips, a confirmation modal, toasts and pagers. Popovers, tooltips, modals and
-- toasts live on one overlay layer (W.init). Every widget is built once and updated in place (no rebuilds).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local System =
	Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("UI"):WaitForChild("System")
local Theme = require(System:WaitForChild("Theme")) :: any
local Ui = require(System:WaitForChild("Ui")) :: any
local Motion = require(System:WaitForChild("Motion")) :: any

local W = {}
W.Theme = Theme
W.Ui = Ui
W.Motion = Motion

local C = Theme.Colors
W.Colors = {
	ok = Color3.fromRGB(110, 235, 90),
	warn = Color3.fromRGB(255, 200, 60),
	bad = Color3.fromRGB(255, 80, 70),
	off = Color3.fromRGB(120, 126, 145),
	info = Color3.fromRGB(95, 200, 255),
	text = C.text,
	muted = C.muted,
	card = C.card,
	body = C.body,
	edge = C.cardEdge,
	border = C.border,
}

local overlay: Frame = nil :: any
local toastLane: Frame = nil :: any
local openPopover: (() -> ())? = nil

function W.init(layer: Frame)
	overlay = layer
	toastLane = Instance.new("Frame")
	toastLane.Name = "Toasts"
	toastLane.BackgroundTransparency = 1
	toastLane.AnchorPoint = Vector2.new(0.5, 0)
	toastLane.Position = UDim2.new(0.5, 0, 0, 14)
	toastLane.Size = UDim2.fromOffset(520, 0)
	toastLane.AutomaticSize = Enum.AutomaticSize.Y
	toastLane.ZIndex = 400
	Ui.list(toastLane, 6, false, Enum.HorizontalAlignment.Center)
	toastLane.Parent = overlay
end

function W.closePopover()
	W.hideTooltip()
	if openPopover then
		local close = openPopover
		openPopover = nil
		close()
	end
end

-- Basics ---------------------------------------------------------------------------------------------------------

function W.frame(parent: Instance, name: string, size: UDim2?, pos: UDim2?): Frame
	return Ui.frame(parent, name, size, pos)
end

export type TextOpts = {
	color: Color3?,
	align: Enum.TextXAlignment?,
	wrap: boolean?,
	autoX: boolean?,
	name: string?,
	stroke: number?,
}

function W.text(parent: Instance, text: string, size: number, o: TextOpts?): TextLabel
	local opts: TextOpts = o or {}
	local l = Instance.new("TextLabel")
	l.Name = opts.name or "Text"
	l.BackgroundTransparency = 1
	l.Font = Theme.Font
	l.Text = text
	l.TextSize = size
	l.TextColor3 = opts.color or C.text
	l.TextXAlignment = opts.align or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	if opts.wrap then
		l.TextWrapped = true
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.Size = UDim2.new(1, 0, 0, size + 6)
	elseif opts.autoX then
		l.AutomaticSize = Enum.AutomaticSize.X
		l.Size = UDim2.fromOffset(0, size + 6)
	else
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Size = UDim2.new(1, 0, 0, size + 6)
	end
	local s = Instance.new("UIStroke")
	s.Thickness = opts.stroke or (if size >= 20 then 2 else 1.2)
	s.Color = C.border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- Bordered card: gradient pair (or flat colour), quiet studs, near-black border.
function W.card(parent: Instance, name: string, fill: any?, size: UDim2?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	f.Size = size or UDim2.fromScale(1, 0)
	Ui.corner(f, 8)
	if typeof(fill) == "table" then
		Ui.fill(f, fill)
	else
		f.BackgroundColor3 = fill or C.card
	end
	Ui.stroke(f, 3)
	Ui.studs(f, Theme.Studs.card + 0.06, 22)
	f.Parent = parent
	return f
end

function W.vstack(parent: Instance, name: string, gap: number?, pad: number?): Frame
	local f = Ui.frame(parent, name, UDim2.fromScale(1, 0))
	f.AutomaticSize = Enum.AutomaticSize.Y
	Ui.list(f, gap or 8)
	if pad then
		Ui.padding(f, pad)
	end
	return f
end

function W.row(parent: Instance, name: string, height: number, gap: number?): Frame
	local f = Ui.frame(parent, name, UDim2.new(1, 0, 0, height))
	local l = Ui.list(f, gap or 8, true)
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	return f
end

function W.scroll(parent: Instance, name: string, size: UDim2?, pos: UDim2?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = name
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Size = size or UDim2.fromScale(1, 1)
	s.Position = pos or UDim2.new()
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = C.muted
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.ElasticBehavior = Enum.ElasticBehavior.Never
	s.Parent = parent
	Ui.list(s, 6)
	local p = Instance.new("UIPadding")
	p.PaddingRight = UDim.new(0, 10)
	p.PaddingLeft = UDim.new(0, 2)
	p.PaddingTop = UDim.new(0, 2)
	p.PaddingBottom = UDim.new(0, 6)
	p.Parent = s
	return s
end

-- Section: coloured strip header + a content stack that grows with its children.
function W.section(parent: Instance, title: string, pair: any?, order: number?): Frame
	local outer = W.card(parent, title, C.card)
	outer.AutomaticSize = Enum.AutomaticSize.Y
	outer.LayoutOrder = order or 0
	local head = Instance.new("Frame")
	head.Name = "Head"
	head.Size = UDim2.new(1, 0, 0, 34)
	head.BorderSizePixel = 0
	head.ClipsDescendants = true
	Ui.corner(head, 8)
	Ui.fill(head, pair or Theme.Headers.index)
	Ui.studs(head, Theme.Studs.header, 20)
	Ui.strips(head, 0.8)
	head.Parent = outer
	local t = W.text(head, string.upper(title), 18, { stroke = 2 })
	t.Position = UDim2.fromOffset(12, 0)
	t.Size = UDim2.new(1, -24, 1, 0)
	t.ZIndex = 3
	local body = W.vstack(outer, "Body", 8)
	body.Position = UDim2.fromOffset(0, 34)
	Ui.padding(body, 10)
	return body
end

-- Buttons ---------------------------------------------------------------------------------------------------------

export type Button = {
	gui: TextButton,
	setText: (string) -> (),
	setEnabled: (boolean) -> (),
	setPending: (boolean, string?) -> (),
	setStyle: (string) -> (),
}

function W.button(
	parent: Instance,
	text: string,
	style: string,
	width: number?,
	onClick: () -> (),
	tip: string?
): Button
	local b = Ui.button(parent, {
		text = text,
		style = style,
		size = if width then UDim2.fromOffset(width, 38) else UDim2.new(1, 0, 0, 38),
		textSize = 17,
		onClick = onClick,
	})
	local stroke = b.gui:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 3
	end
	if tip then
		W.tooltip(b.gui, tip)
	end
	return b
end

function W.chip(parent: Instance, text: string, color: Color3?): (Frame, TextLabel)
	local f = Instance.new("Frame")
	f.Name = "Chip"
	f.AutomaticSize = Enum.AutomaticSize.X
	f.Size = UDim2.fromOffset(0, 26)
	f.BackgroundColor3 = color or C.tabIdle
	f.BorderSizePixel = 0
	Ui.corner(f, 6)
	Ui.stroke(f, 2)
	Ui.padding(f, 8, 0)
	local t = W.text(f, text, 15, { autoX = true })
	t.Size = UDim2.new(0, 0, 1, 0)
	f.Parent = parent
	return f, t
end

-- Status light: a glowing dot + label. state: ok | warn | bad | off | info
function W.light(parent: Instance, state: string, text: string): { gui: Frame, set: (string, string?) -> () }
	local row = Ui.frame(parent, "Light", UDim2.new(1, 0, 0, 22))
	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.Size = UDim2.fromOffset(14, 14)
	dot.Position = UDim2.new(0, 2, 0.5, -7)
	dot.BorderSizePixel = 0
	Ui.corner(dot, 7)
	Ui.stroke(dot, 2)
	dot.Parent = row
	local label = W.text(row, text, 15)
	label.Position = UDim2.fromOffset(24, 0)
	label.Size = UDim2.new(1, -24, 1, 0)
	local function set(s: string, t: string?)
		dot.BackgroundColor3 = W.Colors[s] or W.Colors.off
		if t then
			label.Text = t
		end
	end
	set(state, text)
	return { gui = row, set = set }
end

-- Key / value row (returns the value label to update in place).
function W.kv(parent: Instance, key: string, value: string, order: number?): TextLabel
	local row = Ui.frame(parent, key, UDim2.new(1, 0, 0, 22))
	row.LayoutOrder = order or 0
	local k = W.text(row, key, 15, { color = C.muted })
	k.Size = UDim2.new(0.45, 0, 1, 0)
	local v = W.text(row, value, 15, { align = Enum.TextXAlignment.Right })
	v.Name = "Value"
	v.Position = UDim2.fromScale(0.45, 0)
	v.Size = UDim2.new(0.55, 0, 1, 0)
	return v
end

-- Inputs ----------------------------------------------------------------------------------------------------------

function W.input(parent: Instance, placeholder: string, width: number?, onCommit: ((string) -> ())?): TextBox
	local box = Instance.new("TextBox")
	box.Name = "Input"
	box.Size = if width then UDim2.fromOffset(width, 36) else UDim2.new(1, 0, 0, 36)
	box.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = false
	box.Font = Theme.Font
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(120, 128, 150)
	box.Text = ""
	box.TextSize = 16
	box.TextColor3 = C.text
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextTruncate = Enum.TextTruncate.AtEnd
	Ui.corner(box, 6)
	local stroke = Ui.stroke(box, 2, C.cardEdge)
	Ui.padding(box, 10, 0)
	box.Focused:Connect(function()
		stroke.Color = Color3.fromRGB(95, 200, 255)
	end)
	box.FocusLost:Connect(function()
		stroke.Color = C.cardEdge
		if onCommit then
			onCommit(box.Text)
		end
	end)
	box.Parent = parent
	return box
end

export type Toggle = { gui: Frame, set: (boolean) -> (), get: () -> boolean, setEnabled: (boolean) -> () }

function W.toggle(parent: Instance, label: string, value: boolean, onChange: (boolean) -> (), tip: string?): Toggle
	local row = Ui.frame(parent, label, UDim2.new(1, 0, 0, 32))
	local t = W.text(row, label, 16)
	t.Size = UDim2.new(1, -70, 1, 0)
	local track = Instance.new("TextButton")
	track.Name = "Track"
	track.Text = ""
	track.AutoButtonColor = false
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Position = UDim2.new(1, -2, 0.5, 0)
	track.Size = UDim2.fromOffset(58, 28)
	track.BorderSizePixel = 0
	Ui.corner(track, 14)
	Ui.stroke(track, 3)
	track.Parent = row
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(20, 20)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	Ui.corner(knob, 10)
	Ui.stroke(knob, 2)
	knob.Parent = track
	local on, enabled = value, true
	local function paint(animate: boolean)
		Ui.fill(
			track,
			if not enabled then Theme.Buttons.disabled elseif on then Theme.Buttons.lime else Theme.Buttons.dark
		)
		local goal = { Position = if on then UDim2.new(1, -24, 0.5, 0) else UDim2.new(0, 4, 0.5, 0) }
		if animate and not Motion.reduced() then
			TweenService:Create(knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad), goal):Play()
		else
			knob.Position = goal.Position
		end
	end
	paint(false)
	track.Activated:Connect(function()
		if not enabled then
			return
		end
		on = not on
		paint(true)
		onChange(on)
	end)
	if tip then
		W.tooltip(track, tip)
	end
	return {
		gui = row,
		set = function(v: boolean)
			on = v
			paint(false)
		end,
		get = function()
			return on
		end,
		setEnabled = function(v: boolean)
			enabled = v
			paint(false)
		end,
	}
end

export type Slider = { gui: Frame, set: (number) -> (), get: () -> number, setEnabled: (boolean) -> () }

-- Bounded slider. onChange fires once on release (or Enter in the value box), never per drag frame.
function W.slider(
	parent: Instance,
	label: string,
	min: number,
	max: number,
	step: number,
	value: number,
	onChange: (number) -> (),
	fmt: ((number) -> string)?
): Slider
	local row = Ui.frame(parent, label, UDim2.new(1, 0, 0, 52))
	local t = W.text(row, label, 15, { color = C.muted })
	t.Size = UDim2.new(1, -80, 0, 20)
	local box = W.input(row, "", 72)
	box.AnchorPoint = Vector2.new(1, 0)
	box.Position = UDim2.new(1, 0, 0, -4)
	box.Size = UDim2.fromOffset(72, 26)
	box.TextXAlignment = Enum.TextXAlignment.Center
	local bar = Instance.new("TextButton")
	bar.Name = "Bar"
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Position = UDim2.fromOffset(0, 30)
	bar.Size = UDim2.new(1, -14, 0, 12)
	bar.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	bar.BorderSizePixel = 0
	Ui.corner(bar, 6)
	Ui.stroke(bar, 2)
	bar.Parent = row
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, 6)
	Ui.fill(fill, Theme.Buttons.cyan)
	fill.Parent = bar
	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(22, 22)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	Ui.corner(knob, 11)
	Ui.stroke(knob, 3)
	knob.Parent = bar
	local current, enabled = value, true
	local format = fmt
		or function(n: number): string
			return if step >= 1 then tostring(math.floor(n + 0.5)) else string.format("%.2f", n)
		end
	local function snap(n: number): number
		n = math.clamp(n, min, max)
		return math.clamp(min + math.floor((n - min) / step + 0.5) * step, min, max)
	end
	local function show(n: number)
		local a = if max > min then (n - min) / (max - min) else 0
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		box.Text = format(n)
	end
	show(current)
	local dragging = false
	local function fromX(x: number)
		local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
		current = snap(min + a * (max - min))
		show(current)
	end
	bar.InputBegan:Connect(function(input)
		if not enabled then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			dragging = false
			onChange(current)
		end
	end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n and enabled then
			current = snap(n)
			onChange(current)
		end
		show(current)
	end)
	return {
		gui = row,
		set = function(n: number)
			current = snap(n)
			show(current)
		end,
		get = function()
			return current
		end,
		setEnabled = function(on: boolean)
			enabled = on
			box.TextEditable = on
			Ui.fill(fill, if on then Theme.Buttons.cyan else Theme.Buttons.disabled)
		end,
	}
end

export type Dropdown = {
	gui: Frame,
	set: (string?) -> (),
	get: () -> string?,
	setOptions: ({ string }, { [string]: string }?) -> (),
	setEnabled: (boolean) -> (),
}

-- Dropdown with an optional search box (long lists). `labels` maps option -> shown text.
function W.dropdown(
	parent: Instance,
	label: string?,
	options: { string },
	value: string?,
	onChange: (string) -> (),
	labels: { [string]: string }?
): Dropdown
	local row = Ui.frame(parent, label or "Dropdown", UDim2.new(1, 0, 0, if label then 58 else 38))
	if label then
		local t = W.text(row, label, 15, { color = C.muted })
		t.Size = UDim2.new(1, 0, 0, 20)
	end
	local btn = Instance.new("TextButton")
	btn.Name = "Field"
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Position = UDim2.fromOffset(0, if label then 22 else 2)
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	btn.BorderSizePixel = 0
	Ui.corner(btn, 6)
	Ui.stroke(btn, 2, C.cardEdge)
	btn.Parent = row
	local shown = W.text(btn, "", 16)
	shown.Position = UDim2.fromOffset(10, 0)
	shown.Size = UDim2.new(1, -40, 1, 0)
	local caret = W.text(btn, "▼", 14, { align = Enum.TextXAlignment.Right })
	caret.Position = UDim2.new(1, -28, 0, 0)
	caret.Size = UDim2.new(0, 20, 1, 0)
	local opts, names = options, labels or {}
	local current, enabled = value, true
	local function paint()
		shown.Text = if current then (names[current] or current) else "Choose..."
		shown.TextColor3 = if enabled then C.text else C.muted
	end
	paint()
	local function open()
		W.closePopover()
		local abs, size = btn.AbsolutePosition, btn.AbsoluteSize
		local layerPos = overlay.AbsolutePosition
		local pop = W.card(overlay, "Popover", Color3.fromRGB(22, 25, 36))
		pop.ZIndex = 300
		local height = math.min(320, 46 + #opts * 32)
		local below = abs.Y + size.Y + height < overlay.AbsoluteSize.Y + layerPos.Y
		pop.Size = UDim2.fromOffset(math.max(size.X, 220), height)
		pop.Position = UDim2.fromOffset(
			abs.X - layerPos.X,
			if below then abs.Y - layerPos.Y + size.Y + 4 else abs.Y - layerPos.Y - height - 4
		)
		local searchBox: TextBox? = nil
		local listTop = 6
		if #opts > 10 then
			local sb = W.input(pop, "Search...", nil)
			sb.Position = UDim2.fromOffset(6, 6)
			sb.Size = UDim2.new(1, -12, 0, 32)
			searchBox = sb
			listTop = 44
		end
		local list = W.scroll(pop, "List", UDim2.new(1, -8, 1, -listTop - 4), UDim2.fromOffset(4, listTop))
		local function fill(filter: string)
			for _, c in list:GetChildren() do
				if c:IsA("TextButton") then
					c:Destroy()
				end
			end
			local needle = string.lower(filter)
			local shownCount = 0
			for i, o in opts do
				local text = names[o] or o
				if needle ~= "" and not string.find(string.lower(text), needle, 1, true) then
					continue
				end
				shownCount += 1
				if shownCount > 120 then
					break -- the search box narrows long lists
				end
				local item = Instance.new("TextButton")
				item.Name = o
				item.LayoutOrder = i
				item.Text = ""
				item.AutoButtonColor = false
				item.Size = UDim2.new(1, 0, 0, 28)
				item.BackgroundColor3 = if o == current
					then Color3.fromRGB(40, 110, 170)
					else Color3.fromRGB(30, 34, 48)
				item.BorderSizePixel = 0
				Ui.corner(item, 5)
				local it = W.text(item, text, 15)
				it.Position = UDim2.fromOffset(8, 0)
				it.Size = UDim2.new(1, -16, 1, 0)
				item.MouseEnter:Connect(function()
					if o ~= current then
						item.BackgroundColor3 = Color3.fromRGB(46, 52, 72)
					end
				end)
				item.MouseLeave:Connect(function()
					item.BackgroundColor3 = if o == current
						then Color3.fromRGB(40, 110, 170)
						else Color3.fromRGB(30, 34, 48)
				end)
				item.Activated:Connect(function()
					current = o
					paint()
					W.closePopover()
					onChange(o)
				end)
				item.Parent = list
			end
		end
		fill("")
		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				fill(searchBox.Text)
			end)
			task.defer(function()
				searchBox:CaptureFocus()
			end)
		end
		openPopover = function()
			pop:Destroy()
		end
	end
	btn.Activated:Connect(function()
		if enabled and #opts > 0 then
			open()
		end
	end)
	return {
		gui = row,
		set = function(v: string?)
			current = v
			paint()
		end,
		get = function()
			return current
		end,
		setOptions = function(list: { string }, newLabels: { [string]: string }?)
			opts = list
			if newLabels then
				names = newLabels
			end
			if current and not table.find(opts, current) then
				current = opts[1]
			end
			paint()
		end,
		setEnabled = function(on: boolean)
			enabled = on
			paint()
		end,
	}
end

-- Overlay: tooltips, toasts, confirmation --------------------------------------------------------------------

local tipLabel: Frame? = nil
function W.hideTooltip()
	if tipLabel then
		tipLabel:Destroy()
		tipLabel = nil
	end
end

-- Hover tooltip. `when` (optional) decides at hover time whether to show it.
function W.tooltip(gui: GuiObject, text: string, when: (() -> boolean)?)
	gui.MouseEnter:Connect(function()
		if when and not when() then
			return
		end
		if tipLabel then
			tipLabel:Destroy()
		end
		local f = W.card(overlay, "Tooltip", Color3.fromRGB(12, 14, 20))
		f.ZIndex = 350
		f.AutomaticSize = Enum.AutomaticSize.XY
		f.Size = UDim2.fromOffset(0, 0)
		Ui.padding(f, 8, 4)
		local t = W.text(f, text, 14, { autoX = true })
		t.ZIndex = 351
		local constraint = Instance.new("UISizeConstraint")
		constraint.MaxSize = Vector2.new(320, 200)
		constraint.Parent = f
		local abs = gui.AbsolutePosition - overlay.AbsolutePosition
		f.Position = UDim2.fromOffset(abs.X, abs.Y + gui.AbsoluteSize.Y + 6)
		tipLabel = f
	end)
	gui.MouseLeave:Connect(W.hideTooltip)
	gui.AncestryChanged:Connect(W.hideTooltip)
end

function W.toast(text: string, kind: string?)
	local style = if kind == "good" then W.Colors.ok elseif kind == "error" then W.Colors.bad else W.Colors.info
	local f = W.card(toastLane, "Toast", Color3.fromRGB(18, 20, 30))
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Size = UDim2.fromOffset(500, 0)
	f.ZIndex = 401
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 6, 1, 0)
	bar.BackgroundColor3 = style
	bar.BorderSizePixel = 0
	bar.Parent = f
	local t = W.text(f, text, 16, { wrap = true })
	t.Position = UDim2.fromOffset(16, 0)
	t.Size = UDim2.new(1, -24, 0, 22)
	Ui.padding(f, 6)
	Motion.popIn(f)
	task.delay(if kind == "error" then 5 else 3, function()
		f:Destroy()
	end)
	while #toastLane:GetChildren() > 5 do -- the list layout + 4 toasts
		local oldest: Instance? = nil
		for _, c in toastLane:GetChildren() do
			if c:IsA("Frame") then
				oldest = c
				break
			end
		end
		if not oldest then
			break
		end
		oldest:Destroy()
	end
end

-- Yields until the admin answers. Returns (confirmed, reason?). `reason` asks for a logged reason (min 3 chars).
function W.confirm(title: string, message: string, danger: boolean?, needReason: boolean?): (boolean, string?)
	W.closePopover()
	local scrim = Instance.new("TextButton")
	scrim.Name = "Confirm"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.BackgroundColor3 = Color3.new(0, 0, 0)
	scrim.BackgroundTransparency = 0.45
	scrim.ZIndex = 380
	scrim.Parent = overlay
	local box = W.card(scrim, "Box", C.body, UDim2.fromOffset(460, 0))
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Position = UDim2.fromScale(0.5, 0.5)
	local body = W.section(box, title, if danger then Theme.Buttons.red else Theme.Headers.confirm)
	W.text(body, message, 16, { wrap = true })
	local reasonBox: TextBox? = nil
	if needReason then
		reasonBox = W.input(body, "Reason (logged, 3-120 characters)", nil)
	end
	local buttons = W.row(body, "Buttons", 40, 10)
	local result: boolean? = nil
	W.button(buttons, "CANCEL", "grey", 150, function()
		result = false
	end)
	W.button(buttons, if danger then "CONFIRM" else "OK", if danger then "red" else "lime", 150, function()
		if reasonBox and #reasonBox.Text < 3 then
			W.toast("Write a reason first (it goes into the audit log).", "error")
			return
		end
		result = true
	end)
	Motion.popIn(box)
	while result == nil and scrim.Parent do
		task.wait()
	end
	local reason = if reasonBox then reasonBox.Text else nil
	scrim:Destroy()
	return result == true, reason
end

-- Pager: "< page / pages >".
function W.pager(parent: Instance, onPage: (number) -> ()): { gui: Frame, set: (number, number) -> () }
	local row = W.row(parent, "Pager", 40, 8)
	local page, pages = 1, 1
	local prev = W.button(row, "<", "dark", 50, function()
		if page > 1 then
			onPage(page - 1)
		end
	end)
	local label = W.text(row, "1 / 1", 16, { align = Enum.TextXAlignment.Center })
	label.Size = UDim2.fromOffset(90, 30)
	local nextB = W.button(row, ">", "dark", 50, function()
		if page < pages then
			onPage(page + 1)
		end
	end)
	return {
		gui = row,
		set = function(p: number, n: number)
			page, pages = p, n
			label.Text = `{p} / {n}`
			prev.setEnabled(p > 1)
			nextB.setEnabled(p < n)
		end,
	}
end

-- Clears the generated children of a list (keeps layouts / padding).
function W.clear(container: Instance)
	for _, c in container:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

-- "12:05:33" for unix seconds; "3m 20s" for durations.
function W.clock(unix: number): string
	return os.date("%H:%M:%S", math.floor(unix)) :: string
end
function W.duration(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s >= 3600 then
		return string.format("%dh %02dm", s // 3600, (s % 3600) // 60)
	elseif s >= 60 then
		return string.format("%dm %02ds", s // 60, s % 60)
	end
	return `{s}s`
end

-- Shows a pipeline result as a toast; returns ok.
function W.report(res: { [string]: any }, okText: string?): boolean
	if res.ok then
		if okText then
			W.toast(okText, "good")
		end
		return true
	end
	W.toast(`{res.message or "Failed."} [{res.code or "error"}]`, "error")
	return false
end

return W
