--!strict
-- Treadmill effects (map v3, client). Target = the TrainingRack model.
--   TreadStep    {tier, gain}        one training step: speed streaks off the belt, a puff in the
--                                    tier's style, a tier extra (sparks / glitter / shards / flames)
--                                    and the "+X Power" pop over the console
--   TreadUpgrade {tier, own?}        the treadmill just upgraded: rings, light pillar, confetti and a
--                                    "<Tier> Treadmill!" pop; a small thump if it's your own
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TrainingRack = require(Shared:WaitForChild("Builders"):WaitForChild("Map"):WaitForChild("TrainingRack"))
local Pool = require(script.Parent.Pool)
local Burst = require(script.Parent.Burst)
local Fx = require(script.Parent.Fx)
local Shake = require(script.Parent.Shake)
local Hatch = require(script.Parent.Hatch)
local ZoneLanding = require(script.Parent.ZoneLanding)

local Treadmill = {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local rng = Random.new()

local function part(rack: Instance, name: string): BasePart?
	local p = rack:FindFirstChild(name)
	return if p and p:IsA("BasePart") then p else nil
end

local function puff(cf: CFrame, texture: string, color: Color3, count: number, size: number, speed: number)
	local anchor = Pool.anchor(cf, Vector3.new(3, 0.2, 0.6))
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(size, size * 1.8)
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Lifetime = NumberRange.new(0.4, 0.7)
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(40, 40)
	e.EmissionDirection = Enum.NormalId.Back
	e.LightEmission = if texture == SMOKE then 0 else 1
	e.Drag = 3
	e.Rate = 0
	e.Parent = anchor
	e:Emit(count)
	task.delay(0.9, Pool.release, anchor)
end

-- Thin glowing bars that shoot off the back of the belt and fade.
local function streaks(plate: BasePart, color: Color3, count: number)
	local width = plate.Size.X
	for _ = 1, count do
		local bar = Pool.get("Block")
		bar.Material = Enum.Material.Neon
		bar.Color = color
		bar.Transparency = 0.1
		bar.Size = Vector3.new(0.14, 0.14, rng:NextNumber(1.6, 3))
		local start = plate.CFrame
			* CFrame.new(
				rng:NextNumber(-width / 2 + 0.4, width / 2 - 0.4),
				plate.Size.Y / 2 + rng:NextNumber(0.3, 1.6),
				rng:NextNumber(-1, 2)
			)
		bar.CFrame = start
		local tween = TweenService:Create(
			bar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ CFrame = start * CFrame.new(0, 0, -7), Transparency = 1 }
		)
		tween.Completed:Once(function()
			Pool.release(bar)
		end)
		tween:Play()
	end
end

function Treadmill.Step(target: Instance?, params: { [string]: any })
	if not target then
		return
	end
	local tier = params.tier or target:GetAttribute("Tier") or "Wood"
	local look = TrainingRack.look(tier)
	local rank = table.find(TrainingRack.tiers(), tier) or 1
	local plate, fx, pop = part(target, "Plate"), part(target, "FxAnchor"), part(target, "PopAnchor")
	if plate then
		streaks(plate, look.accent, 2 + rank)
	end
	if fx then
		local at = fx.CFrame
		if tier == "Wood" or tier == "Stone" then
			puff(at, SMOKE, look.frame:Lerp(Color3.new(1, 1, 1), 0.4), 6, 0.8, 5)
		elseif tier == "Inferno" then
			puff(at, FIRE, look.accent, 12, 1.2, 8)
		else
			puff(at, SPARK, look.accent, 10, 0.5, 9)
		end
		if rank >= 3 then -- Iron+: a few pieces kicked off the belt (sparks, glitter, shards, embers)
			Burst.play(
				at.Position,
				2 + rank,
				{ look.accent, look.slat },
				NumberRange.new(0.15, 0.35),
				10 + rank * 2,
				0.5,
				tier == "Gold",
				tier ~= "Gold"
			)
		end
	end
	if pop then
		Hatch.MoneyPop(pop, { text = `+{params.gain or 0} Power`, color = look.accent })
	end
end

function Treadmill.Upgrade(target: Instance?, params: { [string]: any })
	if not target then
		return
	end
	local tier = params.tier or target:GetAttribute("Tier") or "Wood"
	local look = TrainingRack.look(tier)
	local plate, pop = part(target, "Plate"), part(target, "PopAnchor")
	local center = if plate then plate.Position else (Fx.posOf(target) or Vector3.zero)
	local ground = center - Vector3.new(0, 0.6, 0)
	ZoneLanding.shockwave(ground, look.accent, 26, 0.6, 0)
	ZoneLanding.shockwave(ground, look.frame, 16, 0.5, 0.15)
	Fx.pillar(ground, look.accent, 30, 1.6)
	Fx.flash(center + Vector3.new(0, 3, 0), look.accent, 18, 0.4)
	Burst.play(
		center + Vector3.new(0, 2, 0),
		26,
		{ look.accent, look.frame, Color3.new(1, 1, 1) },
		NumberRange.new(0.3, 0.7),
		26,
		1.2,
		true,
		false
	)
	if pop then
		Hatch.MoneyPop(pop, { text = `{string.upper(tier)} TREADMILL!`, color = look.accent })
	end
	if params.own then
		Shake.impulse("TreadUpgrade", 0.35, 0.4)
	end
end

return Treadmill
