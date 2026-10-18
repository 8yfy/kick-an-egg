--!strict
local TweenService = game:GetService("TweenService")
local Assets = require(script.Parent.Assets)
local Motion = require(script.Parent.Parent.System.Motion)
local Audio = require(game:GetService("ReplicatedStorage").Shared.Audio)
local Objective = {}
local INK = Color3.fromRGB(29, 16, 48)
local GOLD = Color3.fromRGB(255, 216, 74)

local function text(parent: Instance, name: string, value: string, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name, label.Text = name, value
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = size
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 43
	label.Parent = parent
	return label
end

function Objective.new(gui: ScreenGui, skip: () -> ())
	local card = Instance.new("Frame")
	card.Name = "Objective"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.BackgroundColor3 = Color3.fromRGB(255, 181, 35)
	card.BorderSizePixel = 0
	card.ZIndex = 40
	card.Visible = false
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	local border = Instance.new("UIStroke")
	border.Color = INK
	border.Thickness = 4
	border.Parent = card
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 225, 97), Color3.fromRGB(255, 164, 35))
	gradient.Rotation = 90
	gradient.Parent = card
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Image = Assets.WorldArrow
	icon.Position = UDim2.fromOffset(10, 17)
	icon.Size = UDim2.fromOffset(48, 48)
	icon.ZIndex = 43
	icon.Parent = card
	local heading = text(card, "Heading", "YOUR FIRST PET", 13)
	heading.TextColor3 = INK
	heading.Position = UDim2.fromOffset(67, 10)
	heading.Size = UDim2.new(1, -150, 0, 18)
	local sentence = text(card, "Sentence", "", 22)
	sentence.TextColor3 = INK
	sentence.Position = UDim2.fromOffset(67, 30)
	sentence.Size = UDim2.new(1, -150, 0, 44)
	sentence.TextWrapped = true
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "Skip"
	skipButton.Text = "SKIP"
	skipButton.Font = Enum.Font.FredokaOne
	skipButton.TextSize = 15
	skipButton.TextColor3 = INK
	skipButton.BackgroundColor3 = Color3.fromRGB(255, 242, 178)
	skipButton.AnchorPoint = Vector2.new(1, 0.5)
	skipButton.Position = UDim2.new(1, -9, 0.5, 0)
	skipButton.Size = UDim2.fromOffset(65, 44)
	skipButton.ZIndex = 45
	skipButton.Parent = card
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 10)
	cr.Parent = skipButton
	skipButton.Activated:Connect(skip)
	local pips: { Frame } = {}
	for i = 1, 4 do
		local pip = Instance.new("Frame")
		pip.Name = "Stage" .. i
		pip.Size = UDim2.fromOffset(12, 4)
		pip.Position = UDim2.fromOffset(67 + (i - 1) * 17, 79)
		pip.BorderSizePixel = 0
		pip.ZIndex = 43
		pip.Parent = card
		table.insert(pips, pip)
	end
	local last = ""
	local successUntil = 0
	local optional = false
	local api = {}
	function api:show(value: string?, stage: number?, complete: boolean?)
		card.Visible = value ~= nil
		if not value then
			last = ""
			return
		end
		sentence.Text = value
		heading.Text = if complete
			then "FIRST PET, FIRST ADVENTURE!"
			elseif optional then "OPTIONAL NEXT STEP"
			else `STEP {stage or 1}/4 • YOUR FIRST PET`
		icon.Image = if complete or os.clock() < successUntil then Assets.Checkmark else Assets.WorldArrow
		skipButton.Text = if optional then "LATER" else "SKIP"
		skipButton.Visible = not complete
		for i, pip in pips do
			pip.BackgroundColor3 = if i <= (stage or 1) then INK else Color3.fromRGB(255, 237, 160)
		end
		if value ~= last then
			Motion.popIn(card)
			last = value
		end
	end
	function api:layout()
		local vp = gui.AbsoluteSize
		local compact = vp.Y < 480
		local width = math.min(460, vp.X - 28)
		local narrow = width < 340
		local inset = if narrow then 54 else 67
		card.Size = UDim2.fromOffset(width, 92)
		card.Position = UDim2.new(0.5, 0, 0, if compact then 4 else 24)
		icon.Size = UDim2.fromOffset(if narrow then 36 else 48, if narrow then 36 else 48)
		icon.Position = UDim2.fromOffset(10, if narrow then 22 else 17)
		heading.Position = UDim2.fromOffset(inset, 10)
		heading.Size = UDim2.new(1, if narrow then -126 else -150, 0, 18)
		heading.TextSize = if narrow then 11 else 13
		sentence.Position = UDim2.fromOffset(inset, 30)
		sentence.Size = UDim2.new(1, if narrow then -126 else -150, 0, 44)
		sentence.TextSize = if narrow then 16 elseif width < 390 then 18 else 22
		skipButton.Size = UDim2.fromOffset(if narrow then 56 else 65, 44)
		for i, pip in pips do
			pip.Position = UDim2.fromOffset(inset + (i - 1) * 17, 79)
		end
	end
	function api:success()
		successUntil = os.clock() + 0.7
		Audio.play("UISuccess")
		icon.Image = Assets.Checkmark
		Motion.popIn(icon)
	end
	function api:optional(on: boolean)
		optional = on
	end
	function api:training(hits: number)
		heading.Text = `TRAINING {math.min(hits, 3)}/3`
	end
	function api:complete()
		self:show("You're ready!", 4, true)
		self:success()
		if Motion.reduced() then
			return
		end
		for i = 1, 8 do
			local spark = Instance.new("ImageLabel")
			spark.Name = "CompletionSparkle"
			spark.Image = Assets.Sparkle
			spark.BackgroundTransparency = 1
			spark.Size = UDim2.fromOffset(22, 22)
			spark.Position = UDim2.new(0.5, 0, 0.5, 0)
			spark.AnchorPoint = Vector2.new(0.5, 0.5)
			spark.ZIndex = 48
			spark.Parent = card
			local angle = i * math.pi / 4
			local tween =
				TweenService:Create(spark, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(0.5, math.cos(angle) * 120, 0.5, math.sin(angle) * 65),
					ImageTransparency = 1,
					Rotation = i * 25,
				})
			tween.Completed:Once(function()
				spark:Destroy()
			end)
			tween:Play()
		end
	end
	function api:destroy()
		card:Destroy()
	end
	return api
end

return Objective
