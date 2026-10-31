--!strict
-- Partner A. Pet loops on BlockBuilder rigs (Body/Head/LegL/LegR/ArmL/ArmR/WingL/WingR/Tail).
--   Idle    bob, slow head look-around, tail wag, blink every 2-5 s
--   Waddle  idle + body roll and a diagonal (trot) leg swing
--   Hop     the whole rig hops every ~1.2 s with squash and stretch (root never moves)
--   Sleep   slow breathing, head drooped, eyes shut, "Z"s drifting up
-- Motion follows the pet's rarity (its "Rarity" attribute, docs/EggPetPlan.md "Effects and motion by rarity"):
-- commons are bouncy (quick bob, big waddle roll, a random hop every few seconds); rarer pets get calmer and
-- prouder, and from Rare up they flourish (head toss, tail flick, wings spread, a paw lift) every 7-14 s, or
-- exactly when their PetFx special fires (PetFx sets the model attribute PetFxSpecial).
-- Hovering pets (no part near the feet: bees, spirits, fish) float, lean into their walk and let their legs
-- dangle; hovering pets with wings buzz them. Grounded winged pets keep their wings still unless they hop or walk.
-- Every group turns in the ROOT's frame about its own pivot (its first part), whatever that part's rotation, and
-- rides along with the body's bob and roll.
-- Eyes are the parts named EyeL/EyeR (+ GlintL/GlintR, PupilL/PupilR), per the Models/Kit convention.
-- Serpent rigs (a Coil joint, e.g. the Frost Serpent) keep the coil on the ground and sway the body about its base
-- instead: every group is its own Motor6D on Root, so the head, wings and arms follow that sway explicitly.
local RunService = game:GetService("RunService")
local Rig = require(script.Parent.Rig)

local Pet = {}

local rng = Random.new()

type Eyes = { parts: { BasePart }, glints: { BasePart }, sizes: { [BasePart]: Vector3 } }

local function eyes(model: Model): Eyes
	local e: Eyes = { parts = {}, glints = {}, sizes = {} }
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "EyeL" or d.Name == "EyeR" or d.Name == "PupilL" or d.Name == "PupilR" then
				table.insert(e.parts, d)
				e.sizes[d] = d.Size
			elseif d.Name == "GlintL" or d.Name == "GlintR" then
				table.insert(e.glints, d)
			end
		end
	end
	return e
end

-- Eyes squash to a slit (welded parts resize around their centre).
local function setEyes(e: Eyes, open: number)
	for _, p in e.parts do
		local s = e.sizes[p]
		p.Size = Vector3.new(s.X, math.max(0.05, s.Y * open), s.Z)
	end
	for _, g in e.glints do
		g.LocalTransparencyModifier = if open < 0.5 then 1 else 0
	end
end

type Tempo = {
	bob: number,
	hz: number,
	roll: number,
	swing: number,
	wag: number,
	wagHz: number,
	hops: { number }?,
	flourish: { number }?,
}

-- Rarity tempo: bob height (studs) and rate (Hz), waddle roll / leg swing / tail wag (degrees), wag rate (Hz),
-- seconds between random hops (bouncy commons) or flourishes (Rare and up).
local TEMPO: { [string]: Tempo } = {
	Common = { bob = 0.25, hz = 1.6, roll = 12, swing = 28, wag = 22, wagHz = 2.4, hops = { 3, 6 } },
	Uncommon = { bob = 0.22, hz = 1.4, roll = 10, swing = 26, wag = 20, wagHz = 2.2, hops = { 5, 9 } },
	Rare = { bob = 0.16, hz = 1.0, roll = 6, swing = 22, wag = 14, wagHz = 1.6, flourish = { 7, 11 } },
	Epic = { bob = 0.16, hz = 0.9, roll = 5, swing = 20, wag = 12, wagHz = 1.4, flourish = { 8, 12 } },
	Legendary = { bob = 0.18, hz = 0.75, roll = 4, swing = 18, wag = 10, wagHz = 1.2, flourish = { 9, 13 } },
	Mythic = { bob = 0.2, hz = 0.7, roll = 4, swing = 18, wag = 10, wagHz = 1.1, flourish = { 9, 13 } },
	Divine = { bob = 0.22, hz = 0.6, roll = 3, swing = 16, wag = 8, wagHz = 1.0, flourish = { 10, 14 } },
	Secret = { bob = 0.22, hz = 0.6, roll = 3, swing = 16, wag = 8, wagHz = 1.0, flourish = { 10, 14 } },
}
local HOP_TIME, FLOURISH_TIME = 0.7, 1.6

