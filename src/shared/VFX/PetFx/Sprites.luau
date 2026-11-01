--!strict
-- Particle sprites for the egg/pet effects (VFX/PetFx): assets/pet-vfx/vfx_<name>.png, the 45 transparent PNGs of
-- the 79-pair art package (25 base + 20 high-tier). Upload them (Creator Hub > Development items > Images, use the
-- IMAGE id, not the Decal id) and put the ids in UPLOADED. Until then Studio shows the local copies staged by
-- tools/preview/stage-art.sh, and live servers use a Roblox built-in texture with one warning per sprite.
-- "sack_<name>" are the Kick Sack sprites, already uploaded (VFX/SackAura).
-- "frost_<name>" are the Frost Serpent's own sprites (assets/pet-vfx/vfx_frost_*.png, drawn by
-- tools/blender/pets/kit/sprites.py): sigil, rune_ring, spark, flake, mist, cube.
-- "meadow_<name>" are the Meadow pairs' own pixel sprites (zones/zone01_meadow.py): leaf, blossom, honey drop.
-- "v3_<name>" are the V3 remodel sprites (tools/blender/pets/v3/sprites_v3.py): the top tier's sun, gear and prism
-- sigils, rays, steam, feather and cog, plus clover, petal, droplet, bubble, sparkle, ripple and shadow; and the
-- signature effects' shaft (light shafts), arc (lightning), clock_dial and veil (aurora sheets) (sprites_signature.py).
-- The frost, meadow and v3 sprites are uploaded: Decal ids in tools/world/ids/pet-vfx.json, Image ids below.
local RunService = game:GetService("RunService")

local Sprites = {}

-- Image ids (resolved from the uploaded Decals, tools/world/ids/pet-vfx.json).
local UPLOADED: { [string]: string } = {
	frost_cube = "rbxassetid://85676958444440",
	frost_flake = "rbxassetid://123815258124915",
	frost_mist = "rbxassetid://114596350917381",
	frost_rune_ring = "rbxassetid://103729123161806",
	frost_sigil = "rbxassetid://119563595237549",
	frost_spark = "rbxassetid://88625969712095",
	meadow_blossom = "rbxassetid://134096189291924",
	meadow_honey = "rbxassetid://128887807493843",
	meadow_leaf = "rbxassetid://113598579979245",
	v3_arc = "rbxassetid://119541733058589",
	v3_bubble = "rbxassetid://73367184848295",
	v3_clock_dial = "rbxassetid://80725111393656",
	v3_clover = "rbxassetid://73902450345163",
	v3_cog = "rbxassetid://121925173518465",
	v3_droplet = "rbxassetid://82969393381613",
	v3_feather = "rbxassetid://90191710527650",
	v3_gear_sigil = "rbxassetid://85192584983147",
	v3_petal = "rbxassetid://96081956109381",
	v3_prism_sigil = "rbxassetid://132431663406726",
	v3_rays = "rbxassetid://70464277835228",
	v3_ripple = "rbxassetid://121273601269778",
	v3_shadow = "rbxassetid://114372794530941",
	v3_shaft = "rbxassetid://138816865541863",
	v3_sparkle = "rbxassetid://77619531977408",
	v3_steam = "rbxassetid://132881811670369",
	v3_sun_sigil = "rbxassetid://118282650516582",
	v3_veil = "rbxassetid://89839204688655",
}

local SACK: { [string]: string } = {
	sack_glow = "rbxassetid://71769032644460",
	sack_spark = "rbxassetid://93549276919655",
	sack_star = "rbxassetid://101074548689105",
	sack_smoke = "rbxassetid://90864470326650",
	sack_ring = "rbxassetid://98854133664400",
	sack_sunburst = "rbxassetid://100264183171540",
	sack_galaxy = "rbxassetid://126996644416188",
	sack_comet = "rbxassetid://134687096930101",
	sack_flame = "rbxassetid://140702759928651",
	sack_bubble = "rbxassetid://120969967687049",
	sack_snowflake = "rbxassetid://96305288386322",
	sack_electric = "rbxassetid://102335833593358",
}

