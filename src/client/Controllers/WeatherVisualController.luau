--!strict
-- Partner A (weather overhaul 2026-10-17). Starts the weather visuals (Shared/VFX/WeatherFx): it listens to the
-- server's WeatherChanged, works out the one weather affecting this player (local storm over global) and crossfades
-- the world look, lighting and ambience. Purely visual and local: the schedule, odds and rewards stay WeatherService's.
-- The HUD widget, start toast and the Studio dev preview read the same WeatherFx.State (UI/Hud/WeatherWidget,
-- UI/Hud/WeatherToast, UI/Dev/WeatherPreview).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeatherVisualController = {}

function WeatherVisualController:Init() end

function WeatherVisualController:Start()
	local WeatherFx =
		require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"):WaitForChild("WeatherFx")) :: any
	WeatherFx.start()
end

return WeatherVisualController
