--!strict
-- The approved menu shell/buttons at tutorial scale; progression remains owned by the controller.
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local System = script.Parent.Parent.System
local Motion = require(System.Motion)
local Theme = require(System.Theme)
local Ui = require(System.Ui)
local Welcome = {}
local C, L, M = Theme.Colors, Theme.Layout, Theme.Motion

function Welcome.new(gui: ScreenGui, begin: () -> (), skip: () -> ())
	local root = Ui.frame(gui, "Welcome")
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Visible = false
	root.ZIndex = 70
	local shadow = Ui.frame(root, "Shadow", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 6))
	shadow.BackgroundColor3, shadow.BackgroundTransparency = C.border, 0.35
	Ui.corner(shadow, L.radius + 2)
	local panel = Ui.surface(root, "Panel", C.body, Theme.Studs.body, L.border)
	panel.Size = UDim2.fromScale(1, 1)
	panel.ZIndex = 1
	local header = Ui.header(panel, Theme.Headers.confirm, "Tutorial", "hud_eggs", 64, 32)
	local divider = Ui.frame(panel, "HeaderEdge", UDim2.new(1, 0, 0, 4), UDim2.fromOffset(0, 62))
	divider.BackgroundColor3, divider.BackgroundTransparency = C.border, 0
	divider.ZIndex = 4

	local title = Ui.text(panel, "Welcome to kick the egg!", 28, {
		name = "Title",
		align = Enum.TextXAlignment.Center,
		stroke = 2,
	})
	title.TextTruncate = Enum.TextTruncate.None
	title.TextWrapped = true
	title.Position, title.Size = UDim2.fromOffset(20, 78), UDim2.new(1, -40, 0, 56)
	title.ZIndex = 2
	local message = Ui.text(panel, "Press to continue with the tutorial!", 20, {
		name = "Message",
		align = Enum.TextXAlignment.Center,
		color = C.muted,
		stroke = 2,
	})
	message.TextTruncate = Enum.TextTruncate.None
	message.TextWrapped = true
	message.Position, message.Size = UDim2.fromOffset(20, 138), UDim2.new(1, -40, 0, 44)
	message.ZIndex = 2
	local actions = Ui.frame(panel, "Actions", UDim2.new(1, -40, 0, 52), UDim2.fromOffset(20, 208))
	actions.ZIndex = 3
	local continueButton = Ui.button(actions, {
		name = "Continue",
		text = "CONTINUE",
		style = "lime",
		size = UDim2.new(0.62, -6, 1, 0),
		textSize = 24,
		onClick = begin,
	})
	local skipButton = Ui.button(actions, {
		name = "Skip",
		text = "SKIP",
		style = "grey",
		size = UDim2.new(0.38, -6, 1, 0),
		textSize = 20,
		onClick = skip,
	})
	skipButton.gui.AnchorPoint, skipButton.gui.Position = Vector2.new(1, 0), UDim2.fromScale(1, 0)
	local previousSelection: GuiObject? = nil
	local scale = Motion.scaleOf(root)
	local api = {}
	function api:show(on: boolean)
		if on == root.Visible then
			return
		end
		Motion.stop(scale)
		root.Visible = on
		if on then
			if Motion.reduced() then
				scale.Scale = 1
			else
				scale.Scale = 0.9
				Motion.tween(scale, M.open * 0.65, { Scale = 1.025 }, Enum.EasingStyle.Quad).Completed
					:Once(function(state)
						if state == Enum.PlaybackState.Completed and root.Visible then
							Motion.tween(scale, M.open * 0.35, { Scale = 1 })
						end
					end)
			end
			if UserInputService:GetLastInputType().Name:match("^Gamepad") then
				previousSelection = GuiService.SelectedObject
				GuiService.SelectedObject = continueButton.gui
			end
		else
			scale.Scale = 1
			if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(root) then
				GuiService.SelectedObject = if previousSelection and previousSelection.Parent
					then previousSelection
					else nil
			end
		end
	end
	function api:layout()
		local width = math.min(520, gui.AbsoluteSize.X - 28)
		local narrow = width < 380
		root.Size = UDim2.fromOffset(width, 280)
		header.title.TextSize = if narrow then 26 else 32
		title.TextSize = if narrow then 22 else 28
		message.TextSize = if narrow then L.minText else 20
		continueButton.label.TextSize = if narrow then 20 else 24
		skipButton.label.TextSize = if narrow then L.minText else 20
	end
	function api:destroy()
		self:show(false)
		root:Destroy()
	end
	return api
end

return Welcome
