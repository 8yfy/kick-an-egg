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

-- ---- Zone 1 Meadow ---------------------------------------------------------------------------------------------
-- Swing / lift a side-hung leg (insect legs, roots) in the ground frame: `fwd` swings the foot forward, `up` lifts
-- it, for a leg on the left (sx = -1) or the right (sx = 1).
local function sideLeg(sx: number, fwd: number, up: number): CFrame
	return CFrame.Angles(0, sx * fwd, sx * up)
end

-- Piproot: a cheerful frog. It breathes with a fluttering throat and looks about; roaming, it hops: a crouch, a kick
-- of the hind legs, an arc through the air with the forelegs reaching, a soft landing (Anim cue "land"). Special,
-- First Croak (2 s, PetFx "croak"): it draws itself up, the throat sac swells, the jaw drops and it croaks in pulses.
BY_KEY.Piproot = {
	special = 2.0,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 2.6)
		local flutter = math.sin(t * TAU * 2.2) * 0.5 + 0.5
		local u = (t / 0.95) % 1
		local crouch = if u < 0.22 then ease(u / 0.22) elseif u < 0.32 then 1 - ease((u - 0.22) / 0.1) else 0
		local air = if u >= 0.32 and u < 0.78 then (u - 0.32) / 0.46 else -1
		local arc = if air >= 0 then 4 * air * (1 - air) else 0
		local land = if u >= 0.78 then math.sin((u - 0.78) / 0.22 * math.pi) else 0
		local kick = if u >= 0.22 and u < 0.32 then ease((u - 0.22) / 0.1) elseif air >= 0 then 1 - ease(air) else 0
		local st = c.state
		local down = u >= 0.78
		if walk > 0.5 and down and not st.down then
			c.cue("land")
		end
		st.down = down
		local inhale = env(k, 0, 0.2, 0.3, 0.42)
		local croak = env(k, 0.28, 0.36, 0.62, 0.86)
		local pulse = croak * (0.5 + 0.5 * math.sin(t * TAU * 6))
		local hop = walk * (arc * 0.9 - crouch * 0.18 - land * 0.1)
		local bob = still * 0.03 * breath + hop + inhale * 0.12
		local pitch = walk * (if air >= 0 then (0.5 - air) * rad(18) else -crouch * rad(5))
			+ inhale * rad(6)
			+ croak * rad(3)
		local around = CFrame.new(0, bob, 0) * c.about(m.Body, CFrame.Angles(pitch, 0, 0))
		c.turn(m.Body, around, CFrame.identity)
		local headRot = CFrame.Angles(
			still * breath * rad(2) + inhale * rad(10) + croak * rad(12),
			still * math.sin(t * 0.5) * rad(9) * (1 - croak),
			0
		)
		c.turn(m.Head, around, headRot)
		c.turn(m.Jaw, around * c.about(m.Head, headRot), CFrame.Angles(-croak * rad(16) - pulse * rad(6), 0, 0))
		local swell = still * flutter * 0.04 + croak * 0.28 + pulse * 0.1
		c.turn(m.Throat, around * CFrame.new(0, -swell * 0.4, -swell), CFrame.identity)
		local feet = CFrame.new(0, hop, 0)
		local reach = walk * (if air >= 0 then math.sin(air * math.pi) else 0)
		c.turn(m.ArmL, feet, CFrame.Angles(reach * rad(40) - walk * crouch * rad(10), 0, 0))
		c.turn(m.ArmR, feet, CFrame.Angles(reach * rad(40) - walk * crouch * rad(10), 0, 0))
		c.turn(m.LegL, feet, CFrame.Angles(-walk * kick * rad(55) + walk * crouch * rad(8), 0, 0))
		c.turn(m.LegR, feet, CFrame.Angles(-walk * kick * rad(55) + walk * crouch * rad(8), 0, 0))
	end,
}

