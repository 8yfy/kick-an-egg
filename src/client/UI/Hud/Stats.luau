--!strict
-- Money (count-up), Kick Power and Run Speed pills on the left, below the Roblox top bar.
local Kit = require(script.Parent.Parent.Kit)

export type Stats = { update: (data: { [string]: any }) -> () }

local Stats = {}

local function pill(
	parent: Instance,
	name: string,
	width: number,
	height: number,
	colors: { Color3 },
	icon: string
): (Frame, TextLabel)
	local f = Kit.panel({
		name = name,
		size = UDim2.fromOffset(width, height),
		parent = parent,
		colors = colors,
		radius = height // 2,
	})
	local badge = Kit.panel({
		name = "Icon",
		size = UDim2.fromOffset(height + 6, height + 6),
		position = UDim2.new(0, -6, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		parent = f,
		colors = Kit.Colors.yellow,
		radius = (height + 6) // 2,
	})
	Kit.label({
		name = "Glyph",
		text = icon,
		size = UDim2.fromScale(0.7, 0.7),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		parent = badge,
	})
	local value = Kit.label({
		name = "Value",
		text = "0",
		size = UDim2.new(1, -(height + 18), 0.72, 0),
		position = UDim2.new(0, height + 10, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		parent = f,
		align = Enum.TextXAlignment.Left,
	})
	return f, value
end

function Stats.new(parent: Instance): Stats
	local root = Kit.panel({
		name = "Stats",
		size = UDim2.fromOffset(300, 200),
		position = UDim2.new(0, 22, 0.17, 0),
		parent = parent,
	})
	Kit.autoScale(root)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 12)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = root

	local money, moneyText = pill(root, "Money", 290, 66, Kit.Colors.green, "$")
	money.LayoutOrder = 1
	local power, powerText = pill(root, "Power", 220, 50, Kit.Colors.red, "⚡")
	power.LayoutOrder = 2
	local speed, speedText = pill(root, "Speed", 220, 50, Kit.Colors.blue, "👟")
	speed.LayoutOrder = 3

	-- Count-up: tween a NumberValue and render it every change.
	local shown = Instance.new("NumberValue")
	shown.Changed:Connect(function(v)
		moneyText.Text = Kit.formatNumber(v)
	end)
	local moneyScale = Instance.new("UIScale")
	moneyScale.Parent = money
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
				powerText.Text = `Power {Kit.formatNumber(data.kickPower)}`
			end
			if typeof(data.runSpeed) == "number" then
				speedText.Text = `Speed {Kit.formatNumber(data.runSpeed)}`
			end
		end,
	}
end

return Stats
