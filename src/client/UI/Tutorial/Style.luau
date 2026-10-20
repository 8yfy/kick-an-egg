--!strict
-- The approved menu proportions, borders, gradients, typography and interaction motion,
-- Native panels with one explicitly approved custom PNG for tutorial pointers.
local ContentProvider = game:GetService("ContentProvider")
local System = script.Parent.Parent.System
local Ui = require(System.Ui)
local Theme = require(System.Theme)
local Motion = require(System.Motion)
local Assets = require(script.Parent.Assets)
local Style = {}
Style.RED = Theme.Colors.danger

function Style.surface(parent: Instance, name: string): Frame
	local panel = Ui.frame(parent, name)
	panel.BackgroundColor3, panel.BackgroundTransparency = Theme.Colors.body, 0
	Ui.corner(panel)
	Ui.stroke(panel, 4)
	return panel
end

function Style.header(parent: Instance, title: string, height: number, size: number)
	local header = Ui.frame(parent, "Header", UDim2.new(1, 0, 0, height))
	header.ClipsDescendants = true
	Ui.corner(header)
	Ui.fill(header, Theme.Buttons.red)
	Ui.strips(header)
	local row = Ui.frame(header, "TitleRow", UDim2.new(1, -32, 1, 0), UDim2.fromOffset(16, 0))
	row.ZIndex = 3
	local label = Ui.text(row, title, size, { name = "Heading", stroke = 2 })
	label.Size, label.ZIndex = UDim2.fromScale(1, 1), 3
	return { gui = header, title = label }
end

function Style.button(parent: Instance, options: Ui.ButtonOpts)
	local button = Instance.new("TextButton")
	button.Name, button.Text = options.name or options.text, ""
	button.AutoButtonColor, button.BorderSizePixel, button.Size = false, 0, options.size
	Ui.corner(button)
	Ui.fill(button, Theme.Buttons.red)
	Ui.stroke(button, 3)
	local top = Ui.frame(button, "Highlight", UDim2.new(1, -8, 0.38, -4), UDim2.fromOffset(4, 4))
	top.BackgroundColor3, top.BackgroundTransparency = Color3.new(1, 1, 1), 0.78
	Ui.corner(top, 5)
	local label = Ui.text(button, options.text, options.textSize or 22, {
		name = "Label",
		align = Enum.TextXAlignment.Center,
		stroke = 3,
	})
	label.Size, label.ZIndex = UDim2.fromScale(1, 1), 2
	Motion.interactive(button)
	button.Activated:Connect(options.onClick)
	button.Parent = parent
	return {
		gui = button,
		label = label,
		setText = function(value: string)
			label.Text = value
		end,
	}
end

-- The same outlined red arrow is reused above controls, world targets and at screen edges.
function Style.arrow(parent: Instance, name: string, z: number): ImageLabel
	local arrow = Instance.new("ImageLabel")
	arrow.Name, arrow.BackgroundTransparency = name, 1
	arrow.Image, arrow.ScaleType = Assets.FocusArrow, Enum.ScaleType.Fit
	arrow.Size = UDim2.fromOffset(64, 64)
	arrow.AnchorPoint, arrow.Active, arrow.ZIndex = Vector2.new(0.5, 0.5), false, z
	arrow.Parent = parent
	return arrow
end

local preloaded = false
function Style.preload()
	if not preloaded then
		preloaded = true
		task.spawn(function()
			pcall(ContentProvider.PreloadAsync, ContentProvider, { Assets.FocusArrow })
		end)
	end
end

return Style
