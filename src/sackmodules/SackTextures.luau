--!nonstrict
-- Vendored from the Kick Sacks package (Kick_Sacks_Roblox_Complete/RobloxStudio/ModuleScripts/SackTextures.lua):
-- kept close to the source on purpose (CLAUDE_PROMPT: minimal targeted changes), so not --!strict.
-- Upload each PNG from Assets/VFX_Textures using Studio Asset Manager.
-- Paste the resulting Roblox decal/image IDs below. Non-uploaded images use built-in fallbacks.
local TextureIds = {}
TextureIds.IDs = {
    galaxy = 0, -- sackvfx_galaxy.png
    glow = 0, -- sackvfx_glow.png
    ring = 0, -- sackvfx_ring.png
    smoke = 0, -- sackvfx_smoke.png
    spark = 0, -- sackvfx_spark.png
    square = 0, -- sackvfx_square.png
    star = 0, -- sackvfx_star.png
    sunburst = 0, -- sackvfx_sunburst.png
    comet = 0, -- sackvfx_comet.png
    flame = 0, -- sackvfx_flame.png
    bubble = 0, -- sackvfx_bubble.png
    snowflake = 0, -- sackvfx_snowflake.png
    electric = 0, -- sackvfx_electric.png
}
TextureIds.Fallbacks = {
    galaxy = "rbxasset://textures/particles/sparkles_main.dds",
    glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
    ring = "rbxasset://textures/particles/forcefield_glow_main.dds",
    smoke = "rbxasset://textures/particles/smoke_main.dds",
    spark = "rbxasset://textures/particles/sparkles_main.dds",
    square = "rbxasset://textures/particles/sparkles_main.dds",
    star = "rbxasset://textures/particles/sparkles_main.dds",
    sunburst = "rbxasset://textures/particles/sparkles_main.dds",
    comet = "rbxasset://textures/particles/sparkles_main.dds",
    flame = "rbxasset://textures/particles/fire_main.dds",
    bubble = "rbxasset://textures/particles/forcefield_glow_main.dds",
    snowflake = "rbxasset://textures/particles/sparkles_main.dds",
    electric = "rbxasset://textures/particles/sparkles_main.dds",
}
function TextureIds.Get(key)
    local id = TextureIds.IDs[key]
    if type(id) == "number" and id > 0 then return "rbxassetid://" .. tostring(id) end
    if type(id) == "string" and id ~= "" and id ~= "0" then
        if id:match("^%d+$") then return "rbxassetid://" .. id end
        return id
    end
    -- Kick The Egg change: in Studio only, show the real sprite from the local content copy
    -- (tools/preview/stage-art.sh) until it is uploaded. Live servers still use the fallbacks below.
    if game:GetService("RunService"):IsStudio() then return "rbxasset://textures/KickTheEggUI/sackvfx_" .. key .. ".png" end
    -- Kick The Egg change: never fall back silently
    TextureIds._warned = TextureIds._warned or {}
    if not TextureIds._warned[key] then
        TextureIds._warned[key] = true
        warn("[SackTextures] sackvfx_" .. key .. ".png has no uploaded image id: using a built-in fallback (assets/sack-vfx, tools/sacks/IMPORT.md)")
    end
    return TextureIds.Fallbacks[key] or TextureIds.Fallbacks.glow
end
-- Kick The Egg change: true when Get(key) returns the real sprite (uploaded, or the Studio local copy).
function TextureIds.Has(key)
    local id = TextureIds.IDs[key]
    return (id ~= nil and id ~= 0 and id ~= "" and id ~= "0") or game:GetService("RunService"):IsStudio()
end
return TextureIds
