--!strict
-- Per-player token bucket for C->S remotes. Default: 5 tokens/s, burst 10.

local Players = game:GetService("Players")

export type RateLimiter = {
	allow: (self: RateLimiter, player: Player) -> boolean,
}

type Bucket = { tokens: number, at: number }

local RateLimiter = {}

function RateLimiter.new(perSecond: number?, burst: number?): RateLimiter
	local rate = perSecond or 5
	local cap = burst or 10
	local buckets: { [Player]: Bucket } = {}

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)

	local limiter = {}
	function limiter.allow(_self: RateLimiter, player: Player): boolean
		local now = os.clock()
		local bucket = buckets[player]
		if not bucket then
			bucket = { tokens = cap, at = now }
			buckets[player] = bucket
		end
		bucket.tokens = math.min(cap, bucket.tokens + (now - bucket.at) * rate)
		bucket.at = now
		if bucket.tokens < 1 then
			return false
		end
		bucket.tokens -= 1
		return true
	end
	return limiter :: any
end

return RateLimiter
