--!strict
-- Game Controls: announcements (Roblox-filtered), registered feature flags (incl. staging-only experiments) and
-- the approved test-scenario reset. Weather and events have their own tab. No DataStore wipes exist anywhere.

return function(holder: Frame, ctx: { [string]: any })
	local W, Net, State = ctx.W, ctx.Net, ctx.State
	local meta = State.meta

	local scroll = W.scroll(holder, "Scroll")

	local aBody = W.section(scroll, "Announcement", W.Theme.Headers.eggs, 1)
	local text =
		W.input(aBody, `Message for every player (max {meta.limits.announce} characters, filtered by Roblox)`, nil)
	text.LayoutOrder = 1
	local styles = {}
	for _, r in meta.rarities do
		table.insert(styles, r.name)
	end
	local style = W.dropdown(aBody, "Banner colour", styles, "Rare", function() end)
	style.gui.LayoutOrder = 2
	local send = W.button(aBody, "SEND ANNOUNCEMENT", "gold", nil, function()
		local message = string.sub(text.Text, 1, meta.limits.announce)
		if #message == 0 then
			W.toast("Write a message first.", "error")
			return
		end
		local scope = State.scopeFor("announce.send")
		local yes = W.confirm(
			"Announcement",
			`Show "{message}" to every player {if scope == "global" then "on ALL live servers" else "on this server"}?`,
			scope == "global"
		)
		if not yes then
			return
		end
		local res =
			Net.request("announce.send", { text = message, style = style.get(), scope = scope, confirmed = true })
		if W.report(res, "Announcement sent.") then
			text.Text = ""
		end
	end)
	send.gui.LayoutOrder = 3
	send.setEnabled(State.can("announce.server"))

	local fBody = W.section(scroll, "Feature flags", W.Theme.Headers.sell, 2)
	local fNote = W.text(
		fBody,
		"Only registered flags exist. The game itself has no flag system yet, so these only affect the admin tools. Header scope decides this server / all servers (global changes expire after 6 h).",
		14,
		{
			wrap = true,
			color = W.Colors.muted,
		}
	)
	fNote.LayoutOrder = 0
	local toggles: { [string]: any } = {}
	local canFlags = State.can("flags.server")

	local function loadFlags()
		local res = Net.poll("flags.list")
		if not (res and res.ok) then
			return
		end
		for i, f in res.data.flags do
			local t = toggles[f.id]
			if not t then
				local holderRow = W.vstack(fBody, f.id, 0)
				holderRow.LayoutOrder = i
				t = W.toggle(holderRow, f.name, f.value, function(v)
					local scope = State.scopeFor("flags.set")
					local params = { flag = f.id, value = v, scope = scope }
					if scope == "global" then
						if not W.confirm("Feature flag", `Set {f.name} to {v} on ALL live servers?`, true) then
							toggles[f.id].set(not v)
							return
						end
						params.confirmed = true
					end
					local r = Net.request("flags.set", params)
					if not W.report(r, `{f.name}: {if v then "on" else "off"}`) then
						toggles[f.id].set(not v)
					end
				end)
				W.text(
					holderRow,
					`{f.description}{if f.environments
						then " (" .. table.concat(f.environments, ", ") .. " only)"
						else ""}`,
					13,
					{
						wrap = true,
						color = W.Colors.muted,
					}
				)
				toggles[f.id] = t
			end
			t.set(f.value)
			t.setEnabled(canFlags and f.available)
		end
	end

	if State.can("scenario.reset") then
		local sBody = W.section(scroll, "Test scenario", W.Theme.Buttons.red, 3)
		W.text(
			sBody,
			"ResetApprovedTestScenario: removes every lab model and test pen pet, resets flags on this server and stops the weather. Player data is never touched.",
			14,
			{
				wrap = true,
				color = W.Colors.muted,
			}
		)
		W.button(sBody, "RESET TEST SCENARIO", "red", nil, function()
			if
				W.confirm("Reset test scenario", "Clear the lab, reset this server's flags and stop the weather?", true)
			then
				W.report(Net.request("scenario.reset", { confirmed = true }), "Test scenario reset.")
				loadFlags()
			end
		end)
	end

	return { refresh = loadFlags, every = 15 }
end
