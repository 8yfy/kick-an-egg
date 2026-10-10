--!strict
-- Native building blocks for the Kick The Egg UI (UI handoff v2 VISUAL-CONTRACT): art images from the
-- AssetIds registry (Fit, white tint, untouched alpha; a named marker if the image can't load), stud
-- surfaces with 5 px near-black borders, section headers (gradient + quiet studs + two diagonal strips +
-- clipped shine), chunky gradient buttons with a top highlight and states, full-width tabs, progress bars,
-- scroll lists with responsive grids and lazy 3D pet/egg previews (pets and eggs have no supplied art).
-- Text is always real TextLabels (never baked into images), fixed sizes, never below Theme.Layout.minText.
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetIds = require(script.Parent.AssetIds)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)

local C, L = Theme.Colors, Theme.Layout
local Ui = {}

export type Pair = Theme.Pair

-- Basics ---------------------------------------------------------------------------------------------------

function Ui.corner(gui: GuiObject, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or L.radius)
	c.Parent = gui
end

function Ui.stroke(gui: GuiObject, thickness: number?, color: Color3?): UIStroke
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 4
	s.Color = color or C.border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = gui
	return s
end

function Ui.padding(gui: GuiObject, x: number, y: number?)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, x), UDim.new(0, x)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, y or x), UDim.new(0, y or x)
	p.Parent = gui
end

function Ui.list(gui: GuiObject, gap: number, horizontal: boolean?, align: Enum.HorizontalAlignment?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap)
	l.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
	if horizontal then
		l.VerticalAlignment = Enum.VerticalAlignment.Center
	end
	l.Parent = gui
	return l
end

