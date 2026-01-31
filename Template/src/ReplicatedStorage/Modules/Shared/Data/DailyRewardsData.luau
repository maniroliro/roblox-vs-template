local SECONDS_IN_DAY = 86400

return {
	MaxDays = 7,
	CooldownSeconds = SECONDS_IN_DAY,
	ResetStreakIfMissed = false,

	Rewards = {
		[1] = { Cash = 500 },
		[2] = { Cash = 1500 },
		[3] = { Cash = 2000, Gear = "BloxyCola" },
		[4] = { Cash = 2500 },
		[5] = { Cash = 3000, Gear = "Cheezburger" },
		[6] = { Cash = 3500 },
		[7] = { Cash = 7000, Item = "GravityCoil" },
	},
}
