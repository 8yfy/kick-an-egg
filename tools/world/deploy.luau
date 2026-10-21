-- DEV ONLY (Studio, Edit): swap in the deploy rbxm built by tools/world/deploy.sh. Set PATH first.
local PATH = "rbxasset://kte/deploy.rbxm"
local root = game:GetObjects(PATH)[1]
local RS = game:GetService("ReplicatedStorage")
local targets = {
	Shared = RS,
	WorldAssets = RS,
	Server = game:GetService("ServerScriptService"),
	Client = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"),
}
local done = {}
for name, parent in targets do
	local new = root:FindFirstChild(name)
	if new then
		local old = parent:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		new.Parent = parent
		table.insert(done, name)
	end
end
return "deployed " .. table.concat(done, ", ")
