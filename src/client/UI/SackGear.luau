--!strict
-- Kick Sack gear without a HUD slot (the numbered SACK box is gone: no Tool UI in the HUD). SackService gives
-- every character a sack Tool; this takes it out / puts it away:
--   * the "Train" prompt on every base's sack stand (UI/Interact, action "EquipSack": E/F, tap, gamepad),
--   * key 1 on keyboards.
-- With the sack out, SackController turns clicks / taps into kicks; a small contextual hint says so (it only
-- shows while the sack is out). Roblox's own backpack hotbar stays hidden.
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Kit = require(script.Parent.Kit)

local SackGear = {}

-- The sack Tool and whether it is in hand.
function SackGear.tool(): (Tool?, boolean)
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

function SackGear.toggle()
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local tool, out = SackGear.tool()
	if not humanoid or not tool or humanoid.Health <= 0 then
		return
	end
	if out then
		humanoid:UnequipTools()
	else
		humanoid:EquipTool(tool)
	end
end

function SackGear.start(parent: Instance)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) -- no Tool UI anywhere in the HUD
	end)
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local hint = Kit.label({
		name = "SackHint",
		text = if touch then "Tap to kick the sack!" else "Click to kick the sack!  (1 to put it away)",
		size = UDim2.fromOffset(520, 34),
		position = UDim2.new(0.5, 0, 1, -40),
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
		if not processed and input.KeyCode == Enum.KeyCode.One then
			SackGear.toggle()
		end
	end)
end

return SackGear
