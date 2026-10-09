--!strict
-- Chunky 3D block icons (BlockBuilder specs rendered in ViewportFrames) — no image assets needed.
-- Icons.view(parent, name, size?) -> ViewportFrame. Names: Book, Chest, Rebirth, Trade, Gear, Cash, Boot, Bolt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Builder = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Builders"):WaitForChild("BlockBuilder"))

type Spec = Builder.Spec
local rgb = Color3.fromRGB

local function P(
	name: string,
	size: { number },
	pos: { number },
	color: Color3,
	rot: { number }?,
	extra: { [string]: any }?
): Builder.PartSpec
	local p: Builder.PartSpec = { name = name, size = size, pos = pos, color = color, rot = rot }
	if extra then
		for k, v in extra do
			(p :: any)[k] = v
		end
	end
	return p
end

local GOLD, INK = rgb(255, 205, 60), rgb(40, 35, 45)

local SPECS: { [string]: Spec } = {
	Book = {
		parts = {
			P("Cover", { 3.2, 0.5, 4 }, { 0, 0, 0 }, rgb(70, 200, 90), { 20, -25, 10 }),
			P("Pages", { 2.9, 0.5, 3.7 }, { 0.1, 0.45, 0.05 }, rgb(250, 248, 235), { 20, -25, 10 }),
			P("Top", { 3.2, 0.4, 4 }, { 0.15, 0.9, 0.08 }, rgb(90, 220, 110), { 20, -25, 10 }),
			P("Spine", { 0.5, 1.3, 4 }, { -1.45, 0.45, -0.6 }, rgb(40, 150, 60), { 20, -25, 10 }),
			P("Clasp", { 0.6, 0.7, 0.3 }, { 1.4, 0.55, 1.1 }, GOLD, { 20, -25, 10 }),
		},
	},
	Chest = {
		parts = {
			P("Box", { 4, 2.2, 3 }, { 0, 0, 0 }, rgb(230, 60, 70), { 0, -25, 0 }),
			P("Lid", { 4.1, 1.1, 3.1 }, { 0, 1.7, 0 }, rgb(250, 90, 95), { -12, -25, 0 }),
			P("BandL", { 0.4, 3.4, 3.2 }, { -1.3, 0.55, 0 }, GOLD, { 0, -25, 0 }),
			P("BandR", { 0.4, 3.4, 3.2 }, { 1.3, 0.55, 0 }, GOLD, { 0, -25, 0 }),
			P("Lock", { 0.8, 0.9, 0.3 }, { 0, 0.9, -1.6 }, GOLD, { 0, -25, 0 }),
			P("Gem", { 0.4, 0.4, 0.2 }, { 0, 0.95, -1.8 }, rgb(80, 220, 120), { 0, -25, 0 }, { material = "Neon" }),
		},
	},
	Rebirth = {
		parts = (function()
			local parts = {}
			for i = 1, 10 do
				local a = (i - 1) / 12 * 2 * math.pi
				local c = if i <= 5 then rgb(240, 70, 80) else rgb(70, 200, 255)
				table.insert(
					parts,
					P("Seg" .. i, { 0.9, 0.9, 0.9 }, { math.cos(a) * 2, math.sin(a) * 2, 0 }, c, { 0, 0, math.deg(a) })
				)
			end
			table.insert(parts, P("HeadA", { 1.6, 1.6, 0.9 }, { 2, -0.9, 0 }, rgb(240, 70, 80), { 0, 0, 45 }))
			table.insert(parts, P("HeadB", { 1.6, 1.6, 0.9 }, { -2, 0.9, 0 }, rgb(70, 200, 255), { 0, 0, 45 }))
			return parts
		end)(),
	},
	Trade = {
		parts = {
			P("ShaftA", { 3.2, 0.9, 0.9 }, { -0.3, 0.8, 0 }, rgb(90, 220, 100)),
			P("HeadA", { 1.5, 1.5, 0.9 }, { 1.4, 0.8, 0 }, rgb(90, 220, 100), { 0, 0, 45 }),
			P("ShaftB", { 3.2, 0.9, 0.9 }, { 0.3, -0.8, 0 }, rgb(255, 160, 40)),
			P("HeadB", { 1.5, 1.5, 0.9 }, { -1.4, -0.8, 0 }, rgb(255, 160, 40), { 0, 0, 45 }),
		},
	},
	Gear = {
		parts = (function()
			local parts =
				{ P("Disc", { 0.8, 3, 3 }, { 0, 0, 0 }, rgb(170, 175, 190), { 0, 90, 0 }, { shape = "Cylinder" }) }
			for i = 1, 4 do
				table.insert(parts, P("Tooth" .. i, { 4, 0.8, 0.8 }, { 0, 0, 0 }, rgb(150, 155, 170), { 0, 0, i * 45 }))
			end
			table.insert(parts, P("Hub", { 0.9, 1.1, 1.1 }, { 0, 0, -0.1 }, INK, { 0, 90, 0 }, { shape = "Cylinder" }))
			return parts
		end)(),
	},
	Cash = {
		parts = {
			P("Bill1", { 4, 0.4, 2.2 }, { 0, 0, 0 }, rgb(70, 190, 80), { 0, -20, 0 }),
			P("Bill2", { 4, 0.4, 2.2 }, { 0.15, 0.45, 0.1 }, rgb(90, 210, 95), { 0, -14, 0 }),
			P("Bill3", { 4, 0.4, 2.2 }, { -0.1, 0.9, -0.05 }, rgb(110, 225, 110), { 0, -24, 0 }),
			P("Band", { 0.8, 1.4, 2.4 }, { 0, 0.5, 0 }, rgb(250, 240, 200), { 0, -20, 0 }),
			P("Dollar", { 0.3, 0.6, 0.1 }, { 1.2, 1.12, -0.2 }, rgb(40, 120, 50), { 90, -24, 0 }),
		},
	},
	Boot = {
		parts = {
			P("Sole", { 1.6, 0.5, 3.6 }, { 0, 0, 0 }, rgb(250, 250, 255), { 0, -30, 0 }),
			P("Body", { 1.5, 1.4, 2.6 }, { 0, 0.9, 0.4 }, rgb(70, 160, 255), { 0, -30, 0 }),
			P("Ankle", { 1.5, 1.4, 1.4 }, { 0, 2.0, 1.0 }, rgb(70, 160, 255), { 0, -30, 0 }),
			P("Toe", { 1.4, 0.9, 1.0 }, { 0, 0.6, -1.4 }, rgb(250, 250, 255), { 0, -30, 0 }),
			P("Stripe", { 1.55, 0.3, 1.8 }, { 0, 1.2, 0.5 }, rgb(255, 210, 60), { 0, -30, 0 }),
		},
	},
	Bolt = {
		parts = {
			P("Top", { 0.9, 2.2, 0.8 }, { 0.5, 1.2, 0 }, rgb(255, 220, 60), { 0, 0, -25 }, { material = "Neon" }),
			P("Mid", { 2.2, 0.8, 0.8 }, { 0, 0, 0 }, rgb(255, 200, 40), { 0, 0, 20 }, { material = "Neon" }),
			P("Bottom", { 0.9, 2.2, 0.8 }, { -0.5, -1.2, 0 }, rgb(255, 220, 60), { 0, 0, -25 }, { material = "Neon" }),
		},
	},
}

