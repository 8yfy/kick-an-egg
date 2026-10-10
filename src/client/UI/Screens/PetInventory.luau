--!strict
-- Sell Pets / inventory (UI handoff v2 01-Mockups/04-Sell-Pets.png). Green header, left sidebar (Sort By:
-- Value / Income / Rarity / Name, SELECT ALL, "Hide on pedestal"), a 4-column grid of pet cards (name, live 3D
-- pet, sale value bar, check badge when selected), footer "N SELECTED | TOTAL $x | SELL SELECTED" and a
-- CONFIRMATION panel. No Weight sort: the game has no pet weight.
-- Pets on a pedestal are PROTECTED (they earn money): marked ON PEDESTAL, skipped by SELECT ALL and hideable;
-- you can still pick one by hand, and selling it pays out its stored cash exactly as the server does. Values
-- use the server's rule (Data.PetRow.sellValue). Sell -> confirmation with the exact count and total ->
-- Remotes.SellPets -> the server's PetsSold reply. Nothing is removed until the server says so
-- (DataChanged); on failure the selection stays and an inline error shows.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local PetInventory = {}

local MAX_BATCH = 100 -- TradeService MAX_SELL_BATCH
local SIDEBAR = 250
local SORTS = { "Value", "Income", "Rarity", "Name" }

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

type Card = {
	row: Data.PetRow,
	gui: TextButton,
	stroke: UIStroke,
	check: Frame,
	tag: Frame,
	value: TextLabel,
}

