--!strict
-- Partner A. Chase outcome effects (client). Never moves the egg: only hides it locally and
-- spawns pooled pieces around it.
--   EggCaught  {theme, ownerUserId?}   target = egg model: shell-shard burst, egg vanishes, "LOST!"
--   EggSecured {rarity, ownerUserId?}  target = egg/player: rarity confetti, "SECURED!"
--   EggPickup  {}                      target = egg: small white pop
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rarities"))
local Pool = require(script.Parent.Pool)
local Popup = require(script.Parent.Popup)
local Shake = require(script.Parent.Shake)

local GRAVITY = Vector3.new(0, -60, 0)
local rng = Random.new()

local ChaseFx = {}

local function isOwner(params: { [string]: any }): boolean
	local uid = params.ownerUserId
	local me = Players.LocalPlayer
	return uid == nil or (me ~= nil and uid == me.UserId)
end

local function positionOf(target: Instance?): Vector3?
	if target and target:IsA("Model") then
		return target:GetPivot().Position
	elseif target and target:IsA("BasePart") then
		return target.Position
	end
	local char = Players.LocalPlayer and Players.LocalPlayer.Character
	return if char then char:GetPivot().Position else nil
end

local function colorsOf(target: Instance?, fallback: { Color3 }): { Color3 }
	local out = {}
	if target then
		for _, d in target:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 and #out < 6 then
				table.insert(out, d.Color)
			end
		end
	end
	return if #out > 0 then out else fallback
end

-- Ballistic burst of pooled pieces that spin, bounce once and fade. Returns immediately.
local function burst(
	origin: Vector3,
	count: number,
	colors: { Color3 },
	sizes: NumberRange,
	power: number,
	seconds: number,
	flat: boolean?,
	neon: boolean?
)
	local bits = {}
	for _ = 1, count do
		local p = Pool.get(if rng:NextNumber() < 0.3 and not flat then "Wedge" else "Block")
		local s = rng:NextNumber(sizes.Min, sizes.Max)
		p.Size = if flat then Vector3.new(s, 0.08, s * 0.6) else Vector3.new(s, s * rng:NextNumber(0.5, 1), s)
		p.Color = colors[rng:NextInteger(1, #colors)]
		if neon then
			p.Material = Enum.Material.Neon
		end
		local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(0.6, 1.4), rng:NextNumber(-1, 1)).Unit
		table.insert(bits, {
			part = p,
			pos = origin,
			vel = dir * power * rng:NextNumber(0.6, 1.1),
			axis = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)).Unit,
			spin = rng:NextNumber(4, 12),
		})
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		local k = (os.clock() - t0) / seconds
		if k >= 1 then
			conn:Disconnect()
			for _, b in bits do
				Pool.release(b.part)
			end
			return
		end
		for _, b in bits do
			local drag = if flat then 0.35 else 1 -- confetti flutters down slowly
			b.vel += GRAVITY * drag * dt
			if flat then
				b.vel *= 0.985
			end
			b.pos += b.vel * dt
			if b.pos.Y < 0.2 then
				b.pos = Vector3.new(b.pos.X, 0.2, b.pos.Z)
				b.vel = Vector3.new(b.vel.X * 0.5, math.abs(b.vel.Y) * 0.3, b.vel.Z * 0.5)
			end
			b.part.CFrame = CFrame.new(b.pos) * CFrame.fromAxisAngle(b.axis, b.spin * (os.clock() - t0))
			b.part.Transparency = math.clamp((k - 0.6) / 0.4, 0, 1)
		end
	end)
end

local function hideLocally(target: Instance?)
	if not target then
		return
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = 1
		end
	end
end

function ChaseFx.EggCaught(target: Instance?, params: { [string]: any })
	local pos = positionOf(target)
	if pos then
		local shell = colorsOf(target, { Color3.fromRGB(255, 240, 200) })
		burst(pos + Vector3.new(0, 2, 0), 16, shell, NumberRange.new(0.4, 1.2), 26, 1.1)
	end
	hideLocally(target)
	if isOwner(params) then
		Shake.impulse("EggCaught", 0.5, 0.35)
		Popup.banner("LOST!", { Color3.fromRGB(255, 120, 110), Color3.fromRGB(200, 20, 40) }, 1.2)
	end
end

function ChaseFx.EggSecured(target: Instance?, params: { [string]: any })
	local rarity = Rarities[params.rarity or "Common"] or Rarities.Common
	local pos = positionOf(target)
	if pos then
		local colors = { rarity.color, rarity.color:Lerp(Color3.new(1, 1, 1), 0.5), Color3.fromRGB(255, 230, 80) }
		burst(pos + Vector3.new(0, 4, 0), 28, colors, NumberRange.new(0.4, 0.8), 34, 1.8, true, rarity.glow)
	end
	if isOwner(params) then
		local top = rarity.color:Lerp(Color3.new(1, 1, 1), 0.45)
		Popup.banner("SECURED!", { top, rarity.color }, 1.4)
	end
end

function ChaseFx.EggPickup(target: Instance?, _params: { [string]: any })
	local pos = positionOf(target)
	if pos then
		burst(
			pos + Vector3.new(0, 1.5, 0),
			8,
			{ Color3.new(1, 1, 1), Color3.fromRGB(255, 240, 150) },
			NumberRange.new(0.3, 0.6),
			18,
			0.6,
			false,
			true
		)
	end
end

return ChaseFx
