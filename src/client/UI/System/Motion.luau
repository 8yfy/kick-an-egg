--!strict
-- Shared UI motion (UI handoff 03-Specs/MOTION-SPEC.md). One place owns every UI tween so that:
--   * a new tween on the same instance+property cancels the old one (rapid open/close settles on the latest),
--   * looping effects (header shine, floating art, CTA pulses) live in registries driven by ONE Heartbeat
--     connection and only run while their GuiObject is actually on screen,
--   * reward bursts reuse a small pool of ImageLabels (<= 24 desktop / 10 phone alive at once),
--   * Reduced Motion (Settings toggle -> LocalPlayer attribute "ReducedMotion", default from Roblox's own
--     GuiService.ReducedMotionEnabled) drops overshoot, rotation, loops and bursts and uses short fades.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local AssetIds = require(script.Parent.AssetIds)
local Theme = require(script.Parent.Theme)

local M = Theme.Motion
local Motion = {}

local me: Player? = Players.LocalPlayer

-- Reduced Motion -----------------------------------------------------------------------------------------

local function systemReduced(): boolean
	local ok, value = pcall(function()
		return (GuiService :: any).ReducedMotionEnabled
	end)
	return ok and value == true
end

function Motion.reduced(): boolean
	local attr = if me then me:GetAttribute("ReducedMotion") else nil
	if typeof(attr) == "boolean" then
		return attr
	end
	return systemReduced()
end

-- Tweens with per-property cancellation ------------------------------------------------------------------

local running: { [Instance]: { [string]: Tween } } = setmetatable({}, { __mode = "k" }) :: any

function Motion.tween(
	obj: Instance,
	seconds: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
): Tween
	local slots = running[obj]
	if not slots then
		slots = {}
		running[obj] = slots
	end
	for prop in props do
		local old = slots[prop]
		if old then
			old:Cancel()
		end
	end
	local t = TweenService:Create(
		obj,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	for prop in props do
		slots[prop] = t
	end
	t.Completed:Once(function()
		for prop in props do
			if slots[prop] == t then
				slots[prop] = nil
			end
		end
	end)
	t:Play()
	return t
end

-- Cancels every running tween on `obj` (used when a screen is torn down mid-animation).
function Motion.stop(obj: Instance)
	local slots = running[obj]
	if slots then
		for _, t in slots do
			t:Cancel()
		end
		running[obj] = nil
	end
end

-- The UIScale this module animates on `gui` (created once).
function Motion.scaleOf(gui: GuiObject): UIScale
	local s = gui:FindFirstChild("MotionScale")
	if s and s:IsA("UIScale") then
		return s
	end
	local ns = Instance.new("UIScale")
	ns.Name = "MotionScale"
	ns.Parent = gui
	return ns
end

-- Visibility ---------------------------------------------------------------------------------------------

-- True when `gui` and every GuiObject/LayerCollector above it is visible and enabled.
function Motion.onScreen(gui: GuiObject): boolean
	local node: Instance? = gui
	while node do
		if node:IsA("GuiObject") then
			if not node.Visible or (node:IsA("CanvasGroup") and node.GroupTransparency >= 0.99) then
				return false
			end
		elseif node:IsA("LayerCollector") then
			return node.Enabled and node:IsDescendantOf(game)
		end
		node = node.Parent
	end
	return false
end

-- Inside the visible rect of its nearest ScrollingFrame (cheap intersection, no relayout).
function Motion.inView(gui: GuiObject): boolean
	local scroller = gui:FindFirstAncestorWhichIsA("ScrollingFrame")
	if not scroller then
		return true
	end
	local a, as = gui.AbsolutePosition, gui.AbsoluteSize
	local b, bs = scroller.AbsolutePosition, scroller.AbsoluteSize
	return a.Y + as.Y >= b.Y and a.Y <= b.Y + bs.Y and a.X + as.X >= b.X and a.X <= b.X + bs.X
end

-- Buttons: hover / focus / press ---------------------------------------------------------------------------

-- Hover/focus 1 -> 1.035 (100 ms), press -> 0.96 (70 ms), release back (120 ms). `enabled` lets disabled
-- buttons stay still. Gamepad selection counts as hover so focus is visible.
function Motion.interactive(button: GuiButton, enabled: (() -> boolean)?)
	local scale = Motion.scaleOf(button)
	local hovering, pressing = false, false
	local function rest(): number
		if pressing then
			return M.pressScale
		end
		return if hovering and (not enabled or enabled()) then M.hoverScale else 1
	end
	local function settle(seconds: number)
		if Motion.reduced() then
			scale.Scale = 1
			return
		end
		Motion.tween(scale, seconds, { Scale = rest() })
	end
	button.MouseEnter:Connect(function()
		if not UserInputService.TouchEnabled then
			hovering = true
			settle(M.hover)
		end
	end)
	button.MouseLeave:Connect(function()
		hovering, pressing = false, false
		settle(M.hover)
	end)
	button.SelectionGained:Connect(function()
		hovering = true
		settle(M.hover)
	end)
	button.SelectionLost:Connect(function()
		hovering = false
		settle(M.hover)
	end)
	button.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if
			(
				t == Enum.UserInputType.MouseButton1
				or t == Enum.UserInputType.Touch
				or input.KeyCode == Enum.KeyCode.ButtonA
			) and (not enabled or enabled())
		then
			pressing = true
			settle(M.press)
		end
	end)
	button.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if
			t == Enum.UserInputType.MouseButton1
			or t == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			pressing = false
			if t == Enum.UserInputType.Touch then
				hovering = false
			end
			settle(M.release)
		end
	end)
