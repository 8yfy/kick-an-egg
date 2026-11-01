--!strict
-- Pure (no Roblox services, no requires): the bounded cross-server message format and its receiver-side checks.
--   { v = 1, id, at, exp, src, uid, name, cmd, p }
--   id   unique message id (GUID)         at/exp  unix seconds sent / expires (exp - at <= ttl)
--   src  sending server id                uid     UserId of the admin who started it (re-checked on every
--   name that admin's name (for logs)              receiver against ITS allowlist by the Pipeline)
--   cmd  registered command id            p       validated scalar params (re-validated by the receiver)
-- Malformed, oversized, expired, future-dated, duplicate and self-sent messages are rejected here; unknown or
-- disallowed commands are rejected by Pipeline.executeRemote.

local Envelope = {}

Envelope.VERSION = 1
local ALLOWED =
	{ v = true, id = true, at = true, exp = true, src = true, uid = true, name = true, cmd = true, p = true }
local ACK_ALLOWED = { v = true, ack = true, src = true, ok = true, code = true }

local function finite(n: any): boolean
	return typeof(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function token(s: any, maxLen: number): boolean
	return typeof(s) == "string" and #s >= 1 and #s <= maxLen and string.match(s, "^[%w%-_]+$") ~= nil
end

local function plain(t: any): boolean
	return typeof(t) == "table" and getmetatable(t) == nil
end

export type Seen = {
	has: (id: string) -> boolean,
	add: (id: string, exp: number) -> (),
	prune: (now: number) -> (),
	size: () -> number,
}

-- Remembers message ids until they expire (bounded: the oldest are dropped past `capacity`).
function Envelope.seen(capacity: number): Seen
	local expires: { [string]: number } = {}
	local order: { string } = {}
	local s = {}
	function s.has(id: string): boolean
		return expires[id] ~= nil
	end
	function s.add(id: string, exp: number)
		if expires[id] == nil then
			table.insert(order, id)
		end
		expires[id] = exp
		while #order > capacity do
			expires[table.remove(order, 1) :: string] = nil
		end
	end
	function s.prune(now: number)
		local keep = {}
		for _, id in order do
			if (expires[id] or 0) >= now then
				table.insert(keep, id)
			else
				expires[id] = nil
			end
		end
		order = keep
	end
	function s.size(): number
		return #order
	end
	return table.freeze(s) :: any
end

function Envelope.build(f: { [string]: any }, ttl: number): { [string]: any }
	return {
		v = Envelope.VERSION,
		id = f.id,
		at = f.at,
		exp = f.at + ttl,
		src = f.src,
		uid = f.uid,
		name = string.sub(tostring(f.name or "?"), 1, 40),
		cmd = f.cmd,
		p = f.p or {},
	}
end

export type Options = {
	now: number,
	maxSkew: number,
	maxTtl: number,
	self: string,
	seen: Seen,
	maxKeys: number?,
	maxString: number?,
}

-- (true, envelope) or (false, reason): malformed | version | expired | future | self | duplicate
function Envelope.validate(msg: any, o: Options): (boolean, any)
	if not plain(msg) then
		return false, "malformed"
	end
	for key in msg do
		if typeof(key) ~= "string" or not ALLOWED[key] then
			return false, "malformed"
		end
	end
	if msg.v ~= Envelope.VERSION then
		return false, "version"
	end
	if not (token(msg.id, 64) and token(msg.src, 64)) then
		return false, "malformed"
	end
	if typeof(msg.cmd) ~= "string" or #msg.cmd > 64 or not string.match(msg.cmd, "^[%a][%w_%.]*$") then
		return false, "malformed"
	end
	if not (finite(msg.at) and finite(msg.exp) and finite(msg.uid)) or msg.uid % 1 ~= 0 or msg.uid == 0 then
		return false, "malformed"
	end
	if typeof(msg.name) ~= "string" or #msg.name > 40 then
		return false, "malformed"
	end
	if msg.exp <= msg.at or msg.exp - msg.at > o.maxTtl then
		return false, "malformed"
	end
	if not plain(msg.p) then
		return false, "malformed"
	end
	local keys, maxKeys, maxString = 0, o.maxKeys or 16, o.maxString or 200
	for k, v in msg.p do
		keys += 1
		if keys > maxKeys or typeof(k) ~= "string" or #k > 32 then
			return false, "malformed"
		end
		local t = typeof(v)
		if t == "string" then
			if #v > maxString then
				return false, "malformed"
			end
		elseif t == "number" then
			if not finite(v) then
				return false, "malformed"
			end
		elseif t ~= "boolean" then
			return false, "malformed"
		end
	end
	if o.now > msg.exp then
		return false, "expired"
	end
	if msg.at > o.now + o.maxSkew then
		return false, "future"
	end
	if msg.src == o.self then
		return false, "self"
	end
	if o.seen.has(msg.id) then
		return false, "duplicate"
	end
	o.seen.add(msg.id, msg.exp + o.maxSkew)
	return true, msg
end

function Envelope.ack(id: string, src: string, ok: boolean, code: string): { [string]: any }
	return { v = Envelope.VERSION, ack = id, src = src, ok = ok, code = string.sub(code, 1, 24) }
end

function Envelope.validateAck(msg: any): (boolean, any)
	if not plain(msg) then
		return false, "malformed"
	end
	for key in msg do
		if typeof(key) ~= "string" or not ACK_ALLOWED[key] then
			return false, "malformed"
		end
	end
	if msg.v ~= Envelope.VERSION or not token(msg.ack, 64) or not token(msg.src, 64) then
		return false, "malformed"
	end
	if typeof(msg.ok) ~= "boolean" or typeof(msg.code) ~= "string" or #msg.code > 24 then
		return false, "malformed"
	end
	return true, msg
end

return table.freeze(Envelope)
