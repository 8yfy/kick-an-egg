--!strict
-- RequestKick(timing): rolls distance, landing zone, pet, size and weather on the server,
-- stores the pending chase and fires KickResult. ChaseService takes over at touchdown.
-- Studio command bar: require(game.ServerScriptService.Server.Services.KickService):Simulate(1000, 10, 0)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)
local Mutations = require(Shared.Config.Mutations)
local Pets = require(Shared.Config.Pets)
local Rarities = require(Shared.Config.Rarities)
local Zones = require(Shared.Config.Zones)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)

export type KickRoll = {
	eggUid: string,
	zonesCrossed: { number },
	landZone: number,
	distance: number,
	landPos: Vector3,
	launchTime: number,
	flightSeconds: number,
	eggModel: string,
	petId: string,
	rarity: string,
	size: string?,
	weather: string?,
}

export type PendingChase = KickRoll & {
	owner: Player,
	touchdown: number,
}

local LAUNCH_DELAY = 0.35 -- kick animation before the egg leaves the pad
local MIN_REQUEST_GAP = 0.5
local RAY_TOP = 500
local RARE_ORDER = Rarities.Rare.order

local KickService = {}

local rng = Random.new()
local limiter = RateLimiter.new()
local lastRequest: { [Player]: number } = {}
local active: { [Player]: PendingChase } = {}
local friendCache: { [number]: { [number]: boolean } } = {}
local touchdownCallbacks: { (PendingChase) -> () } = {}
local kickCallbacks: { (Player, KickRoll) -> () } = {}
local kickResult: RemoteEvent

local LAST_ZONE = Zones[#Zones]
local MAX_DISTANCE = LAST_ZONE.start + LAST_ZONE.length - 1

-- Size/weather keys sorted rarest first, so "first hit wins" is deterministic and fair.
local function byChance(map: { [string]: { chance: number } }): { string }
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return map[a].chance < map[b].chance
	end)
	return keys
end
local SIZE_ORDER = byChance(Mutations.Size :: any)
local WEATHER_ORDER = byChance(Mutations.Weather :: any)

-- Optional: WeatherService (later task) exposes :GetActive() -> string?
local function activeWeather(): string?
	local module = script.Parent:FindFirstChild("WeatherService")
	if module and module:IsA("ModuleScript") then
		local weatherService = (require :: any)(module)
		if weatherService.GetActive then
			return weatherService:GetActive()
		end
	end
	return nil
end

local function timingBonus(timing: number): number
	if timing >= 0.9 then
		return Economy.TimingBonus.perfect
	elseif timing >= 0.6 then
		return Economy.TimingBonus.good
	end
	return Economy.TimingBonus.miss
end

local function zoneAt(distance: number): number
	for _, zone in Zones do
		if distance < zone.start + zone.length then
			return zone.id
		end
	end
	return LAST_ZONE.id
end

-- Pets of `zone`, or of the nearest lower zone that has any (content is still being filled).
local function petsFor(zone: number): { Pets.Pet }
	for z = zone, 1, -1 do
		local list = {}
		for _, pet in Pets do
			if pet.zone == z then
				table.insert(list, pet)
			end
		end
		if #list > 0 then
			return list
		end
	end
	error("[KickService] no pets configured")
end

