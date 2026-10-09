--!strict
-- Menu bar (top right, left of the sound toggle, clear of the phone thumbstick and jump button)
-- and the five menu windows. Index/Store/Rebirth read DataChanged; Store/Rebirth fire C->S remotes.
local Kit = require(script.Parent.Kit)
local IndexMenu = require(script.IndexMenu)
local StoreMenu = require(script.StoreMenu)
local RebirthMenu = require(script.RebirthMenu)
local TradeMenu = require(script.TradeMenu)
local SettingsMenu = require(script.SettingsMenu)

export type Menus = { update: (data: { [string]: any }) -> () }

local Menus = {}

function Menus.new(parent: Instance): Menus
	local entries = {
		{ "Index", "📖", Kit.Colors.purple, IndexMenu.new(parent) },
		{ "Store", "🛒", Kit.Colors.green, StoreMenu.new(parent) },
		{ "Rebirth", "🔁", Kit.Colors.yellow, RebirthMenu.new(parent) },
		{ "Trade", "🤝", Kit.Colors.blue, TradeMenu.new(parent) },
		{ "Settings", "⚙", Kit.Colors.grey, SettingsMenu.new(parent) },
	}

	local bar = Kit.panel({
		name = "MenuBar",
		size = UDim2.fromOffset(#entries * 84, 100),
		position = UDim2.new(1, -110, 0.17, 0),
		anchor = Vector2.new(1, 0),
		parent = parent,
	})
	Kit.autoScale(bar)
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Right
	row.Padding = UDim.new(0, 12)
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Parent = bar

	for i, e in entries do
		local holder = Kit.panel({ name = e[1], size = UDim2.fromOffset(72, 96), parent = bar })
		holder.LayoutOrder = i
		local menu = e[4]
		Kit.button({
			name = "Button",
			text = e[2],
			size = UDim2.fromOffset(72, 72),
			parent = holder,
			colors = e[3],
			radius = 18,
			onClick = function()
				if menu.window.isOpen() then
					menu.window.close()
				else
					menu.window.open()
				end
			end,
		})
		Kit.label({
			name = "Caption",
			text = e[1],
			size = UDim2.fromOffset(84, 22),
			position = UDim2.new(0.5, 0, 0, 74),
			anchor = Vector2.new(0.5, 0),
			parent = holder,
			stroke = 2,
		})
	end

	return {
		update = function(data: { [string]: any })
			for _, e in entries do
				e[4].update(data)
			end
		end,
	}
end

return Menus
