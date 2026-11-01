--!strict
-- Weather and events through the game's own authoritative WeatherService (WeatherChanged -> HUD widget, timer,
-- toast and world visuals on every client). The only timed event the game has is the scheduled weather event, so
-- that is the one registered event. Scope "global" runs on every live server (Owner permission) and stores an
-- expiring MemoryStore copy so servers that start later join in for the remaining time.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)

return function(deps: { [string]: any }): { any }
	local Config = deps.Config
	local CrossServer = deps.CrossServer
	local S = deps.Services
	local W = Config.Weather

	local weathers = {}
	for name in Mutations.Weather do
		table.insert(weathers, name)
	end
	table.sort(weathers)
	local variants = { "Random" }
	for _, name in weathers do
		table.insert(variants, name)
	end
	local rng = Random.new()

	-- The schedule's own weighting (rarer weathers are rarer events).
	local function pickWeather(): string
		local total = 0
		for _, m in Mutations.Weather do
			total += m.chance
		end
		local pick = rng:NextNumber() * total
		for _, name in weathers do
			pick -= Mutations.Weather[name].chance
			if pick <= 0 then
				return name
			end
		end
		return weathers[#weathers]
	end

	local function start(ctx: any, weather: string, seconds: number)
		S.WeatherService:StartEvent(weather, seconds)
		if ctx.scope == "global" and not ctx.remote then
			CrossServer.setState("weather", {
				weather = weather,
				endsAt = os.time() + seconds,
				by = ctx.name,
				id = ctx.correlation,
			}, seconds)
		end
	end
	local function stop(ctx: any)
		S.WeatherService:StopEvent()
		if ctx.scope == "global" and not ctx.remote then
			CrossServer.removeState("weather")
		end
	end

	local SCOPES = { "server", "global" }
	local secondsSpec = { type = "number", min = W.minSeconds, max = W.maxSeconds, integer = true, default = 120 }

	local globalCache: { at: number, value: any } = { at = -math.huge, value = nil }
	local function globalWeather(): any
		if os.clock() - globalCache.at > 15 then
			globalCache = { at = os.clock(), value = CrossServer.getState("weather") }
		end
		return globalCache.value
	end

	return {
		{
			id = "weather.status",
			name = "Weather status",
			description = "The running weather, its time left, the schedule and any global weather in effect.",
			category = "weather",
			permission = "dashboard.view",
			kind = "read",
			handler = function()
				local list = {}
				for _, name in weathers do
					local m = Mutations.Weather[name]
					table.insert(list, { name = name, chance = m.chance, income = m.income })
				end
				return true, { state = deps.weatherState(), weathers = list, global = globalWeather() }
			end,
		},
		{
			id = "weather.start",
			name = "Start weather",
			runnerName = "StartRegisteredWeather",
			description = "Starts a registered weather for a bounded test time (replaces the running one).",
			category = "weather",
			permission = "weather.server",
			globalPermission = "weather.global",
			scopes = SCOPES,
			crossServer = true,
			kind = "action",
			runner = true,
			cooldown = 2,
			params = {
				weather = { type = "enum", options = weathers, default = weathers[1] },
				seconds = secondsSpec,
			},
			target = function(p)
				return p.weather
			end,
			handler = function(ctx, p)
				start(ctx, p.weather, p.seconds)
				return true, { weather = p.weather, seconds = p.seconds }
			end,
		},
		{
			id = "weather.stop",
			name = "Stop weather",
			description = "Ends the running weather now (the schedule continues as usual).",
			category = "weather",
			permission = "weather.server",
			globalPermission = "weather.global",
			scopes = SCOPES,
			crossServer = true,
			kind = "action",
			cooldown = 2,
			handler = function(ctx)
				stop(ctx)
				return true, {}
			end,
		},
		{
			id = "weather.reset",
			name = "Reset weather",
			runnerName = "ResetWeather",
			description = "Stops the weather and, for all servers, clears the stored global weather so new servers stay clear.",
			category = "weather",
			permission = "weather.server",
			globalPermission = "weather.global",
			scopes = SCOPES,
			crossServer = true,
			kind = "action",
			runner = true,
			cooldown = 2,
			handler = function(ctx)
				stop(ctx)
				return true, {}
			end,
		},
		{
			id = "events.list",
			name = "Registered events",
			description = "Events that really exist in the game, with their status.",
			category = "events",
			permission = "dashboard.view",
			kind = "read",
			handler = function()
				local w = deps.weatherState()
				return true,
					{
						events = {
							{
								id = "WeatherEvent",
								name = "Weather event",
								description = `Normally every {w.everySeconds // 60} min for {w.durationSeconds // 60} min, weighted by rarity. While it runs, that weather's mutation is 5x more likely.`,
								active = w.active ~= nil,
								current = w.active,
								remaining = w.remaining,
								variants = variants,
							},
						},
						global = globalWeather(),
					}
			end,
		},
		{
			id = "events.start",
			name = "Start event",
			description = "Starts a registered event now (Random picks like the schedule does).",
			category = "events",
			permission = "events.server",
			globalPermission = "events.global",
			scopes = SCOPES,
			crossServer = true,
			kind = "action",
			cooldown = 2,
			params = {
				event = { type = "enum", options = { "WeatherEvent" }, default = "WeatherEvent" },
				variant = { type = "enum", options = variants, default = "Random" },
				seconds = {
					type = "number",
					min = W.minSeconds,
					max = W.maxSeconds,
					integer = true,
					default = Mutations.WeatherEvent.durationSeconds,
				},
			},
			target = function(p)
				return p.event
			end,
			handler = function(ctx, p)
				if p.variant == "Random" then
					-- resolve once on the sending server so every server runs the same weather
					p.variant = pickWeather()
				end
				start(ctx, p.variant, p.seconds)
				return true, { event = p.event, weather = p.variant, seconds = p.seconds }
			end,
		},
		{
			id = "events.stop",
			name = "Stop event",
			runnerName = "StopRegisteredEvent",
			description = "Stops a registered event now.",
			category = "events",
			permission = "events.server",
			globalPermission = "events.global",
			scopes = SCOPES,
			crossServer = true,
			kind = "action",
			runner = true,
			cooldown = 2,
			params = { event = { type = "enum", options = { "WeatherEvent" }, default = "WeatherEvent" } },
			target = function(p)
				return p.event
			end,
			handler = function(ctx)
				stop(ctx)
				return true, {}
			end,
		},
	}
end
