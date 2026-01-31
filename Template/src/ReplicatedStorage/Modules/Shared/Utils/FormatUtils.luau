local FormatUtils = {}

function FormatUtils.FormatNumber(number: number): string
	local formatted = tostring(math.floor(number))
	local k
	while true do
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

function FormatUtils.FormatCash(amount: number): string
	return "$" .. FormatUtils.FormatNumber(amount)
end

return FormatUtils
