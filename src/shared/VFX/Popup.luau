--!strict
-- Partner A. Big bouncy screen banners ("RUN!", "LOST!", "SECURED!") and the red edge vignette.
-- Self-contained (no client UI dependency) because VFX lives in Shared.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Popup = {}

local FONT = Enum.Font.FredokaOne

-- Banners draw above the HUD; the vignette draws below it so the HUD stays readable.
local function screen(name: string?, order: number?): ScreenGui?
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil
	end
	local guiName = name or "VFXScreen"
	local existing = pg:FindFirstChild(guiName)
	if existing and existing:IsA("ScreenGui") then
		return existing
	end
	local g = Instance.new("ScreenGui")
	g.Name = guiName
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = order or 5
	g.Parent = pg
	return g
end

local function tween(
	obj: Instance,
	seconds: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
)
	TweenService
		:Create(obj, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
		:Play()
end

-- Banner drops in from above with a bounce, holds, then shrinks away.
-- colors = { top, bottom } gradient of the text.
function Popup.banner(text: string, colors: { Color3 }, hold: number?)
	local g = screen()
	if not g then
		return
	end
	local label = Instance.new("TextLabel")
	label.Name = "Banner"
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, -0.2)
	label.Size = UDim2.fromScale(0.6, 0.2)
	label.BackgroundTransparency = 1
	label.Font = FONT
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Rotation = -4
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(colors[1], colors[2])
	grad.Parent = label
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 6
	stroke.Color = Color3.fromRGB(25, 20, 30)
	stroke.Parent = label
	local sizer = Instance.new("UITextSizeConstraint")
	sizer.MaxTextSize = 140
	sizer.Parent = label
	local scale = Instance.new("UIScale")
	scale.Parent = label
	label.Parent = g

	tween(label, 0.55, { Position = UDim2.fromScale(0.5, 0.38) }, Enum.EasingStyle.Bounce)
	tween(label, 0.55, { Rotation = 3 }, Enum.EasingStyle.Back)
	task.delay(hold or 1.3, function()
		tween(scale, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.3)
		label:Destroy()
	end)
end

-- Announcement toast: a rarity-coloured pill slides down under the quest bar, holds, slides away.
function Popup.toast(text: string, color: Color3, rainbow: boolean?)
	local g = screen()
	if not g then
		return
	end
	local pill = Instance.new("Frame")
	pill.Name = "Toast"
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.fromScale(0.5, -0.12)
	pill.Size = UDim2.fromScale(0.5, 0.07)
	pill.BackgroundColor3 = Color3.new(1, 1, 1)
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color:Lerp(Color3.new(0, 0, 0), 0.25))
	grad.Parent = pill
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = pill
	local border = Instance.new("UIStroke")
	border.Thickness = 3
	border.Color = Color3.fromRGB(25, 20, 30)
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = pill
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0.04, 0.12)
	label.Size = UDim2.fromScale(0.92, 0.76)
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(25, 20, 30)
	stroke.Parent = label
	label.Parent = pill
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 9
	ratio.Parent = pill
	pill.Parent = g

	tween(pill, 0.45, { Position = UDim2.fromScale(0.5, 0.24) }, Enum.EasingStyle.Back)
	local alive = true
	if rainbow then
		task.spawn(function()
			while alive do
				local h = (os.clock() * 0.4) % 1
				grad.Color = ColorSequence.new(Color3.fromHSV(h, 0.55, 1), Color3.fromHSV((h + 0.25) % 1, 0.75, 0.9))
				task.wait()
			end
		end)
	end
	task.delay(3, function()
		tween(pill, 0.35, { Position = UDim2.fromScale(0.5, -0.12) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.4)
		alive = false
		pill:Destroy()
	end)
end

-- Red pulsing screen-edge vignette. Returns a stop function (fades out).
function Popup.vignette(color: Color3): () -> ()
	local g = screen("VFXVignette", -1)
	if not g then
		return function() end
	end
	local frame = Instance.new("Frame")
	frame.Name = "Vignette"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	local edges = {}
	-- Four gradient edges fading toward the centre.
	for i, spec in
		{
			{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), 270 },
			{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.16, 1), UDim2.fromScale(0.84, 0), 180 },
		}
	do
		local e = Instance.new("Frame")
		e.Name = "Edge" .. i
		e.Size = spec[1]
		e.Position = spec[2]
		e.BorderSizePixel = 0
		e.BackgroundColor3 = color
		e.BackgroundTransparency = 0.5
		local grad = Instance.new("UIGradient")
		grad.Rotation = spec[3]
		grad.Transparency = NumberSequence.new(0, 1)
		grad.Parent = e
		e.Parent = frame
		table.insert(edges, e)
	end
	frame.Parent = g

	local alive = true
	task.spawn(function()
		while alive do
			for _, e in edges do
				tween(e, 0.35, { BackgroundTransparency = 0.3 }, Enum.EasingStyle.Sine)
			end
			task.wait(0.35)
			for _, e in edges do
				tween(e, 0.35, { BackgroundTransparency = 0.7 }, Enum.EasingStyle.Sine)
			end
			task.wait(0.35)
		end
	end)
	return function()
		alive = false
		for _, e in edges do
			tween(e, 0.4, { BackgroundTransparency = 1 })
		end
		task.delay(0.45, function()
			frame:Destroy()
		end)
	end
end

return Popup
