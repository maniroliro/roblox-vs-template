return function()
	local PlayersService = game:GetService("Players")
	local function OnTick()
		local function GetValid()
			local x = {}
			for i, v in pairs(PlayersService:GetPlayers()) do
				local Session = v:FindFirstChild("CurrentSession") or nil
				if typeof(Session) ~= "nil" then
					table.insert(x, Session)
				end
			end
			return x
		end
		local Valid = GetValid()
		for i, v in pairs(Valid) do
			v.Value += 1
		end
	end
	spawn(function()
		while true do
			task.wait(1)
			OnTick()
		end
	end)
end
