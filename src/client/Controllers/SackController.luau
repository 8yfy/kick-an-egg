--!strict
-- Kick Sack gear, client (Partner B). Draws every player's sack from the character attributes that
-- SackService sets (SackAt, SackTier, SackPlaced, SackHits):
--   * the drop: the sack falls out of the sky on its chain, slams to a stop (hit-stop, squash, BONK)
--     and springs back; a moved / removed sack is yanked back up into the sky
--   * the sack is a damped pendulum: every kick swings it away and squashes it, then it swings back
--   * characters with a sack out hold a fighting stance and play the kick (Anim/Player poses)
--   * the local player kicks with a left click (a tap on mobile) while the sack is out (the SACK box next
--     to KICK equips its Tool): at most one kick per Config/Upgrades.Sack.interval, one quick click is
--     buffered; Remotes.Train fires at the moment the foot lands.
-- Other players' kicks come from their SackHits counter. All of it is local-only visuals.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Upgrades = require(Shared:WaitForChild("Config"):WaitForChild("Upgrades"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Builder = require(Shared:WaitForChild("Builders"):WaitForChild("BlockBuilder"))
local Sacks = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks"))
local PlayerAnim = require(Shared:WaitForChild("Anim"):WaitForChild("Player"))
local VFX = require(Shared:WaitForChild("VFX")) :: any
local SackFx = require(Shared:WaitForChild("VFX"):WaitForChild("Sack"))
local SackAura = require(Shared:WaitForChild("VFX"):WaitForChild("SackAura"))

