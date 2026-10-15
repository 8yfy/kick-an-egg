--!strict
-- Thin, pcall-wrapped AnalyticsService helpers (Creator Hub → Analytics).
-- custom: gameplay events; money: economy source/sink; funnel: onboarding steps (logged once
-- per player, the highest step is saved in data.onboarding). Pet income is summed per player and
-- logged once a minute instead of every tick.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.Parent.Services.DataService)

local FIELD_1 = Enum.AnalyticsCustomFieldKeys.CustomField01.Name
local FIELD_2 = Enum.AnalyticsCustomFieldKeys.CustomField02.Name
local INCOME_FLUSH_SECONDS = 60
local CURRENCY = "Money"

local Analytics = {}

Analytics.Funnel = {
	FirstKick = 1,
	FirstSecure = 2,
	FirstPlace = 3,
	FirstHatch = 4,
	FirstUpgrade = 5,
}

local pendingIncome: { [Player]: number } = {}

local function safely(fn: () -> ())
	local ok, err = pcall(fn :: any)
	if not ok then
		warn(`[Analytics] {err}`)
	end
end

function Analytics.custom(player: Player, name: string, value: number?, field1: string?, field2: string?)
	local fields = {}
	if field1 then
		fields[FIELD_1] = field1
	end
	if field2 then
		fields[FIELD_2] = field2
	end
	safely(function()
		AnalyticsService:LogCustomEvent(player, name, value or 1, fields)
	end)
end

-- flow: "Source" (money in) or "Sink" (money out). txType: an AnalyticsEconomyTransactionType name.
function Analytics.money(player: Player, flow: "Source" | "Sink", amount: number, txType: string, sku: string)
	if amount <= 0 then
		return
	end
	local data = DataService:Get(player)
	local balance = if data then data.money else 0
	safely(function()
		AnalyticsService:LogEconomyEvent(
			player,
			if flow == "Source" then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink,
			CURRENCY,
			amount,
			balance,
			(Enum.AnalyticsEconomyTransactionType :: any)[txType].Name,
			sku
		)
	end)
end

function Analytics.addIncome(player: Player, amount: number)
	pendingIncome[player] = (pendingIncome[player] or 0) + amount
end

local function flushIncome(player: Player)
	local amount = pendingIncome[player]
	pendingIncome[player] = nil
	if amount and amount > 0 then
		Analytics.money(player, "Source", math.floor(amount), "Gameplay", "PetIncome")
	end
end

-- Logs onboarding step `step` the first time this player reaches it.
function Analytics.funnel(player: Player, step: number, stepName: string)
	local data = DataService:Get(player)
	if not data or (data.onboarding or 0) >= step then
		return
	end
	DataService:Set(player, { onboarding = step })
	safely(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

task.spawn(function()
	while true do
		task.wait(INCOME_FLUSH_SECONDS)
		for player in table.clone(pendingIncome) do
			flushIncome(player)
		end
	end
end)
Players.PlayerRemoving:Connect(flushIncome)

return Analytics
