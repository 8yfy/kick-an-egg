--!strict
-- The avalanche chase: the kicker STEERS THE EGG back to the safe zone.
-- At touchdown the server spawns the egg (workspace.Chases[eggUid]) with a LinearVelocity +
-- AlignOrientation; at controlStart (= ChaseStart.eggRunStart) it hands physics ownership to the
-- owner, whose client drives it (like a vehicle). The owner's character is frozen meanwhile.
-- Every 0.1 s the server validates the egg's position (speed limit, snap-back on teleports) and
-- decides EggCaught / EggSecured / ChaseEnded. Egg speed = the player's Run Speed (bought in the shop).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)
local Models = require(Shared.Builders.Models)
local Remotes = require(Shared.Remotes)

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
	speed: number, -- avalanche
	controlStart: number,
	eggSpeed: number, -- max steering speed (studs/s)
	egg: Model?,
	hitbox: BasePart?,
	controlling: boolean,
	resolved: boolean, -- secured; the avalanche keeps rolling to despawnAtZ
	validPos: Vector3, -- last plausible egg position
	validAt: number,
	flags: number,
}

export type Outcome = "EggCaught" | "Secured" | "Ended" | nil

local TICK = 0.1
local SPEED_SLACK_MULT = 1.6
local SPEED_SLACK_ADD = 10
local FALL_LIMIT = 40 -- studs below the landing point = fell off the map
local OWNER_RESTORE_DELAY = 0.25 -- after a server snap-back
local EGG_CLEANUP_DELAY = 1.5 -- lets EggSecured / EggCaught VFX play on the egg
local STEER_FORCE = 1e6

local Avalanche = Chase.Avalanche
local Egg = Chase.Egg

local ChaseService = {}

local chases: { [Player]: ChaseState } = {}
local remotes: { [string]: RemoteEvent } = {}
local chasesFolder: Folder

-- Pure helpers (also used by the headless tests) ----------------------------

function ChaseService.frontZ(chase: ChaseState, now: number): number
	return Chase.frontZ(chase.startZ, chase.startTime, chase.speed, now)
end

-- `eggPos` is the egg's last plausible position.
function ChaseService.decide(chase: ChaseState, now: number, eggPos: Vector3): Outcome
	local front = ChaseService.frontZ(chase, now)
	if not chase.resolved then
		if eggPos.Z >= front - Avalanche.catchDistance then
			return "EggCaught"
		end
		if eggPos.Z < Chase.SafeLineZ then
			return "Secured"
		end
	end
	if front <= Avalanche.despawnAtZ then
		return "Ended"
	end
	return nil
end

-- Accepts `pos` only if reachable from the last valid sample at the allowed speed (XZ plane).
function ChaseService.plausible(fromPos: Vector3, fromAt: number, pos: Vector3, now: number, speed: number): boolean
	local delta = pos - fromPos
	local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local allowed = (speed * SPEED_SLACK_MULT + SPEED_SLACK_ADD) * math.max(now - fromAt, TICK)
	return flat <= allowed
end

function ChaseService.eggSpeedFor(data: { [string]: any }?): number
	if not data then
		return Economy.RunSpeed.base
	end
	return data.runSpeed
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

-- While steering, the kicker's body stays put (their input drives the egg instead).
local function freezeCharacter(player: Player, frozen: boolean)
	local hrp = rootPart(player)
	if hrp then
		hrp.Anchored = frozen
	end
end

-- The egg ------------------------------------------------------------------

local function buildEgg(chase: ChaseState, eggModel: string): (Model, BasePart)
	local egg = Models.egg(eggModel)
	egg.Name = chase.eggUid
	egg:PivotTo(CFrame.lookAt(chase.landPos, chase.landPos - Vector3.zAxis)) -- faces the bases

	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
			part.CanCollide = false
			part.CanTouch = false
		end
	end

	-- One invisible collider carries the physics; the decorated parts ride on it.
	local cf, size = egg:GetBoundingBox()
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = size
	hitbox.CFrame = cf
	hitbox.Transparency = 1
	hitbox.CanCollide = true
	hitbox.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 1) -- no friction drag
	hitbox.Parent = egg
	local root = egg.PrimaryPart :: BasePart
	root.Anchored = false -- the hitbox (anchored until control) now holds the assembly
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hitbox
	weld.Part1 = root
	weld.Parent = hitbox

	local attachment = Instance.new("Attachment")
	attachment.Name = "Steer"
	attachment.Parent = hitbox

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "SteerVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane -- gravity keeps Y
	velocity.PrimaryTangentAxis = Vector3.xAxis
	velocity.SecondaryTangentAxis = Vector3.zAxis
	velocity.PlaneVelocity = Vector2.zero
	velocity.MaxForce = STEER_FORCE
	velocity.Parent = hitbox

	local align = Instance.new("AlignOrientation")
	align.Name = "SteerAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.CFrame = CFrame.lookAt(Vector3.zero, -Vector3.zAxis)
	align.Responsiveness = 30
	align.MaxTorque = STEER_FORCE
	align.Parent = hitbox

	hitbox.Anchored = true -- until control starts (legs sprout first)
	egg.PrimaryPart = hitbox
	egg.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	egg:SetAttribute("OwnerUserId", chase.owner.UserId)
	egg:SetAttribute("Speed", chase.eggSpeed)
	egg:SetAttribute("ControlStart", chase.controlStart)
	egg.Parent = chasesFolder
	pcall(function()
		egg:AddPersistentPlayer(chase.owner) -- the owner always has it, even with streaming
	end)
	return egg, hitbox
end

