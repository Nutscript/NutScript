
nut.type = nut.type or {}
nut.type.map = nut.type.map or {}
nut.type.types = nut.type.types or {}
nut.type.bitsum = nut.type.bitsum  or 0

-- _G.type but for nut.type
function nut.type.type(...)
	local value = select(1, ...)

	if (istable(value) and value == nut.type) then
		value = select(2, ...)
	end

	if (istable(value)) then
		if (value.nutType) then
			return value.nutType
		end
	end

	-- basic types (strings, numbers, bools) are early in the bit values, go through the types list backwards to parse complex types first
	-- as they could use isstring, isnumber, isbool calls to narrow the assertion and give useful returns
	for i = #nut.type.types, 1, -1 do
		local v = nut.type.types[i]
		if (v.assertion and v.assertion(value)) then
			return nut.type[v.name]
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

	local bitPosition = 1
	while (bitPosition <= nut.type.bitsum) do
		bitPosition = bit.lshift(bitPosition, 1)
	end

	nut.type.bitsum = bit.bor(nut.type.bitsum, bitPosition)

	nut.type[bitPosition] = name
	nut.type[name] = bitPosition

	nut.type.map[bitPosition] = #nut.type.types + 1
	nut.type.map[name] = nut.type.map[bitPosition]

	table.insert(nut.type.types, {assertion = assertion, name = name})
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

function nut.type.getMultiple(nutType)
	local operands = {}

	for i = 0, 31 do
		if bit.band(nutType, bit.lshift(1, i)) > 0 then
			operands[#operands + 1] = bit.lshift(1, i)
		end
	end

	return operands
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
	-- could be multiple types, lets see if it is
	elseif (isnumber(nutType)) then
		local types = nut.type.getMultiple(nutType)

		if (#types > 0) then
			local typeNames = {}

			for i, v in ipairs(types) do
				table.insert(typeNames, nut.type.getName(v))
			end

			return table.concat(typeNames, "|")
		end
	elseif (isstring(nutType)) then
		return nutType
	end
end

nut.type = setmetatable(nut.type, {__call = nut.type.type})

nut.type.add("optional")
function nut.type.isOptional(num)
	return isnumber(num) and bit.band(num, nut.type.optional) == nut.type.optional
end

-- may move this kind of parsing/searching through values to the commands or util library instead, and reference it there

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
nut.type.add("character", function(value)
	if (istable(value)) then
		return getmetatable(value) == nut.meta.character and value
	end

	if (isentity(value)) then
		return value.getChar and value:getChar()
	end

	if (isstring(value)) then
		local client = nut.util.findPlayer(value)

		if (client) then
			return client:getChar()
		end

		for _, v in pairs(nut.char.loaded) do
			if (nut.util.stringMatches(v:getName(), value)) then
				return v
			end
		end
	end
end)
nut.type.add("item", function(value)
	if (istable(value)) then
		return value.isItem and value
	end

	if (isentity(value)) then
		if (value.getItemTable) then
			return nut.item.instances[value:getItemID()]
		end
	end

	if (isstring(value)) then
		if (nut.item.list[value]) then
			return nut.item.list[value]
		end
	end

	if (isnumber(tonumber(value))) then
		if (nut.item.instances[tonumber(value)]) then
			return nut.faction.instances[tonumber(value)]
		end
	end
end)
nut.type.add("faction", function(value)
	if (istable(value)) then
		if (value.uniqueID and nut.faction.teams[value.uniqueID]) then
			return nut.faction.teams[value.uniqueID]
		end

		if (value.getFaction) then
			return nut.faction.indices[value:getFaction()]
		end
	end

	if (isentity(value)) then
		if (value.Team) then
			return nut.faction.indices[value:Team()]
		end
	end

	if (isstring(value)) then
		if (nut.faction.teams[value]) then
			return nut.faction.teams[value]
		end

		for _, v in pairs(nut.faction.indices) do
			if (nut.util.stringMatches(v.name, value)) then
				return v
			end
		end

		local client = nut.util.findPlayer(value)

		if (client) then
			return nut.faction.indices[client:Team()]
		end
	end

	if (isnumber(tonumber(value))) then
		if (nut.faction.indices[tonumber(value)]) then
			return nut.faction.indices[tonumber(value)]
		end
	end
end)
nut.type.add("class", function(value)
	if (istable(value)) then
		if (value.getClass) then
			return nut.class.list[value:getClass()]
		end
	end

	if (isentity(value)) then
		if (value.getChar) then
			return nut.class.list[value:getChar():getClass()]
		end
	end

	if (isstring(value)) then
		for _, v in pairs(nut.class.list) do
			if (nut.util.stringMatches(L(v.name, client), value)) then
				return v
			end
		end

		local client = nut.util.findPlayer(value)

		if (client) then
			return nut.class.list[client:getChar():getClass()]
		end
	end

	if (isnumber(tonumber(value))) then
		if (nut.class.list[tonumber(value)]) then
			return nut.class.list[tonumber(value)]
		end
	end
end)
