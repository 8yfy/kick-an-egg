--!strict
-- Kick Sack gear (Config/Upgrades.Sack), server side:
--   * Every character gets a Tool named after the player's current sack (attribute KickSack = true).
--     Equipping it places the sack in front of the player as character attributes, which every client
--     draws (SackController): SackAt (CFrame: hang point, front facing the player), SackTier (number),
--     SackPlaced (server time of the drop). Unequipping clears them.
--   * Stand still more than Sack.range from your sack and it drops again in front of you. Mid-chase
--     the tool is put away.
--   * Train(): one kick. Counts when the sack has finished dropping (Sack.dropSeconds), you are in range,
--     not mid-chase and at most once per Sack.interval; adds tiers[tier].gain to kick power (capped) and
--     bumps the character's SackHits so other clients play the kick.
--   * UpgradeTraining(): buys the next sack for tiers[tier + 1].cost (PlayerData.rackLevel = sack tier).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Remotes = require(Shared.Remotes)
local Sacks = require(Shared.Builders.Models.Sacks)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local DataService = require(script.Parent.DataService)
local KickService = require(script.Parent.KickService)
local PlotService = require(script.Parent.PlotService)

local TOOL_ATTR = "KickSack"
local PLACE_DIST = 3.6 -- studs from the player's root to the sack's axis (the kicking foot meets its front)
local INTERVAL_SLACK = 0.85 -- accept kicks slightly early (network jitter); still ~1 per interval
local CHECK_EVERY = 0.2
local REPLACE_SPEED = 2.5 -- below this horizontal speed (studs/s) the player counts as standing still
local REPLACE_COOLDOWN = 1.2

local SackService = {}

type Out = { at: CFrame, placed: number }

local limiter = RateLimiter.new()
local lastTrain: { [Player]: number } = {}
local out: { [Player]: Out } = {}

-- Pure helpers (used by the tests) -----------------------------------------