-- Vertical gradient fill (top -> bottom). More than two colours make a multi-stop ramp.
function Ui.fill(gui: GuiObject, pair: Pair, rotation: number?): UIGradient
	local g = gui:FindFirstChild("Fill")
	if not (g and g:IsA("UIGradient")) then
		local ng = Instance.new("UIGradient")
		ng.Name = "Fill"
		ng.Parent = gui
		g = ng
	end
	local grad = g :: UIGradient
	grad.Rotation = rotation or 90
	if #pair >= 3 then
		local stops = {}
		for i, c in pair do
			table.insert(stops, ColorSequenceKeypoint.new((i - 1) / (#pair - 1), c))
		end
		grad.Color = ColorSequence.new(stops)
	else
		grad.Color = ColorSequence.new(pair[1], pair[2])
	end
	gui.BackgroundColor3 = Color3.new(1, 1, 1)
	gui.BackgroundTransparency = 0
	return grad
end

function Ui.frame(parent: Instance, name: string, size: UDim2?, position: UDim2?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Size = size or UDim2.fromScale(1, 1)
	f.Position = position or UDim2.new()
	f.Parent = parent
	return f
end

-- Small shallow square studs (tiled texture), quiet and static.
function Ui.studs(gui: GuiObject, transparency: number?, tile: number?): ImageLabel?
	local image = AssetIds.get("texture_studs")
	if not image then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = "Studs"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = image
	img.ImageTransparency = transparency or Theme.Studs.body
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(tile or Theme.Studs.tile, tile or Theme.Studs.tile)
	img.ZIndex = 0
	local corner = gui:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = img
	end
	img.Parent = gui
	return img
end

-- 1-2 px light inner edge.
function Ui.innerEdge(gui: GuiObject, transparency: number?, inset: number?)
	local i = inset or 4
	local rim = Instance.new("Frame")
	rim.Name = "InnerEdge"
	rim.BackgroundTransparency = 1
	rim.Size = UDim2.new(1, -2 * i, 1, -2 * i)
	rim.Position = UDim2.fromOffset(i, i)
	rim.ZIndex = 1
	Ui.corner(rim, math.max(2, L.radius - 3))
	Ui.stroke(rim, 2, Color3.new(1, 1, 1)).Transparency = transparency or 0.75
	rim.Parent = gui
end

-- Two diagonal translucent strips (header decoration, static) clipped by the parent.
function Ui.strips(gui: GuiObject, at: number?)
	local x = at or 0.62
	for i, w in { 70, 34 } do
		local s = Instance.new("Frame")
		s.Name = "Strip" .. i
		s.BackgroundColor3 = Color3.new(1, 1, 1)
		s.BackgroundTransparency = 0.82
		s.BorderSizePixel = 0
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Size = UDim2.new(0, w, 3, 0)
		s.Rotation = 28
		s.Position = UDim2.new(x + (i - 1) * 0.06, 0, 0.5, 0)
		s.ZIndex = 1
		s.Parent = gui
	end
end

export type TextOpts = {
	color: Color3?,
	align: Enum.TextXAlignment?,
	wrap: boolean?,
	stroke: number?,
	name: string?,
	autoX: boolean?,
}

-- Fredoka text with a dark outline. Height = size + 8; `wrap` grows vertically, `autoX` grows width.
function Ui.text(parent: Instance, text: string, size: number, opts: TextOpts?): TextLabel
	local o: TextOpts = opts or {}
	local l = Instance.new("TextLabel")
	l.Name = o.name or "Text"
	l.Text = text
	l.BackgroundTransparency = 1
	l.Font = Theme.Font
	l.TextSize = math.max(size, L.minText)
	l.TextColor3 = o.color or C.text
	l.TextXAlignment = o.align or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	if o.wrap then
		l.TextWrapped = true
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.Size = UDim2.new(1, 0, 0, 0)
	elseif o.autoX then
		l.AutomaticSize = Enum.AutomaticSize.X
		l.Size = UDim2.fromOffset(0, l.TextSize + 8)
	else
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Size = UDim2.new(1, 0, 0, l.TextSize + 8)
	end
	local s = Instance.new("UIStroke")
	s.Thickness = o.stroke or math.max(2, math.floor(l.TextSize / 11))
	s.Color = C.border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- Bordered surface: gradient (or flat colour) + studs + near-black border.
function Ui.surface(parent: Instance, name: string, fill: Pair | Color3, studs: number?, border: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BorderSizePixel = 0
	Ui.corner(f)
	if typeof(fill) == "Color3" then
		f.BackgroundColor3 = fill
	else
		Ui.fill(f, fill)
	end
	Ui.stroke(f, border or 4)
	Ui.studs(f, studs)
	f.Parent = parent
	return f
end

-- Art -----------------------------------------------------------------------------------------------------

-- Conspicuous named placeholder for art that has no image (or failed to load). Never a substitute picture.
local function missingMarker(parent: Instance, key: string): Frame
	local m = Instance.new("Frame")
	m.Name = "MissingArt"
	m.BackgroundColor3 = Color3.fromHex("2A0A24")
	m.BackgroundTransparency = 0.1
	m.Size = UDim2.fromScale(1, 1)
	Ui.corner(m)
	Ui.stroke(m, 3, C.missing)
	local t =
		Ui.text(m, "MISSING ART\n" .. key, 17, { wrap = true, align = Enum.TextXAlignment.Center, color = C.missing })
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.Size = UDim2.new(1, -8, 0, 0)
	m.Parent = parent
	return m
end

-- A supplied PNG as an ImageLabel: Fit, white tint, untouched alpha, filling `parent` (or `size`). If the
-- registry has no image, or Roblox reports the load failed, a named missing-art marker shows instead.
function Ui.art(parent: Instance, key: string, size: UDim2?, scaleType: Enum.ScaleType?): ImageLabel
	local img = Instance.new("ImageLabel")
	img.Name = "Art"
	img.BackgroundTransparency = 1
	img.ImageColor3 = Color3.new(1, 1, 1)
	img.ImageTransparency = 0
	img.ScaleType = scaleType or Enum.ScaleType.Fit
	img.Size = size or UDim2.fromScale(1, 1)
	img:SetAttribute("ArtKey", key)
	local id = AssetIds.get(key)
	img.Parent = parent
	if not id then
		missingMarker(img, key)
		return img
	end
	img.Image = id
	task.spawn(function()
		local ok = true
		pcall(function()
			ContentProvider:PreloadAsync({ img }, function(_content: string, status: Enum.AssetFetchStatus)
				if status == Enum.AssetFetchStatus.Failure then
					ok = false
				end
			end)
		end)
		if not ok and img.Parent then
			warn(`[Ui.art] image for "{key}" failed to load ({id})`)
			missingMarker(img, key)
		end
	end)
	return img
end

-- Cropped art that fills its box (banner backdrops, zone strips).
function Ui.cover(parent: Instance, key: string): ImageLabel
	return Ui.art(parent, key, nil, Enum.ScaleType.Crop)
end

-- Glow + rays images behind featured art (separate tinted layers, sized from the holder's height).
function Ui.glow(holder: GuiObject, color: Color3, rays: boolean?, scale: number?): ImageLabel?
	local s = scale or 1
	if rays then
		local r = AssetIds.get("fx_rays")
		if r then
			local img = Instance.new("ImageLabel")
			img.Name = "Rays"
			img.BackgroundTransparency = 1
			img.AnchorPoint = Vector2.new(0.5, 0.5)
			img.Position = UDim2.fromScale(0.5, 0.5)
			img.Size = UDim2.fromScale(1.3 * s, 1.3 * s)
			img.SizeConstraint = Enum.SizeConstraint.RelativeYY
			img.Image = r
			img.ImageColor3 = color
			img.ImageTransparency = 0.55
			img.ZIndex = 1
			img.Parent = holder
		end
	end
	local image = AssetIds.get("fx_glow")
	if not image then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = "Glow"
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.fromScale(1.05 * s, 1.05 * s)
	img.SizeConstraint = Enum.SizeConstraint.RelativeYY
	img.Image = image
	img.ImageColor3 = color
	img.ImageTransparency = 0.25
	img.ZIndex = 1
	img.Parent = holder
	return img
end

-- Section header ------------------------------------------------------------------------------------------

export type Header = { gui: Frame, title: TextLabel, icon: GuiObject? }

-- Gradient + quiet studs + two diagonal strips + clipped shine sweep; big uppercase outlined title.
function Ui.header(
	parent: Instance,
	fill: Pair,
	title: string,
	iconKey: string?,
	height: number?,
	titleSize: number?
): Header
	local h = height or L.header
	local f = Instance.new("Frame")
	f.Name = "Header"
	f.Size = UDim2.new(1, 0, 0, h)
	f.ClipsDescendants = true
	f.BorderSizePixel = 0
	Ui.corner(f)
	Ui.fill(f, fill)
	Ui.studs(f, Theme.Studs.header)
	Ui.strips(f)
	f.Parent = parent
	Motion.shine(f)
	local row = Ui.frame(f, "TitleRow", UDim2.new(1, -24, 1, 0), UDim2.fromOffset(18, 0))
	row.ZIndex = 3
	Ui.list(row, 12, true)
	local icon: GuiObject? = nil
	if iconKey then
		local iconSize = math.floor(h * 0.74)
		local holder = Ui.frame(row, "Icon", UDim2.fromOffset(iconSize, iconSize))
		holder.LayoutOrder = 1
		Ui.art(holder, iconKey).ZIndex = 3
		icon = holder
	end
	local t = Ui.text(
		row,
		string.upper(title),
		titleSize or math.floor(h * 0.56),
		{ autoX = true, stroke = 4, name = "Title" }
	)
	t.LayoutOrder = 2
	t.ZIndex = 3
	return { gui = f, title = t, icon = icon }
end

-- Buttons --------------------------------------------------------------------------------------------------

export type Button = {
	gui: TextButton,
	label: TextLabel,
	setText: (text: string) -> (),
	setStyle: (style: string) -> (),
	setEnabled: (on: boolean) -> (),
	setPending: (on: boolean, text: string?) -> (),
	setTextColor: (color: Color3) -> (),
	enabled: () -> boolean,
}

export type ButtonOpts = {
	text: string,
	style: string, -- Theme.Buttons key
	size: UDim2,
	textSize: number?,
	icon: string?, -- AssetIds key drawn left of the label
	name: string?,
	onClick: () -> (),
}

-- Chunky gradient button: near-black border, top highlight, quiet studs, label always visible, >= 48 px
-- target, hover/press/focus motion, disabled and pending (blocks repeats until the caller clears it).
function Ui.button(parent: Instance, o: ButtonOpts): Button
	local b = Instance.new("TextButton")
	b.Name = o.name or o.text
	b.Text = ""
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Size = o.size
	b.Selectable = true
	Ui.corner(b)
	Ui.fill(b, Theme.Buttons[o.style] or Theme.Buttons.grey)
	Ui.stroke(b, 4)
	Ui.studs(b, Theme.Studs.header, 20)
	local hi = Instance.new("Frame") -- top highlight
	hi.Name = "Highlight"
	hi.BackgroundColor3 = Color3.new(1, 1, 1)
	hi.BackgroundTransparency = 0.78
	hi.BorderSizePixel = 0
	hi.Position = UDim2.fromOffset(4, 4)
	hi.Size = UDim2.new(1, -8, 0.38, -4)
	hi.ZIndex = 1
	Ui.corner(hi, 5)
	hi.Parent = b
	local row = Ui.frame(b, "Content")
	row.ZIndex = 2
	local list = Ui.list(row, 10, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	local ts = o.textSize or 28
	if o.icon then
		local holder = Ui.frame(row, "Icon", UDim2.fromOffset(ts + 14, ts + 14))
		holder.LayoutOrder = 1
		holder.ZIndex = 2
		Ui.art(holder, o.icon).ZIndex = 2
	end
	local label =
		Ui.text(row, o.text, ts, { align = Enum.TextXAlignment.Center, autoX = true, name = "Label", stroke = 3 })
	label.LayoutOrder = 2
	label.ZIndex = 2
	local style = o.style
	local isEnabled, isPending = true, false
	local idleText = o.text
	local function paint()
		Ui.fill(b, Theme.Buttons[if isEnabled or isPending then style else "disabled"] or Theme.Buttons.grey)
		label.TextTransparency = if isEnabled or isPending then 0 else 0.2
		local muted = not (isEnabled or isPending) or style == "dark" or style == "grey"
		hi.BackgroundTransparency = if muted then 0.93 else 0.78 -- bright highlight only on coloured buttons
	end
	paint()
	Motion.interactive(b, function()
		return isEnabled and not isPending
	end)
	b.Activated:Connect(function()
		if isEnabled and not isPending then
			o.onClick()
		end
	end)
	b.Parent = parent
	return {
		gui = b,
		label = label,
		setText = function(text: string)
			idleText = text
			if not isPending then
				label.Text = text
			end
		end,
		setStyle = function(s: string)
			style = s
			paint()
		end,
		setEnabled = function(on: boolean)
			isEnabled = on
			b.Selectable = on
			paint()
		end,
		setPending = function(on: boolean, text: string?)
			isPending = on
			label.Text = if on then text or "..." else idleText
			paint()
		end,
		setTextColor = function(color: Color3)
			label.TextColor3 = color
		end,
		enabled = function()
			return isEnabled and not isPending
		end,
	}
end

-- Red square close button (70 x 70 by default) with a white X.
function Ui.closeButton(parent: Instance, onClick: () -> (), size: number?, glyph: string?): TextButton
	local s = size or L.close
	local b = Instance.new("TextButton")
	b.Name = "Close"
	b.Text = ""
	b.AutoButtonColor = false
	b.Size = UDim2.fromOffset(s, s)
	b.Selectable = true
	Ui.corner(b, 6)
	Ui.fill(b, Theme.Buttons.red)
	Ui.stroke(b, 4)
	Ui.innerEdge(b, 0.6, 4)
	local x =
		Ui.text(b, glyph or "X", math.floor(s * 0.62), { align = Enum.TextXAlignment.Center, stroke = 4, name = "X" })
	x.Size = UDim2.fromScale(1, 1)
	x.ZIndex = 2
	Motion.interactive(b)
	b.Activated:Connect(onClick)
	b.Parent = parent
	return b
end

-- Non-interactive status block with a button's footprint (EQUIPPED / OWNED / LOCKED / MAXED).
function Ui.pill(
	parent: Instance,
	text: string,
	style: string,
	size: UDim2,
	textSize: number?,
	icon: string?
): (Frame, TextLabel)
	local f = Instance.new("Frame")
	f.Name = "Pill"
	f.Size = size
	f.BorderSizePixel = 0
	Ui.corner(f)
	Ui.fill(f, Theme.Buttons[style] or Theme.Buttons.dark)
	Ui.stroke(f, 4)
	Ui.studs(f, Theme.Studs.header, 20)
	local row = Ui.frame(f, "Content")
	local list = Ui.list(row, 10, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	if icon then
		local ts = textSize or 28
		local holder = Ui.frame(row, "Icon", UDim2.fromOffset(ts + 10, ts + 10))
		holder.LayoutOrder = 1
		Ui.art(holder, icon)
	end
	local t = Ui.text(
		row,
		text,
		textSize or 28,
		{ align = Enum.TextXAlignment.Center, autoX = true, name = "Label", stroke = 3 }
	)
	t.LayoutOrder = 2
	f.Parent = parent
	return f, t
end

-- Tabs: equal-width bars across the row; active = section colour, idle = dark studs.
export type Tabs = { gui: Frame, select: (index: number) -> (), selected: () -> number }

function Ui.tabs(
	parent: Instance,
	names: { string },
	icons: { string? },
	active: Pair,
	onSelect: (index: number) -> ()
): Tabs
	local bar = Ui.frame(parent, "Tabs", UDim2.new(1, 0, 0, 58))
	local buttons: { TextButton } = {}
	local current = 0
	local n = #names
	local function choose(i: number)
		current = i
		for j, b in buttons do
			Ui.fill(b, if j == i then active else { C.tabIdle, C.tabIdle })
		end
		onSelect(i)
	end
	for i, name in names do
		local b = Instance.new("TextButton")
		b.Name = "Tab" .. i
		b.Text = ""
		b.AutoButtonColor = false
		b.Selectable = true
		b.Size = UDim2.new(1 / n, -math.floor(14 * (n - 1) / n), 1, 0)
		b.Position = UDim2.new((i - 1) / n, math.floor(14 * (i - 1) / n), 0, 0)
		Ui.corner(b)
		Ui.stroke(b, 4)
		Ui.studs(b, Theme.Studs.header, 20)
		local row = Ui.frame(b, "Content")
		row.ZIndex = 2
		local list = Ui.list(row, 14, true, Enum.HorizontalAlignment.Center)
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		local icon = icons[i]
		if icon then
			local holder = Ui.frame(row, "Icon", UDim2.fromOffset(46, 46))
			holder.LayoutOrder = 1
			Ui.art(holder, icon).ZIndex = 2
		end
		local label = Ui.text(row, string.upper(name), 32, { autoX = true, stroke = 3, name = "Label" })
		label.LayoutOrder = 2
		label.ZIndex = 2
		Motion.interactive(b)
		b.Activated:Connect(function()
			if current ~= i then
				choose(i)
			end
		end)
		b.Parent = bar
		table.insert(buttons, b)
	end
	return {
		gui = bar,
		select = choose,
		selected = function()
			return current
		end,
	}
end

-- Progress bar: dark track, gradient fill with a top highlight, centred outlined value.
export type Progress = { gui: Frame, set: (fraction: number, text: string?) -> () }

function Ui.progress(parent: Instance, fill: Pair, height: number?, textSize: number?): Progress
	local h = height or 34
	local track = Instance.new("Frame")
	track.Name = "Progress"
	track.Size = UDim2.new(1, 0, 0, h)
	track.BackgroundColor3 = C.card
	track.BorderSizePixel = 0
	Ui.corner(track, 6)
	Ui.stroke(track, 3)
	local bar = Instance.new("Frame")
	bar.Name = "Fill"
	bar.BorderSizePixel = 0
	bar.Size = UDim2.fromScale(0, 1)
	Ui.corner(bar, 6)
	Ui.fill(bar, fill)
	bar.Parent = track
	local hi = Instance.new("Frame")
	hi.Name = "Highlight"
	hi.BackgroundColor3 = Color3.new(1, 1, 1)
	hi.BackgroundTransparency = 0.75
	hi.BorderSizePixel = 0
	hi.Size = UDim2.new(1, -6, 0.35, 0)
	hi.Position = UDim2.fromOffset(3, 2)
	Ui.corner(hi, 4)
	hi.Parent = bar
	local label =
		Ui.text(track, "", textSize or math.max(L.minText, h - 10), { align = Enum.TextXAlignment.Center, stroke = 3 })
	label.Size = UDim2.fromScale(1, 1)
	label.ZIndex = 3
	track.Parent = parent
	return {
		gui = track,
		set = function(fraction: number, text: string?)
			local f = math.clamp(fraction, 0, 1)
			bar.Visible = f > 0
			if Motion.reduced() then
				bar.Size = UDim2.fromScale(f, 1)
			else
				Motion.tween(bar, 0.25, { Size = UDim2.fromScale(f, 1) })
			end
			label.Text = text or ""
		end,
	}
end

-- Count badge for HUD buttons (only shown when it means something).
function Ui.badge(parent: Instance): (Frame, TextLabel)
	local f = Instance.new("Frame")
	f.Name = "Badge"
	f.AnchorPoint = Vector2.new(1, 0)
	f.Position = UDim2.new(1, 10, 0, -10)
	f.AutomaticSize = Enum.AutomaticSize.X
	f.Size = UDim2.fromOffset(38, 38)
	f.ZIndex = 6
	Ui.corner(f, 19)
	Ui.fill(f, Theme.Buttons.red)
	Ui.stroke(f, 3, Color3.new(1, 1, 1))
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 9), UDim.new(0, 9)
	p.Parent = f
	local t = Ui.text(f, "", 22, { autoX = true, align = Enum.TextXAlignment.Center })
	t.Size = UDim2.fromOffset(0, 38)
	t.ZIndex = 7
	f.Visible = false
	f.Parent = parent
	return f, t
end

-- Scrolling ------------------------------------------------------------------------------------------------

-- Vertical-only scroll surface; canvas grows with content (no per-frame canvas updates).
function Ui.scroll(parent: Instance, name: string?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Name = name or "Scroll"
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Size = UDim2.fromScale(1, 1)
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.ScrollBarThickness = 12
	s.ScrollBarImageColor3 = Color3.fromHex("8A4DFF")
	s.ScrollBarImageTransparency = 0
	s.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	s.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	s.Selectable = false
	s.Parent = parent
	return s
end

export type Grid = {
	layout: UIGridLayout,
	shape: (minCell: number, ratio: number, maxCols: number) -> (),
	columns: () -> number,
}

-- Grid whose column count follows the container's width. `ratio` = cell height / width. Re-lays out only
-- when the width or shape changes.
function Ui.grid(parent: GuiObject, minCell: number, ratio: number, gap: number?, maxCols: number?): Grid
	local g = Instance.new("UIGridLayout")
	local spacing = gap or L.gap
	g.CellPadding = UDim2.fromOffset(spacing, spacing)
	g.SortOrder = Enum.SortOrder.LayoutOrder
	g.HorizontalAlignment = Enum.HorizontalAlignment.Left
	local shape = { min = minCell, ratio = ratio, cap = maxCols or 6 }
	local lastKey = ""
	local cols = 1
	local function fit()
		local width = if parent:IsA("ScrollingFrame") then parent.AbsoluteWindowSize.X else parent.AbsoluteSize.X
		local w = width / Ui.screenScale(parent)
		local pad = parent:FindFirstChildOfClass("UIPadding")
		if pad then
			w -= pad.PaddingLeft.Offset + pad.PaddingRight.Offset
		end
		local key = `{math.floor(w)}/{shape.min}/{shape.ratio}/{shape.cap}`
		if w <= 0 or key == lastKey then
			return
		end
		lastKey = key
		cols = math.clamp(math.floor((w + spacing) / (shape.min + spacing)), 1, shape.cap)
		local cell = math.floor((w - spacing * (cols - 1)) / cols)
		g.CellSize = UDim2.fromOffset(cell, math.floor(cell * shape.ratio))
	end
	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	g.Parent = parent
	task.defer(fit)
	return {
		layout = g,
		shape = function(m: number, r: number, c: number)
			shape.min, shape.ratio, shape.cap = m, r, c
			fit()
		end,
		columns = function()
			return cols
		end,
	}
end

-- Product of every UIScale above `gui` (AbsoluteSize is post-scale; layouts work in design pixels).
function Ui.screenScale(gui: Instance): number
	local s = 1
	local node: Instance? = gui
	while node and not node:IsA("LayerCollector") do
		local scale = node:FindFirstChildOfClass("UIScale")
		if scale then
			s *= scale.Scale
		end
		node = node.Parent
	end
	return s
end

-- Lazy 3D previews for pets and eggs (no supplied PNGs for them) ------------------------------------------

type Lazy = { holder: GuiObject, build: () -> () }
local lazy: { Lazy } = {}
local lazyAcc = 0

RunService.Heartbeat:Connect(function(dt)
	lazyAcc += dt
	if lazyAcc < 0.15 or #lazy == 0 then
		return
	end
	lazyAcc = 0
	local built = 0
	for i = #lazy, 1, -1 do
		local entry = lazy[i]
		if not entry.holder.Parent then
			table.remove(lazy, i)
		elseif built < 6 and Motion.onScreen(entry.holder) and Motion.inView(entry.holder) then
			table.remove(lazy, i)
			built += 1 -- a few per tick so opening a big list never hitches
			entry.build()
		end
	end
end)

local function viewport(holder: GuiObject, model: Model, yaw: number, pitch: number, zoom: number, silhouette: boolean)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Model"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(200, 200, 210)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.8)
	vp.ZIndex = holder.ZIndex
	if silhouette then
		vp.ImageColor3 = Color3.fromRGB(14, 10, 30)
		vp.ImageTransparency = 0.15
	end
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local cf, size = model:GetBoundingBox()
	local radius = size.Magnitude / 2
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = radius / math.tan(math.rad(15)) * zoom
	local dir = (CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(-pitch), 0, 0)).LookVector
	cam.CFrame = CFrame.lookAt(cf.Position - dir * dist, cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = holder
end

local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Pet preview (3D). `silhouette` = undiscovered (dark shape; the caller hides the name).
function Ui.petArt(holder: GuiObject, modelKey: string, silhouette: boolean?)
	table.insert(lazy, {
		holder = holder,
		build = function()
			local Models = require(Shared.Builders.Models) :: any
			local ok, model = pcall(Models.pet, modelKey)
			if ok and model then
				viewport(holder, model, 200, 12, 0.92, silhouette == true)
			end
		end,
	})
end

function Ui.eggArt(holder: GuiObject, modelKey: string)
	table.insert(lazy, {
		holder = holder,
		build = function()
			local Models = require(Shared.Builders.Models) :: any
			local ok, model = pcall(Models.egg, modelKey)
			if ok and model then
				viewport(holder, model, 200, 10, 0.95, false)
			end
		end,
	})
end

-- Numbers --------------------------------------------------------------------------------------------------

local Kit = require(script.Parent.Parent.Kit)
function Ui.money(n: number): string
	return "$" .. Kit.formatNumber(n)
end
function Ui.number(n: number): string
	if n < 1000 and n % 1 ~= 0 then
		return string.format("%.1f", n)
	end
	return Kit.formatNumber(n)
end

return Ui
