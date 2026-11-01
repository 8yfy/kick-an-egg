--!strict
-- Which environment this server is: "studio" | "staging" | "production" (the default, and the safest).
-- DataStores belong to the whole universe (every place, every server, private servers too), so staging is a
-- SEPARATE universe listed in Config.StagingUniverseIds. A universe listed as production is never staging.
-- Progression edits additionally need the target's data to be safe to change (see Environment.dataSafety).

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Config)

local Environment = {}

local current: string = if RunService:IsStudio()
	then "studio"
	elseif Config.StagingUniverseIds[game.GameId] and not Config.ProductionUniverseIds[game.GameId] then "staging"
	else "production"

-- JobId is "" in Studio; a GUID keeps every server distinct in logs and broadcasts.
local serverId = if game.JobId ~= "" then game.JobId else `studio-{HttpService:GenerateGUID(false)}`

function Environment.current(): string
	return current
end

function Environment.serverId(): string
	return serverId
end

function Environment.isTest(): boolean
	return current == "studio" or current == "staging"
end

-- Progression edits must never reach production DataStores:
--   staging universe                      -> its own DataStores: allowed
--   Studio with in-memory data            -> nothing is ever saved: allowed
--   Studio with a real DataStore (API on) -> that may be the live universe's store: refused
--   production (private servers included) -> refused
function Environment.dataSafety(persistent: boolean): (boolean, string?)
	if current == "staging" then
		return true, nil
	elseif current == "studio" then
		if persistent then
			return false,
				"Studio is connected to a real DataStore (API access on), which may be the live one. Turn API access off or use the staging universe."
		end
		return true, nil
	end
	return false, "Progression edits are disabled on production servers (private servers share production data)."
end

return Environment
