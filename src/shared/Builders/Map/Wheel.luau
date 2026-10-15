--!strict
-- The Prize Wheel mounted on a plaza wall (Config/Wheel). Stable names (WheelService / WheelController):
--   SpinWheel                Model (attribute Radius); WheelBuilder.axis(model) = the wheel centre with local Z out
--                            of the wall (read from the fixed BackPlate, so it follows the plaza being raised)
--     .Rotor                 Model the client turns locally about that axis; .Label<i> transparent parts the client
--                            decorates with each segment's prize
--     .Pointer               the fixed flapper at 12 o'clock (the segment under it wins)
--     .Podium                Part on the ground with the ProximityPrompt (Action "OpenMenu:Wheel")
-- Segment i is centred (i - 1) * 360 / #segments degrees clockwise from the top when the rotor is at rest.
-- Built from wedge triangles, studded blocks and neon bulbs (classic brick look); nothing collides above the
-- podium so it can't trap players against the wall.
local Bricks = require(script.Parent.Bricks)
local Wheel = require(script.Parent.Parent.Parent.Config.Wheel)

local WheelBuilder = {}

local DISC = CFrame.Angles(0, math.rad(90), 0) -- Roblox cylinders run along X: turn them to face out
local PLATE_Z = 1.6

-- The spin axis (wheel centre, local Z out of the wall) from where the BackPlate really is. MapBuilder lifts the
-- plaza's parts after building (not Model pivots), so this is the only reliable source.
function WheelBuilder.axis(model: Instance): CFrame?
	local plate = model:FindFirstChild("BackPlate")
	if not (plate and plate:IsA("BasePart")) then
		return nil
	end
	return plate.CFrame * DISC:Inverse() * CFrame.new(0, 0, -PLATE_Z)
end

local rgb = Color3.fromRGB
local GOLD, GOLD_DARK = rgb(255, 200, 50), rgb(200, 140, 20)
local NAVY = rgb(40, 30, 75)

-- Two wedges forming the triangle a-b-c (world points), `thickness` along the triangle's normal.
local function triangle(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	thickness: number,
	color: Color3
)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local o: Bricks.Opts = { shape = "Wedge", collide = false, studs = false }
	Bricks.part(
		parent,
		name,
		Vector3.new(thickness, height, math.abs(ab:Dot(back))),
		CFrame.fromMatrix((a + b) / 2, right, up, back),
		color,
		o
	)
	Bricks.part(
		parent,
		name,
		Vector3.new(thickness, height, math.abs(ac:Dot(back))),
		CFrame.fromMatrix((a + c) / 2, -right, up, -back),
		color,
		o
	)
end

