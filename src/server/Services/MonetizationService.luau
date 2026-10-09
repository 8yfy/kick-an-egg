--!strict
-- Gamepasses and dev products from Economy.Gamepasses / Economy.DevProducts (placeholder IDs;
-- id = 0 entries are skipped). A's Store UI prompts purchases with those IDs.
-- - Gamepass ownership is checked on join and after PromptGamePassPurchaseFinished.
--   PlotService reads :GetIncomeMultiplier(player) for the income tick.
-- - ProcessReceipt grants each PurchaseId once: it is recorded in data.receipts and saved
--   before PurchaseGranted is returned.
-- Studio command bar: MonetizationService:SetOwned(game.Players.<Name>, "DoubleMoney", true)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Economy = require(Shared.Config.Economy)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

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

local function productById(id: number): { id: number, money: number }?
	for _, product in Economy.DevProducts do
		if product.id ~= 0 and product.id == id then
			return product
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
	local product = productById(receipt.ProductId)
	if not product then
		warn(`[MonetizationService] unknown product {receipt.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local receipts = table.clone(data.receipts)
	table.insert(receipts, purchaseId)
	while #receipts > MAX_RECEIPTS do
		table.remove(receipts, 1)
	end
	DataService:Set(player, { money = data.money + product.money, receipts = receipts })
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
