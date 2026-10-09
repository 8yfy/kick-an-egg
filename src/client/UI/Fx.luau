--!strict
-- UI juice: shine sweeps, icon wiggles, spinning sunburst rays, twinkling sparkles, background blur,
-- floating "+$" text, confetti, screen flash and big pop-up callouts. One RenderStepped loop drives every
-- continuous effect; objects drop out of the loop automatically when they are destroyed.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Icons = require(script.Parent.Icons)

local Fx = {}

type Wiggle = { amp: number, speed: number, phase: number }
type Twinkle = { speed: number, phase: number, size: number }
local wiggles: { [GuiObject]: Wiggle } = {}
local spinners: { [GuiObject]: number } = {}
local twinkles: { [GuiObject]: Twinkle } = {}
local rng = Random.new()

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	for obj, w in wiggles do
		if obj.Parent then
			obj.Rotation = math.sin(t * w.speed + w.phase) * w.amp
		else
			wiggles[obj] = nil
		end
	end
	for obj, speed in spinners do
		if obj.Parent then
			obj.Rotation = (obj.Rotation + speed * dt) % 360
		else
			spinners[obj] = nil
		end
	end
	for obj, tw in twinkles do
		if obj.Parent then
			local k = math.max(0, math.sin(t * tw.speed + tw.phase))
			obj.Size = UDim2.fromOffset(tw.size * k, tw.size * k)
			obj.Rotation = t * 90 % 360
		else
			twinkles[obj] = nil
		end
	end
end)

local function tween(
	obj: Instance,
	seconds: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
): Tween
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

function Fx.screen(): ScreenGui?
	local pg = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local g = pg and pg:FindFirstChild("HUD")
	return if g and g:IsA("ScreenGui") then g else nil
end

-- Gentle rocking (icons, badges).
function Fx.wiggle(obj: GuiObject, amp: number?, speed: number?)
	wiggles[obj] = { amp = amp or 4, speed = speed or 2.2, phase = rng:NextNumber(0, 6) }
end

function Fx.spin(obj: GuiObject, degPerSecond: number)
	spinners[obj] = degPerSecond
end

-- Diagonal white shine that sweeps across `obj` every `every` seconds (first after `delay`).
function Fx.shine(obj: GuiObject, every: number?, delay: number?): Frame
	local f = Instance.new("Frame")
	f.Name = "Shine"
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	f.ZIndex = 0
	local corner = obj:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = f
	end
	local g = Instance.new("UIGradient")
	g.Rotation = 25
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Offset = Vector2.new(-1, 0)
	g.Parent = f
	f.Parent = obj
	task.spawn(function()
		task.wait(delay or 0)
		while f.Parent do
			g.Offset = Vector2.new(-1, 0)
			tween(g, 0.7, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine)
			task.wait(every or 3.5)
		end
	end)
	return f
end

-- Spinning sunburst behind featured content.
function Fx.rays(parent: Instance, size: number, color: Color3?, speed: number?): ImageLabel
	local r = Icons.view(parent, "Rays", UDim2.fromOffset(size, size))
	r.Name = "Rays"
	r.AnchorPoint = Vector2.new(0.5, 0.5)
	r.Position = UDim2.fromScale(0.5, 0.5)
	r.ImageColor3 = color or Color3.fromRGB(255, 245, 190)
	r.ImageTransparency = 0.25
	r.ZIndex = 0
	Fx.spin(r, speed or 25)
	return r
end

-- Twinkling sparkles scattered over `obj`.
function Fx.sparkles(obj: GuiObject, count: number, size: number?)
	for _ = 1, count do
		local s = Icons.view(obj, "Spark", UDim2.fromOffset(0, 0))
		s.Name = "Sparkle"
		s.AnchorPoint = Vector2.new(0.5, 0.5)
		s.Position = UDim2.fromScale(rng:NextNumber(0.05, 0.95), rng:NextNumber(0.05, 0.95))
		s.ZIndex = 4
		twinkles[s] =
			{ speed = rng:NextNumber(1.5, 3), phase = rng:NextNumber(0, 6), size = size or rng:NextNumber(14, 24) }
	end
end

