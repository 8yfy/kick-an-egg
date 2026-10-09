--!strict
-- CONTRACT FILE: change only via a `contract:` PR.
export type Rarity = {
	order: number,
	color: Color3,
	glow: boolean, -- adds PointLight + Neon accents
	particles: number, -- 0..3 VFX intensity tier
	announce: boolean, -- server-wide message on roll
}

local Rarities: { [string]: Rarity } = {
	Common = { order = 1, color = Color3.fromRGB(190, 190, 190), glow = false, particles = 0, announce = false },
	Uncommon = { order = 2, color = Color3.fromRGB(85, 220, 95), glow = false, particles = 0, announce = false },
	Rare = { order = 3, color = Color3.fromRGB(60, 150, 255), glow = false, particles = 1, announce = false },
	Epic = { order = 4, color = Color3.fromRGB(170, 85, 255), glow = true, particles = 1, announce = false },
	Legendary = { order = 5, color = Color3.fromRGB(255, 195, 40), glow = true, particles = 2, announce = true },
	Mythic = { order = 6, color = Color3.fromRGB(255, 60, 80), glow = true, particles = 2, announce = true },
	Divine = { order = 7, color = Color3.fromRGB(255, 250, 200), glow = true, particles = 3, announce = true },
	Secret = { order = 8, color = Color3.fromRGB(255, 255, 255), glow = true, particles = 3, announce = true }, -- rainbow gradient in UI
}

return Rarities
