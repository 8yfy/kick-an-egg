--!strict
-- The show-don't-tell tutorial (client). TutorialService (server) decides the step from your real actions (saved,
-- so it survives rejoining; never a timer; never asks for something you can't do) and mirrors it as
-- LocalPlayer.TutorialStep; this only SHOWS it, small and in the world:
--   * a ground TRAIL of glowing dots from you to where to go, and a small bobbing ARROW over it (kick pad, your
--     pen, the Boxing Sack Shop),
--   * a soft HIGHLIGHT on the real thing (the pad, the mystery egg in your hands, your placed egg, your pet),
--   * a gold glow on the one HUD element that matters (KICK, the meter, Power, Cash),
--   * one short prompt chip (a few words), and a small SKIP.
-- Nothing blocks input; it all hides during your kick cinematic. TutorialDone -> a short celebration once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Remotes = require(Shared.Remotes)
local EggKick = require(Shared.Anim.EggKick)

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
local TRAIL_DOTS = 12
local trailFolder: Folder
local trail: { Part } = {}
local highlight: Highlight

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
	banner = label(gui, "Banner", UDim2.fromOffset(420, 34), UDim2.new(0.5, 0, 0, 150), 28) -- the prompt chip
	banner.TextColor3 = GOLD
	sub = label(gui, "Sub", UDim2.fromOffset(420, 22), UDim2.new(0.5, 0, 0, 186), 18)
	sub.Visible = false
	skip = Instance.new("TextButton")
	skip.Name = "Skip"
	skip.AnchorPoint = Vector2.new(0.5, 0)
	skip.Position = UDim2.new(0.5, 0, 0, 188)
	skip.Size = UDim2.fromOffset(110, 22)
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
	arrowGui.Size = UDim2.fromOffset(56, 76)
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
	-- the ground trail: small glowing dots from you to the target
	trailFolder = Instance.new("Folder")
	trailFolder.Name = "TutorialTrail"
	trailFolder.Parent = workspace
	for i = 1, TRAIL_DOTS do
		local dot = Instance.new("Part")
		dot.Name = "Dot" .. i
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.new(0.6, 0.6, 0.6)
		dot.Material = Enum.Material.Neon
		dot.Color = GOLD
		dot.Anchored, dot.CanCollide, dot.CanQuery, dot.CanTouch, dot.CastShadow = true, false, false, false, false
		dot.Transparency = 1
		dot.Parent = trailFolder
		table.insert(trail, dot)
	end
	-- the highlight on the real thing
	highlight = Instance.new("Highlight")
	highlight.Name = "TutorialHighlight"
	highlight.FillColor = GOLD
	highlight.FillTransparency = 0.82
	highlight.OutlineColor = GOLD
	highlight.OutlineTransparency = 0.05
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = gui
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