end

-- One-shot feedback ----------------------------------------------------------------------------------------

-- Checkmark / selection pop: 0.6 -> 1.08 -> 1 over 160 ms.
function Motion.popIn(gui: GuiObject)
	local scale = Motion.scaleOf(gui)
	if Motion.reduced() then
		scale.Scale = 1
		return
	end
	scale.Scale = 0.6
	local up = Motion.tween(scale, 0.1, { Scale = 1.08 })
	up.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			Motion.tween(scale, 0.06, { Scale = 1 })
		end
	end)
end

-- Error: border emphasis for 150 ms then back (never a shake).
function Motion.flagError(stroke: UIStroke, rest: Color3)
	stroke.Color = Color3.fromHex("FF5444")
	Motion.tween(stroke, 0.15, { Thickness = Theme.Layout.stroke + 2 }).Completed:Once(function()
		Motion.tween(stroke, 0.4, { Thickness = Theme.Layout.stroke, Color = rest })
	end)
end

-- Short value interpolation that always ends on the exact server value (counters).
function Motion.count(value: NumberValue, target: number)
	if Motion.reduced() or math.abs(value.Value - target) < 1 then
		Motion.stop(value)
		value.Value = target
		return
	end
	Motion.tween(value, M.counter, { Value = target })
end

-- Staggered reveal: each item rises +12 px -> 0 behind a fading veil (the veil has the body colour, so
-- the card looks like it fades in without a CanvasGroup per card). 25 ms stagger, whole wave <= 300 ms.
function Motion.reveal(items: { GuiObject }, veilColor: Color3)
	local reduced = Motion.reduced()
	for i, item in items do
		local delay = math.min((i - 1) * M.revealStagger, M.revealCap - M.reveal)
		local veil = Instance.new("Frame")
		veil.Name = "RevealVeil"
		veil.BackgroundColor3 = veilColor
		veil.BorderSizePixel = 0
		veil.Size = UDim2.new(1, 12, 1, 12)
		veil.Position = UDim2.fromOffset(-6, -6)
		veil.ZIndex = 50
		veil.Parent = item
		local content = item:FindFirstChild("Content")
		local shift = if content and content:IsA("GuiObject") and not reduced then content else nil
		local home = if shift then shift.Position else UDim2.new()
		if shift then
			shift.Position = home + UDim2.fromOffset(0, 12)
		end
		task.delay(if reduced then 0 else delay, function()
			local seconds = if reduced then M.reduced else M.reveal
			Motion.tween(veil, seconds, { BackgroundTransparency = 1 }).Completed:Once(function()
				veil:Destroy()
			end)
			if shift then
				Motion.tween(shift, seconds, { Position = home })
			end
		end)
	end
