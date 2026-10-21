--!strict
-- Partner A. The client's view of "which weather affects ME right now" (client only).
-- Inputs:
--   * the server's global event: Remotes WeatherChanged(weather?, endsAt?) (WeatherService; endsAt is
--     workspace:GetServerTimeNow() time). The only authoritative source; nothing here changes the schedule.
--   * local storm regions: State.setLocal / clearLocal. The game has no local weather yet (see the mapping report),
--     so nothing on the server feeds these; only the Studio dev preview does, to exercise the path.
--   * this player's position: the camera subject (the character, or the egg while steering it), polled 5x a second.
-- Output: State.effective() = the ONE weather for this player (an active local storm the player stands in beats the
-- global event; overlapping locals resolve by Registry priority, then key) and State.subscribe(fn(snapshot, reason)).
-- reason: "start" (a weather began while it affects you), "join" (it was already running when you joined),
-- "enter" (you walked into a running local storm), "leave", "end", "extend" (same event, new end time),
-- "switch" (one weather replaced by another). Duplicate server messages change nothing.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Registry = require(script.Parent.Registry)

local State = {}

export type Local = {
	key: string,
	id: string,
	center: Vector3,
	size: Vector3,
	endsAt: number?,
	rev: number,
	preview: boolean,
}
export type Snapshot = {
	id: string?, -- registry id (exact server id for real weathers)
	scope: string?, -- "global" | "local"
	endsAt: number?, -- server time, or nil (no countdown is ever invented)
	revKey: string?, -- unique per event revision ("g:3", "l:<key>:2"): toasts show once per revKey
	localKey: string?,
	preview: boolean, -- set by the Studio dev preview (client-only), never by the server
}
export type Reason = "start" | "join" | "enter" | "leave" | "end" | "extend" | "switch"

local JOIN_WINDOW = 10 -- seconds after listening: the first active weather received is a mid-event join
local EXIT_MARGIN = 4 -- studs of hysteresis before you count as having left a local storm

local global = { id = nil :: string?, endsAt = nil :: number?, rev = 0, preview = false }
local server = { id = nil :: string?, endsAt = nil :: number? } -- the last real server state (previews override it)
local locals: { [string]: Local } = {}
local inside: string? = nil -- key of the local storm the player is in
local current: Snapshot = { preview = false }
local listeners: { (Snapshot, Reason) -> () } = {}
local listenedAt: number? = nil
local gotFirst = false
local revision = 0 -- bumps on every real change (the visual mixer re-targets on it)

function State.revision(): number
	return revision
end

function State.effective(): Snapshot
	return current
end

function State.globalWeather(): (string?, number?)
	return global.id, global.endsAt
end

function State.locals(): { [string]: Local }
	return locals
end

function State.insideKey(): string?
	return inside
end

function State.subscribe(fn: (Snapshot, Reason) -> ()): () -> ()
	table.insert(listeners, fn)
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

local lastReason: Reason? = nil
function State.lastReason(): Reason?
	return lastReason
end

local function emit(reason: Reason)
	lastReason = reason
	for _, fn in table.clone(listeners) do
		task.spawn(fn, current, reason)
	end
end

local function priority(l: Local): number
	local e = Registry.get(l.id)
	return if e then e.priority else 0
end

-- The local storm the player stands in (deterministic when several overlap).
local function pickInside(pos: Vector3?): string?
	if not pos then
		return nil
	end
	local best: Local? = nil
	for key, l in locals do
		local margin = if key == inside then EXIT_MARGIN else 0
		local d = pos - l.center
		local half = l.size / 2 + Vector3.one * margin
		if math.abs(d.X) <= half.X and math.abs(d.Y) <= half.Y and math.abs(d.Z) <= half.Z then
			if not best or priority(l) > priority(best) or (priority(l) == priority(best) and l.key < best.key) then
				best = l
			end
		end
	end
	return if best then best.key else nil
end

local function snapshot(): Snapshot
	local l = if inside then locals[inside] else nil
	if l then
		return {
			id = l.id,
			scope = "local",
			endsAt = l.endsAt,
			revKey = `l:{l.key}:{l.rev}`,
			localKey = l.key,
			preview = l.preview,
		}
	elseif global.id then
		return {
			id = global.id,
			scope = "global",
			endsAt = global.endsAt,
			revKey = `g:{global.rev}`,
			preview = global.preview,
		}
	end
	return { preview = false }
end

