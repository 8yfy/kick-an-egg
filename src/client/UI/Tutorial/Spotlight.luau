--!strict
-- A red outline around the REAL control. No dark masks, cloned controls or input capture.
-- Rectangles are remeasured every frame, including scrolling, UIScale and differing ScreenGui safe areas.
local GuiService = game:GetService("GuiService")
local Style = require(script.Parent.Style)
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
	local target: GuiObject? = nil
	local api = {}
	function api:set(nextTarget: GuiObject?)
		target = nextTarget
	end
	function api:update(_t: number)
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
		local left = a.X > 80
		arrow.Rotation = if left then 0 else 180
		arrow.Position =
			UDim2.fromOffset(if left then a.X - 36 else b.X + 36, math.clamp((a.Y + b.Y) / 2, 36, size.Y - 36))
	end
	function api:destroy()
		layer:Destroy()
	end
	return api
end

return Spotlight
