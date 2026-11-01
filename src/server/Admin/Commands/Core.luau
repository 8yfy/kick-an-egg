--!strict
-- Session metadata, dashboard, diagnostics, audit logs and cross-server delivery status.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)
local Rarities = require(Shared.Config.Rarities)
local Zones = require(Shared.Config.Zones)

return function(deps: { [string]: any }): { any }
	local Config = deps.Config
	local Catalog = deps.Catalog
	local ModelLab = deps.ModelLab
	local CrossServer = deps.CrossServer
	local Diagnostics = deps.Diagnostics
	local Environment = deps.Environment
	local Flags = deps.Flags
	local audit = deps.audit
	local S = deps.Services

	local function brief(e: any): { [string]: any }
		return {
			id = e.id,
			at = e.at,
			adminName = e.adminName,
			role = e.role,
			command = e.command,
			target = e.target,
			scope = e.scope,
			params = e.params,
			outcome = e.outcome,
			category = e.category,
			message = e.message,
			server = e.server,
			origin = e.origin,
			correlation = e.correlation,
		}
	end

	local function sorted(map: { [string]: any }): { string }
		local list = {}
		for k in map do
			table.insert(list, k)
		end
		table.sort(list)
		return list
	end

	local function weatherState(): { [string]: any }
		local active = S.WeatherService:GetActive()
		local endsAt = S.WeatherService:GetEndsAt()
		local now = workspace:GetServerTimeNow()
		return {
			active = active,
			endsAt = endsAt,
			remaining = if endsAt then math.max(0, math.floor(endsAt - now)) else 0,
			everySeconds = Mutations.WeatherEvent.everySeconds,
			durationSeconds = Mutations.WeatherEvent.durationSeconds,
		}
	end
	deps.weatherState = weatherState

	return {
		{
			id = "session.hello",
			name = "Open session",
			description = "Your role, the commands you may run and the client-safe registries.",
			category = "core",
			permission = "panel.open",
			kind = "read",
			handler = function(ctx)
				local rarities = {}
				for name, r in Rarities do
					table.insert(rarities, { name = name, order = r.order })
				end
				table.sort(rarities, function(a, b)
					return a.order < b.order
				end)
				local zones = {}
				for _, z in Zones do
					table.insert(zones, z.name)
				end
				local qualities = {}
				for name, q in Config.Vfx.qualities do
					qualities[name] = q
				end
				return true,
					{
						name = ctx.name,
						role = ctx.role,
						roleColor = Config.Roles[ctx.role].color,
						permissions = deps.permissionsOf(ctx.role),
						environment = ctx.environment,
						server = ctx.server,
						version = Config.Version,
						placeVersion = game.PlaceVersion,
						hotkey = Config.Client.defaultHotkey,
						hotkeys = Config.Client.allowedHotkeys,
						commands = deps.describe(ctx.role),
						rarities = rarities,
						zones = zones,
						weathers = sorted(Mutations.Weather),
						sizes = sorted(Mutations.Size),
						anims = Catalog.Anims,
						idleAnim = Catalog.IdleAnim,
						animCycle = Catalog.AnimCycle,
						overlays = Catalog.Overlays,
						oneShots = Catalog.OneShots,
						demoEffects = Catalog.DemoEffects,
						qualities = qualities,
						limits = {
							lab = {
								maxPerAdmin = Config.Lab.maxPerAdmin,
								maxTotal = Config.Lab.maxTotal,
								minScale = Config.Lab.minScale,
								maxScale = Config.Lab.maxScale,
								maxOffset = Config.Lab.maxOffset,
								maxLift = Config.Lab.maxLift,
								penMax = Config.Lab.penMax,
							},
							vfx = { maxActive = Config.Vfx.maxActive, maxSeconds = Config.Vfx.maxSeconds },
							weather = { min = Config.Weather.minSeconds, max = Config.Weather.maxSeconds },
							announce = Config.Announce.maxLength,
							auditPage = Config.Audit.pageSize,
						},
					}
			end,
		},
		{
			id = "dashboard.get",
			name = "Dashboard",
			description = "Live server numbers (refreshed every few seconds while the dashboard is open).",
			category = "core",
			permission = "dashboard.view",
			kind = "read",
			handler = function(ctx)
				local snap = Diagnostics.snapshot()
				local w = weatherState()
				local perAdmin: { [string]: number } = {}
				for _, entry in ModelLab.list() do
					if not entry.pen then
						perAdmin[entry.ownerName] = (perAdmin[entry.ownerName] or 0) + 1
					end
				end
				local sessions = {}
				for name, n in perAdmin do
					table.insert(sessions, { name = name, models = n })
				end
				local latest = {}
				for _, e in audit.latest(8) do
					table.insert(latest, brief(e))
				end
				local deliveries = CrossServer.deliveries()
				return true,
					{
						server = {
							id = ctx.server,
							environment = ctx.environment,
							version = Config.Version,
							placeVersion = snap.placeVersion,
							uptime = snap.uptime,
							players = snap.players,
							maxPlayers = snap.maxPlayers,
							memoryMb = snap.memoryMb,
							physicsFps = snap.physicsFps,
						},
						weather = w,
						events = {
							{
								id = "WeatherEvent",
								name = "Weather event",
								active = w.active ~= nil,
								remaining = w.remaining,
							},
						},
						lab = {
							models = ModelLab.count(nil),
							pen = ModelLab.penCount(),
							activeFx = ModelLab.activeFx(),
							sessions = sessions,
							adminsOnline = deps.sessionCount(),
						},
						audit = { latest = latest, total = audit.size(), failures = audit.failures() },
						errors = {
							count = snap.errors,
							warnings = snap.warnings,
							recent = table.move(snap.recentErrors, 1, 5, 1, {}),
						},
						crossServer = {
							health = CrossServer.health(),
							deliveries = table.move(deliveries, 1, 5, 1, {}),
						},
						flags = Flags.list(),
					}
			end,
		},
		{
			id = "diagnostics.refresh",
			name = "Refresh diagnostics",
			runnerName = "RefreshApprovedDiagnosticState",
			description = "Re-reads server diagnostics, probes MemoryStore and optionally clears the error counters.",
			category = "diagnostics",
			permission = "diagnostics.refresh",
			kind = "action",
			runner = true,
			cooldown = 5,
			params = {
				clearErrors = { type = "boolean", default = false, label = "Clear error counters" },
			},
			handler = function(_ctx, p)
				CrossServer.getState("weather") -- a real MemoryStore read updates its health
				if p.clearErrors then
					Diagnostics.clearErrors()
				end
				return true, { snapshot = Diagnostics.snapshot(), crossServer = CrossServer.health() }
			end,
		},
		{
			id = "logs.query",
			name = "Audit log",
			description = "This server's admin audit log (newest first), filtered and paginated.",
			category = "logs",
			permission = "logs.view",
			kind = "read",
			params = {
				admin = { type = "userId", optional = true, label = "Admin UserId" },
				command = { type = "string", optional = true, maxLength = 64, pattern = "^[%w_%.]*$" },
				server = { type = "string", optional = true, maxLength = 64, pattern = "^[%w%-_]*$" },
				outcome = { type = "enum", options = { "any", "ok", "fail" }, default = "any" },
				sinceMinutes = { type = "number", min = 0, max = 10080, integer = true, default = 0 },
				text = { type = "string", optional = true, maxLength = 40 },
				page = { type = "number", min = 1, max = 1000, integer = true, default = 1 },
			},
			handler = function(_ctx, p)
				local since = if p.sinceMinutes > 0 then os.time() - p.sinceMinutes * 60 else nil
				local res = audit.query({
					admin = p.admin,
					command = p.command,
					server = p.server,
					outcome = p.outcome,
					since = since,
					text = p.text,
				}, p.page, Config.Audit.pageSize)
				local entries = {}
				for _, e in res.entries do
					table.insert(entries, brief(e))
				end
				local commands, servers, admins = {}, {}, {}
				for _, e in audit.latest(Config.Audit.capacity) do
					commands[e.command] = true
					servers[e.server] = true
					if e.origin then
						servers[e.origin] = true
					end
					admins[`{e.adminName}|{e.admin}`] = true
				end
				return true,
					{
						entries = entries,
						total = res.total,
						page = res.page,
						pages = res.pages,
						facets = { commands = sorted(commands), servers = sorted(servers), admins = sorted(admins) },
					}
			end,
		},
		{
			id = "logs.global",
			name = "Global audit (all servers)",
			description = "Global-scope admin actions from every server (expiring MemoryStore copy, last day).",
			category = "logs",
			permission = "logs.global",
			kind = "read",
			cooldown = 3,
			handler = function()
				local ok, list = CrossServer.readGlobalAudit(Config.Audit.globalRead)
				if not ok then
					return false, list, "unavailable"
				end
				return true, { entries = list }
			end,
		},
		{
			id = "crossserver.status",
			name = "Cross-server delivery",
			description = "MessagingService / MemoryStore health and the acknowledgements of recent broadcasts.",
			category = "core",
			permission = "dashboard.view",
			kind = "read",
			handler = function()
				return true, { health = CrossServer.health(), deliveries = CrossServer.deliveries() }
			end,
		},
		{
			id = "session.players",
			name = "Player count",
			description = "Players in this server (header chip).",
			category = "core",
			permission = "panel.open",
			kind = "read",
			audit = "none",
			handler = function()
				return true, { players = #Players:GetPlayers(), environment = Environment.current() }
			end,
		},
	}
end
