--!strict
-- Partner A. Kick Sack training on the character: Anim/Clip data played by Anim/Mixer over the Animator, feet
-- planted by leg IK. Keeps the gear's fixed timing (Anim/Player.KICK_IMPACT = 0.26 s: Remotes.Train and the hit
-- VFX; Anim/Player.KICK_LENGTH = 0.6 s = Config/Upgrades.Sack.interval: the next kick can start right away).
--   STANCE  a fighting stance while the sack is out and you stand still: lead (left) foot forward, rear foot
--           turned out, hips bladed, guard up, a light bounce on the knees (1.6 Hz). It fades in when you stop and
--           out when you move, so walking in and out of training never snaps.
--   KICKS   every kick starts and ends exactly on the stance (zero speed), so kicks chain back to back and the
--           stance layer underneath catches the end: anticipation (weight onto the support foot, a short dip),
--           chamber (knee up), the strike (hip-driven extension, the body leaning away, arms counter-swinging),
--           contact at 0.26 s with a short sticky hold, re-chamber, the foot lands back in its spot, settle.
--           A rear-leg push kick and a lead-leg snap kick alternate; the super kick (every 10th, top tiers) is a
--           rear roundhouse with the hips turning through it.
local Clip = require(script.Parent.Clip)
local Mixer = require(script.Parent.Mixer)

local Sack = {}

Sack.IMPACT = 0.26
Sack.LENGTH = 0.6

local LEAD = { 1, -0.05, 0, -0.32, -8, 0 } -- left foot, forward
local REAR = { 1, 0.12, 0, 0.3, -28, 0 } -- right foot, back and turned out

