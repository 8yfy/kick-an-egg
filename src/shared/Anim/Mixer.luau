--!strict
-- Partner A. Plays Anim/Clip clips on characters, layered ON TOP of each character's own Animator (the default
-- Animate idle / walk / jump keep running underneath and come back through crossfades, never a snap).
--
-- Every playing clip is a layer with a priority, a weight that fades in and out (smoothstep), a speed and named
-- markers (exact-time events, also fired when a late start or a speed-up skips past them). Each frame, in
-- RunService.Stepped (after the Animator, before physics), per character:
--   1. start from the Animator's pose (or the rest pose: Options.rest, for rigs nothing else animates such as
--      merchant NPCs),
--   2. blend the layers in priority order (additive layers multiply on top),
--   3. leg / arm IK for planted feet and placed hands (Anim/Body), measured on this avatar,
--   4. write only the joints a layer touched, then run the layers' step callbacks (props that follow the pose).
-- One Stepped connection for every character; characters with no layers cost nothing. Layers of characters that
-- leave the workspace are dropped. Mixer.pause(character, true) freezes a character (distance LOD).
local RunService = game:GetService("RunService")

local Body = require(script.Parent.Body)
local Clip = require(script.Parent.Clip)

local Mixer = {}

Mixer.PRIORITY = { Core = 0, Idle = 1, Movement = 2, Action = 3, Action2 = 4, Action3 = 5, Action4 = 6 }

