--!strict
-- Client loader: requires every ModuleScript in Controllers/, calls all :Init(), then all :Start().

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Controller = { Init: ((any) -> ())?, Start: ((any) -> ())? }

-- Hand-off point: A's KICK button fires this with the timing value; KickController listens.
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
if not sharedFolder:FindFirstChild("KickPressed") then
	local kickPressed = Instance.new("BindableEvent")
	kickPressed.Name = "KickPressed"
	kickPressed.Parent = sharedFolder
end

local controllersFolder = script.Parent:WaitForChild("Controllers")

local modules: { ModuleScript } = {}
for _, child in controllersFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		table.insert(modules, child)
	end
end
table.sort(modules, function(a, b)
	return a.Name < b.Name
end)

local controllers: { [string]: Controller } = {}
for _, module in modules do
	controllers[module.Name] = (require :: any)(module)
end

for _, module in modules do
	local controller = controllers[module.Name]
	if controller.Init then
		controller:Init()
	end
end

for _, module in modules do
	local controller = controllers[module.Name]
	if controller.Start then
		task.spawn(function()
			controller:Start()
		end)
	end
end

print(`[Client] {#modules} controllers started`)
