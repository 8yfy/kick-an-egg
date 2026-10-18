--!strict
-- The two global boards on the plaza wall (Config/Leaderboards, Builders/Map/Boards): TOP KICK POWER and TOP
-- DONATORS. Every RefreshSeconds it writes each player's changed score to the board's OrderedDataStore, reads the
-- top rows back and paints them (rank, avatar headshot, name, value). Without DataStore access (an unpublished
-- Studio place) the boards show this server's players instead, so they can still be tested.
-- Donations: MonetizationService counts real donation receipts into data.donated; in Studio, donation buttons
-- whose product id is still 0 can be test-counted (DonateTest). Each donation is announced and refreshes the board.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Leaderboards = require(Shared.Config.Leaderboards)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local AnnounceService = require(script.Parent.AnnounceService)
local LeaderboardPodiums = require(script.Parent.Parent.Util.LeaderboardPodiums)
local podiums = LeaderboardPodiums.new()

export type Entry = { userId: number, value: number, name: string? }

local LeaderboardService = {}

local stores: { [string]: OrderedDataStore } = {}
local written: { [string]: { [number]: number } } = {}
local names: { [number]: string } = {}
local refreshQueued = false

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

-- 1234 -> "1.23K", 2500000000000 -> "2.5T" (whole numbers below 1000).
function LeaderboardService.format(n: number): string
	local v = math.floor(n)
	if v < 1000 then
		return tostring(v)
	end
	local i = 1
	local x = v
	while x >= 1000 and i < #SUFFIXES do
		x /= 1000
		i += 1
	end
	local s = if x >= 100
		then tostring(math.floor(x))
		elseif x >= 10 then string.format("%.1f", math.floor(x * 10) / 10)
		else string.format("%.2f", math.floor(x * 100) / 100)
	if string.find(s, "%.") then
		s = (string.gsub(string.gsub(s, "0+$", ""), "%.$", ""))
	end
	return s .. SUFFIXES[i]
end

-- The best `rows` of `list` by value (highest first; ties: lower userId first), zero scores dropped.
function LeaderboardService.top(list: { Entry }, rows: number): { Entry }
	local out: { Entry } = {}
	for _, e in list do
		if e.value > 0 then
			table.insert(out, e)
		end
	end
	table.sort(out, function(a, b)
		if a.value ~= b.value then
			return a.value > b.value
		end
		return a.userId < b.userId
	end)
	while #out > rows do
		table.remove(out)
	end
	return out
end

local function localEntries(stat: string): { Entry }
	local list: { Entry } = {}
	for _, player in Players:GetPlayers() do
		local data = DataService:Get(player)
		local v = data and tonumber(data[stat])
		if v then
			table.insert(list, { userId = player.UserId, value = v, name = player.DisplayName })
		end
	end
	return LeaderboardService.top(list, Leaderboards.Rows)
end

local function nameOf(userId: number): string
	local cached = names[userId]
	if cached then
		return cached
	end
	local inServer = Players:GetPlayerByUserId(userId)
	if inServer then
		names[userId] = inServer.DisplayName
		return inServer.DisplayName
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local result = if ok and typeof(name) == "string" then name else "Player"
	names[userId] = result
	return result
end

local function boardModel(key: string): Instance?
	local map = workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("Leaderboard_" .. key, true)
end