type Mood = {
	tempo: Tempo,
	hover: boolean,
	buzz: boolean,
	hopAt: number,
	nextHop: number,
	flourishAt: number,
	nextFlourish: number,
	synced: boolean,
}

-- Hovering = no visible part reaches within 0.4 studs (at scale 1) of the feet.
local function hovering(model: Model): boolean
	local root = model.PrimaryPart
	if not root then
		return false
	end
	local low = math.huge
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root and d.Transparency < 1 then
			local c = root.CFrame:ToObjectSpace(d.CFrame)
			local half = math.abs(c.RightVector.Y) * d.Size.X
				+ math.abs(c.UpVector.Y) * d.Size.Y
				+ math.abs(c.LookVector.Y) * d.Size.Z
			low = math.min(low, c.Position.Y - half / 2)
		end
	end
	return low > 0.4 * model:GetScale()
end

local function mood(model: Model, motors: { [string]: Motor6D }): Mood
	local rarity = model:GetAttribute("Rarity")
	local tempo = TEMPO[if typeof(rarity) == "string" then rarity else "Common"] or TEMPO.Common
	local hover = hovering(model)
	local now = os.clock()
	return {
		tempo = tempo,
		hover = hover,
		buzz = hover and motors.WingL ~= nil,
		hopAt = -1,
		nextHop = now + (if tempo.hops then rng:NextNumber(1, tempo.hops[2]) else math.huge),
		flourishAt = -1,
		nextFlourish = now + (if tempo.flourish then rng:NextNumber(3, tempo.flourish[2]) else math.huge),
		synced = false,
	}
end

-- Starts due hops / flourishes; returns the hop (lift, airborne) and the flourish envelope 0..1 and phase 0..1.
local function beats(md: Mood, now: number): (number, number, number, number)
	local tempo = md.tempo
	if tempo.hops and now >= md.nextHop and not md.hover then
		md.hopAt = now
		md.nextHop = now + rng:NextNumber(tempo.hops[1], tempo.hops[2])
	end
	if tempo.flourish and not md.synced and now >= md.nextFlourish then
		md.flourishAt = now
		md.nextFlourish = now + rng:NextNumber(tempo.flourish[1], tempo.flourish[2])
	end
	local lift, air = 0, 0
	if md.hopAt >= 0 and now - md.hopAt < HOP_TIME then
		local c = now - md.hopAt
		if c < 0.15 then
			lift = -0.2 * (c / 0.15)
		elseif c < 0.55 then
			local k = (c - 0.15) / 0.4
			lift, air = 4 * k * (1 - k) * 0.9, 1
		else
			lift = -0.2 * math.sin((c - 0.55) / 0.15 * math.pi)
		end
	end
	local env, phase = 0, 0
	if md.flourishAt >= 0 and now - md.flourishAt < FLOURISH_TIME then
		phase = (now - md.flourishAt) / FLOURISH_TIME
		env = math.sin(phase * math.pi)
	end
	return lift, air, env, phase
end

-- Turn a group in the root's frame about its own pivot, after `around` (the body's bob / roll in root space).
local function turn(m: Motor6D?, around: CFrame, rot: CFrame)
	if m then
		local b = Rig.base(m)
		local p = b.Position
		m.C0 = around * CFrame.new(p) * rot * CFrame.new(-p) * b
	end
end

-- A rotation about a group's pivot, in root space (the plain rotation without the group).
local function about(m: Motor6D?, rot: CFrame): CFrame
	if not m then
		return rot
	end
	local p = Rig.base(m).Position
	return CFrame.new(p) * rot * CFrame.new(-p)
