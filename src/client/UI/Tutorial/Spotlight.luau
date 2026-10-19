--!strict
-- Darken the surroundings of the REAL control, leaving a clickable hole and red bouncing pointer.
-- Rectangles are remeasured every frame, including scrolling, UIScale and differing ScreenGui safe areas.
local GuiService = game:GetService("GuiService")
local Style = require(script.Parent.Style)
local Motion = require(script.Parent.Parent.System.Motion)
local Spotlight = {}

local function origin(gui: ScreenGui): Vector2
	return GuiService:GetInsetArea(gui.ScreenInsets).Min
end

function Spotlight.rect(target: GuiObject, gui: ScreenGui): Rect?
	local owner = target:FindFirstAncestorWhichIsA("ScreenGui")
	if not owner or not owner.Enabled or not target:IsDescendantOf(game.Players.LocalPlayer.PlayerGui) then
		return nil
	end
	local offset = origin(owner) - origin(gui)
	local a, b = target.AbsolutePosition + offset, target.AbsolutePosition + offset + target.AbsoluteSize
	local parent: Instance? = target
	while parent and parent ~= owner do
		if parent:IsA("GuiObject") then
			if not parent.Visible then
				return nil
			end
			if parent ~= target and parent.ClipsDescendants then
				local p = parent.AbsolutePosition + offset
				a = Vector2.new(math.max(a.X, p.X), math.max(a.Y, p.Y))
				b = Vector2.new(math.min(b.X, p.X + parent.AbsoluteSize.X), math.min(b.Y, p.Y + parent.AbsoluteSize.Y))
			end
		end
		parent = parent.Parent
	end
	local size = gui.AbsoluteSize
	-- Round the shared edges once. Independently truncating UDim2 offsets leaves bright 1px seams.
	a = Vector2.new(math.floor(math.max(0, a.X - 8)), math.floor(math.max(0, a.Y - 8)))
	b = Vector2.new(math.ceil(math.min(size.X, b.X + 8)), math.ceil(math.min(size.Y, b.Y + 8)))
	return if b.X - a.X >= 4 and b.Y - a.Y >= 4 then Rect.new(a, b) else nil
end

function Spotlight.new(gui: ScreenGui)
	local layer = Instance.new("Frame")
	layer.Name = "Spotlight"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.Active = false
	layer.Visible = false
	layer.Parent = gui
	local masks: { Frame } = {}
	for _, name in { "Top", "Bottom", "Left", "Right" } do
		local mask = Instance.new("Frame")
		mask.Name, mask.BorderSizePixel = name, 0
		mask.BackgroundColor3, mask.BackgroundTransparency = Color3.new(0, 0, 0), 1
		mask.Active, mask.ZIndex, mask.Parent = false, 10, layer
		table.insert(masks, mask)
	end
	local focus = Instance.new("Frame")
	focus.Name = "Focus"
	focus.BackgroundTransparency = 1
	focus.Active = false
	focus.ZIndex = 12
	focus.Parent = layer
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = focus
	local stroke = Instance.new("UIStroke")
	stroke.Color = Style.RED
	stroke.Thickness = 3
	stroke.Parent = focus
	local arrow = Style.arrow(layer, "Pointer", 13)
	Style.preload()
	local target: GuiObject? = nil
	local api = {}
	function api:set(nextTarget: GuiObject?)
		if nextTarget ~= target and nextTarget then
			Motion.popIn(arrow)
			if not target then
				for _, mask in masks do
					mask.BackgroundTransparency = 1
					Motion.tween(mask, 0.2, { BackgroundTransparency = 0.48 })
				end
			end
		end
		target = nextTarget
	end
	function api:update(t: number)
		local rect = target and Spotlight.rect(target, gui)
		layer.Visible = rect ~= nil
		if not rect then
			return
		end
		local a, b, size = rect.Min, rect.Max, gui.AbsoluteSize
		local function put(frame: Frame, x: number, y: number, w: number, h: number)
			frame.Position, frame.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(math.max(0, w), math.max(0, h))
		end
		put(focus, a.X, a.Y, b.X - a.X, b.Y - a.Y)
		put(masks[1], 0, 0, size.X, a.Y)
		put(masks[2], 0, b.Y, size.X, size.Y - b.Y)
		put(masks[3], 0, a.Y, a.X, b.Y - a.Y)
		put(masks[4], b.X, a.Y, size.X - b.X, b.Y - a.Y)
		local reduced = Motion.reduced()
		local bounce = if reduced then 0 else (1 - math.cos(t * math.pi * 2 / 1.25)) * 4
		local center = (a + b) / 2
		-- Prefer above the egg/control; fall back only when that would leave the safe viewport.
		if a.Y >= 78 then
			arrow.Rotation, arrow.Position =
				90, UDim2.fromOffset(math.clamp(center.X, 38, size.X - 38), a.Y - 38 - bounce)
		elseif size.Y - b.Y >= 78 then
			arrow.Rotation, arrow.Position =
				270, UDim2.fromOffset(math.clamp(center.X, 38, size.X - 38), b.Y + 38 + bounce)
		elseif a.X >= 78 then
			arrow.Rotation, arrow.Position = 0, UDim2.fromOffset(a.X - 38 - bounce, center.Y)
		else
			arrow.Rotation, arrow.Position = 180, UDim2.fromOffset(b.X + 38 + bounce, center.Y)
		end
		stroke.Thickness = if reduced then 3 else 3.25 + math.sin(t * 4) * 0.45
	end
	function api:destroy()
		Motion.stop(Motion.scaleOf(arrow))
		for _, mask in masks do
			Motion.stop(mask)
		end
		layer:Destroy()
	end
	return api
end

return Spotlight