function PetInventory.define()
	Modal.define(
		"Inventory",
		{ title = "Sell Pets", header = Theme.Headers.sell, icon = "premium_icons_nav_pets", footer = true },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local footer = shell.footer :: Frame
			local cards: { [string]: Card } = {}
			local selected: { [string]: boolean } = {}
			local sortIndex = 1
			local hideProtected = false
			local sending = false
			local errorText = ""
			local refresh: () -> ()
			local paintFooter: () -> ()

			-- Sidebar ---------------------------------------------------------------------------------------
			local side = Ui.surface(body, "Sidebar", C.card, Theme.Studs.body, 4)
			side.Size = UDim2.new(0, SIDEBAR, 1, 0)
			local sideList = Ui.frame(side, "Items", UDim2.new(1, -24, 1, -24), UDim2.fromOffset(12, 12))
			Ui.list(sideList, 12)
			local sortTitle = Ui.text(sideList, "Sort By:", 30, { stroke = 3, name = "SortTitle" })
			sortTitle.LayoutOrder = 0
			local sortButtons: { Ui.Button } = {}
			local function paintSort()
				for i, b in sortButtons do
					b.setStyle(if i == sortIndex then "lime" else "dark")
				end
			end
			for i, name in SORTS do
				local b = Ui.button(sideList, {
					text = string.upper(name) .. (if i == 1 or i == 2 or i == 3 then "  ↓" else "  A-Z"),
					style = "dark",
					size = UDim2.new(1, 0, 0, 58),
					textSize = 24,
					name = "Sort" .. name,
					onClick = function()
						sortIndex = i
						paintSort()
						refresh()
					end,
				})
				b.gui.LayoutOrder = i
				table.insert(sortButtons, b)
			end
			paintSort()
			local selectAll = Ui.button(sideList, {
				text = "SELECT ALL",
				style = "lime",
				size = UDim2.new(1, 0, 0, 62),
				textSize = 26,
				icon = "icon_check",
				name = "SelectAll",
				onClick = function()
					if sending then
						return
					end
					local n = 0
					for _ in selected do
						n += 1
					end
					for uid, card in cards do
						if n >= MAX_BATCH then
							break
						end
						-- every shown, unprotected pet (pets on pedestals are skipped by default)
						if card.gui.Visible and card.row.slot == nil and not selected[uid] then
							selected[uid] = true
							n += 1
						end
					end
					refresh()
				end,
			})
			selectAll.gui.LayoutOrder = 10
			local divider = Instance.new("Frame")
			divider.Name = "Divider"
			divider.BackgroundColor3 = C.cardEdge
			divider.BorderSizePixel = 0
			divider.Size = UDim2.new(1, 0, 0, 4)
			divider.LayoutOrder = 11
			divider.Parent = sideList
			local hideRow = Instance.new("TextButton")
			hideRow.Name = "HideProtected"
			hideRow.Text = ""
			hideRow.BackgroundTransparency = 1
			hideRow.Size = UDim2.new(1, 0, 0, 52)
			hideRow.LayoutOrder = 12
			hideRow.Parent = sideList
			local box = Instance.new("Frame")
			box.Name = "Box"
			box.Size = UDim2.fromOffset(42, 42)
			box.Position = UDim2.fromOffset(0, 5)
			box.BackgroundColor3 = C.tabIdle
			Ui.corner(box, 6)
			Ui.stroke(box, 4)
			box.Parent = hideRow
			local boxCheck = Ui.frame(box, "Check", UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.05, 0.05))
			Ui.art(boxCheck, "icon_check")
			boxCheck.Visible = false
			local hideLabel = Ui.text(hideRow, "Hide on pedestal", 22, { stroke = 3, name = "Label" })
			hideLabel.Position = UDim2.fromOffset(54, 9)
			hideLabel.Size = UDim2.new(1, -54, 0, 34)
			hideRow.Activated:Connect(function()
				hideProtected = not hideProtected
				boxCheck.Visible = hideProtected
				Motion.popIn(boxCheck)
				refresh()
			end)
			local count = Ui.text(sideList, "", 20, { color = C.muted, wrap = true, name = "Count" })
			count.LayoutOrder = 13

			-- Grid ------------------------------------------------------------------------------------------
			local scroll = Ui.scroll(body, "Pets")
			scroll.Position = UDim2.fromOffset(SIDEBAR + 20, 0)
			scroll.Size = UDim2.new(1, -(SIDEBAR + 20), 1, 0)
			Ui.padding(scroll, 6)
			local grid = Ui.grid(scroll, 240, 1.0, 16, 4)
			local empty = Ui.text(body, "No pets yet. Secure eggs and let them hatch!", 28, {
				color = C.muted,
				align = Enum.TextXAlignment.Center,
				name = "Empty",
				stroke = 3,
			})
			empty.Position = UDim2.new(0, SIDEBAR + 20, 0.45, 0)
			empty.Size = UDim2.new(1, -(SIDEBAR + 20), 0, 40)
			empty.Visible = false

			-- Footer: N SELECTED | TOTAL $x | SELL SELECTED --------------------------------------------------
			local selRow = Ui.frame(footer, "SelectedRow", UDim2.fromOffset(320, 66), UDim2.fromOffset(4, 0))
			Ui.list(selRow, 12, true)
			local nSel = Ui.text(selRow, "0", 54, { autoX = true, stroke = 5, color = C.cash, name = "Count" })
			nSel.LayoutOrder = 1
			Ui.text(selRow, "SELECTED", 40, { autoX = true, stroke = 4, name = "Selected" }).LayoutOrder = 2
			local sep = Instance.new("Frame")
			sep.Name = "Separator"
			sep.BackgroundColor3 = C.cardEdge
			sep.BorderSizePixel = 0
			sep.Size = UDim2.fromOffset(3, 50)
			sep.Position = UDim2.fromOffset(330, 9)
			sep.Parent = footer
			local totalLabel = Ui.text(footer, "TOTAL:", 36, { autoX = true, stroke = 4, name = "TotalLabel" })
			totalLabel.Position = UDim2.fromOffset(356, 10)
			local totalIcon = Ui.frame(footer, "CashIcon", UDim2.fromOffset(64, 64), UDim2.fromOffset(500, 1))
			Ui.art(totalIcon, "premium_icons_currency_cash")
			local total = Ui.text(footer, "$0", 50, { autoX = true, stroke = 5, color = C.cash, name = "Total" })
			total.Position = UDim2.fromOffset(572, 2)
			local errorLabel = Ui.text(footer, "", 19, { color = C.danger, name = "Error", stroke = 2 })
			errorLabel.AnchorPoint = Vector2.new(1, 0)
			errorLabel.Position = UDim2.new(1, -440, 0, 20)
			errorLabel.Size = UDim2.fromOffset(300, 28)
			errorLabel.TextXAlignment = Enum.TextXAlignment.Right
			local openConfirm: () -> ()
			local sell = Ui.button(footer, {
				text = "SELL SELECTED",
				style = "lime",
				size = UDim2.fromOffset(420, 66),
				textSize = 36,
				name = "Sell",
				onClick = function()
					openConfirm()
				end,
			})
			sell.gui.AnchorPoint = Vector2.new(1, 0.5)
			sell.gui.Position = UDim2.new(1, 0, 0.5, 0)

			-- Confirmation panel ----------------------------------------------------------------------------
			local confirm = Ui.frame(shell.panel, "Confirm")
			confirm.ZIndex = 40
			confirm.Visible = false
			local dim = Instance.new("TextButton")
			dim.Name = "Dim"
			dim.Text = ""
			dim.AutoButtonColor = false
			dim.Selectable = false
			dim.BackgroundColor3 = C.scrim
			dim.BackgroundTransparency = 0.45
			dim.Size = UDim2.fromScale(1, 1)
			Ui.corner(dim)
			dim.Parent = confirm
			local cbox = Ui.surface(confirm, "Box", C.body, Theme.Studs.body, 5)
			cbox.AnchorPoint = Vector2.new(0.5, 0.5)
			cbox.Position = UDim2.fromScale(0.5, 0.5)
			cbox.Size = UDim2.fromOffset(520, 470)
			local ch = Ui.header(cbox, Theme.Headers.confirm, "Confirmation", nil, 70, 38)
			ch.gui.ZIndex = 2
			local cbX: TextButton
			cbX = Ui.closeButton(cbox, function()
				if not sending then
					confirm.Visible = false
				end
			end, 54)
			cbX.AnchorPoint = Vector2.new(1, 0)
			cbX.Position = UDim2.new(1, -8, 0, 8)
			cbX.ZIndex = 5
			local q = Ui.text(cbox, "", 40, { align = Enum.TextXAlignment.Center, stroke = 4, name = "Question" })
			q.Position = UDim2.fromOffset(10, 86)
			q.Size = UDim2.new(1, -20, 0, 50)
			local cIcon = Ui.frame(cbox, "CashIcon", UDim2.fromOffset(120, 120), UDim2.new(0.5, -60, 0, 136))
			Ui.art(cIcon, "premium_icons_currency_cash")
			local cTotal = Ui.text(
				cbox,
				"",
				64,
				{ align = Enum.TextXAlignment.Center, stroke = 6, color = C.cash, name = "Total" }
			)
			cTotal.Position = UDim2.fromOffset(10, 254)
			cTotal.Size = UDim2.new(1, -20, 0, 72)
			local cNote = Ui.text(
				cbox,
				"",
				19,
				{ align = Enum.TextXAlignment.Center, color = C.muted, wrap = true, name = "Note" }
			)
			cNote.Position = UDim2.fromOffset(20, 326)
			cNote.Size = UDim2.new(1, -40, 0, 0)
			local cRow = Ui.frame(cbox, "Buttons", UDim2.new(1, -40, 0, 66), UDim2.new(0, 20, 1, -84))
			local cancel: Ui.Button
			local yes: Ui.Button
			cancel = Ui.button(cRow, {
				text = "CANCEL",
				style = "grey",
				size = UDim2.new(0.5, -8, 1, 0),
				textSize = 32,
				name = "Cancel",
				onClick = function()
					if not sending then
						confirm.Visible = false
					end
				end,
			})
			yes = Ui.button(cRow, {
				text = "CONFIRM",
				style = "lime",
				size = UDim2.new(0.5, -8, 1, 0),
				textSize = 32,
				name = "ConfirmSell",
				onClick = function() end,
			})
			yes.gui.Position = UDim2.new(0.5, 8, 0, 0)

			-- Cards -----------------------------------------------------------------------------------------
			local function selectedRows(): { Data.PetRow }
				local out = {}
				for uid in selected do
					local card = cards[uid]
					if card then
						table.insert(out, card.row)
					end
				end
				return out
			end

			local function paintCard(card: Card)
				local on = selected[card.row.uid] == true
				card.check.Visible = on
				card.stroke.Color = if on then Theme.Buttons.lime[1] else C.border
				card.stroke.Thickness = if on then 5 else 4
				Ui.fill(
					card.gui,
					if on then { Color3.fromHex("2F7A1C"), Color3.fromHex("123010") } else { C.card, C.card }
				)
				card.tag.Visible = card.row.slot ~= nil
				card.value.Text = Ui.money(card.row.sellValue)
			end

			local function toggle(uid: string)
				if sending then
					return
				end
				if selected[uid] then
					selected[uid] = nil
				else
					local n = 0
					for _ in selected do
						n += 1
					end
					if n >= MAX_BATCH then
						Modal.toast(`You can sell up to {MAX_BATCH} pets at once.`, "info")
						return
					end
					selected[uid] = true
				end
				local card = cards[uid]
				if card then
					paintCard(card)
					if selected[uid] then
						Motion.popIn(card.check)
					end
				end
				errorText = ""
				paintFooter()
			end

			local function makeCard(row: Data.PetRow): Card
				local b = Instance.new("TextButton")
				b.Name = row.uid
				b.Text = ""
				b.AutoButtonColor = false
				b.Selectable = true
				Ui.corner(b)
				Ui.fill(b, { C.card, C.card })
				local stroke = Ui.stroke(b, 4)
				Ui.studs(b, Theme.Studs.body, 20)
				local name = Ui.text(b, row.name, 24, { stroke = 3, name = "Name" })
				name.Position = UDim2.fromOffset(12, 6)
				name.Size = UDim2.new(1, -70, 0, 32)
				name.TextColor3 = Theme.RarityText[row.rarity] or C.text
				name.ZIndex = 3
				local artBox = Ui.frame(b, "ArtBox", UDim2.new(1, -16, 1, -98), UDim2.fromOffset(8, 40))
				artBox.ZIndex = 2
				Ui.glow(artBox, (Theme.Rarity[row.rarity] or Theme.Rarity.Common)[1], false, 0.9)
				local art = Ui.frame(artBox, "ArtFrame")
				art.ZIndex = 2
				Ui.petArt(art, row.model)
				local bar = Instance.new("Frame")
				bar.Name = "ValueBar"
				bar.AnchorPoint = Vector2.new(0.5, 1)
				bar.Position = UDim2.new(0.5, 0, 1, -8)
				bar.Size = UDim2.new(1, -16, 0, 50)
				bar.BackgroundColor3 = Color3.fromHex("0E1119")
				bar.ZIndex = 3
				Ui.corner(bar, 6)
				Ui.stroke(bar, 3)
				bar.Parent = b
				local vIcon = Ui.frame(bar, "CashIcon", UDim2.fromOffset(44, 44), UDim2.fromOffset(10, 3))
				vIcon.ZIndex = 4
				Ui.art(vIcon, "premium_icons_currency_cash").ZIndex = 4
				local value = Ui.text(
					bar,
					"",
					32,
					{ align = Enum.TextXAlignment.Center, stroke = 3, color = C.cash, name = "Value" }
				)
				value.Position = UDim2.fromOffset(48, 0)
				value.Size = UDim2.new(1, -56, 1, 0)
				value.ZIndex = 4
				local check = Instance.new("Frame")
				check.Name = "Check"
				check.AnchorPoint = Vector2.new(1, 0)
				check.Position = UDim2.new(1, -8, 0, 8)
				check.Size = UDim2.fromOffset(46, 46)
				check.ZIndex = 5
				Ui.corner(check, 6)
				Ui.fill(check, Theme.Buttons.lime)
				Ui.stroke(check, 3)
				local ci = Ui.frame(check, "Icon", UDim2.fromScale(0.86, 0.86), UDim2.fromScale(0.07, 0.07))
				ci.ZIndex = 6
				Ui.art(ci, "icon_check").ZIndex = 6
				check.Parent = b
				local tag = Ui.pill(b, "ON PEDESTAL", "purple", UDim2.fromOffset(170, 32), 18, "icon_lock")
				tag.AnchorPoint = Vector2.new(0.5, 1)
				tag.Position = UDim2.new(0.5, 0, 1, -64)
				tag.ZIndex = 5
				Motion.interactive(b)
				local uid = row.uid
				b.Activated:Connect(function()
					toggle(uid)
				end)
				b.Parent = scroll
				local card: Card = { row = row, gui = b, stroke = stroke, check = check, tag = tag, value = value }
				paintCard(card)
				return card
			end

			local function before(a: Data.PetRow, b: Data.PetRow): boolean
				local s = SORTS[sortIndex]
				if s == "Income" and a.income ~= b.income then
					return a.income > b.income
				elseif s == "Rarity" and a.rarityOrder ~= b.rarityOrder then
					return a.rarityOrder > b.rarityOrder
				elseif s == "Name" and a.name ~= b.name then
					return a.name < b.name
				elseif a.sellValue ~= b.sellValue then
					return a.sellValue > b.sellValue
				end
				return a.uid < b.uid
			end

			refresh = function()
				local rows = Data.pets()
				local seen: { [string]: boolean } = {}
				for _, row in rows do
					seen[row.uid] = true
					local card = cards[row.uid]
					if card then
						card.row = row
						paintCard(card)
					else
						cards[row.uid] = makeCard(row)
					end
				end
				for uid, card in cards do
					if not seen[uid] then
						card.gui:Destroy()
						cards[uid] = nil
						selected[uid] = nil
					end
				end
				table.sort(rows, before)
				local shown, protected = 0, 0
				for i, row in rows do
					local card = cards[row.uid]
					card.gui.LayoutOrder = i
					local show = not (hideProtected and row.slot ~= nil)
					card.gui.Visible = show
					if show then
						shown += 1
					end
					if row.slot then
						protected += 1
					end
				end
				count.Text = if #rows > 0 then `{shown} of {#rows} pets shown\n{protected} on pedestals` else ""
				empty.Visible = #rows == 0
				paintFooter()
			end

			paintFooter = function()
				local rows = selectedRows()
				local sum = 0
				for _, row in rows do
					sum += row.sellValue
				end
				nSel.Text = tostring(#rows)
				total.Text = Ui.money(sum)
				sell.setEnabled(#rows > 0)
				errorLabel.Text = errorText
			end

			openConfirm = function()
				local rows = selectedRows()
				if #rows == 0 or sending then
					return
				end
				local sum, protected = 0, 0
				for _, row in rows do
					sum += row.sellValue
					if row.slot then
						protected += 1
					end
				end
				q.Text = `Sell {#rows} pet{if #rows == 1 then "" else "s"}?`
				cTotal.Text = Ui.money(sum)
				cNote.Text = (
					if protected > 0
						then `{protected} {if protected == 1 then "is" else "are"} on a pedestal and will stop earning. `
						else ""
				) .. "This can't be undone."
				confirm.Visible = true
				Motion.popIn(cbox)
			end

			yes.gui.Activated:Connect(function()
				local rows = selectedRows()
				if sending or #rows == 0 or not confirm.Visible then
					return
				end
				sending = true
				yes.setPending(true, "SELLING...")
				cancel.setEnabled(false)
				local uids = {}
				for _, row in rows do
					table.insert(uids, row.uid)
				end
				remote("SellPets"):FireServer(uids)
				local token = {}
				local current: {}? = token
				local function finish(ok: boolean, reply: { [string]: any }?)
					if current ~= token then
						return
					end
					current = nil
					sending = false
					yes.setPending(false)
					cancel.setEnabled(true)
					confirm.Visible = false
					if ok and reply then
						local sold = tonumber(reply.count) or 0
						for _, uid in (reply.petUids or {}) :: { string } do
							selected[uid] = nil
						end
						if sold > 0 then
							Modal.toast(
								`Sold {sold} pet{if sold == 1 then "" else "s"} for {Ui.money(
									tonumber(reply.total) or 0
								)}!`,
								"good"
							)
							Motion.burst(Modal.layer(), sell.gui.AbsolutePosition + sell.gui.AbsoluteSize / 2, "cash")
						end
						local skipped = #uids - sold
						errorText = if skipped > 0 then `{skipped} couldn't be sold (in a trade?)` else ""
					else
						errorText = "Selling failed. Nothing was sold."
					end
					refresh()
				end
				local conn: RBXScriptConnection
				conn = remote("PetsSold").OnClientEvent:Connect(function(reply: { [string]: any })
					conn:Disconnect()
					finish(true, reply)
				end)
				task.delay(6, function()
					if conn.Connected then
						conn:Disconnect()
					end
					finish(false, nil)
				end)
			end)

			return {
				open = function()
					refresh()
					local visible = {}
					local n = 0
					for _, card in cards do
						if n < 12 and card.gui.Visible then
							n += 1
							table.insert(visible, card.gui :: GuiObject)
						end
					end
					Motion.reveal(visible, C.body)
				end,
				close = function()
					if not sending then
						confirm.Visible = false
					end
				end,
				update = refresh,
				resize = function(_size: Vector2, compact: boolean)
					grid.shape(if compact then 220 else 240, 1.0, 4)
					-- short screens: tighter sidebar so every control fits without scrolling
					sortTitle.Visible = not compact
					count.Visible = not compact
					for _, b in sortButtons do
						b.gui.Size = UDim2.new(1, 0, 0, if compact then 48 else 58)
					end
					selectAll.gui.Size = UDim2.new(1, 0, 0, if compact then 54 else 62)
				end,
			}
		end
	)
end

return PetInventory
