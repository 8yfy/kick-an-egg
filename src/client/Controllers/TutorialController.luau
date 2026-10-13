--!strict
-- The show-don't-tell tutorial (client). TutorialService (server) decides the step from your real data and mirrors
-- it as LocalPlayer.TutorialStep; this only SHOWS it: one short banner, a bouncing arrow over the real target in
-- the world (kick pad, your pen, your egg, your pet, the Boxing Sack Shop) and a glow on the one button that
-- matters (KICK, the Eggs tile, the Power "+"). Nothing blocks input; a small SKIP button ends it.
-- Steps 2/3 (press KICK / time it) follow the kick meter; step 4 follows your flight and chase.
-- TutorialDone -> a short celebration once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Remotes = require(Shared.Remotes)

local TutorialController = {}

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 215, 70)
local INK = Color3.fromRGB(20, 24, 40)

local gui: ScreenGui
local banner: TextLabel
local sub: TextLabel
local skip: TextButton
local arrowPart: Part
local arrowGui: BillboardGui
local distLabel: TextLabel
local data: { [string]: any } = {}
local glowOn: GuiObject? = nil
local glowStroke: UIStroke? = nil
local inFlight, inChase = false, false

local function label(parent: Instance, name: string, size: UDim2, pos: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0)
	l.Size, l.Position = size, pos
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Active = false
	local s = Instance.new("UIStroke")
	s.Thickness = 4
	s.Color = INK
	s.Parent = l
	l.Parent = parent
	return l
end

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "Tutorial"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 8
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	banner = label(gui, "Banner", UDim2.fromOffset(640, 52), UDim2.new(0.5, 0, 0, 178), 40)
	banner.TextColor3 = GOLD
	sub = label(gui, "Sub", UDim2.fromOffset(640, 30), UDim2.new(0.5, 0, 0, 230), 24)
	skip = Instance.new("TextButton")
	skip.Name = "Skip"
	skip.AnchorPoint = Vector2.new(0.5, 0)
	skip.Position = UDim2.new(0.5, 0, 0, 266)
	skip.Size = UDim2.fromOffset(150, 30)
	skip.BackgroundColor3 = INK
	skip.BackgroundTransparency = 0.25
	skip.Font = Enum.Font.FredokaOne
	skip.TextScaled = true
	skip.TextColor3 = Color3.fromRGB(200, 205, 225)
	skip.Text = "SKIP TUTORIAL"
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = skip
	skip.Parent = gui
	skip.Activated:Connect(function()
		Remotes.get("SkipTutorial"):FireServer()
	end)
	gui.Parent = player:WaitForChild("PlayerGui")

	-- world arrow: a chunky gold arrow pointing down, bobbing over the target
	arrowPart = Instance.new("Part")
	arrowPart.Name = "TutorialArrow"
	arrowPart.Anchored, arrowPart.CanCollide, arrowPart.CanQuery, arrowPart.CanTouch = true, false, false, false
	arrowPart.Transparency = 1
	arrowPart.Size = Vector3.new(1, 1, 1)
	arrowPart.Parent = workspace
	arrowGui = Instance.new("BillboardGui")
	arrowGui.Name = "Arrow"
	arrowGui.Size = UDim2.fromOffset(90, 120)
	arrowGui.AlwaysOnTop = true
	arrowGui.LightInfluence = 0
	arrowGui.Adornee = arrowPart
	arrowGui.Parent = arrowPart
	local shaft = Instance.new("Frame")
	shaft.AnchorPoint = Vector2.new(0.5, 0)
	shaft.Position = UDim2.fromScale(0.5, 0.05)
	shaft.Size = UDim2.fromScale(0.34, 0.42)
	shaft.BackgroundColor3 = GOLD
	shaft.Parent = arrowGui
	local head = Instance.new("Frame")
	head.AnchorPoint = Vector2.new(0.5, 0.5)
	head.Position = UDim2.fromScale(0.5, 0.52)
	head.Size = UDim2.fromScale(0.62, 0.62)
	head.SizeConstraint = Enum.SizeConstraint.RelativeXX
	head.Rotation = 45
	head.BackgroundColor3 = GOLD
	head.ZIndex = 0
	head.Parent = arrowGui
	for _, f in { shaft, head } do
		local s = Instance.new("UIStroke")
		s.Thickness = 4
		s.Color = INK
		s.Parent = f
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, 6)
		cr.Parent = f
	end
	-- cover the head's top half so the arrow reads as one shape
	local cover = Instance.new("Frame")
	cover.AnchorPoint = Vector2.new(0.5, 1)
	cover.Position = UDim2.fromScale(0.5, 0.52)
	cover.Size = UDim2.fromScale(0.31, 0.12)
	cover.BackgroundColor3 = GOLD
	cover.BorderSizePixel = 0
	cover.ZIndex = 2
	cover.Parent = arrowGui
	distLabel = label(arrowGui :: any, "Distance", UDim2.fromScale(1.6, 0.22), UDim2.fromScale(0.5, 0.86), 20)
	arrowGui.Enabled = false
