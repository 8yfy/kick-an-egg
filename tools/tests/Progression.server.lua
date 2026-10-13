-- Progression with the current Config numbers (Economy, Upgrades.Sack, Chase, Zones). Prints, and checks:
--   1. per zone (egg landing mid-zone, 0 rebirths, perfect kick): the Kick Power it takes, the first Kick Sack
--      whose cap reaches it, the kicks / minutes of training to get there (each sack trained to its cap in
--      turn, one kick per Upgrades.Sack.interval), the sacks' total price, the avalanche speed, and the lowest
--      Run Speed level that gets the egg home ahead of it (steering straight home) with the levels' total price;
--   2. Run Speed per level: speed, next level's price, total price from level 0;
--   3. rebirths: how far the last sack's cap kicks after 0..5 rebirths.
-- Fails if a zone can't be reached or can't be won at any level (the avalanche must never be impossible).
-- Run: sh tools/run-tests.sh tools/tests/Progression.server.lua

local Shared = game.ReplicatedStorage.Shared
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Zones = require(Shared.Config.Zones)
local A, E = Chase.Avalanche, Chase.Egg
local Sack = Upgrades.Sack
local DT = 0.01
local MAX_LEVEL = 2000
local failures = 0

local function fail(text)
	failures += 1
	print("[Prog] FAIL " .. text)
end

local function money(n)
	if n >= 1e12 then
		return ("%.2fT"):format(n / 1e12)
	elseif n >= 1e9 then
		return ("%.2fB"):format(n / 1e9)
	elseif n >= 1e6 then
		return ("%.2fM"):format(n / 1e6)
	elseif n >= 1e3 then
		return ("%.1fK"):format(n / 1e3)
	end
	return tostring(math.floor(n))
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

-- Training: each sack in turn trained to its cap (or to `power`), one kick per Sack.interval.
local function training(power, rebirths)
	local value, kicks, price = Economy.KickPower.base, 0, 0
	for tier, t in Sack.tiers do
		price += t.cost
		local cap = Economy.sackCap(t.cap, rebirths)
		local target = math.min(cap, power)
		if target > value then
			kicks += math.ceil((target - value) / t.gain - 1e-9)
			value = target
		end
		if value >= power - 1e-9 then
			return tier, kicks, price
		end
	end
	return nil, kicks, price
end

print(
	"[Prog] zone | land z | power needed | first sack (tier) | training kicks / min | sacks price | avalanche | Run Speed level (speed) | levels price"
)
for _, zone in Zones do
	local D = zone.start + zone.length / 2
	local power = D / (Economy.DistancePerPower * Economy.TimingBonus.perfect * Economy.distanceMultiplier(0))
	local tier, kicks, price = training(power, 0)
	local level = levelFor(D, zone.id)
	print(
		("[Prog] %2d | %5d | %5.1f | %-16s | %6d / %5.1f | %8s | %4.1f | %s | %s"):format(
			zone.id,
			D,
			power,
			if tier then ("%s (%d)"):format(Sack.tiers[tier].name, tier) else "none",
			kicks,
			kicks * Sack.interval / 60,
			money(price),
			Chase.avalancheSpeed(zone.id),
			if level then ("%d (%.1f)"):format(level, Economy.runSpeedAt(level)) else "never",
			if level then money(speedTotal(level)) else "-"
		)
	)
	if not tier then
		fail(("zone %d: no sack reaches %.1f Kick Power without rebirths"):format(zone.id, power))
	end
	if not level then
		fail(("zone %d: the avalanche can't be outrun at any Run Speed level"):format(zone.id))
	end
end

print("[Prog] Run Speed level | speed | next level price | total from 0")
for _, level in { 0, 1, 5, 10, 20, 30, 40, 50, 60, 75, 100, 120, 150, 200, 500, 1000, 1e6 } do
	local speed, cost = Economy.runSpeedAt(level), Economy.speedCost(level)
	print(
		("[Prog] %7d | %5.2f | %10s | %s"):format(
			level,
			speed,
			money(cost),
			if level <= 1000 then money(speedTotal(level)) else "-"
		)
	)
	if speed ~= speed or speed > Economy.RunSpeed.max or cost ~= cost or cost == math.huge then
		fail(("Run Speed level %d: speed %s / price %s"):format(level, tostring(speed), tostring(cost)))
	end
end

print("[Prog] rebirths | strength cap | last sack reaches z (perfect) | zone")
for r = 0, 5 do
	local cap = Economy.sackCap(Sack.tiers[#Sack.tiers].cap, r)
	local z = cap * Economy.DistancePerPower * Economy.TimingBonus.perfect * Economy.distanceMultiplier(r)
	local zone = math.clamp(math.floor(z / Zones[1].length) + 1, 1, #Zones)
	print(("[Prog] %d | %5.1f | %6.0f | %d"):format(r, cap, z, zone))
end

print(("[Prog] done: %d failure(s)"):format(failures))
