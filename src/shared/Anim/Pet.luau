--!strict
-- Partner A. Pet loops on BlockBuilder rigs (Body/Head/LegL/LegR/ArmL/ArmR/WingL/WingR/Tail).
--   Idle    0.25-stud bob at 1.5 Hz, slow head look-around, tail wag, wing flap, blink every 2-5 s
--   Waddle  idle + +-12 deg roll and alternating leg swing
--   Hop     the whole rig hops every ~1.2 s with squash and stretch (root never moves)
--   Sleep   slow breathing, head drooped, eyes shut, "Z"s drifting up
-- Eyes are the parts named EyeL/EyeR (+ GlintL/GlintR), per the Models/Kit convention.
local RunService = game:GetService("RunService")
local Rig = require(script.Parent.Rig)

local Pet = {}

local rng = Random.new()

type Eyes = { parts: { BasePart }, glints: { BasePart }, sizes: { [BasePart]: Vector3 } }

local function eyes(model: Model): Eyes
	local e: Eyes = { parts = {}, glints = {}, sizes = {} }
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "EyeL" or d.Name == "EyeR" then
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

-- Shared loop: `pose(t, motors)` returns nothing; blinking runs unless `eyesClosed`.
local function run(model: Model, eyesClosed: boolean, pose: (t: number, m: { [string]: Motor6D }) -> ()): () -> ()
	local motors = Rig.motors(model)
	local e = eyes(model)
	local phase = rng:NextNumber(0, 10) -- desync pets standing side by side
	local nextBlink = os.clock() + rng:NextNumber(2, 5)
	local blinkUntil = 0
	if eyesClosed then
		setEyes(e, 0.12)
	end
	local conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			return
		end
		local now = os.clock()
		pose(now + phase, motors)
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
		setEyes(e, 1)
		for _, m in motors do
			Rig.reset(m)
		end
	end
end

local function idlePose(t: number, m: { [string]: Motor6D }, extraRoll: number)
	local bob = (math.sin(t * 2 * math.pi * 1.5) * 0.5 + 0.5) * 0.25
	local up = CFrame.new(0, bob, 0)
	Rig.pose(m.Body, up * CFrame.Angles(0, 0, extraRoll))
	Rig.pose(m.Head, up * CFrame.Angles(math.sin(t * 0.9) * math.rad(4), math.sin(t * 0.6) * math.rad(10), 0))
	Rig.pose(m.Tail, up * CFrame.Angles(0, math.sin(t * 2 * math.pi * 2) * math.rad(20), 0))
	local flap = math.sin(t * 2 * math.pi * 5) * math.rad(25)
	Rig.pose(m.WingL, up * CFrame.Angles(0, 0, -flap))
	Rig.pose(m.WingR, up * CFrame.Angles(0, 0, flap))
	Rig.pose(m.ArmL, up)
	Rig.pose(m.ArmR, up)
end

function Pet.Idle(model: Model, _params: { [string]: any }): () -> ()
	return run(model, false, function(t, m)
		idlePose(t, m, 0)
	end)
end

function Pet.Waddle(model: Model, _params: { [string]: any }): () -> ()
	return run(model, false, function(t, m)
		local w = t * 2 * math.pi * 2
		idlePose(t, m, math.sin(w) * math.rad(12))
		local swing = math.sin(w) * math.rad(25)
		Rig.pose(m.LegL, CFrame.Angles(swing, 0, 0))
		Rig.pose(m.LegR, CFrame.Angles(-swing, 0, 0))
		Rig.pose(m.ArmL, CFrame.Angles(-swing, 0, 0))
		Rig.pose(m.ArmR, CFrame.Angles(swing, 0, 0))
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
				Rig.pose(motor, lift * CFrame.Angles(air * math.rad(-30), 0, 0))
			elseif name == "Body" then
				Rig.pose(motor, lift * CFrame.Angles(air * math.rad(-8), 0, 0))
			else
				Rig.pose(motor, lift)
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
		local breath = math.sin(t * 2 * math.pi * 0.4) * 0.06
		Rig.pose(m.Body, CFrame.new(0, breath, 0))
		Rig.pose(m.Head, CFrame.new(0, breath - 0.1, 0) * CFrame.Angles(math.rad(-14), 0, math.rad(6)))
		Rig.pose(m.Tail, CFrame.new(0, breath, 0))
		Rig.pose(m.WingL, CFrame.new(0, breath, 0))
		Rig.pose(m.WingR, CFrame.new(0, breath, 0))
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