local SACK = Upgrades.Sack
local SKY = 48 -- studs above the hang point the drop starts from / the retract ends at
local FALL = 0.22 -- seconds of free fall before the slam
local SLAM_STOP = 0.06 -- hit-stop when the chain catches
local RETRACT = 0.3
local CHAIN_LINKS = 20 -- links drawn above the model's own chain; a plain rod continues into the sky
local LINK_STEP = 0.34 -- studs between links (the remodel's chain)
local SWING_W = 7 -- pendulum frequency (rad/s) and damping
local SWING_DAMP = 3.2
local SQUASH_K, SQUASH_C = 320, 15 -- kick squash spring
local DROP_K, DROP_C = 190, 9 -- drop squash spring
local PLACE_DIST = Sacks.KICK_DIST -- matches SackService: root to sack axis
local FAR = 220 -- beyond this many studs from the camera, idle sacks stop animating
local FX_RANGE = 140 -- idle VFX (SackAura) only run within this many studs of the camera
local CLICK_BUFFER = 0.45 -- seconds a click made mid-kick is kept for the next kick

type Piece = { part: BasePart, rel: CFrame, size: Vector3, squash: boolean, scaled: boolean }
type Sack = {
	model: Model,
	fx: any, -- SackAura context (the tier's idle VFX), stepped after the sack moves
	pieces: { Piece },
	parts: { BasePart },
	at: CFrame,
	tier: number,
	born: number,
	dropped: boolean,
	leaving: number?,
	upgrade: boolean,
	own: boolean,
	theta: number,
	omega: number,
	phi: number,
	phiV: number,
	q: number,
	qv: number,
	v: number,
	vv: number,
	freeze: number,
}
type Char = {
	character: Model,
	player: Player,
	rig: PlayerAnim.Rig,
	sack: Sack?,
	kickAt: number?,
	kicks: number,
	hits: number,
	conns: { RBXScriptConnection },
}

local SackController = {}

local localPlayer = Players.LocalPlayer
local chars: { [Model]: Char } = {}
local leaving: { Sack } = {}
local rng = Random.new()
local lastKick = 0
local folder: Folder? = nil

local function sackFolder(): Folder
	local f = folder
	if f and f.Parent then
		return f
	end
	local nf = Instance.new("Folder")
	nf.Name = "Sacks"
	nf.Parent = workspace
	folder = nf
	return nf
end

local function stepOf(tier: number): number
	local fx = SACK.tiers[math.clamp(tier, 1, #SACK.tiers)].fx
	return (({ Basics = 1, Comic = 2, Champion = 3, Elemental = 4, Mythic = 5, God = 6 }) :: any)[fx] or 1
end

-- Sack model -----------------------------------------------------------------

local function addChain(model: Model, look: Sacks.Look)
	local function part(name: string, size: Vector3, cf: CFrame, material: Enum.Material, shape: Enum.PartType?)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = look.chain
		p.Material = material
		if shape then
			p.Shape = shape
		end
		p.Parent = model
	end
	local up = CFrame.Angles(0, 0, math.rad(90))
	local top = Sacks.CHAIN_TOP
	if look.rope then
		part(
			"Rope",
			Vector3.new(80, 0.17, 0.17),
			CFrame.new(0, top + 40, 0) * up,
			Enum.Material.Fabric,
			Enum.PartType.Cylinder
		)
		return
	end
	for i = 1, CHAIN_LINKS do
		local y = top + (i - 0.5) * LINK_STEP
		local yaw = if i % 2 == 0 then 0 else math.rad(90)
		part("Link", Vector3.new(0.3, 0.44, 0.08), CFrame.new(0, y, 0) * CFrame.Angles(0, yaw, 0), Enum.Material.Metal)
	end
	local start = top + CHAIN_LINKS * LINK_STEP
	part(
		"Rod",
		Vector3.new(80, 0.2, 0.2),
		CFrame.new(0, start + 40, 0) * up,
		Enum.Material.Metal,
		Enum.PartType.Cylinder
	)
end

local function build(tier: number, at: CFrame, own: boolean): Sack
	local model = Builder.build(Sacks.spec(tier), "Sack")
	addChain(model, Sacks.look(tier))
	for _, d in model:GetDescendants() do
		if d:IsA("WeldConstraint") or d:IsA("Motor6D") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
		end
	end
	-- the tier's idle VFX, built around the origin (= the hang point) like the sack; we step it
	local fx = SackAura.Apply(model, tier, Sacks.vfxRoot(tier), Sacks.SCALE, true)
	local pieces: { Piece } = {}
	local parts: { BasePart } = {}
	for _, d in model:GetDescendants() do
		-- parts the VFX poses itself (wings, arms) stay out: it re-poses them from its root every step
		if d:IsA("BasePart") and d:GetAttribute("SackVFX_Rest") == nil then
			local rel = d.CFrame
			local squash = rel.Y < -1 and not d:IsDescendantOf(fx.folder)
			table.insert(pieces, { part = d, rel = rel, size = d.Size, squash = squash, scaled = false })
			table.insert(parts, d)
		end
	end
	model:PivotTo(at + Vector3.new(0, SKY, 0))
	model.Parent = sackFolder()
	return {
		model = model,
		fx = fx,
		pieces = pieces,
		parts = parts,
		at = at,
		tier = tier,
		born = os.clock(),
		dropped = false,
		upgrade = false,
		own = own,
		theta = 0,
		omega = 0,
		phi = 0,
		phiV = 0,
		q = 0,
		qv = 0,
		v = 0,
		vv = 0,
		freeze = 0,
	}
end

local function floorOf(s: Sack): Vector3
	return s.at.Position - Vector3.new(0, Sacks.HANG, 0)
end

local function retract(s: Sack)
	if not s.leaving then
		s.leaving = os.clock()
		table.insert(leaving, s)
	end
end

-- Size of a part whose model-space axes are scaled by `scale` (exact for axis-aligned parts).
local function scaledSize(rel: CFrame, size: Vector3, scale: Vector3): Vector3
	local function axis(v: Vector3): number
		return (v * scale).Magnitude
	end
	return Vector3.new(size.X * axis(rel.RightVector), size.Y * axis(rel.UpVector), size.Z * axis(-rel.LookVector))
end

-- Advances one sack and writes its parts. Returns false once a leaving sack is gone.
local function stepSack(s: Sack, now: number, dt: number, camPos: Vector3): boolean
	local age = now - s.born
	local yOff = 0
	if s.leaving then
		local k = (now - s.leaving) / RETRACT
		if k >= 1 then
			s.model:Destroy()
			return false
		end
		yOff = SKY * k * k
	elseif not s.dropped then
		local k = math.clamp(age / FALL, 0, 1)
		yOff = SKY * (1 - k * k)
		if k >= 1 then
			s.dropped = true
			s.v, s.vv = -0.32, 0
			s.freeze = now + SLAM_STOP
			s.phiV = rng:NextNumber(-0.5, 0.5)
			VFX.play("SackDrop", s.model, { tier = s.tier, floor = floorOf(s), own = s.own })
			if s.upgrade then
				VFX.play("SackUpgrade", s.model, { tier = s.tier, floor = floorOf(s) }) -- the base stand announces it
			end
		end
	elseif (s.at.Position - camPos).Magnitude > FAR and s.q == 0 then
		return true -- far away and settled: leave it where it is
	end

	if now >= s.freeze then
		local h = math.min(dt, 1 / 30)
		s.omega += (-SWING_W * SWING_W * math.sin(s.theta) - SWING_DAMP * s.omega) * h
		s.theta += s.omega * h
		s.phiV += (-SWING_W * SWING_W * math.sin(s.phi) - SWING_DAMP * s.phiV) * h
		s.phi += s.phiV * h
		s.qv += (-SQUASH_K * s.q - SQUASH_C * s.qv) * h
		s.q += s.qv * h
		s.vv += (-DROP_K * s.v - DROP_C * s.vv) * h
		s.v += s.vv * h
		if math.abs(s.q) < 0.002 and math.abs(s.qv) < 0.01 then
			s.q, s.qv = 0, 0
		end
	end

	local sway = 0.03 * math.sin(now * 1.3 + s.born)
	local hang = s.at * CFrame.new(0, yOff, 0) * CFrame.Angles(s.theta + sway, 0, s.phi + sway * 0.6)
	-- kick squash (along the kick, local Z) and drop squash (vertical), about the body's centre
	local scale =
		Vector3.new((1 - s.q * 0.5) * (1 - s.v * 0.5), (1 - s.q * 0.3) * (1 + s.v), (1 + s.q) * (1 - s.v * 0.5))
	local squashing = (scale - Vector3.one).Magnitude > 0.004
	local center = Vector3.new(0, Sacks.CENTER, 0)
	local cframes = table.create(#s.pieces)
	for i, piece in s.pieces do
		local rel = piece.rel
		if piece.squash and squashing then
			local p = center + (rel.Position - center) * scale
			rel = CFrame.new(p) * rel.Rotation
			piece.part.Size = scaledSize(piece.rel, piece.size, scale)
			piece.scaled = true
		elseif piece.scaled then
			piece.part.Size = piece.size -- squash over: back to rest (sizes are otherwise the VFX's to animate)
			piece.scaled = false
		end
		cframes[i] = hang * rel
	end
	workspace:BulkMoveTo(s.parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	if (s.at.Position - camPos).Magnitude < FX_RANGE then
		s.fx:step(dt) -- after the move: orbits, wings and particles follow the swinging sack
	end
	return true
end

-- Kicks -----------------------------------------------------------------------

local function impactPoint(s: Sack): Vector3
	return (s.at * CFrame.new(0, 2.4 - Sacks.HANG, -Sacks.RADIUS)).Position -- where the sole lands (2.4 up)
end

local function land(c: Char, s: Sack, own: boolean, super: boolean)
	if c.sack ~= s or s.leaving or not s.dropped then
		return
	end
	local power = if super then 1.6 else 1
	s.omega -= 2.6 * power -- away from the kicker (the sack's front faces them)
	s.phiV += rng:NextNumber(-0.7, 0.7)
	s.q, s.qv = -0.15 * power, 0
	s.freeze = os.clock() + (if super and stepOf(s.tier) >= 6 then 0.1 else 0.04)
	VFX.play("SackHit", s.model, {
		tier = s.tier,
		at = impactPoint(s),
		dir = -s.at.LookVector,
		floor = floorOf(s),
		own = own,
		super = super,
		gain = if own then SACK.tiers[math.clamp(s.tier, 1, #SACK.tiers)].gain else nil,
	})
end

local function startKick(c: Char, own: boolean)
	local s = c.sack
	if not s then
		return
	end
	c.kickAt = os.clock()
	c.kicks += 1
	local super = c.kicks % 10 == 0 and stepOf(s.tier) >= 5
	local removeTrail = SackFx.legTrail(c.character, s.tier)
	task.delay(PlayerAnim.KICK_IMPACT, function()
		if own then
			Remotes.get("Train"):FireServer()
		end
		land(c, s, own, super)
	end)
	task.delay(PlayerAnim.KICK_LENGTH, removeTrail)
end

local function toolOut(character: Model): boolean
	local tool = character:FindFirstChildOfClass("Tool")
	return tool ~= nil and tool:GetAttribute("KickSack") == true
end

-- One local kick, if the sack is out and in reach and the last kick has finished. Returns whether it kicked.
local function tryKick(now: number): boolean
	local character = localPlayer.Character
	local c = character and chars[character]
	local s = c and c.sack
	if not c or not s or not character or s.leaving or not s.dropped then
		return false
	end
	if now - s.born < SACK.dropSeconds or now - lastKick < SACK.interval or not toolOut(character) then
		return false
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hrp:IsA("BasePart") or not humanoid then
		return false
	end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		return false
	end
	local axis = Vector3.new(s.at.X, hrp.Position.Y, s.at.Z)
	local offset = hrp.Position - axis
	if offset.Magnitude > SACK.range - 0.5 then
		return false
	end
	-- square up to the sack at kicking distance (small nudges only)
	local dir = if offset.Magnitude > 0.1 then offset.Unit else s.at.LookVector
	local ideal = axis + Vector3.new(dir.X, 0, dir.Z).Unit * PLACE_DIST
	local pos = if (ideal - hrp.Position).Magnitude < 1.5 then ideal else hrp.Position
	hrp.CFrame = CFrame.lookAt(pos, Vector3.new(axis.X, pos.Y, axis.Z))
	lastKick = now
	startKick(c, true)
	return true
end

-- Left click / tap with the sack out (the Tool's Activated) kicks. A click during the previous kick is
-- remembered for CLICK_BUFFER seconds, so quick clicking chains kicks without dropping any.
local queuedUntil = 0
local hooked: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function hookTool(child: Instance)
	if child:IsA("Tool") and child:GetAttribute("KickSack") and not hooked[child] then
		hooked[child] = true
		child.Activated:Connect(function()
			local now = os.clock()
			if not tryKick(now) then
				queuedUntil = now + CLICK_BUFFER
			end
		end)
	end
end

-- Characters ----------------------------------------------------------------

local function refresh(c: Char)
	local character = c.character
	local at = character:GetAttribute("SackAt")
	local tier = character:GetAttribute("SackTier")
	local current = c.sack
	if typeof(at) ~= "CFrame" or typeof(tier) ~= "number" then
		if current then
			retract(current)
			c.sack = nil
		end
		return
	end
	if current and current.at == at and current.tier == tier then
		return
	end
	local upgraded = current ~= nil and tier > current.tier
	if current then
		retract(current)
	end
	local own = c.player == localPlayer
	local s = build(tier, at, own)
	s.upgrade = upgraded
	local placed = character:GetAttribute("SackPlaced")
	if not current and typeof(placed) == "number" and workspace:GetServerTimeNow() - placed > 1.5 then
		s.born -= 2 -- already hanging when we arrived: skip the drop
		s.dropped = true
	end
	c.sack = s
end

local function track(player: Player, character: Model)
	local c: Char = {
		character = character,
		player = player,
		rig = PlayerAnim.rig(character),
		kicks = 0,
		hits = 0,
		conns = {},
	}
	chars[character] = c
	local hits = character:GetAttribute("SackHits")
	c.hits = if typeof(hits) == "number" then hits else 0
	for _, name in { "SackAt", "SackTier" } do
		table.insert(
			c.conns,
			character:GetAttributeChangedSignal(name):Connect(function()
				task.defer(refresh, c) -- SackAt / SackTier / SackPlaced arrive together; read them once
			end)
		)
	end
	table.insert(
		c.conns,
		character:GetAttributeChangedSignal("SackHits"):Connect(function()
			local n = character:GetAttribute("SackHits")
			if typeof(n) ~= "number" or n <= c.hits then
				return
			end
			c.hits = n
			if player ~= localPlayer then
				startKick(c, false)
			end
		end)
	)
	table.insert(
		c.conns,
		character.DescendantAdded:Connect(function(d)
			if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
				c.rig = PlayerAnim.rig(character) -- joints arrive late on streamed-in characters
			end
		end)
	)
	table.insert(
		c.conns,
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				for _, conn in c.conns do
					conn:Disconnect()
				end
				if c.sack then
					retract(c.sack)
				end
				chars[character] = nil
			end
		end)
	)
	refresh(c)
end

local function standing(c: Char): boolean
	local hrp = c.character:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		return false
	end
	local v = hrp.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude < 2.5 and math.abs(v.Y) < 6
end

function SackController:Start()
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		SackAura.Quality = 0.6 -- fewer custom particles on phones
	end
	local function added(player: Player)
		player.CharacterAdded:Connect(function(character)
			track(player, character)
		end)
		if player.Character then
			track(player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(added)
	for _, player in Players:GetPlayers() do
		added(player)
	end

	-- the sack Tool lives in the backpack (a new one after every respawn) or in hand
	local function hookAll(container: Instance)
		for _, child in container:GetChildren() do
			hookTool(child)
		end
		container.ChildAdded:Connect(hookTool)
	end
	localPlayer.ChildAdded:Connect(function(child)
		if child:IsA("Backpack") then
			hookAll(child)
		end
	end)
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		hookAll(backpack)
	end
	localPlayer.CharacterAdded:Connect(hookAll)
	if localPlayer.Character then
		hookAll(localPlayer.Character)
	end

	-- poses after the Animator, before physics
	RunService.Stepped:Connect(function()
		local now = os.clock()
		for _, c in chars do
			local s = c.sack
			if s and s.dropped and not s.leaving then
				local kickAt = c.kickAt
				if kickAt and now - kickAt < PlayerAnim.KICK_LENGTH then
					PlayerAnim.apply(c.rig, PlayerAnim.kickPose(now - kickAt))
				elseif standing(c) then
					PlayerAnim.apply(c.rig, PlayerAnim.guardPose(now))
				end
			end
		end
	end)

	local last = os.clock()
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local dt = now - last
		last = now
		local cam = workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else Vector3.zero
		if queuedUntil > now and tryKick(now) then
			queuedUntil = 0
		end
		for _, c in chars do
			local s = c.sack
			if s then
				stepSack(s, now, dt, camPos)
			end
		end
		for i = #leaving, 1, -1 do
			if not stepSack(leaving[i], now, dt, camPos) then
				table.remove(leaving, i)
			end
		end
	end)
end

return SackController
