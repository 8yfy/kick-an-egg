--!strict
-- Partner A. Player poses. PlayerCarry holds both arms overhead (R15 and R6). The Animator rewrites
-- joint Transforms every frame, so the pose is written in RunService.Stepped (after animation,
-- before physics). Works for Motor6D and the newer AnimationConstraint avatar joints alike.
local RunService = game:GetService("RunService")

local Player = {}

local function joint(char: Model, partName: string, jointName: string): Instance?
	local part = char:FindFirstChild(partName)
	local j = part and part:FindFirstChild(jointName)
	return if j and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then j else nil
end

function Player.PlayerCarry(char: Model, _params: { [string]: any }): () -> ()
	local isR6 = char:FindFirstChild("Torso") ~= nil
	local r = joint(char, "RightUpperArm", "RightShoulder") or joint(char, "Torso", "Right Shoulder")
	local l = joint(char, "LeftUpperArm", "LeftShoulder") or joint(char, "Torso", "Left Shoulder")
	-- R15 arms hang along -Y: ~170 deg about X points them up (slightly forward and outward).
	-- R6 shoulders swing about the joint's Z axis (mirrored on the left).
	local poseR = if isR6 then CFrame.Angles(0, 0, math.rad(170)) else CFrame.Angles(math.rad(170), 0, math.rad(-12))
	local poseL = if isR6 then CFrame.Angles(0, 0, math.rad(-170)) else CFrame.Angles(math.rad(170), 0, math.rad(12))
	local conn = RunService.Stepped:Connect(function()
		if r then
			(r :: any).Transform = poseR
		end
		if l then
			(l :: any).Transform = poseL
		end
	end)
	return function()
		conn:Disconnect()
	end
end

-- Kick Sack front kick (Partner B; storyboard on the sack design canvas). Fighting-game timing:
--   0.00 ready (guard up) -> 0.16 chamber (knee high, lean back) -> hold to 0.20 -> 0.26 snap (3 frames,
--   the sole drives into the bag, arms counter-swing) -> hit-stop to 0.30 -> 0.40 recoil back through the
--   chamber -> 0.52 the foot lands -> 0.60 the arms settle a beat after the legs.
-- Poses are joint -> { pitch, yaw, roll (degrees), lift (studs) } in each joint's own frame (R15:
-- +pitch swings a limb forward / leans the torso back; R6 maps the hips and shoulders only).
type Pose = { [string]: { number } }
type Key = { t: number, ease: string, pose: Pose }
export type Rig = { joints: { [string]: Instance }, mirror: { [string]: number }, r6: boolean }

Player.KICK_IMPACT = 0.26
Player.KICK_LENGTH = 0.6

local READY_LEGS: Pose = {
	Root = { 0, 0, 0, -0.14 },
	Waist = { -6, 0, 0 },
	Neck = { 6, 0, 0 },
	RHip = { 20, 0, 0 },
	RKnee = { -40, 0, 0 },
	RAnkle = { 20, 0, 0 },
	LHip = { 20, 0, 0 },
	LKnee = { -40, 0, 0 },
	LAnkle = { 20, 0, 0 },
}
local CHAMBER_LEGS: Pose = {
	Root = { 8, 0, 0, 0 },
	Waist = { 6, 0, 0 },
	Neck = { -12, 0, 0 },
	RHip = { 92, 0, 0 },
	RKnee = { -115, 0, 0 },
	RAnkle = { 10, 0, 0 },
	LHip = { 2, 0, 0 },
	LKnee = { -20, 0, 0 },
	LAnkle = { 10, 0, 0 },
}
local SNAP_LEGS: Pose = {
	Root = { 16, 0, 0, 0.02 },
	Waist = { 8, 0, 0 },
	Neck = { -20, 0, 0 },
	RHip = { 80, 0, 0 },
	RKnee = { -2, 0, 0 },
	RAnkle = { 0, 0, 0 },
	LHip = { -10, 0, 0 },
	LKnee = { -12, 0, 0 },
	LAnkle = { 6, 0, 0 },
}
local RECOIL_LEGS: Pose = {
	Root = { 8, 0, 0, 0 },
	Waist = { 4, 0, 0 },
	Neck = { -10, 0, 0 },
	RHip = { 88, 0, 0 },
	RKnee = { -110, 0, 0 },
	RAnkle = { 10, 0, 0 },
	LHip = { 2, 0, 0 },
	LKnee = { -20, 0, 0 },
	LAnkle = { 10, 0, 0 },
}
local READY_ARMS: Pose = {
	RShoulder = { 40, 0, -6 },
	RElbow = { 105, 0, 0 },
	LShoulder = { 45, 0, 6 },
	LElbow = { 110, 0, 0 },
}
local CHAMBER_ARMS: Pose = {
	RShoulder = { 50, 0, -10 },
	RElbow = { 115, 0, 0 },
	LShoulder = { 55, 0, 10 },
	LElbow = { 115, 0, 0 },
}
local SNAP_ARMS: Pose = {
	RShoulder = { -35, 0, 20 },
	RElbow = { 35, 0, 0 },
	LShoulder = { 70, 0, 15 },
	LElbow = { 70, 0, 0 },
}
local RECOIL_ARMS: Pose = {
	RShoulder = { 20, 0, 0 },
	RElbow = { 80, 0, 0 },
	LShoulder = { 55, 0, 10 },
	LElbow = { 100, 0, 0 },
}

