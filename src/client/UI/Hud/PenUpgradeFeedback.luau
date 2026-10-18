--!strict
-- Owner-only feedback for a confirmed DataChanged penLevel increase. Initial snapshots are silent.
-- Gameplay geometry stays server-owned: only temporary, non-colliding gate-post copies are animated.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local UI = script.Parent.Parent
local MyBase = require(UI.MyBase)
local Modal = require(UI.System.Modal)
local Motion = require(UI.System.Motion)
local Theme = require(UI.System.Theme)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Audio = require(Shared.Audio)
local Sprites = require(Shared.VFX.WorldSprites)

local Feedback = {}
local GOLD = Color3.fromRGB(255, 211, 105)
local WHITE = Color3.fromRGB(255, 249, 217)

-- A saved profile, repeat delivery, or a stale lower level is not a purchase.
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
	local revision = 0
	local stopped = false
	local cleanups: { () -> () } = {}
	local function clear()
		revision += 1
		for _, cleanup in cleanups do
			cleanup()
		end
		table.clear(cleanups)
	end
	local function tween(obj: Instance, seconds: number, props: { [string]: any })
		local t =
			TweenService:Create(obj, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		table.insert(cleanups, function()
			t:Cancel()
		end)
		t:Play()
	end
	local function notice(token: number, reduced: boolean)
		local card = Instance.new("CanvasGroup")
		card.Name = "PenUpgradeNotice"
		card.BackgroundTransparency = 1
		card.GroupTransparency = 1
		card.Interactable = false
		card.Active = false
		card.LayoutOrder = -200000
		local camera = workspace.CurrentCamera
		local width = math.min(330, (if camera then camera.ViewportSize.X else 390) - 40)
		card.Size = UDim2.fromOffset(width, 56)
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.BackgroundTransparency = 1
		text.Size = UDim2.new(1, -64, 1, -8)
		text.Position = UDim2.fromOffset(32, 4)
		text.Font = Theme.Font
		text.Text = "UPGRADED!"
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextScaled = true
		text.Parent = card
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 36
		cap.MinTextSize = 18
		cap.Parent = text
		local outline = Instance.new("UIStroke")
		outline.Color = Theme.Colors.border
		outline.Thickness = 3
		outline.Parent = text
		for _, side in { 0, 1 } do
			local star = Instance.new("ImageLabel")
			star.Name = "Sparkle"
			star.BackgroundTransparency = 1
			star.Image = Sprites.sparkle
			star.ImageColor3 = GOLD
			star.Size = UDim2.fromOffset(24, 24)
			star.AnchorPoint = Vector2.new(side, 0.5)
			star.Position = UDim2.new(side, if side == 0 then 5 else -5, 0.5, 0)
			star.Parent = card
		end
		local pop = Instance.new("UIScale")
		pop.Scale = if reduced then 1 else 0.9
		pop.Parent = card
		card.Parent = Modal.toastLane() -- existing safe-area-aware lane below quest / zone progress
		table.insert(cleanups, function()
			card:Destroy()
		end)
		tween(card, 0.12, { GroupTransparency = 0 })
		if not reduced then
			tween(pop, 0.14, { Scale = 1.035 })
			task.delay(0.14, function()
				if revision == token then
					tween(pop, 0.12, { Scale = 1 })
				end
			end)
		end
		task.delay(0.76, function()
			if revision == token then
				tween(card, 0.22, { GroupTransparency = 1 })
			end
		end)
	end
	local function decorate(base: Model, pen: Instance, token: number, reduced: boolean)
		local dressing = pen:FindFirstChild("Dressing")
		if not dressing then
			return
		end
		local fx = Instance.new("Model")
		fx.Name = "PenUpgradeFX"
		fx.Parent = workspace
		local hidden: { [BasePart]: number } = {}
		local connections: { RBXScriptConnection } = {}
		local function cleanup()
			for _, c in connections do
				c:Disconnect()
			end
			for p, transparency in hidden do
				if p.Parent then
					p.LocalTransparencyModifier = transparency
				end
			end
			fx:Destroy()
		end
		table.insert(cleanups, cleanup)
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
				tween(
					p,
					0.14,
					{ Size = size * 1.045, CFrame = pivot * (CFrame.new(rel.Position * 1.045) * rel.Rotation) }
				)
				task.delay(0.14, function()
					if revision == token then
						tween(p, 0.24, { Size = size, CFrame = cf })
					end
				end)
			end
			local glow = Instance.new("Highlight")
			glow.Adornee = copy
			glow.DepthMode = Enum.HighlightDepthMode.Occluded
			glow.FillColor, glow.OutlineColor = GOLD, WHITE
			glow.FillTransparency, glow.OutlineTransparency = 0.8, 0.25
			glow.Parent = copy
			tween(glow, 0.48, { FillTransparency = 1, OutlineTransparency = 1 })
			if not reduced then
				local anchor = Instance.new("Part")
				anchor.Name = "SparkleAnchor"
				anchor.Size = Vector3.one * 0.1
				anchor.CFrame = pivot * CFrame.new(0, 6.6, 0)
				anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = true, false, false, false
				anchor.Transparency = 1
				anchor.Parent = fx
				local attachment = Instance.new("Attachment")
				attachment.Parent = anchor
				local sparks = Instance.new("ParticleEmitter")
				sparks.Name = "GoldenSparkles"
				sparks.Texture = Sprites.sparkle
				sparks.Color = ColorSequence.new(GOLD, WHITE)
				sparks.LightEmission = 0.65
				sparks.LightInfluence = 0
				sparks.Rate = 0
				sparks.Enabled = false
				sparks.Lifetime = NumberRange.new(0.35, 0.6)
				sparks.Speed = NumberRange.new(2, 4)
				sparks.SpreadAngle = Vector2.new(55, 55)
				sparks.Rotation = NumberRange.new(0, 180)
				sparks.RotSpeed = NumberRange.new(-40, 40)
				sparks.Drag = 3
				sparks.Acceleration = Vector3.new(0, 1.5, 0)
				sparks.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.15),
					NumberSequenceKeypoint.new(0.2, 0.65),
					NumberSequenceKeypoint.new(1, 0),
				})
				sparks.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.15),
					NumberSequenceKeypoint.new(0.5, 0.1),
					NumberSequenceKeypoint.new(1, 1),
				})
				sparks.Parent = attachment
				sparks:Emit(if me:GetAttribute("LowDetail") == true then 3 else 7)
			end
		end
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
		local reduced = Motion.reduced()
		notice(token, reduced)
		Audio.play("PenUpgrade")
		-- Replication may deliver DataChanged before the rebuilt pen. Never animate the old geometry.
		task.spawn(function()
			local deadline = os.clock() + 1.5
			while not stopped and revision == token and os.clock() < deadline do
				local base = MyBase.get()
				local pen = base and base:FindFirstChild("Pen")
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
					and posts == 2
					and base:GetAttribute("OwnerUserId") == me.UserId
					and base:GetAttribute("PenBuiltLevel") == level
				then
					decorate(base, pen, token, reduced)
					return
				end
				task.wait(0.05)
			end
		end)
		-- Bounded cleanup even if the pen is removed / not streamed in.
		task.delay(0.99, function()
			if revision == token then
				clear()
			end
		end)
	end
	-- Preload typed Sound instances: bare audio ids are interpreted as image content by PreloadAsync.
	task.spawn(function()
		local pop, ding = Instance.new("Sound"), Instance.new("Sound")
		pop.SoundId, ding.SoundId = Audio.Bank.Sources.penPop.id, Audio.Bank.Sources.penDing.id
		pcall(function()
			ContentProvider:PreloadAsync({ pop, ding, Sprites.sparkle })
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