-- the stance (t = 0 of every kick, and the stance loop's rest)
local STANCE: Clip.Pose = {
	Root = { -4, -14, 0, 0, -0.16, 0 },
	Waist = { -4, 10, 0 },
	Neck = { 2, 4, 0 },
	RShoulder = { 36, 0, 12 },
	RElbow = { 118 },
	RWrist = { -8, 0, 0 },
	LShoulder = { 48, 0, -10 },
	LElbow = { 108 },
	LWrist = { -8, 0, 0 },
	RHip = { 0 },
	RKnee = { 0 },
	RAnkle = { 0 },
	LHip = { 0 },
	LKnee = { 0 },
	LAnkle = { 0 },
	RFoot = REAR,
	LFoot = LEAD,
}

local function with(base: Clip.Pose, over: Clip.Pose): Clip.Pose
	local out = table.clone(base)
	for k, v in over do
		out[k] = v
	end
	return out
end

local STANCE_LOOP = Clip.compile({
	name = "SackStance",
	length = 0.625,
	loop = true,
	overlap = { Waist = 0.03, Neck = 0.06, RShoulder = 0.05, LShoulder = 0.05, RElbow = 0.07, LElbow = 0.07 },
	keys = {
		{ t = 0, pose = STANCE },
		{
			t = 0.3125,
			pose = {
				Root = { -5, -14, 0, 0, -0.2, 0 },
				Waist = { -5, 10, 0 },
				Neck = { 3, 4, 0 },
				RElbow = { 121 },
				LElbow = { 111 },
			},
		},
	},
})

local function kick(name: string, keys: { Clip.Key }): Clip.Compiled
	return Clip.compile({
		name = name,
		length = Sack.LENGTH,
		overlap = { Waist = 0.012, Neck = 0.025, RShoulder = 0.02, LShoulder = 0.02, RElbow = 0.03, LElbow = 0.03 },
		markers = { Contact = Sack.IMPACT, Land = 0.52 },
		keys = keys,
	})
end

-- A: rear-leg push kick (the sole drives straight into the bag)
local PUSH = kick("SackPush", {
	{ t = 0, pose = STANCE },
	{ t = 0.035, pose = { RFoot = { 1, 0.12, 0.03, 0.3, -28, -8 } } },
	{ -- load: weight rolls onto the lead leg, the rear heel peels up
		t = 0.06,
		pose = {
			Root = { -2, -8, 3, -0.05, -0.21, 0.02 },
			RFoot = { 1, 0.12, 0.12, 0.26, -28, -22 },
			RShoulder = { 34, 0, 12 },
		},
	},
	-- the planted foot hands over to the leg keys over ~0.07 s: its IK target rises with the knee, so both
	-- agree while the weight passes from one to the other (no pop)
	{ t = 0.1, pose = { RHip = { 10, 0, 4 }, RKnee = { -50 }, RAnkle = { -22 } } },
	{ t = 0.13, pose = { RFoot = { 0, 0.1, 0.5, -0.1, -20, -10 } } },
	{ -- chamber: knee high, leaning back, guard tight
		t = 0.155,
		pose = {
			Root = { 9, -5, 3, -0.05, -0.1, 0.02 },
			Waist = { 2, 6, 0 },
			Neck = { -6, 4, 0 },
			RHip = { 96, 0, 4 },
			RKnee = { -118 },
			RAnkle = { 8 },
			RShoulder = { 28, 0, 16 },
			LShoulder = { 52, 0, -12 },
		},
	},
	{ t = 0.215, pose = { RHip = { 99, 0, 2 }, RKnee = { -72 }, RAnkle = { 14 } } },
	{ -- CONTACT: hips through, leg straight, sole on the bag, rear arm swinging back for balance
		t = Sack.IMPACT,
		ease = "impact",
		pose = {
			Root = { 12, -2, 4, -0.04, -0.06, -0.2 },
			Waist = { 4, 4, 0 },
			Neck = { -10, 2, 0 },
			RHip = { 84, 0, 0 },
			RKnee = { -2 },
			RAnkle = { 18 },
			RShoulder = { -18, 0, 26 },
			RElbow = { 72 },
			LShoulder = { 56, 0, -14 },
			LElbow = { 100 },
		},
	},
	{ t = 0.3, pose = { RHip = { 82, 0, 0 }, RKnee = { -5 }, RAnkle = { 16 } } }, -- the hit sticks for a beat
	{ -- re-chamber
		t = 0.4,
		pose = {
			Root = { 7, -9, 2, -0.04, -0.12, 0.02 },
			Waist = { 0, 8, 0 },
			Neck = { -2, 4, 0 },
			RHip = { 76, 0, 4 },
			RKnee = { -106 },
			RAnkle = { 6 },
			RShoulder = { 26, 0, 14 },
			RElbow = { 106 },
		},
	},
	{ t = 0.45, pose = { RFoot = { 0, 0.12, 0.1, 0.3, -28, -10 } } },
	{ t = 0.47, pose = { RHip = { 18, 0, 2 }, RKnee = { -36 }, RAnkle = { -6 } } },
	{ t = 0.53, pose = { RFoot = REAR, Root = { -5, -13, 0, 0, -0.21, 0 } } }, -- lands in its spot, absorbing
	{ t = Sack.LENGTH, pose = STANCE },
})

-- B: lead-leg snap kick (quick, off the front foot)
local SNAP = kick("SackSnap", {
	{ t = 0, pose = STANCE },
	{ t = 0.035, pose = { LFoot = { 1, -0.05, 0.03, -0.32, -8, -6 } } },
	{ -- weight back onto the rear leg
		t = 0.06,
		pose = {
			Root = { 1, -17, -4, 0.06, -0.2, 0.05 },
			LFoot = { 1, -0.05, 0.12, -0.36, -8, -20 },
			LShoulder = { 46, 0, -10 },
		},
	},
	{ t = 0.1, pose = { LHip = { 10, 0, -3 }, LKnee = { -48 }, LAnkle = { -20 } } },
	{ t = 0.13, pose = { LFoot = { 0, -0.05, 0.5, -0.6, -8, -10 } } },
	{ -- chamber
		t = 0.15,
		pose = {
			Root = { 8, -18, -3, 0.06, -0.12, 0.06 },
			Waist = { 1, 12, 0 },
			Neck = { -5, 6, 0 },
			LHip = { 92, 0, -4 },
			LKnee = { -116 },
			LAnkle = { -8 },
			RShoulder = { 40, 0, 12 },
		},
	},
	{ t = 0.215, pose = { LHip = { 94, 0, -2 }, LKnee = { -70 }, LAnkle = { -16 } } },
	{ -- CONTACT: the snap, lead arm dropping back, rear guard high
		t = Sack.IMPACT,
		ease = "impact",
		pose = {
			Root = { 13, -20, -5, 0.06, -0.08, -0.12 },
			Waist = { 3, 12, 0 },
			Neck = { -9, 6, 0 },
			LHip = { 94, 0, -2 },
			LKnee = { -4 },
			LAnkle = { -24 },
			LShoulder = { -14, 0, -24 },
			LElbow = { 70 },
			RShoulder = { 44, 0, 10 },
			RElbow = { 118 },
		},
	},
	{ t = 0.3, pose = { LHip = { 92, 0, -2 }, LKnee = { -7 }, LAnkle = { -22 } } },
	{
		t = 0.4,
		pose = {
			Root = { 6, -17, -2, 0.05, -0.13, 0.04 },
			Waist = { -2, 11, 0 },
			Neck = { 0, 4, 0 },
			LHip = { 70, 0, -4 },
			LKnee = { -104 },
			LAnkle = { -6 },
			LShoulder = { 44, 0, -10 },
			LElbow = { 104 },
		},
	},
	{ t = 0.45, pose = { LFoot = { 0, -0.05, 0.1, -0.32, -8, -8 } } },
	{ t = 0.47, pose = { LHip = { 20, 0, -2 }, LKnee = { -36 }, LAnkle = { -4 } } },
	{ t = 0.53, pose = { LFoot = LEAD, Root = { -5, -14, 0, 0, -0.21, 0 } } },
	{ t = Sack.LENGTH, pose = STANCE },
})

-- C: rear roundhouse (super kick): the support foot pivots, the hips turn through ~85 degrees, the shin whips
-- round at the bag; the shoulders counter-turn to keep the eyes on it
local ROUND = kick("SackRoundhouse", {
	{ t = 0, pose = STANCE },
	{ t = 0.035, pose = { RFoot = { 1, 0.12, 0.03, 0.3, -28, -8 } } },
	{
		t = 0.06,
		pose = {
			Root = { -2, -6, 4, -0.06, -0.22, 0.02 },
			RFoot = { 1, 0.12, 0.12, 0.26, -28, -22 },
			LFoot = LEAD,
		},
	},
	{ t = 0.1, pose = { RHip = { 10, 0, 8 }, RKnee = { -48 }, RAnkle = { -20 } } },
	{ t = 0.13, pose = { RFoot = { 0, 0.2, 0.45, 0.05, -10, -10 } } },
	{ -- chamber out to the side, hips opening, support foot pivoting
		t = 0.16,
		pose = {
			Root = { 4, 34, 14, -0.07, -0.12, 0 },
			Waist = { 0, -20, -4 },
			Neck = { -4, -12, 0 },
			LFoot = { 1, -0.05, 0, -0.32, -55, 0 },
			RHip = { 58, 8, 62 },
			RKnee = { -122 },
			RAnkle = { -20 },
			RShoulder = { 20, 0, 30 },
			LShoulder = { 58, 0, -20 },
		},
	},
	{ -- CONTACT: the shin snaps round, instep on the bag, the body leaning away
		t = Sack.IMPACT,
		ease = "impact",
		pose = {
			Root = { 6, 84, 20, -0.08, -0.1, 0 },
			Waist = { 0, -50, -6 },
			Neck = { -6, -28, 0 },
			LFoot = { 1, -0.05, 0, -0.32, -95, 0 },
			RHip = { 32, 0, 78 },
			RKnee = { -6 },
			RAnkle = { -32 },
			RShoulder = { -34, 0, 44 },
			RElbow = { 60 },
			LShoulder = { 62, 0, -26 },
			LElbow = { 104 },
		},
	},
	{ t = 0.3, pose = { RHip = { 32, 0, 76 }, RKnee = { -10 } } },
	{ -- the leg folds back, the hips unwind
		t = 0.41,
		pose = {
			Root = { 4, 30, 10, -0.06, -0.13, 0 },
			Waist = { -2, -14, -2 },
			Neck = { 0, -6, 0 },
			LFoot = { 1, -0.05, 0, -0.32, -45, 0 },
			RHip = { 50, -6, 40 },
			RKnee = { -110 },
			RAnkle = { -8 },
			RShoulder = { 26, 0, 16 },
			RElbow = { 104 },
		},
	},
	{ t = 0.45, pose = { RFoot = { 0, 0.12, 0.1, 0.3, -28, -10 } } },
	{ t = 0.48, pose = { RHip = { 16, 0, 6 }, RKnee = { -36 } } },
	{ t = 0.54, pose = { RFoot = REAR, LFoot = LEAD, Root = { -5, -12, 0, 0, -0.21, 0 } } },
	{ t = Sack.LENGTH, pose = STANCE },
})

Sack.CLIPS = { stance = STANCE_LOOP, push = PUSH, snap = SNAP, roundhouse = ROUND }

local stances: { [Model]: Mixer.Handle } = setmetatable({}, { __mode = "k" }) :: any

-- Fades the training stance in (on) or out on `character` (cheap to call every frame).
function Sack.stance(character: Model, on: boolean)
	local h = stances[character]
	if on then
		if h and h.playing() then
			h.setWeight(1, 0.25)
		else
			stances[character] = Mixer.play(character, STANCE_LOOP, {
				fadeIn = 0.25,
				priority = Mixer.PRIORITY.Action,
				start = math.random() * STANCE_LOOP.length,
			})
		end
	elseif h then
		h.stop(0.2)
		stances[character] = nil
	end
end

-- One kick on `character`: the n-th kick of this session (variation), `super` for the special one.
function Sack.kick(character: Model, n: number, super: boolean?): Mixer.Handle
	local clip = if super then ROUND elseif n % 2 == 0 then SNAP else PUSH
	return Mixer.play(character, clip, {
		fadeIn = 0.05, -- it starts on the stance, so this only covers a kick that interrupts a step
		fadeOut = 0.08,
		priority = Mixer.PRIORITY.Action2,
	})
end

return Sack
