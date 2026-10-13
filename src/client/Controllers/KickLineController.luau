--!strict
-- The kick line (client, every character, so everyone sees the same):
--   * MYSTERY EGG: a character standing on the kick pad (Shared/KickPad.SHOW_RADIUS) and not in a chase holds the
--     black "?" egg (Builders/Models/MysteryEgg) in both hands with a ready stance; it goes the moment they step
--     off. It is only a kick-line visual: never an inventory egg.
--   * KICK CUTSCENE: when the server accepts a kick it stamps the character's KickAt (= the egg's launch time).
--     The egg is tossed up out of the hands, the front kick (Anim/Player.kickPose, the same storyboard as the Kick
--     Sack) is timed so the foot lands exactly at launch, the held egg vanishes and the impact plays there (burst,
--     shockwave, sparks, kick sound; your own kick also flashes and shakes a little). The flying egg
--     (FlightController) takes over from that moment and the camera eases into the flight view.
--     It's cosmetic and short (about 0.6 s); the server already decided the kick, timing and distance.
--   * Reduced Motion skips the toss and the shockwave.
-- One Stepped connection for all characters (after the Animator, before physics); pad checks every CHECK s.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KickPad = require(Shared:WaitForChild("KickPad"))
local PlayerAnim = require(Shared:WaitForChild("Anim"):WaitForChild("Player"))
local MysteryEgg = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("MysteryEgg"))
local VFX = require(Shared:WaitForChild("VFX")) :: any

local CHECK = 0.15
local EGG_SCALE = 0.7
local HOLD_OFFSET = CFrame.new(0, -0.55, -1.25) -- in front of the chest (UpperTorso / Torso space)
local TOSS = 0.32 -- seconds before launch the egg leaves the hands
local IMPACT = PlayerAnim.KICK_IMPACT -- seconds into the kick pose when the foot lands
local FOOT = CFrame.new(0.55, -1.7, -2.4) -- where the foot meets the egg (HumanoidRootPart space)

-- Hands forward around the egg, knees soft (R15 joint -> {pitch, yaw, roll, lift}).
local HOLD_POSE = {
	RShoulder = { 62, 0, -22 },
	RElbow = { 55, 0, 0 },
	LShoulder = { 62, 0, 22 },
	LElbow = { 55, 0, 0 },
	Root = { 0, 0, 0, -0.06 },
	Waist = { 4, 0, 0 },
}
-- Arms flung up as the egg goes up.
local TOSS_POSE = {
	RShoulder = { 140, 0, -18 },
	RElbow = { 20, 0, 0 },
	LShoulder = { 140, 0, 18 },
	LElbow = { 20, 0, 0 },
	Waist = { -8, 0, 0 },
}

local KickLineController = {}

type State = {
	character: Model,
	rig: PlayerAnim.Rig,
	egg: Model?,
	holding: boolean,
	kickAt: number?, -- launch time of the kick being played
	tossFrom: CFrame?,
	impacted: boolean,
	conns: { RBXScriptConnection },
}

local states: { [Model]: State } = {}
local player = Players.LocalPlayer
local checkIn = 0

local function bodyPart(character: Model): BasePart?
	local p = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	return if p and p:IsA("BasePart") then p else nil
end

local function rootOf(character: Model): BasePart?
	local p = character:FindFirstChild("HumanoidRootPart")
	return if p and p:IsA("BasePart") then p else nil
end

local function removeEgg(state: State)
	if state.egg then
		state.egg:Destroy()
		state.egg = nil
	end
end

