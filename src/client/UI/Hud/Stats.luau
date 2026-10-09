--!strict
-- Bottom-left stats, big and chunky: Kick Power and Run Speed lines (3D icons, green "+" opens the
-- Store) and the money counter (huge green, count-up tween, cash-stack icon).
local Kit = require(script.Parent.Parent.Kit)
local Icons = require(script.Parent.Parent.Icons)

export type Stats = { update: (data: { [string]: any }) -> () }

local Stats = {}

local function line(
	parent: Instance,
	name: string,
	icon: string,
	height: number,
	colors: { Color3 },
	order: number
): (Frame, TextLabel)
	local row = Kit.panel({ name = name, size = UDim2.fromOffset(460, height), parent = parent })
	row.LayoutOrder = order
	Icons.view(row, icon, UDim2.fromOffset(height, height))
	local text = Kit.label({
		name = "Value",
		text = "",
		size = UDim2.new(1, -(height + 8), 1, 0),
		position = UDim2.fromOffset(height + 6, 0),
		parent = row,
		align = Enum.TextXAlignment.Left,
		stroke = math.max(3, height // 14),
	})
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(colors[1], colors[2])
	g.Parent = text
	return row, text
end

function Stats.new(parent: Instance, onPlus: () -> ()): Stats
	local root = Kit.panel({
		name = "Stats",
		size = UDim2.fromOffset(460, 220),
		position = UDim2.new(0, 84, 1, -18),
		anchor = Vector2.new(0, 1),
		parent = parent,
	})
	Kit.autoScale(root)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Parent = root

	local powerRow, powerText =
		line(root, "Power", "Bolt", 52, { Color3.fromRGB(255, 235, 110), Color3.fromRGB(255, 150, 30) }, 1)
	local _, speedText =
		line(root, "Speed", "Boot", 46, { Color3.fromRGB(150, 220, 255), Color3.fromRGB(60, 140, 255) }, 2)
	local _, moneyText =
		line(root, "Money", "Cash", 88, { Color3.fromRGB(150, 255, 120), Color3.fromRGB(40, 190, 60) }, 3)
	powerText.Size = UDim2.new(1, -120, 1, 0)
	local plus = Kit.button({
		name = "Plus",
		text = "+",
		size = UDim2.fromOffset(48, 48),
		position = UDim2.new(1, -50, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		parent = powerRow,
		colors = Kit.Colors.green,
		radius = 10,
		onClick = onPlus,
	})
	plus.ZIndex = 2

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
						moneyScale.Scale = 1.12
						Kit.tween(moneyScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
					end
				end
				lastMoney = m
			end
			if typeof(data.kickPower) == "number" then
				local kp = data.kickPower
				local shownKp = if kp < 1000 and kp % 1 ~= 0 then string.format("%.1f", kp) else Kit.formatNumber(kp)
				powerText.Text = `{shownKp} Kick Power`
			end
			if typeof(data.runSpeed) == "number" then
				speedText.Text = `{Kit.formatNumber(data.runSpeed)} Run Speed`
			end
		end,
	}
end

return Stats
