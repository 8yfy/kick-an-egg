--!strict
-- Server registry of everything the admin tools may spawn, animate or play. Clients only ever send an id from
-- these lists (validated by the command schemas); never asset ids, module paths or function names.
--   sources   pet:<petId> | egg:<petId> | sack:<tier> | asset:<Name>
--             (pets/eggs from Config/Pets + the block-data builders, the 20 Kick Sacks, and Models a developer put
--             in ServerStorage.AdminPreviewAssets, e.g. IceDragon_V1 to compare with the live IceDragon)
--   anims     the names Anim/init implements, per model kind
--   effects   PetFx idle recipes, VFX.attach weather overlays and VFX.play one-shots that exist in VFX/init

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pets = require(Shared.Config.Pets)
local Zones = require(Shared.Config.Zones)
local Mutations = require(Shared.Config.Mutations)
local Upgrades = require(Shared.Config.Upgrades)
local PetFx = require(Shared.VFX.PetFx)

local Catalog = {}

export type Entry = {
	source: string,
	kind: "pet" | "egg" | "sack" | "asset",
	key: string, -- model key / tier / asset name
	petId: string?,
	name: string,
	zone: number,
	zoneName: string,
	rarity: string,
	version: string,
	anims: { string },
	effects: { string },
	status: { string }, -- honest asset status lines
}

Catalog.ASSET_FOLDER = "AdminPreviewAssets"

