-- DEV ONLY: renders the real UI screens in Studio's viewport (CoreGui) at a pinned stage size so they can be
-- screenshotted and compared with the UI handoff mockups. Run through tools/preview/preview.sh, which sets
-- SCREEN / STAGE below, launches Studio headless-style with run-in-roblox and captures the window.
-- Data shown is a DESIGN FIXTURE (fake balances / pets), clearly not game data.
local SCREEN = "Training" -- Training | Shop | Index | Inventory | Rebirth | HUD | Eggs | Pets | Proof | Proof2 | Showcase | GameSacks | Showroom | Heroes | Kick | SackShop
local STAGE = "desktop" -- desktop (1600x900) | phone (844x390)
local HOLD = 30
local FROM = 1 -- first sack tier for Showcase / GameSacks (five in a row); Heroes: 1 = eggs, 2 = pets, 3 = both, 10 + n = pair n close-up; Kick: 1 idle, 2 timing, 3 Perfect, 4 Great, 5 Miss
local STANDIN = true -- build GLB stand-ins (needs the KTE_Dev folder: preview.sh with STANDIN=1)
local PROFILE = "HIGH" -- Kick Sack VFX quality profile for the 3D sack modes (VFX/SackLod; preview.sh PROFILE=...)
local CAMERA: CFrame? = nil -- 3D modes: the shot (re-applied every frame)

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.Remotes) -- server-side remotes folder so screens can require it
local UI = game.StarterPlayer.StarterPlayerScripts.Client.UI
local Data = require(UI.System.Data)
local Modal = require(UI.System.Modal)
local Kit = require(UI.Kit)

local size = if STAGE == "phone" then Vector2.new(844, 390) else Vector2.new(1600, 900)
local touch = STAGE == "phone"

local old = CoreGui:FindFirstChild("KTE_Preview")
if old then
	old:Destroy()
end
local gui = Instance.new("ScreenGui")
gui.Name = "KTE_Preview"
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui
local stage = Instance.new("Frame")
stage.Name = "Stage"
stage.Size = UDim2.fromOffset(size.X, size.Y)
stage.ClipsDescendants = true
stage.BorderSizePixel = 0
stage.BackgroundColor3 = Color3.new(1, 1, 1)
local bg = Instance.new("UIGradient")
bg.Rotation = 90
bg.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 200, 255)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(150, 220, 255)),
	ColorSequenceKeypoint.new(0.46, Color3.fromRGB(96, 196, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 150, 40)),
})
bg.Parent = stage
stage.Parent = gui

-- Design fixture (not game data).
local now = workspace:GetServerTimeNow()
Data.apply({
	money = 125400,
	kickPower = 42.3,
	runSpeed = 20,
	rebirths = 1,
	rackLevel = 1,
	penLevel = 2,
	plots = {
		["1"] = { uid = "e1", petId = "sprout_pup", placedAt = now - 40, hatchAt = now + 154 },
		["2"] = { uid = "e2", petId = "bumble_bloc", placedAt = now - 30, hatchAt = now - 1 },
	},
	eggs = {},
	pets = {
		p1 = { petId = "sprout_pup", slot = 3, size = "Big" },
		p2 = { petId = "meadow_stag", slot = 4, weather = "Sunny" },
		p3 = { petId = "bumble_bloc" },
		p4 = { petId = "shelly_turtle" },
		p5 = { petId = "gull_bloc", slot = 5 },
	},
	discovered = { sprout_pup = true, bumble_bloc = true, meadow_stag = true, shelly_turtle = true },
	indexClaims = {},
})

