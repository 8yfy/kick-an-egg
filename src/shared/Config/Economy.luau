--!strict
-- Partner B owns this file. Tune freely. tools/tests/Progression.server.lua prints what these numbers mean in
-- play (kicks, minutes and money per sack / zone, speed per level); ServerTests checks the formulas stay finite.
local Economy = {
	StartingMoney = 0,
	-- Kick power = Strength: trained by kicking your Kick Sack gear (Config/Upgrades.Sack), never bought. Each
	-- sack trains only up to its cap (Economy.sackCap); `max` is the absolute cap before rebirths.
	-- costBase/costGrowth are unused while the Store's Kick Power card is disabled.
	KickPower = { base = 1, max = 100, costBase = 25, costGrowth = 1.18 },
	-- Run Speed = egg speed while steering and walk speed; bought in the shop (BuyUpgrade "RunSpeed"), with NO
	-- level cap. The saved value is the level (PlayerData.speedLevel); the actual speed follows a curve that
	-- approaches `max` (half the remaining gap per `halfLevels` levels), so any level is safe to move at.
	-- Price of the next level: costBase * costGrowth^level up to expLevels, then it only grows linearly
	-- (linearStep of that price per level), so it never reaches infinity / NaN however high the level.
	RunSpeed = {
		base = 16,
		max = 48,
		halfLevels = 30,
		costBase = 100,
		costGrowth = 1.35,
		expLevels = 120,
		linearStep = 0.05,
	},
	DistancePerPower = 24, -- studs per kick power point (before timing/multipliers)
	TimingBonus = { perfect = 1.5, good = 1.15, miss = 0.85 },
	Rebirth = {
		requiresMaxPower = true, -- needs kickPower at maxKickPower(rebirths); never mid-chase
		multiplierPerRebirth = 0.5, -- pet income x (1 + rebirths * this)
		-- kick distance x (1 + rebirths * this). Was the income multiplier (0.5) too; together with the higher
		-- caps that stacked into a free ride past most zones after one rebirth.
		distancePerRebirth = 0.1,
		powerCapBonus = 25, -- each rebirth raises the strength cap (and every sack's cap in proportion)
		-- What a rebirth does (UpgradeService applies `resets`; the Rebirth screen lists both lists).
		resets = { "money", "kickPower", "runSpeed" }, -- to StartingMoney / KickPower.base / Run Speed level 0
		keeps = { "eggs", "pets", "rackLevel", "penLevel", "discovered" },
	},
	-- Pet Index: zone id -> reward for discovering every pet of that zone, claimed once
	-- (Remotes.ClaimIndexReward). Empty = no rewards configured; the Index then shows no reward panel.
	IndexRewards = {} :: { [number]: { money: number } },
	-- Pet Index completion milestones (Remotes.ClaimIndexMilestone): discover `count` different pets, claim once.
	-- `incomeBonus` is a permanent pet income bonus (x (1 + bonus)) once claimed. Money scales with the stage of
	-- the game a player usually reaches that count in (10 ~ zones 1-3 ... all 79 = every zone incl. the Secret).
	IndexMilestones = {
		{ count = 10, money = 2500 },
		{ count = 25, money = 75000 },
		{ count = 40, money = 1000000 },
		{ count = 60, money = 50000000 },
		{ count = 79, money = 1000000000, incomeBonus = 0.1 },
	} :: { { count: number, money: number, incomeBonus: number? } },
	PlotSlots = { base = 8, max = 20 }, -- pen capacity: placed eggs + placed pets
	FriendLuckPerFriend = 0.1,
	AutosaveSeconds = 90,
	SellIncomeSeconds = 60, -- a pet sells for this many seconds of its income (size + weather, no rebirth)

	-- Placeholder IDs (0 = not created yet; skipped). Replace with real IDs before publishing.
	Gamepasses = {
		DoubleMoney = { id = 0, incomeMultiplier = 2 },
	} :: { [string]: { id: number, incomeMultiplier: number } },
	DevProducts = {
		MoneySmall = { id = 0, money = 1000 },
		MoneyMedium = { id = 0, money = 15000 },
		MoneyLarge = { id = 0, money = 250000 },
	} :: { [string]: { id: number, money: number } },
}

export type UpgradeKind = "KickPower" | "RunSpeed"

-- Highest Kick Power this player can train; each rebirth raises the cap.
function Economy.maxKickPower(rebirths: number): number
	return Economy.KickPower.max + rebirths * Economy.Rebirth.powerCapBonus
end

-- A sack's training cap (Config/Upgrades.Sack.tiers[].cap) after `rebirths` rebirths: scaled like the absolute
-- cap, so the last sack always trains to maxKickPower(rebirths).
function Economy.sackCap(tierCap: number, rebirths: number): number
	return tierCap * Economy.maxKickPower(rebirths) / Economy.KickPower.max
end

-- Kick distance multiplier from rebirths.
function Economy.distanceMultiplier(rebirths: number): number
	return 1 + rebirths * Economy.Rebirth.distancePerRebirth
end

-- Run Speed (studs/s) at speed `level` (0 = base). Approaches RunSpeed.max, never passes it.
function Economy.runSpeedAt(level: number): number
	local rs = Economy.RunSpeed
	local l = math.max(0, if level == level then level else 0)
	return rs.base + (rs.max - rs.base) * (1 - 2 ^ (-l / rs.halfLevels))
end

-- The lowest level whose speed is at least `speed` (save migration from the old speed value).
function Economy.speedLevelFor(speed: number): number
	local rs = Economy.RunSpeed
	if speed ~= speed or speed <= rs.base then
		return 0
	end
	local fraction = math.min((speed - rs.base) / (rs.max - rs.base), 0.999999)
	return math.ceil(-rs.halfLevels * math.log(1 - fraction, 2) - 1e-9)
end

-- Price of buying speed level `level + 1` when at `level`. Finite for any level.
function Economy.speedCost(level: number): number
	local rs = Economy.RunSpeed
	local l = math.max(0, math.floor(if level == level then level else 0))
	local exp = math.min(l, rs.expLevels)
	local cost = rs.costBase * rs.costGrowth ^ exp * (1 + math.max(0, l - rs.expLevels) * rs.linearStep)
	return math.floor(math.min(cost, 1e300))
end

-- Price of the next +1 of `kind`. KickPower: `value` = current power (not sold); RunSpeed: `value` = the current
-- speed LEVEL (Economy.speedCost). Shared by the server (BuyUpgrade) and the shop UI so both show the same number.
function Economy.upgradeCost(kind: UpgradeKind, value: number): number
	if kind == "RunSpeed" then
		return Economy.speedCost(value)
	end
	local config = Economy.KickPower
	return math.floor(config.costBase * config.costGrowth ^ (value - config.base))
end

return Economy
