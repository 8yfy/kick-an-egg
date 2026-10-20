-- Unpublished, single-player Studio diagnostic. Set LocalPlayer.ShiftLockQAMode to "baseline", "smooth", or "handoff",
-- insert as LocalScript into PlayerScripts, then press Shift twice. Result: ShiftLockQA_<mode>.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0)
local P = game.Players.LocalPlayer
local U = game:GetService("UserInputService")
local R = game:GetService("RunService")
local H = game:GetService("HttpService")
local controller = require(P.PlayerScripts.Client.Controllers.ShiftLockController)
local mode = P:GetAttribute("ShiftLockQAMode") or "smooth"
if mode == "handoff" then
	controller:Start()
	local connection
	connection = U.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.LeftShift then
			return
		end
		connection:Disconnect()
		task.delay(0.06, function()
			local cam = workspace.CurrentCamera
			local kind, cf, focus, subject = cam.CameraType, cam.CFrame, cam.Focus, cam.CameraSubject
			local error = 0
			cam.CameraType = Enum.CameraType.Scriptable
			R:BindToRenderStep("ShiftLockQAHandoff", Enum.RenderPriority.Camera.Value + 4, function()
				error = math.max(error, (cam.CFrame.Position - cf.Position).Magnitude)
			end)
			task.delay(0.4, function()
				R:UnbindFromRenderStep("ShiftLockQAHandoff")
				P:SetAttribute(
					"ShiftLockQA_handoff",
					H:JSONEncode({ error = error, keptScriptable = cam.CameraType == Enum.CameraType.Scriptable })
				)
				cam.CameraType, cam.CameraSubject, cam.CFrame, cam.Focus = kind, subject, cf, focus
				script:Destroy()
			end)
		end)
	end)
	return
end
if mode == "baseline" then
	controller:Destroy()
else
	controller:Start()
end
local old = workspace.CurrentCamera.CFrame
local oldMouse = U.MouseBehavior
local window = 0
local pitchAtShift = math.asin(old.LookVector.Y)
local stats = {
	inputs = 0,
	transitions = 0,
	maxStationaryLateralStep = 0,
	maxVerticalStep = 0,
	maxPitchStep = 0,
	maxPitchDeparture = 0,
	maxAngle = 0,
	states = {},
}
local input = U.InputBegan:Connect(function(i)
	if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.RightShift then
		stats.inputs += 1
		window = os.clock() + 0.35
		pitchAtShift = math.asin(old.LookVector.Y)
	end
end)
R:BindToRenderStep("ShiftLockQAMeasure_" .. mode, Enum.RenderPriority.Camera.Value + 3, function()
	local cf = workspace.CurrentCamera.CFrame
	local angle = math.deg(math.acos(math.clamp(cf.LookVector:Dot(old.LookVector), -1, 1)))
	local mouse = U.MouseBehavior
	stats.states[mouse.Name] = true
	if mouse ~= oldMouse then
		stats.transitions += 1
	end
	if os.clock() < window then
		stats.maxAngle = math.max(stats.maxAngle, angle)
		local pitch = math.asin(math.clamp(cf.LookVector.Y, -1, 1))
		local oldPitch = math.asin(math.clamp(old.LookVector.Y, -1, 1))
		-- Keep recentering rotations in these metrics; excluding them hid the upward snap.
		stats.maxPitchStep = math.max(stats.maxPitchStep, math.deg(math.abs(pitch - oldPitch)))
		stats.maxPitchDeparture = math.max(stats.maxPitchDeparture, math.deg(math.abs(pitch - pitchAtShift)))
		stats.maxVerticalStep = math.max(stats.maxVerticalStep, math.abs(cf.Position.Y - old.Position.Y))
		-- Ignore mouse-look/recentering performed by test input tools; measure the stationary shoulder step.
		if angle < 0.5 and mouse ~= Enum.MouseBehavior.LockCurrentPosition then
			stats.maxStationaryLateralStep =
				math.max(stats.maxStationaryLateralStep, math.abs((cf.Position - old.Position):Dot(cf.RightVector)))
		end
	end
	old, oldMouse = cf, mouse
	P:SetAttribute("ShiftLockQA_" .. mode, H:JSONEncode(stats))
end)
task.delay(7, function()
	R:UnbindFromRenderStep("ShiftLockQAMeasure_" .. mode)
	input:Disconnect()
	controller:Start()
	script:Destroy()
end)
