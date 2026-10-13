--!strict
-- Partner A. Additive camera shake. Sources set an intensity 0..1; the strongest one wins.
-- Applied after the default camera each frame AND undone just before the camera updates the next frame, so the
-- shake never leaks into Roblox's camera state. (Before, the default camera started every frame from the shaken
-- CFrame: each sack drop / hit left a permanent nudge, which with Shift Lock also turned the character.)
local RunService = game:GetService("RunService")

local Shake = {}

local sources: { [string]: number } = {}
local bound = false
local seed = math.random() * 1000

local MAX_ANGLE = math.rad(2.2) -- at intensity 1
local MAX_OFFSET = 0.45

local applied: CFrame? = nil -- the shake added this frame (removed before the camera's next update)

local function undo()
	local cf = applied
	applied = nil
	local cam = workspace.CurrentCamera
	if cf and cam then
		cam.CFrame *= cf:Inverse()
	end
end

local function step()
	local me = game:GetService("Players").LocalPlayer
	if me and me:GetAttribute("ShakeOff") == true then
		return -- Settings > Camera shake off
	end
	local amount = 0
	for _, v in sources do
		amount = math.max(amount, v)
	end
	if amount <= 0.001 then
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local t = os.clock() * 18
	local nx, ny, nz = math.noise(t, seed), math.noise(seed, t), math.noise(t, t + seed)
	local cf = CFrame.new(nx * MAX_OFFSET * amount, ny * MAX_OFFSET * amount, 0)
		* CFrame.Angles(ny * MAX_ANGLE * amount, nx * MAX_ANGLE * amount, nz * MAX_ANGLE * amount)
	cam.CFrame *= cf
	applied = cf
end

function Shake.set(source: string, intensity: number)
	if intensity <= 0 then
		sources[source] = nil
	else
		sources[source] = math.clamp(intensity, 0, 1)
	end
	if not bound and RunService:IsClient() then
		bound = true
		RunService:BindToRenderStep("VFXShakeUndo", Enum.RenderPriority.Camera.Value - 1, undo)
		RunService:BindToRenderStep("VFXShake", Enum.RenderPriority.Camera.Value + 1, step)
	end
end

-- One-shot thump that decays over `seconds`.
function Shake.impulse(source: string, intensity: number, seconds: number)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < seconds do
			Shake.set(source, intensity * (1 - (os.clock() - t0) / seconds))
			task.wait()
		end
		Shake.set(source, 0)
	end)
end

return Shake
