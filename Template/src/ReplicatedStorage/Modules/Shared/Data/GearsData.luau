local timeDuration = 60

return {
	BloxyCola = {
		Name = "Bloxy Cola",
		Description = "Gives you a boost in jump power of 15%.",
		Rarity = "Common",
		Duration = timeDuration,
		ImageId = "rbxassetid://118251543312788",
		Effects = {
			JumpPowerMultiplier = 1.15,
		},
		Price = 1500,
		ActivatedCallback = function()
			task.wait(5)
		end,
	},

	TeddyBear = {
		Name = "Teddy Bear",
		Description = "A cute teddy bear companion.",
		Rarity = "Common",
		Duration = timeDuration,
		ImageId = "rbxassetid://123256625386477",
		Effects = {},
		Price = 2000,
		ActivatedCallback = function()
			task.wait(0.5)
		end,
	},

	Cheezburger = {
		Name = "Cheezburger",
		Description = "Gives you a boost in jump power of 25%.",
		Rarity = "Epic",
		Duration = timeDuration,
		ImageId = "rbxassetid://96501762829446",
		Effects = {
			JumpPowerMultiplier = 1.25,
		},
		Price = 4500,
		ActivatedCallback = function()
			task.wait(1.2)
		end,
	},

	Pizza = {
		Name = "Pizza",
		Description = "Gives you a boost in jump power of 30%.",
		Rarity = "Epic",
		Duration = timeDuration,
		ImageId = "rbxassetid://85576185660819",
		Effects = {
			JumpPowerMultiplier = 1.30,
		},
		Price = 10000,
		ActivatedCallback = function()
			task.wait(1.2)
		end,
	},

	PirateJuice = {
		Name = "Pirate Juice",
		Description = "Gives you a boost in jump power of 40%.",
		Rarity = "Legendary",
		Duration = timeDuration,
		ImageId = "rbxassetid://102241752393632",
		Effects = {
			JumpPowerMultiplier = 1.40,
		},
		Price = 20000,
		ActivatedCallback = function()
			task.wait(5)
		end,
	},
}
