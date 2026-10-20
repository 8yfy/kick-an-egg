--!strict
-- Server loader: requires every ModuleScript in Services/, calls all :Init(), then all :Start().

type Service = { Init: ((any) -> ())?, Start: ((any) -> ())? }

local servicesFolder = script.Parent:WaitForChild("Services")

local modules: { ModuleScript } = {}
for _, child in servicesFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		table.insert(modules, child)
	end
end
table.sort(modules, function(a, b)
	return a.Name < b.Name
end)

local services: { [string]: Service } = {}
for _, module in modules do
	services[module.Name] = (require :: any)(module)
end

for _, module in modules do
	local service = services[module.Name]
	local init = service.Init
	if init then
		init(service)
	end
end

for _, module in modules do
	local service = services[module.Name]
	local start = service.Start
	if start then
		task.spawn(start, service)
	end
end

print(`[Server] {#modules} services started`)
