--!strict
-- Helpers for the premium egg/pet specs (Models/Premium/*). They only build PartSpec tables for BlockBuilder;
-- nothing here is a mesh. Conventions as in Kit: feet at y = 0, models face -Z, left = -X, the first part of a
-- joint group is its hinge. Angles are degrees.
local Builder = require(script.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Kit)

type PartSpec = Builder.PartSpec
export type Opts = Kit.Opts

local Sculpt = {}

Sculpt.part = Kit.part
Sculpt.join = Kit.join
Sculpt.eye = Kit.eye

local function deg(v: number): number
	return math.deg(v)
end

-- A part placed by a CFrame (for tilted shards, fans, rings).
function Sculpt.at(name: string, size: { number }, cf: CFrame, color: Color3, o: Opts?): PartSpec
	local rx, ry, rz = cf:ToEulerAnglesXYZ()
	local opts: Opts = table.clone(o or {})
	opts.rot = { deg(rx), deg(ry), deg(rz) }
	local p = cf.Position
	return Kit.part(name, size, { p.X, p.Y, p.Z }, color, opts)
end

-- CFrame from a position and XYZ angles in degrees (same convention as PartSpec.rot).
function Sculpt.cf(pos: { number }, rot: { number }?): CFrame
	local r = rot or { 0, 0, 0 }
	return CFrame.new(pos[1], pos[2], pos[3]) * CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
end

-- "WingL" -> "WingR", "FeatherL3" -> "FeatherR3" (an L or R just before the trailing digits flips).
local function swapSide(s: string?): string?
	if s == nil then
		return nil
	end
	local head, side, digits = s:match("^(.-)([LR])(%d*)$")
	if not head or not side or not digits then
		return s
	end
	return head .. (if side == "L" then "R" else "L") .. digits
end

-- Mirror a list of left-side parts (x < 0) to the right: names/joints ending in L (+ digits) become R.
function Sculpt.mirror(parts: { PartSpec }): { PartSpec }
	local out = {}
	for _, p in parts do
		local q = table.clone(p)
		q.pos = { -p.pos[1], p.pos[2], p.pos[3] }
		if p.rot then
			q.rot = { p.rot[1], -p.rot[2], -p.rot[3] }
		end
		q.name = swapSide(p.name)
		q.joint = swapSide(p.joint)
		table.insert(out, q)
	end
	return out
end

-- Left parts + their mirrored right twins.
function Sculpt.both(parts: { PartSpec }): { PartSpec }
	return Kit.join(parts, Sculpt.mirror(parts))
end

-- Eggs are the classic blocky Roblox egg: square layers stepping in and out (studded tops), not a round shell.
Sculpt.EGG_STEP = 0.55 -- studs per layer

-- How many square layers an egg of height h gets (7 for a 3.7-stud egg, like Kit.eggShell).
function Sculpt.eggLayers(h: number): number
	return math.max(7, math.floor(h / Sculpt.EGG_STEP + 0.5))
end

-- The egg profile (height h, belly width w): half-width at height y, wider below the middle, rounder on top.
local function profile(h: number, w: number, y: number): number
	local t = math.clamp((y / h) * 2 - 1, -1, 1)
	local r = math.sqrt(math.max(0, 1 - t * t)) * (1 - 0.14 * t)
	return w / 2 * r / 1.03
end

-- Half-width of the square layer at height y (the shell is stepped, so this is constant within a layer).
function Sculpt.eggRadius(h: number, w: number, y: number): number
	local n = Sculpt.eggLayers(h)
	local dh = h / n
	local i = math.clamp(math.floor(y / dh) + 1, 1, n)
	return math.max(profile(h, w, (i - 0.5) * dh), 0.3)
end

-- Blocky egg shell: square layers (Sculpt.eggLayers(h) of them) following the egg profile, joint "Body" (the
-- shell group legs sprout under). `paint(i, n, y)` colours layer i of n (y = its centre height).
function Sculpt.eggShell(h: number, w: number, paint: (number, number, number) -> Color3, o: Opts?): { PartSpec }
	local parts = {}
	local n = Sculpt.eggLayers(h)
	local dh = h / n
	for i = 1, n do
		local y = (i - 0.5) * dh
		local r = Sculpt.eggRadius(h, w, y)
		local opts: Opts = table.clone(o or {})
		opts.joint = opts.joint or "Body"
		table.insert(parts, Kit.part("Shell" .. i, { r * 2, dh, r * 2 }, { 0, y, 0 }, paint(i, n, y), opts))
	end
	return parts
end

-- A square band around the egg at height y (thickness th, sticking out by `out`), like Kit.eggBand.
function Sculpt.eggBand(
	name: string,
	h: number,
	w: number,
	y: number,
	th: number,
	out: number,
	color: Color3,
	o: Opts?
): PartSpec
	local r = Sculpt.eggRadius(h, w, y) + out
	local opts: Opts = table.clone(o or {})
	opts.joint = opts.joint or "Body"
	return Kit.part(name, { r * 2, th, r * 2 }, { 0, y, 0 }, color, opts)
end

-- CFrame on the egg's surface at angle `a` (0 = front, -Z; 90 = right, +X; 180 = back) and height y, facing
-- outward, flush on the square face the angle points at (corners clamp onto a face).
function Sculpt.onEgg(h: number, w: number, a: number, y: number, lift: number?): CFrame
	local r = Sculpt.eggRadius(h, w, y)
	local face = math.floor((a + 45) / 90) * 90
	local th = math.rad(face)
	local along = math.clamp(math.tan(math.rad(a - face)) * r, -r + 0.2, r - 0.2)
	local normal = Vector3.new(math.sin(th), 0, -math.cos(th))
	local tangent = Vector3.new(math.cos(th), 0, math.sin(th))
	local pos = normal * (r + (lift or 0)) + tangent * along + Vector3.new(0, y, 0)
	return CFrame.new(pos) * CFrame.Angles(0, -th, 0)
end

-- `perSide` parts on each of the egg's four faces at height y (trims, crests, fur), facing outward;
-- o.rot turns each in place (degrees).
function Sculpt.eggRing(
	name: string,
	h: number,
	w: number,
	y: number,
	perSide: number,
	size: { number },
	color: Color3,
	o: Opts?
): { PartSpec }
	local parts = {}
	local r = Sculpt.eggRadius(h, w, y)
	local opts: Opts = table.clone(o or {})
	opts.joint = opts.joint or "Body"
	local turn = opts.rot
	opts.rot = nil
	for f = 0, 3 do
		local th = math.rad(f * 90)
		local normal = Vector3.new(math.sin(th), 0, -math.cos(th))
		local tangent = Vector3.new(math.cos(th), 0, math.sin(th))
		for k = 1, perSide do
			local along = (k - (perSide + 1) / 2) * (2 * r / perSide)
			local c = CFrame.new(normal * (r + size[3] / 2 - 0.06) + tangent * along + Vector3.new(0, y, 0))
				* CFrame.Angles(0, -th, 0)
			if turn then
				c *= CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(turn[3]))
			end
			table.insert(parts, Sculpt.at(name .. (f * perSide + k), size, c, color, opts))
		end
	end
	return parts
end

-- Plate flush on the egg surface (depth along the outward normal); o.rot turns it in place (degrees).
function Sculpt.plate(
	name: string,
	h: number,
	w: number,
	a: number,
	y: number,
	size: { number },
	color: Color3,
	o: Opts?
): PartSpec
	local opts: Opts = table.clone(o or {})
	opts.joint = opts.joint or "Body"
	local c = Sculpt.onEgg(h, w, a, y, size[3] / 2 - 0.08)
	local r = opts.rot
	if r then
		c *= CFrame.Angles(math.rad(r[1]), math.rad(r[2]), math.rad(r[3]))
		opts.rot = nil
	end
	return Sculpt.at(name, size, c, color, opts)
end

-- `n` parts around a circle (centre cf, radius r), each turned to follow the ring.
function Sculpt.ring(
	name: string,
	center: CFrame,
	n: number,
	r: number,
	size: { number },
	color: Color3,
	o: Opts?,
	phase: number?
): { PartSpec }
	local parts = {}
	for i = 1, n do
		local a = math.rad((phase or 0) + (i - 1) * 360 / n)
		local cf = center * CFrame.new(math.sin(a) * r, 0, -math.cos(a) * r) * CFrame.Angles(0, -a, 0)
		table.insert(parts, Sculpt.at(name .. i, size, cf, color, o))
	end
	return parts
end

-- Gear: a hub cylinder plus `teeth` blocks (centre cf; the gear lies in cf's XZ plane).
function Sculpt.gear(
	name: string,
	center: CFrame,
	r: number,
	th: number,
	teeth: number,
	color: Color3,
	o: Opts?
): { PartSpec }
	local parts = {
		Sculpt.at(
			name .. "Hub",
			{ th, r * 1.7, r * 1.7 },
			center * CFrame.Angles(0, 0, math.rad(90)),
			color,
			(function()
				local q: Opts = table.clone(o or {})
				q.shape = "Cylinder"
				return q
			end)()
		),
	}
	for _, p in Sculpt.ring(name .. "Tooth", center, teeth, r * 0.9, { r * 0.32, th, r * 0.32 }, color, o) do
		table.insert(parts, p)
	end
	return parts
end

-- Crystal shard growing along cf's up axis: three tapering segments turned 45 degrees (diamond section).
function Sculpt.shard(
	name: string,
	base: CFrame,
	len: number,
	w: number,
	color: Color3,
	o: Opts?,
	tipColor: Color3?
): { PartSpec }
	local turn = CFrame.Angles(0, math.rad(45), 0)
	return {
		Sculpt.at(name .. "A", { w, len * 0.55, w }, base * CFrame.new(0, len * 0.275, 0) * turn, color, o),
		Sculpt.at(name .. "B", { w * 0.66, len * 0.3, w * 0.66 }, base * CFrame.new(0, len * 0.7, 0) * turn, color, o),
		Sculpt.at(
			name .. "C",
			{ w * 0.32, len * 0.2, w * 0.32 },
			base * CFrame.new(0, len * 0.92, 0) * turn,
			tipColor or color,
			o
		),
	}
end

-- Fan of feathers / blades from a pivot: feather k points along pivot's up axis turned by its fan angle
-- (about the pivot's Z), from `from` to `to` degrees. `colors` cycles; `taper` shortens the outer ones.
function Sculpt.fan(
	name: string,
	pivot: CFrame,
	count: number,
	from: number,
	to: number,
	len: number,
	w: number,
	th: number,
	colors: { Color3 },
	o: Opts?,
	taper: number?
): { PartSpec }
	local parts = {}
	for k = 1, count do
		local f = if count == 1 then 0.5 else (k - 1) / (count - 1)
		local a = from + (to - from) * f
		local l = len * (1 - (taper or 0) * math.abs(f - 0.5) * 2)
		local cf = pivot * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(0, l / 2, 0)
		table.insert(parts, Sculpt.at(name .. k, { w, l, th }, cf, colors[(k - 1) % #colors + 1], o))
	end
	return parts
end

-- Rainbow helper for prism / rainbow pieces.
Sculpt.RAINBOW = {
	Color3.fromRGB(255, 80, 95),
	Color3.fromRGB(255, 160, 60),
	Color3.fromRGB(255, 230, 80),
	Color3.fromRGB(90, 230, 120),
	Color3.fromRGB(70, 200, 255),
	Color3.fromRGB(120, 120, 255),
	Color3.fromRGB(200, 110, 255),
}

-- Bounds of a built egg's shell (its "Shell<n>" parts), ignoring decorations that float around it (orbiting
-- crystals, halos): the chase hitbox and the sprouted legs follow the egg itself. Whole model as a fallback.
function Sculpt.shellBounds(egg: Model): (CFrame, Vector3)
	local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, d in egg:GetDescendants() do
		if d:IsA("BasePart") and d.Name:match("^Shell%d+$") then
			local half = d.Size / 2
			for _, x in { -1, 1 } do
				for _, y in { -1, 1 } do
					for _, z in { -1, 1 } do
						local w = d.CFrame:PointToWorldSpace(half * Vector3.new(x, y, z))
						lo, hi = lo:Min(w), hi:Max(w)
					end
				end
			end
		end
	end
	if lo.X > hi.X then
		return egg:GetBoundingBox()
	end
	return CFrame.new((lo + hi) / 2), hi - lo
end

return Sculpt
