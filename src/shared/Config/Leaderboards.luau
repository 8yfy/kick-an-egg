--!strict
-- CONTRACT FILE: the two global boards on the plaza wall opposite the Prize Wheel (Builders/Map/Boards,
-- LeaderboardService, UI Screens/Donate).
--   Power:     all-time top Kick Power (data.kickPower) across every server (an OrderedDataStore).
--   Donations: all-time top Robux donated (data.donated, the Robux Roblox reports for each donation receipt).
-- Without DataStore access (an unpublished Studio place) both show this server's players instead.

export type Board = { title: string, store: string, stat: string, unit: string }
export type Donation = { id: number, robux: number }

local Leaderboards = {
	Boards = {
		Power = { title = "TOP KICK POWER", store = "TopKickPower_v1", stat = "kickPower", unit = "" },
		Donations = { title = "TOP DONATORS", store = "TopDonations_v1", stat = "donated", unit = "R$ " },
	} :: { [string]: Board },
	Rows = 10,
	RefreshSeconds = 60, -- write changed scores + re-read the top rows (DataStore budget friendly)

	-- Donation developer products, smallest first. id = 0 until created on Roblox (Creator Hub > your
	-- experience > Monetization > Developer Products, priced at `robux`), then paste the id here. `robux` is
	-- only the button label: the amount counted is what the receipt says was spent.
	Donations = {
		{ id = 0, robux = 10 },
		{ id = 0, robux = 50 },
		{ id = 0, robux = 100 },
		{ id = 0, robux = 500 },
		{ id = 0, robux = 1000 },
	} :: { Donation },
}

return Leaderboards