-- Honeyback Beetle: its antennae sweep and twitch, the dome halves breathe, the wings tremble; roaming, it walks on
-- alternating tripods (L1 R2 L3, then R1 L2 R3). Special, Honeywing Lift (2.6 s, PetFx "lift"): the dome halves part,
-- the amber wings buzz and it rises into a short hover before settling.
BY_KEY.HoneybackBeetle = {
	special = 2.6,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local open = env(k, 0, 0.15, 0.8, 0.95)
		local lift = env(k, 0.12, 0.35, 0.7, 0.92)
		local ph = t * TAU * 1.9
		local hover = lift * (1.1 + 0.08 * math.sin(t * TAU * 1.5))
		local bob = still * 0.02 * math.sin(t * TAU / 2.2) + walk * 0.04 * math.abs(math.sin(ph)) + hover
		local around = CFrame.new(0, bob, 0)
			* c.about(m.Body, CFrame.Angles(-lift * rad(6), 0, walk * math.sin(ph) * rad(2)))
		c.turn(m.Body, around, CFrame.identity)
		local headRot = CFrame.Angles(
			still * math.sin(t * 0.7) * rad(3),
			still * math.sin(t * 0.45) * rad(8) + walk * math.sin(ph) * rad(3),
			0
		)
		c.turn(m.Head, around, headRot)
		local headAround = around * c.about(m.Head, headRot)
		local twL = math.max(0, math.sin(t * TAU / 3.1)) ^ 12
		local twR = math.max(0, math.sin(t * TAU / 2.7 + 1)) ^ 12
		c.turn(
			m.AntennaL,
			headAround,
			CFrame.Angles(math.sin(t * 1.3) * rad(10) + twL * rad(18) - lift * rad(15), math.sin(t * 0.9) * rad(8), 0)
		)
		c.turn(
			m.AntennaR,
			headAround,
			CFrame.Angles(
				math.sin(t * 1.1 + 2) * rad(10) + twR * rad(18) - lift * rad(15),
				-math.sin(t * 0.8 + 1) * rad(8),
				0
			)
		)
		local breathe = still * (math.sin(t * TAU / 3) * 0.5 + 0.5) * rad(2)
		c.turn(m.ShellL, around, CFrame.Angles(open * rad(10), 0, -(breathe + open * rad(55))))
		c.turn(m.ShellR, around, CFrame.Angles(open * rad(10), 0, breathe + open * rad(55)))
		local rest = still * math.sin(t * TAU * 0.6) * rad(4) + walk * math.sin(t * TAU * 2) * rad(5)
		local flap = (1 - open) * rest + open * (rad(20) + math.sin(t * TAU * 14) * rad(22))
		c.turn(m.WingL, around, CFrame.Angles(0, 0, -flap))
		c.turn(m.WingR, around, CFrame.Angles(0, 0, flap))
		local legs = CFrame.new(0, hover, 0)
		for i = 1, 3 do
			for _, sd in { "L", "R" } do
				local sx = if sd == "L" then -1 else 1
				local tripodA = (sd == "L") == (i % 2 == 1)
				local p = ph + (if tripodA then 0 else math.pi)
				local shuffle = still * (math.max(0, math.sin(t * TAU / 4.1 + i * 1.7 + sx)) ^ 16) * rad(6)
				local fwd = walk * math.sin(p) * rad(18)
				local up = walk * math.max(0, math.cos(p)) * rad(14) + shuffle - lift * rad(14)
				c.turn(m[`Leg{sd}{i}`], legs, sideLeg(sx, fwd, up))
			end
		end
	end,
}

-- Crownstag: a graceful stag. It breathes, turns its head slowly and holds each look, flicks its tail; roaming, it
-- walks on diagonal pairs with a nodding head. Special, Antler Bloom (2.4 s, PetFx "bloom"): it rises proudly on its
-- hind legs, head high, while the blossoms burst along its antlers, then settles.
local STAG_LOOKS = { 0, rad(18), rad(4), rad(-15) }
local function stagLook(t: number): number
	local u = t / 4.2
	local n = math.floor(u)
	local a, b = STAG_LOOKS[n % 4 + 1], STAG_LOOKS[(n + 1) % 4 + 1]
	return a + (b - a) * ease((u - n) / 0.4)
end

