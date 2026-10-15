--!strict
-- How each weather event looks in the HUD (UI/Hud/WeatherHud). Presentation only: the weathers themselves, their
-- chances and durations are Config/Mutations.Weather + WeatherEvent (WeatherService runs them). One entry per
-- Config/Mutations.Weather name: the label shown, the icon (AssetIds key), the header fill, the icon tile fill and
-- the countdown's lower gradient colour. A weather added to Config later without an entry here still shows: its
-- name spelled out in capitals, a neutral cyan look and its icon key "weather_<name>" (a named missing-art marker
-- until that icon exists).
local Theme = require(script.Parent.Theme)

local hex = Color3.fromHex

export type Look = {
	label: string,
	icon: string,
	header: Theme.Pair, -- top -> bottom (3+ colours = a left -> right ramp)
	tile: Theme.Pair,
	accent: Color3,
}

local WeatherLook = {}

WeatherLook.Looks = {
	Sunny = {
		label = "SUNNY",
		icon = "weather_sunny",
		header = { hex("FFE45A"), hex("FF9512") },
		tile = { hex("FFC83A"), hex("F07400") },
		accent = hex("FFE45A"),
	},
	Rainy = {
		label = "RAINY",
		icon = "weather_rainy",
		header = { hex("5FE6FF"), hex("1D8FE0") },
		tile = { hex("4FC8FF"), hex("1466CC") },
		accent = hex("9FEFFF"),
	},
	Snowy = {
		label = "SNOWY",
		icon = "weather_snowy",
		header = { hex("BDF1FF"), hex("5DB8F0") },
		tile = { hex("8EDCFF"), hex("2F8ADA") },
		accent = hex("D9F6FF"),
	},
	Stormy = {
		label = "STORMY",
		icon = "weather_stormy",
		header = { hex("5B7CFF"), hex("232A8C") },
		tile = { hex("5A74E8"), hex("1E2A8C") },
		accent = hex("7FE8FF"),
	},
	Starfall = {
		label = "STARFALL",
		icon = "weather_starfall",
		header = { hex("C27AFF"), hex("5A22C8") },
		tile = { hex("7E4FFF"), hex("2A1270") },
		accent = hex("E6C8FF"),
	},
	Rainbow = {
		label = "RAINBOW",
		icon = "weather_rainbow",
		header = { hex("FF5A5A"), hex("FFB43A"), hex("FFE45A"), hex("7CF04A"), hex("4FB8FF"), hex("B57AFF") },
		tile = { hex("A8EAFF"), hex("4FA8F0") },
		accent = hex("FFF3A0"),
	},
} :: { [string]: Look }

local FALLBACK_HEADER = { hex("55E2FF"), hex("1597E0") }
local FALLBACK_TILE = { hex("3A3F52"), hex("232736") }

-- "HeatWave" / "heat_wave" -> "HEAT WAVE"
local function spell(name: string): string
	local spaced = name:gsub("_", " "):gsub("(%l)(%u)", "%1 %2")
	return string.upper(spaced)
end

-- The look for `weather` (always one: unknown names get the neutral look).
function WeatherLook.get(weather: string): Look
	local look = WeatherLook.Looks[weather]
	if look then
		return look
	end
	return {
		label = spell(weather),
		icon = "weather_" .. string.lower(weather),
		header = FALLBACK_HEADER,
		tile = FALLBACK_TILE,
		accent = hex("B8F2FF"),
	}
end

-- Seconds -> "M:SS" ("1:51", "0:07"); an hour or more -> "H:MM:SS".
function WeatherLook.clock(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local h, m = s // 3600, (s // 60) % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s % 60)
	end
	return string.format("%d:%02d", m, s % 60)
end

return WeatherLook
