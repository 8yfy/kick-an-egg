--!strict
-- Settings (client-side, this session): Sound, Music, Camera Shake, Low Detail effects.
-- Sound/Music drive SoundService.Master / SoundService.Music groups. Camera Shake and Low Detail set
-- LocalPlayer attributes "ShakeOff" / "LowDetail", which VFX reads.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Kit = require(script.Parent.Parent.Kit)
local Window = require(script.Parent.Window)
local SoundToggle = require(script.Parent.Parent.Hud.SoundToggle)

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local SettingsMenu = {}

local function group(name: string, volume: number): SoundGroup
	local g = SoundService:FindFirstChild(name)
	if g and g:IsA("SoundGroup") then
		return g
	end
	local ng = Instance.new("SoundGroup")
	ng.Name = name
	ng.Volume = volume
	ng.Parent = SoundService
	return ng
end

function SettingsMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Settings", Kit.Colors.grey)
	local body = window.body
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 14)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = body
	local rows = 0
	local me = Players.LocalPlayer

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
		apply(on)
	end

	local master = SoundToggle.master()
	toggle("Sound effects", master.Volume > 0, function(on)
		master.Volume = if on then 0.5 else 0
		me:SetAttribute("SoundOn", on)
	end)
	local music = group("Music", 0.35)
	toggle("Music", music.Volume > 0, function(on)
		music.Volume = if on then 0.35 else 0
	end)
	toggle("Camera shake", me:GetAttribute("ShakeOff") ~= true, function(on)
		me:SetAttribute("ShakeOff", not on)
	end)
	toggle("Low detail effects", me:GetAttribute("LowDetail") == true, function(on)
		me:SetAttribute("LowDetail", on)
	end)

	return { window = window, update = function(_data: { [string]: any }) end }
end

return SettingsMenu
