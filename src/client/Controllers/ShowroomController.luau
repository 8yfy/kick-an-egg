--!strict
-- Studio only: the one-at-a-time Kick Sack showroom (UI/Dev/SackShowroom). Chat /showroom (SackService) bumps the
-- LocalPlayer attribute "SackShowroom"; every change toggles the showroom 16 studs in front of the player, on the
-- ground, facing them. The , and . keys step through the 20 sacks while it is open.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Parent.UI.Kit)
local SackShowroom = require(script.Parent.Parent.UI.Dev.SackShowroom)

local ShowroomController = {}

local function anchorFor(character: Model): CFrame?
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
	local spot = root.Position + look * 16
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(spot + Vector3.new(0, 10, 0), Vector3.new(0, -60, 0), params)
	local ground = if hit then hit.Position else spot - Vector3.new(0, 3, 0)
	-- -Z (LookVector) points at the player: the sack's front faces them
	return CFrame.lookAt(ground, Vector3.new(root.Position.X, ground.Y, root.Position.Z))
end

function ShowroomController:Start()
	if not RunService:IsStudio() then
		return
	end
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "SackShowroomGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local showroom = SackShowroom.new(gui)
	Kit.autoScale(showroom.gui)

	player:GetAttributeChangedSignal("SackShowroom"):Connect(function()
		if showroom.isOpen() then
			showroom.close()
			return
		end
		local anchor = player.Character and anchorFor(player.Character)
		if anchor then
			showroom.open(anchor)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not showroom.isOpen() then
			return
		end
		if input.KeyCode == Enum.KeyCode.Comma then
			showroom.step(-1)
		elseif input.KeyCode == Enum.KeyCode.Period then
			showroom.step(1)
		end
	end)
end

return ShowroomController
