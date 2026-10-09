--!strict
-- Strength training: every player carries their best training tool (Economy.Tools[data.tool]).
-- Each click (Tool.Activated, at most once per tool cooldown) adds the tool's `gain` to strength
-- (data.kickPower, capped at Economy.maxKickPower(rebirths)). Better tools are bought in the shop
-- (UpgradeService:BuyTool), which calls :GiveTool to swap it in.
-- Tool visuals: Partner A's Models.tool(id) if it exists (must return a Tool with a Handle),
-- otherwise a plain placeholder handle.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Models = require(Shared.Builders.Models)

local DataService = require(script.Parent.DataService)

local TOOL_ATTRIBUTE = "TrainingTier"
local PLACEHOLDER_HANDLE = Vector3.new(1, 1, 2.5)

local StrengthService = {}

local lastClick: { [Player]: number } = {}

-- Strength after one counted click (pure; used by the tests).
function StrengthService.trained(strength: number, tier: number, rebirths: number): number
	local tool = Economy.Tools[math.clamp(tier, 1, #Economy.Tools)]
	local value = math.min(strength + tool.gain, Economy.maxKickPower(rebirths))
	return math.floor(value * 1000 + 0.5) / 1000 -- keep saves tidy
end

local function makeTool(tier: number): Tool
	local config = Economy.Tools[tier]
	local fromModels = (Models :: any).tool
	local tool: Tool
	if typeof(fromModels) == "function" then
		tool = fromModels(config.id)
	else
		tool = Instance.new("Tool")
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = PLACEHOLDER_HANDLE
		handle.CanCollide = false
		handle.Parent = tool
	end
	tool.Name = config.id
	tool.CanBeDropped = false
	tool:SetAttribute(TOOL_ATTRIBUTE, tier)
	return tool
end

local function onClick(player: Player, tool: Tool)
	local data = DataService:Get(player)
	if not data or tool:GetAttribute(TOOL_ATTRIBUTE) ~= data.tool then
		return -- an old tool that wasn't cleaned up yet
	end
	local now = os.clock()
	local config = Economy.Tools[data.tool]
	if now - (lastClick[player] or 0) < config.cooldown then
		return -- also the rate limit: auto-clickers gain nothing extra
	end
	lastClick[player] = now
	local strength = StrengthService.trained(data.kickPower, data.tool, data.rebirths)
	if strength ~= data.kickPower then
		DataService:Set(player, { kickPower = strength })
	end
end

local function removeTools(player: Player)
	local containers: { Instance? } = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute(TOOL_ATTRIBUTE) ~= nil then
					child:Destroy()
				end
			end
		end
	end
end

-- Gives the player their current best tool (replacing any older one).
function StrengthService:GiveTool(player: Player)
	local data = DataService:Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	removeTools(player)
	local tool = makeTool(data.tool)
	tool.Activated:Connect(function()
		onClick(player, tool)
	end)
	tool.Parent = backpack
end

function StrengthService:Start()
	DataService:OnLoaded(function(player)
		if player.Character then
			self:GiveTool(player)
		end
		player.CharacterAdded:Connect(function()
			player:WaitForChild("Backpack", 10)
			self:GiveTool(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastClick[player] = nil
	end)
end

return StrengthService
