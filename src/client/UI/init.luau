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

local UI = {}

local data: { [string]: any } = {}
local stats: Stats.Stats
local quest: QuestBar.QuestBar
local kick: KickPanel.KickPanel

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

	stats = Stats.new(gui)
	quest = QuestBar.new(gui)
	SoundToggle.new(gui)
	kick = KickPanel.new(gui)
	Kit.watchViewport()
	stats.update(data)
	quest.update(data)
	gui.Parent = playerGui
end

function UI:Start()
	task.spawn(function()
		-- Remotes waits for the server-created folder, so wire up in the background.
		local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
		Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
			for k, v in partial do
				data[k] = v
			end
			stats.update(data)
			quest.update(data)
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
			end
		end)
	end)
end

return UI
