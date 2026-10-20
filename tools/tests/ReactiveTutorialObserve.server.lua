--!strict
-- Temporary observer for a native single-player walkthrough. Reads actual server data; grants nothing.
-- Stop Play to remove the observer/listeners. Never maps into the production build.
local HttpService = game:GetService("HttpService")
local DataService = require(game.ServerScriptService.Server.Services.DataService)
local player = game.Players:GetPlayers()[1]
local began = os.clock()
local records = {}
local function count(t)
	local n = 0
	for _ in t or {} do
		n += 1
	end
	return n
end
local function record(reason)
	local d = DataService:Get(player)
	if not d or #records >= 100 then
		return
	end
	local placed = 0
	for _, pet in d.pets do
		if pet.placed then
			placed += 1
		end
	end
	local index = player:GetAttribute("BaseIndex")
	local base = index and workspace.Map.SafeZone.Bases:FindFirstChild("Base" .. index)
	local rendered = 0
	if base and base:FindFirstChild("Plots") then
		for _, model in base.Plots:GetChildren() do
			if model:GetAttribute("Kind") == "Pet" then
				rendered += 1
			end
		end
	end
	table.insert(records, {
		reason = reason,
		seconds = os.clock() - began,
		step = player:GetAttribute("TutorialStep"),
		power = d.kickPower,
		money = d.money,
		hits = d.tutorial.trainingHits,
		trained = d.tutorial.trained,
		foundPen = d.tutorial.foundPen,
		kicks = d.stats.kicks,
		secured = d.stats.secured,
		lost = d.stats.lost,
		eggs = count(d.eggs),
		hatching = count(d.plots),
		pets = count(d.pets),
		placedPets = placed,
		renderedPets = rendered,
		done = d.tutorial.done,
		skipped = d.tutorial.skipped,
		baseIndex = index,
	})
	workspace:SetAttribute("ReactiveTutorialWalkthrough", HttpService:JSONEncode(records))
end
player:GetAttributeChangedSignal("TutorialStep"):Connect(function()
	record("step")
end)
player:GetAttributeChangedSignal("TutorialDone"):Connect(function()
	record("complete")
end)
DataService:OnChanged(function(p, partial)
	if p == player and (partial.eggs or partial.plots or partial.pets or partial.stats or partial.tutorial) then
		record("data")
	end
end)
record("start")