local LEG_KEYS: { Key } = {
	{ t = 0, ease = "linear", pose = READY_LEGS },
	{ t = 0.16, ease = "out", pose = CHAMBER_LEGS },
	{ t = 0.2, ease = "linear", pose = CHAMBER_LEGS },
	{ t = 0.26, ease = "in", pose = SNAP_LEGS },
	{ t = 0.3, ease = "linear", pose = SNAP_LEGS },
	{ t = 0.4, ease = "out", pose = RECOIL_LEGS },
	{ t = 0.52, ease = "inout", pose = READY_LEGS },
}
local ARM_KEYS: { Key } = {
	{ t = 0, ease = "linear", pose = READY_ARMS },
	{ t = 0.16, ease = "out", pose = CHAMBER_ARMS },
	{ t = 0.2, ease = "linear", pose = CHAMBER_ARMS },
	{ t = 0.26, ease = "in", pose = SNAP_ARMS },
	{ t = 0.3, ease = "linear", pose = SNAP_ARMS },
	{ t = 0.42, ease = "out", pose = RECOIL_ARMS },
	{ t = 0.6, ease = "inout", pose = READY_ARMS },
}
Player.KICK_KEYS = { legs = LEG_KEYS, arms = ARM_KEYS } -- also baked into the Blender preview

local R15_JOINTS: { [string]: { string } } = {
	Root = { "LowerTorso", "Root" },
	Waist = { "UpperTorso", "Waist" },
	Neck = { "Head", "Neck" },
	RHip = { "RightUpperLeg", "RightHip" },
	RKnee = { "RightLowerLeg", "RightKnee" },
	RAnkle = { "RightFoot", "RightAnkle" },
	LHip = { "LeftUpperLeg", "LeftHip" },
	LKnee = { "LeftLowerLeg", "LeftKnee" },
	LAnkle = { "LeftFoot", "LeftAnkle" },
	RShoulder = { "RightUpperArm", "RightShoulder" },
	RElbow = { "RightLowerArm", "RightElbow" },
	LShoulder = { "LeftUpperArm", "LeftShoulder" },
	LElbow = { "LeftLowerArm", "LeftElbow" },
}
-- R6 swings hips / shoulders about the joint's Z axis, mirrored on the left.
local R6_JOINTS: { [string]: { any } } = {
	RHip = { "Right Hip", 1 },
	LHip = { "Left Hip", -1 },
	RShoulder = { "Right Shoulder", 1 },
	LShoulder = { "Left Shoulder", -1 },
}

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

local function sample(keys: { Key }, t: number, into: Pose)
	local prev, nxt = keys[1], keys[#keys]
	for i = 2, #keys do
		if t <= keys[i].t then
			prev, nxt = keys[i - 1], keys[i]
			break
		end
	end
	local span = nxt.t - prev.t
	local a = if span > 0 then ease(nxt.ease, math.clamp((t - prev.t) / span, 0, 1)) else 1
	for name, from in prev.pose do
		local to = nxt.pose[name] or from
		into[name] = {
			from[1] + (to[1] - from[1]) * a,
			from[2] + (to[2] - from[2]) * a,
			from[3] + (to[3] - from[3]) * a,
			(from[4] or 0) + ((to[4] or 0) - (from[4] or 0)) * a,
		}
	end
end

-- Kick pose `t` seconds into the kick (clamped to the last frame).
function Player.kickPose(t: number): Pose
	local pose: Pose = {}
	sample(LEG_KEYS, t, pose)
	sample(ARM_KEYS, t, pose)
	return pose
end

-- Fighting stance between kicks: guard up, knees soft, a light bounce on the balls of the feet.
function Player.guardPose(clock: number): Pose
	local pose = Player.kickPose(0)
	local bob = math.sin(clock * math.pi * 2 * 1.6)
	local root = pose.Root
	root[4] = (root[4] or 0) + bob * 0.04
	for _, n in { "RKnee", "LKnee" } do
		pose[n][1] += bob * 3
	end
	for _, n in { "RHip", "LHip", "RAnkle", "LAnkle" } do
		pose[n][1] -= bob * 1.5
	end
	return pose
end

function Player.rig(char: Model): Rig
	local joints, mirror = {}, {}
	local r6 = char:FindFirstChild("Torso") ~= nil
	if r6 then
		for name, info in R6_JOINTS do
			local j = joint(char, "Torso", info[1])
			if j then
				joints[name], mirror[name] = j, info[2]
			end
		end
	else
		for name, info in R15_JOINTS do
			local j = joint(char, info[1], info[2])
			if j then
				joints[name] = j
			end
		end
	end
	return { joints = joints, mirror = mirror, r6 = r6 }
end

-- Writes a pose (call from RunService.Stepped, after the Animator).
function Player.apply(rig: Rig, pose: Pose)
	for name, j in rig.joints do
		local p = pose[name]
		if p then
			local cf = if rig.r6
				then CFrame.Angles(0, 0, math.rad(p[1]) * rig.mirror[name])
				else CFrame.new(0, p[4] or 0, 0) * CFrame.Angles(math.rad(p[1]), math.rad(p[2]), math.rad(p[3]));
			(j :: any).Transform = cf
		end
	end
end

-- One-shot kick (0.6 s). The Kick Sack controller drives the same poses itself per character.
function Player.PlayerKick(char: Model, _params: { [string]: any }): () -> ()
	local rig = Player.rig(char)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Stepped:Connect(function()
		local t = os.clock() - t0
		if t > Player.KICK_LENGTH or not char.Parent then
			conn:Disconnect()
			return
		end
		Player.apply(rig, Player.kickPose(t))
	end)
	return function()
		conn:Disconnect()
	end
end

return Player
