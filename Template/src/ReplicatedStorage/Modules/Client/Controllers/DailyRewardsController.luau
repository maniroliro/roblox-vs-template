local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local RemotesManager = require(Modules.Shared.Managers.RemotesManager)
local DailyRewardsData = require(Modules.Shared.Data.DailyRewardsData)
local GearsData = require(Modules.Shared.Data.GearsData)
local GUIManager = require(Modules.Client.Managers.GUIManager)
local SoundManager = require(Modules.Client.Managers.SoundManager)

local DailyRewardsController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GUI = playerGui:WaitForChild("GUI")
local framesFolder = GUI:WaitForChild("Frames")

local dailyRewardsFrame = framesFolder:WaitForChild("DailyRewards")
local scrollingFrame = dailyRewardsFrame:WaitForChild("ScrollingFrame")
local template = scrollingFrame:WaitForChild("Template")
local titleLabel = dailyRewardsFrame:WaitForChild("Title")

local rewardData = nil
local isOpen = false
local timerConnection = nil

local function formatTimerText(seconds: number): string
	if seconds <= 0 then
		return ""
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function updateTitleLabel()
	if not rewardData then
		titleLabel.Text = ""
		return
	end

	if rewardData.CanClaim then
		titleLabel.Text = "Claim your reward!"
	else
		local timeLeft = rewardData.NextAvailableTime - os.time()
		if timeLeft > 0 then
			local timerText = formatTimerText(timeLeft)
			titleLabel.Text = 'Next Reward in: <font color="rgb(255,35,35)">' .. timerText .. "</font>"
		else
			titleLabel.Text = "Claim your reward!"
			rewardData.CanClaim = true
		end
	end
end

local function formatCash(amount: number): string
	return "+ $" .. tostring(amount)
end

local function clearDayFrames()
	for _, child in scrollingFrame:GetChildren() do
		if child:IsA("Frame") and child ~= template then
			child:Destroy()
		end
	end
end

local function updateDayFrame(dayFrame, dayNumber: number, currentDay: number, canClaim: boolean)
	local claimButton = dayFrame:FindFirstChild("Claim")
	local titleLabel = dayFrame:FindFirstChild("Title")
	local amountLabel = dayFrame:FindFirstChild("Amount")
	local itemIcon = dayFrame:FindFirstChild("ItemIcon")
	local gearIcon = dayFrame:FindFirstChild("GearIcon")

	if titleLabel then
		titleLabel.Text = "Day " .. dayNumber
	end

	local reward = DailyRewardsData.Rewards[dayNumber]
	if amountLabel and reward then
		amountLabel.Text = formatCash(reward.Cash or 0)
	end

	if itemIcon then
		itemIcon.Visible = reward and reward.Item ~= nil
	end

	if gearIcon then
		if reward and reward.Gear then
			gearIcon.Visible = true
			local gearData = GearsData[reward.Gear]
			if gearData and gearData.ImageId then
				gearIcon.Image = gearData.ImageId
			end
		else
			gearIcon.Visible = false
		end
	end

	if claimButton then
		local claimTitle = claimButton:FindFirstChild("Title")
		if claimTitle then
			if dayNumber < currentDay then
				claimTitle.Text = "Claimed"
				claimButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif dayNumber == currentDay and canClaim then
				claimTitle.Text = "Claim"
				claimButton.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
			else
				claimTitle.Text = "Blocked"
				claimButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end
end

local function populateDays()
	clearDayFrames()

	if not rewardData then
		return
	end

	for i = 1, DailyRewardsData.MaxDays do
		local dayFrame = template:Clone()
		dayFrame.Name = "Day" .. i
		dayFrame.Visible = true
		dayFrame.LayoutOrder = i
		dayFrame.Parent = scrollingFrame

		updateDayFrame(dayFrame, i, rewardData.CurrentDay, rewardData.CanClaim)

		local claimButton = dayFrame:FindFirstChild("Claim")
		if claimButton and i == rewardData.CurrentDay and rewardData.CanClaim then
			claimButton.Activated:Connect(function()
				local claimRemote = RemotesManager:GetRemote("ClaimDailyReward")
				local success = claimRemote:InvokeServer()

				if success then
					SoundManager.Play("PurchasedCoin")
					rewardData.CanClaim = false
					rewardData.LastClaimedTime = os.time()
					rewardData.NextAvailableTime = rewardData.LastClaimedTime + DailyRewardsData.CooldownSeconds
					rewardData.CurrentDay = rewardData.CurrentDay + 1
					if rewardData.CurrentDay > DailyRewardsData.MaxDays then
						rewardData.CurrentDay = 1
					end
					populateDays()
					updateTitleLabel()
				end
			end)
		end
	end
end

local function startTimer()
	if timerConnection then
		task.cancel(timerConnection)
	end

	timerConnection = task.spawn(function()
		while isOpen and rewardData do
			task.wait(1)

			updateTitleLabel()

			if not rewardData.CanClaim then
				local currentTime = os.time()
				if rewardData.NextAvailableTime > 0 and currentTime >= rewardData.NextAvailableTime then
					rewardData.CanClaim = true
					populateDays()
					updateTitleLabel()
				end
			end
		end
	end)
end

local function stopTimer()
	if timerConnection then
		task.cancel(timerConnection)
		timerConnection = nil
	end
end

local function openFrame()
	local actuallyOpen = GUIManager.IsFrameOpen("DailyRewards")
	print("[DailyRewards Client] openFrame called, isOpen:", isOpen, "actuallyOpen:", actuallyOpen)

	if isOpen and not actuallyOpen then
		isOpen = false
	end

	local getDailyRewardsData = RemotesManager:GetRemote("GetDailyRewardsData")
	rewardData = getDailyRewardsData:InvokeServer()
	print("[DailyRewards Client] rewardData:", rewardData)

	if not rewardData then
		print("[DailyRewards Client] No rewardData, returning")
		return
	end

	if isOpen then
		print("[DailyRewards Client] Already open, just updating")
		populateDays()
		updateTitleLabel()
		return
	end

	print("[DailyRewards Client] Opening frame")
	populateDays()
	updateTitleLabel()
	GUIManager.OpenFrame("DailyRewards")
	isOpen = true
	startTimer()
end

local function closeFrame()
	print("[DailyRewards Client] closeFrame called, isOpen:", isOpen)
	if not isOpen then
		return
	end

	stopTimer()
	GUIManager.CloseFrame("DailyRewards")
	isOpen = false

	print("[DailyRewards Client] Firing DailyRewardsClosed")
	local dailyRewardsClosed = RemotesManager:GetRemote("DailyRewardsClosed")
	dailyRewardsClosed:FireServer()
end

local function onDailyRewardAvailable()
	print("[DailyRewards Client] DailyRewardAvailable received!")
	openFrame()
end

function DailyRewardsController.Init()
	GUIManager.RegisterFrame("DailyRewards", dailyRewardsFrame)
end

function DailyRewardsController.Start()
	local dailyRewardAvailable = RemotesManager:GetRemote("DailyRewardAvailable")
	dailyRewardAvailable.OnClientEvent:Connect(onDailyRewardAvailable)
end

function DailyRewardsController.Open()
	openFrame()
end

function DailyRewardsController.Close()
	closeFrame()
end

return DailyRewardsController
