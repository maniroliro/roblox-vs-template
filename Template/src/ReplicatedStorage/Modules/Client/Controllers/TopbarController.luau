local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Icon = require(Modules.Packages.topbarplus)
local GUIManager = require(Modules.Client.Managers.GUIManager)

local TopbarController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local settingsFrame = frames:WaitForChild("Settings")

local settingsIcon = nil

local SETTINGS_IMAGE = "rbxassetid://6031280882" -- Gear icon

function TopbarController.Init()
	GUIManager.RegisterFrame("Settings", settingsFrame)
end

function TopbarController.Start()
	settingsIcon = Icon.new():setImage(SETTINGS_IMAGE):setCaption("Settings"):align("Left")

	settingsIcon.selected:Connect(function()
		GUIManager.OpenFrame("Settings")
	end)

	settingsIcon.deselected:Connect(function()
		GUIManager.CloseFrame("Settings")
	end)

	GUIManager.FrameClosed:Connect(function(name)
		if name == "Settings" and settingsIcon.isSelected then
			settingsIcon:deselect()
		end
	end)

	GUIManager.FrameOpened:Connect(function(name)
		if name ~= "Settings" and settingsIcon.isSelected then
			settingsIcon:deselect()
		end
	end)
end

return TopbarController