local function tierOf(level: number): Upgrades.SackTier
	local tiers = Upgrades.Sack.tiers
	return tiers[math.clamp(level, 1, #tiers)]
end

-- `value` after one kick on a sack of `tier`.
function SackService.trained(value: number, tier: number, rebirths: number): number
	local result = math.min(value + tierOf(tier).gain, Economy.maxKickPower(rebirths))
	return math.floor(result * 1000 + 0.5) / 1000 -- keep saves tidy
end

-- Price of sack tier + 1, or nil at the top.
function SackService.sackCost(tier: number): number?
	local nextTier = Upgrades.Sack.tiers[tier + 1]
	return if nextTier then nextTier.cost else nil
end

-- Close enough to kick: horizontal distance to the sack's axis and roughly the same floor.
function SackService.inRange(at: CFrame, position: Vector3): boolean
	local flat = Vector3.new(position.X - at.X, 0, position.Z - at.Z)
	local floorY = at.Y - Sacks.HANG
	return flat.Magnitude <= Upgrades.Sack.range and position.Y - floorY < 9 and position.Y > floorY - 2
end

-- Hang point for a player standing at `root` (feet at `floorY`): PLACE_DIST ahead, front facing them.
function SackService.placement(root: CFrame, floorY: number): CFrame
	local look = Vector3.new(root.LookVector.X, 0, root.LookVector.Z)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	local p = root.Position + look * PLACE_DIST
	local hang = Vector3.new(p.X, floorY + Sacks.HANG, p.Z)
	return CFrame.lookAt(hang, Vector3.new(root.X, hang.Y, root.Z))
end

-- Character helpers ----------------------------------------------------------

local function rootOf(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if hrp and hrp:IsA("BasePart") and humanoid then
		return hrp, humanoid
	end
	return nil, nil
end

local function equipped(player: Player): Tool?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return if tool and tool:GetAttribute(TOOL_ATTR) then tool else nil
end

local function tierFor(player: Player): number
	local data = DataService:Get(player)
	return math.clamp(if data then data.rackLevel else 1, 1, #Upgrades.Sack.tiers)
end

local function place(player: Player)
	local hrp, humanoid = rootOf(player)
	local character = player.Character
	if not hrp or not humanoid or not character then
		return
	end
	local floorY = hrp.Position.Y - hrp.Size.Y / 2 - humanoid.HipHeight
	local at = SackService.placement(hrp.CFrame, floorY)
	out[player] = { at = at, placed = os.clock() }
	character:SetAttribute("SackTier", tierFor(player))
	character:SetAttribute("SackAt", at)
	character:SetAttribute("SackPlaced", workspace:GetServerTimeNow())
end

local function clear(player: Player)
	out[player] = nil
	local character = player.Character
	if character then
		character:SetAttribute("SackAt", nil)
		character:SetAttribute("SackPlaced", nil)
	end
end

-- The player's sack tools, in the backpack and in hand.
local function toolsOf(player: Player): { Tool }
	local tools = {}
	local holders: { Instance? } = { player:FindFirstChildOfClass("Backpack"), player.Character }
	for _, holder in holders do
		if holder then
			for _, child in holder:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute(TOOL_ATTR) then
					table.insert(tools, child)
				end
			end
		end
	end
	return tools
end

-- Names every sack tool after the player's tier.
local function refreshTools(player: Player)
	local tier = tierFor(player)
	local info = tierOf(tier)
	for _, tool in toolsOf(player) do
		tool.Name = info.name
		tool.ToolTip = `Auto-kick: +{info.gain} Kick Power`
		tool:SetAttribute("Tier", tier)
	end
	if out[player] then
		place(player) -- drop the new sack in
	end
end

local function giveTool(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack or #toolsOf(player) > 0 then
		return
	end
	local tool = Instance.new("Tool")
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute(TOOL_ATTR, true)
	tool.Parent = backpack
	refreshTools(player)
end

local function onCharacter(player: Player, character: Model)
	out[player] = nil
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute(TOOL_ATTR) then
			place(player)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute(TOOL_ATTR) and not equipped(player) then
			clear(player)
		end
	end)
	task.defer(giveTool, player)
end

-- Handlers -----------------------------------------------------------------

local function onTrain(player: Player)
	if not limiter:allow(player) or KickService:GetActive(player) then
		return
	end
	local state = out[player]
	local hrp = rootOf(player)
	local character = player.Character
	local data = DataService:Get(player)
	if not state or not hrp or not character or not data or not equipped(player) then
		return
	end
	local now = os.clock()
	if now - state.placed < Upgrades.Sack.dropSeconds * 0.8 then
		return
	end
	if now - (lastTrain[player] or 0) < Upgrades.Sack.interval * INTERVAL_SLACK then
		return
	end
	if not SackService.inRange(state.at, hrp.Position) then
		return
	end
	lastTrain[player] = now
	local stat = Upgrades.Sack.stat
	local value = SackService.trained(data[stat], data.rackLevel, data.rebirths)
	if value ~= data[stat] then
		DataService:Set(player, { [stat] = value })
	end
	local hits = character:GetAttribute("SackHits")
	character:SetAttribute("SackHits", (if typeof(hits) == "number" then hits else 0) + 1)
end

local function onUpgradeTraining(player: Player)
	local data = DataService:Get(player)
	if not limiter:allow(player) or not data then
		return
	end
	local cost = SackService.sackCost(data.rackLevel)
	if not cost or data.money < cost then
		return
	end
	DataService:Set(player, { money = data.money - cost, rackLevel = data.rackLevel + 1 })
	PlotService:MirrorBase(player)
	Analytics.money(player, "Sink", cost, "Shop", "KickSack")
	Analytics.funnel(player, Analytics.Funnel.FirstUpgrade, "FirstUpgrade")
	refreshTools(player)
end

-- Moves a left-behind sack in front of its player once they stand still; puts it away mid-chase.
local function check()
	local now = os.clock()
	for player, state in out do
		local hrp, humanoid = rootOf(player)
		if not hrp or not humanoid then
			continue
		end
		if KickService:GetActive(player) then
			humanoid:UnequipTools()
			clear(player)
		elseif now - state.placed > REPLACE_COOLDOWN and not SackService.inRange(state.at, hrp.Position) then
			local v = hrp.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude < REPLACE_SPEED then
				place(player)
			end
		end
	end
end

function SackService:Start()
	Remotes.get("Train").OnServerEvent:Connect(onTrain)
	Remotes.get("UpgradeTraining").OnServerEvent:Connect(onUpgradeTraining)
	local function added(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if RunService:IsStudio() then
			-- Studio-only playtest commands (chat): /sack <tier> jumps to any sack, /cash <amount> adds money
			player.Chatted:Connect(function(message)
				local cmd, arg = string.match(message, "^/(%a+)%s+(%S+)")
				local n = tonumber(arg)
				local data = DataService:Get(player)
				if not data or not n then
					return
				end
				if cmd == "sack" then
					DataService:Set(player, { rackLevel = math.clamp(math.floor(n), 1, #Upgrades.Sack.tiers) })
					PlotService:MirrorBase(player)
					refreshTools(player)
				elseif cmd == "cash" then
					DataService:Set(player, { money = data.money + math.max(0, n) })
				end
			end)
		end
		if player.Character then
			onCharacter(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(added)
	for _, player in Players:GetPlayers() do
		added(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastTrain[player] = nil
		out[player] = nil
	end)
	DataService:OnLoaded(function(player)
		refreshTools(player) -- the saved tier arrives after the first character
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= CHECK_EVERY then
			acc = 0
			check()
		end
	end)
end

return SackService
