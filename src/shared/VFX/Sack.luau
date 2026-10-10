--!strict
-- Kick Sack effects (Partner B, client). Target = the sack model (SackController). Steps follow
-- Config/Upgrades.Sack.tiers[tier].fx; each step keeps everything from the one before:
--   Basics    dust puff, cloth bits, a soft thud                    (tiers 1-3)
--   Comic     + POW stars, a comic word, a punchier hit             (4-6)
--   Champion  + a glint flash, an impact ring, theme coins/sparks   (7-9)
--   Elemental + element burst, a floor shockwave, a camera thump    (10-14)
--   Mythic    + big burst and shake; every 10th kick is a super hit (15-19)
--   God       + rainbow rings, confetti; super hits flash the screen (20)
-- Each sack's theme (Builders/Models/Sacks look.theme) picks its colours, words and sounds.
--   SackDrop    {tier, floor: Vector3, own?}                 the sack slams to a stop on its chain
--   SackHit     {tier, at: Vector3, dir: Vector3, floor: Vector3, own?, super?, gain?}  one kick lands
--   SackUpgrade {tier, floor?, own?}                         a new sack was bought
-- Sack.legTrail(character, tier) returns a remover. (The idle auras are VFX/SackAura, the remodel's.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Upgrades = require(Shared:WaitForChild("Config"):WaitForChild("Upgrades"))
local Sacks = require(Shared:WaitForChild("Builders"):WaitForChild("Models"):WaitForChild("Sacks"))
local Pool = require(script.Parent.Pool)
local Burst = require(script.Parent.Burst)
local Fx = require(script.Parent.Fx)
local Shake = require(script.Parent.Shake)
local Hatch = require(script.Parent.Hatch)

local Sack = {}

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"
local STEPS = { Basics = 1, Comic = 2, Champion = 3, Elemental = 4, Mythic = 5, God = 6 }
local rng = Random.new()

-- Built-in engine sounds, retuned per use. Swap `id` for uploaded SFX later without touching callers.
type Sfx = { id: string, pitch: number, volume: number }
local THUD = "rbxasset://sounds/action_jump_land.mp3"
local BOOM = "rbxasset://sounds/impact_explosion_03.mp3"
local SPLASH = "rbxasset://sounds/impact_water.mp3"
local WHOOSH = "rbxasset://sounds/action_jump.mp3"
local SFX: { [string]: Sfx } = {
	thud = { id = THUD, pitch = 0.8, volume = 0.7 },
	punch = { id = BOOM, pitch = 2.6, volume = 0.22 },
	clang = { id = BOOM, pitch = 3.6, volume = 0.18 },
	gong = { id = BOOM, pitch = 0.55, volume = 0.25 },
	splash = { id = SPLASH, pitch = 1.4, volume = 0.5 },
	boom = { id = BOOM, pitch = 1.1, volume = 0.35 },
	bass = { id = BOOM, pitch = 0.45, volume = 0.55 },
	whoosh = { id = WHOOSH, pitch = 0.7, volume = 0.4 },
	zap = { id = BOOM, pitch = 4.5, volume = 0.2 },
}
-- Theme -> extra sound on hits (Elemental and up).
local THEME_SFX: { [string]: string } = {
	frost = "splash",
	crystal = "clang",
	sprinkles = "splash",
	embers = "boom",
	lightning = "zap",
	goo = "splash",
	robo = "zap",
	fire = "boom",
	cosmic = "bass",
	holy = "gong",
	rainbow = "bass",
}
local WORDS: { [string]: { string } } = {
	Comic = { "POW!", "BAM!", "WHAM!" },
	Champion = { "BONG!", "CLANG!", "POW!" },
	frost = { "CRACK!", "FREEZE!" },
	crystal = { "SHINE!", "CHING!" },
	sprinkles = { "BOING!", "SWEET!" },
	embers = { "SIZZLE!", "BLAM!" },
	lightning = { "ZAP!", "BZZT!" },
	goo = { "SPLAT!", "GLOOP!" },
	robo = { "BEEP!", "CLUNK!" },
	fire = { "ROAR!", "FWOOSH!" },
	cosmic = { "WHOOM!", "BOOM!" },
	holy = { "SHINE!", "GLORY!" },
	rainbow = { "KAPOW!", "BOOM!" },
}

local function stepOf(tier: number): number
	local info = Upgrades.Sack.tiers[math.clamp(tier, 1, #Upgrades.Sack.tiers)]
	return STEPS[info.fx] or 1
end

local function play(name: string, pos: Vector3, pitchJitter: number?)
	local s = SFX[name]
	if not s then
		return
	end
	local anchor = Pool.anchor(CFrame.new(pos))
	local sound = Instance.new("Sound")
	sound.SoundId = s.id
	sound.Volume = s.volume
	sound.PlaybackSpeed = s.pitch * (1 + rng:NextNumber(-1, 1) * (pitchJitter or 0.06))
	sound.RollOffMinDistance = 12
	sound.RollOffMaxDistance = 120
	sound.Parent = anchor
	sound:Play()
	task.delay(2.5, Pool.release, anchor)
end

local function puff(
	pos: Vector3,
	texture: string,
	colors: { Color3 },
	count: number,
	size: number,
	speed: number,
	light: boolean?
)
	local anchor = Pool.anchor(CFrame.new(pos), Vector3.new(1, 1, 1))
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = if #colors > 1 then ColorSequence.new(colors[1], colors[2]) else ColorSequence.new(colors[1])
	e.Size = NumberSequence.new(size, size * 2)
	e.Transparency = NumberSequence.new(0.15, 1)
	e.Lifetime = NumberRange.new(0.35, 0.7)
	e.Speed = NumberRange.new(speed * 0.4, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.LightEmission = if light then 1 else 0
	e.Drag = 4
	e.Rate = 0
	e.Parent = anchor
	e:Emit(count)
	task.delay(1, Pool.release, anchor)
end

-- `count` neon pieces in a circle (normal = `up`) that fly out from r0 to r1 and fade.
local function ringWave(
	center: Vector3,
	up: Vector3,
	colors: { Color3 },
	r0: number,
	r1: number,
	seconds: number,
	count: number,
	thick: number?
)
	local base = if math.abs(up.Unit.Y) > 0.99
		then CFrame.new(center)
		else CFrame.lookAt(center, center + up) * CFrame.Angles(math.rad(-90), 0, 0) -- local Y = up
	local pieces = {}
	for i = 1, count do
		local p = Pool.get("Block")
		p.Material = Enum.Material.Neon
		p.Color = colors[(i - 1) % #colors + 1]
		p.Size = Vector3.new(thick or 0.25, thick or 0.25, 2 * math.pi * r0 / count + 0.3)
		pieces[i] = p
	end
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / seconds
		if k >= 1 then
			conn:Disconnect()
			for _, p in pieces do
				Pool.release(p)
			end
			return
		end
		local e = 1 - (1 - k) ^ 3
		local r = r0 + (r1 - r0) * e
		for i, p in pieces do
			local a = (i / count) * math.pi * 2
			p.Size = Vector3.new(p.Size.X, p.Size.Y, 2 * math.pi * r / count + 0.2)
			p.CFrame = base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -r)
			p.Transparency = k
		end
	end)
end

-- Comic word that pops in with a bounce, drifts up and fades.
local function word(pos: Vector3, text: string, color: Color3, scale: number)
	local anchor = Pool.anchor(CFrame.new(pos))
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(math.floor(150 * scale), math.floor(60 * scale))
	gui.AlwaysOnTop = true
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.2, 0.2)
	label.Rotation = rng:NextNumber(-14, 8)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(11, 16, 32)
	stroke.Parent = label
	label.Parent = gui
	gui.Adornee = anchor
	gui.Parent = anchor
	TweenService:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1, 1),
	}):Play()
	local t0 = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / 0.6
		if k >= 1 then
			conn:Disconnect()
			Pool.release(anchor)
			return
		end
		anchor.CFrame = CFrame.new(pos + Vector3.new(0, 1.2 * k, 0))
		local fade = math.max(0, (k - 0.55) / 0.45)
		label.TextTransparency = fade
		stroke.Transparency = fade
	end)
