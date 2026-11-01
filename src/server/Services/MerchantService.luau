--!strict
-- Shop merchants as Roblox avatars (Data/MerchantConfig). After the map is built, every merchant spot (the
-- placeholder NPC Builders/Map/Merchants puts behind a counter, attribute MerchantKind) is replaced by an NPC that
-- wears the configured user's CURRENT avatar: Players:GetHumanoidDescriptionFromUserId, built with
-- CreateHumanoidModelFromDescription in the user's own rig type (R6 / R15, from GetCharacterAppearanceInfoAsync),
-- so it is a direct copy of that avatar. It is loaded fresh every time a server starts, and re-checked every
-- REFRESH_SECONDS while the server runs (ApplyDescriptionReset; rebuilt if the rig type changed), so outfit changes
-- show up without a new server. With no UserId configured (0) it wears a plain default Roblox avatar (an empty
-- HumanoidDescription: no account). If the avatar can't be loaded, the placeholder (or the last good look) stays.
-- The NPC keeps the spot's attributes (Merchant, Greeting) so clients still bob it, turn it toward nearby players
-- and show its greeting (MapLifeController); the shop counters' prompts and screens are untouched.

local Players = game:GetService("Players")

local MerchantConfig = require(script.Parent.Parent.Data.MerchantConfig)

local REFRESH_SECONDS = 300

local MerchantService = {}

type Live = { npc: Model, config: MerchantConfig.Merchant, feet: CFrame, rig: Enum.HumanoidRigType }
local live: { Live } = {}

local function configFor(kind: string): MerchantConfig.Merchant?
	for _, m in MerchantConfig do
		if m.Kind == kind then
			return m
		end
	end
	return nil
end

local function description(config: MerchantConfig.Merchant): HumanoidDescription?
	if config.UserId > 0 then
		local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, config.UserId)
		if ok and desc then
			return desc
		end
		warn(`[MerchantService] couldn't load the avatar of {config.UserId} for {config.DisplayName}: {desc}`)
		return nil
	end
	warn(`[MerchantService] {config.DisplayName}: no UserId in Data/MerchantConfig yet, using a default avatar`)
	return Instance.new("HumanoidDescription")
end

-- The rig type the user's avatar uses (R15 when unknown or for the default avatar).
local function rigOf(config: MerchantConfig.Merchant): Enum.HumanoidRigType
	if config.UserId > 0 then
		local ok, info = pcall(Players.GetCharacterAppearanceInfoAsync, Players, config.UserId)
		if ok and typeof(info) == "table" and info.playerAvatarType == "R6" then
			return Enum.HumanoidRigType.R6
		end
	end
	return Enum.HumanoidRigType.R15
end

-- The lowest world Y of the NPC's body (feet), ignoring accessories: right after
-- CreateHumanoidModelFromDescription they are not attached yet and can sit far below the feet.
local function bodyBottom(npc: Model): number?
	local low = math.huge
	for _, d in npc:GetDescendants() do
		if d:IsA("BasePart") and not d:FindFirstAncestorOfClass("Accessory") then
			local cf, half = d.CFrame, d.Size / 2
			local reach = math.abs(cf.RightVector.Y) * half.X
				+ math.abs(cf.UpVector.Y) * half.Y
				+ math.abs(cf.LookVector.Y) * half.Z
			low = math.min(low, cf.Position.Y - reach)
		end
	end
	return if low < math.huge then low else nil
end

-- Builds the avatar NPC standing on `feet` (facing its LookVector) with `attrs`. nil if it can't be built.
local function build(
	config: MerchantConfig.Merchant,
	desc: HumanoidDescription,
	rig: Enum.HumanoidRigType,
	feet: CFrame,
	attrs: { [string]: any },
	parent: Instance
): Model?
	local ok, npc = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, rig)
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
	-- stand on the spot: lift the model so its feet (any rig or body scale, not the accessories) are on `feet`
	npc:PivotTo(feet)
	local bottom = bodyBottom(npc) or feet.Position.Y
	npc:PivotTo(feet + Vector3.new(0, feet.Position.Y - bottom, 0))
	for k, v in attrs do
		npc:SetAttribute(k, v)
	end
	npc:SetAttribute("Merchant", config.DisplayName)
	npc:SetAttribute("AvatarUserId", config.UserId)
	npc.Parent = parent
	return npc
end

-- Replaces placeholder merchant `spot` with an avatar NPC. Returns the NPC (nil if it stayed a placeholder).
function MerchantService:Replace(spot: Model): Model?
	local kind = spot:GetAttribute("MerchantKind")
	local config = if typeof(kind) == "string" then configFor(kind) else nil
	local feet = spot.PrimaryPart
	if not config or not feet or not spot.Parent then
		return nil
	end
	local desc = description(config)
	if not desc then
		return nil
	end
	local rig = rigOf(config)
	local attrs = {
		Merchant = spot:GetAttribute("Merchant"),
		Greeting = spot:GetAttribute("Greeting"),
		MerchantKind = kind,
	}
	local npc = build(config, desc, rig, feet.CFrame, attrs, spot.Parent :: Instance)
	if not npc then
		return nil
	end
	table.insert(live, { npc = npc, config = config, feet = feet.CFrame, rig = rig })
	spot:Destroy()
	return npc
end

-- Re-reads every configured avatar and updates its NPC (the owner changed their outfit while the server runs).
function MerchantService:Refresh()
	for _, entry in live do
		if entry.config.UserId <= 0 or not entry.npc.Parent then
			continue
		end
		local desc = description(entry.config)
		if not desc then
			continue
		end
		local rig = rigOf(entry.config)
		local humanoid = entry.npc:FindFirstChildOfClass("Humanoid")
		if rig == entry.rig and humanoid then
			pcall(function()
				humanoid:ApplyDescriptionReset(desc)
			end)
		else -- the avatar switched between R6 and R15: rebuild it on the same spot
			local attrs = {
				Merchant = entry.npc:GetAttribute("Merchant"),
				Greeting = entry.npc:GetAttribute("Greeting"),
				MerchantKind = entry.npc:GetAttribute("MerchantKind"),
			}
			local npc = build(entry.config, desc, rig, entry.feet, attrs, entry.npc.Parent :: Instance)
			if npc then
				entry.npc:Destroy()
				entry.npc, entry.rig = npc, rig
			end
		end
	end
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
		while true do
			task.wait(REFRESH_SECONDS)
			MerchantService:Refresh()
		end
	end)
end

return MerchantService
