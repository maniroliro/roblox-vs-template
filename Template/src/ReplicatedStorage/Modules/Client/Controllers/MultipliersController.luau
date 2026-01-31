local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local PlayerDataManager = require(Modules.Client.Managers.PlayerDataManager)
local MultipliersData = require(Modules.Shared.Data.MultipliersData)
local SoundManager = require(Modules.Client.Managers.SoundManager)
local UIAnimations = require(Modules.Client.Utils.UIAnimations)

local MultipliersController = {}

local player = Players.LocalPlayer

local buttonsFrame = player.PlayerGui:WaitForChild("MultiplicationButtons"):WaitForChild("TouchControlFrame")
local jumpButton = buttonsFrame:WaitForChild("Jump")
local speedButton = buttonsFrame:WaitForChild("Speed")

local productPrices = {}

local function getProductPrice(productId: number): number
	if productPrices[productId] then
		return productPrices[productId]
	end

	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
	end)

	if success and info and info.PriceInRobux then
		productPrices[productId] = info.PriceInRobux
		return info.PriceInRobux
	end

	return 0
end

local function updateButtonDisplay(button: Instance, statType: string)
	local data = PlayerDataManager.GetData()
	if not data then
		return
	end

	local robuxMultipliers = data.RobuxMultipliers or { Jump = 1, Speed = 1 }
	local currentMultiplier = robuxMultipliers[statType] or 1

	local nextEntry = MultipliersData.GetNextMultiplier(statType, currentMultiplier)

	local displayLabel = button:FindFirstChild("Display")
	local robuxLabel = button:FindFirstChild("Robux")

	if not nextEntry then
		if displayLabel then
			displayLabel.Text = "MAX"
		end
		if robuxLabel then
			robuxLabel.Text = ""
		end
		return
	end

	if displayLabel then
		displayLabel.Text = nextEntry.Multiplier .. "x " .. statType
	end

	if robuxLabel then
		local price = getProductPrice(nextEntry.ProductId)
		robuxLabel.Text = "" .. tostring(price)
	end
end

local function updateAllButtons()
	updateButtonDisplay(jumpButton, "Jump")
	updateButtonDisplay(speedButton, "Speed")
end

local function onButtonClicked(statType: string)
	local data = PlayerDataManager.GetData()
	if not data then
		return
	end

	local robuxMultipliers = data.RobuxMultipliers or { Jump = 1, Speed = 1 }
	local currentMultiplier = robuxMultipliers[statType] or 1

	local nextEntry = MultipliersData.GetNextMultiplier(statType, currentMultiplier)
	if not nextEntry then
		return
	end

	SoundManager.Play("Click")
	MarketplaceService:PromptProductPurchase(player, nextEntry.ProductId)
end

local function setupButtonAnimations(button: Instance)
	local surfaceGui = button:FindFirstChildWhichIsA("SurfaceGui")
	if surfaceGui then
		UIAnimations.SetupAllButtons(surfaceGui)
	end

	if button:IsA("GuiButton") then
		UIAnimations.SetupButton(button)
	end
end

local function connectButton(button: Instance, statType: string)
	local clickDetector = button:FindFirstChild("ClickDetector")
	if clickDetector then
		clickDetector.MouseClick:Connect(function()
			onButtonClicked(statType)
		end)
	end

	local proximityPrompt = button:FindFirstChild("ProximityPrompt")
	if proximityPrompt then
		proximityPrompt.Triggered:Connect(function()
			onButtonClicked(statType)
		end)
	end

	-- Check for SurfaceGui with a TextButton or ImageButton
	local surfaceGui = button:FindFirstChildWhichIsA("SurfaceGui")
	if surfaceGui then
		for _, descendant in surfaceGui:GetDescendants() do
			if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
				descendant.Activated:Connect(function()
					onButtonClicked(statType)
				end)
			end
		end
	end

	-- Check if button itself is a GUI button
	if button:IsA("TextButton") or button:IsA("ImageButton") then
		button.Activated:Connect(function()
			onButtonClicked(statType)
		end)
	end

	if button:IsA("BasePart") then
		button.Touched:Connect(function(hit)
			local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
			if hitPlayer == player then
				onButtonClicked(statType)
			end
		end)
	end

	setupButtonAnimations(button)
end

function MultipliersController.Init() end

function MultipliersController.Start()
	PlayerDataManager.WaitForData()

	updateAllButtons()

	connectButton(jumpButton, "Jump")
	connectButton(speedButton, "Speed")

	PlayerDataManager.DataUpdated:Connect(function()
		updateAllButtons()
	end)
end

return MultipliersController
