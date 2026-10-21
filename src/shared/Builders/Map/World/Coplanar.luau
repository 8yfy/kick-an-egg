--!strict
-- Partner A. Removes z-fighting. Finds faces of visible parts that lie in the same plane, face the same way and
-- overlap, then separates them by `eps`: the smaller face (the detail) grows out by `eps`, or, when its part may not
-- change, the larger face moves back by `eps`. Repeats until no such pair is left. Used on every Kit template
-- (World/Kit) and once on the whole map after it is built (MapBuilder), with gameplay parts protected.
local Coplanar = {}

export type Movable = (BasePart) -> boolean
export type Options = {
	movable: Movable?, -- which parts may change (all when nil)
	childrenOnly: boolean?, -- only the direct children of the root (a Kit template)
	skipUndersides: boolean?, -- ignore downward faces at the base of their model (they rest on the ground: never
	-- seen, and very many); builder parts outside models skip all of theirs
}

type Face = {
	part: BasePart,
	idx: number, -- 1..6 = local +X, -X, +Y, -Y, +Z, -Z; 7 = wedge slope
	d: number,
	pts: { Vector3 },
	area: number,
	p2: { Vector2 }?,
	bb: { number }?,
}
type Group = { n: Vector3, list: { Face } }
type Groups = { [number]: Group }

local TOL = 0.03 -- planes closer than this count as one plane
local MIN_AREA = 0.01 -- overlaps smaller than this (studs²) are ignored
local PASSES = 6

local function addFace(groups: Groups, part: BasePart, idx: number, pts: { Vector3 }, floorY: number)
	local n = (pts[2] - pts[1]):Cross(pts[3] - pts[1])
	local len = n.Magnitude
	if len < 1e-6 then
		return
	end
	-- a parallelogram's cross product is its area; a triangle's is twice it
	local area = if #pts == 3 then len / 2 else len
	n /= len
	if n.Y < -0.995 and pts[1].Y <= floorY then -- flat bottoms only (a tilted ring is not resting on anything)
		return
	end
	local key = (math.floor(n.X * 1000 + 0.5) + 1000) * 4004001
		+ (math.floor(n.Y * 1000 + 0.5) + 1000) * 2001
		+ (math.floor(n.Z * 1000 + 0.5) + 1000)
	local g = groups[key]
	if not g then
		g = { n = n, list = {} }
		groups[key] = g
	end
	table.insert(g.list, { part = part, idx = idx, d = n:Dot(pts[1]), pts = pts, area = area })
end

local function partFaces(groups: Groups, p: BasePart, skipDown: boolean)
	-- downward faces at or below this height are left out
	local floorY = -math.huge
	if skipDown then
		local m = p.Parent
		floorY = if m and m:IsA("Model") then m.WorldPivot.Y + 0.6 else math.huge
	end
	local cf, s = p.CFrame, p.Size / 2
	local x, y, z = s.X, s.Y, s.Z
	local function f(idx: number, a: Vector3, b: Vector3, c: Vector3, d: Vector3?)
		local pts = { cf * a, cf * b, cf * c }
		if d then
			table.insert(pts, cf * d)
		end
		addFace(groups, p, idx, pts, floorY)
	end
	if p:IsA("WedgePart") then
		-- rises toward local +Z: bottom, the tall back face, two side triangles and the slope
		f(4, Vector3.new(-x, -y, z), Vector3.new(-x, -y, -z), Vector3.new(x, -y, -z), Vector3.new(x, -y, z))
		f(5, Vector3.new(x, -y, z), Vector3.new(x, y, z), Vector3.new(-x, y, z), Vector3.new(-x, -y, z))
		f(1, Vector3.new(x, -y, -z), Vector3.new(x, y, z), Vector3.new(x, -y, z))
		f(2, Vector3.new(-x, -y, z), Vector3.new(-x, y, z), Vector3.new(-x, -y, -z))
		f(7, Vector3.new(-x, -y, -z), Vector3.new(-x, y, z), Vector3.new(x, y, z), Vector3.new(x, -y, -z))
	elseif p:IsA("CornerWedgePart") then
		f(4, Vector3.new(-x, -y, z), Vector3.new(-x, -y, -z), Vector3.new(x, -y, -z), Vector3.new(x, -y, z))
	elseif p:IsA("Part") then
		if p.Shape == Enum.PartType.Block then
			f(1, Vector3.new(x, -y, -z), Vector3.new(x, y, -z), Vector3.new(x, y, z), Vector3.new(x, -y, z))
			f(2, Vector3.new(-x, -y, z), Vector3.new(-x, y, z), Vector3.new(-x, y, -z), Vector3.new(-x, -y, -z))
			f(3, Vector3.new(-x, y, -z), Vector3.new(-x, y, z), Vector3.new(x, y, z), Vector3.new(x, y, -z))
			f(4, Vector3.new(-x, -y, z), Vector3.new(-x, -y, -z), Vector3.new(x, -y, -z), Vector3.new(x, -y, z))
			f(5, Vector3.new(x, -y, z), Vector3.new(x, y, z), Vector3.new(-x, y, z), Vector3.new(-x, -y, z))
			f(6, Vector3.new(-x, -y, -z), Vector3.new(-x, y, -z), Vector3.new(x, y, -z), Vector3.new(x, -y, -z))
		elseif p.Shape == Enum.PartType.Cylinder then
			local r = math.min(y, z) * 0.7
			f(1, Vector3.new(x, -r, -r), Vector3.new(x, r, -r), Vector3.new(x, r, r), Vector3.new(x, -r, r))
			f(2, Vector3.new(-x, -r, r), Vector3.new(-x, r, r), Vector3.new(-x, r, -r), Vector3.new(-x, -r, -r))
		end
	end
