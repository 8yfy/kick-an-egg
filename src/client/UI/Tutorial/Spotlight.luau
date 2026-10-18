--!strict
-- Four non-interactive masks leave a real hole around the REAL button. No cloned controls or input capture.
-- Rectangles are remeasured every frame, including scrolling, UIScale and differing ScreenGui safe areas.
local GuiService = game:GetService("GuiService")
local Assets = require(script.Parent.Assets)
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
	a = Vector2.new(math.max(0, a.X - 8), math.max(0, a.Y - 8))
	b = Vector2.new(math.min(size.X, b.X + 8), math.min(size.Y, b.Y + 8))
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
		mask.Name = name
		mask.BorderSizePixel = 0
		mask.BackgroundColor3 = Color3.new(0, 0, 0)
		mask.BackgroundTransparency = 0.62
		mask.Active = false
		mask.ZIndex = 10
		mask.Parent = layer
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
	stroke.Color = Color3.fromRGB(255, 216, 74)
	stroke.Thickness = 3
	stroke.Parent = focus
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Pointer"
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(64, 64)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Image = Assets.Pointer
	arrow.ZIndex = 13
	arrow.Active = false
	arrow.Parent = layer
	local target: GuiObject? = nil
	local api = {}
	function api:set(nextTarget: GuiObject?)
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
		put(masks[1], 0, 0, size.X, a.Y)
		put(masks[2], 0, b.Y, size.X, size.Y - b.Y)
		put(masks[3], 0, a.Y, a.X, b.Y - a.Y)
		put(masks[4], b.X, a.Y, size.X - b.X, b.Y - a.Y)
		put(focus, a.X, a.Y, b.X - a.X, b.Y - a.Y)
		local reduced = Motion.reduced()
		local left = a.X > 80
		local bob = if reduced then 0 else math.sin(t * 4) * 4
		arrow.Rotation = if left then 0 else 180
		arrow.Position = UDim2.fromOffset(
			if left then a.X - 42 + bob else b.X + 42 - bob,
			math.clamp((a.Y + b.Y) / 2, 36, size.Y - 36)
		)
		stroke.Thickness = if reduced then 3 else 3 + math.sin(t * 4) * 0.65
	end
	function api:destroy()
		layer:Destroy()
	end
	return api
end

return Spotlight
