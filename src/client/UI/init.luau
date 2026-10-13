--!strict
-- Partner A HUD root. Shaped like a controller so Partner B's client loader can start it:
--   local UI = require(script.Parent.UI); UI:Init(); UI:Start()
-- Reads only DataChanged and the chase remotes; never computes rewards.
-- Kick The Egg UI system (UI handoff + final approved icons): left rail (Shop / Index / Rebirth), cash + kick
-- power counters, right rail (Eggs / Pets drawers), quest bar, settings + sound, all with the approved icon art
-- animated by UI/System/IconMotion and UI/System/UiVfx, and the modal screens in UI/Screens on UI/System.
-- Contextual only: the kick controls (UI/Hud/KickPanel: on the kick pad) and the zone progress bar
-- (UI/Hud/ZoneProgress: in a zone). No Training button and no Tool / SACK slot: sacks are bought at the
-- physical Boxing Sack Shop (its prompt opens the same purchasing screen) and taken out with the Train prompt
-- at your base's sack stand (UI/SackGear).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Kit = require(script.Kit)
local QuestBar = require(script.Hud.QuestBar)
local SoundToggle = require(script.Hud.SoundToggle)
local KickPanel = require(script.Hud.KickPanel)
local ChaseOverlay = require(script.Hud.ChaseOverlay)
local Rail = require(script.Hud.Rail)
local Counters = require(script.Hud.Counters)
local Drawers = require(script.Hud.Drawers)
local Menus = require(script.Menus)
local ZoneProgress = require(script.Hud.ZoneProgress)
local SackGear = require(script.SackGear)
local SackSlot = require(script.Hud.SackSlot)
local Interact = require(script.Interact)
local AssetIds = require(script.System.AssetIds)
local Data = require(script.System.Data)
local Modal = require(script.System.Modal)
local TrainingShop = require(script.Screens.TrainingShop)
local Shop = require(script.Screens.Shop)
local PetIndex = require(script.Screens.PetIndex)
local PetInventory = require(script.Screens.PetInventory)
local Rebirth = require(script.Screens.Rebirth)

local UI = {}

local data: { [string]: any } = {}
local quest: QuestBar.QuestBar
local kick: KickPanel.KickPanel
local zoneBar: ZoneProgress.ZoneProgress
local overlay: ChaseOverlay.ChaseOverlay
local menus: Menus.Menus
local rail: Rail.LeftRail
local counters: Counters.Counters
local drawers: Drawers.Drawers
local interactUpdate: ((data: { [string]: any }) -> ())?

-- World prompts (Interact: "OpenMenu:<name>") open the new screens; anything else stays A's window.
local PROMPT_SCREENS: { [string]: string } = { Store = "Training", Index = "Index", Rebirth = "Rebirth" }

