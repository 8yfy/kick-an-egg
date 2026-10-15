-- DEV ONLY: run by run-in-roblox (plugin context) against the play-test build. Starts a real Studio Play
-- session (server + client with a LocalPlayer) and prints what PlayTestServer ends it with.
local RunService = game:GetService("RunService")
local StudioTestService = game:GetService("StudioTestService")
if not RunService:IsEdit() then
	-- run-in-roblox loads this plugin script into the Play session's DataModels too: only the edit copy drives
	-- the test, the others just wait until the session is torn down
	while true do
		task.wait(60)
	end
end
print("PLAYTEST_START")
local ok, result = pcall(function()
	return StudioTestService:ExecutePlayModeAsync({})
end)
if not ok then
	print("PLAYTEST_ERROR " .. tostring(result))
else
	for line in string.gmatch(tostring(result), "[^\n]+") do
		print("PLAYTEST " .. line)
	end
end
print("PLAYTEST_END")