BY_KEY.Crownstag = {
	special = 2.4,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 3.6)
		local stride = t * TAU * 1.1
		local rear = env(k, 0, 0.22, 0.6, 0.85)
		local bloom = env(k, 0.18, 0.3, 0.75, 0.95)
		local st = c.state
		local side = if math.sin(stride) >= 0 then 1 else -1
		if walk > 0.5 and st.side and side ~= st.side then
			c.cue(if side > 0 then "stepL" else "stepR") -- hoof sparkles
		end
		st.side = side
		local bob = still * 0.03 * breath + walk * 0.06 * math.abs(math.sin(stride))
		local around = CFrame.new(0, bob, 0)
			* c.about(
				m.LegL or m.Body,
				CFrame.Angles(still * breath * rad(1) + rear * rad(14), 0, walk * math.sin(stride) * rad(2))
			)
		c.turn(m.Body, around, CFrame.identity)
		local look = still * stagLook(t) * (1 - rear)
		local neckRot =
			CFrame.Angles(still * breath * rad(2) + walk * math.sin(stride * 2) * rad(3) + rear * rad(6), look * 0.4, 0)
		c.turn(m.Neck, around, neckRot)
		local flick = still * (math.max(0, math.sin(t * TAU / 5.3)) ^ 24) * math.sin(t * TAU * 8) * rad(3)
		c.turn(
			m.Head,
			around * c.about(m.Neck, neckRot),
			CFrame.Angles(-walk * math.sin(stride * 2) * rad(4) + bloom * rad(10), look * 0.6, flick)
		)
		local up = math.max(0, math.sin(t * TAU / 4.7)) ^ 10
		c.turn(m.Tail, around, CFrame.Angles(up * rad(18) + walk * rad(8), math.sin(t * TAU * 0.5) * rad(8), 0))
		local swing = walk * math.sin(stride) * rad(22)
		local front = CFrame.identity:Lerp(around, rear)
		c.turn(m.ArmL, front, CFrame.Angles(swing + rear * rad(40), 0, 0))
		c.turn(m.ArmR, front, CFrame.Angles(-swing + rear * rad(32), 0, 0))
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(-swing * 0.9, 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(swing * 0.9, 0, 0))
	end,
}

-- Thistleback Hedgehog: its nose twitches in sniffs and the leaf-and-thorn coat rustles; roaming, it scurries low and
-- fast (Anim cue "step"). Special, Thistle Guard (2.2 s, PetFx "guard"): it crouches and tucks its head, the coat
-- bristles up and pulses out a burst of thorns, then it relaxes.
BY_KEY.ThistlebackHedgehog = {
	special = 2.2,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 2.4)
		local scurry = t * TAU * 3.2
		local guard = env(k, 0, 0.15, 0.7, 0.9)
		local pulse = env(k, 0.35, 0.42, 0.5, 0.65)
		local st = c.state
		local side = if math.sin(scurry) >= 0 then 1 else -1
		if walk > 0.5 and st.side and side ~= st.side then
			c.cue("step")
		end
		st.side = side
		local bob = still * 0.02 * breath + walk * 0.04 * math.abs(math.sin(scurry)) - guard * 0.25
		local around = CFrame.new(0, bob, 0)
			* c.about(m.Body, CFrame.Angles(-guard * rad(6) - walk * rad(3), 0, walk * math.sin(scurry) * rad(2)))
		c.turn(m.Body, around, CFrame.identity)
		local shiver = (math.max(0, math.sin(t * TAU / 3.3)) ^ 16) * math.sin(t * TAU * 14) * rad(2.5)
		local rustle = still * (math.sin(t * TAU * 0.4) * rad(1) + shiver) + walk * math.sin(scurry * 2) * rad(1.5)
		c.turn(
			m.Quills,
			around * CFrame.new(0, guard * 0.18 + pulse * 0.12, 0),
			CFrame.Angles(-guard * rad(8) + rustle, 0, rustle * 0.6 + pulse * math.sin(t * TAU * 20) * rad(2))
		)
		local sniff = (math.max(0, math.sin(t * TAU / 2.4)) ^ 10) * math.sin(t * TAU * 9) * rad(4)
		c.turn(
			m.Head,
			around,
			CFrame.Angles(
				still * sniff - guard * rad(14) + walk * math.sin(scurry * 2) * rad(2),
				still * math.sin(t * 0.6) * rad(12) * (1 - guard),
				0
			)
		)
		local swing = walk * math.sin(scurry) * rad(26)
		c.turn(m.ArmL, CFrame.identity, CFrame.Angles(swing, 0, 0))
		c.turn(m.ArmR, CFrame.identity, CFrame.Angles(-swing, 0, 0))
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(-swing, 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(swing, 0, 0))
	end,
}

