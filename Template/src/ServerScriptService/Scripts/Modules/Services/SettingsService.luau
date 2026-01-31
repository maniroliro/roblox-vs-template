local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Scripts.Modules
local PlayerDataManager = require(Modules.Managers.PlayerDataManager)
local RemotesManager = require(ReplicatedStorage.Modules.Shared.Managers.RemotesManager)

local SettingsService = {}

local VALID_SETTINGS = {
	HighQuality = "boolean",
	Music = "boolean",
	SFX = "boolean",
}

local function onSaveSettings(player: Player, settingName: string, value: any)
	local expectedType = VALID_SETTINGS[settingName]
	if not expectedType then
		return false
	end

	if typeof(value) ~= expectedType then
		return false
	end

	local data = PlayerDataManager.GetData(player)
	if not data then
		return false
	end

	if not data.Settings then
		data.Settings = {}
	end

	data.Settings[settingName] = value
	PlayerDataManager.UpdateClient(player)

	return true
end

function SettingsService.Init() end

function SettingsService.Start()
	local saveSettingsRemote = RemotesManager:GetRemote("SaveSettings")
	if saveSettingsRemote then
		saveSettingsRemote.OnServerInvoke = onSaveSettings
	end
end

return SettingsService
