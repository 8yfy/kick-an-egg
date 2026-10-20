--!strict
-- Contextual presentation of authoritative tutorial progress. The player keeps movement/camera control;
-- holding/placing an egg, finding a pen early, death and changing menus simply re-resolve the current target.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rules = require(Shared.Tutorial.Rules)
local Remotes = require(Shared.Remotes)
local EggKick = require(Shared.Anim.EggKick)
local KickPad = require(Shared.KickPad)
local Economy = require(Shared.Config.Economy)
local UI = script.Parent.Parent.UI
local Data = require(UI.System.Data)
local Spotlight = require(UI.Tutorial.Spotlight)
local WorldGuide = require(UI.Tutorial.WorldGuide)
local Objective = require(UI.Tutorial.Objective)
local Welcome = require(UI.Tutorial.Welcome)
local Focus = require(UI.Tutorial.Focus)
local S = Rules.Steps
local Controller = {}
local player = Players.LocalPlayer
local BINDING = "KickTheEggReactiveTutorial"
local started = false
local gui: ScreenGui?
local spot: any, world: any, objective: any
local welcome: any
local focus: any
local connections: { RBXScriptConnection } = {}
local replay, dismissed, completedHere = false, false, false
local celebrateUntil, flightUntil = 0, 0
local chase = false
local previousStage = 0
local replayPetAt: number? = nil
local replayCharacter: Model? = nil
local replayHits, replayLastHits = 0, 0
local replayTrained = false
local begun, welcomeVisible, completionPending = false, false, false
local optionalSeen: { [string]: boolean } = {}
local optional: { kind: string, untilAt: number, level: number }? = nil

local function hud(): Instance?
	return player.PlayerGui:FindFirstChild("HUD")
end

local function find(parent: Instance?, name: string): GuiObject?
	local found = parent and parent:FindFirstChild(name, true)
	return if found and found:IsA("GuiObject") then found else nil
end

local function base(): Model?
	local map = workspace:FindFirstChild("Map")
	local zone = map and map:FindFirstChild("SafeZone")
	local bases = zone and zone:FindFirstChild("Bases")
	local index = player:GetAttribute("BaseIndex")
	local b = bases and typeof(index) == "number" and bases:FindFirstChild("Base" .. index)
	return if b and b:IsA("Model") and b:GetAttribute("OwnerUserId") == player.UserId then b else nil
end

local function placed(kind: string): Model?
	local b = base()
	local plots = b and b:FindFirstChild("Plots")
	if plots then
		for _, model in plots:GetChildren() do
			if model:IsA("Model") and model:GetAttribute("Kind") == kind then
				return model
			end
		end
	end
	return nil
end

local function held(attribute: string): Tool?
	local c = player.Character
	local tool = c and c:FindFirstChildOfClass("Tool")
	return if tool and tool:GetAttribute(attribute) then tool else nil
end

local function penTarget(): (Vector3?, Instance?, Vector3?, boolean)
	local b = base()
	local area = b and b:FindFirstChild("PenArea")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (area and area:IsA("BasePart") and root and root:IsA("BasePart")) then
		return nil, nil, nil, false
	end
	local p = area.CFrame:PointToObjectSpace(root.Position)
	local inside = math.abs(p.X) < area.Size.X / 2 and math.abs(p.Z) < area.Size.Z / 2
	local floor = if inside
		then area.Position
		else area.CFrame:PointToWorldSpace(Vector3.new(0, 0, -area.Size.Z / 2 - 3))
	return floor, b, floor, inside
end

local function modelTarget(model: Model?): (Vector3?, Instance?, Vector3?)
	if not model then
		return nil, nil, nil
	end
	local cf, size = model:GetBoundingBox()
	return cf.Position + Vector3.new(0, size.Y / 2, 0), model, cf.Position - Vector3.new(0, size.Y / 2, 0)
end

local function shopTarget(): (Vector3?, Instance?, Vector3?)
	local map = workspace:FindFirstChild("Map")
	local shop = map and map:FindFirstChild("BoxingSackShop", true)
	local approach = shop and shop:FindFirstChild("Approach")
	if approach and approach:IsA("BasePart") then
		return approach.Position, shop, approach.Position
	end
	return nil, nil, nil
end

