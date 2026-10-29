--!strict
-- Placing what you hold in your pen (client side of PlotService's Backpack tools, PlaceEgg / PlacePet):
--   While you hold an egg Tool (attribute EggUid) or a stored pet's Tool (PetUid) from the hotbar, a ghost of it
--   follows where you aim on your pen's floor: GREEN = valid, RED = not (outside your pen, an egg too close to
--   another egg, pen full). Mouse: aim with the cursor, click to place. Touch: tap a spot. Gamepad: aim with the
--   screen centre, R2 to place (Tool.Activated covers all three). The server re-checks everything (ownership,
--   the held item, reach, bounds, spacing, capacity).
-- A short hint under the screen centre says what to do (or to walk to your pen first).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Upgrades = require(Shared.Config.Upgrades)
local Models = require(Shared.Builders.Models)
local EggSize = require(Shared.Presentation.EggSize)
local Remotes = require(Shared.Remotes)
local Audio = require(Shared.Audio)

local PEN_MARGIN = 3.5 -- = PlotService
local EGG_SPACING = 4 -- = PlotService
local RAY_LENGTH = 400
local VALID = Color3.fromRGB(80, 255, 120)
local INVALID = Color3.fromRGB(255, 70, 70)

local PlacementController = {}

local player = Players.LocalPlayer
local data: { [string]: any } = {}
local ghost: Model? = nil
local highlight: Highlight? = nil
local hint: TextLabel? = nil
local held: Tool? = nil
local aimPos: Vector3? = nil
local valid = false
local lastTouch: Vector2? = nil
local conns: { RBXScriptConnection } = {}

local function myBase(): Model?
	local index = player:GetAttribute("BaseIndex")
	local map = workspace:FindFirstChild("Map")
	local safeZone = map and map:FindFirstChild("SafeZone")
	local bases = safeZone and safeZone:FindFirstChild("Bases")
	local base = if bases and typeof(index) == "number" then bases:FindFirstChild(`Base{index}`) else nil
	return if base and base:IsA("Model") then base else nil
end

local function used(): number
	local n = 0
	for _ in data.plots or {} do
		n += 1
	end
	for _, pet in data.pets or {} do
		if typeof(pet) == "table" and pet.placed then
			n += 1
		end
	end
	return n
end

local function capacity(): number
	local level = if typeof(data.penLevel) == "number" then data.penLevel else 1
	return math.clamp(Economy.PlotSlots.base + (level - 1) * Upgrades.Pen.slotsPerLevel, 1, Economy.PlotSlots.max)
end

local function kindOf(tool: Tool?): ("Egg" | "Pet")?
	if tool and typeof(tool:GetAttribute("EggUid")) == "string" then
		return "Egg"
	elseif tool and typeof(tool:GetAttribute("PetUid")) == "string" then
		return "Pet"
	end
	return nil
end

-- The held egg's size key (nil for none / a pet).
local function heldSize(): string?
	local s = held and held:GetAttribute("EggSize")
	return if typeof(s) == "string" and s ~= "" then s else nil
end

-- Why `pos` is not a valid spot (nil = valid): the same rules as PlotService.eggSpotProblem (eggs keep room for the
-- size they grow to, from the fence and from each other).
local function problem(area: BasePart, pos: Vector3, kind: "Egg" | "Pet"): string?
	local p = area.CFrame:PointToObjectSpace(pos)
	local hx, hz = area.Size.X / 2 - PEN_MARGIN, area.Size.Z / 2 - PEN_MARGIN
	if math.abs(p.X) > hx or math.abs(p.Z) > hz then
		return "Outside your pen"
	end
	if kind == "Egg" then
		local radius = EggSize.radius(heldSize())
		local edge = math.max(0, radius + 0.5 - PEN_MARGIN)
		if math.abs(p.X) > hx - edge or math.abs(p.Z) > hz - edge then
			return "Too close to the fence for an egg this big"
		end
		for _, egg in data.plots or {} do
			if typeof(egg) == "table" and typeof(egg.x) == "number" and typeof(egg.z) == "number" then
				local need = math.max(EGG_SPACING, radius + EggSize.radius(egg.size))
				if (Vector2.new(egg.x, egg.z) - Vector2.new(p.X, p.Z)).Magnitude < need then
					return "Too close to another egg"
				end
			end
		end
	end
	if used() >= capacity() then
		return "Your pen is full: upgrade it or pick up a pet"
	end
	return nil
end

local function setHint(text: string?, color: Color3?)
	local label = hint
	if not label then
		return
	end
	label.Visible = text ~= nil
	label.Text = text or ""
	label.TextColor3 = color or Color3.new(1, 1, 1)
end

local function screenPoint(): Vector2
	if UserInputService.TouchEnabled and lastTouch then
		return lastTouch
	end
	if UserInputService.GamepadEnabled and not UserInputService.MouseEnabled then
		local vp = workspace.CurrentCamera.ViewportSize
		return Vector2.new(vp.X / 2, vp.Y / 2)
	end
	return UserInputService:GetMouseLocation()
end

-- Where the aim at screen `point` meets your pen's floor (nil if it doesn't). The floor tiles live in the pen's
-- rebuilt "Pen" folder (MapBuilder.buildPen); older maps had them straight under the base.
local function aim(base: Model, point: Vector2): Vector3?
	local cam = workspace.CurrentCamera
	local ray = cam:ViewportPointToRay(point.X, point.Y)
	local floors: { Instance } = {}
	local holders: { Instance } = { base }
	local pen = base:FindFirstChild("Pen")
	if pen then
		table.insert(holders, pen)
	end
	for _, holder in holders do
		for _, child in holder:GetChildren() do
			if child:IsA("BasePart") and child.Name == "Floor" then
				table.insert(floors, child)
			end
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = floors
	local hit = workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, params)
	return hit and hit.Position
