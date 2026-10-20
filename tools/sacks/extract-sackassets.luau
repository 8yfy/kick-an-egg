-- Lune script: pulls ReplicatedStorage.SackAssets (the imported Kick Sack meshes) out of a saved place file and
-- writes it as assets/sacks/SackAssets.rbxm, so the imports survive Rojo builds without Studio's "Save to File".
--   lune run tools/sacks/extract-sackassets.luau KickTheEgg.rbxl assets/sacks/SackAssets.rbxm [Folder]
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local placePath = process.args[1] or "KickTheEgg.rbxl"
local outPath = process.args[2] or "assets/sacks/SackAssets.rbxm"
local name = process.args[3] or "SackAssets"

local game = roblox.deserializePlace(fs.readFile(placePath))
local folder = game:GetService("ReplicatedStorage"):FindFirstChild(name)
if not folder then
	print(`no ReplicatedStorage.{name} in {placePath}`)
	process.exit(1)
end
local meshes = folder:FindFirstChild("Meshes")
local count, parts = 0, 0
for _, sack in (if meshes then meshes:GetChildren() else {}) do
	count += 1
	for _, d in sack:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
end
fs.writeFile(outPath, roblox.serializeModel({ folder }))
print(`extracted ReplicatedStorage.{name}: {count} sack models, {parts} parts -> {outPath}`)