end

local function area2(poly: { Vector2 }): number
	local a = 0
	for i = 1, #poly do
		local p, q = poly[i], poly[i % #poly + 1]
		a += p.X * q.Y - q.X * p.Y
	end
	return a / 2
end

-- Sutherland-Hodgman: the overlap of two convex, counter-clockwise polygons
local function clip(subject: { Vector2 }, clipper: { Vector2 }): { Vector2 }
	local out = subject
	for i = 1, #clipper do
		local a, b = clipper[i], clipper[i % #clipper + 1]
		local input = out
		out = {}
		if #input == 0 then
			break
		end
		local function inside(p: Vector2): boolean
			return (b.X - a.X) * (p.Y - a.Y) - (b.Y - a.Y) * (p.X - a.X) >= -1e-9
		end
		local function cross(p: Vector2, q: Vector2): Vector2
			local den = (a.X - b.X) * (p.Y - q.Y) - (a.Y - b.Y) * (p.X - q.X)
			if math.abs(den) < 1e-12 then
				return q
			end
			local t = ((a.X - p.X) * (p.Y - q.Y) - (a.Y - p.Y) * (p.X - q.X)) / den
			return Vector2.new(a.X + t * (b.X - a.X), a.Y + t * (b.Y - a.Y))
		end
		local prev = input[#input]
		for _, cur in input do
			if inside(cur) then
				if not inside(prev) then
					table.insert(out, cross(prev, cur))
				end
				table.insert(out, cur)
			elseif inside(prev) then
				table.insert(out, cross(prev, cur))
			end
			prev = cur
		end
	end
	return out
end

local AXIS = {
	Vector3.xAxis,
	-Vector3.xAxis,
	Vector3.yAxis,
	-Vector3.yAxis,
	Vector3.zAxis,
	-Vector3.zAxis,
}

-- Moves face `idx` of `p` outward by `by` (inward when negative). Returns false when the part is too thin.
local function push(p: BasePart, idx: number, by: number, normal: Vector3): boolean
	if idx == 7 then
		p.CFrame = p.CFrame + normal * by
		return true
	end
	local axis = AXIS[idx]
	local grow = Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)) * by
	local size = p.Size + grow
	if size.X < 0.05 or size.Y < 0.05 or size.Z < 0.05 then
		return false
	end
	p.Size = size
	p.CFrame = p.CFrame * CFrame.new(axis * (by / 2))
	return true
end

local function visible(p: BasePart): boolean
	return p.Transparency < 0.9
end

-- One detection pass; pushes faces apart and returns how many it moved and how many it could not.
local function pass(
	parts: { BasePart },
	eps: number,
	movable: Movable?,
	skipDown: boolean
): (number, number, { BasePart })
	local groups: Groups = {}
	for _, p in parts do
		partFaces(groups, p, skipDown)
	end
	local moved, stuck = 0, 0
	local done: { [BasePart]: { [number]: boolean } } = {}
	local function wasPushed(f: Face): boolean
		local t = done[f.part]
		return t ~= nil and t[f.idx] == true
	end
	local function mark(f: Face)
		local t = done[f.part]
		if not t then
			t = {}
			done[f.part] = t
		end
		t[f.idx] = true
	end
	for _, g in groups do
		local list = g.list
		if #list > 1 then
			table.sort(list, function(a, b)
				return a.d < b.d
			end)
			local n = g.n
			local u = if math.abs(n.Y) < 0.9 then n:Cross(Vector3.yAxis).Unit else n:Cross(Vector3.xAxis).Unit
			local v = n:Cross(u)
			local function proj(f: Face): ({ Vector2 }, { number })
				if f.p2 and f.bb then
					return f.p2, f.bb
				end
				local poly: { Vector2 } = {}
				local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
				for _, p in f.pts do
					local q = Vector2.new(p:Dot(u), p:Dot(v))
					table.insert(poly, q)
					minx, miny = math.min(minx, q.X), math.min(miny, q.Y)
					maxx, maxy = math.max(maxx, q.X), math.max(maxy, q.Y)
				end
				if area2(poly) < 0 then
					local r: { Vector2 } = {}
					for i = #poly, 1, -1 do
						table.insert(r, poly[i])
					end
					poly = r
				end
				local bb = { minx, miny, maxx, maxy }
				f.p2, f.bb = poly, bb
				return poly, bb
			end
			for i = 1, #list do
				local a = list[i]
				local j = i + 1
				while j <= #list and list[j].d - a.d < TOL do
					local b = list[j]
					if a.part ~= b.part and not (wasPushed(a) or wasPushed(b)) then
						local pa, A = proj(a)
						local pb, B = proj(b)
						if A[1] < B[3] and B[1] < A[3] and A[2] < B[4] and B[2] < A[4] then
							local inter = clip(pa, pb)
							if #inter >= 3 and math.abs(area2(inter)) > MIN_AREA then
								-- the smaller face is the detail: it should end up in front
								local small, large = a, b
								if b.area < a.area * 0.98 or (a.area < b.area * 1.02 and a.area >= b.area * 0.98) then
									small, large = b, a
								end
								local ok = false
								if movable == nil or movable(small.part) then
									ok = push(small.part, small.idx, eps, n)
									if ok then
										mark(small)
									end
								end
								if not ok and (movable == nil or movable(large.part)) then
									ok = push(large.part, large.idx, -eps, n)
									if ok then
										mark(large)
									end
								end
								if ok then
									moved += 1
								else
									stuck += 1
								end
							end
						end
					end
					j += 1
				end
			end
		end
	end
	local touched: { BasePart } = {}
	for part in done do
		table.insert(touched, part)
	end
	return moved, stuck, touched
end

-- Parts whose bounds come within `pad` of any part in `focus` (the focus parts included), via a coarse grid.
local CELL = 32
local function neighbours(all: { BasePart }, focus: { BasePart }, pad: number): { BasePart }
	local function bounds(p: BasePart): (Vector3, Vector3)
		local cf, s = p.CFrame, p.Size / 2
		local e = Vector3.new(
			math.abs(cf.XVector.X) * s.X + math.abs(cf.YVector.X) * s.Y + math.abs(cf.ZVector.X) * s.Z,
			math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z,
			math.abs(cf.XVector.Z) * s.X + math.abs(cf.YVector.Z) * s.Y + math.abs(cf.ZVector.Z) * s.Z
		) + Vector3.one * pad
		return cf.Position - e, cf.Position + e
	end
	local grid: { [number]: { BasePart } } = {}
	local box: { [BasePart]: { Vector3 } } = {}
	local function cells(lo: Vector3, hi: Vector3, fn: (number) -> ())
		for x = math.floor(lo.X / CELL), math.floor(hi.X / CELL) do
			for y = math.floor(lo.Y / CELL), math.floor(hi.Y / CELL) do
				for z = math.floor(lo.Z / CELL), math.floor(hi.Z / CELL) do
					fn((x + 512) * 1048576 + (y + 512) * 1024 + (z + 512))
				end
			end
		end
	end
	for _, p in all do
		local lo, hi = bounds(p)
		box[p] = { lo, hi }
		cells(lo, hi, function(k: number)
			local c = grid[k]
			if not c then
				c = {}
				grid[k] = c
			end
			table.insert(c, p)
		end)
	end
	local seen: { [BasePart]: boolean } = {}
	local out: { BasePart } = {}
	for _, f in focus do
		local fb = box[f]
		if fb then
			cells(fb[1], fb[2], function(k: number)
				for _, q in grid[k] or {} do
					if not seen[q] then
						local qb = box[q]
						if
							qb[1].X <= fb[2].X
							and fb[1].X <= qb[2].X
							and qb[1].Y <= fb[2].Y
							and fb[1].Y <= qb[2].Y
							and qb[1].Z <= fb[2].Z
							and fb[1].Z <= qb[2].Z
						then
							seen[q] = true
							table.insert(out, q)
						end
					end
				end
			end)
		end
	end
	return out
end

-- Separates every coplanar overlap among the visible parts under `root` (see Options). Returns faces moved and the
-- pairs it could not separate (both parts fixed).
function Coplanar.separate(root: Instance, eps: number, options: Options?): (number, number)
	local o: Options = options or {}
	local movable, skipDown = o.movable, o.skipUndersides == true
	local parts: { BasePart } = {}
	for _, d in (if o.childrenOnly then root:GetChildren() else root:GetDescendants()) do
		if d:IsA("BasePart") and visible(d) then
			table.insert(parts, d)
		end
	end
	-- the first pass looks at everything; later passes only at what moved and what touches it
	local total, stuck = 0, 0
	local scope = parts
	for _ = 1, PASSES do
		local moved, left, touched = pass(scope, eps, movable, skipDown)
		total += moved
		stuck = left
		if moved == 0 then
			break
		end
		scope = neighbours(parts, touched, 2 * eps)
	end
	return total, stuck
end

return Coplanar
