--!strict
-- CONTRACT FILE: change only via a `contract:` PR (numbers are Partner B's to tune).
-- Per-player upgrades: the Kick Sack gear (strength training) and the pen.
--
-- Sack: a Tool, taken out with the SACK box next to the KICK button (the Roblox hotbar is hidden). Out, your
--   current sack drops from the sky on a chain in front of you; each left click (tap) next to it kicks, at most
--   once every `interval` seconds (the client fires Remotes.Train at the moment of impact). The server counts a kick only when the sack is out (`dropSeconds` after it
--   was placed), you are within `range` studs of it and not mid-chase; each kick adds `tiers[tier].gain`
--   to `stat` (strength = kickPower, capped by Economy.maxKickPower). Buying the next sack
--   (Remotes.UpgradeTraining) costs `tiers[tier + 1].cost`: sacks are a ladder, bought in order.
--   `fx` is the tier's VFX step; each step keeps everything from the one before:
--   Basics, Comic, Champion, Elemental, Mythic, God. The models live in Builders/Models/Sacks.
--   Saved as PlayerData.rackLevel (the sack tier, 1-based; the key predates the sacks).
-- Pen: each level adds `slotsPerLevel` hatch slots (Economy.PlotSlots.base at level 1, capped at
--   Economy.PlotSlots.max). Level n -> n + 1 costs costBase * costGrowth^(n - 1) (Remotes.UpgradePen).
--
-- The server mirrors the state on workspace.Map.SafeZone.Bases.Base<i> as attributes so every client can
-- draw the signs: OwnerUserId (number, 0 = free), RackLevel (number: sack tier), PenLevel (number).

export type SackTier = { name: string, gain: number, cost: number, fx: string }

local Upgrades = {
	Sack = {
		stat = "kickPower",
		interval = 0.6,
		range = 8,
		dropSeconds = 0.9,
		tiers = {
			{ name = "Burlap Sack", gain = 0.1, cost = 0, fx = "Basics" },
			{ name = "Gym Canvas", gain = 0.15, cost = 150, fx = "Basics" },
			{ name = "Leather Classic", gain = 0.2, cost = 400, fx = "Basics" },
			{ name = "Pro Red", gain = 0.3, cost = 1000, fx = "Comic" },
			{ name = "Tire Stack", gain = 0.4, cost = 2500, fx = "Comic" },
			{ name = "Iron Plate", gain = 0.5, cost = 6000, fx = "Comic" },
			{ name = "Bronze Statue", gain = 0.65, cost = 15000, fx = "Champion" },
			{ name = "Silver Knight", gain = 0.8, cost = 40000, fx = "Champion" },
			{ name = "Gold Champion", gain = 1, cost = 100000, fx = "Champion" },
			{ name = "Ice Block", gain = 1.25, cost = 250000, fx = "Elemental" },
			{ name = "Crystal Geode", gain = 1.5, cost = 600000, fx = "Elemental" },
			{ name = "Candy Smash", gain = 2, cost = 1500000, fx = "Elemental" },
			{ name = "Lava Core", gain = 2.5, cost = 4000000, fx = "Elemental" },
			{ name = "Thunder Cell", gain = 3, cost = 10000000, fx = "Elemental" },
			{ name = "Toxic Barrel", gain = 3.75, cost = 25000000, fx = "Mythic" },
			{ name = "Robo Bag", gain = 4.5, cost = 60000000, fx = "Mythic" },
			{ name = "Dragon Hide", gain = 5.5, cost = 150000000, fx = "Mythic" },
			{ name = "Galaxy Void", gain = 6.5, cost = 400000000, fx = "Mythic" },
			{ name = "Sun Guardian", gain = 8, cost = 1000000000, fx = "Mythic" },
			{ name = "Rainbow God", gain = 10, cost = 2500000000, fx = "God" },
		} :: { SackTier },
	},
	Pen = {
		slotsPerLevel = 2,
		costBase = 2500,
		costGrowth = 4,
	},
}

return Upgrades