-- Bloomcrest Crane: its long neck sways in a slow S, it blinks and resettles its wings; roaming, it takes long slow
-- strides with the bird's head-bob. Special, Bloomwing Display (2.8 s, PetFx "display"): it lifts its head, spreads
-- both wings in a symmetrical fan and fans its tail, holds the pose, then folds.
BY_KEY.BloomcrestCrane = {
	special = 2.8,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 3.8)
		local stride = t * TAU * 0.75
		local display = env(k, 0, 0.25, 0.75, 0.95)
		local bob = still * 0.03 * breath + walk * 0.05 * math.abs(math.sin(stride)) + display * 0.1
		local around = CFrame.new(0, bob, 0)
			* c.about(
				m.Body,
				CFrame.Angles(still * breath * rad(1) + display * rad(6), 0, walk * math.sin(stride) * rad(2))
			)
		c.turn(m.Body, around, CFrame.identity)
		local thrust = walk * (math.sin(stride * 2) * 0.5 + 0.5)
		local sway = math.sin(t * TAU / 4.5)
		local neckRot = CFrame.Angles(
			still * sway * rad(4) - thrust * rad(10) + display * rad(8),
			still * math.sin(t * TAU / 7) * rad(10),
			0
		)
		c.turn(m.Neck, around, neckRot)
		c.turn(
			m.Head,
			around * c.about(m.Neck, neckRot),
			CFrame.Angles(
				-still * sway * rad(5) + thrust * rad(10) + display * rad(10),
				still * math.sin(t * TAU / 5) * rad(8),
				still * math.sin(t * TAU / 6) * rad(4)
			)
		)
		local settle = still * (math.max(0, math.sin(t * TAU / 5.5)) ^ 14) * rad(10)
		local spread = display * rad(50) + walk * math.sin(stride) * rad(3)
		c.turn(m.WingL, around, CFrame.Angles(0, -display * rad(10), settle + spread))
		c.turn(m.WingR, around, CFrame.Angles(0, display * rad(10), -settle - spread))
		c.turn(
			m.Tail,
			around,
			CFrame.Angles(display * rad(25) + still * breath * rad(2), math.sin(t * TAU * 0.3) * rad(4), 0)
		)
		local swing = walk * math.sin(stride) * rad(24)
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(swing, 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(-swing, 0, 0))
	end,
}

