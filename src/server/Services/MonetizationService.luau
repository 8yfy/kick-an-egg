--!strict
-- Gamepasses and dev products from Economy.Gamepasses / Economy.DevProducts (placeholder IDs;
-- id = 0 entries are skipped). A's Store UI prompts purchases with those IDs.
-- - Gamepass ownership is checked on join and after PromptGamePassPurchaseFinished.
--   PlotService reads :GetIncomeMultiplier(player) for the income tick.
-- - ProcessReceipt grants each PurchaseId once: it is recorded in data.receipts and saved
--   before PurchaseGranted is returned. Prize Wheel packs (Config/Wheel.Products) add banked spins;
--   donations (Config/Leaderboards.Donations) add to data.donated (LeaderboardService).
-- Studio command bar: MonetizationService:SetOwned(game.Players.<Name>, "DoubleMoney", true)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)
local Wheel = require(Shared.Config.Wheel)
local Leaderboards = require(Shared.Config.Leaderboards)

local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Parent.Util.Analytics)
local PlotService = require(script.Parent.PlotService)
local LeaderboardService = require(script.Parent.LeaderboardService)

local MAX_RECEIPTS = 50

local MonetizationService = {}

local owned: { [Player]: { [string]: boolean } } = {}

local function passById(id: number): string?
	for name, pass in Economy.Gamepasses do
		if pass.id ~= 0 and pass.id == id then
			return name
		end
	end
	return nil
end

local function productById(id: number): (string?, { id: number, money: number }?)
	for name, product in Economy.DevProducts do
		if product.id ~= 0 and product.id == id then
			return name, product
		end
	end
	return nil, nil
end

local function wheelPackById(id: number): (string?, Wheel.Product?)
	for name, pack in Wheel.Products do
		if pack.id ~= 0 and pack.id == id then
			return name, pack
		end
	end
	return nil, nil
end

local function donationById(id: number): Leaderboards.Donation?
	for _, d in Leaderboards.Donations do
		if d.id ~= 0 and d.id == id then
			return d
		end
	end
	return nil
end

local function loadOwnership(player: Player)
	local passes: { [string]: boolean } = {}
	owned[player] = passes
	for name, pass in Economy.Gamepasses do
		if pass.id ~= 0 then
			local ok, result =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			passes[name] = ok and result == true
		end
	end
	PlotService:Refresh(player)
end

function MonetizationService:Owns(player: Player, passName: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[passName] == true
end

function MonetizationService:SetOwned(player: Player, passName: string, value: boolean)
	local passes = owned[player] or {}
	owned[player] = passes
	passes[passName] = value
	player:SetAttribute(`Pass_{passName}`, value)
	PlotService:Refresh(player)
end

function MonetizationService:GetIncomeMultiplier(player: Player): number
	local mult = 1
	for name, pass in Economy.Gamepasses do
		if self:Owns(player, name) then
			mult *= pass.incomeMultiplier
		end
	end
	return mult
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = player and DataService:Get(player)
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- retried on their next join
	end
	local purchaseId: string = receipt.PurchaseId
	if table.find(data.receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted earlier
	end
	local productName, product = productById(receipt.ProductId)
	local packName, pack = wheelPackById(receipt.ProductId)
	local donation = donationById(receipt.ProductId)
	if not (productName and product) and not (packName and pack) and not donation then
		warn(`[MonetizationService] unknown product {receipt.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local receipts = table.clone(data.receipts)
	table.insert(receipts, purchaseId)
	while #receipts > MAX_RECEIPTS do
		table.remove(receipts, 1)
	end
	if productName and product then
		DataService:Set(player, { money = data.money + product.money, receipts = receipts })
		Analytics.money(player, "Source", product.money, "IAP", productName)
	elseif packName and pack then -- Prize Wheel spins, banked (WheelService spends them)
		DataService:Set(player, { wheelSpins = (data.wheelSpins or 0) + pack.spins, receipts = receipts })
		Analytics.custom(player, "WheelSpinsBought", pack.spins, packName)
	elseif donation then -- counts what Roblox says was spent (TOP DONATORS board)
		local spent = receipt.CurrencySpent
		DataService:Set(player, { receipts = receipts })
		LeaderboardService:AddDonation(
			player,
			if typeof(spent) == "number" and spent > 0 then spent else donation.robux
		)
		Analytics.custom(player, "Donation", donation.robux)
	end
	if not DataService:SaveNow(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- the receipt id is kept in memory; no double grant
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local name = passById(passId)
		if purchased and name then
			self:SetOwned(player, name, true)
			Analytics.custom(player, "GamepassBought", 1, name)
		end
	end)
	DataService:OnLoaded(function(player)
		loadOwnership(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

return MonetizationService
