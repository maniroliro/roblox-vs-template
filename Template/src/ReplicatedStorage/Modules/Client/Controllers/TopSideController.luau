local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local PlayerDataManager = require(Modules.Client.Managers.PlayerDataManager)
local RemotesManager = require(Modules.Shared.Managers.RemotesManager)
local DevProductsData = require(Modules.Shared.Data.DevProductsData)

local TopSideController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI = playerGui:WaitForChild("GUI")

local topSide = GUI:WaitForChild("TopSide")
local stageCounter = topSide:WaitForChild("Counter"):WaitForChild("Amount")
local freeSkipsLabel = topSide:WaitForChild("SkipStage"):WaitForChild("Amount")
local backButton = topSide:WaitForChild("Back")
local forwardButton = topSide:WaitForChild("Next")
local skipButton = topSide:WaitForChild("SkipStage")
local finishButton = GUI:WaitForChild("Finish"):WaitForChild("Finish")
local killAllButton = topSide:WaitForChild("KillAll")

local backButtonImage = backButton:WaitForChild("ImageLabel")
local forwardButtonImage = forwardButton:WaitForChild("ImageLabel")

local function updateStageCounter(data)
	if not data then
		return
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		stageCounter.Text = "0"
		return
	end

	stageCounter.Text = tostring(data.CurrentCheckpoint or 0)
end

local function updateFreeSkipsLabel(data)
	if not data then
		return
	end
	freeSkipsLabel.Text = "Free Skips: " .. (data.FreeSkips or 0)
end

local function isAtMaxCheckpoint(): boolean
	local data = PlayerDataManager.GetData()
	if not data then
		return false
	end

	return (data.CurrentCheckpoint or 0) >= 50
end

local function HasUnlockedMaxCheckpoint(): boolean
	local data = PlayerDataManager.GetData()
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	return mapData.CheckpointReached >= 50
end

local function isAtMinCheckpoint(): boolean
	local data = PlayerDataManager.GetData()
	if not data then
		return true
	end

	return (data.CurrentCheckpoint or 0) <= 0
end

local function canGoForward(): boolean
	local data = PlayerDataManager.GetData()
	if not data then
		return false
	end

	local lastMap = data.LastMapPlayed
	if not lastMap or lastMap == "" then
		return false
	end

	local mapData = data.Map[lastMap]
	if not mapData then
		return false
	end

	local nextCheckpoint = (data.CurrentCheckpoint or 0) + 1
	if nextCheckpoint > 50 then
		return false
	end

	return nextCheckpoint <= (mapData.CheckpointReached or 0)
end

local function updateButtonStates()
	if isAtMinCheckpoint() then
		backButtonImage.ImageTransparency = 0.5
	else
		backButtonImage.ImageTransparency = 0
	end

	if isAtMaxCheckpoint() or not canGoForward() then
		forwardButtonImage.ImageTransparency = 0.5
	else
		forwardButtonImage.ImageTransparency = 0
	end
end

local function updateUI(data)
	updateStageCounter(data)
	updateFreeSkipsLabel(data)
	updateButtonStates()
end

local function onBackButtonClicked()
	if isAtMinCheckpoint() then
		return
	end

	local goBackStage = RemotesManager:GetRemote("GoBackStage")
	if goBackStage then
		goBackStage:InvokeServer()
	end
end

local function onForwardButtonClicked()
	if isAtMaxCheckpoint() then
		return
	end

	local goForwardStage = RemotesManager:GetRemote("GoForwardStage")
	if goForwardStage then
		local success = goForwardStage:InvokeServer()
		if success then
			return
		end
	end

	MarketplaceService:PromptProductPurchase(player, DevProductsData.SkipStage)
end

local function onSkipButtonClicked()
	if HasUnlockedMaxCheckpoint() then
		print("[TopSideController] Already at checkpoint 50, cannot skip")
		return
	end

	local data = PlayerDataManager.GetData()
	if not data then
		return
	end

	if (data.FreeSkips or 0) > 0 then
		local useSkip = RemotesManager:GetRemote("UseSkip")
		if useSkip then
			useSkip:InvokeServer()
		end
	else
		MarketplaceService:PromptProductPurchase(player, DevProductsData.SkipStage)
	end
end

local function onFinishButtonClicked()
	if HasUnlockedMaxCheckpoint() then
		print("[TopSideController] Already at checkpoint 50, cannot finish")
		return
	end

	MarketplaceService:PromptProductPurchase(player, DevProductsData.FinishMap)
end

local function onKillAllButtonClicked()
	MarketplaceService:PromptProductPurchase(player, DevProductsData.KillAll)
end

local function onDataUpdated(newData, _oldData)
	updateUI(newData)
end

function TopSideController.Init() end

function TopSideController.Start()
	backButton.Activated:Connect(onBackButtonClicked)
	forwardButton.Activated:Connect(onForwardButtonClicked)
	skipButton.Activated:Connect(onSkipButtonClicked)
	finishButton.Activated:Connect(onFinishButtonClicked)
	killAllButton.Activated:Connect(onKillAllButtonClicked)

	PlayerDataManager.DataUpdated:Connect(onDataUpdated)

	task.spawn(function()
		local data = PlayerDataManager.WaitForData()
		updateUI(data)
	end)
end

return TopSideController
