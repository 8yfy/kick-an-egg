--!strict
-- Pet trading (both players confirm, the server swaps atomically) and SellPet.
--
-- Payloads (Remotes.luau leaves these to this file):
--   C->S TradeRequest(targetUserId: number)              ask someone to trade (expires after 30 s)
--   S->C TradeRequest({ fromUserId: number })              "X wants to trade" (to the target)
--   C->S TradeRespond(fromUserId: number, accept: boolean) answer a request
--   S->C TradeRespond({ userId: number, accepted: boolean }) to the requester when declined
--   C->S TradeOffer(petUids: { string })                  replace your whole offer (max 8 pets)
--   C->S TradeConfirm(action: "confirm" | "unconfirm" | "cancel")
--   S->C TradeOffer(state) after every change, to both players:
--        state = { tradeId: string, status: "open" | "completed" | "cancelled", reason: string?,
--                  users: { number }, offers: { [string(userId)]: { string } },
--                  confirmed: { [string(userId)]: boolean }, confirmAfter: number }
--   Any offer change clears both confirmations; confirming is allowed only from
--   `confirmAfter` (server time, 2 s after the last change) so offers can't be swapped at the last moment.
--   Received pets go onto free pedestals (PlotService:PlaceUnplacedPets), or stay in the inventory.
--
--   C->S SellPet(petUid: string) → money += base income x size x weather x Economy.SellIncomeSeconds,
--        plus the pet's uncollected cash. Traded pets keep their uncollected cash.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local PlotService = require(script.Parent.PlotService)

type Trade = {
	id: string,
	a: Player,
	b: Player,
	offers: { [Player]: { string } },
	confirmed: { [Player]: boolean },
	confirmAfter: number,
}

local MAX_OFFER = 8
local REQUEST_TTL = 30
local CONFIRM_DELAY = 2

local TradeService = {}

local limiter = RateLimiter.new()
local requests: { [Player]: { from: Player, at: number } } = {} -- keyed by target
local tradeOf: { [Player]: Trade } = {}
local remotes: { [string]: RemoteEvent } = {}

-- Pure swap (tested headlessly). Returns the new pets tables for A and B, or nil if any
-- offered pet is no longer owned by its offerer.
function TradeService.swap(
	petsA: { [string]: any },
	petsB: { [string]: any },
	offerA: { string },
	offerB: { string }
): ({ [string]: any }?, { [string]: any }?)
	for _, uid in offerA do
		if not petsA[uid] then
			return nil, nil
		end
	end
	for _, uid in offerB do
		if not petsB[uid] then
			return nil, nil
		end
	end
	local newA, newB = table.clone(petsA), table.clone(petsB)
	for _, uid in offerA do
		local pet = table.clone(petsA[uid])
		pet.slot = nil
		newA[uid] = nil
		newB[uid] = pet
	end
	for _, uid in offerB do
		local pet = table.clone(petsB[uid])
		pet.slot = nil
		newB[uid] = nil
		newA[uid] = pet
	end
	return newA, newB
end

function TradeService.sellValue(pet: { [string]: any }): number
	return math.floor(PlotService.petIncome(pet :: any, { rebirths = 0 }, 1) * Economy.SellIncomeSeconds)
end

local function partnerOf(trade: Trade, player: Player): Player
	return if trade.a == player then trade.b else trade.a
end

local function sendState(trade: Trade, status: string, reason: string?)
	local offers, confirmed = {}, {}
	for _, player in { trade.a, trade.b } do
		offers[tostring(player.UserId)] = trade.offers[player]
		confirmed[tostring(player.UserId)] = trade.confirmed[player] == true
	end
	local state = {
		tradeId = trade.id,
		status = status,
		reason = reason,
		users = { trade.a.UserId, trade.b.UserId },
		offers = offers,
		confirmed = confirmed,
		confirmAfter = trade.confirmAfter,
	}
	for _, player in { trade.a, trade.b } do
		if player.Parent then
			remotes.TradeOffer:FireClient(player, state)
		end
	end
end

local function closeTrade(trade: Trade, status: string, reason: string?)
	if tradeOf[trade.a] == trade then
		tradeOf[trade.a] = nil
	end
	if tradeOf[trade.b] == trade then
		tradeOf[trade.b] = nil
	end
	sendState(trade, status, reason)
end

