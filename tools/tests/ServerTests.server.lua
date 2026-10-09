--!strict
-- Headless server tests (Partner B). Run from the repo root with Studio installed:
--   sh tools/run-tests.sh            (or: tools/run-tests.sh tools/tests/Balance.server.lua)
-- Uses run-in-roblox, which runs this script inside Studio as a plugin: services are required
-- directly (their Init/Start don't run), so only pure logic is tested here.

local SSS = game:GetService("ServerScriptService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Services = SSS.Server.Services

local Chase = require(Shared.Config.Chase) :: any
local Economy = require(Shared.Config.Economy) :: any

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

section("ChaseService.decide", function()
	local CS = require(Services.ChaseService) :: any
	local function mk(landZ: number, zone: number)
		return {
			landPos = Vector3.new(5, 0, landZ),
			startZ = landZ + Chase.Avalanche.spawnBehindLanding,
			startTime = Chase.Avalanche.warnSeconds,
			speed = Chase.avalancheSpeed(zone),
			eggRunStart = Chase.Egg.runDelay,
			pickedUp = false,
			resolved = false,
			flags = 0,
		}
	end
	local base = Vector3.new(0, 3, -20)
	for _, z in { 50, 600, 2300 } do
		local c, out, t = mk(z, math.floor(z / 120) + 1), nil, 0
		while not out and t < 600 do
			t += 0.1
			out = CS.decide(c, t, base)
		end
		check(`EggCaught z={z}`, out == "EggCaught")
	end
	check("egg clamps at the safe line", CS.eggZ(mk(30, 1), 1000) == Chase.SafeLineZ)
	local c, out, t = mk(300, 3), nil, 0
	while not out and t < 600 do
		t += 0.1
		out = CS.decide(c, t, Vector3.new(0, 3, 400))
	end
	check("Caught in the field", out == "Caught")
	c, out, t = mk(200, 2), nil, 1
	c.pickedUp = true
	while not out and t < 600 do
		t += 0.1
		out = CS.decide(c, t, Vector3.new(0, 3, 200 - 16 * 0.92 * (t - 1)))
	end
	check("Secured", out == "Secured")
	c.resolved, out = true, nil
	while not out and t < 600 do
		t += 0.1
		out = CS.decide(c, t, base)
	end
	check("Ended after secure", out == "Ended")
	local safe = mk(30, 1)
	safe.pickedUp = true
	check("safe behind the line", CS.decide(safe, 2, Vector3.new(0, 3, -8)) ~= "Caught")
	check("no body = Caught", CS.decide(mk(500, 5), 0, nil) == "Caught")
	check("walking is plausible", CS.plausible(Vector3.zero, 0, Vector3.new(0, 0, 2), 0.1, 16))
	check("teleport rejected", not CS.plausible(Vector3.zero, 0, Vector3.new(0, 0, 300), 0.1, 16))
	check("teleport plausible later", CS.plausible(Vector3.zero, 0, Vector3.new(0, 0, 300), 9, 16))
	check("falling ignored", CS.plausible(Vector3.zero, 0, Vector3.new(0, -200, 0), 0.1, 16))
	local behind = ((Chase :: any).Launch or { behindLanding = 12 }).behindLanding
	local drop = CS.launchPosition(Vector3.new(5, 2, 600))
	check("launch lands behind the egg", drop.X == 5 and drop.Z == 600 - behind and drop.Y > 2)
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
	check("KickPower cost 1", Economy.upgradeCost("KickPower", 1) == 25)
	check("KickPower cost 2", Economy.upgradeCost("KickPower", 2) == 29)
	check("RunSpeed cost 17", Economy.upgradeCost("RunSpeed", 17) == 62)
	check("power cap after 2 rebirths", Economy.maxKickPower(2) == 150)
end)

section("TradeService", function()
	local T = require(Services.TradeService) :: any
	local a = { p1 = { petId = "sprout_pup", slot = 1 }, p2 = { petId = "bumble_bloc", slot = 2 } }
	local b = { q1 = { petId = "meadow_stag", slot = 1 } }
	local na, nb = T.swap(a, b, { "p1" }, { "q1" })
	check("A receives q1 unplaced", na and na.q1 and na.q1.slot == nil and na.p1 == nil and na.p2.slot == 2)
	check("B receives p1 unplaced", nb and nb.p1 and nb.p1.slot == nil and nb.q1 == nil)
	check("inputs untouched", a.p1.slot == 1 and b.q1 ~= nil)
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
		kickPower = 1e9,
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
	check("kickPower capped", d.kickPower == 150)
	check("runSpeed raised", d.runSpeed == 16)
	check("eggs restored", typeof(d.eggs) == "table")
	check("onboarding reset", d.onboarding == 0)
	check("plotSlots cleared", d.plotSlots == nil)
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