if SCREEN == "ShopFixture" then
	-- DESIGN FIXTURE for layout review only (ribboned "not for sale"); the real game shows Economy.DevProducts.
	local hex = Color3.fromHex
	require(UI.Screens.Shop).fixture({
		{
			key = "FixturePower",
			id = 0,
			title1 = "POWER",
			title2 = "BOOST",
			benefit = "Fixture copy: 15 minutes",
			backdrop = "banners_power_background",
			hero = "premium_icons_power_sneaker",
			accent = { hex("FF8BF0"), hex("C43CFF") },
			fixture = true,
		},
		{
			key = "FixtureCash",
			id = 0,
			money = 15000,
			title1 = "CASH",
			title2 = "PACK",
			benefit = "Fixture copy: +$15K cash",
			backdrop = "banners_cash_background",
			hero = "premium_icons_currency_cash",
			accent = { hex("C8FF4A"), hex("3FD81A") },
			fixture = true,
		},
		{
			key = "FixtureHatch",
			id = 0,
			title1 = "HATCH",
			title2 = "BOOST",
			benefit = "Fixture copy: faster hatching",
			backdrop = "banners_hatch_background",
			hero = "premium_icons_nav_eggs",
			accent = { hex("FFF06A"), hex("FFB000") },
			fixture = true,
		},
		{
			key = "FixtureMore",
			id = 0,
			title1 = "MORE",
			title2 = "BOOSTS",
			benefit = "Fixture copy",
			backdrop = "banners_power_background",
			hero = "premium_icons_power_sneaker",
			accent = { hex("FFFFFF"), hex("C9C9FF") },
			fixture = true,
		},
	})
	SCREEN = "Shop"
end

Modal.init(stage, { viewport = size, touch = touch })
for _, name in { "TrainingShop", "Shop", "PetIndex", "PetInventory", "Rebirth" } do
	local ok, err = pcall(function()
		require(UI.Screens[name]).define()
	end)
	if not ok then
		warn("define", name, err)
	end
end

if SCREEN == "Settings" then -- the Settings window (FROM 1 = top, 2 = scrolled to the bottom)
	Kit.setPreview(size, touch)
	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.BackgroundTransparency = 1
	hud.Size = UDim2.fromScale(1, 1)
	hud.Parent = stage
	local menus = require(UI.Menus).new(hud, { tiles = false })
	Kit.watchViewport()
	menus.open("Settings")
	task.delay(1.2, function()
		local rows = hud:FindFirstChild("Rows", true) :: ScrollingFrame?
		if rows and FROM == 2 then
			rows.CanvasPosition = Vector2.new(0, rows.AbsoluteCanvasSize.Y)
		end
		if rows then
			local last, inside = nil, true
			for _, row in rows:GetChildren() do
				if row:IsA("GuiObject") and (not last or row.LayoutOrder > last.LayoutOrder) then
					last = row
				end
			end
			print(
				string.format(
					"SETTINGS rows=%d canvas=%d window=%d last=%s",
					#rows:GetChildren(),
					rows.AbsoluteCanvasSize.Y,
					rows.AbsoluteSize.Y,
					last and last.Name or "?"
				)
			)
		end
	end)
