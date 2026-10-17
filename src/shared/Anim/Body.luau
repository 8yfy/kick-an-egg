--!strict
-- Partner A. A character's real joints (R15 or R6, Motor6D or AnimationConstraint), measured from the rig itself,
-- plus the forward kinematics and two-bone IK that keep feet planted and hands on things for EVERY avatar
-- (proportions, Rthro, scale): nothing assumes a body size. Used by Anim/Mixer.
--
-- Clip values live in a joint's "own frame": the parent part's axes, rotating about the joint. A joint's
-- Transform is that rotation seen through its C0 (Transform = C0r^-1 * D * C0r), which is the identity map on
-- R15 (C0 has no rotation) and turns the R6 joints' tilted C0 frames into the same convention.
local Body = {}

export type Joint = {
	inst: Instance, -- Motor6D | AnimationConstraint
	c0: CFrame, -- joint pivot in the parent part (Motor6D.C0 / Attachment0.CFrame)
	c1: CFrame, -- joint pivot in the child part
	rot: CFrame, -- c0's rotation (conjugation)
	rotInv: CFrame,
}
export type Limb = { a: string, b: string, c: string, l1: number, l2: number, arm: boolean }
export type Body = {
	character: Model,
	r6: boolean,
	joints: { [string]: Joint },
	limbs: { [string]: Limb }, -- RFoot / LFoot / RHand / LHand (R15 only)
	scale: number, -- leg length / 2 studs: clip translations scale with the body
	rest: { [string]: Vector3 }, -- rest end-effector positions (ankle / wrist pivot) in root space
}

local R15: { [string]: { string } } = { -- joint = { part1, joint name }
	Root = { "LowerTorso", "Root" },
	Waist = { "UpperTorso", "Waist" },
	Neck = { "Head", "Neck" },
	RShoulder = { "RightUpperArm", "RightShoulder" },
	RElbow = { "RightLowerArm", "RightElbow" },
	RWrist = { "RightHand", "RightWrist" },
	LShoulder = { "LeftUpperArm", "LeftShoulder" },
	LElbow = { "LeftLowerArm", "LeftElbow" },
	LWrist = { "LeftHand", "LeftWrist" },
	RHip = { "RightUpperLeg", "RightHip" },
	RKnee = { "RightLowerLeg", "RightKnee" },
	RAnkle = { "RightFoot", "RightAnkle" },
	LHip = { "LeftUpperLeg", "LeftHip" },
	LKnee = { "LeftLowerLeg", "LeftKnee" },
	LAnkle = { "LeftFoot", "LeftAnkle" },
}
local R6: { [string]: { string } } = { -- joint = { part0, joint name }
	Root = { "HumanoidRootPart", "RootJoint" },
	Neck = { "Torso", "Neck" },
	RShoulder = { "Torso", "Right Shoulder" },
	LShoulder = { "Torso", "Left Shoulder" },
	RHip = { "Torso", "Right Hip" },
	LHip = { "Torso", "Left Hip" },
}
Body.LIMBS = {
	RFoot = { "RHip", "RKnee", "RAnkle" },
	LFoot = { "LHip", "LKnee", "LAnkle" },
	RHand = { "RShoulder", "RElbow", "RWrist" },
	LHand = { "LShoulder", "LElbow", "LWrist" },
}
Body.PARENT = { -- the joint whose child part a joint's pivot sits on (FK chain)
	Waist = "Root",
	Neck = "Waist",
	RShoulder = "Waist",
	LShoulder = "Waist",
	RElbow = "RShoulder",
	LElbow = "LShoulder",
	RWrist = "RElbow",
	LWrist = "LElbow",
	RHip = "Root",
	LHip = "Root",
	RKnee = "RHip",
	LKnee = "LHip",
	RAnkle = "RKnee",
	LAnkle = "LKnee",
}

local function pivots(inst: Instance): (CFrame?, CFrame?)
	if inst:IsA("Motor6D") then
		return inst.C0, inst.C1
	elseif inst:IsA("AnimationConstraint") then
		local a0, a1 = inst.Attachment0, inst.Attachment1
		if a0 and a1 then
			return a0.CFrame, a1.CFrame
		end
	end
	return nil, nil
end

local function find(character: Model, partName: string, jointName: string): Instance?
	local part = character:FindFirstChild(partName)
	local j = part and part:FindFirstChild(jointName)
	if j and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then
		return j
	end
	return nil
end

