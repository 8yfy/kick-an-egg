--!strict
-- Partner A. The Pet Merchant's tall reclining lounge chair (Anim/Merchant's "lazy" pose sits in it): classic studded
-- bricks in the Pet Selling Stand's wood / teal / gold, with a padded seat and back, armrests and gold trim. It is
-- built to the pose, not the other way round: Anim/Merchant fits the seat under his thighs (tilted up toward the
-- counter) and the back along his reclined spine, and passes the crease where the two cushions meet; the legs stand
-- straight down to the floor. A tall chair because the counter top is at the merchant's chest: feet up on it need the
-- hips that high. Purely a prop (anchored, no collision, no queries, no touches).
local Bricks = require(script.Parent.Parent.Map.Bricks)

local LazyChair = {}

export type Spec = {
	seat: CFrame, -- the crease where the seat top meets the back pad (x = the middle), in `base` space; -Z forward,
	-- tilted with the seat
	floorY: number, -- the floor, in `base` space
	width: number,
	seatDepth: number, -- seat top, from the crease forward
	recline: number, -- degrees the back leans back past square to the seat
	backHeight: number, -- back pad, from the crease up
	headrest: { bottom: number, top: number, front: number }?, -- what it holds (his clasped hands), in the back's
	-- frame: up from the crease, behind the pad's face
}

local WOOD = Color3.fromRGB(132, 86, 48)
local WOOD_DARK = Color3.fromRGB(94, 60, 34)
local TEAL = Color3.fromRGB(44, 172, 160)
local TEAL_DARK = Color3.fromRGB(30, 128, 120)
local GOLD = Color3.fromRGB(255, 205, 60)
local POST = 0.4
local BOARD = 0.28
local CUSHION = 0.32
local PAD = 0.26
local PANEL = 0.2
local ARM = 0.85 -- armrest height over the seat
local HEAD_W = 1.0 -- headrest width (it sits between his raised elbows)
local SPLAY = 0.28 -- legs out at the floor

local function prop(p: BasePart)
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.CastShadow = true
end

