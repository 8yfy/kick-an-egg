--!strict
-- The kick-line EGG KICK (a drop punt) and the HOLD / BRACE poses around it: Anim/Clip data played by Anim/Mixer
-- on top of the Animator, with the hands fitted onto the real egg and the feet planted by leg IK on every avatar.
--
--   0.00 ready      the egg hugged at the belly, knees soft
--   0.11 gather     anticipation: sink, chest over the egg, egg pulled in
--   0.21 RELEASE    legs drive up, the arms toss the egg up and forward; it leaves the hands here
--   0.33 step       the support (left) foot lifts as the weight rolls onto the right
--   0.44 PLANT      the left foot plants beside the falling egg, the weight comes onto it, hips coil away
--   0.65 WINDUP     the kicking leg at the top of its draw-back (accelerating into it, no held pose); the
--                   opposite arm out wide, shoulders counter-turned against the hips
--   0.745           the hips whip round first, the thigh leads and the shin lags behind
--   0.80 CONTACT    the shin snaps straight, laces through the egg (the egg's launch, = KickAt)
--   0.98            follow-through: the leg carries on up, the body lifts onto the support toes and leans back
--   1.27 LAND       the kicking foot comes down onto its own spot
--   1.50 RECOVER    the support foot steps back under the body; 1.80 settled, blended back into the Animator
-- Pre-contact is 0.80 s, inside the server's 1.0 s lead (KickService LAUNCH_DELAY). A late start (the answer
-- arrived late) plays the run-up faster, up to 1.4x, so the foot still meets the egg exactly at KickAt; it never
-- jumps frames unless it is later than that.
local Body = require(script.Parent.Body)
local Clip = require(script.Parent.Clip)
local Mixer = require(script.Parent.Mixer)

local EggKick = {}

EggKick.RELEASE = 0.21
EggKick.PLANT = 0.44
EggKick.WINDUP = 0.65
EggKick.CONTACT = 0.8
EggKick.LAND = 1.27
EggKick.RECOVER = 1.5
EggKick.LENGTH = 1.8
EggKick.MAX_CATCH_UP = 1.4 -- fastest run-up speed when the kick starts late
-- FlightController leaves the camera alone until this server time (your kick cinematic owns it until then)
EggKick.cameraBusyUntil = 0

local PLANTED = { 1, 0, 0, 0, 0, 0 }

-- Hold: a living loop (breathing every 2 s, the weight drifting side to side over 4 s, feet planted).
local HOLD = Clip.compile({
	name = "EggHold",
	length = 4,
	loop = true,
	overlap = { Neck = 0.18, Egg = 0.08 },
	keys = {
		{
			t = 0,
			pose = {
				Root = { 3, 0, 0, 0, -0.1, 0 },
				Waist = { 2, 0, 0 },
				Neck = { -7, 0, 0 },
				RShoulder = { 48, 0, 22 },
				RElbow = { 62 },
				LShoulder = { 48, 0, -22 },
				LElbow = { 62 },
				RFoot = PLANTED,
				LFoot = PLANTED,
				RHand = { 1 },
				LHand = { 1 },
				Egg = { 0, 0, 0, 0, 0, 0 },
			},
		},
		{
			t = 1,
			pose = {
				Root = { 3.6, 0, 0.4, -0.012, -0.075, 0 },
				Waist = { 0.6, 0, 0 },
				Neck = { -6, 1, 0 },
				Egg = { 0, 0, 0, 0, 0.035, 0 },
			},
		},
		{
			t = 2,
			pose = {
				Root = { 3, 1, 1.4, -0.045, -0.11, 0 },
				Waist = { 2.4, -1, -1 },
				Neck = { -7.5, 3, 1 },
				Egg = { 0, 0, 0, 0, -0.01, 0 },
			},
		},
		{
			t = 3,
			pose = {
				Root = { 3.6, 0, 0.4, -0.012, -0.075, 0 },
				Waist = { 0.6, 0, 0 },
				Neck = { -6, -1, 0 },
				Egg = { 0, 0, 0, 0, 0.035, 0 },
			},
		},
	},
})