end

-- Looping registries (one Heartbeat) -----------------------------------------------------------------------

type Shine = { holder: GuiObject, streak: Frame, nextAt: number, running: boolean }
type Float = { gui: GuiObject, home: UDim2, phase: number, glow: GuiObject? }
type Pulse = { gui: GuiObject, scale: UIScale, phase: number, period: number, amount: number }

local shines: { Shine } = {}
local floats: { Float } = {}
local pulses: { Pulse } = {}

-- A clipped diagonal white streak that sweeps across `holder` (650 ms) once every 5-8 s while it is on
-- screen. `holder` must clip (ClipsDescendants) -- headers and banners do.
function Motion.shine(holder: GuiObject): () -> ()
	local streak = Instance.new("Frame")
	streak.Name = "Shine"
	streak.BackgroundColor3 = Color3.new(1, 1, 1)
	streak.BackgroundTransparency = 0.72
	streak.BorderSizePixel = 0
	streak.AnchorPoint = Vector2.new(0.5, 0.5)
	streak.Size = UDim2.new(0, 46, 3, 0)
	streak.Rotation = 22
	streak.Position = UDim2.new(-0.2, 0, 0.5, 0)
	streak.Visible = false
	streak.ZIndex = 8
	local shineImage = if AssetIds.hasHandoff("fx/shine") then AssetIds.get("fx/shine") else nil
	if shineImage then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = shineImage
		img.Parent = streak
		streak.BackgroundTransparency = 1
	else
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = streak
	end
	streak.Parent = holder
	local entry: Shine =
		{ holder = holder, streak = streak, nextAt = os.clock() + 1 + math.random() * 4, running = false }
	table.insert(shines, entry)
	return function()
		local i = table.find(shines, entry)
		if i then
			table.remove(shines, i)
		end
		streak:Destroy()
	end
end

-- Featured art: gentle Y +-4 px and rotation +-1.5 deg on a 3.2 s sine, only while visible. `glow` (optional)
-- pulses its ImageTransparency a little in step.
function Motion.float(gui: GuiObject, glow: GuiObject?): () -> ()
	local entry: Float = { gui = gui, home = gui.Position, phase = math.random() * math.pi * 2, glow = glow }
	table.insert(floats, entry)
	return function()
		local i = table.find(floats, entry)
		if i then
			table.remove(floats, i)
		end
		gui.Position = entry.home
		gui.Rotation = 0
	end
end

-- Looping scale pulse for one focal CTA (ready egg, claimable reward). Returns a stop function.
function Motion.pulse(gui: GuiObject, amount: number?, period: number?): () -> ()
	local entry: Pulse = {
		gui = gui,
		scale = Motion.scaleOf(gui),
		phase = os.clock(),
		period = period or 1.2,
		amount = amount or 0.05,
	}
	table.insert(pulses, entry)
	return function()
		local i = table.find(pulses, entry)
		if i then
			table.remove(pulses, i)
		end
		entry.scale.Scale = 1
	end
end