-- Recompute the effective weather; `reason` describes what changed (refined below).
local function refresh(reason: Reason)
	local before = current
	local after = snapshot()
	current = after
	revision += 1
	if after.revKey == before.revKey and after.endsAt == before.endsAt then
		return
	end
	if after.revKey == before.revKey then
		emit("extend")
	elseif not after.id then
		emit(if before.scope == "local" and reason == "leave" then "leave" else "end")
	else
		emit(reason)
	end
end

-- The server's global event (also the dev preview's client-only stand-in, preview = true).
function State.setGlobal(weather: any, endsAt: any, preview: boolean?)
	local id: string? = if typeof(weather) == "string" and weather ~= "" then weather else nil
	local e: number? = if typeof(endsAt) == "number"
			and endsAt == endsAt
			and math.abs(endsAt) < math.huge
		then endsAt
		else nil
	if not id then
		e = nil
	end
	local first = not gotFirst and not preview
	if not preview then
		gotFirst = true
		server.id, server.endsAt = id, e
	end
	if id == global.id and e == global.endsAt then
		return -- duplicate message
	end
	local reason: Reason
	if id == global.id then
		global.endsAt = e
		reason = "extend"
	else
		local had = global.id
		global.rev += 1
		global.id, global.endsAt = id, e
		if not id then
			reason = "end"
		elseif first and listenedAt and os.clock() - listenedAt < JOIN_WINDOW then
			reason = "join"
		elseif had then
			reason = "switch"
		else
			reason = "start"
		end
	end
	global.preview = preview == true
	if id and not Registry.get(id) then
		warn(`[WeatherFx] server weather "{id}" has no Registry entry: no visuals, HUD shows its name only`)
	end
	refresh(reason)
end

-- A local storm region (key = a stable id for this storm instance).
function State.setLocal(key: string, id: string, center: Vector3, size: Vector3, endsAt: number?, preview: boolean?)
	local old = locals[key]
	local rev = if old and old.id == id then old.rev else (if old then old.rev + 1 else 1)
	locals[key] =
		{ key = key, id = id, center = center, size = size, endsAt = endsAt, rev = rev, preview = preview == true }
	local was = inside
	inside = pickInside(State.position())
	refresh(if inside == key and was ~= key then (if old then "enter" else "start") else "extend")
end

function State.clearLocal(key: string)
	if not locals[key] then
		return
	end
	locals[key] = nil
	local was = inside
	inside = pickInside(State.position())
	refresh(if was == key then "end" else "extend")
end

-- Studio dev preview: drop any preview and show the server's real state again.
function State.restoreServer()
	State.setGlobal(server.id, server.endsAt, false)
end

-- Studio dev preview: replay the current global event as if this client had just joined.
function State.simulateJoin()
	local id, e = global.id, global.endsAt
	global.id, global.endsAt = nil, nil
	current = snapshot()
	revision += 1
	emit("end")
	gotFirst = false
	listenedAt = os.clock()
	State.setGlobal(id, e, global.preview)
end

-- Where "the player" is: the camera subject (character root, or the steered egg), else the character.
function State.position(): Vector3?
	local cam = workspace.CurrentCamera
	local subject = cam and cam.CameraSubject
	if subject then
		if subject:IsA("Humanoid") then
			local root = subject.RootPart
			if root then
				return root.Position
			end
		elseif subject:IsA("BasePart") then
			return subject.Position
		elseif subject:IsA("Model") then
			return subject:GetPivot().Position
		end
	end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return if hrp and hrp:IsA("BasePart") then hrp.Position else nil
end

local started = false
function State.listen()
	if started or not RunService:IsClient() then
		return
	end
	started = true
	listenedAt = os.clock()
	task.spawn(function()
		local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
		Remotes.get("WeatherChanged").OnClientEvent:Connect(function(weather: any, endsAt: any)
			State.setGlobal(weather, endsAt, false)
		end)
	end)
	-- local storm entry / exit follows the player's real position
	task.spawn(function()
		while true do
			task.wait(0.2)
			if next(locals) or inside then
				local now = workspace:GetServerTimeNow()
				for key, l in locals do
					if l.endsAt and now > l.endsAt + 2 then
						State.clearLocal(key)
					end
				end
				local was = inside
				local nowIn = pickInside(State.position())
				if nowIn ~= was then
					inside = nowIn
					refresh(if nowIn then "enter" else "leave")
				end
			end
		end
	end)
end

return State
