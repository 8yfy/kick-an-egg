--!strict
-- The kick line (client, every character, so everyone sees the same), and YOUR kick's cinematic:
--   A READY: a character on the kick pad (Shared/KickPad.SHOW_RADIUS), not in a chase, holds the full-size black
--     "?" egg (Builders/Models/MysteryEgg) in both hands with the hold animation (Anim/EggKick.hold); it goes,
--     and the normal animations come back, the moment they step off. A kick-line prop only: never an
--     inventory egg.
--   B PREPARE: while YOUR timing meter runs (LocalPlayer attribute KickTiming, set by UI/Hud/KickPanel) you
--     brace (a lower hold) and the camera eases in (field of view) a little.
--   C TIMING: you lock the meter; the server decides the kick and stamps your character's KickAt (= the egg's
--     launch, which is also the kick's CONTACT frame) and KickBand (perfect / good / weak).
--   D KICK: Anim/EggKick plays on the rig (Animator track once published / in Studio; the same keyframes on the
--     joints otherwise) timed so the foot meets the egg exactly at KickAt: toss, wind-up, coil, strike,
--     hit-stop, follow-through. The egg leaves the hands on the toss and drops onto the foot.
--   E CAMERA (yours only): a low-angle anticipation shot, a side shot of the strike, a fast close-up on the
--     impact, then FlightController takes over and follows the egg (EggKick.cameraBusyUntil hands it over),
--     blended, never snapped. Reduced Motion or AUTO KICK (repeated kicking) keep one steady camera instead.
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
local PlayerAnim = require(Shared:WaitForChild("Anim"):WaitForChild("Player"))
local EggKick = require(Shared:WaitForChild("Anim"):WaitForChild("EggKick"))
local MysteryEgg = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("MysteryEgg"))
local VFX = require(Shared:WaitForChild("VFX")) :: any

local CHECK = 0.15
local HOLD_OFFSET = CFrame.new(0, -0.35, -1.95) -- egg centre in front of the chest, between the hands (UpperTorso)
local TOSS_START = 0.14 -- seconds into the clip the egg leaves the hands
local FOOT = CFrame.new(0.55, -1.6, -2.3) -- where the foot meets the egg at contact (HumanoidRootPart space)
local POWER = { weak = 6, good = 12, perfect = 24 }

local KickLineController = {}

type State = {
	character: Model,
	egg: Model?,
	holding: boolean,
	stopHold: (() -> ())?,
	kickAt: number?,
	kick: EggKick.Playing?,
	tossFrom: CFrame?,
	impacted: boolean,
	conns: { RBXScriptConnection },
}

local states: { [Model]: State } = {}
local player = Players.LocalPlayer
local checkIn = 0
local cinematicToken = 0
local braceRig: PlayerAnim.Rig? = nil
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

local function stopHolding(state: State)
	if state.stopHold then
		state.stopHold()
		state.stopHold = nil
	end
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

-- The shots (relative to contact c = KickAt), from the kicker's root: forward = the kick direction (+Z track).
local function shot(root: BasePart, t: number): (CFrame, number)
	local pos = root.Position
	local fwd = Vector3.new(0, 0, 1)
	local right = Vector3.new(1, 0, 0)
	local up = Vector3.yAxis
	local foot = (root.CFrame * FOOT).Position
	if t < -0.3 then -- 1: low angle, front-side, looking up at the wind-up; slow push in
		local k = math.clamp((t + 0.62) / 0.32, 0, 1)
		local eye = pos + right * (5 - k) + fwd * (8 - k * 1.5) - up * 1.6
		return CFrame.lookAt(eye, pos + up * 1.2), 62
	elseif t < -0.05 then -- 2: side angle at hip height, the strike crossing the frame
		local k = math.clamp((t + 0.3) / 0.25, 0, 1)
		local eye = pos + right * (10 - k * 1.5) + up * 0.6 + fwd * (0.8 + k * 0.8)
		return CFrame.lookAt(eye, pos + fwd * 1.4), 55
	else -- 3: impact close-up on the foot and egg
		local eye = foot + right * 4.2 + up * 0.8 - fwd * 1.4
		return CFrame.lookAt(eye, foot + fwd * 0.6), 48
	end
end

