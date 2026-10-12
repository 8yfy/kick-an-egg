-- DEV ONLY (tools/playtest/playtest.sh): collects PlayTestClient's checks and ends the Play session with them
-- (StudioTestService:EndTest -> the runner prints them). Gives the test player Kick Power 12 so a perfect kick
-- crosses several zones. Never part of the game build.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local report = Instance.new("RemoteEvent")
report.Name = "KTE_PlayTestReport"
report.Parent = ReplicatedStorage

local lines = {}
local done = false
local function finish(extra)
	if done then
		return
	end
	done = true
	if extra then
		table.insert(lines, extra)
	end
	StudioTestService:EndTest(table.concat(lines, "\n"))
end

report.OnServerEvent:Connect(function(_player, kind, text)
	if kind == "DONE" then
		finish()
		return
	end
	table.insert(lines, string.format("[%6.1fs] %s %s", workspace.DistributedGameTime, kind, text))
end)

Players.PlayerAdded:Connect(function(player)
	local DataService = require(ServerScriptService.Server.Services.DataService)
	local data = DataService:WaitForData(player)
	if data then
		data.kickPower = 12
		table.insert(lines, "[setup] test player kickPower = 12")
	end
end)

task.delay(260, function()
	finish("TIMEOUT: the client did not finish within 260 s")
end)
