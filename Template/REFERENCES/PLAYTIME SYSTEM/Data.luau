return {
	["Save"] = function(Player, DataStore, OldSession, LastRefresh)
		local SuccessSaving, ErrorSaving = pcall(DataStore.UpdateAsync, DataStore, Player.UserId, function()
			local ClaimedGifts = {}
			for i, v in pairs(Player["ClaimedGifts"]:GetChildren()) do
				table.insert(ClaimedGifts, v.Name)
			end
			return {
				["TotalSession"] = (OldSession + Player.CurrentSession.Value),
				["ClaimedGifts"] = ClaimedGifts,
				["LastRefresh"] = LastRefresh,
			}
		end)
		if not SuccessSaving then
			warn(ErrorSaving)
		else
			print("✅ Updated Gift Datastore")
		end
	end,
	["Get"] = function(Player, DataStore)
		local Success, Data = pcall(DataStore.GetAsync, DataStore, Player.UserId)
		if Success and Data then
			return Data
		else
			return nil
		end
	end,
}
