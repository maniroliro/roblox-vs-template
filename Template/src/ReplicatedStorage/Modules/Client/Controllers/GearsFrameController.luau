local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local RemotesManager = require(Modules.Shared.Managers.RemotesManager)
local SoundManager = require(Modules.Client.Managers.SoundManager)
local GearsData = require(Modules.Shared.Data.GearsData)
local DevProductsData = require(Modules.Shared.Data.DevProductsData)
local FormatUtils = require(Modules.Shared.Utils.FormatUtils)

local GearsFrameController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local gearsFrame = frames:WaitForChild("Gears")
local gearsScrollingFrame = gearsFrame:WaitForChild("ScrollingFrame")

-- Variables to be referenced (UI elements)
local gearsContent = gearsScrollingFrame
local gearTemplate = gearsScrollingFrame:WaitForChild("Template")
local rarityAssets =
	ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("Gears"):WaitForChild("Rarity")

local function getDevProductPrice(productId: number): number?
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and productInfo then
		return productInfo.PriceInRobux
	end

	return nil
end

local function createGearItem(gearKey: string, gearData)
	if not gearTemplate or not gearsContent then
		warn("[GearsFrameController] Template or content not set")
		return
	end

	local item = gearTemplate:Clone()
	item.Name = gearKey

	local frameContainer = item:FindFirstChild("Frame")
	if frameContainer then
		local iconImage = frameContainer:FindFirstChild("Icon")
		if iconImage and gearData.ImageId then
			iconImage.Image = gearData.ImageId
		end
	end

	local titleLabel = item:FindFirstChild("Title")
	if titleLabel then
		titleLabel.Text = gearData.Name
	end

	local descLabel = item:FindFirstChild("Desc")
	if descLabel then
		descLabel.Text = gearData.Description or ""
	end

	local rarityContainer = item
	if rarityContainer then
		local rarityName = gearData.Rarity or "Common"
		local rarityAsset = rarityAssets:FindFirstChild(rarityName)
		if rarityAsset then
			local rarityClone = rarityAsset:Clone()
			rarityClone.Parent = rarityContainer
		end
	end

	local buyCashButton = item:FindFirstChild("BuyCash")
	if buyCashButton then
		local priceLabel = buyCashButton:FindFirstChild("Title")
		if priceLabel then
			priceLabel.Text = FormatUtils.FormatCash(gearData.Price)
		end

		buyCashButton.Activated:Connect(function()
			local buyRemote = RemotesManager:GetRemote("BuyGearWithCash")
			if buyRemote then
				local success = buyRemote:InvokeServer(gearKey)
				if success then
					SoundManager.Play("PurchasedCoin")
				else
					SoundManager.Play("Error")
				end
			end
		end)
	end

	local buyRobuxButton = item:FindFirstChild("BuyRobux")
	if buyRobuxButton then
		local productId = DevProductsData[gearKey]
		if productId then
			local priceLabel = buyRobuxButton:FindFirstChild("Price")
			if priceLabel then
				local robuxPrice = getDevProductPrice(productId)
				if robuxPrice then
					priceLabel.Text = " " .. tostring(robuxPrice)
				else
					priceLabel.Text = "?"
				end
			end

			buyRobuxButton.Activated:Connect(function()
				MarketplaceService:PromptProductPurchase(player, productId)
			end)
		end
	end

	item.Visible = true
	item.Parent = gearsContent
end

local function populateGearsFrame()
	local sortedGears = {}
	for gearKey, gearData in GearsData do
		table.insert(sortedGears, { key = gearKey, data = gearData })
	end

	table.sort(sortedGears, function(a, b)
		return a.data.Price < b.data.Price
	end)

	for _, gear in sortedGears do
		createGearItem(gear.key, gear.data)
	end
end

function GearsFrameController.SetTemplate(template: Frame)
	gearTemplate = template
	gearTemplate.Visible = false
end

function GearsFrameController.SetContent(content: Frame)
	gearsContent = content
end

function GearsFrameController.Init() end

function GearsFrameController.Start()
	if gearTemplate and gearsContent then
		populateGearsFrame()
	else
		warn("[GearsFrameController] Template or content not set before Start()")
	end
end

return GearsFrameController
