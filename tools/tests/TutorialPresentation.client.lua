--!strict
-- Run as a real Studio LocalScript. Component checks use the production modules;
-- they do not change inventory, saved tutorial progress, camera or controls.
assert(game:GetService("RunService"):IsStudio(), "Studio QA only")
local player = game.Players.LocalPlayer
local modules = player.PlayerScripts.Client.UI.Tutorial
local Objective, Welcome, Focus = require(modules.Objective), require(modules.Welcome), require(modules.Focus)
local Style = require(modules.Style)
local count = 0
local function check(name: string, pass: boolean)
	assert(pass, name)
	count += 1
end
local screen = Instance.new("ScreenGui")
screen.Name = "TutorialPresentationQA"
screen.Parent = player.PlayerGui
local function noImages(root: Instance)
	local images = 0
	for _, object in root:GetDescendants() do
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			images += 1
		end
	end
	check("No tutorial images in " .. root.Name, images == 0)
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
		noImages(host)
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
	local tutorial = player.PlayerGui.Tutorial
	noImages(tutorial)
	noImages(workspace.TutorialGuidance)
	check("Live pointer red", tutorial.Spotlight.Focus.UIStroke.Color == Style.RED)
end)
screen:Destroy()
player:SetAttribute("TutorialPresentationQA", if ok then "Passed " .. count .. " checks" else tostring(problem))
assert(ok, tostring(problem))
script:Destroy()