local function rollPet(zone: number, friendBoost: number): Pets.Pet
	local list = petsFor(zone)
	local total = 0
	local weights = table.create(#list, 0)
	for i, pet in list do
		local weight = pet.weight
		if Rarities[pet.rarity].order >= RARE_ORDER then
			weight *= 1 + friendBoost
		end
		weights[i] = weight
		total += weight
	end
	local pick = rng:NextNumber() * total
	for i, pet in list do
		pick -= weights[i]
		if pick <= 0 then
			return pet
		end
	end
	return list[#list]
end

local function rollSize(): string?
	for _, key in SIZE_ORDER do
		if rng:NextNumber() < Mutations.Size[key].chance then
			return key
		end
	end
	return nil
end

local function rollWeather(zone: number, eventWeather: string?): string?
	local zoneWeather = Zones[zone].weather
	for _, key in WEATHER_ORDER do
		local chance = Mutations.Weather[key].chance
		if key == eventWeather then
			chance *= 5
		end
		if key == zoneWeather then
			chance *= 2
		end
		if rng:NextNumber() < chance then
			return key
		end
	end
	return nil
end

local function groundY(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true -- skip decor like A's AmbientFx emitters; hit the real ground
	local ignore = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(x, RAY_TOP, z), Vector3.new(0, -RAY_TOP * 2, 0), params)
	return if hit then hit.Position.Y else 0
end

local function friendsInServer(player: Player): number
	local cache = friendCache[player.UserId]
	if not cache then
		cache = {}
		friendCache[player.UserId] = cache
	end
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local isFriend = cache[other.UserId]
			if isFriend == nil then
				local ok, result = pcall(player.IsFriendsWithAsync, player, other.UserId)
				isFriend = ok and result == true
				cache[other.UserId] = isFriend
			end
			if isFriend then
				count += 1
			end
		end
	end
	return count
end

-- Player attribute "FriendBoost" (e.g. 0.2 = +20 % Rare+ weight) so the HUD can show it.
local function refreshFriendBoosts()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("FriendBoost", friendsInServer(player) * Economy.FriendLuckPerFriend)
	end
end

-- Pure roll (no player state), shared by real kicks and :Simulate.
local function roll(
	kickPower: number,
	rebirths: number,
	timing: number,
	friends: number,
	eventWeather: string?,
	now: number
): KickRoll
	local mult = 1 + rebirths * Economy.Rebirth.multiplierPerRebirth
	local distance = kickPower * Economy.DistancePerPower * timingBonus(timing) * mult
	distance = math.min(distance, MAX_DISTANCE)

	local zonesCrossed = {}
	for _, zone in Zones do
		if zone.start < distance then
			table.insert(zonesCrossed, zone.id)
		end
	end
	local landZone = zoneAt(distance)

	local halfWidth = Chase.RunwayWidth / 2 - 6
	local x = rng:NextNumber(-halfWidth, halfWidth)
	local landPos = Vector3.new(x, groundY(x, distance), distance)

	local pet = rollPet(landZone, friends * Economy.FriendLuckPerFriend)
	local launchTime = now + LAUNCH_DELAY
	return {
		eggUid = HttpService:GenerateGUID(false),
		zonesCrossed = zonesCrossed,
		landZone = landZone,
		distance = distance,
		landPos = landPos,
		launchTime = launchTime,
		flightSeconds = Chase.flightSeconds(distance),
		eggModel = pet.model,
		petId = pet.id,
		rarity = pet.rarity,
		size = rollSize(),
		weather = rollWeather(landZone, eventWeather),
	}
end

local function onRequestKick(player: Player, timing: any)
	if not limiter:allow(player) then
		return
	end
	local now = workspace:GetServerTimeNow()
	local last = lastRequest[player]
	lastRequest[player] = now
	if last and now - last < MIN_REQUEST_GAP then
		return
	end
	if active[player] then
		return
	end
	if typeof(timing) ~= "number" or timing ~= timing then
		return
	end
	local data = DataService:Get(player)
	if not data then
		return
	end

	local result =
		roll(data.kickPower, data.rebirths, math.clamp(timing, 0, 1), friendsInServer(player), activeWeather(), now)
	local pending: PendingChase = table.clone(result) :: any
	pending.owner = player
	pending.touchdown = result.launchTime + result.flightSeconds
	active[player] = pending

	local stats: { [string]: number } = table.clone(data.stats)
	stats.kicks += 1
	DataService:Set(player, { stats = stats })

	kickResult:FireClient(player, result)
	for _, callback in kickCallbacks do
		task.spawn(callback, player, result)
	end
	Analytics.custom(player, "Kick", result.distance, `Zone{result.landZone}`, result.rarity)
	Analytics.funnel(player, Analytics.Funnel.FirstKick, "FirstKick")

	task.delay(pending.touchdown - workspace:GetServerTimeNow(), function()
		if active[player] ~= pending then
			return
		end
		if #touchdownCallbacks == 0 then
			active[player] = nil -- no ChaseService yet: allow the next kick
			return
		end
		for _, callback in touchdownCallbacks do
			task.spawn(callback, pending)
		end
	end)
end

-- API for ChaseService ----------------------------------------------------

function KickService:GetActive(player: Player): PendingChase?
	return active[player]
end

-- Call when the chase is fully over (ChaseEnded / EggLost); the player may kick again.
function KickService:EndChase(player: Player)
	active[player] = nil
end

function KickService:OnTouchdown(callback: (PendingChase) -> ())
	table.insert(touchdownCallbacks, callback)
end

-- Fires after every accepted kick (AnnounceService uses it for Legendary+ rolls).
function KickService:OnKick(callback: (Player, KickRoll) -> ())
	table.insert(kickCallbacks, callback)
end

-- Prints zone/rarity/mutation distributions for `n` kicks at random timing.
function KickService:Simulate(n: number, kickPower: number?, rebirths: number?)
	local power = kickPower or Economy.KickPower.base
	local zones, rarities, sizes, weathers = {}, {}, {}, {}
	local function bump(t: { [any]: number }, key: any)
		t[key] = (t[key] or 0) + 1
	end
	for _ = 1, n do
		local r = roll(power, rebirths or 0, rng:NextNumber(), 0, nil, 0)
		bump(zones, r.landZone)
		bump(rarities, r.rarity)
		bump(sizes, r.size or "none")
		bump(weathers, r.weather or "none")
	end
	local function dump(label: string, t: { [any]: number })
		local keys = {}
		for k in t do
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		local parts = {}
		for _, k in keys do
			table.insert(parts, `{k}={string.format("%.1f", t[k] / n * 100)}%`)
		end
		print(`[Simulate] {label}: {table.concat(parts, "  ")}`)
	end
	print(`[Simulate] {n} kicks, power {power}, rebirths {rebirths or 0}`)
	dump("zone", zones)
	dump("rarity", rarities)
	dump("size", sizes)
	dump("weather", weathers)
end

function KickService:Init()
	kickResult = Remotes.get("KickResult")
end

function KickService:Start()
	Remotes.get("RequestKick").OnServerEvent:Connect(onRequestKick)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		active[player] = nil
		friendCache[player.UserId] = nil
		task.delay(1, refreshFriendBoosts) -- after the player is gone from GetPlayers
	end)
	Players.PlayerAdded:Connect(function()
		task.spawn(refreshFriendBoosts)
	end)
	task.spawn(refreshFriendBoosts)
end

return KickService
