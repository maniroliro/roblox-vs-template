local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Trove = require(Modules.Packages.trove)
local SoundManager = require(Modules.Client.Managers.SoundManager)
local PlayerDataManager = require(Modules.Client.Managers.PlayerDataManager)
local QualityManager = require(Modules.Client.Managers.QualityManager)
local RemotesManager = require(Modules.Shared.Managers.RemotesManager)

local SettingsController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("GUI")
local frames = gui:WaitForChild("Frames")
local settingsFrame = frames:WaitForChild("Settings")
local scrollingFrame = settingsFrame:WaitForChild("ScrollingFrame")

local assets = ReplicatedStorage:WaitForChild("Assets")
local uiAssets = assets:WaitForChild("UI")
local settingsTemplates = uiAssets:WaitForChild("Settings")
local onTemplate = settingsTemplates:WaitForChild("ON")
local offTemplate = settingsTemplates:WaitForChild("OFF")

local OPTIONS = {
	"HighQuality",
	"Music",
	"SFX",
}

local settingsState = {}
local trove = Trove.new()
local saveSettingsRemote = nil

local function saveSettingToServer(optionName, value)
	if saveSettingsRemote then
		task.spawn(function()
			saveSettingsRemote:InvokeServer(optionName, value)
		end)
	end
end

local function setOptionVisual(optionFrame, isOn)
	local onButton = optionFrame:FindFirstChild("BoolON")
	local offButton = optionFrame:FindFirstChild("BoolOFF")

	if onButton and offButton then
		onButton.Visible = isOn
		offButton.Visible = not isOn
	end
end

local function toggleOption(optionName)
	settingsState[optionName] = not settingsState[optionName]
	local optionFrame = scrollingFrame:FindFirstChild(optionName)

	if optionFrame then
		setOptionVisual(optionFrame, settingsState[optionName])
	end

	SettingsController.OnSettingChanged(optionName, settingsState[optionName])
end

local function setupOptionButton(optionFrame, optionName)
	local originalBool = optionFrame:FindFirstChild("Bool")

	if originalBool then
		originalBool:Destroy()
	end

	local onButton = onTemplate:Clone()
	onButton.Name = "BoolON"
	onButton.Parent = optionFrame

	local offButton = offTemplate:Clone()
	offButton.Name = "BoolOFF"
	offButton.Parent = optionFrame

	trove:Connect(onButton.Activated, function()
		toggleOption(optionName)
	end)

	trove:Connect(offButton.Activated, function()
		toggleOption(optionName)
	end)

	settingsState[optionName] = true
	setOptionVisual(optionFrame, true)
end

function SettingsController.OnSettingChanged(optionName, isOn)
	saveSettingToServer(optionName, isOn)

	if optionName == "SFX" then
		SoundManager.SetSFXEnabled(isOn)
	elseif optionName == "Music" then
		SoundManager.SetMusicEnabled(isOn)
	elseif optionName == "HighQuality" then
		QualityManager.SetHighQuality(isOn)
	end
end

function SettingsController.GetSetting(optionName)
	return settingsState[optionName]
end

function SettingsController.SetSetting(optionName, value)
	if settingsState[optionName] == value then
		return
	end

	settingsState[optionName] = value
	local optionFrame = scrollingFrame:FindFirstChild(optionName)

	if optionFrame then
		setOptionVisual(optionFrame, value)
	end

	SettingsController.OnSettingChanged(optionName, value)
end

function SettingsController.Init()
	saveSettingsRemote = RemotesManager:GetRemote("SaveSettings")
end

function SettingsController.Start()
	local data = PlayerDataManager.WaitForData()
	local savedSettings = data and data.Settings or {}

	for _, optionName in OPTIONS do
		local optionFrame = scrollingFrame:FindFirstChild(optionName)

		if optionFrame then
			setupOptionButton(optionFrame, optionName)

			local savedValue = savedSettings[optionName]
			if savedValue ~= nil then
				settingsState[optionName] = savedValue
				setOptionVisual(optionFrame, savedValue)

				if optionName == "SFX" then
					SoundManager.SetSFXEnabled(savedValue)
				elseif optionName == "Music" then
					SoundManager.SetMusicEnabled(savedValue)
				elseif optionName == "HighQuality" then
					QualityManager.SetHighQuality(savedValue)
				end
			end
		end
	end
end

return SettingsController
