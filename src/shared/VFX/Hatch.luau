--!strict
-- Partner A. Hatching + base feedback effects (client).
--   HatchCrack {progress 0..1}  target = egg on the pedestal: adds zig-zag cracks as progress grows
--                               (Neon in the rarity colour for glowing rarities, light leaking out)
--   HatchBurst {rarity}         target = egg: shell cubes explode, rarity flash, pillar for Legendary+
--   PetReveal  {rarity, name}   target = the new pet: squash-bounce pop, rarity banner, pillar for Legendary+
--   MoneyPop   {amount}         target = pet/plot: "+$12" floats up and fades
--   Announce   {text, rarity}   server-wide toast under the quest bar
-- Pair with Anim.play(egg, "EggWobble", {speed}) for the wobble (faster near the end).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rarities = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Rarities"))
local Burst = require(script.Parent.Burst)
local Pool = require(script.Parent.Pool)
local Fx = require(script.Parent.Fx)
local Popup = require(script.Parent.Popup)
local Shake = require(script.Parent.Shake)

local Hatch = {}

local CRACKS_MAX = 9
local INK, LIGHT = Color3.fromRGB(35, 25, 25), Color3.fromRGB(245, 235, 215) -- light cracks on dark shells
local rng = Random.new()

local function rarityOf(name: string?): any
	return Rarities[name or "Common"] or Rarities.Common
end

local SIDES = { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis }

-- One zig-zag crack (3 thin segments) on a random side face of `shell`, welded to it.
local function crack(egg: Model, shell: BasePart, color: Color3, neon: boolean)
	local n = SIDES[rng:NextInteger(1, 4)]
	local half = shell.Size / 2
	local depth = math.abs(n:Dot(half))
	local across = if math.abs(n.X) > 0 then half.Z else half.X
	local face = shell.CFrame * CFrame.new(n * (depth + 0.02)) * CFrame.lookAt(Vector3.zero, n)
	-- Shell layers are short and wide, so cracks run sideways across the face with a zig-zag.
	local dir = if rng:NextNumber() < 0.5 then -1 else 1
	local u = -dir * across * rng:NextNumber(0.35, 0.6)
	local v = rng:NextNumber(-half.Y * 0.25, half.Y * 0.25)
	local angle = 0
	for i = 1, 3 do
		local len = math.min(rng:NextNumber(0.4, 0.6), across * 0.55)
		angle = -dir * (math.pi / 2 + (if i % 2 == 0 then 0.5 else -0.5))
		local seg = Instance.new("Part")
		seg.Name = "Crack"
		seg.Size = Vector3.new(0.12, len, 0.06)
		seg.Color = color
		seg.Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		seg.CanCollide, seg.CanQuery, seg.CanTouch, seg.Massless = false, false, false, true
		seg.Anchored = false
		seg.CFrame = face * CFrame.new(u, v, 0) * CFrame.Angles(0, 0, angle) * CFrame.new(0, len / 2, 0)
		seg.Parent = egg
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = shell, seg
		w.Parent = seg
		-- next segment starts at this one's tip
		local tip = (face:Inverse() * (seg.CFrame * CFrame.new(0, len / 2, 0))).Position
		u, v = tip.X, tip.Y
	end
end