-- A single short sentence, the real UI target, and an optional world destination.
local function view(step: number): (string, GuiObject?, Vector3?, Instance?, Vector3?, boolean)
	local h = hud()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local gamepad = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled and not touch
	if step == S.GET_SACK then
		local p, thing, floor = shopTarget()
		return "Find your free training sack.", nil, p, thing, floor, true
	elseif step == S.TRAIN then
		if not held("KickSack") then
			local hotbar = h and h:FindFirstChild("Hotbar", true)
			local slot = hotbar and hotbar:FindFirstChild("Slot0")
			return "Take out your training sack.", find(slot, "Tile"), nil, nil, nil, false
		end
		local at = player.Character and player.Character:GetAttribute("SackAt")
		local p = if typeof(at) == "CFrame" then at.Position + Vector3.new(0, 4, 0) else nil
		local floor = if p and root and root:IsA("BasePart") then Vector3.new(p.X, root.Position.Y - 3, p.Z) else nil
		return if touch
			then "Tap to train your power."
			elseif gamepad then "Press R2 to train."
			else "Click to train your power.",
			nil,
			p,
			nil,
			floor,
			false
	elseif step == S.KICK_LINE or step == S.PRESS_KICK or step == S.TIME_KICK or step == S.COLLECT then
		local panel = find(h, "KickPanel")
		if panel and panel.Visible then
			local meter = find(panel, "Meter")
			if meter and meter.Visible then
				return if gamepad then "Press R2 when the meter is high." else "Tap when the meter is high.",
					meter,
					nil,
					nil,
					nil,
					false
			end
			return "Press KICK to start.", find(panel, "Kick"), nil, nil, nil, false
		end
		local map = workspace:FindFirstChild("Map")
		local pad = map and map:FindFirstChild("KickPad")
		local p = if pad and pad:IsA("BasePart") then pad.Position else nil
		return if step == S.COLLECT then "Try another kick!" else "Head to the kicking line.", nil, p, pad, p, true
	elseif step == S.WATCH_EGG then
		return if workspace:GetServerTimeNow() < flightUntil
			then "There goes your egg!"
			else "Steer your egg back home!",
			nil,
			nil,
			nil,
			nil,
			false
	elseif step == S.PLACE_EGG or step == S.PLACE_PET then
		local isEgg = step == S.PLACE_EGG
		local tool = held(if isEgg then "EggUid" else "PetUid")
		local p, thing, floor, inside = penTarget()
		if not tool then
			local hotbar = h and h:FindFirstChild("Hotbar", true)
			local tile: GuiObject? = nil
			if hotbar then
				for _, slot in hotbar:GetChildren() do
					local button = find(slot, "Tile")
					if button and button:GetAttribute("ItemKind") == (if isEgg then "Egg" else "Pet") then
						tile = button
						break
					end
				end
			end
			return if isEgg then "Select your egg in the hotbar." else "Select your pet in the hotbar.",
				tile,
				nil,
				nil,
				nil,
				false
		end
		return if inside
			then (if isEgg then "Place your egg on the grass." else "Place your pet on the grass.")
			else "Bring it to your pen.",
			nil,
			p,
			thing,
			floor,
			not inside
	elseif step == S.HATCH then
		local p, thing, floor = modelTarget(placed("Egg"))
		return "Your egg is hatching!", nil, p, thing, floor, false
	elseif step == S.INCOME then
		local p, thing, floor = modelTarget(placed("Pet"))
		return "Your pet earns money for you!",
			find(h and h:FindFirstChild("Counters", true), "Cash"),
			p,
			thing,
			floor,
			false
	elseif step == S.WAIT_PEN then
		return "Your pen will open soon.", nil, nil, nil, nil, false
	end
	return "", nil, nil, nil, nil, false
end

local function finish()
	focus:restore()
	welcome:show(false)
	replay, dismissed, completedHere = false, false, true
	replayPetAt = nil
	celebrateUntil = os.clock() + 2.3
	optional = nil
	objective:optional(false)
	objective:complete()
	spot:set(nil)
	world:set(nil, nil, nil, false)
end

local function clear()
	objective:show(nil)
	spot:set(nil)
	world:set(nil, nil, nil, false)
end

