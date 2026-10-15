--!strict
-- Partner A. Backpack screen (custom inventory; opened by the hotbar's BAG slot, B, gamepad DPad Up). Every egg
-- you carry and pet you have stored (UI/System/Backpack), each card showing the LIVE 3D model the game builds
-- (Ui.eggArt / Ui.petArt) on its rarity colours with its name, rarity and an EGG / PET tag. Tabs ALL / EGGS /
-- PETS, a search box (by name), and HOLDING on the one in your hands. Click a card to hold it (the screen
-- closes so you can walk to your pen and place it); click the held one to put it away. Selling pets stays on
-- the Sell Pets screen (UI/Screens/PetInventory).
local System = script.Parent.Parent.System
local Backpack = require(System.Backpack)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local GOLD = Color3.fromRGB(255, 215, 70)
local FILTERS = { "All", "Egg", "Pet" }

local Bag = {}

type Card = {
	gui: TextButton,
	art: Frame,
	name: TextLabel,
	rarity: TextLabel,
	tag: TextLabel,
	holding: TextLabel,
	glow: UIStroke,
	item: Backpack.Item,
}

local function makeCard(parent: Instance, item: Backpack.Item): Card
	local b = Instance.new("TextButton")
	b.Name = item.uid
	b.Text = ""
	b.AutoButtonColor = false
	b.Selectable = true
	b.BackgroundColor3 = C.card
	b.Parent = parent
	Ui.corner(b, 16)
	Ui.stroke(b, 4)
	local glow = Ui.stroke(b, 0, GOLD)
	glow.Name = "Glow"

	local fill = Ui.frame(b, "Rarity", UDim2.new(1, -10, 0.68, -6), UDim2.fromOffset(5, 5))
	Ui.corner(fill, 12)
	Ui.fill(fill, Theme.Rarity[item.rarity] or Theme.Rarity.Common)
	fill.BackgroundTransparency = 0.3
	local art = Ui.frame(b, "Art", UDim2.new(1, -10, 0.68, -6), UDim2.fromOffset(5, 5))
	art.ZIndex = 2
	if item.kind == "Egg" then
		Ui.eggArt(art, item.key)
	else
		Ui.petArt(art, item.key)
	end

	local tag = Ui.text(b, if item.kind == "Egg" then "EGG" else "PET", 16, { stroke = 2, name = "Tag" })
	tag.Position = UDim2.fromOffset(10, 6)
	tag.Size = UDim2.fromOffset(40, 22)
	tag.TextXAlignment = Enum.TextXAlignment.Left
	tag.TextColor3 = if item.kind == "Egg" then C.power else C.text
	tag.ZIndex = 3

	local name = Ui.text(b, item.name, 20, { stroke = 3, name = "Name" })
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0.68, 2)
	name.Size = UDim2.new(1, -12, 0.17, 0)
	name.TextScaled = true
	local rarity = Ui.text(b, item.rarity, 16, { stroke = 2, name = "RarityName" })
	rarity.AnchorPoint = Vector2.new(0.5, 0)
	rarity.Position = UDim2.new(0.5, 0, 0.85, 0)
	rarity.Size = UDim2.new(1, -12, 0.12, 0)
	rarity.TextScaled = true
	local pair = Theme.Rarity[item.rarity] or Theme.Rarity.Common
	rarity.TextColor3 = pair[1]

	local holding = Ui.text(b, "HOLDING", 16, { stroke = 3, name = "Holding" })
	holding.AnchorPoint = Vector2.new(1, 0)
	holding.Position = UDim2.new(1, -8, 0, 6)
	holding.Size = UDim2.fromOffset(80, 22)
	holding.TextXAlignment = Enum.TextXAlignment.Right
	holding.TextColor3 = GOLD
	holding.ZIndex = 3

	Motion.interactive(b)
	local card: Card =
		{ gui = b, art = art, name = name, rarity = rarity, tag = tag, holding = holding, glow = glow, item = item }
	b.Activated:Connect(function()
		local wasHeld = card.item.held
		Backpack.hold(card.item)
		if not wasHeld then
			Modal.close() -- go place it
		end
	end)
	return card
end

