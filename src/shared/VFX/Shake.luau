--!strict
-- Partner A. Additive camera shake. Sources set an intensity 0..1; the strongest one wins.
-- Applied after the default camera each frame, so it never fights B's camera code.
local RunService = game:GetService("RunService")

local Shake = {}

local sources: { [string]: number } = {}
local bound = false
local seed = math.random() * 1000

local MAX_ANGLE = math.rad(2.2) -- at intensity 1
local MAX_OFFSET = 0.45

local function step()
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
	cam.CFrame *= CFrame.new(nx * MAX_OFFSET * amount, ny * MAX_OFFSET * amount, 0) * CFrame.Angles(
		ny * MAX_ANGLE * amount,
		nx * MAX_ANGLE * amount,
		nz * MAX_ANGLE * amount
	)
end

function Shake.set(source: string, intensity: number)
	if intensity <= 0 then
		sources[source] = nil
	else
		sources[source] = math.clamp(intensity, 0, 1)
	end
	if not bound and RunService:IsClient() then
		bound = true
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
