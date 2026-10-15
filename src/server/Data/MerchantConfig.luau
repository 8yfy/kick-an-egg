--!strict
-- Shop merchants (MerchantService): which real Roblox avatar appearance each shop's NPC wears.
--
-- UserId = the Roblox user whose AVATAR APPEARANCE the merchant NPC copies (Players:GetHumanoidDescriptionFromUserId).
-- It is only an appearance: the NPC is not that player, is not controlled by them and never joins as them.
-- 0 = not provided yet: the merchant wears a plain default Roblox avatar (no account) until a real id is set.
-- Never put an id here that the owner of that account hasn't agreed to.
--
-- Kinds are the merchant spots the map builds (Builders/Map/Merchants): "Coach" stands behind the Boxing Sack
-- Shop counter, "Professor" behind the Index stall.

export type Merchant = { UserId: number, DisplayName: string, Kind: string }

local MerchantConfig: { [string]: Merchant } = {
	BoxingSackMerchant = {
		UserId = 3953001499, -- provided by Partner A (boxing sack stand)
		DisplayName = "Boxing Sack Merchant",
		Kind = "Coach",
	},
	IndexMerchant = {
		UserId = 1340874349, -- provided by Partner A (pet / Index stand)
		DisplayName = "Index Merchant",
		Kind = "Professor",
	},
}

return MerchantConfig