elseif SCREEN == "HUD" or SCREEN == "Eggs" or SCREEN == "Pets" or SCREEN == "Kick" then
	Kit.setPreview(size, touch)
	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.BackgroundTransparency = 1
	hud.Size = UDim2.fromScale(1, 1)
	hud.Parent = stage
	local quest = require(UI.Hud.QuestBar).new(hud)
	quest.update(Data.state)
	local rail = require(UI.Hud.Rail).new(hud)
	local counters = require(UI.Hud.Counters).new(hud)
	local drawers = require(UI.Hud.Drawers).new(hud)
	-- settings + sound (top right), the zone progress bar (pinned to a zone) and the contextual kick controls:
	-- on the HUD screen as on the kick pad (idle), on the Kick screen in the state FROM picks
	if not pcall(require(UI.Menus).new, hud, { tiles = false }) then
		-- A's Settings window needs a LocalPlayer: draw just its gear button like Menus does
		local gear = Kit.panel({ name = "SettingsButton", size = UDim2.fromOffset(58, 58), parent = hud })
		Kit.autoScale(gear)
		Kit.onLayout(function(compact: boolean)
			gear.AnchorPoint = Vector2.new(1, if compact then 0.5 else 0)
			gear.Size = if compact then UDim2.fromOffset(96, 96) else UDim2.fromOffset(58, 58)
			gear.Position = if compact then UDim2.new(1, -10, 0.5, 30) else UDim2.new(1, -96, 0, 22)
		end)
		local gb = Kit.roundButton(gear, "Button", function() end)
		local art = require(UI.System.Ui).art(gb, "hud_settings", UDim2.fromScale(0.86, 0.86))
		art.Position = UDim2.fromScale(0.07, 0.07)
		art.ZIndex = 3
		require(UI.System.IconMotion).attach(art, "settings")
	end
	require(UI.Hud.SoundToggle).new(hud)
	local zone = require(UI.Hud.ZoneProgress).new(hud)
	Modal.setToastAnchor(hud:FindFirstChild("ZoneProgress"))
	zone.pin(if SCREEN == "Kick" then 9 else 6, if SCREEN == "Kick" then 0.15 else 0.55)
	local kick = require(UI.Hud.KickPanel).new(hud)
	local kickModes = { "idle", "timing", "result", "result", "result" }
	local kickLevels = { 0.5, 0.72, 0.95, 0.75, 0.1 }
	local k = if SCREEN == "Kick" then math.clamp(FROM, 1, 5) else 1
	task.delay(1, function()
		kick.pin(kickModes[k] :: any, kickLevels[k])
	end)
	Kit.watchViewport()
	rail.update()
	counters.update()
	drawers.update()
	if SCREEN == "HUD" then -- keep one toast on screen to check the toast lane sits below the quest bar
		task.spawn(function()
			for _ = 1, 20 do
				Modal.toast("Sprout Pup hatched!", "good")
				task.wait(2)
			end
		end)
	end
	if SCREEN == "Eggs" or SCREEN == "Pets" then
		drawers.open(SCREEN)
	end