end

local function setGlow(target: GuiObject?)
	if target == glowOn then
		return
	end
	if glowStroke then
		glowStroke:Destroy()
		glowStroke = nil
	end
	glowOn = target
	if target then
		local s = Instance.new("UIStroke")
		s.Name = "TutorialGlow"
		s.Color = GOLD
		s.Thickness = 6
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = target
		glowStroke = s
	end
end

local function hud(name: string): GuiObject?
	local pg = player:FindFirstChild("PlayerGui")
	local h = pg and pg:FindFirstChild("HUD")
	local found = h and h:FindFirstChild(name, true)
	return if found and found:IsA("GuiObject") then found else nil
end

local function myBase(): Model?
	local index = player:GetAttribute("BaseIndex")
	local map = workspace:FindFirstChild("Map")
	local safeZone = map and map:FindFirstChild("SafeZone")
	local bases = safeZone and safeZone:FindFirstChild("Bases")
	local base = if bases and typeof(index) == "number" then bases:FindFirstChild(`Base{index}`) else nil
	return if base and base:IsA("Model") then base else nil
end

local function firstOf(kind: string): Model?
	local base = myBase()
	local plots = base and base:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, child in plots:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Kind") == kind then
			return child
		end
	end
	return nil
end

local function holdingEgg(): boolean
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	return tool ~= nil and typeof(tool:GetAttribute("EggUid")) == "string"
end

local function cheapestUpgrade(): number
	local cost = Economy.speedCost(if typeof(data.speedLevel) == "number" then data.speedLevel else 0)
	local tier = if typeof(data.rackLevel) == "number" then data.rackLevel else 1
	local nextSack = Upgrades.Sack.tiers[tier + 1]
	if nextSack then
		cost = math.min(cost, nextSack.cost)
	end
	return cost
end

-- What to show for a step: banner, sub line, a world target, a HUD element to glow.
local function view(step: number): (string?, string?, Vector3?, GuiObject?)
	local map = workspace:FindFirstChild("Map")
	local pad = map and map:FindFirstChild("KickPad")
	local padPos = if pad and pad:IsA("BasePart") then pad.Position + Vector3.new(0, 4, 0) else nil
	local kick = hud("KickPanel")
	local onPad = kick ~= nil and kick.Visible
	local meter = hud("Meter")
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if step == 1 then
		return "HEAD TO THE KICK LINE!", "Follow the arrow to the golden kick pad", padPos, nil
	elseif step == 2 or step == 3 then
		if not onPad then
			return "BACK TO THE KICK LINE!", nil, padPos, nil
		end
		if meter and meter.Visible then
			return "TIME YOUR KICK!",
				if touch then "Tap when the meter is at the top" else "Stop the meter at the top",
				nil,
				meter
		end
		return "PRESS KICK!", "Your mystery egg is ready", nil, hud("Kick")
	elseif step == 4 then
		if inFlight then
			return "WATCH YOUR EGG!", "The bar at the top shows which zone it reaches", nil, hud("ZoneProgress")
		elseif inChase then
			return "RUN! STEER IT HOME!", "Beat the avalanche back to the safe zone", nil, nil
		end
		return "KICK AN EGG!", nil, padPos, nil
	elseif step == 5 then
		if inChase then
			return "RUN! STEER IT HOME!", "Cross the safe line to keep the egg", nil, nil
		end
		local lost = typeof(data.stats) == "table" and (data.stats.lost or 0) > 0
		return "BRING AN EGG HOME!",
			if lost then "Too slow? Get more RUN SPEED at the Boxing Sack Shop" else "Kick again and race it home",
			padPos,
			nil
	elseif step == 6 then
		local base = myBase()
		local area = base and base:FindFirstChild("PenArea")
		if holdingEgg() then
			return "PUT IT DOWN IN YOUR PEN!",
				if touch then "Tap a green spot in your pen" else "Click a green spot in your pen",
				if area and area:IsA("BasePart") then area.Position + Vector3.new(0, 8, 0) else nil,
				nil
		end
		return "OPEN EGGS AND HOLD YOUR EGG", "Then carry it to your pen", nil, hud("Eggs")
	elseif step == 7 then
		local egg = firstOf("Egg")
		return "YOUR EGG IS HATCHING...",
			"Watch it crack!",
			if egg then egg:GetPivot().Position + Vector3.new(0, 7, 0) else nil,
			nil
	elseif step == 8 then
		local pet = firstOf("Pet")
		return "YOUR PET EARNS MONEY FOR YOU!",
			"Pets walk around your pen and earn every second",
			if pet then pet:GetPivot().Position + Vector3.new(0, 7, 0) else nil,
			hud("Cash")
	elseif step == 9 then
		local money = if typeof(data.money) == "number" then data.money else 0
		local shop = map and map:FindFirstChild("BoxingSackShop", true)
		local shopPos = if shop and shop:IsA("Model") then shop:GetPivot().Position + Vector3.new(0, 22, 0) else nil
		if money >= cheapestUpgrade() then
			return "BUY AN UPGRADE!", "A better Kick Sack or more Run Speed at the Boxing Sack Shop", shopPos, nil
		end
		return "SAVE UP FOR AN UPGRADE", "Your pets are earning: upgrades are at the Boxing Sack Shop", shopPos, nil
	end
	return nil, nil, nil, nil
