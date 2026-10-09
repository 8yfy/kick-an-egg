--!strict
-- CONTRACT (API). Partner A implements procedural animations on BlockBuilder rigs (Motor6D groups).
-- Names B will call: "Idle", "Waddle", "Hop", "Sleep", "EggWobble", "EggSpinCycle".
local Anim = {}

-- Starts a looping or one-shot animation; returns a stop function.
function Anim.play(model: Model, name: string, params: { [string]: any }?): () -> ()
	return function() end
end

return Anim
