--!strict
-- Game controls: announcements (filtered by Roblox's text filter before anyone sees them), registered feature
-- flags and the approved test-scenario reset. No DataStore wipes or other destructive operations exist here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rarities = require(Shared.Config.Rarities)

local FLAG_TTL = 6 * 3600 -- a global flag change lasts at most 6 hours on servers that start later

return function(deps: { [string]: any }): { any }
	local Config = deps.Config
	local CrossServer = deps.CrossServer
	local Flags = deps.Flags
	local ModelLab = deps.ModelLab
	local S = deps.Services

	local styles = {}
	for name in Rarities do
		table.insert(styles, name)
	end
	table.sort(styles, function(a, b)
		return Rarities[a].order < Rarities[b].order
	end)

	local function filter(text: string, userId: number): (boolean, string)
		local ok, result = pcall(function()
			local filtered = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
			return filtered:GetNonChatStringForBroadcastAsync()
		end)
		if not ok or typeof(result) ~= "string" then
			return false, "Roblox's text filter is unavailable, so nothing was sent."
		end
		return true, result
	end

	return {
		{
			id = "announce.send",
			name = "Announcement",
			description = "A banner for every player (this server or all servers). Text goes through Roblox's filter.",
			category = "controls",
			permission = "announce.server",
			globalPermission = "announce.global",
			scopes = { "server", "global" },
			crossServer = true,
			kind = "action",
			confirm = true,
			cooldown = 5,
			params = {
				text = { type = "string", minLength = 1, maxLength = Config.Announce.maxLength, label = "Message" },
				style = { type = "enum", options = styles, default = "Rare", label = "Colour" },
			},
			precheck = function(ctx)
				if ctx.scope == "global" and not Flags.get("announce.global") then
					return false, "Global announcements are switched off (flag announce.global).", "flag_off"
				end
				return true
			end,
			handler = function(ctx, p)
				if not ctx.remote then
					local ok, text = filter(p.text, ctx.userId)
					if not ok then
						return false, text, "filter"
					end
					p.text = text -- receivers get the filtered text (only this game's servers can publish)
				end
				S.AnnounceService:Announce(p.text, p.style)
				return true, { text = p.text }
			end,
		},
		{
			id = "flags.list",
			name = "Feature flags",
			description = "Registered feature flags and their current values on this server.",
			category = "controls",
			permission = "panel.open",
			kind = "read",
			handler = function(ctx)
				local list = Flags.list()
				for _, f in list do
					f.available = f.environments == nil or table.find(f.environments, ctx.environment) ~= nil
				end
				return true, { flags = list }
			end,
		},
		{
			id = "flags.set",
			name = "Set feature flag",
			description = "Switches a registered flag on this server or all servers (global changes expire after 6 h).",
			category = "controls",
			permission = "flags.server",
			globalPermission = "flags.global",
			scopes = { "server", "global" },
			crossServer = true,
			kind = "action",
			cooldown = 1,
			params = {
				flag = { type = "enum", options = Flags.ids },
				value = { type = "boolean" },
			},
			target = function(p)
				return p.flag
			end,
			precheck = function(ctx, p)
				local f = Flags.Registry[p.flag]
				if f and f.environments and not table.find(f.environments, ctx.environment) then
					return false, `{f.name} is only available in: {table.concat(f.environments, ", ")}.`, "environment"
				end
				return true
			end,
			handler = function(ctx, p)
				Flags.set(p.flag, p.value)
				if ctx.scope == "global" and not ctx.remote then
					CrossServer.setState(`flag:{p.flag}`, p.value, FLAG_TTL)
				end
				return true, { flag = p.flag, value = p.value }
			end,
		},
		{
			id = "scenario.reset",
			name = "Reset test scenario",
			runnerName = "ResetApprovedTestScenario",
			description = "Clears every lab model and test pen pet, resets flags on this server and stops the weather.",
			category = "controls",
			permission = "scenario.reset",
			kind = "action",
			runner = true,
			confirm = true,
			cooldown = 5,
			handler = function()
				local removed = ModelLab.clear(nil)
				Flags.reset()
				S.WeatherService:StopEvent()
				return true, { removed = removed }
			end,
		},
	}
end
