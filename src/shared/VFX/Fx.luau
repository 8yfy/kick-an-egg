--!strict
-- Partner A. Small helpers shared by the egg / hatch / pet effects.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Pets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Pets"))
local Pool = require(script.Parent.Pool)

local Fx = {}

function Fx.rarityOfKey(key: string?): string
	if key then
		for _, p in Pets do
			if p.model == key then
				return p.rarity
			end
		end
	end
	return "Common"
end

function Fx.keyOfModel(model: Instance): string?
	local name = model.Name
	return if string.sub(name, -3) == "Egg" then string.sub(name, 1, -4) else nil
end

function Fx.posOf(target: Instance?): Vector3?
	if target and target:IsA("Model") then
		return target:GetPivot().Position
	elseif target and target:IsA("BasePart") then
		return target.Position
	end
	return nil
end

function Fx.flash(pos: Vector3, color: Color3, size: number, seconds: number)
	local ball = Pool.get("Ball")
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.one * size * 0.3
	ball.CFrame = CFrame.new(pos)
	ball.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = size * 2
	light.Brightness = 4
	light.Parent = ball
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ball, info, { Size = Vector3.one * size, Transparency = 1 }):Play()
	TweenService:Create(light, info, { Brightness = 0 }):Play()
	task.delay(seconds + 0.05, Pool.release, ball)
end

function Fx.hideLocally(model: Model, hidden: boolean, except: Instance?)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and not (except and d:IsDescendantOf(except)) then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

function Fx.colorsOf(target: Instance?, fallback: { Color3 }): { Color3 }
	local out = {}
	if target then
		for _, d in target:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 and d.Name ~= "Root" and #out < 6 then
				table.insert(out, d.Color)
			end
		end
	end
	return if #out > 0 then out else fallback
end

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }
function Fx.formatNumber(n: number): string
	n = math.floor(n)
	local i, v = 1, n
	while math.abs(v) >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(n)
	end
	if math.abs(v) >= 100 then
		return string.format("%.0f", v) .. SUFFIXES[i]
	end
	local s = string.format(if math.abs(v) >= 10 then "%.1f" else "%.2f", v)
	s = (s:gsub("0+$", ""):gsub("%.$", "")) -- 1.50 -> 1.5, 2.00 -> 2
	return s .. SUFFIXES[i]
end

-- Light pillar (Beam + Neon core + light) standing on `ground`, fading over `seconds`.
function Fx.pillar(ground: Vector3, color: Color3, height: number, seconds: number)
	local base = Pool.anchor(CFrame.new(ground))
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a1.Position = Vector3.new(0, height, 0)
	a0.Parent, a1.Parent = base, base
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Color = ColorSequence.new(color)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Width0, beam.Width1 = 6, 3
	beam.Brightness = 4
	beam.Segments = 1
	beam.Parent = base
	-- Solid Neon core so the pillar reads in daylight.
	local core = Pool.get("Cylinder")
	core.Material = Enum.Material.Neon
	core.Color = color
	core.Size = Vector3.new(height, 1.4, 1.4)
	core.CFrame = CFrame.new(ground + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	core.Transparency = 0.2
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 3
	light.Parent = base
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / seconds
		if k >= 1 then
			conn:Disconnect()
			Pool.release(base)
			Pool.release(core)
			return
		end
		beam.Transparency = NumberSequence.new(0.9 * k, 1)
		core.Transparency = 0.2 + 0.8 * k
		core.Size = Vector3.new(height, 1.4 * (1 - 0.6 * k), 1.4 * (1 - 0.6 * k))
		light.Brightness = 3 * (1 - k)
	end)
end

return Fx