-- Brace (the timing meter is running): lower, knees loaded, egg pulled in, a quick shallow bounce.
local BRACE = Clip.compile({
	name = "EggBrace",
	length = 1.2,
	loop = true,
	keys = {
		{
			t = 0,
			pose = {
				Root = { -3, 0, 0, 0, -0.32, 0.03 },
				Waist = { -5, 0, 0 },
				Neck = { 5, 0, 0 },
				RFoot = PLANTED,
				LFoot = PLANTED,
				RHand = { 1 },
				LHand = { 1 },
				Egg = { -5, 0, 0, 0, -0.05, 0 },
			},
		},
		{
			t = 0.6,
			pose = {
				Root = { -4, 0, 0, 0, -0.37, 0.03 },
				Waist = { -6, 0, 0 },
				Neck = { 6, 0, 0 },
				Egg = { -6, 0, 0, 0, -0.07, 0 },
			},
		},
	},
})

local KICK = Clip.compile({
	name = "EggKick",
	length = EggKick.LENGTH,
	-- secondary action trails the hips: arms and head follow through after the body
	overlap = { Waist = 0.015, Neck = 0.04, RShoulder = 0.03, LShoulder = 0.03, RElbow = 0.05, LElbow = 0.05 },
	markers = {
		Release = EggKick.RELEASE,
		Plant = EggKick.PLANT,
		WindUp = EggKick.WINDUP,
		Contact = EggKick.CONTACT,
		Land = EggKick.LAND,
		Recover = EggKick.RECOVER,
	},
	keys = {
		{ -- ready (= the hold)
			t = 0,
			pose = {
				Root = { 3, 0, 0, 0, -0.1, 0 },
				Waist = { 2, 0, 0 },
				Neck = { -7, 0, 0 },
				RShoulder = { 48, 0, 22 },
				RElbow = { 62 },
				LShoulder = { 48, 0, -22 },
				LElbow = { 62 },
				RHip = { 0 },
				RKnee = { 0 },
				RAnkle = { 0 },
				RFoot = PLANTED,
				LFoot = PLANTED,
				RHand = { 1 },
				LHand = { 1 },
				Egg = { 0, 0, 0, 0, 0, 0 },
			},
		},
		{ -- gather: sink and load, chest over the egg
			t = 0.11,
			pose = {
				Root = { -5, 3, 0, 0, -0.34, 0.03 },
				Waist = { -7, -3, 0 },
				Neck = { 6, 0, 0 },
				Egg = { -10, 0, 0, 0, -0.2, 0 },
			},
		},
		{ -- the push: legs extend, the toss
			t = EggKick.RELEASE,
			pose = {
				Root = { 6, 0, 0, 0, 0.02, -0.03 },
				Waist = { 8, 0, 0 },
				Neck = { 16, 0, 0 },
				RShoulder = { 118, 0, 16 },
				RElbow = { 24 },
				LShoulder = { 118, 0, -16 },
				LElbow = { 24 },
				RHand = { 1 },
				LHand = { 1 },
				Egg = { 22, 0, 0, 0, 0.85, -0.5 },
			},
		},
		{ -- hands open off the egg; arms keep rising, then open for balance; the left foot still bears weight
			t = 0.26,
			pose = {
				LFoot = PLANTED,
				RHand = { 0 },
				LHand = { 0 },
				RShoulder = { 118, 0, 20 },
				LShoulder = { 118, 0, -20 },
				RElbow = { 18 },
				LElbow = { 18 },
			},
		},
		{ -- step: weight rolls onto the right, the left foot lifts
			t = 0.33,
			pose = {
				Root = { 4, -6, -3, 0.05, -0.05, -0.08 },
				Waist = { 4, 6, 0 },
				Neck = { 18, 0, 0 },
				RShoulder = { 54, 0, 36 },
				RElbow = { 30 },
				LShoulder = { 66, 0, -32 },
				LElbow = { 28 },
				LFoot = { 1, -0.05, 0.22, -0.32, -4, -6 },
			},
		},
		{ -- right foot still bearing weight, about to push off
			t = 0.4,
			pose = { RFoot = PLANTED, RHip = { -6 }, RKnee = { -24 }, RAnkle = { -6 } },
		},
		{ -- PLANT: the left foot lands beside the falling egg, the weight comes onto it, hips coil
			t = EggKick.PLANT,
			pose = {
				Root = { -2, -14, 4, -0.08, -0.17, -0.3 },
				Waist = { -4, 18, 0 },
				Neck = { 10, -4, 0 },
				LFoot = { 1, -0.08, 0, -0.6, -8, 0 },
				RShoulder = { 8, 0, 38 },
				RElbow = { 36 },
				LShoulder = { 58, 0, -44 },
				LElbow = { 28 },
			},
		},
		{ -- the right foot peels off the ground into the draw-back
			t = 0.49,
			pose = { RFoot = { 0, 0, 0, 0, 0, 0 }, RHip = { -20, 0, 4 }, RKnee = { -62 }, RAnkle = { -16 } },
		},
		{ -- WINDUP: top of the draw-back, the body coiled against it
			t = EggKick.WINDUP,
			pose = {
				Root = { -6, -22, 6, -0.1, -0.2, -0.3 },
				Waist = { -6, 26, -2 },
				Neck = { 6, -4, -2 },
				RHip = { -46, 0, 6 },
				RKnee = { -106 },
				RAnkle = { -28 },
				RShoulder = { -26, 0, 34 },
				RElbow = { 42 },
				LShoulder = { 56, 0, -58 },
				LElbow = { 26 },
			},
		},
		{ -- the hips fire first: the thigh swings through, the shin still trailing
			t = 0.745,
			pose = {
				Root = { 2, -2, 7, -0.08, -0.12, -0.3 },
				Waist = { 0, 8, -2 },
				RHip = { 20, 0, 3 },
				RKnee = { -114 },
				RAnkle = { -32 },
				RShoulder = { 8, 0, 30 },
				LShoulder = { 40, 0, -68 },
			},
		},
		{ -- CONTACT: the shin snaps straight through the egg, laces on it, arms counter-swing
			t = EggKick.CONTACT,
			ease = "impact",
			pose = {
				Root = { 10, 14, 8, -0.06, -0.06, -0.3 },
				Waist = { 4, -16, 0 },
				Neck = { -22, 4, 0 },
				RHip = { 60, 0, -2 },
				RKnee = { -8 },
				RAnkle = { -38 },
				RShoulder = { 44, 0, 18 },
				RElbow = { 46 },
				LShoulder = { 4, 0, -74 },
				LElbow = { 20 },
			},
		},
		{ -- follow-through: the leg carries on up, onto the support toes, leaning back
			t = 0.98,
			pose = {
				Root = { 16, 22, 6, -0.04, 0.06, -0.3 },
				Waist = { 6, -14, 0 },
				Neck = { -14, 8, 0 },
				RHip = { 112, 0, -6 },
				RKnee = { -20 },
				RAnkle = { -22 },
				LFoot = { 1, -0.08, 0.13, -0.6, -8, -24 },
				RShoulder = { 68, 0, -6 },
				RElbow = { 50 },
				LShoulder = { -10, 0, -58 },
				LElbow = { 26 },
			},
		},
		{ -- coming down, heel back on the ground
			t = 1.14,
			pose = {
				Root = { 6, 10, 3, -0.04, -0.06, -0.24 },
				Waist = { 2, -6, 0 },
				Neck = { -4, 4, 0 },
				RHip = { 52, 0, 0 },
				RKnee = { -52 },
				RAnkle = { -4 },
				LFoot = { 1, -0.08, 0, -0.6, -8, 0 },
				RShoulder = { 30, 0, 10 },
				RElbow = { 34 },
				LShoulder = { 6, 0, -34 },
				LElbow = { 24 },
			},
		},
		{ -- the kicking foot reaches for its spot
			t = 1.21,
			pose = { RFoot = { 0, 0, 0, 0, 0, 0 }, RHip = { 16, 0, 0 }, RKnee = { -30 }, RAnkle = { 6 } },
		},
		{ -- LAND: weight caught on both feet
			t = EggKick.LAND,
			pose = {
				RFoot = PLANTED,
				Root = { 0, 2, 0, -0.02, -0.2, -0.12 },
				Waist = { 0, -2, 0 },
				Neck = { -2, 2, 0 },
				RShoulder = { 15, 0, 12 },
				LShoulder = { 10, 0, -22 },
			},
		},
		{ -- the support foot steps back under the body
			t = 1.38,
			pose = { LFoot = { 1, -0.04, 0.16, -0.3, -4, 0 }, Root = { 0, 0, -2, 0.04, -0.12, -0.04 } },
		},
		{ -- RECOVER
			t = EggKick.RECOVER,
			pose = {
				LFoot = PLANTED,
				Root = { 0, 0, 0, 0, -0.1, 0 },
				RShoulder = { 8, 0, 8 },
				RElbow = { 16 },
				LShoulder = { 8, 0, -8 },
				LElbow = { 16 },
				Neck = { 0, 0, 0 },
			},
		},
		{ -- settled
			t = EggKick.LENGTH,
			pose = {
				Root = { 0, 0, 0, 0, -0.02, 0 },
				Waist = { 0, 0, 0 },
				Neck = { 0, 0, 0 },
				RShoulder = { 4, 0, 6 },
				RElbow = { 10 },
				LShoulder = { 4, 0, -6 },
				LElbow = { 10 },
				RFoot = PLANTED,
				LFoot = PLANTED,
			},
		},
	},
})
EggKick.CLIPS = { hold = HOLD, brace = BRACE, kick = KICK }

