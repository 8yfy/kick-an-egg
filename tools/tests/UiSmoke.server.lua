-- Headless smoke test for the client UI system (UI/System, UI/Screens, the new HUD rails):
--   sh tools/run-tests.sh tools/tests/UiSmoke.server.lua
-- There is no LocalPlayer here, so this only proves every screen/drawer builds, opens, refreshes, swaps
-- and closes against realistic PlayerData without a Luau error (looks are checked in Studio Play).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")
local ServerStorage = game:GetService("ServerStorage")

local passed, failed = 0, 0
local errors = {}
ScriptContext.Error:Connect(function(message, trace)
	table.insert(errors, message .. "\n" .. trace)
end)
local function check(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed += 1
	else
		failed += 1
		print("FAIL " .. name .. ": " .. tostring(err))
	end
end

require(ReplicatedStorage.Shared.Remotes) -- creates the remotes folder (server side)

local UI = game.StarterPlayer.StarterPlayerScripts.Client.UI
local Data = require(UI.System.Data)
local Modal = require(UI.System.Modal)
local AssetIds = require(UI.System.AssetIds)

local playerGui = Instance.new("Folder")
playerGui.Name = "FakePlayerGui"
playerGui.Parent = ServerStorage
local hud = Instance.new("ScreenGui")
hud.Name = "HUD"
hud.Parent = playerGui

check("modal init", function()
	Modal.init(playerGui)
end)
for _, name in { "TrainingShop", "Shop", "PetIndex", "PetInventory", "Rebirth" } do
	check("define " .. name, function()
		require(UI.Screens[name]).define()
	end)
end

local rail, counters, drawers
check("hud", function()
	rail = require(UI.Hud.Rail).new(hud)
	counters = require(UI.Hud.Counters).new(hud)
	drawers = require(UI.Hud.Drawers).new(hud)
end)
Data.onChanged(function()
	rail.update()
	counters.update()
	drawers.update()
	Modal.refresh()
end)

local now = workspace:GetServerTimeNow()
Data.apply({
	money = 5000,
	kickPower = 42.3,
	runSpeed = 20,
	rebirths = 1,
	rackLevel = 3,
	penLevel = 2,
	plots = {
		["1"] = { uid = "e1", petId = "sprout_pup", placedAt = now - 5, hatchAt = now + 20 },
		["2"] = { uid = "e2", petId = "bumble_bloc", placedAt = now - 30, hatchAt = now - 1 },
	},
	eggs = { { uid = "e3", petId = "meadow_stag" } },
	pets = {
		p1 = { petId = "sprout_pup", slot = 3, size = "Big" },
		p2 = { petId = "meadow_stag", weather = "Sunny" },
		p3 = { petId = "not_a_pet" },
	},
	discovered = { sprout_pup = true },
	indexClaims = {},
})
task.wait(0.2)

check("data views", function()
	assert(#Data.sacks() == 20, "20 sacks")
	assert(Data.sacks()[3].state == "Equipped" and Data.sacks()[4].state == "Buy", "sack states")
	assert(Data.sacks()[2].state == "Owned" and Data.sacks()[5].state == "Locked", "sack states 2")
	assert(Data.speed().cost ~= nil, "speed cost")
	assert(Data.pen().slots == 10, "pen slots")
	assert(Data.rebirth().ready == false and Data.rebirth().available, "rebirth")
	assert(#Data.eggs() == 3 and Data.eggs()[3].slot == nil, "eggs")
	assert(#Data.pets() == 3, "pets")
	local cap = Data.capacity()
	assert(cap.eggs == 2 and cap.pets == 1 and cap.waitingEggs == 1 and cap.unplacedPets == 2, "capacity")
	assert(#Data.index() > 0 and Data.claimableZones() == 0, "index")
	assert(#Data.products() == 3 and not Data.products()[1].configured, "products")
end)

check("asset registry binds every sack and zone", function()
	local Upgrades = require(ReplicatedStorage.Shared.Config.Upgrades)
	local Zones = require(ReplicatedStorage.Shared.Config.Zones)
	for _, tier in Upgrades.Sack.tiers do
		local key = AssetIds.sack(tier.name)
		assert(key and AssetIds.source(key), "no sack art for " .. tier.name)
	end
	for _, zone in Zones do
		local key = AssetIds.zone(zone.id)
		assert(key and AssetIds.source(key), "no zone art for " .. zone.name)
	end
	assert(#AssetIds.keys() == 59, "59 supplied PNGs, got " .. #AssetIds.keys())
end)

for _, name in { "Training", "Shop", "Index", "Inventory", "Rebirth" } do
	check("open " .. name, function()
		Modal.open(name)
	end)
	task.wait(0.4)
	check("refresh " .. name, function()
		Modal.refresh()
		Data.apply({ money = 6000 })
	end)
	task.wait(0.4)
	check("close " .. name, function()
		Modal.close()
	end)
	task.wait(0.25)
end

check("rapid swaps", function()
	Modal.open("Training")
	Modal.open("Index")
	Modal.close()
	Modal.open("Rebirth")
	Modal.toggle("Rebirth")
	Modal.toggle("Shop")
	Modal.close()
	Modal.close()
end)
task.wait(0.5)
assert(Modal.current() == nil, "a modal is still open after rapid swaps")

check("drawers", function()
	drawers.open("Eggs")
	drawers.update()
	drawers.open("Pets")
	drawers.update()
	drawers.hatched("Sprout Pup")
	drawers.open(nil)
end)
task.wait(0.6)

check("rebirth ready + data churn", function()
	Data.apply({ kickPower = 125, money = 1e6, rackLevel = 20, runSpeed = 40, penLevel = 7 })
	Modal.open("Rebirth")
	Modal.open("Training")
	Data.apply({ pets = {}, plots = {}, eggs = {} })
	Modal.open("Inventory")
	Modal.close()
end)
task.wait(0.6)

check("toasts capped at 3", function()
	for i = 1, 5 do
		Modal.toast("Toast " .. i, "info")
	end
	local n = 0
	for _, t in playerGui.Modals.Toasts:GetChildren() do
		if t.Name == "Toast" then
			n += 1
		end
	end
	assert(n == 3, "toast count " .. n)
end)
task.wait(1.5) -- let the lazy 3D art builder run over the opened screens

check("lazy 3D art built", function()
	local viewports = 0
	for _, d in playerGui.Modals:GetDescendants() do
		if d:IsA("ViewportFrame") and d:FindFirstChildWhichIsA("Model") then
			viewports += 1
		end
	end
	print("viewports with models:", viewports)
	assert(viewports > 0, "no 3D art was built")
end)

print(
	("UI smoke: %d passed, %d failed, %d runtime errors, %d handoff images missing"):format(
		passed,
		failed,
		#errors,
		#AssetIds.missing()
	)
)
for i, e in errors do
	if i <= 8 then
		print("ERROR " .. e)
	end
end
