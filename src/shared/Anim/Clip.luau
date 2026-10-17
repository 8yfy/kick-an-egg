--!strict
-- Partner A. Character clips as data, sampled with smooth curves (the Graph Editor of this game).
--
-- A clip is a list of keys; each key sets some channels at a time t (seconds):
--   joints  Root Waist Neck RShoulder RElbow RWrist LShoulder LElbow LWrist RHip RKnee RAnkle LHip LKnee LAnkle
--           = { pitch, yaw, roll (degrees), x, y, z (studs) } in the parent part's frame, about the joint
--           (+pitch swings a hanging limb forward and leans the torso back; R15 elbows bend with +pitch,
--           knees with -pitch). Translation is used on Root only (weight shift, crouch).
--   feet    RFoot LFoot = { plant 0..1, dx, dy, dz (studs from the rest stance, character space), yaw, pitch }:
--           plant 1 pins the ankle to that spot with the foot flat (leg IK, Anim/Body), 0 leaves the leg to
--           its joint keys. Animating dx/dz with plant 1 is a clean planted step with no sliding.
--   hands   RHand LHand = { reach 0..1 }: how much the arm follows the hand target the code supplies.
--   props   Egg = { pitch, yaw, roll, x, y, z }: a held prop's offset from its hold frame (the code that owns the
--           prop reads it through Mixer handle.stepped).
-- A channel only has keys where a key sets it (like F-curves); between keys it follows a monotone cubic
-- (Fritsch-Butland): smooth acceleration and deceleration, never overshooting a key, flat at every turn-around,
-- and the full speed carried THROUGH keys that are just passing points. Key options:
--   ease = "hold"    every channel set at that key comes to rest there (a settle, a held beat)
--   ease = "impact"  arrive at full speed and leave slower (the strike: fast into contact, mass after it)
-- overlap = { Neck = 0.05, ... } drags a channel's inner keys later (follow-through and overlapping action);
-- markers = { Contact = 0.62, ... } are the clip's events (Anim/Mixer fires them; bake() writes them too).
-- Loops (loop = true) wrap: the curve is periodic, so the seam has no hitch.
local Clip = {}

export type Value = { number }
export type Pose = { [string]: Value }
export type Key = { t: number, pose: Pose, ease: string? }
export type Def = {
	name: string,
	length: number,
	loop: boolean?,
	keys: { Key },
	overlap: { [string]: number }?,
	markers: { [string]: number }?,
}
type Channel = {
	times: { number },
	values: { Value },
	slopeIn: { Value },
	slopeOut: { Value },
	n: number,
	width: number,
	last: number, -- cached segment for the next sample
}
export type Compiled = {
	name: string,
	length: number,
	loop: boolean,
	channels: { [string]: Channel },
	order: { string },
	markers: { { name: string, t: number } },
	overlap: { [string]: number }, -- loops drag channels at sample time (one-shots bake it into their keys)
}

Clip.JOINTS = {
	"Root",
	"Waist",
	"Neck",
	"RShoulder",
	"RElbow",
	"RWrist",
	"LShoulder",
	"LElbow",
	"LWrist",
	"RHip",
	"RKnee",
	"RAnkle",
	"LHip",
	"LKnee",
	"LAnkle",
}
Clip.LIMBS = { "RFoot", "LFoot", "RHand", "LHand" }
Clip.PROPS = { "Egg" }
local WIDTH = { RFoot = 6, LFoot = 6, RHand = 1, LHand = 1 }

-- Fritsch-Butland: a weighted harmonic mean of the neighbouring secants (0 at a turn-around).
local function slope(d0: number, d1: number, h0: number, h1: number): number
	if d0 * d1 <= 0 then
		return 0
	end
	local w0, w1 = 2 * h1 + h0, h1 + 2 * h0
	return (w0 + w1) / (w0 / d0 + w1 / d1)
end