-- Fitting the egg to this body --------------------------------------------------------------------------------
type Fit = { center: CFrame, toRoot: CFrame, grip: { [string]: Vector3 }, weld: Weld? }
local fits: { [Model]: Fit } = setmetatable({}, { __mode = "k" }) :: any

-- Half-width of the egg's blocks at a point (egg-root space), along X.
local function halfWidth(egg: Model, root: BasePart, at: Vector3): number
	local best = 0
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") and d ~= root and d.Transparency < 1 then
			local rel = root.CFrame:ToObjectSpace(d.CFrame)
			local s = d.Size / 2
			local function ext(axis: Vector3): number
				return math.abs(rel.RightVector:Dot(axis)) * s.X
					+ math.abs(rel.UpVector:Dot(axis)) * s.Y
					+ math.abs(rel.LookVector:Dot(axis)) * s.Z
			end
			local p = rel.Position
			if math.abs(at.Y - p.Y) <= ext(Vector3.yAxis) and math.abs(at.Z - p.Z) <= ext(Vector3.zAxis) then
				best = math.max(best, math.abs(p.X) + ext(Vector3.xAxis))
			end
		end
	end
	return best
end

-- The egg's solid blocks in egg-root space (its root part and anything invisible left out): centre and size.
local function shell(egg: Model, root: BasePart): (Vector3, Vector3)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") and d ~= root and d.Transparency < 1 then
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

