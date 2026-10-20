--!strict
-- Observes existing server gameplay. First pet + a brief income introduction finish the main tutorial;
-- upgrades are optional client tips. There are no tutorial rewards, teleports or gameplay modifiers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rules = require(Shared.Tutorial.Rules)
local KickPad = require(Shared.KickPad)
local Economy = require(Shared.Config.Economy)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local KickService = require(script.Parent.KickService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local RateLimiter = require(script.Parent.Parent.Util.RateLimiter)
local TutorialService = { Steps = Rules.Steps }
local S = Rules.Steps
local limiter = RateLimiter.new()
type State = { character: Model?, hits: number, money: number, earned: boolean, petAt: number?, updating: boolean }
local states: { [Player]: State } = {}

-- Compatibility for the existing server test harness; the shared decision function is also used by replay.
function TutorialService.stepFor(data: { [string]: any }, onPad: boolean, earned: boolean): number
	return Rules.choose(data, { onPad = onPad, incomeExplained = earned })
end

local function baseFor(player: Player): Model?
	local map = workspace:FindFirstChild("Map")
	local safe = map and map:FindFirstChild("SafeZone")
	local bases = safe and safe:FindFirstChild("Bases")
	local index = player:GetAttribute("BaseIndex")
	local base = bases and typeof(index) == "number" and bases:FindFirstChild("Base" .. index)
	return if base and base:IsA("Model") and base:GetAttribute("OwnerUserId") == player.UserId then base else nil
end

local function hasSack(player: Player): boolean
	for _, holder in { player:FindFirstChild("SackGear"), player.Character, player:FindFirstChildOfClass("Backpack") } do
		if holder then
			for _, tool in holder:GetChildren() do
				if tool:IsA("Tool") and tool:GetAttribute("KickSack") then
					return true
				end
			end
		end
	end
	return false
end

local function update(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local tutorial = data.tutorial
	if tutorial.done or tutorial.skipped then
		player:SetAttribute("TutorialStep", 0)
		return
	end
	local state = states[player]
	if not state then
		state = { character = nil, hits = 0, money = data.money, earned = false, updating = false }
		states[player] = state
		-- Older profiles already above base power should not repeat starter training after migration.
		if data.kickPower > Economy.KickPower.base then
			local saved = table.clone(tutorial)
			saved.trained = true
			DataService:Set(player, { tutorial = saved })
			tutorial = saved
		end
	end
	if state.updating then
		return
	end
	state.updating = true
	local character = player.Character
	if character ~= state.character then
		state.character, state.hits = character, 0
	end
	local hits = if character then character:GetAttribute("SackHits") else nil
	local total = if typeof(hits) == "number" then math.max(0, math.floor(hits)) else 0
	local trainingHits, high = Rules.trainingProgress(tutorial.trainingHits or 0, state.hits, total)
	state.hits = high
	local base = baseFor(player)
	local area = base and base:FindFirstChild("PenArea")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local inPen = false
	if area and area:IsA("BasePart") and root and root:IsA("BasePart") then
		local p = area.CFrame:PointToObjectSpace(root.Position)
		inPen = math.abs(p.X) <= area.Size.X / 2 and math.abs(p.Z) <= area.Size.Z / 2 and math.abs(p.Y) < 12
	end
	if trainingHits ~= (tutorial.trainingHits or 0) or (inPen and not tutorial.foundPen) then
		local saved = table.clone(tutorial)
		saved.trainingHits = trainingHits
		saved.trained = tutorial.trained == true or trainingHits >= Rules.TRAIN_HITS
		saved.foundPen = tutorial.foundPen == true or inPen
		DataService:Set(player, { tutorial = saved })
		tutorial = saved
	end
	local petPlaced = false
	for _, pet in data.pets do
		if typeof(pet) == "table" and pet.placed then
			petPlaced = true
			break
		end
	end
	if petPlaced then
		state.petAt = state.petAt or os.clock()
		if data.money > state.money and (player:GetAttribute("IncomePerSecond") or 0) > 0 then
			state.earned = true
		end
	else
		state.petAt, state.earned = nil, false
	end
	state.money = data.money
	local age = if state.petAt then os.clock() - state.petAt else 0
	-- The income sentence is observational. A delayed income tick never forces a purchase or fake payment.
	local explained = age >= 2 and (state.earned or age >= 5)
	local step = Rules.choose(data, {
		active = KickService:GetActive(player) ~= nil,
		onPad = character ~= nil and KickPad.has(character, KickPad.ACCEPT_RADIUS),
		hasPen = base ~= nil,
		hasSack = hasSack(player),
		incomeExplained = explained,
	})
	player:SetAttribute("TutorialHits", trainingHits)
	if step == S.DONE then
		local saved = table.clone(tutorial)
		saved.done, saved.skipped = true, false
		DataService:Set(player, { tutorial = saved })
		Analytics.custom(player, "TutorialDone", 1)
		player:SetAttribute("TutorialIncomeObserved", state.earned)
		player:SetAttribute("TutorialDone", true)
		step = 0
	end
	if player:GetAttribute("TutorialStep") ~= step then
		player:SetAttribute("TutorialStep", step)
	end
	state.updating = false
end

function TutorialService:Start()
	Remotes.get("SkipTutorial").OnServerEvent:Connect(function(player: Player)
		local data = DataService:Get(player)
		if not limiter:allow(player) or not data or data.tutorial.done then
			return
		end
		local saved = table.clone(data.tutorial)
		saved.skipped = true
		DataService:Set(player, { tutorial = saved })
		player:SetAttribute("TutorialStep", 0)
	end)
	DataService:OnChanged(function(player)
		local state = states[player]
		if not state or not state.updating then
			update(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(update, player)
				if not ok then
					if states[player] then
						states[player].updating = false
					end
					warn(`[TutorialService] {player.Name}: {err}`)
				end
			end
			task.wait(0.25)
		end
	end)
end

return TutorialService
