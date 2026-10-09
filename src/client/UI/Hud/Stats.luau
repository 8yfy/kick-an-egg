--!strict
-- Bottom-left stats: Figma icons with huge gradient numbers and thick dark outlines.
-- Kick Power (yellow "+" badge on the icon opens the Shop), Run Speed, and money (count-up tween).
local Kit = require(script.Parent.Parent.Kit)
local Icons = require(script.Parent.Parent.Icons)
local Fx = require(script.Parent.Parent.Fx)

export type Stats = { update: (data: { [string]: any }) -> () }

local Stats = {}
local rgb = Color3.fromRGB

local function line(
	parent: Instance,
	name: string,
	icon: string,
	height: number,
	top: Color3,
	bottom: Color3,
	order: number
): (Frame, TextLabel, ImageLabel)
	local row = Kit.panel({ name = name, size = UDim2.fromOffset(460, height), parent = parent })
	row.LayoutOrder = order
	local img = Icons.view(row, icon, UDim2.fromOffset(height, height))
	local text = Kit.label({
		name = "Value",
		text = "",
		size = UDim2.new(1, -(height + 10), 1, 0),
		position = UDim2.fromOffset(height + 10, 0),
		parent = row,
		align = Enum.TextXAlignment.Left,
		stroke = math.max(3, height // 12),
	})
	text.Rotation = -2
	Kit.gradientText(text, top, bottom)
	return row, text, img
end

function Stats.new(parent: Instance, onPlus: () -> ()): Stats
	local root = Kit.panel({
		name = "Stats",
		size = UDim2.fromOffset(460, 230),
		position = UDim2.new(0, 84, 1, -16),
		anchor = Vector2.new(0, 1),
		parent = parent,
	})
	Kit.autoScale(root)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = root

	local _, powerText, powerIcon = line(root, "Power", "Bolt", 66, rgb(255, 245, 160), rgb(255, 160, 30), 1)
	local _, speedText = line(root, "Speed", "Boot", 54, rgb(225, 245, 255), rgb(110, 175, 255), 2)
	local moneyRow, moneyText, moneyIcon = line(root, "Money", "Cash", 82, rgb(170, 255, 120), rgb(40, 200, 50), 3)
	Fx.sparkles(moneyIcon, 2, 18)
	Fx.wiggle(moneyIcon, 4, 1.6)
	local _ = moneyRow

	-- Yellow "+" badge on the power icon
	local plus = Kit.button({
		name = "Plus",
		text = "+",
		size = UDim2.fromOffset(34, 34),
		position = UDim2.new(1, -16, 1, -16),
		parent = powerIcon,
		colors = { rgb(255, 230, 90), rgb(240, 175, 30) },
		radius = 6,
		onClick = onPlus,
	})
	plus.ZIndex = 3

	local shown = Instance.new("NumberValue")
	shown.Changed:Connect(function(v)
		moneyText.Text = "$" .. Kit.formatNumber(v)
	end)
	moneyText.Text = "$0"
	local moneyScale = Instance.new("UIScale")
	moneyScale.Parent = moneyText
	local lastMoney: number? = nil

	return {
		update = function(data: { [string]: any })
			local m = data.money
			if typeof(m) == "number" and m ~= lastMoney then
				if lastMoney == nil then
					shown.Value = m
				else
					Kit.tween(shown, 0.6, { Value = m })
					if m > lastMoney then
						Fx.floatText(moneyText, "+$" .. Kit.formatNumber(m - lastMoney), rgb(140, 255, 110))
						moneyScale.Scale = 1.12
						Kit.tween(moneyScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
					end
				end
				lastMoney = m
			end
			if typeof(data.kickPower) == "number" then
				local kp = data.kickPower
				powerText.Text = if kp < 1000 and kp % 1 ~= 0 then string.format("%.1f", kp) else Kit.formatNumber(kp)
			end
			if typeof(data.runSpeed) == "number" then
				speedText.Text = Kit.formatNumber(data.runSpeed)
			end
		end,
	}
end

return Stats
