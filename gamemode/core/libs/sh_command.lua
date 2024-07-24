
nut.command = nut.command or {}
nut.command.list = nut.command.list or {}

local COMMAND_PREFIX = "/"

local function buildTypeName(types, bIsOr)
	local name = ""

	for k, v in ipairs(types) do
		if (isfunction(v)) then
			name = name .. "(" .. buildTypeName(nut.type.getMultiple(v), nut.types.ors[v]) .. ")"
		else
			name = name .. v .. (k != #types and (bIsOr and "|" or "&") or "")
		end
	end

	return name
end

function nut.command.add(name, data)
	if (!isstring(name)) then
		return ErrorNoHaltWithStack("nut.command.add expected string for #1 argument but got: " .. type(name))
	end

	if (!istable(data)) then
		return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") expected table for #2 argument but got: " .. type(data))
	end

	if (!isfunction(data.onRun)) then
		return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") expected an onRun function in #2 argument but got: " .. type(data.onRun))
	end

	-- new argument system
	if (isstring(data.arguments) or isfunction(data.arguments)) then
		data.arguments = {data.arguments}
	end

	if (istable(data.arguments)) then
		local missingArguments = {}
		local syntaxes = {}

		local hadOptionalArgument

		for i, v in ipairs(data.arguments) do
			local argumentName = debug.getlocal(data.onRun, i + 1)

			local types = nut.type.getMultiple(v)
			local bIsOr = nut.type.ors[v]
			local bIsOptional = bIsOr and table.HasValue(types, nut.type.optional)

			if (bIsOptional) then
				hadOptionalArgument = true
			elseif (hadOptionalArgument) then
				return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") a required argument is after an optional argument, optional arguments must be last")
			end

			-- we don't want 'optional' text showing up in the argument syntax
			for k, nutType in pairs(types) do
				if (nutType == nut.type.optional) then
					types[k] = nil
				end
			end

			local typeName = buildTypeName(types, bIsOr)

			if (argumentName) then
				if (v != nut.type.optional) then
					table.insert(syntaxes, bIsOptional and "[" .. typeName .. ": " .. argumentName .. "]" or "<" .. typeName .. ": " .. argumentName .. ">")
				end
			else
				table.insert(missingArguments, typeName)
			end
		end

		if (#missingArguments > 0) then
			return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") is missing (" .. table.concat(missingArguments, ", ") .. ") argument declarations(s) in the onRun function")
		end

		-- build syntax if we don't have a custom syntax
		if (!data.syntax and #syntaxes > 0) then
			data.syntax = table.concat(syntaxes, " ")
		end
	end

	data.syntax = data.syntax or "[none]"

	if (!data.onCheckAccess) then
		-- Check if the command is for basic admins only.
		if (data.adminOnly) then
			data.onCheckAccess = function(client)
				return !IsValid(client) and true or client:IsAdmin()
			end
		-- Or if it is only for super administrators.
		elseif (data.superAdminOnly) then
			data.onCheckAccess = function(client)
				return client:IsSuperAdmin()
			end
		-- Or if we specify a usergroup allowed to use this.
		elseif (data.group) then
			-- The group property can be a table of usergroups.
			if istable(data.group) then
				data.onCheckAccess = function(client)
					-- Check if the client's group is allowed.
					for _, v in ipairs(data.group) do
						if (client:IsUserGroup(v)) then
							return true
						end
					end

					return false
				end
			-- Otherwise it is most likely a string.
			else
				data.onCheckAccess = function(client)
					return client:IsUserGroup(data.group)
				end
			end
		end
	end

	local onCheckAccess = data.onCheckAccess

	-- Only overwrite the onRun to check for access if there is anything to check.
	if (onCheckAccess) then
		local onRun = data.onRun

		data._onRun = data.onRun -- for refactoring purpose.
		data.onRun = function(client, ...)
			if (hook.Run("CanPlayerUseCommand", client, name) or onCheckAccess(client)) then
				return onRun(client, ...)
			else
				return "@noPerm"
			end
		end
	end

	-- Add the command to the list of commands.
	local alias = data.alias

	if (alias) then
		if istable(alias) then
			for _, v in ipairs(alias) do
				nut.command.list[v:lower()] = data
			end
		elseif isstring(alias) then
			nut.command.list[alias:lower()] = data
		end
	end

	if (name == name:lower()) then
		nut.command.list[name] = data
	else
		data.realCommand = name

		nut.command.list[name:lower()] = data
	end
end

-- Returns whether or not a player is allowed to run a certain command.
function nut.command.hasAccess(client, command)
	command = nut.command.list[command:lower()]

	if (command) then
		if (command.onCheckAccess) then
			return command.onCheckAccess(client)
		else
			return true
		end
	end

	return hook.Run("CanPlayerUseCommand", client, command) or false
end

-- Gets a table of arguments from a string.
function nut.command.extractArgs(text)
	local skip = 0
	local arguments = {}
	local curString = ""

	for i = 1, #text do
		if (i <= skip) then continue end

		local c = text:sub(i, i)

		if (c == "\"") then
			local match = text:sub(i):match("%b"..c..c)

			if (match) then
				curString = ""
				skip = i + #match
				arguments[#arguments + 1] = match:sub(2, -2)
			else
				curString = curString..c
			end
		elseif (c == " " and curString ~= "") then
			arguments[#arguments + 1] = curString
			curString = ""
		else
			if (c == " " and curString == "") then
				continue
			end

			curString = curString..c
		end
	end

	if (curString ~= "") then
		arguments[#arguments + 1] = curString
	end

	return arguments
end

if (SERVER) then
	-- Finds a player or gives an error notification.
	function nut.command.findPlayer(client, name)
		if isstring(name) then
			if name == "^" then -- thank you Hein/Hankshark - Tov
				return client
			elseif name == "@" then
				local trace = client:GetEyeTrace().Entity
				if IsValid(trace) and trace:IsPlayer() then
					return trace
				else
					client:notifyLocalized("lookToUseAt")
					return
				end
			end
			local target = nut.util.findPlayer(name) or NULL

			if (IsValid(target)) then
				return target
			else
				client:notifyLocalized("plyNoExist")
			end
		else
			client:notifyLocalized("mustProvideString")
		end
	end

	-- Finds a faction based on the uniqueID, and then the name if no such uniqueID exists.
	function nut.command.findFaction(client, name)
		if (nut.faction.teams[name]) then
			return nut.faction.teams[name]
		end

		for _, v in ipairs(nut.faction.indices) do
			if (nut.util.stringMatches(L(v.name,client), name)) then
				return v --This interrupt means we don't need an if statement below.
			end
		end

		client:notifyLocalized("invalidFaction")
	end

	-- Forces a player to run a command.
	function nut.command.run(client, command, arguments)
		command = nut.command.list[command:lower()]
		arguments = arguments or {}

		if (command) then
			local results = {command.onRun(client, unpack(command.arguments and arguments or {arguments}))}
			local result = results[1]

			-- If a string is returned, it is a notification.
			if isstring(result) then
				-- Normal player here.
				if (IsValid(client)) then
					if (result:sub(1, 1) == "@") then
						client:notifyLocalized(result:sub(2), unpack(results, 2))
					else
						client:notify(result)
					end

					nut.log.add(client, "command", command, table.concat(arguments, ", "))
				else
					-- Show the message in server console since we're running from RCON.
					print(result)
				end
			end
		end
	end

	-- Add a function to parse a regular chat string.
	function nut.command.parse(client, text, realCommand, arguments)
		if (realCommand or text:utf8sub(1, 1) == COMMAND_PREFIX) then
			-- See if the string contains a command.
			local match = realCommand or text:lower():match(COMMAND_PREFIX.."([_%w]+)")

			-- is it unicode text?
			-- i hate unicode.
			if (!match) then
				local post = string.Explode(" ", text)
				local len = string.len(post[1])

				match = post[1]:utf8sub(2, len)
			end

			match = match:lower()

			local command = nut.command.list[match]
			-- We have a valid, registered command.
			if (command) then
				arguments = arguments or nut.command.extractArgs(text:sub(#match + 3))

				if (command.arguments) then
					for k, v in ipairs(command.arguments) do
						local types = nut.type.getMultiple(v)
						local bIsOptional = table.HasValue(types, nut.type.optional)

						if (arguments[k] and k == #command.arguments and table.HasValue(types, nut.type.string)) then	
							for _ = k + 1, #arguments do
								arguments[k] = arguments[k] .. " " .. arguments[k + 1]
								table.remove(arguments, k + 1)
							end
						end

						local argument = arguments[k]

						-- we don't want 'optional' text showing up in the argument syntax
						for k, nutType in pairs(types) do
							if (nutType == nut.type.optional) then
								types[k] = nil
							end
						end

						local typeName = buildTypeName(types, nut.type.ors[v])

						if (!bIsOptional) then
							if (argument == nil or argument == "") then
								if (IsValid(client)) then
									client:notify("Missing argument #" .. k .. " expected \'" .. typeName .. "\'")
								else
									print("Missing argument #" .. k .. " expected \'" .. typeName .. "\'")
								end

								return true
							end
						end

						if (arguments[k]) then
							if (IsValid(client)) then
								if (table.HasValue(types, nut.type.player) or table.HasValue(types, nut.type.character)) then
									if (argument == "^") then
										argument = client
									elseif (argument == "@") then
										local trace = client:GetEyeTrace().Entity

										if (IsValid(trace) and trace:IsPlayer()) then
											argument = trace
										else
											client:notifyLocalized("lookToUseAt")
											return true
										end
									end
								end
							end

							local resolve = nut.type.resolve(v, argument)

							if (resolve == nil) then
								resolve = argument
							end

							local success = isfunction(v) and v(resolve) or nut.type.assert(v, resolve)

							if (success or v == nut.type.optional) then
								arguments[k] = resolve
							else
								if (IsValid(client)) then
									client:notify("Invalid \'" .. typeName .. "\' to argument #" .. k)
								else
									print("Invalid \'" .. typeName .. "\' to argument #" .. k)
								end

								return true
							end
						end
					end
				end

				-- Runs the actual command.
				nut.command.run(client, match, arguments)

				if (!realCommand) then
					nut.log.add(client, "command", text)
				end
			else
				if (IsValid(client)) then
					client:notifyLocalized("cmdNoExist")
				else
					print("Sorry, that command does not exist.")
				end
			end

			return true
		end

		return false
	end

	concommand.Add("nut", function(client, _, arguments)
		local command = arguments[1]
		table.remove(arguments, 1)

		nut.command.parse(client, nil, command or "", arguments)
	end)

	netstream.Hook("cmd", function(client, command, arguments)
		if ((client.nutNextCmd or 0) < CurTime()) then
			local arguments2 = {}

			for _, v in ipairs(arguments) do
				if (isstring(v) or isnumber(v)) then
					arguments2[#arguments2 + 1] = tostring(v)
				end
			end

			nut.command.parse(client, nil, command, arguments2)
			client.nutNextCmd = CurTime() + 0.2
		end
	end)
else
	function nut.command.send(command, ...)
		netstream.Start("cmd", command, {...})
	end
end
