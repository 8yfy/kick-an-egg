-- DEV ONLY: Kick Sack VFX benchmark (run-in-roblox, edit mode):
--   sh tools/run-tests.sh tools/perf/SackVfxBench.server.lua
--   run-in-roblox --place <older build>.rbxl --script tools/perf/SackVfxBench.server.lua   (the "before" numbers)
-- For each of the 20 sacks: builds the game model (SackGeometry, the imported meshes) + its idle effects
-- (VFX/SackAura, driven), counts what the effect creates, estimates the live particles, and times the Lua work
-- per frame: the effect step (ctx:step) at each level of detail, and the stand's spin (model:PivotTo vs one
-- BulkMoveTo of the cached parts). Also the build time (what a destroy / rebuild by distance used to cost).
-- Times are CPU script time measured with os.clock over many frames in this Studio process: comparable before /
-- after on the same machine, not FPS. Works on builds without levels of detail (only "Full" is measured there).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local SackGeometry = require(Shared.Builders.SackGeometry)
local Sacks = require(Shared.Builders.Models.Sacks)
local SackAura = require(Shared.VFX.SackAura) :: any
local lodModule = Shared.VFX:FindFirstChild("SackLod")
local SackLod = if lodModule then require(lodModule) :: any else nil

local FRAMES = 240
local DT = 1 / 60
local LEVELS = if SackLod then { "Full", "Reduced", "Minimal", "Disabled", "OffScreen" } else { "Full" }

local function avg(r: NumberRange): number
	return (r.Min + r.Max) / 2
end

-- live particles: hand-driven ones that are showing + the engine emitters' rate x lifetime
local function census(folder: Instance?)
	local c = { emitters = 0, swarm = 0, beams = 0, lights = 0, parts = 0, atts = 0, live = 0 }
	for _, d in if folder then folder:GetDescendants() else {} do
		if d:IsA("ParticleEmitter") then
			c.emitters += 1
			if d.Rate == 0 then
				c.swarm += 1 -- one particle per emitter (Lua-moved before, engine-moved now)
			elseif d.Enabled then
				c.live += d.Rate * avg(d.Lifetime)
			end
		elseif d:IsA("Beam") then
			c.beams += 1
		elseif d:IsA("Light") then
			c.lights += 1
		elseif d:IsA("BasePart") then
			c.parts += 1
		elseif d:IsA("Attachment") then
			c.atts += 1
		end
	end
	return c
end

local function activeSwarm(ctx: any, c: any): number
	if not ctx.swarms then
		return c.swarm -- older build: every swarm particle always runs
	end
	local n = 0
	for _, sw in ctx.swarms do
		for _, p in sw.list do
			if p.active then
				n += 1
			end
		end
	end
	return n
end

local function timeSteps(ctx: any): number
	for _ = 1, 10 do
		ctx:step(DT)
	end
	local t0 = os.clock()
	for _ = 1, FRAMES do
		ctx:step(DT)
	end
	return (os.clock() - t0) / FRAMES * 1000
end

local rows = {}
local totals = { build = 0, spinPivot = 0, spinBulk = 0, swarm = 0, emitters = 0, beams = 0, lights = 0 }
local stepTotals, liveTotals = {}, {}
for _, l in LEVELS do
	stepTotals[l], liveTotals[l] = 0, 0
