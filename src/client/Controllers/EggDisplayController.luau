--!strict
-- Placed eggs (PlotService models in Base<i>.Plots, Kind = "Egg"), for every egg this client sees:
--   * GROWTH: the egg grows while it incubates, to a final size set by its size mutation (Presentation/EggSize).
--     Progress comes from the saved PlacedAt / HatchAt and synced server time, so rejoining shows the right size;
--     the scale is always set from the egg's own base scale (never compounded) around its ground pivot.
--   * DISPLAY: the future pet's name in its rarity colour, a countdown with a small clock and a thin progress bar,
--     floating just above the egg's current top. When the timer ends it turns into READY TO HATCH! (a check, a
--     green-gold gradient, a small sparkle and glow). Nothing hatches by itself.
--   * HOLD TO HATCH: your own READY egg gets a hold-E prompt (custom UI: the E key, your gamepad's button, or a
--     button you hold on touch screens) with a filling bar. Releasing early empties it; finishing it asks the
--     server (HatchCinematicController.request), which checks everything before anything hatches.
-- One Heartbeat loop for every egg: scales only when the size really changes, texts only when the second changes.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EggSize = require(Shared.Presentation.EggSize)
local Format = require(Shared.Presentation.Format)
local Burst = require(Shared.VFX.Burst)
local Audio = require(Shared.Audio)

local UI = script.Parent.Parent:WaitForChild("UI")
local WorldText = require(UI:WaitForChild("World"):WaitForChild("WorldText"))
local AssetIds = require(UI:WaitForChild("System"):WaitForChild("AssetIds"))
local HatchCinematicController = require(script.Parent.HatchCinematicController)

local EggDisplayController = {}

local HOLD_SECONDS = 1 -- hold E this long to hatch (tune after playtests: 0.8 - 1.2)
local GROW_RANGE = 170 -- studs: eggs further away keep their last size until you come closer
local OWN_DISTANCE, OTHER_DISTANCE = 75, 45 -- the display hides beyond this
-- Display width in studs (height follows): narrow enough that eggs at the minimum spacing (4 studs) barely overlap,
-- a little wider over bigger eggs (which are spaced further apart).
local DISPLAY_WIDTH = 5
local PROMPT_REACH = 8 -- + the egg's footprint radius (the server allows 12 + radius)

local player = Players.LocalPlayer

type View = {
	model: Model,
	root: BasePart,
	base: number, -- the model's own scale when it arrived
	top: number, -- egg top above the root's centre at base scale (studs)
	size: string?,
	applied: number,
	own: boolean,
	gui: BillboardGui,
	timer: TextLabel,
	icon: Frame,
	hand: Frame,
	check: ImageLabel,
	track: Frame,
	fill: Frame,
	pop: UIScale,
	text: string,
	ready: boolean,
	prompt: ProximityPrompt?,
	glow: PointLight?,
}

local views: { [Model]: View } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function times(model: Model): (number?, number?)
	local placedAt, hatchAt = model:GetAttribute("PlacedAt"), model:GetAttribute("HatchAt")
	if typeof(placedAt) == "number" and typeof(hatchAt) == "number" then
		return placedAt, hatchAt
	end
	return nil, nil
end

local function isReady(model: Model): boolean
	local _, hatchAt = times(model)
	return model:GetAttribute("Ready") == true or (hatchAt ~= nil and now() >= hatchAt)
end
EggDisplayController.isReady = isReady

local function reducedMotion(): boolean
	return player:GetAttribute("ReducedMotion") == true
end

-- Display ------------------------------------------------------------------------------------------------------

