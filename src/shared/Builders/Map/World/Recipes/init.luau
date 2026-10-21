--!strict
-- Partner A. All classic brick model recipes by asset name: every child module returns { recipes = { [name] = fn } }
-- where fn(model, rng) builds the asset in asset space with World/Brick (origin = base centre, front = -Z).
local Recipes: { [string]: (Model, Random) -> () } = {}

for _, mod in script:GetChildren() do
	if mod:IsA("ModuleScript") then
		local list = (require(mod) :: any).recipes
		for name, fn in list do
			assert(Recipes[name] == nil, `duplicate recipe {name}`)
			Recipes[name] = fn
		end
	end
end

return Recipes
