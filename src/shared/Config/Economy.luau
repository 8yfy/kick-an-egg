--!strict
-- Partner B owns this file. Tune freely. tools/tests/Progression.server.lua prints what these numbers mean in
-- play (kicks, minutes and money per sack / zone, speed per level); ServerTests checks the formulas stay finite.
local Economy = {
	StartingMoney = 0,
	-- Kick Power = Strength: WHOLE numbers, trained by kicking your Kick Sack (Config/Upgrades.Sack, integer gains
	-- that grow into the billions with better sacks), never bought, no design cap. `max` is only the largest
	-- whole number a Luau number stores exactly (2^53 - 1 ~ 9 quadrillion), far above the trillions a full sack
	-- ladder reaches; past it the number would silently lose precision, so power stops there.
	KickPower = { base = 1, max = 9007199254740991 },
	-- Kick distance follows the LOG of power (Economy.kickDistance): every `studsPerDecade` studs takes 10x the
	-- power, so huge numbers never mean an instant trip to the last zone. Fitted to the 2000-stud track: about
	-- 10 power reaches zone 2, 1 million zone 10, 1 trillion zone 20 (tools/tests/Progression.server.lua).
	Distance = { studsPerDecade = 160 },
	-- Timing multiplies the DISTANCE: a Perfect kick goes 12% farther, a missed one 15% shorter.
	TimingBonus = { perfect = 1.12, good = 1, miss = 0.85 },
	-- Run Speed = egg speed while steering and walk speed; bought in the shop (BuyUpgrade "RunSpeed") with NO
	-- level cap. Speed = base + gain * ln(1 + level / scale): it keeps growing at every level, a little less each
	-- time (diminishing returns), so high levels still count but movement stays controllable (`safety` studs/s
	-- is only reached around level 10 million). Price of the next level = costBase * (level + 1)^costPower:
	-- finite and readable at any level, steep enough that late speed is an achievement.
	RunSpeed = { base = 16, gain = 8, scale = 20, safety = 120, costBase = 25, costPower = 2 },
	Rebirth = {
		-- needs Economy.rebirthPower(rebirths) Kick Power: firstPower, then x powerGrowth per rebirth (1M, 10M,
		-- 100M ...); never mid-chase
		firstPower = 1000000,
		powerGrowth = 10,
		multiplierPerRebirth = 0.5, -- pet income x (1 + rebirths * this)
		distancePerRebirth = 0.1, -- kick distance x (1 + rebirths * this)
		trainingPerRebirth = 1, -- Kick Sack gains x (1 + rebirths * this): power grows back faster
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

-- The Kick Power a player needs for their next rebirth (`rebirths` done so far).
function Economy.rebirthPower(rebirths: number): number
	local r = math.clamp(math.floor(if rebirths == rebirths then rebirths else 0), 0, 12)
	return math.floor(Economy.Rebirth.firstPower * Economy.Rebirth.powerGrowth ^ r)
end

-- (kept for older callers) the largest Kick Power a player can hold: the exact-integer ceiling.
function Economy.maxKickPower(_rebirths: number): number
	return Economy.KickPower.max
end

-- Kick distance multiplier from rebirths.
function Economy.distanceMultiplier(rebirths: number): number
	return 1 + rebirths * Economy.Rebirth.distancePerRebirth
end

-- Kick distance (studs, before the track's end clamp) for `power`, `rebirths` and a timing multiplier
-- (TimingBonus.perfect / good / miss): the log curve above. Finite for any power.
function Economy.kickDistance(power: number, rebirths: number, timing: number): number
	local p = math.max(0, if power == power then math.min(power, Economy.KickPower.max) else 0)
	return Economy.Distance.studsPerDecade * math.log10(1 + p) * timing * Economy.distanceMultiplier(rebirths)
end

-- Kick Power gained by one kick on a sack giving `gain` (Config/Upgrades) after `rebirths`: a whole number.
function Economy.trainGain(gain: number, rebirths: number): number
	local mult = 1 + math.max(0, rebirths) * Economy.Rebirth.trainingPerRebirth
	return math.max(1, math.floor(gain * mult + 0.5))
end

-- Kick Power after training `value` by `gain` (whole number, never past KickPower.max, never NaN).
function Economy.addPower(value: number, gain: number): number
	local v = if value == value then math.floor(value) else Economy.KickPower.base
	return math.clamp(v + math.floor(gain), Economy.KickPower.base, Economy.KickPower.max)
end

-- Run Speed (studs/s) at speed `level` (0 = base): grows forever, slower and slower (log), finite for any level.
function Economy.runSpeedAt(level: number): number
	local rs = Economy.RunSpeed
	local l = math.max(0, if level == level then level else 0)
	return math.min(rs.base + rs.gain * math.log(1 + l / rs.scale), rs.safety)
end

-- The lowest level whose speed is at least `speed` (save migration).
function Economy.speedLevelFor(speed: number): number
	local rs = Economy.RunSpeed
	if speed ~= speed or speed <= rs.base then
		return 0
	end
	local s = math.min(speed, rs.safety)
	return math.max(0, math.ceil(rs.scale * (math.exp((s - rs.base) / rs.gain) - 1) - 1e-6))
end

-- Price of buying speed level `level + 1` when at `level`. Finite and whole for any level.
function Economy.speedCost(level: number): number
	local rs = Economy.RunSpeed
	local l = math.max(0, math.floor(if level == level then level else 0))
	return math.floor(math.min(rs.costBase * (l + 1) ^ rs.costPower, 1e300))
end

-- Price of the next +1 of `kind`. RunSpeed: `value` = the current speed LEVEL (Economy.speedCost). Kick Power is
-- never sold (trained only). Shared by the server (BuyUpgrade) and the shop UI so both show the same number.
function Economy.upgradeCost(kind: UpgradeKind, value: number): number
	if kind == "RunSpeed" then
		return Economy.speedCost(value)
	end
	return math.huge
end

return Economy
