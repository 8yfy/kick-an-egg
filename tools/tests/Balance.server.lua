-- Chase winnability per zone with the current Config/Chase numbers (the player steers the egg).
-- For an egg landing in the middle of each zone: the minimum egg speed that reaches the safe line
-- ahead of the avalanche, and the speed multiplier that needs at base Run Speed and at max Run Speed.
-- Egg speed = runSpeed x speedMultiplier (trained on the training pad).
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

print("[Bal] zone | avalanche speed | min egg speed | multiplier needed at Run Speed 16 | at 40")
for _, zone in Zones do
	local D = zone.start + zone.length / 2
	local need = nil
	for v = 1, 400 do
		if secured(D, zone.id, v) then
			need = v
			break
		end
	end
	if need then
		print(
			("[Bal] %2d | %4.1f | %3d | x%.2f | x%.2f"):format(
				zone.id,
				Chase.avalancheSpeed(zone.id),
				need,
				math.max(1, need / Economy.RunSpeed.base),
				math.max(1, need / Economy.RunSpeed.max)
			)
		)
	else
		print(("[Bal] %2d | never"):format(zone.id))
	end
end