end

local function celebrate()
	banner.Visible, sub.Visible, skip.Visible = true, true, false
	banner.Text = "TUTORIAL COMPLETE!"
	sub.Text = "Kick farther, hatch rarer pets, fill the Index!"
	local ok, VFX = pcall(require, Shared.VFX)
	local character = player.Character
	if ok and character then
		pcall((VFX :: any).play, "SackUpgrade", character, { tier = 20, own = false })
	end
	task.delay(4, function()
		if (player:GetAttribute("TutorialStep") or 0) == 0 then
			banner.Visible, sub.Visible = false, false
		end
	end)
end

function TutorialController:Start()
	build()
	Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
		for k, v in partial do
			data[k] = v
		end
	end)
	Remotes.get("KickResult").OnClientEvent:Connect(function(result: { [string]: any })
		inFlight = true
		task.delay(math.max(0, result.launchTime + result.flightSeconds - workspace:GetServerTimeNow()), function()
			inFlight = false
		end)
	end)
	local me = player.UserId
	Remotes.get("ChaseStart").OnClientEvent:Connect(function(p: { [string]: any })
		if p.ownerUserId == me then
			inChase = true
		end
	end)
	Remotes.get("ChaseEnded").OnClientEvent:Connect(function()
		inChase = false
	end)
	player:GetAttributeChangedSignal("TutorialDone"):Connect(function()
		if player:GetAttribute("TutorialDone") then
			celebrate()
		end
	end)
	local t0 = os.clock()
	RunService.RenderStepped:Connect(function()
		local step = player:GetAttribute("TutorialStep")
		local active = typeof(step) == "number" and step > 0
		if not active then
			arrowGui.Enabled = false
			setGlow(nil)
			if banner.Text ~= "TUTORIAL COMPLETE!" then
				banner.Visible, sub.Visible = false, false
			end
			skip.Visible = false
			return
		end
		local text, hint, target, glow = view(step :: number)
		banner.Visible, sub.Visible, skip.Visible = text ~= nil, hint ~= nil, true
		banner.Text, sub.Text = text or "", hint or ""
		local bob = math.sin((os.clock() - t0) * 4) * 0.8
		if target then
			arrowPart.CFrame = CFrame.new(target + Vector3.new(0, bob, 0))
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				distLabel.Text = `{math.floor((root.Position - target).Magnitude)}m`
			end
		end
		arrowGui.Enabled = target ~= nil
		setGlow(glow)
		if glowStroke then
			glowStroke.Thickness = 4 + math.abs(math.sin((os.clock() - t0) * 5)) * 4
		end
	end)
end

return TutorialController
