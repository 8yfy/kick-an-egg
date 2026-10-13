--!strict
-- Headless server tests (Partner B). Run from the repo root with Studio installed:
--   sh tools/run-tests.sh            (or: tools/run-tests.sh tools/tests/Progression.server.lua)
-- Uses run-in-roblox, which runs this script inside Studio as a plugin: services are required
-- directly (their Init/Start don't run), so only pure logic is tested here.

local SSS = game:GetService("ServerScriptService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Services = SSS.Server.Services

local Chase = require(Shared.Config.Chase) :: any
local Economy = require(Shared.Config.Economy) :: any
local Builder = require(Shared.Builders.BlockBuilder) :: any

local passed, failed = 0, 0
local function check(name: string, ok: boolean)
	if ok then
		passed += 1
	else
		failed += 1
		warn(`[FAIL] {name}`)
	end
end

local function section(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		failed += 1
		warn(`[FAIL] {name} errored: {err}`)
	end
end

section("RateLimiter", function()
	local RateLimiter = require(SSS.Server.Util.RateLimiter) :: any
	local limiter = RateLimiter.new()
	local fake = {} :: any
	local allowed = 0
	for _ = 1, 20 do
		if limiter:allow(fake) then
			allowed += 1
		end
	end
	check("burst of 10", allowed == 10)
end)

section("KickService", function()
	local KickService = require(Services.KickService) :: any
	KickService:Simulate(200, 10, 0) -- prints the distributions; must not error
	check("simulate ran", true)
end)

section("ChaseService (steered egg)", function()
	local CS = require(Services.ChaseService) :: any
	local function mk(landZ: number, zone: number)
		return {
			landPos = Vector3.new(5, 0, landZ),
			startZ = landZ + Chase.Avalanche.spawnBehindLanding,
			startTime = Chase.Avalanche.warnSeconds,
			speed = Chase.avalancheSpeed(zone),
			controlStart = Chase.Egg.runDelay,
			resolved = false,
		}
	end
	-- Steers straight home at `v` from controlStart; returns the outcome.
	local function run(c: any, v: number): string?
		local out, t = nil, 0
		while not out and t < 600 do
			t += 0.1
			local z = c.landPos.Z - v * math.max(0, t - c.controlStart)
			out = CS.decide(c, t, Vector3.new(5, 0, z))
		end
		return out
	end
	check("idle egg is caught", run(mk(50, 1), 0) == "EggCaught")
	check("zone 1 at speed 16 is secured", run(mk(50, 1), 16) == "Secured")
	check("zone 10 at speed 16 is caught", run(mk(1140, 10), 16) == "EggCaught")
	check("zone 10 at speed 30 is secured", run(mk(1140, 10), 30) == "Secured")
	local c = mk(50, 1)
	c.resolved = true
	local out, t = nil, 0
	while not out and t < 600 do
		t += 0.1
		out = CS.decide(c, t, Vector3.new(5, 0, -20))
	end
	check("Ended after secure", out == "Ended")
	check("egg speed = Run Speed", CS.eggSpeedFor({ runSpeed = 20 }) == 20)
	check("normal move is plausible", CS.plausible(Vector3.zero, 0, Vector3.new(0, 0, 2), 0.1, 16))
	check("teleport rejected", not CS.plausible(Vector3.zero, 0, Vector3.new(0, 0, 300), 0.1, 16))
	check("teleport plausible later", CS.plausible(Vector3.zero, 0, Vector3.new(0, 0, 300), 9, 16))
	check("falling ignored", CS.plausible(Vector3.zero, 0, Vector3.new(0, -200, 0), 0.1, 16))
end)

section("PlotService.petIncome", function()
	local PS = require(Services.PlotService) :: any
	check(
		"Big + Sunny + 1 rebirth",
		PS.petIncome({ petId = "sprout_pup", size = "Big", weather = "Sunny" }, { rebirths = 1 }, 1) == 3.375
	)
	check("gamepass x2", PS.petIncome({ petId = "meadow_stag" }, { rebirths = 0 }, 2) == 16)
	check("unknown pet = 0", PS.petIncome({ petId = "nope" }, { rebirths = 0 }, 1) == 0)
end)

section("Economy", function()
	-- rebirths need ever more Kick Power (whole numbers): 1M, 10M, 100M ...
	check(
		"rebirth power: 1M, 10M, 100M",
		Economy.rebirthPower(0) == 1e6 and Economy.rebirthPower(1) == 1e7 and Economy.rebirthPower(2) == 1e8
	)
	-- Kick Power: whole numbers into the trillions; distance = log of power (big numbers, slow distance)
	local wholeGains = true
	for tier = 1, 20 do
		for r = 0, 5 do
			local g = Economy.trainGain(require(Shared.Config.Upgrades).Sack.tiers[tier].gain, r)
			wholeGains = wholeGains and g >= 1 and g % 1 == 0
		end
	end
	check("every sack gain is a whole number (every tier, every rebirth)", wholeGains)
	check("power grows past a trillion", Economy.addPower(9.9e11, 2e10) == 1.01e12)
	check(
		"power stops at the exact-integer ceiling",
		Economy.addPower(Economy.KickPower.max - 5, 2e10) == Economy.KickPower.max
	)
	check("power stays whole", Economy.addPower(10.7, 3.9) == 13)
	local function zoneOf(d: number): number
		return math.floor(d / 100) + 1
	end
	local good = Economy.TimingBonus.good
	check("~10 power reaches zone 2", zoneOf(Economy.kickDistance(10, 0, good)) == 2)
	check("1 million power reaches zone 10", zoneOf(Economy.kickDistance(1e6, 0, good)) == 10)
	check("1 trillion power reaches zone 20", zoneOf(Economy.kickDistance(1e12, 0, good)) == 20)
	check(
		"x10 power = one more step of the same size (log)",
		math.abs(
			(Economy.kickDistance(1e9, 0, good) - Economy.kickDistance(1e8, 0, good)) - Economy.Distance.studsPerDecade
		) < 1
	)
	check(
		"distance grows much slower than power",
		Economy.kickDistance(1e12, 0, good) < 2 * Economy.kickDistance(1e6, 0, good)
	)
	check(
		"a Perfect kick goes farther than a miss",
		Economy.kickDistance(1e6, 0, Economy.TimingBonus.perfect)
			> Economy.kickDistance(1e6, 0, Economy.TimingBonus.miss)
	)
	for _, p in { 0 / 0, math.huge, -5, 1e300 } do
		local d = Economy.kickDistance(p, 0, good)
		check(`distance for power {p} is finite`, d == d and d < math.huge and d >= 0)
	end
	-- Run Speed: unlimited levels, every level still adds speed (log), costs grow and never overflow
	check("speed level 0 = base", Economy.runSpeedAt(0) == Economy.RunSpeed.base)
	local last, lastCost, rising, cheaper = -1, -1, true, true
	for level = 0, 2000 do
		local v, c = Economy.runSpeedAt(level), Economy.speedCost(level)
		rising = rising and v > last
		cheaper = cheaper and c > lastCost and c == c and c < math.huge and c % 1 == 0
		last, lastCost = v, c
	end
	check("speed rises at every level (0..2000)", rising)
	check("speed cost rises every level, whole and finite", cheaper)
	check("level 121 is faster than 120 (no cap at 120)", Economy.runSpeedAt(121) > Economy.runSpeedAt(120))
	check("level 10,000 is still faster than 9,999", Economy.runSpeedAt(10000) > Economy.runSpeedAt(9999))
	check(
		"diminishing returns",
		Economy.runSpeedAt(1001) - Economy.runSpeedAt(1000) < Economy.runSpeedAt(11) - Economy.runSpeedAt(10)
	)
	for _, level in { 1e6, 1e12, 0 / 0, -5 } do
		local v, c = Economy.runSpeedAt(level), Economy.speedCost(level)
		check(`speed at level {level} is safe`, v == v and v <= Economy.RunSpeed.safety and c == c and c < math.huge)
	end
	for _, old in { 16, 17, 25, 40 } do
		local level = Economy.speedLevelFor(old)
		check(`old speed {old} keeps its speed`, Economy.runSpeedAt(level) >= old - 1e-6)
	end
	check("upgradeCost(RunSpeed) = speedCost(level)", Economy.upgradeCost("RunSpeed", 7) == Economy.speedCost(7))
	-- avalanche speed: smooth, faster later, always below the top egg speed
	local Chase = require(Shared.Config.Chase) :: any
	local prev, smooth, escapable = 0, true, true
	for zone = 1, 20 do
		local v = Chase.avalancheSpeed(zone)
		smooth = smooth and v > prev and (zone == 1 or v - prev < 3)
		escapable = escapable and v < Economy.runSpeedAt(1000) - 3
		prev = v
	end
	check("avalanche faster in every later zone, no big jumps", smooth)
	check("a well upgraded egg (level 1000) can outrun every avalanche", escapable)
	check(
		"later zones have clearly faster avalanches (zone 1 < 10 < 20)",
		Chase.avalancheSpeed(1) + 8 < Chase.avalancheSpeed(10)
			and Chase.avalancheSpeed(10) + 15 < Chase.avalancheSpeed(20)
	)
	-- avalanche start: inside the landing zone, a fair gap behind the egg, never past the end wall
	local Zones = require(Shared.Config.Zones) :: any
	local A = Chase.Avalanche
	local inside, gap, onMap = true, true, true
	for zone = 1, 20 do
		local z = Zones[zone]
		for _, wanted in { z.start + 1, z.start + z.length / 2, z.start + z.length - 1 } do
			-- real landings stop Chase.Landing.endMargin before the end wall (KickService.landingPoint)
			local landZ = math.min(wanted, Chase.trackEnd() - Chase.Landing.endMargin)
			local start = Chase.avalancheStartZ(landZ, zone)
			gap = gap and start - landZ >= A.spawnMinBehind - 1e-6
			onMap = onMap and start <= Chase.trackEnd() - A.endMargin + 1e-6
			if landZ + A.spawnMinBehind <= z.start + z.length then
				inside = inside and start <= z.start + z.length + 1e-6
			end
		end
	end
	check("avalanche starts inside the landing zone when there is room", inside)
	check("avalanche never closer than the minimum gap", gap)
	check("avalanche never past the map's end wall", onMap)
	-- sack gains: whole numbers, every sack much stronger than the one before (no caps)
	local Upgrades = require(Shared.Config.Upgrades) :: any
	local gainsUp = true
	for i = 2, #Upgrades.Sack.tiers do
		local t = Upgrades.Sack.tiers[i]
		gainsUp = gainsUp and t.gain > Upgrades.Sack.tiers[i - 1].gain and t.gain % 1 == 0 and t.cap == nil
	end
	check("every sack gives more whole Kick Power than the one before, no caps", gainsUp)
	check("sack training grows with rebirths", Economy.trainGain(10, 1) == 20 and Economy.trainGain(10, 2) == 30)
	check("rebirths add a little kick distance", Economy.distanceMultiplier(2) == 1.2)
end)

section("TradeService", function()
	local T = require(Services.TradeService) :: any
	local a =
		{ p1 = { petId = "sprout_pup", placed = true, x = 1, z = 2 }, p2 = { petId = "bumble_bloc", placed = true } }
	local b = { q1 = { petId = "meadow_stag", placed = true } }
	local na, nb = T.swap(a, b, { "p1" }, { "q1" })
	check("A receives q1 stored", na and na.q1 and na.q1.placed == nil and na.p1 == nil and na.p2.placed == true)
	check("B receives p1 stored", nb and nb.p1 and nb.p1.placed == nil and nb.p1.x == nil and nb.q1 == nil)
	check("inputs untouched", a.p1.placed == true and b.q1 ~= nil)
	check("missing pet rejects", T.swap(a, b, { "zzz" }, {}) == nil)
	check("sell value", T.sellValue({ petId = "meadow_stag", size = "Huge", weather = "Sunny" }) == 2160)
end)

section("AnnounceService", function()
	local An = require(Services.AnnounceService) :: any
	check(
		"text",
		An.describe("Kai", "prism_seraph", "Secret", "Huge", "Sunny")
			== "Kai kicked a Huge Sunny Prism Seraph (Secret)!"
	)
end)

section("DataService.sanitize", function()
	local D = require(Services.DataService) :: any
	local d = {
		money = 0 / 0,
		kickPower = 1e9 + 0.7,
		runSpeed = -5,
		rebirths = 2.7,
		eggs = "junk",
		pets = {},
		plots = {},
		stats = {},
		receipts = {},
		onboarding = math.huge,
		plotSlots = 0 / 0,
	}
	D.sanitize(d)
	check("NaN money", d.money == 0)
	check("rebirths floored", d.rebirths == 2)
	check("kickPower kept as a whole number (no design cap)", d.kickPower == 1e9)
	local big = { kickPower = 1e300, eggs = {}, pets = {}, plots = {}, stats = {}, receipts = {} }
	D.sanitize(big)
	check("kickPower never past the exact-integer ceiling", big.kickPower == Economy.KickPower.max)
	check("runSpeed raised", d.runSpeed == 16)
	check("eggs restored", typeof(d.eggs) == "table")
	check("onboarding reset", d.onboarding == 0)
	check("plotSlots cleared", d.plotSlots == nil)
end)

section("SackService + pens + collecting", function()
	local Upgrades = require(Shared.Config.Upgrades) :: any
	local RS = require(Services.RackService) :: any
	local SS = require(Services.SackService) :: any
	local PS = require(Services.PlotService) :: any
	local Sacks = require(Shared.Builders.Models.Sacks) :: any
	local levels = Upgrades.Sack.tiers
	check("20 sacks", #levels == 20 and Sacks.count == 20)
	for i = 2, #levels do
		if levels[i].gain <= levels[i - 1].gain or levels[i].cost <= levels[i - 1].cost then
			check(`sack {i} beats sack {i - 1}`, false)
		end
	end
	check("sack 1 adds its gain", SS.trained(1, 1, 0) == 1 + levels[1].gain)
	check("better sack trains faster", SS.trained(1, 5, 0) > SS.trained(1, 1, 0))
	check("the top sack gives billions per kick", SS.trained(0, #levels, 0) >= 1e10)
	check("no cap: a high power keeps growing", SS.trained(5e11, 1, 0) == 5e11 + levels[1].gain)
	check("a rebirth doubles sack training", SS.trained(1, 5, 1) - 1 == 2 * levels[5].gain)
	check(
		"power never past the exact-integer ceiling",
		SS.trained(Economy.KickPower.max, #levels, 3) == Economy.KickPower.max
	)
	-- with the sack bought for a zone, its next zone takes real training (tens of kicks, not one or thousands)
	local fair = true
	for zone = 5, 19 do
		local function powerAt(d: number): number
			return 10 ^ (d / Economy.Distance.studsPerDecade) - 1
		end
		local need = powerAt((zone - 0.5) * 100) - powerAt((zone - 1.5) * 100) -- the zone it was bought for
		local kicks = need / levels[zone].gain
		if kicks < 30 or kicks > 150 then
			fair = false
			warn(`zone {zone}: {kicks} kicks`)
		end
	end
	check("each sack needs ~30-150 kicks to carry you through its zone", fair)
	check("next sack cost", SS.sackCost(1) == levels[2].cost)
	check("no sack after the top", SS.sackCost(#levels) == nil)
	local root = CFrame.lookAt(Vector3.new(30, 3, -40), Vector3.new(30, 3, -50))
	local at = SS.placement(root, 0)
	check(
		"sack hangs ahead of the player",
		(Vector3.new(at.X, 3, at.Z) - Vector3.new(30, 3, -40 - SS.PLACE_DIST)).Magnitude < 0.01
	)
	check("sack hangs at kicking height", math.abs(at.Y - Sacks.HANG) < 0.01)
	check("sack faces the player", at.LookVector:Dot(Vector3.new(0, 0, 1)) > 0.99)
	check("next to the sack", SS.inRange(at, Vector3.new(30, 3, -40)))
	check("away from the sack", not SS.inRange(at, Vector3.new(30 + Upgrades.Sack.range + 2, 3, -40 - SS.PLACE_DIST)))
	check("not from a different floor", not SS.inRange(at, Vector3.new(30, 40, -40)))
	for tier = 1, Sacks.count do
		local ok, model = pcall(function()
			return Builder.build(Sacks.spec(tier), "Sack")
		end)
		local parts = if ok then #model:GetDescendants() else 0
		check(`sack {tier} builds`, ok and parts > 20 and parts < 700)
		if ok then
			model:Destroy()
		end
	end
	-- the game's sack geometry: the original GLB imports (assets/sacks/SackAssets.rbxm), else the part remodel
	local SackGeometry = require(Shared.Builders.SackGeometry) :: any
	check("all 20 GLB imports in the place", SackGeometry.imported() == 20)
	for _, tier in { 1, 7, 17, 20 } do
		local geo, source = SackGeometry.build(tier)
		local parts = 0
		for _, d in geo:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		-- every imported part carries its original GLB node name, so every one gets its original material
		check(
			"sack " .. tier .. " builds from the import with original materials",
			source == "GLB" and parts > 20 and geo:GetAttribute("MatchedGLBMaterials") == parts
		)
		geo:Destroy()
	end
	local SackAssets = game:GetService("ReplicatedStorage"):FindFirstChild("SackAssets")
	if SackAssets then
		SackAssets.Parent = nil
	end
	local geo, source = SackGeometry.build(7)
	check("SackGeometry falls back to the part remodel", source == "Parts" and #geo:GetDescendants() > 20)
	geo:Destroy()
	local SackModel = require(game:GetService("ReplicatedStorage").SackModules.SackModel) :: any
	check(
		"package SackModel is strict without imports",
		not pcall(SackModel.Build, 1, workspace, CFrame.new(), { RequireGLB = true })
	)
	if SackAssets then
		SackAssets.Parent = game:GetService("ReplicatedStorage")
	end
	-- premium hero pairs (Models/Premium, docs/EggPetPlan.md) and their effects (VFX/PetFx)
	local HeroModels = require(Shared.Builders.Models) :: any
	local Sculpt = require(Shared.Builders.Models.Sculpt) :: any
	local PetFx = require(Shared.VFX.PetFx) :: any
	local heroes =
		{ "SproutPup", "MeadowStag", "TideSpirit", "IceDragon", "QuetzalPhoenix", "ClockworkTitan", "PrismSeraph" }
	local lastParts = 0
	local signatures: { [string]: string } = {}
	local unique = true
	for _, key in heroes do
		local egg, pet = HeroModels.egg(key), HeroModels.pet(key)
		local parts = 0
		for _, d in pet:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		check(key .. " pet is more detailed than the rarity below it", parts > lastParts)
		lastParts = parts
		local _, shell = Sculpt.shellBounds(egg)
		check(key .. " egg shell fits the chase", shell.X <= 4.2 and shell.Z <= 4.2 and shell.Y <= 6)
		check(key .. " egg keeps its Body joint (legs sprout under it)", egg.PrimaryPart:FindFirstChild("Body") ~= nil)
		for _, kind in { "egg", "pet" } do
			local recipe = PetFx.recipe(kind, key)
			local ok = recipe ~= nil and #recipe.layers > 0
			local sig = {}
			for _, layer in if recipe then recipe.layers else {} do
				ok = ok and (layer.sprite == nil or PetFx.Sprites.has(layer.sprite))
				table.insert(sig, layer.kind .. ":" .. tostring(layer.sprite))
			end
			table.sort(sig)
			local text = table.concat(sig, ",")
			if signatures[text] then
				unique = false
			end
			signatures[text] = key .. " " .. kind
			check(key .. " " .. kind .. " has a valid effect recipe", ok)
		end
		pet.Parent = workspace
		local handle = PetFx.attach(pet, "pet", key)
		check(key .. " pet effect attaches", handle ~= nil and pet:FindFirstChild("PetFx") ~= nil)
		if handle then
			handle.Destroy()
		end
		check(key .. " pet effect cleans up", pet:FindFirstChild("PetFx") == nil)
		pet:Destroy()
		egg:Destroy()
	end
	check("every hero egg and pet has its own effect stack", unique)
	check("no recipe for a pair without one", PetFx.attach(HeroModels.pet("BumbleBloc"), "pet", "BumbleBloc") == nil)
	-- kick pad: the HUD shows KICK inside SHOW_RADIUS, the server accepts kicks inside ACCEPT_RADIUS only
	local KickPad = require(Shared.KickPad) :: any
	if not workspace:FindFirstChild("Map") then
		require(Shared.Builders.Map.MapBuilder).build() -- the test place starts without the map
	end
	local pad = KickPad.part()
	if pad then
		local top = pad.Position + Vector3.new(0, 3, 0)
		check("kick pad: on the pad counts", KickPad.contains(top, KickPad.ACCEPT_RADIUS))
		check("kick pad: the HUD radius is inside the server one", KickPad.SHOW_RADIUS < KickPad.ACCEPT_RADIUS)
		check(
			"kick pad: 30 studs away is rejected",
			not KickPad.contains(top + Vector3.new(30, 0, 0), KickPad.ACCEPT_RADIUS)
		)
		check("kick pad: no character is rejected", not KickPad.has(nil, KickPad.ACCEPT_RADIUS))
	end
	-- the physical Boxing Sack Shop (replaces the Training HUD button) + the Train prompt on sack stands
	local map = workspace:FindFirstChild("Map")
	local shop = map and map:FindFirstChild("BoxingSackShop", true)
	if map then
		check("boxing sack shop exists", shop ~= nil)
		local opens, sacks = false, 0
		for _, d in if shop then shop:GetDescendants() else {} do
			if d:IsA("ProximityPrompt") and d:GetAttribute("Action") == "OpenMenu:Store" then
				opens = true
			elseif d:IsA("Model") and d.Name == "Sack" and typeof(d:GetAttribute("Tier")) == "number" then
				sacks += 1
			end
		end
		check("boxing sack shop opens the existing sack screen", opens)
		check("boxing sack shop shows 6 sack models", sacks == 6)
		local trainPrompts, stands, rackSigns = 0, 0, 0
		for _, d in map:GetDescendants() do
			if d:IsA("ProximityPrompt") and d:GetAttribute("Action") == "EquipSack" then
				trainPrompts += 1
			elseif d.Name == "SackStand" then
				stands += 1
			elseif d.Name == "RackSign" then
				rackSigns += 1
			end
		end
		check("old sack stands, Train prompts and sack signs are gone", trainPrompts + stands + rackSigns == 0)
		local bases = map.SafeZone.Bases:GetChildren()
		check("six pens", #bases == 6)
		local areas = 0
		for _, base in bases do
			local area = base:FindFirstChild("PenArea")
			if
				area
				and area:IsA("BasePart")
				and base:FindFirstChild("OwnerAnchor")
				and not base:FindFirstChild("Pedestals")
			then
				areas += 1
			end
		end
		check("every pen has its floor frame and owner anchor, no pedestals", areas == 6)
		local CollectionService = game:GetService("CollectionService")
		check("lanes + ramp are the landing surfaces", #CollectionService:GetTagged("LandingSurface") == 21)
		local Physics = game:GetService("PhysicsService")
		check(
			"steered eggs pass through characters (the kicker waits on the pad, on the way home)",
			not Physics:CollisionGroupsAreCollidable("Eggs", "Players")
				and not Physics:CollisionGroupsAreCollidable("Eggs", "PlayerBarrier")
				and Physics:CollisionGroupsAreCollidable("Eggs", "Default")
		)
		-- landings only on the track: never past the end wall, never on top of walls / props / eggs
		local KS = require(Services.KickService) :: any
		local Chase = require(Shared.Config.Chase) :: any
		local okLand = true
		for _, dist in { 21, 150, 999.5, 1000, 1900, 1990, 2050, 5000 } do
			for _, x in { -30, 0, 17 } do
				local p = KS.landingPoint(x, dist)
				okLand = okLand
					and p.Z <= Chase.trackEnd() - Chase.Landing.endMargin + 1e-6
					and math.abs(p.X) <= Chase.RunwayWidth / 2 - Chase.Landing.edgeMargin + 1e-6
					and p.Y > -1
					and p.Y < 14
			end
		end
		check("eggs land only on the track, inside the lane, before the end wall", okLand)
		-- pen geometry (PlotService): pen-local coordinates, egg spots
		local base1 = map.SafeZone.Bases:FindFirstChild("Base1") :: Model
		local area = base1:FindFirstChild("PenArea") :: BasePart
		local inside = PS.toWorld(area, 3, -4)
		local lx, lz, ok = PS.toLocal(area, inside)
		check("pen local <-> world round trip", ok and math.abs(lx - 3) < 1e-3 and math.abs(lz + 4) < 1e-3)
		local _, _, outside = PS.toLocal(area, PS.toWorld(area, area.Size.X / 2 + 2, 0))
		check("past the fence is outside the pen", not outside)
		local penData = {
			plots = { e1 = { uid = "e1", petId = "sprout_pup", x = 0, z = 0, hatchAt = 1 } },
			pets = {},
			penLevel = 1,
		}
		check("egg spot: free spot is fine", PS.eggSpotProblem(area, penData, PS.toWorld(area, 10, 5)) == nil)
		check("egg spot: too close to an egg", PS.eggSpotProblem(area, penData, PS.toWorld(area, 1, 1)) ~= nil)
		check("egg spot: outside the pen", PS.eggSpotProblem(area, penData, PS.toWorld(area, 100, 0)) ~= nil)
		local full = { plots = {}, pets = {}, penLevel = 1 }
		for i = 1, PS.slotsForPen(1) do
			full.pets["p" .. i] = { petId = "sprout_pup", placed = true }
		end
		check("egg spot: a full pen", PS.eggSpotProblem(area, full, PS.toWorld(area, 10, 5)) ~= nil)
		local hx, hz = PS.penHalf(area)
		local spots = true
		for _ = 1, 50 do
			local spot = PS.pickSpot(hx, hz, { Vector3.zero }, Vector3.zero)
			spots = spots and math.abs(spot.X) <= hx and math.abs(spot.Z) <= hz
		end
		check("roaming targets stay inside the pen", spots)
	end
	check("pen 1 = base slots", PS.slotsForPen(1) == Economy.PlotSlots.base)
	check("pen 2 adds slots", PS.slotsForPen(2) == Economy.PlotSlots.base + Upgrades.Pen.slotsPerLevel)
	check("pen slots capped", PS.slotsForPen(99) == Economy.PlotSlots.max)
	check("pen 1 -> 2 cost", RS.penCost(1) == Upgrades.Pen.costBase)
	check("pen 2 -> 3 cost", RS.penCost(2) == Upgrades.Pen.costBase * Upgrades.Pen.costGrowth)
	check("no pen upgrade at max slots", RS.penCost(99) == nil)
	local D = require(Services.DataService) :: any
	local d = {
		money = 0,
		kickPower = 3.25,
		runSpeed = 16,
		rebirths = 0,
		eggs = {},
		pets = {},
		plots = {},
		stats = {},
		receipts = {},
		tool = 3,
		rackLevel = 99,
		penLevel = 0 / 0,
	}
	D.sanitize(d)
	check("fractional strength rounded down to a whole number", d.kickPower == 3)
	check("sack tier clamped", d.rackLevel == #levels)
	check("NaN pen level -> 1", d.penLevel == 1)
	check("old tool field dropped", d.tool == nil)
	local d2 = {
		money = 0,
		kickPower = 1,
		runSpeed = 16,
		rebirths = 0,
		eggs = {},
		pets = { a = { petId = "sprout_pup", slot = 1 }, b = { petId = "gull_bloc" } },
		plots = {},
		stats = {},
		receipts = {},
		discovered = { maple_fox = true, junk = 5, [7] = true },
		indexClaims = "nope",
	}
	D.migrate(d2)
	D.sanitize(d2)
	check("owned pets count as discovered", d2.discovered.sprout_pup == true and d2.discovered.gull_bloc == true)
	check("discovered keeps earlier finds", d2.discovered.maple_fox == true)
	check("discovered drops junk", d2.discovered.junk == nil and d2.discovered[7] == nil)
	check("bad indexClaims reset", typeof(d2.indexClaims) == "table" and next(d2.indexClaims) == nil)
	-- v1 -> v2 save migration: pedestals -> placed pets / eggs at their old spots, cash paid out, speed kept
	local old = {
		version = 1,
		money = 100,
		kickPower = 12,
		runSpeed = 25,
		rebirths = 0,
		eggs = { { uid = "w1", petId = "sprout_pup" } },
		pets = {
			a = { petId = "sprout_pup", slot = 1, stored = 40.7 },
			b = { petId = "bumble_bloc", slot = 7, stored = 0 },
			c = { petId = "meadow_stag" },
		},
		plots = { ["3"] = { uid = "e3", petId = "sprout_pup", placedAt = 5, hatchAt = 15 } },
		stats = {},
		receipts = {},
	}
	D.migrate(old)
	D.sanitize(old)
	local ax, az = D.slotSpot(1)
	check("migration: version 2", old.version == D.VERSION)
	check(
		"migration: pedestal pets are placed at their spots",
		old.pets.a.placed == true and old.pets.a.x == ax and old.pets.a.z == az
	)
	check("migration: unplaced pets stay stored", old.pets.c.placed == nil)
	check("migration: no pedestal fields left", old.pets.a.slot == nil and old.pets.a.stored == nil)
	check("migration: pedestal cash paid out", old.money == 140)
	check(
		"migration: placed eggs keyed by uid with a spot",
		old.plots.e3 ~= nil and old.plots["3"] == nil and typeof(old.plots.e3.x) == "number"
	)
	check("migration: inventory eggs untouched", #old.eggs == 1 and old.eggs[1].uid == "w1")
	check("migration: run speed kept", Economy.runSpeedAt(old.speedLevel) >= 25 - 1e-6)
	local before = 12 * 24 * 1.5 -- the old Perfect kick of power 12
	local after = Economy.kickDistance(old.kickPower, 0, Economy.TimingBonus.perfect)
	check(
		"migration: power converted to whole numbers, same kick distance",
		old.kickPower % 1 == 0 and old.kickPower > 12 and math.abs(after - before) < 2
	)
	local maxed = {
		version = 2,
		kickPower = 100,
		speedLevel = 200,
		runSpeed = 47.7,
		rebirths = 0,
		eggs = {},
		pets = {},
		plots = {},
	}
	D.migrate(maxed)
	check(
		"migration: an old maxed player still kicks to the last zone, keeps their speed",
		maxed.version == 3
			and Economy.kickDistance(maxed.kickPower, 0, Economy.TimingBonus.perfect) >= 1949
			and Economy.runSpeedAt(maxed.speedLevel) >= 16 + 32 * (1 - 2 ^ (-200 / 30)) - 1e-6
	)
	local again = table.clone(old)
	D.migrate(again)
	check("migration runs once", again.money == 140)
	check("new fields defaulted", typeof(old.tutorial) == "table" and typeof(old.indexMilestones) == "table")
	local slotSpotsInPen = true
	for slot = 1, 20 do
		local x, z = D.slotSpot(slot)
		slotSpotsInPen = slotSpotsInPen and math.abs(x) <= 52 / 2 - 3.5 and math.abs(z) <= 44 / 2 - 3.5
	end
	check("every old pedestal spot is inside the new pens", slotSpotsInPen)
end)

section("Pets and eggs: all 79 build (hatching never fails on a model)", function()
	local Pets = require(Shared.Config.Pets) :: any
	local Models = require(Shared.Builders.Models) :: any
	local bad = {}
	for _, pet in Pets do
		for _, kind in { "pet", "egg" } do
			local ok, model = pcall(Models[kind], pet.model)
			if not ok or typeof(model) ~= "Instance" or not model.PrimaryPart then
				table.insert(bad, `{kind} {pet.model}: {model}`)
			else
				model:Destroy()
			end
		end
	end
	check(`all {#Pets} pets and their eggs build`, #bad == 0)
	for _, b in bad do
		warn("  " .. b)
	end
	check("79 pets configured", #Pets == 79)
end)

section("Pets stay assembled: all 79, normal and Big, through the hatch reveal and animation", function()
	-- (edit mode runs no physics, so jointed parts don't follow here: the joints themselves are checked; the live
	-- play-test checks the shapes on screen)
	local Pets = require(Shared.Config.Pets) :: any
	local Models = require(Shared.Builders.Models) :: any
	local Rig = require(Shared.Anim.Rig) :: any
	local Mutations = require(Shared.Config.Mutations) :: any
	local function close(a: CFrame, b: CFrame): boolean
		return (a.Position - b.Position).Magnitude < 0.01
			and a.LookVector:Dot(b.LookVector) > 0.9999
			and a.UpVector:Dot(b.UpVector) > 0.9999
	end
	local detached, broke, unrecorded = {}, {}, {}
	local motorsSeen = 0
	for _, pet in Pets do
		for _, size in { 1, Mutations.Size.Big and Mutations.Size.Big.scale or 1.5 } do
			local model = Models.pet(pet.model)
			local truth = Models.pet(pet.model) -- a fresh build: the design's exact joints
			if size ~= 1 then
				model:ScaleTo(size)
				truth:ScaleTo(size)
			end
			model.Parent = workspace
			local root = model.PrimaryPart :: BasePart
			-- 1. one assembly: every part rides on the Root (Motor6D / welds), nothing loose or anchored apart
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") and (d.AssemblyRootPart ~= root or (d.Anchored and d ~= root)) then
					table.insert(detached, `{pet.model} x{size}: {d.Name}`)
					break
				end
			end
			-- 2. the hatch reveal's old sequence: shrink -> animate -> grow back -> animate -> rest
			model:ScaleTo(size * 0.2)
			for _, m in Rig.motors(model) do
				Rig.pose(m, CFrame.Angles(0.2, 0.1, 0) + Vector3.new(0, -0.4, 0))
			end
			model:ScaleTo(size)
			for _, m in Rig.motors(model) do
				Rig.pose(m, CFrame.Angles(0.15, 0, 0.1))
				Rig.reset(m)
			end
			local want = Rig.motors(truth)
			for name, m in Rig.motors(model) do
				motorsSeen += 1
				if typeof(m:GetAttribute("RestC0")) ~= "CFrame" then
					table.insert(unrecorded, `{pet.model}.{name}`)
				end
				if not want[name] or not close(m.C0, want[name].C0) then
					table.insert(broke, `{pet.model} x{size}: {name}`)
				end
			end
			model:Destroy()
			truth:Destroy()
		end
	end
	check("all 79 pets: every part attached to the pet (one assembly, only the Root anchored)", #detached == 0)
	check("every animation joint records its rest pose", #unrecorded == 0 and motorsSeen > 0)
	check(
		`all 79 pets, normal + Big: after the hatch reveal + animation every joint is back at its design pose ({motorsSeen} joints)`,
		#broke == 0
	)
	for _, list in { detached, unrecorded, broke } do
		for k = 1, math.min(#list, 5) do
			warn("  " .. list[k])
		end
	end
	-- the old cache (first C0 seen) is what broke: without the record it would have kept the shrunken pose
	local legacy = Models.pet(Pets[1].model)
	local m = next(Rig.motors(legacy)) and select(2, next(Rig.motors(legacy)))
	if m then
		local rest = m.C0
		m:SetAttribute("RestC0", nil)
		legacy:ScaleTo(0.2)
		Rig.pose(m, CFrame.identity)
		legacy:ScaleTo(1)
		Rig.reset(m)
		check("(the old behaviour really broke it: a cached shrunken pose)", not close(m.C0, rest))
	end
	legacy:Destroy()
end)

section("Pet Index + rebirth rules", function()
	local IS = require(Services.IndexService) :: any
	local allPets = require(Shared.Config.Pets) :: any
	local all = {}
	for _, pet in allPets do
		all[pet.id] = true
	end
	check("discovered count", IS.discoveredCount(all) == #allPets and IS.discoveredCount({}) == 0)
	local counts = {}
	for _, m in Economy.IndexMilestones do
		table.insert(counts, m.count)
	end
	check("index milestones 10/25/40/60/79", table.concat(counts, ",") == "10,25,40,60,79")
	check("the last milestone is the whole index", Economy.IndexMilestones[#Economy.IndexMilestones].count == #allPets)
	local Pets = require(Shared.Config.Pets) :: any
	local zone1 = {}
	for _, pet in Pets do
		if pet.zone == 1 then
			zone1[pet.id] = true
		end
	end
	check("zone complete with every zone pet", IS.zoneComplete(zone1, 1))
	local missing = table.clone(zone1)
	missing[next(missing)] = nil
	check("zone not complete when one is missing", not IS.zoneComplete(missing, 1))
	check("unknown zone never complete", not IS.zoneComplete(zone1, 999))
	local D = require(Services.DataService) :: any
	local template = {
		money = 0,
		kickPower = 1,
		runSpeed = 16,
		rebirths = 0,
		eggs = {},
		pets = {},
		plots = {},
		stats = {},
		receipts = {},
	}
	D.sanitize(template)
	for _, key in Economy.Rebirth.resets do
		check(`rebirth resets a real field: {key}`, template[key] ~= nil)
	end
	for _, key in Economy.Rebirth.keeps do
		check(`rebirth keeps a real field: {key}`, template[key] ~= nil or key == "rackLevel" or key == "penLevel")
	end
end)

section("Kick Sack VFX: levels of detail, quality profiles, no leaks", function()
	local SackLod = require(Shared.VFX.SackLod) :: any
	local SackAura = require(Shared.VFX.SackAura) :: any
	local SackGeometry = require(Shared.Builders.SackGeometry) :: any
	local Sacks = require(Shared.Builders.Models.Sacks) :: any
	-- bands with hysteresis (edges 45 / 100 / 180, 8 studs)
	check("lod: 50 studs stays Full (hysteresis)", SackLod.band(50, 1, 1) == 1)
	check("lod: 54 studs from Full -> Reduced", SackLod.band(54, 1, 1) == 2)
	check("lod: 40 studs stays Reduced (hysteresis)", SackLod.band(40, 2, 1) == 2)
	check("lod: 36 studs from Reduced -> Full", SackLod.band(36, 2, 1) == 1)
	check("lod: 200 studs -> Disabled", SackLod.band(200, 1, 1) == 4)
	check("lod: 170 studs from Disabled -> Minimal", SackLod.band(170, 4, 1) == 3)
	check("lod: 175 studs stays Disabled", SackLod.band(175, 4, 1) == 4)
	check("lod: LOW reach pulls the bands in", SackLod.band(50, 1, SackLod.PROFILES.LOW.reach) == 2)
	-- conservative view test: camera at the origin looking down -Z, 70 degrees vertical
	local tanY, aspect = math.tan(math.rad(35)), 16 / 9
	check("view: ahead is in view", SackLod.inView(CFrame.new(), tanY, aspect, Vector3.new(0, 0, -50), 1))
	check("view: behind is culled", not SackLod.inView(CFrame.new(), tanY, aspect, Vector3.new(0, 0, 50), 1))
	check(
		"view: far to the side is culled",
		not SackLod.inView(CFrame.new(), tanY, aspect, Vector3.new(200, 0, -50), 1)
	)
	local edgeX = 50 * tanY * aspect
	check(
		"view: a sphere poking in at the edge counts",
		SackLod.inView(CFrame.new(), tanY, aspect, Vector3.new(edgeX + 3, 0, -50), 5)
	)
	-- quality caps from Roblox's graphics level (touch is never a factor)
	check("quality: Automatic -> HIGH (adaptive)", SackLod.capFor(0) == "HIGH")
	check("quality: level 10 -> HIGH", SackLod.capFor(10) == "HIGH")
	check("quality: level 6 -> MEDIUM", SackLod.capFor(6) == "MEDIUM")
	check("quality: level 3 -> LOW", SackLod.capFor(3) == "LOW")
	check("quality: level 1 -> MINIMAL", SackLod.capFor(1) == "MINIMAL")

	local HIGH = SackLod.PROFILES.HIGH
	local function census(folder: Instance): (number, number)
		local n, emitters = 0, 0
		for _, d in folder:GetDescendants() do
			n += 1
			if d:IsA("ParticleEmitter") then
				emitters += 1
			end
		end
		return n, emitters
	end
	local stepErrors, leaks, hiddenOk, backOk, premiumOk = {}, {}, true, true, true
	local before = SackLod.count()
	for tier = 1, 20 do
		local model = SackGeometry.build(tier)
		local hang = CFrame.new(tier * 30, 50, 0)
		model:PivotTo(hang)
		model.Parent = workspace
		local ok, err = pcall(function()
			local ctx = SackAura.Apply(model, tier, hang * Sacks.vfxRoot(tier), Sacks.SCALE, true, true)
			local folder = model:FindFirstChild("SackVFX") :: Instance
			local count0 = census(folder)
			for level = 1, 4 do
				ctx:setLod(level, true, HIGH)
				for _ = 1, 40 do
					ctx:step(1 / 60)
				end
				if level == 3 and tier >= 18 then
					for _, em in ctx.emitters do
						if em.keep and not em.e.Enabled then
							premiumOk = false -- the big glows / sunbursts / galaxy stay at Minimal
						end
					end
				end
			end
			-- Disabled: nothing shows, nothing is destroyed
			for _, sw in ctx.swarms do
				for _, p in sw.list do
					if p.active then
						hiddenOk = false
					end
				end
			end
			for _, em in ctx.emitters do
				if em.e.Enabled then
					hiddenOk = false
				end
			end
			for _, part in ctx.neons do
				if part.LocalTransparencyModifier ~= 1 then
					hiddenOk = false
				end
			end
			-- back to Full: everything returns (64 particles a frame), with the same instances
			ctx:setLod(1, true, HIGH)
			for _ = 1, 12 do
				ctx:step(1 / 60)
			end
			for _, sw in ctx.swarms do
				for _, p in sw.list do
					if not p.active then
						backOk = false
					end
				end
			end
			for _, L in ctx.lights do
				if L.l.Parent == nil then
					backOk = false
				end
			end
			-- off screen: steps still run (particles stay alive) without errors
			ctx:setLod(1, false, HIGH)
			for _ = 1, 30 do
				ctx:step(1 / 60)
			end
			if census(folder) ~= count0 then
				table.insert(leaks, tier)
			end
			SackAura.Remove(model)
			if model:FindFirstChild("SackVFX") or not ctx.dead then
				table.insert(leaks, tier)
			end
		end)
		if not ok then
			table.insert(stepErrors, `{tier}: {err}`)
		end
		model:Destroy()
	end
	check("sack vfx: all 20 tiers step at every level", #stepErrors == 0)
	for _, e in stepErrors do
		warn("  " .. e)
	end
	check("sack vfx: Disabled hides everything without destroying it", hiddenOk)
	check("sack vfx: back to Full brings every particle and light back", backOk)
	check("sack vfx: tiers 18-20 keep their hero glows at Minimal", premiumOk)
	check("sack vfx: no instances created by level changes, Remove frees all", #leaks == 0)
	check("sack vfx: unmanaged effects never enter the LOD registry", SackLod.count() == before)
	-- managed effects register and leave the registry on Remove / model destroy
	local model = SackGeometry.build(18)
	model.Parent = workspace
	SackAura.Apply(model, 18, Sacks.vfxRoot(18), Sacks.SCALE, true)
	check("sack vfx: Apply registers the effect for LOD", SackLod.count() == before + 1)
	model:Destroy()
	check("sack vfx: destroying the sack unregisters and frees its effect", SackLod.count() == before)
end)

section("Tutorial, sack sounds, mystery egg, merchants", function()
	local TS = require(Services.TutorialService) :: any
	local St = TS.Steps
	local fresh = { stats = { kicks = 0, secured = 0, lost = 0 }, pets = {}, plots = {}, eggs = {}, tutorial = {} }
	check("tutorial: a new player starts at the kick line", TS.stepFor(fresh, false, false) == St.KICK_LINE)
	check("tutorial: on the pad -> press KICK", TS.stepFor(fresh, true, false) == St.PRESS_KICK)
	local kicked = table.clone(fresh)
	kicked.stats = { kicks = 1, secured = 0, lost = 0 }
	check("tutorial: kicked -> watch the egg", TS.stepFor(kicked, true, false) == St.WATCH_EGG)
	local lost = table.clone(kicked)
	lost.stats = { kicks = 1, secured = 0, lost = 1 }
	check("tutorial: lost the first egg -> bring one home (never stuck)", TS.stepFor(lost, true, false) == St.COLLECT)
	local secured = table.clone(kicked)
	secured.stats = { kicks = 1, secured = 1, lost = 0 }
	secured.eggs = { { uid = "e", petId = "sprout_pup" } }
	check("tutorial: secured -> place the egg", TS.stepFor(secured, true, false) == St.PLACE_EGG)
	local placed = table.clone(secured)
	placed.eggs, placed.plots = {}, { e = { uid = "e" } }
	check("tutorial: placed -> hatch", TS.stepFor(placed, true, false) == St.HATCH)
	local hatched = table.clone(placed)
	hatched.plots, hatched.pets = {}, { p = { petId = "sprout_pup", placed = true } }
	check("tutorial: hatched -> income", TS.stepFor(hatched, true, false) == St.INCOME)
	check("tutorial: earning -> upgrade", TS.stepFor(hatched, true, true) == St.UPGRADE)
	local upgraded = table.clone(hatched)
	upgraded.speedLevel = 1
	check("tutorial: upgraded -> done", TS.stepFor(upgraded, true, true) == St.DONE)
	local veteran = table.clone(upgraded)
	veteran.tutorial = { done = true }
	check("tutorial: finished stays finished", TS.stepFor(veteran, false, false) == 0)
	local skipped = table.clone(fresh)
	skipped.tutorial = { skipped = true }
	check("tutorial: skipped never shows", TS.stepFor(skipped, false, false) == 0)
	-- every sack has its own sounds for every moment; only built-in or uploaded ids, never invented ones
	local SackSfx = require(Shared.VFX.SackSfx) :: any
	local soundsOk, distinct = true, {}
	for tier = 1, 20 do
		for _, moment in { "equip", "impact", "special", "upgrade" } do
			local layers = SackSfx.layers(tier, moment)
			soundsOk = soundsOk and #layers > 0
			for _, l in layers do
				soundsOk = soundsOk and l.pitch > 0 and l.volume > 0 and l.volume <= 1
			end
		end
		local sig = {}
		for _, l in SackSfx.layers(tier, "impact") do
			table.insert(sig, l.src .. l.pitch)
		end
		distinct[table.concat(sig, ",")] = true
	end
	local kinds = 0
	for _ in distinct do
		kinds += 1
	end
	check("every sack has equip / impact / special / upgrade sounds", soundsOk)
	check(`sack impacts sound different ({kinds} distinct sets)`, kinds >= 15)
	check("premium sacks have an ambient loop", #SackSfx.layers(18, "idle") > 0 and #SackSfx.layers(20, "idle") > 0)
	check("basic sacks stay quiet when idle", #SackSfx.layers(1, "idle") == 0)
	-- the black "?" mystery egg
	local MysteryEgg = require(Shared.Builders.Models.MysteryEgg) :: any
	local egg = MysteryEgg.build()
	local marks = 0
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Mark" then
			marks += 1
		end
	end
	local _, size = egg:GetBoundingBox()
	check("mystery egg builds with a ? on both faces", egg.PrimaryPart ~= nil and marks == 18)
	check("mystery egg is full egg size (not a small prop)", size.Y >= 3.2 and size.X >= 2.4)
	-- the egg kick: a full-body clip (legs, hips, torso, arms) with a contact frame, as a real KeyframeSequence
	local EggKick = require(Shared.Anim.EggKick) :: any
	local seq = EggKick.buildKeyframeSequence()
	local frames, contact, jointsMoved = 0, false, {}
	for _, kf in seq:GetChildren() do
		if kf:IsA("Keyframe") then
			frames += 1
			contact = contact or kf:FindFirstChild("Contact") ~= nil
			for _, p in kf:GetDescendants() do
				if p:IsA("Pose") and p.CFrame ~= CFrame.identity then
					jointsMoved[p.Name] = true
				end
			end
		end
	end
	local moved = 0
	for _ in jointsMoved do
		moved += 1
	end
	check(
		"egg kick: a keyframed rig animation (8 keys, 13 joints, a Contact marker)",
		frames == 8 and contact and moved >= 13
	)
	local contactPose = EggKick.pose(EggKick.CONTACT)
	check(
		"egg kick: at contact the kicking leg is straight out front",
		contactPose.RHip[1] > 80 and contactPose.RKnee[1] > -15
	)
	local wind = EggKick.pose(0.5)
	check(
		"egg kick: wind-up draws the leg back and twists the hips",
		wind.RHip[1] < -50 and math.abs(wind.Root[2]) > 15
	)
	egg:Destroy()
	-- merchants: no invented UserIds
	local MerchantConfig = require(SSS.Server.Data.MerchantConfig) :: any
	local merchantsOk = true
	for _, m in MerchantConfig do
		merchantsOk = merchantsOk and typeof(m.UserId) == "number" and typeof(m.DisplayName) == "string"
	end
	check("merchant config is well formed (UserIds come from the owner, 0 = not provided)", merchantsOk)
end)

section("Audio: no thunder on ordinary sounds, tiers, landings, contacts, the 10 scenarios", function()
	local Audio = require(Shared.Audio) :: any
	local B = require(Shared.Audio.SoundBank) :: any
	local SackSfx = require(Shared.VFX.SackSfx) :: any
	local Zones = require(Shared.Config.Zones) :: any
	local KickService = require(Services.KickService) :: any
	local BUILTIN = {}
	for _, n in
		{
			"action_falling.ogg",
			"action_footsteps_plastic.mp3",
			"action_get_up.mp3",
			"action_jump.mp3",
			"action_jump_land.mp3",
			"action_swim.mp3",
			"impact_explosion_03.mp3",
			"impact_water.mp3",
			"volume_slider.ogg",
		}
	do
		BUILTIN["rbxasset://sounds/" .. n] = true
	end
	local sourcesOk = true
	for _, src in B.Sources do
		sourcesOk = sourcesOk and BUILTIN[src.id] == true and src.gain > 0 and src.gain <= 12
	end
	check("audio: every source is a sound that ships with Roblox (no invented ids)", sourcesOk)
	check("audio: no custom ids configured yet", next(B.CUSTOM) == nil)

	local function hasBoom(layers): boolean
		for _, l in layers do
			if l.src == "boom" then
				return true
			end
		end
		return false
	end
	-- 1. thunder (the explosion) only for storms / electricity
	local eventsClean = true
	for name, def in B.Events do
		for _, variant in def.variants do
			if hasBoom(variant) then
				eventsClean = false
				warn("boom in " .. name)
			end
		end
	end
	check("audio: no event uses the thunder / explosion sound", eventsClean)
	local landingClean, stormy = true, false
	for surface in B.Surfaces do
		for _, i in { 0, 0.5, 1 } do
			for _, bounce in { false, true } do
				landingClean = landingClean and not hasBoom((B.landing(surface, i, bounce, nil)))
				for mutation in B.MutationAccent do
					local m = B.landing(surface, i, bounce, mutation)
					if mutation == "Stormy" then
						stormy = hasBoom(m)
					else
						landingClean = landingClean and not hasBoom(m)
					end
				end
			end
		end
	end
	check("audio: egg landings never thunder (any surface, speed, bounce, mutation but Stormy)", landingClean)
	check("audio: a Stormy egg may add a quiet far-off crack (storm = thunder is right)", stormy)
	local sacksClean, thunderSpecial = true, nil
	for tier = 1, 20 do
		for _, moment in { "equip", "impact", "upgrade", "idle" } do
			sacksClean = sacksClean and not hasBoom((SackSfx.layers(tier, moment)))
		end
		if hasBoom((SackSfx.layers(tier, "special"))) then
			thunderSpecial = if thunderSpecial == nil then tier else -1
		end
	end
	check("audio: no Kick Sack punch, drop or upgrade uses thunder", sacksClean)
	check("audio: only Thunder Cell's (electric) super hit cracks", thunderSpecial == 14)

	-- 2. every recipe fits its tier; the tiers really are a hierarchy
	local fits, uiFlat, spatialOk, categoriesOk = true, true, true, true
	local byTier = { {}, {}, {}, {} }
	for name, def in B.Events do
		for _, variant in def.variants do
			if B.tierFor(variant, def.tier) ~= def.tier then
				fits = false
				warn(`{name} does not fit tier {def.tier}`)
			end
			local length, _, sum = B.measure(variant)
			table.insert(byTier[def.tier], { length = length, sum = sum })
		end
		if def.category == "UI" then
			uiFlat = uiFlat and not def.spatial
		else
			spatialOk = spatialOk and def.spatial
		end
		categoriesOk = categoriesOk and table.find(B.Categories, def.category) ~= nil
	end
	check("audio: every event fits its tier's caps (length, layers, loudness)", fits)
	check("audio: every event is in a real category (SoundGroup)", categoriesOk)
	check("audio: UI sounds are 2D, world sounds are 3D", uiFlat and spatialOk)
	local means = {}
	for t = 1, 4 do
		local l, v = 0, 0
		for _, m in byTier[t] do
			l += m.length
			v += m.sum
		end
		means[t] = { length = l / math.max(1, #byTier[t]), sum = v / math.max(1, #byTier[t]) }
	end
	check(
		"audio: tier 1 < 2 < 3 < 4 in length and loudness",
		means[1].length < means[2].length
			and means[2].length < means[3].length
			and means[3].length < means[4].length
			and means[1].sum < means[2].sum
			and means[2].sum < means[3].sum
			and means[3].sum < means[4].sum
	)
	for _, name in { "UIClick", "EggStep", "HatchCrack", "MoneyChime" } do
		local def = B.Events[name]
		check(`audio: {name} (repeated often) has variations`, #def.variants >= 2 and (def.jitter or 0) > 0)
	end

	-- 3. landings: surface, speed, bounce, mutation
	check(
		"audio: a soft touch is silent",
		B.landingIntensity(3) == nil and B.landingIntensity(B.Landing.minSpeed) ~= nil
	)
	local _, _, soft = B.measure((B.landing("grass", 0.1, false, nil)))
	local _, _, hard = B.measure((B.landing("grass", 1, false, nil)))
	local bounceLayers, bounceTier = B.landing("grass", 0.5, true, nil)
	local landLayers = B.landing("grass", 0.5, false, nil)
	local bl, _, bs = B.measure(bounceLayers)
	local ll, _, ls = B.measure(landLayers)
	check("audio: a faster landing is louder", hard > soft)
	check("audio: a bounce is a short, lighter pop", bounceTier == 1 and bl <= ll and bs < ls)
	local _, hardTier = B.landing("stone", 1, false, nil)
	check("audio: even the hardest plain landing stays a tier 2 physical impact", hardTier <= 2)
	local void = B.landing("stone", 0.5, false, "Starfall")
	local fxCount = 0
	for _, l in void do
		fxCount += if l.fx then 1 else 0
	end
	check("audio: a cosmic (Starfall) egg adds a quiet resonance on top of the thump", fxCount >= 1 and fxCount < #void)
	check(
		"audio: surfaces follow the zone (plaza grass, Meadow grass, Volcano stone, Snowy Peaks snow)",
		B.surfaceAt(Vector3.new(0, 11, -20), Zones, Chase.SafeLineZ) == "grass"
			and B.surfaceAt(Vector3.new(0, 0, 50), Zones, Chase.SafeLineZ) == "grass"
			and B.surfaceAt(Vector3.new(0, 0, 850), Zones, Chase.SafeLineZ) == "stone"
			and B.surfaceAt(Vector3.new(0, 0, 550), Zones, Chase.SafeLineZ) == "snow"
	)

	-- 4. contacts come from the egg's velocity, with a minimum speed and a cooldown (never from Touched)
	local function run(samples: { number }, dt: number): { string }
		local st, out, t = B.newContact(), {}, 0
		for _, vy in samples do
			t += dt
			local kind = B.contactStep(st, dt, vy, t)
			if kind then
				table.insert(out, kind)
			end
		end
		return out
	end
	local fall = {}
	for _ = 1, 30 do
		table.insert(fall, -30)
	end
	for _ = 1, 10 do
		table.insert(fall, 0)
	end
	local fallKinds = run(fall, 1 / 60)
	check("audio: a long fall that stops = one landing", #fallKinds == 1 and fallKinds[1] == "land")
	check("audio: contact chatter can't stack sounds (cooldown)", #run({ -12, 0, -12, 0, -12, 0, -12, 0 }, 1 / 60) <= 1)
	local slope = {}
	for _ = 1, 60 do
		table.insert(slope, -3)
	end
	check("audio: running down a slope makes no impact sounds", #run(slope, 1 / 60) == 0)
	local bounceKinds = run({ -20, -24, 12, 6, 0, -6, -12, -14, 0, 0 }, 1 / 20) -- hits, flies up, lands again
	check(
		"audio: a contact that flies back up = a bounce, the one that stays = the landing",
		#bounceKinds == 2 and bounceKinds[1] == "bounce" and bounceKinds[2] == "land"
	)

	-- 5. kicks: the server's timing band picks the sound
	check(
		"audio: kick band from the timing",
		KickService.band(0.95) == "perfect" and KickService.band(0.7) == "good" and KickService.band(0.2) == "weak"
	)
	local hasWhoosh, hasFx, hasImpact = false, false, false
	for _, l in B.Events[B.kickEvent("perfect")].variants[1] do
		hasWhoosh = hasWhoosh or l.src == "wind"
		hasFx = hasFx or l.fx == true
		hasImpact = hasImpact or l.src == "thump"
	end
	check("audio: Perfect Kick = whoosh + punchy impact + bright flourish", hasWhoosh and hasImpact and hasFx)
	local goodFx = false
	for _, l in B.Events[B.kickEvent("good")].variants[1] do
		goodFx = goodFx or l.fx == true
	end
	check(
		"audio: a normal kick is a controlled physical impact (no flourish)",
		not goodFx and B.Events.KickGood.tier == 2
	)

	-- 6. the 10 required scenarios
	local function physical(layers): boolean
		for _, l in layers do
			if l.src == "thump" or string.sub(l.src, 1, 3) == "tap" then
				return true
			end
		end
		return false
	end
	local grass, grassTier = B.landing("grass", 0.2, false, nil)
	local stone = B.landing("stone", 0.6, false, nil)
	local bounce = B.landing("grass", 0.4, true, nil)
	local basic, basicTier = SackSfx.layers(1, "impact")
	local premium = SackSfx.layers(20, "impact")
	local premiumFx, basicFx = 0, false
	for _, l in premium do
		premiumFx += if l.fx then 1 else 0
	end
	for _, l in basic do
		basicFx = basicFx or l.fx == true
	end
	check("scenario 1: a gentle drop on grass = a soft tier 1 thump", grassTier == 1 and grass[1].src == "thump")
	check("scenario 2: a drop on stone = a short solid tap", stone[1].src == "tap3" and (B.measure(stone)) < 0.5)
	check("scenario 3: bounces = short pops", (B.measure(bounce)) < 0.4)
	check(
		"scenario 4: the running egg = very quiet steps",
		B.Events.EggStep.tier == 1 and B.Events.EggStep.variants[1][1].volume <= 0.1
	)
	check("scenario 5: a normal kick = KickGood", B.kickEvent("good") == "KickGood")
	check("scenario 6: a Perfect Kick = KickPerfect (tier 3)", B.Events.KickPerfect.tier == 3)
	check(
		"scenario 7: a basic sack punch = a dry tier 1 thud, no magic",
		basicTier == 1 and not basicFx and physical(basic)
	)
	check(
		"scenario 8: a premium sack punch = physical hit + short sparkle",
		physical(premium) and premiumFx >= 1 and premiumFx <= 3
	)
	check(
		"scenario 9: a Common hatch = crack + pop (tier 2)",
		B.hatchEvent("Common") == "HatchCommon" and B.Events.HatchCommon.tier == 2
	)
	check(
		"scenario 10: a Secret hatch = the spectacular one (tier 4)",
		B.hatchEvent("Secret") == "HatchSecret" and B.Events.HatchSecret.tier == 4
	)
	check("audio: an unknown event is ignored", Audio.play("NoSuchSound") == false)
end)

section("every service loads", function()
	for _, module in Services:GetChildren() do
		if module:IsA("ModuleScript") then
			require(module)
		end
	end
	check("services require", true)
end)

print(`[Tests] {passed} passed, {failed} failed`)
if failed > 0 then
	error(`{failed} test(s) failed`)
end
