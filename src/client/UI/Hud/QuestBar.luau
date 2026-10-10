--!strict
-- Quest (approved HUD variant A): big stroked title at the top centre with a slim gold progress bar.
-- Reads `data.quest = { text, progress, goal }` from DataChanged; until Partner B sends quests it shows
-- the "secure your first egg" goal. A red NEW chip pulses for a few seconds when the quest changes.
local Kit = require(script.Parent.Parent.Kit)
local Fx = require(script.Parent.Parent.Fx)

export type QuestBar = { update: (data: { [string]: any }) -> () }

local QuestBar = {}
local rgb = Color3.fromRGB

function QuestBar.new(parent: Instance): QuestBar
	local root = Kit.panel({
		name = "Quest",
		size = UDim2.fromOffset(1000, 100),
		anchor = Vector2.new(0.5, 0),
		parent = parent,
	})
	Kit.autoScale(root)
	Kit.onLayout(function(compact: boolean)
		root.Position = if compact then UDim2.new(0.5, 0, 0, 4) else UDim2.new(0.5, 0, 0, 24)
	end)
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = root

	local title = Kit.text(root, "Title", "", 56, 4)
	title.LayoutOrder = 1

	local bar = Kit.panel({
		name = "Bar",
		size = UDim2.fromOffset(380, 24),
		parent = root,
		colors = { rgb(22, 26, 36), rgb(30, 34, 43) },
		radius = 12,
	})
	bar.LayoutOrder = 2
	bar.ClipsDescendants = true
	local fill = Kit.panel({
		name = "Fill",
		size = UDim2.fromScale(0, 1),
		parent = bar,
		colors = { rgb(255, 228, 90), rgb(245, 163, 0) },
		radius = 12,
		stroke = false,
	})
	Fx.shine(fill, 2.6)
	local count = Kit.label({ name = "Count", text = "", size = UDim2.fromScale(1, 0.9), parent = bar, stroke = 2 })
	count.ZIndex = 2

	local badge = Kit.panel({
		name = "New",
		size = UDim2.fromOffset(70, 32),
		position = UDim2.new(1, 12, 0, 6),
		parent = title,
		colors = Kit.Colors.red,
		radius = 8,
	})
	badge.Rotation = 8
	badge.Visible = false
	Kit.label({
		name = "Text",
		text = "NEW!",
		size = UDim2.fromScale(0.84, 0.8),
		position = UDim2.fromScale(0.08, 0.1),
		parent = badge,
	})

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
			count.Text = `{Kit.formatNumber(progress)} / {Kit.formatNumber(goal)}`
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
