--!strict
-- Text for world displays: pet income per second and incubation countdowns.
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

-- "$0.8/s", "$12/s", "$125/s", "$1.25K/s", "$12.5K/s", "$1.4M/s". Below 1,000 it keeps one decimal when there
-- is one, so a Tiny pet earning 0.8 never reads as $0. Above that, three significant digits, never rounded up
-- past the true value.
function Format.income(perSecond: number): string
	local n = math.max(0, perSecond)
	if n < 1000 then
		local tenths = math.floor(n * 10 + 1e-6) / 10
		local s = if tenths % 1 == 0 then string.format("%d", tenths) else string.format("%.1f", tenths)
		return "$" .. s .. "/s"
	end
	local i, v = 1, n
	while v >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	local digits = if v >= 100 then 0 elseif v >= 10 then 1 else 2
	local f = 10 ^ digits
	v = math.floor(v * f + 1e-6) / f
	local s = string.format(`%.{digits}f`, v)
	if digits > 0 then
		s = (s:gsub("0+$", ""):gsub("%.$", ""))
	end
	return "$" .. s .. SUFFIXES[i] .. "/s"
end

-- Remaining time, never negative: "00:07", "02:35", "1:02:35", "2d 04h". Seconds are rounded UP so 0:00 only
-- shows once the egg is really ready.
function Format.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds - 1e-6))
	local d = s // 86400
	local h = (s // 3600) % 24
	local m = (s // 60) % 60
	local sec = s % 60
	if d > 0 then
		return string.format("%dd %02dh", d, h)
	elseif h > 0 then
		return string.format("%d:%02d:%02d", h, m, sec)
	end
	return string.format("%02d:%02d", m, sec)
end

return Format
