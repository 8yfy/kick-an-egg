--!strict
-- Size-based egg carrying (Presentation/EggSize tiers), played with Anim/Mixer ON TOP of the character's own walk,
-- run, jump and idle (only the upper body is posed; the legs keep walking).
--   Small   one hand under the egg, close to the body on the right; the left arm keeps swinging with the walk
--   Medium  both hands on its sides in front of the chest
--   Large   hugged higher and close, the torso leaning back against the weight
--   Giant   both arms up, holding it overhead, braced (head up, a slower heavier bob)
-- The egg is welded (on this client) to the UpperTorso at a spot fitted to THIS avatar and THIS egg: the hands are
-- placed on the egg's real sides by arm IK (R15, Anim/Body), and the egg sits as low as the arms can still hold it
-- that way, so no hand floats and nothing clips into the chest. R6 rigs get the same poses from joint keys.
-- The egg rides the pose: a weight bob that follows the walking speed (Egg prop channel), a short lift from the hip
-- when it's picked up, a short lower when it's put away.
local Clip = require(script.Parent.Clip)
local Mixer = require(script.Parent.Mixer)

local Carry = {}

export type Handle = { stop: (fade: number?) -> (), tier: string }

type Fit = { center: CFrame, toRoot: CFrame, grip: { [string]: Vector3 }, hints: { [string]: Vector3 } }

local LIFT_SECONDS = 0.35

local function def(name: string, length: number, keys: { Clip.Key }): Clip.Compiled
	return Clip.compile({ name = name, length = length, loop = true, keys = keys })
end

-- Upper-body loops. Arms are placed by IK (RHand / LHand reach = 1); the joint keys are the R6 pose and the start
-- the IK bends from. Egg = the egg's offset from its fitted spot (studs / degrees), the weight bob.
local CLIPS: { [string]: Clip.Compiled } = {
	Small = def("CarrySmall", 1.4, {
		{
			t = 0,
			pose = {
				Waist = { 0, -4, -2 },
				Neck = { -2, 3, 0 },
				RShoulder = { 38, 0, 10 },
				RElbow = { 70 },
				RHand = { 1 },
				Egg = { 0, 0, 0, 0, 0, 0 },
			},
		},
		{ t = 0.7, pose = { Waist = { 1, -4, -2 }, Egg = { 2, 0, 0, 0, 0.04, 0 } } },
		{ t = 1.4, pose = { Waist = { 0, -4, -2 }, Egg = { 0, 0, 0, 0, 0, 0 } } },
	}),
	Medium = def("CarryMedium", 1.3, {
		{
			t = 0,
			pose = {
				Waist = { 4, 0, 0 },
				Neck = { -4, 0, 0 },
				RShoulder = { 55, 0, 14 },
				RElbow = { 55 },
				LShoulder = { 55, 0, -14 },
				LElbow = { 55 },
				RHand = { 1 },
				LHand = { 1 },
				Egg = { 0, 0, 0, 0, 0, 0 },
			},
		},
		{ t = 0.65, pose = { Waist = { 5.5, 0, 0 }, Egg = { 1.5, 0, 0, 0, 0.05, 0 } } },
		{ t = 1.3, pose = { Waist = { 4, 0, 0 }, Egg = { 0, 0, 0, 0, 0, 0 } } },
	}),
	Large = def("CarryLarge", 1.5, {
		{
			t = 0,
			pose = {
				Waist = { 9, 0, 0 },
				Neck = { -7, 0, 0 },
				RShoulder = { 75, 0, 18 },
				RElbow = { 45 },
				LShoulder = { 75, 0, -18 },
				LElbow = { 45 },
				RHand = { 1 },
				LHand = { 1 },
				Egg = { 0, 0, 0, 0, 0, 0 },
			},
		},
		{ t = 0.75, pose = { Waist = { 11, 0, 0 }, Egg = { 2, 0, 1.5, 0, 0.08, 0 } } },
		{ t = 1.5, pose = { Waist = { 9, 0, 0 }, Egg = { 0, 0, 0, 0, 0, 0 } } },
	}),
	Giant = def("CarryGiant", 1.8, {
		{
			t = 0,
			pose = {
				Waist = { 5, 0, 0 },
				Neck = { 8, 0, 0 },
				RShoulder = { 165, 0, 14 },
				RElbow = { 20 },
				LShoulder = { 165, 0, -14 },
				LElbow = { 20 },
				RHand = { 1 },
				LHand = { 1 },
				Egg = { 0, 0, 0, 0, 0, 0 },
			},
		},
		{ t = 0.9, pose = { Waist = { 7, 0, 1 }, Egg = { 0, 0, 2.5, 0, 0.12, 0 } } },
		{ t = 1.8, pose = { Waist = { 5, 0, 0 }, Egg = { 0, 0, 0, 0, 0, 0 } } },
	}),
}
Carry.CLIPS = CLIPS