end

type Pose = (t: number, m: { [string]: Motor6D }, md: Mood, now: number) -> ()

-- Shared loop: `pose(t, motors, mood, now)` returns nothing; blinking runs unless `eyesClosed`.
local function run(model: Model, eyesClosed: boolean, pose: Pose): () -> ()
	local motors = Rig.motors(model)
	local md = mood(model, motors)
	local e = eyes(model)
	local phase = rng:NextNumber(0, 10) -- desync pets standing side by side
	local nextBlink = os.clock() + rng:NextNumber(2, 5)
	local blinkUntil = 0
	if eyesClosed then
		setEyes(e, 0.12)
	end
	-- the pet's PetFx special (a synced burst) cues its flourish
	local special = model:GetAttributeChangedSignal("PetFxSpecial"):Connect(function()
		if md.tempo.flourish then
			md.synced = true
			md.flourishAt = os.clock()
		end
	end)
	local conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			return
		end
		local now = os.clock()
		pose(now + phase, motors, md, now)
		if not eyesClosed then
			if now >= nextBlink then
				blinkUntil = now + 0.12
				nextBlink = now + rng:NextNumber(2, 5)
				setEyes(e, 0.1)
			elseif blinkUntil > 0 and now >= blinkUntil then
				blinkUntil = 0
				setEyes(e, 1)
			end
		end
	end)
	return function()
		conn:Disconnect()
		special:Disconnect()
		setEyes(e, 1)
		for _, m in motors do
			Rig.reset(m)
		end
	end
end

-- Serpent idle (4 s S-sway, breathing, head look-around, slow wing settle, arm drift); `slither` adds a 1 Hz roll
-- and a coil twist while it roams.
local function serpentPose(t: number, m: { [string]: Motor6D }, slither: number)
	local w = t * 2 * math.pi
	local pivot = if m.Body then Rig.base(m.Body) else CFrame.new()
	local roll = math.sin(w * 0.25) * math.rad(3) + math.sin(w) * slither
	local pitch = math.sin(w * 0.25 + 1.2) * math.rad(2)
	local around = pivot * CFrame.Angles(pitch, 0, roll) * pivot:Inverse()
	Rig.pose(m.Coil, CFrame.Angles(0, math.sin(w) * slither * 0.6, 0))
	Rig.poseAbout(m.Body, around, CFrame.new())
	local look = CFrame.Angles(math.sin(t * 0.9) * math.rad(4), math.sin(t * 0.6) * math.rad(10), -roll * 0.6)
	Rig.poseAbout(m.Head, around, look)
	local settle = math.sin(w * 0.5) * math.rad(7)
	Rig.poseAbout(m.WingL, around, CFrame.Angles(0, 0, -settle))
	Rig.poseAbout(m.WingR, around, CFrame.Angles(0, 0, settle))
	local drift = math.sin(w * 0.35) * math.rad(8)
	Rig.poseAbout(m.ArmL, around, CFrame.Angles(drift, 0, 0))
	Rig.poseAbout(m.ArmR, around, CFrame.Angles(-drift, 0, 0))
end

