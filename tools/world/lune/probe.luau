local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local Instance = roblox.Instance
local folder = Instance.new("Folder")
folder.Name = "WorldAssets"
local m = Instance.new("Model")
m.Name = "ProbeTree"
local function mp(name, id, size, pos)
	local p = Instance.new("MeshPart")
	p.Name = name
	p.MeshContent = roblox.Content.fromUri("rbxassetid://" .. id)
	p.InitialSize = size
	p.Size = size * 0.01
	p.CFrame = roblox.CFrame.new(pos * 0.01)
	p.CollisionFidelity = roblox.Enum.CollisionFidelity.Box
	p.Anchored = true
	p.CanCollide = false
	p.Parent = m
	return p
end
local V = roblox.Vector3.new
mp("Leaf", "131974443091897", V(635.18, 612.94, 637.63), V(12.08, 789.39, -5.01))
mp("LeafDark", "86112257900265", V(424.00, 372.79, 449.12), V(-117.66, 657.12, 53.21))
mp("Trunk", "132787985682229", V(173.26, 700.00, 160.73), V(40.42, 349.99, -6.26))
m.Parent = folder
fs.writeDir("assets/world")
fs.writeFile("assets/world/WorldAssets.rbxm", roblox.serializeModel({ folder }))
local back = roblox.deserializeModel(fs.readFile("assets/world/WorldAssets.rbxm"))
print("roundtrip", back[1].ProbeTree.Leaf.MeshContent, back[1].ProbeTree.Leaf.InitialSize)