-- A hand target: given the UpperTorso's CFrame (root space) and the layer's sampled channels this frame, returns
-- where the wrist goes (root space), the direction the elbow points (optional) and the hand's rotation (optional,
-- root space).
export type HandFn = (upperTorso: CFrame, values: { [string]: Clip.Value }) -> (Vector3, Vector3?, CFrame?)
export type Options = {
	fadeIn: number?, -- seconds to blend in (default 0.2)
	fadeOut: number?, -- one-shots: seconds before the end that they start blending out (default 0.25)
	weight: number?,
	speed: number?,
	priority: number?,
	additive: boolean?,
	start: number?, -- start this many seconds into the clip
	rest: boolean?, -- this character has no Animator pose of its own: layers start from the rest pose
	hands: { [string]: HandFn }?, -- RHand / LHand targets (the clip's RHand / LHand channel is the reach)
	-- a procedural layer: instead of sampling the clip, `source(t, values)` fills the channel values each frame
	-- (head tracking toward a target, fitted poses); `clip.order` lists the channels it writes
	source: ((t: number, values: { [string]: Clip.Value }) -> ())?,
	-- only these channels (joints / limbs) are applied; nil = all (e.g. an upper-body layer over a walk)
	mask: { [string]: boolean }?,
	keep: boolean?, -- stays alive at weight 0 (a dormant layer setWeight brings back) until stop()
}
export type Handle = {
	stop: (fade: number?) -> (),
	setSpeed: (speed: number) -> (),
	setWeight: (weight: number, fade: number?) -> (),
	time: () -> number,
	setTime: (t: number) -> (),
	playing: () -> boolean,
	weight: () -> number,
	on: (marker: string, fn: () -> ()) -> (),
	ended: (fn: () -> ()) -> (),
	-- called every frame after the pose is written: (clip time, sampled channel values, blend weight)
	stepped: (fn: (t: number, values: { [string]: Clip.Value }, weight: number) -> ()) -> (),
}
type Layer = {
	clip: Clip.Compiled,
	t: number,
	speed: number,
	w: number,
	target: number,
	rate: number,
	priority: number,
	seq: number,
	additive: boolean,
	fadeOut: number,
	alive: boolean,
	callbacks: { [string]: { () -> () } },
	onEnded: { () -> () },
	onStep: { (number, { [string]: Clip.Value }, number) -> () },
	hands: { [string]: HandFn }?,
	source: ((number, { [string]: Clip.Value }) -> ())?,
	mask: { [string]: boolean }?,
	keep: boolean,
	values: { [string]: Clip.Value },
}
type State = {
	character: Model,
	body: Body.Body?,
	layers: { Layer },
	rest: boolean,
	paused: boolean,
	rebind: boolean,
	conns: { RBXScriptConnection },
}

local states: { [Model]: State } = {}
local seq = 0
local connection: RBXScriptConnection? = nil

local function smooth(a: number): number
	return a * a * (3 - 2 * a)
end

local function stateOf(character: Model): State
	local s = states[character]
	if s then
		return s
	end
	local st: State = {
		character = character,
		body = nil,
		layers = {},
		rest = false,
		paused = false,
		rebind = true,
		conns = {},
	}
	-- joints arrive late (streaming, avatar loading, rescaling): re-measure the rig when they change
	local function changed(d: Instance)
		if d:IsA("Motor6D") or d:IsA("AnimationConstraint") or d:IsA("Attachment") then
			st.rebind = true
		end
	end
	table.insert(st.conns, character.DescendantAdded:Connect(changed))
	table.insert(st.conns, character.DescendantRemoving:Connect(changed))
	states[character] = st
	return st
end

local function drop(st: State)
	for _, c in st.conns do
		c:Disconnect()
	end
	for _, layer in st.layers do
		layer.alive = false
	end
	states[st.character] = nil
end

local function fire(list: { () -> () }?)
	if list then
		for _, fn in list do
			task.spawn(fn)
		end
	end
end

-- Fires the markers a layer passed between `from` and `to` (clip time; loops wrap).
local function markers(layer: Layer, from: number, to: number)
	local list = layer.clip.markers
	if #list == 0 or to <= from then
		return
	end
	local length = layer.clip.length
	if layer.clip.loop then
		local cycles = math.floor(to / length) - math.floor(from / length)
		local a, b = from % length, to % length
		for _, m in list do
			if if cycles == 0 then (m.t > a and m.t <= b) else (m.t > a or m.t <= b) then
				fire(layer.callbacks[m.name])
			end
		end
	else
		for _, m in list do
			if m.t > from and m.t <= to then
				fire(layer.callbacks[m.name])
			end
		end
	end
end

local function advance(layer: Layer, dt: number)
	local from = layer.t
	layer.t += dt * layer.speed
	markers(layer, from, layer.t)
	local clip = layer.clip
	if not clip.loop and layer.target > 0 and layer.t >= clip.length - layer.fadeOut then
		layer.target = 0 -- one-shot: blend out over its last fadeOut seconds, back to whatever is underneath
		layer.rate = 1 / math.max(layer.fadeOut, 1 / 60)
	end
	if layer.w < layer.target then
		layer.w = math.min(layer.target, layer.w + layer.rate * dt)
	elseif layer.w > layer.target then
		layer.w = math.max(layer.target, layer.w - layer.rate * dt)
	end
end

-- R6 has no knees, elbows or waist: fold them into the joints it has.
local function r6Value(name: string, values: { [string]: Clip.Value }): Clip.Value?
	local v = values[name]
	if not v then
		return nil
	end
	local out = table.clone(v)
	local fold = if name == "Root"
		then values.Waist
		elseif name == "RShoulder" then values.RElbow
		elseif name == "LShoulder" then values.LElbow
		elseif name == "RHip" then values.RKnee
		elseif name == "LHip" then values.LKnee
		else nil
	if fold then
		out[1] += fold[1] * 0.5
		if name == "Root" then
			out[2] += fold[2]
			out[3] += fold[3]
		end
	end
	return out
end

local LIMB_ZERO = { 0, 0, 0, 0, 0, 0 }

-- Blends `layers` (with blend weights `weights`) over `final` (pre-filled with the base pose), then the IK.
-- Sets touched[joint] for every joint it changed.
local function blend(
	body: Body.Body,
	layers: { Layer },
	weights: { number },
	final: { [string]: CFrame },
	touched: { [string]: boolean }
)
	local limbs: { [string]: { number } } = {}
	local handFns: { [string]: Layer } = {}
	for i, layer in layers do
		local w = weights[i]
		if w <= 0 then
			continue
		end
		local clip = layer.clip
		local values = layer.values
		local source = layer.source
		if source then
			source(layer.t, values)
		else
			for _, name in clip.order do
				values[name] = values[name] or {}
				Clip.channel(clip, clip.channels[name], layer.t, clip.overlap[name] or 0, values[name])
			end
		end
		local mask = layer.mask
		for name, j in body.joints do
			local v = if body.r6 then r6Value(name, values) else values[name]
			if v and (not mask or mask[name]) then
				local t = Body.toTransform(j, Clip.cframe(v, body.scale))
				final[name] = if layer.additive
					then final[name] * CFrame.identity:Lerp(t, w)
					else final[name]:Lerp(t, w)
				touched[name] = true
			end
		end
		if not body.r6 then
			for _, limb in Clip.LIMBS do
				local v = if clip.channels[limb] or source then values[limb] else nil
				if v and (not mask or mask[limb]) then
					local acc = limbs[limb] or table.clone(LIMB_ZERO)
					for c = 1, #v do
						acc[c] += (v[c] - acc[c]) * w
					end
					limbs[limb] = acc
					if layer.hands and layer.hands[limb] then
						handFns[limb] = layer
					end
				end
			end
		end
	end
	-- IK: planted feet and placed hands, on the blended pose
	local chain: { [string]: CFrame }? = nil
	local ik: { [string]: CFrame } = {}
	for limb, v in limbs do
		local weight = math.clamp(v[1], 0, 1)
		if weight <= 0.001 or not body.limbs[limb] then
			continue
		end
		chain = chain or Body.fk(body, final)
		table.clear(ik)
		if limb == "RHand" or limb == "LHand" then
			local owner = handFns[limb]
			local waist = body.joints.Waist
			if not owner or not waist or not (chain :: any).Waist then
				continue
			end
			local fn = (owner.hands :: any)[limb] :: HandFn
			local target, hint, rot = fn((chain :: any).Waist * waist.c1:Inverse(), owner.values)
			local side = if limb == "RHand" then 1 else -1
			Body.solve(body, limb, chain :: any, target, hint or Vector3.new(0.7 * side, -0.6, 0.5), rot, ik)
		else
			local turn = CFrame.Angles(0, math.rad(v[5]), 0)
			local side = if limb == "RFoot" then 1 else -1
			local target = body.rest[limb] + Vector3.new(v[2], v[3], v[4]) * body.scale
			local hint = turn * Vector3.new(0.12 * side, 0, -1)
			Body.solve(body, limb, chain :: any, target, hint, turn * CFrame.Angles(math.rad(v[6]), 0, 0), ik)
		end
		for _, name in Body.LIMBS[limb] do
			if ik[name] then
				final[name] = final[name]:Lerp(ik[name], weight)
				touched[name] = true
			end
		end
	end
end

local final: { [string]: CFrame } = {}
local touched: { [string]: boolean } = {}
local weights: { number } = {}

local function compose(st: State, body: Body.Body)
	table.clear(final)
	table.clear(touched)
	table.clear(weights)
	for name, j in body.joints do
		final[name] = if st.rest then CFrame.identity else (j.inst :: any).Transform :: CFrame
	end
	for i, layer in st.layers do
		weights[i] = smooth(math.clamp(layer.w, 0, 1))
	end
	blend(body, st.layers, weights, final, touched)
	for name in touched do
		(body.joints[name].inst :: any).Transform = final[name]
	end
	for i, layer in st.layers do
		for _, fn in layer.onStep do
			fn(layer.t, layer.values, weights[i])
		end
	end
end

local function step(_, dt: number)
	for character, st in states do
		if not character.Parent then
			drop(st)
			continue
		end
		if st.paused then
			continue
		end
		if st.rebind then
			st.rebind = false
			st.body = Body.bind(character)
		end
		for i = #st.layers, 1, -1 do
			local layer = st.layers[i]
			if layer.alive then
				advance(layer, dt)
			end
			if not layer.alive or (layer.target <= 0 and layer.w <= 0 and not layer.keep) then
				layer.alive = false
				table.remove(st.layers, i)
				fire(layer.onEnded)
			end
		end
		local body = st.body
		if body and #st.layers > 0 then
			compose(st, body)
		end
	end
end

local function newLayer(clip: Clip.Compiled, o: Options): Layer
	seq += 1
	local fadeIn = o.fadeIn or 0.2
	return {
		clip = clip,
		t = o.start or 0,
		speed = o.speed or 1,
		w = if fadeIn <= 0 then 1 else 0,
		target = o.weight or 1,
		rate = 1 / math.max(fadeIn, 1 / 60),
		priority = o.priority or Mixer.PRIORITY.Action,
		seq = seq,
		additive = o.additive == true,
		fadeOut = o.fadeOut or 0.25,
		alive = true,
		callbacks = {},
		onEnded = {},
		onStep = {},
		hands = o.hands,
		source = o.source,
		mask = o.mask,
		keep = o.keep == true,
		values = {},
	}
end

-- Plays `clip` on `character`. Returns a handle (stop with a fade, change speed / weight, marker callbacks).
function Mixer.play(character: Model, clip: Clip.Compiled, options: Options?): Handle
	if not connection then
		connection = RunService.Stepped:Connect(step)
	end
	local o = options or {}
	local st = stateOf(character)
	if o.rest then
		st.rest = true
	end
	local layer = newLayer(clip, o)
	table.insert(st.layers, layer)
	table.sort(st.layers, function(a, b)
		if a.priority ~= b.priority then
			return a.priority < b.priority
		end
		return a.seq < b.seq
	end)
	local handle: Handle = {
		stop = function(fade: number?)
			local f = fade or 0.2
			layer.keep = false
			layer.target = 0
			layer.rate = 1 / math.max(f, 1 / 60)
			if f <= 0 then
				layer.w = 0
			end
		end,
		setSpeed = function(speed: number)
			layer.speed = speed
		end,
		setWeight = function(weight: number, fade: number?)
			layer.target = weight
			layer.rate = 1 / math.max(fade or 0.2, 1 / 60)
		end,
		time = function()
			return layer.t
		end,
		setTime = function(t: number)
			layer.t = t
		end,
		playing = function()
			return layer.alive
		end,
		weight = function()
			return layer.w
		end,
		on = function(marker: string, fn: () -> ())
			local list = layer.callbacks[marker] or {}
			table.insert(list, fn)
			layer.callbacks[marker] = list
		end,
		ended = function(fn: () -> ())
			table.insert(layer.onEnded, fn)
		end,
		stepped = function(fn)
			table.insert(layer.onStep, fn)
		end,
	}
	return handle
end

-- A procedural layer (see Options.source): an endless "clip" whose channel values `source` writes every frame.
function Mixer.procedural(
	character: Model,
	name: string,
	source: (number, { [string]: Clip.Value }) -> (),
	options: Options?
): Handle
	local o = table.clone(options or {}) :: Options
	o.source = source
	return Mixer.play(character, Clip.compile({ name = name, length = 1e9, loop = false, keys = {} }), o)
end

-- Channel masks: the legs + pelvis (what walking owns) and everything above them.
Mixer.LOWER = {
	Root = true,
	RHip = true,
	RKnee = true,
	RAnkle = true,
	LHip = true,
	LKnee = true,
	LAnkle = true,
	RFoot = true,
	LFoot = true,
}
Mixer.UPPER = {
	Waist = true,
	Neck = true,
	RShoulder = true,
	RElbow = true,
	RWrist = true,
	LShoulder = true,
	LElbow = true,
	LWrist = true,
	RHand = true,
	LHand = true,
}

-- Fades out every layer on `character`.
function Mixer.stopAll(character: Model, fade: number?)
	local st = states[character]
	if st then
		for _, layer in st.layers do
			layer.target = 0
			layer.rate = 1 / math.max(fade or 0.2, 1 / 60)
		end
	end
end

-- Marks a rig nothing else animates (no Animate script: NPCs, previews): its layers start from the rest pose.
function Mixer.rest(character: Model)
	stateOf(character).rest = true
end

-- Freezes / resumes a character's layers (distance LOD for NPCs): no work at all while paused.
function Mixer.pause(character: Model, paused: boolean)
	local st = states[character]
	if st then
		st.paused = paused
	end
end

-- The measured rig (for tools and fitting), nil before its joints exist.
function Mixer.body(character: Model): Body.Body?
	local st = stateOf(character)
	if st.rebind then
		st.rebind = false
		st.body = Body.bind(character)
	end
	return st.body
end

-- The joint Transforms `clip` gives `body` at time t on its own (from rest, full weight, with its IK): for
-- fitting props to the pose (the foot at contact), previews and baking. Writes nothing.
function Mixer.evaluate(
	body: Body.Body,
	clip: Clip.Compiled,
	t: number,
	hands: { [string]: HandFn }?
): { [string]: CFrame }
	local out: { [string]: CFrame } = {}
	for name in body.joints do
		out[name] = CFrame.identity
	end
	local layer = newLayer(clip, { start = t, hands = hands })
	blend(body, { layer }, { 1 }, out, {})
	return out
end

-- How many characters / layers are live (QA: no leaks).
function Mixer.stats(): (number, number)
	local c, l = 0, 0
	for _, st in states do
		c += 1
		l += #st.layers
	end
	return c, l
end

return Mixer
