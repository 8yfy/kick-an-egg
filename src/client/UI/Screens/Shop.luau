--!strict
-- Shop (UI handoff v2 01-Mockups/02-Developer-Product-Shop.png + VISUAL-CONTRACT "Shop composition"): Robux
-- developer products ONLY, from Economy.DevProducts (no gamepasses, sacks or speed, no invented offers or
-- scarcity). Acid-green header, one large feature banner (the biggest pack), then two equal secondary
-- offers, then any further products. Every banner is layered: supplied backdrop PNG (cropped) -> tinted
-- rays/glow -> separate hero PNG (floats gently on the feature banner) -> editable title/benefit text ->
-- price + CTA -> clipped shine.
-- CTA states: LOADING (price fetch), NOT ON SALE (product id 0 / info failed; the card keeps full art),
-- BUY R$ n, CHECK PROMPT (Roblox dialog open), DELIVERING (bought, waiting for the server to grant the cash),
-- granted (+$x added) and cancelled.
-- Shop.fixture(list) is for the dev preview only (tools/preview): it swaps in a clearly ribboned DESIGN
-- FIXTURE catalog to review populated layouts; the game never calls it.
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

export type Offer = {
	key: string,
	id: number, -- developer product id (0 = not created yet)
	money: number?, -- cash granted (cash packs)
	title1: string, -- big gradient line
	title2: string, -- white line
	benefit: string,
	backdrop: string, -- AssetIds key
	hero: string, -- AssetIds key
	accent: Theme.Pair, -- title gradient
	fixture: boolean?,
}

type State = "Loading" | "Unavailable" | "Buy" | "Prompting" | "Pending" | "Granted" | "Cancelled"
type Card = { offer: Offer, gui: Frame, button: Ui.Button, note: TextLabel, state: State, price: number? }

local fixtureList: { Offer }? = nil
function Shop.fixture(list: { Offer })
	fixtureList = list
end

-- Real catalog: the cash packs of Economy.DevProducts, biggest first.
local function catalog(): { Offer }
	if fixtureList then
		return fixtureList
	end
	local list: { Offer } = {}
	for _, p in Data.products() do
		table.insert(list, {
			key = p.key,
			id = p.id,
			money = p.money,
			title1 = Ui.money(p.money),
			title2 = "CASH PACK",
			benefit = `+{Ui.money(p.money)} cash, instantly`,
			backdrop = "banners_cash_background",
			hero = "premium_icons_currency_cash",
			accent = { Color3.fromHex("C8FF4A"), Color3.fromHex("3FD81A") },
		})
	end
	table.sort(list, function(a, b)
		return (a.money or 0) > (b.money or 0)
	end)
	return list
end

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

local function paint(card: Card)
	local b = card.button
	b.setPending(false)
	if card.state == "Loading" then
		b.setText("LOADING...")
		b.setEnabled(false)
	elseif card.state == "Unavailable" then
		b.setText("NOT ON SALE")
		b.setEnabled(false)
	elseif card.state == "Prompting" then
		b.setPending(true, "CHECK PROMPT")
	elseif card.state == "Pending" then
		b.setPending(true, "DELIVERING...")
	else
		b.setText(`BUY  R$ {card.price or 0}`)
		b.setEnabled(true)
	end
	card.note.Text = if card.state == "Granted" and card.offer.money
		then `+{Ui.money(card.offer.money)} added!`
		elseif card.state == "Cancelled" then "Purchase cancelled"
		elseif card.state == "Pending" then "Your cash is on the way"
		else ""
end

