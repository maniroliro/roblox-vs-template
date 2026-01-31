local H, R = game:GetService("HttpService"), game:GetService("ReflectionService")

local TARGET --=

local function getProps(inst)
	local d = { ClassName = inst.ClassName, Name = inst.Name }
	for _, p in ipairs(R:GetPropertiesOfClass(inst.ClassName)) do
		local n = p.Name
		local c = p.Display and p.Display.Category
		local dep = p.Display and p.Display.DeprecationMessage

		if
			not (n:match("^Absolute") or n == "Archivable" or n == "Parent" or n == "Name" or dep)
			and (c == "Data" or c == "Appearance" or c == "Layout")
		then
			local o, v = pcall(function()
				return inst[n]
			end)
			if o and v ~= nil then
				local t = typeof(v)
				if t == "string" or t == "number" or t == "boolean" then
					d[n] = v
				elseif t == "UDim2" then
					d[n] = string.format("{%s,%s},{%s,%s}", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
				elseif t == "UDim" then
					d[n] = string.format("%s,%s", v.Scale, v.Offset)
				elseif t == "Color3" then
					d[n] = string.format("%d,%d,%d", v.R * 255, v.G * 255, v.B * 255)
				elseif t == "Vector2" then
					d[n] = string.format("%s,%s", v.X, v.Y)
				elseif t == "EnumItem" then
					d[n] = tostring(v)
				elseif t == "Rect" then
					d[n] = string.format("%s,%s,%s,%s", v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
				elseif t == "Font" then
					d[n] = string.format("%s,%s,%s", v.Family, tostring(v.Weight), tostring(v.Style))
				end
			end
		end
	end
	return d
end

local function serialize(inst, depth)
	depth = depth or 0
	if depth > 15 then
		return { _max = true }
	end

	local d = getProps(inst)
	local ch = inst:GetChildren()

	if #ch > 0 then
		d.Children = {}
		for _, x in ipairs(ch) do
			table.insert(d.Children, serialize(x, depth + 1))
		end
	end
	return d
end

print(H:JSONEncode(serialize(TARGET)))
