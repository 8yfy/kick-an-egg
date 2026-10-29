--!strict
-- Server-wide weather events: every WeatherEvent.everySeconds one weather (weighted by its
-- mutation chance, so rarer weathers are rarer events) runs for durationSeconds.
-- KickService reads :GetActive() (that weather's mutation chance is x5 while it runs).
-- Fires WeatherChanged(weather?, endsAt?) to everyone, and the current one to new players.
-- Studio command bar: require(game.ServerScriptService.Server.Services.WeatherService):StartEvent("Rainbow", 30)
-- Studio chat command (Studio only, like /cash and /hatch): /weather shows the current weather and the names;
-- /weather Stormy [seconds] starts one (default: the normal event length), /weather random [seconds] picks one
-- the way the schedule does, /weather off ends it. A toast confirms each one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)
local Remotes = require(Shared.Remotes)

local WeatherService = {}

local rng = Random.new()
local active: string? = nil
local endsAt: number? = nil
local eventToken = 0
local weatherChanged: RemoteEvent
local announce: RemoteEvent
local MIN_SECONDS, MAX_SECONDS = 5, 3600 -- /weather lengths

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

-- Server time (workspace:GetServerTimeNow()) the running event ends, or nil. Read-only (admin dashboard).
function WeatherService:GetEndsAt(): number?
	return endsAt
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

-- Ends the running event now (no-op without one).
function WeatherService:StopEvent()
	eventToken += 1
	if active then
		active, endsAt = nil, nil
		weatherChanged:FireAllClients(nil, nil)
	end
end

export type Command = {
	action: "status" | "start" | "stop" | "unknown",
	weather: string?,
	seconds: number?,
	random: boolean?,
}

-- Reads a "/weather ..." chat line (any letter case). Weather names come from Config/Mutations.Weather.
function WeatherService.parseCommand(message: string): Command
	local words = string.split(string.lower((string.gsub(message, "^%s+", ""))), " ")
	local args = {}
	for _, w in words do
		if w ~= "" then
			table.insert(args, w)
		end
	end
	local what = args[2]
	local n = tonumber(args[3])
	local seconds = if n then math.clamp(math.floor(n), MIN_SECONDS, MAX_SECONDS) else nil
	if not what or what == "list" or what == "help" then
		return { action = "status" }
	elseif what == "off" or what == "stop" or what == "clear" or what == "end" then
		return { action = "stop" }
	elseif what == "random" then
		return { action = "start", seconds = seconds, random = true }
	end
	for name in Mutations.Weather do
		if string.lower(name) == what then
			return { action = "start", weather = name, seconds = seconds }
		end
	end
	return { action = "unknown", weather = what }
end

local function names(): string
	local list = {}
	for name in Mutations.Weather do
		table.insert(list, name)
	end
	table.sort(list, function(a, b)
		return Mutations.Weather[a].chance > Mutations.Weather[b].chance
	end)
	return table.concat(list, ", ")
end

local function clock(seconds: number): string
	local s = math.max(0, math.floor(seconds + 0.5))
	return string.format("%d:%02d", s // 60, s % 60)
end

-- Studio only: the /weather chat command (see the header). Feedback goes to the player who typed it.
function WeatherService.command(player: Player, message: string)
	local cmd = WeatherService.parseCommand(message)
	local function tell(text: string, rarity: string)
		announce:FireClient(player, text, rarity)
		print(`[studio] {player.Name}: {text}`)
	end
	if cmd.action == "status" then
		local now = if active and endsAt
			then `{string.upper(active)} weather, {clock(endsAt - workspace:GetServerTimeNow())} left`
			else "No weather right now"
		tell(`{now}. Try /weather Stormy 30, /weather random or /weather off. Weathers: {names()}`, "Common")
	elseif cmd.action == "stop" then
		local had = active
		WeatherService:StopEvent()
		tell(if had then `{string.upper(had)} weather ended` else "No weather was running", "Common")
	elseif cmd.action == "unknown" then
		tell(`No weather called "{cmd.weather}". Weathers: {names()}`, "Common")
	else
		local weather = cmd.weather or pickWeather()
		local seconds = cmd.seconds or Mutations.WeatherEvent.durationSeconds
		WeatherService:StartEvent(weather, seconds)
		tell(`{string.upper(weather)} weather for {clock(seconds)}: {weather} pets are 5x more likely`, "Rare")
	end
end

local function registerStudioCommand()
	local TextChatService = game:GetService("TextChatService")
	local folder = TextChatService:FindFirstChild("TextChatCommands")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "TextChatCommands"
		folder.Parent = TextChatService
	end
	local command = Instance.new("TextChatCommand")
	command.Name = "KTE_weather"
	command.PrimaryAlias = "/weather"
	command.Triggered:Connect(function(source: TextSource, text: string)
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then
			WeatherService.command(player, text)
		end
	end)
	command.Parent = folder
end

function WeatherService:Init()
	weatherChanged = Remotes.get("WeatherChanged")
	announce = Remotes.get("Announce")
end

function WeatherService:Start()
	if RunService:IsStudio() then
		registerStudioCommand()
	end
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