-- What to show for a step: a short prompt, a world spot to go to, a HUD element to glow, a world thing to highlight.
local function view(step: number): (string?, Vector3?, GuiObject?, Instance?)
	local map = workspace:FindFirstChild("Map")
	local pad = map and map:FindFirstChild("KickPad")
	local padPos = if pad and pad:IsA("BasePart") then pad.Position + Vector3.new(0, 4, 0) else nil
	local kick = hud("KickPanel")
	local onPad = kick ~= nil and kick.Visible
	local meter = hud("Meter")
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local character = player.Character
	if step == 1 then
		return "Go to the kick line", padPos, nil, pad
	elseif step == 2 or step == 3 then
		if not onPad then
			return "Back to the kick line", padPos, nil, pad
		end
		if meter and meter.Visible then
			return "Stop it at the top!", nil, meter, nil
		end
		return "Press KICK!", nil, hud("Kick"), character and character:FindFirstChild("MysteryEgg")
	elseif step == 4 then
		if inFlight then
			return "More POWER = farther kicks", nil, hud("Power"), nil -- progression, briefly
		elseif inChase then
			return "Steer it home!", nil, nil, nil
		end
		return "Kick an egg", padPos, nil, pad
	elseif step == 5 then
		if inChase then
			return "Steer it home!", nil, nil, nil
		end
		return "Kick again!", padPos, nil, pad
	elseif step == 6 then
		local base = myBase()
		local area = base and base:FindFirstChild("PenArea")
		local penPos: Vector3? = nil
		if area and area:IsA("BasePart") then
			-- from outside: the pen's gate (the trail walks you in through it, never across a fence); inside: its middle
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local here = if root and root:IsA("BasePart") then area.CFrame:PointToObjectSpace(root.Position) else nil
			local inside = here ~= nil and math.abs(here.X) < area.Size.X / 2 and math.abs(here.Z) < area.Size.Z / 2
			penPos = if inside
				then area.Position + Vector3.new(0, 6, 0)
				else (area.CFrame * CFrame.new(0, 6, -area.Size.Z / 2 - 3)).Position
		end
		if holdingEgg() then
			return if touch then "Tap a spot in your pen" else "Click a spot in your pen", penPos, nil, nil
		end
		return if touch then "Tap your egg in the hotbar" else "Press 1 to hold your egg", penPos, nil, nil
	elseif step == 7 then
		local egg = firstOf("Egg")
		return "It's hatching...", nil, nil, egg
	elseif step == 8 then
		return "Your pet earns money!", nil, hud("Cash"), firstOf("Pet")
	elseif step == 9 then
		local shop = map and map:FindFirstChild("BoxingSackShop", true)
		-- in front of the entrance (map "Approach"), not the roof
		local approach = shop and shop:FindFirstChild("Approach")
		local shopPos = if approach and approach:IsA("BasePart")
			then approach.Position + Vector3.new(0, 5, 0)
			elseif shop and shop:IsA("Model") then shop:GetPivot().Position + Vector3.new(0, 18, 0)
			else nil
		local money = if typeof(data.money) == "number" then data.money else 0
		return if money >= cheapestUpgrade() then "Buy an upgrade" else "Save up for an upgrade", shopPos, nil, shop
	end
	return nil, nil, nil, nil
end

-- Lays the trail dots on the ground from you towards `target` (hidden when you're close or there's none).
local function drawTrail(target: Vector3?, t: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local from = if root and root:IsA("BasePart") then root.Position else nil
	local show = target ~= nil and from ~= nil and (Vector3.new(target.X, from.Y, target.Z) - from).Magnitude > 14
	for i, dot in trail do
		if not show then
			dot.Transparency = 1
			continue
		end
		local a = (i - 0.5) / TRAIL_DOTS
		local flat = (from :: Vector3):Lerp(target :: Vector3, a * 0.92)
		local y = (from :: Vector3).Y - 2.6
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character :: Instance, trailFolder }
		local hit = workspace:Raycast(Vector3.new(flat.X, y + 8, flat.Z), Vector3.new(0, -30, 0), params)
		local pos = if hit then hit.Position + Vector3.new(0, 0.35, 0) else Vector3.new(flat.X, y, flat.Z)
		dot.CFrame = CFrame.new(pos)
		dot.Transparency = 0.15 + 0.55 * (0.5 + 0.5 * math.sin(t * 6 - i * 0.7)) -- a pulse running along it
	end
end

local function celebrate()
	banner.Visible, sub.Visible, skip.Visible = true, false, false
	banner.Text = "TUTORIAL COMPLETE!"
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
		local cinematic = workspace:GetServerTimeNow() < EggKick.cameraBusyUntil + 0.3 -- your kick: hands off
		if not active or cinematic then
			arrowGui.Enabled = false
			highlight.Enabled = false
			drawTrail(nil, 0)
			setGlow(nil)
			if banner.Text ~= "TUTORIAL COMPLETE!" or cinematic then
				banner.Visible, sub.Visible = false, false
			end
			skip.Visible = false
			return
		end
		local text, target, glow, thing = view(step :: number)
		banner.Visible, sub.Visible, skip.Visible = text ~= nil, false, true
		banner.Text = text or ""
		local t = os.clock() - t0
		local bob = math.sin(t * 4) * 0.6
		if target then
			arrowPart.CFrame = CFrame.new(target + Vector3.new(0, bob, 0))
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				distLabel.Text = `{math.floor((root.Position - target).Magnitude)}m`
			end
		end
		arrowGui.Enabled = target ~= nil
		drawTrail(target, t)
		highlight.Adornee = thing
		highlight.Enabled = thing ~= nil
		setGlow(glow)
		if glowStroke then
			glowStroke.Thickness = 3 + math.abs(math.sin(t * 5)) * 3
		end
	end)
end

return TutorialController
