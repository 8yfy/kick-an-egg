-- Progression with the current Config numbers (Economy, Upgrades.Sack, Chase, Zones). Prints, and checks:
--   1. per zone (egg landing mid-zone, 0 rebirths): the whole-number Kick Power a normal and a Perfect kick
--      need (Economy.kickDistance: log of power), the sack bought for that zone and the kicks it takes from the
--      zone before, the avalanche speed, and the lowest Run Speed level that gets the egg home ahead of it
--      (steering straight home) with the levels' total price;
--   2. Run Speed per level (past 120 into the millions): speed, the gain of one more level, its price;
--   3. Kick Power -> distance (1 .. trillions): how slowly distance grows with huge numbers.
-- Fails if a zone can't be reached or won, an avalanche isn't faster than the zone before, or a level adds no speed.
-- Run: sh tools/run-tests.sh tools/tests/Progression.server.lua

local Shared = game.ReplicatedStorage.Shared
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Zones = require(Shared.Config.Zones)
local A, E = Chase.Avalanche, Chase.Egg
local Sack = Upgrades.Sack
local DT = 0.01
local MAX_LEVEL = 10000000
local failures = 0

local function fail(text)
	failures += 1
	print("[Prog] FAIL " .. text)
end

local SUFFIX = { "", "K", "M", "B", "T", "Qa" }
local function short(n)
	local i, v = 1, n
	while math.abs(v) >= 1000 and i < #SUFFIX do
		v /= 1000
		i += 1
	end
	return (if i == 1 then tostring(math.floor(v)) else string.format("%.2f", v)) .. SUFFIX[i]
end

-- Does an egg landing at D (zone `zone`) get home at speed v, steered straight back from touchdown + runDelay?
local function secured(D, zone, v)
	local T = Chase.flightSeconds(D)
	local sZ, sT, spd = Chase.avalancheStartZ(D, zone), T + A.warnSeconds, Chase.avalancheSpeed(zone)
	local control = T + E.runDelay
	local t, z = T, D
	while z >= Chase.SafeLineZ do
		t += DT
		if t >= control then
			z -= v * DT
		end
		if z >= Chase.frontZ(sZ, sT, spd, t) - A.catchDistance then
			return false
		end
	end
	return true
end

local function levelFor(D, zone)
	if secured(D, zone, Economy.runSpeedAt(0)) then
		return 0
	end
	local lo, hi = 0, MAX_LEVEL -- secured() only gets easier with speed: binary search
	if not secured(D, zone, Economy.runSpeedAt(hi)) then
		return nil
	end
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if secured(D, zone, Economy.runSpeedAt(mid)) then
			hi = mid
		else
			lo = mid
		end
	end
	return hi
end

local function speedTotal(level)
	local total = 0
	for l = 0, level - 1 do
		total += Economy.speedCost(l)
	end
	return total
end

-- the whole-number power a kick with `timing` needs to land at D
local function powerFor(D, timing)
	return math.ceil(10 ^ (D / (Economy.Distance.studsPerDecade * timing)) - 1)
end

local good, perfect = Economy.TimingBonus.good, Economy.TimingBonus.perfect
local reach = Chase.trackEnd() - Chase.Landing.endMargin
print(
	"[Prog] zone | land z | power (Perfect) | sack for it (gain) : kicks | avalanche | Run Speed level (speed) | levels price | sack price"
)
local lastAvalanche = 0
for _, zone in Zones do
	local D = math.min(zone.start + zone.length / 2, reach)
	local need, needPerfect = powerFor(D, good), powerFor(D, perfect)
	local tier = math.min(zone.id, #Sack.tiers)
	local before = if zone.id == 1 then Economy.KickPower.base else powerFor(D - zone.length, good)
	local kicks = math.ceil(math.max(0, need - before) / Sack.tiers[tier].gain)
	local level = levelFor(D, zone.id)
	local avalanche = Chase.avalancheSpeed(zone.id)
	print(
		("[Prog] %2d | %5d | %8s (%8s) | %-16s (+%s) : %5d | %4.1f | %s | %s | %s"):format(
			zone.id,
			D,
			short(need),
			short(needPerfect),
			Sack.tiers[tier].name,
			short(Sack.tiers[tier].gain),
			kicks,
			avalanche,
			if level then ("%d (%.2f)"):format(level, Economy.runSpeedAt(level)) else "never",
			if level then short(speedTotal(level)) else "-",
			short(Sack.tiers[tier].cost)
		)
	)
	if Economy.kickDistance(need, 0, good) < D - 1 then
		fail(("zone %d: %s power doesn't reach it"):format(zone.id, short(need)))
	end
	if not level then
		fail(("zone %d: the avalanche can't be outrun at any Run Speed level"):format(zone.id))
	end
	if avalanche <= lastAvalanche then
		fail(("zone %d: the avalanche isn't faster than the zone before"):format(zone.id))
	end
	lastAvalanche = avalanche
end

print("[Prog] Run Speed level | speed | next level adds | next level price | total from 0")
local lastSpeed = -1
for _, level in { 0, 1, 10, 50, 100, 120, 121, 200, 500, 1000, 5000, 10000, 100000, 1000000 } do
	local speed, nextGain, cost =
		Economy.runSpeedAt(level), Economy.runSpeedAt(level + 1) - Economy.runSpeedAt(level), Economy.speedCost(level)
	print(
		("[Prog] %8d | %6.2f | +%.5f | %10s | %s"):format(
			level,
			speed,
			nextGain,
			short(cost),
			if level <= 100000 then short(speedTotal(level)) else "-"
		)
	)
	if speed ~= speed or speed <= lastSpeed or nextGain <= 0 or cost ~= cost or cost == math.huge then
		fail(
			("Run Speed level %d: speed %s, next +%s, price %s"):format(
				level,
				tostring(speed),
				tostring(nextGain),
				tostring(cost)
			)
		)
	end
	lastSpeed = speed
end

print("[Prog] Kick Power | normal kick lands at z | zone | Perfect kick z")
for _, power in { 1, 10, 100, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13, Economy.KickPower.max } do
	local z = math.min(Economy.kickDistance(power, 0, good), reach)
	local zp = math.min(Economy.kickDistance(power, 0, perfect), reach)
	print(("[Prog] %8s | %6.0f | %2d | %6.0f"):format(short(power), z, math.min(20, math.floor(z / 100) + 1), zp))
end

print(("[Prog] done: %d failure(s)"):format(failures))
