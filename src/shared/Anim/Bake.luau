--!strict
-- Partner A. Bakes an Anim/Clip into a KeyframeSequence exactly as Anim/Mixer plays it on one measured body (leg IK
-- included), sampled densely with linear easing so the curves survive unchanged, plus a KeyframeMarker per clip
-- marker. For the Animation Editor (open it on that rig), Moon / Blender round trips or publishing. Dev only: the
-- game itself plays the clips through Anim/Mixer on every avatar.
local Body = require(script.Parent.Body)
local Clip = require(script.Parent.Clip)
local Mixer = require(script.Parent.Mixer)

local R15_PARENT = { -- pose (part) -> parent pose
	LowerTorso = "HumanoidRootPart",
	UpperTorso = "LowerTorso",
	Head = "UpperTorso",
	RightUpperArm = "UpperTorso",
	RightLowerArm = "RightUpperArm",
	RightHand = "RightLowerArm",
	LeftUpperArm = "UpperTorso",
	LeftLowerArm = "LeftUpperArm",
	LeftHand = "LeftLowerArm",
	RightUpperLeg = "LowerTorso",
	RightLowerLeg = "RightUpperLeg",
	RightFoot = "RightLowerLeg",
	LeftUpperLeg = "LowerTorso",
	LeftLowerLeg = "LeftUpperLeg",
	LeftFoot = "LeftLowerLeg",
}
local R6_PARENT = {
	Torso = "HumanoidRootPart",
	Head = "Torso",
	["Right Arm"] = "Torso",
	["Left Arm"] = "Torso",
	["Right Leg"] = "Torso",
	["Left Leg"] = "Torso",
}

local function childPart(j: Body.Joint): string
	local inst = j.inst :: any
	if inst:IsA("Motor6D") then
		return inst.Part1 and inst.Part1.Name or ""
	end
	local a1 = inst.Attachment1
	return a1 and a1.Parent and a1.Parent.Name or ""
end

return function(body: Body.Body, clip: Clip.Compiled, fps: number): KeyframeSequence
	local seq = Instance.new("KeyframeSequence")
	seq.Name = clip.name
	seq.Loop = clip.loop
	seq.Priority = Enum.AnimationPriority.Action4
	local parents = if body.r6 then R6_PARENT else R15_PARENT
	local frames = math.max(1, math.floor(clip.length * fps + 0.5))
	for i = 0, frames do
		local t = math.min(i / fps, clip.length)
		local transforms = Mixer.evaluate(body, clip, t)
		local kf = Instance.new("Keyframe")
		kf.Time = t
		local poses: { [string]: Pose } = {}
		local function poseFor(part: string): Pose
			local p = poses[part]
			if p then
				return p
			end
			local np = Instance.new("Pose")
			np.Name = part
			np.Weight = if part == "HumanoidRootPart" then 0 else 1
			np.EasingStyle = Enum.PoseEasingStyle.Linear
			local parent = parents[part]
			np.Parent = if parent then poseFor(parent) else kf
			poses[part] = np
			return np
		end
		for name, j in body.joints do
			poseFor(childPart(j)).CFrame = transforms[name] or CFrame.identity
		end
		kf.Parent = seq
	end
	-- markers on the keyframe at (or just after) their time
	for _, m in clip.markers do
		local best: Keyframe? = nil
		for _, kf in seq:GetChildren() do
			if kf:IsA("Keyframe") and kf.Time >= m.t - 1e-6 and (not best or kf.Time < best.Time) then
				best = kf
			end
		end
		if best then
			local marker = Instance.new("KeyframeMarker")
			marker.Name = m.name
			marker.Parent = best
		end
	end
	return seq
end
