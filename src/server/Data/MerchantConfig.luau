--!strict
-- Shop merchants (MerchantService): which real Roblox avatar appearance each shop's NPC wears.
--
-- UserId = the Roblox user whose AVATAR APPEARANCE the merchant NPC copies (Players:GetHumanoidDescriptionFromUserId).
-- It is only an appearance: the NPC is not that player, is not controlled by them and never joins as them.
-- 0 = not provided yet: the merchant wears a plain default Roblox avatar (no account) until a real id is set.
-- Never put an id here that the owner of that account hasn't agreed to.
--
-- Kinds are the merchant spots the map builds (Builders/Map/Merchants): "Coach" stands behind the Boxing Sack
-- Shop counter, "PetSeller" behind the Pet Selling Stand counter (map overhaul; the Index stall is gone).

export type Merchant = { UserId: number, DisplayName: string, Kind: string }

local MerchantConfig: { [string]: Merchant } = {
	BoxingSackMerchant = {
		UserId = 3953001499, -- Krono808 (the game owner's own avatar, at their request 2026-10-14)
		DisplayName = "Boxing Sack Merchant",
		Kind = "Coach",
	},
	PetSellerMerchant = {
		UserId = 0, -- BLOCKED: waiting for the real UserId to use
		DisplayName = "Pet Merchant",
		Kind = "PetSeller",
	},
}

return MerchantConfig
