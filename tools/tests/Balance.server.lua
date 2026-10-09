-- Chase winnability per zone and Run Speed with the current Config/Chase numbers.
-- Run: sh tools/run-tests.sh tools/tests/Balance.server.lua
local Shared = game.ReplicatedStorage.Shared
local Chase = require(Shared.Config.Chase)
local Zones = require(Shared.Config.Zones)
local A, E = Chase.Avalanche, Chase.Egg
local DT = 0.01

-- One rescue: player leaves the pad (Z=0) at kick time, runs straight at the egg, carries it back.
-- startZ = where the player is when the kick happens (0 = on the pad).
local function rescue(D, zone, v, startZ)
	local T = 0.35 + Chase.flightSeconds(D)
	local sZ, sT, spd = D + A.spawnBehindLanding, T + A.warnSeconds, Chase.avalancheSpeed(zone)
	local runStart = T + E.runDelay
	local p, t = startZ, 0
	local function front(tt)
		return Chase.frontZ(sZ, sT, spd, tt)
	end
	local function egg(tt)
		return math.max(D - E.runSpeed * math.max(0, tt - runStart), Chase.SafeLineZ)
	end
	-- outbound
	while true do
		t += DT
		if t > T and egg(t) >= front(t) - A.catchDistance then
			return false, "egg caught", t
		end
		if p >= Chase.SafeLineZ and p >= front(t) - A.catchDistance then
			return false, "player caught out", t
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
			return false, "caught carrying", t
		end
	end
	return true, "secured", t
end

local speeds = { 16, 20, 24, 28, 32, 36, 40 }
print(
	"[Bal] zone | aval speed | min Run Speed to win from the pad (zone middle) | from a pre-positioned spot next to the landing"
)
for _, zone in Zones do
	local D = zone.start + zone.length / 2
	local fromPad, fromNear = "never", "never"
	for _, v in speeds do
		if fromPad == "never" and rescue(D, zone.id, v, 0) then
			fromPad = tostring(v)
		end
		if fromNear == "never" and rescue(D, zone.id, v, D - 10) then
			fromNear = tostring(v)
		end
	end
	local _, why = rescue(D, zone.id, 40, 0)
	print(
		("[Bal] %2d | %4.1f | %5s (at 40: %s) | %5s"):format(
			zone.id,
			Chase.avalancheSpeed(zone.id),
			fromPad,
			why,
			fromNear
		)
	)
end
