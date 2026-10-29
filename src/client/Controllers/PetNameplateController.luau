--!strict
-- A nameplate over every pet in the pens (PlotService models, Kind = "Pet"):
--   NAME            in its rarity colour (the most prominent line)
--   $12.5K/s        its REAL income per second: the server's own PlotService.petIncome (model attribute Income:
--                   size, weather, rebirths, gamepass and Index bonus already applied), refreshed when it changes
--   SNOWY           its weather mutation, only if it has one (model attribute Weather). Size mutations never show.
-- The plate sits just above the pet's real top (its bounding box at its real size, wings and horns included), is
-- sized in studs so it shrinks with distance, and hides past MaxDistance (further for your own pets). It stays
-- hidden while the pet's hatch reveal plays (RevealUntil) and pops in after it. No per-frame work: attribute
-- changes and the reveal's end drive every update.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)
local Format = require(Shared.Presentation.Format)

local UI = script.Parent.Parent:WaitForChild("UI")
local WorldText = require(UI:WaitForChild("World"):WaitForChild("WorldText"))
local WeatherLook = require(UI:WaitForChild("System"):WaitForChild("WeatherLook"))

local PetNameplateController = {}

local OWN_DISTANCE, OTHER_DISTANCE = 60, 34

local player = Players.LocalPlayer

type Plate = {
	model: Model,
	root: BasePart,
	gui: BillboardGui,
	income: TextLabel,
	pop: UIScale,
	conns: { RBXScriptConnection },
}

local plates: { [Model]: Plate } = {}

local function revealing(model: Model): boolean
	return (tonumber(model:GetAttribute("RevealUntil")) or 0) > os.clock()
end

-- The weather mutation to show (nil = none: no line at all). Only the pet's own, never the current event.
local function weatherOf(model: Model): string?
	local w = model:GetAttribute("Weather")
	return if typeof(w) == "string" and Mutations.Weather[w] then w else nil
end

local function incomeText(model: Model): string
	local n = tonumber(model:GetAttribute("Income")) or 0
	return Format.income(n)
end

-- Height of the plate above the root's centre: the pet's real top (its visible blocks only: invisible aura / area
-- parts stick out further) + a small gap.
local function place(plate: Plate)
	local rootY = plate.root.Position.Y
	local top = 0
	for _, d in plate.model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			local s, cf = d.Size / 2, d.CFrame
			local reach = math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z
			top = math.max(top, cf.Position.Y + reach - rootY)
		end
	end
	plate.gui.StudsOffsetWorldSpace = Vector3.new(0, top + plate.gui.Size.Y.Scale / 2 + 0.25, 0)
end

local function show(plate: Plate, animate: boolean)
	if revealing(plate.model) then
		plate.gui.Enabled = false
		return
	end
	place(plate)
	local was = plate.gui.Enabled
	plate.gui.Enabled = true
	if animate and not was and player:GetAttribute("ReducedMotion") ~= true then
		plate.pop.Scale = 0.55
		TweenService:Create(plate.pop, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
	end
end

local function untrack(model: Model)
	local plate = plates[model]
	if plate then
		plates[model] = nil
		for _, c in plate.conns do
			c:Disconnect()
		end
		plate.gui:Destroy()
	end
end

local function track(model: Model)
	if plates[model] or model:GetAttribute("Kind") ~= "Pet" then
		return
	end
	local root = model.PrimaryPart
	if not root then
		return
	end
	local weather = weatherOf(model)
	local rarity = model:GetAttribute("Rarity")
	local name = model:GetAttribute("PetName")
	local gui = Instance.new("BillboardGui")
	gui.Name = "PetNameplate"
	gui.Adornee = root
	gui.Size = UDim2.new(6, 0, if weather then 2 else 1.4, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = if model:GetAttribute("OwnerUserId") == player.UserId then OWN_DISTANCE else OTHER_DISTANCE
	gui.Enabled = false
	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.Parent = gui
	local pop = Instance.new("UIScale")
	pop.Parent = holder
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder
	local lines = if weather then 2.7 else 1.9
	local function line(order: number, height: number): Frame
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.Size = UDim2.fromScale(1, height / lines)
		f.LayoutOrder = order
		f.Parent = holder
		return f
	end
	WorldText.label(
		line(1, 1.0),
		"PetName",
		if typeof(name) == "string" then name else "Pet",
		WorldText.rarityPair(if typeof(rarity) == "string" then rarity else nil),
		44
	)
	local income = WorldText.label(line(2, 0.85), "Income", incomeText(model), WorldText.CASH, 36)
	if weather then
		local look = WeatherLook.get(weather)
		local pair = if #look.header >= 2 then { look.header[1], look.header[#look.header] } else WorldText.CASH
		WorldText.label(line(3, 0.75), "Weather", look.label, pair, 30)
	end
	gui.Parent = root
	local plate: Plate = { model = model, root = root, gui = gui, income = income, pop = pop, conns = {} }
	plates[model] = plate
	table.insert(
		plate.conns,
		model:GetAttributeChangedSignal("Income"):Connect(function()
			income.Text = incomeText(model)
		end)
	)
	table.insert(
		plate.conns,
		model:GetAttributeChangedSignal("RevealUntil"):Connect(function()
			if revealing(model) then
				gui.Enabled = false
			else
				show(plate, true)
			end
		end)
	)
	table.insert(
		plate.conns,
		model.AncestryChanged:Connect(function()
			if not model:IsDescendantOf(workspace) then
				untrack(model)
			end
		end)
	)
	-- a fresh hatch: its reveal sets RevealUntil right after it arrives, so look again in a moment
	task.delay(0.1, show, plate, false)
end

local function watchPlots(plots: Instance)
	for _, child in plots:GetChildren() do
		if child:IsA("Model") then
			task.defer(track, child)
		end
	end
	plots.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(track, child)
		end
	end)
end

function PetNameplateController:Start()
	task.spawn(function()
		local map = workspace:WaitForChild("Map", 60)
		local zone = map and map:WaitForChild("SafeZone", 30)
		local bases = zone and zone:WaitForChild("Bases", 30)
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
	end)
end

-- For tests / previews: what a pet's plate shows.
function PetNameplateController.plateOf(model: Model): { [string]: string }?
	local plate = plates[model]
	if not plate then
		return nil
	end
	local out: { [string]: string } = {}
	for _, d in plate.gui:GetDescendants() do
		if d:IsA("TextLabel") then
			out[d.Name] = d.Text
		end
	end
	return out
end

return PetNameplateController
