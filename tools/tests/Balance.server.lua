-- Chase winnability per zone with the current Config/Chase numbers: the minimum Run Speed that
-- secures an egg landing in the middle of each zone.
--   launch: the kicker is moved Launch.behindLanding studs behind the landing at touchdown (the rule)
--   pad:    the old rule, running out from the kick pad (zones 5+ were unwinnable)
-- Run: sh tools/run-tests.sh tools/tests/Balance.server.lua

local Shared = game.ReplicatedStorage.Shared
local Chase = require(Shared.Config.Chase)
local Zones = require(Shared.Config.Zones)
local A, E = Chase.Avalanche, Chase.Egg
local BEHIND = (Chase.Launch or { behindLanding = 12 }).behindLanding
local DT = 0.01

-- `launch` true: player appears at (D - BEHIND) at touchdown. false: leaves the pad (Z=0) at kick time.
local function rescue(D, zone, v, launch)
	local T = 0.35 + Chase.flightSeconds(D)
	local sZ, sT, spd = D + A.spawnBehindLanding, T + A.warnSeconds, Chase.avalancheSpeed(zone)
	local runStart = T + E.runDelay
	local function front(tt)
		return Chase.frontZ(sZ, sT, spd, tt)
	end
	local function egg(tt)
		return math.max(D - E.runSpeed * math.max(0, tt - runStart), Chase.SafeLineZ)
	end
	local t, p = 0, 0
	if launch then
		t, p = T, D - BEHIND
	end
	while true do
		t += DT
		if t > T and egg(t) >= front(t) - A.catchDistance then
			return false
		end
		if p >= Chase.SafeLineZ and p >= front(t) - A.catchDistance then
			return false
		end
		if t >= T and math.abs(egg(t) - p) <= E.pickupDistance then
			break
		end
		if p < egg(t) then
			p = math.min(p + v * DT, egg(t))
		end
	end
	local carry = v * Chase.Carry.speedMultiplier
	while p >= Chase.SafeLineZ do
		t += DT
		p -= carry * DT
		if p >= Chase.SafeLineZ and p >= front(t) - A.catchDistance then
			return false
		end
	end
	return true
end

local function minSpeed(D, zone, launch)
	for v = 16, 40 do
		if rescue(D, zone, v, launch) then
			return tostring(v)
		end
	end
	return "never"
end

print("[Bal] zone | avalanche speed | min Run Speed with launch | (old rule, from the pad)")
for _, zone in Zones do
	local D = zone.start + zone.length / 2
	print(
		("[Bal] %2d | %4.1f | %5s | (%s)"):format(
			zone.id,
			Chase.avalancheSpeed(zone.id),
			minSpeed(D, zone.id, true),
			minSpeed(D, zone.id, false)
		)
	)
end
