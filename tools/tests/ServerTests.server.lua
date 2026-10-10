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
	check("strength capped", SS.trained(Economy.maxKickPower(0), #levels, 0) == Economy.maxKickPower(0))
	check("rebirth raises the cap", SS.trained(Economy.maxKickPower(0), 1, 1) > Economy.maxKickPower(0))
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
	check("pen 1 = base slots", PS.slotsForPen(1) == Economy.PlotSlots.base)
	check("pen 2 adds slots", PS.slotsForPen(2) == Economy.PlotSlots.base + Upgrades.Pen.slotsPerLevel)
	check("pen slots capped", PS.slotsForPen(99) == Economy.PlotSlots.max)
	check("pen 1 -> 2 cost", RS.penCost(1) == Upgrades.Pen.costBase)
	check("pen 2 -> 3 cost", RS.penCost(2) == Upgrades.Pen.costBase * Upgrades.Pen.costGrowth)
	check("no pen upgrade at max slots", RS.penCost(99) == nil)
	local top = Instance.new("Part")
	top.Size = Vector3.new(2.8, 0.3, 2.8)
	top.Position = Vector3.new(10, 1.35, -30)
	check("standing on the pedestal collects", PS.onPedestal(top, Vector3.new(11, 4, -30)))
	check("next to the pedestal doesn't", not PS.onPedestal(top, Vector3.new(16, 4, -30)))
	top:Destroy()
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
	check("fractional strength kept", d.kickPower == 3.25)
	check("sack tier clamped", d.rackLevel == #levels)
	check("NaN pen level -> 1", d.penLevel == 1)
	check("old tool field dropped", d.tool == nil)
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
