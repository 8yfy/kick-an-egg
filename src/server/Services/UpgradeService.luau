--!strict
-- BuyUpgrade(kind): +1 Kick Power or Run Speed for Economy.upgradeCost. Rebirth(): only at the
-- Kick Power cap; resets money, Kick Power and Run Speed, keeps eggs and pets, +1 rebirth
-- (higher income multiplier and a higher Kick Power cap).

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

local limiter = RateLimiter.new()

local DATA_KEY: { [Economy.UpgradeKind]: string } = {
	KickPower = "kickPower",
	RunSpeed = "runSpeed",
}

local function capFor(kind: Economy.UpgradeKind, rebirths: number): number
	return if kind == "KickPower" then Economy.maxKickPower(rebirths) else Economy.RunSpeed.max
end

-- Returns true if bought. Exposed for tests and for a future auto-buy.
function UpgradeService:Buy(player: Player, kind: Economy.UpgradeKind): boolean
	local data = DataService:Get(player)
	local key = DATA_KEY[kind]
	if not data or not key then
		return false
	end
	local value: number = data[key]
	if value >= capFor(kind, data.rebirths) then
		return false
	end
	local cost = Economy.upgradeCost(kind, value)
	if data.money < cost then
		return false
	end
	DataService:Set(player, { money = data.money - cost, [key] = value + 1 })
	Analytics.money(player, "Sink", cost, "Shop", kind)
	Analytics.funnel(player, Analytics.Funnel.FirstUpgrade, "FirstUpgrade")
	if kind == "RunSpeed" then
		ChaseService:RefreshWalkSpeed(player)
	end
	return true
end

-- Next training pad level (faster speedMultiplier training). Returns true if bought.
function UpgradeService:BuyTrainingPad(player: Player): boolean
	local data = DataService:Get(player)
	local cost = data and Economy.trainingPadCost(data.trainingPad)
	if not data or not cost or data.money < cost then
		return false
	end
	DataService:Set(player, { money = data.money - cost, trainingPad = data.trainingPad + 1 })
	Analytics.money(player, "Sink", cost, "Shop", "TrainingPad")
	return true
end

function UpgradeService:CanRebirth(player: Player): boolean
	local data = DataService:Get(player)
	if not data or KickService:GetActive(player) then
		return false -- no rebirth mid-chase
	end
	return not Economy.Rebirth.requiresMaxPower or data.kickPower >= Economy.maxKickPower(data.rebirths)
end

function UpgradeService:Rebirth(player: Player): boolean
	if not self:CanRebirth(player) then
		return false
	end
	local data = DataService:Get(player) :: DataService.Data
	DataService:Set(player, {
		rebirths = data.rebirths + 1,
		money = Economy.StartingMoney,
		kickPower = Economy.KickPower.base,
		runSpeed = Economy.RunSpeed.base,
	})
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
		if kind == "KickPower" or kind == "RunSpeed" then
			self:Buy(player, kind)
		elseif kind == "TrainingPad" then
			self:BuyTrainingPad(player)
		end
	end)
	Remotes.get("Rebirth").OnServerEvent:Connect(function(player: Player)
		if limiter:allow(player) then
			self:Rebirth(player)
		end
	end)
end

return UpgradeService
