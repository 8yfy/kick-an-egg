--!strict
-- Right HUD rail: Eggs and Pets toggles, each opening a drawer that slides in from the right edge (200 ms,
-- cubic out, chevron turns). One drawer at a time; opening a modal closes it. (UI handoff SCREEN-SPEC
-- "Egg drawer" / "Active pets drawer".)
--
-- Eggs: eggs hatching on pedestals (soonest first) with a countdown + bar from the server's placedAt/hatchAt
--   and synced server time, then eggs waiting for a free pedestal. Eggs hatch by themselves on the server at
--   hatchAt, so there is no Hatch button: a finished timer reads "Hatching..." until the server swaps the egg
--   for its pet. Queue-full shows how to make room (Bigger Pen / sell pets). Badge = eggs waiting for room.
-- Pets: pedestal capacity header, the pets earning on pedestals ($/s and cash waiting to be collected),
--   Bigger Pen (Remotes.UpgradePen, the game's real capacity unlock) and Inventory / Sell + Trade shortcuts.
--   No unequip / Equip Best: the game places pets on free pedestals automatically, so neither exists.
--   Badge = pets hatched since you last opened the drawer.
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

local DRAWER_W, DRAWER_H = 470, 620

local function remote(name: string): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get(name)
end

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

export type Drawers = { update: () -> (), hatched: (petName: string) -> (), open: (name: string?) -> () }

type Drawer = { root: Frame, header: TextLabel, sub: TextLabel, list: ScrollingFrame, footer: Frame }

local function drawer(parent: Instance, name: string, title: string, key: Ui.Gradient): Drawer
	local root = Ui.panel(parent, name)
	root.Size = UDim2.fromOffset(DRAWER_W, DRAWER_H)
	root.AnchorPoint = Vector2.new(1, 0.5)
	root.Visible = false
	local head = Instance.new("Frame")
	head.Name = "Header"
	head.Position = UDim2.fromOffset(8, 8)
	head.Size = UDim2.new(1, -16, 0, 64)
	head.ClipsDescendants = true
	Ui.corner(head, 12)
	Ui.gradient(head, key)
	Ui.stroke(head)
	Ui.studs(head, Theme.Studs.header)
	head.Parent = root
	local header = Ui.text(head, title, 34, { stroke = 4, name = "Title" })
	header.Position = UDim2.fromOffset(16, 0)
	header.Size = UDim2.new(0.5, 0, 1, 0)
	local sub = Ui.text(head, "", 22, { align = Enum.TextXAlignment.Right, name = "Capacity" })
	sub.AnchorPoint = Vector2.new(1, 0)
	sub.Position = UDim2.new(1, -16, 0, 0)
	sub.Size = UDim2.new(0.5, -16, 1, 0)
	local list = Ui.scroll(root, "List")
	list.Position = UDim2.fromOffset(12, 84)
	list.Size = UDim2.new(1, -24, 1, -84 - 150)
	Ui.padding(list, 4)
	Ui.list(list, 10)
	local footer = Ui.frame(root, "Footer", UDim2.new(1, -24, 0, 138), UDim2.new(0, 12, 1, -146))
	return { root = root, header = header, sub = sub, list = list, footer = footer }
end

local function rowFrame(list: ScrollingFrame, name: string, order: number): Frame
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 96)
	row.BackgroundColor3 = C.panelDeep
	Ui.corner(row)
	Ui.stroke(row, 3)
	row.Parent = list
	return row
end