function Hatch.HatchCrack(target: Instance?, params: { [string]: any })
	if not (target and target:IsA("Model")) then
		return
	end
	local egg = target :: Model
	local want = math.floor(math.clamp(params.progress or 0, 0, 1) * CRACKS_MAX + 1e-6)
	local have = (egg:GetAttribute("Cracks") :: number?) or 0
	if want <= have then
		return
	end
	local rarity = rarityOf(Fx.rarityOfKey(Fx.keyOfModel(egg)))
	local shells = {}
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, 1, 5) == "Shell" and d.Size.Y >= 0.5 then
			table.insert(shells, d)
		end
	end
	if #shells == 0 then
		for _, d in egg:GetDescendants() do
			if d:IsA("BasePart") and d.Name ~= "Root" then
				table.insert(shells, d)
			end
		end
	end
	if #shells == 0 then
		return
	end
	for _ = have + 1, want do
		local shell = shells[rng:NextInteger(1, #shells)]
		local _, _, value = shell.Color:ToHSV()
		local color = if rarity.glow then rarity.color elseif value < 0.35 then LIGHT else INK
		crack(egg, shell, color, rarity.glow)
		Burst.play(shell.Position, 3, { shell.Color }, NumberRange.new(0.15, 0.3), 8, 0.4)
	end
	egg:SetAttribute("Cracks", want)
end

function Hatch.HatchBurst(target: Instance?, params: { [string]: any })
	local pos = Fx.posOf(target)
	if not pos then
		return
	end
	local rarity = rarityOf(params.rarity)
	local center = pos + Vector3.new(0, 2, 0)
	local shell = Fx.colorsOf(target, { Color3.fromRGB(250, 240, 210) })
	if target and target:IsA("Model") then
		Fx.hideLocally(target, true)
	end
	Burst.play(center, 26, shell, NumberRange.new(0.4, 1.2), 30, 1.2)
	local sparks = { rarity.color, rarity.color:Lerp(Color3.new(1, 1, 1), 0.5) }
	Burst.play(center, 8 + 8 * rarity.particles, sparks, NumberRange.new(0.2, 0.45), 36, 0.9, false, true)
	Fx.flash(center, rarity.color, 10 + 3 * rarity.particles, 0.45)
	Shake.impulse("Hatch", 0.3, 0.3)
	if rarity.order >= Rarities.Legendary.order then
		Fx.pillar(Vector3.new(pos.X, 0.3, pos.Z), rarity.color, 50, 2.5)
	end
end

-- Billboard banner: rarity (gradient, rainbow for Secret) over the pet name.
local function banner(pet: Model, rarityName: string, petName: string)
	local root = pet.PrimaryPart
	if not root then
		return
	end
	local rarity = rarityOf(rarityName)
	local gui = Instance.new("BillboardGui")
	gui.Name = "RevealBanner"
	gui.Size = UDim2.fromOffset(300, 96) -- constant on-screen size at any distance
	gui.StudsOffsetWorldSpace = Vector3.new(0, pet:GetExtentsSize().Y + 2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 150
	gui.LightInfluence = 0
	local function label(text: string, y: number, h: number, colors: { Color3 }): TextLabel
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, h)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.Text = text
		l.TextColor3 = Color3.new(1, 1, 1)
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = ColorSequence.new(colors[1], colors[2])
		g.Parent = l
		local s = Instance.new("UIStroke")
		s.Thickness = 3
		s.Color = Color3.fromRGB(25, 20, 30)
		s.Parent = l
		l.Parent = gui
		return l
	end
	local top = rarity.color:Lerp(Color3.new(1, 1, 1), 0.45)
	local tag = label(string.upper(rarityName), 0, 0.5, { top, rarity.color })
	label(petName, 0.52, 0.42, { Color3.new(1, 1, 1), Color3.fromRGB(220, 220, 230) })
	local scale = Instance.new("UIScale")
	scale.Scale = 0
	scale.Parent = tag
	gui.Adornee = root
	gui.Parent = pet

	local rainbow = rarityName == "Secret"
	local grad = tag:FindFirstChildOfClass("UIGradient") :: UIGradient
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local k = math.clamp(t / 0.4, 0, 1)
		local s = 1.70158
		scale.Scale = if k >= 1 then 1 else 1 + (s + 1) * (k - 1) ^ 3 + s * (k - 1) ^ 2
		if rainbow then
			local h = (t * 0.4) % 1
			grad.Color = ColorSequence.new(Color3.fromHSV(h, 0.6, 1), Color3.fromHSV((h + 0.3) % 1, 0.8, 1))
		end
		if t > 2.8 then
			conn:Disconnect()
			gui:Destroy()
		end
	end)
end

function Hatch.PetReveal(target: Instance?, params: { [string]: any })
	if not (target and target:IsA("Model")) then
		return
	end
	local pet = target :: Model
	local rarity = rarityOf(params.rarity)
	local base = pet:GetScale()
	local pos = pet:GetPivot().Position
	-- Squash-bounce pop: 0.2 -> overshoot -> 1 (relative to any size-mutation scale).
	pet:ScaleTo(base * 0.2)
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		if not pet.Parent then
			conn:Disconnect()
			return
		end
		local k = math.clamp((os.clock() - t0) / 0.5, 0, 1)
		local s = 2.4
		local back = if k >= 1 then 1 else 1 + (s + 1) * (k - 1) ^ 3 + s * (k - 1) ^ 2
		pet:ScaleTo(base * (0.2 + 0.8 * back))
		if k >= 1 then
			conn:Disconnect()
			pet:ScaleTo(base)
		end
	end)
	Burst.play(
		pos + Vector3.new(0, 2, 0),
		10 + 6 * rarity.particles,
		{ rarity.color, Color3.new(1, 1, 1) },
		NumberRange.new(0.2, 0.5),
		22,
		1,
		false,
		true
	)
	banner(pet, params.rarity or "Common", params.name or pet.Name)
	if rarity.order >= Rarities.Legendary.order then
		Fx.pillar(Vector3.new(pos.X, 0.3, pos.Z), rarity.color, 45, 2)
	end
end

function Hatch.MoneyPop(target: Instance?, params: { [string]: any })
	local pos = Fx.posOf(target)
	if not pos then
		return
	end
	local anchor = Pool.anchor(CFrame.new(pos + Vector3.new(0, 3, 0)))
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(150, 48)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = "+$" .. Fx.formatNumber(params.amount or 0)
	l.TextColor3 = Color3.fromRGB(120, 255, 110)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(20, 60, 20)
	s.Parent = l
	l.Parent = gui
	gui.Adornee = anchor
	gui.Parent = anchor
	local t0 = os.clock()
	local start = anchor.Position
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / 0.9
		if k >= 1 then
			conn:Disconnect()
			Pool.release(anchor)
			return
		end
		anchor.CFrame = CFrame.new(start + Vector3.new(0, 3 * k, 0))
		l.TextTransparency = math.max(0, (k - 0.5) * 2)
		s.Transparency = l.TextTransparency
	end)
end

function Hatch.Announce(_target: Instance?, params: { [string]: any })
	local rarityName = params.rarity or "Legendary"
	local rarity = rarityOf(rarityName)
	Popup.toast(params.text or "", rarity.color, rarityName == "Secret")
end

return Hatch
