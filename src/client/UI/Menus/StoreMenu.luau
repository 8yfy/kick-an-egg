--!strict
-- Store: Kick Power and Run Speed upgrades (fires BuyUpgrade; the server charges and validates)
-- plus placeholder cards for Partner B's gamepasses / dev products.
-- The shown price uses Economy's documented formula (costBase x costGrowth^level) for display only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Window = require(script.Parent.Window)
local Economy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Economy"))

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local StoreMenu = {}

type Upgrade = { kind: string, title: string, icon: string, key: string, colors: { Color3 } }
local UPGRADES: { Upgrade } = {
	{ kind = "KickPower", title = "Kick Power", icon = "⚡", key = "kickPower", colors = Kit.Colors.red },
	{ kind = "RunSpeed", title = "Run Speed", icon = "👟", key = "runSpeed", colors = Kit.Colors.blue },
}
local SOON = {
	{ title = "2x Money", icon = "💰" },
	{ title = "VIP", icon = "👑" },
	{ title = "Lucky Kicks", icon = "🍀" },
}

local function fire(name: string, ...: any)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireServer(...)
	end
end

function StoreMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Store", Kit.Colors.green)
	local body = window.body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(262, 230)
	grid.CellPadding = UDim2.fromOffset(16, 16)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = body

	type Row = { level: TextLabel, price: TextLabel, button: TextButton, gradient: UIGradient, up: Upgrade }
	local rows: { Row } = {}
	local money = 0
	for i, up in UPGRADES do
		local card = Kit.panel({
			name = up.kind,
			size = UDim2.fromOffset(262, 230),
			parent = body,
			colors = up.colors,
			radius = 20,
		})
		card.LayoutOrder = i
		Kit.label({
			name = "Icon",
			text = up.icon,
			size = UDim2.fromOffset(60, 60),
			position = UDim2.fromOffset(14, 10),
			parent = card,
		})
		Kit.label({
			name = "Title",
			text = up.title,
			size = UDim2.new(1, -90, 0, 36),
			position = UDim2.fromOffset(80, 20),
			parent = card,
			align = Enum.TextXAlignment.Left,
		})
		local level = Kit.label({
			name = "Level",
			text = "",
			size = UDim2.new(1, -28, 0, 30),
			position = UDim2.fromOffset(14, 80),
			parent = card,
		})
		local price = Kit.label({
			name = "Price",
			text = "",
			size = UDim2.new(1, -28, 0, 30),
			position = UDim2.fromOffset(14, 114),
			parent = card,
			color = Kit.Colors.yellow[1],
		})
		local button, gradient = Kit.button({
			name = "Buy",
			text = "UPGRADE",
			size = UDim2.new(1, -40, 0, 64),
			position = UDim2.new(0.5, 0, 1, -16),
			anchor = Vector2.new(0.5, 1),
			parent = card,
			colors = Kit.Colors.yellow,
			onClick = function()
				fire("BuyUpgrade", up.kind)
			end,
		})
		table.insert(rows, { level = level, price = price, button = button, gradient = gradient, up = up })
	end
	for i, s in SOON do
		local card = Kit.panel({
			name = s.title,
			size = UDim2.fromOffset(262, 230),
			parent = body,
			colors = Kit.Colors.grey,
			radius = 20,
		})
		card.LayoutOrder = 10 + i
		Kit.label({
			name = "Icon",
			text = s.icon,
			size = UDim2.fromOffset(80, 80),
			position = UDim2.new(0.5, 0, 0, 24),
			anchor = Vector2.new(0.5, 0),
			parent = card,
		})
		Kit.label({
			name = "Title",
			text = s.title,
			size = UDim2.new(1, -28, 0, 36),
			position = UDim2.fromOffset(14, 120),
			parent = card,
		})
		local badge = Kit.panel({
			name = "Soon",
			size = UDim2.fromOffset(110, 40),
			position = UDim2.new(0.5, 0, 1, -18),
			anchor = Vector2.new(0.5, 1),
			parent = card,
			colors = Kit.Colors.purple,
			radius = 12,
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

	local function refresh(data: { [string]: any })
		money = if typeof(data.money) == "number" then data.money else money
		for _, r in rows do
			local cfg = (Economy :: any)[r.up.kind]
			local value = data[r.up.key]
			if typeof(value) ~= "number" or not cfg then
				continue
			end
			local maxed = value >= cfg.max
			local lvl = value - cfg.base
			local cost = math.floor(cfg.costBase * cfg.costGrowth ^ lvl)
			r.level.Text = `{Kit.formatNumber(value)} / {Kit.formatNumber(cfg.max)}`
			r.price.Text = if maxed then "MAXED" else `${Kit.formatNumber(cost)}`
			local affordable = not maxed and money >= cost
			r.button.Active = not maxed
			r.gradient.Color =
				ColorSequence.new(table.unpack(if affordable then Kit.Colors.yellow else Kit.Colors.grey))
		end
	end

	return { window = window, update = refresh }
end

return StoreMenu
