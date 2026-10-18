--!strict
-- Confirmed, owner-local pen celebration. Only disposable visuals move.
-- The title lives in the world below the owner's portrait, never in the player's HUD.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local UI = script.Parent.Parent
local MyBase = require(UI.MyBase)
local Motion = require(UI.System.Motion)
local Theme = require(UI.System.Theme)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Audio = require(Shared.Audio)
local Sprites = require(Shared.VFX.WorldSprites)
local Feedback = {}
local GOLD = Color3.fromRGB(255, 196, 58)
local CREAM = Color3.fromRGB(255, 248, 208)
local GREEN = Color3.fromRGB(179, 255, 105)
local DURATION = 1.6

function Feedback.isIncrease(previous: number?, level: any): boolean
	return typeof(level) == "number"
		and level == level
		and level % 1 == 0
		and level >= 1
		and previous ~= nil
		and level > previous
end

function Feedback.new()
	local me = Players.LocalPlayer
	local lastLevel: number? = nil
	local revision, stopped = 0, false
	local cleanups: { () -> () } = {}
	local random = Random.new()
	local function clear()
		revision += 1
		for _, cleanup in cleanups do
			cleanup()
		end
		table.clear(cleanups)
	end
	local function later(token: number, seconds: number, fn: () -> ())
		task.delay(seconds, function()
			if revision == token and not stopped then
				fn()
			end
		end)
	end
	local function tween(obj: Instance, seconds: number, props: { [string]: any }, style: Enum.EasingStyle?)
		local t = TweenService:Create(
			obj,
			TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			props
		)
		table.insert(cleanups, function()
			t:Cancel()
		end)
		t:Play()
	end
	local function part(parent: Instance, name: string, cf: CFrame, size: Vector3, transparency: number): Part
		local p = Instance.new("Part")
		p.Name, p.CFrame, p.Size = name, cf, size
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.CastShadow, p.Transparency = false, transparency
		p.Material, p.Color = Enum.Material.Neon, GOLD
		p.Parent = parent
		return p
	end
	local function sparks(at: BasePart, count: number, wide: boolean)
		local a = Instance.new("Attachment")
		a.Parent = at
		local e = Instance.new("ParticleEmitter")
		e.Name, e.Texture = "GoldenSparkles", Sprites.sparkle
		e.Color = ColorSequence.new(GOLD, CREAM)
		e.LightEmission, e.LightInfluence = 0.85, 0
		e.Rate, e.Enabled = 0, false
		e.Lifetime = NumberRange.new(0.35, 0.65)
		e.Speed = if wide then NumberRange.new(4, 8) else NumberRange.new(2, 4)
		e.SpreadAngle = Vector2.new(48, 48)
		e.Rotation, e.RotSpeed = NumberRange.new(-180, 180), NumberRange.new(-60, 60)
		e.Drag, e.Acceleration = 3, Vector3.new(0, 2, 0)
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.12),
			NumberSequenceKeypoint.new(0.15, 0.8),
			NumberSequenceKeypoint.new(1, 0),
		})
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.55, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Parent = a
		e:Emit(count)
	end

	local function title(fx: Model, area: BasePart, level: number, token: number, reduced: boolean)
		local start = area.CFrame * CFrame.new(0, 10, -area.Size.Z * 0.15)
		local anchor = part(fx, "TitleAnchor", start, Vector3.one * 0.1, 1)
		local gui = Instance.new("BillboardGui")
		gui.Name, gui.Adornee = "PenUpgradeNotice", anchor
		gui.Size = UDim2.fromScale(26, 6.5)
		gui.MaxDistance, gui.LightInfluence = 200, 0
		gui.AlwaysOnTop, gui.Active, gui.ResetOnSpawn = false, false, false
		gui.Parent = anchor
		local card = Instance.new("CanvasGroup")
		card.Name, card.Size = "Title", UDim2.fromScale(1, 1)
		card.BackgroundTransparency, card.GroupTransparency = 1, 1
		card.Interactable, card.Active = false, false
		card.Rotation = if reduced then 0 else -4
		card.Parent = gui
		local text = Instance.new("TextLabel")
		text.Name, text.BackgroundTransparency = "Text", 1
		text.Size, text.Position = UDim2.fromScale(0.82, 0.68), UDim2.fromScale(0.09, 0.04)
		text.Font, text.Text, text.TextScaled = Theme.Font, "UPGRADED!", true
		text.TextColor3 = Color3.new(1, 1, 1)
		text.Parent = card
		local outline = Instance.new("UIStroke")
		outline.Color, outline.Thickness = Theme.Colors.border, 4
		outline.Parent = text
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, CREAM),
			ColorSequenceKeypoint.new(1, GOLD),
		})
		gradient.Rotation = 90
		gradient.Parent = text
		local levelText = text:Clone()
		levelText.Name, levelText.Text = "Level", `PEN LEVEL {level}`
		levelText.Size, levelText.Position = UDim2.fromScale(0.6, 0.23), UDim2.fromScale(0.2, 0.73)
		levelText.TextColor3 = GREEN
		levelText:FindFirstChildOfClass("UIGradient"):Destroy()
		levelText:FindFirstChildOfClass("UIStroke").Thickness = 2
		levelText.Parent = card
		for _, side in { 0, 1 } do
			local star = Instance.new("ImageLabel")
			star.Name, star.Image = "Sparkle", Sprites.star
			star.BackgroundTransparency, star.ImageColor3 = 1, CREAM
			star.Size = UDim2.fromScale(0.09, 0.36)
			star.AnchorPoint, star.Position =
				Vector2.new(0.5, 0.5), UDim2.fromScale(if side == 0 then 0.05 else 0.95, 0.37)
			star.Rotation = if side == 0 then -18 else 18
			star.Parent = card
			if not reduced then
				tween(star, 0.8, { Rotation = if side == 0 then 30 else -30 })
			end
		end
		local pop = Instance.new("UIScale")
		pop.Scale = if reduced then 1 else 0.55
		pop.Parent = card
		tween(card, 0.12, { GroupTransparency = 0, Rotation = 0 })
		if not reduced then
			tween(pop, 0.2, { Scale = 1.06 }, Enum.EasingStyle.Back)
			later(token, 0.2, function()
				tween(pop, 0.18, { Scale = 1 })
			end)
			tween(anchor, 1.1, { CFrame = start + Vector3.new(0, 1.8, 0) }, Enum.EasingStyle.Sine)
		end
		later(token, 0.88, function()
			tween(card, 0.24, { GroupTransparency = 1 })
		end)
		later(token, 1.13, function()
			gui:Destroy()
		end)
	end

	local function perimeter(fx: Model, area: BasePart, token: number, low: boolean)
		local hw, hd = area.Size.X / 2 + 0.7, area.Size.Z / 2 + 0.7
		-- A flat, expanding light ripple ties the bursts together across the pen floor.
		local ripple = part(fx, "UpgradeRipple", area.CFrame * CFrame.new(0, 0.65, 0), Vector3.new(4, 0.05, 4), 1)
		local surface = Instance.new("SurfaceGui")
		surface.Face, surface.CanvasSize = Enum.NormalId.Top, Vector2.new(256, 256)
		surface.LightInfluence, surface.Brightness = 0, 2
		surface.Parent = ripple
		local ring = Instance.new("ImageLabel")
		ring.Size = UDim2.fromScale(1, 1)
		ring.BackgroundTransparency, ring.ImageTransparency = 1, 0.15
		ring.Image, ring.ImageColor3 = Sprites.ring, CREAM
		ring.Parent = surface
		local diameter = math.min(area.Size.X, area.Size.Z) * 0.9
		tween(ripple, 0.8, { Size = Vector3.new(diameter, 0.05, diameter) }, Enum.EasingStyle.Quart)
		tween(ring, 0.8, { ImageTransparency = 1 }, Enum.EasingStyle.Sine)
		for _, side in { -1, 1 } do
			local points = {
				Vector3.new(side * 7.4, 0.65, -hd),
				Vector3.new(side * hw, 0.65, -hd),
				Vector3.new(side * hw, 0.65, hd),
				Vector3.new(0, 0.65, hd),
			}
			for i = 1, 3 do
				later(token, (i - 1) * 0.16, function()
					local anchor = part(fx, "BoundarySweep", area.CFrame, Vector3.one * 0.1, 1)
					local a, b = Instance.new("Attachment"), Instance.new("Attachment")
					a.Position, b.Position = points[i], points[i]
					a.Parent, b.Parent = anchor, anchor
					local beam = Instance.new("Beam")
					beam.Name, beam.Attachment0, beam.Attachment1 = "GoldRibbon", a, b
					beam.FaceCamera, beam.LightEmission, beam.LightInfluence = true, 1, 0
					beam.Color, beam.Transparency = ColorSequence.new(CREAM, GOLD), NumberSequence.new(0.15)
					beam.Width0, beam.Width1 = 1, 1
					beam.Parent = anchor
					tween(b, 0.22, { Position = points[i + 1] }, Enum.EasingStyle.Sine)
					later(token, 0.25, function()
						tween(beam, 0.5, { Width0 = 0, Width1 = 0 })
					end)
				end)
			end
			for _, back in { -1, 1 } do
				local cf = area.CFrame * CFrame.new(side * hw, 1, back * hd)
				later(token, if back == -1 then 0.12 else 0.36, function()
					local anchor = part(fx, "CornerFlare", cf, Vector3.one * 0.1, 1)
					sparks(anchor, if low then 2 else 5, true)
					local a, b = Instance.new("Attachment"), Instance.new("Attachment")
					b.Position = Vector3.new(0, 3, 0)
					a.Parent, b.Parent = anchor, anchor
					local ray = Instance.new("Beam")
					ray.Name, ray.Attachment0, ray.Attachment1 = "CornerRay", a, b
					ray.Color, ray.Transparency = ColorSequence.new(GOLD, CREAM), NumberSequence.new(0.55)
					ray.FaceCamera, ray.LightEmission, ray.LightInfluence = true, 1, 0
					ray.Width0, ray.Width1 = 1.4, 0
					ray.Parent = anchor
					tween(b, 0.45, { Position = Vector3.new(0, 8, 0) })
					tween(ray, 0.6, { Width0 = 0 })
					for n = 1, (if low then 1 else 2) do
						local shard = part(fx, "GoldConfetti", cf, Vector3.one * random:NextNumber(0.25, 0.45), 0.05)
						local target = cf
							* CFrame.new(
								side * random:NextNumber(1, 3),
								random:NextNumber(3, 6),
								back * random:NextNumber(1, 3)
							)
							* CFrame.Angles(1, 2, n)
						tween(
							shard,
							0.65,
							{ CFrame = target, Size = Vector3.one * 0.05, Transparency = 1 },
							Enum.EasingStyle.Quart
						)
					end
				end)
			end
		end
	end

	local function decorate(base: Model, pen: Instance, area: BasePart, level: number, token: number, reduced: boolean)
		local dressing = pen:FindFirstChild("Dressing")
		if not dressing then
			return
		end
		local fx = Instance.new("Model")
		fx.Name = "PenUpgradeFX"
		fx:SetAttribute("OwnerUserId", me.UserId)
		fx:SetAttribute("PenLevel", level)
		fx.Parent = workspace
		local hidden: { [BasePart]: number } = {}
		local connections: { RBXScriptConnection } = {}
		table.insert(cleanups, function()
			for _, c in connections do
				c:Disconnect()
			end
			for p, transparency in hidden do
				if p.Parent then
					p.LocalTransparencyModifier = transparency
				end
			end
			fx:Destroy()
		end)
		table.insert(
			connections,
			pen.AncestryChanged:Connect(function()
				if not pen:IsDescendantOf(workspace) and revision == token then
					clear()
				end
			end)
		)
		table.insert(
			connections,
			base:GetAttributeChangedSignal("OwnerUserId"):Connect(function()
				if base:GetAttribute("OwnerUserId") ~= me.UserId and revision == token then
					clear()
				end
			end)
		)
		title(fx, area, level, token, reduced)
		local low = me:GetAttribute("LowDetail") == true
		if not reduced then
			perimeter(fx, area, token, low)
		end
		for _, post in dressing:GetChildren() do
			if post.Name ~= "GatePost" or not post:IsA("Model") then
				continue
			end
			local pivot = post:GetPivot()
			local copy = post:Clone()
			copy.Name = "DecorativePost"
			for _, p in copy:GetDescendants() do
				if p:IsA("BasePart") then
					p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
				elseif p:IsA("LuaSourceContainer") then
					p:Destroy()
				end
			end
			copy.Parent = fx
			for _, p in post:GetDescendants() do
				if p:IsA("BasePart") then
					hidden[p] = p.LocalTransparencyModifier
					p.LocalTransparencyModifier = 1
				end
			end
			for _, p in copy:GetDescendants() do
				if not p:IsA("BasePart") or reduced then
					continue
				end
				local size, cf = p.Size, p.CFrame
				local rel = pivot:ToObjectSpace(cf)
				tween(p, 0.18, {
					Size = size * 1.09,
					CFrame = pivot * (CFrame.new(rel.Position * 1.09 + Vector3.new(0, 0.25, 0)) * rel.Rotation),
				})
				later(token, 0.18, function()
					tween(p, 0.3, { Size = size, CFrame = cf }, Enum.EasingStyle.Back)
				end)
			end
			local glow = Instance.new("Highlight")
			glow.Adornee, glow.DepthMode = copy, Enum.HighlightDepthMode.Occluded
			glow.FillColor, glow.OutlineColor = GOLD, CREAM
			glow.FillTransparency, glow.OutlineTransparency = 0.6, 0.1
			glow.Parent = copy
			tween(glow, 0.7, { FillTransparency = 1, OutlineTransparency = 1 })
			if not reduced then
				local anchor = part(fx, "SparkleAnchor", pivot * CFrame.new(0, 7, 0), Vector3.one * 0.1, 1)
				local light = Instance.new("PointLight")
				light.Color, light.Range, light.Brightness = GOLD, 12, 2
				light.Parent = anchor
				tween(light, 0.65, { Brightness = 0 })
				sparks(anchor, if low then 3 else 7, true)
			end
		end
		later(token, DURATION, clear)
	end
	local function observe(partial: { [string]: any })
		if stopped then
			return
		end
		local level = partial.penLevel
		if typeof(level) ~= "number" or level ~= level or level % 1 ~= 0 or level < 1 then
			return
		end
		local increase = Feedback.isIncrease(lastLevel, level)
		lastLevel = math.max(lastLevel or level, level)
		if not increase then
			return
		end
		clear()
		local token = revision
		Audio.play("PenUpgrade")
		task.spawn(function()
			local deadline = os.clock() + 1.2
			while not stopped and revision == token and os.clock() < deadline do
				local base = MyBase.get()
				local pen = base and base:FindFirstChild("Pen")
				local area = base and base:FindFirstChild("PenArea")
				local dress = pen and pen:FindFirstChild("Dressing")
				local posts = 0
				if dress then
					for _, p in dress:GetChildren() do
						if p.Name == "GatePost" then
							posts += 1
						end
					end
				end
				if
					base
					and pen
					and area
					and area:IsA("BasePart")
					and posts == 2
					and base:GetAttribute("OwnerUserId") == me.UserId
					and base:GetAttribute("PenBuiltLevel") == level
				then
					decorate(base, pen, area, level, token, Motion.reduced())
					return
				end
				task.wait(0.05)
			end
		end)
		later(token, 3, clear)
	end
	task.spawn(function()
		local pop, ding = Instance.new("Sound"), Instance.new("Sound")
		pop.SoundId, ding.SoundId = Audio.Bank.Sources.penPop.id, Audio.Bank.Sources.penDing.id
		pcall(function()
			ContentProvider:PreloadAsync({ pop, ding, Sprites.sparkle, Sprites.star, Sprites.ring })
		end)
		pop:Destroy()
		ding:Destroy()
	end)
	return {
		observe = observe,
		destroy = function()
			stopped = true
			clear()
		end,
	}
end
return Feedback