elseif SCREEN == "Showcase" or SCREEN == "GameSacks" or SCREEN == "Showroom" then
	-- 3D sack renders (Kick Sacks package check): GLB stand-ins built from the original GLBs (tools/sacks/StandIn),
	-- five tiers FROM..FROM+4 in a row, far from the map. Showcase = package SackModel + SackVFX (10 studs/m);
	-- GameSacks = the game's Builders/SackGeometry + VFX/SackAura (6.5 studs/m, front -Z).
	stage.BackgroundTransparency = 1
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.ClipsDescendants = false
	local ServerStorage = game:GetService("ServerStorage")
	local dev = ServerStorage:FindFirstChild("KTE_Dev")
	local tiers = {}
	for t = FROM, math.min(20, FROM + 4) do
		table.insert(tiers, t)
	end
	if dev and STANDIN then
		local t0 = os.clock()
		print("STANDIN built", require(dev.StandIn).install(dev.Data, tiers), "models in", os.clock() - t0, "s")
	end
	local origin = Vector3.new(3000, 100, 0)
	local floor = Instance.new("Part")
	floor.Name = "PreviewFloor"
	floor.Anchored = true
	floor.Size = Vector3.new(300, 1, 300)
	floor.Position = origin - Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(70, 74, 88)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
	local wall = floor:Clone()
	wall.Size = Vector3.new(300, 160, 1)
	wall.Position = origin + Vector3.new(0, 80, -40)
	wall.Color = Color3.fromRGB(38, 41, 56)
	wall.Parent = workspace
	local folder = Instance.new("Folder")
	folder.Name = "SackPreview"
	folder.Parent = workspace
	local spacing = if SCREEN == "Showcase" then 13 else 9
	local cam = workspace.CurrentCamera
	if SCREEN == "Showroom" then
		-- the one-at-a-time showroom panel + sack FROM (UI/Dev/SackShowroom), game view, effects on
		local showroom = require(UI.Dev.SackShowroom).new(stage, false)
		showroom.open(CFrame.lookAt(origin, origin + Vector3.new(0, 0, 1)))
		showroom.show(FROM)
		CAMERA = CFrame.lookAt(origin + Vector3.new(0, 7.5, 30), origin + Vector3.new(0, 4, 0))
	elseif SCREEN == "Showcase" then
		local SackModel = require(ReplicatedStorage.SackModules.SackModel)
		local SackVFX = require(ReplicatedStorage.SackModules.SackVFX)
		for i, tier in tiers do
			local where = CFrame.new(origin + Vector3.new((i - 3) * spacing, 0.6, 0))
			local ok, model = pcall(
				SackModel.Build,
				tier,
				folder,
				where,
				{ RequireGLB = STANDIN, AutoScale = true, ForceOriginalColors = true, Anchored = true }
			)
			if ok then
				print("SHOWCASE", tier, model:GetAttribute("GeometrySource"), model:GetAttribute("MatchedGLBMaterials"))
				SackVFX.Attach(model, tier, { Quality = 1 })
			else
				warn("SHOWCASE", tier, model)
			end
		end
		CAMERA = CFrame.lookAt(origin + Vector3.new(0, 10, 44), origin + Vector3.new(0, 8, 0))
	else
		local SackGeometry = require(ReplicatedStorage.Shared.Builders.SackGeometry)
		local Sacks = require(ReplicatedStorage.Shared.Builders.Models.Sacks)
		local SackAura = require(ReplicatedStorage.Shared.VFX.SackAura)
		local lod = ReplicatedStorage.Shared.VFX:FindFirstChild("SackLod")
		if lod then
			(require(lod) :: any).override = PROFILE -- the shot shows a known profile, not Studio's frame rate
		end
		for i, tier in tiers do
			local model, source = SackGeometry.build(tier)
			-- hub at HANG above the floor, front (-Z) turned to the camera
			local at = CFrame.new(origin + Vector3.new((i - 3) * spacing, Sacks.HANG, 0)) * CFrame.Angles(0, math.pi, 0)
			model:PivotTo(at)
			for _, d in model:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				end
			end
			model.Parent = folder
			print("GAMESACK", tier, source, model:GetAttribute("MatchedGLBMaterials"))
			pcall(SackAura.Apply, model, tier, at * Sacks.vfxRoot(tier), Sacks.SCALE, false)
		end
		CAMERA = CFrame.lookAt(origin + Vector3.new(0, 6.5, 30), origin + Vector3.new(0, 5, 0))
	end
elseif SCREEN == "SackShop" then
	-- the physical Boxing Sack Shop in the real map (FROM 1 = outside, 2 = inside at the counter), with the
	-- display sacks' idle VFX as clients show them (MapLife -> SackAura)
	stage.BackgroundTransparency = 1
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.ClipsDescendants = false
	local MapBuilder = require(ReplicatedStorage.Shared.Builders.Map.MapBuilder)
	local Sacks = require(ReplicatedStorage.Shared.Builders.Models.Sacks)
	local SackAura = require(ReplicatedStorage.Shared.VFX.SackAura)
	local map = workspace:FindFirstChild("Map") or MapBuilder.build()
	local shop = map:FindFirstChild("BoxingSackShop", true) :: Model
	for _, d in shop:GetDescendants() do
		if d:IsA("Model") and d.Name == "Sack" then
			local tier = d:GetAttribute("Tier") :: number
			pcall(SackAura.Apply, d, tier, d:GetPivot() * Sacks.vfxRoot(tier), Sacks.SCALE, false)
		end
	end
	local bcf, bsize = shop:GetBoundingBox()
	local sign = shop:FindFirstChild("Sign") :: BasePart
	local counter = shop:FindFirstChild("Counter") :: BasePart
	print("SHOP bbox", bcf.Position, bsize, "sign", sign.Position, "counter", counter.Position)
	CAMERA = if FROM == 2
		then CFrame.lookAt(counter.Position + Vector3.new(7, 6, 7), counter.Position + Vector3.new(-2, 3, -9))
		else CFrame.lookAt(sign.Position + Vector3.new(-12, -9, 34), sign.Position + Vector3.new(0, -9, -4))
