--!strict
-- Carry poses for eggs, by size (Anim/Carry, Presentation/EggSize tiers), on EVERY character this client sees: you
-- and the players around you. A character holding an egg Tool (attribute EggUid, server PlotService.makeTool) whose
-- held model ("Held") has arrived gets the tier's upper-body pose on top of its own walk / jump; switching to an egg
-- of another size blends into the new tier; putting it down, placing it, dying or leaving lets go cleanly (no
-- stuck pose, no leftover weld). Nothing here changes movement, speed, the camera or Shift Lock.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Carry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Anim"):WaitForChild("Carry"))

local CarryController = {}

type Active = { tool: Tool, held: Model, handle: Carry.Handle }
local active: { [Model]: Active } = {}
local settling: { [Model]: boolean } = {} -- held eggs waiting for their blocks to settle

local function eggTool(character: Model): (Tool?, Model?)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and typeof(child:GetAttribute("EggUid")) == "string" then
			local held = child:FindFirstChild("Held")
			return child, if held and held:IsA("Model") then held else nil
		end
	end
	return nil, nil
end

local function stop(character: Model, fade: number?)
	local a = active[character]
	if a then
		active[character] = nil
		a.handle.stop(fade)
	end
end

local function refresh(character: Model)
	local tool, held = eggTool(character)
	local a: Active? = active[character]
	if a and (a.tool ~= tool or a.held ~= held or not held) then
		stop(character, if tool then 0.2 else 0.25)
		a = nil
	end
	if a or not tool or not held then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or settling[held] then
		return
	end
	-- wait (a few frames at most) until the egg's root has arrived and its blocks have snapped into place, then check
	-- nothing changed meanwhile
	settling[held] = true
	local ok, last = false, nil
	for _ = 1, 30 do
		RunService.Heartbeat:Wait()
		if not held.Parent then
			break
		end
		ok, last = Carry.settled(held, last)
		if ok then
			break
		end
	end
	settling[held] = nil
	local _, stillHeld = eggTool(character)
	if active[character] or stillHeld ~= held or not held.PrimaryPart or humanoid.Health <= 0 then
		return
	end
	local tier = tool:GetAttribute("CarryTier")
	local handle = Carry.start(character, held, if typeof(tier) == "string" then tier else "Medium")
	if handle then
		active[character] = { tool = tool, held = held, handle = handle }
	end
end

local function watchCharacter(character: Model)
	local function soon()
		task.defer(refresh, character)
	end
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			soon()
			-- the held model is made after the Tool arrives (server, on Equipped)
			child.ChildAdded:Connect(soon)
			child.ChildRemoved:Connect(soon)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			soon()
		end
	end)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			child.ChildAdded:Connect(soon)
			child.ChildRemoved:Connect(soon)
		end
	end
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			stop(character, 0.1)
		end)
	end
	character.AncestryChanged:Connect(function()
		if not character:IsDescendantOf(workspace) then
			stop(character, 0)
		end
	end)
	soon()
end

local function watchPlayer(player: Player)
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
end

function CarryController:Start()
	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
end

-- For tests / previews: the carry currently playing on a character.
function CarryController.tierOf(character: Model): string?
	local a = active[character]
	return a and a.handle.tier
end

return CarryController
