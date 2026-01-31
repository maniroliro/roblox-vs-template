local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Packages.signal)

local QualityManager = {}

QualityManager.HighQualityChanged = Signal.new()

local highQualityEnabled = true

function QualityManager.Init() end

function QualityManager.Start() end

function QualityManager.SetHighQuality(enabled: boolean)
	if highQualityEnabled == enabled then
		return
	end

	highQualityEnabled = enabled
	QualityManager.HighQualityChanged:Fire(enabled)
end

function QualityManager.IsHighQuality(): boolean
	return highQualityEnabled
end

return QualityManager
