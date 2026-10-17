local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local inst = roblox.deserializeModel(fs.readFile(process.args[1]))
local n = 0
for _, root in inst do
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") and n < 2 then
			n += 1
			for _, prop in
				{
					"MeshId",
					"MeshContent",
					"InitialSize",
					"Size",
					"TextureID",
					"CollisionFidelity",
					"RenderFidelity",
					"DoubleSided",
				}
			do
				local ok, v = pcall(function()
					return (d :: any)[prop]
				end)
				print(d:GetFullName(), prop, ok, v)
			end
		end
	end
end
