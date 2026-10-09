--!strict
-- Menu buttons and windows. Left side: a 2x2 grid of dark tiles with big glossy icons (Index, Shop,
-- Rebirth, Trade; Shop has a pulsing "!"); Settings is a round button top right (right edge on phones).
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

local TILE, GAP = 156, 16
local TILE_BG = Color3.fromRGB(22, 26, 36)
local GOLD = Color3.fromRGB(255, 216, 74)

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

	-- Left: 2x2 grid of dark tiles with big icons spilling over the top edge (approved HUD variant A).
	local entries = {
		{ "Index", "Index", "Index", false },
		{ "Store", "Shop", "Shop", true },
		{ "Rebirth", "Rebirth", "Rebirth", false },
		{ "Trade", "Trade", "Trade", false },
	}
	local grid = Kit.panel({
		name = "MenuTiles",
		size = UDim2.fromOffset(TILE * 2 + GAP, TILE * 2 + GAP),
		parent = parent,
	})
	Kit.autoScale(grid)
	Kit.onLayout(function(compact: boolean)
		grid.Position = if compact then UDim2.fromOffset(10, 8) else UDim2.new(0, 30, 0.333, 0)
	end)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(TILE, TILE)
	layout.CellPadding = UDim2.fromOffset(GAP, GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	for i, e in entries do
		local tile = Instance.new("TextButton")
		tile.Name = e[1]
		tile.LayoutOrder = i
		tile.Text = ""
		tile.AutoButtonColor = false
		tile.BackgroundColor3 = TILE_BG
		tile.BackgroundTransparency = 0.22
		tile.BorderSizePixel = 0
		Kit.corner(tile, 16)
		Kit.borderStroke(tile, 3)
		local rim = Instance.new("Frame") -- faint inner highlight
		rim.Name = "Rim"
		rim.BackgroundTransparency = 1
		rim.Size = UDim2.new(1, -4, 1, -4)
		rim.Position = UDim2.fromOffset(2, 2)
		Kit.corner(rim, 14)
		local rimStroke = Instance.new("UIStroke")
		rimStroke.Color = Color3.new(1, 1, 1)
		rimStroke.Transparency = 0.86
		rimStroke.Thickness = 2
		rimStroke.Parent = rim
		rim.Parent = tile
		local icon = Icons.view(tile, e[2], UDim2.fromOffset(136, 136))
		icon.Position = UDim2.fromOffset(10, -22)
		icon.ZIndex = 2
		Fx.wiggle(icon, 5, 2.4 + i * 0.3)
		local caption = Kit.label({
			name = "Caption",
			text = e[3],
			size = UDim2.new(1, 8, 0, 42),
			position = UDim2.new(0.5, 0, 1, -6),
			anchor = Vector2.new(0.5, 1),
			parent = tile,
			color = if e[4] then GOLD else Kit.Colors.white,
			stroke = 4,
		})
		caption.ZIndex = 3
		Kit.bouncy(tile)
		tile.MouseEnter:Connect(function()
			Kit.tween(tile, 0.15, { BackgroundTransparency = 0.06 })
		end)
		tile.MouseLeave:Connect(function()
			Kit.tween(tile, 0.2, { BackgroundTransparency = 0.22 })
		end)
		tile.Activated:Connect(function()
			toggle(e[1])
		end)
		if e[4] then
			local badge = Kit.panel({
				name = "Badge",
				size = UDim2.fromOffset(40, 44),
				position = UDim2.new(1, 10, 0, -14),
				anchor = Vector2.new(1, 0),
				parent = tile,
				colors = Kit.Colors.red,
				radius = 8,
			})
			badge.ZIndex = 4
			Kit.label({
				name = "Text",
				text = "!",
				size = UDim2.fromScale(0.8, 0.8),
				position = UDim2.fromScale(0.1, 0.1),
				parent = badge,
			}).ZIndex =
				5
			Kit.pulse(badge, 1.12)
		end
		tile.Parent = grid
	end

	-- Settings: round dark button (top right on desktop, right edge above the jump button on phones).
	local gear = Kit.panel({ name = "SettingsButton", size = UDim2.fromOffset(58, 58), parent = parent })
	Kit.autoScale(gear)
	Kit.onLayout(function(compact: boolean)
		gear.AnchorPoint = Vector2.new(1, if compact then 0.5 else 0)
		gear.Size = if compact then UDim2.fromOffset(96, 96) else UDim2.fromOffset(58, 58)
		gear.Position = if compact then UDim2.new(1, -10, 0.5, 30) else UDim2.new(1, -96, 0, 22)
	end)
	local gb = Kit.roundButton(gear, "Button", function()
		toggle("Settings")
	end)
	Icons.view(gb, "Gear", UDim2.fromScale(0.7, 0.7)).Position = UDim2.fromScale(0.15, 0.15)

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
