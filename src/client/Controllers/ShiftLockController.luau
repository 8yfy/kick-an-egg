--!strict
-- Ignore cursor-recentering deltas during Shift Lock handoff, and ease the shoulder offset.
-- Roblox keeps ownership of the mouse, character controls and camera subject.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local GameSettings = UserSettings():GetService("UserGameSettings")

local ShiftLockController = {}
local UNDO, APPLY = "KickTheEggShiftLockUndo", "KickTheEggShiftLock"
local DURATION = 0.25
local CURSOR_HANDOFF_SECONDS = 0.12
local started = false
local rotationChanged: RBXScriptConnection? = nil
local sensitivityBeforeHandoff: number? = nil
local handoffSequence = 0
local appliedCamera: Camera? = nil
local appliedSubject: Instance? = nil
local applied = Vector3.zero
local written: CFrame? = nil
local writtenFocus: CFrame? = nil

local function followCamera(): (Camera?, Humanoid?)
	local player = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	if
		not cam
		or not humanoid
		or not root
		or humanoid.Health <= 0
		or game:GetService("VRService").VREnabled
		or cam.CameraType ~= Enum.CameraType.Custom
		or cam.CameraSubject ~= humanoid
		or (cam.CFrame.Position - cam.Focus.Position).Magnitude < 1
	then
		return nil, nil
	end
	return cam, humanoid
end

local function restoreInput()
	local saved = sensitivityBeforeHandoff
	sensitivityBeforeHandoff = nil
	-- Preserve the previous value exactly; let another input system take ownership if it changed it.
	if saved ~= nil and Input.MouseDeltaSensitivity == 0 then
		Input.MouseDeltaSensitivity = saved
	end
end

local function protectCursorHandoff()
	if not followCamera() then
		return
	end
	handoffSequence += 1
	local sequence = handoffSequence
	if sensitivityBeforeHandoff == nil then
		sensitivityBeforeHandoff = Input.MouseDeltaSensitivity
	end
	-- Native cursor warps can arrive several frames after locking. Suppress their relative
	-- input before Roblox's camera/collision update, without rewriting the viewing angle.
	Input.MouseDeltaSensitivity = 0
	task.delay(CURSOR_HANDOFF_SECONDS, function()
		if sequence == handoffSequence then
			restoreInput()
		end
	end)
end

local function undo()
	local cam = appliedCamera
	if
		cam
		and cam.Parent
		and cam.CameraType == Enum.CameraType.Custom
		and cam.CameraSubject == appliedSubject
		and written
		and cam.CFrame == written
	then
		cam.CFrame -= applied
		if writtenFocus and cam.Focus == writtenFocus then
			cam.Focus -= applied
		end
	end
	appliedCamera, written, writtenFocus = nil, nil, nil
	appliedSubject = nil
	applied = Vector3.zero
end

function ShiftLockController:Start()
	if started then
		return
	end
	started = true
	rotationChanged = GameSettings:GetPropertyChangedSignal("RotationType"):Connect(protectCursorHandoff)
	local lastCamera: Camera? = nil
	local lastSubject: Instance? = nil
	local lastOutput: CFrame? = nil
	local lastLocked: boolean? = nil
	local shoulder, began = 0, 0
	-- Undo before the normal camera (and before VFX shake undo), so smoothing cannot accumulate.
	RunService:BindToRenderStep(UNDO, Enum.RenderPriority.Camera.Value - 2, undo)
	RunService:BindToRenderStep(APPLY, Enum.RenderPriority.Camera.Value + 2, function()
		local cam, humanoid = followCamera()
		if not cam or not humanoid then
			restoreInput()
			lastCamera, lastSubject, lastOutput, lastLocked = nil, nil, nil, nil
			shoulder = 0
			return
		end
		local raw = cam.CFrame
		-- The default BaseCamera sets this for Shift Lock. Unlike MouseBehavior it does not
		-- toggle during ordinary right-mouse camera dragging or when a menu releases the cursor.
		local locked = GameSettings.RotationType == Enum.RotationType.CameraRelative
		if
			lastCamera == cam
			and lastSubject == humanoid
			and lastOutput
			and lastLocked ~= nil
			and locked ~= lastLocked
		then
			-- Only compensate the lateral step. Mouse look, zoom, forward motion and collisions remain live.
			local jump = (lastOutput.Position - raw.Position):Dot(raw.RightVector)
			shoulder = if math.abs(jump) <= 3.5 then jump else 0
			began = os.clock()
		end
		lastCamera, lastSubject, lastLocked = cam, humanoid, locked
		local alpha = math.clamp((os.clock() - began) / DURATION, 0, 1)
		if alpha < 1 and math.abs(shoulder) > 0.001 then
			local eased = alpha * alpha * (3 - 2 * alpha)
			applied = raw.RightVector * shoulder * (1 - eased)
			cam.CFrame, cam.Focus = raw + applied, cam.Focus + applied
			appliedCamera, written, writtenFocus = cam, cam.CFrame, cam.Focus
			appliedSubject = cam.CameraSubject
		end
		lastOutput = cam.CFrame
	end)
end

function ShiftLockController:Destroy()
	if rotationChanged then
		rotationChanged:Disconnect()
		rotationChanged = nil
	end
	handoffSequence += 1
	restoreInput()
	RunService:UnbindFromRenderStep(UNDO)
	RunService:UnbindFromRenderStep(APPLY)
	undo()
	started = false
end

return ShiftLockController
