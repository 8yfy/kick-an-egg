--!strict
-- Server-to-client remotes have no gameplay handler on the server, so events an exploiter fires
-- on them would pile up in the server's invocation queue. Drain them here and log offenders.
-- (Every client-to-server remote is rate-limited and type-checked in its own service.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local Analytics = require(script.Parent.Parent.Util.Analytics)

local SERVER_TO_CLIENT = {
	"KickResult",
	"ChaseStart",
	"EggPickedUp",
	"EggSecured",
	"EggLost",
	"ChaseEnded",
	"EggHatched",
	"DataChanged",
	"WeatherChanged",
	"Announce",
}

local SecurityService = {}

local strikes: { [Player]: number } = {}

-- Number of S->C-remote abuse events from this player this session.
function SecurityService:GetStrikes(player: Player): number
	return strikes[player] or 0
end

function SecurityService:Start()
	for _, name in SERVER_TO_CLIENT do
		Remotes.get(name).OnServerEvent:Connect(function(player: Player)
			local count = (strikes[player] or 0) + 1
			strikes[player] = count
			if count == 1 or count % 100 == 0 then
				warn(`[SecurityService] {player.Name} fired server-only remote {name} ({count} times)`)
				Analytics.custom(player, "RemoteAbuse", count, name)
			end
		end)
	end
	Players.PlayerRemoving:Connect(function(player)
		strikes[player] = nil
	end)
end

return SecurityService
