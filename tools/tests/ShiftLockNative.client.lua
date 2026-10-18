-- Unpublished Studio-only native cursor trace. Use real desktop Shift input with the cursor off centre.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0)
local p = game.Players.LocalPlayer
local U = game:GetService("UserInputService")
local R = game:GetService("RunService")
local H = game:GetService("HttpService")
local G = UserSettings():GetService("UserGameSettings")
local cameraModule = p.PlayerScripts.PlayerModule.CameraModule
local inputModule = require(cameraModule.CameraInput)
local classic = require(cameraModule.ClassicCamera)
local oldRotation = inputModule.getRotation
local oldUpdate = classic.Update
local events = {}
local active
local rawPitch, rotation
local beforeYaw = math.atan2(-workspace.CurrentCamera.CFrame.LookVector.X, -workspace.CurrentCamera.CFrame.LookVector.Z)
local beforePitch = math.deg(math.asin(workspace.CurrentCamera.CFrame.LookVector.Y))
local function angle(cf)
	return math.deg(math.asin(math.clamp(cf.LookVector.Y, -1, 1)))
end
local rotationHook = function(...)
	local result = oldRotation(...)
	rotation = { result.X, result.Y }
	return result
end
local updateHook = function(self, ...)
	local cf, focus = oldUpdate(self, ...)
	rawPitch = angle(cf)
	return cf, focus
end
inputModule.getRotation = rotationHook
classic.Update = updateHook
local key = U.InputBegan:Connect(function(i, gp)
	if i.KeyCode == Enum.KeyCode.LeftShift then
		active = {
			start = os.clock(),
			beforePitch = beforePitch,
			beforeYaw = beforeYaw,
			beforeMouse = U.MouseBehavior.Name,
			beforeRotation = G.RotationType.Name,
			mousePosition = tostring(U:GetMouseLocation()),
			frames = {},
			inputs = {},
		}
		table.insert(events, active)
	end
end)
local moves = U.InputChanged:Connect(function(i)
	if active and os.clock() - active.start < 1.2 and i.UserInputType == Enum.UserInputType.MouseMovement then
		table.insert(active.inputs, {
			t = os.clock() - active.start,
			delta = { i.Delta.X, i.Delta.Y },
			position = { i.Position.X, i.Position.Y },
		})
	end
end)
R:BindToRenderStep("ShiftLockNativeProbe", Enum.RenderPriority.Camera.Value + 4, function()
	local cam = workspace.CurrentCamera
	local now = os.clock()
	local pitch = angle(cam.CFrame)
	if active and now - active.start < 1.2 then
		local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		table.insert(active.frames, {
			t = now - active.start,
			pitch = pitch,
			yaw = math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z),
			sensitivity = U.MouseDeltaSensitivity,
			rawPitch = rawPitch,
			rotation = rotation,
			mode = U.MouseBehavior.Name,
			rotationType = G.RotationType.Name,
			y = cam.CFrame.Y,
			focusY = cam.Focus.Y,
			distance = (cam.CFrame.Position - cam.Focus.Position).Magnitude,
			health = h and h.Health,
			VR = game:GetService("VRService").VREnabled,
		})
		p:SetAttribute("ShiftLockNativeProbe", H:JSONEncode(events))
	end
	beforePitch = pitch
	beforeYaw = math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z)
end)
local finish = Instance.new("BindableEvent")
finish.Name = "Finish"
finish.Parent = script
local done = false
local function cleanup()
	if done then
		return
	end
	done = true
	R:UnbindFromRenderStep("ShiftLockNativeProbe")
	key:Disconnect()
	moves:Disconnect()
	if inputModule.getRotation == rotationHook then
		inputModule.getRotation = oldRotation
	end
	if classic.Update == updateHook then
		classic.Update = oldUpdate
	end
	p:SetAttribute("ShiftLockNativeProbe", H:JSONEncode(events))
	script:Destroy()
end
finish.Event:Connect(cleanup)
task.delay(180, cleanup)
