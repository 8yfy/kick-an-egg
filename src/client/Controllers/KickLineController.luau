--!strict
-- The kick line (client, every character, so everyone sees the same), and YOUR kick's cinematic:
--   A READY: a character on the kick pad (Shared/KickPad.SHOW_RADIUS), not in a chase, holds the full-size black
--     "?" egg (Builders/Models/MysteryEgg) in both hands with the hold animation (Anim/EggKick.hold: a living
--     loop, hands fitted to the egg); it blends out, and the normal animations come back, the moment they step
--     off. A kick-line prop only: never an inventory egg.
--   B PREPARE: while YOUR timing meter runs (LocalPlayer attribute KickTiming, set by UI/Hud/KickPanel) you
--     brace (Anim/EggKick.brace, crossfaded over the hold) and the camera eases in (field of view) a little.
--   C TIMING: you lock the meter; the server decides the kick and stamps your character's KickAt (= the egg's
--     launch, which is also the kick's CONTACT frame) and KickBand (perfect / good / weak).
--   D KICK: Anim/EggKick plays on the rig (Anim/Mixer, over the Animator) timed so the foot meets the egg exactly
--     at KickAt: gather, toss, planted step, wind-up, strike, follow-through, recovery. The egg leaves the
--     hands at the clip's Release and falls on a ballistic arc onto this avatar's own foot at contact.
--   E CAMERA (yours only, Anim/KickCamera): one continuous shot timed to the clip (a three-quarter view from the
--     kicking side, a push in through the wind-up, a small punch at contact, then a crane round behind you that
--     follows the launched egg), and FlightController takes over (EggKick.cameraBusyUntil), blended, never
--     snapped. Reduced Motion or AUTO KICK (repeated kicking) keep one steady camera instead.
--   F IMPACT at KickAt: VFX KickImpact (burst, ground shockwave, speed streaks along the launch, flash, a small
--     shake on your screen) sized by the band: Perfect is the big one. Sound: Audio KickWeak / Good / Perfect.
--   G LAUNCH: the flying egg (FlightController) leaves at KickAt with the server's real distance.
-- One Stepped connection for all characters; pad checks every CHECK s; one cinematic at a time.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KickPad = require(Shared:WaitForChild("KickPad"))
local EggKick = require(Shared:WaitForChild("Anim"):WaitForChild("EggKick"))
local KickCamera = require(Shared:WaitForChild("Anim"):WaitForChild("KickCamera"))
local MysteryEgg = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("MysteryEgg"))
local VFX = require(Shared:WaitForChild("VFX")) :: any

local CHECK = 0.15
local FOOT = Vector3.new(0.55, -1.6, -2.3) -- fallback contact point (HumanoidRootPart space) for rigs without one
local TOSS_APEX = 2.2 -- studs the tossed egg rises above where it leaves the hands
local POWER = { weak = 6, good = 12, perfect = 24 }

local KickLineController = {}

type State = {
	character: Model,
	egg: Model?,
	holding: boolean,
	stopHold: ((fade: number?) -> ())?,
	kickAt: number?,
	kick: EggKick.Playing?,
	toss: ((now: number) -> ())?, -- moves the tossed egg (EggKick.toss)
	impacted: boolean,
	conns: { RBXScriptConnection },
}

local states: { [Model]: State } = {}
local player = Players.LocalPlayer
local checkIn = 0
local stopCinematic: (() -> ())? = nil
local fovBase: number? = nil

local function bodyPart(character: Model): BasePart?
	local p = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	return if p and p:IsA("BasePart") then p else nil
end

local function rootOf(character: Model): BasePart?
	local p = character:FindFirstChild("HumanoidRootPart")
	return if p and p:IsA("BasePart") then p else nil
end

local function reduced(): boolean
	return player ~= nil and player:GetAttribute("ReducedMotion") == true
end

local function removeEgg(state: State)
	if state.egg then
		state.egg:Destroy()
		state.egg = nil
	end
end

local function stopHolding(state: State, fade: number?)
	if state.stopHold then
		state.stopHold(fade)
		state.stopHold = nil
	end
	EggKick.brace(state.character, false)
end

local function attachEgg(state: State)
	local body = bodyPart(state.character)
	if state.egg or not body then
		return
	end
	local egg = MysteryEgg.build()
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
		end
	end
	egg.Name = "MysteryEgg"
	if not EggKick.attach(state.character, egg) then -- fitted to this body, hands on its sides
		egg:Destroy()
		return
	end
	egg.Parent = state.character
	state.egg = egg
	if not state.stopHold then
		state.stopHold = EggKick.hold(state.character)
	end
end

