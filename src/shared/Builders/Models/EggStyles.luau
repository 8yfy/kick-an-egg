--!strict
-- Partner A. Parametric egg specs so every egg is DATA:
--   EggStyles.build({ rarity = "Epic", colors = { base, main, accent }, pattern = "flames", top = "horns" })
-- Patterns: "spots" | "stripes" | "flames" | "crystal" | "armor" | "frost" | "stars" | "scales" | "drips" | "rainbow"
-- Tops (hint at the pet): "sprout" | "horns" | "antennae" | "crown" | "fin" | "ears" | "flame" | "crystal" | "halo"
-- Rare+ get the Neon rarity band + light; Legendary+ an "Orbit" ring of Neon cubes (spun by Anim);
-- Mythic+ a second ring.
local Builder = require(script.Parent.Parent.BlockBuilder)
local Kit = require(script.Parent.Kit)
local Rarities = require(script.Parent.Parent.Parent.Config.Rarities)

type PartSpec = Builder.PartSpec

export type Def = {
	rarity: string,
	colors: { Color3 }, -- { base (bottom layer), main, accent }
	pattern: string?,
	top: string?,
	metal: Color3?,
	glow: Color3?,
}

local P = Kit.part
local GOLD = Color3.fromRGB(255, 205, 60)
local EggStyles = {}

local function layers(def: Def): { Color3 }
	local b, m, a = def.colors[1], def.colors[2], def.colors[3]
	if def.pattern == "stripes" then
		return { b, m, a, m, a, m, m }
	elseif def.pattern == "rainbow" then
		local out = {}
		for i = 1, 7 do
			out[i] = Color3.fromHSV((i - 1) / 7, 0.5, 1)
		end
		return out
	end
	return { b, m, m, m, m, m, a }
end

local function pattern(parts: { PartSpec }, def: Def, glow: Color3, metal: Color3)
	local a = def.colors[3]
	local kind = def.pattern
	if kind == "spots" then
		for i, o in
			{
				{ "F", -0.5, 1.35 },
				{ "F", 0.55, 2.2 },
				{ "R", 0.3, 1.3 },
				{ "L", -0.25, 2.1 },
				{ "B", 0.4, 1.5 },
				{ "B", -0.5, 2.3 },
			}
		do
			table.insert(parts, Kit.onShell("Spot" .. i, o[1], o[2], o[3], 0.5, 0.45, a))
		end
	elseif kind == "flames" then
		for i, side in { "F", "R", "B", "L" } do
			table.insert(
				parts,
				Kit.onShell("Flame" .. i, side, 0, 0.9, 0.7, 0.75, Color3.fromRGB(255, 120, 30), { material = "Neon" })
			)
			table.insert(
				parts,
				Kit.onShell(
					"FlameTip" .. i,
					side,
					0.15,
					1.45,
					0.4,
					0.5,
					Color3.fromRGB(255, 220, 80),
					{ material = "Neon" }
				)
			)
		end
	elseif kind == "crystal" then
		for i, o in { { 0.9, 2.5, 0.4, 35 }, { -0.9, 2.3, -0.3, -35 }, { 0.2, 2.6, -0.9, 20 }, { -0.3, 2.4, 0.9, -20 } } do
			local rot = { o[4] * (if i > 2 then 1 else 0), 0, -o[4] * (if i <= 2 then 1 else 0) }
			table.insert(
				parts,
				P(
					"Crystal" .. i,
					{ 0.4, 1.0, 0.4 },
					{ o[1], o[2], o[3] },
					a,
					{ joint = "Body", rot = rot, material = "Glass", transparency = 0.15 }
				)
			)
			table.insert(
				parts,
				P(
					"CrystalCore" .. i,
					{ 0.15, 0.7, 0.15 },
					{ o[1], o[2], o[3] },
					glow,
					{ joint = "Body", rot = rot, material = "Neon" }
				)
			)
		end
	elseif kind == "armor" then
		for i, side in { "F", "R", "B", "L" } do
			table.insert(parts, Kit.onShell("Plate" .. i, side, 0, 1.4, 1.2, 0.6, metal))
			table.insert(parts, Kit.onShell("Rivet" .. i, side, 0.45, 1.6, 0.18, 0.18, GOLD))
		end
	elseif kind == "frost" then
		for i = 2, 6 do -- frost rim on every layer step
			local w, bottom, cy = Kit.eggLayer(i)
			local topY = 2 * cy - bottom
			table.insert(
				parts,
				P(
					"Frost" .. i,
					{ w + 0.04, 0.1, w + 0.04 },
					{ 0, topY + 0.03, 0 },
					Color3.fromRGB(240, 250, 255),
					{ joint = "Body", material = "Glass", transparency = 0.1 }
				)
			)
		end
		for i, side in { "F", "R", "B", "L" } do
			table.insert(
				parts,
				Kit.onShell(
					"Icicle" .. i,
					side,
					-0.3 + i * 0.15,
					0.85,
					0.2,
					0.4,
					Color3.fromRGB(200, 235, 255),
					{ material = "Glass", transparency = 0.2 }
				)
			)
		end
	elseif kind == "stars" then
		for i, o in
			{
				{ "F", -0.5, 1.4 },
				{ "F", 0.5, 2.3 },
				{ "R", 0.2, 1.8 },
				{ "L", -0.3, 1.3 },
				{ "B", 0.4, 2.2 },
				{ "B", -0.4, 1.2 },
			}
		do
			local diamond = if o[1] == "F" or o[1] == "B" then { 0, 0, 45 } else { 45, 0, 0 }
			table.insert(
				parts,
				Kit.onShell("Star" .. i, o[1], o[2], o[3], 0.32, 0.32, glow, { material = "Neon", rot = diamond })
			)
		end
	elseif kind == "scales" then
		local n = 0
		for _, side in { "F", "R", "B", "L" } do
			for _, o in { { -0.5, 1.2 }, { 0.5, 1.2 }, { 0, 1.75 } } do
				n += 1
				table.insert(parts, Kit.onShell("Scale" .. n, side, o[1], o[2], 0.45, 0.35, a))
			end
		end
	elseif kind == "drips" then
		for i, side in { "F", "R", "B", "L" } do
			table.insert(parts, Kit.onShell("Drip" .. i, side, -0.4 + (i % 2) * 0.7, 2.75, 0.35, 0.6, a))
			table.insert(parts, Kit.onShell("DripB" .. i, side, 0.45 - (i % 2) * 0.8, 2.85, 0.3, 0.4, a))
		end
	end
