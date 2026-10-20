--!strict
-- Stats (approved HUD variant A): no panels, big stroked gradient lines. Bottom left on desktop, top right
-- on phones (out of the thumbstick corner). Luck (only once the server sends `luck`), Kick Power and Run
-- Speed with green "+" buttons (open the Shop), and money with a count-up tween.
local Kit = require(script.Parent.Parent.Kit)
local Icons = require(script.Parent.Parent.Icons)
local Fx = require(script.Parent.Parent.Fx)

export type Stats = { update: (data: { [string]: any }) -> () }

local Stats = {}
local rgb = Color3.fromRGB
local GREEN = { rgb(124, 255, 58), rgb(37, 194, 27) }

type Line = { row: Frame, text: TextLabel, icon: ImageLabel?, plus: TextButton? }

local function line(
	parent: Instance,
	name: string,
	icon: string?,
	height: number,
	textSize: number,
	top: Color3,
	bottom: Color3,
	order: number,
	onPlus: (() -> ())?
): Line
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundTransparency = 1
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.fromOffset(0, height)
	row.LayoutOrder = order
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row
	local img: ImageLabel? = nil
	if icon then
		local view = Icons.view(row, icon, UDim2.fromOffset(height, height))
		view.LayoutOrder = 1
		img = view
	end
	local text = Kit.text(row, "Value", "", textSize, math.max(3, textSize // 14))
	text.LayoutOrder = 2
	Kit.gradientText(text, top, bottom)
	local plus: TextButton? = nil
	if onPlus then
		local b = Kit.button({
			name = "Plus",
			text = "+",
			size = UDim2.fromOffset(46, 46),
			parent = row,
			colors = GREEN,
			radius = 10,
			onClick = onPlus,
		})
		b.LayoutOrder = 3
		plus = b
	end
	row.Parent = parent
	return { row = row, text = text, icon = img, plus = plus }
end

function Stats.new(parent: Instance, onPlus: () -> ()): Stats
	local root = Kit.panel({ name = "Stats", size = UDim2.fromOffset(640, 340), parent = parent })
	Kit.autoScale(root)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 2)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = root

	local white, lilac = rgb(255, 255, 255), rgb(220, 215, 255)
	local luck = line(root, "Luck", nil, 50, 44, white, lilac, 1, nil)
	luck.row.Visible = false
	local power = line(root, "Power", "Power", 58, 52, rgb(255, 214, 90), rgb(255, 122, 26), 2, onPlus)
	local speed = line(root, "Speed", "WalkSpeed", 54, 44, rgb(150, 240, 255), rgb(27, 139, 234), 3, onPlus)
	local money = line(root, "Money", "Coins", 104, 104, rgb(190, 255, 110), rgb(47, 207, 31), 4, nil)
	local moneyStroke = money.text:FindFirstChildOfClass("UIStroke")
	if moneyStroke then
		moneyStroke.Thickness = 6
	end
	if money.icon then
		Fx.sparkles(money.icon, 2, 18)
		Fx.wiggle(money.icon, 4, 1.6)
	end

	local compactMode = false
	local last: { [string]: any } = {}
	local function render()
		local kp = last.kickPower
		if typeof(kp) == "number" then
			local n = if kp < 1000 and kp % 1 ~= 0 then string.format("%.1f", kp) else Kit.formatNumber(kp)
			power.text.Text = if compactMode then `{n} Power` else `{n} Kick Power`
		end
		local rs = last.runSpeed
		if typeof(rs) == "number" then
			speed.text.Text = if compactMode then `{Kit.formatNumber(rs)} Speed` else `{Kit.formatNumber(rs)} Run Speed`
		end
		local lk = last.luck
		luck.row.Visible = typeof(lk) == "number"
		if typeof(lk) == "number" then
			luck.text.Text = `{Kit.formatNumber(lk)}% Luck`
		end
	end

	Kit.onLayout(function(compact: boolean)
		compactMode = compact
		root.AnchorPoint = if compact then Vector2.new(1, 0) else Vector2.new(0, 1)
		root.Position = if compact then UDim2.new(1, -12, 0, 8) else UDim2.new(0, 26, 1, -26)
		list.VerticalAlignment = if compact then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom
		list.HorizontalAlignment = if compact then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left
		money.row.LayoutOrder = if compact then 0 else 4
		for _, l in { power, speed } do
			local plus = l.plus
			if plus then
				-- phones: >= 44 px touch targets after the screen scale (~0.49)
				plus.Size = if compact then UDim2.fromOffset(90, 62) else UDim2.fromOffset(46, 46)
			end
		end
		render()
	end)

	local shown = Instance.new("NumberValue")
	shown.Changed:Connect(function(v)
		money.text.Text = "$" .. Kit.formatNumber(v)
	end)
	money.text.Text = "$0"
	local moneyScale = Instance.new("UIScale")
	moneyScale.Parent = money.text
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
						Fx.floatText(money.text, "+$" .. Kit.formatNumber(m - lastMoney), rgb(140, 255, 110))
						moneyScale.Scale = 1.12
						Kit.tween(moneyScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
					end
				end
				lastMoney = m
			end
			last.kickPower, last.runSpeed, last.luck = data.kickPower, data.runSpeed, data.luck
			render()
		end,
	}
end

return Stats
