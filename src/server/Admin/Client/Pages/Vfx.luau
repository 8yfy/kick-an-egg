--!strict
-- VFX: the effects that really exist for the selected lab model (its PetFx idle recipe, weather overlays,
-- VFX/init one-shots, the recipe's signature special), with quality presets, a bounded duration, one-shot
-- cooldowns and a server-wide cap on models with effects on. Plus registered demos at the lab's demo spot.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local meta = State.meta

	local scroll = W.scroll(holder, "Scroll")
	local body = W.section(scroll, "Model effects", W.Theme.Headers.rebirth, 1)
	local target = W.dropdown(body, "Lab model", {}, nil, function(v)
		State.select(v)
	end)
	target.gui.LayoutOrder = 1
	local status = W.light(body, "off", "Select a lab model.")
	status.gui.LayoutOrder = 2
	local effect = W.dropdown(body, "Looping effect", {}, nil, function() end, { Idle = "Idle (its own PetFx recipe)" })
	effect.gui.LayoutOrder = 3
	local quality = W.dropdown(body, "Quality preset", { "Low", "Medium", "High" }, "Medium", function() end)
	quality.gui.LayoutOrder = 4
	local seconds = W.slider(
		body,
		`Switch off after (1–{meta.limits.vfx.maxSeconds} s)`,
		1,
		meta.limits.vfx.maxSeconds,
		1,
		30,
		function() end
	)
	seconds.gui.LayoutOrder = 5
	local row = W.row(body, "Loop", 40, 6)
	row.LayoutOrder = 6
	local shot = W.dropdown(body, "One-shot", {}, nil, function() end)
	shot.gui.LayoutOrder = 7
	local row2 = W.row(body, "Shots", 40, 6)
	row2.LayoutOrder = 8
	local note = W.text(
		body,
		`At most {meta.limits.vfx.maxActive} lab models may have looping effects on at once (server-enforced). Deleting a model removes its effects.`,
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	note.LayoutOrder = 9

	local function send(op: string, extra: { [string]: any }?)
		local id = State.selected
		if not id then
			W.toast("Select a lab model first.", "error")
			return
		end
		local params: { [string]: any } = { labId = id, op = op, quality = quality.get(), seconds = seconds.get() }
		for k, v in extra or {} do
			params[k] = v
		end
		if W.report(Net.request("lab.vfx", params)) then
			ctx.App.refreshNow()
		end
	end
	local buttons = {
		W.button(row, "ENABLE", "lime", 120, function()
			send("enable", { effect = effect.get() })
		end),
		W.button(row, "DISABLE", "dark", 120, function()
			send("disable")
		end),
		W.button(row, "RESET", "grey", 100, function()
			send("reset")
		end, "Removes every effect on this model"),
		W.button(row2, "PLAY ONE-SHOT", "orange", 170, function()
			send("oneshot", { effect = shot.get() })
		end),
		W.button(row2, "SIGNATURE", "violet", 140, function()
			send("special")
		end, "Fires the recipe's timed special bursts once"),
	}

	local demo = W.section(scroll, "Demo spot", W.Theme.Headers.index, 2)
	W.text(
		demo,
		"Plays a registered VFX one-shot at the Model Lab's demo spot (in front of the compare pads).",
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	local demoDrop = W.dropdown(demo, "Effect", meta.demoEffects, meta.demoEffects[1], function() end)
	demoDrop.gui.LayoutOrder = 1
	local demoBtn = W.button(demo, "RUN DEMO", "cyan", nil, function()
		W.report(Net.request("vfx.demo", { effect = demoDrop.get() }), "Playing at the lab's demo spot.")
	end)
	demoBtn.gui.LayoutOrder = 2

	local lastTarget: string? = nil
	local effectsFor: { [string]: { effects: { string }, oneShots: { string } } } = {}
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
		for _, b in buttons do
			b.setEnabled(m ~= nil)
		end
		if not m then
			status.set("off", "Select a lab model.")
			return
		end
		status.set(
			if m.fx ~= "" then "ok" else "off",
			`{m.name} · {if m.fx ~= "" then "effect on: " .. m.fx else "no looping effect"}`
		)
		local known = effectsFor[m.id]
		if known then
			effect.setOptions(known.effects)
			shot.setOptions(known.oneShots)
			if not effect.get() then
				effect.set(known.effects[1])
			end
			if not shot.get() then
				shot.set(known.oneShots[1])
			end
		end
		if lastTarget ~= m.id then
			lastTarget = m.id
			effect.set(nil)
			shot.set(nil)
			task.spawn(function()
				local res = Net.request("lab.inspect", { labId = m.id })
				if res.ok then
					effectsFor[m.id] = { effects = res.data.effects, oneShots = res.data.oneShots }
					paint()
				end
			end)
		end
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