end

local function top(parts: { PartSpec }, def: Def, glow: Color3, metal: Color3)
	local a, m = def.colors[3], def.colors[2]
	local kind = def.top
	local y = Kit.EGG_HEIGHT
	if kind == "sprout" then
		table.insert(
			parts,
			P("Stem", { 0.15, 0.45, 0.15 }, { 0, y + 0.2, 0 }, Color3.fromRGB(65, 145, 55), { joint = "Body" })
		)
		table.insert(
			parts,
			P(
				"SproutL",
				{ 0.55, 0.1, 0.3 },
				{ -0.3, y + 0.4, 0 },
				Color3.fromRGB(150, 225, 100),
				{ joint = "Body", rot = { 0, 0, -25 } }
			)
		)
		table.insert(
			parts,
			P(
				"SproutR",
				{ 0.55, 0.1, 0.3 },
				{ 0.3, y + 0.4, 0 },
				Color3.fromRGB(150, 225, 100),
				{ joint = "Body", rot = { 0, 0, 25 } }
			)
		)
	elseif kind == "horns" then
		table.insert(
			parts,
			P("HornL", { 0.25, 0.6, 0.25 }, { -0.35, y + 0.2, 0 }, metal, { joint = "Body", rot = { 0, 0, 20 } })
		)
		table.insert(
			parts,
			P("HornR", { 0.25, 0.6, 0.25 }, { 0.35, y + 0.2, 0 }, metal, { joint = "Body", rot = { 0, 0, -20 } })
		)
	elseif kind == "antennae" then
		table.insert(
			parts,
			P("AntennaL", { 0.1, 0.6, 0.1 }, { -0.25, y + 0.2, 0 }, metal, { joint = "Body", rot = { 0, 0, 20 } })
		)
		table.insert(
			parts,
			P("AntennaR", { 0.1, 0.6, 0.1 }, { 0.25, y + 0.2, 0 }, metal, { joint = "Body", rot = { 0, 0, -20 } })
		)
		table.insert(
			parts,
			P(
				"AntTipL",
				{ 0.3, 0.3, 0.3 },
				{ -0.38, y + 0.52, 0 },
				glow,
				{ joint = "Body", shape = "Ball", material = "Neon" }
			)
		)
		table.insert(
			parts,
			P(
				"AntTipR",
				{ 0.3, 0.3, 0.3 },
				{ 0.38, y + 0.52, 0 },
				glow,
				{ joint = "Body", shape = "Ball", material = "Neon" }
			)
		)
	elseif kind == "crown" then
		table.insert(parts, P("CrownBand", { 0.9, 0.2, 0.9 }, { 0, y + 0.1, 0 }, GOLD, { joint = "Body" }))
		for i, o in { { -0.35, -0.35 }, { 0.35, -0.35 }, { 0, 0.35 } } do
			table.insert(
				parts,
				P("CrownPoint" .. i, { 0.18, 0.35, 0.18 }, { o[1], y + 0.35, o[2] }, GOLD, { joint = "Body" })
			)
		end
	elseif kind == "fin" then
		table.insert(parts, P("Fin", { 0.15, 0.7, 0.9 }, { 0, y + 0.3, 0.1 }, a, { joint = "Body", shape = "Wedge" }))
	elseif kind == "ears" then
		table.insert(
			parts,
			P(
				"EarL",
				{ 0.2, 0.6, 0.45 },
				{ -0.4, y + 0.15, 0 },
				m,
				{ joint = "Body", shape = "Wedge", rot = { 0, 0, 20 } }
			)
		)
		table.insert(
			parts,
			P(
				"EarR",
				{ 0.2, 0.6, 0.45 },
				{ 0.4, y + 0.15, 0 },
				m,
				{ joint = "Body", shape = "Wedge", rot = { 0, 0, -20 } }
			)
		)
	elseif kind == "flame" then
		table.insert(
			parts,
			P(
				"TopFlame",
				{ 0.6, 0.6, 0.6 },
				{ 0, y + 0.25, 0 },
				Color3.fromRGB(255, 120, 30),
				{ joint = "Body", material = "Neon", rot = { 0, 45, 0 } }
			)
		)
		table.insert(
			parts,
			P(
				"TopFlameTip",
				{ 0.35, 0.45, 0.35 },
				{ 0, y + 0.7, 0 },
				Color3.fromRGB(255, 220, 80),
				{ joint = "Body", material = "Neon", rot = { 0, 45, 0 } }
			)
		)
	elseif kind == "crystal" then
		table.insert(
			parts,
			P(
				"TopCrystal",
				{ 0.45, 1.0, 0.45 },
				{ 0, y + 0.45, 0 },
				a,
				{ joint = "Body", material = "Glass", transparency = 0.15, rot = { 0, 45, 0 } }
			)
		)
		table.insert(
			parts,
			P(
				"TopCore",
				{ 0.18, 0.7, 0.18 },
				{ 0, y + 0.45, 0 },
				glow,
				{ joint = "Body", material = "Neon", rot = { 0, 45, 0 } }
			)
		)
	elseif kind == "halo" then
		for i = 1, 6 do
			local ang = (i - 1) / 6 * 2 * math.pi
			table.insert(
				parts,
				P(
					"HaloCube" .. i,
					{ 0.22, 0.22, 0.22 },
					{ math.cos(ang) * 0.55, y + 0.5, math.sin(ang) * 0.55 },
					GOLD,
					{ joint = "Body", material = "Neon" }
				)
			)
		end
	end
