--!strict
-- Pure (clock injected): the per-server admin audit log. A bounded ring buffer (oldest entries drop off), never
-- written to DataStores. Admin-only: the only reader is the "logs.query" command (permission logs.view).
-- Global-scope actions are also mirrored to an expiring MemoryStore map by CrossServer (see logs.global).

export type Entry = {
	id: number,
	at: number, -- unix seconds
	admin: number, -- UserId (0 = system)
	adminName: string,
	role: string,
	command: string,
	target: string?,
	scope: string,
	params: string, -- short "key=value" summary, never raw tables
	outcome: "ok" | "fail",
	category: string, -- "ok" or the error category (unauthorized, forbidden, invalid_params, ...)
	message: string?,
	server: string, -- server that wrote the entry
	origin: string?, -- for cross-server runs: the server that sent the broadcast
	correlation: string,
}

export type Filter = {
	admin: number?,
	command: string?,
	server: string?,
	outcome: string?,
	since: number?,
	text: string?,
}

export type Audit = {
	add: (entry: { [string]: any }) -> Entry,
	query: (
		filter: Filter?,
		page: number?,
		pageSize: number?
	) -> { entries: { Entry }, total: number, page: number, pages: number },
	latest: (n: number) -> { Entry },
	size: () -> number,
	failures: () -> number,
}

local Audit = {}

local function short(value: any, cap: number): string
	local s = tostring(value)
	s = string.gsub(s, "%c", " ")
	if #s > cap then
		s = string.sub(s, 1, cap - 3) .. "..."
	end
	return s
end

-- "k=v k=v" from validated params (scalars only), sorted for stable output, `confirmed` dropped.
function Audit.summarize(params: { [string]: any }?): string
	local keys = {}
	for k in params or {} do
		if k ~= "confirmed" then
			table.insert(keys, k)
		end
	end
	table.sort(keys)
	local parts = {}
	for _, k in keys do
		table.insert(parts, `{k}={short((params :: any)[k], 48)}`)
	end
	return short(table.concat(parts, " "), 160)
end

function Audit.new(capacity: number, clock: () -> number): Audit
	local ring: { Entry } = {}
	local head = 0 -- index of the newest entry
	local count = 0
	local nextId = 0
	local failures = 0

	local function ordered(): { Entry } -- newest first
		local list = {}
		for i = 0, count - 1 do
			local idx = ((head - 1 - i) % capacity) + 1
			table.insert(list, ring[idx])
		end
		return list
	end

	local audit = {}
	function audit.add(e: { [string]: any }): Entry
		nextId += 1
		local entry: Entry = {
			id = nextId,
			at = e.at or clock(),
			admin = if typeof(e.admin) == "number" then e.admin else 0,
			adminName = short(e.adminName or "?", 40),
			role = short(e.role or "none", 16),
			command = short(e.command or "?", 64),
			target = if e.target then short(e.target, 64) else nil,
			scope = short(e.scope or "server", 8),
			params = short(e.params or "", 160),
			outcome = if e.outcome == "ok" then "ok" else "fail",
			category = short(e.category or "ok", 24),
			message = if e.message then short(e.message, 160) else nil,
			server = short(e.server or "?", 40),
			origin = if e.origin then short(e.origin, 40) else nil,
			correlation = short(e.correlation or "", 40),
		}
		if entry.outcome == "fail" then
			failures += 1
		end
		head = (head % capacity) + 1
		ring[head] = entry
		count = math.min(count + 1, capacity)
		return entry
	end
	function audit.query(filter: Filter?, page: number?, pageSize: number?)
		local f: Filter = filter or {}
		local size = math.clamp(math.floor(pageSize or 25), 1, 100)
		local needle = if f.text and f.text ~= "" then string.lower(f.text) else nil
		local matches = {}
		for _, e in ordered() do
			if f.admin and e.admin ~= f.admin then
				continue
			end
			if f.command and f.command ~= "" and e.command ~= f.command then
				continue
			end
			if f.server and f.server ~= "" and e.server ~= f.server and e.origin ~= f.server then
				continue
			end
			if f.outcome and f.outcome ~= "" and f.outcome ~= "any" and e.outcome ~= f.outcome then
				continue
			end
			if f.since and e.at < f.since then
				continue
			end
			if needle then
				local hay = string.lower(`{e.adminName} {e.command} {e.target or ""} {e.params} {e.category}`)
				if not string.find(hay, needle, 1, true) then
					continue
				end
			end
			table.insert(matches, e)
		end
		local pages = math.max(1, math.ceil(#matches / size))
		local p = math.clamp(math.floor(page or 1), 1, pages)
		local slice = table.move(matches, (p - 1) * size + 1, math.min(#matches, p * size), 1, {})
		return { entries = slice, total = #matches, page = p, pages = pages }
	end
	function audit.latest(n: number): { Entry }
		local all = ordered()
		return table.move(all, 1, math.min(#all, n), 1, {})
	end
	function audit.size(): number
		return count
	end
	function audit.failures(): number
		return failures
	end
	return table.freeze(audit) :: any
end

return table.freeze(Audit)
