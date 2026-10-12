--!strict
-- Cash + Kick Power counters (UI handoff v2 01-Mockups/01-Gameplay-HUD.png, bottom-left). Each is a dark bordered
-- bar with its supplied icon (currency-cash / power-sneaker), a big outlined value that interpolates for 0.3 s
-- and always lands on the exact server value (no bounce on rapid gains), and a green "+" button: cash opens the
-- Shop (developer products), power opens Training (strength is trained, not bought). Phones: top-left, beside
-- the icon-only nav. Replaces A's Stats lines (Run Speed lives in Training > Speed).
local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Counters = {}

export type Counters = { update: () -> () }

type Counter = { row: Frame, value: NumberValue, label: TextLabel }

local function counter(
	parent: Instance,
	name: string,
	icon: string,
	height: number,
	textSize: number,
	fill: Theme.Pair,
	order: number,
	format: (n: number) -> string,
	onPlus: (b: GuiObject) -> ()
): Counter
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, height)
	row.BackgroundColor3 = C.card
	row.BackgroundTransparency = 0.08
	Ui.corner(row)
	Ui.stroke(row, 5)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 6), UDim.new(0, 8)
	pad.Parent = row
	local list = Ui.list(row, 10, true)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	local holder = Ui.frame(row, "Icon", UDim2.fromOffset(height + 14, height + 14))
	holder.LayoutOrder = 1
	Ui.art(holder, icon)
	local label =
		Ui.text(row, format(0), textSize, { autoX = true, stroke = math.max(4, textSize // 10), name = "Value" })
	label.LayoutOrder = 2
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(fill[1], fill[2])
	g.Parent = label
	local plus: Ui.Button
	plus = Ui.button(row, {
		text = "+",
		style = "lime",
		size = UDim2.fromOffset(height - 16, height - 16),
		textSize = math.floor(height * 0.62),
		name = "Plus",
		onClick = function()
			onPlus(plus.gui)
		end,
	})
	plus.gui.LayoutOrder = 3
	row.Parent = parent
	local value = Instance.new("NumberValue")
	value.Changed:Connect(function(v: number)
		label.Text = format(v)
	end)
	return { row = row, value = value, label = label }
end

function Counters.new(parent: Instance): Counters
	local root = Ui.frame(parent, "Counters", UDim2.fromOffset(560, 200))
	Kit.autoScale(root)
	local list = Ui.list(root, 12)

	local cash = counter(
		root,
		"Cash",
		"premium_icons_currency_cash",
		84,
		62,
		{ Color3.fromHex("C8FF4A"), Color3.fromHex("3FD81A") },
		1,
		function(n)
			return Ui.money(n)
		end,
		function(b)
			Modal.open("Shop", b)
		end
	)
	local power = counter(
		root,
		"Power",
		"premium_icons_power_sneaker",
		76,
		48,
		{ Color3.fromHex("FFF06A"), Color3.fromHex("FFB000") },
		2,
		function(n)
			return "POWER " .. Ui.number(n)
		end,
		function(b)
			Modal.open("Training", b)
		end
	)

	Kit.onLayout(function(compact: boolean)
		root.AnchorPoint = if compact then Vector2.new(0, 0) else Vector2.new(0, 1)
		root.Position = if compact then UDim2.fromOffset(116, 124) else UDim2.new(0, 24, 1, -24) -- phones: below the quest title
		list.VerticalAlignment = if compact then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom
	end)

	local first = true
	return {
		update = function()
			if not Data.loaded() then
				return
			end
			if first then
				first = false
				cash.value.Value = Data.money()
				power.value.Value = Data.power()
				cash.label.Text = Ui.money(Data.money())
				power.label.Text = "POWER " .. Ui.number(Data.power())
				return
			end
			Motion.count(cash.value, Data.money())
			Motion.count(power.value, Data.power())
		end,
	}
end

return Counters
