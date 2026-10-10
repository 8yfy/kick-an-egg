--!strict
-- Partner A UI kit: Fredoka text, thick black strokes, vertical gradients, bouncy buttons,
-- pulsing badges, reference-resolution scaling (designed at 1920x1080) and number formatting.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Kit = {}

Kit.FONT = Enum.Font.FredokaOne
Kit.STROKE = 3 -- px at 1080p
local rgb = Color3.fromRGB
Kit.Colors = {
	ink = rgb(25, 20, 30),
	white = rgb(255, 255, 255),
	green = { rgb(120, 235, 100), rgb(40, 170, 60) },
	red = { rgb(255, 110, 80), rgb(215, 35, 45) },
	yellow = { rgb(255, 230, 90), rgb(245, 165, 30) },
	blue = { rgb(110, 200, 255), rgb(40, 110, 230) },
	purple = { rgb(200, 140, 255), rgb(120, 60, 220) },
	grey = { rgb(200, 200, 210), rgb(120, 120, 135) },
	dark = { rgb(70, 65, 90), rgb(35, 30, 50) },
}

function Kit.tween(
	obj: Instance,
	seconds: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
): Tween
	local t = TweenService:Create(
		obj,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

function Kit.stroke(parent: GuiObject, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or Kit.STROKE
	s.Color = Kit.Colors.ink
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.ApplyStrokeMode = if parent:IsA("TextLabel") or parent:IsA("TextButton")
		then Enum.ApplyStrokeMode.Contextual
		else Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- Border stroke for a text button (Contextual would outline the text instead of the frame).
function Kit.borderStroke(parent: GuiObject, thickness: number?): UIStroke
	local s = Kit.stroke(parent, thickness)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

function Kit.corner(parent: GuiObject, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 14)
	c.Parent = parent
end

-- Vertical gradient, light on top. `pair` = { top, bottom }.
function Kit.gradient(parent: GuiObject, pair: { Color3 }): UIGradient
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(pair[1], pair[2])
	g.Parent = parent
	parent.BackgroundColor3 = Color3.new(1, 1, 1)
	return g
end

export type FrameProps = {
	name: string,
	size: UDim2,
	position: UDim2?,
	anchor: Vector2?,
	parent: Instance,
	colors: { Color3 }?,
	radius: number?,
	stroke: boolean?,
}

-- Rounded, stroked, gradient panel. Transparent if no colors.
function Kit.panel(p: FrameProps): Frame
	local f = Instance.new("Frame")
	f.Name = p.name
	f.Size = p.size
	f.Position = p.position or UDim2.new()
	f.AnchorPoint = p.anchor or Vector2.zero
	f.BorderSizePixel = 0
	if p.colors then
		Kit.gradient(f, p.colors)
		Kit.corner(f, p.radius)
		if p.stroke ~= false then
			Kit.stroke(f)
		end
	else
		f.BackgroundTransparency = 1
	end
	f.Parent = p.parent
	return f
end

export type TextProps = {
	name: string,
	text: string,
	size: UDim2,
	position: UDim2?,
	anchor: Vector2?,
	parent: Instance,
	color: Color3?,
	align: Enum.TextXAlignment?,
	stroke: number?,
}

function Kit.label(p: TextProps): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = p.name
	l.Text = p.text
	l.Size = p.size
	l.Position = p.position or UDim2.new()
	l.AnchorPoint = p.anchor or Vector2.zero
	l.BackgroundTransparency = 1
	l.Font = Kit.FONT
	l.TextScaled = true
	l.TextColor3 = p.color or Kit.Colors.white
	l.TextXAlignment = p.align or Enum.TextXAlignment.Center
	Kit.stroke(l, p.stroke)
	l.Parent = p.parent
	return l
end

-- Faint tiled stud pattern behind a panel/button's content (Figma asset, assets/ui-icons/StudPattern.png).
Kit.STUDS = "rbxassetid://137675892333527"
function Kit.studs(parent: GuiObject, tile: number?): ImageLabel
	local img = Instance.new("ImageLabel")
	img.Name = "Studs"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = Kit.STUDS
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(tile or 28, tile or 28)
	img.ZIndex = 0 -- behind the parent's other children
	local c = parent:FindFirstChildOfClass("UICorner")
	if c then
		c:Clone().Parent = img
	end
	img.Parent = parent
	return img
end

-- Text with a vertical gradient fill and a thick dark outline (big stat numbers, banners).
function Kit.gradientText(label: TextLabel, top: Color3, bottom: Color3): UIGradient
	label.TextColor3 = Color3.new(1, 1, 1)
	local g = label:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(top, bottom)
	g.Parent = label
	return g
end

-- Fixed-size stroked text that grows to fit its width (stat lines, quest titles). Optional gradient.
function Kit.text(parent: Instance, name: string, text: string, size: number, stroke: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Text = text
	l.BackgroundTransparency = 1
	l.Font = Kit.FONT
	l.TextSize = size
	l.TextColor3 = Kit.Colors.white
	l.AutomaticSize = Enum.AutomaticSize.X
	l.Size = UDim2.fromOffset(0, size + 6)
	local st = Instance.new("UIStroke")
	st.Thickness = stroke or math.max(2, size // 14)
	st.Color = Color3.new(0, 0, 0)
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = l
	l.Parent = parent
	return l
end

-- Squash on press (0.9) and spring back with Back easing on release.
function Kit.bouncy(button: GuiButton): UIScale
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	button.InputBegan:Connect(function(input)
		if isPress(input) and button.Active then
			Kit.tween(scale, 0.08, { Scale = 0.9 })
		end
	end)
	button.InputEnded:Connect(function(input)
		if isPress(input) then
			Kit.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end)
	button.MouseEnter:Connect(function()
		if button.Active and not UserInputService.TouchEnabled then
			Kit.tween(scale, 0.15, { Scale = 1.06 })
			Kit.tween(button, 0.15, { Rotation = -2.5 }, Enum.EasingStyle.Back)
		end
	end)
	button.MouseLeave:Connect(function()
		Kit.tween(scale, 0.2, { Scale = 1 })
		Kit.tween(button, 0.2, { Rotation = 0 })
	end)
	return scale
end

export type ButtonProps = {
	name: string,
	text: string,
	size: UDim2,
	position: UDim2?,
	anchor: Vector2?,
	parent: Instance,
	colors: { Color3 },
	radius: number?,
	onClick: () -> (),
}

function Kit.button(p: ButtonProps): (TextButton, UIGradient)
	local b = Instance.new("TextButton")
	b.Name = p.name
	b.Size = p.size
	b.Position = p.position or UDim2.new()
	b.AnchorPoint = p.anchor or Vector2.zero
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Text = ""
	local g = Kit.gradient(b, p.colors)
	Kit.corner(b, p.radius or 18)
	Kit.borderStroke(b)
	Kit.studs(b)
	Kit.label({
		name = "Label",
		text = p.text,
		size = UDim2.fromScale(0.86, 0.7),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		parent = b,
	})
	Kit.bouncy(b)
	b.Activated:Connect(function()
		if b.Active then
			p.onClick()
		end
	end)
	b.Parent = p.parent
	return b, g
end

-- Round dark button (settings, sound); fills its parent. Callers add the icon.
function Kit.roundButton(parent: Instance, name: string, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = ""
	b.AutoButtonColor = false
	b.Size = UDim2.fromScale(1, 1)
	b.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	b.BackgroundTransparency = 0.2
	b.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent = b
	Kit.borderStroke(b, 3)
	Kit.bouncy(b)
	b.Activated:Connect(onClick)
	b.Parent = parent
	return b
end

-- Reference-resolution scaling: every registered UIScale follows the viewport.
local scales: { UIScale } = {}
local current = 1

-- The UIScale to animate on `gui` and its resting value (the screen scale if it is auto-scaled).
local function scaleOf(gui: GuiObject): (UIScale, number)
	local scale = gui:FindFirstChildOfClass("UIScale")
	if scale then
		return scale, if table.find(scales, scale) then current else 1
	end
	local s = Instance.new("UIScale")
	s.Parent = gui
	return s, 1
end

-- Looping scale pulse for "NEW"/"FREE" badges. Returns a stop function.
function Kit.pulse(gui: GuiObject, amount: number?): () -> ()
	local scale, rest = scaleOf(gui)
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local t = TweenService:Create(scale, info, { Scale = rest * (amount or 1.12) })
	t:Play()
	return function()
		t:Cancel()
		scale.Scale = rest
	end
end

-- Pop-in: scale 0 -> rest with Back easing.
function Kit.pop(gui: GuiObject, seconds: number?)
	local scale, rest = scaleOf(gui)
	scale.Scale = 0
	Kit.tween(scale, seconds or 0.35, { Scale = rest }, Enum.EasingStyle.Back)
end

-- Studio preview: pretend the screen is `size` (e.g. a phone) so the HUD can be screenshotted at that size.
local preview: { size: Vector2, touch: boolean }? = nil
function Kit.setPreview(size: Vector2?, touch: boolean?)
	preview = if size then { size = size, touch = touch == true } else nil
end

local function viewport(): (Vector2, boolean)
	if preview then
		return preview.size, preview.touch
	end
	local cam = workspace.CurrentCamera
	return if cam then cam.ViewportSize else Vector2.new(1920, 1080), UserInputService.TouchEnabled
end

local function computeScale(): number
	local vp, touch = viewport()
	local s = math.min(vp.X / 1920, vp.Y / 1080)
	if touch then
		s *= 1.35 -- phones: bigger touch targets
	end
	return math.clamp(s, 0.45, 1.5)
end

-- Compact = phone landscape (short screen): HUD pieces move out of the thumbstick / jump corners.
local layouts: { (compact: boolean) -> () } = {}
function Kit.compact(): boolean
	local vp = viewport()
	return vp.Y < 600
end

-- Calls fn(compact) now and whenever the screen size changes.
function Kit.onLayout(fn: (compact: boolean) -> ())
	table.insert(layouts, fn)
	fn(Kit.compact())
end

-- Re-applies scale + layout (set by watchViewport; also used after Kit.setPreview).
function Kit.refreshLayout() end

function Kit.autoScale(gui: GuiObject): UIScale
	local s = Instance.new("UIScale")
	s.Scale = current
	s.Parent = gui
	table.insert(scales, s)
	return s
end

function Kit.watchViewport()
	local function refresh()
		current = computeScale()
		for _, s in scales do
			s.Scale = current
		end
		local compact = Kit.compact()
		for _, fn in layouts do
			fn(compact)
		end
	end
	Kit.refreshLayout = refresh
	refresh()
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
	end
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
function Kit.formatNumber(n: number): string
	n = math.floor(n)
	if math.abs(n) < 1000 then
		return tostring(n)
	end
	local i = 1
	local v = n
	while math.abs(v) >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	local digits = if math.abs(v) >= 100 then 0 elseif math.abs(v) >= 10 then 1 else 2
	local s = string.format(`%.{digits}f`, v)
	if digits > 0 then
		s = (s:gsub("0+$", ""):gsub("%.$", ""))
	end
	return s .. SUFFIXES[i]
end

return Kit
