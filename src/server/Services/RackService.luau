--!strict
-- Base upgrades from Config/Upgrades, server side:
--   UpgradePen()      buys pen level + 1 for Pen.costBase x Pen.costGrowth^(level - 1): more slots.
-- (Strength training and the sack ladder moved to SackService: Train / UpgradeTraining.)
-- Levels are mirrored on the base (PlotService:MirrorBase) for the signs and the Store.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local PlotService = require(script.Parent.PlotService)

local RackService = {}

local limiter = RateLimiter.new()

-- Price of pen level + 1, or nil when the pen already has the most slots.
function RackService.penCost(level: number): number?
	if PlotService.slotsForPen(level) >= Economy.PlotSlots.max then
		return nil
	end
	local pen = Upgrades.Pen
	return math.floor(pen.costBase * pen.costGrowth ^ (level - 1))
end

local function onUpgradePen(player: Player)
	local data = DataService:Get(player)
	if not limiter:allow(player) or not data then
		return
	end
	local cost = RackService.penCost(data.penLevel)
	if not cost or data.money < cost then
		return
	end
	DataService:Set(player, { money = data.money - cost, penLevel = data.penLevel + 1 })
	PlotService:MirrorBase(player)
	Analytics.money(player, "Sink", cost, "Shop", "Pen")
	Analytics.funnel(player, Analytics.Funnel.FirstUpgrade, "FirstUpgrade")
end

function RackService:Start()
	Remotes.get("UpgradePen").OnServerEvent:Connect(onUpgradePen)
end

return RackService
