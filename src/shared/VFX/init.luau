--!strict
-- CONTRACT (API). Partner A replaces the stub bodies. Partner B only calls VFX.play.
-- Names B will call: "KickImpact", "ZoneEnter", "EggSpin", "Landing", "LegsSprout",
-- "HatchCrack", "HatchBurst", "PetReveal", "MoneyPop", "Announce", plus every weather
-- mutation's `vfx` name from Config/Mutations (attached to a pet model).
local VFX = {}

function VFX.play(name: string, target: Instance?, params: { [string]: any }?): ()
	-- stub: no-op until Partner A implements effects
end

function VFX.attach(name: string, model: Model): () -> ()
	-- stub: returns a cleanup function
	return function() end
end

return VFX
