--!strict
-- Partner B owns this file. Tune freely.
local Economy = {
	StartingMoney = 0,
	KickPower = { base = 1, max = 100, costBase = 25, costGrowth = 1.18 },
	RunSpeed = { base = 16, max = 40, costBase = 50, costGrowth = 1.25 },
	DistancePerPower = 24, -- studs per kick power point (before timing/multipliers)
	TimingBonus = { perfect = 1.5, good = 1.15, miss = 0.85 },
	Rebirth = { requiresMaxPower = true, multiplierPerRebirth = 0.5, powerCapBonus = 25 },
	PlotSlots = { base = 8, max = 20 },
	FriendLuckPerFriend = 0.1,
	AutosaveSeconds = 90,
	SellIncomeSeconds = 60, -- a pet sells for this many seconds of its income (size + weather, no rebirth)

	-- Training pad: every `tickSeconds` on your pad adds `gain` to speedMultiplier (egg speed =
	-- runSpeed x speedMultiplier). Pads are upgraded with money; `cost` = price to reach that level.
	Training = {
		tickSeconds = 1,
		maxMultiplier = 10,
		pads = {
			{ gain = 0.002, cost = 0 },
			{ gain = 0.005, cost = 2500 },
			{ gain = 0.012, cost = 25000 },
			{ gain = 0.03, cost = 250000 },
			{ gain = 0.075, cost = 2500000 },
		} :: { { gain: number, cost: number } },
	},

	-- Placeholder IDs (0 = not created yet; skipped). Replace with real IDs before publishing.
	Gamepasses = {
		DoubleMoney = { id = 0, incomeMultiplier = 2 },
	} :: { [string]: { id: number, incomeMultiplier: number } },
	DevProducts = {
		MoneySmall = { id = 0, money = 1000 },
		MoneyMedium = { id = 0, money = 15000 },
		MoneyLarge = { id = 0, money = 250000 },
	} :: { [string]: { id: number, money: number } },
}

export type UpgradeKind = "KickPower" | "RunSpeed"

-- Highest Kick Power this player can buy; each rebirth raises the cap.
function Economy.maxKickPower(rebirths: number): number
	return Economy.KickPower.max + rebirths * Economy.Rebirth.powerCapBonus
end

-- Price of the next +1 of `kind` when the player currently has `value` (level = value - base).
-- Shared by the server (BuyUpgrade) and A's shop UI so both show the same number.
function Economy.upgradeCost(kind: UpgradeKind, value: number): number
	local config = Economy[kind]
	return math.floor(config.costBase * config.costGrowth ^ (value - config.base))
end

-- Price of the next training pad level, or nil at the top level.
function Economy.trainingPadCost(level: number): number?
	local nextPad = Economy.Training.pads[level + 1]
	return if nextPad then nextPad.cost else nil
end

return Economy
