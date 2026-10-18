--!strict
-- Local world labels above the two hub shops. Existing storefront signs/prompts stay intact.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ShopLabelController = {}
local MAX_DISTANCE = 150
local BINDING = "KickTheEggShopLabels"
type Spec = { name: string, text: string, width: number, tint: Color3 }
type Display = { model: Model, sign: BasePart, gui: BillboardGui, height: number }
local SHOPS: { Spec } = {
	{ name = "BoxingSackShop", text = "SACK SHOP", width = 24, tint = Color3.fromRGB(255, 204, 73) },
	{ name = "PetSellingStand", text = "SELL PETS", width = 20, tint = Color3.fromRGB(105, 255, 204) },
}
local displays: { [Model]: Display } = {}
local started = false

local function raiseAboveRoof(display: Display)
	local top = display.sign.Position.Y
	for _, part in display.model:GetDescendants() do
		if part:IsA("BasePart") then
			local cf, size = part.CFrame, part.Size
			local extent = (
				math.abs(cf.RightVector.Y) * size.X
				+ math.abs(cf.UpVector.Y) * size.Y
				+ math.abs(cf.LookVector.Y) * size.Z
			) / 2
			top = math.max(top, part.Position.Y + extent)
		end
	end
	-- Streaming can deliver the roof after its sign. Only raise it as more geometry arrives.
	display.height = math.max(display.height, top - display.sign.Position.Y + 4)
	display.gui.StudsOffsetWorldSpace = Vector3.new(0, display.height, 0)
end

local function build(model: Model, sign: BasePart, spec: Spec): Display
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShopFloatingLabel"
	gui.Adornee = sign
	gui.Size = UDim2.fromScale(spec.width, 4)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false -- buildings/terrain naturally occlude the text
	gui.MaxDistance = MAX_DISTANCE
	gui.Enabled = false
	gui.ResetOnSpawn = false
	local text = Instance.new("TextLabel")
	text.Name = "Title"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.Text = spec.text
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 245), spec.tint)
	gradient.Rotation = 90
	gradient.Parent = text
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(29, 24, 38)
	stroke.Thickness = 2.5
	stroke.Parent = text
	gui.Parent = sign
	local display = { model = model, sign = sign, gui = gui, height = 0 }
	raiseAboveRoof(display)
	return display
end

local function discover()
	local map = workspace:FindFirstChild("Map")
	local zone = map and map:FindFirstChild("SafeZone")
	if not zone then
		return
	end
	for _, spec in SHOPS do
		local model = zone:FindFirstChild(spec.name)
		local sign = model and model:FindFirstChild("Sign")
		if model and model:IsA("Model") and sign and sign:IsA("BasePart") then
			if not displays[model] then
				displays[model] = build(model, sign, spec)
			else
				raiseAboveRoof(displays[model])
			end
		end
	end
end

function ShopLabelController:Start()
	if started then
		return
	end
	started = true
	local elapsed = 0.5
	RunService:BindToRenderStep(BINDING, Enum.RenderPriority.Camera.Value + 4, function(dt)
		for model, display in displays do
			if not model:IsDescendantOf(workspace) or not display.sign.Parent or not display.gui.Parent then
				display.gui:Destroy()
				displays[model] = nil
			end
		end
		elapsed += dt
		if elapsed >= 0.5 then
			elapsed = 0
			discover()
		end
		local camera = workspace.CurrentCamera
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for _, display in displays do
			local visible = false
			if camera and root and root:IsA("BasePart") then
				local anchor = display.sign.Position + Vector3.new(0, display.height, 0)
				if
					(root.Position - display.sign.Position).Magnitude <= MAX_DISTANCE
					and (camera.CFrame.Position - anchor).Magnitude <= MAX_DISTANCE
				then
					local shopPoint, shopInView = camera:WorldToViewportPoint(display.sign.Position)
					local titlePoint, titleInView = camera:WorldToViewportPoint(anchor)
					visible = shopInView and titleInView and shopPoint.Z > 0 and titlePoint.Z > 0
				end
			end
			display.gui.Enabled = visible
		end
	end)
end

function ShopLabelController:Destroy()
	RunService:UnbindFromRenderStep(BINDING)
	for model, display in displays do
		display.gui:Destroy()
		displays[model] = nil
	end
	started = false
end

return ShopLabelController
