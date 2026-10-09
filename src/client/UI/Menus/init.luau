--!strict
-- Menu buttons and windows. Left side (next to the zone bar): a stack of wide, outlined, studded
-- buttons with a Figma icon + label (Shop, Index, Rebirth, Trade); Settings is a gear at the top right.
-- Menus.open(name) lets prompts / the "+" badge open a window.
local Kit = require(script.Parent.Kit)
local Icons = require(script.Parent.Icons)
local Fx = require(script.Parent.Fx)
local IndexMenu = require(script.IndexMenu)
local StoreMenu = require(script.StoreMenu)
local RebirthMenu = require(script.RebirthMenu)
local TradeMenu = require(script.TradeMenu)
local SettingsMenu = require(script.SettingsMenu)

export type Menus = { update: (data: { [string]: any }) -> (), open: (name: string) -> () }

local Menus = {}

local BTN_W, BTN_H, GAP = 210, 68, 12
local rgb = Color3.fromRGB

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

	local entries = {
		{ "Store", "Cart", "Shop", { rgb(135, 245, 70), rgb(70, 200, 40) } },
		{ "Index", "Book", "Index", { rgb(90, 225, 255), rgb(30, 165, 240) } },
		{ "Rebirth", "Rebirth", "Rebirth", { rgb(255, 190, 70), rgb(245, 125, 30) } },
		{ "Trade", "Trade", "Trade", { rgb(205, 130, 255), rgb(150, 70, 240) } },
	}
	local stack = Kit.panel({
		name = "MenuStack",
		size = UDim2.fromOffset(BTN_W, #entries * (BTN_H + GAP)),
		position = UDim2.new(0, 84, 0.42, 0),
		anchor = Vector2.new(0, 0.5),
		parent = parent,
	})
	Kit.autoScale(stack)
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, GAP)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = stack

	for i, e in entries do
		local holder = Kit.panel({ name = e[1], size = UDim2.fromOffset(BTN_W, BTN_H), parent = stack })
		holder.LayoutOrder = i
		local button = Kit.button({
			name = "Button",
			text = "",
			size = UDim2.fromScale(1, 1),
			parent = holder,
			colors = e[4],
			radius = 8,
			onClick = function()
				toggle(e[1])
			end,
		})
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = 4
			stroke.Color = e[4][2]:Lerp(rgb(0, 0, 0), 0.65)
		end
		local icon = Icons.view(button, e[2], UDim2.fromOffset(60, 60))
		icon.Position = UDim2.fromOffset(8, 4)
		Fx.wiggle(icon, 6, 2.4)
		Fx.shine(button, 4.5, i * 0.6)
		Kit.label({
			name = "Caption",
			text = e[3],
			size = UDim2.new(1, -84, 0, 44),
			position = UDim2.fromOffset(74, 12),
			parent = button,
			align = Enum.TextXAlignment.Left,
			stroke = 4,
		})
		if e[1] == "Store" then
			local badge = Kit.panel({
				name = "Badge",
				size = UDim2.fromOffset(64, 28),
				position = UDim2.new(1, 12, 0, -12),
				anchor = Vector2.new(1, 0),
				parent = holder,
				colors = Kit.Colors.red,
				radius = 6,
			})
			badge.Rotation = 8
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
		radius = 10,
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
