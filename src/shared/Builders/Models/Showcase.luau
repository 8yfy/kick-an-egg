--!strict
-- Dev tool: spawns every egg + pet of a zone side by side on a plinth, labelled, for quality review.
-- Studio command bar (edit mode or Play):
--   require(game.ReplicatedStorage.Shared.Builders.Models.Showcase).run(1)
local Models = require(script.Parent)
local Config = script.Parent.Parent.Parent.Config
local PetsConfig = require(Config.Pets)
local Rarities = require(Config.Rarities)

local Showcase = {}

local SPACING = 7
local ORIGIN = Vector3.new(0, 0, -60) -- behind the bases, clear of the map

local function label(model: Model, text: string, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 50)
	gui.StudsOffsetWorldSpace = Vector3.new(0, model:GetExtentsSize().Y + 1.5, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = model.PrimaryPart
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = t
	t.Parent = gui
	gui.Parent = model
end

local function countParts(model: Model): number
	local n = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "Root" then
			n += 1
		end
	end
	return n
end

function Showcase.run(zone: number?): Folder
	local z = zone or 1
	local old = workspace:FindFirstChild("ModelShowcase")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "ModelShowcase"

	local items: { { model: Model, text: string, color: Color3 } } = {}
	for _, p in PetsConfig do
		if p.zone == z then
			local color = Rarities[p.rarity].color
			table.insert(items, { model = Models.egg(p.model), text = p.name .. " Egg", color = color })
			table.insert(items, { model = Models.pet(p.model), text = `{p.name} ({p.rarity})`, color = color })
		end
	end

	local width = #items * SPACING + 4
	local plinth = Instance.new("Part")
	plinth.Name = "Plinth"
	plinth.Anchored = true
	plinth.Size = Vector3.new(width, 1, 12)
	plinth.CFrame = CFrame.new(ORIGIN + Vector3.new(0, 0.5, 0))
	plinth.Color = Color3.fromRGB(120, 210, 80)
	plinth.Material = Enum.Material.SmoothPlastic
	plinth.Parent = folder

	for i, item in items do
		local x = (i - (#items + 1) / 2) * SPACING
		item.model:PivotTo(CFrame.new(ORIGIN + Vector3.new(x, 1, 0)))
		label(item.model, item.text, item.color)
		item.model.Parent = folder
		print(`[Showcase] {item.model.Name}: {countParts(item.model)} parts, {item.model:GetExtentsSize()}`)
	end
	folder.Parent = workspace

	-- Frame the row from the front (models face -Z).
	local cam = workspace.CurrentCamera
	if cam then
		local focus = ORIGIN + Vector3.new(0, 3, 0)
		cam.CFrame = CFrame.lookAt(focus + Vector3.new(0, 7, -(width * 0.75 + 6)), focus)
	end
	return folder
end

return Showcase
