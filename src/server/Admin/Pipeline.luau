--!strict
-- Pure (every dependency injected; no Roblox services, no requires): the ONE path every admin request takes.
--
--   real Player.UserId -> allowlist role -> still connected -> request rate -> known command -> role permission
--   -> environment -> parameter validation -> scope (+ its own permission) -> confirmation -> limits / target
--   scope (precheck) -> cooldown -> concurrency cap -> registered handler (pcall) -> cross-server broadcast
--   (global scope only) -> audit entry -> safe result
--
-- Nothing the client sends is trusted: the UserId comes from the Player object Roblox gives the server, the
-- command id must be registered, parameters must match the command's server-side schema. Errors never leak
-- stack traces to clients (they get a category, a short message and a correlation id that matches the audit).
-- Cross-server messages run through executeRemote: the same registry, permissions, schema, limits and handlers,
-- re-checked against THIS server's allowlist.

export type Result = {
	ok: boolean,
	code: string,
	message: string,
	data: any?,
	delivery: any?,
	correlation: string,
	at: number,
}

export type Context = {
	player: any?, -- the admin's Player (nil for cross-server runs)
	userId: number,
	name: string,
	role: string,
	scope: string,
	correlation: string,
	remote: boolean,
	origin: string?,
	environment: string,
	server: string,
}

export type Command = {
	id: string,
	name: string,
	runnerName: string?,
	description: string,
	category: string,
	permission: string,
	kind: "read" | "action",
	scopes: { string }?,
	globalPermission: string?,
	environments: { string }?,
	params: { [string]: any }?,
	cooldown: number?,
	globalCooldown: number?,
	confirm: boolean?,
	audit: ("all" | "failures" | "none")?,
	runner: boolean?,
	crossServer: boolean?,
	target: ((params: { [string]: any }) -> string?)?,
	precheck: ((ctx: Context, params: { [string]: any }) -> (boolean, string?, string?))?,
	handler: (ctx: Context, params: { [string]: any }) -> (boolean, any, string?),
	reset: ((ctx: Context) -> (boolean, any))?,
}

local Pipeline = {}

local COMMAND_PATTERN = "^[%a][%w_%.]*$"

local function contains(list: { string }?, value: string): boolean
	for _, v in list or {} do
		if v == value then
			return true
		end
	end
	return false
end