local function buildDisplay(model: Model, root: BasePart, own: boolean): (BillboardGui, { [string]: Instance })
	local gui = Instance.new("BillboardGui")
	gui.Name = "EggDisplay"
	gui.Adornee = root
	local sizeKey = model:GetAttribute("Size")
	local width = DISPLAY_WIDTH
		* math.max(1, 0.55 + 0.45 * EggSize.visual(if typeof(sizeKey) == "string" then sizeKey else nil))
	gui.Size = UDim2.new(width, 0, width * 0.34, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = if own then OWN_DISTANCE else OTHER_DISTANCE
	gui.ResetOnSpawn = false
	gui.ClipsDescendants = false
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = gui
	local pop = Instance.new("UIScale")
	pop.Parent = holder
	local name = model:GetAttribute("PetName")
	local rarity = model:GetAttribute("Rarity")
	local nameBox = Instance.new("Frame")
	nameBox.Name = "NameBox"
	nameBox.BackgroundTransparency = 1
	nameBox.Size = UDim2.fromScale(1, 0.44)
	nameBox.Parent = holder
	WorldText.label(
		nameBox,
		"PetName",
		string.upper(if typeof(name) == "string" then name else "Mystery"),
		WorldText.rarityPair(if typeof(rarity) == "string" then rarity else nil),
		40
	)
	local row = Instance.new("Frame")
	row.Name = "TimerRow"
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromScale(0, 0.46)
	row.Size = UDim2.fromScale(1, 0.36)
	row.Parent = holder
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0.02, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row
	local iconBox = Instance.new("Frame")
	iconBox.Name = "Icon"
	iconBox.BackgroundTransparency = 1
	iconBox.Size = UDim2.fromScale(0.84, 0.84)
	iconBox.SizeConstraint = Enum.SizeConstraint.RelativeYY
	iconBox.LayoutOrder = 1
	iconBox.Parent = row
	local face, hand = WorldText.clock(iconBox, "Clock")
	local check = Instance.new("ImageLabel")
	check.Name = "Check"
	check.BackgroundTransparency = 1
	check.Size = UDim2.fromScale(1.15, 1.15)
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.Position = UDim2.fromScale(0.5, 0.5)
	check.Image = AssetIds.get("icon_check") or ""
	check.Visible = false
	check.Parent = iconBox
	local timerBox = Instance.new("Frame")
	timerBox.Name = "TimerBox"
	timerBox.BackgroundTransparency = 1
	timerBox.Size = UDim2.fromScale(0.62, 1)
	timerBox.AutomaticSize = Enum.AutomaticSize.None
	timerBox.LayoutOrder = 2
	timerBox.Parent = row
	local timer = WorldText.label(timerBox, "Timer", "", nil, 34)
	timer.TextXAlignment = Enum.TextXAlignment.Left
	local track, fill =
		WorldText.bar(holder, "Progress", WorldText.rarityPair(if typeof(rarity) == "string" then rarity else nil))
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.fromScale(0.5, 0.86)
	track.Size = UDim2.fromScale(0.5, 0.1)
	gui.Parent = root
	return gui, { timer = timer, icon = face, hand = hand, check = check, track = track, fill = fill, pop = pop }
end

-- Just above the egg's real top right now (measured after every size change, so it follows the growth).
local function placeDisplay(view: View)
	local cf, size = view.model:GetBoundingBox()
	view.top = (cf.Position.Y + size.Y / 2) - view.root.Position.Y
	view.gui.StudsOffsetWorldSpace = Vector3.new(0, view.top + view.gui.Size.Y.Scale / 2 + 0.2, 0)
end

local function setReady(view: View, animate: boolean)
	if view.ready then
		return
	end
	view.ready = true
	view.text = "READY TO HATCH!"
	view.timer.Text = view.text
	WorldText.setGradient(view.timer, WorldText.READY)
	local fill = view.timer:FindFirstChild("Fill")
	if not fill then
		local g = Instance.new("UIGradient")
		g.Name = "Fill"
		g.Rotation = 90
		g.Color = ColorSequence.new(WorldText.READY[1], WorldText.READY[2])
		g.Parent = view.timer
		view.timer.TextColor3 = Color3.new(1, 1, 1)
	end
	local timerBox = view.timer.Parent :: Frame
	timerBox.Size = UDim2.fromScale(0.86, 1)
	view.icon.Visible = false
	view.check.Visible = view.check.Image ~= ""
	view.fill.Size = UDim2.fromScale(1, 1)
	local g = view.fill:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = ColorSequence.new(WorldText.READY[1], WorldText.READY[2])
	end
	if animate then
		TweenService:Create(view.track, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(view.fill, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		if not reducedMotion() then
			view.pop.Scale = 0.85
			TweenService:Create(view.pop, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
		end
		local top = view.root.Position + Vector3.new(0, view.top, 0)
		Burst.play(top, if player:GetAttribute("LowDetail") == true then 5 else 10, {
			WorldText.READY[1],
			WorldText.READY[2],
			Color3.new(1, 1, 1),
		}, NumberRange.new(0.15, 0.35), 12, 0.8, false, true)
		if view.own then
			Audio.play("UISuccess", view.root)
		end
	else
		view.track.Visible = false
	end
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 225, 110)
	glow.Range = 8 * view.applied
	glow.Brightness = 0
	glow.Parent = view.root
	TweenService:Create(glow, TweenInfo.new(0.8), { Brightness = 0.9 }):Play()
	view.glow = glow
end

-- Hold to hatch ------------------------------------------------------------------------------------------------

local function makePrompt(view: View)
	if view.prompt then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "HatchPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Hold to hatch"
	local name = view.model:GetAttribute("PetName")
	prompt.ObjectText = if typeof(name) == "string" then name else "Egg"
	prompt.HoldDuration = HOLD_SECONDS
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = PROMPT_REACH + EggSize.radius(view.size)
	prompt:SetAttribute("KTEHatch", true)
	prompt.Triggered:Connect(function()
		prompt.Enabled = false
		HatchCinematicController.request(view.model)
	end)
	prompt.Parent = view.root
	view.prompt = prompt
end

-- The custom prompt UI (one at a time: the egg you're nearest to).
local function showPromptUi(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local root = prompt.Parent
	if not root or not root:IsA("BasePart") then
		return
	end
	local screen = player:WaitForChild("PlayerGui"):FindFirstChild("HatchPromptUi")
	if not screen then
		local s = Instance.new("ScreenGui")
		s.Name = "HatchPromptUi"
		s.ResetOnSpawn = false
		s.Parent = player.PlayerGui
		screen = s
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "HatchPrompt"
	gui.Adornee = root
	gui.AlwaysOnTop = true
	gui.Active = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(250, 72)
	-- beside the egg at half its height (camera space): the panel's left edge sits just outside the shell at any
	-- distance (SizeOffset shifts it by half its own width), so it never covers the egg
	local model = root.Parent
	local view = if model and model:IsA("Model") then views[model] else nil
	local sizeKey = if model then model:GetAttribute("Size") else nil
	local radius = EggSize.BASE_RADIUS * EggSize.visual(if typeof(sizeKey) == "string" then sizeKey else nil) * 0.9
	gui.StudsOffset = Vector3.new(radius + 0.4, if view then view.top * 0.5 else 2, 0)
	gui.SizeOffset = Vector2.new(0.5, 0)
	local panel = WorldText.panel(gui, "Panel")
	local scale = Instance.new("UIScale")
	scale.Scale = 0.6
	scale.Parent = panel
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()
	-- the key: E on a keyboard, your controller's own button image, or HOLD on touch screens
	local key = Instance.new("Frame")
	key.Name = "Key"
	key.BackgroundColor3 = Color3.new(1, 1, 1)
	key.Position = UDim2.fromOffset(10, 10)
	key.Size = UDim2.fromOffset(52, 52)
	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(0, 10)
	kc.Parent = key
	local ks = Instance.new("UIStroke")
	ks.Color = Color3.fromHex("080A10")
	ks.Thickness = 3
	ks.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ks.Parent = key
	local keyScale = Instance.new("UIScale")
	keyScale.Parent = key
	key.Parent = panel
	if inputType == Enum.ProximityPromptInputType.Gamepad then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(0.9, 0.9)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.Image = UserInputService:GetImageForKeyCode(prompt.GamepadKeyCode)
		img.Parent = key
		key.BackgroundTransparency = 1
		ks.Enabled = false
	else
		local glyph = Instance.new("TextLabel")
		glyph.BackgroundTransparency = 1
		glyph.Size = UDim2.fromScale(1, 1)
		glyph.Font = Enum.Font.FredokaOne
		glyph.TextScaled = true
		glyph.TextColor3 = Color3.fromHex("171B26")
		glyph.Text = if inputType == Enum.ProximityPromptInputType.Touch
			then "HOLD"
			else UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
		local pad = Instance.new("UIPadding")
		local inset = if inputType == Enum.ProximityPromptInputType.Touch then 0.14 else 0.18
		pad.PaddingTop, pad.PaddingBottom = UDim.new(inset, 0), UDim.new(inset, 0)
		pad.PaddingLeft, pad.PaddingRight = UDim.new(0.12, 0), UDim.new(0.12, 0)
		pad.Parent = glyph
		glyph.Parent = key
	end
	local title = Instance.new("Frame")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(72, 8)
	title.Size = UDim2.new(1, -82, 0, 30)
	title.Parent = panel
	WorldText.label(title, "Title", "HOLD TO HATCH", nil, 26).TextXAlignment = Enum.TextXAlignment.Left
	local track, fill = WorldText.bar(panel, "Hold", WorldText.LIME)
	track.Position = UDim2.fromOffset(72, 44)
	track.Size = UDim2.new(1, -86, 0, 14)
	gui.Parent = screen

	local holding: Tween? = nil
	local function fillTo(target: number, seconds: number, style: Enum.EasingStyle)
		if holding then
			holding:Cancel()
		end
		local t = TweenService:Create(fill, TweenInfo.new(seconds, style, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(target, 1),
		})
		holding = t
		t:Play()
	end
	local conns: { RBXScriptConnection } = {}
	table.insert(
		conns,
		prompt.PromptButtonHoldBegan:Connect(function()
			fillTo(1, prompt.HoldDuration * (1 - fill.Size.X.Scale), Enum.EasingStyle.Linear)
			TweenService:Create(keyScale, TweenInfo.new(0.1), { Scale = 0.88 }):Play()
		end)
	)
	table.insert(
		conns,
		prompt.PromptButtonHoldEnded:Connect(function()
			fillTo(0, 0.2, Enum.EasingStyle.Quad) -- let go early: it empties smoothly
			TweenService:Create(keyScale, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
	)
	table.insert(
		conns,
		prompt.Triggered:Connect(function()
			fillTo(1, 0.05, Enum.EasingStyle.Linear)
			TweenService:Create(panel, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromHex("2F4A1C") }):Play()
		end)
	)
	-- touch / mouse: hold the panel itself
	local button = Instance.new("TextButton")
	button.Name = "Hold"
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Size = UDim2.fromScale(1, 1)
	button.ZIndex = 5
	button.Parent = panel
	table.insert(
		conns,
		button.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				prompt:InputHoldBegin()
			end
		end)
	)
	table.insert(
		conns,
		button.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				prompt:InputHoldEnd()
			end
		end)
	)
	local hiddenConn: RBXScriptConnection
	hiddenConn = prompt.PromptHidden:Connect(function()
		hiddenConn:Disconnect()
		for _, c in conns do
			c:Disconnect()
		end
		TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 0.6 }):Play()
		task.delay(0.13, function()
			gui:Destroy()
		end)
	end)
end

-- Tracking -----------------------------------------------------------------------------------------------------

local function track(model: Model)
	if views[model] or model:GetAttribute("Kind") ~= "Egg" then
		return
	end
	local root = model.PrimaryPart
	if not root then
		return
	end
	local base = model:GetScale()
	local cf, size = model:GetBoundingBox()
	local top = (cf.Position.Y + size.Y / 2) - root.Position.Y
	local own = model:GetAttribute("OwnerUserId") == player.UserId
	local gui, parts = buildDisplay(model, root, own)
	local sizeKey = model:GetAttribute("Size")
	local view: View = {
		model = model,
		root = root,
		base = base,
		top = top,
		size = if typeof(sizeKey) == "string" then sizeKey else nil,
		applied = 1,
		own = own,
		gui = gui,
		timer = parts.timer :: TextLabel,
		icon = parts.icon :: Frame,
		hand = parts.hand :: Frame,
		check = parts.check :: ImageLabel,
		track = parts.track :: Frame,
		fill = parts.fill :: Frame,
		pop = parts.pop :: UIScale,
		text = "",
		ready = false,
		prompt = nil,
		glow = nil,
	}
	views[model] = view
	placeDisplay(view)
	if isReady(model) then
		setReady(view, false)
	end
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			views[model] = nil
			gui:Destroy()
		end
	end)
end

local function step()
	local t = now()
	local cam = workspace.CurrentCamera
	local camPos = if cam then cam.CFrame.Position else Vector3.zero
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local herePos = if hrp and hrp:IsA("BasePart") then hrp.Position else camPos
	for model, view in views do
		if not model.Parent then
			continue
		end
		local placedAt, hatchAt = times(model)
		if not placedAt or not hatchAt then
			continue
		end
		local near = (view.root.Position - camPos).Magnitude < GROW_RANGE
			or (view.root.Position - herePos).Magnitude < GROW_RANGE
		-- growth from the saved timestamps (rejoin = the right size), applied from the base scale (no compounding)
		local target = EggSize.placed(view.size, EggSize.progress(placedAt, hatchAt, t))
		if near and math.abs(target - view.applied) / view.applied > 0.003 then
			model:ScaleTo(view.base * target)
			view.applied = target
			placeDisplay(view)
			if view.glow then
				view.glow.Range = 8 * target
			end
		end
		-- countdown (texts only change once a second)
		if not view.ready then
			if t >= hatchAt or model:GetAttribute("Ready") == true then
				setReady(view, true)
			else
				local text = Format.clock(hatchAt - t)
				if text ~= view.text then
					view.text = text
					view.timer.Text = text
					view.hand.Rotation = (view.hand.Rotation + 30) % 360
				end
				view.fill.Size = UDim2.fromScale(EggSize.progress(placedAt, hatchAt, t), 1)
			end
		end
		-- your own READY egg: hold E (hidden while its hatch is being asked / shown)
		if view.own and view.ready then
			local uid = model:GetAttribute("EggUid")
			local busy = typeof(uid) == "string" and HatchCinematicController.busy(uid)
			if not view.prompt then
				makePrompt(view)
			end
			local prompt = view.prompt
			if prompt then
				prompt.Enabled = not busy
			end
			view.gui.Enabled = not busy -- (the egg's hatch show has taken over)
		end
	end
end

local function watchPlots(plots: Instance)
	for _, child in plots:GetChildren() do
		if child:IsA("Model") then
			task.defer(track, child)
		end
	end
	plots.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(track, child)
		end
	end)
end

function EggDisplayController:Start()
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt:GetAttribute("KTEHatch") == true then
			showPromptUi(prompt, inputType)
		end
	end)
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		local zone = map and map:WaitForChild("SafeZone", 30)
		local bases = zone and zone:WaitForChild("Bases", 30)
		if not bases then
			return
		end
		local function watchBase(base: Instance)
			task.spawn(function()
				local plots = base:WaitForChild("Plots", math.huge)
				if plots then
					watchPlots(plots)
				end
			end)
		end
		for _, base in bases:GetChildren() do
			watchBase(base)
		end
		bases.ChildAdded:Connect(watchBase)
	end)
	RunService.Heartbeat:Connect(step)
end

-- For tests / previews.
function EggDisplayController.viewOf(model: Model): { applied: number, ready: boolean, text: string }?
	local v = views[model]
	return v and { applied = v.applied, ready = v.ready, text = v.text }
end

return EggDisplayController
