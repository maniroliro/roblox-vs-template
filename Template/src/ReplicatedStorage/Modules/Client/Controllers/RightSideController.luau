local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local GamePassesData = require(Modules.Shared.Data.GamePassesData)

local RightSideController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local rightSide = gui:WaitForChild("RightSide")

-- Item buttons (to be referenced)
-- local laserGunButton = nil
-- local jetpackButton = nil
local gravityCoilButton = rightSide:WaitForChild("GravityCoil")
-- local slapButton = nil
local grappleHookButton = rightSide:WaitForChild("GrappleHook")
local magicCarpetButton = rightSide:WaitForChild("MagicCarpet")
-- local fusionCoilButton = nil
local speedCoilButton = rightSide:WaitForChild("SpeedCoil")

local ITEM_BUTTONS = {
	-- { button = laserGunButton, gamePassId = GamePassesData.LaserGun },
	-- { button = jetpackButton, gamePassId = GamePassesData.Jetpack },
	{ button = gravityCoilButton, gamePassId = GamePassesData.GravityCoil },
	-- { button = slapButton, gamePassId = GamePassesData.Slap },
	{ button = grappleHookButton, gamePassId = GamePassesData.GrappleHook },
	{ button = magicCarpetButton, gamePassId = GamePassesData.MagicCarpet },
	-- { button = fusionCoilButton, gamePassId = GamePassesData.FusionCoil },
	{ button = speedCoilButton, gamePassId = GamePassesData.SpeedCoil },
}

local function getGamePassPrice(gamePassId: number): number?
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(gamePassId, Enum.InfoType.GamePass)
	end)

	if success and productInfo then
		return productInfo.PriceInRobux
	end

	return nil
end

local function setupItemButtons()
	for _, data in ITEM_BUTTONS do
		if not data.button then
			continue
		end

		local priceLabel = data.button:FindFirstChild("Price")
		if priceLabel then
			local robuxPrice = getGamePassPrice(data.gamePassId)
			if robuxPrice then
				priceLabel.Text = tostring(robuxPrice)
			else
				priceLabel.Text = "?"
			end
		end

		data.button.Activated:Connect(function()
			MarketplaceService:PromptGamePassPurchase(player, data.gamePassId)
		end)
	end
end

function RightSideController.Init() end

function RightSideController.Start()
	setupItemButtons()
end

return RightSideController
