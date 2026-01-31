local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local ClientModules = Modules.Client

local RemotesManager = require(SharedModules.Managers.RemotesManager)
local PlayerDataManager = require(ClientModules.Managers.PlayerDataManager)
local SoundManager = require(ClientModules.Managers.SoundManager)
local UpgradesData = require(SharedModules.Data.UpgradesData)
local FormatUtils = require(SharedModules.Utils.FormatUtils)
local UIAnimations = require(ClientModules.Utils.UIAnimations)

local UpgradesController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local framesContainer = gui:WaitForChild("Frames")
local upgradesFrame = framesContainer:WaitForChild("Upgrades")
local scrollingFrame = upgradesFrame:WaitForChild("ScrollingFrame")

local cashFrame = scrollingFrame:WaitForChild("Cash")
local jumpFrame = scrollingFrame:WaitForChild("Jump")
local speedFrame = scrollingFrame:WaitForChild("Speed")

local buyUpgradeRemote = nil

local UPGRADE_FRAMES = {
	CashMultiplier = cashFrame,
	JumpMultiplier = jumpFrame,
	SpeedMultiplier = speedFrame,
}

local function getCurrentLevel(upgradeType: string): number
	local data = PlayerDataManager.GetData()
	if not data or not data.UpgradesLevel then
		return 1
	end
	local level = data.UpgradesLevel[upgradeType]
	if not level or level < 1 then
		return 1
	end
	return level
end

local function updateUpgradeFrame(upgradeType: string)
	local frame = UPGRADE_FRAMES[upgradeType]
	if not frame then
		return
	end

	local currentLevel = getCurrentLevel(upgradeType)
	local maxLevel = UpgradesData.GetMaxLevel(upgradeType)
	local isMaxed = currentLevel >= maxLevel

	local currentMultiplier = UpgradesData.GetMultiplier(upgradeType, currentLevel)
	local nextLevelData = UpgradesData.GetNextLevelData(upgradeType, currentLevel)

	local progressLabel = frame:FindFirstChild("Progress")
	local levelLabel = frame:FindFirstChild("Level")
	local buyButton = frame:FindFirstChild("Buy")

	if progressLabel then
		if isMaxed then
			progressLabel.Text = currentMultiplier .. "x -> MAX"
		else
			local nextMultiplier = nextLevelData and nextLevelData.Multiplier or currentMultiplier
			progressLabel.Text = currentMultiplier .. "x -> " .. nextMultiplier .. "x"
		end
	end

	if levelLabel then
		levelLabel.Text = "Lvl " .. currentLevel
	end

	if buyButton then
		local titleLabel = buyButton:FindFirstChild("Title")
		if titleLabel then
			if isMaxed then
				titleLabel.Text = "MAX"
			elseif nextLevelData then
				titleLabel.Text = FormatUtils.FormatCash(nextLevelData.Price)
			end
		end
	end
end

local function updateAllUpgradeFrames()
	for upgradeType, _ in UPGRADE_FRAMES do
		updateUpgradeFrame(upgradeType)
	end
end

local function onBuyUpgrade(upgradeType: string)
	local currentLevel = getCurrentLevel(upgradeType)
	local maxLevel = UpgradesData.GetMaxLevel(upgradeType)

	if currentLevel >= maxLevel then
		SoundManager.Play("Error")
		return
	end

	local success = buyUpgradeRemote:InvokeServer(upgradeType)

	if success then
		SoundManager.Play("PurchasedCoin")
		updateUpgradeFrame(upgradeType)
	else
		SoundManager.Play("Error")
	end
end

local function setupUpgradeButtons()
	for upgradeType, frame in UPGRADE_FRAMES do
		local buyButton = frame:FindFirstChild("Buy")
		if buyButton then
			UIAnimations.SetupButton(buyButton)

			buyButton.Activated:Connect(function()
				onBuyUpgrade(upgradeType)
			end)
		end
	end
end

function UpgradesController.Init()
	buyUpgradeRemote = RemotesManager:GetRemote("BuyUpgrade")
end

function UpgradesController.Start()
	setupUpgradeButtons()
	updateAllUpgradeFrames()

	PlayerDataManager.DataUpdated:Connect(function()
		updateAllUpgradeFrames()
	end)
end

return UpgradesController
