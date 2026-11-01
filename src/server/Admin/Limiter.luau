--!strict
-- Pure (clock injected): per-admin token bucket, per-command cooldowns and a cap on concurrent requests.
-- Keys are UserIds. forget(key) drops everything when the admin leaves.

export type Limiter = {
	allow: (key: number) -> boolean,
	cooldown: (key: number, id: string, seconds: number) -> (boolean, number),
	enter: (key: number, max: number) -> boolean,
	leave: (key: number) -> (),
	forget: (key: number) -> (),
}

local Limiter = {}

function Limiter.new(rate: number, burst: number, clock: () -> number): Limiter
	local buckets: { [number]: { tokens: number, at: number } } = {}
	local last: { [number]: { [string]: number } } = {}
	local inFlight: { [number]: number } = {}

	local limiter = {}
	function limiter.allow(key: number): boolean
		local now = clock()
		local b = buckets[key]
		if not b then
			b = { tokens = burst, at = now }
			buckets[key] = b
		end
		b.tokens = math.min(burst, b.tokens + math.max(0, now - b.at) * rate)
		b.at = now
		if b.tokens < 1 then
			return false
		end
		b.tokens -= 1
		return true
	end
	-- (true, 0) and starts the cooldown, or (false, seconds left).
	function limiter.cooldown(key: number, id: string, seconds: number): (boolean, number)
		if seconds <= 0 then
			return true, 0
		end
		local now = clock()
		local mine = last[key]
		if not mine then
			mine = {}
			last[key] = mine
		end
		local at = mine[id]
		if at and now - at < seconds then
			return false, seconds - (now - at)
		end
		mine[id] = now
		return true, 0
	end
	function limiter.enter(key: number, max: number): boolean
		local n = inFlight[key] or 0
		if n >= max then
			return false
		end
		inFlight[key] = n + 1
		return true
	end
	function limiter.leave(key: number)
		local n = (inFlight[key] or 1) - 1
		inFlight[key] = if n > 0 then n else nil
	end
	function limiter.forget(key: number)
		buckets[key] = nil
		last[key] = nil
		inFlight[key] = nil
	end
	return table.freeze(limiter) :: any
end

return table.freeze(Limiter)
