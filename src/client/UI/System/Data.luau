--!strict
-- UI data adapter: turns the server's PlayerData (DataChanged) + shared Config into the view models the
-- screens draw. It never decides anything: prices, states and totals come from the same Config formulas the
-- server uses (Economy.upgradeCost, Upgrades.Pen, TradeService.sellValue's rule), and every action is a
-- remote the server validates. Live per-pet numbers (Income with all multipliers, Stored cash) are read
-- from the server's replicated pedestal models (PlotService attributes).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Mutations = require(Shared.Config.Mutations)
local PetsConfig = require(Shared.Config.Pets)
local Rarities = require(Shared.Config.Rarities)
local Upgrades = require(Shared.Config.Upgrades)
local Zones = require(Shared.Config.Zones)

local Data = {}

Data.state = {} :: { [string]: any }
Data.busy = false -- our chase is running (KickResult -> ChaseEnded); rebirth is refused meanwhile
local listeners: { () -> () } = {}

function Data.setBusy(on: boolean)
	Data.busy = on
	for _, fn in listeners do
		task.spawn(fn)
	end
end

local petsById: { [string]: PetsConfig.Pet } = {}
for _, pet in PetsConfig do
	petsById[pet.id] = pet
end

function Data.apply(partial: { [string]: any })
	for k, v in partial do
		Data.state[k] = v
	end
	for _, fn in listeners do
		task.spawn(fn)
	end
end

function Data.onChanged(fn: () -> ())
	table.insert(listeners, fn)
end

-- Pending requests: the purchase remotes have no reply, so a request counts as done when the server's next
-- DataChanged makes `check()` true, and as failed if that hasn't happened within `timeout` seconds.
type Pending = { check: () -> boolean, callback: (ok: boolean) -> (), deadline: number }
local pending: { Pending } = {}

function Data.expect(check: () -> boolean, timeout: number, callback: (ok: boolean) -> ())
	local entry: Pending = { check = check, callback = callback, deadline = os.clock() + timeout }
	table.insert(pending, entry)
	task.delay(timeout, function()
		local i = table.find(pending, entry)
		if i then
			table.remove(pending, i)
			callback(false)
		end
	end)
end

table.insert(listeners, function()
	for i = #pending, 1, -1 do
		local entry = pending[i]
		if entry.check() then
			table.remove(pending, i)
			entry.callback(true)
		end
	end
end)

function Data.now(): number
	return workspace:GetServerTimeNow()
end

local function num(key: string, default: number): number
	local v = Data.state[key]
	return if typeof(v) == "number" then v else default
end

function Data.loaded(): boolean
	return typeof(Data.state.money) == "number"
end

function Data.money(): number
	return num("money", 0)
end

function Data.power(): number
	return num("kickPower", Economy.KickPower.base)
end

function Data.pet(petId: string): PetsConfig.Pet?
	return petsById[petId]
end

-- Training: boxing sacks ---------------------------------------------------------------------------------

export type SackState = "Equipped" | "Owned" | "Buy" | "Insufficient" | "Locked"
export type SackRow = {
	tier: number,
	name: string,
	gain: number, -- whole Kick Power per kick, with your rebirths (Economy.trainGain); no cap
	cost: number,
	fx: string,
	state: SackState,
}

-- The sack ladder (Config/Upgrades.Sack): your tier is the one you train with; lower tiers are owned and
-- superseded (there is no equip-a-lower-sack rule); only the next tier can be bought; later ones are locked.
function Data.sacks(): { SackRow }
	local tier = num("rackLevel", 1)
	local money = Data.money()
	local rows = {}
	for i, t in Upgrades.Sack.tiers do
		local state: SackState = if i == tier
			then "Equipped"
			elseif i < tier then "Owned"
			elseif i == tier + 1 then (if money >= t.cost then "Buy" else "Insufficient")
			else "Locked"
		local gain = Economy.trainGain(t.gain, num("rebirths", 0))
		table.insert(rows, { tier = i, name = t.name, gain = gain, cost = t.cost, fx = t.fx, state = state })
	end
	return rows
end

-- Training: run speed --------------------------------------------------------------------------------------

export type SpeedInfo = {
	current: number, -- studs/s now
	nextSpeed: number, -- studs/s after one more level
	currentText: string, -- "31.57" (2 decimals)
	nextText: string,
	stepText: string, -- "+0.06", "+0.008": enough decimals to show the real gain of one level
	level: number,
	base: number,
	cost: number?,
	maxed: boolean, -- always false: Run Speed has no level cap
}

-- Decimals that keep one level's gain visible: 2 normally, more once a level adds less than 0.01 (so "now ->
-- next" never reads the same number and a step never shows as a fake "+0").
function Data.speedDigits(step: number): number
	return if step >= 0.1 then 2 elseif step >= 0.01 then 3 elseif step >= 0.001 then 4 else 5
end
function Data.speedText(v: number, digits: number?): string
	return string.format(`%.{digits or 2}f`, v)
end
function Data.speedStepText(d: number): string
	return "+" .. string.format(`%.{Data.speedDigits(d)}f`, d)
end

function Data.speed(): SpeedInfo
	local rs = Economy.RunSpeed
	local level = num("speedLevel", 0)
	local step = Economy.runSpeedAt(level + 1) - Economy.runSpeedAt(level)
	return {
		current = Economy.runSpeedAt(level),
		nextSpeed = Economy.runSpeedAt(level + 1),
		currentText = Data.speedText(Economy.runSpeedAt(level), Data.speedDigits(step)),
		nextText = Data.speedText(Economy.runSpeedAt(level + 1), Data.speedDigits(step)),
		stepText = Data.speedStepText(Economy.runSpeedAt(level + 1) - Economy.runSpeedAt(level)),
		level = level,
		base = rs.base,
		cost = Economy.speedCost(level),
		maxed = false,
	}
end

-- Pen (pedestal slots) -------------------------------------------------------------------------------------

export type PenInfo = { level: number, slots: number, nextSlots: number?, cost: number? }

local function slotsForPen(level: number): number
	return math.clamp(Economy.PlotSlots.base + (level - 1) * Upgrades.Pen.slotsPerLevel, 1, Economy.PlotSlots.max)
end

function Data.pen(): PenInfo
	local level = num("penLevel", 1)
	local slots = slotsForPen(level)
	if slots >= Economy.PlotSlots.max then
		return { level = level, slots = slots }
	end
	local pen = Upgrades.Pen
	return {
		level = level,
		slots = slots,
		nextSlots = slotsForPen(level + 1),
		cost = math.floor(pen.costBase * pen.costGrowth ^ (level - 1)),
	}
end

-- Rebirth --------------------------------------------------------------------------------------------------

local LABELS: { [string]: string } = {
	money = "Cash",
	kickPower = "Kick Power",
	runSpeed = "Run Speed",
	eggs = "Eggs",
	pets = "Pets",
	rackLevel = "Boxing Sack",
	penLevel = "Pen size",
	discovered = "Pet Index",
}

export type RebirthInfo = {
	available: boolean, -- false when the rules aren't fully known (screen shows unavailable)
	count: number,
	power: number,
	required: number,
	ready: boolean,
	inChase: boolean,
	multiplier: number,
	nextMultiplier: number,
	nextCap: number, -- Kick Power the rebirth after this one will need
	resets: { string },
	keeps: { string },
}

function Data.rebirth(): RebirthInfo
	local rules = Economy.Rebirth
	local count = num("rebirths", 0)
	local power = Data.power()
	local required = Economy.rebirthPower(count)
	local resets, keeps = {}, {}
	local known = typeof(rules) == "table" and typeof(rules.resets) == "table" and typeof(rules.keeps) == "table"
	if known then
		for _, key in rules.resets do
			table.insert(resets, LABELS[key] or key)
			known = known and LABELS[key] ~= nil
		end
		for _, key in rules.keeps do
			table.insert(keeps, LABELS[key] or key)
		end
	end
	local per = rules.multiplierPerRebirth
	return {
		available = known,
		count = count,
		power = power,
		required = required,
		ready = power >= required,
		inChase = Data.busy,
		multiplier = 1 + count * per,
		nextMultiplier = 1 + (count + 1) * per,
		nextCap = Economy.rebirthPower(count + 1),
		resets = resets,
		keeps = keeps,
	}
end

-- Pedestal models (server-replicated attributes) -----------------------------------------------------------

local function plotsFolder(): Instance?
	local me = Players.LocalPlayer
	local index = if me then me:GetAttribute("BaseIndex") else nil
	local map = workspace:FindFirstChild("Map")
	local safe = map and map:FindFirstChild("SafeZone")
	local bases = safe and safe:FindFirstChild("Bases")
	local base = bases and typeof(index) == "number" and bases:FindFirstChild("Base" .. index)
	return base and base:FindFirstChild("Plots") or nil
end

-- petUid -> {income} from the placed pets' models (the server's exact income, all multipliers included).
local function liveStats(): { [string]: { income: number } }
	local out = {}
	local folder = plotsFolder()
	if folder then
		for _, model in folder:GetChildren() do
			local uid = model:GetAttribute("PetUid")
			if typeof(uid) == "string" then
				local income = model:GetAttribute("Income")
				out[uid] = { income = if typeof(income) == "number" then income else 0 }
			end
		end
	end
	return out
