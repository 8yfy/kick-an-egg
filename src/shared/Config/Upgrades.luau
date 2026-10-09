--!strict
-- CONTRACT FILE: change only via a `contract:` PR (numbers are Partner B's to tune).
-- Per-player base upgrades: the training rack next to each pen, and the pen itself.
--
-- Rack: standing on your rack's kick plate trains `stat` by `levels[level].gain` per kick, at most one
--   kick every `interval` seconds within `range` studs of the plate (server checks both; fired by the
--   client as Remotes.Train). Buying the next level (Remotes.UpgradeTraining) costs `levels[level + 1].cost`.
--   `tier` picks the rack's look (Partner A's model): Wood, Stone, Iron, Gold, Crystal, Inferno.
-- Pen: each level adds `slotsPerLevel` hatch slots (Economy.PlotSlots.base at level 1, capped at
--   Economy.PlotSlots.max). Level n -> n + 1 costs costBase * costGrowth^(n - 1) (Remotes.UpgradePen).
--
-- The server mirrors the state on workspace.Map.SafeZone.Bases.Base<i> as attributes so every client can
-- draw the signs: OwnerUserId (number, 0 = free), RackLevel (number), PenLevel (number).

export type RackLevel = { gain: number, cost: number, tier: string }

local Upgrades = {
	Rack = {
		stat = "kickPower",
		interval = 0.6,
		range = 7,
		levels = {
			{ gain = 0.1, cost = 0, tier = "Wood" },
			{ gain = 0.2, cost = 250, tier = "Wood" },
			{ gain = 0.3, cost = 1500, tier = "Stone" },
			{ gain = 0.5, cost = 8000, tier = "Stone" },
			{ gain = 0.75, cost = 40000, tier = "Iron" },
			{ gain = 1, cost = 200000, tier = "Iron" },
			{ gain = 1.5, cost = 1000000, tier = "Gold" },
			{ gain = 2, cost = 5000000, tier = "Gold" },
			{ gain = 3, cost = 25000000, tier = "Crystal" },
			{ gain = 4, cost = 125000000, tier = "Crystal" },
			{ gain = 5, cost = 600000000, tier = "Inferno" },
			{ gain = 7, cost = 3000000000, tier = "Inferno" },
		} :: { RackLevel },
	},
	Pen = {
		slotsPerLevel = 2,
		costBase = 2500,
		costGrowth = 4,
	},
}

return Upgrades
