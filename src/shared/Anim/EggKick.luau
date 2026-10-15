--!strict
-- The kick-line EGG KICK: an original, full-body rig animation (R15 joints: hips, both legs, torso twist, arms,
-- head) for kicking the mystery egg, plus the two-handed HOLD pose for carrying it on the kick line.
--   0.00 hold        the egg in both hands, knees soft
--   0.14 toss        arms fling the egg up, up on the toes
--   0.34 wind-up     hips and torso twist away, kicking leg drawn far back, arms spread for balance
--   0.50 coil        a beat of anticipation: lower, tighter
--   CONTACT 0.62     the strike: hips whip round, the leg snaps straight through the egg, arms counter-swing
--   0.70             hit-stop at full extension
--   0.94 follow      the leg carries on up and across, body leans back off the ground
--   1.18 recover     back to a neutral stance (the default Animate takes over)
-- Pose = joint -> { pitch, yaw, roll (degrees), lift (studs) }, the same convention as Anim/Player.
--
-- PLAYBACK (EggKick.play): with a published AnimationId (EggKick.PUBLISHED, set after publishing) it plays as a
-- real AnimationTrack on the character's Animator. In Studio without one it registers the clip
-- (KeyframeSequenceProvider) and still plays it through the Animator. On live servers before publishing, the
-- same keyframes are written to the rig's joints every frame (identical motion). To publish: run
-- require(game.ReplicatedStorage.Shared.Anim.EggKick).buildKeyframeSequence().Parent = workspace in Studio's
-- command bar, right-click it > Save to Roblox, and put the id in EggKick.PUBLISHED.kick (same for .hold with
-- buildHoldSequence). See docs/KickCinematic.md.
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local RunService = game:GetService("RunService")

local PlayerAnim = require(script.Parent.Player)

local EggKick = {}

EggKick.PUBLISHED = { kick = "", hold = "" } -- "rbxassetid://<id>" once published (never invented)
EggKick.CONTACT = 0.62
EggKick.LENGTH = 1.18

type Pose = { [string]: { number } }
type Key = { t: number, ease: string, pose: Pose }

local HOLD: Pose = {
	Root = { 0, 0, 0, -0.08 },
	Waist = { 4, 0, 0 },
	Neck = { -4, 0, 0 },
	RShoulder = { 72, 0, -12 },
	RElbow = { 28, 0, 0 },
	LShoulder = { 72, 0, 12 },
	LElbow = { 28, 0, 0 },
	RHip = { 8, 0, 0 },
	RKnee = { -14, 0, 0 },
	RAnkle = { 6, 0, 0 },
	LHip = { 8, 0, 0 },
	LKnee = { -14, 0, 0 },
	LAnkle = { 6, 0, 0 },
}
EggKick.HOLD = HOLD
-- the hold, braced (lower, knees bent) while your timing meter runs
local BRACED: Pose = table.clone(HOLD)
BRACED.Root = { 6, 0, 0, -0.22 }
BRACED.RHip, BRACED.LHip = { 22, 0, 0 }, { 22, 0, 0 }
BRACED.RKnee, BRACED.LKnee = { -34, 0, 0 }, { -34, 0, 0 }
EggKick.BRACED = BRACED
-- FlightController leaves the camera alone until this server time (your kick cinematic owns it until then)
EggKick.cameraBusyUntil = 0

