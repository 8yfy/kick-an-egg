--!strict
-- Kick Sack sounds (client). Five moments per sack:
--   equip    the bag drops onto its chain      impact   an ordinary punch (tier 1: a dry fabric / leather thud)
--   special  a super hit (heavier + the look's flourish)   upgrade  a new sack is bought (tier 3 flourish)
--   idle     a soft ambient loop (premium sacks only: Lava Core, Galaxy Void, Sun Guardian, Rainbow God)
-- The recipes are data in Audio/SoundBank (SoundBank.sack): each sack's physical BODY by what it is made of
-- (canvas, leather, rubber, metal, ice, crystal, candy, rock), plus a quiet magic ACCENT only where its look calls
-- for it (sparkle, coins, cosmic, rainbow ...; SpecialEffects group). No thunder on punches: only Thunder Cell (an
-- electric sack) gets a short crack, on its super hit. Audio plays them (spatial, cooldowns, voices, cleanup).
-- Custom audio: SoundBank.CUSTOM["Sack<tier>.<moment>"] = { id = "rbxassetid://...", volume = 0.5 }.
local Sacks = require(script.Parent.Parent.Builders.Models.Sacks)
local Audio = require(script.Parent.Parent.Audio)
local SoundBank = require(script.Parent.Parent.Audio.SoundBank)

local SackSfx = {}

export type Layer = SoundBank.Layer
export type Moment = "equip" | "impact" | "special" | "upgrade" | "idle"

-- The layers (and tier) for `tier`'s `moment` (the tests and tools/audio read it).
function SackSfx.layers(tier: number, moment: Moment): ({ Layer }, number)
	return SoundBank.sack(tier, moment, Sacks.look(tier).theme)
end

-- Plays `tier`'s `moment` at `at` (position or part). opts.own = your own sack (others' play quieter).
function SackSfx.play(tier: number, moment: Moment, at: Vector3 | Instance, opts: { own: boolean?, volume: number? }?)
	local layers, level = SackSfx.layers(tier, moment)
	Audio.playStack(`Sack{tier}.{moment}`, layers, level, at, {
		own = if opts and opts.own then nil else false,
		volume = opts and opts.volume,
		key = if typeof(at) == "Instance" then at:GetFullName() else nil,
	})
end

-- Starts `tier`'s ambient loop on `part` (premium sacks only). Returns a stop function (no-op if none) and a
-- setter that pauses it (e.g. while the sack's effect is hidden far away).
function SackSfx.idle(tier: number, part: BasePart): (() -> (), (on: boolean) -> ())
	local layers = SackSfx.layers(tier, "idle")
	if #layers == 0 then
		return function() end, function(_on: boolean) end
	end
	local handle = Audio.loopStack(`Sack{tier}.idle`, layers, part)
	return handle.stop, function(on: boolean)
		handle.setPaused(not on)
	end
end

return SackSfx
