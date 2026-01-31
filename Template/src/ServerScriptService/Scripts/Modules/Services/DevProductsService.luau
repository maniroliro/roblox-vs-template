local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local DevProductsData = require(Modules.Data.DevProductsData)
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local DevProductsService = {}

local function getProductPrice(productId: number): number
	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and info and info.PriceInRobux then
		return info.PriceInRobux
	end

	return 0
end

local function processReceipt(receiptInfo)
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId
	local handler = DevProductsData[productId]

	if handler then
		local success = handler(player)
		if success then
			local price = getProductPrice(productId)
			if price > 0 then
				PlayerDataManager.Increase(player, "RobuxSpent", price)
			end

			local robuxPurchaseRemote = RemotesManager:GetRemote("RobuxPurchaseCompleted")
			if robuxPurchaseRemote then
				robuxPurchaseRemote:FireClient(player)
			end

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function DevProductsService.Init() end

function DevProductsService.Start()
	MarketplaceService.ProcessReceipt = processReceipt
end

return DevProductsService
