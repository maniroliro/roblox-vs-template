-- services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- modules
local DAILY_REWARD_CONFIG = require(ReplicatedStorage:FindFirstChild("DAILY_REWARD_CONFIG", true))
local SoundController = require(ReplicatedStorage:FindFirstChild("SoundController", true))

-- remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local functionsFolder = remotesFolder:WaitForChild("Functions")
local promptDailyRewardFunction = functionsFolder:WaitForChild("PromptDailyReward")

-- guis
local guisFolder = ReplicatedStorage:WaitForChild("GUIs")
local dayFrameExample, progressBarFrameExample, MarkerImageExample =
	guisFolder:WaitForChild("DayExample"),
	guisFolder:WaitForChild("ProgressBarExample"),
	guisFolder:WaitForChild("MarkerImageExample")

-- player
local localPlayer = Players.LocalPlayer

-- ui
local dailyRewardGui = localPlayer.PlayerGui:WaitForChild("DailyRewardGUI")

local cardsListFrame = dailyRewardGui.CardsList
local progressionFrame = dailyRewardGui.Progression
local claimButton = dailyRewardGui.ClaimButton

local headerLabel = dailyRewardGui.HeaderLabel
local timerLabel = dailyRewardGui.TimerLabel
local streakScoreLabel = dailyRewardGui.StreakScoreLabel
local streakHighscoreLabel = dailyRewardGui.StreakHighscoreLabel

-- values
local TWEEN_SPEED = 1.5
local SCRIPT_LOADED = false

local recentRewardData = nil

local debounce = false
local rewardClaimed = false