function UI:Init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("HUD")
	if old then
		old:Destroy()
	end
	local oldModals = playerGui:FindFirstChild("Modals")
	if oldModals then
		oldModals:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	-- Studio only: workspace attribute HudPreview = "phone" lays the HUD out inside an 844x390 frame
	-- (phone landscape) so both layouts can be screenshotted from Studio.
	local root: Instance = gui
	if RunService:IsStudio() and workspace:GetAttribute("HudPreview") == "phone" then
		Kit.setPreview(Vector2.new(844, 390), true)
		local frame = Instance.new("Frame")
		frame.Name = "PhonePreview"
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromOffset(844, 390)
		frame.BackgroundTransparency = 1
		frame.ClipsDescendants = true
		local outline = Instance.new("UIStroke")
		outline.Thickness = 3
		outline.Color = Color3.new(1, 1, 1)
		outline.Parent = frame
		frame.Parent = gui
		root = frame
	end

	Modal.init(playerGui)
	TrainingShop.define()
	Shop.define()
	PetIndex.define()
	PetInventory.define()
	Rebirth.define()

	menus = Menus.new(root, { tiles = false }) -- Settings gear + Trade window; the rail replaces the tiles
	quest = QuestBar.new(root)
	SoundToggle.new(root)
	kick = KickPanel.new(root)
	SackGear.start(root) -- key 1 / gamepad Y, the "click to kick" hint
	local sackSlot = SackSlot.new(root, root:FindFirstChild("KickPanel") :: GuiObject?) -- bottom Kick Sack quickslot
	overlay = ChaseOverlay.new(root)
	zoneBar = ZoneProgress.new(root)
	rail = Rail.new(root)
	counters = Counters.new(root)
	drawers = Drawers.new(root)
	Drawers.openTrade = function()
		menus.open("Trade")
	end
	Rail.openTrade = function() -- the TRADE button on the left rail (no Trade button in the Pets drawer any more)
		menus.open("Trade")
	end
	-- toasts stay below the quest bar, and below the zone progress bar while it shows
	local questBar = root:FindFirstChild("Quest") :: GuiObject?
	local zoneRoot = root:FindFirstChild("ZoneProgress") :: GuiObject?
	local function anchorToasts()
		Modal.setToastAnchor(if zoneRoot and zoneRoot.Visible then zoneRoot else questBar)
	end
	anchorToasts()
	if zoneRoot then
		zoneRoot:GetPropertyChangedSignal("Visible"):Connect(anchorToasts)
	end
	Kit.watchViewport()
	quest.update(data)
	menus.update(data)
	Data.onChanged(function()
		rail.update()
		counters.update()
		drawers.update()
		sackSlot.update()
		Modal.refresh()
	end)
	gui.Parent = playerGui

	if RunService:IsStudio() then
		local missing = AssetIds.missing()
		if #missing > 0 then
			print(`[UI] {#missing} UI handoff images not uploaded yet (stand-ins in use); see UI/System/AssetIds`)
		end
	end
end

function UI:Start()
	-- Starts the client-side spinner for orbiting cubes / halos on rare eggs and pets.
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anim"))
	interactUpdate = Interact.start(function(name: string)
		local screen = PROMPT_SCREENS[name]
		if screen then
			Modal.open(screen)
		else
			menus.open(name)
		end
	end)
	task.spawn(function()
		-- Remotes waits for the server-created folder, so wire up in the background.
		local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
		Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
			for k, v in partial do
				data[k] = v
			end
			Data.apply(partial)
			quest.update(data)
			menus.update(data)
			if interactUpdate then
				interactUpdate(data)
			end
		end)

		-- KICK stays locked from KickResult until our chase ends (the server rejects kicks meanwhile).
		local myEgg: string? = nil
		Remotes.get("KickResult").OnClientEvent:Connect(function(result: { [string]: any })
			myEgg = result.eggUid
			kick.setBusy(true)
			Data.setBusy(true)
			zoneBar.kicked(result)
		end)
		Remotes.get("ChaseEnded").OnClientEvent:Connect(function(p: { [string]: any })
			if p and p.eggUid == myEgg then
				myEgg = nil
				kick.setBusy(false)
				Data.setBusy(false)
				overlay.stop()
				zoneBar.chaseOver(p.eggUid)
			end
		end)

		-- Hatches: toast + Pets badge. EggHatched goes to every client; it's ours when the new petUid is in our
		-- own data (the server writes it just before firing).
		Remotes.get("EggHatched").OnClientEvent:Connect(function(p: { [string]: any })
			task.wait(0.2)
			local pets = Data.state.pets
			local pet = typeof(pets) == "table" and typeof(p) == "table" and pets[p.petUid] or nil
			local config = pet and Data.pet(pet.petId)
			if config then
				drawers.hatched(config.name)
			end
		end)

		-- Chase overlay: only for our own chase (ChaseStart goes to every client).
		local me = Players.LocalPlayer.UserId
		local overlayEgg: string? = nil
		Remotes.get("ChaseStart").OnClientEvent:Connect(function(p: { [string]: any })
			if p.ownerUserId == me then
				overlayEgg = p.eggUid
				overlay.start(p)
			end
		end)
		Remotes.get("EggPickedUp").OnClientEvent:Connect(function(p: { [string]: any })
			if p.eggUid == overlayEgg and p.userId == me then
				overlay.pickedUp()
			end
		end)
		for _, name in { "EggSecured", "EggLost" } do
			Remotes.get(name).OnClientEvent:Connect(function(p: { [string]: any })
				if p and p.eggUid == overlayEgg then
					overlayEgg = nil
					overlay.stop()
				end
			end)
		end
	end)
end

return UI