local function sweep(entry: Shine)
	entry.running = true
	local streak = entry.streak
	streak.Visible = true
	streak.Position = UDim2.new(-0.2, 0, 0.5, 0)
	Motion.tween(streak, M.shine, { Position = UDim2.new(1.2, 0, 0.5, 0) }, Enum.EasingStyle.Sine).Completed
		:Once(function()
			streak.Visible = false
			entry.running = false
		end)
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	local reduced = Motion.reduced()
	for _, s in shines do
		if not s.running and now >= s.nextAt then
			s.nextAt = now + 5 + math.random() * 3
			if not reduced and Motion.onScreen(s.holder) and Motion.inView(s.holder) then
				sweep(s)
			end
		end
	end
	for _, f in floats do
		if reduced or not Motion.onScreen(f.gui) or not Motion.inView(f.gui) then
			if f.gui.Rotation ~= 0 then
				f.gui.Position = f.home
				f.gui.Rotation = 0
			end
			continue
		end
		local a = (now / M.float) * math.pi * 2 + f.phase
		f.gui.Position = f.home + UDim2.fromOffset(0, math.sin(a) * 4)
		f.gui.Rotation = math.sin(a * 0.5) * 1.5
		local glow = f.glow
		if glow and glow:IsA("ImageLabel") then
			glow.ImageTransparency = 0.35 + math.sin(a) * 0.12
		end
	end
	for _, p in pulses do
		if reduced or not Motion.onScreen(p.gui) then
			p.scale.Scale = 1
			continue
		end
		local t = ((now - p.phase) % p.period) / p.period
		p.scale.Scale = 1 + math.sin(t * math.pi) * p.amount
	end
end)

-- Pooled 2D bursts -----------------------------------------------------------------------------------------

local pool: { ImageLabel } = {}
local alive = 0

local function budget(): number
	return if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then 10 else 24
end

local function take(): ImageLabel
	local img = table.remove(pool)
	if img then
		return img
	end
	local n = Instance.new("ImageLabel")
	n.Name = "Spark"
	n.BackgroundTransparency = 1
	n.AnchorPoint = Vector2.new(0.5, 0.5)
	n.ZIndex = 60
	return n
end

local function give(img: ImageLabel)
	img.Parent = nil
	alive -= 1
	table.insert(pool, img)
end

-- 8-12 sparkles (or cash icons) that rise 30-70 px and fade over 500-700 ms from `at` (absolute screen
-- position) inside `layer` (a full-screen transient layer). Skipped under Reduced Motion.
function Motion.burst(layer: GuiObject, at: Vector2, kind: "sparkle" | "cash", count: number?)
	if Motion.reduced() then
		return
	end
	local image = AssetIds.get(if kind == "cash" then "icon/cash" else "fx/sparkle")
	if not image then
		return
	end
	local origin = at - layer.AbsolutePosition
	for _ = 1, count or math.random(8, 12) do
		if alive >= budget() then
			break
		end
		alive += 1
		local img = take()
		local size = if kind == "cash" then math.random(22, 30) else math.random(18, 30)
		img.Image = image
		img.ImageTransparency = 0
		img.Size = UDim2.fromOffset(size, size)
		img.Rotation = math.random(-20, 20)
		local x = origin.X + math.random(-36, 36)
		img.Position = UDim2.fromOffset(x, origin.Y + math.random(-8, 8))
		img.Parent = layer
		local seconds = 0.5 + math.random() * 0.2
		Motion.tween(img, seconds, {
			Position = UDim2.fromOffset(x + math.random(-14, 14), origin.Y - math.random(30, 70)),
			ImageTransparency = 1,
		}).Completed
			:Once(function()
				give(img)
			end)
	end
end

-- Rebirth success: an expanding ring + 12-18 sparks (<= 900 ms, no full-screen flash).
function Motion.ring(layer: GuiObject, at: Vector2, color: Color3)
	if Motion.reduced() then
		return
	end
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	local origin = at - layer.AbsolutePosition
	ring.Position = UDim2.fromOffset(origin.X, origin.Y)
	ring.Size = UDim2.fromOffset(40, 40)
	ring.ZIndex = 60
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 8
	stroke.Color = color
	stroke.Parent = ring
	ring.Parent = layer
	Motion.tween(ring, 0.8, { Size = UDim2.fromOffset(420, 420) }, Enum.EasingStyle.Quart)
	Motion.tween(stroke, 0.8, { Transparency = 1, Thickness = 2 }).Completed:Once(function()
		ring:Destroy()
	end)
	Motion.burst(layer, at, "sparkle", math.random(12, 18))
end

return Motion
