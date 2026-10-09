--!strict
-- Sound on/off (top right, below the top bar). Mutes the client-side SoundService.Master group;
-- every sound Partner A adds is parented to that group. Also sets LocalPlayer attribute "SoundOn".
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Kit = require(script.Parent.Parent.Kit)

local VOLUME = 0.5

local SoundToggle = {}

function SoundToggle.master(): SoundGroup
	local g = SoundService:FindFirstChild("Master")
	if g and g:IsA("SoundGroup") then
		return g
	end
	local group = Instance.new("SoundGroup")
	group.Name = "Master"
	group.Volume = VOLUME
	group.Parent = SoundService
	return group
end

function SoundToggle.new(parent: Instance)
	local on = true
	local master = SoundToggle.master()
	-- Container carries the screen scale; the button's own UIScale does the bounce.
	local holder = Kit.panel({
		name = "SoundToggle",
		size = UDim2.fromOffset(72, 72),
		position = UDim2.new(1, -22, 0.17, 0),
		anchor = Vector2.new(1, 0),
		parent = parent,
	})
	Kit.autoScale(holder)
	local button: TextButton
	local gradient: UIGradient
	button, gradient = Kit.button({
		name = "Sound",
		text = "🔊",
		size = UDim2.fromScale(1, 1),
		parent = holder,
		colors = Kit.Colors.blue,
		radius = 18,
		onClick = function()
			on = not on
			master.Volume = if on then VOLUME else 0
			Players.LocalPlayer:SetAttribute("SoundOn", on)
			local label = button:FindFirstChild("Label") :: TextLabel
			label.Text = if on then "🔊" else "🔇"
			gradient.Color = ColorSequence.new(table.unpack(if on then Kit.Colors.blue else Kit.Colors.grey))
		end,
	})
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.Parent = button
	Players.LocalPlayer:SetAttribute("SoundOn", on)
end

return SoundToggle
