--!strict
-- The avalanche chase. Starts at touchdown (KickService:OnTouchdown), ticks every 0.1 s,
-- decides EggCaught / Caught / EggSecured / ChaseEnded, handles PickupEgg and anti-teleport.
-- The egg runs on a deterministic formula (see eggZ) so clients draw exactly the same thing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)
local Remotes = require(Shared.Remotes)

local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local KickService = require(script.Parent.KickService)

export type ChaseState = {
	owner: Player,
	eggUid: string,
	petId: string,
	size: string?,
	weather: string?,
	landPos: Vector3,
	startZ: number,
	startTime: number,
	speed: number,
	eggRunStart: number,
	pickedUp: boolean,
	resolved: boolean, -- an outcome (secured) was decided; avalanche keeps rolling
	validPos: Vector3?, -- last plausible owner HRP position
	validAt: number,
	flags: number,
}

export type Outcome = "EggCaught" | "Caught" | "Secured" | "Ended" | nil

local TICK = 0.1
local FLING_UP = 30
local RESPAWN_DELAY = 1.2
local SPEED_SLACK_MULT = 1.6
local SPEED_SLACK_ADD = 10
local PICKUP_SLACK = 2
local FALLBACK_BASE_BACK = 14 -- studs behind the safe line when no PlotService/SpawnLocation exists

local Avalanche = Chase.Avalanche
local Egg = Chase.Egg

local ChaseService = {}

local chases: { [Player]: ChaseState } = {}
local limiter = RateLimiter.new()
local remotes: { [string]: RemoteEvent } = {}

-- Pure helpers (also used by the headless tests) ----------------------------

-- Server egg Z before pickup: runs toward -Z after eggRunStart, stops at the safe line.
function ChaseService.eggZ(chase: ChaseState, now: number): number
	local z = chase.landPos.Z - Egg.runSpeed * math.max(0, now - chase.eggRunStart)
	return math.max(z, Chase.SafeLineZ)
end

function ChaseService.frontZ(chase: ChaseState, now: number): number
	return Chase.frontZ(chase.startZ, chase.startTime, chase.speed, now)
end

-- Decides what happens this tick. `hrpPos` is the owner's last plausible position (nil = no body).
function ChaseService.decide(chase: ChaseState, now: number, hrpPos: Vector3?): Outcome
	local front = ChaseService.frontZ(chase, now)
	if not chase.resolved then
		if not chase.pickedUp and ChaseService.eggZ(chase, now) >= front - Avalanche.catchDistance then
			return "EggCaught"
		end
		if not hrpPos then
			return "Caught"
		end
		local inField = hrpPos.Z >= Chase.SafeLineZ
		if inField and hrpPos.Z >= front - Avalanche.catchDistance then
			return "Caught"
		end
		if chase.pickedUp and hrpPos.Z < Chase.SafeLineZ then
			return "Secured"
		end
	end
	if front <= Avalanche.despawnAtZ then
		return "Ended"
	end
	return nil
end

-- Accepts `pos` only if reachable from the last valid sample at the allowed speed (XZ plane).
function ChaseService.plausible(fromPos: Vector3, fromAt: number, pos: Vector3, now: number, walkSpeed: number): boolean
	local delta = pos - fromPos
	local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local allowed = (walkSpeed * SPEED_SLACK_MULT + SPEED_SLACK_ADD) * math.max(now - fromAt, TICK)
	return flat <= allowed
end

-- Player helpers -----------------------------------------------------------

local function rootPart(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not hrp or not hrp:IsA("BasePart") then
		return nil, nil
	end
	return hrp, humanoid
end

local function baseWalkSpeed(player: Player): number
	local data = DataService:Get(player)
	return if data then data.runSpeed else Economy.RunSpeed.base
end

local function setWalkSpeed(player: Player, speed: number)
	local _, humanoid = rootPart(player)
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

local function baseCFrame(player: Player): CFrame
	local module = script.Parent:FindFirstChild("PlotService")
	if module and module:IsA("ModuleScript") then
		local plotService = (require :: any)(module)
		if plotService.GetBaseCFrame then
			local cf = plotService:GetBaseCFrame(player)
			if cf then
				return cf
			end
		end
	end
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		return spawn.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 5, Chase.SafeLineZ - FALLBACK_BASE_BACK)
end