end

-- Eggs -----------------------------------------------------------------------------------------------------

export type EggRow = {
	uid: string,
	petId: string,
	name: string, -- egg name ("<Pet> Egg")
	rarity: string,
	model: string,
	slot: number?, -- 1 = placed in the pen (hatching); nil = in the inventory (hold it, then place it)
	placed: boolean,
	placedAt: number?,
	hatchAt: number?,
}

-- Hatching eggs (placed in the pen, soonest first) then inventory eggs (oldest first): hold one (EquipEgg)
-- and put it down in your pen. Eggs hatch by themselves on the server at hatchAt; the client never hatches.
function Data.eggs(): { EggRow }
	local rows: { EggRow } = {}
	local plots = Data.state.plots
	if typeof(plots) == "table" then
		for uidKey, egg in plots do
			if typeof(egg) == "table" and typeof(egg.petId) == "string" then
				local config = petsById[egg.petId]
				table.insert(rows, {
					uid = tostring(egg.uid or uidKey),
					petId = egg.petId,
					name = (if config then config.name else egg.petId) .. " Egg",
					rarity = if config then config.rarity else "Common",
					model = if config then config.model else "",
					slot = 1,
					placed = true,
					placedAt = egg.placedAt,
					hatchAt = egg.hatchAt,
				})
			end
		end
	end
	table.sort(rows, function(a, b)
		return (a.hatchAt or math.huge) < (b.hatchAt or math.huge)
	end)
	local waiting = Data.state.eggs
	if typeof(waiting) == "table" then
		for _, egg in waiting do
			if typeof(egg) == "table" and typeof(egg.petId) == "string" then
				local config = petsById[egg.petId]
				table.insert(rows, {
					uid = tostring(egg.uid),
					petId = egg.petId,
					name = (if config then config.name else egg.petId) .. " Egg",
					rarity = if config then config.rarity else "Common",
					model = if config then config.model else "",
					placed = false,
				})
			end
		end
	end
	return rows