local KEYS: { Key } = {
	{ t = 0, ease = "linear", pose = HOLD },
	{
		t = 0.14,
		ease = "out",
		pose = { -- toss: arms up, on the toes
			Root = { -4, 0, 0, 0.12 },
			Waist = { -8, 0, 0 },
			Neck = { -18, 0, 0 },
			RShoulder = { 160, 0, -20 },
			RElbow = { 10, 0, 0 },
			LShoulder = { 160, 0, 20 },
			LElbow = { 10, 0, 0 },
			RHip = { 0, 0, 0 },
			RKnee = { -4, 0, 0 },
			RAnkle = { -18, 0, 0 },
			LHip = { 0, 0, 0 },
			LKnee = { -4, 0, 0 },
			LAnkle = { -18, 0, 0 },
		},
	},
	{
		t = 0.34,
		ease = "out",
		pose = { -- wind-up: twist away, kicking leg far back, arms spread
			Root = { 10, -22, 0, -0.06 },
			Waist = { 6, 28, 0 },
			Neck = { 12, -10, 0 },
			RShoulder = { 70, 0, -70 },
			RElbow = { 20, 0, 0 },
			LShoulder = { -35, 0, 55 },
			LElbow = { 30, 0, 0 },
			RHip = { -55, 0, 0 },
			RKnee = { -95, 0, 0 },
			RAnkle = { 22, 0, 0 },
			LHip = { 28, 0, 0 },
			LKnee = { -38, 0, 0 },
			LAnkle = { 14, 0, 0 },
		},
	},
	{
		t = 0.5,
		ease = "inout",
		pose = { -- coil: lower, tighter (anticipation)
			Root = { 12, -26, 0, -0.16 },
			Waist = { 8, 32, 0 },
			Neck = { 14, -12, 0 },
			RShoulder = { 78, 0, -78 },
			RElbow = { 24, 0, 0 },
			LShoulder = { -42, 0, 60 },
			LElbow = { 34, 0, 0 },
			RHip = { -66, 0, 0 },
			RKnee = { -108, 0, 0 },
			RAnkle = { 24, 0, 0 },
			LHip = { 34, 0, 0 },
			LKnee = { -46, 0, 0 },
			LAnkle = { 16, 0, 0 },
		},
	},
	{
		t = EggKick.CONTACT,
		ease = "in",
		pose = { -- contact: hips whip round, leg straight through the egg, arms counter-swing
			Root = { 18, 16, 0, 0.02 },
			Waist = { 10, -22, 0 },
			Neck = { -8, 6, 0 },
			RShoulder = { -50, 0, -35 },
			RElbow = { 40, 0, 0 },
			LShoulder = { 85, 0, 30 },
			LElbow = { 20, 0, 0 },
			RHip = { 98, 0, 0 },
			RKnee = { -4, 0, 0 },
			RAnkle = { -14, 0, 0 },
			LHip = { -12, 0, 0 },
			LKnee = { -10, 0, 0 },
			LAnkle = { 8, 0, 0 },
		},
	},
	{
		t = 0.7,
		ease = "linear",
		pose = { -- hit-stop: held at full extension
			Root = { 20, 18, 0, 0.04 },
			Waist = { 10, -24, 0 },
			Neck = { -10, 6, 0 },
			RShoulder = { -55, 0, -38 },
			RElbow = { 40, 0, 0 },
			LShoulder = { 88, 0, 32 },
			LElbow = { 20, 0, 0 },
			RHip = { 108, 0, 0 },
			RKnee = { -2, 0, 0 },
			RAnkle = { -16, 0, 0 },
			LHip = { -14, 0, 0 },
			LKnee = { -8, 0, 0 },
			LAnkle = { 10, 0, 0 },
		},
	},
	{
		t = 0.94,
		ease = "out",
		pose = { -- follow-through: up and across, off the ground
			Root = { 24, 26, 0, 0.18 },
			Waist = { 8, -18, 0 },
			Neck = { -14, 10, 0 },
			RShoulder = { -30, 0, -55 },
			RElbow = { 50, 0, 0 },
			LShoulder = { 60, 0, 50 },
			LElbow = { 35, 0, 0 },
			RHip = { 128, 18, 0 },
			RKnee = { -22, 0, 0 },
			RAnkle = { -10, 0, 0 },
			LHip = { -18, 0, 0 },
			LKnee = { -6, 0, 0 },
			LAnkle = { -12, 0, 0 },
		},
	},
	{
		t = EggKick.LENGTH,
		ease = "inout",
		pose = { -- recover
			Root = { 0, 0, 0, 0 },
			Waist = { 0, 0, 0 },
			Neck = { 0, 0, 0 },
			RShoulder = { 10, 0, -6 },
			RElbow = { 20, 0, 0 },
			LShoulder = { 10, 0, 6 },
			LElbow = { 20, 0, 0 },
			RHip = { 4, 0, 0 },
			RKnee = { -8, 0, 0 },
			RAnkle = { 4, 0, 0 },
			LHip = { 4, 0, 0 },
			LKnee = { -8, 0, 0 },
			LAnkle = { 4, 0, 0 },
		},
	},
}
EggKick.KEYS = KEYS

