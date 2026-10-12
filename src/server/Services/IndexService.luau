--!strict
-- Pet Index rewards (Economy.IndexRewards), server side:
--   ClaimIndexReward(zone): once every pet of that zone is in data.discovered (PlotService marks pets at
--   hatch), grants the zone's configured reward once and records data.indexClaims[tostring(zone)] = true.
--   A zone without a configured reward can't be claimed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Pets = require(Shared.Config.Pets)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)

local IndexService = {}

local limiter = RateLimiter.new()

-- Every pet of `zone` has been discovered (and the zone has pets at all).
function IndexService.zoneComplete(discovered: { [string]: boolean }, zone: number): boolean
	local any = false
	for _, pet in Pets do
		if pet.zone == zone then
			any = true
			if not discovered[pet.id] then
				return false
			end
		end
	end
	return any
end

local function onClaim(player: Player, zone: any)
	if not limiter:allow(player) or typeof(zone) ~= "number" then
		return
	end
	local reward = Economy.IndexRewards[zone]
	local data = DataService:Get(player)
	local key = tostring(zone)
	if not reward or not data or data.indexClaims[key] or not IndexService.zoneComplete(data.discovered, zone) then
		return
	end
	local claims = table.clone(data.indexClaims)
	claims[key] = true
	DataService:Set(player, { indexClaims = claims, money = data.money + reward.money })
	Analytics.money(player, "Source", reward.money, "Gameplay", "IndexReward")
end

function IndexService:Start()
	Remotes.get("ClaimIndexReward").OnServerEvent:Connect(onClaim)
end

return IndexService
