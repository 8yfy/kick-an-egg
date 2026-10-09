--!strict
-- CONTRACT (API). Partner A implements procedural animations on BlockBuilder rigs (Motor6D groups).
-- Names B will call: "EggRun" (panicked legged-egg sprint), "EggCarried" (legs kicking while held),
-- "EggWobble" (on plot, hatching), "Idle", "Waddle", "Hop", "Sleep" (pets),
-- "PlayerCarry" (player arms up holding the egg; target = player Character).
local Anim = {}

-- Starts a looping or one-shot animation; returns a stop function.
function Anim.play(model: Model, name: string, params: { [string]: any }?): () -> ()
	return function() end
end

return Anim
