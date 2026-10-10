--!strict
-- Partner A HUD root. Shaped like a controller so Partner B's client loader can start it:
--   local UI = require(script.Parent.UI); UI:Init(); UI:Start()
-- Reads only DataChanged and the chase remotes; never computes rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Kit)
local Stats = require(script.Hud.Stats)
local QuestBar = require(script.Hud.QuestBar)
local SoundToggle = require(script.Hud.SoundToggle)
local KickPanel = require(script.Hud.KickPanel)
local SackButton = require(script.Hud.SackButton)
local ChaseOverlay = require(script.Hud.ChaseOverlay)
local Menus = require(script.Menus)
local ZoneBar = require(script.Hud.ZoneBar)
local Interact = require(script.Interact)

local UI = {}

local data: { [string]: any } = {}
local stats: Stats.Stats
local quest: QuestBar.QuestBar
local kick: KickPanel.KickPanel
local sack: SackButton.SackButton
local overlay: ChaseOverlay.ChaseOverlay
local menus: Menus.Menus
local interactUpdate: ((data: { [string]: any }) -> ())?

function UI:Init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("HUD")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	menus = Menus.new(gui)
	stats = Stats.new(gui, function()
		menus.open("Store")
	end)
	quest = QuestBar.new(gui)
	SoundToggle.new(gui)
	kick = KickPanel.new(gui)
	sack = SackButton.new(gui:FindFirstChild("KickPanel") or gui) -- the SACK box sits next to KICK
	overlay = ChaseOverlay.new(gui)
	ZoneBar.new(gui)
	Kit.watchViewport()
	stats.update(data)
	quest.update(data)
	menus.update(data)
	sack.update(data)
	gui.Parent = playerGui
end

function UI:Start()
	-- Starts the client-side spinner for orbiting cubes / halos on rare eggs and pets.
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anim"))
	interactUpdate = Interact.start(function(name: string)
		menus.open(name)
	end)
	task.spawn(function()
		-- Remotes waits for the server-created folder, so wire up in the background.
		local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
		Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
			for k, v in partial do
				data[k] = v
			end
			stats.update(data)
			quest.update(data)
			menus.update(data)
			sack.update(data)
			if interactUpdate then
				interactUpdate(data)
			end
		end)

		-- KICK stays locked from KickResult until our chase ends (the server rejects kicks meanwhile).
		local myEgg: string? = nil
		Remotes.get("KickResult").OnClientEvent:Connect(function(result: { [string]: any })
			myEgg = result.eggUid
			kick.setBusy(true)
		end)
		Remotes.get("ChaseEnded").OnClientEvent:Connect(function(p: { [string]: any })
			if p and p.eggUid == myEgg then
				myEgg = nil
				kick.setBusy(false)
				overlay.stop()
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
