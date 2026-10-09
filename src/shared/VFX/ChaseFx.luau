--!strict
-- Partner A. Chase outcome effects (client). Never moves the egg: only hides it locally and
-- spawns pooled pieces around it.
--   EggCaught  {theme, ownerUserId?}   target = egg model: shell-shard burst, egg vanishes, "LOST!"
--   EggSecured {rarity, ownerUserId?}  target = egg/player: rarity confetti, "SECURED!"
--   EggPickup  {}                      target = egg: small white pop
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rarities"))
local Popup = require(script.Parent.Popup)
local Shake = require(script.Parent.Shake)
local Burst = require(script.Parent.Burst)

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
		Burst.play(pos + Vector3.new(0, 2, 0), 16, shell, NumberRange.new(0.4, 1.2), 26, 1.1)
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
		Burst.play(pos + Vector3.new(0, 4, 0), 28, colors, NumberRange.new(0.4, 0.8), 34, 1.8, true, rarity.glow)
	end
	if isOwner(params) then
		local top = rarity.color:Lerp(Color3.new(1, 1, 1), 0.45)
		Popup.banner("SECURED!", { top, rarity.color }, 1.4)
	end
end

function ChaseFx.EggPickup(target: Instance?, _params: { [string]: any })
	local pos = positionOf(target)
	if pos then
		Burst.play(
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
