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
local Audio = require(Shared:WaitForChild("Audio"))
local SoundBank = require(Shared.Audio.SoundBank)
Audio.measure = true -- record what every sound really does in the engine (the audio steps)
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

local function backpackTool(attribute, uid)
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, t in if backpack then backpack:GetChildren() else {} do
		local value = t:IsA("Tool") and t:GetAttribute(attribute)
		if value ~= nil and value ~= false and (uid == nil or value == uid) then
			return t
		end
	end
	return nil
end

-- A pet on screen vs a fresh build of the same design (+ its size mutation): overall size and how far its
-- farthest part sits from the Root. Scattered / floating parts make both grow.
local function petShape(model)
	local root = model.PrimaryPart
	local far = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and root then
			far = math.max(far, (d.Position - root.Position).Magnitude)
		end
	end
	local _, size = model:GetBoundingBox()
	return size, far
end
local function assembledLikeDesign(model)
	local Models = require(Shared.Builders.Models)
	local Mutations = require(Shared.Config.Mutations)
	local key = model:GetAttribute("ModelKey")
	local fresh = Models.pet(key)
	local m = model:GetAttribute("Size") and Mutations.Size[model:GetAttribute("Size")]
	if m then
		fresh:ScaleTo(m.scale)
	end
	fresh:PivotTo(CFrame.new(0, -400, 0))
	fresh.Parent = workspace
	task.wait()
	local wantSize, wantFar = petShape(fresh)
	fresh:Destroy()
	local size, far = petShape(model)
	local tol = 0.9 * (m and m.scale or 1) -- walk / idle sway
	local ok = far <= wantFar + tol and (size - wantSize).Magnitude <= tol * 2
	return ok,
		string.format(
			"%s: farthest part %.2f (design %.2f), size %.1f/%.1f/%.1f (design %.1f/%.1f/%.1f)",
			tostring(key),
			far,
			wantFar,
			size.X,
			size.Y,
			size.Z,
			wantSize.X,
			wantSize.Y,
			wantSize.Z
		)
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
	check("HUD: Roblox's Backpack hotbar is on (eggs + pets)", StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
	check("the Kick Sack is not in the Backpack (it has its own quickslot)", backpackTool("KickSack") == nil)
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
	local n, stands = 0, 0
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
	-- owner display: only the avatar headshot + the username, high above an occupied pen; nothing on free pens
	local area = mine and mine:FindFirstChild("PenArea")
	local display = area
		and waitFor(function()
			local g = area:FindFirstChild("PenOwner")
			return g and g.Enabled and g
		end, 6)
	local texts, images, extras = {}, 0, 0
	for _, d in if display then display:GetDescendants() else {} do
		if d:IsA("TextLabel") then
			table.insert(texts, d.Text)
		elseif d:IsA("ImageLabel") then
			images += if string.find(d.Image, "AvatarHeadShot") then 1 else 0
		elseif d:IsA("Frame") or d:IsA("ImageButton") or d:IsA("TextButton") then
			extras += 1
		end
	end
	check("pen owner: your username over your pen", #texts == 1 and texts[1] == player.Name, table.concat(texts, " | "))
	check(
		"pen owner: your avatar headshot, nothing else (no panel / banner)",
		images == 1 and extras == 0,
		`{images} images, {extras} panels`
	)
	check("pen owner: high above the pen", display ~= nil and display.StudsOffsetWorldSpace.Y >= 15)
	local freeShown, freeText = 0, false
	for _, b in if bases then bases:GetChildren() else {} do
		local g = b:FindFirstChild("PenOwner", true)
		if g and b ~= mine and g.Enabled then
			freeShown += 1
		end
		for _, d in if g then g:GetDescendants() else {} do
			if d:IsA("TextLabel") and string.find(string.upper(d.Text), "FREE") then
				freeText = true
			end
		end
	end
	check("pen owner: free pens show nothing (no FREE PEN)", freeShown == 0 and not freeText, freeShown)
	local oldCard = mine and mine:FindFirstChild("OwnerAnchor", true)
	check("pen owner: the old big card is gone", not (oldCard and oldCard:FindFirstChild("PenOwner")))
end)

step("tutorial guidance (in the world, small)", function()
	if player:GetAttribute("TutorialStep") ~= 1 then
		note("tutorial not on step 1 here: " .. tostring(player:GetAttribute("TutorialStep")))
		return
	end
	task.wait(0.5)
	local tut = gui:FindFirstChild("Tutorial")
	local chip = tut and tut:FindFirstChild("Banner")
	check(
		"tutorial: one short prompt, no big banner",
		chip and chip.Visible and #chip.Text <= 28 and chip.AbsoluteSize.Y <= 40,
		chip and chip.Text
	)
	local hl = tut and tut:FindFirstChild("TutorialHighlight")
	check("tutorial: the kick pad itself is highlighted", hl and hl.Enabled and hl.Adornee == pad)
	local dots = 0
	local folder = workspace:FindFirstChild("TutorialTrail")
	for _, d in if folder then folder:GetChildren() else {} do
		dots += if d.Transparency < 1 then 1 else 0
	end
	check("tutorial: a ground trail leads to the kick line", dots >= 6, dots)
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
	-- A: the full-size mystery egg held between the hands with the hold animation
	local held = waitFor(function()
		return char:FindFirstChild("MysteryEgg")
	end, 3)
	if held then
		local _, size = held:GetBoundingBox()
		local rh, lh = char:FindFirstChild("RightHand"), char:FindFirstChild("LeftHand")
		local centre = held:GetBoundingBox().Position
		local gap = if rh and lh
			then math.max((rh.Position - centre).Magnitude, (lh.Position - centre).Magnitude)
			else 99
		check("the mystery egg is full size", size.Y >= 3.2, string.format("%.1f studs tall", size.Y))
		check(
			"it is held between the hands (not at the waist)",
			gap < 2.2,
			string.format("hands %.2f studs from its centre", gap)
		)
		local shoulder = char:FindFirstChild("RightUpperArm") and char.RightUpperArm:FindFirstChild("RightShoulder")
		local pitch = shoulder and math.deg(select(1, (shoulder :: any).Transform:ToEulerAnglesXYZ())) or 0
		check("the hold animation poses the arms forward", pitch > 45, string.format("shoulder %.0f°", pitch))
	end
	kickPressed:Fire(0.95)
	-- D / E: the kick clip on the rig at contact, your camera on the cinematic shots, the flying egg hidden
	task.spawn(function()
		local at = waitFor(function()
			local v = char:GetAttribute("KickAt")
			return typeof(v) == "number" and v
		end, 4)
		if not at then
			return
		end
		local cam = workspace.CurrentCamera
		local sawScriptable, camAway = false, 0
		while workspace:GetServerTimeNow() < at - 0.1 do
			sawScriptable = sawScriptable or cam.CameraType == Enum.CameraType.Scriptable
			camAway = math.max(camAway, (cam.CFrame.Position - hrp.Position).Magnitude)
			task.wait()
		end
		local hip = char:FindFirstChild("RightUpperLeg") and char.RightUpperLeg:FindFirstChild("RightHip")
		local peak = -999
		while workspace:GetServerTimeNow() < at + 0.12 do
			if hip then
				peak = math.max(peak, math.deg(select(1, (hip :: any).Transform:ToEulerAnglesXYZ())))
			end
			task.wait()
		end
		check(
			"the kick animation swings the leg through the egg at contact",
			peak > 70,
			string.format("hip %.0f°", peak)
		)
		check(
			"your camera plays the cinematic (scripted shots before launch)",
			sawScriptable,
			string.format("up to %.1f studs away", camAway)
		)
		local tut = gui:FindFirstChild("Tutorial")
		local tchip = tut and tut:FindFirstChild("Banner")
		check(
			"tutorial prompts stay out of the kick cinematic",
			not (tchip and tchip.Visible and tchip.Text ~= "" and tchip.Text ~= "TUTORIAL COMPLETE!")
		)
		local flying = workspace:FindFirstChild("ClientEggs") and workspace.ClientEggs:FindFirstChildWhichIsA("Model")
		note("flying egg after launch: " .. tostring(flying and math.floor(flying:GetPivot().Position.Y)))
	end)
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
		local eggTool = waitFor(function()
			return backpackTool("EggUid", securedUid)
		end, 3)
		check("the secured egg is a Tool in your Backpack (hotbar)", eggTool ~= nil, eggTool and eggTool.Name)
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
	task.wait(0.8) -- (the reveal pop)
	local shown, hiddenParts = 0, 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			if d.LocalTransparencyModifier > 0.5 then
				hiddenParts += 1
			else
				shown += 1
			end
		end
	end
	check(
		"the freshly hatched pet is VISIBLE right away (no pickup + place needed)",
		shown > 0 and hiddenParts == 0,
		`{shown} visible parts, {hiddenParts} hidden`
	)
	task.wait(1.5) -- after the reveal, walking / idling
	local okH, whyH = assembledLikeDesign(model)
	check("the hatched pet is in one piece, exactly its design (nothing floating)", okH, whyH)
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
	local petTool = waitFor(function()
		return backpackTool("PetUid", petUid)
	end, 3)
	check("the stored pet is a Tool in your Backpack (hotbar)", petTool ~= nil, petTool and petTool.Name)
	local money1 = Data.state.money or 0
	task.wait(2.5)
	check("a stored pet earns nothing", (Data.state.money or 0) == money1)
	-- choose the spot: a spot without holding the pet is refused; holding its tool it goes exactly there
	local area = mine:FindFirstChild("PenArea", true)
	local spot = area.Position + area.CFrame.RightVector * 6 + area.CFrame.LookVector * -6
	Remotes.get("PlacePet"):FireServer(petUid, spot)
	task.wait(1)
	check("a chosen spot needs the pet in your hand", not ((Data.state.pets or {})[petUid] or {}).placed)
	if petTool then
		humanoid:EquipTool(petTool)
	end
	check("holding the pet shows its placement ghost", waitFor(function()
		return workspace:FindFirstChild("PetGhost")
	end, 3) ~= nil)
	Remotes.get("PlacePet"):FireServer(petUid, spot)
	check("holding the pet, it is placed where you chose", waitFor(function()
		local pet = (Data.state.pets or {})[petUid]
		local model = plots:FindFirstChild("Pet_" .. petUid)
		return pet and pet.placed and model and (model:GetPivot().Position - spot).Magnitude < 8
	end, 4) ~= nil)
	task.wait(1.5)
	local placedModel = plots:FindFirstChild("Pet_" .. petUid)
	if placedModel then
		local okP, whyP = assembledLikeDesign(placedModel)
		check("after pick up + place it looks the same: one piece, its design", okP, whyP)
	end
	check("its Backpack tool goes once it is placed", waitFor(function()
		return backpackTool("PetUid", petUid) == nil and not char:FindFirstChildOfClass("Tool")
	end, 3) ~= nil)
	check("tutorial: finished after the first upgrade (TutorialDone)", waitFor(function()
		return player:GetAttribute("TutorialDone") == true or player:GetAttribute("TutorialStep") == 0
	end, 4) ~= nil, table.concat(tutorialSteps, ","))
	note("tutorial steps seen: " .. table.concat(tutorialSteps, " > "))
end)

-- SOUND DESIGN, live. Audio.measure records what each sound really did in the engine (loaded, the summed
-- PlaybackLoudness of its layers, seconds audible). The 10 required scenarios + the loop's sounds.
local function audioEntries(from: number, prefix: string)
	local list = {}
	for i = from + 1, #Audio.history do
		local e = Audio.history[i]
		if string.sub(e.event, 1, #prefix) == prefix then
			table.insert(list, e)
		end
	end
	return list
end
local function describe(e)
	return if e
		then string.format(
			"%s tier %d, loudness %.0f, audible %.2f s, %s",
			e.event,
			e.tier,
			e.loudness,
			e.audible,
			table.concat(e.layers, "+")
		)
		else "nothing played"
end
local function groundAt(x: number, z: number): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local hit = workspace:Raycast(Vector3.new(x, 120, z), Vector3.new(0, -260, 0), params)
	return hit and hit.Position
end
-- A real physics drop: an egg-sized ball, its contacts detected like the steered egg's (velocity, never Touched).
local function drop(x: number, z: number, height: number, elasticity: number, seconds: number)
	local ground = groundAt(x, z)
	if not ground then
		return {}
	end
	tp(ground + Vector3.new(7, 4, 7))
	task.wait(0.8)
	local ball = Instance.new("Part")
	ball.Name = "AudioTestEgg"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2.4, 2.4, 2.4)
	ball.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, elasticity, 1, 100)
	ball.Position = ground + Vector3.new(0, 1.2 + height, 0)
	ball.Parent = workspace
	local from = #Audio.history
	local st = SoundBank.newContact()
	local last = os.clock()
	local conn = game:GetService("RunService").Heartbeat:Connect(function()
		local t = os.clock()
		local kind, speed = SoundBank.contactStep(st, t - last, ball.AssemblyLinearVelocity.Y, t)
		last = t
		if kind then
			Audio.landing(ball, speed, kind == "bounce", nil, { key = "drop" })
		end
	end)
	task.wait(seconds)
	conn:Disconnect()
	ball:Destroy()
	task.wait(0.4)
	return audioEntries(from, "Egg")
