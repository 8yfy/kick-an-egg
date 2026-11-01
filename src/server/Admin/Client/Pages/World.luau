--!strict
-- Weather & Events: drives the game's own WeatherService (so the HUD widget, timer, toast and world look follow),
-- on this server or all live servers (header scope; needs the global permission). Shows honest delivery status.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local meta = State.meta
	local B = meta.limits.weather

	local scroll = W.scroll(holder, "Scroll")
	local nowBody = W.section(scroll, "Right now", W.Theme.Headers.confirm, 1)
	local light = W.light(nowBody, "off", "Loading...")
	light.gui.LayoutOrder = 1
	local schedule = W.kv(nowBody, "Schedule", "–", 2)
	local globalRow = W.kv(nowBody, "Stored global weather", "–", 3)
	local scopeNote = W.text(nowBody, "", 15, { wrap = true })
	scopeNote.LayoutOrder = 4

	local endsAt: number? = nil
	local active: string? = nil

	local wBody = W.section(scroll, "Weather", W.Theme.Headers.index, 2)
	local weather = W.dropdown(wBody, "Weather", meta.weathers, meta.weathers[1], function() end)
	weather.gui.LayoutOrder = 1
	local seconds = W.slider(
		wBody,
		`Test duration ({B.min}–{B.max} s)`,
		B.min,
		B.max,
		5,
		120,
		function() end,
		function(n)
			return W.duration(n)
		end
	)
	seconds.gui.LayoutOrder = 2
	local row = W.row(wBody, "Buttons", 40, 6)
	row.LayoutOrder = 3
	local delivery = W.text(wBody, "", 14, { wrap = true, color = W.Colors.muted })
	delivery.LayoutOrder = 4

	local function run(cmd: string, params: { [string]: any }, okText: string)
		local scope = State.scopeFor(cmd)
		params.scope = scope
		local c = State.command(cmd)
		if scope == "global" or (c and c.confirm) then
			local yes = W.confirm(
				if scope == "global" then "All live servers" else (c and c.name or cmd),
				if scope == "global"
					then `Run "{c and c.name or cmd}" on EVERY live server? Delivery isn't guaranteed; you'll see acknowledgements here.`
					else (c and c.description or ""),
				scope == "global"
			)
			if not yes then
				return
			end
			params.confirmed = true
		end
		local res = Net.request(cmd, params)
		if W.report(res, okText .. (if scope == "global" then " (all servers)" else "")) then
			if res.delivery then
				delivery.Text = `Broadcast: {string.upper(res.delivery.status)}. {res.delivery.detail or ""}`
			else
				delivery.Text = "Applied on this server."
			end
			ctx.App.refreshNow()
		end
	end
	local canWeather = State.can("weather.server")
	local wButtons = {
		W.button(row, "START", "lime", 120, function()
			run("weather.start", { weather = weather.get(), seconds = seconds.get() }, `{weather.get()} started.`)
		end),
		W.button(row, "STOP", "red", 110, function()
			run("weather.stop", {}, "Weather stopped.")
		end),
		W.button(row, "RESET", "grey", 110, function()
			run("weather.reset", {}, "Weather reset.")
		end, "Stop, and for all servers also clear the stored global weather"),
	}
	for _, b in wButtons do
		b.setEnabled(canWeather)
	end

	local eBody = W.section(scroll, "Registered events", W.Theme.Headers.eggs, 3)
	local eInfo = W.text(eBody, "Loading...", 15, { wrap = true })
	eInfo.LayoutOrder = 1
	local variant = W.dropdown(eBody, "Variant", { "Random" }, "Random", function() end)
	variant.gui.LayoutOrder = 2
	local eSeconds = W.slider(eBody, "Duration", B.min, B.max, 5, 180, function() end, function(n)
		return W.duration(n)
	end)
	eSeconds.gui.LayoutOrder = 3
	local eRow = W.row(eBody, "Buttons", 40, 6)
	eRow.LayoutOrder = 4
	local canEvents = State.can("events.server")
	local eButtons = {
		W.button(eRow, "START EVENT", "lime", 150, function()
			run(
				"events.start",
				{ event = "WeatherEvent", variant = variant.get(), seconds = eSeconds.get() },
				"Event started."
			)
		end),
		W.button(eRow, "STOP EVENT", "red", 150, function()
			run("events.stop", { event = "WeatherEvent" }, "Event stopped.")
		end),
	}
	for _, b in eButtons do
		b.setEnabled(canEvents)
	end
	if not (canWeather and canEvents) then
		local n =
			W.text(eBody, "Your role can view weather and events but not change them.", 14, { color = W.Colors.muted })
		n.LayoutOrder = 5
	end

	local xBody = W.section(scroll, "Broadcast acknowledgements", W.Theme.Headers.shop, 4)
	local xList = W.vstack(xBody, "List", 4)

	local function paintScope()
		local global = State.scope == "global"
		scopeNote.Text = if global
			then "Scope: ALL SERVERS. Actions run here and are broadcast to every live server (needs the Owner permission)."
			else "Scope: THIS SERVER. Switch to ALL SERVERS in the header to broadcast."
		scopeNote.TextColor3 = if global then W.Colors.warn else W.Colors.muted
	end
	State.on("scope", paintScope)
	paintScope()

	local function tick()
		if active and endsAt then
			local left = endsAt - workspace:GetServerTimeNow()
			light.set("ok", `{string.upper(active)} · {W.duration(left)} left`)
		else
			light.set("off", "No weather event running")
		end
	end

	local function refresh()
		local res = Net.poll("weather.status")
		if res and res.ok then
			local s = res.data.state
			active, endsAt = s.active, s.endsAt
			schedule.Text = `every {W.duration(s.everySeconds)} for {W.duration(s.durationSeconds)}`
			local g = res.data.global
			globalRow.Text = if typeof(g) == "table"
				then `{g.weather} until {W.clock(g.endsAt)} (by {g.by})`
				else "none (or MemoryStore unavailable)"
			tick()
		end
		local ev = Net.poll("events.list")
		if ev and ev.ok then
			local e = ev.data.events[1]
			eInfo.Text = `{e.name}: {if e.active
				then "RUNNING (" .. tostring(e.current) .. ", " .. W.duration(e.remaining) .. " left)"
				else "idle"}\n{e.description}`
			variant.setOptions(e.variants)
		end
		local xs = Net.poll("crossserver.status")
		if xs and xs.ok then
			W.clear(xList)
			for _, d in xs.data.deliveries do
				W.text(
					xList,
					`{W.clock(d.at)} {d.command}: {d.status} · {d.acks} server(s) applied, {d.failedAcks} refused{if d.counting
						then " · still counting"
						else ""}`,
					14,
					{ wrap = true }
				)
			end
			if #xs.data.deliveries == 0 then
				W.text(
					xList,
					`No broadcasts from this server yet. MessagingService: {xs.data.health.messaging}.`,
					14,
					{ color = W.Colors.muted }
				)
			end
		end
	end

	-- local 1 s countdown while this tab is visible (no server calls)
	task.spawn(function()
		while holder.Parent do
			task.wait(1)
			if holder.Visible and ctx.App.isOpen() then
				tick()
			end
		end
	end)

	return { refresh = refresh, every = 5 }
end