end

local function screenFlash(color: Color3, seconds: number)
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SackFlash"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	local f = Instance.new("Frame")
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 0.35
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.Parent = gui
	gui.Parent = pg
	local tw = TweenService:Create(f, TweenInfo.new(seconds, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
	tw.Completed:Once(function()
		gui:Destroy()
	end)
	tw:Play()
end

local function body(target: Instance?): BasePart?
	local b = target and target:FindFirstChild("Body")
	return if b and b:IsA("BasePart") then b else nil
end

local function pick(list: { string }): string
	return list[rng:NextInteger(1, #list)]
end

-- Effects ------------------------------------------------------------------

function Sack.SackDrop(target: Instance?, params: { [string]: any })
	local tier = params.tier or 1
	local look = Sacks.look(tier)
	local step = stepOf(tier)
	local floor: Vector3 = params.floor or (Fx.posOf(target) or Vector3.zero)
	local b = body(target)
	local center = if b then b.Position else floor + Vector3.new(0, 3.4, 0)
	-- Basics: dust ring on the floor, BONK
	puff(floor + Vector3.new(0, 0.4, 0), SMOKE, { Color3.fromRGB(230, 222, 205) }, 14, 1.2, 14)
	ringWave(floor + Vector3.new(0, 0.2, 0), Vector3.yAxis, { Color3.fromRGB(240, 232, 215) }, 1.5, 6, 0.4, 14, 0.3)
	word(center + Vector3.new(-1.5, 1.5, 0), "BONK!", Color3.fromRGB(255, 225, 77), 1)
	play("thud", center)
	play("whoosh", center + Vector3.new(0, 4, 0), 0.1)
	if step >= 2 then
		Burst.play(
			center,
			8,
			{ Color3.fromRGB(255, 225, 77), Color3.new(1, 1, 1) },
			NumberRange.new(0.25, 0.5),
			22,
			0.6,
			false,
			true
		)
	end
	if step >= 3 then
		Fx.flash(center, look.fx[1], 6, 0.35)
		play("clang", center)
	end
	if step >= 4 then
		Fx.pillar(floor, look.fx[1], 40, 0.9)
		ringWave(floor + Vector3.new(0, 0.3, 0), Vector3.yAxis, look.fx, 2, 11, 0.6, 20, 0.35)
		puff(center, SPARK, look.fx, 24, 0.8, 18, true)
		play(THEME_SFX[look.theme] or "boom", center)
	end
	if step >= 5 then
		Burst.play(center, 18, look.fx, NumberRange.new(0.3, 0.7), 34, 0.9, false, true)
		if params.own then
			Shake.impulse("SackDrop", 0.45, 0.35)
		end
		play("bass", center)
	end
	if step >= 6 then
		for i, c in look.fx do
			task.delay(i * 0.04, Fx.pillar, floor + Vector3.new(math.cos(i) * 2, 0, math.sin(i) * 2), c, 60, 1.2)
		end
		Burst.play(center + Vector3.new(0, 2, 0), 30, look.fx, NumberRange.new(0.2, 0.45), 30, 1.4, true, true)
		word(center + Vector3.new(0, 3.5, 0), "LEGENDARY!", Color3.fromRGB(255, 225, 77), 1.6)
	end
end

function Sack.SackHit(target: Instance?, params: { [string]: any })
	local tier = params.tier or 1
	local look = Sacks.look(tier)
	local step = stepOf(tier)
	local at: Vector3 = params.at or (Fx.posOf(target) or Vector3.zero)
	local dir: Vector3 = params.dir or Vector3.zAxis
	local floor: Vector3 = params.floor or (at - Vector3.new(0, 3, 0))
	local super = params.super == true and step >= 5
	local own = params.own == true
	local mult = if super then 1.8 else 1
	local b = body(target)
	local cloth = if b then { b.Color, look.fx[1] } else look.fx
	-- Basics: dust puff off the impact, cloth bits, thud; theme extras for the first sacks
	puff(at, SMOKE, { Color3.fromRGB(235, 228, 214) }, math.floor(6 * mult), 0.7, 8)
	Burst.play(at, math.floor(4 * mult), cloth, NumberRange.new(0.15, 0.3), 12, 0.45)
	play("thud", at)
	if look.theme == "chalk" then
		puff(at, SMOKE, { Color3.new(1, 1, 1) }, 8, 0.9, 10)
	elseif look.theme == "sweat" then
		Burst.play(
			at + Vector3.new(0, 1, 0),
			6,
			{ Color3.fromRGB(150, 210, 255) },
			NumberRange.new(0.12, 0.22),
			14,
			0.5,
			false,
			true
		)
	end
	if step >= 2 then
		Burst.play(
			at,
			math.floor(5 * mult),
			{ Color3.fromRGB(255, 225, 77), Color3.new(1, 1, 1) },
			NumberRange.new(0.2, 0.45),
			18,
			0.5,
			false,
			true
		)
		play("punch", at)
		local words = WORDS[look.theme] or WORDS[if step >= 3 then "Champion" else "Comic"]
		word(
			at + Vector3.new(0, 1.6, 0) - dir * 0.5,
			pick(words),
			look.fx[1]:Lerp(Color3.new(1, 1, 1), 0.25),
			if super then 1.5 else 1
		)
		if look.theme == "rubber" then
			ringWave(at, dir, { Color3.fromRGB(42, 42, 46) }, 0.5, 2.2, 0.3, 10, 0.18)
		elseif look.theme == "sparks" then
			Burst.play(
				at,
				10,
				{ Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 240, 160) },
				NumberRange.new(0.08, 0.16),
				26,
				0.4,
				false,
				true
			)
			play("clang", at)
		end
	end
	if step >= 3 then
		Fx.flash(at, look.fx[1], 2.5 * mult, 0.2)
		ringWave(at, dir, { look.fx[1] }, 0.6, 3 * mult, 0.3, 12, 0.2)
		if look.theme == "coins" then
			Burst.play(
				at + Vector3.new(0, 0.5, 0),
				6,
				{ Color3.fromRGB(255, 216, 77) },
				NumberRange.new(0.35, 0.5),
				20,
				0.8,
				true,
				false
			)
			play("clang", at, 0.15)
		elseif look.theme == "glint" then
			play("gong", at)
		end
	end
	if step >= 4 then
		puff(at, SPARK, look.fx, math.floor(14 * mult), 0.6, 16, true)
		ringWave(floor + Vector3.new(0, 0.25, 0), Vector3.yAxis, look.fx, 1.2, 6 * mult, 0.45, 16, 0.25)
		play(THEME_SFX[look.theme] or "boom", at)
		if look.theme == "embers" or look.theme == "fire" then
			puff(at, FIRE, { look.fx[1], look.fx[2] }, math.floor(12 * mult), 1.1, 12, true)
		end
		if own then
			Shake.impulse("SackHit", 0.12 * mult, 0.15)
		end
	end
	if step >= 5 then
		Burst.play(at, math.floor(10 * mult), look.fx, NumberRange.new(0.25, 0.6), 28, 0.7, false, true)
		if own then
			Shake.impulse("SackHit", 0.25 * mult, 0.22)
		end
		if super then
			Fx.flash(at, look.fx[1], 9, 0.4)
			ringWave(at, dir, look.fx, 1, 9, 0.5, 18, 0.35)
			play("bass", at)
		end
	end
	if step >= 6 then
		for i, c in look.fx do
			task.delay(i * 0.03, ringWave, at, dir, { c }, 0.5 + i * 0.2, 3 + i * 0.7, 0.45, 12, 0.22)
		end
		Burst.play(
			at + Vector3.new(0, 1, 0),
			math.floor(14 * mult),
			look.fx,
			NumberRange.new(0.15, 0.35),
			24,
			1,
			true,
			true
		)
		if super and own then
			screenFlash(Color3.new(1, 1, 1), 0.25)
		end
	end
	if own and params.gain then
		Hatch.MoneyPop(target, { text = `+{params.gain} Power`, color = Color3.fromRGB(255, 220, 70) })
	end
end

function Sack.SackUpgrade(target: Instance?, params: { [string]: any })
	local tier = params.tier or 1
	local look = Sacks.look(tier)
	local floor: Vector3? = params.floor
	local b = body(target)
	local pos = if b then b.Position elseif floor then floor + Vector3.new(0, 3.4, 0) else Fx.posOf(target)
	if not pos then
		return
	end
	Fx.pillar(floor or pos - Vector3.new(0, 3.4, 0), look.fx[1], 50, 1.2)
	Burst.play(pos + Vector3.new(0, 1, 0), 26, look.fx, NumberRange.new(0.2, 0.45), 26, 1.3, true, true)
	ringWave(pos, Vector3.yAxis, look.fx, 1, 8, 0.6, 18, 0.3)
	play("gong", pos)
	if params.own then
		local info = Upgrades.Sack.tiers[math.clamp(tier, 1, #Upgrades.Sack.tiers)]
		Hatch.Announce(
			nil,
			{ text = `New Kick Sack: {info.name}!`, rarity = if stepOf(tier) >= 5 then "Legendary" else "Rare" }
		)
	end
end

-- Glowing trail on the kicking foot (Mythic and up). Returns a remover.
function Sack.legTrail(character: Model, tier: number): () -> ()
	local foot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
	if not foot or not foot:IsA("BasePart") or stepOf(tier) < 5 then
		return function() end
	end
	local look = Sacks.look(tier)
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Position, a1.Position = Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0)
	a0.Parent, a1.Parent = foot, foot
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Lifetime = 0.2
	trail.LightEmission = 1
	trail.FaceCamera = true
	trail.Color = if #look.fx >= 3
		then ColorSequence.new({
			ColorSequenceKeypoint.new(0, look.fx[1]),
			ColorSequenceKeypoint.new(0.5, look.fx[2]),
			ColorSequenceKeypoint.new(1, look.fx[#look.fx]),
		})
		else ColorSequence.new(look.fx[1])
	trail.Transparency = NumberSequence.new(0.1, 1)
	trail.Parent = foot
	return function()
		trail:Destroy()
		a0:Destroy()
		a1:Destroy()
	end
end

return Sack
