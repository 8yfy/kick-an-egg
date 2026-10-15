--!strict
-- Shared modal window, shop style: dimmed backdrop, dark chunky panel, a coloured header bar with
-- diagonal stripes, the title on the left and a red square X on the right; pops in/out.
-- Only one window is open at a time.
local Kit = require(script.Parent.Parent.Kit)
local Fx = require(script.Parent.Parent.Fx)

export type Window = {
	frame: Frame, -- the panel
	body: Frame, -- content area (below the header)
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
	onOpen: (() -> ()) -> (),
}

local Window = {}

local current: Window? = nil
local HEADER = 76

function Window.new(parent: Instance, title: string, colors: { Color3 }, size: Vector2?): Window
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
		size = UDim2.fromOffset((size or Vector2.new(960, 640)).X, (size or Vector2.new(960, 640)).Y),
		position = UDim2.fromScale(0.5, 0.54),
		anchor = Vector2.new(0.5, 0.5),
		parent = backdrop,
	})
	panel.Active = true -- clicks on the panel don't fall through to the backdrop
	Kit.autoScale(panel)
	local inner = Kit.panel({
		name = "Inner",
		size = UDim2.fromScale(1, 1),
		parent = panel,
		colors = { Color3.fromRGB(58, 60, 78), Color3.fromRGB(36, 38, 52) },
		radius = 12,
	})
	Kit.studs(inner, 36).ImageTransparency = 0.5
	local outline = inner:FindFirstChildOfClass("UIStroke")
	if outline then
		outline.Thickness = 5
	end

	-- Header bar with stripes
	local header = Kit.panel({
		name = "Header",
		size = UDim2.new(1, 0, 0, HEADER),
		parent = inner,
		colors = colors,
		radius = 12,
	})
	header.ClipsDescendants = true
	Kit.studs(header)
	Fx.shine(header, 5, 0.4)
	for i = 0, 5 do
		local stripe = Instance.new("Frame")
		stripe.Name = "Stripe"
		stripe.BorderSizePixel = 0
		stripe.BackgroundColor3 = Color3.new(1, 1, 1)
		stripe.BackgroundTransparency = 0.82
		stripe.Size = UDim2.fromOffset(46, 220)
		stripe.AnchorPoint = Vector2.new(0.5, 0.5)
		stripe.Position = UDim2.new(0.45 + i * 0.09, 0, 0.5, 0)
		stripe.Rotation = 35
		stripe.Parent = header
	end
	Kit.label({
		name = "Title",
		text = title,
		size = UDim2.new(0.6, 0, 0, 58),
		position = UDim2.fromOffset(26, 9),
		parent = header,
		align = Enum.TextXAlignment.Left,
		stroke = 5,
	})

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(24, HEADER + 16)
	body.Size = UDim2.new(1, -48, 1, -(HEADER + 32))
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
		Fx.blur(false)
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
		Fx.blur(true)
		for _, cb in openCallbacks do
			task.spawn(cb)
		end
	end
	local closeButton = Kit.button({
		name = "Close",
		text = "X",
		size = UDim2.fromOffset(64, 64),
		position = UDim2.new(1, -12, 0, 6),
		anchor = Vector2.new(1, 0),
		parent = inner,
		colors = { Color3.fromRGB(240, 60, 60), Color3.fromRGB(180, 20, 30) },
		radius = 8,
		onClick = close,
	})
	closeButton.ZIndex = 3
	backdrop.Activated:Connect(close)

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

-- Section heading in the shop style: "-- FEATURED --"
function Window.heading(parent: Instance, text: string, order: number): TextLabel
	local l = Kit.label({
		name = "Heading",
		text = `-- {string.upper(text)} --`,
		size = UDim2.new(1, -20, 0, 46),
		parent = parent,
		color = Color3.fromRGB(255, 220, 60),
		stroke = 4,
	})
	l.LayoutOrder = order
	return l
end

return Window
