-- @module nut.log
-- @moduleCommentStart
-- Library functions for nutscript logs
-- @moduleCommentEnd

FLAG_NORMAL = 0
FLAG_SUCCESS = 1
FLAG_WARNING = 2
FLAG_DANGER = 3
FLAG_SERVER = 4
FLAG_DEV = 5

nut.log = nut.log or {}
nut.log.color = {
	[FLAG_NORMAL] = Color(200, 200, 200),
	[FLAG_SUCCESS] = Color(50, 200, 50),
	[FLAG_WARNING] = Color(255, 255, 0),
	[FLAG_DANGER] = Color(255, 50, 50),
	[FLAG_SERVER] = Color(200, 200, 220),
	[FLAG_DEV] = Color(200, 200, 220),
}
local consoleColor = Color(50, 200, 50)

CAMI.RegisterPrivilege({
	Name = "NS.Logs",
	MinAccess = "admin"
})

if (SERVER) then
	if (not nut.db) then
		include("sv_database.lua")
	end

	-- @type function nut.log.loadTables()
	-- @typeCommentStart
	-- Used to load tables into the database
	-- @typeCommentEnd
	-- @realm server
	-- @internal
	function nut.log.loadTables()
		file.CreateDir("nutscript/logs")
	end

	-- @type function nut.log.resetTables()
	-- @typeCommentStart
	-- Used to reset tables into database
	-- @typeCommentEnd
	-- @realm server
	-- @internal
	function nut.log.resetTables()
	end

	-- @type table nut.log.types()
	-- @typeCommentStart
	-- Stores log types and their formatting functions
	-- @typeCommentEnd
	-- @realm server
	nut.log.types = nut.log.types or {}

	-- @type function nut.log.addType(logType, func)
	-- @typeCommentStart
	-- Used to reset tables into database
	-- @typeCommentEnd
	-- @realm server
	-- @string logType
	-- @function (client, ...) log format callback
	-- @usageStart
	-- nut.log.addType("playerConnected", function(client, ...)
	--		local data = {...}
	--		local steamID = data[2]
	--
	--		return string.format("%s[%s] has connected to the server.", client:Name(), steamID or client:SteamID())
	--	end)
	-- @usageEnd
	function nut.log.addType(logType, func)
		nut.log.types[logType] = func
	end

	-- @type function nut.log.getString(client, logType, ...)
	-- @typeCommentStart
	-- Formats a string that is in log.type
	-- @typeCommentEnd
	-- @player client Default argument for format string
	-- @string logType 
	-- @vararg ... Other arguments on log format
	-- @realm server
	-- @treturn string Formatted string
	-- @internal
	function nut.log.getString(client, logType, ...)
		local text = nut.log.types[logType]
		if (isfunction(text)) then
			local success, result = pcall(text, client, ...)
			if (success) then
				return result
			end
		end
	end

	-- @type function nut.log.addRaw(logString, shouldNotify, flag)
	-- @typeCommentStart
	-- Adds a raw that does not require formatting
	-- @typeCommentEnd
	-- @string logString Log string data
	-- @bool sholdNotify Display log notification in the administration console
	-- @int flag Log color flag
	-- @realm server
	function nut.log.addRaw(logString, shouldNotify, flag)		
		if (shouldNotify) then
			CAMI.GetPlayersWithAccess("NS.Logs", function(allowedPlys)
				nut.log.send(allowedPlys, logString, flag)
			end)
		end

		Msg("[LOG] ", logString.."\n")
		if (!noSave) then
			file.Append("nutscript/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end

	-- @type function nut.log.add(client, logType, ...)
	-- @typeCommentStart
	-- Displays a line of the log according to the match described in the log type
	-- @typeCommentEnd
	-- @player client player name on displayed log
	-- @string logType type of log
	-- @vararg ... other arguments for log
	-- @realm server
	-- @usageStart
	-- function GM:PlayerAuthed(client, steamID, uniqueID)
	--	nut.log.add(client, "playerConnected", client, steamID)
	-- end
	-- @usageEnd
	function nut.log.add(client, logType, ...)
		local logString = nut.log.getString(client, logType, ...)
		if (not isstring(logString)) then return end

		hook.Run("OnServerLog", client, logType, ...)
		Msg("[LOG] ", logString.."\n")

		if (noSave) then return end
		file.Append("nutscript/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
	end

	function nut.log.open(client)
		local logData = {}
		netstream.Hook(client, "nutLogView", logData)
	end

	-- @type function nut.log.add(client, logString, flag)
	-- @typeCommentStart
	-- Display log raw on client console
	-- @typeCommentEnd
	-- @player client player name on displayed log
	-- @string logString log string
	-- @int flag Color flag on log string
	-- @realm server
	-- @internal
	function nut.log.send(client, logString, flag)
		netstream.Start(client, "nutLogStream", logString, flag)
	end
else
	netstream.Hook("nutLogStream", function(logString, flag)
		MsgC(consoleColor, "[SERVER] ", nut.log.color[flag] or color_white, tostring(logString).."\n")
	end)
end
