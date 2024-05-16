
nut.command = nut.command or {}
nut.command.list = nut.command.list or {}

local COMMAND_PREFIX = "/"

function nut.command.add(name, data)
	if (!isstring(name)) then
		return ErrorNoHaltWithStack("nut.command.add expected string for #1 argument but got: " .. nut.type(name))
	end

	if (!istable(data)) then
		return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") expected table for #2 argument but got: " .. nut.type(data))
	end

	if (!isfunction(data.onRun)) then
		return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") expected an onRun function in #2 argument but got: " .. nut.type(data.onRun))
	end

	-- new argument system
	if (istable(data.arguments)) then
		local missingArguments = {}
		local syntaxes = {}

		local hadOptionalArgument

		for i, v in ipairs(data.arguments) do
			local argumentName = debug.getlocal(data.onRun, i + 1)

			if (nut.type.isOptional(v)) then
				hadOptionalArgument = true
			elseif (hadOptionalArgument) then
				return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") a required argument is after an optional argument, optional arguments must be last")
			end

			if (argumentName) then
				table.insert(syntaxes, nut.type.isOptional(v) and "[" .. nut.type.getName(v) .. " " .. argumentName .. "]" or "<" .. nut.type.getName(v) .. " " .. argumentName .. ">")
			else
				table.insert(missingArguments, nut.type.getName(v))
			end
		end

		if (#missingArguments > 0) then
			return ErrorNoHaltWithStack("nut.command.add(\"" .. name .. "\") is missing (" .. table.concat(missingArguments, ", ") .. ") argument declarations(s) in the onRun function")
		end

		-- build syntax if we don't have a custom syntax
		if (!data.syntax) then
			data.syntax = table.concat(syntaxes, " ")
		end
	end

	data.syntax = data.syntax or "[none]"

	if (!data.onCheckAccess) then
		-- Check if the command is for basic admins only.
		if (data.adminOnly) then
			data.onCheckAccess = function(client)
				return client:IsAdmin()
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
		data.onRun = function(client, arguments)
			if (hook.Run("CanPlayerUseCommand", client, name) or onCheckAccess(client)) then
				return onRun(client, arguments)
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

		PrintTable(arguments)

		if (command) then
			local results

			-- new argument system
			if (command.arguments) then
				if (#arguments > #command.arguments) then
					client:notify("Too many arguments provided, expected \'" .. #command.arguments .. "\' got \'" .. #arguments .. "\'")
					return
				end

				for i, v in ipairs(command.arguments) do
					local argument = arguments[i]
					local nutType = command.arguments[i]
					local bIsOptional = nut.type.isOptional(nutType)
					nutType = bIsOptional and bit.bxor(nutType, nut.type.optional) or nutType

					if (!bIsOptional) then
						if (argument == nil or argument == "") then
							client:notify("Missing argument #" .. i .. " expected \'" .. nut.type.getName(nutType) .. "\'")
							return
						end
					end

					if (argument) then
						local assertion = nut.type.assert(nutType, argument)

						if (assertion) then
							if (!isbool(assertion)) then
								arguments[i] = assertion
							end
						else
							if (nut.type.getName(nutType) == "player") then
								client:notify("Could not find player \'" .. argument .. "\'")
							else
								client:notify("Wrong type to #" .. i .. " argument, expected \'" .. nut.type.getName(nutType) .. "\' got \'" .. nut.type(argument) .. "\'")
							end

							return
						end
					end
				end

				results = {command.onRun(client, unpack(arguments))}
			else
				-- Run the command's callback and get the return.
				results = {command.onRun(client, arguments or {})}
			end

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
				-- Get the arguments like a console command.
				if (!arguments) then
					arguments = nut.command.extractArgs(text:sub(#match + 3))
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
