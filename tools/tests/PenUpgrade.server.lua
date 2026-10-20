-- QA harness only: insert as a Script in an UNPUBLISHED Studio play session, then run PenUpgrade.client.lua.
-- Not mapped by Rojo. Never run against published/player data.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0, "Requires unpublished QA place")
local RS = game:GetService("ReplicatedStorage")
local Services = game.ServerScriptService.Server.Services
local Data = require(Services.DataService)
local Plot = require(Services.PlotService)
local Remotes = require(RS.Shared.Remotes)
local qa = Instance.new("RemoteFunction")
qa.Name = "PenUpgradeQA"
qa.OnServerInvoke = function(player, action)
	local data = Data:WaitForData(player)
	if action == "fund" then
		Data:Set(player, { money = 1e12 })
	elseif action == "empty" then
		Data:Set(player, { money = 0 })
	elseif action == "duplicate" then
		Remotes.get("DataChanged"):FireClient(player, { penLevel = data.penLevel })
		Remotes.get("DataChanged"):FireClient(player, { penLevel = data.penLevel - 1 })
		Remotes.get("DataChanged"):FireClient(player, { penLevel = data.penLevel })
	elseif action == "other" then
		local other = workspace.Map.SafeZone.Bases.Base2
		assert(other ~= Plot:GetBase(player))
		other:SetAttribute("OwnerUserId", -999)
		other:SetAttribute("PenLevel", (other:GetAttribute("PenLevel") or 1) + 1)
	elseif action == "pet" then
		local pets = table.clone(data.pets)
		pets.PenQAPet = { petId = "sprout_pup", size = "Normal", weather = "Normal" }
		Data:Set(player, { pets = pets })
		local area = Plot:GetBase(player).PenArea
		player.Character:PivotTo(area.CFrame + Vector3.new(0, 4, 0))
		assert(Plot:PlacePet(player, "PenQAPet", nil))
	elseif action == "status" then
		return {
			level = data.penLevel,
			money = data.money,
			pet = data.pets.PenQAPet,
			cost = require(Services.RackService).penCost(data.penLevel),
		}
	end
	return true
end
qa.Parent = RS
