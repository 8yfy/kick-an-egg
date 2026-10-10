--!strict
-- Native Roblox building blocks for the Kick The Egg UI system (Figma "Kick The Egg — UI System" components):
-- text, stud panels, gradient buttons with states, tabs, progress bars, rarity chips, scroll lists with
-- responsive grids, icons with controlled fallbacks and lazy 3D art (sacks / pets / eggs in ViewportFrames,
-- built only when first scrolled into view). Fixed TextSize (never below Theme.Layout.minText) instead of
-- TextScaled so text stays readable and wraps intentionally.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AssetIds = require(script.Parent.AssetIds)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)

local C, L = Theme.Colors, Theme.Layout
local Ui = {}

export type Gradient = "lime" | "cyan" | "violet" | "purple" | "orange" | "gold" | "red" | "grey" | "disabled"

-- Basics ---------------------------------------------------------------------------------------------------

function Ui.corner(gui: GuiObject, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or L.radius)
	c.Parent = gui
end

function Ui.stroke(gui: GuiObject, thickness: number?, color: Color3?): UIStroke
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or L.stroke
	s.Color = color or C.stroke
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = gui
	return s
end

function Ui.padding(gui: GuiObject, px: number, top: number?)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, px), UDim.new(0, px)
	p.PaddingTop, p.PaddingBottom = UDim.new(0, top or px), UDim.new(0, top or px)
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

function Ui.gradient(gui: GuiObject, key: Gradient): UIGradient
	local pair = Theme.Gradients[key]
	local g = gui:FindFirstChild("Fill")
	if not (g and g:IsA("UIGradient")) then
		local ng = Instance.new("UIGradient")
		ng.Name = "Fill"
		ng.Rotation = 90
		ng.Parent = gui
		g = ng
	end
	local grad = g :: UIGradient
	grad.Color = ColorSequence.new(pair[1], pair[2])
	gui.BackgroundColor3 = Color3.new(1, 1, 1)
	gui.BackgroundTransparency = 0
	return grad
end

-- Quiet tiled studs behind a surface (alpha ~0.1; Theme.Studs). Not animated.
function Ui.studs(gui: GuiObject, transparency: number?): ImageLabel?
	local image = AssetIds.get("texture/studs")
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
	img.TileSize = UDim2.fromOffset(Theme.Studs.tile, Theme.Studs.tile)
	img.ZIndex = 0
	local corner = gui:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = img
	end
	img.Parent = gui
	return img
end

-- Faint light inner edge (the bevelled look of the mockups).
function Ui.innerEdge(gui: GuiObject, transparency: number?)
	local rim = Instance.new("Frame")
	rim.Name = "InnerEdge"
	rim.BackgroundTransparency = 1
	rim.Size = UDim2.new(1, -6, 1, -6)
	rim.Position = UDim2.fromOffset(3, 3)
	rim.ZIndex = 0
	Ui.corner(rim, math.max(2, L.radius - 3))
	Ui.stroke(rim, 2, C.innerEdge).Transparency = transparency or 0.55
	rim.Parent = gui
end

export type TextOpts = {
	color: Color3?,
	align: Enum.TextXAlignment?,
	wrap: boolean?,
	stroke: number?,
	name: string?,
	autoX: boolean?,
}

-- Fredoka text with a dark outline. Height = size + 8; `wrap` grows it vertically instead, `autoX` grows width.
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
	s.Thickness = o.stroke or math.max(2, math.floor(l.TextSize / 12))
	s.Color = C.stroke
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	l.Parent = parent
	return l
end

