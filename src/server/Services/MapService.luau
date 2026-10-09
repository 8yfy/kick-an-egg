--!strict
-- Builds Partner A's map (workspace.Map) once when the server starts, and puts every character in
-- the "Players" collision group so the map's PlayerBarrier (canyon mouth) stops players while
-- steered eggs ("Eggs") drive through it.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PLAYERS_GROUP = "Players"

local MapService = {}

local function setGroup(part: Instance)
	if part:IsA("BasePart") then
		part.CollisionGroup = PLAYERS_GROUP
	end
end

local function onCharacter(character: Model)
	if not PhysicsService:IsCollisionGroupRegistered(PLAYERS_GROUP) then
		return -- no map v3 groups (MapBuilder missing): leave the default group
	end
	for _, d in character:GetDescendants() do
		setGroup(d)
	end
	character.DescendantAdded:Connect(setGroup) -- accessories, tools added later
end

function MapService:Init()
	local builders = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Builders")
	local mapFolder = builders:FindFirstChild("Map")
	local module = mapFolder and mapFolder:FindFirstChild("MapBuilder")
	if not module or not module:IsA("ModuleScript") then
		warn("[MapService] MapBuilder not found; no map built")
		return
	end
	local started = os.clock()
	local MapBuilder = (require :: any)(module)
	MapBuilder.build()
	print(`[MapService] map built in {string.format("%.2f", os.clock() - started)} s`)
end

function MapService:Start()
	local function watch(player: Player)
		if player.Character then
			onCharacter(player.Character)
		end
		player.CharacterAdded:Connect(onCharacter)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
end

return MapService
