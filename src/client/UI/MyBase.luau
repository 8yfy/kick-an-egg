--!strict
-- The local player's base: Base<player.BaseIndex> (PlotService), else the base whose OwnerUserId is ours. Levels fall back to data.rackLevel / data.penLevel, then 1.
local Players = game:GetService("Players")

local MyBase = {}

function MyBase.get(): Model?
	local map = workspace:FindFirstChild("Map")
	local zone = map and map:FindFirstChild("SafeZone")
	local bases = zone and zone:FindFirstChild("Bases")
	if not bases then
		return nil
	end
	local index = Players.LocalPlayer:GetAttribute("BaseIndex") -- set by PlotService on join
	if typeof(index) == "number" then
		local b = bases:FindFirstChild(`Base{index}`)
		if b and b:IsA("Model") then
			return b
		end
	end
	local me = Players.LocalPlayer.UserId
	for _, b in bases:GetChildren() do
		if b:IsA("Model") and b:GetAttribute("OwnerUserId") == me then
			return b
		end
	end
	return nil
end

function MyBase.level(attr: string, data: { [string]: any }, dataKey: string): number
	local base = MyBase.get()
	local v = base and base:GetAttribute(attr)
	if typeof(v) == "number" then
		return v
	end
	local d = data[dataKey]
	return if typeof(d) == "number" then d else 1
end

return MyBase
