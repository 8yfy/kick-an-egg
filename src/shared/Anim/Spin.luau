--!strict
-- Partner A. Spins the "Orbit"/"Orbit2"/"Halo" joint groups of every model tagged "KTE_Spin"
-- (Models.egg/Models.pet tag rare models that have them). Client only, one loop for all models.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Rig = require(script.Parent.Rig)

local Spin = {}

local SPEEDS: { [string]: number } = { Orbit = 1.3, Orbit2 = -0.9, Halo = 0.6 } -- rad/s about Y
local TAG = "KTE_Spin"
local started = false

function Spin.start()
	if started or not RunService:IsClient() then
		return
	end
	started = true
	local motors: { [Model]: { Motor6D } } = {}
	local function track(inst: Instance)
		if not inst:IsA("Model") then
			return
		end
		local list = {}
		local root = inst.PrimaryPart
		if root then
			for _, m in root:GetChildren() do
				if m:IsA("Motor6D") and SPEEDS[m.Name] then
					table.insert(list, m)
				end
			end
		end
		motors[inst] = list
	end
	for _, inst in CollectionService:GetTagged(TAG) do
		track(inst)
	end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
		motors[inst :: Model] = nil
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for model, list in motors do
			if not model.Parent then
				motors[model] = nil
				continue
			end
			if not model:IsDescendantOf(workspace) then
				continue
			end
			for _, m in list do
				Rig.pose(m, CFrame.Angles(0, t * SPEEDS[m.Name], 0))
			end
		end
	end)
end

Spin.TAG = TAG

return Spin