-- Your camera ---------------------------------------------------------------------------------------------------
local function setFov(target: number, seconds: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	fovBase = fovBase or cam.FieldOfView
	TweenService:Create(cam, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { FieldOfView = target }):Play()
end

-- The launched egg (FlightController's ClientEggs), once it is flying: the cinematic follows it.
local function flyingEgg(): Vector3?
	local folder = workspace:FindFirstChild("ClientEggs")
	for _, egg in if folder then folder:GetChildren() else {} do
		if egg:IsA("Model") then
			local pos = egg:GetPivot().Position
			if pos.Y > -100 then -- (waiting out of sight at -500 before the launch)
				return pos + Vector3.new(0, 1.7, 0)
			end
		end
	end
	return nil
end

-- E: one continuous shot timed to the kick clip (Anim/KickCamera); Reduced Motion / AUTO KICK keep the steady
-- camera (FlightController takes it at the launch).
local function playCinematic(state: State, contactAt: number)
	local cam = workspace.CurrentCamera
	local steady = reduced() or player:GetAttribute("AutoKick") == true
	if stopCinematic then
		stopCinematic()
		stopCinematic = nil
	end
	if steady or not cam or not rootOf(state.character) then
		EggKick.cameraBusyUntil = contactAt
		return
	end
	local kick = state.kick
	local clipTime = if kick
		then kick.handle.time
		else function()
			return workspace:GetServerTimeNow() - (contactAt - EggKick.CONTACT)
		end
	stopCinematic = KickCamera.play(state.character, contactAt, clipTime, flyingEgg, fovBase or cam.FieldOfView)
end

-- The kick ------------------------------------------------------------------------------------------------------
local function startKick(state: State, at: number)
	if state.kick then
		state.kick.stop()
	end
	state.stopHold = nil -- (EggKick.play blends the hold and brace out under the kick)
	state.kickAt, state.toss, state.impacted = at, nil, false
	state.kick = EggKick.play(state.character, at)
	if state.character == (player and player.Character) then
		playCinematic(state, at)
	end
end

local function track(character: Model)
	if states[character] then
		return
	end
	local state: State = {
		character = character,
		egg = nil,
		holding = false,
		stopHold = nil,
		kickAt = nil,
		kick = nil,
		impacted = false,
		conns = {},
	}
	states[character] = state
	table.insert(
		state.conns,
		character:GetAttributeChangedSignal("KickAt"):Connect(function()
			local at = character:GetAttribute("KickAt")
			if typeof(at) == "number" then
				startKick(state, at)
			end
		end)
	)
	table.insert(
		state.conns,
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				removeEgg(state)
				stopHolding(state, 0)
				if state.kick then
					state.kick.stop()
				end
				for _, c in state.conns do
					c:Disconnect()
				end
				states[character] = nil
			end
		end)
	)
end

-- Where the foot's laces are at contact (world), for this character.
local function contactPoint(state: State, root: BasePart): Vector3
	local kick = state.kick
	return root.CFrame * (if kick and kick.contact then kick.contact else FOOT)
end

-- The egg during the kick: it leaves the hands at the clip's Release and flies a ballistic arc (one gravity, up
-- then down) that ends with its lower back on the laces at contact; gone at contact (the flying egg takes over).
-- Returns true while the kick is running.
local function stepKick(state: State, now: number): boolean
	local at = state.kickAt
	if not at then
		return false
	end
	local t = now - (at - EggKick.CONTACT) -- seconds into the clip
	if t > EggKick.LENGTH then
		state.kickAt = nil
		state.kick = nil
		return false
	end
	local root = rootOf(state.character)
	local egg = state.egg
	local kick = state.kick
	local releaseAt = if kick then kick.releaseAt else at - EggKick.CONTACT + EggKick.RELEASE
	if now < at and now >= releaseAt and egg and root then
		if not state.toss then
			state.toss =
				EggKick.toss(egg, root, contactPoint(state, root), at, now, if reduced() then 0.8 else TOSS_APEX)
		end
		(state.toss :: (number) -> ())(now)
	end
	if now >= at and not state.impacted then
		state.impacted = true
		local point = if root then contactPoint(state, root) else nil
		removeEgg(state)
		if point then
			local own = state.character == (player and player.Character)
			local band = state.character:GetAttribute("KickBand")
			local b = if typeof(band) == "string" then band else "good"
			local anchor = Instance.new("Part")
			anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
			anchor.Transparency = 1
			anchor.Size = Vector3.new(1, 1, 1)
			anchor.CFrame = CFrame.new(point)
			anchor.Parent = workspace
			task.delay(2, anchor.Destroy, anchor)
			VFX.play("KickImpact", anchor, { power = POWER[b] or 12, cutscene = true, own = own, band = b })
		end
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
			stopHolding(state)
			continue
		end
		if stepKick(state, now) then
			continue
		end
		if check then
			local onPad = KickPad.has(character, KickPad.SHOW_RADIUS)
			state.holding = onPad and character:GetAttribute("InChase") ~= true
			if state.holding then
				attachEgg(state)
			else
				removeEgg(state)
				stopHolding(state) -- the normal animations come back
			end
		end
	end
	-- B: your brace while the meter runs (a layer crossfaded over the hold)
	local mine = player and player.Character and states[player.Character]
	local bracing = mine ~= nil and mine.holding and not mine.kickAt and player:GetAttribute("KickTiming") == true
	if mine and mine.character:GetAttribute("KickBrace") ~= bracing then
		mine.character:SetAttribute("KickBrace", bracing) -- (local)
		EggKick.brace(mine.character, bracing)
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
	if player then
		player:GetAttributeChangedSignal("KickTiming"):Connect(function()
			if reduced() then
				return
			end
			if player:GetAttribute("KickTiming") == true then
				setFov(math.max(55, (fovBase or 70) - 8), 0.35) -- B: the camera eases in while you time it
			else
				setFov(fovBase or 70, 0.5)
			end
		end)
	end
	RunService.Stepped:Connect(function(_, dt: number)
		step(dt)
	end)
end

return KickLineController