-- Charcoal stud panel (card / section background).
function Ui.panel(parent: Instance, name: string, color: Color3?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color or C.panel
	f.BorderSizePixel = 0
	Ui.corner(f)
	Ui.stroke(f)
	Ui.studs(f)
	f.Parent = parent
	return f
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

-- An image from AssetIds, or a stroked glyph when no id exists (controlled placeholder, never a broken image).
function Ui.icon(parent: Instance, key: string, size: number, glyph: string?): GuiObject
	local image = AssetIds.get(key)
	if image then
		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(size, size)
		img.Image = image
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = parent
		return img
	end
	if not glyph then
		local empty = Ui.frame(parent, "Icon", UDim2.fromOffset(size, size))
		return empty
	end
	local t = Ui.text(parent, glyph, math.floor(size * 0.8), { align = Enum.TextXAlignment.Center, name = "Icon" })
	t.Size = UDim2.fromOffset(size, size)
	return t
end

-- Buttons --------------------------------------------------------------------------------------------------

export type Button = {
	gui: TextButton,
	label: TextLabel,
	setText: (text: string) -> (),
	setGradient: (key: Gradient) -> (),
	setEnabled: (on: boolean) -> (),
	setPending: (on: boolean, text: string?) -> (),
	enabled: () -> boolean,
}

export type ButtonOpts = {
	text: string,
	gradient: Gradient,
	size: UDim2,
	textSize: number?,
	icon: string?, -- AssetIds key drawn left of the label
	name: string?,
	onClick: () -> (),
}

-- Gradient action button: label always visible, 48 px minimum target, hover/press/focus motion, disabled and
-- pending states (pending ignores clicks until the caller clears it, so requests can't double-submit).
function Ui.button(parent: Instance, o: ButtonOpts): Button
	local b = Instance.new("TextButton")
	b.Name = o.name or o.text
	b.Text = ""
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Size = o.size
	b.Selectable = true
	Ui.corner(b)
	Ui.gradient(b, o.gradient)
	local stroke = Ui.stroke(b)
	Ui.studs(b, Theme.Studs.header)
	Ui.innerEdge(b, 0.5)
	local row = Ui.frame(b, "Content")
	local list = Ui.list(row, 8, true, Enum.HorizontalAlignment.Center)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	if o.icon then
		local icon = Ui.icon(row, o.icon, (o.textSize or 24) + 10)
		icon.LayoutOrder = 1
	end
	local label =
		Ui.text(row, o.text, o.textSize or 24, { align = Enum.TextXAlignment.Center, autoX = true, name = "Label" })
	label.LayoutOrder = 2
	local current: Gradient = o.gradient
	local isEnabled, isPending = true, false
	local idleText = o.text
	local function paint()
		Ui.gradient(b, if isEnabled and not isPending then current else "disabled")
		stroke.Color = C.stroke
		label.TextTransparency = if isEnabled or isPending then 0 else 0.25
	end
	Motion.interactive(b, function()
		return isEnabled and not isPending
	end)
	b.Activated:Connect(function()
		if isEnabled and not isPending then
			o.onClick()
		end
	end)
	b.Parent = parent
	local self: Button
	self = {
		gui = b,
		label = label,
		setText = function(text: string)
			idleText = text
			if not isPending then
				label.Text = text
			end
		end,
		setGradient = function(key: Gradient)
			current = key
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
		enabled = function()
			return isEnabled and not isPending
		end,
	}
	return self
end

-- Non-interactive status pill (EQUIPPED / OWNED / LOCKED / MAXED): same footprint as a button, no motion.
function Ui.pill(parent: Instance, text: string, key: Gradient, size: UDim2, textSize: number?): (Frame, TextLabel)
	local f = Instance.new("Frame")
	f.Name = "Pill"
	f.Size = size
	f.BorderSizePixel = 0
	Ui.corner(f)
	Ui.gradient(f, key)
	Ui.stroke(f)
	Ui.innerEdge(f, 0.5)
	local t = Ui.text(f, text, textSize or 24, { align = Enum.TextXAlignment.Center, name = "Label" })
	t.Size = UDim2.fromScale(1, 1)
	f.Parent = parent
	return f, t
end

-- Round red close button (close/remove only, per the style rules).
function Ui.closeButton(parent: Instance, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Close"
	b.Text = ""
	b.AutoButtonColor = false
	b.Size = UDim2.fromOffset(64, 64)
	b.Selectable = true
	Ui.corner(b, 14)
	Ui.gradient(b, "red")
	Ui.stroke(b)
	Ui.innerEdge(b, 0.5)
	local icon = Ui.icon(b, "icon/close", 40, "X")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	Motion.interactive(b)
	b.Activated:Connect(onClick)
	b.Parent = parent
	return b
end

-- Tabs -----------------------------------------------------------------------------------------------------

export type Tabs = { gui: Frame, select: (index: number) -> (), selected: () -> number }

function Ui.tabs(parent: Instance, names: { string }, onSelect: (index: number) -> ()): Tabs
	local bar = Ui.frame(parent, "Tabs", UDim2.new(1, 0, 0, 56))
	Ui.list(bar, 12, true)
	local buttons: { Button } = {}
	local current = 0
	local function choose(i: number)
		current = i
		for j, btn in buttons do
			btn.setGradient(if j == i then "cyan" else "grey")
			btn.label.TextTransparency = if j == i then 0 else 0.15
		end
		onSelect(i)
	end
	for i, name in names do
		local btn = Ui.button(bar, {
			text = name,
			gradient = "grey",
			size = UDim2.fromOffset(220, 56),
			textSize = 24,
			name = "Tab" .. i,
			onClick = function()
				if current ~= i then
					choose(i)
				end
			end,
		})
		btn.gui.LayoutOrder = i
		table.insert(buttons, btn)
	end
	return {
		gui = bar,
		select = choose,
		selected = function()
			return current
		end,
	}
end

-- Progress bar ---------------------------------------------------------------------------------------------

export type Progress = { gui: Frame, set: (fraction: number, text: string?) -> () }

function Ui.progress(parent: Instance, key: Gradient, height: number?): Progress
	local h = height or 30
	local track = Instance.new("Frame")
	track.Name = "Progress"
	track.Size = UDim2.new(1, 0, 0, h)
	track.BackgroundColor3 = C.panelDeep
	track.BorderSizePixel = 0
	Ui.corner(track, h // 2)
	Ui.stroke(track, 3)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	Ui.corner(fill, h // 2)
	Ui.gradient(fill, key)
	fill.Parent = track
	local label = Ui.text(track, "", math.max(16, h - 12), { align = Enum.TextXAlignment.Center })
	label.Size = UDim2.fromScale(1, 1)
	label.ZIndex = 3
	track.Parent = parent
	return {
		gui = track,
		set = function(fraction: number, text: string?)
			local f = math.clamp(fraction, 0, 1)
			fill.Visible = f > 0
			if Motion.reduced() then
				fill.Size = UDim2.fromScale(f, 1)
			else
				Motion.tween(fill, 0.25, { Size = UDim2.fromScale(f, 1) })
			end
			label.Text = text or ""
		end,
	}
end

-- Rarity chip (rarity palette only).
function Ui.chip(parent: Instance, rarity: string): Frame
	local color = (Theme.Rarity :: any)[rarity] or Theme.Rarity.Common
	local f = Instance.new("Frame")
	f.Name = "Rarity"
	f.AutomaticSize = Enum.AutomaticSize.X
	f.Size = UDim2.fromOffset(0, 28)
	f.BackgroundColor3 = color
	Ui.corner(f, 14)
	Ui.stroke(f, 3)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	p.Parent = f
	local t = Ui.text(f, rarity, 16, { autoX = true, align = Enum.TextXAlignment.Center })
	t.Size = UDim2.fromOffset(0, 28)
	if rarity == "Secret" then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("FF5A5A")),
			ColorSequenceKeypoint.new(0.33, Color3.fromHex("FFE15A")),
			ColorSequenceKeypoint.new(0.66, Color3.fromHex("5AE1FF")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("C35AFF")),
		})
		g.Parent = f
	end
	f.Parent = parent
	return f
end

-- Small count badge for HUD buttons (shown only when it means something).
function Ui.badge(parent: Instance): (Frame, TextLabel)
	local f = Instance.new("Frame")
	f.Name = "Badge"
	f.AnchorPoint = Vector2.new(1, 0)
	f.Position = UDim2.new(1, 8, 0, -8)
	f.AutomaticSize = Enum.AutomaticSize.X
	f.Size = UDim2.fromOffset(34, 34)
	f.ZIndex = 6
	Ui.corner(f, 17)
	Ui.gradient(f, "red")
	Ui.stroke(f, 3)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	p.Parent = f
	local t = Ui.text(f, "", 18, { autoX = true, align = Enum.TextXAlignment.Center })
	t.Size = UDim2.fromOffset(0, 34)
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
	s.ScrollBarThickness = 10
	s.ScrollBarImageColor3 = C.innerEdge
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

-- Grid whose column count follows the container's width (3 desktop / 2 tablet / 1-2 phone; screens change
-- the shape on short screens). `ratio` = cell height / width. Re-lays out only when width or shape change.
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

-- Lazy 3D art ----------------------------------------------------------------------------------------------

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
	vp.Name = "Art"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(190, 190, 200)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.8)
	if silhouette then
		vp.ImageColor3 = Color3.fromRGB(12, 14, 20)
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

