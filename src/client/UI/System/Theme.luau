--!strict
-- Kick The Egg UI tokens (UI handoff 03-Specs/design-tokens.json, Figma "Kick The Egg — UI System"
-- variables). Classic Roblox look: charcoal stud panels, saturated gradient headers, thick near-black
-- outlines, Fredoka One. Red = close/remove only; violet = progression; actions are always labelled.
local Theme = {}

local hex = Color3.fromHex

Theme.Colors = {
	panel = hex("242735"),
	panelDeep = hex("171922"),
	stroke = hex("090B10"),
	innerEdge = hex("687083"),
	text = hex("FFFFFF"),
	muted = hex("B8C0D4"),
	cash = hex("7DFF4A"),
	power = hex("FFD84A"),
	scrim = Color3.new(0, 0, 0),
}

-- Gradient pairs, top -> bottom.
Theme.Gradients = {
	lime = { hex("B8FF19"), hex("4AD800") },
	cyan = { hex("53F0FF"), hex("069EDF") },
	violet = { hex("D95AFF"), hex("7A22F0") },
	purple = { hex("B07BFF"), hex("5B2BE0") },
	orange = { hex("FFD252"), hex("F18A00") },
	gold = { hex("FFF16A"), hex("FFBB00") },
	red = { hex("FF5444"), hex("DF1429") },
	grey = { hex("9AA0AE"), hex("5D6372") },
	disabled = { hex("7D8290"), hex("555A66") },
}

-- Rarity palette only: never a currency, and never inferred from a sack's position in the ladder.
Theme.Rarity = {
	Common = hex("A9ADBA"),
	Uncommon = hex("66E835"),
	Rare = hex("21B8FF"),
	Epic = hex("C354FF"),
	Legendary = hex("FFD432"),
	Mythic = hex("FF65C7"),
	Divine = hex("FFF6C8"),
	Secret = hex("FFFFFF"),
}

Theme.Font = Enum.Font.FredokaOne

Theme.Layout = {
	modalW = 1200,
	modalH = 760,
	header = 90,
	footer = 84,
	pad = 24,
	gap = 20,
	radius = 8,
	stroke = 4,
	tap = 48,
	minText = 16,
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

-- Texture alpha: quiet studs on bodies, a little stronger on coloured headers.
Theme.Studs = { body = 0.9, header = 0.86, tile = 26 }

return Theme
