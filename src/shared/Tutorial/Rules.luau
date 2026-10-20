--!strict
-- Tutorial decisions only: no rewards, prices, physics or player movement. Current accomplishments win
-- over introductory lessons, so finding an egg/pet early never sends a player back through old steps.
local Rules = {}
Rules.TRAIN_HITS = 3
Rules.Steps = {
	KICK_LINE = 1,
	PRESS_KICK = 2,
	TIME_KICK = 3,
	WATCH_EGG = 4,
	COLLECT = 5,
	PLACE_EGG = 6,
	HATCH = 7,
	INCOME = 8,
	UPGRADE = 9,
	DONE = 10,
	TRAIN = 11,
	GET_SACK = 12,
	PLACE_PET = 13,
	WAIT_PEN = 14,
}
local S = Rules.Steps

-- A replicated/server counter can be seen repeatedly. Respawn callers reset only `last`, keeping `saved`.
function Rules.trainingProgress(saved: number, last: number, current: number): (number, number)
	local high = math.max(last, math.max(0, math.floor(current)))
	return math.min(Rules.TRAIN_HITS, saved + high - last), high
end
Rules.Definitions = {
	[S.GET_SACK] = { id = "starter_sack", objective = "Find your free training sack.", stage = 1 },
	[S.TRAIN] = { id = "train", objective = "Train your kicking power.", stage = 1 },
	[S.KICK_LINE] = { id = "kick_line", objective = "Head to the kicking line.", stage = 2 },
	[S.PRESS_KICK] = { id = "kick", objective = "Press KICK to start.", stage = 2 },
	[S.TIME_KICK] = { id = "timing", objective = "Tap when the meter is high.", stage = 2 },
	[S.WATCH_EGG] = { id = "chase", objective = "Steer your egg back home!", stage = 2 },
	[S.COLLECT] = { id = "retry", objective = "Try another kick!", stage = 2 },
	[S.PLACE_EGG] = { id = "place_egg", objective = "Bring your egg to your pen.", stage = 3 },
	[S.HATCH] = { id = "hatch", objective = "Your egg is hatching!", stage = 3 },
	[S.PLACE_PET] = { id = "place_pet", objective = "Put your pet in your pen.", stage = 3 },
	[S.INCOME] = { id = "income", objective = "Your pet earns money for you!", stage = 4 },
	[S.WAIT_PEN] = { id = "waiting_pen", objective = "Keep your egg; a pen will open soon.", stage = 3 },
	[S.UPGRADE] = { id = "optional_upgrade", objective = "More room? Upgrade your pen.", stage = 4 },
	[S.DONE] = { id = "complete", objective = "You're ready!", stage = 4 },
}

export type Context = {
	active: boolean?,
	onPad: boolean?,
	hasPen: boolean?,
	hasSack: boolean?,
	trained: boolean?,
	incomeExplained: boolean?,
	replay: boolean?,
}

local function count(t: any): number
	local n = 0
	if typeof(t) == "table" then
		for _ in t do
			n += 1
		end
	end
	return n
end

function Rules.choose(data: { [string]: any }, context: Context): number
	local tutorial = data.tutorial or {}
	if not context.replay and (tutorial.done or tutorial.skipped) then
		return 0
	end
	if context.active then
		return S.WATCH_EGG
	end
	local stored = false
	for _, pet in data.pets or {} do
		if typeof(pet) == "table" then
			if pet.placed then
				if context.hasPen == false then
					return S.WAIT_PEN
				end
				return if context.incomeExplained then S.DONE else S.INCOME
			end
			stored = true
		end
	end
	if stored then
		return if context.hasPen == false then S.WAIT_PEN else S.PLACE_PET
	end
	if count(data.plots) > 0 then
		return S.HATCH
	end
	if count(data.eggs) > 0 then
		return if context.hasPen == false then S.WAIT_PEN else S.PLACE_EGG
	end
	local stats = data.stats or {}
	if (stats.kicks or 0) > 0 then
		return S.COLLECT
	end
	local trained = context.trained or tutorial.trained or (tutorial.trainingHits or 0) >= Rules.TRAIN_HITS
	if not trained then
		return if context.hasSack == false then S.GET_SACK else S.TRAIN
	end
	return if context.onPad then S.PRESS_KICK else S.KICK_LINE
end

return Rules
