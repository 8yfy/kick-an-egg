--!strict
-- Training shop (UI handoff SCREEN-SPEC "Training shop"; Figma "Training / Boxing Sacks"), paid with in-game
-- cash only. Two tabs:
--   Boxing Sacks: all 20 sacks of Config/Upgrades.Sack in ladder order. One main action per card:
--     Equipped (the sack you train with), Owned (an earlier sack, superseded), Buy (the next sack, affordable),
--     Insufficient (the next sack, price + how much is missing), Locked (buy the one before first),
--     Pending (request sent, waiting for the server) and Failed (inline error, card stays).
--     Buying the next sack is what the game does on UpgradeTraining: it becomes your sack right away.
--   Speed: Run Speed (= how fast your egg runs home), next value, level/cap, exact cost, Upgrade or Maxed.
--     One step per purchase (BuyUpgrade "RunSpeed"); no bulk buying because the server sells +1 at a time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local TrainingShop = {}

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

-- Glow behind the art by VFX step (Config/Upgrades.Sack.tiers[].fx), not by rarity.
local FX_GLOW: { [string]: Color3 } = {
	Basics = Color3.fromHex("C9CED8"),
	Comic = Color3.fromHex("FF8A3D"),
	Champion = Color3.fromHex("FFD84A"),
	Elemental = Color3.fromHex("53F0FF"),
	Mythic = Color3.fromHex("D95AFF"),
	God = Color3.fromHex("FFF16A"),
}

type Card = {
	tier: number,
	gui: Frame,
	stroke: UIStroke,
	art: Frame,
	info: Frame,
	button: Ui.Button,
	pill: Frame,
	pillLabel: TextLabel,
	note: TextLabel,
	failedUntil: number,
}

local function buildCard(parent: Instance, row: Data.SackRow, onBuy: (card: Card) -> ()): Card
	local card = Ui.panel(parent, "Sack" .. row.tier)
	card.LayoutOrder = row.tier
	local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	local content = Ui.frame(card, "Content")

	local art = Instance.new("Frame")
	art.Name = "ArtHolder"
	art.BackgroundColor3 = C.panelDeep
	art.BorderSizePixel = 0
	Ui.corner(art)
	Ui.stroke(art, 3)
	art.ClipsDescendants = true
	art.Parent = content
	local glow = FX_GLOW[row.fx] or FX_GLOW.Basics
	Ui.glow(art, glow, true)
	local artFrame = Ui.frame(art, "ArtFrame", UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.5, 0.5))
	artFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.sackArt(artFrame, row.tier)
	local chip = Ui.pill(art, "#" .. row.tier, "grey", UDim2.fromOffset(58, 32), 18)
	chip.Position = UDim2.fromOffset(8, 8)
	chip.ZIndex = 3

	local info = Ui.frame(content, "Info")
	local name = Ui.text(info, row.name, 28, { name = "Name" })
	name.Position = UDim2.new()
	local benefit =
		Ui.text(info, `+{Ui.number(row.gain)} Kick Power per kick`, 20, { color = C.power, name = "Benefit" })
	benefit.Position = UDim2.fromOffset(0, 38)
	local note = Ui.text(info, "", 18, { color = C.muted, name = "Note" })
	note.AnchorPoint = Vector2.new(0, 1)
	note.Position = UDim2.new(0, 0, 1, -64)

	local self: Card
	local button = Ui.button(info, {
		text = "BUY",
		gradient = "lime",
		size = UDim2.new(1, 0, 0, 56),
		textSize = 26,
		icon = "icon/cash",
		name = "Action",
		onClick = function()
			onBuy(self)
		end,
	})
	button.gui.AnchorPoint = Vector2.new(0, 1)
	button.gui.Position = UDim2.fromScale(0, 1)
	local pill, pillLabel = Ui.pill(info, "", "grey", UDim2.new(1, 0, 0, 56), 26)
	pill.AnchorPoint = Vector2.new(0, 1)
	pill.Position = UDim2.fromScale(0, 1)

	self = {
		tier = row.tier,
		gui = card,
		stroke = stroke,
		art = art,
		info = info,
		button = button,
		pill = pill,
		pillLabel = pillLabel,
		note = note,
		failedUntil = 0,
	}
	return self
end

-- Vertical card on wide screens, art-left card on short (phone) screens.
local function layoutCard(card: Card, compact: boolean)
	if compact then
		card.art.Position = UDim2.fromOffset(12, 12)
		card.art.Size = UDim2.new(0.42, -12, 1, -24)
		card.info.Position = UDim2.new(0.42, 14, 0, 14)
		card.info.Size = UDim2.new(0.58, -28, 1, -28)
	else
		card.art.Position = UDim2.fromOffset(12, 12)
		card.art.Size = UDim2.new(1, -24, 0.54, -12)
		card.info.Position = UDim2.new(0, 14, 0.54, 12)
		card.info.Size = UDim2.new(1, -28, 0.46, -26)
	end
