--!strict
-- Pets & Eggs: QA of one egg/pet pair (spawn, rock, hatch, idle/walk, auras, signature special, measurements)
-- and the isolated test pen (roaming copies with no owner, income or saved data).

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local Theme = W.Theme

	local scroll = W.scroll(holder, "Scroll")
	local function optionsOf(cmd: string, param: string): { string }
		local c = State.command(cmd)
		for _, p in if c then c.params else {} do
			if p.name == param then
				return p.options or {}
			end
		end
		return {}
	end
	local petIds = optionsOf("lab.pair", "petId")
	local pair = { egg = nil :: string?, pet = nil :: string? }
	local picked = petIds[1]

	local pairBody = W.section(scroll, "Egg + pet pair", Theme.Headers.eggs, 1)
	local info = W.text(pairBody, "Pick a pet.", 15, { wrap = true, color = W.Colors.muted })
	local function loadInfo()
		if not picked then
			return
		end
		local res = Net.request("lab.catalog", { kind = "all", query = picked, page = 1 })
		if not res.ok then
			return
		end
		local lines = {}
		for _, e in res.data.entries do
			if e.source == `pet:{picked}` or e.source == `egg:{picked}` then
				if #lines == 0 then
					table.insert(lines, `{e.zoneName} (zone {e.zone}) · {e.rarity}`)
				end
				table.insert(
					lines,
					`{if e.kind == "pet" then "🐾" else "🥚"} {e.name}: {table.concat(e.status, " · ")}`
				)
			end
		end
		table.insert(
			lines,
			"Animations: Idle, Waddle (walk), Hop, Sleep · eggs rock with EggWobble. No fly animation exists in Anim/init."
		)
		info.Text = table.concat(lines, "\n")
	end
	local petDrop = W.dropdown(pairBody, "Pet", petIds, picked, function(v)
		picked = v
		task.spawn(loadInfo)
	end)
	petDrop.gui.LayoutOrder = -1
	local status = W.text(pairBody, "No pair spawned.", 15, { wrap = true, color = W.Colors.muted })
	status.LayoutOrder = 9

	local function send(cmd: string, params: { [string]: any }, okText: string?): boolean
		local res = Net.request(cmd, params)
		return W.report(res, okText)
	end
	local function need(id: string?, what: string): boolean
		if not id or not State.model(id) then
			W.toast(`Spawn a pair first (no {what} on the platform).`, "error")
			return false
		end
		return true
	end

	local spawnRow = W.row(pairBody, "SpawnRow", 40)
	spawnRow.LayoutOrder = 1
	W.button(spawnRow, "SPAWN PAIR", "lime", 150, function()
		local res = Net.request("lab.pair", { petId = picked })
		if W.report(res, "Pair spawned on the lab platform.") then
			pair.egg, pair.pet = res.data.egg.id, res.data.pet.id
			status.Text = `Egg {pair.egg} · pet {pair.pet}`
			ctx.App.refreshNow()
		end
	end)
	W.button(spawnRow, "GO TO LAB", "cyan", 130, function()
		send("players.teleportToLab", {}, "Welcome to the Model Lab.")
	end)
	W.button(spawnRow, "CHECK PAIR", "dark", 130, function()
		local lines = {}
		for _, id in { pair.egg, pair.pet } do
			if id and State.model(id) then
				local res = Net.request("lab.inspect", { labId = id })
				if res.ok then
					local i = res.data.info
					table.insert(
						lines,
						string.format(
							"%s: %.1f × %.1f × %.1f studs, %d parts, %d joints",
							res.data.model.name,
							i.bbox[1],
							i.bbox[2],
							i.bbox[3],
							i.parts,
							i.motors
						)
					)
					for _, issue in res.data.issues do
						table.insert(
							lines,
							`  {if issue.severity == "error"
								then "⛔"
								elseif issue.severity == "warn" then "⚠"
								else "ℹ"} {issue.message}`
						)
					end
				end
			end
		end
		status.Text = if #lines > 0 then table.concat(lines, "\n") else "Spawn a pair first."
	end)

	local eggRow = W.row(pairBody, "EggRow", 40, 6)
	eggRow.LayoutOrder = 2
	W.text(eggRow, "🥚", 20, { autoX = true })
	W.button(eggRow, "ROCK", "gold", 90, function()
		if need(pair.egg, "egg") then
			send("lab.anim", { labId = pair.egg, anim = "EggWobble", op = "play" })
		end
	end)
	W.button(eggRow, "STILL", "dark", 80, function()
		if need(pair.egg, "egg") then
			send("lab.anim", { labId = pair.egg, op = "stop" })
		end
	end)
	W.button(eggRow, "AURA", "violet", 90, function()
		if need(pair.egg, "egg") then
			send("lab.vfx", { labId = pair.egg, op = "enable", effect = "Idle", seconds = 60 })
		end
	end, "The egg's own PetFx aura (60 s)")
	W.button(eggRow, "HATCH", "orange", 100, function()
		if need(pair.egg, "egg") and send("lab.hatch", { labId = pair.egg }, "Hatching...") then
			pair.egg = nil
		end
	end, "Crack, burst, then the pet appears with its reveal")

	local petRow = W.row(pairBody, "PetRow", 40, 6)
	petRow.LayoutOrder = 3
	W.text(petRow, "🐾", 20, { autoX = true })
	for _, a in { { "IDLE", "Idle" }, { "WALK", "Waddle" }, { "HOP", "Hop" }, { "SLEEP", "Sleep" } } do
		W.button(petRow, a[1], "cyan", 80, function()
			if need(pair.pet, "pet") then
				send("lab.anim", { labId = pair.pet, anim = a[2], op = "play" })
			end
		end)
	end
	local petRow2 = W.row(pairBody, "PetRow2", 40, 6)
	petRow2.LayoutOrder = 4
	W.button(petRow2, "IDLE VFX", "violet", 120, function()
		if need(pair.pet, "pet") then
			send("lab.vfx", { labId = pair.pet, op = "enable", effect = "Idle", seconds = 60 })
		end
	end)
	W.button(petRow2, "SIGNATURE", "orange", 130, function()
		if need(pair.pet, "pet") then
			send("lab.vfx", { labId = pair.pet, op = "special" })
		end
	end, "Fires the recipe's timed special bursts once (e.g. the Frost Serpent's breath)")
	W.button(petRow2, "VFX OFF", "dark", 110, function()
		for _, id in { pair.egg, pair.pet } do
			if id and State.model(id) then
				send("lab.vfx", { labId = id, op = "reset" })
			end
		end
	end)

	-- test pen ------------------------------------------------------------------------------------------------
	local pen = W.section(scroll, "Test pen", Theme.Headers.shop, 2)
	W.text(
		pen,
		"Copies roam an isolated fenced pen on the lab platform with the game's own spot picker. They have no owner, earn nothing and are never saved.",
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	local penPet = petIds[1]
	local penSize = "None"
	local pd = W.dropdown(pen, "Pet", petIds, penPet, function(v)
		penPet = v
	end)
	local sizes = optionsOf("lab.pen.add", "size")
	local sd = W.dropdown(pen, "Size mutation", sizes, "None", function(v)
		penSize = v
	end)
	pd.gui.LayoutOrder, sd.gui.LayoutOrder = 1, 2
	local penRow = W.row(pen, "PenRow", 40, 6)
	penRow.LayoutOrder = 3
	W.button(penRow, "ADD TO PEN", "lime", 140, function()
		send("lab.pen.add", { petId = penPet, size = penSize }, "Added to the test pen.")
	end)
	W.button(penRow, "RESET MINE", "grey", 130, function()
		send("lab.pen.clear", { everyone = false }, "Your pen pets were removed.")
	end)
	if State.can("lab.manageAll") then
		W.button(penRow, "RESET ALL", "red", 120, function()
			send("lab.pen.clear", { everyone = true }, "Test pen emptied.")
		end)
	end
	local checkText = W.text(pen, "", 15, { wrap = true })
	checkText.LayoutOrder = 5
	local checkBtn = W.button(pen, "CHECK PEN", "cyan", nil, function()
		local res = Net.request("lab.pen.check", {})
		if not W.report(res) then
			return
		end
		local lines = {}
		for _, p in res.data.pets do
			local problems = {}
			for _, issue in p.issues do
				if issue.severity ~= "info" then
					table.insert(problems, issue.message)
				end
			end
			table.insert(
				lines,
				`{if #problems == 0 then "✅" else "⚠"} {p.model.name}{if #problems > 0
					then ": " .. table.concat(problems, " ")
					else ""}`
			)
		end
		for _, o in res.data.overlaps do
			table.insert(lines, `⚠ clipping: {o}`)
		end
		checkText.Text = if #lines > 0 then table.concat(lines, "\n") else "The test pen is empty."
	end, "Floating parts, broken joints, invisibility, unrigged pets, floor clipping, overlaps")
	checkBtn.gui.LayoutOrder = 4

	task.spawn(loadInfo)
	return {
		refresh = function()
			local res = Net.poll("lab.list")
			if res and res.ok then
				State.setModels(res.data.models)
			end
		end,
		every = 4,
	}
end
