return {
	Cash = 0,
	Wins = 0,
	RobuxSpent = 0,

	Map = {
		["67Blue"] = {
			Completed = false,
			TimesCompleted = 0,
			CheckpointReached = 0,
			LastCheckpoint = 0,
		},
		["67Red"] = {
			Completed = false,
			TimesCompleted = 0,
			CheckpointReached = 0,
			LastCheckpoint = 0,
		},
		["67Purple"] = {
			Completed = false,
			TimesCompleted = 0,
			CheckpointReached = 0,
			LastCheckpoint = 0,
		},
		["67Green"] = {
			Completed = false,
			TimesCompleted = 0,
			CheckpointReached = 0,
			LastCheckpoint = 0,
		},
	},

	LastMapPlayed = "",
	CurrentCheckpoint = 0,

	DailyRewards = {
		CurrentDay = 1,
		LastClaimedTime = 0,
		CurrentStreak = 0,
		LongestStreak = 0,
	},

	FreeSkips = 3,

	Gears = {},

	Settings = {
		SFXVolume = 0.5,
		MusicVolume = 0.5,
		HighQuality = true,
		Music = true,
		SFX = true,
	},

	UpgradesLevel = {
		CashMultiplier = 1,
		SpeedMultiplier = 1,
		JumpMultiplier = 1,
	},

	RobuxMultipliers = {
		Jump = 1,
		Speed = 1,
	},

	Playtime = {
		TotalSeconds = 0,
		ClaimedGifts = {},
		LastReset = 0,
	},

	FirstJoinTime = 0,
	CollectedDiamondSlap = false,
}
