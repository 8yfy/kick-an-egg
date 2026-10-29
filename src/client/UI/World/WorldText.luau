--!strict
-- Building blocks for world-space displays (egg timers, the hatch prompt, pet nameplates) in the approved HUD
-- style (UI/System/Theme): Fredoka One, white text with a near-black outline, rarity / cash gradients, rounded
-- dark panels with a thick border. Text scales with its box (the boxes are sized in studs, so it reads the same at
-- any distance until the display's MaxDistance hides it).
local Theme = require(script.Parent.Parent.System.Theme)

local C = Theme.Colors
local WorldText = {}

export type Pair = Theme.Pair

-- A scaled, outlined text label. `pair` puts a top -> bottom gradient on the text.
function WorldText.label(parent: Instance, name: string, text: string, pair: Pair?, maxSize: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.Font = Theme.Font
	l.Text = text
	l.TextScaled = true
	l.TextColor3 = if pair then Color3.new(1, 1, 1) else C.text
	l.Size = UDim2.fromScale(1, 1)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize or 64
	limit.MinTextSize = 6
	limit.Parent = l
	local stroke = Instance.new("UIStroke")
	stroke.Color = C.border
	stroke.Thickness = 2.5
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = l
	if pair then
		local g = Instance.new("UIGradient")
		g.Name = "Fill"
		g.Rotation = 90
		g.Color = ColorSequence.new(pair[1], pair[2])
		g.Parent = l
	end
	l.Parent = parent
	return l
end

function WorldText.setGradient(label: TextLabel, pair: Pair)
	local g = label:FindFirstChild("Fill")
	if g and g:IsA("UIGradient") then
		g.Color = ColorSequence.new(pair[1], pair[2])
	end
end

-- The rarity's text gradient (light top -> its colour).
function WorldText.rarityPair(rarity: string?): Pair
	local text = Theme.RarityText[rarity or "Common"] or C.text
	return { text:Lerp(Color3.new(1, 1, 1), 0.55), text }
end

-- A small round clock face with two hands; returns the face and its minute hand (spin it to tick).
function WorldText.clock(parent: Instance, name: string): (Frame, Frame)
	local face = Instance.new("Frame")
	face.Name = name
	face.BackgroundColor3 = Color3.new(1, 1, 1)
	face.Size = UDim2.fromScale(1, 1)
	face.SizeConstraint = Enum.SizeConstraint.RelativeYY
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = face
	local ring = Instance.new("UIStroke")
	ring.Color = C.border
	ring.Thickness = 2.5
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.Parent = face
	local function hand(handName: string, length: number, width: number, rotation: number): Frame
		local pivot = Instance.new("Frame")
		pivot.Name = handName
		pivot.BackgroundTransparency = 1
		pivot.AnchorPoint = Vector2.new(0.5, 0.5)
		pivot.Position = UDim2.fromScale(0.5, 0.5)
		pivot.Size = UDim2.fromScale(1, 1)
		pivot.Rotation = rotation
		local bar = Instance.new("Frame")
		bar.BackgroundColor3 = C.border
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0.5, 1)
		bar.Position = UDim2.fromScale(0.5, 0.5)
		bar.Size = UDim2.fromScale(width, length)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.5, 0)
		c.Parent = bar
		bar.Parent = pivot
		pivot.Parent = face
		return pivot
	end
	hand("Hour", 0.26, 0.12, 60)
	local minute = hand("Minute", 0.36, 0.09, 0)
	local dot = Instance.new("Frame")
	dot.BackgroundColor3 = C.border
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromScale(0.16, 0.16)
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0.5, 0)
	dc.Parent = dot
	dot.Parent = face
	face.Parent = parent
	return face, minute
end

-- A rounded progress bar (dark track, gradient fill); returns the track and its fill (Size.X.Scale = progress).
function WorldText.bar(parent: Instance, name: string, pair: Pair): (Frame, Frame)
	local track = Instance.new("Frame")
	track.Name = name
	track.BackgroundColor3 = C.card
	track.BackgroundTransparency = 0.15
	track.BorderSizePixel = 0
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0.5, 0)
	tc.Parent = track
	local ts = Instance.new("UIStroke")
	ts.Color = C.border
	ts.Thickness = 2
	ts.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ts.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.new(1, 1, 1)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0.5, 0)
	fc.Parent = fill
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(pair[1], pair[2])
	g.Parent = fill
	fill.Parent = track
	track.Parent = parent
	return track, fill
end

-- A dark rounded panel with the thick HUD border.
function WorldText.panel(parent: Instance, name: string): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = C.card
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Color = C.border
	s.Thickness = 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = f
	f.Parent = parent
	return f
end

WorldText.CASH = { Color3.fromHex("C8FF4A"), Color3.fromHex("3FD81A") } -- the Cash counter's gradient
WorldText.READY = { Color3.fromHex("D8FF5A"), Color3.fromHex("FFC21A") } -- green into gold
WorldText.LIME = Theme.Buttons.lime

return WorldText
