--!strict
-- Shared modal window: dimmed backdrop, rounded gradient panel with a tilted title tag, a bouncy
-- close button, and a pop-in/out. Only one window is open at a time.
local Kit = require(script.Parent.Parent.Kit)

export type Window = {
	frame: Frame, -- the panel
	body: Frame, -- content area (below the title)
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	onOpen: (() -> ()) -> (),
}

local Window = {}

local current: Window? = nil

function Window.new(parent: Instance, title: string, colors: { Color3 }): Window
	local backdrop = Instance.new("TextButton")
	backdrop.Name = title .. "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.45
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Visible = false
	backdrop.ZIndex = 20
	backdrop.Parent = parent

	local panel = Kit.panel({
		name = title .. "Window",
		size = UDim2.fromOffset(900, 600),
		position = UDim2.fromScale(0.5, 0.55),
		anchor = Vector2.new(0.5, 0.5),
		parent = backdrop,
		colors = Kit.Colors.dark,
		radius = 26,
	})
	panel.ZIndex = 21
	Kit.autoScale(panel)
	local inner = Instance.new("Frame") -- pop animates this so the screen scale stays on `panel`
	inner.Name = "Inner"
	inner.Size = UDim2.fromScale(1, 1)
	inner.BackgroundTransparency = 1
	inner.Parent = panel

	local tag = Kit.panel({
		name = "Title",
		size = UDim2.fromOffset(300, 70),
		position = UDim2.new(0, 30, 0, -34),
		parent = inner,
		colors = colors,
		radius = 18,
	})
	tag.Rotation = -3
	Kit.label({
		name = "Text",
		text = string.upper(title),
		size = UDim2.fromScale(0.86, 0.7),
		position = UDim2.fromScale(0.07, 0.15),
		parent = tag,
		stroke = 4,
	})

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(28, 56)
	body.Size = UDim2.new(1, -56, 1, -84)
	body.Parent = inner

	local openCallbacks: { () -> () } = {}
	local self: Window
	local function close()
		if not backdrop.Visible then
			return
		end
		local s = inner:FindFirstChildOfClass("UIScale")
		if s then
			Kit.tween(s, 0.18, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		end
		task.delay(0.18, function()
			backdrop.Visible = false
		end)
		if current == self then
			current = nil
		end
	end
	local function open()
		if current and current ~= self then
			current.close()
		end
		current = self
		backdrop.Visible = true
		Kit.pop(inner, 0.35)
		for _, cb in openCallbacks do
			task.spawn(cb)
		end
	end
	Kit.button({
		name = "Close",
		text = "X",
		size = UDim2.fromOffset(72, 72),
		position = UDim2.new(1, 18, 0, -26),
		anchor = Vector2.new(1, 0),
		parent = inner,
		colors = Kit.Colors.red,
		radius = 20,
		onClick = close,
	})
	backdrop.Activated:Connect(close)
	panel.Active = true -- clicks on the panel don't fall through to the backdrop

	self = {
		frame = panel,
		body = body,
		open = open,
		close = close,
		isOpen = function()
			return backdrop.Visible
		end,
		onOpen = function(cb: () -> ())
			table.insert(openCallbacks, cb)
		end,
	}
	return self
end

function Window.closeAll()
	if current then
		current.close()
	end
end

return Window