local function optionalView(): boolean
	if not completedHere or dismissed or Data.busy then
		return false
	end
	if optional and os.clock() > optional.untilAt then
		optionalSeen[optional.kind] = true
		optional = nil
	end
	if not optional then
		local pen, speed = Data.pen(), Data.speed()
		if not optionalSeen.Pen and pen.cost and Data.money() >= pen.cost then
			optional = { kind = "Pen", untilAt = os.clock() + 12, level = pen.level }
		elseif not optionalSeen.Speed and speed.cost and Data.money() >= speed.cost then
			optional = { kind = "Speed", untilAt = os.clock() + 12, level = speed.level }
		end
	end
	if not optional then
		return false
	end
	objective:optional(true)
	spot:set(nil)
	if optional.kind == "Pen" then
		if Data.pen().level > optional.level then
			optionalSeen.Pen = true
			optional = nil
			return false
		end
		local b = base()
		local sign = b and b:FindFirstChild("PenSign")
		local p = if sign and sign:IsA("BasePart") then sign.Position else nil
		objective:show("More room? Upgrade your pen.", 4)
		world:set(p and p + Vector3.new(0, 5, 0), sign, p, true)
	else
		if Data.speed().level > optional.level then
			optionalSeen.Speed = true
			optional = nil
			return false
		end
		local p, thing, floor = shopTarget()
		objective:show("Faster eggs? Visit the sack shop.", 4)
		world:set(p, thing, floor, true)
	end
	return true
end

function Controller:Replay()
	if not started then
		return
	end
	replay, dismissed, completedHere = true, false, false
	celebrateUntil, previousStage = 0, 0
	replayPetAt, optional = nil, nil
	optionalSeen = {}
	replayCharacter = player.Character
	replayLastHits = if replayCharacter then (replayCharacter:GetAttribute("SackHits") or 0) else 0
	replayHits = (Data.state.tutorial or {}).trainingHits or 0
	replayTrained = Data.power() > Economy.KickPower.base or (Data.state.tutorial or {}).trained == true
	begun, welcomeVisible, completionPending = false, false, false
end

