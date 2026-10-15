-- Studio Command Bar helper (based on the Kick Sacks package's ImportRenameCommandBar.lua). Run it AFTER
-- File > Import 3D of assets/sacks/kick-sacks-all.glb (one import, recommended) or of the 20 single GLBs.
-- It finds the imported sacks anywhere in Workspace, strips Blender's ".001" name suffixes so the part names
-- match the original GLB node names again, and moves them to ReplicatedStorage > SackAssets > Meshes as
-- Sack_01 .. Sack_20 (replacing older copies). It does NOT import files: Lua can't read your disk.
local RS = game:GetService("ReplicatedStorage")
local assets = RS:FindFirstChild("SackAssets") or Instance.new("Folder")
assets.Name = "SackAssets"
assets.Parent = RS
local meshes = assets:FindFirstChild("Meshes") or Instance.new("Folder")
meshes.Name = "Meshes"
meshes.Parent = assets

local function tierFrom(name)
	local lower = name:lower()
	local n = lower:match("^sack[%s_%-]*0?(%d%d?)$") or lower:match("kick[%s_%-]*sack[%s_%-]*0?(%d%d?)")
	n = tonumber(n)
	if n and n >= 1 and n <= 20 then
		return n
	end
end

local found = {}
for _, inst in ipairs(workspace:GetDescendants()) do
	if inst:IsA("Model") then
		local n = tierFrom(inst.Name)
		if n and not found[n] then
			found[n] = inst
		end
	end
end

local moved = 0
for n, model in pairs(found) do
	local dest = string.format("Sack_%02d", n)
	local old = meshes:FindFirstChild(dest)
	if old then
		warn("Replacing the older " .. dest)
		old:Destroy()
	end
	for _, d in ipairs(model:GetDescendants()) do
		local clean = d.Name:gsub("%.%d%d%d$", "")
		if clean ~= d.Name then
			d.Name = clean
		end
	end
	model.Name = dest
	model.Parent = meshes
	moved += 1
	print("Prepared " .. dest .. " (" .. #model:GetDescendants() .. " objects)")
end

-- the single-file import leaves an empty wrapper model behind
for _, inst in ipairs(workspace:GetChildren()) do
	if inst:IsA("Model") and inst.Name:lower():find("kick") and #inst:GetDescendants() == 0 then
		inst:Destroy()
	end
end

local missing = {}
for i = 1, 20 do
	if not meshes:FindFirstChild(string.format("Sack_%02d", i)) then
		table.insert(missing, string.format("Sack_%02d", i))
	end
end
if #missing > 0 then
	warn("Missing: " .. table.concat(missing, ", "))
end
print(string.format("Done: moved %d, %d of 20 sacks in %s", moved, 20 - #missing, meshes:GetFullName()))