-- True if this pet is offered in an open trade (can't be sold meanwhile).
function TradeService:IsOffered(player: Player, petUid: string): boolean
	local trade = tradeOf[player]
	return trade ~= nil and table.find(trade.offers[player], petUid) ~= nil
end

local function complete(trade: Trade)
	local dataA, dataB = DataService:Get(trade.a), DataService:Get(trade.b)
	if not dataA or not dataB then
		closeTrade(trade, "cancelled", "Data not loaded")
		return
	end
	local newA, newB = TradeService.swap(dataA.pets, dataB.pets, trade.offers[trade.a], trade.offers[trade.b])
	if not newA or not newB then
		closeTrade(trade, "cancelled", "An offered pet is gone")
		return
	end
	-- Both writes happen in the same frame (no yield in between).
	DataService:Set(trade.a, { pets = newA })
	DataService:Set(trade.b, { pets = newB })
	closeTrade(trade, "completed")
	for _, player in { trade.a, trade.b } do
		Analytics.custom(player, "TradeCompleted", #trade.offers[partnerOf(trade, player)])
	end
	for _, player in { trade.a, trade.b } do
		PlotService:PlaceUnplacedPets(player)
		task.spawn(function()
			DataService:SaveNow(player)
		end)
	end
end

local function onRequest(player: Player, targetUserId: any)
	if not limiter:allow(player) or typeof(targetUserId) ~= "number" then
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player or tradeOf[player] or tradeOf[target] then
		return
	end
	requests[target] = { from = player, at = os.clock() }
	remotes.TradeRequest:FireClient(target, { fromUserId = player.UserId })
end

local function onRespond(player: Player, fromUserId: any, accept: any)
	if not limiter:allow(player) or typeof(fromUserId) ~= "number" or typeof(accept) ~= "boolean" then
		return
	end
	local request = requests[player]
	if not request or request.from.UserId ~= fromUserId or os.clock() - request.at > REQUEST_TTL then
		return
	end
	requests[player] = nil
	local from = request.from
	if not accept then
		remotes.TradeRespond:FireClient(from, { userId = player.UserId, accepted = false })
		return
	end
	if not from.Parent or tradeOf[from] or tradeOf[player] then
		return
	end
	local trade: Trade = {
		id = HttpService:GenerateGUID(false),
		a = from,
		b = player,
		offers = { [from] = {}, [player] = {} },
		confirmed = {},
		confirmAfter = workspace:GetServerTimeNow(),
	}
	tradeOf[from] = trade
	tradeOf[player] = trade
	sendState(trade, "open")
end

local function onOffer(player: Player, petUids: any)
	if not limiter:allow(player) or typeof(petUids) ~= "table" then
		return
	end
	local trade = tradeOf[player]
	local data = DataService:Get(player)
	if not trade or not data then
		return
	end
	local offer: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, uid in petUids do
		if typeof(uid) ~= "string" or seen[uid] or not data.pets[uid] or #offer >= MAX_OFFER then
			return -- reject the whole offer
		end
		seen[uid] = true
		table.insert(offer, uid)
	end
	trade.offers[player] = offer
	table.clear(trade.confirmed)
	trade.confirmAfter = workspace:GetServerTimeNow() + CONFIRM_DELAY
	sendState(trade, "open")
end

local function onConfirm(player: Player, action: any)
	if not limiter:allow(player) then
		return
	end
	local trade = tradeOf[player]
	if not trade then
		return
	end
	if action == "cancel" then
		closeTrade(trade, "cancelled", `{player.DisplayName} cancelled`)
	elseif action == "unconfirm" then
		trade.confirmed[player] = nil
		sendState(trade, "open")
	elseif action == "confirm" then
		if workspace:GetServerTimeNow() < trade.confirmAfter then
			return
		end
		trade.confirmed[player] = true
		if trade.confirmed[partnerOf(trade, player)] then
			complete(trade)
		else
			sendState(trade, "open")
		end
	end
end

local function onSellPet(player: Player, petUid: any)
	if not limiter:allow(player) or typeof(petUid) ~= "string" then
		return
	end
	local data = DataService:Get(player)
	local pet = data and data.pets[petUid]
	if not data or not pet or TradeService:IsOffered(player, petUid) then
		return
	end
	local pets = table.clone(data.pets)
	pets[petUid] = nil
	local value = TradeService.sellValue(pet) + math.floor(pet.stored or 0) -- uncollected cash too
	DataService:Set(player, { pets = pets, money = data.money + value })
	Analytics.money(player, "Source", value, "Gameplay", "SellPet")
	PlotService:Refresh(player)
end

function TradeService:Init()
	for _, name in { "TradeRequest", "TradeRespond", "TradeOffer", "TradeConfirm" } do
		remotes[name] = Remotes.get(name)
	end
end

function TradeService:Start()
	remotes.TradeRequest.OnServerEvent:Connect(onRequest)
	remotes.TradeRespond.OnServerEvent:Connect(onRespond)
	remotes.TradeOffer.OnServerEvent:Connect(onOffer)
	remotes.TradeConfirm.OnServerEvent:Connect(onConfirm)
	Remotes.get("SellPet").OnServerEvent:Connect(onSellPet)
	Players.PlayerRemoving:Connect(function(player)
		requests[player] = nil
		for target, request in requests do
			if request.from == player then
				requests[target] = nil
			end
		end
		local trade = tradeOf[player]
		if trade then
			closeTrade(trade, "cancelled", `{player.DisplayName} left`)
		end
	end)
end

return TradeService
