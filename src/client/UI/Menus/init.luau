--!strict
-- Menu buttons and windows. Left side (next to the zone bar): a 2 x 2 grid of big square buttons with
-- 3D block icons (Index, Shop, Rebirth, Trade); Settings is a gear at the top right by the sound toggle.
-- Menus.open(name) lets prompts / the "+" button open a window.
local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local IndexMenu = require(script.IndexMenu)
local StoreMenu = require(script.StoreMenu)
local RebirthMenu = require(script.RebirthMenu)
local TradeMenu = require(script.TradeMenu)
local SettingsMenu = require(script.SettingsMenu)

export type Menus = { update: (data: { [string]: any }) -> (), open: (name: string) -> () }

local Menus = {}

local SIZE, GAP = 118, 12

function Menus.new(parent: Instance): Menus
	local menus: { [string]: any } = {
		Index = IndexMenu.new(parent),
		Store = StoreMenu.new(parent),
		Rebirth = RebirthMenu.new(parent),
		Trade = TradeMenu.new(parent),
		Settings = SettingsMenu.new(parent),
	}
	local function toggle(name: string)
		local m = menus[name]
		if m.window.isOpen() then
			m.window.close()
		else
			m.window.open()
		end
	end

	local grid = Kit.panel({
		name = "MenuGrid",
		size = UDim2.fromOffset(2 * SIZE + GAP, 2 * SIZE + GAP),
		position = UDim2.new(0, 84, 0.42, 0),
		anchor = Vector2.new(0, 0.5),
		parent = parent,
	})
	Kit.autoScale(grid)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(SIZE, SIZE)
	layout.CellPadding = UDim2.fromOffset(GAP, GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local entries = {
		{ "Index", "Book", "Index", { Color3.fromRGB(90, 85, 110), Color3.fromRGB(55, 50, 72) } },
		{ "Store", "Chest", "Shop", { Color3.fromRGB(90, 85, 110), Color3.fromRGB(55, 50, 72) } },
		{ "Rebirth", "Rebirth", "Rebirth", { Color3.fromRGB(90, 85, 110), Color3.fromRGB(55, 50, 72) } },
		{ "Trade", "Trade", "Trade", { Color3.fromRGB(90, 85, 110), Color3.fromRGB(55, 50, 72) } },
	}
	for i, e in entries do
		local holder = Kit.panel({ name = e[1], size = UDim2.fromOffset(SIZE, SIZE), parent = grid })
		holder.LayoutOrder = i
		local button = Kit.button({
			name = "Button",
			text = "",
			size = UDim2.fromScale(1, 1),
			parent = holder,
			colors = e[4],
			radius = 14,
			onClick = function()
				toggle(e[1])
			end,
		})
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = 4
		end
		Icons.view(button, e[2], UDim2.new(1, -16, 1, -34)).Position = UDim2.fromOffset(8, 4)
		Kit.label({
			name = "Caption",
			text = e[3],
			size = UDim2.new(1, -8, 0, 34),
			position = UDim2.new(0, 4, 1, -36),
			parent = button,
			stroke = 4,
		})
		if e[1] == "Store" then
			local badge = Kit.panel({
				name = "Badge",
				size = UDim2.fromOffset(70, 30),
				position = UDim2.new(1, 10, 0, -10),
				anchor = Vector2.new(1, 0),
				parent = holder,
				colors = Kit.Colors.red,
				radius = 6,
			})
			badge.Rotation = 6
			badge.ZIndex = 3
			Kit.label({
				name = "Text",
				text = "NEW",
				size = UDim2.fromScale(0.86, 0.8),
				position = UDim2.fromScale(0.07, 0.1),
				parent = badge,
			})
			Kit.pulse(badge, 1.1)
		end
	end

	-- Settings gear (top right, left of the sound toggle)
	local gear = Kit.panel({
		name = "SettingsButton",
		size = UDim2.fromOffset(72, 72),
		position = UDim2.new(1, -106, 0.17, 0),
		anchor = Vector2.new(1, 0),
		parent = parent,
	})
	Kit.autoScale(gear)
	local gb = Kit.button({
		name = "Button",
		text = "",
		size = UDim2.fromScale(1, 1),
		parent = gear,
		colors = Kit.Colors.grey,
		radius = 18,
		onClick = function()
			toggle("Settings")
		end,
	})
	Icons.view(gb, "Gear", UDim2.new(1, -12, 1, -12)).Position = UDim2.fromOffset(6, 6)

	return {
		update = function(data: { [string]: any })
			for _, m in menus do
				m.update(data)
			end
		end,
		open = function(name: string)
			local m = menus[name]
			if m and not m.window.isOpen() then
				m.window.open()
			end
		end,
	}
end

return Menus