-- One layered banner. `feature` = the big top banner (title left, hero right, CTA bottom-right).
local function banner(parent: Instance, offer: Offer, order: number, feature: boolean, onBuy: (Card) -> ()): Card
	local f = Instance.new("Frame")
	f.Name = offer.key
	f.LayoutOrder = order
	f.BorderSizePixel = 0
	f.BackgroundColor3 = C.card
	f.ClipsDescendants = true
	Ui.corner(f)
	Ui.stroke(f, 5)
	f.Parent = parent

	local backdrop = Ui.cover(f, offer.backdrop) -- 1: supplied backdrop
	backdrop.ZIndex = 1
	local heroBox = Ui.frame(f, "HeroBox") -- 2: rays/glow + 3: separate hero art
	heroBox.ZIndex = 2
	if feature then
		heroBox.Size = UDim2.new(0.46, 0, 1.05, 0)
		heroBox.Position = UDim2.new(0.38, 0, -0.03, 0)
	else
		heroBox.Size = UDim2.new(0.52, 0, 1.0, 0)
		heroBox.Position = UDim2.new(0.46, 0, 0.02, 0)
	end
	local glow = Ui.glow(heroBox, Color3.fromHex("FFF6B0"), true, 0.95)
	local hero = Ui.frame(heroBox, "Hero", UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.5))
	hero.AnchorPoint = Vector2.new(0.5, 0.5)
	hero.ZIndex = 3
	Ui.art(hero, offer.hero).ZIndex = 3
	if feature then
		Motion.float(hero, glow)
	end

	-- 4: editable text layers (never baked into the art)
	local textBox = Ui.frame(f, "Text", UDim2.new(if feature then 0.42 else 0.5, 0, 1, -24), UDim2.fromOffset(28, 12))
	textBox.ZIndex = 4
	local t1 = Ui.text(textBox, offer.title1, if feature then 104 else 72, { stroke = 7, name = "Title1" })
	t1.Size = UDim2.new(1, 0, 0, if feature then 112 else 80)
	t1.ZIndex = 4
	local tg = Instance.new("UIGradient")
	tg.Rotation = 90
	tg.Color = ColorSequence.new(offer.accent[1], offer.accent[2])
	tg.Parent = t1
	local t2 = Ui.text(textBox, offer.title2, if feature then 64 else 48, { stroke = 6, name = "Title2" })
	t2.Position = UDim2.fromOffset(0, if feature then 106 else 74)
	t2.Size = UDim2.new(1, 0, 0, if feature then 72 else 56)
	t2.ZIndex = 4
	local benefit = Ui.text(textBox, offer.benefit, if feature then 30 else 24, { stroke = 3, name = "Benefit" })
	benefit.Position = UDim2.fromOffset(4, if feature then 184 else 134)
	benefit.Size = UDim2.new(1, 0, 0, 38)
	benefit.ZIndex = 4

	-- 5: price + CTA
	local self: Card
	local button = Ui.button(f, {
		text = "LOADING...",
		style = "lime",
		size = if feature then UDim2.fromOffset(380, 96) else UDim2.fromOffset(300, 78),
		textSize = if feature then 46 else 38,
		name = "Buy",
		onClick = function()
			onBuy(self)
		end,
	})
	button.gui.ZIndex = 5
	if feature then
		button.gui.AnchorPoint = Vector2.new(1, 1)
		button.gui.Position = UDim2.new(1, -28, 1, -28)
	else
		button.gui.AnchorPoint = Vector2.new(0, 1)
		button.gui.Position = UDim2.new(0, 24, 1, -22)
	end
	local note = Ui.text(f, "", 22, { stroke = 3, name = "Note", color = C.cash })
	note.AnchorPoint = Vector2.new(0, 1)
	note.Position = if feature then UDim2.new(0, 32, 1, -26) else UDim2.new(0, 28, 1, -104)
	note.Size = UDim2.new(0.5, 0, 0, 30)
	note.ZIndex = 5

	if offer.fixture then
		local rib = Ui.pill(f, "DESIGN FIXTURE · NOT FOR SALE", "red", UDim2.fromOffset(420, 40), 20)
		rib.AnchorPoint = Vector2.new(1, 0)
		rib.Position = UDim2.new(1, -16, 0, 14)
		rib.ZIndex = 6
	end
	Motion.shine(f) -- 6: clipped shine
	self = { offer = offer, gui = f, button = button, note = note, state = "Loading", price = nil }
	return self
end