-- Sack art: the uploaded handoff PNG for that tier if it exists, else a 3D render of the in-game sack.
function Ui.sackArt(holder: GuiObject, tier: number)
	local key = "sack/" .. tier
	if AssetIds.hasHandoff(key) then
		local img = Instance.new("ImageLabel")
		img.Name = "Art"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.ScaleType = Enum.ScaleType.Fit
		img.Image = AssetIds.get(key) :: string
		img.Parent = holder
		return
	end
	table.insert(lazy, {
		holder = holder,
		build = function()
			local Builder = require(Shared.Builders.BlockBuilder) :: any
			local Sacks = require((Shared :: any).Builders.Models.Sacks) :: any
			local ok, model = pcall(Builder.build, Sacks.spec(tier), "Sack")
			if ok and model then
				viewport(holder, model, 200, 8, 1.0, false)
			end
		end,
	})
end

-- Pet art (3D). `silhouette` = undiscovered (black shape, name hidden by the caller).
function Ui.petArt(holder: GuiObject, modelKey: string, silhouette: boolean?)
	table.insert(lazy, {
		holder = holder,
		build = function()
			local Models = require(Shared.Builders.Models) :: any
			local ok, model = pcall(Models.pet, modelKey)
			if ok and model then
				viewport(holder, model, 200, 12, 1.05, silhouette == true)
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
				viewport(holder, model, 200, 10, 1.0, false)
			end
		end,
	})
end

-- Soft glow + rays behind featured art (pooled images from AssetIds; nothing if not uploaded).
function Ui.glow(holder: GuiObject, color: Color3, rays: boolean?): ImageLabel?
	local image = AssetIds.get("fx/glow")
	if rays then
		local r = AssetIds.get("fx/rays")
		if r then
			local img = Instance.new("ImageLabel")
			img.Name = "Rays"
			img.BackgroundTransparency = 1
			img.AnchorPoint = Vector2.new(0.5, 0.5)
			img.Position = UDim2.fromScale(0.5, 0.5)
			img.Size = UDim2.fromScale(1.25, 1.25)
			img.Image = r
			img.ImageColor3 = color
			img.ImageTransparency = 0.7
			img.ZIndex = 0
			img.Parent = holder
		end
	end
	if not image then
		return nil
	end
	local img = Instance.new("ImageLabel")
	img.Name = "Glow"
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.fromScale(1.1, 1.1)
	img.Image = image
	img.ImageColor3 = color
	img.ImageTransparency = 0.35
	img.ZIndex = 0
	img.Parent = holder
	return img
end

-- "$1.2K" / "1.5M" (A's Kit formatter, one rule everywhere).
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
