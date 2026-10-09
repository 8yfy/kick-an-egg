--!strict
-- Builds Partner A's map (workspace.Map) once when the server starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapService = {}

function MapService:Init()
	local builders = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Builders")
	local mapFolder = builders:FindFirstChild("Map")
	local module = mapFolder and mapFolder:FindFirstChild("MapBuilder")
	if not module or not module:IsA("ModuleScript") then
		warn("[MapService] MapBuilder not found; no map built")
		return
	end
	local started = os.clock()
	local MapBuilder = (require :: any)(module)
	MapBuilder.build()
	print(`[MapService] map built in {string.format("%.2f", os.clock() - started)} s`)
end

return MapService