-- Small keeps the left arm with the walk; every other tier owns both arms.
local SMALL_MASK = { Waist = true, Neck = true, RShoulder = true, RElbow = true, RWrist = true, RHand = true }

-- The egg's visible blocks in egg-root space: centre and size.
local function shell(egg: Model, root: BasePart): (Vector3, Vector3)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local rel = root.CFrame:ToObjectSpace(d.CFrame)
			local s = d.Size / 2
			local ext = Vector3.new(
				math.abs(rel.XVector.X) * s.X + math.abs(rel.YVector.X) * s.Y + math.abs(rel.ZVector.X) * s.Z,
				math.abs(rel.XVector.Y) * s.X + math.abs(rel.YVector.Y) * s.Y + math.abs(rel.ZVector.Y) * s.Z,
				math.abs(rel.XVector.Z) * s.X + math.abs(rel.YVector.Z) * s.Y + math.abs(rel.ZVector.Z) * s.Z
			)
			lo = lo:Min(rel.Position - ext)
			hi = hi:Max(rel.Position + ext)
		end
	end
	if lo.X > hi.X then
		return Vector3.zero, Vector3.one
	end
	return (lo + hi) / 2, hi - lo
end

local function partSize(character: Model, ...: string): Vector3?
	for _, name in { ... } do
		local p = character:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			return p.Size
		end
	end
	return nil
end

-- Where the egg sits against this body (UpperTorso space) and where the wrists grip it (egg-centre space), for one
-- tier. Each hold is lowered / pulled in until the arms really reach the grips (as EggKick fits its hug).
local function fit(character: Model, egg: Model, tier: string): Fit?
	local ut = partSize(character, "UpperTorso", "Torso")
	local root = egg.PrimaryPart
	if not ut or not root then
		return nil
	end
	local body = Mixer.body(character)
	local head = partSize(character, "Head") or Vector3.new(1.2, 1.2, 1.2)
	local hand = partSize(character, "RightHand", "Right Arm")
	local palm = if hand then math.min(hand.X, 1) / 2 + 0.02 else 0.3
	local mid, size = shell(egg, root)
	local w, h, d = size.X, size.Y, size.Z
	local front = -(ut.Z / 2 + d / 2 + 0.06)
	local center: Vector3
	local grip: { [string]: Vector3 } = {}
	local hints: { [string]: Vector3 } = {}
	if tier == "Small" then
		center = Vector3.new(ut.X * 0.32 + w * 0.2, -ut.Y * 0.38, front + 0.12)
		grip.RHand = Vector3.new(w * 0.18, -h * 0.4, d * 0.05) -- palm up under the egg
		hints.RHand = Vector3.new(0.9, -0.7, 0.2)
	elseif tier == "Giant" then
		-- overhead, resting on both palms: its bottom clears the head (an egg this big never sits on the head)
		center = Vector3.new(0, ut.Y / 2 + head.Y + 0.15 + h / 2, -0.2)
		local gy = -h / 2 - palm * 0.5
		grip.RHand = Vector3.new(w * 0.3, gy, 0)
		grip.LHand = Vector3.new(-w * 0.3, gy, 0)
		hints.RHand, hints.LHand = Vector3.new(1, -0.1, 0.1), Vector3.new(-1, -0.1, 0.1)
	else
		local high = tier == "Large"
		center = Vector3.new(0, if high then -ut.Y * 0.02 else -ut.Y * 0.3, front + (if high then 0.05 else 0))
		local gx = w / 2 + palm - 0.05
		local gy = if high then -h * 0.12 else h * 0.02
		grip.RHand = Vector3.new(gx, gy, d * 0.12)
		grip.LHand = Vector3.new(-gx, gy, d * 0.12)
		hints.RHand, hints.LHand = Vector3.new(0.9, -0.55, 0.35), Vector3.new(-0.9, -0.55, 0.35)
	end
	-- pull the egg in (or down a little, overhead: never into the head) until both hands really reach their grip
	local lowest = ut.Y / 2 + head.Y - 0.05 + h / 2
	if body then
		local arm = body.limbs.RHand
		local shoulder = body.joints.RShoulder
		if arm and shoulder then
			local reach = (arm.l1 + arm.l2) * 0.96
			local s = shoulder.c0.Position
			for _ = 1, 24 do
				local worst = 0
				for limb, g in grip do
					local sp = if limb == "RHand" then s else Vector3.new(-s.X, s.Y, s.Z)
					worst = math.max(worst, ((center + g) - sp).Magnitude - reach)
				end
				if worst <= 0 then
					break
				end
				if tier == "Giant" then
					if center.Y <= lowest then
						break -- (the arms stretch as far as they go; the egg stays clear of the head)
					end
					center = Vector3.new(center.X, math.max(lowest, center.Y - math.min(worst, 0.2)), center.Z)
				else
					center += Vector3.new(0, math.min(worst, 0.12) * 0.5, math.min(worst, 0.12))
				end
			end
		end
	end
	return { center = CFrame.new(center), toRoot = CFrame.new(mid):Inverse(), grip = grip, hints = hints }
