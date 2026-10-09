--!strict
-- CONTRACT (API). Partner A implements procedural animations on BlockBuilder rigs (Motor6D groups).
-- Names B will call: "EggRun" (legged-egg sprint while the player steers it; the egg's speed is
-- its HumanoidRootPart-free Hitbox velocity, so scale the leg cycle by Hitbox.AssemblyLinearVelocity),
-- "EggWobble" (on plot, hatching), "Idle", "Waddle", "Hop", "Sleep" (pets),
-- "Train" {tool} (one lift/swing when the player clicks a strength training tool; target = Character).
-- No longer called since the player steers the egg: "EggCarried", "PlayerCarry".
local Anim = {}

-- Starts a looping or one-shot animation; returns a stop function.
function Anim.play(model: Model, name: string, params: { [string]: any }?): () -> ()
	return function() end
end

return Anim
