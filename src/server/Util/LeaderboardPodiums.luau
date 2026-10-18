--!strict
-- Cosmetic copies of the same top three entries painted on each global board. Avatar requests yield;
-- a podium revision prevents a slow old request from replacing a newer winner. No player characters change.
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local PodiumEmotes = require(script.Parent.PodiumEmotes)

local LeaderboardPodiums = {}
export type Entry = { userId: number, name: string? }
type Cached = { model: Model, loadedAt: number }
local REFRESH_SECONDS = 300
local CACHE_LIMIT = 12
local DISPLAY_GROUP = "LeaderboardDisplay"

local function prepare(avatar: Model)
	-- Native avatar requests may return detached accessories at their uploaded coordinates. A private
	-- WorldModel assembles joints/accessories before measuring, without replicating a temporary NPC.
	local staging = Instance.new("WorldModel")
	staging.Parent = ServerStorage
	avatar.Parent = staging
	avatar:GetBoundingBox() -- resolve lazy joint transforms while the avatar belongs to a WorldRoot
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	local root = avatar:FindFirstChild("HumanoidRootPart")
	assert(humanoid and root and root:IsA("BasePart"), "avatar has no humanoid/root")
	humanoid.EvaluateStateMachine = false -- display rigs must not restore body collisions or run floor sensors
	humanoid.AutomaticScalingEnabled = false
	for _, item in avatar:GetDescendants() do
		if item:IsA("BaseScript") or item:IsA("Tool") then
			item:Destroy()
		elseif item:IsA("BasePart") then
			item.CollisionGroup = DISPLAY_GROUP
			item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
			item.Massless = true
		end
	end
	avatar.Name = "Avatar"
	avatar.PrimaryPart = root
	root.Anchored = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.BreakJointsOnDeath = false
	local size = avatar:GetExtentsSize()
	-- Preserve the player's body proportions and accessories, uniformly fitting oversized outfits.
	local fit = math.min(1, 6.2 / size.X, 6.8 / size.Y, 5.6 / size.Z)
	avatar:ScaleTo(avatar:GetScale() * fit)
	avatar.Parent = nil
	staging:Destroy()
end

-- The loader seam lets Studio exercise failed/delayed requests without changing real rankings or DataStores.
function LeaderboardPodiums.new(loader: ((number) -> Model)?)
	local cache: { [number]: Cached } = {}
	local pending: { [number]: BindableEvent } = {}
	local loadAvatar = loader
		or function(userId: number): Model
			return Players:CreateHumanoidModelFromUserIdAsync(userId)
		end

	local function trim()
		local count = 0
		local oldestId: number? = nil
		local oldest = math.huge
		for id, item in cache do
			count += 1
			if item.loadedAt < oldest then
				oldestId, oldest = id, item.loadedAt
			end
		end
		if count > CACHE_LIMIT and oldestId then
			cache[oldestId].model:Destroy()
			cache[oldestId] = nil
		end
	end

	local function copy(userId: number): Model?
		local waiting = pending[userId]
		if waiting then
			waiting.Event:Wait()
			local result = cache[userId]
			return if result then result.model:Clone() else nil
		end
		local cached = cache[userId]
		if cached and os.clock() - cached.loadedAt < REFRESH_SECONDS then
			return cached.model:Clone()
		end
		local signal = Instance.new("BindableEvent")
		pending[userId] = signal
		local avatar: Model? = nil
		local ok, err = pcall(function()
			avatar = loadAvatar(userId)
			prepare(avatar :: Model)
		end)
		if ok and avatar then
			if cached then
				cached.model:Destroy()
			end
			cache[userId] = { model = avatar, loadedAt = os.clock() }
			trim()
		else
			if avatar then
				avatar:Destroy()
			end
			warn(`[LeaderboardPodiums] couldn't load avatar {userId}: {err}`)
		end
		pending[userId] = nil
		signal:Fire()
		signal:Destroy()
		local result = cache[userId]
		return if result then result.model:Clone() else nil
	end

	local renderer = {}
	function renderer:Update(board: Instance, entries: { Entry })
		local winners = board:FindFirstChild("Winners")
		if not winners then
			return
		end
		-- Client Humanoid initialization can reset torso CanCollide. The group also excludes these
		-- display copies from player/egg physics and rays, independently of that engine behavior.
		if not PhysicsService:IsCollisionGroupRegistered(DISPLAY_GROUP) then
			PhysicsService:RegisterCollisionGroup(DISPLAY_GROUP)
		end
		for _, group in PhysicsService:GetRegisteredCollisionGroups() do
			PhysicsService:CollisionGroupSetCollidable(DISPLAY_GROUP, group.name, false)
		end
		for rank = 1, 3 do
			local podium = winners:FindFirstChild("Rank" .. rank)
			local anchor = podium and podium:FindFirstChild("AvatarAnchor")
			if not (podium and anchor and anchor:IsA("BasePart")) then
				continue
			end
			local entry = entries[rank]
			local userId = if entry and entry.userId > 0 then entry.userId else nil
			local revision = (podium:GetAttribute("AvatarRevision") :: number?) or 0
			if podium:GetAttribute("UserId") ~= userId then
				revision += 1
				podium:SetAttribute("AvatarRevision", revision)
				podium:SetAttribute("UserId", userId)
				podium:SetAttribute("AvatarLoadedAt", nil)
				podium:SetAttribute("AvatarStatus", "Empty")
				local old = podium:FindFirstChild("Avatar")
				if old then
					old:Destroy()
				end
			end
			local name = podium:FindFirstChild("PlayerName", true)
			if name and name:IsA("TextLabel") then
				name.Text = if entry then (entry.name or "Player") else "UNCLAIMED"
			end
			if not userId or podium:GetAttribute("AvatarStatus") == "Loading" then
				continue
			end
			local loadedAt = podium:GetAttribute("AvatarLoadedAt") :: number?
			if podium:FindFirstChild("Avatar") and loadedAt and os.clock() - loadedAt < REFRESH_SECONDS then
				continue
			end
			revision += 1
			podium:SetAttribute("AvatarRevision", revision)
			podium:SetAttribute("AvatarStatus", "Loading")
			task.spawn(function()
				local avatar = copy(userId)
				if not podium.Parent or podium:GetAttribute("AvatarRevision") ~= revision then
					if avatar then
						avatar:Destroy()
					end
					return
				end
				local old = podium:FindFirstChild("Avatar")
				if not avatar then
					podium:SetAttribute("AvatarStatus", if old then "Ready" else "Unavailable")
					return -- retry on the next board refresh; never display the previous winner
				end
				avatar:PivotTo(anchor.CFrame)
				local box, size = avatar:GetBoundingBox()
				avatar:PivotTo(avatar:GetPivot() + Vector3.new(0, anchor.Position.Y - (box.Position.Y - size.Y / 2), 0))
				avatar:SetAttribute("AvatarUserId", userId)
				avatar:SetAttribute("LeaderboardRank", rank)
				if old then
					old:Destroy()
				end
				avatar.Parent = podium
				-- Parenting initializes Humanoid torso collisions even with state evaluation off.
				for _, item in avatar:GetDescendants() do
					if item:IsA("BasePart") then
						item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
					end
				end
				podium:SetAttribute("AvatarLoadedAt", os.clock())
				podium:SetAttribute("AvatarStatus", "Ready")
				task.spawn(PodiumEmotes.Play, avatar)
			end)
		end
	end
	return renderer
end

return LeaderboardPodiums
