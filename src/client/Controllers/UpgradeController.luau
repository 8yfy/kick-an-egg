--!strict
-- Studio-only shop keys until A's Store/Rebirth menus land (they fire the same remotes):
-- U = buy the next training tool, I = buy Run Speed, R = Rebirth.
-- Also plays the "Train" animation when the local player clicks with a training tool.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Anim = require(Shared.Anim)

local UpgradeController = {}

local player = Players.LocalPlayer

-- Training tools are server-made Tools with a "TrainingTier" attribute.
local function watchTool(child: Instance)
	if child:IsA("Tool") and child:GetAttribute("TrainingTier") ~= nil then
		child.Activated:Connect(function()
			local character = player.Character
			if character then
				Anim.play(character, "Train", { tool = child.Name })
			end
		end)
	end
end

function UpgradeController:Start()
	local function watchBackpack(backpack: Instance)
		for _, child in backpack:GetChildren() do
			watchTool(child)
		end
		backpack.ChildAdded:Connect(watchTool)
	end
	watchBackpack(player:WaitForChild("Backpack"))
	player.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			watchBackpack(child)
		end
	end)

	if not RunService:IsStudio() then
		return
	end
	local buyUpgrade = Remotes.get("BuyUpgrade")
	local rebirth = Remotes.get("Rebirth")
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.U then
			buyUpgrade:FireServer("Tool")
		elseif input.KeyCode == Enum.KeyCode.I then
			buyUpgrade:FireServer("RunSpeed")
		elseif input.KeyCode == Enum.KeyCode.R then
			rebirth:FireServer()
		end
	end)
end

return UpgradeController