-- Where the egg sits against this body (UpperTorso space) and where the wrists grip it (egg-centre space).
-- A big egg is hugged: its back against the chest, the hands on its sides close to the body, and the egg as low
-- as these arms can still hold it that way (so as much of the face as possible stays above it).
local function fit(character: Model, egg: Model): Fit?
	local body = Mixer.body(character)
	local ut = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local root = egg.PrimaryPart
	if not body or not ut or not ut:IsA("BasePart") or not root then
		return nil
	end
	local mid, size = shell(egg, root)
	local cz = -(ut.Size.Z / 2 + size.Z / 2 + 0.03)
	local cy = -ut.Size.Y * 0.35
	local grip = {}
	local arm = body.limbs.RHand
	local shoulder = body.joints.RShoulder
	if arm and shoulder then
		local reach = (arm.l1 + arm.l2) * 0.97
		local hand = character:FindFirstChild("RightHand")
		local palm = if hand and hand:IsA("BasePart") then hand.Size.X / 2 + 0.02 else 0.3
		local gy = size.Y * 0.04 -- the grip band, just above the egg's middle
		local gz = size.Z / 2 - 0.35 -- near its back corners, beside the body
		local gx = halfWidth(egg, root, mid + Vector3.new(0, gy, gz)) + palm
		local s = shoulder.c0.Position
		local dx, dz = gx - math.abs(s.X), (cz + gz) - s.Z
		local dy = math.sqrt(math.max(reach * reach - dx * dx - dz * dz, 0.04))
		cy = s.Y - dy - gy -- as low as the hug still reaches
		grip.RHand = Vector3.new(gx, gy, gz)
		grip.LHand = Vector3.new(-gx, gy, gz)
	end
	local toRoot = CFrame.new(mid):Inverse()
	return { center = CFrame.new(0, cy, cz), toRoot = toRoot, grip = grip, weld = nil }