-- `face`: the wheel centre on the wall surface; its local Z points out of the wall, X to the viewer's right.
function WheelBuilder.build(parent: Instance, face: CFrame, radius: number, groundY: number): Model
	local R = radius
	local model = Instance.new("Model")
	model.Name = "SpinWheel"
	model:SetAttribute("Radius", R)
	model.Parent = parent
	local function at(x: number, y: number, z: number): CFrame
		return face * CFrame.new(x, y, z)
	end
	local function dir(alpha: number): Vector3 -- clockwise from the top, in the wheel plane
		return Vector3.new(math.sin(alpha), math.cos(alpha), 0)
	end
	local disc = DISC

	-- Back plate (fixed): navy disc with a gold edge ring
	Bricks.part(model, "BackPlate", Vector3.new(1, 2 * R + 4, 2 * R + 4), at(0, 0, PLATE_Z) * disc, NAVY, {
		shape = "Cylinder",
		collide = false,
	})

	-- Rotor
	local rotor = Instance.new("Model")
	rotor.Name = "Rotor"
	rotor.Parent = model
	local n = #Wheel.Segments
	local step = 2 * math.pi / n
	local SLICES = 3
	for i, seg in Wheel.Segments do
		local mid = (i - 1) * step
		local light = seg.color:Lerp(Color3.new(1, 1, 1), 0.12)
		for s = 0, SLICES - 1 do
			local a0 = mid - step / 2 + s * step / SLICES
			local a1 = a0 + step / SLICES
			local p0 = face:PointToWorldSpace(Vector3.new(0, 0, 2.7))
			local p1 = face:PointToWorldSpace(dir(a0) * R + Vector3.new(0, 0, 2.7))
			local p2 = face:PointToWorldSpace(dir(a1) * R + Vector3.new(0, 0, 2.7))
			triangle(rotor, "Segment" .. i, p0, p1, p2, 1, if s == 1 then light else seg.color)
		end
		-- divider spoke on the segment's clockwise edge
		local edge = mid + step / 2
		Bricks.part(
			rotor,
			"Spoke",
			Vector3.new(0.7, R, 0.5),
			face * CFrame.Angles(0, 0, -edge) * CFrame.new(0, R / 2, 3.3),
			GOLD,
			{ collide = false, studs = false }
		)
		-- prize label carrier (the client draws the icon + text on its +Z face)
		local label = Bricks.part(
			rotor,
			"Label" .. i,
			Vector3.new(9, 12, 0.1),
			face * CFrame.Angles(0, 0, -mid) * CFrame.new(0, R * 0.6, 3.3),
			Color3.new(1, 1, 1),
			{ collide = false, transparency = 1, studs = false }
		)
		label:SetAttribute("Segment", i)
	end
	-- rim of studded gold blocks with alternating neon bulbs
	local RIM = 36
	local tangent = 2 * math.pi * (R + 0.8) / RIM + 0.35
	for k = 0, RIM - 1 do
		local beta = k * 2 * math.pi / RIM
		Bricks.part(
			rotor,
			"Rim",
			Vector3.new(tangent, 1.6, 1.8),
			face * CFrame.Angles(0, 0, -beta) * CFrame.new(0, R + 0.8, 2.8),
			if k % 2 == 0 then GOLD else GOLD_DARK,
			{ collide = false }
		)
		if k % 2 == 0 then
			Bricks.part(
				rotor,
				"Bulb",
				Vector3.one * 1.1,
				face * CFrame.Angles(0, 0, -beta) * CFrame.new(0, R + 0.8, 3.9),
				if k % 4 == 0 then rgb(255, 250, 220) else rgb(255, 210, 60),
				{ shape = "Ball", material = Enum.Material.Neon, collide = false }
			)
		end
	end
	-- hub
	local hub = Bricks.part(rotor, "Hub", Vector3.new(1.4, 9, 9), at(0, 0, 3.4) * disc, GOLD, {
		shape = "Cylinder",
		collide = false,
	})
	Bricks.part(rotor, "HubCap", Vector3.new(0.6, 6, 6), at(0, 0, 4.2) * disc, rgb(230, 50, 60), {
		shape = "Cylinder",
		material = Enum.Material.Neon,
		collide = false,
	})
	Bricks.light(hub, rgb(255, 220, 120), 30, 1.2)
	-- no PrimaryPart: the pivot must be the wheel centre with Z out of the wall (the hub cylinder is turned)
	rotor.WorldPivot = at(0, 0, 0)

	-- pointer (fixed) at the top
	local pointer = Instance.new("Model")
	pointer.Name = "Pointer"
	pointer.Parent = model
	local tip = face:PointToWorldSpace(Vector3.new(0, R - 2.8, 4.4))
	local l = face:PointToWorldSpace(Vector3.new(-2.2, R + 2.4, 4.4))
	local r = face:PointToWorldSpace(Vector3.new(2.2, R + 2.4, 4.4))
	triangle(pointer, "Flapper", tip, l, r, 1.2, rgb(235, 45, 55))
	Bricks.part(pointer, "Cap", Vector3.new(5.6, 2.4, 2.2), at(0, R + 3.4, 4.2), GOLD)
	Bricks.glow(pointer, "Gem", Vector3.one * 1.2, at(0, R + 3.4, 5.4), rgb(255, 250, 220), "Ball")

	-- podium on the ground in front of the wheel: the prompt + a sign
	local podiumCF = CFrame.new(face:PointToWorldSpace(Vector3.new(0, 0, 9)))
	local pos = podiumCF.Position
	podiumCF = CFrame.lookAt(
		Vector3.new(pos.X, groundY + 1.5, pos.Z),
		face.Position * Vector3.new(1, 0, 1) + Vector3.new(0, groundY + 1.5, 0)
	)
	local podium = Bricks.part(model, "Podium", Vector3.new(10, 3, 6), podiumCF, rgb(140, 60, 220))
	Bricks.part(model, "PodiumTrim", Vector3.new(10.6, 0.6, 6.6), podiumCF * CFrame.new(0, 1.8, 0), GOLD)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SpinPrompt"
	prompt.ActionText = "Spin the Wheel"
	prompt.ObjectText = "Prize Wheel"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Action", "OpenMenu:Wheel")
	prompt.Parent = podium
	local sign = Instance.new("SurfaceGui")
	sign.Name = "Sign"
	sign.Face = Enum.NormalId.Back -- the podium looks at the wall: its back faces the plaza
	sign.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud -- (default FixedSize stretches 800x600)
	sign.PixelsPerStud = 40
	sign.LightInfluence = 0
	sign.Parent = podium
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.Text = "PRIZE WHEEL"
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Parent = text
	text.Parent = sign
	return model
end

return WheelBuilder
