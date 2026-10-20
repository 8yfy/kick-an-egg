--!strict
-- CONTRACT FILE: change only via a `contract:` PR.
-- Everything about flight timing, the avalanche chase, the running egg and carrying.
--
-- WORLD AXES (both partners must use these):
--   The kick pad is at (0, 0, 0). The runway runs along +Z. Zone N covers
--   Z = Zones[N].start .. start + length. The runway is RunwayWidth studs wide, centred on X = 0.
--   The SAFE ZONE (player bases) is Z < 0. Crossing Z = SafeLineZ back toward the bases = safe.
--   The avalanche always moves toward -Z (toward the safe zone).

local Flight = {
	-- seconds in the air = clamp(distance / studsPerSecond, min, max)
	studsPerSecond = 140,
	minSeconds = 1.6,
	maxSeconds = 6,
	arcHeightPerStud = 0.12, -- apex height = distance * this, capped below
	maxArcHeight = 160,
	spinSecondsPerZone = 0.45, -- EggSpin cycle length when entering each zone
}

local Avalanche = {
	warnSeconds = 1.5, -- rumble + "RUN!" banner before it appears
	-- Where the front appears (Chase.avalancheStartZ): spawnBehindLanding studs beyond the landing point (+Z),
	-- kept inside the landing zone, never closer than spawnMinBehind to the egg and never within endMargin of
	-- the track's end wall (an egg landing near the end of zone 20 used to put it past the map).
	spawnBehindLanding = 60,
	spawnMinBehind = 35,
	endMargin = 6,
	-- Front speed (studs/s) by landing zone, a smooth curve: first (zone 1) .. last (zone 20), shaped by
	-- exponent (> 1 = gentle early zones, steeper late): 12 in zone 1, ~24 in zone 10, 44 in zone 20. Independent
	-- of the player's Run Speed; every zone stays outrunnable at a reachable speed level
	-- (tools/tests/Progression.server.lua lists the level each zone needs).
	speedCurve = { first = 12, last = 44, exponent = 1.35 },
	catchDistance = 4, -- caught when the front is within this many studs (Z axis) of you
	height = 22,
	despawnAtZ = -6, -- stops and crumbles at the safe line
	ownerOnly = true, -- only hurts its owner; other players see it at low detail
}

-- Visual theme of the avalanche per zone range (Partner A builds one look per theme).
local Themes: { { fromZone: number, theme: string } } = {
	{ fromZone = 1, theme = "Rock" },
	{ fromZone = 2, theme = "Sand" },
	{ fromZone = 3, theme = "Rock" },
	{ fromZone = 5, theme = "Sand" },
	{ fromZone = 6, theme = "Snow" },
	{ fromZone = 7, theme = "Candy" },
	{ fromZone = 8, theme = "Coral" },
	{ fromZone = 9, theme = "Lava" },
	{ fromZone = 10, theme = "Crystal" },
	{ fromZone = 11, theme = "Rock" },
	{ fromZone = 12, theme = "Neon" },
	{ fromZone = 13, theme = "Bone" },
	{ fromZone = 14, theme = "Cloud" },
	{ fromZone = 15, theme = "Sludge" },
	{ fromZone = 16, theme = "Scrap" },
	{ fromZone = 17, theme = "Snow" },
	{ fromZone = 18, theme = "Lava" },
	{ fromZone = 19, theme = "Void" },
	{ fromZone = 20, theme = "Rainbow" },
}

local Zones = require(script.Parent.Zones)
local LAST = Zones[#Zones]
local TRACK_END = LAST.start + LAST.length -- the end wall's inner face

local Chase = {
	RunwayWidth = 48,
	SafeLineZ = -6,
	Flight = Flight,
	Avalanche = Avalanche,
	Themes = Themes,
	-- Where eggs may land (server, KickService): only on surfaces tagged LANDING_TAG by the MapBuilder (the
	-- zone lanes and the launch ramp), never on walls, arches or other eggs; at most endMargin studs before the
	-- end wall and edgeMargin studs inside the lane edges.
	Landing = { tag = "LandingSurface", endMargin = 50, edgeMargin = 6 },

	Egg = {
		runDelay = 0.9, -- seconds after touchdown (legs sprout) before the player can steer it
		-- The egg is steered by its owner at their Run Speed (bought in the shop).
		-- Unused since the steering change (kept so old code doesn't break): runSpeed, zigzag,
		-- pickupDistance, Carry, Caught.
		runSpeed = 7,
		zigzag = 3,
		pickupDistance = 6,
	},

	Carry = {
		speedMultiplier = 0.92,
		maxCarried = 1,
	},

	Caught = {
		knockback = 60,
		respawnAtBase = true,
		eggLost = true,
	},

	flightSeconds = function(distance: number): number
		return math.clamp(distance / Flight.studsPerSecond, Flight.minSeconds, Flight.maxSeconds)
	end,

	avalancheSpeed = function(landZone: number): number
		local c = Avalanche.speedCurve
		local t = (math.clamp(landZone, 1, #Zones) - 1) / math.max(1, #Zones - 1)
		return c.first + (c.last - c.first) * t ^ c.exponent
	end,

	trackEnd = function(): number
		return TRACK_END
	end,

	-- The avalanche front's start Z for an egg that landed at `landZ` in zone `landZone` (see Avalanche).
	avalancheStartZ = function(landZ: number, landZone: number): number
		local zone = Zones[math.clamp(landZone, 1, #Zones)]
		local mapEnd = TRACK_END - Avalanche.endMargin
		local lo = landZ + Avalanche.spawnMinBehind
		local hi = math.min(zone.start + zone.length, mapEnd)
		if hi < lo then
			-- landed at the zone's far end: a fair gap wins over the zone line, but never past the map
			return math.min(lo, mapEnd)
		end
		return math.clamp(landZ + Avalanche.spawnBehindLanding, lo, hi)
	end,

	-- Front Z at server time `now` for an avalanche that appeared at `startTime` at `startZ`.
	frontZ = function(startZ: number, startTime: number, speed: number, now: number): number
		return startZ - speed * math.max(0, now - startTime)
	end,

	themeFor = function(zone: number): string
		local theme = "Rock"
		for _, t in Themes do
			if zone >= t.fromZone then
				theme = t.theme
			end
		end
		return theme
	end,
}

return Chase
