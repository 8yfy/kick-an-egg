--!nonstrict
-- Vendored from the Kick Sacks package (Kick_Sacks_Roblox_Complete/RobloxStudio/ModuleScripts/SackConfig.lua):
-- kept close to the source on purpose (CLAUDE_PROMPT: minimal targeted changes), so not --!strict.
-- Single reference for tier names, rarity, reference GLB and source bounds.
local Colors = require(script.Parent:WaitForChild("SackColors"))
local GLB = require(script.Parent:WaitForChild("SackGLBData"))
local Config = {}
Config.MetersToStuds = 10
Config.RarityColors = {
    Common=Color3.fromRGB(185,182,171), Rare=Color3.fromRGB(90,168,255),
    Epic=Color3.fromRGB(185,122,255), Legendary=Color3.fromRGB(255,180,68),
    Mythic=Color3.fromRGB(255,122,208),
}
function Config.Get(tier)
    assert(type(tier)=="number" and tier>=1 and tier<=20 and tier%1==0, "Tier must be 1..20")
    local source=GLB[tier]
    local data=Colors.Tiers[tier]
    return {
        Tier=tier, Name=data.Name, Rarity=data.Rarity,
        MeshName=string.format("Sack_%02d",tier),
        GLBFilename=source.File,
        SourceBounds={Min=source.Min,Max=source.Max},
        RarityColor=Config.RarityColors[data.Rarity]
    }
end
return Config
