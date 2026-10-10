--!strict
-- Cash + Kick Power counters (UI handoff SCREEN-SPEC "HUD": bottom-left; Figma "HUD / Counter"). Each is a
-- dark stud pill with its icon and a big gradient number that interpolates for 0.3 s and always lands on the
-- exact server value (no bounce on rapid gains). Phones: top-left, beside the icon-only rail. Replaces A's
-- Stats lines (Run Speed now lives in Training > Speed).
local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local Data = require(System.Data)
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
	glyph: string,
	height: number,
	textSize: number,
	top: Color3,
	bottom: Color3,
	order: number,
	format: (n: number) -> string
): Counter
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.AutomaticSize = Enum.AutomaticSize.X
	row.Size = UDim2.fromOffset(0, height)
	row.BackgroundColor3 = C.panelDeep
	row.BackgroundTransparency = 0.25
	Ui.corner(row, height // 2)
	Ui.stroke(row)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 22)
	pad.Parent = row
	local list = Ui.list(row, 10, true)
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	local img = Ui.icon(row, icon, height - 8, glyph)
	img.LayoutOrder = 1
	local label =
		Ui.text(row, format(0), textSize, { autoX = true, stroke = math.max(3, textSize // 12), name = "Value" })
	label.LayoutOrder = 2
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(top, bottom)
	g.Parent = label
	row.Parent = parent
	local value = Instance.new("NumberValue")
	value.Changed:Connect(function(v: number)
		label.Text = format(v)
	end)
	return { row = row, value = value, label = label }
end

function Counters.new(parent: Instance): Counters
	local root = Ui.frame(parent, "Counters", UDim2.fromOffset(520, 190))
	Kit.autoScale(root)
	local list = Ui.list(root, 10)

	local cash = counter(
		root,
		"Cash",
		"icon/cash",
		"$",
		92,
		72,
		Theme.Gradients.lime[1],
		Color3.fromHex("2FCF1F"),
		2,
		function(n)
			return Ui.money(n)
		end
	)
	local power = counter(
		root,
		"Power",
		"icon/power",
		"P",
		64,
		46,
		Theme.Gradients.gold[1],
		Theme.Gradients.orange[2],
		1,
		function(n)
			return Ui.number(n) .. " Kick Power"
		end
	)

	Kit.onLayout(function(compact: boolean)
		root.AnchorPoint = if compact then Vector2.new(0, 0) else Vector2.new(0, 1)
		root.Position = if compact then UDim2.fromOffset(112, 8) else UDim2.new(0, 30, 1, -26)
		list.VerticalAlignment = if compact then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom
		cash.row.LayoutOrder = if compact then 1 else 2
		power.row.LayoutOrder = if compact then 2 else 1
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
				power.label.Text = Ui.number(Data.power()) .. " Kick Power"
				return
			end
			Motion.count(cash.value, Data.money())
			Motion.count(power.value, Data.power())
		end,
	}
end

return Counters