end
for tier = 1, 20 do
	local model = SackGeometry.build(tier)
	local hang = CFrame.new(tier * 30, 50, 0)
	model:PivotTo(hang)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	model.Parent = workspace
	local modelParts = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			modelParts += 1
		end
	end
	local t0 = os.clock()
	local ok, ctx = pcall(SackAura.Apply, model, tier, hang * Sacks.vfxRoot(tier), Sacks.SCALE, true, true)
	local buildMs = (os.clock() - t0) * 1000
	if not ok then
		print("BENCH", tier, "apply failed", ctx)
		continue
	end
	local folder = model:FindFirstChild("SackVFX")
	local base = census(folder)
	local per = {}
	for i, l in LEVELS do
		if SackLod then
			-- levels 1-4 by distance; OffScreen = Full detail, but outside the camera's view
			if l == "OffScreen" then
				ctx:setLod(1, false, SackLod.PROFILES.HIGH)
			else
				ctx:setLod(i, true, SackLod.PROFILES.HIGH)
			end
		end
		local ms = timeSteps(ctx)
		local c = census(folder)
		per[l] = { ms = ms, live = c.live + activeSwarm(ctx, c) }
		stepTotals[l] += ms
		liveTotals[l] += per[l].live
	end
	-- spin: PivotTo of the whole model vs one BulkMoveTo of cached parts (effect-placed parts left to the effect)
	t0 = os.clock()
	for i = 1, FRAMES do
		model:PivotTo(hang * CFrame.Angles(0, i * 0.01, 0))
	end
	local pivotMs = (os.clock() - t0) / FRAMES * 1000
	local parts, rel = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("SackVFX_Placed") == nil and d:GetAttribute("SackVFX_Rest") == nil then
			table.insert(parts, d)
			table.insert(rel, hang:ToObjectSpace(d.CFrame))
		end
	end
	local cfs = table.create(#parts)
	t0 = os.clock()
	for i = 1, FRAMES do
		local at = hang * CFrame.Angles(0, i * 0.01, 0)
		for k, r in rel do
			cfs[k] = at * r
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
	local bulkMs = (os.clock() - t0) / FRAMES * 1000
	local name = Sacks.TIERS and Sacks.TIERS[tier] and Sacks.TIERS[tier].name or tostring(tier)
	local steps = {}
	for _, l in LEVELS do
		table.insert(steps, string.format("%s %.3f ms / ~%d live", l, per[l].ms, per[l].live))
	end
	table.insert(
		rows,
		string.format(
			"BENCH %2d %-16s modelParts %3d | emitters %3d (swarm %3d) beams %3d lights %2d fxParts %3d atts %3d | build %.1f ms | %s | spin PivotTo %.3f / BulkMoveTo %.3f ms",
			tier,
			name,
			modelParts,
			base.emitters,
			base.swarm,
			base.beams,
			base.lights,
			base.parts,
			base.atts,
			buildMs,
			table.concat(steps, " | "),
			pivotMs,
			bulkMs
		)
	)
	totals.build += buildMs
	totals.spinPivot += pivotMs
	totals.spinBulk += bulkMs
	totals.swarm += base.swarm
	totals.emitters += base.emitters
	totals.beams += base.beams
	totals.lights += base.lights
	SackAura.Remove(model)
	model:Destroy()
end
for _, r in rows do
	print(r)
end
local steps = {}
for _, l in LEVELS do
	table.insert(steps, string.format("%s %.2f ms / ~%d live", l, stepTotals[l], liveTotals[l]))
end
print(
	string.format(
		"BENCH TOTAL (all 20) emitters %d (swarm %d) beams %d lights %d | build %.0f ms | step %s | spin PivotTo %.2f / BulkMoveTo %.2f ms per frame",
		totals.emitters,
		totals.swarm,
		totals.beams,
		totals.lights,
		totals.build,
		table.concat(steps, " | "),
		totals.spinPivot,
		totals.spinBulk
	)
)
if SackLod then
	-- the quality profiles at Full, all 20 sacks
	for _, name in SackLod.ORDER do
		local total, live = 0, 0
		for tier = 1, 20 do
			local model = SackGeometry.build(tier)
			local hang = CFrame.new(tier * 30, 50, 0)
			model:PivotTo(hang)
			model.Parent = workspace
			local ctx = SackAura.Apply(model, tier, hang * Sacks.vfxRoot(tier), Sacks.SCALE, true, true)
			ctx:setLod(1, true, SackLod.PROFILES[name])
			total += timeSteps(ctx)
			local c = census(model:FindFirstChild("SackVFX"))
			live += c.live + activeSwarm(ctx, c)
			SackAura.Remove(model)
			model:Destroy()
		end
		print(string.format("BENCH PROFILE %-7s Full, all 20: step %.2f ms / ~%d live", name, total, live))
	end
end
print("[Tests] 1 passed, 0 failed")
