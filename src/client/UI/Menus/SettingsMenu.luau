--!strict
-- Settings (client-side, this session): Sound, a volume per sound category, Camera Shake, Low Detail effects,
-- Sack effects. Sound mutes SoundService.Master; UI / Gameplay / Ambience / Music / Special effects set the volume
-- of that category's SoundGroup (Audio.setVolume; magic layers on top of hits, kicks and hatches are Special
-- effects, so they can be turned down on their own). Camera Shake and Low Detail set
-- LocalPlayer attributes "ShakeOff" / "LowDetail", which VFX reads. Sack effects sets "SackVfxQuality"
-- (nil = AUTO), the Kick Sack effects' quality profile (VFX/SackLod).
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Kit = require(script.Parent.Parent.Kit)
local Window = require(script.Parent.Window)
local SoundToggle = require(script.Parent.Parent.Hud.SoundToggle)
local Audio = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Audio")) :: any

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local SettingsMenu = {}

local VOLUMES = { 1, 0.75, 0.5, 0.25, 0 }
local VOLUME_LABELS = { "100%", "75%", "50%", "25%", "OFF" }

function SettingsMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Settings", Kit.Colors.grey)
	local body = Instance.new("ScrollingFrame") -- more rows than fit on a phone: scroll
	body.Name = "Rows"
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Size = UDim2.fromScale(1, 1)
	body.CanvasSize = UDim2.new()
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.ScrollBarThickness = 8
	body.Parent = window.body
	body.ScrollBarImageColor3 = Color3.fromRGB(200, 205, 230)
	body.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar -- rows never run under the bar
	body.ScrollingEnabled = true
	body.Selectable = false
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 18) -- the last row ends fully inside the window
	pad.Parent = body
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 14)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = body
	local rows = 0
	local me = Players.LocalPlayer
	-- (attributes on the local player; no player in Studio previews / headless tests)
	local function attr(name: string): any
		return if me then me:GetAttribute(name) else nil
	end
	local function setAttr(name: string, value: any)
		if me then
			me:SetAttribute(name, value)
		end
	end
	local firstButton: GuiObject? = nil

	local function toggle(title: string, initial: boolean, apply: (on: boolean) -> ())
		local row = Kit.panel({
			name = title,
			size = UDim2.new(1, -40, 0, 92),
			parent = body,
			colors = { Color3.fromRGB(70, 65, 95), Color3.fromRGB(50, 46, 70) },
			radius = 18,
		})
		rows += 1
		row.LayoutOrder = rows
		Kit.label({
			name = "Title",
			text = title,
			size = UDim2.new(1, -260, 0, 44),
			position = UDim2.fromOffset(24, 24),
			parent = row,
			align = Enum.TextXAlignment.Left,
		})
		local on = initial
		local button: TextButton
		local gradient: UIGradient
		button, gradient = Kit.button({
			name = "Toggle",
			text = if on then "ON" else "OFF",
			size = UDim2.fromOffset(180, 66),
			position = UDim2.new(1, -16, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			parent = row,
			colors = if on then Kit.Colors.green else Kit.Colors.red,
			onClick = function()
				on = not on
				local label = button:FindFirstChild("Label") :: TextLabel
				label.Text = if on then "ON" else "OFF"
				gradient.Color = ColorSequence.new(table.unpack(if on then Kit.Colors.green else Kit.Colors.red))
				apply(on)
			end,
		})
		firstButton = firstButton or button
		apply(on)
	end

	-- a row whose button steps through `options` (labels) on each click
	local function choice(title: string, options: { string }, initial: number, apply: (index: number) -> ())
		local row = Kit.panel({
			name = title,
			size = UDim2.new(1, -40, 0, 92),
			parent = body,
			colors = { Color3.fromRGB(70, 65, 95), Color3.fromRGB(50, 46, 70) },
			radius = 18,
		})
		rows += 1
		row.LayoutOrder = rows
		Kit.label({
			name = "Title",
			text = title,
			size = UDim2.new(1, -260, 0, 44),
			position = UDim2.fromOffset(24, 24),
			parent = row,
			align = Enum.TextXAlignment.Left,
		})
		local index = initial
		local button: TextButton
		button = Kit.button({
			name = "Choice",
			text = options[index],
			size = UDim2.fromOffset(180, 66),
			position = UDim2.new(1, -16, 0.5, 0),
			anchor = Vector2.new(1, 0.5),
			parent = row,
			colors = Kit.Colors.blue,
			onClick = function()
				index = index % #options + 1
				local label = button:FindFirstChild("Label") :: TextLabel
				label.Text = options[index]
				apply(index)
			end,
		})
	end

	local master = SoundToggle.master()
	toggle("Sound effects", master.Volume > 0, function(on)
		master.Volume = if on then 0.5 else 0
		setAttr("SoundOn", on)
	end)
	for _, category in
		{
			{ "UI", "UI sounds" },
			{ "Gameplay", "Gameplay" },
			{ "Ambience", "Ambience" },
			{ "Music", "Music" },
			{ "SpecialEffects", "Special effects" },
		}
	do
		local now = Audio.volume(category[1])
		local index = 1
		for i, v in VOLUMES do
			if math.abs(v - now) < math.abs(VOLUMES[index] - now) then
				index = i
			end
		end
		choice(category[2], VOLUME_LABELS, index, function(i)
			Audio.setVolume(category[1], VOLUMES[i])
		end)
	end
	toggle("Camera shake", attr("ShakeOff") ~= true, function(on)
		setAttr("ShakeOff", not on)
	end)
	toggle("Low detail effects", attr("LowDetail") == true, function(on)
		setAttr("LowDetail", on)
	end)
	-- Kick Sack effects: AUTO follows the Roblox graphics level and this device's frame rate (VFX/SackLod)
	local levels = { "AUTO", "HIGH", "MEDIUM", "LOW", "MINIMAL" }
	local current = attr("SackVfxQuality")
	choice(
		"Sack effects",
		levels,
		if typeof(current) == "string" then table.find(levels, current) or 1 else 1,
		function(index)
			setAttr("SackVfxQuality", if index == 1 then nil else levels[index])
		end
	)
	-- UI/System/Motion reads "ReducedMotion": no overshoot, loops, floating art or bursts; short fades only. The
	-- kick cutscene keeps one steady camera and VFX/Shake shakes much less with it on.
	local reduced = attr("ReducedMotion")
	toggle(
		"Reduced motion",
		if typeof(reduced) == "boolean" then reduced else (GuiService :: any).ReducedMotionEnabled == true,
		function(on)
			setAttr("ReducedMotion", on)
		end
	)

	-- gamepads: opening the window selects its first option (the list scrolls along with the selection)
	window.onOpen(function()
		local UserInputService = game:GetService("UserInputService")
		local last = UserInputService:GetLastInputType()
		if firstButton and string.find(last.Name, "Gamepad") then
			body.CanvasPosition = Vector2.zero
			GuiService.SelectedObject = firstButton
		end
	end)

	return { window = window, update = function(_data: { [string]: any }) end }
end

return SettingsMenu
