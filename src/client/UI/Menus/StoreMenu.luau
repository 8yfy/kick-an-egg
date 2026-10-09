--!strict
-- Shop: a horizontal row of tall cards (gradient + studs, title + subtitle, big preview, a dark stat
-- pill with the gain in green, a chunky price button). Cards:
--   Training Station (UpgradeTraining, live 3D preview of the next tier), Kick Power / Run Speed
--   (BuyUpgrade), Bigger Pen (UpgradePen), and "SOON" cards for Partner B's gamepasses.
-- Prices come from the documented Config formulas (display only; the server charges).
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
local rgb = Color3.fromRGB
local CARD_W, CARD_H = 250, 400
local GREEN_HEX = "#8CFF5A"

local function fire(name: string, ...: any)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local ev = remotes and remotes:FindFirstChild(name)
	if ev and ev:IsA("RemoteEvent") then
		ev:FireServer(...)
	end
end

type Card = {
	frame: Frame,
	subtitle: TextLabel,
	pill: TextLabel,
	button: TextButton,
	grad: UIGradient,
	label: TextLabel,
	preview: Frame,
}

local function card(parent: Instance, order: number, title: string, colors: { Color3 }, onClick: (() -> ())?): Card
	local c = Kit.panel({
		name = title,
		size = UDim2.fromOffset(CARD_W, CARD_H),
		parent = parent,
		colors = colors,
		radius = 12,
	})
	c.LayoutOrder = order
	local stroke = c:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Thickness = 5
	end
	Kit.studs(c)
	Kit.label({
		name = "Title",
		text = title,
		size = UDim2.new(1, -20, 0, 42),
		position = UDim2.fromOffset(10, 12),
		parent = c,
		stroke = 4,
	})
	local subtitle = Kit.label({
		name = "Subtitle",
		text = "",
		size = UDim2.new(1, -20, 0, 24),
		position = UDim2.fromOffset(10, 52),
		parent = c,
		stroke = 3,
	})
	local preview = Kit.panel({
		name = "Preview",
		size = UDim2.new(1, -30, 0, 170),
		position = UDim2.fromOffset(15, 82),
		parent = c,
	})
	Icons.glow(c, UDim2.new(1, 0, 0, 200)).Position = UDim2.fromOffset(0, 66)
	local pillBox = Kit.panel({
		name = "PillBox",
		size = UDim2.new(1, -28, 0, 46),
		position = UDim2.fromOffset(14, 262),
		parent = c,
		colors = { rgb(30, 30, 40), rgb(20, 20, 28) },
		radius = 8,
		stroke = false,
	})
	for _, g in pillBox:GetChildren() do
		if g:IsA("UIGradient") then
			g.Transparency = NumberSequence.new(0.45)
		end
	end
	local pill = Kit.label({
		name = "Pill",
		text = "",
		size = UDim2.new(1, -16, 1, -10),
		position = UDim2.fromOffset(8, 5),
		parent = pillBox,
		stroke = 3,
	})
	pill.RichText = true
	local b, g = Kit.button({
		name = "Buy",
		text = "",
		size = UDim2.new(1, -28, 0, 64),
		position = UDim2.new(0.5, 0, 1, -14),
		anchor = Vector2.new(0.5, 1),
		parent = c,
		colors = Kit.Colors.green,
		radius = 8,
		onClick = onClick or function() end,
	})
	return {
		frame = c,
		subtitle = subtitle,
		pill = pill,
		button = b,
		grad = g,
		label = b:FindFirstChild("Label") :: TextLabel,
		preview = preview,
	}
end

local function setPrice(c: Card, cost: number?, money: number)
	if not cost then
		c.label.Text = "MAXED"
		c.button.Active = false
		c.grad.Color = ColorSequence.new(table.unpack(Kit.Colors.grey))
		return
	end
	c.label.Text = "$" .. Kit.formatNumber(cost)
	c.button.Active = true
	c.grad.Color = ColorSequence.new(table.unpack(if money >= cost then Kit.Colors.green else Kit.Colors.red))
end

local function gain(text: string, rest: string): string
	return `<font color="{GREEN_HEX}">{text}</font> {rest}`
