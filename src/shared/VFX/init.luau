--!strict
-- CONTRACT (API). Partner A replaces the stub bodies. Partner B only calls VFX.play.
-- Names B will call (params in brackets):
--   Kick + flight: "KickImpact" {power}, "ZoneEnter" {zone}, "EggSpin" {zone, keys, finalKey?, seconds},
--                  "Landing" {rarity, zone}, "LegsSprout" {}
--   Chase:         "AvalancheWarn" {theme, startZ, seconds}, "AvalancheStart" {theme, startZ, speed, startTime},
--                  "AvalancheStop" {}, "EggPickup" {}, "EggSecured" {rarity}, "EggCaught" {theme},
--                  "PlayerLaunch" {from, to} (target = owner's Character; the server has already moved it to `to`)
--   Base:          "HatchCrack" {progress}, "HatchBurst" {rarity}, "PetReveal" {rarity, name}, "MoneyPop" {amount},
--                  "Announce" {text, rarity}
--   plus every weather mutation's `vfx` name from Config/Mutations via VFX.attach (looping on a pet).
-- "AvalancheStart" returns nothing; the effect drives itself from Config/Chase.frontZ() every frame
-- and is removed by "AvalancheStop" (target = the same folder/model passed to AvalancheStart).
local VFX = {}

function VFX.play(name: string, target: Instance?, params: { [string]: any }?): ()
	-- stub: no-op until Partner A implements effects
end

function VFX.attach(name: string, model: Model): () -> ()
	-- stub: returns a cleanup function
	return function() end
end

return VFX
