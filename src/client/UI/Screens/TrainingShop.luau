--!strict
-- Training Shop (UI handoff v2 01-Mockups/06-Training-Shop.png + VISUAL-CONTRACT "Training card construction"),
-- paid with in-game cash. Purple/pink header, BOXING SACKS / SPEED tabs, cash footer.
--   Boxing Sacks: the 20 sacks of Config/Upgrades.Sack in catalog order, 3 art-led cards per row on desktop
--     (4 smaller ones on phones). Each card: name, tier, the supplied sack PNG large on a stud gradient in the
--     sack's own material colour (sampled from its PNG, not a rarity), the real kick-power gain and ONE action:
--     EQUIPPED (the sack you train with) / OWNED (an earlier sack, superseded) / BUY $x (the next sack) /
--     the same price disabled when you can't afford it / LOCKED (buy the one before first) / BUYING... while
--     the request is pending / an inline error if it fails. Buying makes the new sack yours right away
--     (that is what UpgradeTraining does).
--   Speed: Run Speed (= how fast your egg runs home), next value, level (no cap: each level adds a little less,
--   approaching Economy.RunSpeed.max), exact price, UPGRADE.
--     One step per purchase (BuyUpgrade "RunSpeed"); no bulk buying: the server sells +1 at a time.
-- Cards are authored at the contract's reference size (444 x 566) and scaled as a whole to the grid cell.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local System = script.Parent.Parent.System
local AssetIds = require(System.AssetIds)
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local TrainingShop = {}

local CARD = Vector2.new(444, 566)
local CARD_WIDE = Vector2.new(640, 300) -- phones

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

type Card = {
	tier: number,
	gui: Frame,
	content: Frame,
	scale: UIScale,
	stroke: UIStroke,
	art: Frame,
	sub: TextLabel,
	buy: Ui.Button,
	price: TextLabel,
	priceIcon: Frame,
	pill: Frame,
	pillLabel: TextLabel,
	pillIcon: Frame,
	failedUntil: number,
	layout: (compact: boolean) -> (),
}

