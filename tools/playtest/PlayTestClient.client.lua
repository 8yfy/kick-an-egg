-- DEV ONLY (tools/playtest/playtest.sh): drives the local player through a real Play session and reports each
-- check to PlayTestServer, which ends the test with the results. Never part of the game build.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local report = ReplicatedStorage:WaitForChild("KTE_PlayTestReport", 60)

local function send(kind, text)
	report:FireServer(kind, text)
end
local function check(name, ok, detail)
	send(if ok then "PASS" else "FAIL", name .. (if detail ~= nil then " (" .. tostring(detail) .. ")" else ""))
end
local function note(text)
	send("NOTE", text)
end
local function waitFor(fn, timeout)
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		local ok, v = pcall(fn)
		if ok and v then
			return v
		end
		task.wait(0.05)
	end
	return nil
end
local function step(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		send("FAIL", name .. " crashed: " .. tostring(err))
	end
end

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local gui = player:WaitForChild("PlayerGui")
local hud = gui:WaitForChild("HUD", 60)
local map = workspace:WaitForChild("Map", 60)
task.wait(4) -- data load, base assignment, HUD settle
local kickPanel = hud:FindFirstChild("KickPanel", true)
local pad = map:WaitForChild("KickPad")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local kickPressed = ReplicatedStorage.Shared:WaitForChild("KickPressed")
local results, ended = {}, {}
Remotes.get("KickResult").OnClientEvent:Connect(function(r)
	table.insert(results, r)
end)
Remotes.get("ChaseEnded").OnClientEvent:Connect(function(p)
	table.insert(ended, p)
end)

local function tp(pos)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(pos)
end
local onPad = pad.Position + Vector3.new(0, 4, 0)

step("hud", function()
	local left = hud:FindFirstChild("LeftRail", true)
	check(
		"HUD: SHOP / INDEX / REBIRTH on the left",
		left and left:FindFirstChild("Shop") and left:FindFirstChild("Index") and left:FindFirstChild("Rebirth")
	)
	check("HUD: no TRAINING button", left and not left:FindFirstChild("Training"))
	check("HUD: no SACK / Tool slot", not hud:FindFirstChild("Sack", true))
	check("HUD: Roblox hotbar hidden", not StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
	local keys = {}
	for _, d in hud:GetDescendants() do
		if d:IsA("ImageLabel") and typeof(d:GetAttribute("ArtKey")) == "string" then
			keys[d:GetAttribute("ArtKey")] = true
		end
	end
	local missing = {}
	for _, k in { "hud_shop", "hud_index", "hud_rebirth", "hud_eggs", "hud_pets", "hud_settings", "hud_sound", "hud_money", "hud_power" } do
		if not keys[k] then
			table.insert(missing, k)
		end
	end
	check("HUD: all 9 approved icons on screen", #missing == 0, if #missing > 0 then table.concat(missing, ",") else nil)
	check("KICK hidden away from the pad (at spawn)", kickPanel and not kickPanel.Visible)
end)

step("pad", function()
	tp(onPad)
	check("KICK + AUTO KICK appear on the pad", waitFor(function()
		return kickPanel.Visible and kickPanel.Kick.Visible and kickPanel.AutoKick.Visible
	end, 3) ~= nil)
	check("strength meter hidden until KICK is pressed", not kickPanel.Meter.Visible)
	local zp = hud:FindFirstChild("ZoneProgress", true)
	task.wait(0.5)
	check("no zone bar while standing on the pad (base)", zp and not zp.Visible)
	tp(onPad + Vector3.new(0, 0, -40))
	check("KICK hides after leaving the pad", waitFor(function()
		return not kickPanel.Visible
	end, 3) ~= nil)
	task.wait(1)
	kickPressed:Fire(0.95)
	task.wait(3)
	check("server rejects a kick sent from off the pad", #results == 0)
end)

local result
step("kick", function()
	tp(onPad)
	task.wait(1.2)
	kickPressed:Fire(0.95)
	result = waitFor(function()
		return results[1]
	end, 5)
	check(
		"perfect kick from the pad is accepted",
		result ~= nil,
		result and string.format("%.0f studs, lands in zone %d", result.distance, result.landZone)
	)
	check("KICK hides during the flight", waitFor(function()
		return not kickPanel.Visible
	end, 2) ~= nil)
end)

step("zones", function()
	if not result then
		return
	end
	local zp = hud:FindFirstChild("ZoneProgress", true)
	local label = zp.ZoneName.Art
	local pct = zp.Bar.Percent
	local seen, lowAtChange, lastKey = {}, 0, nil
	local stop = result.launchTime + result.flightSeconds + 0.4
	while workspace:GetServerTimeNow() < stop do
		if zp.Visible then
			local key = label:GetAttribute("ArtKey")
			if key ~= lastKey then
				lastKey = key
				table.insert(seen, key)
				local p = tonumber(string.match(pct.Text, "%d+")) or 100
				if p <= 35 then
					lowAtChange += 1
				end
			end
		end
		task.wait()
	end
	local ordered = true
	for i = 2, #seen do
		if (tonumber(string.match(seen[i], "%d+")) or 0) <= (tonumber(string.match(seen[i - 1], "%d+")) or 0) then
			ordered = false
		end
	end
	check("zone bar names every zone of the flight, in order", #seen >= 3 and ordered, table.concat(seen, " > "))
	check("zone bar restarts near 0% at each new zone", lowAtChange == #seen, `{lowAtChange}/{#seen}`)
	check(
		"zone bar ends on the landing zone",
		lastKey == string.format("zone_label_%02d", result.landZone),
		lastKey
	)
end)

step("chase", function()
	if not result then
		return
	end
	note("waiting for the chase to end (nobody steers, so the avalanche takes the egg)")
	local e = waitFor(function()
		return ended[1]
	end, 150)
	check("chase ended", e ~= nil)
	tp(onPad)
	check("KICK returns on the pad after the chase", waitFor(function()
		return kickPanel.Visible
	end, 6) ~= nil)
end)

step("shop", function()
	local shop = map:FindFirstChild("BoxingSackShop", true)
	check("Boxing Sack Shop is in the world", shop ~= nil)
	local counter = shop and shop:FindFirstChild("Counter")
	local prompt = counter and counter:FindFirstChildOfClass("ProximityPrompt")
	check("shop counter has its prompt", prompt ~= nil, prompt and prompt.ActionText .. " / " .. prompt.ObjectText)
	if not prompt then
		return
	end
	tp(counter.Position + Vector3.new(0, 1, 5))
	task.wait(1.5)
	local Modal = require(player.PlayerScripts.Client.UI.System.Modal)
	prompt:InputHoldBegin()
	task.wait(0.15)
	prompt:InputHoldEnd()
	check("pressing the shop prompt opens the existing sack screen", waitFor(function()
		return Modal.current() == "Training"
	end, 4) ~= nil, Modal.current())
	task.wait(1.5)
	Modal.close()
	check("closing it returns to the world", waitFor(function()
		return Modal.current() == nil
	end, 3) ~= nil)
end)

step("train", function()
	local bases = map:FindFirstChild("SafeZone") and map.SafeZone:FindFirstChild("Bases")
	local mine
	for _, b in if bases then bases:GetChildren() else {} do
		if b:GetAttribute("OwnerUserId") == player.UserId then
			mine = b
		end
	end
	check("you own a base", mine ~= nil)
	local stand = mine and mine:FindFirstChild("SackStand")
	local plinth = stand and stand:FindFirstChild("Plinth")
	local prompt = plinth and plinth:FindFirstChildOfClass("ProximityPrompt")
	check("your sack stand has the Train prompt", prompt ~= nil and prompt:GetAttribute("Action") == "EquipSack")
	if not prompt then
		return
	end
	tp(plinth.Position + Vector3.new(0, 3, 0) + (plinth.CFrame.LookVector * 4))
	task.wait(1.5)
	local function holding()
		local t = char:FindFirstChildOfClass("Tool")
		return t ~= nil and t:GetAttribute("KickSack") == true
	end
	prompt:InputHoldBegin()
	task.wait(0.15)
	prompt:InputHoldEnd()
	check("Train takes the Kick Sack out", waitFor(holding, 3) ~= nil)
	task.wait(1)
	prompt:InputHoldBegin()
	task.wait(0.15)
	prompt:InputHoldEnd()
	check("Train again puts it away", waitFor(function()
		return not holding()
	end, 3) ~= nil)
end)

step("sack vfx lod", function()
	local SackLod = require(ReplicatedStorage.Shared.VFX.SackLod)
	local function levels()
		local l = SackLod.levels()
		return l, string.format(
			"Full %d, Reduced %d, Minimal %d, Disabled %d, off screen %d",
			l.Full,
			l.Reduced,
			l.Minimal,
			l.Disabled,
			l.OffScreen
		)
	end
	local shop = map:FindFirstChild("BoxingSackShop", true)
	local counter = shop and shop:FindFirstChild("Counter")
	if counter then
		tp(counter.Position + Vector3.new(0, 1, 5))
		task.wait(4) -- effects are built nearest first, one per 0.25 s
		local l, text = levels()
		note("sack effects at the shop counter: " .. text)
		check("sack vfx: the shop's sacks run at Full up close", l.Full >= 1, text)
	end
	tp(Vector3.new(0, 60, 900)) -- far out in the zones: every map sack is > 180 studs away
	task.wait(1.5)
	local l, text = levels()
	note("sack effects far away: " .. text)
	check("sack vfx: far away every sack effect is Disabled", l.Full + l.Reduced + l.Minimal == 0, text)
	tp(onPad)
	task.wait(1.5)
	local _, back = levels()
	note("sack effects back on the kick pad: " .. back)
	player:SetAttribute("SackVfxQuality", "LOW")
	check("sack vfx: the Settings override picks the profile", SackLod.profile().name == "LOW")
	player:SetAttribute("SackVfxQuality", nil)
	note("sack vfx profile (AUTO): " .. SackLod.profile().name)
end)

send("DONE", "")
