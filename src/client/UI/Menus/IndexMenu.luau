--!strict
-- Index: every pet in Config/Pets grouped by zone. Discovered pets show a live 3D preview
-- (ViewportFrame built lazily the first time the card is shown); undiscovered ones are "?".
-- Discovered = data.index[petId] (if B provides it) or any pet with that petId in data.pets.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Kit = require(script.Parent.Parent.Kit)
local Window = require(script.Parent.Window)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetsConfig = require(Shared:WaitForChild("Config"):WaitForChild("Pets"))
local Rarities = require(Shared:WaitForChild("Config"):WaitForChild("Rarities"))
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))

export type Menu = { window: Window.Window, update: (data: { [string]: any }) -> () }

local IndexMenu = {}

local CARD = Vector2.new(150, 190)

local function discoveredSet(data: { [string]: any }): { [string]: boolean }
	local set = {}
	if typeof(data.index) == "table" then
		for id, v in data.index do
			if v then
				set[tostring(id)] = true
			end
		end
	end
	if typeof(data.pets) == "table" then
		for _, p in data.pets do
			if typeof(p) == "table" and p.petId then
				set[tostring(p.petId)] = true
			end
		end
	end
	return set
end

local function preview(card: Frame, modelKey: string)
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Preview"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.new(1, -16, 0, 120)
	vp.Position = UDim2.fromOffset(8, 8)
	vp.Ambient = Color3.fromRGB(170, 170, 180)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.Parent = card
	local Models = require(Shared:WaitForChild("Builders"):WaitForChild("Models")) :: any
	local model: Model = Models.pet(modelKey)
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local cam = Instance.new("Camera")
	local cf, size = model:GetBoundingBox()
	local radius = size.Magnitude / 2
	cam.FieldOfView = 40
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(radius * 0.9, radius * 0.6, -radius * 2.4), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
end

function IndexMenu.new(parent: Instance): Menu
	local window = Window.new(parent, "Index", Kit.Colors.purple)
	local body = window.body

	local counter = Kit.label({
		name = "Counter",
		text = "0 / 0 discovered",
		size = UDim2.new(1, -20, 0, 34),
		position = UDim2.fromOffset(10, 0),
		parent = body,
		align = Enum.TextXAlignment.Right,
	})
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, 40)
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.ScrollBarThickness = 10
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = body
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 14)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	type Card = { frame: Frame, pet: any, built: boolean, question: TextLabel }
	local cards: { Card } = {}
	for zi, zone in Zones do
		local section = Instance.new("Frame")
		section.Name = "Zone" .. zi
		section.BackgroundTransparency = 1
		section.Size = UDim2.new(1, -14, 0, 0)
		section.AutomaticSize = Enum.AutomaticSize.Y
		section.LayoutOrder = zi
		section.Parent = scroll
		local header = Kit.label({
			name = "Header",
			text = `ZONE {zi} · {string.upper(zone.name)}`,
			size = UDim2.new(1, 0, 0, 30),
			parent = section,
			align = Enum.TextXAlignment.Left,
			color = zone.accent:Lerp(Color3.new(1, 1, 1), 0.3),
		})
		header.LayoutOrder = 0
		local grid = Instance.new("Frame")
		grid.Name = "Grid"
		grid.BackgroundTransparency = 1
		grid.Position = UDim2.fromOffset(0, 36)
		grid.Size = UDim2.new(1, 0, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y
		grid.Parent = section
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.fromOffset(CARD.X, CARD.Y)
		layout.CellPadding = UDim2.fromOffset(12, 12)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid
		for i, pet in PetsConfig do
			if pet.zone == zi then
				local rarity = Rarities[pet.rarity] or Rarities.Common
				local card = Kit.panel({
					name = pet.id,
					size = UDim2.fromOffset(CARD.X, CARD.Y),
					parent = grid,
					colors = { Color3.fromRGB(60, 55, 80), Color3.fromRGB(40, 36, 56) },
					radius = 16,
				})
				card.LayoutOrder = rarity.order * 100 + i
				local stroke = card:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = rarity.color
					stroke.Thickness = 4
				end
				local question = Kit.label({
					name = "Unknown",
					text = "?",
					size = UDim2.new(1, -16, 0, 110),
					position = UDim2.fromOffset(8, 12),
					parent = card,
					color = Color3.fromRGB(120, 115, 140),
				})
				Kit.label({
					name = "Name",
					text = pet.name,
					size = UDim2.new(1, -12, 0, 26),
					position = UDim2.new(0, 6, 1, -58),
					parent = card,
					stroke = 2,
				})
				Kit.label({
					name = "Rarity",
					text = string.upper(pet.rarity),
					size = UDim2.new(1, -12, 0, 22),
					position = UDim2.new(0, 6, 1, -30),
					parent = card,
					color = rarity.color,
					stroke = 2,
				})
				table.insert(cards, { frame = card, pet = pet, built = false, question = question })
			end
		end
	end

	local known: { [string]: boolean } = {}
	local function refresh()
		local n = 0
		for _, c in cards do
			local found = known[c.pet.id] == true
			if found then
				n += 1
			end
			c.question.Visible = not found
			if found and not c.built and window.isOpen() then
				c.built = true
				preview(c.frame, c.pet.model)
			end
		end
		counter.Text = `{n} / {#cards} discovered`
	end
	window.onOpen(refresh)

	return {
		window = window,
		update = function(data: { [string]: any })
			known = discoveredSet(data)
			refresh()
		end,
	}
end

return IndexMenu