end

function StoreMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Shop", Kit.Colors.green)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Cards"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.ScrollBarThickness = 10
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = window.body
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.Padding = UDim.new(0, 16)
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = scroll

	local station = card(scroll, 1, "Training Station", { rgb(110, 205, 255), rgb(40, 120, 235) }, function()
		fire("UpgradeTraining")
	end)
	local power = card(scroll, 2, "Kick Power", { rgb(255, 190, 80), rgb(245, 110, 30) }, function()
		fire("BuyUpgrade", "KickPower")
	end)
	Icons.view(power.preview, "Bolt")
	local speed = card(scroll, 3, "Run Speed", { rgb(120, 235, 255), rgb(40, 170, 235) }, function()
		fire("BuyUpgrade", "RunSpeed")
	end)
	Icons.view(speed.preview, "Boot")
	local pen = card(scroll, 4, "Bigger Pen", { rgb(255, 235, 110), rgb(240, 180, 30) }, function()
		fire("UpgradePen")
	end)
	Icons.view(pen.preview, "Egg")
	local soon = {
		{ "2x Money", "CoinBoost", { rgb(255, 120, 230), rgb(200, 40, 200) } },
		{ "VIP", "Gamepasses", { rgb(200, 150, 255), rgb(130, 70, 240) } },
		{ "Lucky Kicks", "Luck", { rgb(140, 245, 120), rgb(50, 190, 70) } },
	}
	for i, s in soon do
		local c = card(scroll, 10 + i, s[1], s[3], nil)
		Icons.view(c.preview, s[2])
		c.subtitle.Text = "Game Pass"
		c.pill.Text = "Coming soon"
		c.label.Text = "SOON"
		c.button.Active = false
		c.grad.Color = ColorSequence.new(rgb(240, 90, 255), rgb(170, 30, 220))
	end

	local data: { [string]: any } = {}
	local shownTier = ""
	local function refresh()
		local money = if typeof(data.money) == "number" then data.money else 0
		local levels = Upgrades.Rack.levels
		local lvl = math.clamp(MyBase.level("RackLevel", data, "rackLevel"), 1, #levels)
		local now, nxt = levels[lvl], levels[lvl + 1]
		local tier = if nxt then nxt.tier else now.tier
		if shownTier ~= tier then
			shownTier = tier
			station.preview:ClearAllChildren()
			Icons.rack(station.preview, tier)
		end
		station.subtitle.Text = if nxt then `Lv {lvl} → {lvl + 1} · {tier}` else `Lv {lvl} · MAX`
		station.pill.Text = if nxt then gain(`+{nxt.gain}`, "per kick") else gain(`+{now.gain}`, "per kick")
		setPrice(station, if nxt then nxt.cost else nil, money)
		for _, pair in { { power, "KickPower", "kickPower" }, { speed, "RunSpeed", "runSpeed" } } do
			local c = pair[1] :: Card
			local cfg = (Economy :: any)[pair[2]]
			local value = data[pair[3]]
			if typeof(value) == "number" and cfg then
				local maxed = value >= cfg.max
				c.subtitle.Text = `{Kit.formatNumber(value)} / {Kit.formatNumber(cfg.max)}`
				c.pill.Text = if maxed then "MAXED" else gain("+1", if pair[2] == "KickPower" then "Power" else "Speed")
				setPrice(
					c,
					if maxed then nil else math.floor(cfg.costBase * cfg.costGrowth ^ (value - cfg.base)),
					money
				)
			end
		end
		local plvl = math.max(1, MyBase.level("PenLevel", data, "penLevel"))
		local slots = math.min(Economy.PlotSlots.base + (plvl - 1) * Upgrades.Pen.slotsPerLevel, Economy.PlotSlots.max)
		local maxed = slots >= Economy.PlotSlots.max
		pen.subtitle.Text = `{slots} egg slots`
		pen.pill.Text = if maxed then "MAXED" else gain(`+{Upgrades.Pen.slotsPerLevel}`, "slots")
		setPrice(pen, if maxed then nil else Upgrades.Pen.costBase * Upgrades.Pen.costGrowth ^ (plvl - 1), money)
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
