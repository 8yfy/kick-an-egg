--!strict
-- CONTRACT FILE: change only via a `contract:` PR.
-- Server creates the folder; client waits for it. All C->S remotes are rate-limited on the server.
--
-- All times are server time (workspace:GetServerTimeNow()). All positions use the axes in Config/Chase.
--
-- C->S  RequestKick(timing: number 0..1)          -- rejected while the player has an active chase
-- S->C  KickResult({ eggUid: string, zonesCrossed: {number}, landZone: number, distance: number,
--                     landPos: Vector3, launchTime: number, flightSeconds: number,
--                     eggModel: string, petId: string, rarity: string, size: string?, weather: string? })
-- S->C  ChaseStart({ eggUid: string, ownerUserId: number, theme: string, startZ: number,
--                     startTime: number, speed: number, eggStartPos: Vector3, eggRunStart: number,
--                     eggModel: string, rarity: string })
--                     -- fired to ALL clients at touchdown; startTime = touchdown + warnSeconds
-- C->S  PickupEgg(eggUid: string)                  -- server checks distance <= Egg.pickupDistance
-- S->C  EggPickedUp({ eggUid: string, userId: number })
-- S->C  EggSecured({ eggUid: string })             -- owner crossed SafeLineZ while carrying it
-- S->C  EggLost({ eggUid: string, reason: "Caught" | "EggCaught" | "Left" })
-- S->C  ChaseEnded({ eggUid: string })             -- avalanche crumbles at the safe line
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
	"RequestKick", "KickResult", "ChaseStart", "PickupEgg", "EggPickedUp", "EggSecured",
	"EggLost", "ChaseEnded", "PlaceEgg", "EggHatched", "BuyUpgrade", "Rebirth",
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
