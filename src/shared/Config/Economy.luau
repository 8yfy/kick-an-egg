--!strict
-- Partner B owns this file. Tune freely.
local Economy = {
	StartingMoney = 0,
	-- Kick power = Strength: trained at your base's training rack (Config/Upgrades.Rack), not bought.
	-- costBase/costGrowth are unused while the Store's Kick Power card is disabled.
	KickPower = { base = 1, max = 100, costBase = 25, costGrowth = 1.18 },
	-- Run Speed = egg speed while steering; bought in the shop (BuyUpgrade "RunSpeed").
	RunSpeed = { base = 16, max = 40, costBase = 50, costGrowth = 1.25 },
	DistancePerPower = 24, -- studs per kick power point (before timing/multipliers)
	TimingBonus = { perfect = 1.5, good = 1.15, miss = 0.85 },
	Rebirth = { requiresMaxPower = true, multiplierPerRebirth = 0.5, powerCapBonus = 25 },
	PlotSlots = { base = 8, max = 20 },
	FriendLuckPerFriend = 0.1,
	AutosaveSeconds = 90,
	SellIncomeSeconds = 60, -- a pet sells for this many seconds of its income (size + weather, no rebirth)

	-- Pets store their income on their pedestal until the owner steps onto it to collect.
	CollectRadius = 3.5, -- studs (XZ) from the pedestal top that count as standing on it

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

return Economy
