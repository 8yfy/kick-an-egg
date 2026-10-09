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
			Kit.tween(scale, 0.15, { Scale = 1.05 })
		end
	end)
	button.MouseLeave:Connect(function()
		Kit.tween(scale, 0.2, { Scale = 1 })
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

-- Looping scale pulse for "NEW"/"FREE" badges. Returns a stop function.
function Kit.pulse(gui: GuiObject, amount: number?): () -> ()
	local scale = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = gui
	local info = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local t = TweenService:Create(scale, info, { Scale = amount or 1.12 })
	t:Play()
	return function()
		t:Cancel()
		scale.Scale = 1
	end
end

-- Pop-in: scale 0 -> 1 with Back easing.
function Kit.pop(gui: GuiObject, seconds: number?)
	local scale = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = gui
	scale.Scale = 0
	Kit.tween(scale, seconds or 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Reference-resolution scaling: every registered UIScale follows the viewport.
local scales: { UIScale } = {}
local current = 1

local function computeScale(): number
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	local s = math.min(vp.X / 1920, vp.Y / 1080)
	if UserInputService.TouchEnabled then
		s *= 1.35 -- phones: bigger touch targets
	end
	return math.clamp(s, 0.45, 1.5)
end

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
	end
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