function LazyChair.build(base: CFrame, s: Spec): Model
	local model = Instance.new("Model")
	model.Name = "LazyChair"
	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, studs: boolean?)
		prop(Bricks.part(model, name, size, base * cf, color, { collide = false, studs = studs ~= false }))
	end
	local seat = s.seat
	local gamma = math.rad(s.recline)
	local back = seat * CFrame.Angles(gamma, 0, 0) -- the back pad's front face is this frame's z = 0
	local w, depth, h = s.width, s.seatDepth, s.backHeight
	local hx = w / 2 - POST / 2 -- legs, uprights and armrests
	local inner = w - 2 * POST - 0.04 -- between them
	local under = -(CUSHION + BOARD) -- the seat's underside (seat frame)
	-- a point on an upright (back frame: x, t up it, z = in line with the pad) in the seat frame
	local uz = PAD / 2
	local function upright(t: number): (number, number)
		return t * math.cos(gamma) - uz * math.sin(gamma), t * math.sin(gamma) + uz * math.cos(gamma)
	end
	local function onUpright(y: number): (number, number) -- the upright's t and seat-frame z at seat-frame height y
		local t = (y + uz * math.sin(gamma)) / math.cos(gamma)
		local _, z = upright(t)
		return t, z
	end
	local t0, rearZ = onUpright(under)

	-- the seat: a wooden board under a studded teal cushion, a gold strip along the front
	local boardBack = rearZ + POST / 2
	part(
		"Seat",
		Vector3.new(w, BOARD, depth + 0.06 + boardBack),
		seat * CFrame.new(0, under + BOARD / 2, (boardBack - depth - 0.06) / 2),
		WOOD
	)
	part(
		"Cushion",
		Vector3.new(inner, CUSHION, depth + 0.14),
		seat * CFrame.new(0, -CUSHION / 2, (0.14 - depth) / 2),
		TEAL,
		true
	)
	part(
		"CushionRoll",
		Vector3.new(inner + 0.02, CUSHION + 0.02, 0.3),
		seat * CFrame.new(0, -CUSHION / 2 - 0.03, 0.12 - depth), -- (piping along the front, just under the top)
		TEAL_DARK,
		false
	)
	part(
		"SeatTrim",
		Vector3.new(w + 0.06, 0.16, 0.16),
		seat * CFrame.new(0, under + BOARD / 2, -depth - 0.1),
		GOLD,
		false
	)

	-- the back: the teal pad on a wooden panel between two uprights, a gold top rail and gold knobs
	part("BackPad", Vector3.new(inner, h, PAD), back * CFrame.new(0, h / 2, PAD / 2), TEAL)
	part(
		"BackPadStripe",
		Vector3.new(inner + 0.02, 0.16, PAD),
		back * CFrame.new(0, h * 0.62, PAD / 2 + 0.01),
		TEAL_DARK,
		false
	)
	part("BackPanel", Vector3.new(inner + 0.1, h + 0.1, PANEL), back * CFrame.new(0, h / 2, PAD + PANEL / 2), WOOD)
	part(
		"BackRail",
		Vector3.new(inner + 0.1, 0.24, PAD + PANEL - 0.04), -- (set back off the pad's face: his shoulders)
		back * CFrame.new(0, h + 0.12, (PAD + PANEL) / 2 + 0.06),
		GOLD
	)
	local t1 = h + 0.24 -- (flush with the rail: his raised upper arms pass just above)
	for _, side in { -1, 1 } do
		local x = hx * side
		part(
			"Upright",
			Vector3.new(POST, t1 - t0, POST + 0.04),
			back * CFrame.new(x, (t0 + t1) / 2, uz),
			WOOD_DARK,
			false
		)
		part(
			"Knob",
			Vector3.new(POST + 0.08, 0.12, POST + 0.12),
			back * CFrame.new(x, t1 + 0.04, uz + 0.04),
			GOLD,
			false
		)
	end

	-- the headrest: a teal pillow behind his head on a wooden post up from the back's rail, gold cap; his clasped
	-- hands rest on it
	if s.headrest then
		local r = s.headrest
		local y0, y1 = r.bottom - 0.08, r.top + 0.06
		local mid = (y0 + y1) / 2
		part("Headrest", Vector3.new(HEAD_W, y1 - y0, PAD), back * CFrame.new(0, mid, r.front + PAD / 2), TEAL)
		part(
			"HeadrestBack",
			Vector3.new(HEAD_W - 0.12, y1 - y0 - 0.12, PANEL),
			back * CFrame.new(0, mid, r.front + PAD + PANEL / 2),
			WOOD,
			false
		)
		part(
			"HeadrestCap",
			Vector3.new(HEAD_W + 0.08, 0.18, PAD + PANEL + 0.06),
			back * CFrame.new(0, y1 + 0.09, r.front + (PAD + PANEL) / 2),
			GOLD,
			false
		)
		local postZ = math.max(r.front + PAD, (PAD + PANEL) / 2 + 0.06)
		part(
			"HeadrestPost",
			Vector3.new(POST, y0 + 0.2 - h, 0.3),
			back * CFrame.new(0, (h + y0 + 0.2) / 2, postZ),
			WOOD_DARK,
			false
		)
	end

	-- armrests along the seat: from the front post back into the uprights, a teal pad on top, gold caps
	local _, armZ = onUpright(ARM)
	local frontZ = -depth + POST / 2 + 0.02
	local armLen = armZ - frontZ
	for _, side in { -1, 1 } do
		local x = hx * side
		part("Armrest", Vector3.new(POST, 0.2, armLen), seat * CFrame.new(x, ARM, frontZ + armLen / 2), WOOD)
		part(
			"ArmPad",
			Vector3.new(POST - 0.04, 0.12, armLen - 0.3),
			seat * CFrame.new(x, ARM + 0.16, frontZ + armLen / 2 + 0.1),
			TEAL
		)
		part("ArmCap", Vector3.new(POST + 0.1, 0.34, 0.24), seat * CFrame.new(x, ARM + 0.04, frontZ - 0.1), GOLD)
		part(
			"ArmPost",
			Vector3.new(POST - 0.04, ARM - under, POST - 0.04),
			seat * CFrame.new(x, (ARM + under) / 2, frontZ),
			WOOD_DARK,
			false
		)
	end

	-- legs: a tall director's chair. Down to the floor from under the seat (the front ones longer: the seat tilts up),
	-- splayed a little, brass feet, an X brace on each side with a gold bolt where it crosses, a rung below it and a
	-- gold foot rest across the front
	local legs: { [string]: { top: Vector3, foot: Vector3 } } = {}
	for _, side in { -1, 1 } do
		local x = hx * side
		local key = if side == 1 then "R" else "L"
		local front = seat * Vector3.new(x, under + 0.08, frontZ)
		local rear = seat * Vector3.new(x, under + 0.08, rearZ)
		-- (splayed out at the floor: a steadier stance under such a tall seat)
		legs["F" .. key] = { top = front, foot = Vector3.new(x + SPLAY * side, s.floorY, front.Z - SPLAY) }
		legs["B" .. key] = { top = rear, foot = Vector3.new(x + SPLAY * side, s.floorY, rear.Z + SPLAY) }
	end
	local function at(key: string, y: number): Vector3 -- a point on a leg at height y
		local leg = legs[key]
		return leg.top:Lerp(leg.foot, (leg.top.Y - y) / (leg.top.Y - leg.foot.Y))
	end
	local function bar(name: string, a: Vector3, c: Vector3, thick: number, color: Color3)
		part(name, Vector3.new(thick, thick, (c - a).Magnitude), CFrame.lookAt((a + c) / 2, c), color, false)
	end
	local lowTop = math.huge
	for _, leg in legs do
		lowTop = math.min(lowTop, leg.top.Y - s.floorY)
		bar("Leg", leg.top, leg.foot + Vector3.new(0, 0.12, 0), POST, WOOD_DARK)
		part(
			"Foot",
			Vector3.new(POST + 0.14, 0.2, POST + 0.14),
			CFrame.new(leg.foot + Vector3.new(0, 0.1, 0)),
			GOLD,
			false
		)
	end
	local rungY = s.floorY + lowTop * 0.38
	for _, key in { "R", "L" } do
		local f, b = "F" .. key, "B" .. key
		bar("SideRung", at(f, rungY), at(b, rungY), 0.22, WOOD)
		-- the X: front-top to back-bottom and back-top to front-bottom, a gold bolt where they cross
		local ft, bb = at(f, legs[f].top.Y - 0.3), at(b, rungY + 0.12)
		local bt, fb = at(b, legs[b].top.Y - 0.3), at(f, rungY + 0.12)
		bar("Brace", ft, bb, 0.2, WOOD)
		bar("Brace", bt, fb, 0.2, WOOD)
		local d1, d2 = bb - ft, fb - bt
		local den = d1.Z * d2.Y - d1.Y * d2.Z
		local k = if math.abs(den) > 1e-6 then ((bt.Z - ft.Z) * d2.Y - (bt.Y - ft.Y) * d2.Z) / den else 0.5
		part("Bolt", Vector3.new(0.3, 0.3, 0.3), CFrame.new(ft + d1 * k), GOLD, false)
	end
	bar("BackRung", at("BL", rungY), at("BR", rungY), 0.22, WOOD)
	local restY = s.floorY + lowTop * 0.62
	bar("FootRest", at("FL", restY), at("FR", restY), 0.28, GOLD)
	return model
end

return LazyChair