end

local function eggOffset(values: { [string]: Clip.Value }): CFrame
	local e = values.Egg
	return if e then Clip.cframe(e, 1) else CFrame.identity
end

local function hands(f: Fit): { [string]: Mixer.HandFn }
	local out: { [string]: Mixer.HandFn } = {}
	for limb, point in f.grip do
		local side = if limb == "RHand" then 1 else -1
		out[limb] = function(ut: CFrame, values)
			local egg = ut * f.center * eggOffset(values)
			return (egg * point), egg.Rotation * Vector3.new(0.9 * side, -0.55, 0.35), nil
		end
	end
	return out
end

-- Welds `egg` (a BlockBuilder model, its parts unanchored) to the character's chest at its fitted spot; the clips
-- then move it with the hands. Returns false if the character has no torso yet.
function EggKick.attach(character: Model, egg: Model): boolean
	local f = fit(character, egg)
	local ut = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local root = egg.PrimaryPart
	if not f or not ut or not ut:IsA("BasePart") or not root then
		return false
	end
	local weld = Instance.new("Weld")
	weld.Name = "HoldWeld"
	weld.Part0, weld.Part1 = ut, root
	weld.C0 = f.center * f.toRoot
	weld.Parent = root
	f.weld = weld
	fits[character] = f
	egg:PivotTo(ut.CFrame * weld.C0)
	return true
end

-- Moves the welded egg with a layer's Egg channel (until `untilT`, clip time).
local function carry(character: Model, handle: Mixer.Handle, untilT: number?)
	handle.stepped(function(t, values, weight)
		local f = fits[character]
		local weld = f and f.weld
		if not f or not weld or not weld.Parent or (untilT and t >= untilT) or weight <= 0.001 then
			return
		end
		weld.C0 = f.center * CFrame.identity:Lerp(eggOffset(values), weight) * f.toRoot
	end)
end

-- Per-character layers (one hold, one brace).
local holds: { [Model]: Mixer.Handle } = setmetatable({}, { __mode = "k" }) :: any
local braces: { [Model]: Mixer.Handle } = setmetatable({}, { __mode = "k" }) :: any

-- The hold (a looping layer, hands on the egg if one is attached). Returns stop(fade?).
function EggKick.hold(character: Model): (fade: number?) -> ()
	local old = holds[character]
	if old and old.playing() then
		return old.stop
	end
	local f = fits[character]
	local h = Mixer.play(character, HOLD, {
		fadeIn = 0.3,
		priority = Mixer.PRIORITY.Action,
		hands = if f then hands(f) else nil,
		start = math.random() * 4,
	})
	carry(character, h)
	holds[character] = h
	return h.stop
end

-- The brace on top of the hold while the timing meter runs (crossfaded in and out).
function EggKick.brace(character: Model, on: boolean)
	local b = braces[character]
	if on then
		if b and b.playing() then
			b.setWeight(1, 0.25)
			return
		end
		local f = fits[character]
		b = Mixer.play(character, BRACE, {
			fadeIn = 0.25,
			priority = Mixer.PRIORITY.Action2,
			hands = if f then hands(f) else nil,
		})
		carry(character, b)
		braces[character] = b
	elseif b then
		b.stop(0.3)
		braces[character] = nil
	end
