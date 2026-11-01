--!strict
-- Player search and read-only inspection (existing DataService data), teleports to approved spots, progression
-- test edits (Studio in-memory data or a staging universe only) and kick moderation (Owner, confirmed, reason
-- logged, only players of a lower rank).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Mutations = require(Shared.Config.Mutations)
local Pets = require(Shared.Config.Pets)
local Upgrades = require(Shared.Config.Upgrades)
local Zones = require(Shared.Config.Zones)
local KickPad = require(Shared.KickPad)

local PAGE = 20
local PET_PAGE = 30
local MAX_EGGS, MAX_PETS = 100, 300 -- test grants stop here

return function(deps: { [string]: any }): { any }
	local S = deps.Services
	local Catalog = deps.Catalog
	local ModelLab = deps.ModelLab
	local Environment = deps.Environment

	local petsById: { [string]: any } = {}
	for _, pet in Pets do
		petsById[pet.id] = pet
	end
	local maxPen = math.floor((Economy.PlotSlots.max - Economy.PlotSlots.base) / Upgrades.Pen.slotsPerLevel) + 1
	local STAT_MAX = {
		money = 1e15,
		kickPower = math.min(Economy.KickPower.max, 1e15),
		speedLevel = 10000,
		rebirths = 1000,
		penLevel = maxPen,
	}
	local STAT_MIN = { money = 0, kickPower = Economy.KickPower.base, speedLevel = 0, rebirths = 0, penLevel = 1 }

	local function rootOf(player: Player): BasePart?
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return if hrp and hrp:IsA("BasePart") then hrp else nil
	end

	local function zoneOf(player: Player): string
		local hrp = rootOf(player)
		if not hrp then
			return "no character"
		end
		local z = hrp.Position.Z
		if hrp.Position.Y > 150 and math.abs(hrp.Position.X) > 400 then
			return "Model Lab"
		end
		if z < 0 then
			return "Safe zone"
		end
		for _, zone in Zones do
			if z >= zone.start and z < zone.start + zone.length then
				return `{zone.id}. {zone.name}`
			end
		end
		return "beyond the track"
	end

	local function busy(player: Player): boolean
		return S.KickService:GetActive(player) ~= nil or S.ChaseService:GetChase(player) ~= nil
	end

	local function target(userId: number): Player?
		local p = Players:GetPlayerByUserId(userId)
		return if p and p.Parent == Players then p else nil
	end

	local function teleport(player: Player, cf: CFrame): (boolean, string?)
		local hrp = rootOf(player)
		if not hrp then
			return false, "That player has no character right now."
		end
		local char = player.Character :: Model
		char:PivotTo(cf + Vector3.new(0, 3, 0))
		return true, nil
	end

	local function needTarget(p: { [string]: any }): (boolean, string?, string?)
		if not target(p.userId) then
			return false, "That player isn't in this server.", "not_found"
		end
		return true, nil, nil
	end

	local function progressionCheck(_ctx: any, p: { [string]: any }): (boolean, string?, string?)
		local player = target(p.userId)
		if not player then
			return false, "That player isn't in this server.", "not_found"
		end
		if not S.DataService:Get(player) then
			return false, "Their data hasn't loaded.", "not_found"
		end
		local safe, why = Environment.dataSafety(S.DataService:IsPersistent(player))
		if not safe then
			return false, why, "data_safety"
		end
		return true, nil, nil
	end

	local function grantEntry(p: { [string]: any }): { [string]: any }
		return {
			petId = p.petId,
			size = if p.size ~= "None" then p.size else nil,
			weather = if p.weather ~= "None" then p.weather else nil,
		}
	end

	local sizes = { "None" }
	for name in Mutations.Size do
		table.insert(sizes, name)
	end
	local weathers = { "None" }
	for name in Mutations.Weather do
		table.insert(weathers, name)
	end
	local userTarget = function(p: { [string]: any }): string?
		return tostring(p.userId)
	end

	return {
		{
			id = "players.list",
			name = "Find players",
			description = "Players in this server, searchable by name, display name or UserId.",
			category = "players",
			permission = "players.view",
			kind = "read",
			params = {
				query = { type = "string", optional = true, maxLength = 40 },
				page = { type = "number", min = 1, max = 50, integer = true, default = 1 },
			},
			handler = function(_ctx, p)
				local needle = if p.query and p.query ~= "" then string.lower(p.query) else nil
				local list = {}
				for _, player in Players:GetPlayers() do
					local hay = string.lower(`{player.Name} {player.DisplayName} {player.UserId}`)
					if needle and not string.find(hay, needle, 1, true) then
						continue
					end
					table.insert(list, {
						userId = player.UserId,
						name = player.Name,
						displayName = player.DisplayName,
						zone = zoneOf(player),
						base = player:GetAttribute("BaseIndex"),
						busy = busy(player),
					})
				end
				table.sort(list, function(a, b)
					return string.lower(a.name) < string.lower(b.name)
				end)
				local pages = math.max(1, math.ceil(#list / PAGE))
				local page = math.clamp(p.page, 1, pages)
				return true,
					{
						players = table.move(list, (page - 1) * PAGE + 1, math.min(#list, page * PAGE), 1, {}),
						total = #list,
						page = page,
						pages = pages,
					}
			end,
		},
		{
			id = "players.inspect",
			name = "Inspect player",
			description = "Read-only: money, Kick Power, Run Speed, rebirths, zone, pen, eggs and pets.",
			category = "players",
			permission = "players.view",
			kind = "read",
			params = {
				userId = { type = "userId" },
				petPage = { type = "number", min = 1, max = 100, integer = true, default = 1 },
			},
			precheck = function(_ctx, p)
				return needTarget(p)
			end,
			target = userTarget,
			handler = function(_ctx, p)
				local player = target(p.userId) :: Player
				local data = S.DataService:Get(player)
				if not data then
					return false, "Their data hasn't loaded yet.", "not_found"
				end
				local pets = {}
				local placed = 0
				for uid, pet in data.pets do
					local cfg = petsById[pet.petId]
					if pet.placed then
						placed += 1
					end
					table.insert(pets, {
						uid = string.sub(uid, 1, 8),
						name = if cfg then cfg.name else pet.petId,
						rarity = if cfg then cfg.rarity else "?",
						size = pet.size,
						weather = pet.weather,
						placed = pet.placed == true,
					})
				end
				table.sort(pets, function(a, b)
					return a.name < b.name
				end)
				local pages = math.max(1, math.ceil(#pets / PET_PAGE))
				local page = math.clamp(p.petPage, 1, pages)
				local eggs = {}
				for i, egg in data.eggs do
					if i > 30 then
						break
					end
					local cfg = petsById[egg.petId]
					table.insert(
						eggs,
						{ name = if cfg then cfg.name else egg.petId, size = egg.size, weather = egg.weather }
					)
				end
				local hatching = 0
				for _ in data.plots do
					hatching += 1
				end
				return true,
					{
						userId = player.UserId,
						name = player.Name,
						displayName = player.DisplayName,
						accountAge = player.AccountAge,
						zone = zoneOf(player),
						busy = busy(player),
						money = data.money,
						kickPower = data.kickPower,
						speedLevel = data.speedLevel,
						runSpeed = data.runSpeed,
						rebirths = data.rebirths,
						rackLevel = data.rackLevel,
						penLevel = data.penLevel,
						penSlots = S.PlotService.slotsForPen(data.penLevel or 1),
						base = player:GetAttribute("BaseIndex"),
						income = S.PlotService.incomePerSecond(player, data),
						eggCount = #data.eggs,
						eggs = eggs,
						hatching = hatching,
						petCount = #pets,
						placedPets = placed,
						pets = table.move(pets, (page - 1) * PET_PAGE + 1, math.min(#pets, page * PET_PAGE), 1, {}),
						petPage = page,
						petPages = pages,
						tutorialDone = data.tutorial and data.tutorial.done == true,
						persistent = S.DataService:IsPersistent(player),
					}
			end,
		},
		{
			id = "players.teleportToPlayer",
			name = "Teleport to player",
			description = "Moves you next to a player in this server.",
			category = "players",
			permission = "players.teleport.self",
			kind = "action",
			cooldown = 1,
			params = { userId = { type = "userId" } },
			target = userTarget,
			precheck = function(ctx, p)
				if busy(ctx.player) then
					return false, "Finish your egg chase first.", "busy"
				end
				local t = target(p.userId)
				if not (t and rootOf(t)) then
					return false, "That player isn't in this server or has no character.", "not_found"
				end
				return true
			end,
			handler = function(ctx, p)
				local hrp = rootOf(target(p.userId) :: Player) :: BasePart
				return teleport(ctx.player, hrp.CFrame * CFrame.new(0, 0, 5))
			end,
		},
		{
			id = "players.teleportPlayer",
			name = "Teleport player to a spot",
			description = "Moves a player (of a lower rank) to an approved spot: the kick pad or their own pen.",
			category = "players",
			permission = "players.teleport.others",
			kind = "action",
			cooldown = 1,
			params = {
				userId = { type = "userId" },
				spot = { type = "enum", options = { "KickPad", "TheirPen" }, default = "KickPad" },
			},
			target = userTarget,
			precheck = function(ctx, p)
				local t = target(p.userId)
				if not (t and rootOf(t)) then
					return false, "That player isn't in this server or has no character.", "not_found"
				end
				if t ~= ctx.player and deps.rank(deps.roleOf(t.UserId)) >= deps.rank(ctx.role) then
					return false, "You can only move players of a lower rank.", "forbidden"
				end
				if busy(t) then
					return false, "They're in an egg chase; try again after it.", "busy"
				end
				return true
			end,
			handler = function(_ctx, p)
				local t = target(p.userId) :: Player
				if p.spot == "TheirPen" then
					local cf = S.PlotService:GetBaseCFrame(t)
					if not cf then
						return false, "They don't have a pen yet.", "not_found"
					end
					return teleport(t, cf)
				end
				local pad = KickPad.part()
				if not pad then
					return false, "No kick pad in this place.", "not_found"
				end
				return teleport(t, pad.CFrame + Vector3.new(0, pad.Size.Y / 2, -6))
			end,
		},
		{
			id = "players.teleportToLab",
			name = "Go to the Model Lab",
			description = "Moves you to the Model Lab platform (built on first use).",
			category = "players",
			permission = "lab.use",
			kind = "action",
			cooldown = 1,
			precheck = function(ctx)
				if busy(ctx.player) then
					return false, "Finish your egg chase first.", "busy"
				end
				return true
			end,
			handler = function(ctx)
				return teleport(ctx.player, ModelLab.spawnCFrame())
			end,
		},
		{
			id = "players.setStat",
			name = "Set progression stat",
			description = "TEST DATA ONLY: Studio in-memory data or a staging universe. Never production.",
			category = "progression",
			permission = "players.progression",
			kind = "action",
			environments = { "studio", "staging" },
			confirm = true,
			cooldown = 0.5,
			params = {
				userId = { type = "userId" },
				stat = { type = "enum", options = { "money", "kickPower", "speedLevel", "rebirths", "penLevel" } },
				value = { type = "number", min = 0, max = 1e15, integer = true },
			},
			target = userTarget,
			precheck = function(ctx, p)
				local ok, why, cat = progressionCheck(ctx, p)
				if not ok then
					return ok, why, cat
				end
				if p.value < STAT_MIN[p.stat] or p.value > STAT_MAX[p.stat] then
					return false, `{p.stat} must be {STAT_MIN[p.stat]}..{STAT_MAX[p.stat]}.`, "invalid_params"
				end
				return true
			end,
			handler = function(_ctx, p)
				local player = target(p.userId) :: Player
				if p.stat == "speedLevel" then
					S.DataService:Set(player, { speedLevel = p.value, runSpeed = Economy.runSpeedAt(p.value) })
					S.ChaseService:RefreshWalkSpeed(player)
				else
					S.DataService:Set(player, { [p.stat] = p.value })
					if p.stat == "penLevel" then
						S.PlotService:MirrorBase(player)
					end
				end
				return true, { stat = p.stat, value = p.value }
			end,
		},
		{
			id = "players.giveEgg",
			name = "Give test egg",
			description = "TEST DATA ONLY: adds an egg (with optional mutations) to a player's inventory.",
			category = "progression",
			permission = "players.progression",
			kind = "action",
			environments = { "studio", "staging" },
			confirm = true,
			cooldown = 0.5,
			params = {
				userId = { type = "userId" },
				petId = { type = "enum", options = Catalog.petIds, searchable = true },
				size = { type = "enum", options = sizes, default = "None" },
				weather = { type = "enum", options = weathers, default = "None" },
			},
			target = userTarget,
			precheck = progressionCheck,
			handler = function(_ctx, p)
				local player = target(p.userId) :: Player
				local data = S.DataService:Get(player)
				if #data.eggs >= MAX_EGGS then
					return false, `They already hold {MAX_EGGS} eggs.`, "limit"
				end
				local eggs = table.clone(data.eggs)
				local egg = grantEntry(p)
				egg.uid = HttpService:GenerateGUID(false)
				table.insert(eggs, egg)
				S.DataService:Set(player, { eggs = eggs })
				return true, { petId = p.petId }
			end,
		},
		{
			id = "players.givePet",
			name = "Give test pet",
			description = "TEST DATA ONLY: adds a stored pet (with optional mutations) to a player's inventory.",
			category = "progression",
			permission = "players.progression",
			kind = "action",
			environments = { "studio", "staging" },
			confirm = true,
			cooldown = 0.5,
			params = {
				userId = { type = "userId" },
				petId = { type = "enum", options = Catalog.petIds, searchable = true },
				size = { type = "enum", options = sizes, default = "None" },
				weather = { type = "enum", options = weathers, default = "None" },
			},
			target = userTarget,
			precheck = progressionCheck,
			handler = function(_ctx, p)
				local player = target(p.userId) :: Player
				local data = S.DataService:Get(player)
				local count = 0
				for _ in data.pets do
					count += 1
				end
				if count >= MAX_PETS then
					return false, `They already own {MAX_PETS} pets.`, "limit"
				end
				local pets = table.clone(data.pets)
				pets[HttpService:GenerateGUID(false)] = grantEntry(p)
				S.DataService:Set(player, { pets = pets })
				return true, { petId = p.petId }
			end,
		},
		{
			id = "players.kick",
			name = "Kick from server",
			description = "Moderation: removes a player of a LOWER rank from this server. Reason is logged.",
			category = "moderation",
			permission = "players.moderate",
			kind = "action",
			confirm = true,
			cooldown = 2,
			params = {
				userId = { type = "userId" },
				reason = { type = "string", minLength = 3, maxLength = 120, label = "Reason (logged)" },
			},
			target = userTarget,
			precheck = function(ctx, p)
				local t = target(p.userId)
				if not t then
					return false, "That player isn't in this server.", "not_found"
				end
				if t == ctx.player then
					return false, "You can't kick yourself.", "forbidden"
				end
				if deps.rank(deps.roleOf(t.UserId)) >= deps.rank(ctx.role) then
					return false, "You can only moderate players of a lower rank.", "forbidden"
				end
				return true
			end,
			handler = function(_ctx, p)
				local t = target(p.userId) :: Player
				t:Kick("You were removed from this server by a moderator.")
				return true, { userId = p.userId }
			end,
		},
	}
end
