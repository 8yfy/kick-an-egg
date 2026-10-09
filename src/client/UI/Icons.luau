--!strict
-- Cartoon UI icons (512 px transparent PNGs from the "Flex A Pet" icon pack, sources in assets/ui-icons)
-- uploaded to Roblox. Icons.glow(parent) adds the soft glow used behind featured icons. Icons.view(parent, name, size?) -> ImageLabel.
-- Icons.rack(parent, tier) renders a live 3D preview of a training station (Shop only).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IDS: { [string]: string } = {
	Shop = "rbxassetid://132910564494130",
	Index = "rbxassetid://126256569858051",
	Rebirth = "rbxassetid://113623474106175",
	Trade = "rbxassetid://109855075288503",
	Settings = "rbxassetid://95627212951225",
	Coins = "rbxassetid://75117087575516",
	WalkSpeed = "rbxassetid://101868527178776",
	Power = "rbxassetid://71794317489960",
	PetSlots = "rbxassetid://140466692425935",
	Pets = "rbxassetid://113010957021814",
	Hatch = "rbxassetid://115696461322982",
	Sound = "rbxassetid://92360072113067",
	Close = "rbxassetid://118401516062764",
	CoinBoost = "rbxassetid://70443158948695",
	Gamepasses = "rbxassetid://105143391724931",
	Luck = "rbxassetid://78520637349210",
	Quests = "rbxassetid://105409041159249",
	New = "rbxassetid://92832610420901",
	Glow = "rbxassetid://79458319600739",
}
-- older names used around the UI
IDS.Cart, IDS.Chest, IDS.Book, IDS.Gear = IDS.Shop, IDS.Shop, IDS.Index, IDS.Settings
IDS.Cash, IDS.Boot, IDS.Bolt, IDS.Egg, IDS.Paw = IDS.Coins, IDS.WalkSpeed, IDS.Power, IDS.PetSlots, IDS.Pets

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

function Icons.glow(parent: Instance, size: UDim2?): ImageLabel
	local img = Icons.view(parent, "Glow", size)
	img.Name = "Glow"
	img.ZIndex = 0
	img.ImageTransparency = 0.35
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
