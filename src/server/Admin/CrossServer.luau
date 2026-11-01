--!strict
-- Cross-server admin actions (MessagingService) and temporary global state (MemoryStoreService).
--   * The sending server runs the command locally first, then publishes a bounded Envelope (id, timestamps,
--     expiry, source server, initiating UserId, command id, validated params). Every receiver re-validates it
--     (Envelope.validate: shape, size, expiry, duplicates, own messages) and runs it through
--     Pipeline.executeRemote: ITS allowlist, the same registry, permissions, schemas, limits and handlers.
--   * Delivery is not guaranteed by Roblox, so the status is honest: "published" means MessagingService accepted
--     it (after up to Config.CrossServer.retries attempts); receivers send an acknowledgement and the sender counts
--     them for ackWindow seconds. Servers that don't ack may simply not have received it.
--   * Temporary global effects (weather, flags) are also written to an expiring MemoryStore hash map so servers
--     that start later pick them up (AdminService:Start). DataStores are never used as a broadcast channel.
--   * In an unpublished Studio place these services are unavailable: everything degrades to "unavailable" and the
--     local part of a command still runs.

local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local MessagingService = game:GetService("MessagingService")

local Config = require(script.Parent.Config)
local Envelope = require(script.Parent.Envelope)
local Environment = require(script.Parent.Environment)

local X = Config.CrossServer
local CrossServer = {}

type Delivery = {
	id: string,
	command: string,
	at: number,
	status: string, -- published | failed | unavailable | too_large
	attempts: number,
	detail: string?,
	acks: number,
	failedAcks: number,
	servers: { string },
}

local pipeline: any = nil
local seen = Envelope.seen(X.seenCapacity)
local deliveries: { Delivery } = {} -- newest first, max 20
local byId: { [string]: Delivery } = {}
local health = { messaging = "untested", memory = "untested", received = 0, rejected = 0, lastReject = "" }
local stateMap: MemoryStoreHashMap? = nil
local auditMap: MemoryStoreSortedMap? = nil

-- An unpublished place (PlaceId 0, e.g. a Studio file) has no MessagingService or MemoryStore, and calls there
-- can yield for a long time instead of failing: report "unavailable" at once and never call them.
local published = game.PlaceId ~= 0
local CALL_TIMEOUT = 4

