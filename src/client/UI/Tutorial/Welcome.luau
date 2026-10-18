--!strict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Motion = require(script.Parent.Parent.System.Motion)
local Welcome = {}
local INK = Color3.fromRGB(29, 16, 48)

function Welcome.new(gui: ScreenGui, begin: () -> (), skip: () -> ())
	local panel = Instance.new("Frame")
	panel.Name = "Welcome"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(255, 195, 47)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 70
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness = INK, 4
	stroke.Parent = panel
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 231, 117), Color3.fromRGB(255, 171, 34))
	gradient.Rotation = 90
	gradient.Parent = panel
	local function label(name: string, value: string, y: number, height: number, size: number): TextLabel
		local text = Instance.new("TextLabel")
		text.Name, text.Text = name, value
		text.Font, text.TextColor3, text.TextSize = Enum.Font.FredokaOne, INK, size
		text.BackgroundTransparency = 1
		text.TextWrapped = true
		text.Position = UDim2.fromOffset(24, y)
		text.Size = UDim2.new(1, -48, 0, height)
		text.ZIndex = 71
		text.Parent = panel
		return text
	end
	local title = label("Title", "Welcome to kick the egg!", 16, 60, 26)
	local message = label("Message", "Press to continue with the tutorial!", 80, 44, 18)
	local function button(name: string, value: string, y: number, action: () -> ()): TextButton
		local b = Instance.new("TextButton")
		b.Name, b.Text = name, value
		b.Font, b.TextColor3, b.TextSize = Enum.Font.FredokaOne, INK, 19
		b.AnchorPoint = Vector2.new(0.5, 0)
		b.Position = UDim2.new(0.5, 0, 0, y)
		b.Size = UDim2.new(1, -64, 0, 48)
		b.BackgroundColor3 = Color3.fromRGB(255, 247, 196)
		b.BorderSizePixel = 0
		b.ZIndex = 72
		b.Parent = panel
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 12)
		cr.Parent = b
		b.Activated:Connect(action)
		return b
	end
	local continueButton = button("Continue", "CONTINUE", 138, begin)
	local skipButton = button("Skip", "SKIP TUTORIAL", 190, skip)
	skipButton.BackgroundTransparency, skipButton.TextSize = 1, 13
	local previousSelection: GuiObject? = nil
	local api = {}
	function api:show(on: boolean)
		if on == panel.Visible then
			return
		end
		panel.Visible = on
		if on then
			Motion.popIn(panel)
			if UserInputService:GetLastInputType().Name:match("^Gamepad") then
				previousSelection = GuiService.SelectedObject
				GuiService.SelectedObject = continueButton
			end
		elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(panel) then
			GuiService.SelectedObject = if previousSelection and previousSelection.Parent
				then previousSelection
				else nil
		end
	end
	function api:layout()
		local width = math.min(420, gui.AbsoluteSize.X - 28)
		panel.Size = UDim2.fromOffset(width, 242)
		title.TextSize = if width < 340 then 22 else 26
		message.TextSize = if width < 340 then 16 else 18
	end
	function api:destroy()
		self:show(false)
		panel:Destroy()
	end
	return api
end

return Welcome
