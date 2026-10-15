--!strict
-- Zone progress (top centre, under the quest bar): the kick progress bar for the CURRENT zone with the zone's
-- name label under it, from the supplied art (zone_bar_* frames, zone_label_NN). It replaces the old brick track.
--   * What it follows: your egg while it flies (positions from the server's KickResult, exactly like
--     FlightController) and while you steer it (the server model workspace.Chases[eggUid]); otherwise your
--     character. Zones come from Config/Zones; behind the start line (base) the bar is hidden, and so is it for a
--     character still on the kick pad (the pad sits on Meadow's start line; you're not in Meadow until you leave it).
--   * A zone change is "confirmed" once the new zone has held for CONFIRM seconds (no flicker on a boundary).
--     Each confirmed change bumps a revision: the bar resets to frame 1 / 0 % and the label pops in.
--   * Progress = how far you are through the zone in the direction you entered it, reported with its zone and
--     revision; a report for any other zone / older revision is ignored, and re-entering the same zone (or
--     duplicate updates) never resets. Zone 20 is the last zone: there is no zone 21.
-- The state part (newState / enter / report / frameKey) is pure so it can be tested on its own.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.Parent.Kit)
local System = script.Parent.Parent.System
local AssetIds = require(System.AssetIds)
local Motion = require(System.Motion)
local Ui = require(System.Ui)
local UiVfx = require(System.UiVfx)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))
local KickPad = require(Shared:WaitForChild("KickPad"))

local CONFIRM = 0.1 -- seconds a new zone must hold before it counts
local TICK = 1 / 20 -- progress updates per second

local ZoneProgress = {}

export type State = {
	zone: number, -- 0 = base / no zone yet
	revision: number,
	progress: number, -- 0..1 within the current zone
	inbound: boolean, -- entered from the far end (steering home)
}

function ZoneProgress.newState(): State
	return { zone = 0, revision = 0, progress = 0, inbound = false }
end

-- The zone at depth z (0 = behind the start line). Never past the last zone.
function ZoneProgress.zoneAt(z: number): number
	if z < 0 then
		return 0
	end
	for _, zone in Zones do
		if z < zone.start + zone.length then
			return zone.id
		end
	end
	return #Zones
end

