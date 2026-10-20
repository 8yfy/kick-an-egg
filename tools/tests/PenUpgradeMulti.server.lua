-- Temporary server Script for StudioTestService:ExecuteMultiplayerTestAsync(2, {}).
-- Not mapped into the production place. Use with PenUpgradeMulti.client.lua in StarterPlayerScripts.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Data = require(game.ServerScriptService.Server.Services.DataService)
local Plot = require(game.ServerScriptService.Server.Services.PlotService)
local remote = Instance.new("RemoteEvent")
remote.Name = "PenUpgradeMultiQA"
local ready, reports = {}, {}
remote.OnServerEvent:Connect(function(p, kind, report)
	if kind == "ready" then
		ready[p] = true
	end
	if kind == "report" then
		reports[p] = report
	end
end)
remote.Parent = RS
local function finish()
	local result = { passed = false, clients = {} }
	for _, p in Players:GetPlayers() do
		local d = Data:Get(p)
		local report = reports[p]
		table.insert(result.clients, {
			level = d and d.penLevel,
			ownerMatches = Plot:GetBase(p) and Plot:GetBase(p):GetAttribute("OwnerUserId") == p.UserId,
			report = report,
		})
	end
	result.passed = #result.clients == 2
	for _, c in result.clients do
		local r = c.report
		result.passed = result.passed
			and c.level == 2
			and c.ownerMatches
			and r ~= nil
			and r.notices == 1
			and r.audio == 1
			and r.ownFX
			and not r.foreignFX
			and r.cleaned
	end
	game:GetService("StudioTestService"):EndTest(result)
end
task.delay(35, finish)
local deadline = os.clock() + 25
repeat
	task.wait(0.1)
until #Players:GetPlayers() == 2 or os.clock() > deadline
for _, p in Players:GetPlayers() do
	Data:WaitForData(p)
	Data:Set(p, { money = 1e8 })
end
repeat
	task.wait(0.1)
until (function()
		local count = 0
		for _ in ready do
			count += 1
		end
		return count == 2
	end)() or os.clock() > deadline
workspace:SetAttribute("PenUpgradeMultiAt", workspace:GetServerTimeNow() + 0.6)
repeat
	task.wait(0.1)
until (function()
		local count = 0
		for _ in reports do
			count += 1
		end
		return count == 2
	end)() or os.clock() > deadline
finish()