end

-- Pets -----------------------------------------------------------------------------------------------------

export type PetRow = {
	uid: string,
	petId: string,
	name: string,
	rarity: string,
	rarityOrder: number,
	zone: number,
	model: string,
	size: string?,
	weather: string?,
	slot: number?, -- 1 = placed (roaming the pen, earning); nil = stored. Placed pets are protected from bulk sell
	placed: boolean,
	income: number, -- money per second (paid straight into money while placed)
	stored: number, -- always 0 (no pedestal cash any more); kept for older screens
	sellValue: number, -- what SellPet(s) pays: Economy.SellIncomeSeconds of base income x size x weather
}

local function mutationIncome(size: string?, weather: string?): number
	local s = if size then Mutations.Size[size] else nil
	local w = if weather then Mutations.Weather[weather] else nil
	return (if s then s.income else 1) * (if w then w.income else 1)
end

function Data.pets(): { PetRow }
	local rows: { PetRow } = {}
	local pets = Data.state.pets
	if typeof(pets) ~= "table" then
		return rows
	end
	local live = liveStats()
	local rebirthMult = 1 + num("rebirths", 0) * Economy.Rebirth.multiplierPerRebirth
	for uid, pet in pets do
		if typeof(pet) == "table" and typeof(pet.petId) == "string" then
			local config = petsById[pet.petId]
			local base = if config then config.income else 0
			local mult = mutationIncome(pet.size, pet.weather)
			local stats = live[uid]
			local rarity = if config then config.rarity else "Common"
			table.insert(rows, {
				uid = uid,
				petId = pet.petId,
				name = if config then config.name else pet.petId,
				rarity = rarity,
				rarityOrder = if Rarities[rarity] then Rarities[rarity].order else 0,
				zone = if config then config.zone else 0,
				model = if config then config.model else "",
				size = pet.size,
				weather = pet.weather,
				slot = if pet.placed == true then 1 else nil,
				placed = pet.placed == true,
				income = if stats then stats.income else base * mult * rebirthMult,
				stored = 0,
				sellValue = math.floor(base * mult * Economy.SellIncomeSeconds),
			})
		end
	end
	return rows
end

export type Capacity = { slots: number, eggs: number, pets: number, waitingEggs: number, unplacedPets: number }

