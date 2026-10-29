--!strict
-- Server Scripts: the runner for the server's registry of APPROVED commands. There is no free-form Lua, no
-- loadstring, no module paths, asset ids or function names: the list, the parameter forms and their bounds all
-- come from the server's registry ("session.hello"), and the server re-validates every run.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State

	local runnable = {}
	for _, c in State.meta.commands or {} do
		if c.runner then
			table.insert(runnable, c)
		end
	end
	table.sort(runnable, function(a, b)
		return (a.runnerName or a.name) < (b.runnerName or b.name)
	end)

	local left = W.card(holder, "Registry", W.Colors.card, UDim2.new(0.38, -6, 1, 0))
	W.Ui.padding(left, 10)
	W.text(left, "APPROVED COMMANDS", 17)
	local list = W.scroll(left, "List", UDim2.new(1, 0, 1, -30), UDim2.fromOffset(0, 30))
	local right = W.scroll(holder, "Runner", UDim2.new(0.62, -6, 1, 0), UDim2.new(0.38, 6, 0, 0))
	local formBody = W.section(right, "Run", { Color3.fromHex("FF7A5C"), Color3.fromHex("D83A2E") }, 1)
	local resultBody = W.section(right, "Result", W.Theme.Headers.index, 2)
	local resultText = W.text(resultBody, "Nothing run yet.", 15, { wrap = true, color = W.Colors.muted })
	local historyBody = W.section(right, "This session", W.Theme.Headers.pets, 3)
	local history = W.vstack(historyBody, "History", 4)
	local runs: { string } = {}

	local current: { [string]: any }? = nil
	local getters: { [string]: () -> any } = {}

	local function field(p: { [string]: any }, order: number)
		local label = `{p.label}{if p.optional then " (optional)" else ""}`
		local get: () -> any
		if p.type == "enum" then
			local d = W.dropdown(
				formBody,
				label,
				p.options or {},
				p.default or (p.options and p.options[1]),
				function() end
			)
			d.gui.LayoutOrder = order
			get = d.get
		elseif p.name == "labId" then
			-- lab targets: the server accepts a lab model id or "latest" (your newest model)
			local ids, labels = { "latest" }, { latest = "Your newest lab model" }
			for _, m in State.models do
				if not m.pen then
					table.insert(ids, m.id)
					labels[m.id] = `{m.name} ({m.slot})`
				end
			end
			local d = W.dropdown(formBody, label, ids, "latest", function() end, labels)
			d.gui.LayoutOrder = order
			get = d.get
		elseif p.type == "number" then
			local step = if p.integer then 1 else (if p.max - p.min <= 10 then 0.05 else 1)
			local s = W.slider(
				formBody,
				`{label} ({p.min}–{p.max})`,
				p.min,
				p.max,
				step,
				p.default or p.min,
				function() end
			)
			s.gui.LayoutOrder = order
			get = s.get
		elseif p.type == "boolean" then
			local t = W.toggle(formBody, label, p.default == true, function() end)
			t.gui.LayoutOrder = order
			get = t.get
		else
			local t = W.text(formBody, label, 15, { color = W.Colors.muted })
			t.LayoutOrder = order
			local box = W.input(formBody, p.description or "", nil)
			box.LayoutOrder = order + 1
			get = function()
				if p.type == "userId" then
					return tonumber(box.Text)
				end
				return if box.Text ~= "" then box.Text else nil
			end
		end
		getters[p.name] = get
	end

	local function show(c: { [string]: any })
		current = c
		W.clear(formBody)
		table.clear(getters)
		local title = W.text(formBody, c.runnerName or c.name, 22, { stroke = 2 })
		title.LayoutOrder = 0
		local desc = W.text(
			formBody,
			`{c.description}\nid {c.id} · cooldown {c.cooldown}s{if c.confirm then " · needs confirmation" else ""}{if c.environments
				then " · only in " .. table.concat(c.environments, ", ")
				else ""}`,
			14,
			{
				wrap = true,
				color = W.Colors.muted,
			}
		)
		desc.LayoutOrder = 1
		for i, p in c.params do
			field(p, 10 + i * 2)
		end
		local scopes = W.text(
			formBody,
			`Scope: {State.scopeFor(c.id) == "global" and "ALL SERVERS" or "THIS SERVER"} (header){if #c.scopes
					> 1
				then ""
				else " · this command only runs on one server"}`,
			14,
			{
				color = W.Colors.muted,
			}
		)
		scopes.LayoutOrder = 98
		local run = W.button(formBody, "RUN", "lime", nil, function()
			local cmd = current
			if not cmd then
				return
			end
			local params: { [string]: any } = { scope = State.scopeFor(cmd.id) }
			for name, get in getters do
				local v = get()
				if v ~= nil then
					params[name] = v
				end
			end
			if cmd.confirm or params.scope == "global" then
				local yes = W.confirm(
					cmd.runnerName or cmd.name,
					`Run {cmd.runnerName or cmd.name}{if params.scope == "global" then " on ALL live servers" else ""}?`,
					params.scope == "global"
				)
				if not yes then
					return
				end
				params.confirmed = true
			end
			local res = Net.request(cmd.id, params)
			local lines = {
				`{W.clock(res.at or os.time())} · {cmd.runnerName or cmd.name} · {if res.ok then "OK" else "FAILED"} [{res.code}]`,
				res.message,
				`Audit ref: {res.correlation or "–"}`,
			}
			if res.delivery then
				table.insert(lines, `Broadcast: {string.upper(res.delivery.status)}. {res.delivery.detail or ""}`)
			end
			if res.ok and typeof(res.data) == "table" then
				local keys = {}
				for k, v in res.data do
					if typeof(v) ~= "table" then
						table.insert(keys, `{k} = {tostring(v)}`)
					end
				end
				table.sort(keys)
				if #keys > 0 then
					table.insert(lines, table.concat(keys, " · "))
				end
			end
			resultText.Text = table.concat(lines, "\n")
			resultText.TextColor3 = if res.ok then W.Colors.ok else W.Colors.bad
			table.insert(runs, 1, lines[1])
			if #runs > 10 then
				table.remove(runs)
			end
			W.clear(history)
			for _, r in runs do
				W.text(history, r, 14)
			end
		end)
		run.gui.LayoutOrder = 99
		run.setEnabled(c.available)
		if not c.available then
			local n = W.text(formBody, "Not available in this environment.", 14, { color = W.Colors.bad })
			n.LayoutOrder = 100
		end
	end

	for i, c in runnable do
		local b = Instance.new("TextButton")
		b.Name = c.runnerName or string.gsub(c.id, "%.", "_")
		b.LayoutOrder = i
		b.Text = ""
		b.AutoButtonColor = false
		b.Size = UDim2.new(1, 0, 0, 52)
		b.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
		b.BorderSizePixel = 0
		W.Ui.corner(b, 6)
		local t = W.text(b, c.runnerName or c.name, 16)
		t.Position = UDim2.fromOffset(8, 3)
		t.Size = UDim2.new(1, -16, 0, 22)
		local s = W.text(b, c.description, 13, { color = W.Colors.muted })
		s.Position = UDim2.fromOffset(8, 26)
		s.Size = UDim2.new(1, -16, 0, 20)
		b.Activated:Connect(function()
			for _, o in list:GetChildren() do
				if o:IsA("TextButton") then
					o.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
				end
			end
			b.BackgroundColor3 = Color3.fromRGB(40, 110, 170)
			show(c)
		end)
		b.Parent = list
	end
	if #runnable == 0 then
		W.text(list, "Your role has no runnable commands.", 15, { color = W.Colors.muted })
	else
		W.text(formBody, "Pick a command on the left.", 16, { color = W.Colors.muted })
	end
	State.on("scope", function()
		if current then
			show(current)
		end
	end)

	return {}
end
