local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local SharedModules = Modules.Shared
local ClientModules = Modules.Client

local RemotesManager = require(SharedModules.Managers.RemotesManager)
local GUIManager = require(ClientModules.Managers.GUIManager)
local SoundManager = require(ClientModules.Managers.SoundManager)
local GiftsData = require(SharedModules.Data.GiftsData)
local GearsData = require(SharedModules.Data.GearsData)
local FormatUtils = require(SharedModules.Utils.FormatUtils)
local UIAnimations = require(ClientModules.Utils.UIAnimations)

local GiftsController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local framesContainer = gui:WaitForChild("Frames")
local giftsFrame = framesContainer:WaitForChild("Gifts")
local giftsHolder = giftsFrame:WaitForChild("Holder")
local giftButton = gui:WaitForChild("Gift")
local giftButtonTime = giftButton:WaitForChild("Time")

local getPlaytimeDataRemote = nil
local claimGiftRemote = nil
local playtimeUpdatedRemote = nil

local totalPlaytime = 0
local claimedGifts = {}
local giftElements = {}

local buttonOriginalColors = {
	Text = nil,
	Stroke = nil,
}

local COLORS = {
	Timer = {
		Text = Color3.fromRGB(255, 34, 34),
		Stroke = Color3.fromRGB(56, 4, 4),
	},
	Ready = {
		Text = Color3.fromRGB(28, 255, 24),
		Stroke = Color3.fromRGB(7, 39, 2),
	},
	Claimed = {
		Text = Color3.fromRGB(172, 172, 172),
		Stroke = Color3.fromRGB(39, 39, 39),
	},
}

local function formatTime(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%02d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%02d:%02d", minutes, secs)
	end
end

local function hasClaimedGift(giftNumber: number): boolean
	return table.find(claimedGifts, giftNumber) ~= nil
end

local function getGiftData(giftNumber: number)
	for _, gift in GiftsData do
		if gift.GiftNumber == giftNumber then
			return gift
		end
	end
	return nil
end

local function setTimerStyle(timerLabel: TextLabel, style: string)
	local colors = COLORS[style]
	if not colors then
		return
	end

	timerLabel.TextColor3 = colors.Text

	local stroke = timerLabel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = colors.Stroke
	end
end

local function updateGiftButton()
	local lowestTime = nil
	local hasReady = false

	for _, gift in GiftsData do
		if not hasClaimedGift(gift.GiftNumber) then
			local remainingTime = gift.Time - totalPlaytime

			if remainingTime <= 0 then
				hasReady = true
				break
			elseif lowestTime == nil or remainingTime < lowestTime then
				lowestTime = remainingTime
			end
		end
	end

	if hasReady then
		giftButtonTime.Text = "Ready to Claim"
		setTimerStyle(giftButtonTime, "Ready")
	elseif lowestTime then
		giftButtonTime.Text = "Claim in " .. formatTime(lowestTime)
		giftButtonTime.TextColor3 = buttonOriginalColors.Text
		local stroke = giftButtonTime:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = buttonOriginalColors.Stroke
		end
	else
		giftButtonTime.Text = "All Claimed!"
		setTimerStyle(giftButtonTime, "Claimed")
	end
end

local function updateGiftElement(giftNumber: number)
	local element = giftElements[giftNumber]
	if not element then
		return
	end

	local giftData = getGiftData(giftNumber)
	if not giftData then
		return
	end

	local timerLabel = element:FindFirstChild("Timer")
	if not timerLabel then
		return
	end

	if hasClaimedGift(giftNumber) then
		timerLabel.Text = "Claimed"
		setTimerStyle(timerLabel, "Claimed")
	elseif totalPlaytime >= giftData.Time then
		timerLabel.Text = "Ready to Claim"
		setTimerStyle(timerLabel, "Ready")
	else
		local remainingTime = giftData.Time - totalPlaytime
		timerLabel.Text = formatTime(remainingTime)
		setTimerStyle(timerLabel, "Timer")
	end
end

local function updateAllGifts()
	for giftNumber, _ in giftElements do
		updateGiftElement(giftNumber)
	end
	updateGiftButton()
end

local function onGiftClicked(giftNumber: number)
	local giftData = getGiftData(giftNumber)
	if not giftData then
		return
	end

	if hasClaimedGift(giftNumber) then
		SoundManager.Play("Error")
		return
	end

	if totalPlaytime < giftData.Time then
		SoundManager.Play("Error")
		return
	end

	local success = claimGiftRemote:InvokeServer(giftNumber)

	if success then
		SoundManager.Play("PurchasedCoin")
		table.insert(claimedGifts, giftNumber)
		updateGiftElement(giftNumber)
		updateGiftButton()
	else
		SoundManager.Play("Error")
	end
end

local function setupGiftElements()
	for i = 1, 12 do
		local giftElement = giftsHolder:FindFirstChild("Gift" .. i)
		if not giftElement then
			continue
		end

		giftElements[i] = giftElement

		local giftData = getGiftData(i)
		if giftData then
			local rewardLabel = giftElement:FindFirstChild("Reward2")
			if rewardLabel then
				rewardLabel.Text = "+" .. FormatUtils.FormatCash(giftData.Reward)
			end

			local itemIcon = giftElement:FindFirstChild("ItemIcon")
			if itemIcon then
				itemIcon.Visible = giftData.Item ~= nil
			end

			local gearIcon = giftElement:FindFirstChild("GearIcon")
			if gearIcon then
				if giftData.Gear then
					gearIcon.Visible = true
					local gearInfo = GearsData[giftData.Gear]
					if gearInfo and gearInfo.ImageId then
						gearIcon.Image = gearInfo.ImageId
					end
				else
					gearIcon.Visible = false
				end
			end
		end

		UIAnimations.SetupButton(giftElement)

		giftElement.Activated:Connect(function()
			onGiftClicked(i)
		end)
	end
end

local function onPlaytimeUpdated(newPlaytime: number)
	totalPlaytime = newPlaytime
	updateAllGifts()
end

function GiftsController.Init()
	getPlaytimeDataRemote = RemotesManager:GetRemote("GetPlaytimeData")
	claimGiftRemote = RemotesManager:GetRemote("ClaimGift")
	playtimeUpdatedRemote = RemotesManager:GetRemote("PlaytimeUpdated")
end

function GiftsController.Start()
	buttonOriginalColors.Text = giftButtonTime.TextColor3
	local stroke = giftButtonTime:FindFirstChildOfClass("UIStroke")
	if stroke then
		buttonOriginalColors.Stroke = stroke.Color
	end

	GUIManager.RegisterFrame("Gifts", giftsFrame)

	giftButton.Activated:Connect(function()
		GUIManager.ToggleFrame("Gifts")
	end)

	setupGiftElements()

	local playtimeData = getPlaytimeDataRemote:InvokeServer()
	if playtimeData then
		totalPlaytime = playtimeData.TotalPlaytime or 0
		claimedGifts = playtimeData.ClaimedGifts or {}
	end

	updateAllGifts()

	playtimeUpdatedRemote.OnClientEvent:Connect(onPlaytimeUpdated)
end

return GiftsController
