--!strict
local TweenService = game:GetService("TweenService")
local Assets = require(script.Parent.Assets)
local System = script.Parent.Parent.System
local AssetIds = require(System.AssetIds)
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)
local Audio = require(game:GetService("ReplicatedStorage").Shared.Audio)
local Objective = {}
local C, L, M = Theme.Colors, Theme.Layout, Theme.Motion
local STAGE_ICONS = {
	AssetIds.get("01_burlap_sack"),
	AssetIds.get("hud_eggs"),
	AssetIds.get("hud_pets"),
	AssetIds.get("premium_icons_currency_cash"),
}

function Objective.new(gui: ScreenGui, skip: () -> ())
	local card = Ui.frame(gui, "Objective")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.ZIndex, card.Visible = 40, false
	local shadow = Ui.frame(card, "Shadow", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 6))
	shadow.BackgroundColor3, shadow.BackgroundTransparency = C.border, 0.35
	Ui.corner(shadow, L.radius + 2)
	local panel = Ui.surface(card, "Panel", C.body, Theme.Studs.body, L.border)
	panel.Size, panel.ZIndex = UDim2.fromScale(1, 1), 1
	local header = Ui.header(panel, Theme.Headers.confirm, "First pet", nil, 32, L.minText)
	local heading = header.title
	heading.Name = "Heading"
	heading.AutomaticSize = Enum.AutomaticSize.None
	heading.Size = UDim2.fromScale(1, 1)
	heading:FindFirstChildOfClass("UIStroke").Thickness = 2
	local divider = Ui.frame(panel, "HeaderEdge", UDim2.new(1, 0, 0, 3), UDim2.fromOffset(0, 30))
	divider.BackgroundColor3, divider.BackgroundTransparency, divider.ZIndex = C.border, 0, 4
	local icon = Instance.new("ImageLabel")
	icon.Name, icon.BackgroundTransparency = "Icon", 1
	icon.Image, icon.ScaleType = STAGE_ICONS[1] or Assets.WorldArrow, Enum.ScaleType.Fit
	icon.Position, icon.Size = UDim2.fromOffset(14, 38), UDim2.fromOffset(42, 46)
	icon.ZIndex, icon.Parent = 2, panel
	local sentence = Ui.text(panel, "", 22, { name = "Sentence", stroke = 2 })
	sentence.TextWrapped, sentence.TextTruncate, sentence.ZIndex = true, Enum.TextTruncate.None, 2
	local skipButton = Ui.button(panel, {
		name = "Skip",
		text = "SKIP",
		style = "grey",
		size = UDim2.fromOffset(80, 48),
		textSize = L.minText,
		onClick = skip,
	})
	skipButton.gui.AnchorPoint, skipButton.gui.Position = Vector2.new(1, 0), UDim2.new(1, -12, 0, 37)
	skipButton.gui.ZIndex = 3
	local progress = Ui.progress(panel, Theme.Buttons.lime, 5, L.minText)
	progress.gui.Name, progress.gui.Position = "StageProgress", UDim2.fromOffset(14, 88)
	progress.gui.Size = UDim2.new(1, -28, 0, 5)
	progress.gui.ZIndex = 2
	progress.gui:FindFirstChildOfClass("UIStroke").Thickness = 1
	progress.gui.Text.Visible = false
	local last, lastStage = "", 0
	local successUntil = 0
	local optional = false
	local scale = Motion.scaleOf(card)
	local api = {}
	function api:show(value: string?, stage: number?, complete: boolean?)
		card.Visible = value ~= nil
		if not value then
			last = ""
			return
		end
		sentence.Text = value
		heading.Text = if complete
			then "FIRST PET COMPLETE!"
			elseif optional then "OPTIONAL NEXT STEP"
			else "STEP " .. (stage or 1) .. "/4 • FIRST PET"
		icon.Image = if complete or os.clock() < successUntil
			then AssetIds.get("icon_check") or Assets.Checkmark
			else STAGE_ICONS[stage or 1] or Assets.WorldArrow
		skipButton.setText(if optional then "LATER" else "SKIP")
		skipButton.gui.Visible = not complete
		if stage ~= lastStage then
			lastStage = stage or 1
			progress.set(lastStage / 4)
		end
		if value ~= last then
			scale.Scale = if Motion.reduced() then 1 else 0.97
			Motion.tween(scale, M.reveal, { Scale = 1 })
			last = value
		end
	end
	function api:layout()
		local vp = gui.AbsoluteSize
		local width = math.min(520, vp.X - 28)
		local narrow = width < 390
		card.Size = UDim2.fromOffset(width, 96)
		card.Position = UDim2.new(0.5, 0, 0, if vp.Y < 480 then 4 else 24)
		icon.Visible = not narrow
		local inset, reserve = if narrow then 14 else 68, if narrow then 108 else 172
		sentence.Position, sentence.Size = UDim2.fromOffset(inset, 36), UDim2.new(1, -reserve, 0, 48)
		sentence.TextSize = if width < 340 then L.minText elseif narrow then 18 else 22
		skipButton.gui.Size = UDim2.fromOffset(if narrow then 68 else 80, 48)
	end
	function api:success()
		successUntil = os.clock() + 0.7
		Audio.play("UISuccess")
		icon.Image = AssetIds.get("icon_check") or Assets.Checkmark
		Motion.popIn(icon)
	end
	function api:optional(on: boolean)
		optional = on
	end
	function api:training(hits: number)
		heading.Text = "TRAINING " .. math.min(hits, 3) .. "/3"
	end
	function api:complete()
		self:show("You're ready!", 4, true)
		self:success()
		if Motion.reduced() then
			return
		end
		for i = 1, 8 do
			local spark = Instance.new("ImageLabel")
			spark.Name, spark.Image = "CompletionSparkle", AssetIds.get("fx_sparkle") or Assets.Sparkle
			spark.BackgroundTransparency = 1
			spark.Size, spark.Position = UDim2.fromOffset(22, 22), UDim2.new(0.5, 0, 0.5, 0)
			spark.AnchorPoint, spark.ZIndex, spark.Parent = Vector2.new(0.5, 0.5), 48, card
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
		Motion.stop(scale)
		card:Destroy()
	end
	return api
end

return Objective