function Controller:Start()
	if started then
		return
	end
	started = true
	local screen = Instance.new("ScreenGui")
	screen.Name = "Tutorial"
	screen.DisplayOrder = 50
	screen.ResetOnSpawn = false
	screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = player:WaitForChild("PlayerGui")
	gui = screen
	spot, world = Spotlight.new(screen), WorldGuide.new(screen)
	local function skip()
		if optional then
			optionalSeen[optional.kind] = true
			optional = nil
			clear()
			return
		end
		if replay then
			replay = false
		else
			Remotes.get("SkipTutorial"):FireServer()
		end
		dismissed, completedHere, celebrateUntil = true, false, 0
		focus:restore()
		screen:SetAttribute("AwaitingContinue", false)
		welcome:show(false)
		clear()
	end
	objective = Objective.new(screen, skip)
	focus = Focus.new()
	welcome = Welcome.new(screen, function()
		begun, welcomeVisible = true, false
		welcome:show(false)
		screen:SetAttribute("AwaitingContinue", false)
		if completionPending and not replay then
			finish()
		end
	end, skip)
	table.insert(
		connections,
		Remotes.get("KickResult").OnClientEvent:Connect(function(result)
			flightUntil = result.launchTime + result.flightSeconds
		end)
	)
	table.insert(
		connections,
		Remotes.get("ChaseStart").OnClientEvent:Connect(function(p)
			if p.ownerUserId == player.UserId then
				chase = true
			end
		end)
	)
	table.insert(
		connections,
		Remotes.get("ChaseEnded").OnClientEvent:Connect(function()
			chase = false
			flightUntil = 0
		end)
	)
	table.insert(
		connections,
		player:GetAttributeChangedSignal("TutorialDone"):Connect(function()
			if player:GetAttribute("TutorialDone") and not dismissed then
				if begun then
					finish()
				else
					completionPending = true
				end
			end
		end)
	)
	RunService:BindToRenderStep(BINDING, Enum.RenderPriority.Camera.Value + 5, function(dt)
		objective:layout()
		welcome:layout()
		local t = os.clock()
		local cinematic = workspace:GetServerTimeNow() < EggKick.cameraBusyUntil + 0.15
		local h = hud()
		local settings, trade = find(h, "SettingsBackdrop"), find(h, "TradeBackdrop")
		local modals = player.PlayerGui:FindFirstChild("Modals")
		local scrim = modals and modals:FindFirstChild("Scrim")
		local menuOpen = (settings and settings.Visible)
			or (trade and trade.Visible)
			or (scrim and scrim:IsA("GuiObject") and scrim.Visible)
		local paused = cinematic or menuOpen
		local saved = Data.state.tutorial or {}
		local onboarding = Data.loaded()
			and not dismissed
			and not completedHere
			and (replay or (not saved.done and not saved.skipped))
		focus:update(
			h,
			onboarding and not menuOpen,
			player:GetAttribute("TutorialStep") == S.INCOME or screen:GetAttribute("ObjectiveId") == "income"
		)
		screen:SetAttribute("FocusActive", onboarding and not menuOpen)
		screen.Enabled = not paused
		if paused then
			spot:set(nil)
			world:set(nil, nil, nil, false)
		end
		local waiting = false
		if not paused and Data.loaded() and not dismissed and not begun then
			local saved = Data.state.tutorial or {}
			if welcomeVisible or replay or (not saved.done and not saved.skipped) then
				welcomeVisible, waiting = true, true
				clear()
				welcome:show(true)
				screen:SetAttribute("ObjectiveId", "welcome")
				screen:SetAttribute("AwaitingContinue", true)
			end
		end
		if not paused and Data.loaded() and not dismissed and begun then
			if t < celebrateUntil then
				-- Completion is short and never owns movement, input or the camera.
			else
				local step = player:GetAttribute("TutorialStep") or 0
				if replay then
					if player.Character ~= replayCharacter then
						replayCharacter, replayLastHits = player.Character, 0
					end
					local hits = if replayCharacter then (replayCharacter:GetAttribute("SackHits") or 0) else 0
					replayHits, replayLastHits = Rules.trainingProgress(replayHits, replayLastHits, hits)
					if placed("Pet") then
						replayPetAt = replayPetAt or t
					else
						replayPetAt = nil
					end
					step = Rules.choose(Data.state, {
						replay = true,
						active = Data.busy or chase,
						onPad = player.Character ~= nil and KickPad.has(player.Character, KickPad.ACCEPT_RADIUS),
						hasPen = base() ~= nil,
						trained = replayTrained or replayHits >= Rules.TRAIN_HITS,
						incomeExplained = replayPetAt ~= nil and t - replayPetAt >= 2,
					})
					if step == S.DONE then
						finish()
					end
				end
				if t >= celebrateUntil then
					if step > 0 and step ~= S.DONE then
						objective:optional(false)
						local sentence, target, position, thing, floor, trail = view(step)
						local definition = Rules.Definitions[step]
						local stage = if definition then definition.stage else 1
						objective:show(sentence, stage)
						if step == S.TRAIN then
							objective:training(
								if replay
									then replayHits
									else player:GetAttribute("TutorialHits")
										or (Data.state.tutorial or {}).trainingHits
										or 0
							)
						end
						if previousStage > 0 and stage > previousStage then
							objective:success()
						end
						previousStage = stage
						spot:set(target)
						world:set(position, thing, floor, trail)
						screen:SetAttribute("ObjectiveId", definition and definition.id)
					else
						if not optionalView() then
							clear()
						end
						screen:SetAttribute("ObjectiveId", optional and "optional_" .. optional.kind or nil)
					end
				end
			end
		else
			if not paused and not waiting then
				welcome:show(false)
				clear()
			end
		end
		objective:update(t)
		spot:update(t)
		world:update(dt, t)
	end)
end

function Controller:Destroy()
	RunService:UnbindFromRenderStep(BINDING)
	for _, c in connections do
		c:Disconnect()
	end
	connections = {}
	if spot then
		spot:destroy()
	end
	if world then
		world:destroy()
	end
	if objective then
		objective:destroy()
	end
	if welcome then
		welcome:destroy()
	end
	if focus then
		focus:destroy()
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	started, replay, dismissed, completedHere = false, false, false, false
	celebrateUntil, flightUntil, previousStage = 0, 0, 0
	chase, replayPetAt, optional = false, nil, nil
	replayCharacter, replayHits, replayLastHits, replayTrained = nil, 0, 0, false
	begun, welcomeVisible, completionPending = false, false, false
end

return Controller
