-- DEV ONLY (tools/playtest/playtest.sh): drives the local player through a real Play session and reports each
-- check to PlayTestServer, which ends the test with the results. Never part of the game build.
-- The whole loop: HUD, pad + mystery egg, kick cutscene, zone bar, steering the egg home (secure, inventory,
-- hidden character, camera back), holding + placing the egg, hatching (PlayTestServer hurries it), the pet
-- roaming, pick up / place, income, the tutorial steps, the 6 pens + owner card, the shop, the Kick Sack
-- quickslot, the Shift Lock camera probe and the sack VFX LOD.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local report = ReplicatedStorage:WaitForChild("KTE_PlayTestReport", 60)
local hook = ReplicatedStorage:WaitForChild("KTE_PlayTestHook", 60)

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

-- the tutorial step, recorded from the very start
local tutorialSteps = {}
local function recordStep()
	local s = player:GetAttribute("TutorialStep")
	if typeof(s) == "number" and tutorialSteps[#tutorialSteps] ~= s then
		table.insert(tutorialSteps, s)
	end
end
player:GetAttributeChangedSignal("TutorialStep"):Connect(recordStep)
recordStep()

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")
local gui = player:WaitForChild("PlayerGui")
local hud = gui:WaitForChild("HUD", 60)
local map = workspace:WaitForChild("Map", 60)
task.wait(4) -- data load, base assignment, HUD settle
local kickPanel = hud:FindFirstChild("KickPanel", true)
local pad = map:WaitForChild("KickPad")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Chase = require(Shared.Config.Chase)
local UI = player.PlayerScripts.Client.UI
local Data = require(UI.System.Data)
local Modal = require(UI.System.Modal)
local SackGear = require(UI.SackGear)
local kickPressed = Shared:WaitForChild("KickPressed")
local results, ended, secured = {}, {}, {}
Remotes.get("KickResult").OnClientEvent:Connect(function(r)
	table.insert(results, r)
end)
Remotes.get("ChaseEnded").OnClientEvent:Connect(function(p)
	table.insert(ended, { payload = p, at = os.clock() })
end)
Remotes.get("EggSecured").OnClientEvent:Connect(function(p)
	table.insert(secured, { payload = p, at = os.clock() })
end)

local function tp(pos)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = CFrame.new(pos)
end
local onPad = pad.Position + Vector3.new(0, 4, 0)

local function myBase()
	local bases = map:FindFirstChild("SafeZone") and map.SafeZone:FindFirstChild("Bases")
	for _, b in if bases then bases:GetChildren() else {} do
		if b:GetAttribute("OwnerUserId") == player.UserId then
			return b, bases
		end
	end
	return nil, bases
end

local function yaw(cf)
	local look = cf.LookVector
	return math.deg(math.atan2(-look.X, -look.Z))
end
local function angleDiff(a, b)
	return math.abs((a - b + 180) % 360 - 180)
end

step("hud", function()
	local left = hud:FindFirstChild("LeftRail", true)
	check(
		"HUD: SHOP / INDEX / REBIRTH on the left",
		left and left:FindFirstChild("Shop") and left:FindFirstChild("Index") and left:FindFirstChild("Rebirth")
	)
	local trade, rebirth = left and left:FindFirstChild("Trade"), left and left:FindFirstChild("Rebirth")
	check("HUD: TRADE right under REBIRTH", trade and rebirth and trade.LayoutOrder == rebirth.LayoutOrder + 1)
	check("HUD: no TRAINING button", left and not left:FindFirstChild("Training"))
	local slot = hud:FindFirstChild("SackSlot", true)
	check("HUD: the bottom Kick Sack quickslot is there", slot and slot:FindFirstChild("Tile") and slot.Visible)
	check("HUD: Roblox hotbar hidden", not StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
	local keys = {}
	for _, d in hud:GetDescendants() do
		if d:IsA("ImageLabel") and typeof(d:GetAttribute("ArtKey")) == "string" then
			keys[d:GetAttribute("ArtKey")] = true
		end
	end
	local missing = {}
	for _, k in
		{
			"hud_shop",
			"hud_index",
			"hud_rebirth",
			"hud_eggs",
			"hud_pets",
			"hud_settings",
			"hud_sound",
			"hud_money",
			"hud_power",
		}
	do
		if not keys[k] then
			table.insert(missing, k)
		end
	end
	check(
		"HUD: all 9 approved icons on screen",
		#missing == 0,
		if #missing > 0 then table.concat(missing, ",") else nil
	)
	check("KICK hidden away from the pad (at spawn)", kickPanel and not kickPanel.Visible)
	local meter = kickPanel and kickPanel:FindFirstChild("Meter")
	check(
		"kick meter: one bar with a colour fill, no separate indicator",
		meter and meter:FindFirstChild("Fill", true) and not meter:FindFirstChild("Indicator", true)
	)
end)

step("pens", function()
	local mine, bases = myBase()
	local n, stands, cards = 0, 0, 0
	for _, b in if bases then bases:GetChildren() else {} do
		if b:FindFirstChild("PenArea") then
			n += 1
		end
		if b:FindFirstChild("SackStand", true) then
			stands += 1
		end
	end
	check("6 pens on the map", n == 6, n)
	check("no old sack stands", stands == 0 and not map:FindFirstChild("SackStand", true), stands)
	check("you own a pen", mine ~= nil)
	local anchor = mine and mine:FindFirstChild("OwnerAnchor", true)
	local card = anchor and waitFor(function()
		return anchor:FindFirstChild("PenOwner")
	end, 5)
	local texts = {}
	for _, d in if card then card:GetDescendants() else {} do
		if d:IsA("TextLabel") then
			table.insert(texts, d.Text)
		end
		if d:IsA("ImageLabel") and string.find(d.Image, "AvatarHeadShot") then
			cards += 1
		end
	end
	local all = table.concat(texts, " | ")
	check("your pen shows your owner card (@username)", string.find(all, "@" .. player.Name, 1, true) ~= nil, all)
	check("the owner card uses your avatar headshot", cards >= 1)
end)

step("pad", function()
	recordStep()
	tp(onPad)
	check("KICK + AUTO KICK appear on the pad", waitFor(function()
		return kickPanel.Visible and kickPanel.Kick.Visible and kickPanel.AutoKick.Visible
	end, 3) ~= nil)
	check("strength meter hidden until KICK is pressed", not kickPanel.Meter.Visible)
	check("you hold the black ? mystery egg on the kick line", waitFor(function()
		return char:FindFirstChild("MysteryEgg")
	end, 2) ~= nil)
	check("tutorial: on the pad it asks for KICK (step 2)", waitFor(function()
		return player:GetAttribute("TutorialStep") == 2 or player:GetAttribute("TutorialStep") == 0
	end, 3) ~= nil, player:GetAttribute("TutorialStep"))
	local zp = hud:FindFirstChild("ZoneProgress", true)
	task.wait(0.5)
	check("no zone bar while standing on the pad (base)", zp and not zp.Visible)
	tp(onPad + Vector3.new(0, 0, -40))
	check("KICK hides after leaving the pad", waitFor(function()
		return not kickPanel.Visible
	end, 3) ~= nil)
	check("the mystery egg goes when you step off", waitFor(function()
		return not char:FindFirstChild("MysteryEgg")
	end, 2) ~= nil)
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
	check("the kick cutscene is stamped on your character (KickAt)", typeof(char:GetAttribute("KickAt")) == "number")
	check("KICK hides during the flight", waitFor(function()
		return not kickPanel.Visible
	end, 2) ~= nil)
	check("the mystery egg leaves your hands at the kick", waitFor(function()
		return not char:FindFirstChild("MysteryEgg")
	end, 2) ~= nil)
	if result then
		local landing = Vector3.new(0, 0, result.distance)
		note(string.format("landing z %.0f (track end %.0f)", landing.Z, Chase.trackEnd()))
		check("the egg lands before the end of the map", landing.Z <= Chase.trackEnd() - Chase.Landing.endMargin + 1)
	end
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
	check("zone bar ends on the landing zone", lastKey == string.format("zone_label_%02d", result.landZone), lastKey)
end)

-- Steering: the test holds the stick toward home (camera-relative, like a player) through the real ControlModule.
local securedUid
step("chase", function()
	if not result then
		return
	end
	local chases = workspace:WaitForChild("Chases", 10)
	local egg = chases and chases:WaitForChild(result.eggUid, 10)
	check("the chase egg exists at workspace.Chases[eggUid]", egg ~= nil)
	if not egg then
		return
	end
	local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
	local home = Vector3.new(0, 0, Chase.SafeLineZ - 14)
	controls.GetMoveVector = function()
		local hitbox = egg:FindFirstChild("Hitbox")
		if not hitbox or not egg.Parent then
			return Vector3.zero
		end
		local d = home - hitbox.Position
		d = Vector3.new(d.X, 0, d.Z)
		if d.Magnitude < 1 then
			return Vector3.zero
		end
		d = d.Unit
		local cf = workspace.CurrentCamera.CFrame
		local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
		local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
		return Vector3.new(d:Dot(right), 0, -d:Dot(look))
	end
	-- egg form: once the legs are out the kicker is hidden and the camera follows the egg
	local head = char:FindFirstChild("Head")
	local hidden = waitFor(function()
		return head and head.Transparency >= 0.99
	end, 30)
	check("egg form: your character is hidden while you steer", hidden ~= nil)
	check("egg form: the camera follows the egg", waitFor(function()
		local hitbox = egg:FindFirstChild("Hitbox")
		return hitbox and workspace.CurrentCamera.CameraSubject == hitbox
	end, 5) ~= nil)
	check("tutorial: watch your egg / steer it home (step 4)", waitFor(function()
		return player:GetAttribute("TutorialStep") == 4 or player:GetAttribute("TutorialStep") == 0
	end, 3) ~= nil, player:GetAttribute("TutorialStep"))
	local moved = 0
	local hitbox = egg:FindFirstChild("Hitbox")
	local z0 = hitbox and hitbox.Position.Z or 0
	task.wait(3)
	if hitbox and hitbox.Parent then
		moved = z0 - hitbox.Position.Z
	end
	check("steering moves the egg toward home", moved > 10, string.format("%.0f studs in 3 s", moved))
	local trace = {}
	local e = waitFor(function()
		local hb = egg:FindFirstChild("Hitbox")
		if hb and egg.Parent and (#trace == 0 or os.clock() - trace[#trace].at > 1) then
			table.insert(trace, { at = os.clock(), p = hb.Position, v = hb.AssemblyLinearVelocity })
		end
		return ended[1]
	end, 150)
	local path = {}
	for _, t in trace do
		table.insert(path, string.format("(%.0f,%.0f,%.0f v%.0f)", t.p.X, t.p.Y, t.p.Z, t.v.Magnitude))
	end
	note("egg path home: " .. table.concat(path, " "))
	controls.GetMoveVector = nil -- back to the real method
	check("chase ended", e ~= nil)
	local s = secured[1]
	check("you steered the egg home (EggSecured)", s ~= nil, if s then nil else "lost to the avalanche")
	if s and e then
		securedUid = s.payload.eggUid
		check("ChaseEnded follows EggSecured at once", e.at - s.at < 1, string.format("%.2f s", e.at - s.at))
		check("the secured egg model goes away promptly", waitFor(function()
			return not egg.Parent
		end, 2) ~= nil)
		local copies = waitFor(function()
			local n = 0
			for _, row in Data.state.eggs or {} do
				if row.uid == securedUid then
					n += 1
				end
			end
			return n > 0 and n
		end, 3)
		check("the egg is in your inventory exactly once", copies == 1, copies)
	end
	check("your character shows again after the chase", waitFor(function()
		return head and head.Transparency < 0.01
	end, 3) ~= nil)
	check("the camera is back on your character", waitFor(function()
		return workspace.CurrentCamera.CameraSubject == humanoid
	end, 4) ~= nil)
	tp(onPad)
	check("KICK returns on the pad after the chase", waitFor(function()
		return kickPanel.Visible
	end, 6) ~= nil)
end)

-- Egg -> pen -> pet.
local petUid
step("egg placement", function()
	if not securedUid then
		hook:FireServer("giveEgg") -- the chase was lost: an egg to keep testing with
		securedUid = waitFor(function()
			local eggs = Data.state.eggs
			return eggs and eggs[1] and eggs[1].uid
		end, 4)
		note("chase not secured: PlayTestServer gave an egg for the placement checks")
	end
	check("tutorial: put the egg in your pen (step 6)", waitFor(function()
		return player:GetAttribute("TutorialStep") == 6 or player:GetAttribute("TutorialStep") == 0
	end, 3) ~= nil, player:GetAttribute("TutorialStep"))
	local mine = myBase()
	local area = mine and mine:FindFirstChild("PenArea", true)
	if not securedUid or not area then
		check("an egg and a pen to place it in", false)
		return
	end
	tp(area.Position + Vector3.new(0, 4, 0))
	task.wait(1)
	Remotes.get("EquipEgg"):FireServer(securedUid)
	local tool = waitFor(function()
		local t = char:FindFirstChildOfClass("Tool")
		return t and t:GetAttribute("EggUid") == securedUid and t
	end, 3)
	check("HOLD gives you the egg as a Tool", tool ~= nil)
	check("holding the egg shows the placement ghost", waitFor(function()
		return workspace:FindFirstChild("EggGhost")
	end, 2) ~= nil)
	-- outside the pen: refused
	Remotes.get("PlaceEgg"):FireServer(securedUid, area.Position + area.CFrame.LookVector * 200)
	task.wait(1)
	check("placing outside your pen is refused", not (Data.state.plots or {})[securedUid])
	Remotes.get("PlaceEgg"):FireServer(securedUid, area.Position)
	check("placing in your pen works", waitFor(function()
		return (Data.state.plots or {})[securedUid]
	end, 3) ~= nil)
	check("the egg Tool is gone after placing", waitFor(function()
		return not char:FindFirstChildOfClass("Tool") and not workspace:FindFirstChild("EggGhost")
	end, 2) ~= nil)
	Remotes.get("PlaceEgg"):FireServer(securedUid, area.Position + Vector3.new(6, 0, 0))
	task.wait(1)
	local inInventory = 0
	for _, row in Data.state.eggs or {} do
		if row.uid == securedUid then
			inInventory += 1
		end
	end
	check("a repeated PlaceEgg doesn't duplicate the egg", inInventory == 0)
	local plots = mine:FindFirstChild("Plots")
	check("the egg model sits in your pen", waitFor(function()
		return plots and plots:FindFirstChild("Egg_" .. securedUid)
	end, 3) ~= nil)
	hook:FireServer("hatch")
	petUid = waitFor(function()
		for uid, pet in Data.state.pets or {} do
			if pet.placed then
				return uid
			end
		end
		return nil
	end, 6)
	check("the egg hatches into a pet in your pen", petUid ~= nil)
	check(
		"tutorial: wait for it to hatch / it earns (steps 7-8)",
		table.find(tutorialSteps, 6) ~= nil,
		table.concat(tutorialSteps, ",")
	)
end)

step("pets", function()
	if not petUid then
		return
	end
	local mine = myBase()
	local plots = mine and mine:FindFirstChild("Plots")
	local model = plots and waitFor(function()
		return plots:FindFirstChild("Pet_" .. petUid)
	end, 5)
	check("the pet model loads in your pen", model ~= nil and model.PrimaryPart ~= nil)
	if not model then
		return
	end
	tp(model:GetPivot().Position + Vector3.new(16, 4, 0)) -- inside the pen (52 wide), out of OWNER_NEAR
	task.wait(1.5) -- a pet idles while you stand next to it: step back first
	local p0 = model:GetPivot().Position
	local path0 = model:GetAttribute("PathEnd")
	local maxMove = 0
	waitFor(function()
		maxMove = math.max(maxMove, (model:GetPivot().Position - p0).Magnitude)
		return maxMove > 1.5
	end, 12)
	check(
		"the pet roams around the pen (Path attributes + it moves)",
		maxMove > 1.5 and path0 ~= nil,
		string.format("%.1f studs", maxMove)
	)
	local money0 = Data.state.money or 0
	local earned = waitFor(function()
		return (Data.state.money or 0) > money0
	end, 5)
	check("the placed pet earns money by itself (no collecting)", earned ~= nil)
	local prompt = model:FindFirstChild("PickUpPet", true)
	check("your pet has a Pick Up prompt", prompt ~= nil and prompt:IsA("ProximityPrompt"))
	tp(model:GetPivot().Position + Vector3.new(0, 4, 3))
	local shown = prompt
		and waitFor(function()
			return model:GetAttribute("PathStart") == model:GetAttribute("PathEnd") -- it stopped for you
		end, 2)
	check("your pet stops and idles while you stand next to it", shown ~= nil)
	task.wait(0.4)
	local function stored()
		local pet = (Data.state.pets or {})[petUid]
		return pet and not pet.placed and not plots:FindFirstChild("Pet_" .. petUid)
	end
	if prompt then
		prompt:InputHoldBegin()
		task.wait(math.max(prompt.HoldDuration, 0) + 0.15)
		prompt:InputHoldEnd()
		check("the Pick Up prompt stores the pet", waitFor(stored, 3) ~= nil)
	end
	if not stored() then
		Remotes.get("PickupPet"):FireServer(petUid)
	end
	check("picking it up stores it (model goes, STORED)", waitFor(stored, 4) ~= nil)
	local money1 = Data.state.money or 0
	task.wait(2.5)
	check("a stored pet earns nothing", (Data.state.money or 0) == money1)
	Remotes.get("PlacePet"):FireServer(petUid, nil)
	check("PLACE puts the stored pet back in your pen", waitFor(function()
		local pet = (Data.state.pets or {})[petUid]
		return pet and pet.placed and plots:FindFirstChild("Pet_" .. petUid)
	end, 4) ~= nil)
	check("tutorial: finished after the first upgrade (TutorialDone)", waitFor(function()
		return player:GetAttribute("TutorialDone") == true or player:GetAttribute("TutorialStep") == 0
	end, 4) ~= nil, table.concat(tutorialSteps, ","))
	note("tutorial steps seen: " .. table.concat(tutorialSteps, " > "))
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
	local merchants = 0
	for _, d in map:GetDescendants() do
		if d:IsA("Model") and d:GetAttribute("Merchant") and d:FindFirstChildOfClass("Humanoid") then
			merchants += 1
		end
	end
	check("merchants are Roblox avatars (Humanoid rigs)", merchants >= 1, merchants)
end)

local function holdingSack()
	local t = char:FindFirstChildOfClass("Tool")
	return t ~= nil and t:GetAttribute("KickSack") == true
end

step("quickslot", function()
	tp(onPad + Vector3.new(0, 0, -30))
	task.wait(1)
	local slot = hud:FindFirstChild("SackSlot", true)
	local glow = slot and slot:FindFirstChild("Glow", true)
	SackGear.toggle() -- the same call as clicking the tile / key 1 / gamepad Y
	check("the quickslot takes the Kick Sack out", waitFor(holdingSack, 3) ~= nil)
	check("the quickslot glows while the sack is out", waitFor(function()
		return glow and glow.Thickness > 0
	end, 2) ~= nil)
	SackGear.toggle()
	check("the quickslot puts it away again", waitFor(function()
		return not holdingSack()
	end, 3) ~= nil)
	check("the glow goes off when it's away", waitFor(function()
		return glow and glow.Thickness == 0
	end, 2) ~= nil)
end)

-- BUG 6: Shift Lock + the sack. The camera must stay on the Humanoid and not turn by itself. Scripts can't press
-- Shift or reach the PlayerModule's MouseLockController (RobloxScript only), so the probe does what Shift Lock does
-- to the character: UserGameSettings.RotationType = CameraRelative (the character turns with the camera).
step("shift lock", function()
	local gameSettings = UserSettings():GetService("UserGameSettings")
	local oldRotation = gameSettings.RotationType
	gameSettings.RotationType = Enum.RotationType.CameraRelative
	tp(onPad + Vector3.new(0, 0, -30))
	task.wait(1.5)
	local camera = workspace.CurrentCamera
	local yaw0 = yaw(camera.CFrame)
	local face0 = angleDiff(yaw(hrp.CFrame), yaw0)
	check("shift lock (emulated): your character faces the camera", face0 < 5, string.format("%.1f°", face0))
	SackGear.toggle()
	waitFor(holdingSack, 3)
	task.wait(1.5)
	check(
		"shift lock + sack out: the camera stays on your Humanoid",
		camera.CameraSubject == humanoid,
		tostring(camera.CameraSubject)
	)
	local d1 = angleDiff(yaw(camera.CFrame), yaw0)
	check("shift lock + sack out: no camera snap", d1 < 3, string.format("%.1f°", d1))
	local Shake = require(Shared.VFX.Shake)
	Shake.impulse("PlayTest", 1, 0.6) -- the kick / impact shake
	task.wait(1.2)
	local d2 = angleDiff(yaw(camera.CFrame), yaw0)
	check("shift lock: a camera shake leaves no drift", d2 < 1.5, string.format("%.2f°", d2))
	SackGear.toggle()
	task.wait(1)
	local d3 = angleDiff(yaw(camera.CFrame), yaw0)
	check(
		"shift lock + sack away: camera unchanged",
		camera.CameraSubject == humanoid and d3 < 3,
		string.format("%.1f°", d3)
	)
	gameSettings.RotationType = oldRotation
end)

step("sack vfx lod", function()
	local SackLod = require(Shared.VFX.SackLod)
	local function levels()
		local l = SackLod.levels()
		return l,
			string.format(
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
