--!strict
-- Logs: this server's audit log (filter by admin, command, server, outcome, time, text; 25 per page), and for
-- Owners the expiring all-servers log of global-scope actions. Refreshes every 10 s while open.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State

	local filters: { [string]: any } = { outcome = "any", sinceMinutes = 0, page = 1 }
	local globalMode = false

	local top = W.frame(holder, "Filters", UDim2.new(1, 0, 0, 84))
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(1 / 3, -6, 0, 38)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = top
	local refresh: () -> ()
	local function cell(order: number): Frame
		local f = W.frame(top, `Cell{order}`)
		f.LayoutOrder = order
		return f
	end
	local outcome = W.dropdown(cell(1), nil, { "any", "ok", "fail" }, "any", function(v)
		filters.outcome, filters.page = v, 1
		refresh()
	end, { any = "Any outcome", ok = "Succeeded", fail = "Failed" })
	local since = W.dropdown(cell(2), nil, { "0", "15", "60", "1440" }, "0", function(v)
		filters.sinceMinutes, filters.page = tonumber(v) or 0, 1
		refresh()
	end, { ["0"] = "Any time", ["15"] = "Last 15 min", ["60"] = "Last hour", ["1440"] = "Last 24 h" })
	local textBox = W.input(cell(3), "🔎 Text", nil)
	local commandDrop = W.dropdown(cell(4), nil, { "" }, "", function(v)
		filters.command, filters.page = if v ~= "" then v else nil, 1
		refresh()
	end, { [""] = "All commands" })
	local serverDrop = W.dropdown(cell(5), nil, { "" }, "", function(v)
		filters.server, filters.page = if v ~= "" then v else nil, 1
		refresh()
	end, { [""] = "All servers" })
	local adminDrop = W.dropdown(cell(6), nil, { "" }, "", function(v)
		filters.admin, filters.page = if v ~= "" then tonumber(v) else nil, 1
		refresh()
	end, { [""] = "All admins" })
	textBox.FocusLost:Connect(function()
		filters.text, filters.page = if textBox.Text ~= "" then string.sub(textBox.Text, 1, 40) else nil, 1
		refresh()
	end)
	local _ = outcome
	local _2 = since

	local header = W.frame(holder, "Bar", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 90))
	local bl = W.Ui.list(header, 8, true)
	bl.VerticalAlignment = Enum.VerticalAlignment.Center
	local count = W.text(header, "–", 15, { autoX = true, color = W.Colors.muted })
	count.LayoutOrder = 1
	local pager = W.pager(header, function(p)
		filters.page = p
		refresh()
	end)
	pager.gui.Size = UDim2.fromOffset(220, 40)
	pager.gui.LayoutOrder = 2
	if State.can("logs.global") then
		local g = W.button(
			header,
			"ALL-SERVERS LOG",
			"orange",
			190,
			function() end,
			"Global-scope actions from every server (MemoryStore copy, last day)"
		)
		g.gui.LayoutOrder = 3
		g.gui.Activated:Connect(function()
			globalMode = not globalMode
			g.setText(if globalMode then "THIS SERVER" else "ALL-SERVERS LOG")
			refresh()
		end)
	end

	local list = W.scroll(holder, "Entries", UDim2.new(1, 0, 1, -136), UDim2.fromOffset(0, 136))

	local function row(i: number, e: { [string]: any })
		local f = Instance.new("Frame")
		f.Name = tostring(e.id or i)
		f.LayoutOrder = i
		f.Size = UDim2.new(1, 0, 0, 46)
		f.BackgroundColor3 = if e.outcome == "ok" then Color3.fromRGB(28, 40, 34) else Color3.fromRGB(48, 28, 30)
		f.BorderSizePixel = 0
		W.Ui.corner(f, 6)
		local mark = if e.outcome == "ok" then "✅" else "⛔"
		local a = W.text(
			f,
			`{mark} {W.clock(e.at)} · {e.adminName} ({e.role}) · {e.command}{if e.target
				then " → " .. e.target
				else ""} · {string.upper(e.scope)}`,
			15
		)
		a.Position = UDim2.fromOffset(8, 2)
		a.Size = UDim2.new(1, -16, 0, 22)
		local detail =
			`{e.category}{if e.message then ": " .. e.message else ""} · {e.params ~= "" and e.params or "no params"} · server {string.sub(
				e.server or "?",
				1,
				13
			)}{if e.origin then " from " .. string.sub(e.origin, 1, 13) else ""} · ref {string.sub(
				e.correlation or "",
				1,
				8
			)}`
		local b = W.text(f, detail, 13, { color = W.Colors.muted })
		b.Position = UDim2.fromOffset(8, 24)
		b.Size = UDim2.new(1, -16, 0, 18)
		f.Parent = list
	end

	local function facets(drop: any, values: { string }, all: string, labelOf: ((string) -> (string, string))?)
		local opts, labels = { "" }, { [""] = all }
		for _, v in values do
			local value, label = v, v
			if labelOf then
				value, label = labelOf(v)
			end
			table.insert(opts, value)
			labels[value] = label
		end
		drop.setOptions(opts, labels)
	end

	refresh = function()
		W.clear(list)
		if globalMode then
			local res = Net.request("logs.global", {})
			if not res.ok then
				W.text(list, `All-servers log unavailable: {res.message}`, 15, { color = W.Colors.bad })
				count.Text = "–"
				return
			end
			for i, e in res.data.entries do
				row(i, e)
			end
			count.Text = `{#res.data.entries} global action(s), last day`
			pager.set(1, 1)
			return
		end
		local res = Net.poll("logs.query", filters)
		if not res then
			return
		end
		if not res.ok then
			W.report(res)
			return
		end
		for i, e in res.data.entries do
			row(i, e)
		end
		if #res.data.entries == 0 then
			W.text(list, "No entries match.", 15, { color = W.Colors.muted })
		end
		count.Text = `{res.data.total} entr{if res.data.total == 1 then "y" else "ies"}`
		pager.set(res.data.page, res.data.pages)
		facets(commandDrop, res.data.facets.commands, "All commands")
		facets(serverDrop, res.data.facets.servers, "All servers", function(v)
			return v, string.sub(v, 1, 18)
		end)
		facets(adminDrop, res.data.facets.admins, "All admins", function(v)
			local name, id = string.match(v, "^(.*)|(%-?%d+)$")
			return id or v, `{name or v} ({id or "?"})`
		end)
	end

	return { refresh = refresh, every = 10 }
end
