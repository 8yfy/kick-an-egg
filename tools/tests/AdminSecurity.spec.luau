-- Offline security tests for the admin system's pure modules (no Roblox needed):
--   lune run tools/tests/AdminSecurity.spec.luau
-- Authorization, Schema, Limiter, Audit, Envelope and the central Pipeline are loaded from src/server/Admin and
-- attacked with fake players and messages. Roblox glue (remotes, MessagingService, MemoryStore, the UI) is
-- covered by the Studio tests in tools/tests/AdminStudio.server.lua.
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local function load(name: string): any
	local path = `src/server/Admin/{name}.luau`
	return luau.load(fs.readFile(path), { debugName = path })()
end

local Authorization = load("Authorization")
local Schema = load("Schema")
local Limiter = load("Limiter")
local Audit = load("Audit")
local Envelope = load("Envelope")
local Pipeline = load("Pipeline")

local checks = 0
local function check(cond: any, label: string)
	assert(cond, label)
	checks += 1
end
local function eq(a: any, b: any, label: string)
	assert(a == b, `{label}: expected {tostring(b)}, got {tostring(a)}`)
	checks += 1
end

-- Fixtures ------------------------------------------------------------------------------------------------------

local function set(list)
	local s = {}
	for _, v in list do
		s[v] = true
	end
	return s
end
local ROLES = {
	Tester = { rank = 1, color = "cyan", permissions = set({ "panel.open", "lab.use" }) },
	Developer = {
		rank = 2,
		color = "violet",
		permissions = set({ "panel.open", "lab.use", "weather.server", "logs.view" }),
	},
	Owner = {
		rank = 3,
		color = "gold",
		permissions = set({ "panel.open", "lab.use", "weather.server", "logs.view", "weather.global" }),
	},
}
local ALLOW = {
	users = { [100] = "Owner", [200] = "Developer", [300] = "Tester", [0] = "Owner", [400] = "Admin", [-5] = "Owner" },
	studioTestUsers = { [-1] = "Owner", [7] = "Owner" },
}

-- Authorization -------------------------------------------------------------------------------------------------

