--!nonstrict
-- Vendored from the Kick Sacks package (Kick_Sacks_Roblox_Complete/RobloxStudio/ModuleScripts/SackColors.lua):
-- kept close to the source on purpose (CLAUDE_PROMPT: minimal targeted changes), so not --!strict.
-- Generated from the original sacks.js palette and material hints.
-- Studio > ReplicatedStorage > SackModules > SackColors (ModuleScript)
local Colors = {}
local function spec(hex, material, transparency, neon)
    return { Color = Color3.fromRGB(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16)), Material = material, Transparency = transparency or 0, Neon = neon or false }
end
Colors.Tiers = {
    [1] = { Name = 'Burlap Sack', Rarity = 'Common', Palette = {
        ['burlap'] = spec('B08A58', Enum.Material.Fabric, 0.00, false),
        ['wood'] = spec('6E4A28', Enum.Material.Wood, 0.00, false),
        ['rope'] = spec('9C7646', Enum.Material.Fabric, 0.00, false),
        ['patch_cloth'] = spec('8A6436', Enum.Material.Fabric, 0.00, false),
        ['thread'] = spec('E2CFA4', Enum.Material.Fabric, 0.00, false),
        ['steel'] = spec('9AA0A8', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'burlap', Cap = 'wood', Chain = 'steel', Strap = 'rope', Rope = 'rope' } },
    [2] = { Name = 'Gym Canvas', Rarity = 'Common', Palette = {
        ['canvas'] = spec('ECE6D8', Enum.Material.Fabric, 0.00, false),
        ['gym_red'] = spec('C4242C', Enum.Material.SmoothPlastic, 0.00, false),
        ['label_black'] = spec('1A1A1C', Enum.Material.SmoothPlastic, 0.00, false),
        ['cuff_white'] = spec('F4F4F0', Enum.Material.SmoothPlastic, 0.00, false),
        ['steel'] = spec('9AA0A8', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'canvas', Cap = 'gym_red', Chain = 'steel', Strap = 'label_black', Rope = nil } },
    [3] = { Name = 'Leather Classic', Rarity = 'Common', Palette = {
        ['leather_black'] = spec('221E1E', Enum.Material.SmoothPlastic, 0.00, false),
        ['gold_trim'] = spec('D8A84C', Enum.Material.Metal, 0.00, false),
        ['glove_red'] = spec('C0202A', Enum.Material.SmoothPlastic, 0.00, false),
        ['cuff_white'] = spec('F0F0EA', Enum.Material.SmoothPlastic, 0.00, false),
        ['steel'] = spec('8C929A', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'leather_black', Cap = 'leather_black', Chain = 'steel', Strap = 'leather_black', Rope = nil } },
    [4] = { Name = 'Pro Red', Rarity = 'Common', Palette = {
        ['pro_red'] = spec('C81C26', Enum.Material.SmoothPlastic, 0.00, false),
        ['pro_white'] = spec('F2F2EE', Enum.Material.SmoothPlastic, 0.00, false),
        ['gold'] = spec('E2B44A', Enum.Material.Metal, 0.00, false),
        ['steel'] = spec('A8AEB6', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'pro_red', Cap = 'pro_white', Chain = 'steel', Strap = 'pro_white', Rope = nil } },
    [5] = { Name = 'Tire Stack', Rarity = 'Common', Palette = {
        ['rubber'] = spec('1C1C1F', Enum.Material.Rubber, 0.00, false),
        ['stripe_yellow'] = spec('E8B81E', Enum.Material.SmoothPlastic, 0.00, false),
        ['steel_rim'] = spec('8D939B', Enum.Material.Metal, 0.00, false),
        ['rope'] = spec('8C6A40', Enum.Material.Fabric, 0.00, false),
    }, Base = { Body = 'rubber', Cap = 'steel_rim', Chain = 'steel_rim', Strap = 'steel_rim', Rope = 'rope' } },
    [6] = { Name = 'Iron Plate', Rarity = 'Rare', Palette = {
        ['iron'] = spec('8C939C', Enum.Material.Metal, 0.00, false),
        ['iron_dark'] = spec('40454C', Enum.Material.Metal, 0.00, false),
        ['hazard_yellow'] = spec('F0C020', Enum.Material.SmoothPlastic, 0.00, false),
        ['hazard_black'] = spec('141414', Enum.Material.SmoothPlastic, 0.00, false),
        ['rust'] = spec('8A3A1C', Enum.Material.SmoothPlastic, 0.00, false),
        ['warn_red'] = spec('FF3020', Enum.Material.Neon, 0.00, true),
    }, Base = { Body = 'iron', Cap = 'iron_dark', Chain = 'iron', Strap = 'iron_dark', Rope = nil } },
    [7] = { Name = 'Bronze Statue', Rarity = 'Rare', Palette = {
        ['bronze'] = spec('B87333', Enum.Material.Metal, 0.00, false),
        ['bronze_dark'] = spec('6A3C1A', Enum.Material.Metal, 0.00, false),
        ['verdigris'] = spec('4F9C88', Enum.Material.SmoothPlastic, 0.00, false),
    }, Base = { Body = 'bronze', Cap = 'bronze_dark', Chain = 'bronze', Strap = 'bronze_dark', Rope = nil } },
    [8] = { Name = 'Silver Knight', Rarity = 'Rare', Palette = {
        ['silver'] = spec('D2D6DE', Enum.Material.Metal, 0.00, false),
        ['steel_dark'] = spec('555B66', Enum.Material.Metal, 0.00, false),
        ['heraldic_blue'] = spec('2456D0', Enum.Material.SmoothPlastic, 0.00, false),
        ['gold_trim'] = spec('E0B250', Enum.Material.Metal, 0.00, false),
        ['visor_black'] = spec('0C0D10', Enum.Material.SmoothPlastic, 0.00, false),
    }, Base = { Body = 'silver', Cap = 'steel_dark', Chain = 'silver', Strap = 'steel_dark', Rope = nil } },
    [9] = { Name = 'Gold Champion', Rarity = 'Rare', Palette = {
        ['gold'] = spec('F0C04C', Enum.Material.Metal, 0.00, false),
        ['gold_deep'] = spec('B8862A', Enum.Material.Metal, 0.00, false),
        ['belt_leather'] = spec('18181C', Enum.Material.SmoothPlastic, 0.00, false),
        ['ruby'] = spec('E01840', Enum.Material.SmoothPlastic, 0.00, false),
        ['sapphire'] = spec('2A8CE0', Enum.Material.SmoothPlastic, 0.00, false),
    }, Base = { Body = 'gold', Cap = 'gold_deep', Chain = 'gold', Strap = 'gold_deep', Rope = nil } },
    [10] = { Name = 'Ice Block', Rarity = 'Rare', Palette = {
        ['ice'] = spec('9FD4F0', Enum.Material.Glass, 0.22, false),
        ['frost_core'] = spec('E8F6FF', Enum.Material.SmoothPlastic, 0.45, false),
        ['snow'] = spec('F6FBFF', Enum.Material.SmoothPlastic, 0.00, false),
        ['icicle'] = spec('C8ECFF', Enum.Material.SmoothPlastic, 0.15, false),
        ['snowflake'] = spec('E0F8FF', Enum.Material.Neon, 0.00, true),
        ['steel_frosted'] = spec('B6C4D0', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'ice', Cap = 'steel_frosted', Chain = 'steel_frosted', Strap = 'steel_frosted', Rope = nil } },
    [11] = { Name = 'Crystal Geode', Rarity = 'Epic', Palette = {
        ['geode_rock'] = spec('3A2950', Enum.Material.Slate, 0.00, false),
        ['rock_dark'] = spec('20172E', Enum.Material.Slate, 0.00, false),
        ['amethyst'] = spec('B070FF', Enum.Material.Neon, 0.08, true),
        ['aquamarine'] = spec('60F0FF', Enum.Material.Neon, 0.08, true),
        ['geode_core'] = spec('FFFFFF', Enum.Material.Neon, 0.00, true),
        ['steel'] = spec('9A90B0', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'geode_rock', Cap = 'rock_dark', Chain = 'steel', Strap = 'rock_dark', Rope = nil } },
    [12] = { Name = 'Candy Smash', Rarity = 'Epic', Palette = {
        ['candy_pink'] = spec('F06AA8', Enum.Material.SmoothPlastic, 0.00, false),
        ['candy_cream'] = spec('FAF2EE', Enum.Material.SmoothPlastic, 0.00, false),
        ['frosting'] = spec('FFFFFF', Enum.Material.SmoothPlastic, 0.00, false),
        ['cane_red'] = spec('E02838', Enum.Material.SmoothPlastic, 0.00, false),
        ['gumball'] = spec('38D058', Enum.Material.SmoothPlastic, 0.00, false),
        ['steel_pink'] = spec('E0A8C4', Enum.Material.Metal, 0.00, false),
        ['sprinkle_0'] = spec('FF4060', Enum.Material.SmoothPlastic),
        ['sprinkle_1'] = spec('40C0FF', Enum.Material.SmoothPlastic),
        ['sprinkle_2'] = spec('FFE040', Enum.Material.SmoothPlastic),
        ['sprinkle_3'] = spec('60E070', Enum.Material.SmoothPlastic),
        ['sprinkle_4'] = spec('B070FF', Enum.Material.SmoothPlastic),
        ['sprinkle_5'] = spec('FFFFFF', Enum.Material.SmoothPlastic),
    }, Base = { Body = 'candy_pink', Cap = 'candy_cream', Chain = 'steel_pink', Strap = 'candy_cream', Rope = nil } },
    [13] = { Name = 'Lava Core', Rarity = 'Epic', Palette = {
        ['basalt'] = spec('1C1614', Enum.Material.Slate, 0.00, false),
        ['magma'] = spec('FF6A18', Enum.Material.Neon, 0.00, true),
        ['crust'] = spec('2C1C16', Enum.Material.Slate, 0.00, false),
        ['lava_drip'] = spec('FFA030', Enum.Material.Neon, 0.00, true),
    }, Base = { Body = 'basalt', Cap = 'crust', Chain = 'crust', Strap = 'crust', Rope = nil } },
    [14] = { Name = 'Thunder Cell', Rarity = 'Epic', Palette = {
        ['cell_shell'] = spec('111A28', Enum.Material.Metal, 0.45, false),
        ['plasma_core'] = spec('30C8FF', Enum.Material.Neon, 0.00, true),
        ['neon_cyan'] = spec('20D8FF', Enum.Material.Neon, 0.00, true),
        ['copper'] = spec('C87533', Enum.Material.Metal, 0.00, false),
        ['cell_cap'] = spec('1A2230', Enum.Material.Metal, 0.00, false),
        ['bolt_yellow'] = spec('FFE860', Enum.Material.Neon, 0.00, true),
    }, Base = { Body = 'cell_shell', Cap = 'cell_cap', Chain = 'cell_cap', Strap = 'cell_cap', Rope = nil } },
    [15] = { Name = 'Toxic Barrel', Rarity = 'Epic', Palette = {
        ['barrel_green'] = spec('2E6E2A', Enum.Material.SmoothPlastic, 0.00, false),
        ['barrel_ridge'] = spec('1D4A1C', Enum.Material.SmoothPlastic, 0.00, false),
        ['rad_yellow'] = spec('F2D020', Enum.Material.SmoothPlastic, 0.00, false),
        ['rad_black'] = spec('111111', Enum.Material.SmoothPlastic, 0.00, false),
        ['ooze'] = spec('9CFF3A', Enum.Material.Neon, 0.00, true),
    }, Base = { Body = 'barrel_green', Cap = 'barrel_ridge', Chain = 'barrel_ridge', Strap = 'rad_black', Rope = nil } },
    [16] = { Name = 'Robo Bag', Rarity = 'Legendary', Palette = {
        ['chrome'] = spec('D8DEE8', Enum.Material.Metal, 0.00, false),
        ['robo_dark'] = spec('22262E', Enum.Material.Metal, 0.00, false),
        ['screen'] = spec('05080C', Enum.Material.SmoothPlastic, 0.00, false),
        ['led_cyan'] = spec('80FFFF', Enum.Material.Neon, 0.00, true),
        ['led_red'] = spec('FF4040', Enum.Material.Neon, 0.00, true),
        ['led_yellow'] = spec('FFE040', Enum.Material.Neon, 0.00, true),
        ['led_green'] = spec('60FF80', Enum.Material.Neon, 0.00, true),
    }, Base = { Body = 'chrome', Cap = 'robo_dark', Chain = 'chrome', Strap = 'robo_dark', Rope = nil } },
    [17] = { Name = 'Dragon Hide', Rarity = 'Legendary', Palette = {
        ['dragon_scale'] = spec('A8161A', Enum.Material.SmoothPlastic, 0.00, false),
        ['dragon_hide'] = spec('5A0A0C', Enum.Material.SmoothPlastic, 0.00, false),
        ['dragon_belly'] = spec('D9A23A', Enum.Material.Metal, 0.00, false),
        ['horn_bone'] = spec('EADFC4', Enum.Material.SmoothPlastic, 0.00, false),
        ['dragon_eye'] = spec('FFE040', Enum.Material.Neon, 0.00, true),
        ['wing_membrane'] = spec('7A0E12', Enum.Material.SmoothPlastic, 0.00, false),
        ['iron_black'] = spec('2A2426', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'dragon_hide', Cap = 'iron_black', Chain = 'iron_black', Strap = 'dragon_hide', Rope = nil } },
    [18] = { Name = 'Galaxy Void', Rarity = 'Legendary', Palette = {
        ['void_body'] = spec('0C0822', Enum.Material.SmoothPlastic, 0.00, false),
        ['nebula_band'] = spec('7040FF', Enum.Material.Neon, 0.00, true),
        ['body_star'] = spec('FFFFFF', Enum.Material.Neon, 0.00, true),
        ['void_cap'] = spec('241A48', Enum.Material.Metal, 0.00, false),
        ['ring_gold'] = spec('FFD070', Enum.Material.Neon, 0.00, true),
        ['nebula_0'] = spec('B060FF', Enum.Material.Neon, 0.50, true),
        ['nebula_1'] = spec('40A0FF', Enum.Material.Neon, 0.50, true),
        ['nebula_2'] = spec('FF60C0', Enum.Material.Neon, 0.50, true),
    }, Base = { Body = 'void_body', Cap = 'void_cap', Chain = 'void_cap', Strap = 'void_cap', Rope = nil } },
    [19] = { Name = 'Sun Guardian', Rarity = 'Legendary', Palette = {
        ['marble'] = spec('F3EEE2', Enum.Material.SmoothPlastic, 0.00, false),
        ['sun_gold'] = spec('F2C24A', Enum.Material.Metal, 0.00, false),
        ['sun_core'] = spec('FFE070', Enum.Material.Neon, 0.00, true),
        ['feather'] = spec('FFF6E0', Enum.Material.SmoothPlastic, 0.00, false),
        ['feather_gold'] = spec('F6D27A', Enum.Material.Metal, 0.00, false),
    }, Base = { Body = 'marble', Cap = 'sun_gold', Chain = 'sun_gold', Strap = 'sun_gold', Rope = nil } },
    [20] = { Name = 'Rainbow God', Rarity = 'Mythic', Palette = {
        ['pearl'] = spec('FDFAFF', Enum.Material.SmoothPlastic, 0.00, false),
        ['crown_gold'] = spec('FFD060', Enum.Material.Metal, 0.00, false),
        ['rainbow_0'] = spec('F91F1F', Enum.Material.Neon, 0, true),
        ['gem_0'] = spec('FF3333', Enum.Material.Neon, 0, true),
        ['rainbow_1'] = spec('F97B1F', Enum.Material.Neon, 0, true),
        ['gem_1'] = spec('FF8933', Enum.Material.Neon, 0, true),
        ['rainbow_2'] = spec('F9D61F', Enum.Material.Neon, 0, true),
        ['gem_2'] = spec('FFDE33', Enum.Material.Neon, 0, true),
        ['rainbow_3'] = spec('24F91F', Enum.Material.Neon, 0, true),
        ['gem_3'] = spec('37FF33', Enum.Material.Neon, 0, true),
        ['rainbow_4'] = spec('1FB8F9', Enum.Material.Neon, 0, true),
        ['gem_4'] = spec('33C2FF', Enum.Material.Neon, 0, true),
        ['rainbow_5'] = spec('311FF9', Enum.Material.Neon, 0, true),
        ['gem_5'] = spec('4333FF', Enum.Material.Neon, 0, true),
        ['rainbow_6'] = spec('CE1FF9', Enum.Material.Neon, 0, true),
        ['gem_6'] = spec('D633FF', Enum.Material.Neon, 0, true),
    }, Base = { Body = 'rainbow_0', Cap = 'crown_gold', Chain = 'crown_gold', Strap = 'crown_gold', Rope = nil } },
}
function Colors.Get(tier, key)
    local def = assert(Colors.Tiers[tier], "Unknown sack tier: " .. tostring(tier))
    local k = def.Base[key] or key
    return def.Palette[k] or def.Palette[def.Base.Body]
end
function Colors.Apply(part, tier, key)
    local style = Colors.Get(tier, key)
    part.Color = style.Color
    part.Material = style.Material
    part.Transparency = style.Transparency
    part.Reflectance = (style.Material == Enum.Material.Metal) and 0.12 or 0
    part:SetAttribute("PaletteKey", key)
end
function Colors.ApplyModel(model, tier)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part:GetAttribute("PaletteKey") then
            Colors.Apply(part, tier, part:GetAttribute("PaletteKey"))
        end
    end
end

-- Exact material values and mesh-to-material assignments extracted from the GLB files.
-- For imported meshes, preserve imported appearance by default. Call this after import
-- if Studio changed the original colors or emissive/transparent appearance.
local SackGLBData = require(script.Parent:WaitForChild("SackGLBData"))
local function fromHex(hex)
    return Color3.fromRGB(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16))
end
function Colors.ApplyImported(model,tier,force)
    local data=SackGLBData[tier]
    assert(data, "No original GLB metadata for tier "..tostring(tier))
    local matched=0
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local matName=data.PartMaterials[part.Name]
            if not matName then
                local normalized=part.Name:gsub("%.%d+$","")
                matName=data.PartMaterials[normalized]
            end
            local m=matName and data.Materials[matName]
            if m then
                part:SetAttribute("SourceMaterial",matName)
                part:SetAttribute("SourceHex",m.Hex)
                if force then
                    -- Roblox cannot represent glTF roughness/metalness/emissive exactly.
                    -- These are source-grounded, closest-native Roblox assignments.
                    local neon = m.EmissivePower>.20
                    local isGlass=(m.Alpha<.85 and (matName:find("ice") or matName:find("shell") or matName:find("glass")))
                    if isGlass then part.Material=Enum.Material.Glass
                    elseif neon then part.Material=Enum.Material.Neon
                    elseif m.Metalness>.45 then part.Material=Enum.Material.Metal
                    elseif matName:find("rock") or matName:find("basalt") then part.Material=Enum.Material.Slate
                    else part.Material=Enum.Material.SmoothPlastic end
                    part.Color=fromHex(m.Hex)
                    part.Transparency=math.clamp(1-m.Alpha,0,1)
                    part.Reflectance=(m.Metalness>.45) and .06 or 0
                end
                matched += 1
            end
        end
    end
    return matched
end
function Colors.GetOriginalMaterial(tier,materialName)
    local d=SackGLBData[tier]
    return d and d.Materials[materialName]
end
function Colors.GetOriginalPartMaterial(tier,partName)
    local d=SackGLBData[tier]
    return d and d.PartMaterials[partName]
end
return Colors
