--!strict
-- Dashboard: real numbers from "dashboard.get", refreshed every 5 s while this tab is open.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net = ctx.W, ctx.Net
	local Theme = W.Theme
	local hex = Color3.fromHex

	local scroll = W.scroll(holder, "Scroll")
	local updated = W.text(scroll, "Loading...", 14, { color = W.Colors.muted })
	updated.LayoutOrder = 0

	local tiles = W.frame(scroll, "Tiles", UDim2.new(1, 0, 0, 0))
	tiles.AutomaticSize = Enum.AutomaticSize.Y
	tiles.LayoutOrder = 1
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(176, 84)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = tiles
	local function tile(order: number, title: string, pair: { Color3 }): TextLabel
		local f = W.card(tiles, title, pair)
		f.LayoutOrder = order
		local t = W.text(f, string.upper(title), 14)
		t.Position = UDim2.fromOffset(12, 8)
		t.Size = UDim2.new(1, -24, 0, 18)
		local v = W.text(f, "–", 28, { stroke = 2 })
		v.Name = "Value"
		v.Position = UDim2.fromOffset(12, 32)
		v.Size = UDim2.new(1, -24, 0, 40)
		return v
	end
	local players = tile(1, "Players", Theme.Headers.shop)
	local uptime = tile(2, "Uptime", Theme.Headers.index)
	local memory = tile(3, "Memory", Theme.Headers.training)
	local fps = tile(4, "Physics FPS", Theme.Headers.rebirth)
	local actions = tile(5, "Admin actions", Theme.Headers.eggs)
	local errors = tile(6, "Server errors", { hex("FF6A5A"), hex("C8201A") })

	local serverBody = W.section(scroll, "Server", Theme.Headers.index, 2)
	local sId = W.kv(serverBody, "Server id", "–", 1)
	local sEnv = W.kv(serverBody, "Environment", "–", 2)
	local sVer = W.kv(serverBody, "Version", "–", 3)

	local worldBody = W.section(scroll, "Weather & events", Theme.Headers.confirm, 3)
	local wLight = W.light(worldBody, "off", "–")
	wLight.gui.LayoutOrder = 1
	local wSchedule = W.kv(worldBody, "Schedule", "–", 2)

	local labBody = W.section(scroll, "Test sessions & Model Lab", Theme.Headers.training, 4)
	local lModels = W.kv(labBody, "Spawned test models", "–", 1)
	local lPen = W.kv(labBody, "Test pen pets", "–", 2)
	local lFx = W.kv(labBody, "Models with VFX on", "–", 3)
	local lAdmins = W.kv(labBody, "Admin panels open", "–", 4)
	local lSessions = W.text(labBody, "", 15, { wrap = true, color = W.Colors.muted })
	lSessions.LayoutOrder = 5

	local xBody = W.section(scroll, "Cross-server", Theme.Headers.eggs, 5)
	local xMsg = W.light(xBody, "off", "MessagingService: –")
	local xMem = W.light(xBody, "off", "MemoryStore: –")
	local xList = W.vstack(xBody, "Deliveries", 4)
	xMsg.gui.LayoutOrder, xMem.gui.LayoutOrder, xList.LayoutOrder = 1, 2, 3

	local eBody = W.section(scroll, "Latest server errors", { hex("FF6A5A"), hex("C8201A") }, 6)
	local eList = W.vstack(eBody, "Errors", 4)

	local aBody = W.section(scroll, "Latest admin actions", Theme.Headers.pets, 7)
	local aList = W.vstack(aBody, "Actions", 4)

	local function line(parent: Instance, text: string, color: Color3?)
		local t = W.text(parent, text, 14, { wrap = true, color = color })
		return t
	end

	local function refresh()
		local res = Net.poll("dashboard.get")
		if not res then
			return
		end
		if not res.ok then
			updated.Text = `Couldn't load the dashboard: {res.message}`
			return
		end
		local d = res.data
		updated.Text = `Updated {W.clock(os.time())} · refreshes every 5 s while open`
		players.Text = `{d.server.players} / {d.server.maxPlayers}`
		uptime.Text = W.duration(d.server.uptime)
		memory.Text = if d.server.memoryMb then `{d.server.memoryMb} MB` else "n/a"
		fps.Text = tostring(d.server.physicsFps)
		actions.Text = `{d.audit.total} ({d.audit.failures} failed)`
		errors.Text = tostring(d.errors.count)
		sId.Text = d.server.id
		sEnv.Text = string.upper(d.server.environment)
		sVer.Text = `{d.server.version} · place v{d.server.placeVersion}`
		local w = d.weather
		if w.active then
			wLight.set(
				"ok",
				`{string.upper(w.active)} weather · {W.duration(w.remaining)} left (Weather event running)`
			)
		else
			wLight.set("off", "No weather event running")
		end
		wSchedule.Text = `every {W.duration(w.everySeconds)} for {W.duration(w.durationSeconds)}`
		lModels.Text = tostring(d.lab.models)
		lPen.Text = tostring(d.lab.pen)
		lFx.Text = tostring(d.lab.activeFx)
		lAdmins.Text = tostring(d.lab.adminsOnline)
		local parts = {}
		for _, s in d.lab.sessions do
			table.insert(parts, `{s.name}: {s.models}`)
		end
		lSessions.Text = if #parts > 0
			then "Models per admin: " .. table.concat(parts, ", ")
			else "No test models spawned."
		local h = d.crossServer.health
		xMsg.set(
			if h.messaging == "ok"
				then "ok"
				elseif string.find(h.messaging, "unavailable", 1, true) then "bad"
				else "off",
			`MessagingService: {h.messaging} · received {h.received}, rejected {h.rejected}`
		)
		xMem.set(
			if h.memory == "ok" then "ok" elseif string.find(h.memory, "unavailable", 1, true) then "bad" else "off",
			`MemoryStore: {h.memory}`
		)
		W.clear(xList)
		for _, del in d.crossServer.deliveries do
			line(
				xList,
				`{W.clock(del.at)} {del.command}: {del.status}, {del.acks} acks ({del.failedAcks} refused){if del.counting
					then " · counting"
					else ""}`
			)
		end
		if #d.crossServer.deliveries == 0 then
			line(xList, "No broadcasts from this server yet.", W.Colors.muted)
		end
		W.clear(eList)
		for _, e in d.errors.recent do
			line(eList, `{W.clock(e.at)}  {e.text}`, W.Colors.bad)
		end
		if #d.errors.recent == 0 then
			line(eList, "No errors since the server started.", W.Colors.ok)
		end
		W.clear(aList)
		for _, a in d.audit.latest do
			local mark = if a.outcome == "ok" then "✅" else "⛔"
			line(
				aList,
				`{mark} {W.clock(a.at)}  {a.adminName} · {a.command}{if a.target then " → " .. a.target else ""} · {a.scope}{if a.outcome
						~= "ok"
					then " · " .. a.category
					else ""}`
			)
		end
		if #d.audit.latest == 0 then
			line(aList, "No admin actions yet.", W.Colors.muted)
		end
	end

	return { refresh = refresh, every = 5 }
end