-- Pen capacity: placed eggs and placed pets share it (PlotService); everything else is in the inventory.
function Data.capacity(): Capacity
	local eggs, pets, waiting, unplaced = 0, 0, 0, 0
	if typeof(Data.state.plots) == "table" then
		for _ in Data.state.plots do
			eggs += 1
		end
	end
	if typeof(Data.state.pets) == "table" then
		for _, pet in Data.state.pets do
			if typeof(pet) == "table" and pet.placed == true then
				pets += 1
			else
				unplaced += 1
			end
		end
	end
	if typeof(Data.state.eggs) == "table" then
		waiting = #Data.state.eggs
	end
	return { slots = Data.pen().slots, eggs = eggs, pets = pets, waitingEggs = waiting, unplacedPets = unplaced }
end

-- Pet Index completion milestones (Economy.IndexMilestones; claimed on the server, IndexService) -----------

export type Milestone = {
	count: number,
	money: number,
	incomeBonus: number?,
	state: "Claimed" | "Claim" | "Locked",
}

-- Different pets discovered (Pet Index), all of them, and the milestone rows.
function Data.milestones(): (number, number, { Milestone })
	local discovered = Data.state.discovered
	local found, all = 0, 0
	for _, pet in PetsConfig do
		all += 1
		if typeof(discovered) == "table" and discovered[pet.id] then
			found += 1
		end
	end
	local claimed = Data.state.indexMilestones
	local rows: { Milestone } = {}
	for _, m in Economy.IndexMilestones do
		local done = typeof(claimed) == "table" and claimed[tostring(m.count)] == true
		table.insert(rows, {
			count = m.count,
			money = m.money,
			incomeBonus = m.incomeBonus,
			state = if done then "Claimed" elseif found >= m.count then "Claim" else "Locked",
		})
	end
	return found, all, rows
end

function Data.claimableMilestones(): number
	local _, _, rows = Data.milestones()
	local n = 0
	for _, r in rows do
		if r.state == "Claim" then
			n += 1
		end
	end
	return n
end

-- Pet Index ------------------------------------------------------------------------------------------------

export type IndexPet = { petId: string, name: string, rarity: string, model: string, income: number, discovered: boolean }
export type IndexZone = {
	id: number,
	name: string,
	ground: Color3,
	accent: Color3,
	pets: { IndexPet },
	found: number,
	reward: { money: number }?,
	claimed: boolean,
}

function Data.discovered(): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if typeof(Data.state.discovered) == "table" then
		for id, v in Data.state.discovered do
			if v then
				set[tostring(id)] = true
			end
		end
	end
	if typeof(Data.state.pets) == "table" then -- the server backfills these too; harmless before it does
		for _, pet in Data.state.pets do
			if typeof(pet) == "table" and typeof(pet.petId) == "string" then
				set[pet.petId] = true
			end
		end
	end
	return set
end

function Data.index(): { IndexZone }
	local discovered = Data.discovered()
	local claims = if typeof(Data.state.indexClaims) == "table" then Data.state.indexClaims else {}
	local zones: { IndexZone } = {}
	for _, zone in Zones do
		local entry: IndexZone = {
			id = zone.id,
			name = zone.name,
			ground = zone.ground,
			accent = zone.accent,
			pets = {},
			found = 0,
			reward = Economy.IndexRewards[zone.id],
			claimed = claims[tostring(zone.id)] == true,
		}
		for _, pet in PetsConfig do
			if pet.zone == zone.id then
				local seen = discovered[pet.id] == true
				table.insert(entry.pets, {
					petId = pet.id,
					name = pet.name,
					rarity = pet.rarity,
					model = pet.model,
					income = pet.income,
					discovered = seen,
				})
				if seen then
					entry.found += 1
				end
			end
		end
		if #entry.pets > 0 then
			table.insert(zones, entry)
		end
	end
	return zones
end

-- A zone reward is claimable: configured, every pet found, not claimed yet.
function Data.claimableZones(): number
	local n = 0
	for _, zone in Data.index() do
		if zone.reward and not zone.claimed and zone.found == #zone.pets then
			n += 1
		end
	end
	return n
end

-- Developer products ---------------------------------------------------------------------------------------

export type Product = { key: string, id: number, money: number, configured: boolean }

-- Economy.DevProducts in a stable order (by cash amount). id = 0 means "not created yet": shown as
-- unavailable, never prompted.
function Data.products(): { Product }
	local list: { Product } = {}
	for key, p in Economy.DevProducts do
		table.insert(list, { key = key, id = p.id, money = p.money, configured = p.id ~= 0 })
	end
	table.sort(list, function(a, b)
		return a.money < b.money
	end)
	return list
end

return Data