function Drawers.new(parent: Instance): Drawers
	local rail = Ui.frame(parent, "RightRail", UDim2.fromOffset(104, 2 * 104 + 12))
	Kit.autoScale(rail)
	Ui.list(rail, 12)
	local host = Ui.frame(parent, "DrawerHost", UDim2.fromOffset(DRAWER_W, DRAWER_H))
	host.AnchorPoint = Vector2.new(1, 0.5)
	Kit.autoScale(host)

	local eggs = drawer(host, "EggsDrawer", "Eggs", "orange")
	local pets = drawer(host, "PetsDrawer", "Pets", "lime")
	local open: string? = nil
	local newPets = 0

	local eggButton: Rail.RailButton
	local petButton: Rail.RailButton
	local refreshEggs: () -> ()
	local refreshPets: () -> ()

	local function chevron(b: Rail.RailButton, on: boolean)
		local c = b.gui:FindFirstChild("Chevron")
		if c and c:IsA("TextLabel") then
			if Motion.reduced() then
				c.Rotation = if on then 180 else 0
			else
				Motion.tween(c, Theme.Motion.drawer, { Rotation = if on then 180 else 0 }, Enum.EasingStyle.Cubic)
			end
		end
	end

	local function show(name: string?)
		local previous = open
		open = name
		local both: { [string]: Drawer } = { Eggs = eggs, Pets = pets }
		for n, d in both do
			local shown = n == name
			local root = d.root
			local home = UDim2.new(1, 0, 0.5, 0)
			local away = UDim2.new(1, DRAWER_W + 40, 0.5, 0)
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
		chevron(eggButton, name == "Eggs")
		chevron(petButton, name == "Pets")
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

	eggButton = Rail.button(rail, "Eggs", "Eggs", "orange", "icon/egg", "E", function()
		show(if open == "Eggs" then nil else "Eggs")
	end)
	eggButton.gui.LayoutOrder = 1
	petButton = Rail.button(rail, "Pets", "Pets", "lime", "icon/pets", "P", function()
		show(if open == "Pets" then nil else "Pets")
	end)
	petButton.gui.LayoutOrder = 2
	for _, b in { eggButton, petButton } do
		local c = Ui.text(b.gui, "<", 26, { align = Enum.TextXAlignment.Center, name = "Chevron" })
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.Position = UDim2.new(0, 2, 0.5, 0)
		c.Size = UDim2.fromOffset(26, 34)
		c.ZIndex = 5
	end

	Modal.onChanged(function(name: string?)
		if name and open then
			show(nil)
		end
	end)

	-- Eggs drawer ----------------------------------------------------------------------------------------------

	type EggRow = {
		frame: Frame,
		name: TextLabel,
		time: TextLabel,
		bar: Ui.Progress,
		state: TextLabel,
		data: Data.EggRow,
		stopPulse: (() -> ())?,
	}
	local eggRows: { [string]: EggRow } = {}
	local eggEmpty = Ui.text(eggs.list, "No eggs. Kick one and race it home!", 22, {
		color = C.muted,
		wrap = true,
		align = Enum.TextXAlignment.Center,
		name = "Empty",
	})
	local fullNote = Ui.text(eggs.footer, "", 20, { color = C.power, wrap = true, name = "Full" })
	local penPending = false
	local function penButton(container: Instance, order: number): Ui.Button
		local b: Ui.Button
		b = Ui.button(container, {
			text = "BIGGER PEN",
			gradient = "cyan",
			size = UDim2.new(0.5, -6, 0, 60),
			textSize = 20,
			icon = "icon/cash",
			name = "BiggerPen",
			onClick = function()
				local pen = Data.pen()
				if penPending or not pen.cost or Data.money() < pen.cost then
					return
				end
				penPending = true
				refreshEggs()
				refreshPets()
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
						refreshEggs()
						refreshPets()
					end
				)
			end,
		})
		b.gui.LayoutOrder = order
		return b
	end
	local eggActions = Ui.frame(eggs.footer, "Actions", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 1, -60))
	Ui.list(eggActions, 12, true)
	local eggPen = penButton(eggActions, 1)
	local eggSell = Ui.button(eggActions, {
		text = "SELL PETS",
		gradient = "orange",
		size = UDim2.new(0.5, -6, 0, 60),
		textSize = 20,
		name = "SellPets",
		onClick = function()
			Modal.open("Inventory", eggButton.gui)
		end,
	})
	eggSell.gui.LayoutOrder = 2

	local function paintPen(b: Ui.Button)
		local pen = Data.pen()
		if pen.cost then
			b.setText(`+{(pen.nextSlots or pen.slots) - pen.slots} SLOTS {Ui.money(pen.cost)}`)
			b.setEnabled(Data.money() >= pen.cost)
		else
			b.setText("PEN MAXED")
			b.setEnabled(false)
		end
		b.setPending(penPending, "UPGRADING...")
	end

	local function tickEggs()
		local now = Data.now()
		for _, row in eggRows do
			local d = row.data
			if d.hatchAt and d.placedAt then
				local left = d.hatchAt - now
				local span = math.max(1, d.hatchAt - d.placedAt)
				row.bar.set(1 - left / span, "")
				if left > 0 then
					row.time.Text = clock(left)
					if row.stopPulse then
						row.stopPulse()
						row.stopPulse = nil
					end
				else
					row.time.Text = "Ready"
					row.state.Text = "Hatching..."
					row.state.TextColor3 = Theme.Gradients.lime[1]
					if not row.stopPulse then
						row.stopPulse = Motion.pulse(row.frame, 0.03, 2.8)
					end
				end
			end
		end
	end

	refreshEggs = function()
		local rows = Data.eggs()
		local cap = Data.capacity()
		eggs.sub.Text = `{cap.eggs + cap.pets} / {cap.slots} pedestals`
		local seen: { [string]: boolean } = {}
		for i, d in rows do
			seen[d.uid] = true
			local row = eggRows[d.uid]
			if not row then
				local f = rowFrame(eggs.list, d.uid, i)
				local thumb = Ui.frame(f, "Thumb", UDim2.fromOffset(80, 80), UDim2.fromOffset(8, 8))
				if d.model ~= "" then
					Ui.eggArt(thumb, d.model)
				end
				local name = Ui.text(f, d.name, 22, { name = "Name" })
				name.Position = UDim2.fromOffset(98, 6)
				name.Size = UDim2.new(1, -200, 0, 30)
				name.TextColor3 = (Theme.Rarity :: any)[d.rarity] or C.text
				local time = Ui.text(f, "", 24, { align = Enum.TextXAlignment.Right, name = "Time" })
				time.AnchorPoint = Vector2.new(1, 0)
				time.Position = UDim2.new(1, -12, 0, 6)
				time.Size = UDim2.fromOffset(96, 30)
				local barHolder = Ui.frame(f, "Bar", UDim2.new(1, -112, 0, 20), UDim2.fromOffset(98, 40))
				local bar = Ui.progress(barHolder, "orange", 20)
				local state = Ui.text(f, "", 18, { color = C.muted, name = "State" })
				state.Position = UDim2.fromOffset(98, 64)
				state.Size = UDim2.new(1, -112, 0, 26)
				row = { frame = f, name = name, time = time, bar = bar, state = state, data = d }
				eggRows[d.uid] = row
			end
			local r = row :: EggRow
			r.data = d
			r.frame.LayoutOrder = i
			if d.slot then
				r.state.Text = `On pedestal {d.slot}`
				r.state.TextColor3 = C.muted
				r.bar.gui.Visible = true
			else
				r.state.Text = "Waiting for a free pedestal"
				r.state.TextColor3 = C.power
				r.time.Text = ""
				r.bar.gui.Visible = false
			end
		end
		for uid, row in eggRows do
			if not seen[uid] then
				if row.stopPulse then
					row.stopPulse()
				end
				row.frame:Destroy()
				eggRows[uid] = nil
			end
		end
		eggEmpty.Visible = #rows == 0
		local full = cap.waitingEggs > 0
		fullNote.Text = if full
			then `Pedestals full: {cap.waitingEggs} egg{if cap.waitingEggs == 1 then "" else "s"} waiting. Get a bigger pen or sell pets.`
			else "Eggs hatch by themselves on their pedestal."
		fullNote.TextColor3 = if full then C.power else C.muted
		paintPen(eggPen)
		tickEggs()
	end

	-- Pets drawer ----------------------------------------------------------------------------------------------

	type PetRowUi = { frame: Frame, income: TextLabel, stored: TextLabel }
	local petRows: { [string]: PetRowUi } = {}
	local petEmpty = Ui.text(pets.list, "No pets on pedestals yet.", 22, {
		color = C.muted,
		wrap = true,
		align = Enum.TextXAlignment.Center,
		name = "Empty",
	})
	local petNote = Ui.text(pets.footer, "", 18, { color = C.muted, wrap = true, name = "Note" })
	local petActions = Ui.frame(pets.footer, "Actions", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 1, -60))
	Ui.list(petActions, 12, true)
	local petPen = penButton(petActions, 1)
	petPen.gui.Size = UDim2.new(0.42, -8, 0, 60)
	local inventory = Ui.button(petActions, {
		text = "INVENTORY",
		gradient = "lime",
		size = UDim2.new(0.34, -8, 0, 60),
		textSize = 20,
		name = "Inventory",
		onClick = function()
			Modal.open("Inventory", petButton.gui)
		end,
	})
	inventory.gui.LayoutOrder = 2
	local trade = Ui.button(petActions, {
		text = "TRADE",
		gradient = "purple",
		size = UDim2.new(0.24, 0, 0, 60),
		textSize = 20,
		name = "Trade",
		onClick = function()
			show(nil)
			Drawers.openTrade()
		end,
	})
	trade.gui.LayoutOrder = 3

	refreshPets = function()
		local rows = Data.pets()
		local cap = Data.capacity()
		pets.sub.Text = `{cap.eggs + cap.pets} / {cap.slots} pedestals`
			.. (if cap.eggs + cap.pets >= cap.slots then "  FULL" else "")
		local placed = {}
		for _, row in rows do
			if row.slot then
				table.insert(placed, row)
			end
		end
		table.sort(placed, function(a, b)
			return (a.slot or 0) < (b.slot or 0)
		end)
		local seen: { [string]: boolean } = {}
		for i, d in placed do
			seen[d.uid] = true
			local ui = petRows[d.uid]
			if not ui then
				local f = rowFrame(pets.list, d.uid, i)
				local thumb = Ui.frame(f, "Thumb", UDim2.fromOffset(80, 80), UDim2.fromOffset(8, 8))
				Ui.petArt(thumb, d.model)
				local name = Ui.text(f, d.name, 22, { name = "Name" })
				name.Position = UDim2.fromOffset(98, 6)
				name.Size = UDim2.new(1, -110, 0, 30)
				name.TextColor3 = (Theme.Rarity :: any)[d.rarity] or C.text
				local income = Ui.text(f, "", 20, { color = C.cash, name = "Income" })
				income.Position = UDim2.fromOffset(98, 36)
				income.Size = UDim2.new(1, -110, 0, 26)
				local stored = Ui.text(f, "", 18, { color = C.muted, name = "Stored" })
				stored.Position = UDim2.fromOffset(98, 62)
				stored.Size = UDim2.new(1, -110, 0, 26)
				ui = { frame = f, income = income, stored = stored }
				petRows[d.uid] = ui
			end
			local u = ui :: PetRowUi
			u.frame.LayoutOrder = i
			u.income.Text = `{Ui.money(d.income)}/s · pedestal {d.slot}`
			u.stored.Text = if d.stored > 0
				then `{Ui.money(d.stored)} waiting: step on its pedestal`
				else "Collecting..."
		end
		for uid, ui in petRows do
			if not seen[uid] then
				ui.frame:Destroy()
				petRows[uid] = nil
			end
		end
		petEmpty.Visible = #placed == 0
		local waiting = cap.unplacedPets
		petNote.Text = if waiting > 0
			then `{waiting} pet{if waiting == 1 then "" else "s"} waiting for a free pedestal.`
			else "Pets fill free pedestals automatically."
		paintPen(petPen)
	end

	-- Layout + timers ------------------------------------------------------------------------------------------

	Kit.onLayout(function(compact: boolean)
		local tile = if compact then 88 else 104
		rail.Size = UDim2.fromOffset(tile, 2 * tile + 12)
		rail.AnchorPoint = if compact then Vector2.new(1, 0) else Vector2.new(1, 0.5)
		rail.Position = if compact then UDim2.new(1, -10, 0, 8) else UDim2.new(1, -30, 0.5, 0)
		for _, b in { eggButton, petButton } do
			b.setCompact(compact)
		end
		host.AnchorPoint = if compact then Vector2.new(1, 0) else Vector2.new(1, 0.5)
		host.Position = if compact
			then UDim2.new(1, -(10 + tile + 12), 0, 8)
			else UDim2.new(1, -(30 + tile + 16), 0.5, 0)
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
			local at = petButton.gui.AbsolutePosition + petButton.gui.AbsoluteSize / 2
			Motion.burst(Modal.layer(), at, "sparkle", 10)
		end,
	}
end

-- Set by UI/init: opens A's Trade window.
function Drawers.openTrade() end

return Drawers