-- Outcomes -----------------------------------------------------------------

local function finish(chase: ChaseState)
	if chases[chase.owner] == chase then
		chases[chase.owner] = nil
	end
	KickService:EndChase(chase.owner)
end

local function bumpStat(player: Player, key: string)
	local data = DataService:Get(player)
	if data then
		local stats: { [string]: number } = table.clone(data.stats)
		stats[key] = (stats[key] or 0) + 1
		DataService:Set(player, { stats = stats })
	end
end

local function fling(player: Player)
	local hrp = rootPart(player)
	if not hrp then
		return
	end
	pcall(function()
		hrp:SetNetworkOwner(nil) -- the server applies the velocity, not the client
	end)
	hrp.AssemblyLinearVelocity = Vector3.new(0, FLING_UP, -Chase.Caught.knockback)
	task.delay(RESPAWN_DELAY, function()
		local current = rootPart(player)
		if current then
			current.AssemblyLinearVelocity = Vector3.zero
			if Chase.Caught.respawnAtBase then
				current.CFrame = baseCFrame(player)
			end
			pcall(function()
				current:SetNetworkOwner(player)
			end)
		end
	end)
end

local function lose(chase: ChaseState, reason: "Caught" | "EggCaught" | "Left")
	remotes.EggLost:FireAllClients({ eggUid = chase.eggUid, reason = reason })
	Analytics.custom(chase.owner, "EggLost", 1, reason, chase.petId)
	if reason ~= "Left" then
		setWalkSpeed(chase.owner, baseWalkSpeed(chase.owner))
		bumpStat(chase.owner, "lost")
		if reason == "Caught" then
			fling(chase.owner)
		end
	end
	-- Every chase ends with ChaseEnded (the HUD unlocks KICK on it), even when the egg is lost.
	remotes.ChaseEnded:FireAllClients({ eggUid = chase.eggUid })
	finish(chase)
end

local function secure(chase: ChaseState)
	chase.resolved = true
	local player = chase.owner
	local data = DataService:Get(player)
	if data then
		local eggs = table.clone(data.eggs)
		table.insert(eggs, { uid = chase.eggUid, petId = chase.petId, size = chase.size, weather = chase.weather })
		DataService:Set(player, { eggs = eggs })
		bumpStat(player, "secured")
	end
	setWalkSpeed(player, baseWalkSpeed(player))
	remotes.EggSecured:FireAllClients({ eggUid = chase.eggUid })
	Analytics.custom(player, "EggSecured", 1, chase.petId)
	Analytics.funnel(player, Analytics.Funnel.FirstSecure, "FirstSecure")
end

-- Tick ---------------------------------------------------------------------

local function sampleOwner(chase: ChaseState, now: number): Vector3?
	local hrp, humanoid = rootPart(chase.owner)
	if not hrp or not humanoid then
		return nil
	end
	local pos = hrp.Position
	local valid = chase.validPos
	if not valid or ChaseService.plausible(valid, chase.validAt, pos, now, humanoid.WalkSpeed) then
		chase.validPos = pos
		chase.validAt = now
	else
		chase.flags += 1
		if chase.flags == 1 or chase.flags % 20 == 0 then
			warn(`[ChaseService] {chase.owner.Name} moved too fast ({chase.flags} samples ignored)`)
		end
	end
	return chase.validPos
end

local function tick(chase: ChaseState)
	local now = workspace:GetServerTimeNow()
	local hrpPos = sampleOwner(chase, now)
	local outcome = ChaseService.decide(chase, now, hrpPos)
	if outcome == "EggCaught" or outcome == "Caught" then
		lose(chase, outcome)
	elseif outcome == "Secured" then
		secure(chase)
	elseif outcome == "Ended" then
		remotes.ChaseEnded:FireAllClients({ eggUid = chase.eggUid })
		finish(chase)
	end
