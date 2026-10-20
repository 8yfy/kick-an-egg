--!strict
-- Run as a real Studio LocalScript. Component checks use the production modules;
-- they do not change inventory, saved tutorial progress, camera or controls.
assert(game:GetService("RunService"):IsStudio(), "Studio QA only")
local player = game.Players.LocalPlayer
local modules = player.PlayerScripts.Client.UI.Tutorial
local Objective, Welcome, Focus = require(modules.Objective), require(modules.Welcome), require(modules.Focus)
local Style = require(modules.Style)
local Assets = require(modules.Assets)
local Spotlight = require(modules.Spotlight)
local WorldGuide = require(modules.WorldGuide)
local Motion = require(player.PlayerScripts.Client.UI.System.Motion)
local Theme = require(player.PlayerScripts.Client.UI.System.Theme)
local previousReduced = player:GetAttribute("ReducedMotion")
local count = 0
local function check(name: string, pass: boolean)
	assert(pass, name)
	count += 1
end
local screen = Instance.new("ScreenGui")
screen.Name = "TutorialPresentationQA"
screen.Parent = player.PlayerGui
local function approvedImagesOnly(root: Instance)
	local unexpected = 0
	for _, object in root:GetDescendants() do
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			if not object:IsA("ImageLabel") or object.Image ~= Assets.FocusArrow then
				unexpected += 1
			end
		end
	end
	check("Only approved arrow images in " .. root.Name, unexpected == 0)
