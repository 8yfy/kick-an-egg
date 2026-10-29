--!strict
-- How an egg's size mutation LOOKS: placed growth, footprint and carry tier. Presentation and placement room
-- only. The gameplay value never changes here: Config/Mutations.Size still sets the pet's income multiplier and
-- its real model scale (PlotService.spawnPetModel), and the egg keeps the size key KickService rolled.
--
-- Visual policy (docs/EggExperience.md): the true multipliers (Tiny 0.6, Big 1.5, Huge 2.2, Colossal 3.2) would
-- make a Colossal egg about 22 studs wide, wider than a starter pen. Eggs therefore use a compressed curve with
-- the same order:
--   visual = 1 + (scale - 1) * 0.5 above 1x, 1 - (1 - scale) * 0.6 below
--   Tiny 0.76, normal 1, Big 1.25, Huge 1.6, Colossal 2.1 (capped at MAX_VISUAL).
-- A placed egg grows from START of that size to all of it while it incubates. Progress comes from the saved
-- placedAt / hatchAt, so a player who rejoins halfway sees the halfway size.
local Mutations = require(script.Parent.Parent.Config.Mutations)

local EggSize = {}

EggSize.START = 0.55 -- a freshly placed egg is this fraction of its final size
EggSize.MAX_VISUAL = 2.2
EggSize.BASE_RADIUS = 2 -- footprint radius of a 1x egg (studs): 1x eggs keep the old 4-stud spacing
EggSize.HOLD_SCALE = 0.55 -- the egg model's scale in the hands at 1x (it was the same for every egg before)

-- Carry tiers by visual size, smallest first (Anim/Carry has one pose per tier).
EggSize.TIERS = {
	{ name = "Small", below = 0.9 }, -- Tiny: one hand, close to the body
	{ name = "Medium", below = 1.15 }, -- no size mutation: both hands in front of the chest
	{ name = "Large", below = 1.45 }, -- Big: hugged higher, leaning back a little
	{ name = "Giant", below = math.huge }, -- Huge / Colossal: both arms holding it overhead
}

-- The real size multiplier of a size key (1 for none or an unknown key).
function EggSize.multiplier(sizeKey: string?): number
	local size = if sizeKey then Mutations.Size[sizeKey] else nil
	return if size then size.scale else 1
end

-- Final visual scale of a placed egg with this size key.
function EggSize.visual(sizeKey: string?): number
	local s = EggSize.multiplier(sizeKey)
	local v = if s >= 1 then 1 + (s - 1) * 0.5 else 1 - (1 - s) * 0.6
	return math.clamp(v, 0.5, EggSize.MAX_VISUAL)
end

-- Growth curve 0..1 -> START..1: a gentle S-curve (slow start, steady middle, settling at the end) mixed with a
-- linear part so the egg always visibly grows.
function EggSize.growth(progress: number): number
	local p = math.clamp(progress, 0, 1)
	local smoother = p * p * p * (p * (p * 6 - 15) + 10)
	local eased = 0.3 * p + 0.7 * smoother
	return EggSize.START + (1 - EggSize.START) * eased
end

-- Visual scale of a placed egg at incubation `progress` (0 = just placed, 1 = ready).
function EggSize.placed(sizeKey: string?, progress: number): number
	return EggSize.visual(sizeKey) * EggSize.growth(progress)
end

-- Incubation progress from the saved timestamps (server time).
function EggSize.progress(placedAt: number, hatchAt: number, now: number): number
	if hatchAt <= placedAt then
		return 1
	end
	return math.clamp((now - placedAt) / (hatchAt - placedAt), 0, 1)
end

-- Footprint radius of a fully grown egg (studs): placement keeps eggs this far from each other and the fence.
function EggSize.radius(sizeKey: string?): number
	return EggSize.BASE_RADIUS * math.max(1, EggSize.visual(sizeKey))
end

-- Scale of the egg model while it's carried.
function EggSize.held(sizeKey: string?): number
	return EggSize.HOLD_SCALE * EggSize.visual(sizeKey)
end

-- Carry tier name for this size key.
function EggSize.tier(sizeKey: string?): string
	local v = EggSize.visual(sizeKey)
	for _, t in EggSize.TIERS do
		if v < t.below then
			return t.name
		end
	end
	return "Giant"
end

return EggSize
