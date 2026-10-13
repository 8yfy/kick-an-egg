--!strict
-- The shop's speed card: BuyUpgrade("RunSpeed") = +1 Run Speed LEVEL (no cap) for Economy.speedCost(level); the
-- speed itself (egg speed and walk speed) is Economy.runSpeedAt(level): it keeps growing, slower each level.
-- Strength (kickPower) is trained at the rack and better racks are bought (RackService), so
-- BuyUpgrade("KickPower") is ignored. Rebirth(): only at the strength cap; resets Economy.Rebirth.resets (money, strength
-- and Run Speed), keeps the rest (eggs, pets, sacks, pen, index), +1 rebirth (more income, higher strength cap).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local KickService = require(script.Parent.KickService)
local ChaseService = require(script.Parent.ChaseService)
local PlotService = require(script.Parent.PlotService)

local UpgradeService = {}

-- Values Economy.Rebirth.resets puts back (the Rebirth screen lists the same keys).
local RESET_TO: { [string]: number } = {
	money = Economy.StartingMoney,
	kickPower = Economy.KickPower.base,
	runSpeed = Economy.RunSpeed.base,
}

local limiter = RateLimiter.new()

-- Returns true if bought. Exposed for tests and for a future auto-buy. Only RunSpeed is sold.
function UpgradeService:Buy(player: Player, kind: Economy.UpgradeKind): boolean
	local data = DataService:Get(player)
	if not data or kind ~= "RunSpeed" then
		return false
	end
	local level: number = data.speedLevel
	local cost = Economy.speedCost(level)
	if cost ~= cost or cost == math.huge or cost < 0 or data.money < cost then
		return false
	end
	DataService:Set(player, {
		money = data.money - cost,
		speedLevel = level + 1,
		runSpeed = Economy.runSpeedAt(level + 1),
	})
	Analytics.money(player, "Sink", cost, "Shop", kind)
	Analytics.funnel(player, Analytics.Funnel.FirstUpgrade, "FirstUpgrade")
	if kind == "RunSpeed" then
		ChaseService:RefreshWalkSpeed(player)
	end
	return true
end

function UpgradeService:CanRebirth(player: Player): boolean
	local data = DataService:Get(player)
	if not data or KickService:GetActive(player) then
		return false -- no rebirth mid-chase
	end
	return data.kickPower >= Economy.rebirthPower(data.rebirths)
end

function UpgradeService:Rebirth(player: Player): boolean
	if not self:CanRebirth(player) then
		return false
	end
	local data = DataService:Get(player) :: DataService.Data
	local partial: { [string]: any } = { rebirths = data.rebirths + 1 }
	for _, key in Economy.Rebirth.resets do
		partial[key] = RESET_TO[key]
	end
	if partial.runSpeed then
		partial.speedLevel = 0 -- the speed level goes with the speed
	end
	DataService:Set(player, partial)
	ChaseService:RefreshWalkSpeed(player)
	PlotService:Refresh(player) -- income labels include the rebirth multiplier
	Analytics.custom(player, "Rebirth", data.rebirths) -- `data` is live: already the new count
	return true
end

function UpgradeService:Start()
	Remotes.get("BuyUpgrade").OnServerEvent:Connect(function(player: Player, kind: any)
		if not limiter:allow(player) then
			return
		end
		if kind == "RunSpeed" then
			self:Buy(player, kind)
		end -- "KickPower" is not sold: strength is trained at the rack (RackService)
	end)
	Remotes.get("Rebirth").OnServerEvent:Connect(function(player: Player)
		if limiter:allow(player) then
			self:Rebirth(player)
		end
	end)
end

return UpgradeService