-- Measures the character's rig. nil when it has no recognisable joints yet (streaming, loading).
function Body.bind(character: Model): Body?
	local r6 = character:FindFirstChild("Torso") ~= nil and character:FindFirstChild("UpperTorso") == nil
	local joints: { [string]: Joint } = {}
	for name, info in if r6 then R6 else R15 do
		local inst = find(character, info[1], info[2])
		if inst then
			local c0, c1 = pivots(inst)
			if c0 and c1 then
				local rot = c0.Rotation
				joints[name] = { inst = inst, c0 = c0, c1 = c1, rot = rot, rotInv = rot:Inverse() }
			end
		end
	end
	if not joints.Root then
		return nil
	end
	local body: Body = { character = character, r6 = r6, joints = joints, limbs = {}, scale = 1, rest = {} }
	if not r6 then
		for limb, names in Body.LIMBS do
			local a, b, c = joints[names[1]], joints[names[2]], joints[names[3]]
			if a and b and c then
				body.limbs[limb] = {
					a = names[1],
					b = names[2],
					c = names[3],
					l1 = (b.c0.Position - a.c1.Position).Magnitude,
					l2 = (c.c0.Position - b.c1.Position).Magnitude,
					arm = limb == "RHand" or limb == "LHand",
				}
			end
		end
		local leg = body.limbs.RFoot
		if leg then
			body.scale = (leg.l1 + leg.l2) / 1.75 -- (a classic R15 leg is about 1.75 studs hip to ankle)
		end
		local rest = Body.fk(body, {})
		for limb, l in body.limbs do
			body.rest[limb] = rest[l.c].Position
		end
	end
	return body
end

-- Joint value (own frame) -> Transform.
function Body.toTransform(j: Joint, d: CFrame): CFrame
	return j.rotInv * d * j.rot
end

-- Transform -> joint value (own frame).
function Body.fromTransform(j: Joint, t: CFrame): CFrame
	return j.rot * t * j.rotInv
end

-- Forward kinematics (R15): every joint's pivot frame in root (HumanoidRootPart) space for the given
-- Transforms (missing = identity). The frame of joint X is its parent part's frame moved to the pivot, after the
-- joint's own rotation (so frame.Rotation is the child part's rotation, frame.Position the pivot).
function Body.fk(body: Body, transforms: { [string]: CFrame }): { [string]: CFrame }
	local out: { [string]: CFrame } = {}
	local parts: { [string]: CFrame } = {} -- joint -> its child part's CFrame (root space)
	local function solve(name: string): CFrame?
		if parts[name] then
			return parts[name]
		end
		local j = body.joints[name]
		if not j then
			return nil
		end
		local parentName = Body.PARENT[name]
		local parentPart = if parentName then solve(parentName) else CFrame.identity
		if not parentPart then
			return nil
		end
		local t = transforms[name] or CFrame.identity
		local pivot = parentPart * j.c0 * t
		out[name] = pivot
		local part = pivot * j.c1:Inverse()
		parts[name] = part
		return part
	end
	for name in body.joints do
		solve(name)
	end
	return out
end

-- Two-bone IK in root space: puts limb's end pivot on `target` (clamped to its reach), the middle joint bending
-- toward `hint`, the end part turned to `endRot` (root-space rotation; nil keeps it in line with the forearm /
-- shin). `chain` = Body.fk of the final pose (it places the limb's base: LowerTorso / UpperTorso). Writes the
-- three joint Transforms into `into`.
function Body.solve(
	body: Body,
	limbName: string,
	chain: { [string]: CFrame },
	target: Vector3,
	hint: Vector3,
	endRot: CFrame?,
	into: { [string]: CFrame }
)
	local limb = body.limbs[limbName]
	if not limb then
		return
	end
	local ja, jb, jc = body.joints[limb.a], body.joints[limb.b], body.joints[limb.c]
	local parentName = Body.PARENT[limb.a] :: string
	-- the limb's base part (LowerTorso for legs, UpperTorso for arms) in root space
	local parentPivot = chain[parentName]
	local parentJoint = body.joints[parentName]
	if not parentPivot or not parentJoint then
		return
	end
	local base = parentPivot * parentJoint.c1:Inverse()
	local origin = (base * ja.c0).Position
	local l1, l2 = limb.l1, limb.l2
	local v = target - origin
	local d = math.clamp(v.Magnitude, math.abs(l1 - l2) + 1e-3, (l1 + l2) * 0.9995)
	local vhat = if v.Magnitude > 1e-4 then v.Unit else -Vector3.yAxis
	local k = hint - vhat * hint:Dot(vhat)
	local khat = if k.Magnitude > 1e-4 then k.Unit else base.LookVector
	local cosA = math.clamp((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d), -1, 1)
	local sinA = math.sqrt(1 - cosA * cosA)
	local u = vhat * cosA + khat * sinA -- upper segment direction
	local mid = origin + u * l1
	local s = ((origin + vhat * d) - mid).Unit -- lower segment direction
	-- hinge axis: knees bend backward, elbows forward (R15's +X stays +X at rest)
	local x = if limb.arm then khat:Cross(vhat).Unit else vhat:Cross(khat).Unit
	local function frame(dir: Vector3): CFrame
		local y = -dir
		return CFrame.fromMatrix(Vector3.zero, x, y, x:Cross(y))
	end
	local upper, lower = frame(u), frame(s)
	local baseRot = base.Rotation
	into[limb.a] = Body.toTransform(ja, baseRot:Inverse() * upper)
	into[limb.b] = Body.toTransform(jb, upper:Inverse() * lower)
	into[limb.c] = Body.toTransform(jc, if endRot then lower:Inverse() * endRot else CFrame.identity)
end

return Body
