-- Run with Lune: pure decision regression tests, no Roblox APIs or DataStore writes.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local Rules = luau.load(fs.readFile("src/shared/Tutorial/Rules.luau"))()
local S = Rules.Steps
local n = 0
local function check(name, condition)
	assert(condition, name)
	n += 1
end
local function fresh(changes)
	local data = { tutorial = {}, stats = { kicks = 0, secured = 0, lost = 0 }, pets = {}, eggs = {}, plots = {} }
	for k, v in changes or {} do
		data[k] = v
	end
	return data
end
check("fresh player learns real training first", Rules.choose(fresh(), {}) == S.TRAIN)
check("no gear points at the actual starter source", Rules.choose(fresh(), { hasSack = false }) == S.GET_SACK)
check("two training hits are not three", Rules.choose(fresh({ tutorial = { trainingHits = 2 } }), {}) == S.TRAIN)
check(
	"training completion goes straight to the kick line",
	Rules.choose(fresh({ tutorial = { trainingHits = 3 } }), {}) == S.KICK_LINE
)
check(
	"already trained on the kick pad presses KICK",
	Rules.choose(fresh({ tutorial = { trained = true } }), { onPad = true }) == S.PRESS_KICK
)
check("early arrival at kick line doesn't fabricate training", Rules.choose(fresh(), { onPad = true }) == S.TRAIN)
local egg = fresh({ eggs = { { uid = "early", petId = "sprout_pup" } } })
check("egg acquired before training skips the old introduction", Rules.choose(egg, {}) == S.PLACE_EGG)
check("egg acquired with zero kick stats never sends player back", Rules.choose(egg, { onPad = true }) == S.PLACE_EGG)
check(
	"knowing the pen does not reset anything",
	Rules.choose(fresh({ eggs = egg.eggs, tutorial = { foundPen = true } }), {}) == S.PLACE_EGG
)
check("waiting for pen assignment keeps the egg", Rules.choose(egg, { hasPen = false }) == S.WAIT_PEN)
check("assignment resumes placement immediately", Rules.choose(egg, { hasPen = true }) == S.PLACE_EGG)
local hatching = fresh({ plots = { e = { uid = "e", hatchAt = 999 } } })
check("out-of-order placement goes directly to hatching", Rules.choose(hatching, {}) == S.HATCH)
local stored = fresh({ pets = { p = { petId = "sprout_pup" } } })
check("stored pet goes to placement rather than demanding a new egg", Rules.choose(stored, {}) == S.PLACE_PET)
local pet = fresh({ pets = { p = { petId = "sprout_pup", placed = true } }, money = 0 })
check("existing placed pet goes directly to income explanation", Rules.choose(pet, {}) == S.INCOME)
check("returning placed pets wait for a real assigned pen", Rules.choose(pet, { hasPen = false }) == S.WAIT_PEN)
check("zero money never creates an upgrade paywall", Rules.choose(pet, { incomeExplained = true }) == S.DONE)
check("completed core loop needs no upgrade", Rules.choose(pet, { incomeExplained = true, onPad = false }) == S.DONE)
local loss = fresh({ stats = { kicks = 1, secured = 0, lost = 1 } })
check("failed collection provides a retry", Rules.choose(loss, {}) == S.COLLECT)
check(
	"repeated failures still provide a retry",
	Rules.choose(fresh({ stats = { kicks = 8, lost = 8 } }), {}) == S.COLLECT
)
check("active chase always keeps attention on real gameplay", Rules.choose(egg, { active = true }) == S.WATCH_EGG)
check("active chase overrides older placed pets", Rules.choose(pet, { active = true }) == S.WATCH_EGG)
check("late chase-end events cannot undo owned inventory", Rules.choose(egg, { active = false }) == S.PLACE_EGG)
check(
	"old secured stats without inventory still allow a new attempt",
	Rules.choose(fresh({ stats = { kicks = 4, secured = 1 } }), {}) == S.COLLECT
)
check("completed profile stays quiet", Rules.choose(fresh({ tutorial = { done = true } }), {}) == 0)
check("skipped profile stays quiet", Rules.choose(fresh({ tutorial = { skipped = true } }), {}) == 0)
check(
	"replay observes real inventory without resetting completion",
	Rules.choose(fresh({ tutorial = { done = true }, eggs = egg.eggs }), { replay = true }) == S.PLACE_EGG
)
check(
	"replay of an existing pet is contextual",
	Rules.choose(fresh({ tutorial = { done = true }, pets = pet.pets }), { replay = true }) == S.INCOME
)
local before = pet.money
Rules.choose(pet, { incomeExplained = true })
check(
	"decision code never awards money or alters inventory",
	pet.money == before and pet.pets.p.placed == true and pet.tutorial.done == nil
)
local ids = {}
local progress, high = Rules.trainingProgress(0, 0, 2)
check("training counts only observed successful hits", progress == 2 and high == 2)
progress, high = Rules.trainingProgress(progress, high, 2)
check("repeated hit snapshots are idempotent", progress == 2 and high == 2)
progress, high = Rules.trainingProgress(progress, high, 1)
check("late lower counters never add fake hits", progress == 2 and high == 2)
progress, high = Rules.trainingProgress(progress, 0, 1)
check("respawn keeps prior training and counts the next real hit", progress == 3 and high == 1)
for _, definition in Rules.Definitions do
	check("unique definition " .. definition.id, not ids[definition.id])
	ids[definition.id] = true
	local _, words = definition.objective:gsub("%S+", "")
	check("short main objective " .. definition.id, words <= 10)
end
print(`Reactive tutorial: {n} checks passed`)
