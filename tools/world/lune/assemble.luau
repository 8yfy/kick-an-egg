-- Builds assets/world/WorldAssets.rbxm from every kit that has both a Blender manifest (tools/world/out/<Kit>.
-- manifest.json, per-part bounds in Blender axes) and uploaded mesh ids (tools/world/ids/<Kit>.meshes.txt,
-- "Asset__Role=meshId;..."). Each asset becomes a Model (pivot = the asset's origin, its base centre) holding one
-- MeshPart per colour role, placed at the part's bounds centre. Blender (x, y, z) -> Roblox (-x, z, y).
--   lune run tools/world/lune/assemble.luau Nature Hub Zones1 ...
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Instance = roblox.Instance
local V3 = roblox.Vector3.new
local OUT = "assets/world/WorldAssets.rbxm"

local root = Instance.new("Folder")
root.Name = "WorldAssets"
local total, missing = 0, 0
for _, kitName in process.args do
	local manifest = serde.decode("json", fs.readFile(`tools/world/out/{kitName}.manifest.json`))
	local ids: { [string]: string } = {}
	for pair in string.gmatch(fs.readFile(`tools/world/ids/{kitName}.meshes.txt`), "[^;%s]+") do
		local k, v = string.match(pair, "^(.-)=(%d+)$")
		if k then
			ids[k] = v
		end
	end
	local kitFolder = Instance.new("Folder")
	kitFolder.Name = kitName
	local names = {}
	for assetName in manifest do
		table.insert(names, assetName)
	end
	table.sort(names)
	for _, assetName in names do
		local spec = manifest[assetName]
		local model = Instance.new("Model")
		model.Name = assetName
		local lo, hi = spec.min, spec.max
		-- footprint and height in Roblox axes, for placement code (X, Y = up, Z)
		model:SetAttribute("Size", V3(hi[1] - lo[1], hi[3] - lo[3], hi[2] - lo[2]))
		for role, b in spec.parts do
			local id = ids[`{assetName}__{role}`]
			if not id then
				missing += 1
				print(`missing mesh id: {assetName}__{role}`)
				continue
			end
			local size = V3(b.max[1] - b.min[1], b.max[3] - b.min[3], b.max[2] - b.min[2])
			local c = V3(-(b.max[1] + b.min[1]) / 2, (b.max[3] + b.min[3]) / 2, (b.max[2] + b.min[2]) / 2)
			local p = Instance.new("MeshPart")
			p.Name = role
			p.MeshContent = roblox.Content.fromUri(`rbxassetid://{id}`)
			p.InitialSize = size
			p.Size = size
			p.CFrame = roblox.CFrame.new(c)
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CollisionFidelity = roblox.Enum.CollisionFidelity.Box
			p.RenderFidelity = roblox.Enum.RenderFidelity.Automatic
			p.Material = roblox.Enum.Material.SmoothPlastic
			p.Parent = model
			total += 1
		end
		model.WorldPivot = roblox.CFrame.new()
		model.Parent = kitFolder
	end
	kitFolder.Parent = root
end
fs.writeDir("assets/world")
fs.writeFile(OUT, roblox.serializeModel({ root }))
print(`WorldAssets: {total} mesh parts, {missing} missing -> {OUT}`)
