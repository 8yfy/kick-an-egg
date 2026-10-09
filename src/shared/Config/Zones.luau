--!strict
-- CONTRACT FILE: change only via a `contract:` PR.
-- Each zone is a strip of the runway. `start` = studs from the kick pad.
-- `ground`/`accent` drive the MapBuilder; `ambient` names a particle preset in VFX.
export type Zone = {
	id: number,
	name: string,
	start: number,
	length: number,
	ground: Color3,
	accent: Color3,
	ambient: string,
	weather: string?, -- default weather mutation that can roll here
}

local LEN = 120
local function z(id: number, name: string, ground: Color3, accent: Color3, ambient: string, weather: string?): Zone
	return { id = id, name = name, start = (id - 1) * LEN, length = LEN, ground = ground, accent = accent, ambient = ambient, weather = weather }
end
local rgb = Color3.fromRGB

local Zones: { Zone } = {
	z(1, "Meadow", rgb(120, 210, 80), rgb(250, 240, 120), "Petals"),
	z(2, "Sandy Beach", rgb(240, 215, 150), rgb(70, 190, 240), "Bubbles"),
	z(3, "Autumn Forest", rgb(230, 130, 50), rgb(150, 80, 40), "Leaves"),
	z(4, "Mushroom Grove", rgb(110, 80, 150), rgb(240, 70, 70), "Spores"),
	z(5, "Desert Dunes", rgb(230, 185, 100), rgb(200, 120, 60), "Sand", "Sunny"),
	z(6, "Snowy Peaks", rgb(235, 245, 255), rgb(140, 190, 240), "Snow", "Snowy"),
	z(7, "Candy Land", rgb(255, 170, 210), rgb(140, 230, 230), "Sprinkles"),
	z(8, "Coral Reef", rgb(50, 160, 200), rgb(255, 120, 110), "Bubbles", "Rainy"),
	z(9, "Volcano", rgb(60, 45, 45), rgb(255, 100, 30), "Embers"),
	z(10, "Crystal Caves", rgb(70, 60, 110), rgb(120, 240, 255), "Sparkles"),
	z(11, "Jungle Ruins", rgb(60, 140, 60), rgb(170, 160, 120), "Fireflies", "Rainy"),
	z(12, "Neon City", rgb(30, 30, 45), rgb(255, 40, 200), "Neon"),
	z(13, "Haunted Graveyard", rgb(55, 60, 55), rgb(140, 255, 120), "Wisps"),
	z(14, "Sky Islands", rgb(200, 230, 255), rgb(255, 255, 255), "Clouds"),
	z(15, "Toxic Swamp", rgb(80, 110, 40), rgb(170, 255, 40), "ToxicBubbles"),
	z(16, "Clockwork Factory", rgb(110, 90, 70), rgb(230, 180, 60), "Steam"),
	z(17, "Frozen Aurora", rgb(170, 220, 240), rgb(120, 255, 200), "Aurora", "Snowy"),
	z(18, "Lava Core", rgb(90, 30, 20), rgb(255, 170, 40), "Magma", "Stormy"),
	z(19, "Galaxy Void", rgb(20, 15, 40), rgb(170, 120, 255), "Stars", "Starfall"),
	z(20, "Rainbow Heaven", rgb(255, 255, 255), rgb(255, 120, 200), "Rainbow", "Rainbow"),
}

return Zones