local function giveControl(chase: ChaseState)
	local hitbox = chase.hitbox
	if not hitbox or chases[chase.owner] ~= chase or chase.resolved then
		return
	end
	chase.controlling = true
	hitbox.Anchored = false
	pcall(function()
		hitbox:SetNetworkOwner(chase.owner)
	end)
	chase.owner.ReplicationFocus = hitbox -- stream the map around the egg, not the frozen body
	freezeCharacter(chase.owner, true)
end

-- Puts the egg back at its last valid position (teleport / speed hack / fell off the map).
local function snapBack(chase: ChaseState)
	local egg, hitbox = chase.egg, chase.hitbox
	if not egg or not hitbox then
		return
	end
	pcall(function()
		hitbox:SetNetworkOwner(nil)
	end)
	hitbox.AssemblyLinearVelocity = Vector3.zero
	egg:PivotTo(CFrame.lookAt(chase.validPos, chase.validPos - Vector3.zAxis))
	task.delay(OWNER_RESTORE_DELAY, function()
		if chases[chase.owner] == chase and chase.controlling and hitbox.Parent then
			pcall(function()
				hitbox:SetNetworkOwner(chase.owner)
			end)
		end
	end)
end

-- Ends player control; the egg stays for the outcome VFX, then is removed.
local function releaseEgg(chase: ChaseState, delay: number)
	chase.controlling = false
	if chase.owner.Parent then
		chase.owner.ReplicationFocus = nil
		freezeCharacter(chase.owner, false)
	end
	local egg, hitbox = chase.egg, chase.hitbox
	if hitbox then
		hitbox.Anchored = true
	end
	chase.egg, chase.hitbox = nil, nil
	if egg then
		task.delay(delay, function()
			egg:Destroy()
		end)
	end
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

local function lose(chase: ChaseState, reason: "EggCaught" | "Left")
	remotes.EggLost:FireAllClients({ eggUid = chase.eggUid, reason = reason })
	Analytics.custom(chase.owner, "EggLost", 1, reason, chase.petId)
	if reason ~= "Left" then
		bumpStat(chase.owner, "lost")
	end
	releaseEgg(chase, if reason == "Left" then 0 else EGG_CLEANUP_DELAY)
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
	remotes.EggSecured:FireAllClients({ eggUid = chase.eggUid })
	releaseEgg(chase, EGG_CLEANUP_DELAY)
	Analytics.custom(player, "EggSecured", 1, chase.petId)
	Analytics.funnel(player, Analytics.Funnel.FirstSecure, "FirstSecure")
end

-- Tick ---------------------------------------------------------------------

local function sampleEgg(chase: ChaseState, now: number): Vector3
	local hitbox = chase.hitbox
	if not hitbox or not chase.controlling then
		return chase.validPos
	end
	local pos = hitbox.Position
	local fell = pos.Y < chase.landPos.Y - FALL_LIMIT
	if not fell and ChaseService.plausible(chase.validPos, chase.validAt, pos, now, chase.eggSpeed) then
		chase.validPos = pos
		chase.validAt = now
	else
		chase.flags += 1
		if chase.flags == 1 or chase.flags % 20 == 0 then
			warn(`[ChaseService] {chase.owner.Name}'s egg moved implausibly ({chase.flags} snap-backs)`)
		end
		snapBack(chase)
	end
	return chase.validPos
end

local function tick(chase: ChaseState)
	local now = workspace:GetServerTimeNow()
	if not chase.controlling and not chase.resolved and now >= chase.controlStart then
		giveControl(chase)
	end
	local outcome = ChaseService.decide(chase, now, sampleEgg(chase, now))
	if outcome == "EggCaught" then
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
		controlStart = touchdown + Egg.runDelay,
		eggSpeed = ChaseService.eggSpeedFor(DataService:Get(player)),
		egg = nil,
		hitbox = nil,
		controlling = false,
		resolved = false,
		validPos = pending.landPos,
		validAt = workspace:GetServerTimeNow(),
		flags = 0,
	}
	chase.egg, chase.hitbox = buildEgg(chase, pending.eggModel)
	chases[player] = chase
	remotes.ChaseStart:FireAllClients({
		eggUid = chase.eggUid,
		ownerUserId = player.UserId,
		theme = Chase.themeFor(pending.landZone),
		startZ = chase.startZ,
		startTime = chase.startTime,
		speed = chase.speed,
		eggStartPos = chase.landPos,
		eggRunStart = chase.controlStart, -- control starts here (the legs have sprouted)
		eggModel = pending.eggModel,
		rarity = pending.rarity,
	})
end

-- Public API ---------------------------------------------------------------

function ChaseService:GetChase(player: Player): ChaseState?
	return chases[player]
end

-- Re-applies speeds after runSpeed changes (shop purchase, rebirth).
function ChaseService:RefreshWalkSpeed(player: Player)
	local data = DataService:Get(player)
	local _, humanoid = rootPart(player)
	if humanoid and data then
		humanoid.WalkSpeed = data.runSpeed
	end
	local chase = chases[player]
	if chase and not chase.resolved then
		chase.eggSpeed = ChaseService.eggSpeedFor(data)
		if chase.egg then
			chase.egg:SetAttribute("Speed", chase.eggSpeed)
		end
	end
end

function ChaseService:Init()
	for _, name in { "ChaseStart", "EggSecured", "EggLost", "ChaseEnded" } do
		remotes[name] = Remotes.get(name)
	end
	chasesFolder = Instance.new("Folder")
	chasesFolder.Name = "Chases"
	chasesFolder.Parent = workspace
end

function ChaseService:Start()
	KickService:OnTouchdown(startChase)

	-- Walk speed follows the Run Speed upgrade outside chases.
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