-- The Burrow Monarch: a massive digger. It breathes heavily, sniffs in bursts, flexes its claws and twitches its ears;
-- its floating rocks circle and bob. It walks heavily, sinking onto each footfall (Anim cues "stepL" / "stepR").
-- Special, Royal Excavation (2.6 s, PetFx "dig"): it rears up, slams both claws into the ground, then digs with
-- alternating scoops, ears flattened, while the rocks race round it.
BY_KEY.BurrowMonarch = {
	special = 2.6,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 4.2)
		local stride = t * TAU * 0.7
		local plant = (1 - math.abs(math.sin(stride))) ^ 4
		local rear = env(k, 0, 0.22, 0.32, 0.42)
		local slam = env(k, 0.38, 0.44, 0.52, 0.62)
		local dig = env(k, 0.48, 0.55, 0.85, 0.98)
		local st = c.state
		local side = if math.sin(stride) >= 0 then 1 else -1
		if walk > 0.5 and st.side and side ~= st.side then
			c.cue(if side > 0 then "stepL" else "stepR")
		end
		st.side = side
		local bob = still * 0.06 * breath - walk * plant * 0.1 + rear * 0.35 - slam * 0.15 - dig * 0.1
		local around = CFrame.new(0, bob, 0)
			* c.about(
				m.LegL or m.Body,
				CFrame.Angles(
					still * breath * rad(1.5) + rear * rad(22) - slam * rad(6) - dig * rad(4),
					0,
					walk * math.sin(stride) * rad(3)
				)
			)
		c.turn(m.Body, around, CFrame.identity)
		local sniff = (math.max(0, math.sin(t * TAU / 3)) ^ 12) * math.sin(t * TAU * 7) * rad(4)
		local headRot = CFrame.Angles(
			still * sniff + rear * rad(10) - dig * rad(10) - walk * rad(3),
			still * math.sin(t * 0.4) * rad(12),
			0
		)
		c.turn(m.Head, around, headRot)
		local ears = around * c.about(m.Head, headRot)
		local twL = (math.max(0, math.sin(t * TAU / 4.4)) ^ 20) * rad(15)
		local twR = (math.max(0, math.sin(t * TAU / 3.9 + 2)) ^ 20) * rad(15)
		c.turn(m.EarL, ears, CFrame.Angles(-dig * rad(35) - rear * rad(10), 0, -twL))
		c.turn(m.EarR, ears, CFrame.Angles(-dig * rad(35) - rear * rad(10), 0, twR))
		local flex = still * math.sin(t * TAU / 2.5) * rad(3)
		local swing = walk * math.sin(stride) * rad(16)
		local scoop = dig * math.sin(t * TAU * 3) * rad(25)
		local front = CFrame.identity:Lerp(around, rear)
		c.turn(m.ArmL, front, CFrame.Angles(swing + flex + rear * rad(50) - slam * rad(20) + scoop, 0, 0))
		c.turn(m.ArmR, front, CFrame.Angles(-swing + flex + rear * rad(50) - slam * rad(20) - scoop, 0, 0))
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(-swing * 0.8, 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(swing * 0.8, 0, 0))
		c.turn(m.Tail, around, CFrame.Angles(0, math.sin(t * TAU * 0.5) * rad(8), 0))
		local race = if k >= 0 then ease(k) * TAU else 0
		c.turn(
			m.Rocks,
			CFrame.new(0, math.sin(t * TAU / 3) * 0.15 + rear * 0.4, 0),
			CFrame.Angles(0, t * rad(20) + race, 0)
		)
	end,
}

-- The Walking Orchard: an ancient tree-stag. Its canopy antlers sway on their own slow rhythms, it breathes and looks
-- about slowly; it walks with heavy, majestic steps (Anim cues "stepL" / "stepR"). Special, Orchard Awakening (3 s,
-- PetFx "awaken"): it draws itself up, head high, the antler canopies lift and spread while the orchard glows, then
-- settles.
BY_KEY.WalkingOrchard = {
	special = 3.0,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 5)
		local stride = t * TAU * 0.55
		local plant = (1 - math.abs(math.sin(stride))) ^ 4
		local wake = env(k, 0, 0.25, 0.75, 0.95)
		local st = c.state
		local side = if math.sin(stride) >= 0 then 1 else -1
		if walk > 0.5 and st.side and side ~= st.side then
			c.cue(if side > 0 then "stepL" else "stepR")
		end
		st.side = side
		local bob = still * 0.04 * breath - walk * plant * 0.08 + wake * 0.25
		local around = CFrame.new(0, bob, 0)
			* c.about(
				m.Body,
				CFrame.Angles(still * breath * rad(0.8) + wake * rad(4), 0, walk * math.sin(stride) * rad(2))
			)
		c.turn(m.Body, around, CFrame.identity)
		local neckRot = CFrame.Angles(still * breath * rad(1.5) + wake * rad(8), still * math.sin(t * 0.3) * rad(6), 0)
		c.turn(m.Neck, around, neckRot)
		local headAround = around * c.about(m.Neck, neckRot)
		local headRot = CFrame.Angles(
			walk * math.sin(stride * 2) * rad(2) + wake * rad(10),
			still * math.sin(t * 0.3 + 0.5) * rad(10),
			0
		)
		c.turn(m.Head, headAround, headRot)
		local antlers = headAround * c.about(m.Head, headRot)
		local swayL = math.sin(t * TAU / 4.4) * rad(3) + walk * math.sin(stride) * rad(3)
		local swayR = math.sin(t * TAU / 4.9 + 1.3) * rad(3) - walk * math.sin(stride) * rad(3)
		c.turn(
			m.AntlerL,
			antlers,
			CFrame.Angles(math.sin(t * TAU / 5.3) * rad(2) + wake * rad(6), 0, swayL - wake * rad(8))
		)
		c.turn(
			m.AntlerR,
			antlers,
			CFrame.Angles(math.sin(t * TAU / 5.7 + 2) * rad(2) + wake * rad(6), 0, swayR + wake * rad(8))
		)
		c.turn(m.Tail, around, CFrame.Angles(0, math.sin(t * TAU * 0.25) * rad(6), 0))
		local swing = walk * math.sin(stride) * rad(16)
		c.turn(m.ArmL, CFrame.identity, CFrame.Angles(swing, 0, 0))
		c.turn(m.ArmR, CFrame.identity, CFrame.Angles(-swing, 0, 0))
		c.turn(m.LegL, CFrame.identity, CFrame.Angles(-swing * 0.9, 0, 0))
		c.turn(m.LegR, CFrame.identity, CFrame.Angles(swing * 0.9, 0, 0))
	end,
}

