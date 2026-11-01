--!strict
-- Animations: play / stop / restart / loop / speed / return to idle / reset pose on a lab model, using only the
-- animations Anim/init implements for that model kind. Unrigged models show an honest disabled state.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local meta = State.meta

	local scroll = W.scroll(holder, "Scroll")
	local body = W.section(scroll, "Animation player", W.Theme.Headers.pets, 1)
	local target = W.dropdown(body, "Lab model", {}, nil, function(v)
		State.select(v)
	end)
	target.gui.LayoutOrder = 1
	local status = W.light(body, "off", "Select a lab model (spawn one in the Model Lab).")
	status.gui.LayoutOrder = 2
	local animDrop = W.dropdown(body, "Animation", {}, nil, function() end)
	animDrop.gui.LayoutOrder = 3
	local speed = W.slider(body, "Speed (0.1x – 3x)", 0.1, 3, 0.05, 1, function() end, function(n)
		return string.format("%.2fx", n)
	end)
	speed.gui.LayoutOrder = 4
	local loop = W.toggle(body, "Loop (off = one cycle, then back to idle)", true, function() end)
	loop.gui.LayoutOrder = 5
	local row = W.row(body, "Buttons", 40, 6)
	row.LayoutOrder = 6
	local row2 = W.row(body, "Buttons2", 40, 6)
	row2.LayoutOrder = 7
	local note = W.text(
		body,
		"One animator per model: starting an animation stops the previous one; deleting the model stops it.",
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	note.LayoutOrder = 8

	local function send(op: string)
		local id = State.selected
		if not id then
			W.toast("Select a lab model first.", "error")
			return
		end
		local res = Net.request("lab.anim", {
			labId = id,
			anim = animDrop.get() or "Idle",
			op = op,
			speed = speed.get(),
			loop = loop.get(),
		})
		if W.report(res) then
			ctx.App.refreshNow()
		end
	end
	local buttons = {
		W.button(row, "▶ PLAY", "lime", 120, function()
			send("play")
		end),
		W.button(row, "■ STOP", "red", 110, function()
			send("stop")
		end),
		W.button(row, "↻ RESTART", "gold", 130, function()
			send("restart")
		end),
		W.button(row2, "RETURN TO IDLE", "cyan", 180, function()
			send("idle")
		end),
		W.button(row2, "RESET POSE", "grey", 150, function()
			send("reset")
		end, "Stops the animation and restores the rest pose"),
	}

	local function paint()
		local labels, ids = {}, {}
		for _, m in State.models do
			if not m.pen then
				table.insert(ids, m.id)
				labels[m.id] = `{m.name} ({m.slot})`
			end
		end
		target.setOptions(ids, labels)
		target.set(State.selected)
		local m = State.model(State.selected)
		local enabled = m ~= nil and m.rigged
		if not m then
			status.set("off", "Select a lab model (spawn one in the Model Lab).")
		elseif not m.rigged then
			status.set("bad", `{m.name} is unrigged (no Motor6D joints): animations are disabled.`)
		else
			status.set(
				"ok",
				`{m.name} · now: {if m.anim ~= ""
					then m.anim .. string.format(" at %.2fx", m.animSpeed)
					else "rest pose"}`
			)
		end
		local list = if m then (meta.anims[m.kind] or {}) else {}
		animDrop.setOptions(list)
		if not animDrop.get() then
			animDrop.set(list[1])
		end
		for _, b in buttons do
			b.setEnabled(enabled)
		end
		animDrop.setEnabled(enabled)
		speed.setEnabled(enabled)
		loop.setEnabled(enabled)
	end
	State.on("models", paint)
	State.on("selected", paint)

	return {
		onShow = paint,
		refresh = function()
			local res = Net.poll("lab.list")
			if res and res.ok then
				State.setModels(res.data.models)
			end
		end,
		every = 3,
	}
end