-- Grounded pets: bob (and a roll while walking) about the body, head look-around, tail wag; commons hop now and
-- then (legs tuck, wings flap), Rare and up flourish. `walk` is 0 standing, 1 walking.
local function groundPose(t: number, m: { [string]: Motor6D }, md: Mood, now: number, walk: number)
	local T = md.tempo
	local w = t * 2 * math.pi
	local lift, air, fl, k = beats(md, now)
	local bob = (math.sin(w * T.hz) * 0.5 + 0.5) * T.bob * (1 - 0.5 * walk)
	local roll = walk * math.sin(w * 2) * math.rad(T.roll)
	local pitch = air * math.rad(-8) + fl * math.rad(5)
	local around = CFrame.new(0, bob + lift + fl * 0.12, 0) * about(m.Body, CFrame.Angles(pitch, 0, roll))
	turn(m.Body, around, CFrame.identity)
	turn(
		m.Head,
		around,
		CFrame.Angles(
			math.sin(t * 0.9) * math.rad(4) + fl * math.rad(16),
			math.sin(t * 0.6) * math.rad(10) + fl * math.sin(k * 4 * math.pi) * math.rad(9),
			0
		)
	)
	local wag = math.sin(w * T.wagHz * (1 + fl)) * math.rad(T.wag) * (1 + fl)
	turn(m.Tail, around, CFrame.Angles(0, wag, 0))
	local flap = air * math.sin(w * 6) * math.rad(30)
		+ walk * math.sin(w * 2) * math.rad(10)
		+ fl * math.rad(35)
		+ math.sin(w * 0.5) * math.rad(3)
	turn(m.WingL, around, CFrame.Angles(0, 0, -flap))
	turn(m.WingR, around, CFrame.Angles(0, 0, flap))
	local swing = walk * math.sin(w * 2) * math.rad(T.swing)
	local tuck = air * math.rad(-30)
	local feet = CFrame.new(0, lift, 0)
	turn(m.LegL, feet, CFrame.Angles(swing + tuck, 0, 0))
	turn(m.LegR, feet, CFrame.Angles(-swing + tuck, 0, 0))
	turn(m.ArmL, feet, CFrame.Angles(-swing - tuck, 0, 0))
	turn(m.ArmR, feet, CFrame.Angles(swing - tuck + fl * math.rad(24), 0, 0))
end

-- Hovering pets: a slow float and sway, leaning into their walk; legs dangle (trailing back while flying),
-- wings buzz (insects) or beat slowly; Rare and up rise and spread their wings on a flourish.
local function hoverPose(t: number, m: { [string]: Motor6D }, md: Mood, now: number, walk: number)
	local w = t * 2 * math.pi
	local _, _, fl, k = beats(md, now)
	local float = math.sin(w * 0.8) * 0.28 + fl * 0.3
	local pitch = math.sin(w * 0.6) * math.rad(3) - walk * math.rad(9) + fl * math.rad(8)
	local roll = math.sin(w * 0.45) * math.rad(4) + walk * math.sin(w * 1.2) * math.rad(5)
	local around = CFrame.new(0, float, 0) * about(m.Body, CFrame.Angles(pitch, 0, roll))
	turn(m.Body, around, CFrame.identity)
	turn(
		m.Head,
		around,
		CFrame.Angles(
			math.sin(t * 0.9) * math.rad(5) + fl * math.rad(12),
			math.sin(t * 0.6) * math.rad(12) + fl * math.sin(k * 4 * math.pi) * math.rad(8),
			0
		)
	)
	turn(m.Tail, around, CFrame.Angles(0, math.sin(w * 0.9) * math.rad(md.tempo.wag * 0.6), 0))
	local flap = if md.buzz
		then math.rad(12) + math.sin(t * 2 * math.pi * 9) * math.rad(18)
		else math.sin(w * 1.2) * math.rad(20)
	flap += fl * math.rad(25)
	turn(m.WingL, around, CFrame.Angles(0, 0, -flap))
	turn(m.WingR, around, CFrame.Angles(0, 0, flap))
	local dangle = math.sin(w * 0.9) * math.rad(8) - walk * math.rad(18)
	turn(m.ArmL, around, CFrame.Angles(dangle, 0, 0))
	turn(m.ArmR, around, CFrame.Angles(math.sin(w * 0.9 + 1.3) * math.rad(8) - walk * math.rad(18), 0, 0))
	turn(m.LegL, around, CFrame.Angles(dangle * 0.7 - walk * math.rad(8), 0, 0))
	turn(m.LegR, around, CFrame.Angles(math.sin(w * 0.9 + 2.1) * math.rad(6) - walk * math.rad(8), 0, 0))
end

local function petPose(t: number, m: { [string]: Motor6D }, md: Mood, now: number, walk: number)
	if m.Coil then
		serpentPose(t, m, walk * math.rad(6))
	elseif md.hover then
		hoverPose(t, m, md, now, walk)
	else
		groundPose(t, m, md, now, walk)
	end
