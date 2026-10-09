--!strict
-- CONTRACT (API). Partner A implements procedural animations on BlockBuilder rigs (Motor6D groups).
-- Names B will call: "EggRun" (panicked legged-egg sprint), "EggCarried" (legs kicking while held),
-- "EggWobble" (on plot, hatching), "Idle", "Waddle", "Hop", "Sleep" (pets),
-- "PlayerCarry" (player arms up holding the egg; target = player Character).
-- Implementations: Anim/Egg (EggRun, EggCarried, EggWobble), Anim/Player (PlayerCarry).
-- Unknown names return a no-op stop function. The stop function restores the rest pose.
type Player = (model: Model, params: { [string]: any }) -> () -> ()

local Anim = {}

local players: { [string]: Player }? = nil

local function load(): { [string]: Player }
	local p = players
	if p then
		return p
	end
	local Egg = require(script.Egg)
	local PlayerAnims = require(script.Player)
	local loaded: { [string]: Player } = {
		EggRun = Egg.EggRun,
		EggCarried = Egg.EggCarried,
		EggWobble = Egg.EggWobble,
		PlayerCarry = PlayerAnims.PlayerCarry,
	}
	players = loaded
	return loaded
end

-- Starts a looping or one-shot animation; returns a stop function.
function Anim.play(model: Model, name: string, params: { [string]: any }?): () -> ()
	local fn = load()[name]
	if not fn then
		return function() end
	end
	local ok, stop = pcall(fn, model, params or {})
	if not ok then
		warn(`[Anim] {name} failed: {stop}`)
		return function() end
	end
	return stop
end

return Anim