end

local function startChase(pending: KickService.PendingChase)
	local player = pending.owner
	if not player.Parent then
		KickService:EndChase(player)
		return
	end
	local touchdown = pending.touchdown
	local hrp = rootPart(player)
	local chase: ChaseState = {
		owner = player,
		eggUid = pending.eggUid,
		petId = pending.petId,
		size = pending.size,
		weather = pending.weather,
		landPos = pending.landPos,
		startZ = pending.landPos.Z + Avalanche.spawnBehindLanding,
		startTime = touchdown + Avalanche.warnSeconds,
		speed = Chase.avalancheSpeed(pending.landZone),
		eggRunStart = touchdown + Egg.runDelay,
		pickedUp = false,
		resolved = false,
		validPos = hrp and hrp.Position,
		validAt = workspace:GetServerTimeNow(),
		flags = 0,
	}
	chases[player] = chase
	remotes.ChaseStart:FireAllClients({
		eggUid = chase.eggUid,
		ownerUserId = player.UserId,
		theme = Chase.themeFor(pending.landZone),
		startZ = chase.startZ,
		startTime = chase.startTime,
		speed = chase.speed,
		eggStartPos = chase.landPos,
		eggRunStart = chase.eggRunStart,
	})
end

local function onPickupEgg(player: Player, eggUid: any)
	if not limiter:allow(player) or typeof(eggUid) ~= "string" then
		return
	end
	local chase = chases[player]
	if not chase or chase.eggUid ~= eggUid or chase.pickedUp or chase.resolved then
		return
	end
	local now = workspace:GetServerTimeNow()
	local hrpPos = sampleOwner(chase, now) -- validated position, so a teleport can't reach the egg
	if not hrpPos then
		return
	end
	local eggPos = Vector3.new(chase.landPos.X, hrpPos.Y, ChaseService.eggZ(chase, now))
	local flat = Vector3.new(hrpPos.X - eggPos.X, 0, hrpPos.Z - eggPos.Z).Magnitude
	-- The client egg zig-zags ±Egg.zigzag around the server X, so allow that too.
	if flat > Egg.pickupDistance + PICKUP_SLACK + Egg.zigzag then
		return
	end
	chase.pickedUp = true
	setWalkSpeed(player, baseWalkSpeed(player) * Chase.Carry.speedMultiplier)
	remotes.EggPickedUp:FireAllClients({ eggUid = eggUid, userId = player.UserId })
end

-- Public API ---------------------------------------------------------------

function ChaseService:GetChase(player: Player): ChaseState?
	return chases[player]
end

-- Re-applies WalkSpeed after runSpeed changes (upgrade/rebirth), keeping the carry slowdown.
function ChaseService:RefreshWalkSpeed(player: Player)
	local chase = chases[player]
	local carrying = chase ~= nil and chase.pickedUp and not chase.resolved
	local speed = baseWalkSpeed(player)
	setWalkSpeed(player, if carrying then speed * Chase.Carry.speedMultiplier else speed)
end

function ChaseService:Init()
	for _, name in { "ChaseStart", "EggPickedUp", "EggSecured", "EggLost", "ChaseEnded" } do
		remotes[name] = Remotes.get(name)
	end
end

function ChaseService:Start()
	KickService:OnTouchdown(startChase)
	Remotes.get("PickupEgg").OnServerEvent:Connect(onPickupEgg)

	-- Walk speed always follows the RunSpeed upgrade (carry slows it while holding an egg).
	local function applySpeed(player: Player, character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			local data = DataService:WaitForData(player)
			if data then
				humanoid.WalkSpeed = data.runSpeed
			end
		end
	end
	DataService:OnLoaded(function(player)
		if player.Character then
			applySpeed(player, player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			applySpeed(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local chase = chases[player]
		if chase then
			lose(chase, "Left")
		end
	end)

	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < TICK then
			return
		end
		accumulator = 0
		for _, chase in table.clone(chases) do
			tick(chase)
		end
	end)
end

return ChaseService
