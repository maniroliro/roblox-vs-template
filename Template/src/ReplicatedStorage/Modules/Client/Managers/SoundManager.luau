local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundsData = require(ReplicatedStorage.Modules.Client.Data.SoundsData)

local SoundManager = {}

local sfxEnabled = true
local musicEnabled = true
local sfxVolume = 1
local musicVolume = 0.5

local soundInstances = {}
local backgroundMusic = nil

local function getOrCreateSound(soundName: string): Sound?
	if soundInstances[soundName] then
		return soundInstances[soundName]
	end

	local soundId = SoundsData[soundName]
	if not soundId then
		return nil
	end

	local sound = Instance.new("Sound")
	sound.Name = soundName
	sound.SoundId = soundId
	sound.Parent = SoundService

	soundInstances[soundName] = sound
	return sound
end

function SoundManager.Init()
	local musicId = SoundsData.BackgroundMusic
	if musicId then
		backgroundMusic = Instance.new("Sound")
		backgroundMusic.Name = "BackgroundMusic"
		backgroundMusic.SoundId = musicId
		backgroundMusic.Volume = musicVolume
		backgroundMusic.Looped = true
		backgroundMusic.Parent = SoundService
	end
end

function SoundManager.Start()
	if backgroundMusic and musicEnabled then
		backgroundMusic:Play()
	end
end

function SoundManager.Play(soundName: string)
	if not sfxEnabled then
		return
	end

	local sound = getOrCreateSound(soundName)
	if not sound then
		return
	end

	sound.Volume = sfxVolume
	sound:Play()
end

function SoundManager.PlayOneShot(soundName: string, volume: number?)
	if not sfxEnabled then
		return
	end

	local soundId = SoundsData[soundName]
	if not soundId then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = (volume or 1) * sfxVolume
	sound.Parent = SoundService
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
end

function SoundManager.SetSFXEnabled(enabled: boolean)
	sfxEnabled = enabled
end

function SoundManager.SetMusicEnabled(enabled: boolean)
	musicEnabled = enabled

	if backgroundMusic then
		if enabled then
			backgroundMusic.Volume = musicVolume
		else
			backgroundMusic.Volume = 0
		end
	end
end

function SoundManager.SetSFXVolume(volume: number)
	sfxVolume = math.clamp(volume, 0, 1)
end

function SoundManager.SetMusicVolume(volume: number)
	musicVolume = math.clamp(volume, 0, 1)

	if backgroundMusic then
		backgroundMusic.Volume = musicVolume
	end
end

function SoundManager.IsSFXEnabled(): boolean
	return sfxEnabled
end

function SoundManager.IsMusicEnabled(): boolean
	return musicEnabled
end

function SoundManager.GetSFXVolume(): number
	return sfxVolume
end

function SoundManager.GetMusicVolume(): number
	return musicVolume
end

return SoundManager