local function paint(key: string, entries: { Entry }, global: boolean)
	local model = boardModel(key)
	local screen = model and model:FindFirstChild("Screen")
	local gui = screen and screen:FindFirstChild("Rows")
	local list = gui and gui:FindFirstChild("List")
	if not (gui and list) then
		return
	end
	local board = Leaderboards.Boards[key]
	local winners: { LeaderboardPodiums.Entry } = {}
	for i = 1, Leaderboards.Rows do
		local row = list:FindFirstChild("Row" .. i)
		if not row then
			continue
		end
		local e = entries[i]
		local displayName = if e then (e.name or nameOf(e.userId)) else "---"
		if e and i <= 3 then
			table.insert(winners, { userId = e.userId, name = displayName })
		end
		local name = row:FindFirstChild("Name") :: TextLabel?
		local value = row:FindFirstChild("Value") :: TextLabel?
		local avatar = row:FindFirstChild("Avatar") :: ImageLabel?
		if name then
			name.Text = displayName
		end
		if value then
			value.Text = if e then board.unit .. LeaderboardService.format(e.value) else ""
		end
		if avatar then
			avatar.Image = if e and e.userId > 0 then `rbxthumb://type=AvatarHeadShot&id={e.userId}&w=150&h=150` else ""
		end
	end
	podiums:Update(model :: Instance, winners)
	local footer = gui:FindFirstChild("Footer") :: TextLabel?
	if footer then
		footer.Text = if global
			then "All servers · updates every minute"
			else "This server only (no DataStore access in Studio)"
	end
end

function LeaderboardService:Refresh()
	for key, board in Leaderboards.Boards do
		local store = stores[key]
		local done = written[key]
		if store then
			for _, player in Players:GetPlayers() do
				local data = DataService:Get(player)
				local v = data and tonumber(data[board.stat])
				if player.UserId > 0 and v and v > 0 and done[player.UserId] ~= v then
					local ok = pcall(store.SetAsync, store, tostring(player.UserId), math.floor(v))
					if ok then
						done[player.UserId] = v
					end
				end
			end
		end
		local entries: { Entry }? = nil
		if store then
			local ok, pages = pcall(store.GetSortedAsync, store, false, Leaderboards.Rows)
			if ok and pages then
				local list: { Entry } = {}
				for _, item in (pages :: DataStorePages):GetCurrentPage() do
					local id = tonumber(item.key)
					if id and typeof(item.value) == "number" then
						table.insert(list, { userId = id, value = item.value })
					end
				end
				entries = LeaderboardService.top(list, Leaderboards.Rows)
			end
		end
		paint(key, entries or localEntries(board.stat), entries ~= nil)
	end
end

-- A refresh soon (after a donation or a join), at most one queued at a time.
function LeaderboardService:RefreshSoon()
	if refreshQueued then
		return
	end
	refreshQueued = true
	task.delay(2, function()
		refreshQueued = false
		self:Refresh()
	end)
end

-- Counts a donation of `robux` for `player` (data.donated) and thanks them server-wide.
function LeaderboardService:AddDonation(player: Player, robux: number)
	local data = DataService:Get(player)
	if not data or robux <= 0 then
		return
	end
	DataService:Set(player, { donated = (data.donated or 0) + math.floor(robux) })
	AnnounceService:Announce(`{player.DisplayName} donated R$ {math.floor(robux)}! Thank you!`, "Mythic")
	self:RefreshSoon()
end

function LeaderboardService:Start()
	for key, board in Leaderboards.Boards do
		written[key] = {}
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, board.store)
		if ok and store then
			stores[key] = store
		end
	end
	Remotes.get("DonateTest").OnServerEvent:Connect(function(player, index)
		local d = typeof(index) == "number" and Leaderboards.Donations[index] or nil
		if RunService:IsStudio() and d and d.id == 0 then
			self:AddDonation(player, d.robux)
		end
	end)
	DataService:OnLoaded(function()
		self:RefreshSoon()
	end)
	Players.PlayerRemoving:Connect(function(player)
		-- their final scores (the loop may not run again before they're gone)
		for key, board in Leaderboards.Boards do
			local store = stores[key]
			local data = DataService:Get(player)
			local v = data and tonumber(data[board.stat])
			if store and player.UserId > 0 and v and v > 0 and written[key][player.UserId] ~= v then
				task.spawn(pcall, store.SetAsync, store, tostring(player.UserId), math.floor(v))
			end
			written[key][player.UserId] = nil
		end
	end)
	task.spawn(function()
		while true do
			self:Refresh()
			task.wait(Leaderboards.RefreshSeconds)
		end
	end)
end

return LeaderboardService
