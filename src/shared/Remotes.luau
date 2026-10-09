--!strict
-- CONTRACT FILE: change only via a `contract:` PR.
-- Server creates the folder; client waits for it. All C->S remotes are rate-limited on the server.
--
-- C->S  RequestKick(timing: number 0..1)
-- S->C  KickResult({ zonesCrossed: {number}, landZone: number, distance: number,
--                     eggModel: string, petId: string, size: string?, weather: string?, eggUid: string })
-- C->S  PlaceEgg(eggUid: string, slot: number)
-- S->C  EggHatched({ eggUid: string, slot: number, petUid: string })
-- C->S  BuyUpgrade(kind: "KickPower" | "RunSpeed")
-- C->S  Rebirth()
-- C->S  SellPet(petUid: string)
-- S->C  DataChanged(partial: {[string]: any})
-- S->C  WeatherChanged(weather: string?, endsAt: number?)
-- S->C  Announce(text: string, rarity: string)
-- C->S  TradeRequest / TradeRespond / TradeOffer / TradeConfirm (Partner B defines payloads in TradeService)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = {
	"RequestKick", "KickResult", "PlaceEgg", "EggHatched", "BuyUpgrade", "Rebirth",
	"SellPet", "DataChanged", "WeatherChanged", "Announce",
	"TradeRequest", "TradeRespond", "TradeOffer", "TradeConfirm",
}

local folder: Folder
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in EVENTS do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

local Remotes = {}
function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end
return Remotes
