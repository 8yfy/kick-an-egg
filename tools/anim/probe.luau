-- DEV ONLY (paste into MCP execute_luau, Client). Measures what the eye calls "snapping" on the local character:
-- each frame (after every Stepped writer, in Heartbeat) it reads every R15 joint's final Transform and records the
-- rotation since the previous frame. A SNAP is a frame whose rotation is > SNAP_DEG and > SNAP_RATIO x both
-- neighbours (an isolated jump, not a fast but continuous strike). Also reports the peak angular speed per joint
-- and how far each foot slid while it was planted (foot below PLANT_H studs over the ground and the root still).
-- Set ACTION (a function) to drive the character while it records; returns a text report.
local SECONDS = _G.PROBE_SECONDS or 4
local SNAP_DEG, SNAP_RATIO = 9, 3
local PLANT_H = 0.35

local RunService = game:GetService("RunService")
local character = game.Players.LocalPlayer.Character
local joints = {}
for _, d in character:GetDescendants() do
	if d:IsA("AnimationConstraint") or d:IsA("Motor6D") then
		joints[d.Name] = d
	end
end
local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
local feet = { character:FindFirstChild("RightFoot"), character:FindFirstChild("LeftFoot") }

local frames = {}
local conn = RunService.Heartbeat:Connect(function(dt)
	local f = { t = os.clock(), dt = dt, rot = {}, feet = {}, root = hrp.Position }
	for name, j in joints do
		f.rot[name] = j.Transform
	end
	for i, foot in feet do
		if foot then
			f.feet[i] = foot.Position
		end
	end
	table.insert(frames, f)
end)
if _G.PROBE_ACTION then
	task.spawn(_G.PROBE_ACTION)
end
task.wait(SECONDS)
conn:Disconnect()

local function angle(a: CFrame, b: CFrame): number
	local _, ang = (a:Inverse() * b):ToAxisAngle()
	return math.deg(math.abs(ang))
end

local out = {}
local snaps = {}
local peak = {}
local t0 = frames[1].t
for name in joints do
	local d = {}
	for i = 2, #frames do
		d[i] = angle(frames[i - 1].rot[name], frames[i].rot[name])
		local speed = d[i] / math.max(frames[i].dt, 1 / 240)
		if speed > (peak[name] or 0) then
			peak[name] = speed
		end
	end
	for i = 3, #frames - 1 do
		if d[i] > SNAP_DEG and d[i] > SNAP_RATIO * d[i - 1] and d[i] > SNAP_RATIO * d[i + 1] then
			table.insert(snaps, string.format("%5.2fs %-14s %5.1f deg (neighbours %.1f / %.1f)", frames[i].t - t0, name, d[i], d[i - 1], d[i + 1]))
		end
	end
end
table.sort(snaps)
table.insert(out, string.format("frames %d over %.2fs (%.0f fps)", #frames, frames[#frames].t - t0, #frames / (frames[#frames].t - t0)))
table.insert(out, "SNAPS: " .. #snaps)
for _, s in snaps do
	table.insert(out, "  " .. s)
end
local names = {}
for name in peak do
	table.insert(names, name)
end
table.sort(names)
local line = {}
for _, name in names do
	table.insert(line, string.format("%s %.0f", name, peak[name]))
end
table.insert(out, "peak deg/s: " .. table.concat(line, ", "))
-- foot slide: planted spans (foot near its lowest height, root not moving horizontally)
for i, _ in feet do
	local low = math.huge
	for _, f in frames do
		if f.feet[i] then
			low = math.min(low, f.feet[i].Y)
		end
	end
	local slide, worst = 0, 0
	for k = 2, #frames do
		local a, b = frames[k - 1], frames[k]
		local rootMove = ((b.root - a.root) * Vector3.new(1, 0, 1)).Magnitude
		if a.feet[i] and b.feet[i] and a.feet[i].Y < low + PLANT_H and b.feet[i].Y < low + PLANT_H and rootMove < 0.02 then
			local m = ((b.feet[i] - a.feet[i]) * Vector3.new(1, 0, 1)).Magnitude
			slide += m
			worst = math.max(worst, m)
		end
	end
	table.insert(out, string.format("foot %d planted slide total %.3f studs, worst frame %.3f", i, slide, worst))
end
return table.concat(out, "\n")