local GLOW = "rbxasset://textures/particles/forcefield_glow_main.dds"
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local RING = "rbxasset://textures/particles/explosion01_shockwave_main.dds"
local CORE = "rbxasset://textures/particles/explosion01_core_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

-- Every package sprite, with the built-in texture closest in shape (live servers, before upload).
local NAMES: { [string]: string } = {
	aurora_ribbon = GLOW,
	beam_vertical = GLOW,
	bubble_aqua = RING,
	candy_heart = SPARKLE,
	comet_streak_blue = SPARKLE,
	comet_streak_gold = SPARKLE,
	core_burst = CORE,
	cosmic_orb = GLOW,
	divine_sigil = RING,
	droplet_aqua = SPARKLE,
	ember_orange = FIRE,
	energy_arc_cyan = SPARKLE,
	feather_light = SPARKLE,
	frost_cube = SPARKLE,
	frost_flake = SPARKLE,
	frost_mist = SMOKE,
	frost_rune_ring = RING,
	frost_sigil = RING,
	frost_spark = SPARKLE,
	galaxy_nebula = SMOKE,
	halo_gold = RING,
	halo_ring = RING,
	halo_white = RING,
	leaf_autumn = SPARKLE,
	leaf_green = SPARKLE,
	meadow_blossom = SPARKLE,
	meadow_honey = SPARKLE,
	meadow_leaf = SPARKLE,
	lightning_cyan = SPARKLE,
	mushroom_pink = SPARKLE,
	planet_orbit_ring = RING,
	pollen_gold = GLOW,
	prism_glint = SPARKLE,
	prism_ring = RING,
	prism_twinkle = SPARKLE,
	prismatic_burst = CORE,
	rainbow_ribbon = GLOW,
	rock_molten = FIRE,
	rune_cyan = SPARKLE,
	sand_grain = SPARKLE,
	shard_ice = SPARKLE,
	shard_prism = SPARKLE,
	smoke_gray = SMOKE,
	snowflake_ice = SPARKLE,
	soft_glow_green = GLOW,
	soft_glow_violet = GLOW,
	v3_arc = GLOW,
	v3_bubble = RING,
	v3_clock_dial = RING,
	v3_clover = SPARKLE,
	v3_cog = SPARKLE,
	v3_droplet = SPARKLE,
	v3_feather = SPARKLE,
	v3_gear_sigil = RING,
	v3_petal = SPARKLE,
	v3_prism_sigil = RING,
	v3_rays = CORE,
	v3_ripple = RING,
	v3_shadow = GLOW,
	v3_shaft = GLOW,
	v3_sparkle = SPARKLE,
	v3_steam = SMOKE,
	v3_sun_sigil = RING,
	v3_veil = GLOW,
	soft_glow_white = GLOW,
	solar_rays = CORE,
	spore_magenta = GLOW,
	star_cross_large = SPARKLE,
	star_pastel = SPARKLE,
	star_white = SPARKLE,
	void_sigil = RING,
	void_spiral = SMOKE,
}

local warned: { [string]: boolean } = {}

-- Content id for a sprite name ("leaf_green", "halo_gold", "sack_glow", ...). Unknown names error in Studio.
function Sprites.get(name: string): string
	local sack = SACK[name]
	if sack then
		return sack
	end
	local id = UPLOADED[name]
	if id then
		return id
	end
	local builtin = NAMES[name]
	if not builtin then
		if RunService:IsStudio() then
			error(`[PetFx] unknown sprite "{name}"`)
		end
		return GLOW
	end
	if RunService:IsStudio() then
		return `rbxasset://textures/KickTheEggUI/vfx_{name}.png`
	end
	if not warned[name] then -- never fall back silently
		warned[name] = true
		warn(`[PetFx] vfx_{name}.png has no uploaded image id: using a built-in texture (VFX/PetFx/Sprites)`)
	end
	return builtin
end

function Sprites.has(name: string): boolean
	return SACK[name] ~= nil or NAMES[name] ~= nil
end

function Sprites.names(): { string }
	local out = {}
	for name in NAMES do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

return Sprites