end

local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	highlight = nil
	aimPos = nil
	setHint(nil)
end

local function makeGhost(tool: Tool)
	clearGhost()
	local key = tool:GetAttribute("ModelKey")
	local ok, model =
		pcall(if kindOf(tool) == "Pet" then Models.pet else Models.egg, if typeof(key) == "string" then key else "")
	if not ok or not model then
		return
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
			d.Transparency = math.max(d.Transparency, 0.45)
		end
	end
	model.Name = if kindOf(tool) == "Pet" then "PetGhost" else "EggGhost"
	if kindOf(tool) == "Egg" then -- the ghost shows the size this egg grows to (its room in the pen)
		local size = tool:GetAttribute("EggSize")
		local m = model :: any
		m:ScaleTo(m:GetScale() * EggSize.visual(if typeof(size) == "string" and size ~= "" then size else nil))
	end
	local h = Instance.new("Highlight")
	h.FillTransparency = 0.55
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	highlight = h
	model.Parent = workspace
	ghost = model :: Model
end

local function update()
	local tool = held
	local base = myBase()
	local area = base and base:FindFirstChild("PenArea")
	if not tool or not ghost or not base or not area or not area:IsA("BasePart") then
		return
	end
	local pos = aim(base, screenPoint())
	if not pos then
		aimPos = nil
		valid = false
		ghost:PivotTo(CFrame.new(0, -500, 0))
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
		setHint(
			if touch then "Walk to your pen, then tap a spot to place it" else "Walk to your pen and aim at its floor",
			Color3.new(1, 1, 1)
		)
		return
	end
	aimPos = pos
	local kind: "Egg" | "Pet" = kindOf(tool) or "Egg"
	local thing = if kind == "Pet" then "pet" else "egg"
	local why = problem(area, pos, kind)
	valid = why == nil
	ghost:PivotTo(CFrame.lookAt(pos, pos + area.CFrame.LookVector))
	if highlight then
		highlight.FillColor = if valid then VALID else INVALID
		highlight.OutlineColor = if valid then VALID else INVALID
	end
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local pad = UserInputService.GamepadEnabled and not UserInputService.MouseEnabled
	setHint(
		why
			or (
				if touch
					then `Tap to place your {thing}`
					elseif pad then `R2 to place your {thing}`
					else `Click to place your {thing}`
			),
		if valid then VALID else INVALID
	)
end

-- What a click at screen `point` would do with the held item: the floor spot it aims at (nil = misses your pen's
-- floor) and why it would be refused (nil = valid). Used by tools/playtest to drive the real aim path.
function PlacementController.preview(point: Vector2): (Vector3?, string?)
	local base = myBase()
	local area = base and base:FindFirstChild("PenArea")
	if not base or not area or not area:IsA("BasePart") then
		return nil, "No pen"
	end
	local pos = aim(base, point)
	if not pos then
		return nil, "Not on your pen's floor"
	end
	return pos, problem(area, pos, kindOf(held) or "Egg")
end

local function onActivated()
	local tool = held
	local kind = kindOf(tool)
	local uid = tool and tool:GetAttribute(if kind == "Pet" then "PetUid" else "EggUid")
	if not kind or typeof(uid) ~= "string" then
		return
	end
	update() -- a tap moves the aim first
	if valid and aimPos then
		Remotes.get(if kind == "Pet" then "PlacePet" else "PlaceEgg"):FireServer(uid, aimPos)
	end
end

local function hold(tool: Tool?)
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	held = tool
	if not tool then
		clearGhost()
		return
	end
	makeGhost(tool)
	-- at the character: on the frame the tool is equipped its Handle hasn't reached the hand yet (it can still be at the
	-- tool's spawn spot, far from the camera in the five-pen hub, and the sound would be culled)
	local holder = tool.Parent
	local root = holder and holder:FindFirstChild("HumanoidRootPart")
	Audio.play("EggHold", root or tool:FindFirstChild("Handle") or holder)
	table.insert(conns, tool.Activated:Connect(onActivated))
end

local function watchCharacter(character: Model)
	local function refresh()
		local tool = character:FindFirstChildOfClass("Tool")
		local item = if kindOf(tool) then tool else nil
		if item ~= held then
			hold(item)
		end
	end
	character.ChildAdded:Connect(refresh)
	character.ChildRemoved:Connect(refresh)
	refresh()
end

-- The hint label lives in the HUD (built here so the controller works without the UI too).
local function makeHint()
	local gui = Instance.new("ScreenGui")
	gui.Name = "EggPlacement"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	local label = Instance.new("TextLabel")
	label.Name = "Hint"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -190)
	label.Size = UDim2.fromOffset(560, 36)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Visible = false
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(20, 24, 40)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
	hint = label
end

function PlacementController:Start()
	Remotes.get("DataChanged").OnClientEvent:Connect(function(partial: { [string]: any })
		for k, v in partial do
			data[k] = v
		end
	end)
	task.spawn(makeHint)
	UserInputService.TouchStarted:Connect(function(input)
		lastTouch = Vector2.new(input.Position.X, input.Position.Y)
	end)
	UserInputService.TouchMoved:Connect(function(input)
		lastTouch = Vector2.new(input.Position.X, input.Position.Y)
	end)
	player.CharacterAdded:Connect(function(character)
		hold(nil)
		watchCharacter(character)
	end)
	if player.Character then
		watchCharacter(player.Character)
	end
	RunService.RenderStepped:Connect(function()
		if held then
			update()
		end
	end)
end

return PlacementController
