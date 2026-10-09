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

-- One-shot kick with the right leg (training rack): wind back, snap forward, recover. ~0.4 s.
function Player.PlayerKick(char: Model, _params: { [string]: any }): () -> ()
	local isR6 = char:FindFirstChild("Torso") ~= nil
	local hip = joint(char, "RightUpperLeg", "RightHip") or joint(char, "Torso", "Right Hip")
	local knee = joint(char, "RightLowerLeg", "RightKnee")
	if not hip then
		return function() end
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.Stepped:Connect(function()
		local t = os.clock() - t0
		if t > 0.42 then
			conn:Disconnect()
			return
		end
		-- angle curve: 0 -> -25 deg (wind back) -> +95 deg (kick) -> 0
		local a
		if t < 0.1 then
			a = -25 * (t / 0.1)
		elseif t < 0.2 then
			a = -25 + 120 * ((t - 0.1) / 0.1)
		else
			a = 95 * (1 - (t - 0.2) / 0.22)
		end
		local r = math.rad(a);
		(hip :: any).Transform = if isR6 then CFrame.Angles(0, 0, r) else CFrame.Angles(r, 0, 0)
		if knee then
			(knee :: any).Transform = CFrame.Angles(-math.rad(math.max(0, 40 - math.abs(a - 30))), 0, 0)
		end
	end)
	return function()
		conn:Disconnect()
	end
end

return Player