end
local ok, problem = pcall(function()
	for _, size in { Vector2.new(844, 390), Vector2.new(390, 844), Vector2.new(320, 568) } do
		local host = Instance.new("Frame")
		host.Size, host.Position, host.BackgroundTransparency =
			UDim2.fromOffset(size.X, size.Y), UDim2.fromOffset(-2000, 0), 1
		host.Parent = screen
		local welcome = Welcome.new(host :: any, function() end, function() end)
		local objective = Objective.new(host :: any, function() end)
		welcome:layout()
		welcome:show(true)
		task.wait(0.35)
		local panel = host.Welcome.Panel
		for _, label in
			{
				panel.Title,
				panel.Message,
				panel.Header.TitleRow.Heading,
				panel.Actions.Continue.Label,
				panel.Actions.Skip.Label,
			}
		do
			check("Welcome text fits " .. label.Name, label.TextFits)
		end
		check(
			"Welcome tap target",
			panel.Actions.Continue.AbsoluteSize.Y >= 48 and panel.Actions.Skip.AbsoluteSize.Y >= 48
		)
		local color = panel.Header.Fill.Color.Keypoints[1].Value
		check("Red welcome gradient", color.R > color.G)
		for _, phrase in
			{ "Select your egg in the hotbar.", "Click to train your power.", "Your pet earns money for you!" }
		do
			objective:show(phrase, 3)
			objective:layout()
			objective:update(os.clock() + 0.3)
			task.wait()
			local card = host.Objective
			local body = card.Reveal.Content.Panel
			check("Objective text fits " .. phrase, body.Sentence.TextFits)
			check("Objective tap target", body.Skip.AbsoluteSize.Y >= 48)
			-- Include the visible border and real hover enlargement, not just the button rectangle.
			local buttonScale = Motion.scaleOf(body.Skip)
			buttonScale.Scale = Theme.Motion.hoverScale
			task.wait()
			local lowerEdge = body.Skip.AbsolutePosition.Y
				+ body.Skip.AbsoluteSize.Y
				+ body.Skip.UIStroke.Thickness * Theme.Motion.hoverScale
			local progressTop = body.StageProgress.AbsolutePosition.Y - body.StageProgress.UIStroke.Thickness
			check("Skip border clears progress while hovered", progressTop - lowerEdge >= 4)
			buttonScale.Scale = 1
			check("Visible cue", card.Reveal.Visible and not card.Hint.Visible)
			objective:update(os.clock() + 5)
			check("Quiet interval keeps hint available", not card.Reveal.Visible and card.Hint.Visible)
			objective:update(os.clock() + 10.3)
			check("Reminder returns", card.Reveal.Visible and not card.Hint.Visible)
		end
		objective:complete()
		objective:layout()
		objective:update(os.clock())
		task.wait()
		check("Completion fits", host.Objective.Reveal.Content.Panel.Header.TitleRow.Heading.TextFits)
		approvedImagesOnly(host)
		welcome:destroy()
		objective:destroy()
		host:Destroy()
	end
	local hud = Instance.new("Frame")
	hud.Parent = screen
	local rail, weather, hotbar, counters =
		Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame"), Instance.new("Frame")
	rail.Name, weather.Name, hotbar.Name, counters.Name = "LeftRail", "WeatherWidget", "Hotbar", "Counters"
	for _, object in { rail, weather, hotbar, counters } do
		object.Parent = hud
	end
	local focus = Focus.new()
	focus:update(hud, true, false)
	check("Distractions hidden", not rail.Parent.Visible and not weather.Parent.Visible)
	check("Hotbar untouched", hotbar.Parent == hud and hotbar.Visible)
	weather.Visible = false -- The live widget can change its own state while masked.
	focus:update(hud, true, true)
	check("Income counter revealed", counters.Parent == hud)
	focus:restore()
	check("Exact roots restored", rail.Parent == hud and weather.Parent == hud and counters.Parent == hud)
	check("Hidden widget remains hidden", not weather.Visible)
	check("Wrapper cleanup", #hud:GetChildren() == 4)
	focus:destroy()
	hud:Destroy()
	-- Exercise the real hole geometry and motion on a control near the bottom of the viewport.
	local button = Instance.new("TextButton")
	button.Name, button.Size = "Target", UDim2.fromOffset(64, 64)
	button.Position, button.Parent = UDim2.new(0.5, 0, 1, -90), screen
	local spot = Spotlight.new(screen)
	spot:set(button)
	task.wait(0.25)
	player:SetAttribute("ReducedMotion", false)
	spot:update(0)
	local layer, pointer = screen.Spotlight, screen.Spotlight.Pointer
	local firstY, firstX = pointer.AbsolutePosition.Y, pointer.AbsolutePosition.X
	check(
		"Custom PNG points down above control",
		pointer:IsA("ImageLabel")
			and pointer.Image == Assets.FocusArrow
			and pointer.Rotation == 90
			and pointer.Position.Y.Offset + 32 < layer.Focus.Position.Y.Offset
	)
	spot:update(0.3125)
	check(
		"Pointer bounces vertically",
		math.abs(pointer.AbsolutePosition.Y - firstY) > 2 and pointer.AbsolutePosition.X == firstX
	)
	task.wait() -- Roblox settles the changed rectangles before reading their absolute sizes.
	local center = layer.Focus.AbsolutePosition + layer.Focus.AbsoluteSize / 2
	local area = layer.Focus.AbsoluteSize.X * layer.Focus.AbsoluteSize.Y
	for _, name in { "Top", "Bottom", "Left", "Right" } do
		local mask = layer:FindFirstChild(name) :: Frame
		local a, b = mask.AbsolutePosition, mask.AbsolutePosition + mask.AbsoluteSize
		check(
			"Mask leaves control clear: " .. name,
			not (center.X > a.X and center.X < b.X and center.Y > a.Y and center.Y < b.Y)
		)
		check("Mask cannot capture input: " .. name, not mask.Active and mask.BackgroundTransparency < 0.6)
		area += mask.AbsoluteSize.X * mask.AbsoluteSize.Y
	end
	check("Masks cover surroundings without gaps", math.abs(area - screen.AbsoluteSize.X * screen.AbsoluteSize.Y) < 2)
	player:SetAttribute("ReducedMotion", true)
	spot:update(0)
	local reducedY, thickness = pointer.Position.Y.Offset, layer.Focus.UIStroke.Thickness
	spot:update(0.3125)
	check(
		"Reduced Motion freezes pointer and pulse",
		pointer.Position.Y.Offset == reducedY and layer.Focus.UIStroke.Thickness == thickness
	)
	button.Position = UDim2.fromOffset(100, 4)
	task.wait()
	spot:update(0)
	check("Top-edge control uses downward-space fallback", pointer.Rotation == 270)
	spot:set(nil)
	spot:update(0)
	check("Clearing target removes dimming", not layer.Visible)
	spot:destroy()
	button:Destroy()
	local liveFolder = workspace:FindFirstChild("TutorialGuidance")
	local world = WorldGuide.new(screen)
	local folder: Instance? = nil
	for _, child in workspace:GetChildren() do
		if child.Name == "TutorialGuidance" and child ~= liveFolder then
			folder = child
		end
	end
	assert(folder, "World QA folder missing")
	folder.Name = "TutorialWorldQA"
	local anchor = folder:FindFirstChild("WorldTarget") :: Part
	local worldArrow = screen.WorldPointer
	world:set(Vector3.new(0, 1000, 0), nil, nil, false)
	player:SetAttribute("ReducedMotion", false)
	world:update(1 / 60, 0)
	local startY = anchor.Position.Y
	world:update(1 / 60, 0.3125)
	check("World destination remains fixed while pointer bounces", anchor.Position.Y == startY)
	check("World arrow uses same downward PNG", worldArrow.Image == Assets.FocusArrow and worldArrow.Rotation == 90)
	player:SetAttribute("ReducedMotion", true)
	world:update(1 / 60, 0)
	startY = anchor.Position.Y
	world:update(1 / 60, 0.3125)
	check("Reduced Motion freezes world bob", anchor.Position.Y == startY)
	local camera = workspace.CurrentCamera
	local inFront = camera.CFrame:PointToWorldSpace(Vector3.new(0, 0, -30))
	player:SetAttribute("ReducedMotion", false)
	world:set(inFront, nil, nil, false)
	world:update(1 / 60, 0)
	local projected = camera:WorldToScreenPoint(inFront)
	local tipOffset = worldArrow.Size.X.Offset * 0.34
	local tip = Vector2.new(worldArrow.Position.X.Offset, worldArrow.Position.Y.Offset + tipOffset)
	check(
		"Arrow tip stays above the real target with GUI inset applied",
		worldArrow.Visible
			and math.abs(tip.X - projected.X) <= 1
			and projected.Y - tip.Y >= 7
			and projected.Y - tip.Y <= 10
	)
	local firstArrowY = worldArrow.Position.Y.Offset
	world:update(1 / 60, 0.3125)
	check("World pointer bounces in screen pixels", math.abs(worldArrow.Position.Y.Offset - firstArrowY) >= 3)
	player:SetAttribute("ReducedMotion", true)
	world:update(1 / 60, 0)
	firstArrowY = worldArrow.Position.Y.Offset
	world:update(1 / 60, 0.3125)
	check("Reduced Motion freezes screen pointer", worldArrow.Position.Y.Offset == firstArrowY)
	for _, depth in { 12, 35, 120 } do
		local aim = camera.CFrame:PointToWorldSpace(Vector3.new(4, -2, -depth))
		world:set(aim, nil, nil, false)
		world:update(1 / 60, 0)
		local expected = camera:WorldToScreenPoint(aim)
		local actualTip = Vector2.new(worldArrow.Position.X.Offset, worldArrow.Position.Y.Offset + tipOffset)
		check(
			"Tip remains aligned at distance " .. depth,
			worldArrow.Visible
				and worldArrow.Rotation == 90
				and math.abs(actualTip.X - expected.X) <= 1
				and expected.Y - actualTip.Y >= 7
				and expected.Y - actualTip.Y <= 10
		)
	end
	local guiInset = game:GetService("GuiService"):GetGuiInset()
	local size = screen.AbsoluteSize
	for _, sample in
		{
			{ position = Vector2.new(size.X / 2, 18), rotation = 270 },
			{ position = Vector2.new(size.X / 2, size.Y - 18), rotation = 90 },
			{ position = Vector2.new(18, size.Y / 2), rotation = 180 },
			{ position = Vector2.new(size.X - 18, size.Y / 2), rotation = 0 },
		}
	do
		local ray = camera:ViewportPointToRay(sample.position.X + guiInset.X, sample.position.Y + guiInset.Y)
		local aim = ray.Origin + ray.Direction * 40
		world:set(aim, nil, nil, false)
		world:update(1 / 60, 0)
		check(
			"Near-edge pointer faces the destination " .. sample.rotation,
			worldArrow.Visible and worldArrow.Rotation == sample.rotation and not screen.OffscreenDirection.Visible
		)
		local direction = Vector2.new(math.cos(math.rad(worldArrow.Rotation)), math.sin(math.rad(worldArrow.Rotation)))
		local actualTip = Vector2.new(worldArrow.Position.X.Offset, worldArrow.Position.Y.Offset)
			+ direction * tipOffset
		local toTarget = sample.position - actualTip
		check(
			"Near-edge tip aligns with destination " .. sample.rotation,
			toTarget:Dot(direction) >= 7
				and toTarget:Dot(direction) <= 10
				and math.abs(toTarget.X * direction.Y - toTarget.Y * direction.X) <= 1
		)
	end
	player:SetAttribute("ReducedMotion", false)
	local boundaryRay = camera:ViewportPointToRay(size.X / 2 + guiInset.X, 80 + guiInset.Y)
	world:set(boundaryRay.Origin + boundaryRay.Direction * 40, nil, nil, false)
	world:update(1 / 60, 0)
	local firstRotation, stable = worldArrow.Rotation, worldArrow.Visible
	for _, phase in { 0.3125, 0.625, 0.9375 } do
		world:update(1 / 60, phase)
		stable = stable and worldArrow.Visible and worldArrow.Rotation == firstRotation
	end
	check("Bounce cannot flip pointer side at a viewport boundary", stable)
	player:SetAttribute("ReducedMotion", true)
	screen.IgnoreGuiInset = true
	task.wait()
	world:set(inFront, nil, nil, false)
	world:update(1 / 60, 0)
	local raw = camera:WorldToViewportPoint(inFront)
	tip = Vector2.new(worldArrow.Position.X.Offset, worldArrow.Position.Y.Offset + tipOffset)
	check(
		"Inset-free screen uses viewport coordinates",
		worldArrow.Visible and math.abs(tip.X - raw.X) <= 1 and raw.Y - tip.Y >= 7 and raw.Y - tip.Y <= 10
	)
	world:set(camera.CFrame:PointToWorldSpace(Vector3.new(0, 0, 30)), nil, nil, false)
	world:update(1 / 60, 0)
	check("Behind-camera target uses edge pointer", not worldArrow.Visible and screen.OffscreenDirection.Visible)
	world:set(nil, nil, nil, false)
	world:update(1 / 60, 0)
	check("Clearing world target hides pointers", not worldArrow.Visible and not screen.OffscreenDirection.Visible)
	world:destroy()
	check("World effect cleanup", folder.Parent == nil and worldArrow.Parent == nil)
	local tutorial = player.PlayerGui.Tutorial
	approvedImagesOnly(tutorial)
	approvedImagesOnly(workspace.TutorialGuidance)
	check("Live pointer red", tutorial.Spotlight.Focus.UIStroke.Color == Style.RED)
end)
screen:Destroy()
player:SetAttribute("ReducedMotion", previousReduced)
player:SetAttribute("TutorialPresentationQA", if ok then "Passed " .. count .. " checks" else tostring(problem))
assert(ok, tostring(problem))
script:Destroy()
