local MultipliersData = {}

MultipliersData.Jump = {
	{ Multiplier = 2, ProductId = 3490478620 },
	{ Multiplier = 3, ProductId = 3490479776 },
	{ Multiplier = 4, ProductId = 3490480200 },
	{ Multiplier = 5, ProductId = 3490480370 },
	{ Multiplier = 6, ProductId = 3490480610 },
	{ Multiplier = 7, ProductId = 3490480874 },
	{ Multiplier = 8, ProductId = 3490481093 },
	{ Multiplier = 9, ProductId = 3490481300 },
	{ Multiplier = 10, ProductId = 3490481596 },
	{ Multiplier = 11, ProductId = 3490481829 },
}

MultipliersData.Speed = {
	{ Multiplier = 2, ProductId = 3490486824 },
	{ Multiplier = 3, ProductId = 3490487063 },
	{ Multiplier = 4, ProductId = 3490487292 },
	{ Multiplier = 5, ProductId = 3490487495 },
	{ Multiplier = 6, ProductId = 3490488088 },
	{ Multiplier = 7, ProductId = 3490488357 },
	{ Multiplier = 8, ProductId = 3490488666 },
	{ Multiplier = 9, ProductId = 3490488867 },
	{ Multiplier = 10, ProductId = 3490489081 },
	{ Multiplier = 11, ProductId = 3490489309 },
}

function MultipliersData.GetNextMultiplier(statType: string, currentMultiplier: number)
	local data = MultipliersData[statType]
	if not data then
		return nil
	end
	
	for _, entry in data do
		if entry.Multiplier > currentMultiplier then
			return entry
		end
	end
	
	return nil
end

function MultipliersData.GetMultiplierByProductId(productId: number): (string?, number?)
	for _, entry in MultipliersData.Jump do
		if entry.ProductId == productId then
			return "Jump", entry.Multiplier
		end
	end
	
	for _, entry in MultipliersData.Speed do
		if entry.ProductId == productId then
			return "Speed", entry.Multiplier
		end
	end
	
	return nil, nil
end

return MultipliersData
