--!strict
-- Studio-only test keys until A's Store/Rebirth menus land (they fire the same remotes):
-- U = buy Kick Power, I = buy Run Speed, R = Rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local UpgradeController = {}

function UpgradeController:Start()
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
			buyUpgrade:FireServer("KickPower")
		elseif input.KeyCode == Enum.KeyCode.I then
			buyUpgrade:FireServer("RunSpeed")
		elseif input.KeyCode == Enum.KeyCode.R then
			rebirth:FireServer()
		end
	end)
end

return UpgradeController
