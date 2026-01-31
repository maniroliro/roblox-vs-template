local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Packages.signal)
local UIAnimations = require(ReplicatedStorage.Modules.Client.Utils.UIAnimations)

local GUIManager = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentOpenFrame = nil
local registeredFrames = {}

GUIManager.FrameOpened = Signal.new()
GUIManager.FrameClosed = Signal.new()

local function setupCloseButton(frame: Frame)
	local canvasGroup = frame:FindFirstChild("CanvasGroup")
	if not canvasGroup then
		return
	end

	local top = canvasGroup:FindFirstChild("Top")
	if not top then
		return
	end

	local closeButton = top:FindFirstChild("Close")
	if not closeButton then
		return
	end

	closeButton.Activated:Connect(function()
		for name, registeredFrame in registeredFrames do
			if registeredFrame == frame then
				GUIManager.CloseFrame(name)
				break
			end
		end
	end)
end

function GUIManager.RegisterFrame(name: string, frame: Frame)
	registeredFrames[name] = frame
	frame.Visible = false
	setupCloseButton(frame)
end

function GUIManager.OpenFrame(name: string)
	local frame = registeredFrames[name]
	if not frame then
		return
	end

	if currentOpenFrame and currentOpenFrame ~= name then
		local previousFrame = registeredFrames[currentOpenFrame]
		local previousName = currentOpenFrame
		currentOpenFrame = nil

		UIAnimations.CloseFrame(previousFrame, function()
			GUIManager.FrameClosed:Fire(previousName)
			UIAnimations.OpenFrame(frame)
			currentOpenFrame = name
			GUIManager.FrameOpened:Fire(name)
		end)
	else
		UIAnimations.OpenFrame(frame)
		currentOpenFrame = name
		GUIManager.FrameOpened:Fire(name)
	end
end

function GUIManager.CloseFrame(name: string)
	local frame = registeredFrames[name]
	if not frame then
		return
	end

	UIAnimations.CloseFrame(frame)

	if currentOpenFrame == name then
		currentOpenFrame = nil
	end

	GUIManager.FrameClosed:Fire(name)
end

function GUIManager.CloseCurrentFrame()
	if not currentOpenFrame then
		return
	end
	GUIManager.CloseFrame(currentOpenFrame)
end

function GUIManager.ToggleFrame(name: string)
	if currentOpenFrame == name then
		GUIManager.CloseFrame(name)
	else
		GUIManager.OpenFrame(name)
	end
end

function GUIManager.IsFrameOpen(name: string): boolean
	return currentOpenFrame == name
end

function GUIManager.GetCurrentFrame(): string?
	return currentOpenFrame
end

function GUIManager.Init()
	UIAnimations.Init()
end

function GUIManager.Start()
	local gui = playerGui:WaitForChild("GUI")
	UIAnimations.SetupAllButtons(gui)
end

return GUIManager
