local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local DevProductsData = require(Modules.Shared.Data.DevProductsData)

local CashFrameController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local buyCashFrame = frames:WaitForChild("Cash")
local buyCashScrollingFrame = buyCashFrame:WaitForChild("ScrollingFrame")

local cash1 = buyCashScrollingFrame:WaitForChild("Cash1")
local cash2 = buyCashScrollingFrame:WaitForChild("Cash2")

local buyCash1000Button = cash1:WaitForChild("1K")
local buyCash5000Button = cash1:WaitForChild("5K")
local buyCash10000Button = cash1:WaitForChild("10K")
local buyCash30000Button = cash2:WaitForChild("30K")
local buyCash50000Button = cash2:WaitForChild("50K")
local CASH_BUTTONS = {
	{ button = buyCash1000Button, productId = DevProductsData.BuyCash1000 },
	{ button = buyCash5000Button, productId = DevProductsData.BuyCash5000 },
	{ button = buyCash10000Button, productId = DevProductsData.BuyCash10000 },
	{ button = buyCash30000Button, productId = DevProductsData.BuyCash30000 },
	{ button = buyCash50000Button, productId = DevProductsData.BuyCash50000 },
}

local function getDevProductPrice(productId: number): number?
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and productInfo then
		return productInfo.PriceInRobux
	end

	return nil
end

local function setupCashButtons()
	for _, data in CASH_BUTTONS do
		local priceLabel = data.button:FindFirstChild("Price")
		if priceLabel then
			local robuxPrice = getDevProductPrice(data.productId)
			if robuxPrice then
				priceLabel.Text = tostring(robuxPrice)
			else
				priceLabel.Text = "?"
			end
		end

		data.button.Activated:Connect(function()
			MarketplaceService:PromptProductPurchase(player, data.productId)
		end)
	end
end

function CashFrameController.Init() end

function CashFrameController.Start()
	setupCashButtons()
end

return CashFrameController
