--!strict
-- Shop (UI handoff SCREEN-SPEC "Developer-product shop"): Robux developer products ONLY, straight from
-- Economy.DevProducts -- no gamepasses, no sacks, no speed, no invented offers or scarcity. A featured banner
-- (the biggest pack) followed by the product cards, one scroll surface.
-- Card states: Loading (price fetch), Unavailable (id = 0 / product info failed), Buy (real Robux price),
-- Prompting (Roblox purchase dialog open), Pending (bought, waiting for the server to grant the cash),
-- Granted (cash arrived via DataChanged) and Cancelled.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Shop = {}

type CardState = "Loading" | "Unavailable" | "Buy" | "Prompting" | "Pending" | "Granted" | "Cancelled"
type Card = {
	product: Data.Product,
	gui: Frame,
	title: TextLabel,
	button: Ui.Button,
	note: TextLabel,
	state: CardState,
	price: number?,
}

local infoCache: { [number]: { name: string, price: number }? } = {}

local function fetchInfo(id: number): { name: string, price: number }?
	if infoCache[id] ~= nil then
		return infoCache[id]
	end
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product)
	end)
	local result = if ok
			and typeof(info) == "table"
			and typeof(info.PriceInRobux) == "number"
		then { name = tostring(info.Name), price = info.PriceInRobux :: number }
		else nil
	infoCache[id] = result
	return result
end

local function title(p: Data.Product): string
	return `{Ui.money(p.money)} Cash`
end

local function paint(card: Card)
	local b = card.button
	b.setPending(false)
	if card.state == "Loading" then
		b.setText("LOADING...")
		b.setEnabled(false)
		card.note.Text = ""
	elseif card.state == "Unavailable" then
		b.setText("UNAVAILABLE")
		b.setEnabled(false)
		card.note.Text = if card.product.configured then "Couldn't load this product" else "Not on sale yet"
	elseif card.state == "Prompting" then
		b.setPending(true, "CHECK PROMPT...")
		card.note.Text = ""
	elseif card.state == "Pending" then
		b.setPending(true, "DELIVERING...")
		card.note.Text = "Your cash is on the way"
	else
		b.setText(`R$ {card.price or 0}`)
		b.setEnabled(true)
		card.note.Text = if card.state == "Granted"
			then `+{Ui.money(card.product.money)} added!`
			elseif card.state == "Cancelled" then "Purchase cancelled"
			else `+{Ui.money(card.product.money)} cash`
	end
end

local function buildCard(parent: Instance, p: Data.Product, order: number, featured: boolean, onBuy: (Card) -> ()): Card
	local card = Ui.panel(parent, p.key)
	card.LayoutOrder = order
	local content = Ui.frame(card, "Content")
	local art = Instance.new("Frame")
	art.Name = "ArtHolder"
	art.BorderSizePixel = 0
	art.ClipsDescendants = true
	Ui.corner(art)
	Ui.gradient(art, if featured then "gold" else "lime")
	Ui.stroke(art, 3)
	Ui.studs(art, Theme.Studs.header)
	art.Parent = content
	Ui.glow(art, Color3.new(1, 1, 1), true)
	local icon = Ui.icon(art, "icon/cash", if featured then 200 else 120, "$")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.ZIndex = 2
	if featured then
		Motion.shine(art)
		Motion.float(icon)
	end

	local info = Ui.frame(content, "Info")
	local name = Ui.text(info, title(p), if featured then 44 else 30, { name = "Title", stroke = 4 })
	local note = Ui.text(info, "", 20, { color = C.cash, name = "Note" })
	note.Position = UDim2.fromOffset(0, if featured then 56 else 40)

	local self: Card
	local button = Ui.button(info, {
		text = "LOADING...",
		gradient = "lime",
		size = UDim2.new(1, 0, 0, 60),
		textSize = 26,
		name = "Buy",
		onClick = function()
			onBuy(self)
		end,
	})
	button.gui.AnchorPoint = Vector2.new(0, 1)
	button.gui.Position = UDim2.fromScale(0, 1)

	if featured then
		art.Position = UDim2.fromOffset(12, 12)
		art.Size = UDim2.new(0.55, -12, 1, -24)
		info.Position = UDim2.new(0.55, 20, 0, 24)
		info.Size = UDim2.new(0.45, -40, 1, -44)
		button.gui.Size = UDim2.new(1, 0, 0, 72)
	else
		art.Position = UDim2.fromOffset(12, 12)
		art.Size = UDim2.new(1, -24, 0.55, -12)
		info.Position = UDim2.new(0, 14, 0.55, 12)
		info.Size = UDim2.new(1, -28, 0.45, -26)
	end
	self = { product = p, gui = card, title = name, button = button, note = note, state = "Loading", price = nil }
	return self
