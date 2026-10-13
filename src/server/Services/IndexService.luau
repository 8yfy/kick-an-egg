--!strict
-- Pet Index rewards (Economy.IndexRewards), server side:
--   ClaimIndexReward(zone): once every pet of that zone is in data.discovered (PlotService marks pets at
--   hatch), grants the zone's configured reward once and records data.indexClaims[tostring(zone)] = true.
--   A zone without a configured reward can't be claimed.
--   ClaimIndexMilestone(count): once data.discovered holds at least `count` different pets, grants that milestone
--   (Economy.IndexMilestones: money, and a permanent pet income bonus on the last one) once, recorded in
--   data.indexMilestones[tostring(count)]. Discovery never goes away (trading / selling a pet keeps it), and
--   players who already qualify can claim straight away.

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

-- How many different pets are discovered.
function IndexService.discoveredCount(discovered: { [string]: boolean }): number
	local n = 0
	for _, pet in Pets do
		if discovered[pet.id] then
			n += 1
		end
	end
	return n
end

local function milestone(count: number): { count: number, money: number, incomeBonus: number? }?
	for _, m in Economy.IndexMilestones do
		if m.count == count then
			return m
		end
	end
	return nil
end

-- Grants milestone `count` if it exists, is reached and wasn't claimed. True if granted.
function IndexService:ClaimMilestone(player: Player, count: number): boolean
	local m = milestone(count)
	local data = DataService:Get(player)
	local key = tostring(count)
	if not m or not data or data.indexMilestones[key] then
		return false
	end
	if IndexService.discoveredCount(data.discovered) < m.count then
		return false
	end
	local claimed = table.clone(data.indexMilestones)
	claimed[key] = true
	DataService:Set(player, { indexMilestones = claimed, money = data.money + m.money })
	Analytics.money(player, "Source", m.money, "Gameplay", "IndexMilestone")
	if m.incomeBonus then
		local plots = script.Parent:FindFirstChild("PlotService")
		if plots and plots:IsA("ModuleScript") then
			((require :: any)(plots)):Refresh(player) -- income labels include the bonus
		end
	end
	return true
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
	Remotes.get("ClaimIndexMilestone").OnServerEvent:Connect(function(player: Player, count: any)
		if limiter:allow(player) and typeof(count) == "number" and count == count then
			IndexService:ClaimMilestone(player, count)
		end
	end)
end

return IndexService
