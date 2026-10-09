--!strict
-- CONTRACT (API). Partner A adds specs in Models/Eggs/*.luau and Models/Pets/*.luau,
-- one file per zone, e.g. Pets/Zone01.luau returning { [modelKey]: Spec }.
-- Missing keys fall back to a placeholder so Partner B is never blocked.
local CollectionService = game:GetService("CollectionService")
local Builder = require(script.Parent.BlockBuilder)
local Models = {}

local function placeholder(color: Color3, h: number): Builder.Spec
	return { parts = { { name = "Body", size = { 3, h, 3 }, pos = { 0, h / 2, 0 }, color = color } } }
end

local function collect(folder: Instance?): { [string]: Builder.Spec }
	local all = {}
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("ModuleScript") then
				for key, spec in require(m) :: any do
					all[key] = spec
				end
			end
		end
	end
	return all
end

local eggSpecs = collect(script:FindFirstChild("Eggs"))
local petSpecs = collect(script:FindFirstChild("Pets"))

-- Rare models with "Orbit"/"Orbit2"/"Halo" joint groups get a tag; Anim/Spin spins them on clients.
local SPIN_TAG = "KTE_Spin"
local function tagSpinners(model: Model): Model
	local root = model.PrimaryPart
	if root then
		for _, name in { "Orbit", "Orbit2", "Halo" } do
			if root:FindFirstChild(name) then
				CollectionService:AddTag(model, SPIN_TAG)
				break
			end
		end
	end
	return model
end

function Models.egg(key: string): Model
	return tagSpinners(Builder.build(eggSpecs[key] or placeholder(Color3.fromRGB(255, 220, 90), 4), key .. "Egg"))
end

function Models.pet(key: string): Model
	return tagSpinners(Builder.build(petSpecs[key] or placeholder(Color3.fromRGB(255, 0, 255), 3), key))
end

function Models.eggKeysForZone(petsConfig: { any }, zone: number): { string }
	local keys = {}
	for _, p in petsConfig do
		if p.zone == zone then
			table.insert(keys, p.model)
		end
	end
	return keys
end

return Models
