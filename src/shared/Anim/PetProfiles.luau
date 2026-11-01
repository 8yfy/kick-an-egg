--!strict
-- Partner A. Signature motion for individual pets, so no two of them move alike (docs/EggPetPlan.md "Signature
-- motion"). Anim/Pet looks a profile up by model key: the ModelKey attribute on pen pets, else the model's name.
-- A profile owns the whole pose: idle (walk 0), roam (walk 1) and its special. The special plays when the pet's PetFx
-- special fires (PetFxSpecial), or by itself every so often; `k` runs 0..1 over `special` seconds (-1 otherwise).
-- Minor PetFx beats (`beat` bursts, e.g. the titan's steam hiss) arrive by name through `beatAge`.
-- Angles follow Anim/Pet: +X lifts a nose or swings a paw forward, +Y turns left, a group turns about its own pivot
-- in the root's frame after `around` (the body's motion), and legs keep the ground frame (CFrame.identity).
local Profiles = {}

export type Ctx = {
	t: number, -- phased time (s), different for every pet
	now: number,
	walk: number, -- 0 standing .. 1 roaming
	k: number, -- special phase 0..1, -1 when no special is playing
	m: { [string]: Motor6D },
	turn: (m: Motor6D?, around: CFrame, rot: CFrame) -> (),
	about: (m: Motor6D?, rot: CFrame) -> CFrame,
	beatAge: (name: string) -> number, -- seconds since the named PetFx beat, math.huge before the first
	cue: (name: string) -> (), -- a beat of this motion for PetFx `cue` emitters (a footfall, a tick)
	state: { [string]: any }, -- the profile's own memory, per pet
}
export type Profile = { special: number, pose: (c: Ctx) -> () }

local BY_KEY: { [string]: Profile } = {}

local TAU, rad = 2 * math.pi, math.rad

local function ease(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- 0 before a, eased up to 1 at b, held to c, eased back to 0 at d (and 0 while no special plays: k < 0).
local function env(k: number, a: number, b: number, c: number, d: number): number
	if k < a then
		return 0
	elseif k < b then
		return ease((k - a) / (b - a))
	elseif k < c then
		return 1
	end
	return 1 - ease((k - c) / (d - c))
end

-- Clock time: whole ticks of `every` seconds, each eased in over its first 0.12 s.
local function tick(t: number, every: number): number
	local u = t / every
	local n = math.floor(u)
	return n + ease((u - n) * every / 0.12)
end

-- Heaven Lion: a regal guardian. Breathes slowly (the mane swells with it), turns its head proudly and holds each
-- look, prowls heavily with rolling shoulders and a low head. Special, the roar (2.2 s, PetFx "roar"): it gathers
-- itself (body back and down, head rearing up, mane bristling), thrusts forward and roars with a shaking head, the
-- mane flaring back, the forepaws planted wide and the tail lashing; PetFx fires the shockwave at the thrust.
local LION_LOOKS = { 0, rad(-22), 0, rad(18) }
local function lionLook(t: number): number
	local u = t / 3.5
	local n = math.floor(u)
	local a, b = LION_LOOKS[n % 4 + 1], LION_LOOKS[(n + 1) % 4 + 1]
	return a + (b - a) * ease((u - n) / 0.35)
end

BY_KEY.HeavenLion = {
	special = 2.2,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 4)
		local stride = t * TAU * 0.9
		local gather = env(k, 0, 0.2, 0.27, 0.36)
		local roar = env(k, 0.27, 0.36, 0.72, 0.95)
		local bob = still * (0.05 + 0.03 * breath)
			+ walk * 0.07 * math.abs(math.sin(stride))
			- gather * 0.18
			+ roar * 0.04
		local pitch = still * breath * rad(1.2) + gather * rad(4) - roar * rad(3)
		local roll = walk * math.sin(stride) * rad(3)
		local around = CFrame.new(0, bob, gather * 0.18 - roar * 0.12) * c.about(m.Body, CFrame.Angles(pitch, 0, roll))
		c.turn(m.Body, around, CFrame.identity)
		local shake = roar * math.sin(t * TAU * 11) * rad(5)
		local yaw = (still * lionLook(t) + walk * math.sin(stride) * rad(4)) * (1 - gather) * (1 - roar) + shake
		local headPitch = still * breath * rad(2) - walk * rad(6) + gather * rad(26) - roar * rad(14)
		c.turn(m.Head, around * CFrame.new(0, 0, -roar * 0.3), CFrame.Angles(headPitch, yaw, 0))
		c.turn(
			m.Mane,
			around * CFrame.new(0, still * breath * 0.035, roar * 0.12),
			CFrame.Angles(headPitch * 0.3 + roar * rad(9), yaw * 0.4, 0)
		)
		local flick = still * math.max(0, math.sin(t * TAU / 6)) ^ 8 * rad(25)
		local lash = roar * math.sin(t * TAU * 3) * rad(22)
		c.turn(
			m.Tail,
			around,
			CFrame.Angles(-walk * rad(10) - roar * rad(15), math.sin(t * TAU * 0.35) * rad(14) + flick + lash, 0)
		)
		local swing = walk * math.sin(stride) * rad(16)
		c.turn(m.ArmL, CFrame.identity, CFrame.Angles(swing - gather * rad(4), 0, -roar * rad(6)))
		c.turn(m.ArmR, CFrame.identity, CFrame.Angles(-swing - gather * rad(4), 0, roar * rad(6)))
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(-swing + gather * rad(6), 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(swing + gather * rad(6), 0, 0))
	end,
}

-- Clockwork Titan: a machine that keeps time. Its head sweeps in one-second ticks like a second hand, the chest clock
-- ticks and the gears turn, the fists pump in turn; every few seconds a steam hiss (PetFx beat "hiss") drops the
-- body and sends a shudder through it. It stomps, sinking onto each footfall. Special, overclock (2.4 s, PetFx
-- "vent"): fists up and back leaning while the clock races four turns, then a slam that shakes it.
BY_KEY.ClockworkTitan = {
	special = 2.4,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local tk = tick(t, 1)
		local age = c.beatAge("hiss")
		if age > 4 then
			age = t % 3.2
		end
		local hiss = if age < 0.15 then age / 0.15 else math.max(0, 1 - (age - 0.15) / 1.3)
		local shudder = if age < 0.4 then math.sin(age * TAU * 22) * rad(0.7) * (1 - age / 0.4) else 0
		local up = env(k, 0, 0.3, 0.4, 0.46)
		local slam = env(k, 0.44, 0.48, 0.55, 0.8)
		local shake = if k >= 0.44 and k < 0.75 then math.sin(t * TAU * 18) * rad(1.2) * (1 - (k - 0.44) / 0.31) else 0
		local stride = math.sin(t * TAU / 1.6)
		local plant = (1 - math.abs(stride)) ^ 4
		-- cues for its Overcharged Engine effects: a spark burst at the knee of each stomping foot, exhaust each tick
		local st = c.state
		local side = if stride >= 0 then 1 else -1
		if walk > 0.5 and st.side and side ~= st.side then
			c.cue(if side > 0 then "stepL" else "stepR")
		end
		st.side = side
		local whole = math.floor(tk)
		if st.tick and whole ~= st.tick then
			c.cue("tick")
		end
		st.tick = whole
		local stiff = math.sign(stride) * math.abs(stride) ^ 0.6
		local bob = -still * hiss * 0.07 - walk * plant * 0.12 - slam * 0.22 + up * 0.05
		local around = CFrame.new(0, bob, 0)
			* c.about(m.Body, CFrame.Angles(up * rad(6) + shudder + shake, 0, walk * stride * rad(3.5)))
		c.turn(m.Body, around, CFrame.identity)
		local sweep = tk % 12
		local gaze = if sweep < 6 then sweep else 12 - sweep
		c.turn(m.Head, around, CFrame.Angles(up * rad(10), still * (gaze - 3) * rad(5), 0))
		local beat = tk - math.floor(tk)
		local pump = if math.floor(tk) % 2 == 0 then beat else 1 - beat
		local armSwing = walk * stiff * rad(9)
		c.turn(m.ArmL, around, CFrame.Angles(still * pump * rad(3) - armSwing + up * rad(75), 0, -up * rad(8)))
		c.turn(m.ArmR, around, CFrame.Angles(still * (1 - pump) * rad(3) + armSwing + up * rad(75), 0, up * rad(8)))
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(walk * stiff * rad(12), 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(-walk * stiff * rad(12), 0, 0))
		-- four whole turns, so the hands are back where they were when the overclock ends
		local race = if k >= 0 then ease(k / 0.46) * TAU * 4 else 0
		c.turn(m.HeartHands, around, CFrame.Angles(0, 0, tk * rad(6) + race))
		for i = 1, 7 do
			local dir = if i % 2 == 0 then 1 else -1
			c.turn(m["Gear" .. i], around, CFrame.Angles(0, 0, dir * (t * rad(28 + 4 * i) + race * 0.5)))
		end
	end,
}

-- Prism Seraph: a serene floating angel. It drifts on a slow figure eight, beats its crystal wings with a pause at
-- the top of each stroke and tilts its head; roaming, it glides forward with wings swept back and arms trailing.
-- Special, bless (2.6 s, PetFx "bless"): wings spread wide, arms open, it rises and turns once round in the air;
-- PetFx fires the prism ring as it settles.
BY_KEY.PrismSeraph = {
	special = 2.6,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local w = t * TAU
		local spread = env(k, 0, 0.18, 0.78, 0.97)
		local twirl = if k >= 0 then ease((k - 0.18) / 0.55) * TAU else 0
		local drift = CFrame.new(still * math.sin(w / 8) * 0.35, math.sin(w / 4) * 0.22 + spread * 0.6 + walk * 0.1, 0)
		local pitch = -walk * rad(12) + spread * rad(4)
		local roll = still * math.cos(w / 8) * rad(4) + walk * math.sin(w / 3) * rad(5)
		local around = drift * c.about(m.Body, CFrame.Angles(0, twirl, 0) * CFrame.Angles(pitch, 0, roll))
		c.turn(m.Body, around, CFrame.identity)
		c.turn(
			m.Head,
			around,
			CFrame.Angles(
				spread * rad(15) + math.sin(w * 0.2) * rad(3),
				still * math.sin(w * 0.1) * rad(10),
				math.sin(w * 0.12) * rad(5)
			)
		)
		local u = (t * (0.5 + walk * 0.25)) % 1
		local stroke = if u < 0.3 then 1 - ease(u / 0.3) else ease((u - 0.3) / 0.7)
		local raise = rad(8) + stroke * rad(18 + walk * 8) + spread * rad(38)
		local sweep = walk * rad(22)
		c.turn(m.WingL, around, CFrame.Angles(0, sweep, -raise))
		c.turn(m.WingR, around, CFrame.Angles(0, -sweep, raise))
		local trail = -walk * rad(20) + spread * rad(25)
		c.turn(m.ArmL, around, CFrame.Angles(math.sin(w * 0.3) * rad(4) + trail, 0, -spread * rad(40)))
		c.turn(m.ArmR, around, CFrame.Angles(math.sin(w * 0.3 + 1) * rad(4) + trail, 0, spread * rad(40)))
	end,
}

function Profiles.get(key: string): Profile?
	return BY_KEY[key]
end

return Profiles