function Shop.define()
	Modal.define("Shop", { title = "Shop", header = Theme.Headers.shop }, function(shell: Modal.Shell): Modal.Screen
		local body = shell.body
		local label = Ui.text(body, "Developer products", 24, { color = C.muted, name = "Section", stroke = 3 })
		label.Size = UDim2.new(1, 0, 0, 30)
		local scroll = Ui.scroll(body, "Products")
		scroll.Position = UDim2.fromOffset(0, 40)
		scroll.Size = UDim2.new(1, 0, 1, -40)
		Ui.padding(scroll, 6)
		Ui.list(scroll, 20)

		local cards: { Card } = {}
		local byId: { [number]: Card } = {}
		local busy: Card? = nil
		local offers = catalog()
		local compact = false

		local function onBuy(card: Card)
			if busy or card.state ~= "Buy" and card.state ~= "Granted" and card.state ~= "Cancelled" then
				return
			end
			busy = card
			card.state = "Prompting"
			paint(card)
			local ok = pcall(function()
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, card.offer.id)
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
				if
					not card
					or card.state ~= "Prompting"
					or userId ~= (Players.LocalPlayer and Players.LocalPlayer.UserId)
				then
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
				local amount = card.offer.money or 0
				Data.expect(
					function()
						return Data.money() >= before + amount
					end,
					30,
					function(granted: boolean)
						card.state = if granted then "Granted" else "Buy"
						paint(card)
						if granted then
							Modal.sfx("ShopPurchase") -- (a tier 3 sound: the toast chime under it is masked)
							Modal.toast(`+{Ui.money(amount)} cash!`, "good")
							Motion.burst(Modal.layer(), card.gui.AbsolutePosition + card.gui.AbsoluteSize / 2, "cash")
						else
							card.note.Text = "Still processing. Your cash will arrive soon."
						end
					end
				)
			end
		)

		-- Feature banner, then rows of two equal secondary offers.
		local rows: { Frame } = {}
		local feature: Frame? = nil
		for i, offer in offers do
			if i == 1 then
				local holder = Ui.frame(scroll, "Feature", UDim2.new(1, 0, 0, 360))
				holder.LayoutOrder = 1
				local card = banner(holder, offer, 1, true, onBuy)
				card.gui.Size = UDim2.fromScale(1, 1)
				table.insert(cards, card)
				feature = holder
			else
				local rowIndex = (i - 2) // 2
				if not rows[rowIndex + 1] then
					local newRow = Ui.frame(scroll, "Row" .. (rowIndex + 1), UDim2.new(1, 0, 0, 300))
					newRow.LayoutOrder = 2 + rowIndex
					table.insert(rows, newRow)
				end
				local row = rows[rowIndex + 1]
				local card = banner(row, offer, i, false, onBuy)
				table.insert(cards, card)
			end
			if offer.id ~= 0 then
				byId[offer.id] = cards[#cards]
			end
		end
		if #offers == 0 then
			Ui.text(scroll, "No products yet.", 28, { color = C.muted, align = Enum.TextXAlignment.Center }).LayoutOrder =
				9
		end

		local function place()
			if feature then
				feature.Size = UDim2.new(1, 0, 0, if compact then 300 else 360)
			end
			for _, row in rows do
				local kids = {}
				for _, k in row:GetChildren() do
					if k:IsA("Frame") then
						table.insert(kids, k)
					end
				end
				table.sort(kids, function(a, b)
					return a.LayoutOrder < b.LayoutOrder
				end)
				row.Size = UDim2.new(1, 0, 0, 300)
				for j, k in kids do
					k.Size = UDim2.new(0.5, -10, 1, 0)
					k.Position = UDim2.new((j - 1) * 0.5, (j - 1) * 10, 0, 0)
				end
			end
		end

		local loaded = false
		local function load()
			if loaded then
				return
			end
			loaded = true
			for _, card in cards do
				if card.offer.fixture then
					card.price = 99
					card.state = "Buy"
					paint(card)
				elseif card.offer.id == 0 then
					card.state = "Unavailable"
					paint(card)
				else
					paint(card)
					task.spawn(function()
						local info = fetchInfo(card.offer.id)
						if info then
							card.price = info.price
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
				Motion.reveal(visible, C.body)
			end,
			resize = function(_size: Vector2, isCompact: boolean)
				compact = isCompact
				place()
			end,
		}
	end)
end

return Shop
