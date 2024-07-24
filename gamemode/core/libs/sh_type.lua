
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

	nut.type.list[name] = nut.type.list[name] or {}
	nut.type.list[name].assertion = assertion
	nut.type[name] = name
end

function nut.type.addResolve(nutType, identifier, resolve)
	if (!isstring(nutType)) then
		error("nut.type.addResolve expected string for #1 input but got: " .. type(nutType))
	end

	if (!isfunction(resolve)) then
		error("nut.type.addResolve(\"" .. nutType .. "\") expected function for #2 input but got: " .. type(assertion))
	end

	nut.type.list[nutType].resolves = nut.type.list[nutType].resolves or {}
	nut.type.list[nutType].resolves[identifier] = resolve
end

function nut.type.assert(nutType, value)
	-- if it's a function then it's an or/and func, we run it now
	if (isfunction(nutType)) then
		return nutType(value)
	end

	return nut.type.list[nutType] and nut.type.list[nutType].assertion(value)
end

function nut.type.resolve(nutType, value)
	local resolve

	-- if it's a function then it's an or/and func, we'll have to resolve each type see what succeeds
	if (isfunction(nutType)) then
		local types = nut.type.ors[nutType] or nut.type.ands[nutType]

		for _, v in ipairs(types) do
			-- if the value is the correct type we don't need to resolve, return the value
			if (nut.type.assert(v, value)) then return value end

			if (nut.type.list[v].resolves) then
				for _, resolveFunc in pairs(nut.type.list[v].resolves) do
					resolve = resolveFunc(value)

					if (resolve) then
						return resolve
					end
				end
			end
		end
	end

	if (nut.type.list[nutType]) then
		-- if the value is the correct type we don't need to resolve, return the value
		if (nut.type.assert(nutType, value)) then return value end

		for _, resolveFunc in pairs(nut.type.list[nutType].resolves or {}) do
			resolve = resolveFunc(value)

			if (resolve) then
				return resolve
			end
		end
	end

	return resolve
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
nut.type.add("steamid", function(value) return (isstring(value) and string.match(value, "STEAM_%d+:%d+:%d+") == value) end)
nut.type.add("player", function(value) return (isentity(value) and value:IsPlayer()) end)
nut.type.add("character", function(value) return (istable(value) and getmetatable(value) == nut.meta.character) end)
nut.type.add("item", function(value) return (istable(value) and value.isItem != nil) end)
nut.type.add("faction", function(value) return (istable(value) and value.uniqueID and nut.faction.teams[value.uniqueID] != nil) end)
nut.type.add("class", function(value) return (istable(value) and value.index and nut.class.list[value.index] != nil) end)

-- do type resolves
nut.type.addResolve(nut.type.number, "tonumber", function(value) return (tonumber(value)) end)
nut.type.addResolve(nut.type.bool, "tobool", function(value) return (tobool(value)) end)
nut.type.addResolve(nut.type.player, "findPlayer", function(value)
	if (isstring(value)) then
		if (nut.type.assert(nut.type.steamid, value) and player.GetBySteamID(value)) then
			return player.GetBySteamID(value)
		end

		for _, v in ipairs(player.GetAll()) do
			if (nut.util.stringMatches(v:Name(), value)) then
				return v
			end
		end
	end
end)
nut.type.addResolve(nut.type.character, "findCharacter", function(value)
	local ply = nut.type.resolve(nut.type.player, value)

	-- if the value can resolve to a player then we probably want the player's character
	if (ply and ply:getChar()) then
		return ply:getChar() 
	end

	if (isstring(value)) then
		for _, v in pairs(nut.char.loaded) do
			if (nut.util.stringMatches(v:getName(), value)) then
				return v
			end
		end
	end
end)
nut.type.addResolve(nut.type.item, "findItem", function(value)
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
end)
nut.type.addResolve(nut.type.faction, "findFaction", function(value)
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
			if (nut.util.stringMatches(client and L(v.uniqueID, client) or v.uniqueID, value) or nut.util.stringMatches(client and L(v.name, client) or v.name, value)) then
				return v
			end
		end
	end
end)
nut.type.addResolve(nut.type.class, "findClass", function(value)
	if (isnumber(tonumber(value))) then
		if (nut.class.list[tonumber(value)]) then
			return nut.class.list[tonumber(value)]
		end
	end

	if (isstring(value)) then
		for _, v in pairs(nut.class.list) do
			if (nut.util.stringMatches(client and L(v.uniqueID, client) or v.uniqueID, value) or nut.util.stringMatches(client and L(v.name, client) or v.name, value)) then
				return v
			end
		end
	end
end)
