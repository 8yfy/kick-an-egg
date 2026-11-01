--!strict
-- SERVER ONLY admin configuration: roles and their permissions, limits, environments and cross-server settings.
-- Lives in ServerScriptService, so clients never receive it. Clients only get what Commands/Core "session.hello"
-- sends: their own role, their own permission names and client-safe command metadata.

local Config = {}

Config.Version = "admin-1.0"

-- Permission names. Every command names one of these (Pipeline checks it before anything else runs).
local TESTER = {
	"panel.open",
	"dashboard.view",
	"settings.view",
	"players.view",
	"players.teleport.self",
	"lab.use",
	"anim.play",
	"vfx.play",
	"commands.run",
}
local DEVELOPER = {
	"players.teleport.others",
	"players.progression", -- still limited to Studio in-memory data or a staging universe (Environment)
	"lab.manageAll",
	"weather.server",
	"events.server",
	"announce.server",
	"flags.server",
	"logs.view",
	"diagnostics.refresh",
	"scenario.reset",
}
local OWNER = {
	"weather.global",
	"events.global",
	"announce.global",
	"flags.global",
	"players.moderate",
	"logs.global",
}

local function union(...: { string }): { [string]: boolean }
	local set = {}
	for _, list in { ... } do
		for _, name in list do
			set[name] = true
		end
	end
	return table.freeze(set)
end

export type Role = { rank: number, permissions: { [string]: boolean }, color: string }

-- Higher rank = more trusted. Moderation can only target players of a LOWER rank (no escalation).
Config.Roles = table.freeze({
	Tester = table.freeze({ rank = 1, permissions = union(TESTER), color = "cyan" }),
	Developer = table.freeze({ rank = 2, permissions = union(TESTER, DEVELOPER), color = "violet" }),
	Owner = table.freeze({ rank = 3, permissions = union(TESTER, DEVELOPER, OWNER), color = "gold" }),
}) :: { [string]: Role }

-- Environments. DataStores are shared by EVERY place and server (private servers included) of one universe,
-- so staging is identified by the universe (game.GameId), never by PlaceId or server type.
--   studio      RunService:IsStudio()
--   staging     game.GameId is listed in StagingUniverseIds (a separate experience with its own DataStores)
--   production  everything else (the safe default)
Config.StagingUniverseIds = table.freeze({
	-- [1234567890] = true, -- add the staging experience's universe id (game.GameId) here
}) :: { [number]: boolean }
Config.ProductionUniverseIds = table.freeze({
	-- [1234567890] = true, -- optional: listing the live universe makes the production check explicit
}) :: { [number]: boolean }

Config.Limits = table.freeze({
	requestRate = 6, -- requests per second per admin (token bucket)
	requestBurst = 14,
	maxInFlight = 4, -- concurrent requests per admin
	maxParamKeys = 16,
	maxStringLength = 200,
	globalCooldown = 10, -- seconds between global-scope runs of one command by one admin
	unauthorizedLogEvery = 10, -- seconds between audit entries for one unauthorized UserId
})

Config.Lab = table.freeze({
	origin = Vector3.new(-900, 260, 0), -- far west of the runway and high above it: out of everyone's way
	maxPerAdmin = 8,
	maxTotal = 24,
	minScale = 0.25,
	maxScale = 4,
	maxOffset = 30, -- studs a model may be moved from its pad (x/z); y 0..maxLift
	maxLift = 16,
	nearDistance = 12, -- "near me" spawns land this far in front of the admin
	penMax = 12, -- pets in the test pen
	penHalf = 20, -- the test pen's usable half size (studs)
})

Config.Vfx = table.freeze({
	maxActive = 10, -- lab models with an effect switched on at once
	maxSeconds = 120, -- an enabled effect switches itself off after at most this long
	oneShotCooldown = 0.5,
	qualities = table.freeze({ Low = 0.35, Medium = 0.65, High = 1 }),
})

Config.Weather = table.freeze({ minSeconds = 10, maxSeconds = 1800 })

Config.Announce = table.freeze({ maxLength = 120 })

Config.Audit = table.freeze({
	capacity = 500, -- per-server ring buffer
	pageSize = 25,
	globalTtl = 86400, -- MemoryStore copy of global-scope actions: one day
	globalRead = 100,
})

Config.CrossServer = table.freeze({
	topic = "KTE_Admin_v1",
	ackTopic = "KTE_AdminAck_v1",
	ttl = 60, -- seconds a broadcast stays valid
	maxSkew = 30, -- tolerated clock difference between servers
	maxBytes = 900, -- MessagingService allows 1 kB per message
	retries = 3,
	ackWindow = 10, -- seconds the sender counts acknowledgements
	seenCapacity = 512,
	stateMap = "KTE_AdminGlobal_v1", -- MemoryStore hash map of temporary global effects (expiring)
	auditMap = "KTE_AdminAudit_v1",
})

Config.Client = table.freeze({
	defaultHotkey = "F2", -- not used by the game (";" opens the Studio AnimShowcase, F9 is the console)
	allowedHotkeys = table.freeze({ "F2", "F4", "F6", "F7", "F8", "RightBracket", "Backquote", "Insert" }),
})

return table.freeze(Config)