end

function Shop.define()
	Modal.define(
		"Shop",
		{ title = "Shop", gradient = "gold", icon = "icon/shop" },
		function(shell: Modal.Shell): Modal.Screen
			local scroll = Ui.scroll(shell.body, "Products")
			Ui.padding(scroll, 6)
			local list = Ui.list(scroll, Theme.Layout.gap)
			list.HorizontalAlignment = Enum.HorizontalAlignment.Center

			local products = Data.products()
			local cards: { Card } = {}
			local byId: { [number]: Card } = {}
			local busy: Card? = nil

			local function onBuy(card: Card)
				if busy or card.state == "Loading" or card.state == "Unavailable" then
					return
				end
				busy = card
				card.state = "Prompting"
				paint(card)
				local ok = pcall(function()
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, card.product.id)
				end)
				if not ok then
					busy = nil
					card.state = "Unavailable"
					paint(card)
				end
			end

			MarketplaceService.PromptProductPurchaseFinished:Connect(
				function(userId: number, productId: number, purchased: boolean)
					local card = byId[productId]
					if userId ~= Players.LocalPlayer.UserId or not card or card.state ~= "Prompting" then
						return
					end
					busy = nil
					if not purchased then
						card.state = "Cancelled"
						paint(card)
						return
					end
					card.state = "Pending"
					paint(card)
					local before = Data.money()
					Data.expect(
						function()
							return Data.money() >= before + card.product.money
						end,
						30,
						function(granted: boolean)
							card.state = if granted then "Granted" else "Buy"
							paint(card)
							if granted then
								Modal.toast(`+{Ui.money(card.product.money)} cash!`, "good")
								local abs = card.gui.AbsolutePosition + card.gui.AbsoluteSize / 2
								Motion.burst(Modal.layer(), abs, "cash")
							else
								card.note.Text = "Still processing. Your cash will arrive soon."
							end
						end
					)
				end
			)

			-- Featured banner: the biggest pack, full width.
			local banner = Ui.frame(scroll, "Featured", UDim2.new(1, 0, 0, 300))
			banner.LayoutOrder = 1
			local section = Ui.text(scroll, "Cash Packs", 32, { name = "SectionTitle" })
			section.LayoutOrder = 2
			local gridHolder = Ui.frame(scroll, "Grid", UDim2.new(1, 0, 0, 0))
			gridHolder.AutomaticSize = Enum.AutomaticSize.Y
			gridHolder.LayoutOrder = 3
			local grid = Ui.grid(gridHolder, 320, 1.05, Theme.Layout.gap, 3)

			for i, p in products do
				local featured = i == #products
				local card = buildCard(if featured then banner else gridHolder, p, i, featured, onBuy)
				if featured then
					card.gui.Size = UDim2.fromScale(1, 1)
				end
				table.insert(cards, card)
				if p.configured then
					byId[p.id] = card
				end
			end
			local empty = #products == 0
			if empty then
				Ui.text(scroll, "No products yet.", 26, { color = C.muted, align = Enum.TextXAlignment.Center }).LayoutOrder =
					4
			end

			local loaded = false
			local function load()
				if loaded then
					return
				end
				loaded = true
				for _, card in cards do
					if not card.product.configured then
						card.state = "Unavailable"
						paint(card)
					else
						paint(card)
						task.spawn(function()
							local info = fetchInfo(card.product.id)
							if info then
								card.price = info.price
								card.title.Text = if info.name ~= "" then info.name else title(card.product)
								card.state = "Buy"
							else
								card.state = "Unavailable"
								loaded = false -- try again next open
							end
							paint(card)
						end)
					end
				end
			end

			return {
				open = function()
					load()
					local visible = {}
					for _, card in cards do
						table.insert(visible, card.gui :: GuiObject)
					end
					Motion.reveal(visible, C.panel)
				end,
				resize = function(_size: Vector2, compact: boolean)
					banner.Size = UDim2.new(1, 0, 0, if compact then 220 else 300)
					grid.shape(if compact then 260 else 320, if compact then 0.9 else 1.05, 3)
				end,
			}
		end
	)
end

return Shop
