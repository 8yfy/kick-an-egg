--!strict
-- Model Lab, Animations, VFX and Pets & Eggs commands. Every model comes from the server registry (Catalog
-- source ids), every animation / effect name from the server's own lists, every number has bounds. Testers act on
-- their own lab models; "lab.manageAll" (Developer+) may act on anyone's. Lab commands never cross servers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mutations = require(Shared.Config.Mutations)
local Rarities = require(Shared.Config.Rarities)

local CATALOG_PAGE = 24

return function(deps: { [string]: any }): { any }
	local Config = deps.Config
	local Catalog = deps.Catalog
	local ModelLab = deps.ModelLab
	local S = deps.Services
	local L = Config.Lab

	local LAB_ID = { type = "string", maxLength = 16, pattern = "^[%w]+$", label = "Lab model" }

	local function resolve(ctx: any, labId: string): (any?, string?)
		local entry = if labId == "latest" then ModelLab.latest(ctx.userId) else ModelLab.get(labId)
		if not entry then
			return nil, "That lab model doesn't exist (any more)."
		end
		if entry.owner ~= ctx.userId and not deps.can(ctx.role, "lab.manageAll") then
			return nil, "That model belongs to another admin."
		end
		return entry, nil
	end
	local function needEntry(ctx: any, p: { [string]: any }): (boolean, string?, string?)
		local entry, why = resolve(ctx, p.labId)
		if not entry then
			return false, why, "not_found"
		end
		return true
	end
	local function room(ctx: any, n: number): (boolean, string?, string?)
		if ModelLab.count(ctx.userId) + n > L.maxPerAdmin then
			return false, `You can have {L.maxPerAdmin} lab models; delete some first.`, "limit"
		end
		if ModelLab.count(nil) + n > L.maxTotal then
			return false, `The lab is full ({L.maxTotal} models on this server).`, "limit"
		end
		return true
	end
	local function busy(player: Player?): boolean
		return player ~= nil and (S.KickService:GetActive(player) ~= nil or S.ChaseService:GetChase(player) ~= nil)
	end

	local function view(entry: any): { [string]: any }
		local m = entry.model
		return {
			id = entry.id,
			name = entry.name,
			source = entry.source,
			kind = entry.kind,
			key = entry.key,
			owner = entry.ownerName,
			ownerId = entry.owner,
			slot = entry.slot,
			yaw = entry.yaw,
			scale = entry.scale,
			offset = { entry.offset.X, entry.offset.Y, entry.offset.Z },
			pen = entry.pen,
			rigged = m:GetAttribute("Rigged") == true,
			anim = m:GetAttribute("LabAnim") or "",
			animSpeed = m:GetAttribute("LabAnimSpeed") or 1,
			fx = m:GetAttribute("LabFx") or "",
			rarity = m:GetAttribute("LabRarity"),
			version = m:GetAttribute("LabVersion"),
		}
	end

	local function bump(m: Model, attr: string)
		m:SetAttribute(attr, (m:GetAttribute(attr) or 0) + 1)
	end

	local rarityOptions = { "All" }
	for name in Rarities do
		table.insert(rarityOptions, name)
	end
	local sizes = { "None" }
	for name in Mutations.Size do
		table.insert(sizes, name)
	end
	local labTarget = function(p: { [string]: any }): string?
		return p.labId
	end
	local fxToken: { [Model]: number } = {}

	local commands = {
		{
			id = "lab.catalog",
			name = "Model catalog",
			description = "Pets, eggs, Kick Sacks and ServerStorage preview assets from the server registry.",
			category = "lab",
			permission = "lab.use",
			kind = "read",
			params = {
				kind = { type = "enum", options = { "all", "pet", "egg", "sack", "asset" }, default = "all" },
				query = { type = "string", optional = true, maxLength = 40 },
				zone = { type = "number", min = 0, max = 20, integer = true, default = 0 },
				rarity = { type = "enum", options = rarityOptions, default = "All" },
				page = { type = "number", min = 1, max = 100, integer = true, default = 1 },
			},
			handler = function(_ctx, p)
				local needle = if p.query and p.query ~= "" then string.lower(p.query) else nil
				local list = {}
				for _, e in Catalog.all() do
					if p.kind ~= "all" and e.kind ~= p.kind then
						continue
					end
					if p.zone > 0 and e.zone ~= p.zone then
						continue
					end
					if p.rarity ~= "All" and e.rarity ~= p.rarity then
						continue
					end
					if
						needle
						and not string.find(string.lower(`{e.name} {e.key} {e.zoneName} {e.source}`), needle, 1, true)
					then
						continue
					end
					table.insert(list, e)
				end
				local pages = math.max(1, math.ceil(#list / CATALOG_PAGE))
				local page = math.clamp(p.page, 1, pages)
				return true,
					{
						entries = table.move(
							list,
							(page - 1) * CATALOG_PAGE + 1,
							math.min(#list, page * CATALOG_PAGE),
							1,
							{}
						),
						total = #list,
						page = page,
						pages = pages,
					}
			end,
		},
		{
			id = "lab.spawn",
			name = "Spawn test model",
			runnerName = "SpawnRegisteredTestModel",
			description = "A temporary copy of a registered model on the lab platform, a compare pad or near you.",
			category = "lab",
			permission = "lab.use",
			kind = "action",
			runner = true,
			cooldown = 0.5,
			params = {
				source = { type = "enum", options = Catalog.sourceIds, searchable = true, label = "Model" },
				placement = {
					type = "enum",
					options = { "platform", "nearMe", "compareA", "compareB" },
					default = "platform",
				},
			},
			target = function(p)
				return p.source
			end,
			precheck = function(ctx, p)
				if p.placement == "nearMe" and busy(ctx.player) then
					return false, "Finish your egg chase first.", "busy"
				end
				return room(ctx, 1)
			end,
			handler = function(ctx, p)
				local entry, err = ModelLab.spawn(ctx.player, ctx.userId, ctx.name, p.source, p.placement, nil)
				if not entry then
					return false, err, "failed"
				end
				return true, { model = view(entry), info = ModelLab.measure(entry.model) }
			end,
		},
		{
			id = "lab.pair",
			name = "Spawn egg + pet pair",
			description = "An egg and its pet side by side on two free pads.",
			category = "pets",
			permission = "lab.use",
			kind = "action",
			cooldown = 1,
			params = { petId = { type = "enum", options = Catalog.petIds, searchable = true, label = "Pet" } },
			target = function(p)
				return p.petId
			end,
			precheck = function(ctx)
				return room(ctx, 2)
			end,
			handler = function(ctx, p)
				local egg, err = ModelLab.spawn(ctx.player, ctx.userId, ctx.name, `egg:{p.petId}`, "platform", nil)
				if not egg then
					return false, err, "failed"
				end
				local pet, err2 = ModelLab.spawn(ctx.player, ctx.userId, ctx.name, `pet:{p.petId}`, "platform", nil)
				if not pet then
					ModelLab.delete(egg)
					return false, err2, "failed"
				end
				egg.model:SetAttribute("LabPair", pet.id)
				pet.model:SetAttribute("LabPair", egg.id)
				return true, { egg = view(egg), pet = view(pet) }
			end,
		},
		{
			id = "lab.compare",
			name = "Compare two models",
			description = "Two models on the compare pads: same scale, orientation and spotlights; separate VFX and animation.",
			category = "lab",
			permission = "lab.use",
			kind = "action",
			cooldown = 1,
			params = {
				sourceA = { type = "enum", options = Catalog.sourceIds, searchable = true, label = "Model A" },
				sourceB = { type = "enum", options = Catalog.sourceIds, searchable = true, label = "Model B" },
			},
			target = function(p)
				return `{p.sourceA} vs {p.sourceB}`
			end,
			precheck = function(ctx)
				return room(ctx, 2)
			end,
			handler = function(ctx, p)
				local a, err = ModelLab.spawn(ctx.player, ctx.userId, ctx.name, p.sourceA, "compareA", nil)
				if not a then
					return false, err, "failed"
				end
				local b, err2 = ModelLab.spawn(ctx.player, ctx.userId, ctx.name, p.sourceB, "compareB", nil)
				if not b then
					return false, err2, "failed"
				end
				return true,
					{
						a = view(a),
						b = view(b),
						infoA = ModelLab.measure(a.model),
						infoB = ModelLab.measure(b.model),
					}
			end,
		},
		{
			id = "lab.list",
			name = "Lab models",
			description = "Every test model on this server (yours first).",
			category = "lab",
			permission = "lab.use",
			kind = "read",
			audit = "none",
			handler = function(ctx)
				local mine, others = {}, {}
				for _, entry in ModelLab.list() do
					local v = view(entry)
					v.mine = entry.owner == ctx.userId
					table.insert(if v.mine then mine else others, v)
				end
				for _, v in others do
					table.insert(mine, v)
				end
				return true,
					{
						models = mine,
						count = ModelLab.count(nil),
						pen = ModelLab.penCount(),
						activeFx = ModelLab.activeFx(),
					}
			end,
		},
		{
			id = "lab.inspect",
			name = "Measure and check model",
			description = "Bounding box and part/mesh/joint counts measured from the actual model, plus QA checks.",
			category = "lab",
			permission = "lab.use",
			kind = "read",
			params = { labId = LAB_ID },
			precheck = needEntry,
			handler = function(ctx, p)
				local entry = resolve(ctx, p.labId)
				local e = Catalog.get(entry.source)
				return true,
					{
						model = view(entry),
						info = ModelLab.measure(entry.model),
						issues = ModelLab.inspect(entry),
						status = if e then e.status else {},
						anims = if e then e.anims else {},
						effects = if e then e.effects else {},
						oneShots = Catalog.OneShots[entry.kind] or {},
					}
			end,
		},
		{
			id = "lab.transform",
			name = "Move / rotate / scale",
			description = "Rotate, scale (bounded), move within the preview area, center or reset a lab model.",
			category = "lab",
			permission = "lab.use",
			kind = "action",
			audit = "failures",
			params = {
				labId = LAB_ID,
				op = { type = "enum", options = { "rotate", "scale", "move", "center", "reset" } },
				yaw = { type = "number", min = 0, max = 359, default = 0 },
				scale = { type = "number", min = L.minScale, max = L.maxScale, default = 1 },
				dx = { type = "number", min = -L.maxOffset, max = L.maxOffset, default = 0 },
				dy = { type = "number", min = 0, max = L.maxLift, default = 0 },
				dz = { type = "number", min = -L.maxOffset, max = L.maxOffset, default = 0 },
			},
			target = labTarget,
			precheck = needEntry,
			handler = function(ctx, p)
				local entry = resolve(ctx, p.labId)
				local ok, err = ModelLab.transform(entry, p.op, p)
				if not ok then
					return false, err, "failed"
				end
				return true, { model = view(entry), info = ModelLab.measure(entry.model) }
			end,
		},
		{
			id = "lab.delete",
			name = "Delete lab model",
			description = "Removes one lab model (its animations and effects stop with it).",
			category = "lab",
			permission = "lab.use",
			kind = "action",
			params = { labId = LAB_ID },
			target = labTarget,
			precheck = needEntry,
			handler = function(ctx, p)
				ModelLab.delete(resolve(ctx, p.labId))
				return true, {}
			end,
		},
		{
			id = "lab.clearMine",
			name = "Clear my lab models",
			description = "Removes every lab model and test pen pet you spawned.",
			category = "lab",
			permission = "lab.use",
			kind = "action",
			cooldown = 1,
			handler = function(ctx)
				return true, { removed = ModelLab.clear(ctx.userId) }
			end,
		},
		{
			id = "lab.clearAll",
			name = "Clear all test models",
			runnerName = "ClearAdminTestModels",
			description = "Removes every admin test model and test pen pet on this server.",
			category = "lab",
			permission = "lab.manageAll",
			kind = "action",
			runner = true,
			confirm = true,
			cooldown = 2,
			handler = function()
				return true, { removed = ModelLab.clear(nil) }
			end,
		},
		{
			id = "lab.anim",
			name = "Play animation",
			runnerName = "PlayRegisteredAnimation",
			description = "Play / stop / restart a registered animation on a rigged lab model (one animator per model).",
			category = "animations",
			permission = "anim.play",
			kind = "action",
			runner = true,
			audit = "failures",
			params = {
				labId = LAB_ID,
				anim = { type = "enum", options = Catalog.allAnims, default = "Idle" },
				op = { type = "enum", options = { "play", "stop", "restart", "idle", "reset" }, default = "play" },
				speed = { type = "number", min = 0.1, max = 3, default = 1 },
				loop = { type = "boolean", default = true },
			},
			target = labTarget,
			precheck = function(ctx, p)
				local entry, why = resolve(ctx, p.labId)
				if not entry then
					return false, why, "not_found"
				end
				if entry.model:GetAttribute("Rigged") ~= true then
					return false, "This model has no Motor6D joints, so it can't animate.", "unrigged"
				end
				local allowed = Catalog.Anims[entry.kind] or {}
				if (p.op == "play" or p.op == "restart") and not table.find(allowed, p.anim) then
					return false, `{p.anim} doesn't apply to a {entry.kind}.`, "invalid_params"
				end
				if entry.pen and p.op ~= "reset" then
					return false, "Test pen pets walk/idle on their own.", "invalid_params"
				end
				return true
			end,
			handler = function(ctx, p)
				local entry = resolve(ctx, p.labId)
				local m: Model = entry.model
				local anim, speed, loop = p.anim, p.speed, p.loop
				if p.op == "stop" or p.op == "reset" then
					anim, speed, loop = "", 1, true
				elseif p.op == "idle" then
					anim, speed, loop = Catalog.IdleAnim[entry.kind] or "", 1, true
				end
				m:SetAttribute("LabAnim", anim)
				m:SetAttribute("LabAnimSpeed", speed)
				m:SetAttribute("AnimSpeed", speed) -- Anim/Pet's time scale
				m:SetAttribute("LabAnimLoop", loop)
				local cycle = Catalog.AnimCycle[anim] or 2
				m:SetAttribute(
					"LabAnimUntil",
					if loop or anim == "" then 0 else workspace:GetServerTimeNow() + cycle / speed
				)
				bump(m, "LabAnimRev")
				return true, { model = view(entry) }
			end,
		},
		{
			id = "lab.vfx",
			name = "Model VFX",
			description = "Enable / disable / one-shot / signature special / reset for effects that exist for this model.",
			category = "vfx",
			permission = "vfx.play",
			kind = "action",
			audit = "failures",
			cooldown = Config.Vfx.oneShotCooldown,
			params = {
				labId = LAB_ID,
				op = { type = "enum", options = { "enable", "disable", "oneshot", "special", "reset" } },
				effect = {
					type = "enum",
					optional = true,
					options = function()
						local list = Catalog.allEffects()
						for _, n in Catalog.allOneShots() do
							table.insert(list, n)
						end
						return list
					end,
				},
				quality = { type = "enum", options = { "Low", "Medium", "High" }, default = "Medium" },
				seconds = { type = "number", min = 1, max = Config.Vfx.maxSeconds, integer = true, default = 30 },
			},
			target = labTarget,
			precheck = function(ctx, p)
				local entry, why = resolve(ctx, p.labId)
				if not entry then
					return false, why, "not_found"
				end
				local e = Catalog.get(entry.source)
				if p.op == "enable" then
					if not (p.effect and e and table.find(e.effects, p.effect)) then
						return false, "That effect doesn't exist for this model.", "invalid_params"
					end
					local current = entry.model:GetAttribute("LabFx")
					if (current == nil or current == "") and ModelLab.activeFx() >= Config.Vfx.maxActive then
						return false, `At most {Config.Vfx.maxActive} models may have effects on.`, "limit"
					end
				elseif p.op == "oneshot" then
					if not (p.effect and table.find(Catalog.OneShots[entry.kind] or {}, p.effect)) then
						return false, "That one-shot doesn't apply to this model.", "invalid_params"
					end
				elseif p.op == "special" then
					if not (e and table.find(e.effects, "Idle")) then
						return false,
							"This model has no PetFx recipe, so it has no signature special.",
							"invalid_params"
					end
				end
				return true
			end,
			handler = function(ctx, p)
				local entry = resolve(ctx, p.labId)
				local m: Model = entry.model
				local quality = Config.Vfx.qualities[p.quality] or 0.65
				if p.op == "enable" then
					local untilAt = workspace:GetServerTimeNow() + p.seconds
					m:SetAttribute("LabFx", p.effect)
					m:SetAttribute("LabFxQuality", quality)
					m:SetAttribute("LabFxUntil", untilAt)
					bump(m, "LabFxRev")
					local token = (fxToken[m] or 0) + 1
					fxToken[m] = token
					task.delay(p.seconds, function()
						if fxToken[m] == token and m.Parent then
							m:SetAttribute("LabFx", "")
							bump(m, "LabFxRev")
						end
					end)
				elseif p.op == "disable" or p.op == "reset" then
					fxToken[m] = (fxToken[m] or 0) + 1
					m:SetAttribute("LabFx", "")
					bump(m, "LabFxRev")
					if p.op == "reset" then
						m:SetAttribute("LabOneShot", "")
						bump(m, "LabFxResetRev")
					end
				elseif p.op == "oneshot" then
					m:SetAttribute("LabOneShot", p.effect)
					bump(m, "LabOneShotRev")
				elseif p.op == "special" then
					m:SetAttribute("LabFxQuality", quality)
					bump(m, "LabSpecialRev")
				end
				return true, { model = view(entry), activeFx = ModelLab.activeFx() }
			end,
		},
		{
			id = "vfx.demo",
			name = "Run VFX demo",
			runnerName = "RunRegisteredVFXDemo",
			description = "Plays one registered VFX one-shot at the lab's demo spot (builds the lab if needed).",
			category = "vfx",
			permission = "vfx.play",
			kind = "action",
			runner = true,
			cooldown = 1,
			params = { effect = { type = "enum", options = Catalog.DemoEffects, default = "HatchBurst" } },
			target = function(p)
				return p.effect
			end,
			handler = function(_ctx, p)
				local folder = ModelLab.ensure()
				local anchor = folder:FindFirstChild("Platform") and folder.Platform:FindFirstChild("DemoAnchor")
				if not anchor then
					return false, "The demo spot is missing.", "failed"
				end
				anchor:SetAttribute("LabDemo", p.effect)
				bump(anchor :: any, "LabDemoRev")
				return true, { effect = p.effect }
			end,
		},
		{
			id = "lab.hatch",
			name = "Hatch sequence",
			description = "Plays the egg's crack + burst, then swaps it for its pet with the reveal (lab copy only).",
			category = "pets",
			permission = "lab.use",
			kind = "action",
			cooldown = 4,
			params = { labId = LAB_ID },
			target = labTarget,
			precheck = function(ctx, p)
				local entry, why = resolve(ctx, p.labId)
				if not entry then
					return false, why, "not_found"
				end
				if entry.kind ~= "egg" or entry.pen then
					return false, "Pick an egg on a pad.", "invalid_params"
				end
				if entry.model:GetAttribute("LabHatchAt") then
					return false, "It's already hatching.", "busy"
				end
				return true
			end,
			handler = function(ctx, p)
				local egg = resolve(ctx, p.labId)
				local petSource = string.gsub(egg.source, "^egg:", "pet:")
				local seconds = 3
				egg.model:SetAttribute("LabHatchAt", workspace:GetServerTimeNow() + seconds)
				task.delay(seconds + 0.35, function()
					if ModelLab.get(egg.id) ~= egg then
						return -- deleted meanwhile
					end
					local slot, owner, ownerName = egg.slot, egg.owner, egg.ownerName
					local fixedSlot = string.match(slot, "^pad%d$") or slot == "compareA" or slot == "compareB"
					ModelLab.delete(egg)
					local pet = ModelLab.spawn(
						ctx.player,
						owner,
						ownerName,
						petSource,
						if fixedSlot then slot else "platform",
						nil
					)
					if pet then
						pet.model:SetAttribute("LabReveal", workspace:GetServerTimeNow())
					end
				end)
				return true, { seconds = seconds }
			end,
		},
		{
			id = "lab.pen.add",
			name = "Add pet to test pen",
			description = "A roaming copy in the isolated test pen (no owner, no income, no saved data).",
			category = "pets",
			permission = "lab.use",
			kind = "action",
			cooldown = 0.5,
			params = {
				petId = { type = "enum", options = Catalog.petIds, searchable = true, label = "Pet" },
				size = { type = "enum", options = sizes, default = "None" },
			},
			target = function(p)
				return p.petId
			end,
			precheck = function()
				if ModelLab.penCount() >= L.penMax then
					return false, `The test pen holds {L.penMax} pets.`, "limit"
				end
				return true
			end,
			handler = function(ctx, p)
				local entry, err = ModelLab.spawn(
					ctx.player,
					ctx.userId,
					ctx.name,
					`pet:{p.petId}`,
					"pen",
					if p.size ~= "None" then p.size else nil
				)
				if not entry then
					return false, err, "failed"
				end
				return true, { model = view(entry) }
			end,
		},
		{
			id = "lab.pen.clear",
			name = "Reset test pen",
			description = "Removes test pen pets (yours, or everyone's with lab.manageAll).",
			category = "pets",
			permission = "lab.use",
			kind = "action",
			cooldown = 1,
			params = { everyone = { type = "boolean", default = false } },
			precheck = function(ctx, p)
				if p.everyone and not deps.can(ctx.role, "lab.manageAll") then
					return false, "Only Developers and Owners can clear everyone's pen pets.", "forbidden"
				end
				return true
			end,
			handler = function(ctx, p)
				return true, { removed = ModelLab.clear(if p.everyone then nil else ctx.userId, true) }
			end,
		},
		{
			id = "lab.pen.check",
			name = "Check test pen",
			description = "QA: floating parts, broken joints, invisibility, unrigged pets, floor clipping and overlaps.",
			category = "pets",
			permission = "lab.use",
			kind = "read",
			handler = function()
				local pets = {}
				for _, entry in ModelLab.list() do
					if entry.pen then
						table.insert(pets, { model = view(entry), issues = ModelLab.inspect(entry) })
					end
				end
				return true, { pets = pets, overlaps = ModelLab.penOverlaps() }
			end,
		},
	}
	return commands
end
