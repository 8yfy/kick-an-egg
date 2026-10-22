--!strict
-- Partner A. Classic brick recipes for the launch station at the kick pad (flat start, 2026-10-22): the stepped
-- kick spot around the pad (the KickPad part itself is MapBuilder's), a red-and-white launch pylon with a beacon,
-- the 3-2-1 countdown board and the KICK THE EGG! board.
-- Asset space: origin = base centre, +Y up, front = -Z.
local B = require(script.Parent.Parent.Brick)

local V = Vector3.new
local rad = math.rad

local Launch = {}

-- A voxel disc standing in the XY plane (facing -Z) centred at (x, y, z): d across, t thick.
local function disc(m: Model, role: string, d: number, t: number, x: number, y: number, z: number)
	local cf = CFrame.new(x, y, z)
	B.at(m, role, V(d * 0.64, d, t), cf)
	B.at(m, role, V(d, d * 0.64, t - 0.02), cf)
	if d >= 3 then
		B.at(m, role, V(d * 0.66, d * 0.66, t - 0.04), cf * CFrame.Angles(0, 0, rad(45)))
	end
end

-- The stepped kick spot around the pad: a dark outer tier, a darker rim the pad sits in, a ring of glow studs on
-- the tier, and the brick arrow lying on the pad's top (y = 0.5) pointing down the lane (+Z). Reaches 6 studs from
-- the centre, so the safe-line markings at z <= -6 stay clear.
local function kickSpot(m: Model)
	B.round(m, "StoneDark", 0.2, 12, 0, 0, 0)
	B.round(m, "Dark", 0.38, 10, 0, 0, 0, 22.5)
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		B.at(
			m,
			if i % 2 == 0 then "Glow" else "Glow2",
			V(0.9, 0.12, 0.5),
			CFrame.new(math.cos(a) * 5.5, 0.26, math.sin(a) * 5.5) * CFrame.Angles(0, -a, 0)
		)
	end
	-- arrow: a shaft and a stepped head, 0.2 tall on the pad top
	B.on(m, "Arrow", V(1.4, 0.2, 3.4), 0, 0.5, -1.2)
	for k, w in { 4.2, 2.8, 1.4 } do
		B.on(m, "Arrow", V(w, 0.2, 0.9), 0, 0.5, 0.05 + k * 0.9)
	end
end

-- A launch pylon: a studded plinth, four corner posts in red / white bands, ring frames every 6 studs with glow
-- studs on the corners, a top deck and a beacon. About 27 tall, 5 wide.
local function launchPylon(m: Model)
	local h, s = 24, 1.7
	B.on(m, "StoneDark", V(5.4, 1.2, 5.4), 0, 0, 0)
	B.on(m, "Stone", V(4.6, 0.4, 4.6), 0, 1.2, 0)
	local band = h / 6
	for _, px in { -s, s } do
		for _, pz in { -s, s } do
			for k = 0, 5 do
				B.on(m, if k % 2 == 0 then "Red" else "White", V(0.9, band, 0.9), px, 1.6 + k * band, pz)
			end
		end
	end
	for k = 1, 4 do
		local y = 1.6 + k * h / 5
		for _, pz in { -s, s } do
			B.box(m, "Frame", V(2 * s - 0.9, 0.5, 0.5), 0, y, pz)
		end
		for _, px in { -s, s } do
			B.box(m, "Frame", V(0.5, 0.5, 2 * s - 0.9), px, y, 0)
		end
		for _, px in { -s, s } do
			for _, pz in { -s, s } do
				B.box(m, "Glow2", V(1.0, 0.3, 1.0), px, y + 0.4, pz)
			end
		end
	end
	B.on(m, "StoneDark", V(5, 0.6, 5), 0, 1.6 + h, 0)
	B.round(m, "Frame", 0.6, 2.6, 0, 2.2 + h, 0)
	B.round(m, "Glow", 1.6, 2.0, 0, 2.8 + h, 0)
	B.on(m, "Frame", V(1.0, 0.4, 1.0), 0, 4.4 + h, 0)
end

-- The 3-2-1 countdown board: a dark face in a studded frame, three lamps (red, amber, green; roles Glow, Glow2,
-- Glow3) across the top and a sign strip ("Sign") for the text below. 14 wide, 9 tall, base at the board's foot.
local function countdownBoard(m: Model)
	local w, h = 14, 9
	B.on(m, "Sign", V(w, h, 0.6), 0, 0, 0)
	for _, s in { -1, 1 } do
		B.on(m, "Frame", V(0.8, h + 0.8, 1.0), s * (w / 2 + 0.4), -0.4, 0)
	end
	B.on(m, "Frame", V(w + 1.6, 0.8, 1.0), 0, h, 0)
	B.on(m, "Frame", V(w + 1.6, 0.8, 1.0), 0, -0.8, 0)
	for k, role in { "Glow", "Glow2", "Glow3" } do
		local x = (2 - k) * 4.2 -- red (3) on the viewer's left: the board faces -Z, so that is local +X
		disc(m, "Frame", 3.8, 0.4, x, 6.1, -0.45)
		disc(m, role, 3.0, 0.5, x, 6.1, -0.6)
	end
	B.on(m, "Frame", V(w - 1, 0.3, 0.4), 0, 3.6, -0.45)
end

-- The KICK THE EGG! board: an orange studded board with a yellow frame and a smooth sign face ("Sign") for the
-- text. 17 wide, 6 tall, base at its foot.
local function kickBoard(m: Model)
	local w, h = 17, 6
	B.on(m, "Board", V(w, h, 0.8), 0, 0, 0)
	B.on(m, "Sign", V(w - 1.2, h - 1.2, 0.2), 0, 0.6, -0.5)
	for _, s in { -1, 1 } do
		B.on(m, "Trim", V(0.8, h + 0.8, 1.2), s * (w / 2 + 0.4), -0.4, 0)
	end
	B.on(m, "Trim", V(w + 1.6, 0.8, 1.2), 0, h, 0)
	B.on(m, "Trim", V(w + 1.6, 0.8, 1.2), 0, -0.8, 0)
end

Launch.recipes = {
	KickSpot = kickSpot,
	LaunchPylon = launchPylon,
	CountdownBoard = countdownBoard,
	KickBoard = kickBoard,
}

return Launch
