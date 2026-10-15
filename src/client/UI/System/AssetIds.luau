--!strict
-- The UI's art registry (UI handoff v2: 05-Claude/AssetMap.template.luau + 00-REBUILD-FIRST/ACTIVE-ASSET-MAP.md).
-- One entry per supplied PNG, keyed by the manifest key. `id` is the REAL uploaded Roblox image id
-- ("rbxassetid://<n>"); never invent one. All are uploaded (Krono808, Creator Hub > Development items >
-- Images: 59 on 2026-10-12, the 50 HUD / kick / rating / zone-bar / zone-label / sparkle images on 2026-10-13,
-- the targeted-fixes Auto Kick / Trade / 3-layer kick meter on 2026-10-13; these are the IMAGE ids, asset type
-- 1, not the Decal ids the upload panel shows).
--
-- To replace one: upload assets/ui-upload/<key>.png and paste the new Image id into its `id`.
--
-- An entry with id = "" falls back to:
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
	banners_cash_background = { source = "02-Assets/Banners/cash-background.png", id = "rbxassetid://87430887454166" },
	banners_hatch_background = { source = "02-Assets/Banners/hatch-background.png", id = "rbxassetid://73485605638537" },
	banners_power_background = {
		source = "02-Assets/Banners/power-background.png",
		id = "rbxassetid://124677169471098",
	},
	-- 02-Assets/Boxing-Sacks (bound to Config/Upgrades.Sack by NAME in SACKS below)
	["01_burlap_sack"] = { source = "02-Assets/Boxing-Sacks/01-burlap-sack.png", id = "rbxassetid://91113451788633" },
	["02_gym_canvas"] = { source = "02-Assets/Boxing-Sacks/02-gym-canvas.png", id = "rbxassetid://71371869320711" },
	["03_leather_classic"] = {
		source = "02-Assets/Boxing-Sacks/03-leather-classic.png",
		id = "rbxassetid://123168551945605",
	},
	["04_pro_red"] = { source = "02-Assets/Boxing-Sacks/04-pro-red.png", id = "rbxassetid://138385070713934" },
	["05_tirestack"] = { source = "02-Assets/Boxing-Sacks/05-tirestack.png", id = "rbxassetid://74427195392481" },
	["06_iron_plate"] = { source = "02-Assets/Boxing-Sacks/06-iron-plate.png", id = "rbxassetid://117838688841876" },
	["07_bronze_statue"] = {
		source = "02-Assets/Boxing-Sacks/07-bronze-statue.png",
		id = "rbxassetid://82376484882120",
	},
	["08_silver_knight"] = {
		source = "02-Assets/Boxing-Sacks/08-silver-knight.png",
		id = "rbxassetid://84365098742204",
	},
	["09_gold_champion"] = {
		source = "02-Assets/Boxing-Sacks/09-gold-champion.png",
		id = "rbxassetid://85765290544611",
	},
	["10_ice_block"] = { source = "02-Assets/Boxing-Sacks/10-ice-block.png", id = "rbxassetid://127679095489551" },
	["11_crystal_geode"] = {
		source = "02-Assets/Boxing-Sacks/11-crystal-geode.png",
		id = "rbxassetid://102888690251620",
	},
	["12_candy_smash"] = { source = "02-Assets/Boxing-Sacks/12-candy-smash.png", id = "rbxassetid://79953088836931" },
	["13_lava_core"] = { source = "02-Assets/Boxing-Sacks/13-lava-core.png", id = "rbxassetid://137279866165799" },
	["14_thunder_cell"] = { source = "02-Assets/Boxing-Sacks/14-thunder-cell.png", id = "rbxassetid://90417499855666" },
	["15_toxic_barrel"] = { source = "02-Assets/Boxing-Sacks/15-toxic-barrel.png", id = "rbxassetid://133329004488973" },
	["16_robo_bag"] = { source = "02-Assets/Boxing-Sacks/16-robo-bag.png", id = "rbxassetid://134503652035085" },
	["17_dragon_hide"] = { source = "02-Assets/Boxing-Sacks/17-dragon-hide.png", id = "rbxassetid://79151810993065" },
	["18_galaxy_void"] = { source = "02-Assets/Boxing-Sacks/18-galaxy-void.png", id = "rbxassetid://85692103491473" },
	["19_sun_guardian"] = { source = "02-Assets/Boxing-Sacks/19-sun-guardian.png", id = "rbxassetid://76531280610257" },
	["20_rainbow_god"] = { source = "02-Assets/Boxing-Sacks/20-rainbow-god.png", id = "rbxassetid://91102148660237" },
	-- 02-Assets/Premium-Icons (navigation + currency heroes; supersede the old UI/icon-* files)
	premium_icons_currency_cash = {
		source = "02-Assets/Premium-Icons/currency-cash.png",
		id = "rbxassetid://122210387180336",
	},
	premium_icons_nav_eggs = { source = "02-Assets/Premium-Icons/nav-eggs.png", id = "rbxassetid://119366070358291" },
	premium_icons_nav_index = { source = "02-Assets/Premium-Icons/nav-index.png", id = "rbxassetid://94178073999979" },
	premium_icons_nav_pets = { source = "02-Assets/Premium-Icons/nav-pets.png", id = "rbxassetid://100066710339265" },
	premium_icons_nav_rebirth = {
		source = "02-Assets/Premium-Icons/nav-rebirth.png",
		id = "rbxassetid://125467004208382",
	},
	premium_icons_nav_shop = { source = "02-Assets/Premium-Icons/nav-shop.png", id = "rbxassetid://137513692032978" },
	premium_icons_nav_training = {
		source = "02-Assets/Premium-Icons/nav-training.png",
		id = "rbxassetid://84196659777573",
	},
	premium_icons_power_sneaker = {
		source = "02-Assets/Premium-Icons/power-sneaker.png",
		id = "rbxassetid://97152880787198",
	},
	-- 02-Assets/UI (reusable effects, technical controls, stud texture)
	fx_glow = { source = "02-Assets/UI/fx-glow.png", id = "rbxassetid://131200174693466" },
	fx_rays = { source = "02-Assets/UI/fx-rays.png", id = "rbxassetid://80237947202198" },
	fx_shine = { source = "02-Assets/UI/fx-shine.png", id = "rbxassetid://106000367902622" },
	fx_sparkle = { source = "02-Assets/UI/fx-sparkle.png", id = "rbxassetid://131412552719894" },
	icon_check = { source = "02-Assets/UI/icon-check.png", id = "rbxassetid://83643286630963" },
	icon_close = { source = "02-Assets/UI/icon-close.png", id = "rbxassetid://104155934366478" },
	icon_lock = { source = "02-Assets/UI/icon-lock.png", id = "rbxassetid://114769201437734" },
	texture_studs = { source = "02-Assets/UI/texture-studs.png", id = "rbxassetid://112317755032573" },
	-- 02-Assets/Zone-Art (bound to Config/Zones by zone id in ZONES below)
	zone_art_meadow = { source = "02-Assets/Zone-Art/meadow.png", id = "rbxassetid://129163670239514" },
	zone_art_sandy_beach = { source = "02-Assets/Zone-Art/sandy-beach.png", id = "rbxassetid://108675681763572" },
	zone_art_autumn_forest = { source = "02-Assets/Zone-Art/autumn-forest.png", id = "rbxassetid://94525850821257" },
	zone_art_mushroom_grove = { source = "02-Assets/Zone-Art/mushroom-grove.png", id = "rbxassetid://108207873910094" },
	zone_art_desert_dunes = { source = "02-Assets/Zone-Art/desert-dunes.png", id = "rbxassetid://133235195136021" },
	zone_art_snowy_peaks = { source = "02-Assets/Zone-Art/snowy-peaks.png", id = "rbxassetid://124577686575726" },
	zone_art_candy_land = { source = "02-Assets/Zone-Art/candy-land.png", id = "rbxassetid://83112750318576" },
	zone_art_coral_reef = { source = "02-Assets/Zone-Art/coral-reef.png", id = "rbxassetid://89883539792540" },
	zone_art_volcano = { source = "02-Assets/Zone-Art/volcano.png", id = "rbxassetid://94698303380590" },
	zone_art_crystal_caves = { source = "02-Assets/Zone-Art/crystal-caves.png", id = "rbxassetid://129698839697789" },
	zone_art_jungle_ruins = { source = "02-Assets/Zone-Art/jungle-ruins.png", id = "rbxassetid://121053504894769" },
	zone_art_neon_city = { source = "02-Assets/Zone-Art/neon-city.png", id = "rbxassetid://95477373741493" },
	zone_art_haunted_graveyard = {
		source = "02-Assets/Zone-Art/haunted-graveyard.png",
		id = "rbxassetid://108145850555118",
	},
	zone_art_sky_islands = { source = "02-Assets/Zone-Art/sky-islands.png", id = "rbxassetid://117110405270371" },
	zone_art_toxic_swamp = { source = "02-Assets/Zone-Art/toxic-swamp.png", id = "rbxassetid://107746871407492" },
	zone_art_clockwork_factory = {
		source = "02-Assets/Zone-Art/clockwork-factory.png",
		id = "rbxassetid://76179793237866",
	},
	zone_art_frozen_aurora = { source = "02-Assets/Zone-Art/frozen-aurora.png", id = "rbxassetid://128752109720890" },
	zone_art_lava_core = { source = "02-Assets/Zone-Art/lava-core.png", id = "rbxassetid://76479570711918" },
	zone_art_galaxy_void = { source = "02-Assets/Zone-Art/galaxy-void.png", id = "rbxassetid://116152121647212" },
	zone_art_rainbow_heaven = { source = "02-Assets/Zone-Art/rainbow-heaven.png", id = "rbxassetid://139335812344018" },
	-- Final approved HUD icons (Kick_An_Egg_Final_Approved_Icons_NoToolUI; they replace the older nav/currency icons)
	hud_shop = { source = "Approved-Icons/Shop.png", id = "rbxassetid://124063885519959" },
	hud_index = { source = "Approved-Icons/Index.png", id = "rbxassetid://129632301300395" },
	hud_rebirth = { source = "Approved-Icons/Rebirth.png", id = "rbxassetid://114455910779142" },
	hud_eggs = { source = "Approved-Icons/Eggs.png", id = "rbxassetid://90997219081318" },
	hud_pets = { source = "Approved-Icons/Pets.png", id = "rbxassetid://84890738919357" },
	hud_settings = { source = "Approved-Icons/Settings.png", id = "rbxassetid://121688620921925" },
	hud_sound = { source = "Approved-Icons/Sound.png", id = "rbxassetid://102220234745257" },
	hud_money = { source = "Approved-Icons/Money.png", id = "rbxassetid://97122527077619" },
	hud_power = { source = "Approved-Icons/Power.png", id = "rbxassetid://100350848236207" },
	-- Contextual kick UI (Master handoff v2: KICK / AUTO KICK buttons, strength meter states)
	kick_button = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Kick_Button.png",
		id = "rbxassetid://110480185583493",
	},
	-- targeted fixes (2026-10-13): the new Auto Kick button, the Trade HUD button and the single kick meter as three
	-- aligned layers (track behind, a tintable fill clipped to the level, the frame on top)
	kick_auto = {
		source = "Targeted-Fixes/PNG_Assets/Auto_Kick_Button.png",
		id = "rbxassetid://133970296249456",
	},
	hud_trade = { source = "assets/ui-icons/approved/Trade.png", id = "rbxassetid://112475659466025" },
	hud_bag = { source = "assets/ui-icons/approved/Bag.png", id = "rbxassetid://112704079535367" },
	kick_meter_track = {
		source = "Targeted-Fixes/PNG_Assets/Kick_Meter_Track.png",
		id = "rbxassetid://114311291241712",
	},
	kick_meter_fill = {
		source = "Targeted-Fixes/PNG_Assets/Kick_Meter_Fill_Tintable.png",
		id = "rbxassetid://133073599038746",
	},
	kick_meter_frame = {
		source = "Targeted-Fixes/PNG_Assets/Kick_Meter_Frame.png",
		id = "rbxassetid://109486048637563",
	},
	kick_meter_idle = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Strength_Meter_Idle.png",
		id = "rbxassetid://136550503602655",
	},
	kick_meter_low = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Strength_Meter_Low.png",
		id = "rbxassetid://120053828564741",
	},
	kick_meter_mid = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Strength_Meter_Mid.png",
		id = "rbxassetid://109599021858372",
	},
	kick_meter_high = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Strength_Meter_High.png",
		id = "rbxassetid://138183036684293",
	},
	kick_meter_full = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Strength_Meter_Full.png",
		id = "rbxassetid://99229129863864",
	},
	-- Kick ratings (Master handoff v2: Perfect / Excellent / Great / Good / Okay / Miss)
	rating_perfect = {
		source = "Master-v2/01_Final_UI_Assets/03_UI_Text_Assets/Rating_Perfect.png",
		id = "rbxassetid://105064803687403",
	},
	rating_excellent = {
		source = "Master-v2/01_Final_UI_Assets/03_UI_Text_Assets/Rating_Excellent.png",
		id = "rbxassetid://134027495906114",
	},
	rating_great = {
		source = "Master-v2/01_Final_UI_Assets/03_UI_Text_Assets/Rating_Great.png",
		id = "rbxassetid://87569717537397",
	},
	rating_good = {
		source = "Master-v2/01_Final_UI_Assets/03_UI_Text_Assets/Rating_Good.png",
		id = "rbxassetid://106254352632431",
	},
	rating_okay = {
		source = "Master-v2/01_Final_UI_Assets/03_UI_Text_Assets/Rating_Okay.png",
		id = "rbxassetid://81341228109524",
	},
	rating_miss = {
		source = "Master-v2/01_Final_UI_Assets/03_UI_Text_Assets/Rating_Miss.png",
		id = "rbxassetid://89504865537074",
	},
	-- Zone progress bar frames (frame 1 = empty) and zone name labels (Master handoff v2)
	zone_bar_empty = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Distance_Progress_Bar_Empty.png",
		id = "rbxassetid://109070858959652",
	},
	zone_bar_quarter = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Distance_Progress_Bar_Quarter.png",
		id = "rbxassetid://111273665799579",
	},
	zone_bar_half = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Distance_Progress_Bar_Half.png",
		id = "rbxassetid://104816659335936",
	},
	zone_bar_three_quarter = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Distance_Progress_Bar_Three_Quarter.png",
		id = "rbxassetid://103103494095218",
	},
	zone_bar_full = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Distance_Progress_Bar_Full.png",
		id = "rbxassetid://93093238813279",
	},
	zone_bar_rainbow = {
		source = "Master-v2/01_Final_UI_Assets/02_Kick_UI/Distance_Progress_Bar_Rainbow.png",
		id = "rbxassetid://104645132263398",
	},
	zone_label_empty = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Panel_Empty.png",
		id = "rbxassetid://135166278948704",
	},
	zone_label_01 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/01_Meadow.png",
		id = "rbxassetid://91530334895234",
	},
	zone_label_02 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/02_Sandy_Beach.png",
		id = "rbxassetid://117311157014450",
	},
	zone_label_03 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/03_Autumn_Forest.png",
		id = "rbxassetid://72765603290181",
	},
	zone_label_04 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/04_Mushroom_Grove.png",
		id = "rbxassetid://77174297300239",
	},
	zone_label_05 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/05_Desert_Dunes.png",
		id = "rbxassetid://86262392682469",
	},
	zone_label_06 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/06_Snowy_Peaks.png",
		id = "rbxassetid://123570735147640",
	},
	zone_label_07 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/07_Candy_Land.png",
		id = "rbxassetid://127765974854596",
	},
	zone_label_08 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/08_Coral_Reef.png",
		id = "rbxassetid://126380424438136",
	},
	zone_label_09 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/09_Volcano.png",
		id = "rbxassetid://89752997315055",
	},
	zone_label_10 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/10_Crystal_Caves.png",
		id = "rbxassetid://89264134040943",
	},
	zone_label_11 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/11_Jungle_Ruins.png",
		id = "rbxassetid://117212562093442",
	},
	zone_label_12 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/12_Neon_City.png",
		id = "rbxassetid://131186297807590",
	},
	zone_label_13 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/13_Haunted_Graveyard.png",
		id = "rbxassetid://79578745646199",
	},
	zone_label_14 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/14_Sky_Islands.png",
		id = "rbxassetid://130131237424956",
	},
	zone_label_15 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/15_Toxic_Swamp.png",
		id = "rbxassetid://134208222406486",
	},
	zone_label_16 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/16_Clockwork_Factory.png",
		id = "rbxassetid://84909515109343",
	},
	zone_label_17 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/17_Frozen_Aurora.png",
		id = "rbxassetid://109707900514670",
	},
	zone_label_18 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/18_Lava_Core.png",
		id = "rbxassetid://70877785211814",
	},
	zone_label_19 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/19_Galaxy_Void.png",
		id = "rbxassetid://102923501057160",
	},
	zone_label_20 = {
		source = "Master-v2/02_Zone_Progress/Zone_Name_Previews/20_Rainbow_Heaven.png",
		id = "rbxassetid://119757409558363",
	},
	-- UI sparkle overlay (Master handoff v2)
	fx_ui_sparkle = {
		source = "Master-v2/08_New_Icons/UI_Sparkle_Transparent.png",
		id = "rbxassetid://129791085225899",
	},
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

-- Config/Zones[].id -> zone name label shown under the zone progress bar.
function AssetIds.zoneLabel(id: number): string
	return string.format("zone_label_%02d", id)
end

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
