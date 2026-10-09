--!strict
-- Decorates the replicated plot models (PlotService) with A's VFX/Anim: eggs wobble and crack
-- toward HatchAt, freshly hatched pets burst + reveal, pets idle and wear their weather overlay.
-- MoneyPop on income. Studio only: press P to place your next egg on the first free pedestal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Mutations = require(Shared.Config.Mutations)
local VFX = require(Shared.VFX)
local Anim = require(Shared.Anim)
local Remotes = require(Shared.Remotes)

local CRACK_STEPS = 10 -- HatchCrack fires each time progress crosses a tenth
local REVEAL_WINDOW = 5 -- seconds after HatchedAt during which a new pet plays its reveal

local PlotController = {}

local player = Players.LocalPlayer
local data: { [string]: any } = {}
local tracked: { [Model]: { () -> () } } = {}

local function untrack(model: Model)
	local stops = tracked[model]
	if stops then
		tracked[model] = nil
		for _, stop in stops do
			stop()
		end
	end
end

local function trackEgg(egg: Model)
	local stops = { Anim.play(egg, "EggWobble") }
	tracked[egg] = stops
	local lastStep = -1
	local connection = RunService.Heartbeat:Connect(function()
		local placedAt = egg:GetAttribute("PlacedAt")
		local hatchAt = egg:GetAttribute("HatchAt")
		if typeof(placedAt) ~= "number" or typeof(hatchAt) ~= "number" or hatchAt <= placedAt then
			return
		end
		local progress = math.clamp((workspace:GetServerTimeNow() - placedAt) / (hatchAt - placedAt), 0, 1)
		local step = math.floor(progress * CRACK_STEPS)
		if step ~= lastStep then
			lastStep = step
			VFX.play("HatchCrack", egg, { progress = progress })
		end
	end)
	table.insert(stops, function()
		connection:Disconnect()
	end)
end

local function trackPet(pet: Model)
	local rarity = pet:GetAttribute("Rarity")
	local hatchedAt = pet:GetAttribute("HatchedAt")
	if typeof(hatchedAt) == "number" and workspace:GetServerTimeNow() - hatchedAt < REVEAL_WINDOW then
		VFX.play("HatchBurst", pet, { rarity = rarity })
		VFX.play("PetReveal", pet, { rarity = rarity, name = pet:GetAttribute("PetName") })
	end
	local stops = { Anim.play(pet, "Idle") }
	local weather = pet:GetAttribute("Weather")
	local mutation = if typeof(weather) == "string" then Mutations.Weather[weather] else nil
	if mutation then
		table.insert(stops, VFX.attach(mutation.vfx, pet))
	end
	tracked[pet] = stops
end

local function onPlotChild(child: Instance)
	if not child:IsA("Model") or tracked[child] then
		return
	end
	local kind = child:GetAttribute("Kind")
	if kind == "Egg" then
		trackEgg(child)
	elseif kind == "Pet" then
		trackPet(child)
	else
		return
	end
	child.AncestryChanged:Connect(function()
		if not child:IsDescendantOf(workspace) then
			untrack(child)
		end
	end)
end

local function watchPlots(plots: Instance)
	for _, child in plots:GetChildren() do
		task.spawn(onPlotChild, child)
	end
	plots.ChildAdded:Connect(function(child)
		-- Attributes replicate with the model; defer so children are in place too.
		task.defer(onPlotChild, child)
	end)
end

local function watchBases()
	local map = workspace:WaitForChild("Map", 60)
	local safeZone = map and map:WaitForChild("SafeZone", 30)
	local bases = safeZone and safeZone:WaitForChild("Bases", 30)
	if not bases then
		return
	end
	local function watchBase(base: Instance)
		task.spawn(function()
			local plots = base:WaitForChild("Plots", math.huge)
			if plots then
				watchPlots(plots)
			end
		end)
	end
	for _, base in bases:GetChildren() do
		watchBase(base)
	end
	bases.ChildAdded:Connect(watchBase)
end

local function myBase(): Instance?
	local index = player:GetAttribute("BaseIndex")
	local map = workspace:FindFirstChild("Map")
	local safeZone = map and map:FindFirstChild("SafeZone")
	local bases = safeZone and safeZone:FindFirstChild("Bases")
	return if bases and typeof(index) == "number" then bases:FindFirstChild(`Base{index}`) else nil
end

local function placeNextEgg()
	local eggs = data.eggs
	if typeof(eggs) ~= "table" or #eggs == 0 then
		print("[PlotController] no eggs in inventory")
		return
	end
	local taken: { [number]: boolean } = {}
	for key in data.plots or {} do
		taken[tonumber(key) :: number] = true
	end
	for _, pet in data.pets or {} do
		if pet.slot then
			taken[pet.slot] = true
		end
	end
	for slot = 1, data.plotSlots or Economy.PlotSlots.base do
		if not taken[slot] then
			Remotes.get("PlaceEgg"):FireServer(eggs[1].uid, slot)
			return
		end
	end
	print("[PlotController] all pedestals are full")
end

function PlotController:Start()
	Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
		local before = data.money
		for k, v in partial do
			data[k] = v
		end
		if typeof(before) == "number" and typeof(partial.money) == "number" and partial.money > before then
			local base = myBase()
			if base then
				VFX.play("MoneyPop", base, { amount = partial.money - before })
			end
		end
	end)

	task.spawn(watchBases)

	if RunService:IsStudio() then
		UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == Enum.KeyCode.P then
				placeNextEgg()
			end
		end)
	end
end

return PlotController
