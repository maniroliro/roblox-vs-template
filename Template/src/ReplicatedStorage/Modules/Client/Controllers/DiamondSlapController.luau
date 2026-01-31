local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local RemotesManager = require(Modules.Shared.Managers.RemotesManager)

local DiamondSlapController = {}

local bigBlock = workspace:WaitForChild("BigBlock")
local countdownLabel =
	workspace:WaitForChild("Countdown"):WaitForChild("Header"):WaitForChild("SurfaceGui"):WaitForChild("TextLabel")

local isUnlocked = false
local timeRemaining = nil
local countdownConnection = nil

local function formatTime(seconds: number): string
	if seconds <= 0 then
		return "UNLOCKED!"
	end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)

	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

local function startLocalCountdown()
	if countdownConnection then
		return
	end

	countdownConnection = task.spawn(function()
		while timeRemaining and timeRemaining > 0 do
			countdownLabel.Text = formatTime(timeRemaining)
			task.wait(1)
			timeRemaining = timeRemaining - 1
		end

		if timeRemaining and timeRemaining <= 0 then
			countdownLabel.Text = "UNLOCKED!"
		end
	end)
end

local function onCountdownReceived(time: number)
	timeRemaining = time

	if time <= 0 then
		countdownLabel.Text = "UNLOCKED!"
		isUnlocked = true
		bigBlock.CanCollide = false
	else
		startLocalCountdown()
	end
end

local function unlockBlock()
	if isUnlocked then
		return
	end

	isUnlocked = true
	timeRemaining = 0
	countdownLabel.Text = "UNLOCKED!"
	bigBlock.CanCollide = false
end

local function onCollected()
	countdownLabel.Text = "COLLECTED!"
	isUnlocked = true
	bigBlock.CanCollide = false
end

function DiamondSlapController.Init() end

function DiamondSlapController.Start()
	RemotesManager.OnEvent("DiamondSlapCountdown", onCountdownReceived)
	RemotesManager.OnEvent("DiamondSlapUnlocked", unlockBlock)
	RemotesManager.OnEvent("DiamondSlapCollected", onCollected)
end

return DiamondSlapController