-- functions
function FormatNumberToMilitaryTime(number)
	local hours = math.floor(number / 3600)
	local minutes = math.floor((number % 3600) / 60)
	local seconds = math.floor(number % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function FormatSuffix(text, plural)
	return plural and text .. "s" or not plural and text
end

function RefreshGUI(currentDayIndex, isClaimed)
	for _, dayFrame in pairs(cardsListFrame:GetChildren()) do
		if dayFrame:IsA("Frame") then
			local holderFrame = dayFrame.Holder
			local tintFrame = dayFrame.Tint

			local markerImage = progressionFrame:FindFirstChild(dayFrame.Name .. "_Marker")
			local progressionBar = progressionFrame:FindFirstChild(dayFrame.Name .. "_Progress")

			-- defaults
			holderFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
			holderFrame.UIStroke.Color = DAILY_REWARD_CONFIG.STATE_COLORS.UNCLAIMED
			holderFrame.UIStroke.Thickness = 4
			holderFrame.BackShadow.Visible = false

			-- update day frames depending on current day index
			if tonumber(dayFrame.Name) < currentDayIndex then
				tintFrame.Visible = true
				if progressionBar then
					progressionBar.BackgroundColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.CLAIMED
				end
				markerImage.ImageColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.CLAIMED
				markerImage.DayLabel.TextColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.CLAIMED
				markerImage.DayLabel.FontFace = DAILY_REWARD_CONFIG.STATE_FONTS.CLAIMED
			else
				tintFrame.Visible = false
				if progressionBar then
					progressionBar.BackgroundColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.UNCLAIMED
				end
				if tonumber(dayFrame.Name) == currentDayIndex then
					markerImage.ImageColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.CLAIMED
					if isClaimed then
						tintFrame.Visible = true
						markerImage.DayLabel.TextColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.CLAIMED
						markerImage.DayLabel.FontFace = DAILY_REWARD_CONFIG.STATE_FONTS.CLAIMED
					else
						holderFrame.Size = UDim2.new(1, 0, 1, 0)
						holderFrame.UIStroke.Color = DAILY_REWARD_CONFIG.STATE_COLORS.CLAIMED
						holderFrame.UIStroke.Thickness = 6
						holderFrame.BackShadow.Visible = true
						markerImage.DayLabel.TextColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.SELECTED
						markerImage.DayLabel.FontFace = DAILY_REWARD_CONFIG.STATE_FONTS.SELECTED
					end
				else
					markerImage.ImageColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.UNCLAIMED
					markerImage.DayLabel.TextColor3 = DAILY_REWARD_CONFIG.STATE_COLORS.UNCLAIMED
					markerImage.DayLabel.FontFace = DAILY_REWARD_CONFIG.STATE_FONTS.UNCLAIMED
				end
			end
		end
	end
	--print("Completed refreshing daily rewards UI")
end

function ToggleGUI(value)
	debounce = true
	if value then
		-- reset
		timerLabel.Text = ""
		streakScoreLabel.Text = ""
		streakHighscoreLabel.Text = ""
		headerLabel.Position = UDim2.new(0.5, 0, 1.5, 0)
		cardsListFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
		progressionFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
		claimButton.Position = UDim2.new(0.5, 0, 1.5, 0)
		claimButton.Size = UDim2.new(0.25, 0, 0.125, 0)
		dailyRewardGui.Enabled = true
		Lighting.GUI_Background_Blur.Enabled = true
		SoundController.Play("SFX", "UI_Menu_Open")

		-- animations
		local headerAnim = TweenService:Create(
			headerLabel,
			TweenInfo.new(TWEEN_SPEED, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 0.2, 0) }
		)
		headerAnim:Play()
		task.wait(TWEEN_SPEED * 0.25)

		local cardsListAnim = TweenService:Create(
			cardsListFrame,
			TweenInfo.new(TWEEN_SPEED * 0.75, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 0.4, 0) }
		)
		cardsListAnim:Play()
		task.wait(TWEEN_SPEED * 0.1)

		local progressionFrameAnim = TweenService:Create(
			progressionFrame,
			TweenInfo.new(TWEEN_SPEED * 0.75, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 0.625, 0) }
		)
		progressionFrameAnim:Play()
		task.wait(TWEEN_SPEED)

		local claimButtonAnim = TweenService:Create(
			claimButton,
			TweenInfo.new(TWEEN_SPEED * 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 0.85, 0) }
		)
		claimButtonAnim:Play()
		task.wait(TWEEN_SPEED * 0.25)
	else
		-- animations
		local claimButtonAnim = TweenService:Create(
			claimButton,
			TweenInfo.new(TWEEN_SPEED * 0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut),
			{ Size = UDim2.new(0, 0, 0, 0) }
		)
		claimButtonAnim:Play()
		task.wait(TWEEN_SPEED * 0.25)

		SoundController.Play("SFX", "UI_Menu_Close")
		local progressionFrameAnim = TweenService:Create(
			progressionFrame,
			TweenInfo.new(TWEEN_SPEED * 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 1.5, 0) }
		)
		progressionFrameAnim:Play()
		task.wait(TWEEN_SPEED * 0.1)

		local cardsListAnim = TweenService:Create(
			cardsListFrame,
			TweenInfo.new(TWEEN_SPEED * 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 1.5, 0) }
		)
		cardsListAnim:Play()
		task.wait(TWEEN_SPEED * 0.1)

		local headerAnim = TweenService:Create(
			headerLabel,
			TweenInfo.new(TWEEN_SPEED * 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
			{ Position = UDim2.new(0.5, 0, 1.5, 0) }
		)
		headerAnim:Play()
		task.wait(TWEEN_SPEED * 0.5)
		dailyRewardGui.Enabled = false
		Lighting.GUI_Background_Blur.Enabled = false
	end
	debounce = false
end

-- claim
claimButton.MouseButton1Click:Connect(function()
	if debounce then
		return
	end
	SoundController.Play("SFX", "SFX_Reward_Claimed")
	RefreshGUI(recentRewardData.CurrentDay, true)
	ToggleGUI(false)
	recentRewardData = nil
	rewardClaimed = true
	print("Daily reward claimed: ", localPlayer.Name)
end)
claimButton:AddTag("HoverScaleEffect")

-- prompt
promptDailyRewardFunction.OnClientInvoke = function(playerRewardData)
	repeat
		task.wait(0.5)
	until SCRIPT_LOADED

	rewardClaimed = false
	recentRewardData = {}
	for name, value in pairs(playerRewardData) do
		recentRewardData[tostring(name)] = value
	end

	print("Prompted daily reward (Day " .. tostring(recentRewardData.CurrentDay) .. "): ", localPlayer.Name)
	RefreshGUI(recentRewardData.CurrentDay)
	ToggleGUI(true)

	if recentRewardData.CurrentDailyRewardStreak > 0 then
		streakScoreLabel.Text = "Current Streak: "
			.. tostring(recentRewardData.CurrentDailyRewardStreak)
			.. " "
			.. FormatSuffix("Day", recentRewardData.CurrentDailyRewardStreak > 1)
	end
	if recentRewardData.LongestDailyRewardStreak > 0 then
		streakHighscoreLabel.Text = "Longest Streak: "
			.. tostring(recentRewardData.LongestDailyRewardStreak)
			.. " "
			.. FormatSuffix("Day", recentRewardData.LongestDailyRewardStreak > 1)
	end

	while true do
		if rewardClaimed then
			timerLabel.Text = ""
			break
		end
		local timeLeftInSeconds = recentRewardData.NextDailyRewardTime - os.time()
		timerLabel.Text = "Time left to claim: " .. FormatNumberToMilitaryTime(timeLeftInSeconds)
		task.wait(1)
	end
end

-- initialize daily reward gui
for i = 1, DAILY_REWARD_CONFIG.MAX_DAYS do
	local dayFrame = dayFrameExample:Clone()
	local holderFrame = dayFrame.Holder
	dayFrame.Name = i
	holderFrame.Info.RewardLabel.Text = DAILY_REWARD_CONFIG.DAY_PRESETS["Day " .. i].reward_text
	holderFrame.Info.RewardImage.Image = DAILY_REWARD_CONFIG.DAY_PRESETS["Day " .. i].reward_image_ID
	holderFrame.Info.Visible = true
	dayFrame.Parent = cardsListFrame

	local markerImage = MarkerImageExample:Clone()
	markerImage.Name = i .. "_Marker"
	markerImage.Visible = true
	markerImage.Parent = progressionFrame
	markerImage.DayLabel.Text = "Day " .. i

	if i < DAILY_REWARD_CONFIG.MAX_DAYS then
		local progressBar = progressBarFrameExample:Clone()
		progressBar.Name = i .. "_Progress"
		progressBar.Visible = true
		progressBar.Parent = progressionFrame
	end
end
SCRIPT_LOADED = true