end

function Pet.Idle(model: Model, _params: { [string]: any }): () -> ()
	return run(model, false, function(t, m, md, now)
		petPose(t, m, md, now, 0)
	end)
end

function Pet.Waddle(model: Model, _params: { [string]: any }): () -> ()
	return run(model, false, function(t, m, md, now)
		petPose(t, m, md, now, 1)
	end)
end

-- Hop curve over one 1.2 s cycle (c in seconds): squash, jump, land squash, rest. Returns lift, airborne.
local function hopAt(c: number): (number, number)
	if c < 0.15 then
		return -0.25 * (c / 0.15), 0
	elseif c < 0.55 then
		local k = (c - 0.15) / 0.4
		return 4 * k * (1 - k) * 1.4, 1
	elseif c < 0.7 then
		local k = (c - 0.55) / 0.15
		return -0.25 * math.sin(k * math.pi), 0
	end
	return 0, 0
end

function Pet.Hop(model: Model, _params: { [string]: any }): () -> ()
	return run(model, false, function(t, m)
		local y, air = hopAt(t % 1.2)
		local lift = CFrame.new(0, y, 0)
		-- Every group gets the same lift so the whole rig hops without moving the root.
		for name, motor in m do
			if name == "LegL" or name == "LegR" then
				turn(motor, lift, CFrame.Angles(air * math.rad(-30), 0, 0))
			elseif name == "Body" then
				turn(motor, lift, CFrame.Angles(air * math.rad(-8), 0, 0))
			else
				turn(motor, lift, CFrame.identity)
			end
		end
	end)
end

function Pet.Sleep(model: Model, _params: { [string]: any }): () -> ()
	local root = model.PrimaryPart
	local zzz: { BillboardGui } = {}
	local alive = true
	if root then
		task.spawn(function()
			local height = model:GetExtentsSize().Y
			while alive and model.Parent do
				local gui = Instance.new("BillboardGui")
				gui.Size = UDim2.fromOffset(40, 40)
				gui.StudsOffsetWorldSpace = Vector3.new(0.6, height * 0.8, 0)
				gui.LightInfluence = 0
				gui.MaxDistance = 60
				local l = Instance.new("TextLabel")
				l.BackgroundTransparency = 1
				l.Size = UDim2.fromScale(1, 1)
				l.Font = Enum.Font.FredokaOne
				l.TextScaled = true
				l.Text = "Z"
				l.TextColor3 = Color3.fromRGB(200, 220, 255)
				local s = Instance.new("UIStroke")
				s.Thickness = 2
				s.Color = Color3.fromRGB(40, 50, 90)
				s.Parent = l
				l.Parent = gui
				gui.Adornee = root
				gui.Parent = root
				table.insert(zzz, gui)
				task.spawn(function()
					local t0 = os.clock()
					while gui.Parent and os.clock() - t0 < 1.6 do
						local k = (os.clock() - t0) / 1.6
						gui.StudsOffsetWorldSpace = Vector3.new(0.6 + math.sin(k * 6) * 0.3, height * 0.8 + k * 2.2, 0)
						l.TextTransparency = k
						s.Transparency = k
						task.wait()
					end
					gui:Destroy()
				end)
				task.wait(0.8)
			end
		end)
	end
	local stop = run(model, true, function(t, m)
		local up = CFrame.new(0, math.sin(t * 2 * math.pi * 0.4) * 0.06, 0)
		turn(m.Body, up, CFrame.identity)
		turn(m.Head, up * CFrame.new(0, -0.1, 0), CFrame.Angles(math.rad(-14), 0, math.rad(6)))
		turn(m.Tail, up, CFrame.identity)
		turn(m.WingL, up, CFrame.identity)
		turn(m.WingR, up, CFrame.identity)
	end)
	return function()
		alive = false
		stop()
		for _, g in zzz do
			g:Destroy()
		end
	end
end

return Pet
