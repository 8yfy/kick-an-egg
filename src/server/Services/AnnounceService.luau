--!strict
-- Server-wide announcements. Rolls of a rarity with `announce = true` (Legendary+) are broadcast
-- as soon as they are kicked: Announce(text, rarity) to all clients (A's UI shows the banner).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pets = require(Shared.Config.Pets)
local Rarities = require(Shared.Config.Rarities)
local Remotes = require(Shared.Remotes)

local KickService = require(script.Parent.KickService)

local AnnounceService = {}

local announce: RemoteEvent
local petNames: { [string]: string } = {}
for _, pet in Pets do
	petNames[pet.id] = pet.name
end

function AnnounceService:Announce(text: string, rarity: string)
	announce:FireAllClients(text, rarity)
end

-- "Kai kicked a Huge Sunny Prism Seraph (Secret)!"
function AnnounceService.describe(name: string, petId: string, rarity: string, size: string?, weather: string?): string
	local parts = {}
	if size then
		table.insert(parts, size)
	end
	if weather then
		table.insert(parts, weather)
	end
	table.insert(parts, petNames[petId] or petId)
	return `{name} kicked a {table.concat(parts, " ")} ({rarity})!`
end

function AnnounceService:Init()
	announce = Remotes.get("Announce")
end

function AnnounceService:Start()
	KickService:OnKick(function(player, result)
		local rarity = Rarities[result.rarity]
		if rarity and rarity.announce then
			self:Announce(
				AnnounceService.describe(player.DisplayName, result.petId, result.rarity, result.size, result.weather),
				result.rarity
			)
		end
	end)
end

return AnnounceService