local function ease(kind: string, a: number): number
	if kind == "in" then
		return a * a * a
	elseif kind == "out" then
		return 1 - (1 - a) ^ 2
	elseif kind == "inout" then
		return a * a * (3 - 2 * a)
	end
	return a
end

-- The pose `t` seconds into the kick (clamped).
function EggKick.pose(t: number): Pose
	local prev, nxt = KEYS[1], KEYS[#KEYS]
	for i = 2, #KEYS do
		if t <= KEYS[i].t then
			prev, nxt = KEYS[i - 1], KEYS[i]
			break
		end
	end
	local span = nxt.t - prev.t
	local a = if span > 0 then ease(nxt.ease, math.clamp((t - prev.t) / span, 0, 1)) else 1
	local out: Pose = {}
	for name, from in prev.pose do
		local to = nxt.pose[name] or from
		out[name] = {
			from[1] + (to[1] - from[1]) * a,
			from[2] + (to[2] - from[2]) * a,
			from[3] + (to[3] - from[3]) * a,
			(from[4] or 0) + ((to[4] or 0) - (from[4] or 0)) * a,
		}
	end
	return out
end

-- KeyframeSequence (R15 pose hierarchy) for the Animator / publishing --------------------------------------------
local PARENT = { -- pose part -> its parent pose part
	LowerTorso = "HumanoidRootPart",
	UpperTorso = "LowerTorso",
	Head = "UpperTorso",
	RightUpperArm = "UpperTorso",
	RightLowerArm = "RightUpperArm",
	LeftUpperArm = "UpperTorso",
	LeftLowerArm = "LeftUpperArm",
	RightUpperLeg = "LowerTorso",
	RightLowerLeg = "RightUpperLeg",
	RightFoot = "RightLowerLeg",
	LeftUpperLeg = "LowerTorso",
	LeftLowerLeg = "LeftUpperLeg",
	LeftFoot = "LeftLowerLeg",
}
local PART_OF = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	RShoulder = "RightUpperArm",
	RElbow = "RightLowerArm",
	LShoulder = "LeftUpperArm",
	LElbow = "LeftLowerArm",
	RHip = "RightUpperLeg",
	RKnee = "RightLowerLeg",
	RAnkle = "RightFoot",
	LHip = "LeftUpperLeg",
	LKnee = "LeftLowerLeg",
	LAnkle = "LeftFoot",
}
local EASING = {
	linear = Enum.PoseEasingStyle.Linear,
	["in"] = Enum.PoseEasingStyle.Cubic,
	out = Enum.PoseEasingStyle.Cubic,
	inout = Enum.PoseEasingStyle.Cubic,
}
local DIRECTION = {
	linear = Enum.PoseEasingDirection.In,
	["in"] = Enum.PoseEasingDirection.In,
	out = Enum.PoseEasingDirection.Out,
	inout = Enum.PoseEasingDirection.InOut,
}

local function keyframe(time: number, pose: Pose, easeName: string): Keyframe
	local kf = Instance.new("Keyframe")
	kf.Time = time
	local poses: { [string]: Pose } = {}
	local function poseFor(part: string): any
		if poses[part] then
			return poses[part]
		end
		local p = Instance.new("Pose")
		p.Name = part
		p.Weight = if part == "HumanoidRootPart" then 0 else 1
		p.EasingStyle = EASING[easeName] or Enum.PoseEasingStyle.Linear
		p.EasingDirection = DIRECTION[easeName] or Enum.PoseEasingDirection.In
		local parent = PARENT[part]
		p.Parent = if parent then poseFor(parent) else kf
		poses[part] = p :: any
		return p
	end
	for joint, v in pose do
		local part = PART_OF[joint]
		if part then
			local p = poseFor(part)
			p.CFrame = CFrame.new(0, v[4] or 0, 0) * CFrame.Angles(math.rad(v[1]), math.rad(v[2]), math.rad(v[3]))
		end
	end
	return kf
