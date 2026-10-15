-- Lune script: restores the ORIGINAL GLB node names on imported Kick Sack parts.
-- Studio's 3D importer de-duplicates names across one import, and the 20 sacks share node names (every sack has a
-- ceiling_mount, chain_link_0 ...), so a single-file import comes back as "ceiling_mount3", "chain_link_03",
-- "..._Node" and so on, which SackColors (original materials) and SackAura (wings, eyes) can't look up. Text alone
-- is ambiguous ("fray_113" = fray_1 + 13 or fray_11 + 3), so each part is matched to its node by GEOMETRY: the
-- part's world bounding-box centre and size against the node's, computed from the original GLB by
-- tools/sacks/glb_nodes.py (same scale and axes; the import only moves the sacks, which is solved per sack).
--
--   lune run tools/sacks/fix-import-names.luau assets/sacks/SackAssets.rbxm <glb-node-bounds.json>
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local Vector3 = roblox.Vector3

local rbxmPath = process.args[1] or "assets/sacks/SackAssets.rbxm"
local nodesPath = process.args[2]
assert(nodesPath, "usage: lune run fix-import-names.luau <SackAssets.rbxm> <glb-node-bounds.json>")
local allNodes = serde.decode("json", fs.readFile(nodesPath))
local roots = roblox.deserializeModel(fs.readFile(rbxmPath))
local assets = roots[1]
local meshes = assets:FindFirstChild("Meshes")
assert(meshes, "no Meshes folder in " .. rbxmPath)

-- world-space bounding-box size of an oriented part
local function extent(cf, size)
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	local function axis(c)
		return math.abs(r[c]) * size.X + math.abs(u[c]) * size.Y + math.abs(l[c]) * size.Z
	end
	return Vector3.new(axis("X"), axis("Y"), axis("Z"))
end

local function bounds(list)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, v in list do
		lo, hi = lo:Min(v), hi:Max(v)
	end
	return (lo + hi) / 2
end

-- One import applies ONE axis conversion to every sack, so it is chosen over all 20 together: a mirror-symmetric
-- sack matches its mirror image almost as well, and a per-sack choice would swap its left/right parts.
local COMBOS = { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }

local function match(parts, glb, sx, sz)
	local mapped = {}
	for _, g in glb do
		table.insert(mapped, Vector3.new(sx * g.at.X, g.at.Y, sz * g.at.Z))
	end
	local shift = bounds((function()
		local t = {}
		for _, p in parts do
			table.insert(t, p.at)
		end
		return t
	end)()) - bounds(mapped)
	local candidates = {}
	for i, p in parts do
		for j, m in mapped do
			local d = (p.at - (m + shift)).Magnitude + 0.5 * (p.size - glb[j].size).Magnitude
			table.insert(candidates, { d = d, i = i, j = j })
		end
	end
	table.sort(candidates, function(a, b)
		return a.d < b.d
	end)
	local usedP, usedG, assign, cost, maxD = {}, {}, {}, 0, 0
	for _, c in candidates do
		if not usedP[c.i] and not usedG[c.j] then
			usedP[c.i], usedG[c.j] = true, true
			assign[c.i] = c.j
			cost += c.d
			maxD = math.max(maxD, c.d)
		end
	end
	return { cost = cost, assign = assign, maxD = maxD }
end

local sacks, totals = {}, { 0, 0, 0, 0 }
for tier = 1, 20 do
	local sack = meshes:FindFirstChild(string.format("Sack_%02d", tier))
	local nodes = allNodes[tostring(tier)]
	if not sack or not nodes then
		print(string.format("Sack_%02d: missing", tier))
		continue
	end
	local parts = {}
	for _, d in sack:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, { part = d, at = d.CFrame.Position, size = extent(d.CFrame, d.Size) })
		end
	end
	local glb = {}
	for _, n in nodes do
		table.insert(glb, {
			name = n.name,
			at = Vector3.new(n.center[1], n.center[2], n.center[3]),
			size = Vector3.new(n.size[1], n.size[2], n.size[3]),
		})
	end
	local results = {}
	for k, c in COMBOS do
		results[k] = match(parts, glb, c[1], c[2])
		totals[k] += results[k].cost
	end
	table.insert(sacks, { tier = tier, sack = sack, parts = parts, glb = glb, results = results })
end
local pick = 1
for k = 2, 4 do
	if totals[k] < totals[pick] then
		pick = k
	end
end
for k, c in COMBOS do
	print(string.format("axes x%+d z%+d: total cost %.3f%s", c[1], c[2], totals[k], k == pick and "  <- used" or ""))
end

local totalRenamed, worst = 0, 0
for _, s in sacks do
	local tier, sack, parts, glb = s.tier, s.sack, s.parts, s.glb
	local best = s.results[pick]
	local own = pick
	for k = 1, 4 do
		if s.results[k].cost < s.results[own].cost then
			own = k
		end
	end
	local alone =
		string.format("x%+d z%+d, cost %.3f vs %.3f", COMBOS[own][1], COMBOS[own][2], s.results[own].cost, best.cost)
	local renamed = 0
	for i, p in parts do
		local j = best.assign[i]
		if j then
			local name = glb[j].name
			local part = p.part
			if part.Name ~= name then
				renamed += 1
			end
			part.Name = name
			local parent = part.Parent
			-- the importer wraps each node in a Model holding its one MeshPart: give it the node name too
			if parent and parent:IsA("Model") and parent ~= sack then
				local only = 0
				for _, c in parent:GetChildren() do
					if c:IsA("BasePart") then
						only += 1
					end
				end
				if only == 1 then
					parent.Name = name
				end
			end
		end
	end
	totalRenamed += renamed
	worst = math.max(worst, best.maxD)
	print(
		string.format(
			"Sack_%02d: %d parts, %d GLB nodes, %d renamed, worst match %.5f (best alone: %s)",
			tier,
			#parts,
			#glb,
			renamed,
			best.maxD,
			alone
		)
	)
end

fs.writeFile(rbxmPath, roblox.serializeModel(roots))
print(string.format("restored %d names, worst match %.5f studs -> %s", totalRenamed, worst, rbxmPath))
