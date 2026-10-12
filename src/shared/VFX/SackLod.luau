--!strict
-- Kick Sack VFX level of detail and quality profiles (client). One driver for every sack's idle effects
-- (VFX/SackAura contexts): the stand / shop sacks (MapLifeController), every player's gear sack
-- (SackController) and the dev showcases.
--   * Distance bands from the camera, checked every CHECK_INTERVAL with HYSTERESIS so nothing flickers on an edge:
--     Full < 45 studs <= Reduced < 100 <= Minimal < 180 <= Disabled (x the profile's `reach`).
--   * Conservative view culling, every frame (cheap): a sack whose bounding sphere (x CULL_MARGIN) is off
--     screen stops animating, but keeps its particles alive; nothing is culled nearer than CULL_MIN.
--   * Quality profiles HIGH / MEDIUM / LOW / MINIMAL scale how many particles run, how often the Lua-driven
--     parts update, and which lights / lightning run. AUTO (the default) follows Roblox's own graphics quality
--     (UserGameSettings.SavedQualityLevel; Automatic adapts to this device's real frame time) and the
--     "Low detail effects" setting. Settings > "Sack effects" (LocalPlayer attribute "SackVfxQuality") overrides
--     it. Touch alone never lowers quality: a fast phone keeps HIGH.
-- Contexts are kept while far away (Disabled = hidden and not stepped) instead of being destroyed and rebuilt.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SackLod = {}

SackLod.FULL, SackLod.REDUCED, SackLod.MINIMAL, SackLod.DISABLED = 1, 2, 3, 4
SackLod.BANDS = { 45, 100, 180 } -- studs: Full | Reduced | Minimal | Disabled edges (before `reach`)
SackLod.HYSTERESIS = 8 -- studs past an edge before the band changes
SackLod.CHECK_INTERVAL = 0.2 -- seconds between distance checks
SackLod.CULL_MIN = 25 -- studs: never view-cull nearer than this
SackLod.CULL_MARGIN = 1.5 -- bounding radius x this for the view test (particles drift outside the sack)
SackLod.ORPHAN_SECONDS = 10 -- a context whose sack left the world (streamed out) this long is destroyed

export type Profile = {
	name: string,
	reach: number, -- band edges x this
	density: { number }, -- share of particles at Full, Reduced, Minimal (stream rates follow, floored)
	stride: { number }, -- frames per update of Lua-driven particles and animation at Full, Reduced, Minimal
	lights: number, -- point lights stay on up to this level
	bolts: { number }, -- share of lightning bolts at Full, Reduced, Minimal
}

SackLod.PROFILES = {
	HIGH = {
		name = "HIGH",
		reach = 1,
		density = { 1, 0.6, 0.3 },
		stride = { 1, 2, 4 },
		lights = 2,
		bolts = { 1, 0.5, 0.25 },
	},
	MEDIUM = {
		name = "MEDIUM",
		reach = 0.85,
		density = { 0.8, 0.45, 0.2 },
		stride = { 1, 2, 4 },
		lights = 2,
		bolts = { 1, 0.5, 0.25 },
	},
	LOW = {
		name = "LOW",
		reach = 0.7,
		density = { 0.55, 0.3, 0.12 },
		stride = { 1, 3, 6 },
		lights = 1,
		bolts = { 0.5, 0.25, 0 },
	},
	MINIMAL = {
		name = "MINIMAL",
		reach = 0.55,
		density = { 0.35, 0.15, 0 },
		stride = { 2, 4, 8 },
		lights = 1,
		bolts = { 0.25, 0, 0 },
	},
} :: { [string]: Profile }
SackLod.ORDER = { "HIGH", "MEDIUM", "LOW", "MINIMAL" }

-- Adaptive AUTO: below LOW_FPS for 2 windows steps down a profile; above HIGH_FPS for 10 windows steps back
-- up (never above the graphics-quality cap, and not within COOLDOWN of a step down).
local WINDOW = 2
local LOW_FPS, HIGH_FPS = 40, 55
local COOLDOWN = 30

-- Level for a sack `d` studs from the camera, currently at `current` (hysteresis), edges x `reach`.
function SackLod.band(d: number, current: number, reach: number): number
	local level = 1
	for i, edge in SackLod.BANDS do
		local e = edge * reach
		local limit = if current > i then e - SackLod.HYSTERESIS else e + SackLod.HYSTERESIS
		if d >= limit then
			level = i + 1
		end
	end
	return level
end

-- Whether a sphere is (conservatively) inside the camera's view. `tanY` = tan(vertical FOV / 2).
function SackLod.inView(cam: CFrame, tanY: number, aspect: number, center: Vector3, radius: number): boolean
	local rel = cam:PointToObjectSpace(center)
	local z = -rel.Z
	if z < -radius then
		return false
	end
	local tanX = tanY * aspect
	return math.abs(rel.Y) - z * tanY <= radius * math.sqrt(1 + tanY * tanY)
		and math.abs(rel.X) - z * tanX <= radius * math.sqrt(1 + tanX * tanX)
end

-- Profile cap from Roblox's graphics quality (1-10). Automatic = HIGH, adapted to the real frame time.
function SackLod.capFor(savedQuality: number): string
	if savedQuality <= 0 or savedQuality >= 8 then
		return "HIGH"
	elseif savedQuality >= 5 then
		return "MEDIUM"
	elseif savedQuality >= 3 then
		return "LOW"
	end
	return "MINIMAL"
end

local function rankOf(name: string): number
	return table.find(SackLod.ORDER, name) or 1
end

-- quality ------------------------------------------------------------------------------------------------------
local gameSettings: any = nil
pcall(function()
	gameSettings = UserSettings():GetService("UserGameSettings")
end)

local autoRank = 1 -- adaptive step inside the cap (AUTO only)
local slowWindows, fastWindows, lastDrop = 0, 0, -math.huge
local winTime, winFrames = 0, 0
local focused = true

local function savedQuality(): (number, boolean)
	if not gameSettings then
		return 0, true
	end
	local ok, v = pcall(function()
		return gameSettings.SavedQualityLevel
	end)
	if not ok or not v or v == Enum.SavedQualitySetting.Automatic then
		return 0, true
	end
	return v.Value, false
end

SackLod.override = nil :: string? -- dev tools (previews, benchmarks): force a profile by name

-- The profile in force now.
function SackLod.profile(): Profile
	if SackLod.override and SackLod.PROFILES[SackLod.override] then
		return SackLod.PROFILES[SackLod.override]
	end
	local me = Players.LocalPlayer
	local override = me and me:GetAttribute("SackVfxQuality")
	if typeof(override) == "string" and SackLod.PROFILES[override] then
		return SackLod.PROFILES[override]
	end
	local q = savedQuality()
	local cap = rankOf(SackLod.capFor(q))
	if me and me:GetAttribute("LowDetail") == true then
		cap = math.max(cap, rankOf("LOW"))
	end
	return SackLod.PROFILES[SackLod.ORDER[math.clamp(math.max(cap, autoRank), 1, #SackLod.ORDER)]]
end

-- Frame-time monitor for AUTO under Automatic graphics.
local function monitor(dt: number)
	if not focused or dt > 0.5 then
		return -- backgrounded / hitch: not a measure of the effects
	end
	winTime += dt
	winFrames += 1
	if winTime < WINDOW then
		return
	end
	local fps = winFrames / winTime
	winTime, winFrames = 0, 0
	local _, automatic = savedQuality()
	if not automatic then
		autoRank = 1
		return
	end
	local now = os.clock()
	if fps < LOW_FPS then
		slowWindows += 1
		fastWindows = 0
		if slowWindows >= 2 and autoRank < #SackLod.ORDER then
			autoRank += 1
			slowWindows = 0
			lastDrop = now
		end
	elseif fps > HIGH_FPS then
		fastWindows += 1
		slowWindows = 0
		if fastWindows >= 10 and autoRank > 1 and now - lastDrop > COOLDOWN then
			autoRank -= 1
			fastWindows = 0
		end
	else
		slowWindows, fastWindows = 0, 0
	end
end

-- driver -------------------------------------------------------------------------------------------------------
type Entry = { level: number, visible: boolean, orphanSince: number? }
local entries: { [any]: Entry } = {}
local conn: RBXScriptConnection? = nil
local checkIn = 0

local function evaluate(ctx: any, e: Entry, prof: Profile, cam: Camera?, distance: boolean, now: number)
	if not ctx.model.Parent then
		e.orphanSince = e.orphanSince or now
		if e.level ~= SackLod.DISABLED then
			e.level = SackLod.DISABLED
			ctx:setLod(SackLod.DISABLED, false, prof)
		end
		return
	end
	e.orphanSince = nil
	if not cam then
		ctx:setLod(e.level, true, prof)
		return
	end
	local camCF = cam.CFrame
	local center, radius = ctx:bounds()
	local d = (center - camCF.Position).Magnitude
	if distance then
		e.level = SackLod.band(d, e.level, prof.reach)
	end
	local vp = cam.ViewportSize
	local aspect = if vp.Y > 0 then vp.X / vp.Y else 16 / 9
	e.visible = d < SackLod.CULL_MIN
		or SackLod.inView(camCF, math.tan(math.rad(cam.FieldOfView) / 2), aspect, center, radius * SackLod.CULL_MARGIN)
	ctx:setLod(e.level, e.visible, prof)
end

local function frame(dt: number)
	monitor(dt)
	local now = os.clock()
	local prof = SackLod.profile()
	local cam = workspace.CurrentCamera
	checkIn -= dt
	local distance = checkIn <= 0
	if distance then
		checkIn = SackLod.CHECK_INTERVAL
	end
	for ctx, e in entries do
		if ctx.dead then
			entries[ctx] = nil
			continue
		end
		evaluate(ctx, e, prof, cam, distance, now)
		if e.orphanSince and now - e.orphanSince > SackLod.ORPHAN_SECONDS then
			entries[ctx] = nil
			ctx:destroy() -- streamed out for good: free it (it is rebuilt if the sack comes back)
		elseif not ctx.driven then
			local ok, err = pcall(ctx.step, ctx, dt) -- one broken effect must not stop the others
			if not ok then
				entries[ctx] = nil
				warn("[SackLod] sack effect stopped:", err)
				ctx:destroy()
			end
		end
	end
	if next(entries) == nil and conn then
		conn:Disconnect()
		conn = nil
	end
end

-- Starts managing `ctx` (a SackAura context): sets its level right away, then every frame. Non-driven contexts
-- are also stepped here (one RenderStepped for all of them).
function SackLod.register(ctx: any)
	local e: Entry = { level = SackLod.FULL, visible = true }
	entries[ctx] = e
	evaluate(ctx, e, SackLod.profile(), workspace.CurrentCamera, true, os.clock()) -- a far sack starts far
	if not conn then
		conn = RunService.RenderStepped:Connect(frame)
	end
end

function SackLod.unregister(ctx: any)
	entries[ctx] = nil
end

-- For tests / the benchmark / the play test.
function SackLod.count(): number
	local n = 0
	for _ in entries do
		n += 1
	end
	return n
end

-- How many managed effects are at each level right now, and how many of the visible-level ones are off screen.
function SackLod.levels(): { [string]: number }
	local out = { Full = 0, Reduced = 0, Minimal = 0, Disabled = 0, OffScreen = 0 }
	local names = { "Full", "Reduced", "Minimal", "Disabled" }
	for _, e in entries do
		local name = names[e.level] or "Disabled"
		out[name] += 1
		if e.level < SackLod.DISABLED and not e.visible then
			out.OffScreen += 1
		end
	end
	return out
end

UserInputService.WindowFocused:Connect(function()
	focused = true
end)
UserInputService.WindowFocusReleased:Connect(function()
	focused = false
end)

return SackLod
