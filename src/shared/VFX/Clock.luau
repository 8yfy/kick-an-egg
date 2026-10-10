--!strict
-- Partner A. Shared time source for VFX so effects can be frozen mid-frame for screenshots
-- (Studio/debug only — never call freeze during real play: frozen time shifts the avalanche off the
-- server's clock). Effects read Clock.now() / Clock.server() and scale dt with Clock.dt().
--   workspace:SetAttribute("VFXFreeze", true)   -- hold the current frame (Studio only, see bottom)
local Clock = {}

local paused = false
local pausedReal, pausedServer = 0, 0
local offReal, offServer = 0, 0

function Clock.now(): number
	return (if paused then pausedReal else os.clock()) - offReal
end

function Clock.server(): number
	return (if paused then pausedServer else workspace:GetServerTimeNow()) - offServer
end

function Clock.dt(dt: number): number
	return if paused then 0 else dt
end

function Clock.isFrozen(): boolean
	return paused
end

-- task.delay on VFX time: holds while frozen so pooled parts aren't released mid-screenshot.
function Clock.delay(seconds: number, fn: (...any) -> (), ...: any)
	local target = Clock.now() + seconds
	local args = table.pack(...)
	task.spawn(function()
		task.wait(seconds)
		while Clock.now() < target do
			task.wait()
		end
		fn(table.unpack(args, 1, args.n))
	end)
end

function Clock.freeze(on: boolean)
	if on == paused then
		return
	end
	if on then
		pausedReal, pausedServer = os.clock(), workspace:GetServerTimeNow()
		paused = true
	else
		offReal += os.clock() - pausedReal
		offServer += workspace:GetServerTimeNow() - pausedServer
		paused = false
	end
	local folder = workspace:FindFirstChild("VFX")
	if folder then
		for _, d in folder:GetDescendants() do
			if d:IsA("ParticleEmitter") then
				d.TimeScale = if on then 0 else 1
			end
		end
	end
end

-- Studio debug hook: workspace:SetAttribute("VFXFreeze", true/false) from any context (command bar, MCP)
-- freezes every copy of this module, including the one the game's client scripts loaded.
if game:GetService("RunService"):IsStudio() then
	workspace:GetAttributeChangedSignal("VFXFreeze"):Connect(function()
		Clock.freeze(workspace:GetAttribute("VFXFreeze") == true)
	end)
end

return Clock