local live = Authorization.new(ALLOW, ROLES, false)
eq(live.roleOf(100), "Owner", "listed owner")
eq(live.roleOf(300), "Tester", "listed tester")
eq(live.roleOf(999), nil, "unlisted user has no role")
eq(live.roleOf("100"), nil, "string UserId is not accepted")
eq(live.roleOf(100.5), nil, "fractional UserId")
eq(live.roleOf(0 / 0), nil, "NaN UserId")
eq(live.roleOf(0), nil, "zero UserId entry rejected")
eq(live.roleOf(400), nil, "unknown role entry rejected")
eq(live.roleOf(-5), nil, "negative id in live list rejected")
eq(live.roleOf(-1), nil, "studio test id ignored outside Studio")
eq(#live.rejected, 3, "invalid allowlist entries reported")
local studio = Authorization.new(ALLOW, ROLES, true)
eq(studio.roleOf(-1), "Owner", "studio test id honoured in Studio")
eq(studio.roleOf(7), nil, "positive id in studio test list rejected")
check(live.can("Owner", "weather.global"), "owner has global weather")
check(not live.can("Developer", "weather.global"), "developer lacks global weather")
check(not live.can("Tester", "weather.server"), "tester lacks server weather")
check(not live.can(nil, "panel.open"), "nil role denied")
check(not live.can("owner", "panel.open"), "role names are case-sensitive")
check(not live.can("Owner", "made.up"), "unknown permission denied")
check(not pcall(function()
	(live :: any).roleOf = function()
		return "Owner"
	end
end), "authorization object is frozen")
eq(live.rank(nil), 0, "no role = rank 0")

-- Schema --------------------------------------------------------------------------------------------------------

local LIMITS = { maxKeys = 4, maxString = 50 }
local specs = {
	n = { type = "number", min = 1, max = 10, integer = true },
	s = { type = "string", maxLength = 20, optional = true },
	e = { type = "enum", options = { "A", "B" }, default = "A" },
	b = { type = "boolean", optional = true },
}
local function v(params)
	return Schema.validate(specs, params, LIMITS)
end
local ok, clean = v({ n = 3 })
check(ok and clean.n == 3 and clean.e == "A", "valid params + default")
check(not (v({ n = 11 })), "above max rejected (not clamped)")
check(not (v({ n = 0 })), "below min rejected")
check(not (v({ n = 2.5 })), "fraction rejected")
check(not (v({ n = 0 / 0 })), "NaN rejected")
check(not (v({ n = math.huge })), "infinity rejected")
check(not (v({ n = "3" })), "string for number rejected")
check(not (v({})), "missing required rejected")
check(not (v({ n = 3, userId = 100 })), "undeclared key (spoofed UserId) rejected")
check(not (v({ n = 3, e = "C" })), "enum outside options rejected")
check(not (v({ n = 3, s = "bad\0text" })), "control characters rejected")
check(not (v({ n = 3, s = string.rep("x", 21) })), "long string rejected")
check(not (v({ n = 3, s = { "nested" } })), "nested table rejected")
check(not (v({ n = 3, [1] = "array" })), "non-string key rejected")
check(not (v(setmetatable({ n = 3 }, {}))), "table with metatable rejected")
check(not (v({ n = 3, s = "a", b = true, e = "A", x = 1 })), "too many keys rejected")
check(not (v("loadstring('x')")), "script source string as params rejected")
local okr, cleanR = v({ n = 3, scope = "global", confirmed = true })
check(okr and cleanR.scope == nil, "reserved keys skipped by schema")
check(not Schema.check({ x = { type = "number" } }), "number without bounds fails the startup check")
check(not Schema.check({ scope = { type = "boolean" } }), "reserved name fails the startup check")
eq(#Schema.describe(specs), 4, "describe lists every param")

-- Limiter -------------------------------------------------------------------------------------------------------

local t = 0
local lim = Limiter.new(2, 3, function()
	return t
end)
check(lim.allow(1) and lim.allow(1) and lim.allow(1), "burst of 3 allowed")
check(not lim.allow(1), "4th request in the same instant refused")
check(lim.allow(2), "other admins have their own bucket")
t = 0.5
check(lim.allow(1), "refills over time")
check((lim.cooldown(1, "x", 5)), "first run passes cooldown")
local free, left = lim.cooldown(1, "x", 5)
check(not free and left > 4.9, "second run inside cooldown refused")
t = 6
check((lim.cooldown(1, "x", 5)), "cooldown expires")
check(lim.enter(1, 2) and lim.enter(1, 2) and not lim.enter(1, 2), "in-flight cap")
lim.leave(1)
check(lim.enter(1, 2), "slot freed after leave")

-- Audit ---------------------------------------------------------------------------------------------------------

local now = 1000
local log = Audit.new(5, function()
	return now
end)
for i = 1, 7 do
	log.add({ admin = 100, adminName = "Kai", command = if i % 2 == 0 then "b" else "a", outcome = "ok", server = "s1" })
end
eq(log.size(), 5, "ring buffer bounded")
eq(log.latest(1)[1].id, 7, "newest first")
eq(log.query({ command = "b" }).total, 2, "filter by command (oldest dropped)")
eq(log.query(nil, 2, 2).page, 2, "pagination")
eq(log.query(nil, 99, 2).page, 3, "page clamped")
log.add({ admin = 200, adminName = "Ana", command = "a", outcome = "fail", category = "forbidden", server = "s2" })
eq(log.query({ outcome = "fail" }).total, 1, "filter by outcome")
eq(log.query({ server = "s2" }).total, 1, "filter by server")
eq(log.query({ admin = 200 }).total, 1, "filter by admin")
check(#Audit.summarize({ text = string.rep("y", 400) }) <= 160, "param summary truncated")
eq(Audit.summarize({ confirmed = true, a = 1 }), "a=1", "confirmed not logged")

-- Envelope ------------------------------------------------------------------------------------------------------

local seen = Envelope.seen(3)
local function opts(n)
	return { now = n or 5000, maxSkew = 30, maxTtl = 60, self = "me", seen = seen }
end
local function env(over)
	local e = Envelope.build(
		{
			id = "id-1",
			at = 5000,
			src = "other",
			uid = 100,
			name = "Kai",
			cmd = "weather.start",
			p = { weather = "Rainy" },
		},
		60
	)
	for k, val in over or {} do
		e[k] = val
	end
	return e
end
check((Envelope.validate(env(), opts())), "valid envelope accepted")
local _, why = Envelope.validate(env(), opts())
eq(why, "duplicate", "duplicate rejected")
_, why = Envelope.validate(env({ id = "id-2" }), opts(5061))
eq(why, "expired", "expired rejected")
_, why = Envelope.validate(env({ id = "id-3", at = 5100, exp = 5150 }), opts())
eq(why, "future", "future-dated rejected")
_, why = Envelope.validate(env({ id = "id-4", src = "me" }), opts())
eq(why, "self", "own broadcast ignored")
_, why = Envelope.validate(env({ id = "id-5", extra = 1 }), opts())
eq(why, "malformed", "unknown field rejected")
_, why = Envelope.validate(env({ id = "id-6", p = { nested = {} } }), opts())
eq(why, "malformed", "nested param rejected")
_, why = Envelope.validate(env({ id = "id-7", p = { src = string.rep("x", 300) } }), opts())
eq(why, "malformed", "oversized string rejected")
_, why = Envelope.validate(env({ id = "id-8", exp = 9000 }), opts())
eq(why, "malformed", "ttl beyond the limit rejected")
_, why = Envelope.validate(env({ id = "bad id!" }), opts())
eq(why, "malformed", "bad id characters rejected")
_, why = Envelope.validate(env({ id = "id-9", v = 2 }), opts())
eq(why, "version", "unknown version rejected")
_, why = Envelope.validate(env({ id = "id-10", uid = 0 / 0 }), opts())
eq(why, "malformed", "NaN uid rejected")
_, why = Envelope.validate(env({ id = "id-11", cmd = "require(1)" }), opts())
eq(why, "malformed", "code in command id rejected")
_, why = Envelope.validate("not a table", opts())
eq(why, "malformed", "non-table rejected")
for i = 20, 30 do
	seen.add(`x{i}`, 99999)
end
check(seen.size() <= 3, "seen cache bounded")
check((Envelope.validateAck(Envelope.ack("id-1", "s2", true, "ok"))), "valid ack")
check(not (Envelope.validateAck({ v = 1, ack = "id-1", src = "s2", ok = "yes", code = "ok" })), "bad ack rejected")

-- Pipeline ------------------------------------------------------------------------------------------------------

local calls: { [string]: number } = {}
local broadcasts = {}
local function cmd(id, perm, extra)
	local c = {
		id = id,
		name = id,
		description = id,
		category = "test",
		permission = perm,
		kind = "action",
		handler = function(ctx, params)
			calls[id] = (calls[id] or 0) + 1
			return true, { remote = ctx.remote, n = params.n }
		end,
	}
	for k, val in extra or {} do
		c[k] = val
	end
	return c
end
local commands = {
	["t.read"] = cmd("t.read", "panel.open", { kind = "read" }),
	["t.lab"] = cmd("t.lab", "lab.use", { params = { n = { type = "number", min = 1, max = 5, integer = true } } }),
	["t.dev"] = cmd("t.dev", "weather.server", { cooldown = 5 }),
	["t.global"] = cmd(
		"t.global",
		"weather.server",
		{ scopes = { "server", "global" }, globalPermission = "weather.global", crossServer = true }
	),
	["t.local"] = cmd(
		"t.local",
		"weather.server",
		{ scopes = { "server", "global" }, globalPermission = "weather.global" }
	),
	["t.err"] = cmd("t.err", "panel.open", {
		handler = function()
			error("secret internal path ServerScriptService.Server.Admin")
		end,
	}),
	["t.env"] = cmd("t.env", "panel.open", { environments = { "staging" } }),
	["t.confirm"] = cmd("t.confirm", "panel.open", { confirm = true }),
	["t.pre"] = cmd("t.pre", "panel.open", {
		precheck = function()
			return false, "Too many lab models.", "limit"
		end,
	}),
}
local clockT = 0
local pAudit = Audit.new(200, function()
	return 1
end)
local connected = {}
local pipe = Pipeline.new({
	auth = live,
	commands = commands,
	schema = Schema,
	limiter = Limiter.new(5, 10, function()
		return clockT
	end),
	audit = pAudit,
	limits = {
		maxParamKeys = 8,
		maxStringLength = 100,
		maxInFlight = 2,
		globalCooldown = 10,
		unauthorizedLogEvery = 10,
	},
	environment = function()
		return "production"
	end,
	clock = function()
		return clockT
	end,
	now = function()
		return 1
	end,
	serverId = "server-a",
	newId = (function()
		local i = 0
		return function()
			i += 1
			return `c{i}`
		end
	end)(),
	isConnected = function(p)
		return connected[p] == true
	end,
	broadcast = function(c, params, ctx)
		table.insert(broadcasts, { cmd = c.id, params = params, uid = ctx.userId })
		return { status = "published", id = ctx.correlation }
	end,
	summarize = Audit.summarize,
})
local function player(id, name)
	local p = { UserId = id, Name = name or `p{id}` }
	connected[p] = true
	return p
end
local owner, dev, tester, stranger = player(100), player(200), player(300), player(555)
local function call(p, id, params)
	clockT += 0.5
	return pipe.execute(p, id, params)
end

local r = pipe.execute(stranger, "t.read", {})
eq(r.code, "unauthorized", "non-admin denied")
call(stranger, "t.read", {})
eq(pAudit.query({ admin = 555 }).total, 1, "unauthorized attempts audited but throttled")
r = call(stranger, "t.read", { userId = 100, role = "Owner" })
eq(r.code, "unauthorized", "spoofed UserId/role in params ignored")
eq(calls["t.read"], nil, "no handler ran for unauthorized calls")
r = call({ UserId = "100", Name = "x" }, "t.read", {})
eq(r.code, "malformed", "string UserId on the player object rejected")
r = call(nil, "t.read", {})
eq(r.code, "malformed", "missing player rejected")

r = call(tester, "t.read", {})
check(r.ok and calls["t.read"] == 1, "tester read ok")
r = call(tester, "t.dev", {})
eq(r.code, "forbidden", "tester can't run a developer command (escalation)")
r = call(tester, "t.global", { scope = "global", confirmed = true })
eq(r.code, "forbidden", "tester can't escalate via scope")
r = call(dev, "t.global", { scope = "global", confirmed = true })
eq(r.code, "forbidden", "developer lacks global scope")
r = call(owner, "t.read", { scope = "global" })
eq(r.code, "scope", "global scope on a server-only command refused")
r = call(owner, "t.read", { scope = "everywhere" })
eq(r.code, "scope", "unknown scope refused")
r = call(owner, "nope.cmd", {})
eq(r.code, "unknown_command", "unknown command id")
r = call(owner, "../../ServerStorage", {})
eq(r.code, "malformed", "path-like command id")
r = call(owner, string.rep("a", 500), {})
eq(r.code, "malformed", "huge command id")
r = call(owner, { "t.read" }, {})
eq(r.code, "malformed", "table command id")
r = call(owner, "t.lab", { n = 9 })
eq(r.code, "invalid_params", "out-of-range param")
r = call(owner, "t.lab", { n = 2, source = "rbxassetid://1" })
eq(r.code, "invalid_params", "client-supplied asset id refused")
r = call(owner, "t.lab", "print('hi')")
eq(r.code, "invalid_params", "script source as params refused")
eq(calls["t.lab"], nil, "no handler ran for invalid params")
r = call(owner, "t.env", {})
eq(r.code, "environment", "staging-only command refused in production")
r = call(owner, "t.confirm", {})
eq(r.code, "confirm_required", "confirmation required")
r = call(owner, "t.confirm", { confirmed = true })
check(r.ok, "confirmed run ok")
r = call(owner, "t.pre", {})
check(r.code == "limit" and r.message == "Too many lab models.", "precheck limit")
r = call(owner, "t.err", {})
eq(r.code, "handler_error", "handler error caught")
check(not string.find(r.message, "ServerScriptService", 1, true), "error details not leaked to the client")
eq(pAudit.query({ outcome = "fail", command = "t.err" }).entries[1].correlation, r.correlation, "audit has the ref")

clockT = 100
r = call(dev, "t.dev", {})
check(r.ok, "developer command ok")
r = call(dev, "t.dev", {})
eq(r.code, "cooldown", "cooldown enforced")

clockT = 200
r = call(owner, "t.global", { scope = "global" })
eq(r.code, "confirm_required", "global scope needs confirmation")
r = call(owner, "t.global", { scope = "global", confirmed = true })
check(r.ok and r.delivery and r.delivery.status == "published", "global run broadcast")
eq(#broadcasts, 1, "exactly one broadcast")
eq(broadcasts[1].uid, 100, "broadcast carries the real initiator")
r = call(owner, "t.global", { scope = "global", confirmed = true })
eq(r.code, "cooldown", "global cooldown")

clockT = 300
local spam = 0
for _ = 1, 30 do
	if pipe.execute(tester, "t.read", {}).code == "rate_limited" then
		spam += 1
	end
end
check(spam >= 15, "spam is rate limited")

connected[dev] = nil
clockT = 400
local before = calls["t.dev"]
r = call(dev, "t.dev", {})
eq(r.code, "disconnected", "call after disconnect refused")
eq(calls["t.dev"], before, "no handler after disconnect")

-- cross-server receive path
local function remote(over)
	local e = { id = "m1", src = "server-b", uid = 100, name = "Kai", cmd = "t.global", p = {} }
	for k, val in over or {} do
		e[k] = val
	end
	return e
end
clockT = 500
r = pipe.executeRemote(remote())
check(r.ok and r.data.remote == true, "valid broadcast runs the same handler, flagged remote")
eq(#broadcasts, 1, "receivers never re-broadcast")
eq(pipe.executeRemote(remote({ uid = 555 })).code, "unauthorized", "broadcast from non-admin refused")
eq(pipe.executeRemote(remote({ uid = 200 })).code, "forbidden", "broadcast by a role without global permission")
eq(pipe.executeRemote(remote({ cmd = "t.local" })).code, "scope", "command not marked cross-server")
eq(pipe.executeRemote(remote({ cmd = "t.missing" })).code, "unknown_command", "unknown broadcast command")
eq(pipe.executeRemote(remote({ cmd = "t.lab", p = {} })).code, "scope", "lab commands never cross servers")
local okRemote = pipe.executeRemote(remote({ p = { bogus = 1 } }))
eq(okRemote.code, "invalid_params", "broadcast params re-validated")
eq(pAudit.query({ server = "server-b" }).total >= 5, true, "remote runs audited with their origin")

-- metadata
local meta = pipe.describe("Tester")
local ids = {}
for _, m in meta do
	ids[m.id] = m
end
check(ids["t.read"] and not ids["t.dev"], "describe only lists permitted commands")
local ownerMeta = {}
for _, m in pipe.describe("Owner") do
	ownerMeta[m.id] = m
end
eq(#ownerMeta["t.global"].scopes, 2, "owner sees global scope")
local devMeta = {}
for _, m in pipe.describe("Developer") do
	devMeta[m.id] = m
end
eq(#devMeta["t.global"].scopes, 1, "developer only sees server scope")

local problems = Pipeline.checkRegistry({
	bad = { id = "bad", permission = "nope", scopes = { "global" }, params = { x = { type = "number" } } },
}, { ["panel.open"] = true }, Schema)
check(#problems >= 4, "registry check catches bad definitions")

print(`AdminSecurity.spec: {checks} checks passed`)
