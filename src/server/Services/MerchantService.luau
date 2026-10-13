--!strict
-- Shop merchants as Roblox avatars (Data/MerchantConfig). After the map is built, every merchant spot (the
-- placeholder NPC Builders/Map/Merchants puts behind a counter, attribute MerchantKind) is replaced by an NPC that
-- wears the configured user's avatar appearance (Players:GetHumanoidDescriptionFromUserId +
-- CreateHumanoidModelFromDescription, R15). With no UserId configured yet (0) it wears a plain default Roblox avatar
-- (an empty HumanoidDescription: no account). If the avatar can't be loaded, the placeholder stays.
-- The NPC keeps the spot's attributes (Merchant, Greeting) so clients still bob it, turn it toward nearby players
-- and show its greeting (MapLifeController); the shop counters' prompts and screens are untouched.

local Players = game:GetService("Players")

local MerchantConfig = require(script.Parent.Parent.Data.MerchantConfig)

local MerchantService = {}

local function configFor(kind: string): MerchantConfig.Merchant?
	for _, m in MerchantConfig do
		if m.Kind == kind then
			return m
		end
	end
	return nil
end

local function description(config: MerchantConfig.Merchant): HumanoidDescription
	if config.UserId > 0 then
		local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, config.UserId)
		if ok and desc then
			return desc
		end
		warn(`[MerchantService] couldn't load the avatar of {config.UserId} for {config.DisplayName}: {desc}`)
	else
		warn(`[MerchantService] {config.DisplayName}: no UserId in Data/MerchantConfig yet, using a default avatar`)
	end
	return Instance.new("HumanoidDescription")
end

-- Replaces placeholder merchant `spot` with an avatar NPC. Returns the NPC (nil if it stayed a placeholder).
function MerchantService:Replace(spot: Model): Model?
	local kind = spot:GetAttribute("MerchantKind")
	local config = if typeof(kind) == "string" then configFor(kind) else nil
	local feet = spot.PrimaryPart
	if not config or not feet then
		return nil
	end
	local ok, npc =
		pcall(Players.CreateHumanoidModelFromDescription, Players, description(config), Enum.HumanoidRigType.R15)
	if not ok or not npc then
		warn(`[MerchantService] avatar NPC failed for {config.DisplayName}: {npc}`)
		return nil
	end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		npc:Destroy()
		return nil
	end
	npc.Name = config.DisplayName
	humanoid.DisplayName = config.DisplayName
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.NameDisplayDistance = 40
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	for _, d in npc:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanTouch = false
		end
	end
	root.Anchored = true
	npc.PrimaryPart = root
	-- stand on the spot: the root sits HipHeight + half its height above the feet
	npc:PivotTo(feet.CFrame * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0))
	for _, attr in { "Merchant", "Greeting", "MerchantKind" } do
		npc:SetAttribute(attr, spot:GetAttribute(attr))
	end
	npc:SetAttribute("Merchant", config.DisplayName)
	npc:SetAttribute("AvatarUserId", config.UserId)
	npc.Parent = spot.Parent
	spot:Destroy()
	return npc
end

function MerchantService:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		if not map then
			return
		end
		for _, d in map:GetDescendants() do
			if d:IsA("Model") and typeof(d:GetAttribute("MerchantKind")) == "string" then
				task.spawn(function()
					MerchantService:Replace(d)
				end)
			end
		end
	end)
end

return MerchantService