end

step("audio: scenarios 1-3, egg drops (real physics)", function()
	local gentle = drop(16, -24, 1, 0, 2.5) -- plaza = grass
	check(
		"scenario 1: a gentle drop on grass = one soft thump",
		#gentle == 1 and gentle[1].event == "EggLand_grass" and gentle[1].tier == 1 and gentle[1].loaded,
		describe(gentle[1])
	)
	local stone = drop(0, 850, 5, 0.05, 2.5) -- Volcano = stone
	check(
		"scenario 2: a drop on stone = a short solid contact",
		#stone >= 1 and #stone <= 3 and string.find(stone[1].event, "_stone") ~= nil and stone[1].audible < 0.6,
		describe(stone[1])
	)
	local bouncy = drop(16, -24, 9, 0.75, 4)
	local bounces, spaced = 0, true
	for i, e in bouncy do
		bounces += if string.find(e.event, "Bounce") then 1 else 0
		if i > 1 and e.t - bouncy[i - 1].t < SoundBank.Landing.cooldown - 0.01 then
			spaced = false
		end
	end
	check(
		"scenario 3: a bouncing egg = several short pops, never stacked",
		bounces >= 2 and #bouncy <= 10 and spaced,
		`{bounces} bounces, {#bouncy} sounds`
	)
	local bounceOnly = {}
	for _, e in bouncy do
		if string.find(e.event, "Bounce") then
			table.insert(bounceOnly, e)
		end
	end
	local settle = bouncy[#bouncy]
	check(
		"scenario 3: each bounce is softer than the first, and the final settle too",
		#bounceOnly >= 2
			and bounceOnly[1].loudness > bounceOnly[#bounceOnly].loudness
			and settle.loudness <= bounceOnly[1].loudness,
		#bounceOnly >= 2
				and string.format(
					"first bounce %.0f, last bounce %.0f, final %s %.0f",
					bounceOnly[1].loudness,
					bounceOnly[#bounceOnly].loudness,
					settle.event,
					settle.loudness
				)
			or nil
	)
	local all = {}
	for _, e in gentle do
		table.insert(all, describe(e))
	end
	for _, e in stone do
		table.insert(all, describe(e))
	end
	note("drops: " .. table.concat(all, " | "))
end)

step("audio: scenarios 9-10, hatching a Common and a Secret pet", function()
	local mine = myBase()
	local area = mine and mine:FindFirstChild("PenArea", true)
	if not area then
		check("a pen to hatch in", false)
		return
	end
	local measured = {}
	for i, rarity in { "Common", "Secret" } do
		local before = {}
		for _, row in Data.state.eggs or {} do
			before[row.uid] = true
		end
		hook:FireServer("giveEgg", rarity)
		local uid = waitFor(function()
			for _, row in Data.state.eggs or {} do
				if not before[row.uid] then
					return row.uid
				end
			end
			return nil
		end, 4)
		if not uid then
			check(`a {rarity} egg to hatch`, false)
			continue
		end
		local spot = area.Position + area.CFrame.RightVector * (i == 1 and 9 or -9) + area.CFrame.LookVector * 6
		tp(spot + Vector3.new(0, 4, 0))
		task.wait(0.6)
		Remotes.get("EquipEgg"):FireServer(uid)
		waitFor(function()
			local t = char:FindFirstChildOfClass("Tool")
			return t and t:GetAttribute("EggUid") == uid
		end, 3)
		Remotes.get("PlaceEgg"):FireServer(uid, spot)
		local placed = waitFor(function()
			return (Data.state.plots or {})[uid]
		end, 3)
		local heldTool = char:FindFirstChildOfClass("Tool")
		note(`{rarity} egg: placed {placed ~= nil}, holding {heldTool and heldTool.Name or "nothing"}`)
		local from = #Audio.history
		hook:FireServer("hatch")
		local name = SoundBank.hatchEvent(rarity)
		local e = waitFor(function()
			local list = audioEntries(from, name)
			return list[1]
		end, 6)
		task.wait(2)
		measured[rarity] = e
		-- this pen now holds several pets: each hatched one in one piece
		task.wait(1.2)
		local mine2 = myBase()
		local plots2 = mine2 and mine2:FindFirstChild("Plots")
		local newest, best = nil, -1
		for _, mdl in if plots2 then plots2:GetChildren() else {} do
			local h = mdl:GetAttribute("HatchedAt")
			if mdl:GetAttribute("Kind") == "Pet" and typeof(h) == "number" and h > best then
				newest, best = mdl, h
			end
		end
		if newest then
			local okR, whyR = assembledLikeDesign(newest)
			check(`a hatched {rarity} pet (with other pets in the pen) is in one piece`, okR, whyR)
		end
		check(
			`scenario {if rarity == "Common" then 9 else 10}: a {rarity} hatch = {name}`,
			e ~= nil and e.loaded,
			describe(e)
		)
	end
	local c, s = measured.Common, measured.Secret
	check(
		"a Secret hatch is bigger than a Common one (louder and longer, in the engine)",
		c ~= nil and s ~= nil and s.loudness > c.loudness and s.audible > c.audible,
		c
				and s
				and string.format(
					"Common %.0f / %.2f s, Secret %.0f / %.2f s",
					c.loudness,
					c.audible,
					s.loudness,
					s.audible
				)
			or nil
	)
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
	check("the sack never lands in the Backpack hotbar", waitFor(function()
		return backpackTool("KickSack") == nil
	end, 2) ~= nil)
	check("the quickslot puts it away again", waitFor(function()
		return not holdingSack()
	end, 3) ~= nil)
	check("the glow goes off when it's away", waitFor(function()
		return glow and glow.Thickness == 0
	end, 2) ~= nil)
end)

-- Phase 2, live: Run Speed past level 120 (no cap, every level counts), trillion-scale whole-number Power on the
-- HUD, and a real sack kick adding exactly its whole-number gain.
step("speed + power (live)", function()
	local Economy = require(Shared.Config.Economy)
	local moneyLog = {} -- every money value the server sends, in order (income ticks arrive in between)
	local logConn = Remotes.get("DataChanged").OnClientEvent:Connect(function(partial)
		if typeof(partial.money) == "number" then
			table.insert(moneyLog, { money = partial.money, level = partial.speedLevel })
		end
	end)
	local function buyAt(level)
		hook:FireServer("set", { speedLevel = level, money = 1e15 })
		waitFor(function()
			return Data.state.speedLevel == level
		end, 3)
		task.wait(0.3)
		table.clear(moneyLog)
		Remotes.get("BuyUpgrade"):FireServer("RunSpeed")
		local ok = waitFor(function()
			return Data.state.speedLevel == level + 1
		end, 4)
		task.wait(0.3)
		local paid = nil
		for i, entry in moneyLog do
			if entry.level == level + 1 then -- the purchase's own update: money right before it - money in it
				local before = if i > 1 then moneyLog[i - 1].money else 1e15
				paid = before - entry.money
			end
		end
		return ok ~= nil, paid, humanoid.WalkSpeed
	end
	local ok121, paid121, walk121 = buyAt(121)
	check(
		"Run Speed: buying past level 121 works (no cap at 120)",
		ok121 and paid121 == Economy.speedCost(121) and math.abs(walk121 - Economy.runSpeedAt(122)) < 0.01,
		string.format("paid %s, walk speed %.3f", tostring(paid121), walk121)
	)
	local ok10k, paid10k, walk10k = buyAt(10000)
	check(
		"Run Speed: level 10,001 bought, still faster than 10,000, price finite",
		ok10k
			and paid10k ~= nil
			and math.abs(paid10k - Economy.speedCost(10000)) < 1e6
			and walk10k > Economy.runSpeedAt(10000),
		string.format("paid %s, walk speed %.4f", tostring(paid10k), walk10k)
	)
	logConn:Disconnect()
	hook:FireServer("set", { speedLevel = 200 })
	-- trillion-scale whole-number Power, shown abbreviated on the Power HUD
	hook:FireServer("command", "/power 2500000000000")
	check("Power can be 2.5 trillion", waitFor(function()
		return Data.state.kickPower == 2.5e12
	end, 4) ~= nil, Data.state.kickPower)
	task.wait(0.6)
	local shown = nil
	for _, d in hud:GetDescendants() do
		if d:IsA("TextLabel") and string.sub(d.Text, 1, 6) == "POWER " then
			shown = d.Text
		end
	end
	check("the Power HUD shows it as a whole abbreviated number", shown == "POWER 2.5T", shown)
	-- a real sack kick adds exactly the sack's whole-number gain
	hook:FireServer("command", "/power 1000")
	waitFor(function()
		return Data.state.kickPower == 1000
	end, 3)
	tp(onPad + Vector3.new(0, 0, -30))
	task.wait(0.8)
	SackGear.toggle()
	waitFor(holdingSack, 3)
	task.wait(1.8)
	local before = Data.state.kickPower
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		tool:Activate()
	end
	local after = waitFor(function()
		return Data.state.kickPower ~= before and Data.state.kickPower
	end, 3)
	local tier = Data.state.rackLevel or 1
	local want = Economy.trainGain(require(Shared.Config.Upgrades).Sack.tiers[tier].gain, Data.state.rebirths or 0)
	check(
		"a sack kick adds its whole-number gain",
		after ~= nil and after - before == want and after % 1 == 0,
		after and `+{after - before} (sack {tier}: +{want})`
	)
	SackGear.toggle()
	waitFor(function()
		return not holdingSack()
	end, 3)
end)

-- BUG 6: Shift Lock + the sack. The camera must stay on the Humanoid and not turn by itself. Scripts can't press
-- Shift or reach the PlayerModule's MouseLockController (RobloxScript only), so the probe does what Shift Lock does
-- to the character: UserGameSettings.RotationType = CameraRelative (the character turns with the camera).
step("audio: scenarios 7-8, punching a basic and a premium sack", function()
	local function punch(tier: number)
		local from = #Audio.history
		SackGear.toggle()
		waitFor(holdingSack, 3)
		task.wait(1.8) -- the bag drops onto its chain
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			tool:Activate()
		end
		local e = waitFor(function()
			return audioEntries(from, `Sack{tier}.impact`)[1]
		end, 3)
		task.wait(0.8)
		local equip = audioEntries(from, `Sack{tier}.equip`)[1]
		SackGear.toggle()
		waitFor(function()
			return not holdingSack()
		end, 3)
		return e, equip
	end
	tp(onPad + Vector3.new(0, 0, -30))
	task.wait(1)
	local basic, basicEquip = punch(Data.state.rackLevel or 1)
	local basicMagic = basic ~= nil and table.find(basic.layers, "tone") ~= nil
	check(
		"scenario 7: a basic sack punch = a dry thud (thump + tap, no magic, no thunder)",
		basic ~= nil and basic.loaded and basic.tier == 1 and not basicMagic and table.find(basic.layers, "boom") == nil,
		describe(basic)
	)
	check("the sack's drop onto its chain plays (equip)", basicEquip ~= nil and basicEquip.loaded, describe(basicEquip))
	hook:FireServer("sack", 20)
	waitFor(function()
		return Data.state.rackLevel == 20
	end, 4)
	task.wait(1.5)
	local premium = punch(20)
	check(
		"scenario 8: a Rainbow God punch = physical hit + short sparkle",
		premium ~= nil
			and premium.loaded
			and table.find(premium.layers, "thump") ~= nil
			and table.find(premium.layers, "tone") ~= nil
			and table.find(premium.layers, "boom") == nil
			and premium.audible < 0.9,
		describe(premium)
	)
end)

step("audio: scenarios 4-6 and the loop's sounds, live", function()
	-- 5 / 6: the real kick was a Perfect one (timing 0.95); a normal and a weak kick through the same path
	local perfect = Audio.last("KickPerfect")
	check(
		"scenario 6: the Perfect Kick played KickPerfect (whoosh + impact + flourish)",
		perfect ~= nil and perfect.loaded,
		describe(perfect)
	)
	local anchor = Instance.new("Part")
	anchor.Anchored, anchor.CanCollide, anchor.Transparency = true, false, 1
	anchor.CFrame = hrp.CFrame * CFrame.new(0, -1, -3)
	anchor.Parent = workspace
	local VFX = require(Shared.VFX)
	VFX.play("KickImpact", anchor, { power = 12, cutscene = true, own = true, band = "good" })
	task.wait(1)
	VFX.play("KickImpact", anchor, { power = 12, cutscene = true, own = true, band = "weak" })
	task.wait(1)
	anchor:Destroy()
	local good, weak = Audio.last("KickGood"), Audio.last("KickWeak")
	check(
		"scenario 5: a normal kick = KickGood (controlled impact)",
		good ~= nil and good.loaded and table.find(good.layers, "boom") == nil,
		describe(good)
	)
	check(
		"kicks scale: weak < normal < perfect (loudness in the engine)",
		weak ~= nil
			and good ~= nil
			and perfect ~= nil
			and weak.loudness < good.loudness
			and good.loudness < perfect.loudness,
		weak
				and good
				and perfect
				and string.format("%.0f < %.0f < %.0f", weak.loudness, good.loudness, perfect.loudness)
			or nil
	)
	-- 4: the running egg
	local steps = 0
	for _, e in Audio.history do
		steps += if e.event == "EggStep" then 1 else 0
	end
	check("scenario 4: the steered egg's light steps played while it ran", steps >= 5, steps)
	-- the rest of the loop
	-- (SpinStop plays only when the last slot-machine spin finishes before touchdown, i.e. on long flights)
	note("SpinStop: " .. describe(Audio.last("SpinStop")))
	for _, name in
		{
			"ZoneEnter",
			"LegsSprout",
			"AvalancheStart",
			"AvalancheStop",
			"EggSecured",
			"EggHold",
			"EggPlace",
			"PetPickup",
			"PetPlace",
		}
	do
		local e = Audio.last(name)
		check(`sound plays and loads: {name}`, e ~= nil and e.loaded, describe(e))
	end
	check("the avalanche rolls with a looping roar", Audio.last("AvalancheRoll") ~= nil)
	if result then
		local surface = SoundBank.ZoneSurface[result.landZone]
		local land = Audio.last("EggLand_" .. surface)
		check(
			`the flight egg's landing sounds like its zone's ground ({surface})`,
			land ~= nil and land.loaded,
			describe(land)
		)
	end
	Modal.toast("Sound check", "good")
	task.wait(0.3)
	Modal.toast("Sound check", "error")
	task.wait(0.5)
	local ok, bad = Audio.last("UISuccess"), Audio.last("UIError")
	check("UI: success and error sounds (2D)", ok ~= nil and ok.loaded and bad ~= nil and bad.loaded and ok.at == nil)
	-- thunder only where it belongs
	local offenders = {}
	for _, e in Audio.history do
		if table.find(e.layers, "boom") and e.event ~= "Sack14.special" and not string.find(e.event, "Stormy") then
			table.insert(offenders, e.event)
		end
	end
	check("no thunder on any ordinary sound in the whole session", #offenders == 0, table.concat(offenders, ","))
	-- the tiers, as heard in the engine
	local byTier = { {}, {}, {}, {} }
	for _, e in Audio.history do
		if e.loudness > 0 then
			table.insert(byTier[e.tier], e.loudness)
		end
	end
	local means = {}
	for t = 1, 4 do
		local sum = 0
		for _, v in byTier[t] do
			sum += v
		end
		means[t] = if #byTier[t] > 0 then sum / #byTier[t] else 0
	end
	note(
		string.format(
			"mean loudness by tier (engine): T1 %.0f (%d), T2 %.0f (%d), T3 %.0f (%d), T4 %.0f (%d)",
			means[1],
			#byTier[1],
			means[2],
			#byTier[2],
			means[3],
			#byTier[3],
			means[4],
			#byTier[4]
		)
	)
	check(
		"in the engine: routine (tier 1) sounds are the quietest",
		means[1] > 0 and means[1] < means[2] and means[1] < means[3]
	)
	local unloaded = {}
	for _, e in Audio.history do
		if e.loudness > 0 and not e.loaded then
			table.insert(unloaded, e.event)
		end
	end
	check("every measured sound loaded its asset", #unloaded == 0, table.concat(unloaded, ","))
end)

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

step("inventory after a respawn", function()
	local function count()
		local eggs, pets = 0, 0
		local backpack = player:FindFirstChildOfClass("Backpack")
		for _, t in if backpack then backpack:GetChildren() else {} do
			eggs += if t:IsA("Tool") and t:GetAttribute("EggUid") then 1 else 0
			pets += if t:IsA("Tool") and t:GetAttribute("PetUid") then 1 else 0
		end
		return eggs, pets
	end
	local before = #(Data.state.eggs or {})
	hook:FireServer("giveEgg") -- something to carry over
	waitFor(function()
		return #(Data.state.eggs or {}) > before
	end, 4)
	local wantEggs = #(Data.state.eggs or {})
	local wantPets = 0
	for _, pet in Data.state.pets or {} do
		wantPets += if not pet.placed then 1 else 0
	end
	local function sackState(tag)
		local seen = {}
		for _, holder in
			{ player:FindFirstChild("SackGear"), player:FindFirstChildOfClass("Backpack"), player.Character }
		do
			for _, c in if holder then holder:GetChildren() else {} do
				if c:IsA("Tool") and c:GetAttribute("KickSack") then
					table.insert(seen, holder.Name .. ":" .. c.Name)
				end
			end
		end
		note(tag .. " client sack tools: " .. table.concat(seen, ", "))
		hook:FireServer("sackstate")
	end
	sackState("before respawn")
	hook:FireServer("respawn")
	task.delay(5, sackState, "after respawn")
	local newChar = waitFor(function()
		return player.Character ~= char and player.Character
	end, 10)
	check("respawned", newChar ~= nil)
	local ok = waitFor(function()
		local e, p = count()
		return e == wantEggs and p == wantPets
	end, 6)
	local e, p = count()
	check(
		"after a respawn the Backpack holds every egg and stored pet once",
		ok ~= nil and wantEggs >= 1,
		`eggs {e}/{wantEggs}, pets {p}/{wantPets}`
	)
	local sackOk = waitFor(function()
		local folder = player:FindFirstChild("SackGear")
		return folder and folder:FindFirstChildOfClass("Tool") and backpackTool("KickSack") == nil
	end, 6)
	local folder = player:FindFirstChild("SackGear")
	local held = player.Character and player.Character:FindFirstChildOfClass("Tool")
	check(
		"after a respawn the sack is still on its quickslot (not in the Backpack)",
		sackOk ~= nil,
		string.format(
			"folder %s, in backpack %s, in hand %s",
			tostring(folder and #folder:GetChildren()),
			tostring(backpackTool("KickSack") ~= nil),
			tostring(held and held.Name)
		)
	)
end)

send("DONE", "")
