--!strict
-- Sound on/off (round button: top right on desktop, right edge on phones). Mutes the client-side SoundService.Master group;
-- every sound Partner A adds is parented to that group. Also sets LocalPlayer attribute "SoundOn". Shows the final
-- approved Sound icon ("hud_sound"), dimmed while muted, with a short pulse on every toggle.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Kit = require(script.Parent.Parent.Kit)
local Ui = require(script.Parent.Parent.System.Ui)
local IconMotion = require(script.Parent.Parent.System.IconMotion)

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
		if Players.LocalPlayer then
			Players.LocalPlayer:SetAttribute("SoundOn", on)
		end
		icon.ImageTransparency = if on then 0 else 0.6
		IconMotion.toggled(icon)
	end)
	icon = Ui.art(button, "hud_sound", UDim2.fromScale(0.86, 0.86))
	icon.Position = UDim2.fromScale(0.07, 0.07)
	icon.ZIndex = 3
	IconMotion.attach(icon, "sound")
	if Players.LocalPlayer then -- (none in Studio previews / headless tests)
		Players.LocalPlayer:SetAttribute("SoundOn", on)
	end
end

return SoundToggle