local function attachEgg(state: State)
	local body = bodyPart(state.character)
	if state.egg or not body then
		return
	end
	local egg = MysteryEgg.build()
	local Builder = require(Shared.Builders.BlockBuilder) :: any
	Builder.scale(egg, EGG_SCALE)
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		end
	end
	local root = egg.PrimaryPart :: BasePart
	local _, size = egg:GetBoundingBox()
	egg:PivotTo(body.CFrame * HOLD_OFFSET * CFrame.new(0, -size.Y / 2, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "HoldWeld"
	weld.Part0, weld.Part1 = body, root
	weld.Parent = root
	egg.Name = "MysteryEgg"
	egg.Parent = state.character
	state.egg = egg
end

local function reduced(): boolean
	return player ~= nil and player:GetAttribute("ReducedMotion") == true
end

local function track(character: Model)
	if states[character] then
		return
	end
	local state: State = {
		character = character,
		rig = PlayerAnim.rig(character),
		egg = nil,
		holding = false,
		kickAt = nil,
		tossFrom = nil,
		impacted = false,
		conns = {},
	}
	states[character] = state
	table.insert(
		state.conns,
		character:GetAttributeChangedSignal("KickAt"):Connect(function()
			local at = character:GetAttribute("KickAt")
			if typeof(at) == "number" then
				state.kickAt, state.tossFrom, state.impacted = at, nil, false
			end
		end)
	)
	table.insert(
		state.conns,
		character.DescendantAdded:Connect(function(d)
			if d:IsA("Motor6D") or d:IsA("AnimationConstraint") then
				state.rig = PlayerAnim.rig(character) -- joints arrive late on streamed-in characters
			end
		end)
	)
	table.insert(
		state.conns,
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				removeEgg(state)
				for _, c in state.conns do
					c:Disconnect()
				end
				states[character] = nil
			end
		end)
	)
end

-- The kick: toss (before launch), then the front kick pose; the impact at launch.
local function playKick(state: State, now: number): boolean
	local at = state.kickAt
	if not at then
		return false
	end
	local t = now - (at - IMPACT) -- seconds into the kick pose
	if t > PlayerAnim.KICK_LENGTH then
		state.kickAt = nil
		return false
	end
	local root = rootOf(state.character)
	local egg = state.egg
	if now < at and egg and root and not reduced() then
		-- toss: the egg leaves the hands, rises and drops onto the kicking foot
		local eggRoot = egg.PrimaryPart :: BasePart
		if not state.tossFrom then
			state.tossFrom = egg:GetPivot()
			local weld = eggRoot:FindFirstChild("HoldWeld")
			if weld then
				weld:Destroy()
			end
			eggRoot.Anchored = true
		end
		local k = math.clamp(1 - (at - now) / TOSS, 0, 1)
		local from = state.tossFrom :: CFrame
		local to = root.CFrame * FOOT
		local pos = from.Position:Lerp(to.Position, k) + Vector3.new(0, math.sin(k * math.pi) * 2.2, 0)
		egg:PivotTo(CFrame.new(pos) * from.Rotation * CFrame.Angles(k * 4, 0, k * 2))
	end
	if now >= at and not state.impacted then
		state.impacted = true
		local point = if root then (root.CFrame * FOOT).Position else nil
		removeEgg(state) -- the flying egg takes over from here
		if point then
			local own = state.character == (player and player.Character)
			local anchor = Instance.new("Part")
			anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
			anchor.Transparency = 1
			anchor.Size = Vector3.new(1, 1, 1)
			anchor.CFrame = CFrame.new(point)
			anchor.Parent = workspace
			task.delay(2, anchor.Destroy, anchor)
			VFX.play("KickImpact", anchor, { power = 12, cutscene = true, own = own })
		end
	end
	if t < 0 then
		PlayerAnim.apply(state.rig, if reduced() then HOLD_POSE else TOSS_POSE)
	else
		PlayerAnim.apply(state.rig, PlayerAnim.kickPose(t))
	end
	return true
end

local function step(dt: number)
	checkIn -= dt
	local check = checkIn <= 0
	if check then
		checkIn = CHECK
	end
	local now = workspace:GetServerTimeNow()
	for character, state in states do
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			removeEgg(state)
			continue
		end
		if playKick(state, now) then
			continue
		end
		if check then
			local onPad = KickPad.has(character, KickPad.SHOW_RADIUS)
			state.holding = onPad and character:GetAttribute("InChase") ~= true
			if state.holding then
				attachEgg(state)
			else
				removeEgg(state)
			end
		end
		if state.holding and state.egg then
			PlayerAnim.apply(state.rig, HOLD_POSE)
		end
	end
end

function KickLineController:Start()
	local function watch(other: Player)
		other.CharacterAdded:Connect(track)
		if other.Character then
			track(other.Character)
		end
	end
	for _, other in Players:GetPlayers() do
		watch(other)
	end
	Players.PlayerAdded:Connect(watch)
	RunService.Stepped:Connect(function(_, dt: number)
		step(dt)
	end)
end

return KickLineController
