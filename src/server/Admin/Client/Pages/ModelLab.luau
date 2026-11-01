--!strict
-- Model Lab: browse the server's model registry (pets, eggs, Kick Sacks, ServerStorage preview assets), spawn
-- temporary copies, transform them within bounds, compare two side by side, and read honest measurements.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local Theme = W.Theme
	local meta = State.meta
	local LIM = meta.limits.lab

	local filters = { kind = "all", query = "", zone = 0, rarity = "All", page = 1 }
	local chosen: { [string]: any }? = nil -- catalog entry

	-- Left: catalog -------------------------------------------------------------------------------------------
	-- a scrolling stack, so the column also works on short phone screens
	local left = W.scroll(holder, "Catalog", UDim2.new(0.5, -6, 1, 0))
	local search = W.input(left, "🔎 Search models (name, key, zone)", nil)
	search.LayoutOrder = 1
	local filterRow = W.frame(left, "Filters", UDim2.new(1, 0, 0, 38))
	filterRow.LayoutOrder = 2
	local fl = W.Ui.list(filterRow, 6, true)
	fl.VerticalAlignment = Enum.VerticalAlignment.Center
	local loadCatalog: () -> ()
	local function dropIn(
		parent: Instance,
		width: number,
		options: { string },
		value: string,
		labels: { [string]: string }?,
		onPick: (string) -> ()
	)
		local box = W.frame(parent, "D", UDim2.new(width, -4, 1, 0))
		return W.dropdown(box, nil, options, value, onPick, labels)
	end
	dropIn(filterRow, 0.3, { "all", "pet", "egg", "sack", "asset" }, "all", {
		all = "All kinds",
		pet = "Pets",
		egg = "Eggs",
		sack = "Kick Sacks",
		asset = "Preview assets",
	}, function(v)
		filters.kind, filters.page = v, 1
		loadCatalog()
	end)
	local zoneOptions, zoneLabels = { "0" }, { ["0"] = "All zones" }
	for i, name in meta.zones do
		table.insert(zoneOptions, tostring(i))
		zoneLabels[tostring(i)] = `{i}. {name}`
	end
	dropIn(filterRow, 0.36, zoneOptions, "0", zoneLabels, function(v)
		filters.zone, filters.page = tonumber(v) or 0, 1
		loadCatalog()
	end)
	local rarities = { "All" }
	for _, r in meta.rarities do
		table.insert(rarities, r.name)
	end
	dropIn(filterRow, 0.34, rarities, "All", { All = "All rarities" }, function(v)
		filters.rarity, filters.page = v, 1
		loadCatalog()
	end)
	local results = W.scroll(left, "Results", UDim2.new(1, 0, 0, 290))
	results.LayoutOrder = 3
	local pagerHolder = W.frame(left, "Pager", UDim2.new(1, 0, 0, 40))
	pagerHolder.LayoutOrder = 4
	local pager = W.pager(pagerHolder, function(p)
		filters.page = p
		loadCatalog()
	end)
	local info = W.card(left, "Chosen", Color3.fromRGB(28, 32, 46), UDim2.new(1, 0, 0, 196))
	info.LayoutOrder = 5
	W.Ui.padding(info, 8)
	local infoText = W.text(info, "Pick a model to see its asset status.", 15, { wrap = true, color = W.Colors.muted })
	local spawnRow = W.frame(info, "Spawn", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 1, -40))
	local sl = W.Ui.list(spawnRow, 6, true)
	sl.VerticalAlignment = Enum.VerticalAlignment.Center
	local function spawn(placement: string)
		if not chosen then
			W.toast("Pick a model first.", "error")
			return
		end
		local res = Net.request("lab.spawn", { source = chosen.source, placement = placement })
		if W.report(res, `Spawned {chosen.name}.`) then
			State.select(res.data.model.id)
			ctx.App.refreshNow()
		end
	end
	W.button(spawnRow, "PLATFORM", "lime", 120, function()
		spawn("platform")
	end, "First free pad on the lab platform")
	W.button(spawnRow, "NEAR ME", "cyan", 112, function()
		spawn("nearMe")
	end, `{12} studs in front of you`)
	W.button(spawnRow, "A", "violet", 50, function()
		spawn("compareA")
	end, "Compare pad A")
	W.button(spawnRow, "B", "violet", 50, function()
		spawn("compareB")
	end, "Compare pad B")

	local function showChosen(e: { [string]: any })
		chosen = e
		infoText.TextColor3 = W.Colors.text
		infoText.Text = `{e.name} · {e.kind} · {e.zoneName}{if e.zone > 0 then " (zone " .. e.zone .. ")" else ""} · {e.rarity} · version {e.version}\n`
			.. table.concat(e.status, "\n")
			.. `\nAnimations: {if #e.anims > 0 then table.concat(e.anims, ", ") else "none (unrigged)"}`
			.. `\nVFX presets: {if #e.effects > 0 then table.concat(e.effects, ", ") else "none"}`
	end

	loadCatalog = function()
		local res = Net.request("lab.catalog", filters)
		if not res.ok then
			W.report(res)
			return
		end
		W.clear(results)
		for i, e in res.data.entries do
			local b = Instance.new("TextButton")
			b.Name = e.source
			b.LayoutOrder = i
			b.Text = ""
			b.AutoButtonColor = false
			b.Size = UDim2.new(1, 0, 0, 42)
			b.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
			b.BorderSizePixel = 0
			W.Ui.corner(b, 6)
			local missing = string.find(table.concat(e.status, " "), "MISSING", 1, true) ~= nil
			local icon = if e.kind == "pet"
				then "🐾"
				elseif e.kind == "egg" then "🥚"
				elseif e.kind == "sack" then "🥊"
				else "📦"
			local t = W.text(b, `{icon} {e.name}`, 16)
			t.Position = UDim2.fromOffset(8, 1)
			t.Size = UDim2.new(1, -16, 0, 22)
			local s = W.text(
				b,
				`{e.zoneName} · {e.rarity} · {e.version}{if missing then " · ⚠ placeholder" else ""}`,
				13,
				{
					color = if missing then W.Colors.warn else W.Colors.muted,
				}
			)
			s.Position = UDim2.fromOffset(8, 22)
			s.Size = UDim2.new(1, -16, 0, 18)
			b.Activated:Connect(function()
				for _, other in results:GetChildren() do
					if other:IsA("TextButton") then
						other.BackgroundColor3 = Color3.fromRGB(30, 34, 48)
					end
				end
				b.BackgroundColor3 = Color3.fromRGB(40, 110, 170)
				showChosen(e)
			end)
			b.Parent = results
		end
		pager.set(res.data.page, res.data.pages)
	end
	search.FocusLost:Connect(function()
		filters.query, filters.page = string.sub(search.Text, 1, 40), 1
		loadCatalog()
	end)

	-- Right: lab models + controls ------------------------------------------------------------------------------
	local right = W.scroll(holder, "Lab", UDim2.new(0.5, -6, 1, 0), UDim2.new(0.5, 6, 0, 0))
	local topBody = W.section(right, "Lab models", Theme.Headers.training, 1)
	local count = W.text(topBody, "–", 15, { wrap = true, color = W.Colors.muted })
	count.LayoutOrder = 0
	local actions = W.row(topBody, "Actions", 40)
	actions.LayoutOrder = 1
	W.button(actions, "GO TO LAB", "cyan", 140, function()
		W.report(Net.request("players.teleportToLab", {}), "Welcome to the Model Lab.")
	end)
	W.button(actions, "CLEAR MINE", "grey", 140, function()
		if W.report(Net.request("lab.clearMine", {}), "Cleared your models.") then
			ctx.App.refreshNow()
		end
	end)
	if State.can("lab.manageAll") then
		W.button(actions, "CLEAR ALL", "red", 130, function()
			if
				W.confirm(
					"Clear all test models",
					"Remove every admin's lab models and test pen pets on this server?",
					true
				)
			then
				W.report(Net.request("lab.clearAll", { confirmed = true }), "Lab cleared.")
				ctx.App.refreshNow()
			end
		end)
	end
	local modelList = W.vstack(topBody, "Models", 4)
	modelList.LayoutOrder = 2

	local ctl = W.section(right, "Selected model", Theme.Headers.rebirth, 2)
	local selText = W.text(ctl, "Select a lab model above.", 16, { wrap = true })
	selText.LayoutOrder = 0
	local function transform(op: string, extra: { [string]: any })
		local id = State.selected
		if not id then
			W.toast("Select a lab model first.", "error")
			return
		end
		local params = { labId = id, op = op }
		for k, v in extra do
			params[k] = v
		end
		local res = Net.request("lab.transform", params)
		if W.report(res) then
			ctx.App.refreshNow()
		end
	end
	local yaw = W.slider(ctl, "Rotate (degrees)", 0, 359, 1, 0, function(v)
		transform("rotate", { yaw = v })
	end)
	yaw.gui.LayoutOrder = 1
	local scale = W.slider(
		ctl,
		`Scale ({LIM.minScale}–{LIM.maxScale}x)`,
		LIM.minScale,
		LIM.maxScale,
		0.05,
		1,
		function(v)
			transform("scale", { scale = v })
		end
	)
	scale.gui.LayoutOrder = 2
	local moves: { [string]: any } = {}
	local function sendMove()
		transform("move", { dx = moves.dx.get(), dy = moves.dy.get(), dz = moves.dz.get() })
	end
	moves.dx = W.slider(ctl, "Move X (studs)", -LIM.maxOffset, LIM.maxOffset, 0.5, 0, sendMove)
	moves.dz = W.slider(ctl, "Move Z (studs)", -LIM.maxOffset, LIM.maxOffset, 0.5, 0, sendMove)
	moves.dy = W.slider(ctl, "Lift (studs)", 0, LIM.maxLift, 0.5, 0, sendMove)
	moves.dx.gui.LayoutOrder, moves.dz.gui.LayoutOrder, moves.dy.gui.LayoutOrder = 3, 4, 5
	local btns = W.row(ctl, "Buttons", 40, 6)
	btns.LayoutOrder = 6
	W.button(btns, "CENTER", "dark", 100, function()
		transform("center", {})
	end)
	W.button(btns, "RESET", "grey", 90, function()
		transform("reset", {})
	end, "Rotation 0, scale 1, centred on its pad")
	W.button(btns, "MEASURE", "cyan", 110, function()
		ctx.measure()
	end)
	W.button(btns, "DELETE", "red", 100, function()
		local id = State.selected
		if id and W.report(Net.request("lab.delete", { labId = id }), "Deleted.") then
			State.select(nil)
			ctx.App.refreshNow()
		end
	end)
	local measureText = W.text(ctl, "", 15, { wrap = true, color = W.Colors.muted })
	measureText.LayoutOrder = 7

	function ctx.measure()
		local id = State.selected
		if not id then
			return
		end
		local res = Net.request("lab.inspect", { labId = id })
		if not W.report(res) then
			return
		end
		local i = res.data.info
		local lines = {
			string.format(
				"Bounding box: %.2f × %.2f × %.2f studs (scale %.2f)",
				i.bbox[1],
				i.bbox[2],
				i.bbox[3],
				i.scale
			),
			`Parts {i.parts} · MeshParts {i.meshParts} · SpecialMeshes {i.specialMeshes} · Unions {i.unions} · Decals {i.decals}`,
			`Motor6D {i.motors} · welds {i.welds} · bones {i.bones} · attachments {i.attachments}`,
			`Emitters/beams/trails {i.emitters} · lights {i.lights} · rigged: {if i.rigged then "yes" else "NO"}`,
		}
		for _, issue in res.data.issues do
			local mark = if issue.severity == "error" then "⛔" elseif issue.severity == "warn" then "⚠" else "ℹ"
			table.insert(lines, `{mark} {issue.message}`)
		end
		if #res.data.issues == 0 then
			table.insert(lines, "✅ No problems found.")
		end
		measureText.Text = table.concat(lines, "\n")
	end

	local cmp = W.section(right, "Compare two versions", Theme.Headers.index, 3)
	W.text(
		cmp,
		"Both land on the compare pads with the same scale, orientation and spotlights; animate and add VFX to each separately in their tabs.",
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	local sources = {}
	local sourceLabels = {}
	for _, p in (State.command("lab.compare") or { params = {} }).params do
		if p.name == "sourceA" then
			sources = p.options or {}
		end
	end
	for _, s in sources do
		local kind, key = string.match(s, "^(%a+):(.+)$")
		sourceLabels[s] = if kind then `{string.upper(string.sub(kind, 1, 1))}{string.sub(kind, 2)} · {key}` else s
	end
	local aDrop = W.dropdown(cmp, "Model A", sources, sources[1], function() end, sourceLabels)
	local bDrop = W.dropdown(cmp, "Model B", sources, sources[2], function() end, sourceLabels)
	W.button(cmp, "COMPARE", "violet", nil, function()
		local res = Net.request("lab.compare", { sourceA = aDrop.get(), sourceB = bDrop.get() })
		if W.report(res, "Both models are on the compare pads.") then
			ctx.App.refreshNow()
		end
	end)
	aDrop.gui.LayoutOrder, bDrop.gui.LayoutOrder = 2, 3

	local rowByModel: { [string]: TextButton } = {}
	local shownId: string? = nil -- sliders only jump to the model's values when the selection changes
	local function paintSelection()
		for id, b in rowByModel do
			b.BackgroundColor3 = if id == State.selected
				then Color3.fromRGB(40, 110, 170)
				else Color3.fromRGB(30, 34, 48)
		end
		local m = State.model(State.selected)
		if m then
			selText.Text = `{m.name} · {m.slot} · owner {m.owner}{if m.rigged then "" else " · unrigged"}`
			if shownId == m.id then
				return
			end
			shownId = m.id
			measureText.Text = ""
			yaw.set(m.yaw)
			scale.set(m.scale)
			moves.dx.set(m.offset[1])
			moves.dy.set(m.offset[2])
			moves.dz.set(m.offset[3])
		else
			shownId = nil
			selText.Text = "Select a lab model above."
			measureText.Text = ""
		end
	end
	State.on("selected", paintSelection)

	local function refresh()
		local res = Net.poll("lab.list")
		if not (res and res.ok) then
			return
		end
		State.setModels(res.data.models)
		count.Text =
			`{res.data.count} test model(s) on this server · {res.data.pen} in the test pen · your limit {LIM.maxPerAdmin}, server limit {LIM.maxTotal}`
		W.clear(modelList)
		table.clear(rowByModel)
		for i, m in res.data.models do
			if m.pen then
				continue
			end
			local b = Instance.new("TextButton")
			b.Name = m.id
			b.LayoutOrder = i
			b.Text = ""
			b.AutoButtonColor = false
			b.Size = UDim2.new(1, 0, 0, 40)
			b.BorderSizePixel = 0
			W.Ui.corner(b, 6)
			local t = W.text(b, `{m.name} · {m.slot}{if m.mine then "" else " · " .. m.owner}`, 15)
			t.Position = UDim2.fromOffset(8, 0)
			t.Size = UDim2.new(1, -16, 0, 22)
			local s = W.text(
				b,
				`{if m.anim ~= "" then "▶ " .. m.anim else "idle pose"} · {if m.fx ~= ""
					then "✨ " .. m.fx
					else "no VFX"} · {m.version}`,
				13,
				{ color = W.Colors.muted }
			)
			s.Position = UDim2.fromOffset(8, 20)
			s.Size = UDim2.new(1, -16, 0, 18)
			b.Activated:Connect(function()
				State.select(m.id)
			end)
			b.Parent = modelList
			rowByModel[m.id] = b
		end
		paintSelection()
	end

	task.spawn(loadCatalog)
	return { refresh = refresh, every = 3 }
end
