--!strict
local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)
local Style = require(script.Parent.Style)
local Objective = {}
local C, L = Theme.Colors, Theme.Layout

function Objective.new(gui: ScreenGui, skip: () -> ())
	local card = Ui.frame(gui, "Objective")
	card.AnchorPoint, card.ZIndex, card.Visible = Vector2.new(0.5, 0), 40, false
	-- Padding gives the original border and shadow room inside the fading group.
	local reveal = Instance.new("CanvasGroup")
	reveal.Name, reveal.BackgroundTransparency = "Reveal", 1
	reveal.Position, reveal.Size = UDim2.fromOffset(-6, -6), UDim2.new(1, 12, 1, 24)
	reveal.Parent = card
	local content = Ui.frame(reveal, "Content", UDim2.new(1, -12, 1, -24), UDim2.fromOffset(6, 6))
	local shadow = Ui.frame(content, "Shadow", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 6))
	shadow.BackgroundColor3, shadow.BackgroundTransparency = C.border, 0.35
	Ui.corner(shadow, L.radius + 2)
	local panel = Style.surface(content, "Panel")
	panel.Size, panel.ZIndex = UDim2.fromScale(1, 1), 1
	local header = Style.header(panel, "FIRST PET", 32, L.minText)
	local heading = header.title
	local divider = Ui.frame(panel, "HeaderEdge", UDim2.new(1, 0, 0, 2), UDim2.fromOffset(0, 30))
	divider.BackgroundColor3, divider.BackgroundTransparency, divider.ZIndex = C.border, 0, 4
	local sentence = Ui.text(panel, "", 22, { name = "Sentence", stroke = 2 })
	sentence.TextWrapped, sentence.TextTruncate, sentence.ZIndex = true, Enum.TextTruncate.None, 2
	local skipButton = Style.button(panel, {
		name = "Skip",
		text = "SKIP",
		style = "red",
		size = UDim2.fromOffset(80, 48),
		textSize = L.minText,
		onClick = skip,
	})
	skipButton.gui.AnchorPoint, skipButton.gui.Position = Vector2.new(1, 0), UDim2.new(1, -12, 0, 36)
	skipButton.gui.ZIndex = 3
	local progress = Ui.progress(panel, Theme.Buttons.red, 5, L.minText)
	progress.gui.Name, progress.gui.Position = "StageProgress", UDim2.new(0, 14, 1, -9)
	progress.gui.Size, progress.gui.ZIndex = UDim2.new(1, -28, 0, 5), 2
	progress.gui:FindFirstChildOfClass("UIStroke").Thickness = 1
	progress.gui.Text.Visible = false
	local epoch, last, lastStage = 0, "", 0
	local optional, complete = false, false
	local hint = Style.button(card, {
		name = "Hint",
		text = "SHOW HINT",
		style = "red",
		size = UDim2.fromOffset(156, 48),
		textSize = L.minText,
		onClick = function()
			epoch = os.clock()
		end,
	})
	hint.gui.AnchorPoint, hint.gui.Position = Vector2.new(0.5, 0), UDim2.fromScale(0.5, 0)
	hint.gui.Visible = false
	local scale = Motion.scaleOf(reveal)
	local headingScale = Motion.scaleOf(heading)
	local lastTrainingHits = 0
	local api = {}
	function api:show(value: string?, stage: number?, done: boolean?)
		card.Visible = value ~= nil
		if not value then
			last, epoch = "", 0
			return
		end
		complete = done == true
		if value ~= last then
			last, epoch = value, os.clock()
		end
		sentence.Text = value
		heading.Text = if complete
			then "FIRST PET COMPLETE!"
			elseif optional then "OPTIONAL NEXT STEP"
			else "STEP " .. (stage or 1) .. "/4 • FIRST PET"
		skipButton.setText(if optional then "LATER" else "SKIP")
		skipButton.gui.Visible = not complete
		if stage ~= lastStage then
			lastStage = stage or 1
			progress.set(lastStage / 4)
		end
	end
	function api:layout()
		local vp = gui.AbsoluteSize
		local width = math.min(520, vp.X - 28)
		local narrow = width < 390
		card.Size = UDim2.fromOffset(width, 104)
		card.Position = UDim2.new(0.5, 0, 0, if vp.Y < 480 then 4 else 24)
		sentence.Position, sentence.Size = UDim2.fromOffset(14, 36), UDim2.new(1, if narrow then -108 else -120, 0, 48)
		sentence.TextSize = if width < 340 then L.minText elseif narrow then 18 else 22
		skipButton.gui.Size = UDim2.fromOffset(if narrow then 68 else 80, 48)
	end
	function api:update(t: number)
		-- Keep the previous styled card, briefly tuck it away while the player acts,
		-- then repeat the instruction if needed. SHOW HINT recalls it immediately.
		local elapsed = (t - epoch) % 10
		local alpha = if complete then 0 else math.clamp((elapsed - 4) / 0.2, 0, 1)
		if elapsed < 0.18 and not complete then
			alpha = 1 - elapsed / 0.18
		end
		if Motion.reduced() then
			alpha = if alpha < 0.5 then 0 else 1
		end
		reveal.GroupTransparency, reveal.Visible = alpha, alpha < 1
		reveal.Position = UDim2.fromOffset(-6, -6 + (if Motion.reduced() then 0 else alpha * 6))
		scale.Scale = if Motion.reduced() or complete then 1 else 1 - alpha * 0.03
		hint.gui.Visible = not complete and not reveal.Visible
		gui:SetAttribute("PromptVisible", card.Visible and reveal.Visible)
	end
	function api:success()
		Motion.stop(headingScale)
		if Motion.reduced() then
			headingScale.Scale = 1
			return
		end
		headingScale.Scale = 0.96
		Motion.tween(headingScale, 0.12, { Scale = 1.035 }).Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed and heading.Parent then
				Motion.tween(headingScale, 0.18, { Scale = 1 })
			end
		end)
	end
	function api:optional(on: boolean)
		optional = on
	end
	function api:training(hits: number)
		heading.Text = "TRAINING " .. math.min(hits, 3) .. "/3"
		if hits > lastTrainingHits then
			epoch = os.clock()
			self:success()
		end
		lastTrainingHits = hits
	end
	function api:complete()
		self:show("You're ready!", 4, true)
		self:success()
	end
	function api:destroy()
		Motion.stop(scale)
		Motion.stop(headingScale)
		card:Destroy()
	end
	return api
end

return Objective
