-- Offline regression: runs the production controller with Lune's Roblox CFrame types.
-- lune run tools/tests/ShiftLock.spec.luau [optional-controller-source]
-- The camera/input services are deterministic fixtures; real cursor input still needs Studio QA.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local source = fs.readFile(process.args[1] or "src/client/Controllers/ShiftLockController.luau")
local checks = 0
local function close(actual, expected, label, tolerance)
	assert(math.abs(actual - expected) < (tolerance or 0.0001), `{label}: expected {expected}, got {actual}`)
	checks += 1
end
local function fixture()
	local now, bindings, timers, listeners = 0, {}, {}, {}
	local root = {
		IsA = function(_, className)
			return className == "BasePart"
		end,
	}
	local humanoid = { RootPart = root, Health = 100 }
	local character = {
		FindFirstChildOfClass = function()
			return humanoid
		end,
		FindFirstChild = function(_, name)
			return if name == "HumanoidRootPart" then root else nil
		end,
	}
	local player = {
		Character = character,
		GetAttribute = function()
			return nil
		end,
	}
	local cam = { Parent = true, CameraType = "Custom", CameraSubject = humanoid }
	local rotation = "MovementRelative"
	local settings = setmetatable({}, {
		__index = function(_, key)
			if key == "RotationType" then
				return rotation
			end
			if key == "GetPropertyChangedSignal" then
				return function()
					return {
						Connect = function(_, callback)
							listeners[callback] = true
							return {
								Disconnect = function()
									listeners[callback] = nil
								end,
							}
						end,
					}
				end
			end
		end,
		__newindex = function(_, key, value)
			assert(key == "RotationType")
			if value ~= rotation then
				rotation = value
				for callback in listeners do
					callback()
				end
			end
		end,
	})
	local input = { MouseDeltaSensitivity = 1.35 }
	local vr = { VREnabled = false }
	local run = {}
	function run:BindToRenderStep(name, priority, callback)
		bindings[name] = { priority = priority, callback = callback }
	end
	function run:UnbindFromRenderStep(name)
		bindings[name] = nil
	end
	function run:IsClient()
		return true
	end
	local services = { Players = { LocalPlayer = player }, RunService = run, VRService = vr, UserInputService = input }
	local env = {
		game = {
			GetService = function(_, name)
				return assert(services[name], name)
			end,
		},
		workspace = { CurrentCamera = cam },
		UserSettings = function()
			return {
				GetService = function()
					return settings
				end,
			}
		end,
		Enum = {
			CameraType = { Custom = "Custom" },
			RotationType = { CameraRelative = "CameraRelative" },
			RenderPriority = { Camera = { Value = 200 } },
		},
		CFrame = CFrame,
		Vector3 = Vector3,
		task = {
			delay = function(seconds, callback)
				table.insert(timers, { at = now + seconds, callback = callback })
			end,
		},
		os = {
			clock = function()
				return now
			end,
		},
	}
	local controller = luau.load(source, { environment = env })()
	local focus = Vector3.new(20, 4, 0)
	local distance = 12.5
	local function pose(pitch, yaw, locked)
		local rot = CFrame.fromOrientation(math.rad(pitch), yaw or 0, 0)
		local target = focus + (if locked then rot.RightVector * 1.75 else Vector3.zero)
		cam.Focus = CFrame.new(target)
		cam.CFrame = rot + target - rot.LookVector * distance
	end
	pose(-15)
	local function callbacks(before)
		local sorted = {}
		for _, binding in bindings do
			table.insert(sorted, binding)
		end
		table.sort(sorted, function(a, b)
			return a.priority < b.priority
		end)
		for _, binding in sorted do
			if (binding.priority < 200) == before then
				binding.callback()
			end
		end
	end
	local function pitch()
		return math.deg(math.asin(math.clamp(cam.CFrame.LookVector.Y, -1, 1)))
	end
	local function advance(seconds)
		now += seconds
		for i = #timers, 1, -1 do
			if timers[i].at <= now then
				local timer = table.remove(timers, i)
				timer.callback()
			end
		end
	end
	local function frame(locked, delta, yaw)
		advance(1 / 60)
		callbacks(true)
		settings.RotationType = if locked then "CameraRelative" else "MovementRelative"
		pose(pitch() + (delta or 0) * input.MouseDeltaSensitivity, yaw, locked)
		callbacks(false)
	end
	controller:Start()
	return {
		cam = cam,
		controller = controller,
		frame = frame,
		pitch = pitch,
		bindings = bindings,
		settings = settings,
		input = input,
		advance = advance,
		listeners = listeners,
		vr = vr,
		player = player,
		env = env,
		callbacks = callbacks,
		zoom = function(value)
			distance = value
			cam.CFrame = cam.CFrame.Rotation + cam.Focus.Position - cam.CFrame.LookVector * distance
		end,
	}