end

local function paint(card: Card, row: Data.SackRow, pendingTier: number?, rows: { Data.SackRow })
	local button, pill = card.button, card.pill
	local failed = os.clock() < card.failedUntil
	card.stroke.Color = if row.state == "Equipped" then Theme.Gradients.lime[2] else C.stroke
	card.stroke.Thickness = if row.state == "Equipped" then 6 else Theme.Layout.stroke
	local showButton = row.state == "Buy" or row.state == "Insufficient"
	button.gui.Visible = showButton
	pill.Visible = not showButton
	card.note.TextColor3 = C.muted
	if row.state == "Equipped" then
		card.pillLabel.Text = "EQUIPPED"
		Ui.gradient(pill, "lime")
		card.note.Text = "Training with this sack"
	elseif row.state == "Owned" then
		card.pillLabel.Text = "OWNED"
		Ui.gradient(pill, "grey")
		card.note.Text = "Replaced by a stronger sack"
	elseif row.state == "Locked" then
		card.pillLabel.Text = "LOCKED"
		Ui.gradient(pill, "disabled")
		local prev = rows[row.tier - 1]
		card.note.Text = if prev then `Buy {prev.name} first` else ""
	else
		button.setText(Ui.money(row.cost))
		button.setEnabled(row.state == "Buy")
		button.setPending(pendingTier == row.tier, "BUYING...")
		if row.state == "Insufficient" then
			card.note.Text = `Need {Ui.money(row.cost - Data.money())} more`
			card.note.TextColor3 = C.power
		else
			card.note.Text = "Next sack"
		end
	end
	if failed then
		card.note.Text = "Purchase failed. Try again."
		card.note.TextColor3 = Theme.Gradients.red[1]
	end
end

local function buildSpeed(page: Frame, onUpgrade: () -> ()): (info: Data.SpeedInfo, pending: boolean) -> ()
	local panel = Ui.panel(page, "SpeedPanel")
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.fromScale(0.5, 0)
	panel.Size = UDim2.new(1, 0, 1, -8)
	local inner = Ui.frame(panel, "Inner", UDim2.new(1, -48, 1, -40), UDim2.fromOffset(24, 20))

	local head = Ui.frame(inner, "Head", UDim2.new(1, 0, 0, 96))
	local icon = Ui.icon(head, "icon/speed", 96, ">>")
	icon.Position = UDim2.new()
	local title = Ui.text(head, "Run Speed", 40, { name = "Title" })
	title.Position = UDim2.fromOffset(112, 6)
	title.Size = UDim2.new(1, -112, 0, 48)
	local sub = Ui.text(
		head,
		"How fast your egg runs home. Faster eggs survive farther zones.",
		20,
		{ color = C.muted, name = "Sub" }
	)
	sub.Position = UDim2.fromOffset(112, 56)
	sub.Size = UDim2.new(1, -112, 0, 28)

	local values = Ui.frame(inner, "Values", UDim2.new(1, 0, 0, 90), UDim2.fromOffset(0, 120))
	Ui.list(values, 22, true, Enum.HorizontalAlignment.Center)
	local now = Ui.text(values, "", 72, { autoX = true, stroke = 5, color = Theme.Gradients.cyan[1], name = "Now" })
	now.LayoutOrder = 1
	local arrow = Ui.text(values, ">", 56, { autoX = true, name = "Arrow" })
	arrow.LayoutOrder = 2
	local nextValue =
		Ui.text(values, "", 72, { autoX = true, stroke = 5, color = Theme.Gradients.lime[1], name = "Next" })
	nextValue.LayoutOrder = 3

	local bar = Ui.progress(inner, "cyan", 34)
	bar.gui.Position = UDim2.fromOffset(0, 230)

	local note = Ui.text(inner, "", 20, { color = C.muted, align = Enum.TextXAlignment.Center, name = "Note" })
	note.AnchorPoint = Vector2.new(0, 1)
	note.Position = UDim2.new(0, 0, 1, -80)

	local button = Ui.button(inner, {
		text = "UPGRADE",
		gradient = "lime",
		size = UDim2.fromOffset(420, 64),
		textSize = 28,
		icon = "icon/cash",
		name = "Upgrade",
		onClick = onUpgrade,
	})
	button.gui.AnchorPoint = Vector2.new(0.5, 1)
	button.gui.Position = UDim2.fromScale(0.5, 1)
	local maxPill = Ui.pill(inner, "MAXED", "grey", UDim2.fromOffset(420, 64), 28)
	maxPill.AnchorPoint = Vector2.new(0.5, 1)
	maxPill.Position = UDim2.fromScale(0.5, 1)

	return function(info: Data.SpeedInfo, pending: boolean)
		now.Text = tostring(info.current)
		arrow.Visible = not info.maxed
		nextValue.Visible = not info.maxed
		nextValue.Text = tostring(info.current + 1)
		local levels = info.max - info.base
		local level = info.current - info.base
		bar.set(level / math.max(1, levels), `Level {level} / {levels}`)
		button.gui.Visible = not info.maxed
		maxPill.Visible = info.maxed
		if info.maxed then
			note.Text = "Run Speed is maxed."
			note.TextColor3 = C.muted
		elseif info.cost then
			local short = info.cost - Data.money()
			button.setText("UPGRADE  " .. Ui.money(info.cost))
			button.setEnabled(short <= 0)
			button.setPending(pending, "UPGRADING...")
			note.Text = if short > 0 then `Need {Ui.money(short)} more` else "+1 Run Speed"
			note.TextColor3 = if short > 0 then C.power else C.muted
		end
	end
