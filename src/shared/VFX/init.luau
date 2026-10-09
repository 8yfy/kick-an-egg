--!strict
-- CONTRACT (API). Partner A replaces the stub bodies. Partner B only calls VFX.play.
-- Names B will call (params in brackets):
--   Kick + flight: "KickImpact" {power}, "ZoneEnter" {zone}, "EggSpin" {zone, keys, finalKey?, seconds},
--                  "Landing" {rarity, zone}, "LegsSprout" {}
--   Chase:         "AvalancheWarn" {theme, startZ, seconds}, "AvalancheStart" {theme, startZ, speed, startTime},
--                  "AvalancheStop" {}, "EggPickup" {}, "EggSecured" {rarity}, "EggCaught" {theme}
--   Base:          "HatchCrack" {progress}, "HatchBurst" {rarity}, "PetReveal" {rarity, name}, "MoneyPop" {amount},
--                  "Announce" {text, rarity}
--   plus every weather mutation's `vfx` name from Config/Mutations via VFX.attach (looping on a pet).
-- "AvalancheStart" returns nothing; the effect drives itself from Config/Chase.frontZ() every frame
-- and is removed by "AvalancheStop" (target = the same folder/model passed to AvalancheStart).
-- Optional on every chase effect: `ownerUserId` (pass the ChaseStart payload's value). Without it the
-- effect assumes it belongs to the local player; with it, other players get the low-detail version
-- (half the boulders, no camera shake, no banners).
-- Implementations live in submodules (Egg, Hatch, Avalanche, ChaseFx, ...); unknown names are a no-op.
local RunService = game:GetService("RunService")

type Handler = (target: Instance?, params: { [string]: any }) -> ()

local VFX = {}

local handlers: { [string]: Handler }? = nil

local function load(): { [string]: Handler }
	local h = handlers
	if h then
		return h
	end
	local Avalanche = require(script.Avalanche)
	local ChaseFx = require(script.ChaseFx)
	local Egg = require(script.Egg)
	local Hatch = require(script.Hatch)
	local loaded: { [string]: Handler } = {
		HatchCrack = Hatch.HatchCrack,
		HatchBurst = Hatch.HatchBurst,
		PetReveal = Hatch.PetReveal,
		MoneyPop = Hatch.MoneyPop,
		Announce = Hatch.Announce,
		KickImpact = Egg.KickImpact,
		ZoneEnter = Egg.ZoneEnter,
		EggSpin = Egg.EggSpin,
		Landing = Egg.Landing,
		LegsSprout = Egg.LegsSprout,
		AvalancheWarn = Avalanche.Warn,
		AvalancheStart = Avalanche.Start,
		AvalancheStop = Avalanche.Stop,
		EggCaught = ChaseFx.EggCaught,
		EggSecured = ChaseFx.EggSecured,
		EggPickup = ChaseFx.EggPickup,
	}
	handlers = loaded
	return loaded
end

function VFX.play(name: string, target: Instance?, params: { [string]: any }?): ()
	if not RunService:IsClient() then
		return -- effects are client-only
	end
	local fn = load()[name]
	if fn then
		local ok, err = pcall(fn, target, params or {})
		if not ok then
			warn(`[VFX] {name} failed: {err}`)
		end
	end
end

-- Looping overlay on a pet (weather mutations from Config/Mutations `vfx`, plus "IncomeLabel").
-- Returns a cleanup function; it also runs automatically if the model is destroyed.
function VFX.attach(name: string, model: Model): () -> ()
	if not RunService:IsClient() then
		return function() end
	end
	local Weather = require(script.Weather) :: any
	local fn = Weather[name]
	if typeof(fn) ~= "function" then
		return function() end
	end
	local ok, cleanup = pcall(fn, model)
	if not ok then
		warn(`[VFX] attach {name} failed: {cleanup}`)
		return function() end
	end
	local done = false
	local conn: RBXScriptConnection
	local function stop()
		if not done then
			done = true
			conn:Disconnect()
			cleanup()
		end
	end
	conn = model.Destroying:Connect(stop)
	return stop
end

return VFX
