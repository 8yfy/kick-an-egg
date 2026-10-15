-- DEV ONLY. Prints the game's sound recipes (Audio/SoundBank, the Kick Sack stacks, egg landings, the 10 required
-- scenarios) as JSON for tools/audio/render.py, which mixes them from Roblox's own sound files into WAVs you can
-- listen to. Run: sh tools/audio/render.sh
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage").Shared
local B = require(Shared.Audio.SoundBank) :: any
local SackSfx = require(Shared.VFX.SackSfx) :: any
local Upgrades = require(Shared.Config.Upgrades) :: any

local stacks = {}
local function add(name: string, group: string, layers, tier: number)
	table.insert(stacks, { name = name, group = group, tier = tier, layers = layers })
end

for name, def in B.Events do
	for i, variant in def.variants do
		add(if #def.variants > 1 then `{name}_{i}` else name, "events", variant, def.tier)
	end
end
for tier, sack in Upgrades.Sack.tiers do
	for _, moment in { "equip", "impact", "special", "upgrade", "idle" } do
		local layers, level = SackSfx.layers(tier, moment)
		if #layers > 0 then
			add(string.format("sack%02d_%s_%s", tier, (string.gsub(sack.name, "%s", "")), moment), "sacks", layers, level)
		end
	end
end
for surface in B.Surfaces do
	for _, case in { { "soft", 0.15, false }, { "hard", 1, false }, { "bounce", 0.5, true } } do
		local layers, tier = B.landing(surface, case[2], case[3], nil)
		add(`land_{surface}_{case[1]}`, "landings", layers, tier)
	end
end
for mutation in B.MutationAccent do
	local layers, tier = B.landing("grass", 0.5, false, mutation)
	add(`land_grass_{mutation}`, "landings", layers, tier)
end
-- the 10 required scenarios, in order
local function sack(tier: number, moment: string)
	return (SackSfx.layers(tier, moment))
end
local scenarios = {
	{ "01_gentle_drop_grass", (B.landing("grass", 0.2, false, nil)) },
	{ "02_drop_stone", (B.landing("stone", 0.6, false, nil)) },
	{ "03_bounces", (B.landing("grass", 0.6, true, nil)) },
	{ "04_running_steps", B.Events.EggStep.variants[1] },
	{ "05_normal_kick", B.Events.KickGood.variants[1] },
	{ "06_perfect_kick", B.Events.KickPerfect.variants[1] },
	{ "07_basic_sack_punch", sack(1, "impact") },
	{ "08_premium_sack_punch", sack(20, "impact") },
	{ "09_common_hatch", B.Events.HatchCommon.variants[1] },
	{ "10_secret_hatch", B.Events.HatchSecret.variants[1] },
}
for _, s in scenarios do
	add(s[1], "scenarios", s[2], B.tierFor(s[2], 1))
end

local out = HttpService:JSONEncode({ sources = B.Sources, stacks = stacks })
-- printed in chunks (the Output line limit), reassembled by render.py
local CHUNK = 3000
for i = 1, #out, CHUNK do
	print("AUDIOJSON " .. string.sub(out, i, i + CHUNK - 1))
end
print("AUDIOJSON_END")
