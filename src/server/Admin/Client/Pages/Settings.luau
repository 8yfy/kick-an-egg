--!strict
-- Settings: this session's panel preferences (hotkey, size, motion) and a read-only view of your role,
-- permissions and the environment. Roles can't be changed here (or anywhere at runtime).

return function(holder: Frame, ctx: { [string]: any })
	local W, State = ctx.W, ctx.State
	local meta = State.meta

	local scroll = W.scroll(holder, "Scroll")
	local p = W.section(scroll, "Panel", W.Theme.Buttons.grey, 1)
	local hotkey = W.dropdown(p, "Open / close hotkey", meta.hotkeys, State.prefs.hotkey, function(v)
		State.prefs.hotkey = v
		W.toast(`Hotkey: {v} (this session).`, "good")
	end)
	hotkey.gui.LayoutOrder = 1
	local scale = W.slider(p, "Panel size (desktop)", 0.7, 1.2, 0.05, State.prefs.scale, function(v)
		State.prefs.scale = v
		ctx.App.relayout()
	end, function(n)
		return string.format("%d%%", math.floor(n * 100 + 0.5))
	end)
	scale.gui.LayoutOrder = 2
	local motion = W.toggle(p, "Reduced motion (no open animation)", State.prefs.reducedMotion, function(v)
		State.prefs.reducedMotion = v
	end)
	motion.gui.LayoutOrder = 3
	local n = W.text(
		p,
		"Preferences last for this session. The small 🛡 button at the top right opens the panel too.",
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	n.LayoutOrder = 4

	local s = W.section(scroll, "Your access", W.Theme.Headers.index, 2)
	W.kv(s, "Role", tostring(meta.role), 1)
	W.kv(s, "Environment", string.upper(tostring(meta.environment)), 2)
	W.kv(s, "Server", tostring(meta.server), 3)
	W.kv(s, "Admin version", `{meta.version} · place v{meta.placeVersion}`, 4)
	local perms = W.text(
		s,
		"Permissions: " .. table.concat(meta.permissions or {}, ", "),
		14,
		{ wrap = true, color = W.Colors.muted }
	)
	perms.LayoutOrder = 5

	local sec = W.section(scroll, "How access works", W.Theme.Headers.shop, 3)
	W.text(
		sec,
		table.concat({
			"• Access comes only from a server-side allowlist of numeric UserIds (Owner, Developer, Tester).",
			"• This panel is just a view: every action is re-checked on the server (role, parameters, scope, limits, rate) and written to the audit log.",
			"• Roles can't be changed while a server runs. Progression edits only work on test data (Studio in-memory or a staging universe).",
			"• All-servers actions are re-validated by every receiving server; delivery isn't guaranteed, so check the acknowledgements.",
		}, "\n"),
		14,
		{ wrap = true }
	)

	return {}
end
