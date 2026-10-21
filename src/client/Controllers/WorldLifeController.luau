--!strict
-- Partner A (world remodel 2026-10-15). Starts the shared world ambience loop (VFX/Ambient): scrolling water
-- textures, particle distance culling + quality scaling, foliage sway and floating bob. Purely visual and local;
-- MapLifeController still owns Spin models and the merchants.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldLifeController = {}

function WorldLifeController:Init() end

function WorldLifeController:Start()
	local Ambient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX"):WaitForChild("Ambient")) :: any
	Ambient.start()
end

return WorldLifeController