end

local f = fixture()
f.frame(false)
local originalY = f.cam.CFrame.Position.Y
f.frame(true, 22, 0.3) -- cursor warp on the toggle frame
close(f.pitch(), -15, "enter lock preserves pitch")
close(f.cam.CFrame.Position.Y, originalY, "enter lock preserves camera height")
close(math.atan2(-f.cam.CFrame.LookVector.X, -f.cam.CFrame.LookVector.Z), 0.3, "non-mouse yaw stays live")
f.frame(true, 17, 0.3) -- cursor warp delivered on the next frame
close(f.pitch(), -15, "delayed cursor warp is rejected")
f.frame(true, 16.17, 0.3) -- real reproduction: native warp arrived on frame THREE
close(f.pitch(), -15, "third-frame native warp is rejected")
f.advance(0.13)
close(f.input.MouseDeltaSensitivity, 1.35, "exact input sensitivity is restored")
f.frame(true, -8 / 1.35, 0.3)
close(f.pitch(), -23, "vertical mouse look resumes after handoff")
f.frame(false, 35, 0.3)
close(f.pitch(), -23, "exit lock preserves pitch")
f.frame(false, -12, 0.3)
close(f.pitch(), -23, "exit lock rejects delayed warp")
f.frame(false, 16.17, 0.3)
close(f.pitch(), -23, "exit lock rejects third-frame warp")
f.advance(0.13)
f.frame(false, 5 / 1.35, 0.3)
close(f.pitch(), -18, "unlocked mouse look resumes")
for i = 1, 60 do
	local locked = i % 2 == 1
	f.frame(locked, 9, 0.3)
	f.frame(locked, 13, 0.3)
end
close(f.pitch(), -18, "repeated toggles do not accumulate pitch")
f.advance(0.13)
close(f.input.MouseDeltaSensitivity, 1.35, "rapid toggles retain original sensitivity")
f.cam.CameraType = "Scriptable"
local cinematic = f.cam.CFrame
f.callbacks(true)
f.callbacks(false)
close((f.cam.CFrame.Position - cinematic.Position).Magnitude, 0, "cinematic position untouched")
close(f.cam.CFrame.LookVector:Dot(cinematic.LookVector), 1, "cinematic rotation untouched")
f.controller:Destroy()
assert(next(f.bindings) == nil, "Destroy removes all controller bindings")
checks += 1
assert(next(f.listeners) == nil, "Destroy disconnects the settings listener")
checks += 1
local cancelled = fixture()
cancelled.frame(false)
cancelled.frame(true)
close(cancelled.input.MouseDeltaSensitivity, 0, "handoff protects input")
cancelled.controller:Destroy()
close(cancelled.input.MouseDeltaSensitivity, 1.35, "Destroy restores input during handoff")
cancelled.input.MouseDeltaSensitivity = 0.7
cancelled.advance(1)
close(cancelled.input.MouseDeltaSensitivity, 0.7, "cancelled timers cannot change later input")
local takeover = fixture()
takeover.frame(false)
takeover.frame(true)
takeover.input.MouseDeltaSensitivity = 0.6
takeover.advance(0.13)
close(takeover.input.MouseDeltaSensitivity, 0.6, "another input owner's change is preserved")
takeover.controller:Destroy()

for _, mode in { "firstPerson", "otherSubject", "VR", "respawn" } do
	local bypass = fixture()
	bypass.frame(false)
	if mode == "firstPerson" then
		bypass.zoom(0.5)
	elseif mode == "otherSubject" then
		bypass.cam.CameraSubject = {}
	elseif mode == "VR" then
		bypass.vr.VREnabled = true
	elseif mode == "respawn" then
		bypass.player.Character = nil
	end
	bypass.frame(true, 10 / 1.35)
	close(bypass.pitch(), -5, `{mode} bypasses pitch guard`)
	bypass.controller:Destroy()
end

local shaken = fixture()
local shake = luau.load(fs.readFile("src/shared/VFX/Shake.luau"), { environment = shaken.env })()
shake.set("regression", 0.7)
assert(shaken.bindings.VFXShake.priority < shaken.bindings.KickTheEggShiftLock.priority)
checks += 1
shaken.frame(false)
for i = 1, 120 do
	shaken.frame(i % 4 < 2)
end
shake.set("regression", 0)
shaken.frame(false)
close(shaken.pitch(), -15, "camera shake leaves no pitch drift", 0.002)
shaken.controller:Destroy()
print(`ShiftLock regression: {checks} checks passed`)
