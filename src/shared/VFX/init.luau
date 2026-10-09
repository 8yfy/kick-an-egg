--!strict
-- CONTRACT (API). Partner B replaces the stub bodies. Partner A only calls VFX.play.
-- Names A will call: "KickImpact", "ZoneEnter", "EggSpin", "Landing", "LegsSprout",
-- "HatchCrack", "HatchBurst", "PetReveal", "MoneyPop", "Announce", plus every weather
-- mutation's `vfx` name from Config/Mutations (attached to a pet model).
local VFX = {}

function VFX.play(name: string, target: Instance?, params: { [string]: any }?): ()
	-- stub: no-op until Partner B implements effects
end

function VFX.attach(name: string, model: Model): () -> ()
	-- stub: returns a cleanup function
	return function() end
end

return VFX
