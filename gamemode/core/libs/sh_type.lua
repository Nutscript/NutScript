
nut.type = nut.type or {}
nut.type.list = nut.type.list or {}

nut.type.ors = {}
nut.type.ands = {}

function nut.type.type(...)
	local value = select(1, ...)

	if (istable(value) and value == nut.type) then
		value = select(2, ...)
	end

	if (istable(value) and value.nutType) then
		return value.nutType
	end

	for k in pairs(nut.type.list) do
		if (nut.type.assert(k, value)) then
			return k
		end
	end

	return type(value)
end

function nut.type.add(name, assertion)
	if (!isstring(name)) then
		error("nut.type.add expected string for #1 input but got: " .. type(name))
	end

	if (!isfunction(assertion)) then
		error("nut.type.add(\"" .. name .. "\") expected function for #2 input but got: " .. type(assertion))
	end

	nut.type.list[name] = {assertion = assertion}
	nut.type[name] = name
end

function nut.type.addResolve(name, resolve)
	if (!isstring(name)) then
		error("nut.type.addResolve expected string for #1 input but got: " .. type(name))
	end

	if (!isfunction(resolve)) then
		error("nut.type.addResolve(\"" .. name .. "\") expected function for #2 input but got: " .. type(assertion))
	end

	nut.type.list[name].resolve = resolve
end

function nut.type.assert(nutType, value)
	-- if it's a function then it's an or/and func, we run it now
	if (isfunction(nutType)) then
		return nutType(value)
	end

	return nut.type.list[nutType] and nut.type.list[nutType].assertion(value)
end

function nut.type.resolve(nutType, value)
	local resolve, failString

	-- if it's a function then it's an or/and func, we'll have to resolve each type see what succeeds
	if (isfunction(nutType)) then
		local types = nut.type.ors[nutType] or nut.type.ands[nutType]

		for _, v in ipairs(types) do
			if (nut.type.list[v].resolve) then
				resolve, failString = nut.type.list[v].resolve(value)

				if (resolve) then
					return resolve, failString
				end
			end
		end
	end

	if (nut.type.list[nutType] and nut.type.list[nutType].resolve) then
		resolve, failString = nut.type.list[nutType].resolve(value)
	end

	return resolve, failString
end

function nut.type.tor(...)
	local types = {...}

	local func = function(value)
		for _, nutType in ipairs(types) do
			if (isfunction(nutType)) then
				if (nutType(value)) then
					return true
				end
			else
				if (nut.type.assert(nutType, value)) then
					return true
				end
			end
		end

		return false
	end

	nut.type.ors[func] = types

	return func
end

function nut.type.tand(...)
	local types = {...}

	local func = function(value)
		for _, nutType in ipairs(types) do
			if (isfunction(nutType)) then
				if (!nutType(value)) then
					return false
				end
			else
				if (!nut.type.assert(nutType, value)) then
					return false
				end
			end
		end

		return true
	end

	nut.type.ands[func] = types

	return func
end

function nut.type.getMultiple(nutType)
	if (isfunction(nutType)) then
		return table.Copy(nut.type.ors[nutType]) or table.Copy(nut.type.ands[nutType])
	end

	if (isstring(nutType)) then
		return {nutType}
	end
end

function nut.type.getName(nutType)
	if (isstring(nutType) and nut.type.list[nutType]) then
		return nutType
	end
end

nut.type = setmetatable(nut.type, {__call = nut.type.type})

-- do type definitions
nut.type.add("optional", function(value) return (value == "") end)
nut.type.add("string", function(value) return (isstring(value)) end)
nut.type.add("number", function(value) return (isnumber(value)) end)
nut.type.add("bool", function(value) return (isbool(value)) end)
nut.type.add("steamid64", function(value) return (isstring(value) and string.format("%017.17s", value) == value) end)
nut.type.add("player", function(value) return (isentity(value) and value:IsPlayer()) end)
nut.type.add("character", function(value) return (istable(value) and getmetatable(value) == nut.meta.character) end)
nut.type.add("item", function(value) return (istable(value) and value.isItem != nil) or (isentity(value) and value.getItemTable != nil) end)
nut.type.add("faction", function(value) return (istable(value) and value.uniqueID and nut.faction.teams[value.uniqueID] != nil) end)
nut.type.add("class", function(value) return (istable(value) and value.index and nut.class.list[value.index] != nil) end)

-- do type resolves
nut.type.addResolve("number", function(value) return (tonumber(value)) end)
nut.type.addResolve("bool", function(value) return (tobool(value)) end)
nut.type.addResolve("player", function(value)
	if (nut.type.assert(nut.type.player, value)) then
		return value
	end

	if (isstring(value)) then
		return nut.util.findPlayer(value)
	end

	return false, "Could not find the player \'" .. value .. "\'"
end)
nut.type.addResolve("character", function(value)
	if (nut.type.assert(nut.type.character, value)) then
		return value
	end

	-- if the value can resolve to a player then we probably want the player's character
	if (nut.type.resolve(nut.type.player, value)) then
		return nut.type.resolve(nut.type.player, value):getChar()
	end

	if (isstring(value)) then
		for _, v in pairs(nut.char.loaded) do
			if (nut.util.stringMatches(v:getName(), value)) then
				return v
			end
		end
	end

	return false, "Could not find the character \'" .. value .. "\'"
end)
nut.type.addResolve("item", function(value)
	if (nut.type.assert(nut.type.item, value)) then
		return (value.getItemTable and value:getItemTable()) or value
	end

	if (isstring(value)) then
		if (nut.item.list[value]) then
			return nut.item.list[value]
		end
	end

	if (isnumber(tonumber(value))) then
		if (nut.item.instances[tonumber(value)]) then
			return nut.item.instances[tonumber(value)]
		end
	end

	return false, "Could not find the item \'" .. value .. "\'"
end)
nut.type.addResolve("faction", function(value)
	if (nut.type.assert(nut.type.faction, value)) then
		return value
	end

	if (isnumber(tonumber(value))) then
		if (nut.faction.indices[tonumber(value)]) then
			return nut.faction.indices[tonumber(value)]
		end
	end

	if (isstring(value)) then
		if (nut.faction.teams[value]) then
			return nut.faction.teams[value]
		end

		for _, v in pairs(nut.faction.indices) do
			if (nut.util.stringMatches(v.uniqueID, value) or nut.util.stringMatches(v.name, value)) then
				return v
			end
		end
	end

	return false, "Could not find the faction \'" .. value .. "\'"
end)
nut.type.addResolve("class", function(value)
	if (nut.type.assert(nut.type.class, value)) then
		return value
	end

	if (isnumber(tonumber(value))) then
		if (nut.class.list[tonumber(value)]) then
			return nut.class.list[tonumber(value)]
		end
	end

	if (isstring(value)) then
		for _, v in pairs(nut.class.list) do
			if (nut.util.stringMatches(v.uniqueID, value) or nut.util.stringMatches(v.name, value)) then
				return v
			end
		end
	end

	return false, "Could not find the class \'" .. value .. "\'"
end)