function Pipeline.new(deps: { [string]: any })
	local auth = deps.auth
	local commands: { [string]: Command } = deps.commands
	local Schema = deps.schema
	local limiter = deps.limiter
	local audit = deps.audit
	local limits = deps.limits
	local clock: () -> number = deps.clock
	local now: () -> number = deps.now
	local serverId: string = deps.serverId
	local newId: () -> string = deps.newId
	local isConnected: (any) -> boolean = deps.isConnected
	local warnFn: (string) -> () = deps.warn or function() end
	local summarize = deps.summarize
	local schemaLimits = { maxKeys = limits.maxParamKeys, maxString = limits.maxStringLength }
	local quietUntil: { [string]: number } = {} -- throttles repetitive audit entries (unauthorized / spam)

	local pipeline = {}

	local function quiet(key: string, seconds: number): boolean
		local t = clock()
		local untilAt = quietUntil[key]
		if untilAt and t < untilAt then
			return true
		end
		quietUntil[key] = t + seconds
		return false
	end

	local function result(ok: boolean, code: string, message: string, correlation: string, data: any?): Result
		return { ok = ok, code = code, message = message, data = data, correlation = correlation, at = now() }
	end

	local function record(
		ctx: { [string]: any },
		cmd: Command?,
		commandId: string,
		clean: any,
		res: Result,
		origin: string?
	)
		local policy = if cmd then cmd.audit or (if cmd.kind == "read" then "failures" else "all") else "all"
		if policy == "none" or (policy == "failures" and res.ok) then
			return
		end
		local target: string? = nil
		if cmd and cmd.target and typeof(clean) == "table" then
			local ok, t = pcall(cmd.target, clean)
			target = if ok and typeof(t) == "string" then t else nil
		end
		audit.add({
			admin = ctx.userId,
			adminName = ctx.name,
			role = ctx.role,
			command = commandId,
			target = target,
			scope = ctx.scope or "server",
			params = if typeof(clean) == "table" then summarize(clean) else "",
			outcome = if res.ok then "ok" else "fail",
			category = res.code,
			message = if res.ok then nil else res.message,
			server = serverId,
			origin = origin,
			correlation = res.correlation,
		})
	end

	-- Runs the handler and, for global scope, the broadcast. Shared by local and cross-server runs.
	local function run(ctx: Context, cmd: Command, clean: { [string]: any }): Result
		local ok, a, b, c = pcall(cmd.handler, ctx, clean)
		if not ok then
			warnFn(`[Admin] {cmd.id} failed ({ctx.correlation}): {a}`)
			return result(
				false,
				"handler_error",
				`The command failed on the server (ref {ctx.correlation}).`,
				ctx.correlation
			)
		end
		if a ~= true then
			local message = if typeof(b) == "string" then b else "The command was refused."
			return result(false, if typeof(c) == "string" then c else "failed", message, ctx.correlation)
		end
		local res = result(true, "ok", "Done.", ctx.correlation, b)
		if ctx.scope == "global" and not ctx.remote and deps.broadcast then
			local sent, delivery = pcall(deps.broadcast, cmd, clean, ctx)
			res.delivery = if sent then delivery else { status = "failed", detail = "broadcast error" }
			if not sent then
				warnFn(`[Admin] broadcast of {cmd.id} failed: {delivery}`)
			end
		end
		return res
	end

	-- `params` may contain `scope` ("server" | "global") and `confirmed` (UI confirmation, not a security check).
	function pipeline.execute(player: any, commandId: any, params: any): Result
		local correlation = newId()
		local isPlayer = typeof(player) == "table" or (typeof(player) == "Instance" and player:IsA("Player"))
		local userId = if isPlayer then player.UserId else nil
		if typeof(userId) ~= "number" then
			return result(false, "malformed", "Bad request.", correlation)
		end
		local name = tostring(player.Name)
		local role = auth.roleOf(userId)
		local ctxInfo = { userId = userId, name = name, role = role or "none", scope = "server" }
		local safeId = if typeof(commandId) == "string" and #commandId <= 64 then commandId else "?"

		-- 1. allowlist (by the real UserId only)
		if not role then
			local res = result(false, "unauthorized", "Not authorized.", correlation)
			if not quiet(`u{userId}`, limits.unauthorizedLogEvery) then
				record(ctxInfo, nil, safeId, nil, res)
			end
			return res
		end
		-- 2. calls after disconnect
		if not isConnected(player) then
			local res = result(false, "disconnected", "You are no longer in this server.", correlation)
			record(ctxInfo, nil, safeId, nil, res)
			return res
		end
		-- 3. request flood
		if not limiter.allow(userId) then
			local res = result(false, "rate_limited", "Too many requests; slow down.", correlation)
			if not quiet(`r{userId}`, 5) then
				record(ctxInfo, nil, safeId, nil, res)
			end
			return res
		end
		-- 4. registered command
		if typeof(commandId) ~= "string" or #commandId > 64 or not string.match(commandId, COMMAND_PATTERN) then
			local res = result(false, "malformed", "Bad command id.", correlation)
			record(ctxInfo, nil, safeId, nil, res)
			return res
		end
		local cmd = commands[commandId]
		if not cmd then
			local res = result(false, "unknown_command", "Unknown command.", correlation)
			record(ctxInfo, nil, commandId, nil, res)
			return res
		end
		-- 5. role permission
		if not auth.can(role, cmd.permission) then
			local res = result(false, "forbidden", "Your role can't run this command.", correlation)
			record(ctxInfo, cmd, commandId, nil, res)
			return res
		end
		-- 6. environment
		local environment = deps.environment()
		if cmd.environments and not contains(cmd.environments, environment) then
			local res = result(
				false,
				"environment",
				`Only available in: {table.concat(cmd.environments, ", ")} (this server is {environment}).`,
				correlation
			)
			record(ctxInfo, cmd, commandId, nil, res)
			return res
		end
		-- 7. parameters
		if params ~= nil and (typeof(params) ~= "table" or getmetatable(params) ~= nil) then
			local res = result(false, "invalid_params", "Parameters must be a table.", correlation)
			record(ctxInfo, cmd, commandId, nil, res)
			return res
		end
		local raw = params or {}
		local valid, clean = Schema.validate(cmd.params, raw, schemaLimits)
		if not valid then
			local res = result(false, "invalid_params", clean, correlation)
			record(ctxInfo, cmd, commandId, nil, res)
			return res
		end
		-- 8. scope
		local scope = raw.scope
		if scope == nil then
			scope = "server"
		end
		ctxInfo.scope = if scope == "global" then "global" else "server"
		local scopes = cmd.scopes or { "server" }
		if (scope ~= "server" and scope ~= "global") or not contains(scopes, scope) then
			local res = result(false, "scope", "That scope isn't allowed for this command.", correlation)
			record(ctxInfo, cmd, commandId, clean, res)
			return res
		end
		if scope == "global" and not (cmd.globalPermission and auth.can(role, cmd.globalPermission)) then
			local res = result(false, "forbidden", "Your role can't run this on all servers.", correlation)
			record(ctxInfo, cmd, commandId, clean, res)
			return res
		end
		-- 9. confirmation (UX guard for dangerous commands; the security checks are everything else)
		if (cmd.confirm or scope == "global") and raw.confirmed ~= true then
			local res = result(false, "confirm_required", "Confirm this action first.", correlation)
			record(ctxInfo, cmd, commandId, clean, res)
			return res
		end
		local ctx: Context = {
			player = player,
			userId = userId,
			name = name,
			role = role,
			scope = scope,
			correlation = correlation,
			remote = false,
			origin = nil,
			environment = environment,
			server = serverId,
		}
		-- 10. limits and target scope (lab counts, data safety, rank of the target, ...)
		if cmd.precheck then
			local ok, okay, message, category = pcall(cmd.precheck, ctx, clean)
			if not ok or okay ~= true then
				local res = result(
					false,
					if ok and typeof(category) == "string" then category else "limit",
					if ok and typeof(message) == "string" then message else "Not allowed right now.",
					correlation
				)
				if not ok then
					warnFn(`[Admin] precheck {cmd.id} errored: {okay}`)
				end
				record(ctxInfo, cmd, commandId, clean, res)
				return res
			end
		end
		-- 11. cooldown (global runs have a longer one)
		local wait = cmd.cooldown or 0
		if scope == "global" then
			wait = math.max(wait, cmd.globalCooldown or limits.globalCooldown)
		end
		local free, left = limiter.cooldown(userId, `{cmd.id}:{scope}`, wait)
		if not free then
			local res = result(false, "cooldown", string.format("Cooling down: %.1f s left.", left), correlation)
			if not quiet(`c{userId}{cmd.id}`, 3) then
				record(ctxInfo, cmd, commandId, clean, res)
			end
			return res
		end
		-- 12. concurrency cap, then the handler
		if not limiter.enter(userId, limits.maxInFlight) then
			local res = result(false, "busy", "Too many requests running at once.", correlation)
			record(ctxInfo, cmd, commandId, clean, res)
			return res
		end
		local res = run(ctx, cmd, clean)
		limiter.leave(userId)
		record(ctxInfo, cmd, commandId, clean, res)
		return res
	end

	-- A broadcast from another server (already shape/expiry/duplicate-checked by Envelope.validate).
	function pipeline.executeRemote(envelope: { [string]: any }): Result
		local correlation = tostring(envelope.id)
		local userId = envelope.uid
		local role = auth.roleOf(userId)
		local ctxInfo = {
			userId = if typeof(userId) == "number" then userId else 0,
			name = tostring(envelope.name or "?"),
			role = role or "none",
			scope = "global",
		}
		local commandId = if typeof(envelope.cmd) == "string" then envelope.cmd else "?"
		local function deny(code: string, message: string, cmd: Command?, clean: any?): Result
			local res = result(false, code, message, correlation)
			record(ctxInfo, cmd, commandId, clean, res, envelope.src)
			return res
		end
		if not role then
			return deny("unauthorized", "Sender is not an admin on this server.")
		end
		local cmd = commands[commandId]
		if not cmd then
			return deny("unknown_command", "Unknown command.")
		end
		if not cmd.crossServer or not contains(cmd.scopes, "global") then
			return deny("scope", "Command can't run across servers.", cmd)
		end
		if not (auth.can(role, cmd.permission) and cmd.globalPermission and auth.can(role, cmd.globalPermission)) then
			return deny("forbidden", "Sender may not run this on all servers.", cmd)
		end
		local environment = deps.environment()
		if cmd.environments and not contains(cmd.environments, environment) then
			return deny("environment", "Not available in this environment.", cmd)
		end
		if not limiter.allow(userId) then
			return deny("rate_limited", "Too many broadcasts.", cmd)
		end
		local valid, clean = Schema.validate(cmd.params, envelope.p, schemaLimits)
		if not valid then
			return deny("invalid_params", clean, cmd)
		end
		local ctx: Context = {
			player = nil,
			userId = userId,
			name = ctxInfo.name,
			role = role,
			scope = "global",
			correlation = correlation,
			remote = true,
			origin = envelope.src,
			environment = environment,
			server = serverId,
		}
		if cmd.precheck then
			local ok, okay, message, category = pcall(cmd.precheck, ctx, clean)
			if not ok or okay ~= true then
				return deny(
					if ok and typeof(category) == "string" then category else "limit",
					if ok and typeof(message) == "string" then message else "Not allowed.",
					cmd,
					clean
				)
			end
		end
		local res = run(ctx, cmd, clean)
		record(ctxInfo, cmd, commandId, clean, res, envelope.src)
		return res
	end

	-- Client-safe metadata of the commands this role may see (no handlers, no other roles, no allowlist).
	function pipeline.describe(role: string): { { [string]: any } }
		local environment = deps.environment()
		local list = {}
		for id, cmd in commands do
			if not auth.can(role, cmd.permission) then
				continue
			end
			local scopes = {}
			for _, s in cmd.scopes or { "server" } do
				if s == "server" or (cmd.globalPermission and auth.can(role, cmd.globalPermission)) then
					table.insert(scopes, s)
				end
			end
			table.insert(list, {
				id = id,
				name = cmd.name,
				runnerName = cmd.runnerName,
				description = cmd.description,
				category = cmd.category,
				kind = cmd.kind,
				scopes = scopes,
				cooldown = cmd.cooldown or 0,
				confirm = cmd.confirm == true,
				runner = cmd.runner == true,
				environments = cmd.environments,
				available = cmd.environments == nil or contains(cmd.environments, environment),
				params = Schema.describe(cmd.params),
			})
		end
		table.sort(list, function(a, b)
			return a.id < b.id
		end)
		return list
	end

	function pipeline.forget(userId: number)
		limiter.forget(userId)
	end

	return table.freeze(pipeline)
end

-- Startup validation of the registry: unique ids, known permissions, valid schemas. Returns problems found.
function Pipeline.checkRegistry(
	commands: { [string]: Command },
	knownPermissions: { [string]: boolean },
	Schema: any
): { string }
	local problems = {}
	for id, cmd in commands do
		if cmd.id ~= id or not string.match(id, COMMAND_PATTERN) then
			table.insert(problems, `{id}: id mismatch or invalid`)
		end
		if not knownPermissions[cmd.permission] then
			table.insert(problems, `{id}: unknown permission {tostring(cmd.permission)}`)
		end
		if cmd.globalPermission and not knownPermissions[cmd.globalPermission] then
			table.insert(problems, `{id}: unknown global permission {cmd.globalPermission}`)
		end
		if contains(cmd.scopes, "global") and not cmd.globalPermission then
			table.insert(problems, `{id}: global scope without a global permission`)
		end
		if typeof(cmd.handler) ~= "function" then
			table.insert(problems, `{id}: no handler`)
		end
		local ok, message = Schema.check(cmd.params)
		if not ok then
			table.insert(problems, `{id}: {message}`)
		end
	end
	return problems
end

return table.freeze(Pipeline)
