--!strict
-- Kick The Egg UI tokens (UI handoff v2 00-REBUILD-FIRST/VISUAL-CONTRACT.md). Roblox-part look: broad flat
-- surfaces, small shallow studs, 5 px near-black borders, square-leaning corners, saturated headers with two
-- diagonal strips, bold white Fredoka One with dark outlines. Lime = buy/confirm, red = close/remove.
local Theme = {}

local hex = Color3.fromHex
export type Pair = { Color3 }

Theme.Colors = {
	border = hex("080A10"),
	body = hex("262938"),
	card = hex("171B26"),
	cardEdge = hex("343A4E"),
	footer = hex("1B1E2A"),
	tabIdle = hex("2E3243"),
	text = hex("FFFFFF"),
	muted = hex("B8C0D4"),
	cash = hex("7DFF4A"),
	power = hex("FFD84A"),
	danger = hex("FF5444"),
	scrim = Color3.new(0, 0, 0),
	missing = hex("FF00C8"),
}

-- Section headers, top -> bottom.
Theme.Headers = {
	training = { hex("D654FF"), hex("8A2BEF") },
	shop = { hex("8CFF3A"), hex("36C40F") },
	index = { hex("55E2FF"), hex("1597E0") },
	rebirth = { hex("C45EFF"), hex("7522DD") },
	sell = { hex("8CFF3A"), hex("36C40F") },
	eggs = { hex("FFD43A"), hex("FF9512") },
	pets = { hex("FFB43A"), hex("FF7012") },
	confirm = { hex("55E2FF"), hex("1597E0") },
} :: { [string]: Pair }

-- Buttons / pills.
Theme.Buttons = {
	lime = { hex("B8FF19"), hex("4AD800") },
	grey = { hex("A3A8B6"), hex("666B7B") },
	dark = { hex("3A3F52"), hex("232736") },
	purple = { hex("C45EFF"), hex("7522DD") },
	violet = { hex("8F5CFF"), hex("4D2BD4") },
	red = { hex("FF4A3A"), hex("D3121F") },
	gold = { hex("FFE45A"), hex("FFAA00") },
	cyan = { hex("5FE6FF"), hex("1199DD") },
	orange = { hex("FFB43A"), hex("F07000") },
	disabled = { hex("7D8290"), hex("525766") },
} :: { [string]: Pair }

-- HUD navigation colours (contract: Shop green, Index cyan, Rebirth purple, Training purple, Eggs gold, Pets orange).
Theme.Nav = {
	Shop = { hex("7CF03A"), hex("2DB30E") },
	Index = { hex("4FD8FF"), hex("118FD6") },
	Rebirth = { hex("C45EFF"), hex("7522DD") },
	Training = { hex("9B5CFF"), hex("5A2BD8") },
	Eggs = { hex("FFD43A"), hex("F59A00") },
	Pets = { hex("FFAA3A"), hex("F06A00") },
} :: { [string]: Pair }

-- Rarity card backgrounds (Config/Rarities names). Secret is drawn as a rainbow.
Theme.Rarity = {
	Common = { hex("C9CDD6"), hex("7D8291") },
	Uncommon = { hex("7CF04A"), hex("2B9E1A") },
	Rare = { hex("4FB8FF"), hex("1D5CE0") },
	Epic = { hex("C25BFF"), hex("7322D6") },
	Legendary = { hex("FFE04A"), hex("EE9A00") },
	Mythic = { hex("FF6FD0"), hex("C2248A") },
	Divine = { hex("FFF7CF"), hex("E3BE5C") },
	Secret = { hex("FFFFFF"), hex("9AA0B0") },
} :: { [string]: Pair }

Theme.RarityText = {
	Common = hex("E4E7EE"),
	Uncommon = hex("7CF04A"),
	Rare = hex("4FC3FF"),
	Epic = hex("D27BFF"),
	Legendary = hex("FFD84A"),
	Mythic = hex("FF7AD6"),
	Divine = hex("FFF3B0"),
	Secret = hex("FFFFFF"),
} :: { [string]: Color3 }

-- Card backgrounds for the 20 sacks: a material accent sampled from each supplied PNG (not a rarity).
Theme.SackAccent = {
	["Burlap Sack"] = { hex("C3C6CF"), hex("6E7280") },
	["Gym Canvas"] = { hex("8C9AB6"), hex("3B465F") },
	["Leather Classic"] = { hex("E09445"), hex("7A3A12") },
	["Pro Red"] = { hex("FF5050"), hex("A3101C") },
	["Tire Stack"] = { hex("F5A040"), hex("70380E") },
	["Iron Plate"] = { hex("9AACC0"), hex("3E4B5C") },
	["Bronze Statue"] = { hex("E8A055"), hex("7A4214") },
	["Silver Knight"] = { hex("CBD6E8"), hex("55617C") },
	["Gold Champion"] = { hex("FFDD55"), hex("C27A00") },
	["Ice Block"] = { hex("8EE8FF"), hex("2A82C8") },
	["Crystal Geode"] = { hex("B57AFF"), hex("4C1E9C") },
	["Candy Smash"] = { hex("FF92CC"), hex("BF2E78") },
	["Lava Core"] = { hex("FF8E2E"), hex("9E1E0C") },
	["Thunder Cell"] = { hex("52C6FF"), hex("1A3CA6") },
	["Toxic Barrel"] = { hex("A2FF40"), hex("2C8810") },
	["Robo Bag"] = { hex("62E6E2"), hex("1E6C88") },
	["Dragon Hide"] = { hex("FFAE33"), hex("B22E0E") },
	["Galaxy Void"] = { hex("7E4FFF"), hex("1C0E58") },
	["Sun Guardian"] = { hex("FFE56E"), hex("DE7400") },
	["Rainbow God"] = { hex("FF7AD9"), hex("5B6CFF") },
} :: { [string]: Pair }

Theme.Font = Enum.Font.FredokaOne

Theme.Layout = {
	designW = 1440, -- max authored modal size (fits 92% of the safe viewport, scaled)
	designH = 960,
	header = 92,
	title = 52,
	headerIcon = 64,
	close = 70,
	footer = 78,
	pad = 20,
	gap = 16,
	radius = 8,
	border = 5,
	tap = 48,
	minText = 17,
}

Theme.Motion = {
	open = 0.28,
	close = 0.16,
	hover = 0.10,
	press = 0.07,
	release = 0.12,
	hoverScale = 1.035,
	pressScale = 0.96,
	reveal = 0.18,
	revealStagger = 0.025,
	revealCap = 0.3,
	float = 3.2,
	shine = 0.65,
	reduced = 0.12,
	counter = 0.3,
	drawer = 0.2,
}

-- Stud texture alpha: quiet on bodies (~10%), a little stronger on coloured headers/cards.
Theme.Studs = { body = 0.9, header = 0.86, card = 0.84, tile = 24 }

return Theme
