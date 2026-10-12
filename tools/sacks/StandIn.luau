--!strict
-- DEV ONLY (tools/preview, Studio): builds stand-ins for the 20 GLB imports from tools/sacks/standin/TierNN
-- (generated from the original GLBs by tools/sacks/glb2luau.py). Each GLB node becomes a MeshPart built with
-- EditableMesh, named after the node, in a Model named Sack_NN: the same shape Studio's File > Import gives,
-- so SackModules/SackModel and Builders/SackGeometry can be verified before the real import. Geometry is the
-- GLB's own triangles (glTF frame, 1 stud = 1 metre). Never used by the game.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StandIn = {}

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local LOOKUP: { [number]: number } = {}
for i = 1, #ALPHABET do
	LOOKUP[string.byte(ALPHABET, i)] = i - 1
end

local function decode(s: string): buffer
	local n = #s
	local pad = (if string.sub(s, n, n) == "=" then 1 else 0) + (if string.sub(s, n - 1, n - 1) == "=" then 1 else 0)
	local out = buffer.create(n // 4 * 3 - pad)
	local o = 0
	for i = 1, n, 4 do
		local a, b, c, d = string.byte(s, i, i + 3)
		local v = bit32.lshift(LOOKUP[a], 18) + bit32.lshift(LOOKUP[b], 12) + bit32.lshift(LOOKUP[c] or 0, 6) + (LOOKUP[d] or 0)
		buffer.writeu8(out, o, bit32.rshift(v, 16))
		if c ~= 61 then
			buffer.writeu8(out, o + 1, bit32.band(bit32.rshift(v, 8), 255))
		end
		if d ~= 61 then
			buffer.writeu8(out, o + 2, bit32.band(v, 255))
		end
		o += 3
	end
	return out
end

-- One Sack_NN model from its data module.
function StandIn.build(tier: number, module: ModuleScript): Model
	local d = (require :: any)(module)
	local buf = decode(d.data)
	local o = 0
	local model = Instance.new("Model")
	model.Name = string.format("Sack_%02d", tier)
	for _, p in d.parts do
		local name, mat, nv, nt = p[1], p[2], p[3], p[4]
		local pos = table.create(nv)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for i = 1, nv do
			local v = Vector3.new(buffer.readf32(buf, o), buffer.readf32(buf, o + 4), buffer.readf32(buf, o + 8))
			pos[i] = v
			lo, hi = lo:Min(v), hi:Max(v)
			o += 12
		end
		local nrm = table.create(nv)
		for i = 1, nv do
			nrm[i] = Vector3.new(buffer.readi8(buf, o), buffer.readi8(buf, o + 1), buffer.readi8(buf, o + 2)) / 127
			o += 3
		end
		local center = (lo + hi) / 2
		local em = AssetService:CreateEditableMesh()
		local vids, nids = table.create(nv), table.create(nv)
		for i = 1, nv do
			vids[i] = em:AddVertex(pos[i] - center)
			nids[i] = em:AddNormal(nrm[i])
		end
		for _ = 1, nt do
			local a, b, c = buffer.readu16(buf, o) + 1, buffer.readu16(buf, o + 2) + 1, buffer.readu16(buf, o + 4) + 1
			o += 6
			local face = em:AddTriangle(vids[a], vids[b], vids[c])
			em:SetFaceNormals(face, { nids[a], nids[b], nids[c] })
		end
		local ok, part = pcall(function()
			return AssetService:CreateMeshPartAsync(Content.fromObject(em))
		end)
		if ok and part then
			part.Name = name
			part.CFrame = CFrame.new(center)
			part.Anchored = true
			part:SetAttribute("SourceMaterial", mat)
			part.Parent = model
		else
			warn(`[StandIn] {model.Name}.{name}: {part}`)
		end
	end
	model.WorldPivot = CFrame.new()
	return model
end

-- ReplicatedStorage.SackAssets.Meshes.Sack_01..20 from `data` (the generated TierNN modules). Returns the count.
function StandIn.install(data: Instance, tiers: { number }?): number
	local assets = ReplicatedStorage:FindFirstChild("SackAssets") or Instance.new("Folder")
	assets.Name = "SackAssets"
	assets.Parent = ReplicatedStorage
	local meshes = assets:FindFirstChild("Meshes") or Instance.new("Folder")
	meshes.Name = "Meshes"
	meshes.Parent = assets
	local n = 0
	for _, tier in tiers or { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 } do
		local module = data:FindFirstChild(string.format("Tier%02d", tier))
		if module and module:IsA("ModuleScript") then
			local model = StandIn.build(tier, module)
			model:SetAttribute("StandIn", true)
			model.Parent = meshes
			n += 1
		end
	end
	return n
end

return StandIn
