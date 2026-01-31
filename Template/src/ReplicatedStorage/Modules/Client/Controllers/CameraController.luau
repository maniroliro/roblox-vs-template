local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local CameraController = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local function updateCameraSubject()
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

function CameraController.Init() end

function CameraController.Start()
	local updateCameraRemote = RemotesManager:GetRemote("UpdateCamera")
	updateCameraRemote.OnClientEvent:Connect(updateCameraSubject)
end

return CameraController
