-- DEV ONLY (tools/playtest/playtest.sh): collects PlayTestClient's checks and ends the Play session with them
-- (StudioTestService:EndTest -> the runner prints them). Gives the test player Kick Power 12 (a perfect kick
-- crosses several zones) and Run Speed level 200 (the egg outruns any avalanche when steered home), and a
-- hook (KTE_PlayTestHook) to hurry what normally takes minutes: "hatch" (placed eggs hatch now), "giveEgg"
-- (an inventory egg if the chase was lost). Never part of the game build.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local Economy = require(ReplicatedStorage.Shared.Config.Economy)
local Pets = require(ReplicatedStorage.Shared.Config.Pets)

local report = Instance.new("RemoteEvent")
report.Name = "KTE_PlayTestReport"
report.Parent = ReplicatedStorage
local hook = Instance.new("RemoteEvent")
hook.Name = "KTE_PlayTestHook"
hook.Parent = ReplicatedStorage

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

local function DataService()
	return require(ServerScriptService.Server.Services.DataService)
end

hook.OnServerEvent:Connect(function(player, what, arg)
	local data = DataService():Get(player)
	if not data then
		return
	end
	if what == "hatch" then
		local plots = table.clone(data.plots)
		local now = workspace:GetServerTimeNow()
		for uid, egg in plots do
			local e = table.clone(egg)
			e.hatchAt = now
			plots[uid] = e
		end
		DataService():Set(player, { plots = plots })
		table.insert(lines, "[setup] hook: placed eggs hatch now")
	elseif what == "giveEgg" then -- arg = a rarity (the first pet of it), else the first pet
		local petId = Pets[1].id
		for _, pet in Pets do
			if typeof(arg) == "string" and pet.rarity == arg then
				petId = pet.id
				break
			end
		end
		local eggs = table.clone(data.eggs)
		table.insert(eggs, { uid = HttpService:GenerateGUID(false), petId = petId })
		DataService():Set(player, { eggs = eggs })
		table.insert(lines, "[setup] hook: gave an inventory egg (" .. petId .. ")")
	elseif what == "set" and typeof(arg) == "table" then -- dev: set data fields (money, speedLevel ...)
		local partial = table.clone(arg)
		if typeof(partial.speedLevel) == "number" then
			partial.runSpeed = Economy.runSpeedAt(partial.speedLevel)
		end
		DataService():Set(player, partial)
		require(ServerScriptService.Server.Services.ChaseService):RefreshWalkSpeed(player)
	elseif what == "command" and typeof(arg) == "string" then -- the Studio chat commands (SackService.command)
		require(ServerScriptService.Server.Services.SackService).command(player, arg)
	elseif what == "sackstate" then -- dev: where the server sees the player's Kick Sack tools
		local seen = {}
		for _, holder in { player:FindFirstChild("SackGear"), player:FindFirstChildOfClass("Backpack"), player.Character, game:GetService("StarterPack"), player:FindFirstChild("StarterGear") } do
			for _, child in if holder then holder:GetChildren() else {} do
				if child:IsA("Tool") and child:GetAttribute("KickSack") then
					table.insert(seen, holder.Name .. ":" .. child.Name)
				end
			end
		end
		table.insert(lines, "[server] sack tools: " .. table.concat(seen, ", "))
	elseif what == "respawn" then
		player:LoadCharacter()
		table.insert(lines, "[setup] hook: respawned the test player")
	elseif what == "sack" and typeof(arg) == "number" then -- switch the Kick Sack (the Studio /sack command)
		require(ServerScriptService.Server.Services.SackService).command(player, "/sack " .. tostring(arg))
	end
end)

Players.PlayerAdded:Connect(function(player)
	local data = DataService():WaitForData(player)
	if data then
		DataService():Set(player, { kickPower = 400, speedLevel = 200, runSpeed = Economy.runSpeedAt(200) })
		table.insert(
			lines,
			string.format(
				"[setup] test player kickPower = 400 (a Perfect kick lands in zone 5), Run Speed level 200 (%.1f studs/s)",
				Economy.runSpeedAt(200)
			)
		)
	end
end)

task.delay(420, function()
	finish("TIMEOUT: the client did not finish within 420 s")
end)