function Bag.define()
	Modal.define(
		"Bag",
		{ title = "Backpack", header = Theme.Headers.pets, icon = "hud_pets", footer = false },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local filter = 1
			local query = ""
			local cards: { [string]: Card } = {}
			local refresh: () -> ()

			local tabs = Ui.tabs(
				body,
				{ "ALL", "EGGS", "PETS" },
				{ nil, nil, nil },
				Theme.Headers.pets,
				function(i: number)
					filter = i
					refresh()
				end
			)
			tabs.gui.Position = UDim2.new()

			local searchBox = Instance.new("TextBox")
			searchBox.Name = "Search"
			searchBox.PlaceholderText = "Search by name..."
			searchBox.Text = ""
			searchBox.ClearTextOnFocus = false
			searchBox.Font = Theme.Font
			searchBox.TextSize = 22
			searchBox.TextColor3 = C.text
			searchBox.PlaceholderColor3 = C.muted
			searchBox.TextXAlignment = Enum.TextXAlignment.Left
			searchBox.BackgroundColor3 = C.card
			searchBox.Position = UDim2.fromOffset(0, 68)
			searchBox.Size = UDim2.new(1, 0, 0, 46)
			searchBox.Parent = body
			Ui.corner(searchBox, 12)
			Ui.stroke(searchBox, 3, C.cardEdge)
			Ui.padding(searchBox, 14, 0)
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				query = string.lower(searchBox.Text)
				refresh()
			end)

			local count = Ui.text(body, "", 20, { stroke = 2, name = "Count" })
			count.AnchorPoint = Vector2.new(1, 0)
			count.Position = UDim2.new(1, -14, 0, 76)
			count.Size = UDim2.fromOffset(220, 30)
			count.TextXAlignment = Enum.TextXAlignment.Right
			count.TextColor3 = C.muted
			count.ZIndex = 3

			local scroll = Ui.scroll(body, "Items")
			scroll.Position = UDim2.fromOffset(0, 126)
			scroll.Size = UDim2.new(1, 0, 1, -126)
			Ui.padding(scroll, 6)
			local grid = Ui.grid(scroll, 170, 1.25, 14, 6)

			local empty = Ui.text(body, "No eggs or pets yet. Kick an egg and bring it home!", 26, {
				stroke = 3,
				wrap = true,
				name = "Empty",
			})
			empty.AnchorPoint = Vector2.new(0.5, 0.5)
			empty.Position = UDim2.fromScale(0.5, 0.6)
			empty.Size = UDim2.new(0.8, 0, 0, 80)
			empty.TextColor3 = C.muted

			refresh = function()
				local items = Backpack.items()
				local seen: { [string]: boolean } = {}
				local shown, eggs, pets = 0, 0, 0
				for order, item in items do
					seen[item.uid] = true
					if item.kind == "Egg" then
						eggs += 1
					else
						pets += 1
					end
					local card = cards[item.uid]
					if not card then
						card = makeCard(scroll, item)
						cards[item.uid] = card
					end
					card.item = item
					local passFilter = filter == 1 or item.kind == FILTERS[filter]
					local passQuery = query == "" or string.find(string.lower(item.name), query, 1, true) ~= nil
					card.gui.Visible = passFilter and passQuery
					card.gui.LayoutOrder = order
					card.holding.Visible = item.held
					card.glow.Thickness = if item.held then 4 else 0
					if card.gui.Visible then
						shown += 1
					end
				end
				for uid, card in cards do
					if not seen[uid] then
						card.gui:Destroy()
						cards[uid] = nil
					end
				end
				count.Text = `{eggs} eggs  ·  {pets} pets`
				empty.Visible = shown == 0
				empty.Text = if #items == 0
					then "No eggs or pets yet. Kick an egg and bring it home!"
					else "Nothing matches."
			end

			local isOpen = false
			Backpack.onChanged(function()
				if isOpen then
					refresh()
				end
			end)

			return {
				open = function()
					isOpen = true
					tabs.select(1) -- always opens on ALL (highlight + filter in step); refreshes
				end,
				close = function()
					isOpen = false
				end,
				update = refresh,
				resize = function(_size: Vector2, compact: boolean)
					grid.shape(if compact then 130 else 170, 1.25, if compact then 5 else 6)
				end,
				focus = function()
					return searchBox
				end,
			}
		end
	)
end

return Bag
