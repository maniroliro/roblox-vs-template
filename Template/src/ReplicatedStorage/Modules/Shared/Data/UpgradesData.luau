local UpgradesData = {
	CashMultiplier = {
		[2] = {
			Multiplier = 1.25,
			Price = 4500,
		},
		[3] = {
			Multiplier = 1.5,
			Price = 9500,
		},
		[4] = {
			Multiplier = 1.75,
			Price = 15000,
		},
		[5] = {
			Multiplier = 2,
			Price = 30000,
		},
	},

	SpeedMultiplier = {
		[2] = {
			Multiplier = 1.25,
			Price = 4500,
		},
		[3] = {
			Multiplier = 1.5,
			Price = 9500,
		},
		[4] = {
			Multiplier = 1.75,
			Price = 15000,
		},
		[5] = {
			Multiplier = 2,
			Price = 30000,
		},
	},

	JumpMultiplier = {
		[2] = {
			Multiplier = 1.25,
			Price = 4500,
		},
		[3] = {
			Multiplier = 1.5,
			Price = 9500,
		},
		[4] = {
			Multiplier = 1.75,
			Price = 15000,
		},
		[5] = {
			Multiplier = 2,
			Price = 30000,
		},
	},
}

function UpgradesData.GetMultiplier(upgradeType: string, level: number): number
	if level <= 1 then
		return 1
	end

	local upgradeData = UpgradesData[upgradeType]
	if not upgradeData then
		return 1
	end

	local levelData = upgradeData[level]
	if not levelData then
		return 1
	end

	return levelData.Multiplier
end

function UpgradesData.GetMaxLevel(upgradeType: string): number
	local upgradeData = UpgradesData[upgradeType]
	if not upgradeData then
		return 1
	end

	local maxLevel = 1
	for level, _ in upgradeData do
		if level > maxLevel then
			maxLevel = level
		end
	end

	return maxLevel
end

function UpgradesData.GetNextLevelData(upgradeType: string, currentLevel: number)
	local upgradeData = UpgradesData[upgradeType]
	if not upgradeData then
		return nil
	end

	return upgradeData[currentLevel + 1]
end

return UpgradesData
