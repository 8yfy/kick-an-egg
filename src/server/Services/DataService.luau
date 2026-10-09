--!strict
-- Player profiles: session-locked DataStore records, retried saves, autosave, BindToClose.
-- Other services read with :Get / :WaitForData and write with :Set / :Increment (fires DataChanged).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Remotes = require(Shared.Remotes)

export type Data = { [string]: any }

type Record = {
	data: Data?,
	lock: { server: string, at: number }?,
}

type Profile = {
	data: Data,
	inMemory: boolean, -- Studio without API access: never written to the DataStore
	released: boolean,
}

local STORE_NAME = "PlayerData_v1"
local MAX_TRIES = 3
local LOCK_TIMEOUT = Economy.AutosaveSeconds * 5 -- a lock older than this is from a crashed server
local LOCKED_RETRIES = 4 -- the other server may still be saving on leave
local SERVER_ID = HttpService:GenerateGUID(false) -- JobId is "" in Studio, so use our own

local TEMPLATE: Data = {
	version = 1,
	money = Economy.StartingMoney,
	kickPower = Economy.KickPower.base,
	runSpeed = Economy.RunSpeed.base,
	rebirths = 0,
	eggs = {}, -- { {uid, petId, size, weather} }
	pets = {},
	plots = {},
	stats = { kicks = 0, secured = 0, lost = 0 },
	receipts = {}, -- last processed dev-product PurchaseIds (MonetizationService)
	onboarding = 0, -- highest onboarding funnel step logged (Util/Analytics)
	tool = 1, -- best training tool tier owned (Economy.Tools); kickPower is the strength it trains
}

local DataService = {}

local store: DataStore? = nil
local profiles: { [Player]: Profile } = {}
local loadedCallbacks: { (Player, Data) -> () } = {}
local dataChanged: RemoteEvent

local function deepCopy<T>(value: T): T
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value :: any do
		copy[k] = deepCopy(v)
	end
	return copy :: any
end

-- Adds keys that the template has but the saved data doesn't (new fields after an update).
local function reconcile(data: Data, template: Data)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif typeof(v) == "table" and typeof(data[k]) == "table" and next(v) ~= nil then
			reconcile(data[k], v)
		end
	end
end