end

local function ring(
	parts: { PartSpec },
	joint: string,
	y: number,
	radius: number,
	count: number,
	size: number,
	color: Color3
)
	table.insert(
		parts,
		P(joint .. "Hub", { 0.2, 0.2, 0.2 }, { 0, y, 0 }, color, { joint = joint, transparency = 1, studs = false })
	)
	for i = 1, count do
		local a = (i - 1) / count * 2 * math.pi
		table.insert(
			parts,
			P(joint .. "Cube" .. i, { size, size, size }, { math.cos(a) * radius, y, math.sin(a) * radius }, color, {
				joint = joint,
				material = "Neon",
				rot = { 45, i * 30, 45 },
			})
		)
	end
end

function EggStyles.build(def: Def): Builder.Spec
	local rarity = Rarities[def.rarity] or Rarities.Common
	local glow = def.glow or rarity.color
	local metal = def.metal or def.colors[3]:Lerp(Color3.new(0, 0, 0), 0.35)
	local parts = Kit.eggShell(layers(def))
	pattern(parts, def, glow, metal)
	top(parts, def, glow, metal)
	if rarity.order >= Rarities.Rare.order then
		table.insert(parts, Kit.eggBand(3, def.rarity))
	end
	if rarity.order >= Rarities.Legendary.order then
		ring(parts, "Orbit", 1.8, 2.3, 4, 0.35, rarity.color)
	end
	if rarity.order >= Rarities.Mythic.order then
		ring(parts, "Orbit2", 2.8, 1.8, 6, 0.25, GOLD)
	end
	return { parts = parts }
end

return EggStyles
