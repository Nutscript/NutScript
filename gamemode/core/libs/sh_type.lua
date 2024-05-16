
nut.type = nut.type or {}
nut.type.map = nut.type.map or {}
nut.type.types = nut.type.types or {}
nut.type.bitsum = nut.type.bitsum  or 0

-- _G.type but for nut.type
function nut.type.type(...)
	local value = select(1, ...)
	value = (istable(value) and value == nut.type) and select(2, ...) or value

	if (istable(value)) then
		if (value.nutType and nut.type.map[value.nutType]) then
			return nut.type.types[nut.type.map[value.nutType]].name
		end

		for _, v in ipairs(nut.type.types) do
			if (v.assertion and v.assertion(value)) then
				return v.name
			end
		end
	end

	return type(value)
end

function nut.type.add(name, assertion)
	if (nut.type[name]) then
		nut.type.types[nut.type.map[name]].assertion = assertion

		return
	end

	if (!isstring(name)) then
		error("nut.type.add expected string for #1 input but got: " .. type(name))
	end

	if (assertion and !isfunction(assertion)) then
		error("nut.type.add expected function for #2 input but got: " .. type(assertion))
	end

	local pow2 = 2 ^ (#nut.type.types + 1)

	nut.type.bitsum = bit.bor(nut.type.bitsum, pow2)

	nut.type[pow2] = name
	nut.type[name] = pow2

	nut.type.map[pow2] = table.insert(nut.type.types, {assertion = assertion, name = name})
	nut.type.map[name] = nut.type.map[pow2]
end

function nut.type.assert(nutType, value)
	if (nut.type.map[nutType]) then
		nutType = nut.type.types[nut.type.map[nutType]]

		if (nutType.assertion) then
			return nutType.assertion(value)
		else
			return true
		end
	end
end

function nut.type.getName(nutType)
	if (nut.type.map[nutType]) then
		nutType = nut.type.types[nut.type.map[nutType]]

		if (nutType.name) then
			return nutType.name
		end
	-- could be a 'bit.bor(x, nut.type.optional)', let's see if it is
	elseif (nut.type.isOptional(nutType)) then
		local xor = bit.bxor(nutType, nut.type.optional)

		if (xor) then
			return nut.type.getName(xor)
		end
	end
end

nut.type = setmetatable(nut.type, {__call = nut.type.type})

nut.type.add("optional")
function nut.type.isOptional(num)
	return isnumber(num) and bit.band(num, nut.type.optional) == nut.type.optional
end

nut.type.add("string", function(value) return isstring(value) end)
nut.type.add("number", function(value) return isnumber(tonumber(value)) end)
nut.type.add("bool", function(value) return isbool(value) end)
nut.type.add("steamid64", function(value) return isstring(value) and string.format("%017.17s", value) == value end)
nut.type.add("player", function(value)
	if (isentity(value)) then
		return value:IsPlayer() and value
	end

	if (isstring(value)) then
		return nut.util.findPlayer(value)
	end
end)
