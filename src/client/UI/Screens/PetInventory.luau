--!strict
-- Pet inventory + selling (UI handoff SCREEN-SPEC "Pets and selling"). Every pet you own, searchable and
-- sortable (Sell value / Income / Rarity / Name; no Weight: the game has no pet weight). Tap cards to select.
-- Pets on a pedestal are PROTECTED: they earn money, so "Select all" skips them (you can still pick one by
-- hand; selling it also pays out its stored cash, exactly as the server does). Sell -> confirmation with the
-- exact count and total -> Remotes.SellPets -> the server's PetsSold reply. Nothing is removed until the
-- server says so (DataChanged); on failure the selection stays and an inline error shows.
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
local SORTS = { "Sell value", "Income", "Rarity", "Name" }

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

type Card = {
	row: Data.PetRow,
	gui: TextButton,
	check: Frame,
	stroke: UIStroke,
	value: TextLabel,
	income: TextLabel,
	lock: Frame,
}

local function tags(row: Data.PetRow): string
	local parts = {}
	if row.size then
		table.insert(parts, row.size)
	end
	if row.weather then
		table.insert(parts, row.weather)
	end
	return table.concat(parts, " · ")
end

function PetInventory.define()
	Modal.define(
		"Inventory",
		{ title = "Pets", gradient = "lime", icon = "icon/pets", footer = true },
		function(shell: Modal.Shell): Modal.Screen
			local body = shell.body
			local footer = shell.footer :: Frame
			local cards: { [string]: Card } = {}
			local selected: { [string]: boolean } = {}
			local sortIndex = 1
			local query = ""
			local sending = false
			local errorText = ""

			-- Toolbar: search + sort.
			local bar = Ui.frame(body, "Toolbar", UDim2.new(1, 0, 0, 56))
			local search = Instance.new("TextBox")
			search.Name = "Search"
			search.PlaceholderText = "Search pets..."
			search.Text = ""
			search.ClearTextOnFocus = false
			search.Font = Theme.Font
			search.TextSize = 22
			search.TextColor3 = C.text
			search.PlaceholderColor3 = C.muted
			search.TextXAlignment = Enum.TextXAlignment.Left
			search.BackgroundColor3 = C.panelDeep
			search.Size = UDim2.new(0.5, -10, 1, 0)
			Ui.corner(search)
			Ui.stroke(search, 3)
			Ui.padding(search, 14, 0)
			search.Parent = bar
			local sortButton = Ui.button(bar, {
				text = "Sort: " .. SORTS[1],
				gradient = "grey",
				size = UDim2.fromOffset(280, 56),
				textSize = 22,
				name = "Sort",
				onClick = function() end,
			})
			sortButton.gui.AnchorPoint = Vector2.new(1, 0)
			sortButton.gui.Position = UDim2.fromScale(1, 0)
			local count = Ui.text(bar, "", 20, { color = C.muted, name = "Count", align = Enum.TextXAlignment.Center })
			count.Position = UDim2.new(0.5, 0, 0, 0)
			count.Size = UDim2.new(0.5, -290, 1, 0)

			local scroll = Ui.scroll(body, "Pets")
			scroll.Position = UDim2.fromOffset(0, 70)
			scroll.Size = UDim2.new(1, 0, 1, -70)
			Ui.padding(scroll, 6)
			local grid = Ui.grid(scroll, 180, 1.32, 16, 6)
			local empty = Ui.text(body, "No pets yet. Secure eggs and let them hatch!", 26, {
				color = C.muted,
				align = Enum.TextXAlignment.Center,
				name = "Empty",
			})
			empty.Position = UDim2.fromScale(0, 0.45)
			empty.Visible = false

			-- Footer: selection summary + actions.
			local summary = Ui.text(footer, "", 24, { name = "Summary" })
			summary.Size = UDim2.new(0.4, 0, 0, 34)
			summary.Position = UDim2.fromOffset(0, 6)
			local errorLabel = Ui.text(footer, "", 18, { color = Theme.Gradients.red[1], name = "Error" })
			errorLabel.Position = UDim2.fromOffset(0, 42)
			errorLabel.Size = UDim2.new(0.4, 0, 0, 26)
			local actions = Ui.frame(footer, "Actions", UDim2.new(0.6, 0, 1, -12), UDim2.fromScale(0.4, 0))
			local actionList = Ui.list(actions, 12, true, Enum.HorizontalAlignment.Right)
			actionList.VerticalAlignment = Enum.VerticalAlignment.Center

			-- Confirmation dialog (inside the modal; Cancel as visible as Sell).
			local confirm = Ui.frame(shell.panel, "Confirm")
			confirm.ZIndex = 40
			confirm.Visible = false
			local dim = Instance.new("TextButton")
			dim.Name = "Dim"
			dim.Text = ""
			dim.AutoButtonColor = false
			dim.Selectable = false
			dim.BackgroundColor3 = C.scrim
			dim.BackgroundTransparency = 0.4
			dim.Size = UDim2.fromScale(1, 1)
			dim.ZIndex = 40
			Ui.corner(dim, 16)
			dim.Parent = confirm
			local box = Ui.panel(confirm, "Box", C.panel)
			box.AnchorPoint = Vector2.new(0.5, 0.5)
			box.Position = UDim2.fromScale(0.5, 0.5)
			box.Size = UDim2.fromOffset(620, 300)
			box.ZIndex = 41
			local boxText = Ui.text(box, "", 30, { wrap = true, align = Enum.TextXAlignment.Center, name = "Question" })
			boxText.Position = UDim2.fromOffset(30, 28)
			boxText.Size = UDim2.new(1, -60, 0, 0)
			local boxNote = Ui.text(
				box,
				"",
				20,
				{ wrap = true, align = Enum.TextXAlignment.Center, color = C.muted, name = "Note" }
			)
			boxNote.Position = UDim2.fromOffset(30, 130)
			boxNote.Size = UDim2.new(1, -60, 0, 0)
			local confirmRow = Ui.frame(box, "Buttons", UDim2.new(1, -60, 0, 64), UDim2.new(0, 30, 1, -88))
			Ui.list(confirmRow, 20, true, Enum.HorizontalAlignment.Center)

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

			local paintFooter: () -> ()

			local function paintCard(card: Card)
				local on = selected[card.row.uid] == true
				card.check.Visible = on
				card.stroke.Color = if on then Theme.Gradients.lime[1] else C.stroke
				card.stroke.Thickness = if on then 5 else 3
				card.lock.Visible = card.row.slot ~= nil
				card.value.Text = Ui.money(card.row.sellValue)
				card.income.Text = `{Ui.money(card.row.income)}/s`
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
				b.BackgroundColor3 = C.panel
				b.Selectable = true
				Ui.corner(b)
				local stroke = Ui.stroke(b, 3)
				Ui.studs(b)
				local glowColor = (Theme.Rarity :: any)[row.rarity] or C.text
				local artHolder = Ui.frame(b, "ArtHolder", UDim2.new(1, -16, 0.55, 0), UDim2.fromOffset(8, 8))
				Ui.glow(artHolder, glowColor, false)
				local art = Ui.frame(artHolder, "ArtFrame")
				Ui.petArt(art, row.model)
				local name = Ui.text(b, row.name, 20, { name = "Name", align = Enum.TextXAlignment.Center })
				name.TextColor3 = glowColor
				name.Position = UDim2.new(0, 6, 0.55, 10)
				name.Size = UDim2.new(1, -12, 0, 26)
				local tag =
					Ui.text(b, tags(row), 16, { name = "Tags", align = Enum.TextXAlignment.Center, color = C.power })
				tag.Position = UDim2.new(0, 6, 0.55, 36)
				tag.Size = UDim2.new(1, -12, 0, 22)
				local value = Ui.text(b, "", 22, { name = "Value", align = Enum.TextXAlignment.Center, color = C.cash })
				value.AnchorPoint = Vector2.new(0, 1)
				value.Position = UDim2.new(0, 6, 1, -30)
				value.Size = UDim2.new(1, -12, 0, 28)
				local income =
					Ui.text(b, "", 16, { name = "Income", align = Enum.TextXAlignment.Center, color = C.muted })
				income.AnchorPoint = Vector2.new(0, 1)
				income.Position = UDim2.new(0, 6, 1, -6)
				income.Size = UDim2.new(1, -12, 0, 22)
				-- selected check (top right) and protected marker (top left)
				local check = Instance.new("Frame")
				check.Name = "Check"
				check.Size = UDim2.fromOffset(40, 40)
				check.AnchorPoint = Vector2.new(1, 0)
				check.Position = UDim2.new(1, -6, 0, 6)
				check.ZIndex = 5
				Ui.corner(check, 20)
				Ui.gradient(check, "lime")
				Ui.stroke(check, 3)
				local ci = Ui.icon(check, "icon/check", 28, "✓")
				ci.AnchorPoint = Vector2.new(0.5, 0.5)
				ci.Position = UDim2.fromScale(0.5, 0.5)
				ci.ZIndex = 6
				check.Parent = b
				local lock, _ = Ui.pill(b, "ON PEDESTAL", "cyan", UDim2.fromOffset(132, 26), 16)
				lock.Position = UDim2.fromOffset(6, 6)
				lock.ZIndex = 5
				Motion.interactive(b)
				local uid = row.uid
				b.Activated:Connect(function()
					toggle(uid)
				end)
				b.Parent = scroll
				local card: Card =
					{ row = row, gui = b, check = check, stroke = stroke, value = value, income = income, lock = lock }
				paintCard(card)
				return card
			end

			local function sortKey(a: Data.PetRow, b: Data.PetRow): boolean
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

			local function refresh()
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
				table.sort(rows, sortKey)
				local q = string.lower(query)
				local shown = 0
				for i, row in rows do
					local card = cards[row.uid]
					card.gui.LayoutOrder = i
					local match = q == ""
						or string.find(string.lower(row.name), q, 1, true) ~= nil
						or string.find(string.lower(row.rarity), q, 1, true) ~= nil
					card.gui.Visible = match
					if match then
						shown += 1
					end
				end
				count.Text = if #rows > 0 then `{shown} of {#rows} pets` else ""
				empty.Visible = #rows == 0
				paintFooter()
			end

			local selectAll = Ui.button(actions, {
				text = "SELECT ALL",
				gradient = "cyan",
				size = UDim2.fromOffset(220, 60),
				textSize = 22,
				name = "SelectAll",
				onClick = function()
					if sending then
						return
					end
					-- every visible, unprotected pet (pets on pedestals are skipped by default)
					local n = 0
					for _ in selected do
						n += 1
					end
					for uid, card in cards do
						if n >= MAX_BATCH then
							break
						end
						if card.gui.Visible and card.row.slot == nil and not selected[uid] then
							selected[uid] = true
							n += 1
						end
					end
					for _, card in cards do
						paintCard(card)
					end
					paintFooter()
				end,
			})
			selectAll.gui.LayoutOrder = 1
			local clear = Ui.button(actions, {
				text = "CLEAR",
				gradient = "grey",
				size = UDim2.fromOffset(150, 60),
				textSize = 22,
				name = "Clear",
				onClick = function()
					if sending then
						return
					end
					table.clear(selected)
					for _, card in cards do
						paintCard(card)
					end
					errorText = ""
					paintFooter()
				end,
			})
			clear.gui.LayoutOrder = 2
			local sell = Ui.button(actions, {
				text = "SELL",
				gradient = "orange",
				size = UDim2.fromOffset(220, 60),
				textSize = 24,
				icon = "icon/cash",
				name = "Sell",
				onClick = function()
					local rows = selectedRows()
					if #rows == 0 or sending then
						return
					end
					local total, protected = 0, 0
					for _, row in rows do
						total += row.sellValue
						if row.slot then
							protected += 1
						end
					end
					boxText.Text = `Sell {#rows} pet{if #rows == 1 then "" else "s"} for {Ui.money(total)}?`
					boxNote.Text = (
						if protected > 0
							then `{protected} of them {if protected == 1 then "is" else "are"} on a pedestal and will stop earning. `
							else ""
					) .. "This can't be undone."
					confirm.Visible = true
				end,
			})
			sell.gui.LayoutOrder = 3

			local cancel: Ui.Button
			local yes: Ui.Button
			cancel = Ui.button(confirmRow, {
				text = "CANCEL",
				gradient = "grey",
				size = UDim2.fromOffset(250, 64),
				textSize = 26,
				name = "Cancel",
				onClick = function()
					if not sending then
						confirm.Visible = false
					end
				end,
			})
			yes = Ui.button(confirmRow, {
				text = "SELL",
				gradient = "orange",
				size = UDim2.fromOffset(250, 64),
				textSize = 26,
				name = "ConfirmSell",
				onClick = function()
					local rows = selectedRows()
					if sending or #rows == 0 then
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
								local at = sell.gui.AbsolutePosition + sell.gui.AbsoluteSize / 2
								Motion.burst(Modal.layer(), at, "cash")
							end
							local skipped = #uids - sold
							errorText = if skipped > 0
								then `{skipped} pet{if skipped == 1 then "" else "s"} couldn't be sold (in a trade?).`
								else ""
						else
							errorText = "Selling failed. Nothing was sold. Try again."
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
				end,
			})

			paintFooter = function()
				local rows = selectedRows()
				local total = 0
				for _, row in rows do
					total += row.sellValue
				end
				summary.Text = if #rows > 0 then `Selected {#rows}: {Ui.money(total)}` else "Tap pets to select"
				sell.setEnabled(#rows > 0)
				clear.setEnabled(#rows > 0)
				errorLabel.Text = errorText
			end

			sortButton.gui.Activated:Connect(function()
				sortIndex = sortIndex % #SORTS + 1
				sortButton.setText("Sort: " .. SORTS[sortIndex])
				refresh()
			end)
			search:GetPropertyChangedSignal("Text"):Connect(function()
				query = search.Text
				refresh()
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
					Motion.reveal(visible, C.panel)
				end,
				close = function()
					if not sending then
						confirm.Visible = false
					end
				end,
				update = refresh,
				resize = function(_size: Vector2, compact: boolean)
					grid.shape(if compact then 200 else 180, if compact then 1.2 else 1.32, 6)
				end,
			}
		end
	)
end

return PetInventory