local function compileChannel(def: Def, name: string): Channel?
	local width = WIDTH[name] or 6
	local times: { number }, values: { Value }, eases: { string? } = {}, {}, {}
	for _, key in def.keys do
		local v = key.pose[name]
		if v then
			local full = table.create(width, 0)
			for i = 1, width do
				full[i] = v[i] or 0
			end
			table.insert(times, key.t)
			table.insert(values, full)
			table.insert(eases, key.ease)
		end
	end
	local n = #times
	if n == 0 then
		return nil
	end
	-- overlap: inner keys of one-shots shift later (loops shift at sample time instead)
	local drag = def.overlap and def.overlap[name] or 0
	if drag ~= 0 and not def.loop and n > 2 then
		local room = def.length - times[n - 1]
		for i = 2, n - 1 do
			times[i] = math.min(times[i] + drag, times[i] + room * 0.8)
		end
	end
	local loop = def.loop == true
	if loop and times[n] < def.length then -- close the loop with the first key one period later
		table.insert(times, times[1] + def.length)
		table.insert(values, table.clone(values[1]))
		table.insert(eases, eases[1])
		n += 1
	end
	local slopeIn, slopeOut = {}, {}
	for i = 1, n do
		local sIn, sOut = table.create(width, 0), table.create(width, 0)
		for c = 1, width do
			local d0, d1, h0, h1
			if i > 1 then
				h0 = times[i] - times[i - 1]
				d0 = (values[i][c] - values[i - 1][c]) / h0
			end
			if i < n then
				h1 = times[i + 1] - times[i]
				d1 = (values[i + 1][c] - values[i][c]) / h1
			end
			if loop and (i == 1 or i == n) and n > 2 then -- periodic: the seam sees both neighbours
				local a, b = values[n - 1][c], values[2][c]
				local ha, hb = times[n] - times[n - 1], times[2] - times[1]
				d0, d1, h0, h1 = (values[1][c] - a) / ha, (b - values[1][c]) / hb, ha, hb
			end
			local m = if d0 and d1 then slope(d0, d1, h0, h1) else 0 -- one-shot ends start and stop at rest
			sIn[c], sOut[c] = m, m
			local ease = eases[i]
			if ease == "hold" then
				sIn[c], sOut[c] = 0, 0
			elseif ease == "impact" and d0 and d1 then
				sIn[c] = if d0 * d1 > 0 or d1 == 0 then d0 * 1.45 else d0 * 1.2 -- into the hit at full speed
				sOut[c] = d1 * 0.55 -- the mass of the follow-through
			end
		end
		slopeIn[i], slopeOut[i] = sIn, sOut
	end
	return {
		times = times,
		values = values,
		slopeIn = slopeIn,
		slopeOut = slopeOut,
		n = n,
		width = width,
		last = 1,
	}
end

function Clip.compile(def: Def): Compiled
	local channels, order = {}, {}
	for _, name in Clip.JOINTS do
		local ch = compileChannel(def, name)
		if ch then
			channels[name] = ch
			table.insert(order, name)
		end
	end
	for _, list in { Clip.LIMBS, Clip.PROPS } do
		for _, name in list do
			local ch = compileChannel(def, name)
			if ch then
				channels[name] = ch
				table.insert(order, name)
			end
		end
	end
	local markers = {}
	for name, t in def.markers or {} do
		table.insert(markers, { name = name, t = t })
	end
	table.sort(markers, function(a, b)
		return a.t < b.t
	end)
	return {
		name = def.name,
		length = def.length,
		loop = def.loop == true,
		channels = channels,
		order = order,
		markers = markers,
		overlap = if def.loop then def.overlap or {} else {},
	}
end

-- Value of one channel at time t (into `out`, reused).
function Clip.channel(clip: Compiled, ch: Channel, t: number, drag: number, out: Value): Value
	local times = ch.times
	if clip.loop then
		t = (t - drag) % clip.length
		if t < times[1] then
			t += clip.length
		end
	end
	local n = ch.n
	if n == 1 or t <= times[1] then
		local v = ch.values[1]
		for c = 1, ch.width do
			out[c] = v[c]
		end
		return out
	elseif t >= times[n] then
		local v = ch.values[n]
		for c = 1, ch.width do
			out[c] = v[c]
		end
		return out
	end
	local i = ch.last
	if i >= n or times[i] > t then
		i = 1
	end
	while times[i + 1] < t do
		i += 1
	end
	ch.last = i
	local t0, t1 = times[i], times[i + 1]
	local h = t1 - t0
	local s = (t - t0) / h
	local s2, s3 = s * s, s * s * s
	local h00, h10, h01, h11 = 2 * s3 - 3 * s2 + 1, s3 - 2 * s2 + s, -2 * s3 + 3 * s2, s3 - s2
	local v0, v1, m0, m1 = ch.values[i], ch.values[i + 1], ch.slopeOut[i], ch.slopeIn[i + 1]
	for c = 1, ch.width do
		out[c] = h00 * v0[c] + h10 * h * m0[c] + h01 * v1[c] + h11 * h * m1[c]
	end
	return out
end

-- The whole pose at time t (fresh tables; for tools and baking, Anim/Mixer reuses its own).
function Clip.sample(clip: Compiled, t: number, overlap: { [string]: number }?): Pose
	local pose = {}
	for name, ch in clip.channels do
		pose[name] = Clip.channel(clip, ch, t, if clip.loop and overlap then overlap[name] or 0 else 0, {})
	end
	return pose
end

-- Joint value -> rotation (and Root translation) in the joint's own frame.
function Clip.cframe(v: Value, scale: number): CFrame
	-- (procedural layers may write just { pitch, yaw, roll }: missing values are 0)
	return CFrame.new((v[4] or 0) * scale, (v[5] or 0) * scale, (v[6] or 0) * scale)
		* CFrame.Angles(math.rad(v[1] or 0), math.rad(v[2] or 0), math.rad(v[3] or 0))
end

return Clip
