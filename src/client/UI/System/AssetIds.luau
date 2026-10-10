--!strict
-- The UI's art registry (UI handoff v2: 05-Claude/AssetMap.template.luau + 00-REBUILD-FIRST/ACTIVE-ASSET-MAP.md).
-- One entry per supplied PNG, keyed by the manifest key. `id` is the REAL uploaded Roblox image id
-- ("rbxassetid://<n>") and stays "" until the PNG is uploaded: never invent one.
--
-- How to fill it: Studio > View > Asset Manager > Images > Bulk Import every PNG in assets/ui-upload/
-- (files are named <key>.png), then right-click each > Copy Asset ID and paste it into `id` below.
--
-- Until then:
--   * Studio only: the UI loads the same PNG from Studio's local content folder
--     (rbxasset://textures/KickTheEggUI/<key>.png, copied there by tools/preview/stage-art.sh) and shows a
--     "LOCAL ART" developer banner. This is a preview, not an upload: it works on this computer only.
--   * Live servers: a missing id draws a named missing-art marker (Ui.art) and is logged. Nothing silently
--     falls back to other art or 3D model previews.
local RunService = game:GetService("RunService")

local AssetIds = {}

export type Entry = { source: string, id: string }

local A: { [string]: Entry } = {
	-- 02-Assets/Banners (shop banner backdrops; hero art stays a separate layer)
	banners_cash_background = { source = "02-Assets/Banners/cash-background.png", id = "" },
	banners_hatch_background = { source = "02-Assets/Banners/hatch-background.png", id = "" },
	banners_power_background = { source = "02-Assets/Banners/power-background.png", id = "" },
	-- 02-Assets/Boxing-Sacks (bound to Config/Upgrades.Sack by NAME in SACKS below)
	["01_burlap_sack"] = { source = "02-Assets/Boxing-Sacks/01-burlap-sack.png", id = "" },
	["02_gym_canvas"] = { source = "02-Assets/Boxing-Sacks/02-gym-canvas.png", id = "" },
	["03_leather_classic"] = { source = "02-Assets/Boxing-Sacks/03-leather-classic.png", id = "" },
	["04_pro_red"] = { source = "02-Assets/Boxing-Sacks/04-pro-red.png", id = "" },
	["05_tirestack"] = { source = "02-Assets/Boxing-Sacks/05-tirestack.png", id = "" },
	["06_iron_plate"] = { source = "02-Assets/Boxing-Sacks/06-iron-plate.png", id = "" },
	["07_bronze_statue"] = { source = "02-Assets/Boxing-Sacks/07-bronze-statue.png", id = "" },
	["08_silver_knight"] = { source = "02-Assets/Boxing-Sacks/08-silver-knight.png", id = "" },
	["09_gold_champion"] = { source = "02-Assets/Boxing-Sacks/09-gold-champion.png", id = "" },
	["10_ice_block"] = { source = "02-Assets/Boxing-Sacks/10-ice-block.png", id = "" },
	["11_crystal_geode"] = { source = "02-Assets/Boxing-Sacks/11-crystal-geode.png", id = "" },
	["12_candy_smash"] = { source = "02-Assets/Boxing-Sacks/12-candy-smash.png", id = "" },
	["13_lava_core"] = { source = "02-Assets/Boxing-Sacks/13-lava-core.png", id = "" },
	["14_thunder_cell"] = { source = "02-Assets/Boxing-Sacks/14-thunder-cell.png", id = "" },
	["15_toxic_barrel"] = { source = "02-Assets/Boxing-Sacks/15-toxic-barrel.png", id = "" },
	["16_robo_bag"] = { source = "02-Assets/Boxing-Sacks/16-robo-bag.png", id = "" },
	["17_dragon_hide"] = { source = "02-Assets/Boxing-Sacks/17-dragon-hide.png", id = "" },
	["18_galaxy_void"] = { source = "02-Assets/Boxing-Sacks/18-galaxy-void.png", id = "" },
	["19_sun_guardian"] = { source = "02-Assets/Boxing-Sacks/19-sun-guardian.png", id = "" },
	["20_rainbow_god"] = { source = "02-Assets/Boxing-Sacks/20-rainbow-god.png", id = "" },
	-- 02-Assets/Premium-Icons (navigation + currency heroes; supersede the old UI/icon-* files)
	premium_icons_currency_cash = { source = "02-Assets/Premium-Icons/currency-cash.png", id = "" },
	premium_icons_nav_eggs = { source = "02-Assets/Premium-Icons/nav-eggs.png", id = "" },
	premium_icons_nav_index = { source = "02-Assets/Premium-Icons/nav-index.png", id = "" },
	premium_icons_nav_pets = { source = "02-Assets/Premium-Icons/nav-pets.png", id = "" },
	premium_icons_nav_rebirth = { source = "02-Assets/Premium-Icons/nav-rebirth.png", id = "" },
	premium_icons_nav_shop = { source = "02-Assets/Premium-Icons/nav-shop.png", id = "" },
	premium_icons_nav_training = { source = "02-Assets/Premium-Icons/nav-training.png", id = "" },
	premium_icons_power_sneaker = { source = "02-Assets/Premium-Icons/power-sneaker.png", id = "" },
	-- 02-Assets/UI (reusable effects, technical controls, stud texture)
	fx_glow = { source = "02-Assets/UI/fx-glow.png", id = "" },
	fx_rays = { source = "02-Assets/UI/fx-rays.png", id = "" },
	fx_shine = { source = "02-Assets/UI/fx-shine.png", id = "" },
	fx_sparkle = { source = "02-Assets/UI/fx-sparkle.png", id = "" },
	icon_check = { source = "02-Assets/UI/icon-check.png", id = "" },
	icon_close = { source = "02-Assets/UI/icon-close.png", id = "" },
	icon_lock = { source = "02-Assets/UI/icon-lock.png", id = "" },
	texture_studs = { source = "02-Assets/UI/texture-studs.png", id = "" },
	-- 02-Assets/Zone-Art (bound to Config/Zones by zone id in ZONES below)
	zone_art_meadow = { source = "02-Assets/Zone-Art/meadow.png", id = "" },
	zone_art_sandy_beach = { source = "02-Assets/Zone-Art/sandy-beach.png", id = "" },
	zone_art_autumn_forest = { source = "02-Assets/Zone-Art/autumn-forest.png", id = "" },
	zone_art_mushroom_grove = { source = "02-Assets/Zone-Art/mushroom-grove.png", id = "" },
	zone_art_desert_dunes = { source = "02-Assets/Zone-Art/desert-dunes.png", id = "" },
	zone_art_snowy_peaks = { source = "02-Assets/Zone-Art/snowy-peaks.png", id = "" },
	zone_art_candy_land = { source = "02-Assets/Zone-Art/candy-land.png", id = "" },
	zone_art_coral_reef = { source = "02-Assets/Zone-Art/coral-reef.png", id = "" },
	zone_art_volcano = { source = "02-Assets/Zone-Art/volcano.png", id = "" },
	zone_art_crystal_caves = { source = "02-Assets/Zone-Art/crystal-caves.png", id = "" },
	zone_art_jungle_ruins = { source = "02-Assets/Zone-Art/jungle-ruins.png", id = "" },
	zone_art_neon_city = { source = "02-Assets/Zone-Art/neon-city.png", id = "" },
	zone_art_haunted_graveyard = { source = "02-Assets/Zone-Art/haunted-graveyard.png", id = "" },
	zone_art_sky_islands = { source = "02-Assets/Zone-Art/sky-islands.png", id = "" },
	zone_art_toxic_swamp = { source = "02-Assets/Zone-Art/toxic-swamp.png", id = "" },
	zone_art_clockwork_factory = { source = "02-Assets/Zone-Art/clockwork-factory.png", id = "" },
	zone_art_frozen_aurora = { source = "02-Assets/Zone-Art/frozen-aurora.png", id = "" },
	zone_art_lava_core = { source = "02-Assets/Zone-Art/lava-core.png", id = "" },
	zone_art_galaxy_void = { source = "02-Assets/Zone-Art/galaxy-void.png", id = "" },
	zone_art_rainbow_heaven = { source = "02-Assets/Zone-Art/rainbow-heaven.png", id = "" },
}

-- Config/Upgrades.Sack.tiers[].name -> sack art (by the sack's name, never by list position).
AssetIds.SACKS = {
	["Burlap Sack"] = "01_burlap_sack",
	["Gym Canvas"] = "02_gym_canvas",
	["Leather Classic"] = "03_leather_classic",
	["Pro Red"] = "04_pro_red",
	["Tire Stack"] = "05_tirestack",
	["Iron Plate"] = "06_iron_plate",
	["Bronze Statue"] = "07_bronze_statue",
	["Silver Knight"] = "08_silver_knight",
	["Gold Champion"] = "09_gold_champion",
	["Ice Block"] = "10_ice_block",
	["Crystal Geode"] = "11_crystal_geode",
	["Candy Smash"] = "12_candy_smash",
	["Lava Core"] = "13_lava_core",
	["Thunder Cell"] = "14_thunder_cell",
	["Toxic Barrel"] = "15_toxic_barrel",
	["Robo Bag"] = "16_robo_bag",
	["Dragon Hide"] = "17_dragon_hide",
	["Galaxy Void"] = "18_galaxy_void",
	["Sun Guardian"] = "19_sun_guardian",
	["Rainbow God"] = "20_rainbow_god",
} :: { [string]: string }

-- Config/Zones[].id -> zone illustration (ZONE-CATALOG.md order = the game's zone order).
AssetIds.ZONES = {
	"zone_art_meadow",
	"zone_art_sandy_beach",
	"zone_art_autumn_forest",
	"zone_art_mushroom_grove",
	"zone_art_desert_dunes",
	"zone_art_snowy_peaks",
	"zone_art_candy_land",
	"zone_art_coral_reef",
	"zone_art_volcano",
	"zone_art_crystal_caves",
	"zone_art_jungle_ruins",
	"zone_art_neon_city",
	"zone_art_haunted_graveyard",
	"zone_art_sky_islands",
	"zone_art_toxic_swamp",
	"zone_art_clockwork_factory",
	"zone_art_frozen_aurora",
	"zone_art_lava_core",
	"zone_art_galaxy_void",
	"zone_art_rainbow_heaven",
} :: { string }

local LOCAL_ROOT = "rbxasset://textures/KickTheEggUI/"
local warned: { [string]: boolean } = {}

export type State = "uploaded" | "local" | "missing"

-- The image for `key` and how it was resolved. "local" = Studio-only preview copy (not uploaded).
function AssetIds.resolve(key: string): (string?, State)
	local entry = A[key]
	if not entry then
		if not warned[key] then
			warned[key] = true
			warn(`[AssetIds] no artwork mapping for "{key}"`)
		end
		return nil, "missing"
	end
	if entry.id ~= "" then
		return entry.id, "uploaded"
	end
	if RunService:IsStudio() then
		return LOCAL_ROOT .. key .. ".png", "local"
	end
	if not warned[key] then
		warned[key] = true
		warn(`[AssetIds] "{key}" ({entry.source}) has no uploaded image id`)
	end
	return nil, "missing"
end

function AssetIds.get(key: string): string?
	return (AssetIds.resolve(key))
end

function AssetIds.sack(name: string): string?
	return AssetIds.SACKS[name]
end

function AssetIds.zone(id: number): string?
	return AssetIds.ZONES[id]
end

function AssetIds.source(key: string): string?
	local entry = A[key]
	return entry and entry.source
end

-- Keys still waiting for an uploaded id (setup report / Studio banner).
function AssetIds.missing(): { string }
	local list = {}
	for key, entry in A do
		if entry.id == "" then
			table.insert(list, key)
		end
	end
	table.sort(list)
	return list
end

function AssetIds.keys(): { string }
	local list = {}
	for key in A do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

return AssetIds
