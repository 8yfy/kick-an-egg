--!strict
-- Every image the new UI uses, in one place (UI handoff 03-Specs/asset-manifest.json).
-- HANDOFF holds the Roblox ids for the handoff PNGs: upload them (Studio Asset Manager > Bulk Import) and
-- paste "rbxassetid://<id>" into the empty slots. None are invented here. Until a slot is filled the UI
-- uses FALLBACK (images already uploaded for the old HUD, see UI/Icons) or, for the 20 sacks, a live 3D
-- render of the in-game sack model (UI/System/Ui.sackArt).
local AssetIds = {}

-- Handoff PNG -> uploaded id ("" = not uploaded yet).
local HANDOFF: { [string]: string } = {
	-- 02-Assets/Boxing-Sacks/NN-*.png, in ladder order (Config/Upgrades.Sack.tiers)
	["sack/1"] = "", -- 01-burlap-sack.png
	["sack/2"] = "", -- 02-gym-canvas.png
	["sack/3"] = "", -- 03-leather-classic.png
	["sack/4"] = "", -- 04-pro-red.png
	["sack/5"] = "", -- 05-tirestack.png
	["sack/6"] = "", -- 06-iron-plate.png
	["sack/7"] = "", -- 07-bronze-statue.png
	["sack/8"] = "", -- 08-silver-knight.png
	["sack/9"] = "", -- 09-gold-champion.png
	["sack/10"] = "", -- 10-ice-block.png
	["sack/11"] = "", -- 11-crystal-geode.png
	["sack/12"] = "", -- 12-candy-smash.png
	["sack/13"] = "", -- 13-lava-core.png
	["sack/14"] = "", -- 14-thunder-cell.png
	["sack/15"] = "", -- 15-toxic-barrel.png
	["sack/16"] = "", -- 16-robo-bag.png
	["sack/17"] = "", -- 17-dragon-hide.png
	["sack/18"] = "", -- 18-galaxy-void.png
	["sack/19"] = "", -- 19-sun-guardian.png
	["sack/20"] = "", -- 20-rainbow-god.png
	-- 02-Assets/UI/*.png
	["icon/cash"] = "",
	["icon/check"] = "",
	["icon/close"] = "",
	["icon/egg"] = "",
	["icon/index"] = "",
	["icon/lock"] = "",
	["icon/pets"] = "",
	["icon/power"] = "",
	["icon/rebirth"] = "",
	["icon/shop"] = "",
	["icon/training"] = "",
	["fx/glow"] = "",
	["fx/rays"] = "",
	["fx/shine"] = "",
	["fx/sparkle"] = "",
	["texture/studs"] = "",
}

-- Already-uploaded stand-ins (UI/Icons, UI/Kit) used while a handoff slot is empty.
local FALLBACK: { [string]: string } = {
	["icon/cash"] = "rbxassetid://87716585873855",
	["icon/close"] = "rbxassetid://125377353826856",
	["icon/egg"] = "rbxassetid://80077964816211",
	["icon/index"] = "rbxassetid://102517293443898",
	["icon/pets"] = "rbxassetid://96366429916416",
	["icon/power"] = "rbxassetid://130642391715113",
	["icon/rebirth"] = "rbxassetid://71261019262412",
	["icon/shop"] = "rbxassetid://93294781213829",
	["icon/speed"] = "rbxassetid://100327618588257",
	["icon/training"] = "rbxassetid://130642391715113", -- Power icon until the training icon is uploaded
	["icon/trade"] = "rbxassetid://74243416141687",
	["icon/settings"] = "rbxassetid://84245192417477",
	["icon/slots"] = "rbxassetid://88628040109592",
	["fx/glow"] = "rbxassetid://110070937482051",
	["fx/rays"] = "rbxassetid://133942308484025",
	["fx/sparkle"] = "rbxassetid://125277121997681",
	["texture/studs"] = "rbxassetid://137675892333527",
}

-- The image for `key`: the uploaded handoff art, else the stand-in, else nil (caller draws a fallback).
function AssetIds.get(key: string): string?
	local id = HANDOFF[key]
	if id and id ~= "" then
		return id
	end
	return FALLBACK[key]
end

-- True when the handoff art itself is uploaded (not a stand-in).
function AssetIds.hasHandoff(key: string): boolean
	local id = HANDOFF[key]
	return id ~= nil and id ~= ""
end

-- Handoff slots still waiting for an upload (for the setup report / Studio output).
function AssetIds.missing(): { string }
	local list = {}
	for key, id in HANDOFF do
		if id == "" then
			table.insert(list, key)
		end
	end
	table.sort(list)
	return list
end

return AssetIds