end

function EggKick.buildKeyframeSequence(): KeyframeSequence
	local seq = Instance.new("KeyframeSequence")
	seq.Name = "EggKick"
	seq.Loop = false
	seq.Priority = Enum.AnimationPriority.Action4
	for _, k in KEYS do
		local kf = keyframe(k.t, k.pose, k.ease)
		if k.t == EggKick.CONTACT then
			local marker = Instance.new("KeyframeMarker")
			marker.Name = "Contact"
			marker.Parent = kf
		end
		kf.Parent = seq
	end
	return seq
end

function EggKick.buildHoldSequence(): KeyframeSequence
	local seq = Instance.new("KeyframeSequence")
	seq.Name = "EggHold"
	seq.Loop = true
	seq.Priority = Enum.AnimationPriority.Action
	keyframe(0, HOLD, "linear").Parent = seq
	keyframe(1, HOLD, "linear").Parent = seq
	return seq
end

-- Playback ---------------------------------------------------------------------------------------------------
local registered: { [string]: string } = {}
local function animationId(which: "kick" | "hold"): string?
	local published = EggKick.PUBLISHED[which]
	if published ~= "" then
		return published
	end
	if not RunService:IsStudio() then
		return nil -- (unpublished on a live server: the joint fallback below)
	end
	if not registered[which] then
		local ok, id = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(
				if which == "kick" then EggKick.buildKeyframeSequence() else EggKick.buildHoldSequence()
			)
		end)
		registered[which] = if ok then id else ""
	end
	return if registered[which] ~= "" then registered[which] else nil
end

local function animatorOf(character: Model): Animator?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

export type Playing = { stop: () -> (), track: AnimationTrack? }

-- Plays the kick on `character` so its CONTACT frame lands at server time `contactAt`. Returns a stop handle.
-- A late start (the server's answer arrived after the clip should have begun) catches up instead of lagging.
function EggKick.play(character: Model, contactAt: number): Playing
	local startAt = contactAt - EggKick.CONTACT
	local animator = animatorOf(character)
	local id = animationId("kick")
	if animator and id then
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action4
			track:Play(0.05)
			local late = math.max(0, workspace:GetServerTimeNow() - startAt)
			if late > 0 then
				track.TimePosition = math.min(late, EggKick.LENGTH)
			end
			return {
				stop = function()
					track:Stop(0.15)
				end,
				track = track,
			}
		end
	end
	-- joints (live servers before the clip is published): the same keyframes every frame, after the Animator
	local rig = PlayerAnim.rig(character)
	local conn: RBXScriptConnection
	conn = RunService.Stepped:Connect(function()
		local t = workspace:GetServerTimeNow() - startAt
		if t > EggKick.LENGTH or not character.Parent then
			conn:Disconnect()
			return
		end
		PlayerAnim.apply(rig, EggKick.pose(math.max(0, t)))
	end)
	return {
		stop = function()
			conn:Disconnect()
		end,
		track = nil,
	}
end

-- The hold: a looping track (published / Studio) or, else, the HOLD pose written each frame. Returns stop.
function EggKick.hold(character: Model): () -> ()
	local animator = animatorOf(character)
	local id = animationId("hold")
	if animator and id then
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play(0.2)
			return function()
				track:Stop(0.2)
			end
		end
	end
	local rig = PlayerAnim.rig(character)
	local conn = RunService.Stepped:Connect(function()
		if character.Parent and character:GetAttribute("KickBrace") ~= true then
			PlayerAnim.apply(rig, HOLD)
		end
	end)
	return function()
		conn:Disconnect()
	end
end

return EggKick