elseif SCREEN == "Heroes" then
	-- the 7 hero egg/pet pairs of the 79-pair art plan (docs/EggPetPlan.md), Common -> Secret, with their effects
	stage.BackgroundTransparency = 1
	stage.AnchorPoint = Vector2.new(0.5, 0.5)
	stage.Position = UDim2.fromScale(0.5, 0.5)
	stage.ClipsDescendants = false
	local Models = require(ReplicatedStorage.Shared.Builders.Models)
	local okFx, PetFx = pcall(require, ReplicatedStorage.Shared.VFX:FindFirstChild("PetFx") or Instance.new("Folder"))
	local origin = Vector3.new(3000, 100, 0)
	local floor = Instance.new("Part")
	floor.Name = "PreviewFloor"
	floor.Anchored = true
	floor.Size = Vector3.new(400, 1, 300)
	floor.Position = origin - Vector3.new(0, 0.5, 0)
	floor.Color = Color3.fromRGB(70, 74, 88)
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
	local wall = floor:Clone()
	wall.Size = Vector3.new(400, 160, 1)
	wall.Position = origin + Vector3.new(0, 80, -40)
	wall.Color = Color3.fromRGB(38, 41, 56)
	wall.Parent = workspace
	local folder = Instance.new("Folder")
	folder.Name = "HeroPreview"
	folder.Parent = workspace
	local heroes =
		{ "SproutPup", "MeadowStag", "TideSpirit", "IceDragon", "QuetzalPhoenix", "ClockworkTitan", "PrismSeraph" }
	local spacing = if FROM == 1 then 7.5 else 11
	local function place(model: Model, at: Vector3, kind: string, key: string, yaw: number?)
		local _, size = model:GetBoundingBox()
		-- models face -Z: turn them to the camera (plus a 3/4 yaw in close-ups)
		model:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.pi + math.rad(yaw or 0), 0))
		-- the Root is at the feet (BlockBuilder convention), so floaters hover as they do on a pedestal
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		model.Parent = folder
		local parts = 0
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
			end
		end
		local fx = if okFx and type(PetFx) == "table" then PetFx.attach(model, kind, key, { Quality = 1 }) else nil
		print(
			"HERO",
			kind,
			key,
			"parts",
			parts,
			string.format("size %.1f x %.1f x %.1f", size.X, size.Y, size.Z),
			"fx",
			fx ~= nil
		)
	end
	if FROM > 10 then -- one pair close-up: egg left, pet right
		local key = heroes[FROM - 10]
		local pet = Models.pet(key)
		local _, size = pet:GetBoundingBox()
		place(Models.egg(key), origin + Vector3.new(-size.X / 2 - 3.5, 0, 0), "egg", key, 20)
		place(pet, origin + Vector3.new(2, 0, 0), "pet", key, -32)
		local h = math.max(size.Y, 5)
		CAMERA = CFrame.lookAt(origin + Vector3.new(-1, h * 0.75, h * 1.9 + 6), origin + Vector3.new(-1, h * 0.42, 0))
		heroes = {}
	end
	for i, key in heroes do
		local x = (i - 4) * spacing
		if FROM == 1 or FROM == 3 then
			place(Models.egg(key), origin + Vector3.new(x, 0, if FROM == 3 then -12 else 0), "egg", key)
		end
		if FROM == 2 or FROM == 3 then
			place(Models.pet(key), origin + Vector3.new(x, 0, 0), "pet", key)
		end
	end
	if FROM <= 10 then
		CAMERA = if FROM == 1
			then CFrame.lookAt(origin + Vector3.new(0, 7, 31), origin + Vector3.new(0, 3, 0))
			else CFrame.lookAt(origin + Vector3.new(0, 11, 48), origin + Vector3.new(0, 5, 0))
	end
