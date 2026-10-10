--!strict
-- Studio-only shop keys (A's Store and the base's ProximityPrompts fire the same remotes):
-- U = upgrade the training rack, I = buy Run Speed, O = upgrade the pen, R = Rebirth.
-- Training itself (Train) is fired by A's UI while you stand on your rack's plate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local UpgradeController = {}

function UpgradeController:Start()
	if not RunService:IsStudio() then
		return
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.U then
			Remotes.get("UpgradeTraining"):FireServer()
		elseif input.KeyCode == Enum.KeyCode.I then
			Remotes.get("BuyUpgrade"):FireServer("RunSpeed")
		elseif input.KeyCode == Enum.KeyCode.O then
			Remotes.get("UpgradePen"):FireServer()
		elseif input.KeyCode == Enum.KeyCode.R then
			Remotes.get("Rebirth"):FireServer()
		end
	end)
end

return UpgradeController
