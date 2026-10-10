--!strict
-- Base upgrades from Config/Upgrades (Partner A's contract #30), server side:
--   Train()           one training kick at your own rack: you must stand within Rack.range of
--                     Base<i>.TrainingRack.Plate, at most once per Rack.interval, not mid-chase;
--                     adds Rack.levels[rackLevel].gain to Rack.stat (strength = kickPower, capped).
--   UpgradeTraining() buys rack level + 1 for levels[level + 1].cost (a better rack trains faster).
--   UpgradePen()      buys pen level + 1 for Pen.costBase x Pen.costGrowth^(level - 1): more slots.
-- Levels are mirrored on the base (PlotService:MirrorBase) for A's rack model, signs and Store.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local KickService = require(script.Parent.KickService)
local PlotService = require(script.Parent.PlotService)

local INTERVAL_SLACK = 0.85 -- accept kicks slightly early (network jitter); still ~1 per interval

local RackService = {}

local limiter = RateLimiter.new()
local lastTrain: { [Player]: number } = {}

-- Pure helpers (used by the tests) -----------------------------------------

local function capFor(stat: string, rebirths: number): number
	if stat == "kickPower" then
		return Economy.maxKickPower(rebirths)
	elseif stat == "runSpeed" then
		return Economy.RunSpeed.max
	end
	return math.huge
end

-- `value` after one training kick on a rack of `level`.
function RackService.trained(value: number, level: number, rebirths: number): number
	local levels = Upgrades.Rack.levels
	local gain = levels[math.clamp(level, 1, #levels)].gain
	local result = math.min(value + gain, capFor(Upgrades.Rack.stat, rebirths))
	return math.floor(result * 1000 + 0.5) / 1000 -- keep saves tidy
end

-- Price of rack level + 1, or nil at the top.
function RackService.rackCost(level: number): number?
	local nextLevel = Upgrades.Rack.levels[level + 1]
	return if nextLevel then nextLevel.cost else nil
end

-- Price of pen level + 1, or nil when the pen already has the most slots.
function RackService.penCost(level: number): number?
	if PlotService.slotsForPen(level) >= Economy.PlotSlots.max then
		return nil
	end
	local pen = Upgrades.Pen
	return math.floor(pen.costBase * pen.costGrowth ^ (level - 1))
end

function RackService.inRange(plate: BasePart, position: Vector3): boolean
	return (position - plate.Position).Magnitude <= Upgrades.Rack.range
end

-- Handlers -----------------------------------------------------------------

local function plateOf(player: Player): BasePart?
	local base = PlotService:GetBase(player)
	local rack = base and base:FindFirstChild("TrainingRack")
	local plate = rack and rack:FindFirstChild("Plate", true)
	return if plate and plate:IsA("BasePart") then plate else nil
end

local function onTrain(player: Player)
	if not limiter:allow(player) or KickService:GetActive(player) then
		return
	end
	local now = os.clock()
	if now - (lastTrain[player] or 0) < Upgrades.Rack.interval * INTERVAL_SLACK then
		return
	end
	local data = DataService:Get(player)
	local plate = plateOf(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not plate or not hrp or not hrp:IsA("BasePart") or not RackService.inRange(plate, hrp.Position) then
		return
	end
	lastTrain[player] = now
	local stat = Upgrades.Rack.stat
	local value = RackService.trained(data[stat], data.rackLevel, data.rebirths)
	if value ~= data[stat] then
		DataService:Set(player, { [stat] = value })
	end
end

local function buy(player: Player, cost: number?, key: string, sku: string)
	local data = DataService:Get(player)
	if not data or not cost or data.money < cost then
		return
	end
	DataService:Set(player, { money = data.money - cost, [key] = data[key] + 1 })
	PlotService:MirrorBase(player)
	Analytics.money(player, "Sink", cost, "Shop", sku)
	Analytics.funnel(player, Analytics.Funnel.FirstUpgrade, "FirstUpgrade")
end

local function onUpgradeTraining(player: Player)
	local data = DataService:Get(player)
	if limiter:allow(player) and data then
		buy(player, RackService.rackCost(data.rackLevel), "rackLevel", "TrainingRack")
	end
end

local function onUpgradePen(player: Player)
	local data = DataService:Get(player)
	if limiter:allow(player) and data then
		buy(player, RackService.penCost(data.penLevel), "penLevel", "Pen")
	end
end

function RackService:Start()
	Remotes.get("Train").OnServerEvent:Connect(onTrain)
	Remotes.get("UpgradeTraining").OnServerEvent:Connect(onUpgradeTraining)
	Remotes.get("UpgradePen").OnServerEvent:Connect(onUpgradePen)
	Players.PlayerRemoving:Connect(function(player)
		lastTrain[player] = nil
	end)
end

return RackService
