--!strict
-- Right HUD rail + drawers (UI handoff v2 01-Mockups/05-Eggs-and-Active-Pets.png, 01-Gameplay-HUD.png). EGGS (gold)
-- and PETS (orange) square tiles on the right edge; each opens a compact drawer that slides in from the edge
-- (200 ms cubic out). Drawers size to their rows (1-4 visible, then scroll) instead of a tall empty box.
-- One drawer at a time; opening a modal closes it.
--
-- HATCHING EGGS: eggs on pedestals (soonest first): 3D egg, name, countdown + bar from the server's
--   placedAt/hatchAt and synced server time. Eggs hatch BY THEMSELVES at hatchAt (no Hatch action exists), so a
--   finished timer reads HATCHING... until the server swaps the egg for its pet. Then eggs waiting for a free
--   pedestal, then one compact "free pedestals" row. Footer: BIGGER PEN (Remotes.UpgradePen, the real capacity
--   unlock). Badge = eggs waiting for room.
-- ACTIVE PETS: pets earning on pedestals: 3D pet, name, $/s and cash waiting on the pedestal. The game places
--   pets on free pedestals automatically, so there is no Unequip / Equip Best. Footer: SELL PETS (inventory)
--   and TRADE (A's trade window). Badge = pets hatched since you last opened the drawer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Kit = require(script.Parent.Parent.Kit)
local Rail = require(script.Parent.Rail)
local System = script.Parent.Parent.System
local Data = require(System.Data)
local Modal = require(System.Modal)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)

local C = Theme.Colors
local Drawers = {}

local W = 440
local HEAD = 68
local ROW = 100
local ROW_GAP = 10
local FOOT = 90
local MAX_H = 620 -- ~58% of the 1080 reference height

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%02d:%02d", s // 60, s % 60)
end

export type Drawers = { update: () -> (), hatched: (petName: string) -> (), open: (name: string?) -> () }

type Drawer = { root: Frame, title: TextLabel, count: TextLabel, list: ScrollingFrame, footer: Frame, rows: () -> number }

local function drawer(parent: Instance, name: string, title: string, fill: Theme.Pair, onClose: () -> ()): Drawer
	local root = Ui.surface(parent, name, C.body, Theme.Studs.body, 5)
	root.AnchorPoint = Vector2.new(1, 0)
	root.Visible = false
	root.ClipsDescendants = false
	local head = Ui.header(root, fill, title, nil, HEAD, 34)
	head.gui.ZIndex = 2
	local count = Ui.text(head.gui, "", 34, { align = Enum.TextXAlignment.Right, stroke = 4, name = "Count" })
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, -78, 0, 0)
	count.Size = UDim2.new(0, 120, 1, 0)
	count.ZIndex = 4
	local close = Ui.closeButton(root, onClose, 52, ">")
	close.AnchorPoint = Vector2.new(1, 0.5)
	close.Position = UDim2.new(1, -8, 0, HEAD / 2)
	close.ZIndex = 5
	local list = Ui.scroll(root, "List")
	list.Position = UDim2.fromOffset(10, HEAD + 10)
	list.Size = UDim2.new(1, -20, 1, -(HEAD + 20 + FOOT))
	Ui.padding(list, 3)
	Ui.list(list, ROW_GAP)
	local footer = Ui.frame(root, "Footer", UDim2.new(1, -20, 0, FOOT - 14), UDim2.new(0, 10, 1, -(FOOT - 4)))
	return {
		root = root,
		title = head.title,
		count = count,
		list = list,
		footer = footer,
		rows = function()
			local n = 0
			for _, c in list:GetChildren() do
				if c:IsA("GuiObject") and c.Visible then
					n += 1
				end
			end
			return n
		end,
	}
end

-- Auto height: header + rows (scroll after 4 or MAX_H) + footer.
local function fit(d: Drawer, rowHeights: number)
	local h = math.min(MAX_H, HEAD + 20 + rowHeights + FOOT)
	d.root.Size = UDim2.fromOffset(W, h)
end

