--!strict
-- Server-wide weather events: every WeatherEvent.everySeconds one weather (weighted by its
-- mutation chance, so rarer weathers are rarer events) runs for durationSeconds.
-- KickService reads :GetActive() (that weather's mutation chance is x5 while it runs).
-- Fires WeatherChanged(weather?, endsAt?) to everyone, and the current one to new players.
-- Studio command bar: require(game.ServerScriptService.Server.Services.WeatherService):StartEvent("Rainbow", 30)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)
local Remotes = require(Shared.Remotes)

local WeatherService = {}

local rng = Random.new()
local active: string? = nil
local endsAt: number? = nil
local eventToken = 0
local weatherChanged: RemoteEvent

local function pickWeather(): string
	local total = 0
	for _, mutation in Mutations.Weather do
		total += mutation.chance
	end
	local pick = rng:NextNumber() * total
	local last = "Sunny"
	for name, mutation in Mutations.Weather do
		last = name
		pick -= mutation.chance
		if pick <= 0 then
			return name
		end
	end
	return last
end

function WeatherService:GetActive(): string?
	return active
end

-- Starts `weather` now for `seconds` (replaces any running event).
function WeatherService:StartEvent(weather: string, seconds: number)
	if not Mutations.Weather[weather] then
		warn(`[WeatherService] unknown weather {weather}`)
		return
	end
	eventToken += 1
	local token = eventToken
	active = weather
	endsAt = workspace:GetServerTimeNow() + seconds
	weatherChanged:FireAllClients(active, endsAt)
	task.delay(seconds, function()
		if eventToken == token then
			active, endsAt = nil, nil
			weatherChanged:FireAllClients(nil, nil)
		end
	end)
end

function WeatherService:Init()
	weatherChanged = Remotes.get("WeatherChanged")
end

function WeatherService:Start()
	Players.PlayerAdded:Connect(function(player)
		if active then
			weatherChanged:FireClient(player, active, endsAt)
		end
	end)
	task.spawn(function()
		local schedule = Mutations.WeatherEvent
		while true do
			task.wait(schedule.everySeconds)
			self:StartEvent(pickWeather(), schedule.durationSeconds)
		end
	end)
end

return WeatherService