end

local function eggOffset(values: { [string]: Clip.Value }): CFrame
	local e = values.Egg
	return if e then Clip.cframe(e, 1) else CFrame.identity
end

-- Lift: the egg comes up from the hip when picked up (k 0 -> 1) and goes back down when put away (1 -> 0).
local function liftFrame(k: number): CFrame
	local e = 1 - (1 - math.clamp(k, 0, 1)) ^ 3
	return CFrame.new(0, -1.3 * (1 - e), 0.55 * (1 - e)) * CFrame.Angles(math.rad(-25 * (1 - e)), 0, 0)
end

-- Starts carrying `egg` (a welded, unanchored model the character holds) in `tier`'s pose. nil if the character or
-- egg isn't ready (streaming): call again when it is.
function Carry.start(character: Model, egg: Model, tier: string): Handle?
	local clip = CLIPS[tier] or CLIPS.Medium
	local ut = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local root = egg.PrimaryPart
	local f = fit(character, egg, tier)
	if not f or not ut or not ut:IsA("BasePart") or not root then
		return nil
	end
	-- this client's own hold: the egg rides the torso (the server's weld to the tool handle is set aside locally)
	local held: { WeldConstraint } = {}
	for _, w in root:GetChildren() do
		if w:IsA("WeldConstraint") and w.Enabled then
			w.Enabled = false
			table.insert(held, w)
		end
	end
	for _, w in (egg.Parent and egg.Parent:FindFirstChild("Handle") or root):GetChildren() do
		if w:IsA("WeldConstraint") and w.Part1 == root and w.Enabled then
			w.Enabled = false
			table.insert(held, w)
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0, weld.Part1 = ut, root
	weld.C0 = f.center * liftFrame(0) * f.toRoot
	weld.Parent = root

	local lift, liftTarget = 0, 1
	local current = CFrame.identity -- this frame's egg offset (bob x lift), shared with the hand targets
	local hands: { [string]: Mixer.HandFn } = {}
	for limb, point in f.grip do
		local hint = f.hints[limb]
		hands[limb] = function(utCF: CFrame, _values)
			local e = utCF * f.center * current
			return e * point, e.Rotation * hint, nil
		end
	end
	local handle = Mixer.play(character, clip, {
		fadeIn = 0.28,
		priority = Mixer.PRIORITY.Action,
		hands = hands,
		mask = if tier == "Small" then SMALL_MASK else Mixer.UPPER,
		start = math.random() * clip.length,
	})
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local last = os.clock()
	handle.stepped(function(_t, values, weight)
		local now = os.clock()
		local dt = math.min(now - last, 0.1)
		last = now
		lift = math.clamp(lift + (if liftTarget > lift then dt else -dt) / LIFT_SECONDS, 0, 1)
		-- walking speeds the weight bob up (and a giant egg bobs slower, it's heavy)
		if hrp and hrp:IsA("BasePart") then
			local v = hrp.AssemblyLinearVelocity
			local flat = Vector3.new(v.X, 0, v.Z).Magnitude
			local base = if tier == "Giant" then 0.55 else 0.7
			handle.setSpeed(base + math.clamp(flat / 16, 0, 1) * (if tier == "Giant" then 0.7 else 0.9))
		end
		current = CFrame.identity:Lerp(eggOffset(values), weight) * liftFrame(lift)
		if weld.Parent then
			weld.C0 = f.center * current * f.toRoot
		end
	end)

	local stopped = false
	return {
		tier = tier,
		stop = function(fade: number?)
			if stopped then
				return
			end
			stopped = true
			local fadeTime = fade or 0.25
			liftTarget = 0 -- lowered while the arms let go
			handle.stop(fadeTime)
			task.delay(fadeTime, function()
				weld:Destroy()
				for _, w in held do
					if w.Parent then
						w.Enabled = true
					end
				end
			end)
		end,
	}
end

-- Whether a just-arrived held egg's blocks sit in place around its root yet. For a frame or two after the model
-- replicates they can still be tens of studs away (only physics snaps them onto their joints), and a hold fitted
-- then stays that far off. `last` is the previous frame's shell centre: settled = the same twice and egg-sized.
function Carry.settled(egg: Model, last: Vector3?): (boolean, Vector3?)
	local root = egg.PrimaryPart
	if not root then
		return false, nil
	end
	local mid, size = shell(egg, root)
	local sane = mid.Magnitude <= size.Magnitude
	return sane and last ~= nil and (mid - last).Magnitude < 0.05, mid
end

-- Hold offsets as data for tests and previews: the tiers this module poses.
Carry.TIERS = { "Small", "Medium", "Large", "Giant" }

return Carry
