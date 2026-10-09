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

return Player
