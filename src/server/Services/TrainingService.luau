--!strict
-- Training pad: every Economy.Training.tickSeconds a player standing on their training pad gains
-- Training.pads[trainingPad].gain speedMultiplier (capped at maxMultiplier). Egg speed in a chase
-- = runSpeed x speedMultiplier. No training while steering an egg.
--
-- Which pad: the player's base `Base<i>.TrainingPad`, else a shared `Map.SafeZone.TrainingPad`
-- (both built by Partner A), else a plain placeholder pad this service creates in workspace.Gameplay.
-- Player attribute "OnTrainingPad" (boolean) lets A's UI show a training indicator.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chase = require(Shared.Config.Chase)
local Economy = require(Shared.Config.Economy)

local DataService = require(script.Parent.DataService)
local KickService = require(script.Parent.KickService)
local PlotService = require(script.Parent.PlotService)

local PAD_EDGE_SLACK = 1 -- studs outside the pad that still count
local PAD_HEIGHT_ABOVE = 8 -- HumanoidRootPart may be this far above the pad's top
local PLACEHOLDER_SIZE = Vector3.new(10, 0.4, 10)
local PLACEHOLDER_BACK = 16 -- studs behind the safe line, in the aisle between the bases

local TrainingService = {}

local placeholder: BasePart? = nil

local function safeZonePad(): BasePart?
	local map = workspace:FindFirstChild("Map")
	local safeZone = map and map:FindFirstChild("SafeZone")
	local pad = safeZone and safeZone:FindFirstChild("TrainingPad")
	return if pad and pad:IsA("BasePart") then pad else nil
end

local function ensurePlaceholder(): BasePart
	if placeholder and placeholder.Parent then
		return placeholder
	end
	local folder = workspace:FindFirstChild("Gameplay") or Instance.new("Folder")
	folder.Name = "Gameplay"
	folder.Parent = workspace
	local pad = Instance.new("Part")
	pad.Name = "TrainingPad"
	pad.Size = PLACEHOLDER_SIZE
	pad.CFrame = CFrame.new(0, PLACEHOLDER_SIZE.Y / 2, Chase.SafeLineZ - PLACEHOLDER_BACK)
	pad.Anchored = true
	pad.Parent = folder
	placeholder = pad
	return pad
end

-- The pad this player trains on.
function TrainingService:GetPad(player: Player): BasePart
	local base = PlotService:GetBase(player)
	local own = base and base:FindFirstChild("TrainingPad", true)
	if own and own:IsA("BasePart") then
		return own
	end
	return safeZonePad() or ensurePlaceholder()
end

function TrainingService.isOnPad(pad: BasePart, position: Vector3): boolean
	local rel = pad.CFrame:PointToObjectSpace(position)
	local half = pad.Size / 2
	return math.abs(rel.X) <= half.X + PAD_EDGE_SLACK
		and math.abs(rel.Z) <= half.Z + PAD_EDGE_SLACK
		and rel.Y >= 0
		and rel.Y <= half.Y + PAD_HEIGHT_ABOVE
end

-- New multiplier after one tick on a pad of `level` (pure; used by the tests).
function TrainingService.trained(multiplier: number, level: number): number
	local training = Economy.Training
	local pad = training.pads[math.clamp(level, 1, #training.pads)]
	local value = math.min(multiplier + pad.gain, training.maxMultiplier)
	return math.floor(value * 10000 + 0.5) / 10000 -- keep saves tidy
end

local function trainTick()
	for _, player in Players:GetPlayers() do
		local data = DataService:Get(player)
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local onPad = data ~= nil
			and hrp ~= nil
			and hrp:IsA("BasePart")
			and humanoid ~= nil
			and humanoid.Health > 0
			and not KickService:GetActive(player)
			and TrainingService.isOnPad(TrainingService:GetPad(player), hrp.Position)
		player:SetAttribute("OnTrainingPad", onPad)
		if onPad and data then
			local multiplier = TrainingService.trained(data.speedMultiplier, data.trainingPad)
			if multiplier ~= data.speedMultiplier then
				DataService:Set(player, { speedMultiplier = multiplier })
			end
		end
	end
end

local function mapHasPads(): boolean
	if safeZonePad() then
		return true
	end
	local map = workspace:FindFirstChild("Map")
	local bases = map and map:FindFirstChild("SafeZone") and map.SafeZone:FindFirstChild("Bases")
	return bases ~= nil and bases:FindFirstChild("TrainingPad", true) ~= nil
end

function TrainingService:Start()
	if not mapHasPads() then
		ensurePlaceholder() -- so there's always somewhere to train before A's pads exist
	end
	task.spawn(function()
		while true do
			task.wait(Economy.Training.tickSeconds)
			trainTick()
		end
	end)
end

return TrainingService
