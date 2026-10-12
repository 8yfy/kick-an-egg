--!strict
-- Sound on/off (round button: top right on desktop, right edge on phones). Mutes the client-side SoundService.Master group;
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
	-- Round dark button: top right on desktop, right edge above the jump button on phones.
	local holder = Kit.panel({ name = "SoundToggle", size = UDim2.fromOffset(58, 58), parent = parent })
	Kit.autoScale(holder)
	Kit.onLayout(function(compact: boolean)
		holder.AnchorPoint = Vector2.new(1, if compact then 0.5 else 0)
		holder.Size = if compact then UDim2.fromOffset(96, 96) else UDim2.fromOffset(58, 58)
		holder.Position = if compact then UDim2.new(1, -10, 0.5, -28) else UDim2.new(1, -26, 0, 22)
	end)
	local icon: ImageLabel
	local button = Kit.roundButton(holder, "Sound", function()
		on = not on
		master.Volume = if on then VOLUME else 0
		Players.LocalPlayer:SetAttribute("SoundOn", on)
		icon.ImageTransparency = if on then 0 else 0.6
	end)
	icon = require(script.Parent.Parent.Icons).view(button, "Sound", UDim2.fromScale(0.7, 0.7))
	icon.Position = UDim2.fromScale(0.15, 0.15)
	Players.LocalPlayer:SetAttribute("SoundOn", on)
end

return SoundToggle
