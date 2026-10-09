--!strict
-- Store, shop style. Sections:
--   TRAINING RACK  wide card: current -> next rack tier (3D), gain per kick, price -> UpgradeTraining
--   UPGRADES       Kick Power / Run Speed (BuyUpgrade) and Pen slots (UpgradePen)
--   COMING SOON    placeholders for Partner B's gamepasses
-- Prices come from the documented formulas in Config (display only; the server charges).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Icons = require(script.Parent.Parent.Icons)
local MyBase = require(script.Parent.Parent.MyBase)
local Window = require(script.Parent.Window)
local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Economy = require(Config:WaitForChild("Economy"))
local Upgrades = require(Config:WaitForChild("Upgrades"))

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local StoreMenu = {}

local function fire(name: string, ...: any)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireServer(...)
	end
end

local function priceButton(parent: Instance, onClick: () -> ()): (TextButton, UIGradient, TextLabel)
	local b, g = Kit.button({
		name = "Buy",
		text = "",
		size = UDim2.fromOffset(220, 66),
		position = UDim2.new(0.5, 0, 1, -14),
		anchor = Vector2.new(0.5, 1),
		parent = parent,
		colors = Kit.Colors.green,
		radius = 10,
		onClick = onClick,
	})
	return b, g, b:FindFirstChild("Label") :: TextLabel
end

local function setPrice(button: TextButton, grad: UIGradient, label: TextLabel, cost: number?, money: number)
	if not cost then
		label.Text = "MAXED"
		button.Active = false
		grad.Color = ColorSequence.new(table.unpack(Kit.Colors.grey))
		return
	end
	label.Text = "$" .. Kit.formatNumber(cost)
	button.Active = true
	grad.Color = ColorSequence.new(table.unpack(if money >= cost then Kit.Colors.green else Kit.Colors.red))
end

function StoreMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Shop", Kit.Colors.green)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.ScrollBarThickness = 10
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = window.body
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 12)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	-- TRAINING RACK
	Window.heading(scroll, "Training Rack", 1)
	local rack = Kit.panel({
		name = "Rack",
		size = UDim2.new(1, -24, 0, 250),
		parent = scroll,
		colors = { Color3.fromRGB(110, 200, 255), Color3.fromRGB(60, 130, 230) },
		radius = 14,
	})
	rack.LayoutOrder = 2
	local nowView = Kit.panel({
		name = "Now",
		size = UDim2.fromOffset(200, 200),
		position = UDim2.fromOffset(18, 24),
		parent = rack,
	})
	local arrow = Kit.label({
		name = "Arrow",
		text = "➜",
		size = UDim2.fromOffset(70, 70),
		position = UDim2.fromOffset(224, 90),
		parent = rack,
		color = Color3.fromRGB(240, 60, 60),
		stroke = 4,
	})
	local nextView = Kit.panel({
		name = "Next",
		size = UDim2.fromOffset(200, 200),
		position = UDim2.fromOffset(300, 24),
		parent = rack,
	})
	local title = Kit.label({
		name = "Title",
		text = "UPGRADE TRAINING RACK!",
		size = UDim2.new(1, -540, 0, 52),
		position = UDim2.fromOffset(520, 20),
		parent = rack,
		stroke = 4,
	})
	local rainbow = Instance.new("UIGradient")
	local keys = {}
	for i = 0, 5 do
		table.insert(keys, ColorSequenceKeypoint.new(i / 5, Color3.fromHSV(i / 6, 0.55, 1)))
	end
	rainbow.Color = ColorSequence.new(keys)
	rainbow.Parent = title
	local rackInfo = Kit.label({
		name = "Info",
		text = "",
		size = UDim2.new(1, -540, 0, 64),
		position = UDim2.fromOffset(520, 78),
		parent = rack,
		stroke = 3,
	})
	local rackBuy = Kit.panel({
		name = "BuyHolder",
		size = UDim2.new(1, -540, 0, 90),
		position = UDim2.fromOffset(520, 146),
		parent = rack,
	})
	local rackButton, rackGrad, rackLabel = priceButton(rackBuy, function()
		fire("UpgradeTraining")
	end)

	-- UPGRADES
	Window.heading(scroll, "Upgrades", 3)
	local grid = Instance.new("Frame")
	grid.Name = "Upgrades"
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, -24, 0, 280)
	grid.LayoutOrder = 4
	grid.Parent = scroll
	local gl = Instance.new("UIGridLayout")
	gl.CellSize = UDim2.fromOffset(280, 270)
	gl.CellPadding = UDim2.fromOffset(14, 14)
	gl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = grid

	type Card = { level: TextLabel, button: TextButton, grad: UIGradient, label: TextLabel }
	local function card(order: number, name: string, icon: string, colors: { Color3 }, onClick: () -> ()): Card
		local c =
			Kit.panel({ name = name, size = UDim2.fromOffset(280, 270), parent = grid, colors = colors, radius = 14 })
		c.LayoutOrder = order
		Icons.view(c, icon, UDim2.fromOffset(96, 96)).Position = UDim2.new(0.5, -48, 0, 10)
		Kit.label({
			name = "Title",
			text = name,
			size = UDim2.new(1, -20, 0, 38),
			position = UDim2.fromOffset(10, 104),
			parent = c,
			stroke = 4,
		})
		local level = Kit.label({
			name = "Level",
			text = "",
			size = UDim2.new(1, -20, 0, 30),
			position = UDim2.fromOffset(10, 144),
			parent = c,
			stroke = 3,
		})
		local b, g, l = priceButton(c, onClick)
		return { level = level, button = b, grad = g, label = l }
	end
	local power = card(1, "Kick Power", "Bolt", Kit.Colors.red, function()
		fire("BuyUpgrade", "KickPower")
	end)
	local speed = card(2, "Run Speed", "Boot", Kit.Colors.blue, function()
		fire("BuyUpgrade", "RunSpeed")
	end)
	local pen = card(3, "Bigger Pen", "Egg", Kit.Colors.yellow, function()
		fire("UpgradePen")
	end)

	-- COMING SOON
	Window.heading(scroll, "Coming Soon", 5)
	local soon = Instance.new("Frame")
	soon.Name = "Soon"
	soon.BackgroundTransparency = 1
	soon.Size = UDim2.new(1, -24, 0, 150)
	soon.LayoutOrder = 6
	soon.Parent = scroll
	local sl = gl:Clone()
	sl.CellSize = UDim2.fromOffset(280, 140)
	sl.Parent = soon
	for i, s in { "2x Money", "VIP", "Lucky Kicks" } do
		local c = Kit.panel({
			name = s,
			size = UDim2.fromOffset(280, 140),
			parent = soon,
			colors = Kit.Colors.grey,
			radius = 14,
		})
		c.LayoutOrder = i
		Kit.label({
			name = "Title",
			text = s,
			size = UDim2.new(1, -20, 0, 44),
			position = UDim2.fromOffset(10, 18),
			parent = c,
			stroke = 4,
		})
		local badge = Kit.panel({
			name = "Soon",
			size = UDim2.fromOffset(120, 44),
			position = UDim2.new(0.5, 0, 1, -16),
			anchor = Vector2.new(0.5, 1),
			parent = c,
			colors = Kit.Colors.purple,
			radius = 10,
		})
		Kit.label({
			name = "Text",
			text = "SOON",
			size = UDim2.fromScale(0.8, 0.75),
			position = UDim2.fromScale(0.1, 0.12),
			parent = badge,
		})
		Kit.pulse(badge, 1.08)
	end

	local data: { [string]: any } = {}
	local shownTiers = { now = "", nxt = "" }
	local function refresh()
		local money = if typeof(data.money) == "number" then data.money else 0
		-- rack
		local levels = Upgrades.Rack.levels
		local lvl = math.clamp(MyBase.level("RackLevel", data, "rackLevel"), 1, #levels)
		local now, nxt = levels[lvl], levels[lvl + 1]
		if shownTiers.now ~= now.tier then
			shownTiers.now = now.tier
			nowView:ClearAllChildren()
			Icons.rack(nowView, now.tier)
		end
		local nextTier = if nxt then nxt.tier else now.tier
		if shownTiers.nxt ~= nextTier then
			shownTiers.nxt = nextTier
			nextView:ClearAllChildren()
			Icons.rack(nextView, nextTier)
		end
		arrow.Visible, nextView.Visible = nxt ~= nil, nxt ~= nil
		rackInfo.Text = if nxt
			then `Lv {lvl} → {lvl + 1}: +{now.gain} → +{nxt.gain} Kick Power per kick`
			else `Lv {lvl} (MAX): +{now.gain} Kick Power per kick`
		setPrice(rackButton, rackGrad, rackLabel, if nxt then nxt.cost else nil, money)
		-- stat upgrades
		for _, pair in { { power, "KickPower", "kickPower" }, { speed, "RunSpeed", "runSpeed" } } do
			local c = pair[1] :: Card
			local cfg = (Economy :: any)[pair[2]]
			local value = data[pair[3]]
			if typeof(value) == "number" and cfg then
				local maxed = value >= cfg.max
				c.level.Text = `{Kit.formatNumber(value)} / {Kit.formatNumber(cfg.max)}`
				setPrice(
					c.button,
					c.grad,
					c.label,
					if maxed then nil else math.floor(cfg.costBase * cfg.costGrowth ^ (value - cfg.base)),
					money
				)
			end
		end
		-- pen
		local plvl = math.max(1, MyBase.level("PenLevel", data, "penLevel"))
		local slots = math.min(Economy.PlotSlots.base + (plvl - 1) * Upgrades.Pen.slotsPerLevel, Economy.PlotSlots.max)
		local maxed = slots >= Economy.PlotSlots.max
		pen.level.Text = if maxed
			then `{slots} slots (MAX)`
			else `{slots} → {math.min(slots + Upgrades.Pen.slotsPerLevel, Economy.PlotSlots.max)} slots`
		setPrice(
			pen.button,
			pen.grad,
			pen.label,
			if maxed then nil else Upgrades.Pen.costBase * Upgrades.Pen.costGrowth ^ (plvl - 1),
			money
		)
	end
	window.onOpen(refresh)

	return {
		window = window,
		update = function(d: { [string]: any })
			data = d
			refresh()
		end,
	}
end

return StoreMenu
