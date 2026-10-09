--!strict
-- Flat cartoon UI icons designed in Figma ("Kick the Egg — UI Icons", source PNGs in assets/ui-icons)
-- and uploaded to Roblox. Icons.view(parent, name, size?) -> ImageLabel.
-- Icons.rack(parent, tier) renders a live 3D preview of a training station (Shop only).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IDS: { [string]: string } = {
	Book = "rbxassetid://94821788169433",
	Cart = "rbxassetid://87731851786628",
	Rebirth = "rbxassetid://86367013289364",
	Trade = "rbxassetid://127508912627543",
	Gear = "rbxassetid://117181078576708",
	Cash = "rbxassetid://121833459541106",
	Boot = "rbxassetid://76846640911342",
	Bolt = "rbxassetid://135208817381331",
	Egg = "rbxassetid://137658338811044",
	Paw = "rbxassetid://123408591131262",
}
IDS.Chest = IDS.Cart -- old name

local Icons = {}

function Icons.view(parent: Instance, name: string, size: UDim2?): ImageLabel
	local img = Instance.new("ImageLabel")
	img.Name = name .. "Icon"
	img.BackgroundTransparency = 1
	img.Size = size or UDim2.fromScale(1, 1)
	img.Image = IDS[name] or ""
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = parent
	return img
end

function Icons.rack(parent: Instance, tier: string, size: UDim2?): ViewportFrame
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Builder = require(Shared:WaitForChild("Builders"):WaitForChild("BlockBuilder")) :: any
	local TrainingRack = require((Shared :: any).Builders.Map.TrainingRack) :: any
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Rack" .. tier
	vp.BackgroundTransparency = 1
	vp.Size = size or UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(200, 200, 205)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.8)
	local model = Builder.build(TrainingRack.spec(tier), "Rack")
	model:PivotTo(CFrame.new())
	model.Parent = vp
	local cf, sz = model:GetBoundingBox()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	local dist = sz.Magnitude / 2 / math.tan(math.rad(15)) * 1.05
	cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.55, dist * 0.3, -dist * 0.8), cf.Position)
	cam.Parent = vp
	vp.CurrentCamera = cam
	vp.Parent = parent
	return vp
end

return Icons
