-- Progression per zone with the current Config numbers (the player steers the egg).
-- For an egg landing in the middle of each zone:
--   strength: kick power needed to reach it with a perfect kick (0 rebirths)
--   speed:    the minimum Run Speed (= egg speed, bought in the shop) that gets it home ahead of
--             the avalanche, and the total shop cost of buying up to it from the base speed.
-- Run: sh tools/run-tests.sh tools/tests/Balance.server.lua

local Shared = game.ReplicatedStorage.Shared
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)
local Zones = require(Shared.Config.Zones)
local A, E = Chase.Avalanche, Chase.Egg
local DT = 0.01

local function secured(D, zone, v)
	local T = 0.35 + Chase.flightSeconds(D)
	local sZ, sT, spd = D + A.spawnBehindLanding, T + A.warnSeconds, Chase.avalancheSpeed(zone)
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

local function speedCost(target)
	local total = 0
	for v = Economy.RunSpeed.base, target - 1 do
		total += Economy.upgradeCost("RunSpeed", v)
	end
	return total
end

print("[Bal] zone | strength needed | avalanche speed | Run Speed needed | shop cost from base")
for _, zone in Zones do
	local D = zone.start + zone.length / 2
	local strength = D / (Economy.DistancePerPower * Economy.TimingBonus.perfect)
	local need = nil
	for v = Economy.RunSpeed.base, Economy.RunSpeed.max do
		if secured(D, zone.id, v) then
			need = v
			break
		end
	end
	print(
		("[Bal] %2d | %5.1f | %4.1f | %s | %s"):format(
			zone.id,
			strength,
			Chase.avalancheSpeed(zone.id),
			if need then tostring(need) else "above max",
			if need then tostring(speedCost(need)) else "-"
		)
	)
end