-- Blur the world behind open windows.
function Fx.blur(on: boolean)
	local b = Lighting:FindFirstChild("UIBlur")
	if not (b and b:IsA("BlurEffect")) then
		local nb = Instance.new("BlurEffect")
		nb.Name = "UIBlur"
		nb.Size = 0
		nb.Parent = Lighting
		b = nb
	end
	tween(b :: BlurEffect, 0.25, { Size = if on then 14 else 0 })
end

local function stroked(text: string, size: Vector2, color: Color3, strokeWidth: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromOffset(size.X, size.Y)
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	local s = Instance.new("UIStroke")
	s.Thickness = strokeWidth
	s.Color = Color3.fromRGB(25, 20, 30)
	s.Parent = l
	return l
end

-- "+$1.2K" that floats up from a GUI element and fades.
function Fx.floatText(from: GuiObject, text: string, color: Color3)
	local gui = Fx.screen()
	if not gui then
		return
	end
	local l = stroked(text, Vector2.new(220, 48), color, 3)
	local p = from.AbsolutePosition + from.AbsoluteSize / 2 + Vector2.new(rng:NextNumber(-30, 30), -10)
	l.Position = UDim2.fromOffset(p.X, p.Y)
	l.Rotation = rng:NextNumber(-8, 8)
	l.ZIndex = 50
	l.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.4
	scale.Parent = l
	tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(l, 1.1, { Position = UDim2.fromOffset(p.X, p.Y - 90), TextTransparency = 1 })
	tween(l:FindFirstChildOfClass("UIStroke") :: UIStroke, 1.1, { Transparency = 1 })
	task.delay(1.15, function()
		l:Destroy()
	end)
end

-- Confetti from a screen point (absolute pixels).
function Fx.confetti(at: Vector2, count: number?)
	local gui = Fx.screen()
	if not gui then
		return
	end
	local colors = {
		Color3.fromRGB(255, 90, 120),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(90, 220, 110),
		Color3.fromRGB(80, 190, 255),
		Color3.fromRGB(190, 120, 255),
	}
	local bits = {}
	for _ = 1, count or 28 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.Size = UDim2.fromOffset(rng:NextInteger(8, 14), rng:NextInteger(12, 20))
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BackgroundColor3 = colors[rng:NextInteger(1, #colors)]
		f.ZIndex = 60
		f.Parent = gui
		local a = rng:NextNumber(-math.pi * 0.9, -math.pi * 0.1)
		local sp = rng:NextNumber(260, 620)
		table.insert(
			bits,
			{ f = f, pos = at, vel = Vector2.new(math.cos(a) * sp, math.sin(a) * sp), spin = rng:NextNumber(-540, 540) }
		)
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local k = (os.clock() - t0) / 1.4
		for _, b in bits do
			b.vel += Vector2.new(0, 1100 * dt)
			b.vel *= 0.985
			b.pos += b.vel * dt
			b.f.Position = UDim2.fromOffset(b.pos.X, b.pos.Y)
			b.f.Rotation += b.spin * dt
			b.f.BackgroundTransparency = math.clamp((k - 0.6) / 0.4, 0, 1)
		end
		if k >= 1 then
			conn:Disconnect()
			for _, b in bits do
				b.f:Destroy()
			end
		end
	end)
end

function Fx.flash(color: Color3?, strength: number?)
	local gui = Fx.screen()
	if not gui then
		return
	end
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color or Color3.new(1, 1, 1)
	f.BackgroundTransparency = 1 - (strength or 0.45)
	f.ZIndex = 70
	f.Parent = gui
	tween(f, 0.35, { BackgroundTransparency = 1 })
	task.delay(0.4, function()
		f:Destroy()
	end)
end

-- Big centre callout with spinning rays ("PERFECT!", "REBIRTH!").
function Fx.callout(text: string, top: Color3, bottom: Color3)
	local gui = Fx.screen()
	if not gui then
		return
	end
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.42)
	holder.Size = UDim2.fromOffset(520, 140)
	holder.ZIndex = 65
	holder.Parent = gui
	local rays = Fx.rays(holder, 420, top, 60)
	rays.ImageTransparency = 0.35
	local l = stroked(text, Vector2.new(520, 120), Color3.new(1, 1, 1), 6)
	l.Position = UDim2.fromScale(0.5, 0.5)
	l.ZIndex = 66
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(top, bottom)
	g.Parent = l
	l.Parent = holder
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = holder
	tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(0.9, function()
		tween(scale, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.3)
		holder:Destroy()
	end)
end

return Fx