elseif SCREEN == "Proof" or SCREEN == "Proof2" then
	-- Asset-proof view: the supplied PNGs as plain ImageLabels (Fit, white tint), each with its name + key.
	local AssetIds = require(UI.System.AssetIds)
	local Upgrades = require(ReplicatedStorage.Shared.Config.Upgrades)
	local function cell(parent, key, label, w, h, crop)
		local f = Instance.new("Frame")
		f.Size = UDim2.fromOffset(w, h)
		f.BackgroundColor3 = Color3.fromRGB(38, 41, 56)
		f.BorderSizePixel = 0
		f.Parent = parent
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.new(1, -8, 1, -44)
		img.Position = UDim2.fromOffset(4, 4)
		img.ScaleType = if crop then Enum.ScaleType.Crop else Enum.ScaleType.Fit
		img.ImageColor3 = Color3.new(1, 1, 1)
		img.Image = AssetIds.get(key) or ""
		img.Parent = f
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, -4, 0, 40)
		t.Position = UDim2.new(0, 2, 1, -42)
		t.Font = Enum.Font.FredokaOne
		t.TextSize = 15
		t.TextWrapped = true
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = label .. "\n" .. key
		t.Parent = f
	end
	local grid = Instance.new("Frame")
	grid.BackgroundColor3 = Color3.fromRGB(23, 27, 38)
	grid.Size = UDim2.fromScale(1, 1)
	grid.Parent = stage
	local layout = Instance.new("UIGridLayout")
	layout.CellPadding = UDim2.fromOffset(6, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	if SCREEN == "Proof" then
		layout.CellSize = UDim2.fromOffset(154, 440)
		for i, tier in Upgrades.Sack.tiers do
			cell(grid, AssetIds.sack(tier.name) or "?", `{i}. {tier.name}`, 154, 440)
		end
	else
		layout.CellSize = UDim2.fromOffset(190, 200)
		for _, key in
			{
				"premium_icons_nav_shop",
				"premium_icons_nav_index",
				"premium_icons_nav_rebirth",
				"premium_icons_nav_training",
				"premium_icons_nav_eggs",
				"premium_icons_nav_pets",
				"premium_icons_currency_cash",
				"premium_icons_power_sneaker",
			}
		do
			cell(grid, key, "icon", 190, 200)
		end
		for _, key in { "banners_power_background", "banners_cash_background", "banners_hatch_background" } do
			cell(grid, key, "banner", 190, 200, true)
		end
		for id = 1, 3 do
			cell(grid, AssetIds.zone(id), "zone " .. id, 190, 200, true)
		end
		for _, key in { "fx_glow", "fx_rays", "icon_close", "icon_check", "icon_lock" } do
			cell(grid, key, "ui", 190, 200)
		end
	end
else
	Modal.open(SCREEN)
end

-- 12x12 magenta corner marker: the capture script finds the stage by it and crops to STAGE size.
local marker = Instance.new("Frame")
marker.Name = "CaptureMarker"
marker.Size = UDim2.fromOffset(12, 12)
marker.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
marker.BorderSizePixel = 0
marker.ZIndex = 1000
marker.Parent = stage -- top-left of the stage (centred on the viewport in the 3D modes)

if
	SCREEN == "Showcase"
	or SCREEN == "GameSacks"
	or SCREEN == "Showroom"
	or SCREEN == "Heroes"
	or SCREEN == "SackShop"
then
	HOLD = 50 -- 3D previews take longer to build; keep the window up for the capture
	-- Studio's camera controller fights script moves: make it scriptable and keep re-asserting the shot
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	game:GetService("RunService").Heartbeat:Connect(function()
		if CAMERA then
			camera.CFrame = CAMERA
		end
	end)
end
print("PREVIEW_READY", SCREEN, STAGE, size)
task.wait(HOLD)
print("PREVIEW_DONE")