-- A confirmed zone at depth z: returns true when it is a genuine change (bar reset).
function ZoneProgress.enter(state: State, zone: number, z: number?): boolean
	zone = math.clamp(zone, 0, #Zones)
	if zone == state.zone then
		return false
	end
	state.zone = zone
	state.revision += 1
	state.progress = 0
	local info = Zones[zone]
	state.inbound = info ~= nil and z ~= nil and z > info.start + info.length / 2
	return true
end

-- A progress report for (zone, revision): accepted only for the current zone and revision.
function ZoneProgress.report(state: State, zone: number, revision: number, ratio: number): boolean
	if zone ~= state.zone or revision ~= state.revision or zone == 0 then
		return false
	end
	state.progress = math.clamp(ratio, 0, 1)
	return true
end

-- How far through the zone depth z is, in the direction the zone was entered.
function ZoneProgress.ratio(state: State, z: number): number
	local info = Zones[state.zone]
	if not info then
		return 0
	end
	local t = math.clamp((z - info.start) / info.length, 0, 1)
	return if state.inbound then 1 - t else t
end

-- The bar frame for a progress ratio (frame 1 = empty). The last zone fills with the rainbow frame.
function ZoneProgress.frameKey(ratio: number, zone: number): string
	if ratio >= 0.875 then
		return if zone == #Zones then "zone_bar_rainbow" else "zone_bar_full"
	elseif ratio >= 0.625 then
		return "zone_bar_three_quarter"
	elseif ratio >= 0.375 then
		return "zone_bar_half"
	elseif ratio >= 0.125 then
		return "zone_bar_quarter"
	end
	return "zone_bar_empty"
end

-- UI -----------------------------------------------------------------------------------------------------------

export type ZoneProgress = {
	kicked: (result: { [string]: any }) -> (),
	chaseOver: (eggUid: string?) -> (),
	pin: (zone: number?, ratio: number?) -> (), -- previews / tests: hold a zone + progress (nil = live again)
	state: State,
}

function ZoneProgress.new(parent: Instance): ZoneProgress
	local player = Players.LocalPlayer
	local root = Instance.new("Frame")
	root.Name = "ZoneProgress"
	root.BackgroundTransparency = 1
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Size = UDim2.fromOffset(460, 112)
	root.Visible = false
	root.Parent = parent
	local scale = Kit.autoScale(root)

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, 0)
	bar.Size = UDim2.fromOffset(440, 48)
	bar.Parent = root
	local barArt = Ui.art(bar, "zone_bar_empty")
	barArt.ZIndex = 2
	local percent = Kit.label({
		name = "Percent",
		text = "0%",
		size = UDim2.fromOffset(120, 30),
		position = UDim2.fromScale(0.45, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		parent = bar,
		stroke = 3,
	})
	percent.ZIndex = 3

	local label = Instance.new("Frame")
	label.Name = "ZoneName"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 56)
	label.Size = UDim2.fromOffset(372, 50)
	label.Parent = root
	local labelArt = Ui.art(label, "zone_label_01")
	labelArt.ZIndex = 2

	-- directly under the quest bar (both auto-scale; the quest bar is 100 px tall at y 24 / 4 on phones)
	local compactNow = false
	local function place()
		root.Position = UDim2.new(0.5, 0, 0, (if compactNow then 4 else 24) + 104 * scale.Scale)
	end
	Kit.onLayout(function(compact: boolean)
		compactNow = compact
		place()
	end)
	scale:GetPropertyChangedSignal("Scale"):Connect(place)

	local state = ZoneProgress.newState()
	local candidate, candidateSince = 0, 0
	local flight: { [string]: any }? = nil
	local chaseEgg: string? = nil

	local function setArt(img: ImageLabel, key: string)
		if img:GetAttribute("ArtKey") == key then
			return
		end
		img:SetAttribute("ArtKey", key)
		local id = AssetIds.get(key)
		if id then
			img.Image = id
		end
	end

	local function showZone(zone: number)
		if zone == 0 then
			root.Visible = false -- base: no stale zone text
			return
		end
		root.Visible = true
		setArt(barArt, "zone_bar_empty")
		percent.Text = "0%"
		setArt(labelArt, AssetIds.zoneLabel(zone))
		local info = Zones[zone]
		local s = Motion.scaleOf(label)
		s.Scale = if Motion.reduced() then 1 else 0.55
		Motion.tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		UiVfx.glowPulse(label, info.accent, 1.5)
		UiVfx.sparkleBurst(label, 6)
		UiVfx.shineSweep(bar)
	end

	-- where the tracked thing is (depth along the runway) and whether it's your character, or nil when nothing is
	-- tracked yet
	local function depth(): (number?, boolean)
		local now = workspace:GetServerTimeNow()
		local f = flight
		if f then
			if now < f.launchTime + f.flightSeconds then
				local t = math.clamp((now - f.launchTime) / f.flightSeconds, 0, 1)
				return f.landPos.Z * t, false
			end
			flight = nil
		end
		local uid = chaseEgg
		if uid then
			local chases = workspace:FindFirstChild("Chases")
			local egg = chases and chases:FindFirstChild(uid)
			if egg and egg:IsA("Model") then
				return egg:GetPivot().Position.Z, false
			end
		end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return if hrp and hrp:IsA("BasePart") then hrp.Position.Z else nil, true
	end

	local pinned = false
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if pinned then
			return
		end
		acc += dt
		if acc < TICK then
			return
		end
		acc = 0
		local z, isCharacter = depth()
		if not z then
			return
		end
		local zone = if isCharacter and z < KickPad.ACCEPT_RADIUS then 0 else ZoneProgress.zoneAt(z)
		local now = os.clock()
		if zone ~= candidate then
			candidate, candidateSince = zone, now
		end
		if zone ~= state.zone and now - candidateSince >= CONFIRM then
			if ZoneProgress.enter(state, zone, z) then
				showZone(zone)
			end
		end
		if state.zone ~= 0 and ZoneProgress.report(state, state.zone, state.revision, ZoneProgress.ratio(state, z)) then
			setArt(barArt, ZoneProgress.frameKey(state.progress, state.zone))
			percent.Text = `{math.floor(state.progress * 100)}%`
		end
	end)

	return {
		state = state,
		-- your own kick: follow the egg's flight (server data), then the chase egg
		kicked = function(result: { [string]: any })
			if
				typeof(result.launchTime) == "number"
				and typeof(result.flightSeconds) == "number"
				and typeof(result.landPos) == "Vector3"
			then
				flight = result
				chaseEgg = result.eggUid
			end
		end,
		pin = function(zone: number?, ratio: number?)
			pinned = zone ~= nil
			if zone then
				local info = Zones[zone]
				if ZoneProgress.enter(state, zone, info and info.start) then
					showZone(zone)
				end
				ZoneProgress.report(state, zone, state.revision, ratio or 0)
				setArt(barArt, ZoneProgress.frameKey(state.progress, zone))
				percent.Text = `{math.floor(state.progress * 100)}%`
			end
		end,
		chaseOver = function(eggUid: string?)
			if eggUid == nil or eggUid == chaseEgg then
				flight = nil
				chaseEgg = nil
			end
		end,
	}
end

return ZoneProgress