end

export type Playing = { stop: () -> (), releaseAt: number, contact: Vector3?, handle: Mixer.Handle }

-- Where the kicking foot's laces meet the egg at CONTACT, in the character's root space (this avatar's legs).
function EggKick.contactPoint(character: Model): Vector3?
	local body = Mixer.body(character)
	if not body or body.r6 then
		local root = character:FindFirstChild("HumanoidRootPart")
		return if root then Vector3.new(0.5, -1.6, -2) else nil
	end
	local chain = Body.fk(body, Mixer.evaluate(body, KICK, EggKick.CONTACT))
	local ankle = chain.RAnkle
	local foot = character:FindFirstChild("RightFoot")
	if not ankle or not foot or not foot:IsA("BasePart") then
		return nil
	end
	local part = ankle * body.joints.RAnkle.c1:Inverse()
	return (part * Vector3.new(0, foot.Size.Y / 2, -foot.Size.Z * 0.15))
end

-- Plays the kick so its CONTACT lands at server time `contactAt`; the hold and brace blend out under it.
function EggKick.play(character: Model, contactAt: number): Playing
	local untilContact = contactAt - workspace:GetServerTimeNow()
	local start, speed = 0, 1
	if untilContact >= EggKick.CONTACT then
		start = EggKick.CONTACT - untilContact -- early: hold the first frame (negative clip time) until it is due
	elseif untilContact > 0 then
		speed = math.min(EggKick.CONTACT / untilContact, EggKick.MAX_CATCH_UP)
		start = math.max(0, EggKick.CONTACT - untilContact * speed)
	else
		start = EggKick.CONTACT - untilContact
	end
	local f = fits[character]
	local h = Mixer.play(character, KICK, {
		fadeIn = 0.14,
		fadeOut = 0.4,
		priority = Mixer.PRIORITY.Action4,
		start = start,
		speed = speed,
		hands = if f then hands(f) else nil,
	})
	carry(character, h, EggKick.RELEASE)
	h.on("Contact", function()
		h.setSpeed(1)
	end)
	local hold, brace = holds[character], braces[character]
	if hold then
		hold.stop(0.18)
		holds[character] = nil
	end
	if brace then
		brace.stop(0.18)
		braces[character] = nil
	end
	local now = workspace:GetServerTimeNow()
	local releaseIn = (EggKick.RELEASE - start) / speed
	return {
		stop = function()
			h.stop(0.25)
		end,
		releaseAt = now + releaseIn,
		contact = EggKick.contactPoint(character),
		handle = h,
	}
end

-- Dev / showcase: holds `which` clip ("kick" | "hold" | "brace") frozen at clip time t on `character` (hands on
-- its attached egg). Returns the layer handle (setSpeed(1) to play on from there, stop() to release).
function EggKick.preview(character: Model, which: string, t: number): Mixer.Handle
	local clip = (EggKick.CLIPS :: any)[which] :: Clip.Compiled
	local f = fits[character]
	local h = Mixer.play(character, clip, {
		fadeIn = 0,
		fadeOut = 0,
		priority = Mixer.PRIORITY.Action4,
		start = t,
		speed = 0,
		hands = if f then hands(f) else nil,
	})
	carry(character, h, if which == "kick" then EggKick.RELEASE else nil)
	return h
end

-- The KeyframeSequence of a clip as this character's rig plays it (IK baked in), for the Animation Editor or
-- publishing: require(Shared.Anim.EggKick).bake(workspace.SomeRig, "kick").Parent = workspace
function EggKick.bake(character: Model, which: string, fps: number?): KeyframeSequence?
	local body = Mixer.body(character)
	local clip = (EggKick.CLIPS :: any)[which] :: Clip.Compiled?
	if not body or not clip then
		return nil
	end
	return require(script.Parent.Bake)(body, clip, fps or 60)
end

return EggKick
