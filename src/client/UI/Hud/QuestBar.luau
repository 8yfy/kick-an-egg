--!strict
-- Quest bar (top centre, just below the top 15%). Reads `data.quest = { text, progress, goal }`
-- from DataChanged when Partner B adds quests; until then it shows the "secure your first egg" goal.
local Kit = require(script.Parent.Parent.Kit)

export type QuestBar = { update: (data: { [string]: any }) -> () }

local QuestBar = {}

function QuestBar.new(parent: Instance): QuestBar
	local root = Kit.panel({
		name = "Quest",
		size = UDim2.fromOffset(470, 70),
		position = UDim2.new(0.5, 0, 0.15, 6),
		anchor = Vector2.new(0.5, 0),
		parent = parent,
		colors = Kit.Colors.dark,
		radius = 18,
	})
	Kit.autoScale(root)

	Kit.studs(root)
	local Icons = require(script.Parent.Parent.Icons)
	local tag = Icons.view(root, "Quests", UDim2.fromOffset(84, 84))
	tag.Position = UDim2.fromOffset(4, -12)
	tag.Rotation = -8

	local badge = Kit.panel({
		name = "New",
		size = UDim2.fromOffset(58, 28),
		position = UDim2.new(1, 8, 0, -12),
		anchor = Vector2.new(1, 0),
		parent = root,
		colors = Kit.Colors.red,
		radius = 10,
	})
	badge.Rotation = 8
	badge.Visible = false
	Kit.label({
		name = "Text",
		text = "NEW",
		size = UDim2.fromScale(0.8, 0.8),
		position = UDim2.fromScale(0.1, 0.1),
		parent = badge,
	})

	local title = Kit.label({
		name = "Title",
		text = "",
		size = UDim2.new(1, -124, 0, 28),
		position = UDim2.fromOffset(104, 8),
		parent = root,
		align = Enum.TextXAlignment.Left,
	})
	local bar = Kit.panel({
		name = "Bar",
		size = UDim2.new(1, -40, 0, 20),
		position = UDim2.fromOffset(20, 40),
		parent = root,
		colors = { Color3.fromRGB(30, 25, 40), Color3.fromRGB(50, 45, 65) },
		radius = 10,
		stroke = false,
	})
	local fill = Kit.panel({
		name = "Fill",
		size = UDim2.fromScale(0, 1),
		parent = bar,
		colors = Kit.Colors.yellow,
		radius = 10,
		stroke = false,
	})
	local count = Kit.label({
		name = "Count",
		text = "",
		size = UDim2.fromScale(1, 1),
		parent = bar,
		stroke = 2,
	})
	count.ZIndex = 2

	local lastText = ""
	local stopPulse: (() -> ())? = nil
	return {
		update = function(data: { [string]: any })
			local text, progress, goal
			local q = data.quest
			if typeof(q) == "table" and typeof(q.text) == "string" then
				text, progress, goal = q.text, tonumber(q.progress) or 0, tonumber(q.goal) or 1
			else
				local secured = if typeof(data.stats) == "table" then tonumber(data.stats.secured) or 0 else 0
				if secured < 1 then
					text, progress, goal = "Kick an egg and carry it home!", 0, 1
				else
					text, progress, goal = "Eggs secured", secured, secured
				end
			end
			title.Text = text
			local frac = math.clamp(progress / math.max(goal, 1), 0, 1)
			Kit.tween(fill, 0.4, { Size = UDim2.fromScale(frac, 1) })
			fill.Visible = frac > 0
			count.Text = `{Kit.formatNumber(progress)}/{Kit.formatNumber(goal)}`
			if text ~= lastText and lastText ~= "" then
				badge.Visible = true
				if stopPulse then
					stopPulse()
				end
				stopPulse = Kit.pulse(badge)
				task.delay(4, function()
					if stopPulse then
						stopPulse()
						stopPulse = nil
					end
					badge.Visible = false
				end)
			end
			lastText = text
		end,
	}
end

return QuestBar
