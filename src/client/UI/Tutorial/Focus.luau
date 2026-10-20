--!strict
-- Temporarily hide distractions without destroying HUD state or fighting its visibility updates.
-- Contextual controls (hotbar, kicking, chase, placement and touch movement) keep working normally.
local Focus = {}
local HIDDEN = {
	LeftRail = true,
	RightRail = true,
	DrawerHost = true,
	SettingsButton = true,
	SoundToggle = true,
	WeatherWidget = true,
	WeatherDev = true,
	Counters = true,
}

function Focus.new()
	local wrapped: { [GuiObject]: { parent: Instance, mask: CanvasGroup } } = {}
	local api = {}
	function api:restore()
		for object, saved in wrapped do
			if object.Parent == saved.mask and saved.parent.Parent then
				object.Parent = saved.parent
			end
			saved.mask:Destroy()
		end
		table.clear(wrapped)
	end
	function api:update(hud: Instance?, active: boolean, income: boolean)
		if not active or not hud then
			self:restore()
			return
		end
		for object, saved in wrapped do
			if not object:IsDescendantOf(hud) or (income and object.Name == "Counters") then
				if object.Parent == saved.mask and saved.parent.Parent then
					object.Parent = saved.parent
				end
				saved.mask:Destroy()
				wrapped[object] = nil
			end
		end
		for name in HIDDEN do
			if income and name == "Counters" then
				continue
			end
			local object = hud:FindFirstChild(name, true)
			if object and object:IsA("GuiObject") and not wrapped[object] and object.Parent then
				local mask = Instance.new("CanvasGroup")
				mask.Name, mask.Size = "TutorialHidden" .. name, UDim2.fromScale(1, 1)
				mask.BackgroundTransparency, mask.GroupTransparency = 1, 1
				mask.Interactable, mask.Active = false, false
				mask.Visible = false
				local parent = object.Parent
				mask.Parent, object.Parent = parent, mask
				wrapped[object] = { parent = parent, mask = mask }
			end
		end
	end
	api.destroy = api.restore
	return api
end

return Focus