-- Runs `fn` with a time limit (the call itself can't be cancelled; a late result is ignored).
local function withTimeout(seconds: number, fn: () -> any): (boolean, any)
	local done, ok, result = false, false, nil
	task.spawn(function()
		ok, result = pcall(fn)
		done = true
	end)
	local started = os.clock()
	while not done and os.clock() - started < seconds do
		task.wait(0.05)
	end
	if not done then
		return false, "timed out"
	end
	return ok, result
end

local function withRetries(label: string, fn: () -> any): (boolean, any, number)
	local lastErr: any = nil
	for attempt = 1, X.retries do
		local ok, result = withTimeout(CALL_TIMEOUT, fn)
		if ok then
			return true, result, attempt
		end
		lastErr = result
		if attempt < X.retries then
			task.wait(attempt) -- 1 s, 2 s
		end
	end
	warn(`[Admin.CrossServer] {label} failed: {lastErr}`)
	return false, lastErr, X.retries
end

function CrossServer.init(p: any)
	pipeline = p
end

local function remember(d: Delivery)
	table.insert(deliveries, 1, d)
	byId[d.id] = d
	while #deliveries > 20 do
		local old = table.remove(deliveries) :: Delivery
		byId[old.id] = nil
	end
end

-- Called by the Pipeline after a successful global-scope run on this server.
function CrossServer.broadcast(cmd: any, params: { [string]: any }, ctx: any): { [string]: any }
	local env = Envelope.build({
		id = ctx.correlation,
		at = os.time(),
		src = Environment.serverId(),
		uid = ctx.userId,
		name = ctx.name,
		cmd = cmd.id,
		p = params,
	}, X.ttl)
	local d: Delivery = {
		id = env.id,
		command = cmd.id,
		at = env.at,
		status = "pending",
		attempts = 0,
		acks = 0,
		failedAcks = 0,
		servers = {},
	}
	local okEncode, json = pcall(HttpService.JSONEncode, HttpService, env)
	if not okEncode or #json > X.maxBytes then
		d.status, d.detail = "too_large", "The message is over MessagingService's size limit."
	elseif not published or health.messaging == "unavailable" then
		d.status = "unavailable"
		d.detail = if published
			then "MessagingService is unavailable right now; only this server changed."
			else "This place isn't published, so there is no MessagingService; only this server changed."
	else
		-- publish in the background (bounded retries with timeouts); the panel polls crossserver.status
		d.status = "sending"
		d.detail = "Publishing; delivery isn't guaranteed, so watch the acknowledgements."
		task.spawn(function()
			local ok, _err, attempts = withRetries(`publish {cmd.id}`, function()
				MessagingService:PublishAsync(X.topic, env)
			end)
			d.attempts = attempts
			if ok then
				d.status = "published"
				d.detail = "Accepted by MessagingService. Servers that don't acknowledge may not have received it."
				health.messaging = "ok"
			else
				d.status = "failed"
				d.detail = "MessagingService did not accept the message; only this server changed."
			end
		end)
	end
	remember(d)
	return { id = d.id, status = d.status, attempts = d.attempts, detail = d.detail }
end

-- Handles one incoming message (also used directly by the Studio security tests). Returns (accepted, reason).
function CrossServer.receive(data: any): (boolean, string)
	local ok, envOrReason = Envelope.validate(data, {
		now = os.time(),
		maxSkew = X.maxSkew,
		maxTtl = X.ttl,
		self = Environment.serverId(),
		seen = seen,
		maxKeys = Config.Limits.maxParamKeys,
		maxString = Config.Limits.maxStringLength,
	})
	if not ok then
		health.rejected += 1
		health.lastReject = envOrReason
		return false, envOrReason
	end
	health.received += 1
	local res = pipeline.executeRemote(envOrReason)
	task.spawn(function()
		withTimeout(CALL_TIMEOUT, function()
			MessagingService:PublishAsync(
				X.ackTopic,
				Envelope.ack(envOrReason.id, Environment.serverId(), res.ok, res.code)
			)
		end)
	end)
	return res.ok, res.code
end

local function onAck(data: any)
	local ok, ack = Envelope.validateAck(data)
	if not ok then
		return
	end
	local d = byId[ack.ack]
	if not d or os.time() - d.at > X.ackWindow or table.find(d.servers, ack.src) or #d.servers >= 200 then
		return
	end
	table.insert(d.servers, ack.src)
	if ack.ok then
		d.acks += 1
	else
		d.failedAcks += 1
	end
end

function CrossServer.deliveries(): { { [string]: any } }
	local list = {}
	for _, d in deliveries do
		table.insert(list, {
			id = d.id,
			command = d.command,
			at = d.at,
			status = d.status,
			attempts = d.attempts,
			detail = d.detail,
			acks = d.acks,
			failedAcks = d.failedAcks,
			counting = os.time() - d.at <= X.ackWindow,
		})
	end
	return list
end

function CrossServer.health(): { [string]: any }
	return table.clone(health)
end

-- Temporary global state ------------------------------------------------------------------------------------

-- Fire-and-forget (bounded retries with timeouts); the outcome shows up in health().memory.
function CrossServer.setState(key: string, value: any, ttl: number)
	local map = stateMap
	if not map then
		return
	end
	task.spawn(function()
		local ok = withRetries(`state set {key}`, function()
			map:SetAsync(key, value, math.clamp(math.floor(ttl), 1, 86400))
		end)
		health.memory = if ok then "ok" else "unavailable"
	end)
end

function CrossServer.removeState(key: string)
	local map = stateMap
	if not map then
		return
	end
	task.spawn(function()
		local ok = withRetries(`state remove {key}`, function()
			map:RemoveAsync(key)
		end)
		health.memory = if ok then "ok" else "unavailable"
	end)
end

function CrossServer.getState(key: string): any
	local map = stateMap
	if not map then
		return nil
	end
	local ok, value = withTimeout(CALL_TIMEOUT, function()
		return map:GetAsync(key)
	end)
	health.memory = if ok then "ok" else "unavailable"
	return if ok then value else nil
end

-- Mirrors one audit entry of a global-scope action (expires after Config.Audit.globalTtl).
function CrossServer.recordGlobalAudit(entry: { [string]: any })
	if not auditMap then
		return
	end
	local map = auditMap :: MemoryStoreSortedMap
	task.spawn(function()
		local key = string.format("%012d_%s", entry.at, string.sub(entry.correlation, 1, 24))
		local ok = withTimeout(CALL_TIMEOUT, function()
			map:SetAsync(key, entry, Config.Audit.globalTtl)
		end)
		health.memory = if ok then "ok" else "unavailable"
	end)
end

function CrossServer.readGlobalAudit(n: number): (boolean, any)
	if not auditMap then
		return false, "MemoryStore unavailable"
	end
	local map = auditMap :: MemoryStoreSortedMap
	local ok, items = withTimeout(CALL_TIMEOUT, function()
		return map:GetRangeAsync(Enum.SortDirection.Descending, math.clamp(n, 1, 200))
	end)
	if not ok then
		health.memory = "unavailable"
		return false, "MemoryStore unavailable (unpublished Studio place or quota)."
	end
	health.memory = "ok"
	local list = {}
	for _, item in items do
		table.insert(list, item.value)
	end
	return true, list
end

function CrossServer.start()
	if not published then
		health.messaging = "unavailable (unpublished place)"
		health.memory = "unavailable (unpublished place)"
		return
	end
	local okMap, map = pcall(function()
		return MemoryStoreService:GetHashMap(X.stateMap)
	end)
	stateMap = if okMap then map else nil
	local okAudit, sorted = pcall(function()
		return MemoryStoreService:GetSortedMap(X.auditMap)
	end)
	auditMap = if okAudit then sorted else nil
	task.spawn(function()
		local ok, err = withTimeout(15, function()
			MessagingService:SubscribeAsync(X.topic, function(message)
				CrossServer.receive(message.Data)
			end)
			MessagingService:SubscribeAsync(X.ackTopic, function(message)
				onAck(message.Data)
			end)
		end)
		health.messaging = if ok then "ok" else "unavailable"
		if not ok then
			warn(`[Admin.CrossServer] MessagingService unavailable: {err}`)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			seen.prune(os.time())
		end
	end)
end

return CrossServer
