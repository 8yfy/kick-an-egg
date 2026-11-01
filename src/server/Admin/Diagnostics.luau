--!strict
-- Real server numbers for the dashboard: uptime, players, memory, physics rate, version and the latest server
-- errors (LogService, server side only). Nothing is sampled per frame; snapshot() reads current values on demand.

local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local Diagnostics = {}

local started = os.clock()
local startedAt = os.time()
local errorCount, warnCount = 0, 0
local recent: { { at: number, text: string } } = {}
local MAX_RECENT = 10

local function clean(text: string): string
	local s = string.gsub(text, "%c", " ")
	return if #s > 180 then string.sub(s, 1, 177) .. "..." else s
end

function Diagnostics.start()
	LogService.MessageOut:Connect(function(message: string, kind: Enum.MessageType)
		if kind == Enum.MessageType.MessageError then
			errorCount += 1
			table.insert(recent, 1, { at = os.time(), text = clean(message) })
			if #recent > MAX_RECENT then
				table.remove(recent)
			end
		elseif kind == Enum.MessageType.MessageWarning then
			warnCount += 1
		end
	end)
end

function Diagnostics.uptime(): number
	return os.clock() - started
end

function Diagnostics.snapshot(): { [string]: any }
	local ok, memory = pcall(function()
		return Stats:GetTotalMemoryUsageMb()
	end)
	return {
		uptime = math.floor(Diagnostics.uptime()),
		startedAt = startedAt,
		players = #Players:GetPlayers(),
		maxPlayers = Players.MaxPlayers,
		memoryMb = if ok then math.floor(memory) else nil,
		physicsFps = math.floor(workspace:GetRealPhysicsFPS() * 10) / 10,
		placeVersion = game.PlaceVersion,
		placeId = game.PlaceId,
		errors = errorCount,
		warnings = warnCount,
		recentErrors = table.clone(recent),
	}
end

function Diagnostics.clearErrors()
	errorCount, warnCount = 0, 0
	table.clear(recent)
end

return Diagnostics