local Icons = {}

function Icons.view(parent: Instance, name: string, size: UDim2?): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Name = name .. "Icon"
	vp.BackgroundTransparency = 1
	vp.Size = size or UDim2.fromScale(1, 1)
	vp.Ambient = rgb(200, 200, 205)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-0.5, -1, -0.8)
	local spec = SPECS[name]
	if spec then
		local model = Builder.build(spec, name)
		model:PivotTo(CFrame.new())
		model.Parent = vp
		local cf, sz = model:GetBoundingBox()
		local cam = Instance.new("Camera")
		cam.FieldOfView = 30
		local dist = sz.Magnitude / 2 / math.tan(math.rad(15)) * 1.05
		cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0, dist * 0.18, -dist), cf.Position)
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
	vp.Parent = parent
	return vp
end

-- Rack preview for the Store (tier name from Config/Upgrades).
function Icons.rack(parent: Instance, tier: string, size: UDim2?): ViewportFrame
	local TrainingRack = require((ReplicatedStorage :: any).Shared.Builders.Map.TrainingRack) :: any
	SPECS["Rack" .. tier] = SPECS["Rack" .. tier] or TrainingRack.spec(tier)
	local vp = Icons.view(parent, "Rack" .. tier, size)
	local cam = vp.CurrentCamera
	if cam then
		cam.CFrame = cam.CFrame * CFrame.new(0, 0, -2)
	end
	return vp
end

return Icons
