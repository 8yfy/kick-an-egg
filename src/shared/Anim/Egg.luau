--!strict
-- Partner A. Legged-egg loops (motors come from LegsSprout: LegL/LegR, ArmL/ArmR on Rare+).
--   EggRun     fast leg cycle, forward tilt, bob, flailing arms, sweat drops
--   EggCarried legs kicking in the air, arms waving, little wiggle
--   EggWobble  hatching wobble on the pedestal (params.speed 1..3, faster near the end)
local RunService = game:GetService("RunService")
local Rig = require(script.Parent.Rig)

local Egg = {}

local SWEAT = "rbxasset://textures/particles/sparkles_main.dds"

local function loop(model: Model, fn: (t: number, motors: { [string]: Motor6D }) -> ()): () -> ()
	local motors = Rig.motors(model)
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		if not model.Parent then
			return
		end
		fn(os.clock() - t0, motors)
	end)
	return function()
		conn:Disconnect()
		for _, m in motors do
			Rig.reset(m)
		end
	end
end

local function sweat(model: Model): ParticleEmitter?
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local a = Instance.new("Attachment")
	a.Name = "SweatAttachment"
	a.Position = Vector3.new(0, 3.4, 0)
	a.Parent = root
	local e = Instance.new("ParticleEmitter")
	e.Texture = SWEAT
	e.Color = ColorSequence.new(Color3.fromRGB(150, 210, 255))
	e.Size = NumberSequence.new(0.5, 0.2)
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.4, 0.7)
	e.Speed = NumberRange.new(6, 9)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Rate = 10
	e.Parent = a
	return e
end

function Egg.EggRun(model: Model, params: { [string]: any }): () -> ()
	local hz = (params.speed or 1) * 4.5 -- strides per second
	local drop = sweat(model)
	local stop = loop(model, function(t, m)
		local phase = t * hz * 2 * math.pi
		local swing = math.sin(phase) * math.rad(40)
		Rig.pose(m.LegL, CFrame.Angles(swing, 0, 0))
		Rig.pose(m.LegR, CFrame.Angles(-swing, 0, 0))
		Rig.pose(m.ArmL, CFrame.Angles(-swing * 1.2, 0, math.rad(-25)))
		Rig.pose(m.ArmR, CFrame.Angles(swing * 1.2, 0, math.rad(25)))
		-- Lean forward (-Z), bounce twice per stride, waddle roll.
		local bob = math.abs(math.sin(phase)) * 0.3
		Rig.pose(m.Body, CFrame.new(0, bob, 0) * CFrame.Angles(math.rad(-14), 0, math.sin(phase) * math.rad(8)))
	end)
	return function()
		stop()
		if drop and drop.Parent then
			(drop.Parent :: Instance):Destroy()
		end
	end
end

function Egg.EggCarried(model: Model, _params: { [string]: any }): () -> ()
	return loop(model, function(t, m)
		local kick = math.sin(t * 2 * math.pi * 6) * math.rad(55)
		Rig.pose(m.LegL, CFrame.Angles(kick, 0, math.rad(-10)))
		Rig.pose(m.LegR, CFrame.Angles(-kick, 0, math.rad(10)))
		local wave = math.sin(t * 2 * math.pi * 5) * math.rad(50)
		Rig.pose(m.ArmL, CFrame.Angles(0, 0, math.rad(-60) + wave))
		Rig.pose(m.ArmR, CFrame.Angles(0, 0, math.rad(60) - wave))
		Rig.pose(m.Body, CFrame.Angles(0, 0, math.sin(t * 2 * math.pi * 3) * math.rad(10)))
	end)
end

function Egg.EggWobble(model: Model, params: { [string]: any }): () -> ()
	return loop(model, function(t, m)
		local speed = params.speed or 1
		local hz = 1.2 * speed
		-- Bursts of wobble with pauses; amplitude grows with speed.
		local burst = math.max(0, math.sin(t * 2 * math.pi * 0.5 * speed))
		local roll = math.sin(t * 2 * math.pi * hz * 3) * math.rad(6 + 6 * speed) * burst
		Rig.pose(m.Body, CFrame.Angles(0, 0, roll) * CFrame.new(0, burst * 0.1 * speed, 0))
	end)
end

return Egg