end

function TrainingShop.define()
	Modal.define(
		"Training",
		{ title = "Training", gradient = "orange", icon = "icon/training" },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local sacksPage: ScrollingFrame
			local speedPage: Frame
			local cards: { Card } = {}
			local rows: { Data.SackRow } = Data.sacks()
			local pendingTier: number? = nil
			local speedPending = false
			local stopFloat: (() -> ())? = nil
			local focalTier = 0
			local compact = false
			local scrolledOnce = false

			local function refresh()
				rows = Data.sacks()
				local focal = 0
				for _, row in rows do
					if row.state == "Buy" or row.state == "Insufficient" then
						focal = row.tier
					end
				end
				if focal == 0 then
					focal = Data.state.rackLevel or 1
				end
				for i, card in cards do
					paint(card, rows[i], pendingTier, rows)
				end
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
							Motion.flagError(card.stroke, C.stroke)
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

			local tabs = Ui.tabs(body, { "Boxing Sacks", "Speed" }, function(i: number)
				sacksPage.Visible = i == 1
				speedPage.Visible = i == 2
				if i == 1 then
					local visible = {}
					for n = 1, math.min(#cards, 6) do
						table.insert(visible, cards[n].gui :: GuiObject)
					end
					Motion.reveal(visible, C.panel)
				end
			end)
			tabs.gui.Position = UDim2.new()

			local pages = Ui.frame(body, "Pages", UDim2.new(1, 0, 1, -72), UDim2.fromOffset(0, 72))
			sacksPage = Ui.scroll(pages, "Sacks")
			Ui.padding(sacksPage, 6)
			local grid = Ui.grid(sacksPage, 340, 1.3, Theme.Layout.gap, 3)
			for _, row in rows do
				local card = buildCard(sacksPage, row, buy)
				layoutCard(card, false)
				table.insert(cards, card)
			end

			speedPage = Ui.frame(pages, "Speed")
			speedPage.Visible = false
			updateSpeed = buildSpeed(speedPage, upgradeSpeed)

			tabs.select(1)

			return {
				open = function()
					refresh()
					updateSpeed(Data.speed(), speedPending)
					if not scrolledOnce then
						scrolledOnce = true
						task.defer(function()
							local card = cards[focalTier]
							if card then -- first open: bring the next sack into view
								local delta = card.gui.AbsolutePosition.Y - sacksPage.AbsolutePosition.Y
								local y = delta / Ui.screenScale(sacksPage) + sacksPage.CanvasPosition.Y
								sacksPage.CanvasPosition = Vector2.new(0, math.max(0, y - 12))
							end
						end)
					end
				end,
				update = function()
					refresh()
					updateSpeed(Data.speed(), speedPending)
				end,
				resize = function(_size: Vector2, isCompact: boolean)
					compact = isCompact
					if compact then
						grid.shape(460, 0.5, 2)
					else
						grid.shape(340, 1.3, 3)
					end
					for _, card in cards do
						layoutCard(card, compact)
					end
				end,
				focus = function()
					local card = cards[focalTier]
					return if card and card.button.gui.Visible
						then card.button.gui
						else tabs.gui:FindFirstChild("Tab1") :: GuiObject?
				end,
			}
		end
	)
end

return TrainingShop
