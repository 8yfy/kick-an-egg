--!strict
-- SACK box next to the KICK button (Partner B, Kick Sack gear). It replaces the Roblox backpack
-- hotbar: clicking it (or pressing 1) takes your Kick Sack out or puts it away by equipping the sack
-- Tool that SackService gives every character. With the sack out, every left click (a tap on
-- mobile) kicks it: SackController listens to the Tool's Activated. Shows your current sack in 3D.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Kit = require(script.Parent.Parent.Kit)
local Icons = require(script.Parent.Parent.Icons)

export type SackButton = { update: (data: { [string]: any }) -> () }

local SackButton = {}

local OFF = { Color3.fromRGB(255, 175, 80), Color3.fromRGB(230, 105, 30) }
local ON = { Color3.fromRGB(135, 245, 70), Color3.fromRGB(60, 190, 40) }

-- The sack Tool and whether it is in hand.
local function sackTool(): (Tool?, boolean)
	local player = Players.LocalPlayer
	local held = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if held and held:GetAttribute("KickSack") then
		return held, true
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, t in if backpack then backpack:GetChildren() else {} do
		if t:IsA("Tool") and t:GetAttribute("KickSack") then
			return t, false
		end
	end
	return nil, false
end

local function toggle()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local tool, out = sackTool()
	if not humanoid or not tool or humanoid.Health <= 0 then
		return
	end
	if out then
		humanoid:UnequipTools()
	else
		humanoid:EquipTool(tool)
	end
end

function SackButton.new(parent: Instance): SackButton
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- the SACK box is the only gear
	end)
	-- Just right of A's KICK button and as tall as it (read from the KickPanel layout, so it follows it).
	local size, position, anchor = UDim2.fromOffset(96, 86), UDim2.new(1, -2, 1, 0), Vector2.new(1, 1)
	local kick = parent:FindFirstChild("Kick")
	if kick and kick:IsA("GuiObject") then
		local h = kick.Size.Y.Offset
		local right = kick.Position.X.Offset + kick.Size.X.Offset * (1 - kick.AnchorPoint.X)
		size = UDim2.fromOffset(math.floor(h * 0.85), h)
		position = UDim2.new(kick.Position.X.Scale, right + 14, kick.Position.Y.Scale, kick.Position.Y.Offset)
		anchor = Vector2.new(0, kick.AnchorPoint.Y)
	end
	local button, gradient = Kit.button({
		name = "Sack",
		text = "SACK",
		size = size,
		position = position,
		anchor = anchor,
		parent = parent,
		colors = OFF,
		radius = 22,
		onClick = toggle,
	})
	local label = button:FindFirstChild("Label") :: TextLabel
	label.Size = UDim2.fromScale(0.86, 0.22)
	label.Position = UDim2.new(0.5, 0, 1, -6)
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.ZIndex = 3
	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.BackgroundTransparency = 1
	preview.Size = UDim2.new(1, -8, 0.74, 0)
	preview.Position = UDim2.fromOffset(4, 4)
	preview.ZIndex = 2
	preview.Parent = button
	if UserInputService.KeyboardEnabled then
		local key = Kit.label({
			name = "Key",
			text = "1",
			size = UDim2.fromOffset(20, 20),
			position = UDim2.fromOffset(7, 5),
			parent = button,
			stroke = 2,
		})
		key.ZIndex = 3
	end
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local hint = Kit.label({
		name = "Hint",
		text = if touch then "Tap to kick!" else "Click to kick!",
		size = UDim2.fromOffset(170, 26),
		position = UDim2.new(0.5, 0, 0, -4),
		anchor = Vector2.new(0.5, 1),
		parent = button,
		color = ON[1],
		stroke = 2,
	})
	hint.Visible = false

	local stopPulse: (() -> ())? = nil
	local function refresh()
		local _, out = sackTool()
		local pair = if out then ON else OFF
		gradient.Color = ColorSequence.new(pair[1], pair[2])
		hint.Visible = out
		if out and not stopPulse then
			Kit.pop(hint, 0.25)
			stopPulse = Kit.pulse(hint, 1.08)
		elseif not out and stopPulse then
			stopPulse()
			stopPulse = nil
		end
	end
	local function watch(character: Model)
		character.ChildAdded:Connect(refresh)
		character.ChildRemoved:Connect(refresh)
		refresh()
	end
	Players.LocalPlayer.CharacterAdded:Connect(watch)
	if Players.LocalPlayer.Character then
		watch(Players.LocalPlayer.Character)
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.One then
			toggle()
		end
	end)

	local shown = 0
	local function update(data: { [string]: any })
		local tier = if typeof(data.rackLevel) == "number" then data.rackLevel else 1
		if tier ~= shown then
			shown = tier
			preview:ClearAllChildren()
			Icons.sack(preview, tier).ZIndex = 2
		end
	end
	update({})
	return { update = update }
end

return SackButton
