--!strict
-- The show-don't-tell tutorial (server side). The current step is WORKED OUT from the player's real data and what
-- the server sees (never from time, never from the client's word), so it can't be skipped by accident, survives
-- rejoining (it is the data) and can't softlock: every step is finished by an action the player can always do.
--   1 KICK_LINE   reach the kick line                       (the server sees you on the pad; or you kicked before)
--   2 PRESS_KICK  press KICK                                (the client shows 2 / 3 around the meter)
--   3 TIME_KICK   time your kick                            (2 and 3 end with your first real kick)
--   4 WATCH_EGG   watch your egg fly, then steer it home    (ends when your first chase ends, won or lost)
--   5 COLLECT     bring an egg home                         (first secured egg; after a loss: kick again /
--                                                            the client suggests Run Speed)
--   6 PLACE_EGG   hold the egg and put it down in your pen  (an egg placed, hatching or hatched)
--   7 HATCH       wait for it to hatch                      (you own a pet)
--   8 INCOME      your pet earns money                      (a pet in your pen and money earned)
--   9 UPGRADE     a real upgrade, when you can afford one   (Run Speed level, a Kick Sack or a bigger pen)
--  10 DONE        celebration; data.tutorial.done = true
-- (The spec's order put UPGRADE before placing the egg; a new player has no money until a pet earns, so the real
-- upgrade comes once it is affordable instead of asking for an impossible purchase.)
-- The step is mirrored on the player as attribute TutorialStep (0 = finished / skipped); SkipTutorial ends it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KickPad = require(Shared.KickPad)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)

local TutorialService = {}

TutorialService.Steps = {
	KICK_LINE = 1,
	PRESS_KICK = 2,
	TIME_KICK = 3,
	WATCH_EGG = 4,
	COLLECT = 5,
	PLACE_EGG = 6,
	HATCH = 7,
	INCOME = 8,
	UPGRADE = 9,
	DONE = 10,
}
local S = TutorialService.Steps

local TICK = 0.5
local limiter = RateLimiter.new()
local onPad: { [Player]: boolean } = {} -- seen on the kick line this session (step 1 for new players)
local moneyAt: { [Player]: number } = {} -- money when the first pet was in the pen (step 8)

local function count(t: any): number
	local n = 0
	if typeof(t) == "table" then
		for _ in t do
			n += 1
		end
	end
	return n
end

-- The step for this data (pure; the tests call it). `seenOnPad`: the server saw the character on the kick pad.
-- `earned`: money has gone up since a pet was first in the pen.
function TutorialService.stepFor(data: { [string]: any }, seenOnPad: boolean, earned: boolean): number
	local tutorial = data.tutorial or {}
	if tutorial.done or tutorial.skipped then
		return 0
	end
	local stats = data.stats or {}
	local kicks, secured, lost = stats.kicks or 0, stats.secured or 0, stats.lost or 0
	local pets, placedEggs, eggs = count(data.pets), count(data.plots), count(data.eggs)
	local placedPets = 0
	for _, pet in data.pets or {} do
		if typeof(pet) == "table" and pet.placed then
			placedPets += 1
		end
	end
	local upgraded = (data.speedLevel or 0) > 0 or (data.rackLevel or 1) > 1 or (data.penLevel or 1) > 1
	if kicks == 0 then
		return if seenOnPad then S.PRESS_KICK else S.KICK_LINE
	end
	if secured + lost == 0 and eggs + placedEggs + pets == 0 then
		return S.WATCH_EGG
	end
	if secured == 0 and eggs + placedEggs + pets == 0 then
		return S.COLLECT
	end
	if placedEggs + pets == 0 then
		return S.PLACE_EGG
	end
	if pets == 0 then
		return S.HATCH
	end
	if placedPets > 0 and not earned then
		return S.INCOME
	end
	if not upgraded then
		return S.UPGRADE
	end
	return S.DONE
end

local function update(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local character = player.Character
	if not onPad[player] and character and KickPad.has(character, KickPad.ACCEPT_RADIUS) then
		onPad[player] = true
	end
	-- step 8: money has to actually arrive from a placed pet
	local placedPet = false
	for _, pet in data.pets do
		if typeof(pet) == "table" and pet.placed then
			placedPet = true
		end
	end
	if placedPet and not moneyAt[player] then
		moneyAt[player] = data.money
	end
	local earned = moneyAt[player] ~= nil and data.money > (moneyAt[player] :: number)
	local step = TutorialService.stepFor(data, onPad[player] == true, earned)
	if step == S.DONE then
		DataService:Set(player, { tutorial = { done = true, skipped = false } })
		Analytics.custom(player, "TutorialDone", 1)
		player:SetAttribute("TutorialDone", true) -- the client plays the celebration once
		step = 0
	end
	if player:GetAttribute("TutorialStep") ~= step then
		player:SetAttribute("TutorialStep", step)
	end
end

function TutorialService:Start()
	Remotes.get("SkipTutorial").OnServerEvent:Connect(function(player: Player)
		local data = DataService:Get(player)
		if not limiter:allow(player) or not data or data.tutorial.done then
			return
		end
		DataService:Set(player, { tutorial = { done = false, skipped = true } })
		player:SetAttribute("TutorialStep", 0)
	end)
	Players.PlayerRemoving:Connect(function(player)
		onPad[player] = nil
		moneyAt[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				xpcall(update, function(err)
					warn(`[TutorialService] {player.Name}: {err}`)
				end, player)
			end
		end
	end)
end

return TutorialService
