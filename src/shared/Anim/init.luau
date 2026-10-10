--!strict
-- CONTRACT (API). Partner A implements procedural animations on BlockBuilder rigs (Motor6D groups).
-- Names B will call: "EggRun" (legged-egg sprint while the player steers it; the egg's speed is
-- its HumanoidRootPart-free Hitbox velocity, so scale the leg cycle by Hitbox.AssemblyLinearVelocity),
-- "EggWobble" (on plot, hatching), "Idle", "Waddle", "Hop", "Sleep" (pets),
-- "PlayerKick" (Anim/Player: the Kick Sack front kick; SackController drives the same poses). No longer
-- called since the player steers the egg: "EggCarried", "PlayerCarry" (still implemented).
-- Implementations: Anim/Egg (EggRun, EggCarried, EggWobble), Anim/Pet (Idle, Waddle, Hop, Sleep),
-- Anim/Player (PlayerCarry, PlayerKick).
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
	local Pet = require(script.Pet)
	local loaded: { [string]: Player } = {
		Idle = Pet.Idle,
		Waddle = Pet.Waddle,
		Hop = Pet.Hop,
		Sleep = Pet.Sleep,
		EggRun = Egg.EggRun,
		EggCarried = Egg.EggCarried,
		EggWobble = Egg.EggWobble,
		PlayerCarry = PlayerAnims.PlayerCarry,
		PlayerKick = PlayerAnims.PlayerKick,
	}
	players = loaded
	return loaded
end

-- Orbiting cubes / halos on rare eggs and pets spin automatically on clients.
require(script.Spin).start()

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