local function buildCard(parent: Instance, row: Data.SackRow, onBuy: (card: Card) -> ()): Card
	local accent = Theme.SackAccent[row.name] or Theme.Buttons.grey
	local card = Instance.new("Frame")
	card.Name = "Sack" .. row.tier
	card.LayoutOrder = row.tier
	card.BackgroundTransparency = 1
	card.Parent = parent

	-- The whole card is authored at CARD size inside `content` and scaled to the cell.
	local content = Ui.frame(card, "Content", UDim2.fromOffset(CARD.X, CARD.Y))
	local scale = Instance.new("UIScale")
	scale.Parent = content
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.ClipsDescendants = true
	Ui.corner(bg)
	if row.name == "Rainbow God" then
		Ui.fill(bg, {
			Color3.fromHex("FF6A8A"),
			Color3.fromHex("FFD34A"),
			Color3.fromHex("5BE07A"),
			Color3.fromHex("4FA8FF"),
			Color3.fromHex("B65CFF"),
		}, 120)
	else
		Ui.fill(bg, accent)
	end
	local stroke = Ui.stroke(bg, 5)
	Ui.studs(bg, Theme.Studs.card)
	bg.Parent = content
	local shade = Instance.new("Frame") -- darker foot so the action reads on every accent
	shade.Name = "Shade"
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BorderSizePixel = 0
	shade.AnchorPoint = Vector2.new(0, 1)
	shade.Position = UDim2.fromScale(0, 1)
	shade.Size = UDim2.new(1, 0, 0, 170)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Transparency = NumberSequence.new(1, 0.45)
	g.Parent = shade
	shade.Parent = bg

	-- Art well: rays + glow behind the supplied PNG (Fit, white tint), big.
	local art = Ui.frame(bg, "ArtWell", UDim2.new(1, -16, 0, 326), UDim2.fromOffset(8, 84))
	Ui.glow(art, accent[1]:Lerp(Color3.new(1, 1, 1), 0.45), true, 0.95)
	local key = AssetIds.sack(row.name)
	local artFrame = Ui.frame(art, "ArtFrame", UDim2.fromScale(0.95, 0.95), UDim2.fromScale(0.5, 0.5))
	artFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	artFrame.ZIndex = 2
	Ui.art(artFrame, key or ("sack:" .. row.name)).ZIndex = 2

	local name = Ui.text(bg, row.name, 38, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Name" })
	name.Position = UDim2.fromOffset(10, 8)
	name.Size = UDim2.new(1, -20, 0, 46)
	name.ZIndex = 3
	local sub = Ui.text(bg, "", 22, { align = Enum.TextXAlignment.Center, stroke = 3, name = "Sub" })
	sub.Position = UDim2.fromOffset(10, 52)
	sub.Size = UDim2.new(1, -20, 0, 28)
	sub.ZIndex = 3
	local benefit = Ui.text(bg, `+{Ui.number(row.gain)} Kick Power per kick, up to {Ui.number(row.cap)}`, 24, {
		align = Enum.TextXAlignment.Center,
		stroke = 3,
		name = "Benefit",
	})
	benefit.Position = UDim2.fromOffset(10, 412)
	benefit.Size = UDim2.new(1, -20, 0, 36)
	benefit.ZIndex = 3

	local self: Card
	local buy = Ui.button(bg, {
		text = "BUY",
		style = "lime",
		size = UDim2.new(1, -28, 0, 64),
		textSize = 34,
		name = "Buy",
		onClick = function()
			onBuy(self)
		end,
	})
	buy.gui.AnchorPoint = Vector2.new(0.5, 1)
	buy.gui.Position = UDim2.new(0.5, 0, 1, -16)
	buy.gui.ZIndex = 3
	local row2 = buy.gui:FindFirstChild("Content") :: Frame
	local priceIcon = Ui.frame(row2, "CashIcon", UDim2.fromOffset(52, 52))
	priceIcon.LayoutOrder = 3
	Ui.art(priceIcon, "premium_icons_currency_cash").ZIndex = 2
	local price = Ui.text(row2, "", 34, { autoX = true, stroke = 3, name = "Price" })
	price.LayoutOrder = 4
	price.ZIndex = 2

	local pill, pillLabel = Ui.pill(bg, "", "dark", UDim2.new(1, -28, 0, 64), 34)
	pill.AnchorPoint = Vector2.new(0.5, 1)
	pill.Position = UDim2.new(0.5, 0, 1, -16)
	pill.ZIndex = 3
	local pillRow = pill:FindFirstChild("Content") :: Frame
	local pillIcon = Ui.frame(pillRow, "Lock", UDim2.fromOffset(44, 44))
	pillIcon.LayoutOrder = 0
	Ui.art(pillIcon, "icon_lock")

	self = {
		tier = row.tier,
		gui = card,
		content = content,
		scale = scale,
		stroke = stroke,
		art = art,
		sub = sub,
		buy = buy,
		price = price,
		priceIcon = priceIcon,
		pill = pill,
		pillLabel = pillLabel,
		pillIcon = pillIcon,
		failedUntil = 0,
		layout = function(compact: boolean)
			-- desktop: tall art-led card; phones: wide card (art left, text + action right) so the action
			-- is always on screen without scrolling inside a card
			local size = if compact then CARD_WIDE else CARD
			content.Size = UDim2.fromOffset(size.X, size.Y)
			local center = if compact then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
			name.TextXAlignment, sub.TextXAlignment, benefit.TextXAlignment = center, center, center
			if compact then
				art.Size = UDim2.new(0.44, -8, 1, -16)
				art.Position = UDim2.fromOffset(8, 8)
				name.Position = UDim2.new(0.46, 4, 0, 14)
				name.Size = UDim2.new(0.54, -16, 0, 46)
				sub.Position = UDim2.new(0.46, 4, 0, 60)
				sub.Size = UDim2.new(0.54, -16, 0, 28)
				benefit.Position = UDim2.new(0.46, 4, 0, 98)
				benefit.Size = UDim2.new(0.54, -16, 0, 36)
				for _, gui in { buy.gui :: GuiObject, pill } do
					gui.AnchorPoint = Vector2.new(1, 1)
					gui.Position = UDim2.new(1, -14, 1, -16)
					gui.Size = UDim2.new(0.54, -22, 0, 64)
				end
			else
				art.Size = UDim2.new(1, -16, 0, 326)
				art.Position = UDim2.fromOffset(8, 84)
				name.Position = UDim2.fromOffset(10, 8)
				name.Size = UDim2.new(1, -20, 0, 46)
				sub.Position = UDim2.fromOffset(10, 52)
				sub.Size = UDim2.new(1, -20, 0, 28)
				benefit.Position = UDim2.fromOffset(10, 412)
				benefit.Size = UDim2.new(1, -20, 0, 36)
				for _, gui in { buy.gui :: GuiObject, pill } do
					gui.AnchorPoint = Vector2.new(0.5, 1)
					gui.Position = UDim2.new(0.5, 0, 1, -16)
					gui.Size = UDim2.new(1, -28, 0, 64)
				end
			end
		end,
	}
	return self
end

local function paint(card: Card, row: Data.SackRow, pendingTier: number?, rows: { Data.SackRow })
	local failed = os.clock() < card.failedUntil
	local showBuy = row.state == "Buy" or row.state == "Insufficient"
	card.buy.gui.Visible = showBuy
	card.pill.Visible = not showBuy
	card.pillIcon.Visible = row.state == "Locked"
	card.sub.Text = `TIER {row.tier}`
	card.sub.TextColor3 = C.text
	if row.state == "Equipped" then
		card.pillLabel.Text = "EQUIPPED"
		card.pillLabel.TextColor3 = Theme.Buttons.lime[1]
		Ui.fill(card.pill, Theme.Buttons.grey)
	elseif row.state == "Owned" then
		card.pillLabel.Text = "OWNED"
		card.pillLabel.TextColor3 = C.text
		Ui.fill(card.pill, Theme.Buttons.dark)
	elseif row.state == "Locked" then
		card.pillLabel.Text = "LOCKED"
		card.pillLabel.TextColor3 = C.muted
		Ui.fill(card.pill, Theme.Buttons.dark)
		local prev = rows[row.tier - 1]
		card.sub.Text = if prev then `TIER {row.tier} · after {prev.name}` else `TIER {row.tier}`
	else
		local pending = pendingTier == row.tier
		card.price.Text = Ui.money(row.cost)
		card.buy.setEnabled(row.state == "Buy")
		card.buy.setPending(pending, "BUYING...")
		card.priceIcon.Visible = not pending
		card.price.Visible = not pending
		if row.state == "Insufficient" then
			card.sub.Text = `NEED {Ui.money(row.cost - Data.money())} MORE`
			card.sub.TextColor3 = C.power
		end
	end
	if failed then
		card.sub.Text = "PURCHASE FAILED · TRY AGAIN"
		card.sub.TextColor3 = C.danger
	end
end

-- Speed tab ------------------------------------------------------------------------------------------------

local function buildSpeed(
	page: Frame,
	onUpgrade: () -> ()
): ((info: Data.SpeedInfo, pending: boolean) -> (), (compact: boolean) -> ())
	local panel = Instance.new("Frame")
	panel.Name = "SpeedCard"
	panel.Size = UDim2.new(1, 0, 1, -6)
	panel.BorderSizePixel = 0
	panel.ClipsDescendants = true
	Ui.corner(panel)
	Ui.fill(panel, { Color3.fromHex("49C9FF"), Color3.fromHex("1A3FA8") })
	Ui.stroke(panel, 5)
	Ui.studs(panel, Theme.Studs.card)
	panel.Parent = page

	local hero = Ui.frame(panel, "Hero", UDim2.new(0.4, 0, 1, -40), UDim2.fromOffset(20, 20))
	Ui.glow(hero, Color3.fromHex("BFF4FF"), true, 0.9)
	local heroArt = Ui.frame(hero, "ArtFrame", UDim2.fromScale(0.82, 0.82), UDim2.fromScale(0.5, 0.5))
	heroArt.AnchorPoint = Vector2.new(0.5, 0.5)
	heroArt.ZIndex = 2
	Ui.art(heroArt, "premium_icons_nav_eggs").ZIndex = 2

	local info = Ui.frame(panel, "Info", UDim2.new(0.6, -50, 1, -40), UDim2.new(0.4, 30, 0, 20))
	local title = Ui.text(info, "RUN SPEED", 56, { stroke = 5, name = "Title" })
	title.Size = UDim2.new(1, 0, 0, 66)
	local sub = Ui.text(info, "How fast your egg runs home. Faster eggs survive farther zones.", 24, {
		wrap = true,
		name = "Sub",
	})
	sub.Position = UDim2.fromOffset(0, 70)
	local values = Ui.frame(info, "Values", UDim2.new(1, 0, 0, 110), UDim2.fromOffset(0, 140))
	Ui.list(values, 22, true)
	local now = Ui.text(values, "", 96, { autoX = true, stroke = 6, name = "Now" })
	now.LayoutOrder = 1
	local arrow = Ui.text(values, "→", 72, { autoX = true, stroke = 5, name = "Arrow" })
	arrow.LayoutOrder = 2
	local nextValue =
		Ui.text(values, "", 96, { autoX = true, stroke = 6, color = Theme.Buttons.lime[1], name = "Next" })
	nextValue.LayoutOrder = 3
	local barHolder = Ui.frame(info, "Bar", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 270))
	local bar = Ui.progress(barHolder, Theme.Buttons.lime, 44, 26)
	local note = Ui.text(info, "", 24, { name = "Note" })
	note.Position = UDim2.fromOffset(0, 326)

	local button = Ui.button(info, {
		text = "UPGRADE",
		style = "lime",
		size = UDim2.new(1, 0, 0, 72),
		textSize = 38,
		name = "Upgrade",
		onClick = onUpgrade,
	})
	button.gui.AnchorPoint = Vector2.new(0, 1)
	button.gui.Position = UDim2.fromScale(0, 1)
	local bRow = button.gui:FindFirstChild("Content") :: Frame
	local bIcon = Ui.frame(bRow, "CashIcon", UDim2.fromOffset(56, 56))
	bIcon.LayoutOrder = 3
	Ui.art(bIcon, "premium_icons_currency_cash").ZIndex = 2
	local bPrice = Ui.text(bRow, "", 38, { autoX = true, stroke = 3, name = "Price" })
	bPrice.LayoutOrder = 4
	bPrice.ZIndex = 2
	local maxPill = Ui.pill(info, "MAXED", "grey", UDim2.new(1, 0, 0, 72), 38)
	maxPill.AnchorPoint = Vector2.new(0, 1)
	maxPill.Position = UDim2.fromScale(0, 1)

	local function update(info2: Data.SpeedInfo, pending: boolean)
		now.Text = tostring(info2.current)
		arrow.Visible = not info2.maxed
		nextValue.Visible = not info2.maxed
		nextValue.Text = tostring(info2.nextSpeed)
		-- no level cap: the bar shows how close the speed is to the top speed every level approaches
		bar.set(
			(info2.current - info2.base) / math.max(1, info2.max - info2.base),
			`LEVEL {info2.level}  ·  TOP SPEED {info2.max}`
		)
		button.gui.Visible = not info2.maxed
		maxPill.Visible = info2.maxed
		if info2.maxed then
			note.Text = "Run Speed is maxed."
			note.TextColor3 = C.text
		elseif info2.cost then
			local short = info2.cost - Data.money()
			bPrice.Text = Ui.money(info2.cost)
			button.setEnabled(short <= 0)
			button.setPending(pending, "UPGRADING...")
			bIcon.Visible = not pending
			bPrice.Visible = not pending
			local step = math.floor((info2.nextSpeed - info2.current) * 10 + 0.5) / 10
			note.Text = if short > 0 then `Need {Ui.money(short)} more` else `+{step} Run Speed per upgrade`
			note.TextColor3 = if short > 0 then C.power else C.text
		end
	end
	local function layout(compact: boolean)
		hero.Visible = not compact
		info.Size = if compact then UDim2.new(1, -40, 1, -40) else UDim2.new(0.6, -50, 1, -40)
		info.Position = if compact then UDim2.fromOffset(20, 20) else UDim2.new(0.4, 30, 0, 20)
	end
	return update, layout