-- The First Seed: the primordial guardian. Its shell plates breathe, the seed core rocks gently, every root stirs on
-- its own rhythm and the halo turns; roaming, its six roots step in a rolling wave. Special, Genesis Unfolding
-- (3.2 s, PetFx "genesis"): the plates open wide, the roots lift and spread, the core flares (PetFx burst) and the
-- halo races one turn, then everything closes again.
local SEED_ROOTS = {
	{ "ArmL", -1, 0 },
	{ "LegR", 1, 1 / 6 },
	{ "RootR", 1, 1 / 3 },
	{ "ArmR", 1, 1 / 2 },
	{ "LegL", -1, 2 / 3 },
	{ "RootL", -1, 5 / 6 },
}

BY_KEY.FirstSeed = {
	special = 3.2,
	pose = function(c: Ctx)
		local t, m, walk, k = c.t, c.m, c.walk, c.k
		local still = 1 - walk
		local breath = math.sin(t * TAU / 4)
		local open = env(k, 0.05, 0.22, 0.75, 0.92)
		local reach = env(k, 0.2, 0.38, 0.7, 0.88)
		local flare = env(k, 0.35, 0.42, 0.62, 0.8)
		local bob = still * 0.05 * breath + walk * 0.05 * math.sin(t * TAU * 1.2) + reach * 0.3
		local around = CFrame.new(0, bob, 0)
			* c.about(
				m.Body,
				CFrame.Angles(still * breath * rad(1) - walk * rad(3), 0, walk * math.sin(t * TAU * 0.6) * rad(2))
			)
		c.turn(m.Body, around, CFrame.identity)
		c.turn(
			m.Core,
			around * CFrame.new(0, 0, -0.04 * (0.5 + 0.5 * math.sin(t * TAU / 2)) - flare * 0.15),
			CFrame.Angles(0, 0, math.sin(t * TAU / 6) * rad(4))
		)
		c.turn(
			m.Head,
			around,
			CFrame.Angles(still * breath * rad(2) + reach * rad(12), still * math.sin(t * 0.35) * rad(10), 0)
		)
		local race = if k >= 0 then ease((k - 0.3) / 0.45) * TAU else 0
		c.turn(m.HaloRing, around, CFrame.Angles(0, 0, t * rad(12) + race))
		local plates = still * (breath * 0.5 + 0.5) * rad(3) + open * rad(35)
		c.turn(m.PlateL, around, CFrame.Angles(0, 0, -plates))
		c.turn(m.PlateR, around, CFrame.Angles(0, 0, plates))
		local wave = t * TAU * 0.9
		for _, r in SEED_ROOTS do
			local name, sx, off = r[1], r[2], r[3]
			local p = wave - off * TAU
			local stir = still * math.sin(t * TAU / (3.1 + off * 2) + off * 9) * rad(3)
			local fwd = walk * math.sin(p) * rad(12)
			local up = walk * math.max(0, math.cos(p)) * rad(10) + stir + reach * rad(18)
			c.turn(m[name], CFrame.identity, sideLeg(sx, fwd, up))
		end
	end,
}

function Profiles.get(key: string): Profile?
	return BY_KEY[key]
end

return Profiles
