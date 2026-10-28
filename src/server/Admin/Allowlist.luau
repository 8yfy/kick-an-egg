--!strict
-- SERVER ONLY (ServerScriptService never replicates to clients). The ONLY source of admin access:
-- numeric UserId -> role ("Owner" | "Developer" | "Tester"). Nothing else grants access: not names, display
-- names, groups, game passes, Premium, friends, account age, passwords or anything a client sends.
-- A UserId that is not listed has no role and zero privileges. Roles are read once when the server starts;
-- there is no way to change them while it runs (edit this file and ship a new server version instead).
--
-- To add someone: put their numeric UserId (from their profile URL, roblox.com/users/<id>/profile) here,
-- review it in a PR and ship. Never paste ids that came from chat or a client.

return table.freeze({
	users = table.freeze({
		-- Confirmed by the project owner on 2026-10-28: the owner (8yf_y) and the co-owner.
		[1340874349] = "Owner",
		[3953001499] = "Owner",
	}),
	-- Studio multi-client test servers use negative ids (-1, -2, ...). They can never exist on a live server,
	-- and Authorization only honours these when RunService:IsStudio() is true on the server.
	-- -1 = the first test client (an Owner); -2 and later stay unprivileged so the deny paths can be tested.
	studioTestUsers = table.freeze({
		[-1] = "Owner",
	}),
})