local function rowFrame(list: ScrollingFrame, name: string, order: number, height: number?): Frame
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -6, 0, height or ROW)
	row.BackgroundColor3 = C.card
	Ui.corner(row)
	Ui.stroke(row, 4)
	Ui.studs(row, Theme.Studs.body, 20)
	row.Parent = list
	return row
end

function Drawers.new(parent: Instance): Drawers
	local rail = Ui.frame(parent, "RightRail", UDim2.fromOffset(120, 2 * 120 + 14))
	Kit.autoScale(rail)
	Ui.list(rail, 14)
	local host = Ui.frame(parent, "DrawerHost", UDim2.fromOffset(W, MAX_H))
	host.AnchorPoint = Vector2.new(1, 0.5)
	Kit.autoScale(host)

	local open: string? = nil
	local newPets = 0
	local show: (name: string?) -> ()
	local eggs = drawer(host, "EggsDrawer", "Hatching Eggs", Theme.Headers.eggs, function()
		show(nil)
	end)
	local pets = drawer(host, "PetsDrawer", "Active Pets", Theme.Headers.pets, function()
		show(nil)
	end)

	local eggButton: Rail.RailButton
	local petButton: Rail.RailButton
	local refreshEggs: () -> ()
	local refreshPets: () -> ()

	show = function(name: string?)
		local previous = open
		open = name
		local both: { [string]: Drawer } = { Eggs = eggs, Pets = pets }
		for n, d in both do
			local shown = n == name
			local root = d.root
			local home = UDim2.new(1, 0, 0, 0)
			local away = UDim2.new(1, W + 60, 0, 0)
			if shown then
				root.Visible = true
				if n ~= previous then
					root.Position = if Motion.reduced() then home else away
					Motion.tween(root, Theme.Motion.drawer, { Position = home }, Enum.EasingStyle.Cubic)
				end
			elseif root.Visible then
				if Motion.reduced() then
					root.Visible = false
				else
					Motion.tween(
						root,
						Theme.Motion.drawer,
						{ Position = away },
						Enum.EasingStyle.Cubic,
						Enum.EasingDirection.In
					).Completed
						:Once(function(state)
							if state == Enum.PlaybackState.Completed and open ~= n then
								root.Visible = false
							end
						end)
				end
			end
		end
		eggButton.setActive(name == "Eggs")
		petButton.setActive(name == "Pets")
		if name == "Pets" then
			newPets = 0
			petButton.setBadge(nil)
			refreshPets()
		elseif name == "Eggs" then
			refreshEggs()
		end
	end

	eggButton = Rail.tile(rail, "Eggs", Theme.Nav.Eggs, "premium_icons_nav_eggs", function()
		show(if open == "Eggs" then nil else "Eggs")
	end)
	eggButton.gui.LayoutOrder = 1
	petButton = Rail.tile(rail, "Pets", Theme.Nav.Pets, "premium_icons_nav_pets", function()
		show(if open == "Pets" then nil else "Pets")
	end)
	petButton.gui.LayoutOrder = 2

	Modal.onChanged(function(name: string?)
		if name and open then
			show(nil)
		end
	end)

	-- Pen upgrade (shared by both footers) ---------------------------------------------------------------------
	local penPending = false
	local penButtons: { Ui.Button } = {}
	local function paintPen()
		local pen = Data.pen()
		for _, b in penButtons do
			if pen.cost then
				b.setText(`BIGGER PEN +{(pen.nextSlots or pen.slots) - pen.slots}  {Ui.money(pen.cost)}`)
				b.setEnabled(Data.money() >= pen.cost)
			else
				b.setText("PEN MAXED")
				b.setEnabled(false)
			end
			b.setPending(penPending, "UPGRADING...")
		end
	end
	local function upgradePen()
		local pen = Data.pen()
		if penPending or not pen.cost or Data.money() < pen.cost then
			return
		end
		penPending = true
		paintPen()
		local before = pen.level
		remote("UpgradePen"):FireServer()
		Data.expect(
			function()
				return (Data.state.penLevel or 1) > before
			end,
			5,
			function(ok: boolean)
				penPending = false
				if ok then
					Modal.toast(`Pen upgraded: {Data.pen().slots} pedestals!`, "good")
				else
					Modal.toast("Pen upgrade failed. Try again.", "error")
				end
				paintPen()
				refreshEggs()
			end
		)
	end

	-- Eggs drawer ----------------------------------------------------------------------------------------------
	type EggUi = {
		frame: Frame,
		time: TextLabel,
		bar: Ui.Progress,
		ready: Frame,
		state: TextLabel,
		data: Data.EggRow,
		stopPulse: (() -> ())?,
	}
	local eggRows: { [string]: EggUi } = {}
	local eggEmpty = rowFrame(eggs.list, "Empty", 9000, 84)
	local eggEmptyText = Ui.text(
		eggEmpty,
		"No eggs yet. Kick one and race it home!",
		22,
		{ align = Enum.TextXAlignment.Center, stroke = 3, wrap = true }
	)
	eggEmptyText.AnchorPoint = Vector2.new(0, 0.5)
	eggEmptyText.Position = UDim2.fromScale(0, 0.5)
	local freeRow = rowFrame(eggs.list, "FreePedestals", 9001, 64)
	freeRow.BackgroundTransparency = 0.6
	local freePlus =
		Ui.text(freeRow, "+", 40, { align = Enum.TextXAlignment.Center, stroke = 3, color = C.muted, name = "Plus" })
	freePlus.Size = UDim2.fromOffset(64, 64)
	local freeText = Ui.text(freeRow, "", 24, { stroke = 3, color = C.muted, name = "Text" })
	freeText.Position = UDim2.fromOffset(70, 14)
	freeText.Size = UDim2.new(1, -80, 0, 36)
	local eggPen = Ui.button(eggs.footer, {
		text = "BIGGER PEN",
		style = "gold",
		size = UDim2.fromScale(1, 1),
		textSize = 30,
		icon = "premium_icons_currency_cash",
		name = "BiggerPen",
		onClick = upgradePen,
	})
	table.insert(penButtons, eggPen)

	local function tickEggs()
		local now = Data.now()
		for _, row in eggRows do
			local d = row.data
			if d.hatchAt and d.placedAt then
				local left = d.hatchAt - now
				local span = math.max(1, d.hatchAt - d.placedAt)
				local hatching = left <= 0
				row.bar.set(1 - left / span, "")
				row.time.Text = if hatching then "" else clock(left)
				row.bar.gui.Visible = not hatching
				row.ready.Visible = hatching
				if hatching and not row.stopPulse then
					row.stopPulse = Motion.pulse(row.ready, 0.05, 2.8)
				elseif not hatching and row.stopPulse then
					row.stopPulse()
					row.stopPulse = nil
				end
			end
		end
	end

	refreshEggs = function()
		local rows = Data.eggs()
		local cap = Data.capacity()
		eggs.count.Text = `{cap.eggs}/{cap.slots}`
		local seen: { [string]: boolean } = {}
		local height = 0
		for i, d in rows do
			seen[d.uid] = true
			local ui = eggRows[d.uid]
			if not ui then
				local f = rowFrame(eggs.list, d.uid, i)
				local thumb = Ui.frame(f, "Thumb", UDim2.fromOffset(84, 84), UDim2.fromOffset(8, 8))
				thumb.ZIndex = 2
				if d.model ~= "" then
					Ui.eggArt(thumb, d.model)
				end
				local nameLabel = Ui.text(f, d.name, 26, { stroke = 3, name = "Name" })
				nameLabel.Position = UDim2.fromOffset(102, 8)
				nameLabel.Size = UDim2.new(1, -210, 0, 34)
				nameLabel.TextColor3 = Theme.RarityText[d.rarity] or C.text
				local time = Ui.text(f, "", 30, { align = Enum.TextXAlignment.Right, stroke = 3, name = "Time" })
				time.AnchorPoint = Vector2.new(1, 0)
				time.Position = UDim2.new(1, -12, 0, 6)
				time.Size = UDim2.fromOffset(110, 36)
				local barHolder = Ui.frame(f, "Bar", UDim2.new(1, -118, 0, 30), UDim2.fromOffset(102, 54))
				local bar = Ui.progress(barHolder, Theme.Buttons.lime, 30)
				local ready = Ui.pill(f, "HATCHING...", "lime", UDim2.fromOffset(220, 46), 26)
				ready.Position = UDim2.fromOffset(102, 46)
				ready.Visible = false
				local state = Ui.text(f, "", 22, { stroke = 3, color = C.power, name = "State" })
				state.Position = UDim2.fromOffset(102, 52)
				state.Size = UDim2.new(1, -118, 0, 32)
				ui = { frame = f, time = time, bar = bar, ready = ready, state = state, data = d }
				eggRows[d.uid] = ui
			end
			local u = ui :: EggUi
			u.data = d
			u.frame.LayoutOrder = i
			local waiting = d.slot == nil
			u.state.Visible = waiting
			u.state.Text = if waiting then "WAITING FOR A PEDESTAL" else ""
			if waiting then
				u.bar.gui.Visible = false
				u.ready.Visible = false
				u.time.Text = ""
			end
			height += ROW + ROW_GAP
		end
		for uid, ui in eggRows do
			if not seen[uid] then
				if ui.stopPulse then
					ui.stopPulse()
				end
				ui.frame:Destroy()
				eggRows[uid] = nil
			end
		end
		local free = math.max(0, cap.slots - cap.eggs - cap.pets)
		eggEmpty.Visible = #rows == 0
		freeRow.Visible = free > 0 and #rows > 0
		freeText.Text = `{free} FREE PEDESTAL{if free == 1 then "" else "S"}`
		if eggEmpty.Visible then
			height += 84 + ROW_GAP
		end
		if freeRow.Visible then
			height += 64 + ROW_GAP
		end
		fit(eggs, height)
		paintPen()
		tickEggs()
	end

	-- Pets drawer ----------------------------------------------------------------------------------------------
	type PetUi = { frame: Frame, income: TextLabel, stored: TextLabel }
	local petRows: { [string]: PetUi } = {}
	local petEmpty = rowFrame(pets.list, "Empty", 9000, 84)
	local petEmptyText = Ui.text(
		petEmpty,
		"No pets on pedestals yet.",
		22,
		{ align = Enum.TextXAlignment.Center, stroke = 3, wrap = true }
	)
	petEmptyText.AnchorPoint = Vector2.new(0, 0.5)
	petEmptyText.Position = UDim2.fromScale(0, 0.5)
	local waitingRow = rowFrame(pets.list, "Waiting", 9001, 56)
	waitingRow.BackgroundTransparency = 0.6
	local waitingText =
		Ui.text(waitingRow, "", 21, { stroke = 3, color = C.power, name = "Text", align = Enum.TextXAlignment.Center })
	waitingText.Position = UDim2.fromOffset(8, 10)
	waitingText.Size = UDim2.new(1, -16, 0, 36)
	local sellButton = Ui.button(pets.footer, {
		text = "SELL PETS",
		style = "lime",
		size = UDim2.new(0.62, -6, 1, 0),
		textSize = 30,
		icon = "premium_icons_currency_cash",
		name = "SellPets",
		onClick = function()
			Modal.open("Inventory", petButton.gui)
		end,
	})
	sellButton.gui.Position = UDim2.new()
	local trade = Ui.button(pets.footer, {
		text = "TRADE",
		style = "purple",
		size = UDim2.new(0.38, -6, 1, 0),
		textSize = 30,
		name = "Trade",
		onClick = function()
			show(nil)
			Drawers.openTrade()
		end,
	})
	trade.gui.AnchorPoint = Vector2.new(1, 0)
	trade.gui.Position = UDim2.fromScale(1, 0)

	refreshPets = function()
		local rows = Data.pets()
		local cap = Data.capacity()
		pets.count.Text = `{cap.pets}/{cap.slots}`
		local placed = {}
		for _, row in rows do
			if row.slot then
				table.insert(placed, row)
			end
		end
		table.sort(placed, function(a, b)
			return a.income > b.income
		end)
		local seen: { [string]: boolean } = {}
		local height = 0
		for i, d in placed do
			seen[d.uid] = true
			local ui = petRows[d.uid]
			if not ui then
				local f = rowFrame(pets.list, d.uid, i)
				local thumb = Ui.frame(f, "Thumb", UDim2.fromOffset(84, 84), UDim2.fromOffset(8, 8))
				thumb.ZIndex = 2
				Ui.petArt(thumb, d.model)
				local nameLabel = Ui.text(f, d.name, 26, { stroke = 3, name = "Name" })
				nameLabel.Position = UDim2.fromOffset(102, 8)
				nameLabel.Size = UDim2.new(1, -112, 0, 34)
				nameLabel.TextColor3 = Theme.RarityText[d.rarity] or C.text
				local coin = Ui.frame(f, "Coin", UDim2.fromOffset(38, 38), UDim2.fromOffset(100, 50))
				Ui.art(coin, "premium_icons_currency_cash")
				local income = Ui.text(f, "", 28, { autoX = true, stroke = 3, color = C.cash, name = "Income" })
				income.Position = UDim2.fromOffset(142, 50)
				local stored = Ui.text(
					f,
					"",
					20,
					{ align = Enum.TextXAlignment.Right, stroke = 2, color = C.muted, name = "Stored" }
				)
				stored.AnchorPoint = Vector2.new(1, 0)
				stored.Position = UDim2.new(1, -12, 0, 56)
				stored.Size = UDim2.fromOffset(150, 28)
				ui = { frame = f, income = income, stored = stored }
				petRows[d.uid] = ui
			end
			local u = ui :: PetUi
			u.frame.LayoutOrder = i
			u.income.Text = `+{Ui.money(d.income)}/s`
			u.stored.Text = if d.stored > 0 then `{Ui.money(d.stored)} waiting` else ""
			height += ROW + ROW_GAP
		end
		for uid, ui in petRows do
			if not seen[uid] then
				ui.frame:Destroy()
				petRows[uid] = nil
			end
		end
		petEmpty.Visible = #placed == 0
		local waiting = cap.unplacedPets
		waitingRow.Visible = waiting > 0
		waitingText.Text = `{waiting} more pet{if waiting == 1 then "" else "s"} waiting for a free pedestal`
		if petEmpty.Visible then
			height += 84 + ROW_GAP
		end
		if waitingRow.Visible then
			height += 56 + ROW_GAP
		end
		fit(pets, height)
	end

	-- Layout + timers ------------------------------------------------------------------------------------------
	Kit.onLayout(function(compact: boolean)
		local tile = if compact then 96 else 120
		rail.Size = UDim2.fromOffset(tile, 2 * tile + 14)
		rail.AnchorPoint = if compact then Vector2.new(1, 0) else Vector2.new(1, 0.5)
		rail.Position = if compact then UDim2.new(1, -10, 0, 8) else UDim2.new(1, -24, 0.5, 0)
		eggButton.setCompact(compact)
		petButton.setCompact(compact)
		host.AnchorPoint = Vector2.new(1, 0)
		host.Position = if compact
			then UDim2.new(1, -(10 + tile + 12), 0, 8)
			else UDim2.new(1, -(24 + tile + 16), 0.5, -MAX_H / 2)
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		if open == "Eggs" then
			tickEggs()
		elseif open == "Pets" then
			refreshPets() -- Stored cash ticks on the pedestal models every second
		end
	end)

	refreshEggs()
	refreshPets()
	return {
		open = function(name: string?)
			show(name)
		end,
		update = function()
			local cap = Data.capacity()
			eggButton.setBadge(if cap.waitingEggs > 0 then tostring(cap.waitingEggs) else nil)
			if open == "Eggs" then
				refreshEggs()
			elseif open == "Pets" then
				refreshPets()
			end
		end,
		hatched = function(petName: string)
			Modal.toast(`{petName} hatched!`, "good")
			if open ~= "Pets" then
				newPets += 1
				petButton.setBadge(tostring(newPets))
			end
			Motion.burst(Modal.layer(), petButton.gui.AbsolutePosition + petButton.gui.AbsoluteSize / 2, "sparkle", 10)
		end,
	}
end

-- Set by UI/init: opens A's Trade window.
function Drawers.openTrade() end

return Drawers
