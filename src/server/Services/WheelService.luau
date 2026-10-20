--!strict
-- The Prize Wheel (Config/Wheel). Spins are banked in data.wheelSpins (Robux packs: MonetizationService; Studio
-- test packs: WheelTestSpins). SpinWheel spends one: the server checks the player has a spin, is near the wheel
-- and has no spin still turning, rolls the segment by weight, works out the prize (cash from the current pet
-- income, or an egg of the segment's rarity from the zones the player has reached), saves it as
-- data.wheelPending and tells the client (WheelResult) so it can spin the wheel. When the wheel stops
-- (Config/Wheel.SpinSeconds) the prize is granted; a player who leaves first gets it on their next join.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Wheel = require(Shared.Config.Wheel)
local Pets = require(Shared.Config.Pets)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local AnnounceService = require(script.Parent.AnnounceService)
local Analytics = require(script.Parent.Parent.Util.Analytics)

export type Prize = {
	uid: string,
	segment: number,
	key: string,
	kind: string,
	amount: number?,
	petId: string?,
	rarity: string?,
}

local WheelService = {}

local rng = Random.new()
local busy: { [Player]: number } = {}

-- Segment index by weight.
function WheelService.roll(random: Random): number
	local total = 0
	for _, s in Wheel.Segments do
		total += s.weight
	end
	local r = random:NextNumber() * total
	for i, s in Wheel.Segments do
		r -= s.weight
		if r < 0 then
			return i
		end
	end
	return #Wheel.Segments
end

-- The furthest zone the player has reached: zones of pets they have discovered or own, at least 1.
function WheelService.reachedZone(data: { [string]: any }): number
	local byId: { [string]: number } = {}
	for _, p in Pets do
		byId[p.id] = p.zone
	end
	local best = 1
	local function see(petId: any)
		local z = typeof(petId) == "string" and byId[petId] or nil
		if z and z > best then
			best = z
		end
	end
	if typeof(data.discovered) == "table" then
		for petId in data.discovered do
			see(petId)
		end
	end
	for _, list in { data.pets, data.eggs, data.plots } do
		if typeof(list) == "table" then
			for _, entry in list do
				if typeof(entry) == "table" then
					see(entry.petId)
				end
			end
		end
	end
	return best
end

-- A pet of `rarity` from zones 1..zone; if there is none, one from the earliest zone that has that rarity.
function WheelService.pickPet(rarity: string, zone: number, random: Random): string?
	local pool: { string } = {}
	local earliest: number? = nil
	for _, p in Pets do
		if p.rarity == rarity then
			if p.zone <= zone then
				table.insert(pool, p.id)
			end
			if not earliest or p.zone < earliest then
				earliest = p.zone
			end
		end
	end
	if #pool == 0 and earliest then
		for _, p in Pets do
			if p.rarity == rarity and p.zone == earliest then
				table.insert(pool, p.id)
			end
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[random:NextInteger(1, #pool)]
end

-- The prize for segment `index` given the player's data and current income per second.
function WheelService.prize(index: number, data: { [string]: any }, incomePerSecond: number, random: Random): Prize
	local s = Wheel.Segments[index]
	local prize: Prize = { uid = HttpService:GenerateGUID(false), segment = index, key = s.key, kind = s.kind }
	if s.kind == "Cash" then
		local ips = if incomePerSecond == incomePerSecond and incomePerSecond > 0 then incomePerSecond else 0
		prize.amount = math.max(s.min or 0, math.floor(ips * (s.seconds or 0)))
	else
		prize.rarity = s.rarity
		prize.petId = WheelService.pickPet(s.rarity or "Common", WheelService.reachedZone(data), random)
	end
	return prize
end

-- The data change that grants `prize` (and clears the pending spin). Granting twice is a no-op for eggs.
function WheelService.grantPartial(data: { [string]: any }, prize: { [string]: any }): { [string]: any }
	local partial: { [string]: any } = { wheelPending = false }
	if prize.kind == "Cash" and typeof(prize.amount) == "number" and prize.amount > 0 then
		partial.money = data.money + math.floor(prize.amount)
	elseif prize.kind == "Egg" and typeof(prize.petId) == "string" and typeof(prize.uid) == "string" then
		for _, egg in data.eggs do
			if egg.uid == prize.uid then
				return partial
			end
		end
		local eggs = table.clone(data.eggs)
		table.insert(eggs, { uid = prize.uid, petId = prize.petId })
		partial.eggs = eggs
	end
	return partial
end

local function grant(player: Player)
	local data = DataService:Get(player)
	local prize = data and data.wheelPending
	if not data or typeof(prize) ~= "table" then
		return
	end
	DataService:Set(player, WheelService.grantPartial(data, prize))
	if prize.kind == "Cash" and typeof(prize.amount) == "number" then
		Analytics.money(player, "Source", prize.amount, "Gameplay", "Wheel" .. prize.key)
	end
	local seg = Wheel.Segments[prize.segment]
	if seg and seg.jackpot and typeof(prize.petId) == "string" then
		for _, p in Pets do
			if p.id == prize.petId then
				AnnounceService:Announce(`{player.DisplayName} won the JACKPOT: a {p.name} egg!`, p.rarity)
			end
		end
	end
end

local function podium(): BasePart?
	local map = workspace:FindFirstChild("Map")
	local wheel = map and map:FindFirstChild("SpinWheel", true)
	local p = wheel and wheel:FindFirstChild("Podium")
	return if p and p:IsA("BasePart") then p else nil
end

local function near(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local at = podium()
	if not (root and root:IsA("BasePart") and at) then
		return false
	end
	return (root.Position - at.Position).Magnitude <= Wheel.Reach
end

local function onSpin(player: Player)
	if (busy[player] or 0) > os.clock() then
		return
	end
	local data = DataService:Get(player)
	if not data or typeof(data.wheelPending) == "table" or (data.wheelSpins or 0) < 1 or not near(player) then
		return
	end
	busy[player] = os.clock() + Wheel.SpinSeconds + 0.5
	local index = WheelService.roll(rng)
	local prize = WheelService.prize(index, data, PlotService.incomePerSecond(player, data), rng)
	DataService:Set(player, { wheelSpins = data.wheelSpins - 1, wheelPending = prize })
	task.spawn(function()
		DataService:SaveNow(player) -- the spin is spent and the prize recorded even if the server stops now
	end)
	Analytics.custom(player, "WheelSpin", 1, prize.key)
	Remotes.get("WheelResult"):FireClient(player, {
		segment = index,
		key = prize.key,
		kind = prize.kind,
		amount = prize.amount,
		petId = prize.petId,
		rarity = prize.rarity,
		spinSeconds = Wheel.SpinSeconds,
	})
	task.delay(Wheel.SpinSeconds, function()
		if player.Parent then
			grant(player)
		end
	end)
end

-- Studio only: grant a pack whose developer product isn't created yet (id 0), so the wheel can be tested.
local function onTestSpins(player: Player, pack: any)
	if not RunService:IsStudio() or typeof(pack) ~= "string" then
		return
	end
	local product = Wheel.Products[pack]
	local data = DataService:Get(player)
	if product and product.id == 0 and data then
		DataService:Set(player, { wheelSpins = data.wheelSpins + product.spins })
	end
end

function WheelService:Start()
	Remotes.get("SpinWheel").OnServerEvent:Connect(onSpin)
	Remotes.get("WheelTestSpins").OnServerEvent:Connect(onTestSpins)
	DataService:OnLoaded(function(player)
		grant(player) -- a spin that was still turning when they left
	end)
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return WheelService