end

function TrainingShop.define()
	Modal.define(
		"Training",
		{ title = "Training Shop", header = Theme.Headers.training, footer = true },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local footer = shell.footer :: Frame
			local sacksPage: ScrollingFrame
			local speedPage: Frame
			local cards: { Card } = {}
			local rows: { Data.SackRow } = Data.sacks()
			local pendingTier: number? = nil
			local speedPending = false
			local stopFloat: (() -> ())? = nil
			local focalTier = 0
			local scrolledOnce = false
			local wide = false

			-- Footer: your cash + what you are training with.
			local cashIcon = Ui.frame(footer, "CashIcon", UDim2.fromOffset(70, 70), UDim2.fromOffset(0, -1))
			Ui.art(cashIcon, "premium_icons_currency_cash")
			local cash = Ui.text(footer, "", 46, { autoX = true, stroke = 4, color = C.cash, name = "Cash" })
			cash.Position = UDim2.fromOffset(80, 6)
			local sep = Instance.new("Frame")
			sep.Name = "Separator"
			sep.BackgroundColor3 = C.cardEdge
			sep.BorderSizePixel = 0
			sep.Size = UDim2.fromOffset(3, 46)
			sep.Position = UDim2.fromOffset(330, 12)
			sep.Parent = footer
			local trainingNote = Ui.text(footer, "", 24, { color = C.muted, name = "Note", stroke = 2 })
			trainingNote.Position = UDim2.fromOffset(356, 15)
			trainingNote.Size = UDim2.new(1, -356, 0, 34)

			local function refresh()
				rows = Data.sacks()
				local focal = 0
				local equipped: Data.SackRow? = nil
				for _, row in rows do
					if row.state == "Buy" or row.state == "Insufficient" then
						focal = row.tier
					elseif row.state == "Equipped" then
						equipped = row
					end
				end
				if focal == 0 then
					focal = if equipped then equipped.tier else 1
				end
				for i, card in cards do
					paint(card, rows[i], pendingTier, rows)
				end
				cash.Text = Ui.money(Data.money())
				trainingNote.Text = if equipped
					then `Training with {equipped.name}: +{Ui.number(equipped.gain)} Kick Power per kick`
					else "Train with your equipped sack"
				if focal ~= focalTier then
					focalTier = focal
					if stopFloat then
						stopFloat()
					end
					local card = cards[focal]
					local frame = card and card.art:FindFirstChild("ArtFrame")
					stopFloat = if frame and frame:IsA("GuiObject")
						then Motion.float(frame, card.art:FindFirstChild("Glow") :: GuiObject?)
						else nil
				end
			end

			local updateSpeed: (info: Data.SpeedInfo, pending: boolean) -> ()
			local layoutSpeed: (compact: boolean) -> ()

			local function buy(card: Card)
				local row = rows[card.tier]
				if pendingTier or not row or row.state ~= "Buy" then
					return
				end
				pendingTier = card.tier
				refresh()
				remote("UpgradeTraining"):FireServer()
				Data.expect(
					function()
						return (Data.state.rackLevel or 1) >= card.tier
					end,
					5,
					function(ok: boolean)
						pendingTier = nil
						if ok then
							Modal.toast(`{row.name} equipped!`, "good")
							local abs = card.art.AbsolutePosition + card.art.AbsoluteSize / 2
							Motion.burst(Modal.layer(), abs, "sparkle")
						else
							card.failedUntil = os.clock() + 3
							Motion.flagError(card.stroke, C.border)
							task.delay(3.1, refresh)
						end
						refresh()
					end
				)
			end

			local function upgradeSpeed()
				local info = Data.speed()
				if speedPending or info.maxed or not info.cost or Data.money() < info.cost then
					return
				end
				speedPending = true
				updateSpeed(info, true)
				remote("BuyUpgrade"):FireServer("RunSpeed")
				local before = info.current
				Data.expect(
					function()
						return (Data.state.runSpeed or 0) > before
					end,
					5,
					function(ok: boolean)
						speedPending = false
						updateSpeed(Data.speed(), false)
						if ok then
							Modal.toast(`Run Speed {Data.speed().current}!`, "good")
						else
							Modal.toast("Upgrade failed. Try again.", "error")
						end
					end
				)
			end

			local tabs = Ui.tabs(
				body,
				{ "Boxing Sacks", "Speed" },
				{ "premium_icons_nav_training", "premium_icons_nav_eggs" },
				Theme.Headers.training,
				function(i: number)
					sacksPage.Visible = i == 1
					speedPage.Visible = i == 2
					if i == 1 then
						local visible = {}
						for n = 1, math.min(#cards, 6) do
							table.insert(visible, cards[n].gui :: GuiObject)
						end
						Motion.reveal(visible, C.body)
					end
				end
			)

			local pages = Ui.frame(body, "Pages", UDim2.new(1, 0, 1, -72), UDim2.fromOffset(0, 72))
			sacksPage = Ui.scroll(pages, "Sacks")
			Ui.padding(sacksPage, 6)
			local grid = Ui.grid(sacksPage, 400, CARD.Y / CARD.X, Theme.Layout.gap, 3)
			for _, row in rows do
				table.insert(cards, buildCard(sacksPage, row, buy))
			end
			local function rescale()
				local w = grid.layout.CellSize.X.Offset
				for _, card in cards do
					card.scale.Scale = w / (if wide then CARD_WIDE.X else CARD.X)
				end
			end
			grid.layout:GetPropertyChangedSignal("CellSize"):Connect(rescale)

			speedPage = Ui.frame(pages, "Speed")
			speedPage.Visible = false
			updateSpeed, layoutSpeed = buildSpeed(speedPage, upgradeSpeed)

			tabs.select(1)

			return {
				open = function()
					refresh()
					updateSpeed(Data.speed(), speedPending)
					if not scrolledOnce then
						scrolledOnce = true
						task.defer(function()
							-- first open: scroll so the next sack's row is the top row (computed from the grid, not from
							-- AbsolutePosition, which is stale while the modal animates in)
							local cols = math.max(1, grid.columns())
							local rowIndex = (focalTier - 1) // cols
							if rowIndex > 0 then
								local cellH = grid.layout.CellSize.Y.Offset + Theme.Layout.gap
								sacksPage.CanvasPosition = Vector2.new(0, rowIndex * cellH)
							end
						end)
					end
				end,
				update = function()
					refresh()
					updateSpeed(Data.speed(), speedPending)
				end,
				resize = function(_size: Vector2, compact: boolean)
					wide = compact
					for _, card in cards do
						card.layout(compact)
					end
					if compact then
						grid.shape(560, CARD_WIDE.Y / CARD_WIDE.X, 2)
					else
						grid.shape(400, CARD.Y / CARD.X, 3)
					end
					rescale()
					layoutSpeed(compact)
				end,
				focus = function()
					local card = cards[focalTier]
					return if card and card.buy.gui.Visible
						then card.buy.gui
						else tabs.gui:FindFirstChild("Tab1") :: GuiObject?
				end,
			}
		end
	)
end

return TrainingShop