local function playCinematic(state: State, contactAt: number, band: string)
	cinematicToken += 1
	local token = cinematicToken
	local cam = workspace.CurrentCamera
	local root = rootOf(state.character)
	local steady = reduced() or player:GetAttribute("AutoKick") == true
	EggKick.cameraBusyUntil = contactAt + (if steady then 0 else 0.14)
	if steady or not cam or not root then
		return -- one steady camera: FlightController takes it at the launch
	end
	local fovStart = cam.FieldOfView
	local prevType = cam.CameraType
	local blendFrom = cam.CFrame
	local blendStart = os.clock()
	cam.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("KTE_KickCinematic", Enum.RenderPriority.Camera.Value + 2, function()
		local now = workspace:GetServerTimeNow()
		local t = now - contactAt
		if token ~= cinematicToken or not root.Parent or t > 0.14 then
			RunService:UnbindFromRenderStep("KTE_KickCinematic")
			if token == cinematicToken and not root.Parent then
				cam.CameraType = prevType -- interrupted (respawn): give the normal camera back
				cam.FieldOfView = fovStart
			end
			return
		end
		local cf, fov = shot(root, t)
		local blend = math.clamp((os.clock() - blendStart) / 0.12, 0, 1) -- ease in from where the camera was
		cam.CFrame = blendFrom:Lerp(cf, blend * blend * (3 - 2 * blend))
		cam.FieldOfView = cam.FieldOfView + (fov - cam.FieldOfView) * 0.35
	end)
	task.delay(math.max(0, contactAt - workspace:GetServerTimeNow()) + 1.2, function()
		if token == cinematicToken and cam.FieldOfView ~= fovStart then
			TweenService:Create(cam, TweenInfo.new(0.4), { FieldOfView = fovBase or fovStart }):Play()
		end
	end)
end

-- The kick ------------------------------------------------------------------------------------------------------
local function startKick(state: State, at: number)
	if state.kick then
		state.kick.stop()
	end
	stopHolding(state)
	state.kickAt, state.tossFrom, state.impacted = at, nil, false
	state.kick = EggKick.play(state.character, at)
	if state.character == (player and player.Character) then
		local band = state.character:GetAttribute("KickBand")
		playCinematic(state, at, if typeof(band) == "string" then band else "good")
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
				startKick(state, at)
			end
		end)
	)
	table.insert(
		state.conns,
		character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				removeEgg(state)
				stopHolding(state)
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

-- The egg during the kick: toss out of the hands, rise, drop onto the foot; gone at contact (the flying egg
-- takes over). Returns true while the kick is running.
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
	if now < at and t >= TOSS_START and egg and root then
		local eggRoot = egg.PrimaryPart :: BasePart
		if not state.tossFrom then
			state.tossFrom = egg:GetPivot()
			local weld = eggRoot:FindFirstChild("HoldWeld")
			if weld then
				weld:Destroy()
			end
			eggRoot.Anchored = true
		end
		local k = math.clamp((t - TOSS_START) / (EggKick.CONTACT - TOSS_START), 0, 1)
		local from = state.tossFrom :: CFrame
		local to = root.CFrame * FOOT
		local _, size = egg:GetBoundingBox()
		local pos = from.Position:Lerp(to.Position - Vector3.new(0, size.Y / 2, 0), k)
			+ Vector3.new(0, math.sin(k * math.pi) * (if reduced() then 1 else 3.2), 0)
		egg:PivotTo(CFrame.new(pos) * from.Rotation * CFrame.Angles(k * 3, 0, k * 1.5))
	end
	if now >= at and not state.impacted then
		state.impacted = true
		local point = if root then (root.CFrame * FOOT).Position else nil
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
	-- B: your brace while the meter runs (on top of the hold)
	local mine = player and player.Character and states[player.Character]
	local bracing = mine ~= nil and mine.holding and not mine.kickAt and player:GetAttribute("KickTiming") == true
	if mine and mine.character:GetAttribute("KickBrace") ~= bracing then
		mine.character:SetAttribute("KickBrace", bracing) -- (local: the hold steps aside while you brace)
	end
	if mine and bracing then
		braceRig = braceRig or PlayerAnim.rig(mine.character)
		PlayerAnim.apply(braceRig :: PlayerAnim.Rig, EggKick.BRACED)
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
		player.CharacterAdded:Connect(function()
			braceRig = nil
		end)
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
