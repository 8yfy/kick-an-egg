--!strict
-- CONTRACT FILE: change only via a `contract:` PR (numbers are Partner B's to tune).
-- Per-player upgrades: the Kick Sack gear (strength training) and the pen.
--
-- Sack: a Tool, taken out with the bottom Kick Sack quickslot (key 1 / tap / gamepad; the Roblox hotbar is
--   hidden). Out, your current sack drops from the sky on a chain in front of you; each left click (tap) next to
--   it kicks, at most once every `interval` seconds (the client fires Remotes.Train at the moment of impact). The
--   server counts a kick only when the sack is out (`dropSeconds` after it was placed), you are within `range`
--   studs of it and not mid-chase; each kick adds `tiers[tier].gain` to `stat` (strength = kickPower) up to the
--   sack's training `cap` (scaled by rebirths: Economy.sackCap). A better sack is the only way past a cap, so
--   power follows the sack ladder (each sack reaches about one zone farther with a good kick) instead of
--   maxing out within minutes. Saved power above a cap is never lowered. Buying the next sack
--   (Remotes.UpgradeTraining, at the Boxing Sack Shop) costs `tiers[tier + 1].cost`: sacks are bought in order.
--   `fx` is the tier's VFX step; each step keeps everything from the one before:
--   Basics, Comic, Champion, Elemental, Mythic, God. The models live in Builders/Models/Sacks.
--   Saved as PlayerData.rackLevel (the sack tier, 1-based; the key predates the sacks).
-- Pen: each level adds `slotsPerLevel` hatch slots (Economy.PlotSlots.base at level 1, capped at
--   Economy.PlotSlots.max). Level n -> n + 1 costs costBase * costGrowth^(n - 1) (Remotes.UpgradePen).
--
-- The server mirrors the state on workspace.Map.SafeZone.Bases.Base<i> as attributes so every client can
-- draw the signs: OwnerUserId (number, 0 = free), RackLevel (number: sack tier), PenLevel (number).

export type SackTier = { name: string, gain: number, cap: number, cost: number, fx: string }

local Upgrades = {
	Sack = {
		stat = "kickPower",
		interval = 0.6,
		range = 8,
		dropSeconds = 0.9,
		tiers = {
			{ name = "Burlap Sack", gain = 0.07, cap = 4, cost = 0, fx = "Basics" },
			{ name = "Gym Canvas", gain = 0.08, cap = 7.5, cost = 150, fx = "Basics" },
			{ name = "Leather Classic", gain = 0.09, cap = 11.5, cost = 400, fx = "Basics" },
			{ name = "Pro Red", gain = 0.1, cap = 15, cost = 1000, fx = "Comic" },
			{ name = "Tire Stack", gain = 0.11, cap = 18.5, cost = 2500, fx = "Comic" },
			{ name = "Iron Plate", gain = 0.12, cap = 22, cost = 6000, fx = "Comic" },
			{ name = "Bronze Statue", gain = 0.13, cap = 26, cost = 15000, fx = "Champion" },
			{ name = "Silver Knight", gain = 0.14, cap = 29.5, cost = 40000, fx = "Champion" },
			{ name = "Gold Champion", gain = 0.15, cap = 33, cost = 100000, fx = "Champion" },
			{ name = "Ice Block", gain = 0.16, cap = 37, cost = 250000, fx = "Elemental" },
			{ name = "Crystal Geode", gain = 0.17, cap = 40.5, cost = 600000, fx = "Elemental" },
			{ name = "Candy Smash", gain = 0.18, cap = 44, cost = 1500000, fx = "Elemental" },
			{ name = "Lava Core", gain = 0.19, cap = 47.5, cost = 4000000, fx = "Elemental" },
			{ name = "Thunder Cell", gain = 0.2, cap = 51, cost = 10000000, fx = "Elemental" },
			{ name = "Toxic Barrel", gain = 0.21, cap = 55, cost = 25000000, fx = "Mythic" },
			{ name = "Robo Bag", gain = 0.22, cap = 58.5, cost = 60000000, fx = "Mythic" },
			{ name = "Dragon Hide", gain = 0.23, cap = 62, cost = 150000000, fx = "Mythic" },
			{ name = "Galaxy Void", gain = 0.24, cap = 65.5, cost = 400000000, fx = "Mythic" },
			{ name = "Sun Guardian", gain = 0.25, cap = 69.5, cost = 1000000000, fx = "Mythic" },
			{ name = "Rainbow God", gain = 0.3, cap = 100, cost = 2500000000, fx = "God" },
		} :: { SackTier },
	},
	Pen = {
		slotsPerLevel = 2,
		costBase = 2500,
		costGrowth = 4,
	},
}

return Upgrades
