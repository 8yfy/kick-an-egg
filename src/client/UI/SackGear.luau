--!strict
-- Kick Sack gear. SackService gives every player a sack Tool kept in Player.SackGear (outside the Backpack, so
-- Roblox's hotbar lists only your eggs and pets); this takes it out / puts it away through the server
-- (Remotes.EquipSack):
--   * the bottom Kick Sack quickslot (UI/Hud/SackSlot: click / tap),
--   * Q on keyboards (1-9 belong to the hotbar), Y on gamepads.
-- With the sack out, SackController turns clicks / taps into kicks; a small contextual hint says so (it only
-- shows while the sack is out). Roblox's own Backpack hotbar is on: eggs and pets are Tools there.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Kit = require(script.Parent.Kit)

local SackGear = {}

-- The sack Tool and whether it is in hand.
function SackGear.tool(): (Tool?, boolean)
	local player = Players.LocalPlayer
	if not player then
		return nil, false -- (Studio previews / headless tests)
	end
	local held = player.Character and player.Character:FindFirstChildOfClass("Tool")
	if held and held:GetAttribute("KickSack") then
		return held, true
	end
	for _, holder in { player:FindFirstChild("SackGear"), player:FindFirstChildOfClass("Backpack") } do
		for _, t in if holder then holder:GetChildren() else {} do
			if t:IsA("Tool") and t:GetAttribute("KickSack") then
				return t, false
			end
		end
	end
	return nil, false
end

local function remote(): RemoteEvent
	local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")) :: any
	return Remotes.get("EquipSack")
end

function SackGear.toggle()
	local me = Players.LocalPlayer
	local character = me and me.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local tool, out = SackGear.tool()
	if not humanoid or not tool or humanoid.Health <= 0 then
		return
	end
	remote():FireServer(not out) -- the server holds the sack (Player.SackGear) and hands it over
end

function SackGear.start(parent: Instance)
	pcall(function()
		-- Roblox's own hotbar is replaced by the custom one (UI/Hud/Hotbar + UI/Screens/Bag): eggs and stored pets
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local hint = Kit.label({
		name = "SackHint",
		text = if touch then "Tap to kick the sack!" else "Click to kick the sack!  (Q to put it away)",
		size = UDim2.fromOffset(520, 34),
		position = UDim2.new(0.5, 0, 1, -150), -- above the quickslot
		anchor = Vector2.new(0.5, 1),
		parent = parent,
		color = Color3.fromRGB(135, 245, 70),
		stroke = 3,
	})
	Kit.autoScale(hint)
	hint.Visible = false
	local stopPulse: (() -> ())? = nil
	local function refresh()
		local _, out = SackGear.tool()
		if out == hint.Visible then
			return
		end
		hint.Visible = out
		if out then
			Kit.pop(hint, 0.25)
			stopPulse = Kit.pulse(hint, 1.06)
		elseif stopPulse then
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
		if not processed and (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonY) then
			SackGear.toggle()
		end
	end)
end

return SackGear
