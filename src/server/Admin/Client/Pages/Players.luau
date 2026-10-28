--!strict
-- Players: search (name / display name / UserId, for targeting only), read-only inspection from the game's own
-- data, teleports, progression TEST edits (server refuses them outside Studio in-memory data / staging) and
-- moderation (Owner; confirmed, reason logged).

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local Theme = W.Theme

	local selected: number? = nil
	local listPage, petPage = 1, 1
	local query = ""

	local left = W.card(holder, "List", W.Colors.card, UDim2.new(0.4, -6, 1, 0))
	W.Ui.padding(left, 10)
	local search = W.input(left, "🔎 Search name or UserId", nil)
	local list = W.scroll(left, "Players", UDim2.new(1, 0, 1, -96), UDim2.fromOffset(0, 44))
	local pagerHolder = W.frame(left, "PagerHolder", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 1, -40))
	local refresh: () -> ()
	local pager = W.pager(pagerHolder, function(p)
		listPage = p
		refresh()
	end)

	local right = W.scroll(holder, "Detail", UDim2.new(0.6, -6, 1, 0), UDim2.new(0.4, 6, 0, 0))
	local hint = W.text(right, "Pick a player on the left.", 17, { color = W.Colors.muted })
	hint.LayoutOrder = 0

	local summary = W.section(right, "Player", Theme.Headers.shop, 1)
	local rows: { [string]: TextLabel } = {}
	for i, key in
		{
			"Name",
			"UserId",
			"Zone",
			"Money",
			"Kick Power",
			"Run Speed",
			"Rebirths",
			"Pen",
			"Income",
			"Eggs",
			"Pets",
			"Data",
		}
	do
		rows[key] = W.kv(summary, key, "–", i)
	end
	local petsBody = W.section(right, "Pets (read-only)", Theme.Headers.pets, 2)
	local petList = W.vstack(petsBody, "PetList", 2)
	petList.LayoutOrder = 1
	local petPager = W.pager(petsBody, function(p)
		petPage = p
		refresh()
	end)
	petPager.gui.LayoutOrder = 2
	local eggText = W.text(petsBody, "", 15, { wrap = true, color = W.Colors.muted })
	eggText.LayoutOrder = 3

	local tpBody = W.section(right, "Teleport", Theme.Headers.index, 3)
	local tpRow = W.row(tpBody, "Row", 40)
	local function run(cmd: string, params: { [string]: any }, okText: string, confirmText: string?, danger: boolean?)
		local c = State.command(cmd)
		if c and (c.confirm or confirmText) then
			local yes = W.confirm(c.name, confirmText or c.description, danger)
			if not yes then
				return
			end
			params.confirmed = true
		end
		local res = Net.request(cmd, params)
		if W.report(res, okText) then
			refresh()
		end
	end
	if State.can("players.teleport.self") then
		W.button(tpRow, "GO TO THEM", "cyan", 160, function()
			if selected then
				run("players.teleportToPlayer", { userId = selected }, "Teleported.")
			end
		end)
	end
	if State.can("players.teleport.others") then
		W.button(tpRow, "→ KICK PAD", "violet", 150, function()
			if selected then
				run("players.teleportPlayer", { userId = selected, spot = "KickPad" }, "Moved to the kick pad.")
			end
		end, "Only players of a lower rank, never mid-chase")
		W.button(tpRow, "→ THEIR PEN", "violet", 150, function()
			if selected then
				run("players.teleportPlayer", { userId = selected, spot = "TheirPen" }, "Moved to their pen.")
			end
		end)
	end

	local progBody = W.section(right, "Progression test edits", Theme.Headers.eggs, 4)
	local env = tostring(State.meta.environment)
	local progAllowed = State.can("players.progression") and (env == "studio" or env == "staging")
	local note = W.text(
		progBody,
		if not State.can("players.progression")
			then "Your role can't edit progression."
			elseif
				not progAllowed
			then `Disabled on {string.upper(env)} servers: test edits must never touch production data.`
			else "TEST DATA ONLY. In Studio these work only while the game uses in-memory data (API access off); the server re-checks every edit.",
		15,
		{ wrap = true, color = if progAllowed then W.Colors.warn else W.Colors.muted }
	)
	note.LayoutOrder = 0
	local function optionsOf(cmd: string, param: string): { string }
		local c = State.command(cmd)
		for _, p in if c then c.params else {} do
			if p.name == param then
				return p.options or {}
			end
		end
		return {}
	end
	local statDrop = W.dropdown(progBody, "Stat", optionsOf("players.setStat", "stat"), "money", function() end)
	statDrop.gui.LayoutOrder = 1
	local valueBox = W.input(progBody, "Value (whole number)", nil)
	valueBox.LayoutOrder = 2
	local setBtn = W.button(progBody, "SET STAT", "gold", nil, function()
		local n = tonumber(valueBox.Text)
		if selected and n then
			run("players.setStat", { userId = selected, stat = statDrop.get(), value = math.floor(n) }, "Stat set.")
		else
			W.toast("Enter a number first.", "error")
		end
	end)
	setBtn.gui.LayoutOrder = 3
	local petDrop = W.dropdown(progBody, "Pet / egg", optionsOf("players.giveEgg", "petId"), nil, function() end)
	petDrop.gui.LayoutOrder = 4
	local sizeDrop = W.dropdown(progBody, "Size mutation", optionsOf("players.giveEgg", "size"), "None", function() end)
	sizeDrop.gui.LayoutOrder = 5
	local weatherDrop = W.dropdown(
		progBody,
		"Weather mutation",
		optionsOf("players.giveEgg", "weather"),
		"None",
		function() end
	)
	weatherDrop.gui.LayoutOrder = 6
	local giveRow = W.row(progBody, "Give", 40)
	giveRow.LayoutOrder = 7
	local function give(cmd: string)
		if not (selected and petDrop.get()) then
			W.toast("Pick a player and a pet first.", "error")
			return
		end
		run(
			cmd,
			{ userId = selected, petId = petDrop.get(), size = sizeDrop.get(), weather = weatherDrop.get() },
			"Granted."
		)
	end
	local giveEgg = W.button(giveRow, "GIVE EGG", "lime", 150, function()
		give("players.giveEgg")
	end)
	local givePet = W.button(giveRow, "GIVE PET", "lime", 150, function()
		give("players.givePet")
	end)
	for _, b in { setBtn, giveEgg, givePet } do
		b.setEnabled(progAllowed)
	end
	for _, d in { statDrop, petDrop, sizeDrop, weatherDrop } do
		d.setEnabled(progAllowed)
	end

	if State.can("players.moderate") then
		local modBody = W.section(right, "Moderation", W.Theme.Buttons.red, 5)
		W.text(
			modBody,
			"Kick removes a lower-rank player from this server. You must confirm and give a reason; both are logged.",
			15,
			{ wrap = true, color = W.Colors.muted }
		)
		W.button(modBody, "KICK FROM SERVER", "red", nil, function()
			if not selected then
				return
			end
			local yes, reason = W.confirm("Kick player", `Remove UserId {selected} from this server?`, true, true)
			if yes then
				local res = Net.request("players.kick", { userId = selected, reason = reason, confirmed = true })
				W.report(res, "Player removed.")
				refresh()
			end
		end)
	end

	local rowsByUser: { [number]: TextButton } = {}
	local function paintRows()
		for uid, b in rowsByUser do
			b.BackgroundColor3 = if uid == selected then Color3.fromRGB(40, 110, 170) else Color3.fromRGB(30, 34, 48)
		end
	end

	local function showDetail(d: { [string]: any })
		hint.Visible = false
		rows.Name.Text = `{d.displayName} (@{d.name})`
		rows.UserId.Text = tostring(d.userId)
		rows.Zone.Text = d.zone .. (if d.busy then " · in a chase" else "")
		rows.Money.Text = W.Ui.money(d.money)
		rows["Kick Power"].Text = W.Ui.number(d.kickPower)
		rows["Run Speed"].Text = string.format("level %d (%.1f studs/s)", d.speedLevel, d.runSpeed)
		rows.Rebirths.Text = tostring(d.rebirths)
		rows.Pen.Text = `level {d.penLevel} · {d.penSlots} slots · base {d.base or "–"}`
		rows.Income.Text = W.Ui.money(d.income) .. "/s"
		rows.Eggs.Text = `{d.eggCount} held · {d.hatching} hatching`
		rows.Pets.Text = `{d.petCount} owned · {d.placedPets} in pen`
		rows.Data.Text = if d.persistent then "saved DataStore profile" else "in-memory (never saved)"
		W.clear(petList)
		for _, p in d.pets do
			local tags = {}
			if p.size then
				table.insert(tags, p.size)
			end
			if p.weather then
				table.insert(tags, p.weather)
			end
			local color = W.Theme.Rarity and W.Theme.Rarity[p.rarity]
			W.text(
				petList,
				`{if p.placed then "🏠" else "🎒"} {p.name} · {p.rarity}{if #tags > 0
					then " · " .. table.concat(tags, " ")
					else ""}`,
				15,
				{
					color = if typeof(color) == "Color3" then color else nil,
				}
			)
		end
		if #d.pets == 0 then
			W.text(petList, "No pets.", 15, { color = W.Colors.muted })
		end
		petPager.set(d.petPage, d.petPages)
		local eggs = {}
		for _, e in d.eggs do
			table.insert(eggs, e.name)
		end
		eggText.Text = if #eggs > 0 then "Eggs: " .. table.concat(eggs, ", ") else "No eggs held."
	end

	refresh = function()
		local res = Net.poll("players.list", { query = query, page = listPage })
		if res and res.ok then
			W.clear(list)
			table.clear(rowsByUser)
			for i, p in res.data.players do
				local b = Instance.new("TextButton")
				b.Name = tostring(p.userId)
				b.LayoutOrder = i
				b.Text = ""
				b.AutoButtonColor = false
				b.Size = UDim2.new(1, 0, 0, 46)
				b.BorderSizePixel = 0
				W.Ui.corner(b, 6)
				local t = W.text(b, `{p.displayName} (@{p.name})`, 16)
				t.Position = UDim2.fromOffset(8, 2)
				t.Size = UDim2.new(1, -16, 0, 22)
				local s = W.text(
					b,
					`{p.userId} · {p.zone}{if p.busy then " · chasing" else ""}`,
					13,
					{ color = W.Colors.muted }
				)
				s.Position = UDim2.fromOffset(8, 24)
				s.Size = UDim2.new(1, -16, 0, 18)
				b.Activated:Connect(function()
					selected = p.userId
					petPage = 1
					paintRows()
					task.spawn(refresh)
				end)
				b.Parent = list
				rowsByUser[p.userId] = b
			end
			paintRows()
			pager.set(res.data.page, res.data.pages)
		end
		if selected then
			local d = Net.request("players.inspect", { userId = selected, petPage = petPage })
			if d.ok then
				showDetail(d.data)
			elseif d.code == "not_found" then
				selected = nil
				hint.Visible = true
				hint.Text = "That player left."
			end
		end
	end

	search.FocusLost:Connect(function()
		query = string.sub(search.Text, 1, 40)
		listPage = 1
		refresh()
	end)

	return { refresh = refresh, every = 5 }
end