local function isFinite(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Repairs corrupted or exploited numbers and wrong types so no service ever sees NaN or junk.
local function sanitize(data: Data)
	for _, key in { "eggs", "pets", "plots", "stats", "receipts" } do
		if typeof(data[key]) ~= "table" then
			data[key] = deepCopy(TEMPLATE[key])
		end
	end
	data.money = if isFinite(data.money) then math.max(0, data.money) else Economy.StartingMoney
	data.rebirths = if isFinite(data.rebirths) then math.max(0, math.floor(data.rebirths)) else 0
	local powerCap = Economy.maxKickPower(data.rebirths)
	data.kickPower = if isFinite(data.kickPower)
		then math.clamp(data.kickPower, Economy.KickPower.base, powerCap) -- strength is fractional
		else Economy.KickPower.base
	data.runSpeed = if isFinite(data.runSpeed)
		then math.clamp(math.floor(data.runSpeed), Economy.RunSpeed.base, Economy.RunSpeed.max)
		else Economy.RunSpeed.base
	if data.plotSlots ~= nil and not isFinite(data.plotSlots) then
		data.plotSlots = nil
	end
	data.onboarding = if isFinite(data.onboarding) then data.onboarding else 0
	data.tool = if isFinite(data.tool) then math.clamp(math.floor(data.tool), 1, #Economy.Tools) else 1
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

-- Retries `fn` up to MAX_TRIES times with 1/2/4 s backoff. Returns ok, result/error.
local function withRetries<T>(label: string, fn: () -> T): (boolean, any)
	local lastErr: any
	for attempt = 1, MAX_TRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		warn(`[DataService] {label} failed (try {attempt}/{MAX_TRIES}): {result}`)
		if attempt < MAX_TRIES then
			task.wait(2 ^ (attempt - 1))
		end
	end
	return false, lastErr
end

-- Claims the session lock and returns the data. "locked" means another live server owns it.
local function claim(player: Player): ("ok" | "locked" | "error", Data?)
	local ds = store :: DataStore
	local lockedOut = false
	local ok, result = withRetries(`load {player.UserId}`, function()
		lockedOut = false
		return ds:UpdateAsync(keyFor(player), function(old: Record?)
			local record: Record = old or {}
			local now = os.time()
			local lock = record.lock
			if lock and lock.server ~= SERVER_ID and now - lock.at < LOCK_TIMEOUT then
				lockedOut = true
				return nil -- cancel the write
			end
			record.lock = { server = SERVER_ID, at = now }
			return record
		end)
	end)
	if not ok then
		return "error", nil
	end
	if lockedOut then
		return "locked", nil
	end
	local record = result :: Record
	return "ok", record.data or deepCopy(TEMPLATE)
end

-- Writes the profile. `release` drops the lock (player left / server closing).
local function save(player: Player, profile: Profile, release: boolean): boolean
	if profile.inMemory or profile.released or not store then
		return true
	end
	local ds = store :: DataStore
	local lostLock = false
	local ok = withRetries(`save {player.UserId}`, function()
		lostLock = false
		return ds:UpdateAsync(keyFor(player), function(old: Record?)
			local record: Record = old or {}
			local lock = record.lock
			if lock and lock.server ~= SERVER_ID then
				lostLock = true
				return nil -- another server took over; never overwrite its data
			end
			record.data = profile.data
			record.lock = if release then nil else { server = SERVER_ID, at = os.time() }
			return record
		end)
	end)
	if lostLock then
		warn(`[DataService] {player.UserId} lock is held by another server; save skipped`)
		return false
	end
	if ok and release then
		profile.released = true
	end
	return ok
end

local function onPlayerAdded(player: Player)
	local status: "ok" | "locked" | "error" = "error"
	local data: Data? = nil
	if store then
		for attempt = 1, LOCKED_RETRIES do
			status, data = claim(player)
			if status ~= "locked" or attempt == LOCKED_RETRIES then
				break
			end
			task.wait(2 ^ attempt)
		end
	end

	local inMemory = false
	if status ~= "ok" then
		if status == "error" and RunService:IsStudio() then
			warn("[DataService] DataStore unavailable in Studio (enable API access); using in-memory data")
			data = deepCopy(TEMPLATE)
			inMemory = true
		else
			local reason = if status == "locked"
				then "Your data is open in another server. Please rejoin in a moment."
				else "Couldn't load your data. Please rejoin."
			player:Kick(reason)
			return
		end
	end

	local loaded = data :: Data
	reconcile(loaded, TEMPLATE)
	sanitize(loaded)
	local profile: Profile = { data = loaded, inMemory = inMemory, released = false }

	if not player.Parent then
		-- Left while loading: release the lock we just took.
		save(player, profile, true)
		return
	end

	profiles[player] = profile
	dataChanged:FireClient(player, loaded)
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, loaded)
	end
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	save(player, profile, true)
	profiles[player] = nil
end

-- Public API ---------------------------------------------------------------

function DataService:Get(player: Player): Data?
	local profile = profiles[player]
	return profile and profile.data
end

-- Yields until the player's data is loaded. Returns nil if they leave first.
function DataService:WaitForData(player: Player): Data?
	while player.Parent and not profiles[player] do
		task.wait()
	end
	return self:Get(player)
end

-- Merges top-level keys and tells the client only what changed.
function DataService:Set(player: Player, partial: Data)
	local profile = profiles[player]
	if not profile then
		return
	end
	for k, v in partial do
		profile.data[k] = v
	end
	dataChanged:FireClient(player, partial)
end

function DataService:Increment(player: Player, key: string, delta: number): number?
	local data = self:Get(player)
	if not data then
		return nil
	end
	local value = (data[key] :: number) + delta
	self:Set(player, { [key] = value })
	return value
end

DataService.sanitize = sanitize -- exposed for the headless tests

-- Saves right away (keeps the lock). Used after purchases and trades. True on success.
function DataService:SaveNow(player: Player): boolean
	local profile = profiles[player]
	return profile ~= nil and save(player, profile, false)
end

function DataService:OnLoaded(callback: (Player, Data) -> ())
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile.data)
	end
end

function DataService:Init()
	dataChanged = Remotes.get("DataChanged")
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`[DataService] GetDataStore failed: {result}`)
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		local pending = 0
		for player, profile in profiles do
			pending += 1
			task.spawn(function()
				save(player, profile, true)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Economy.AutosaveSeconds)
			for player, profile in profiles do
				task.spawn(save, player, profile, false)
			end
		end
	end)
end

return DataService