-- Animation names Anim/init really implements, by kind (EggRun needs the chase rig, so it isn't offered).
Catalog.Anims = table.freeze({
	pet = table.freeze({ "Idle", "Waddle", "Hop", "Sleep" }),
	egg = table.freeze({ "EggWobble" }),
	sack = table.freeze({}),
	asset = table.freeze({ "Idle", "Waddle", "Hop", "Sleep" }),
})
Catalog.IdleAnim = table.freeze({ pet = "Idle", egg = "EggWobble", asset = "Idle" })
-- Seconds of one cycle at speed 1 (a non-looping play stops after one cycle and returns to idle).
Catalog.AnimCycle = table.freeze({ Idle = 4, Waddle = 1, Hop = 1.2, Sleep = 4, EggWobble = 2 })

-- Persistent effects: "Idle" = the model's own PetFx recipe; the rest are VFX/Weather overlays (Config/Mutations).
local overlays = {}
for _, mutation in Mutations.Weather do
	table.insert(overlays, mutation.vfx)
end
table.sort(overlays)
Catalog.Overlays = table.freeze(overlays)
-- One-shots from VFX/init with the params each needs (filled from the model on the client).
Catalog.OneShots = table.freeze({
	pet = table.freeze({ "PetReveal", "MoneyPop", "TrainHit", "Landing", "KickImpact" }),
	egg = table.freeze({ "HatchCrack", "HatchBurst", "EggSpin", "Landing", "EggSecured", "KickImpact" }),
	sack = table.freeze({ "TrainHit", "KickImpact" }),
	asset = table.freeze({ "PetReveal", "MoneyPop", "Landing" }),
})
Catalog.DemoEffects = table.freeze({ "HatchBurst", "PetReveal", "MoneyPop", "KickImpact", "Landing", "ZoneEnter" })

local zoneNames: { [number]: string } = {}
for _, z in Zones do
	zoneNames[z.id] = z.name
end

-- Which model keys have real block data (anything else builds the magenta placeholder).
local function specKeys(folderName: string): { [string]: boolean }
	local keys = {}
	local folder = Shared.Builders.Models:FindFirstChild(folderName)
	for _, m in if folder then folder:GetChildren() else {} do
		if m:IsA("ModuleScript") then
			local ok, specs = pcall(require, m)
			if ok and typeof(specs) == "table" then
				for key in specs :: any do
					keys[key] = true
				end
			end
		end
	end
	return keys
end
local petSpecs = specKeys("Pets")
local eggSpecs = specKeys("Eggs")

local function hasRecipe(kind: string, key: string): boolean
	local ok, recipe = pcall(PetFx.recipe, kind, key)
	return ok and recipe ~= nil
end

local function specials(kind: string, key: string): number
	local ok, recipe = pcall(PetFx.recipe, kind, key)
	local n = 0
	if ok and recipe then
		for _, layer in (recipe :: any).layers do
			if typeof(layer.every) == "table" then
				n += 1
			end
		end
	end
	return n
end

local function effectsFor(kind: string, key: string): { string }
	local list = {}
	if (kind == "pet" or kind == "egg") and hasRecipe(kind, key) then
		table.insert(list, "Idle")
	end
	if kind == "pet" or kind == "asset" then
		for _, o in Catalog.Overlays do
			table.insert(list, o)
		end
	end
	return list
end

local fixed: { Entry } = {}
local bySource: { [string]: Entry } = {}

local function add(e: Entry)
	table.insert(fixed, e)
	bySource[e.source] = e
end

for _, pet in Pets do
	local zoneName = zoneNames[pet.zone] or "?"
	local petStatus = {
		if petSpecs[pet.model] then "Block data: yes" else "Block data: MISSING (placeholder model)",
		if hasRecipe("pet", pet.model) then "Idle VFX recipe: yes" else "Idle VFX recipe: none yet",
	}
	local nSpecial = specials("pet", pet.model)
	table.insert(petStatus, if nSpecial > 0 then `Signature specials: {nSpecial}` else "Signature specials: none")
	add({
		source = `pet:{pet.id}`,
		kind = "pet",
		key = pet.model,
		petId = pet.id,
		name = pet.name,
		zone = pet.zone,
		zoneName = zoneName,
		rarity = pet.rarity,
		version = "live",
		anims = Catalog.Anims.pet :: any,
		effects = effectsFor("pet", pet.model),
		status = petStatus,
	})
	add({
		source = `egg:{pet.id}`,
		kind = "egg",
		key = pet.model,
		petId = pet.id,
		name = `{pet.name} Egg`,
		zone = pet.zone,
		zoneName = zoneName,
		rarity = pet.rarity,
		version = "live",
		anims = Catalog.Anims.egg :: any,
		effects = effectsFor("egg", pet.model),
		status = {
			if eggSpecs[pet.model] then "Block data: yes" else "Block data: MISSING (placeholder model)",
			if hasRecipe("egg", pet.model) then "Egg aura recipe: yes" else "Egg aura recipe: none yet",
		},
	})
end
for tier, t in Upgrades.Sack.tiers do
	add({
		source = `sack:{tier}`,
		kind = "sack",
		key = tostring(tier),
		name = `Sack {tier}: {t.name}`,
		zone = 0,
		zoneName = "Kick Sacks",
		rarity = t.fx or "Basics",
		version = "live",
		anims = {},
		effects = {},
		status = { "Kick Sack geometry (imported GLB when present, else parts)", "Unrigged: no animations" },
	})
end

local function assetFolder(): Folder
	local folder = ServerStorage:FindFirstChild(Catalog.ASSET_FOLDER)
	if not folder then
		local f = Instance.new("Folder")
		f.Name = Catalog.ASSET_FOLDER
		f.Parent = ServerStorage
		folder = f
	end
	return folder :: Folder
end

-- Models a developer placed in ServerStorage.AdminPreviewAssets (server-only; read fresh each time).
local function assets(): { Entry }
	local list = {}
	for _, child in assetFolder():GetChildren() do
		local name = child.Name
		if not child:IsA("Model") or #name > 48 or not string.match(name, "^[%w_]+$") then
			continue
		end
		local version = child:GetAttribute("Version")
		local suffix = string.match(name, "_[Vv](%d+)$")
		table.insert(list, {
			source = `asset:{name}`,
			kind = "asset",
			key = name,
			name = name,
			zone = tonumber(child:GetAttribute("Zone")) or 0,
			zoneName = "Preview assets",
			rarity = tostring(child:GetAttribute("Rarity") or "Common"),
			version = if typeof(version) == "string" then version elseif suffix then `V{suffix}` else "unversioned",
			anims = Catalog.Anims.asset :: any,
			effects = effectsFor("asset", name),
			status = { "ServerStorage preview asset: scripts are stripped on spawn" },
		})
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	return list
end

function Catalog.all(): { Entry }
	local list = table.clone(fixed)
	for _, e in assets() do
		table.insert(list, e)
	end
	return list
end

function Catalog.get(source: string): Entry?
	local e = bySource[source]
	if e then
		return e
	end
	local name = string.match(source, "^asset:([%w_]+)$")
	if name then
		for _, a in assets() do
			if a.key == name then
				return a
			end
		end
	end
	return nil
end

function Catalog.sourceIds(): { string }
	local ids = {}
	for _, e in Catalog.all() do
		table.insert(ids, e.source)
	end
	return ids
end

function Catalog.petIds(): { string }
	local ids = {}
	for _, pet in Pets do
		table.insert(ids, pet.id)
	end
	return ids
end

function Catalog.assetModel(name: string): Model?
	local m = assetFolder():FindFirstChild(name)
	return if m and m:IsA("Model") then m else nil
end

function Catalog.allEffects(): { string }
	local list = { "Idle" }
	for _, o in Catalog.Overlays do
		table.insert(list, o)
	end
	return list
end

function Catalog.allOneShots(): { string }
	local seen, list = {}, {}
	for _, names in Catalog.OneShots do
		for _, n in names do
			if not seen[n] then
				seen[n] = true
				table.insert(list, n)
			end
		end
	end
	table.sort(list)
	return list
end

function Catalog.allAnims(): { string }
	return { "Idle", "Waddle", "Hop", "Sleep", "EggWobble" }
end

function Catalog.contains(list: { string }, value: string): boolean
	return table.find(list, value) ~= nil
end

function Catalog.ensureAssetFolder()
	assetFolder()
end

return Catalog
