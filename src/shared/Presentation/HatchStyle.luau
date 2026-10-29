--!strict
-- How a hatch is staged, per rarity (Config/Rarities names), plus signature accents for single pets. Data only:
-- HatchCinematicController reads it. Durations are seconds for the full version (the hatching player). Watchers
-- and Reduced Motion get the short version: no anticipation or camera, and the growth runs at `quick` speed.
--   silhouette  "Dark" (black fill, rarity outline) or "Light" (white fill) while the pet grows
--   anticipation  egg build-up before the shell breaks
--   grow  silhouette from tiny to the pet's real size
--   reveal  silhouette fades into the real materials
--   sparkles / rings / aura / pillar / orbit  effect budget (halved with Low Detail effects)
--   accent  sound accent after the reveal (Audio events)
local HatchStyle = {}

export type Tier = {
	silhouette: "Dark" | "Light",
	anticipation: number,
	grow: number,
	reveal: number,
	sparkles: number,
	rings: number,
	aura: boolean,
	pillar: boolean,
	orbit: number, -- orbiting light motes around the growing silhouette
	camera: boolean, -- gentle camera framing for the hatching player
	accent: string,
}

local T: { [string]: Tier } = {
	Common = {
		silhouette = "Dark",
		anticipation = 0.55,
		grow = 0.85,
		reveal = 0.3,
		sparkles = 12,
		rings = 1,
		aura = false,
		pillar = false,
		orbit = 0,
		camera = true,
		accent = "UISuccess",
	},
	Uncommon = {
		silhouette = "Dark",
		anticipation = 0.6,
		grow = 0.9,
		reveal = 0.32,
		sparkles = 16,
		rings = 1,
		aura = false,
		pillar = false,
		orbit = 0,
		camera = true,
		accent = "UISuccess",
	},
	Rare = {
		silhouette = "Dark",
		anticipation = 0.7,
		grow = 1.05,
		reveal = 0.36,
		sparkles = 22,
		rings = 1,
		aura = false,
		pillar = false,
		orbit = 4,
		camera = true,
		accent = "UISuccess",
	},
	Epic = {
		silhouette = "Dark",
		anticipation = 0.8,
		grow = 1.2,
		reveal = 0.4,
		sparkles = 28,
		rings = 2,
		aura = true,
		pillar = false,
		orbit = 6,
		camera = true,
		accent = "UISuccess",
	},
	Legendary = {
		silhouette = "Dark",
		anticipation = 0.9,
		grow = 1.35,
		reveal = 0.45,
		sparkles = 34,
		rings = 2,
		aura = true,
		pillar = true,
		orbit = 8,
		camera = true,
		accent = "MilestoneClaim",
	},
	Mythic = {
		silhouette = "Dark",
		anticipation = 1,
		grow = 1.45,
		reveal = 0.5,
		sparkles = 40,
		rings = 3,
		aura = true,
		pillar = true,
		orbit = 10,
		camera = true,
		accent = "MilestoneClaim",
	},
	Divine = {
		silhouette = "Light",
		anticipation = 1.05,
		grow = 1.55,
		reveal = 0.55,
		sparkles = 46,
		rings = 3,
		aura = true,
		pillar = true,
		orbit = 12,
		camera = true,
		accent = "MilestoneClaim",
	},
	Secret = {
		silhouette = "Light",
		anticipation = 1.15,
		grow = 1.7,
		reveal = 0.6,
		sparkles = 54,
		rings = 3,
		aura = true,
		pillar = true,
		orbit = 14,
		camera = true,
		accent = "MilestoneClaim",
	},
}
HatchStyle.Tiers = T

-- Signature accents for single pets (Config/Pets `model` key), layered on top of the rarity tier. Any pet can get
-- one by adding an entry; the controller has no pet names in it.
--   motif  "Frost" (ice shards and a cold rim), "Prism" (cycling rainbow rim and prismatic motes)
--   silhouette / tint  override the tier's silhouette and the effect colour
export type Signature = { motif: string?, silhouette: ("Dark" | "Light")?, tint: Color3? }
HatchStyle.Signatures = {
	FrostSerpent = { motif = "Frost", tint = Color3.fromRGB(150, 225, 255) },
	PrismSeraph = { motif = "Prism", silhouette = "Light" },
} :: { [string]: Signature }

-- Landing after the reveal, from the rig itself (Anim/Pet joint groups) unless a pet overrides it:
-- "Unfold" (WingL / WingR), "Rise" (serpent Coil), "Heavy" (a pet this big), else "Hop".
HatchStyle.HEAVY_HEIGHT = 9 -- studs, after its size mutation
HatchStyle.Landing = {} :: { [string]: string }

function HatchStyle.tier(rarity: string?): Tier
	return T[rarity or "Common"] or T.Common
end

-- Seconds the server keeps a freshly hatched pet still (the reveal plays where it hatched).
HatchStyle.HOLD_SECONDS = 6

return HatchStyle
