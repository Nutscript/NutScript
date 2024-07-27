local PLUGIN = PLUGIN

PLUGIN.name = "Plugin Configuration"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a menu for enabling/disabling plugins."

CAMI.RegisterPrivilege({
	Name = "NS.Config.Plugins",
	MinAccess = "superadmin"
})

if (SERVER) then
	PLUGIN.overwrite = PLUGIN.overwrite or {}

	util.AddNetworkString("nutPluginDisable")
	util.AddNetworkString("nutPluginList")

	function PLUGIN:getPluginList()
		if (self.computedPlugins) then
			return self.computedPlugins
		end

		local plugins = {}
		local found = {}

		local function findPlugins(path)
			local files, folders = file.Find(path.."/*", "LUA")

			for _, folder in ipairs(folders) do
				if (
					not file.Exists(path.."/"..folder.."/sh_plugin.lua", "LUA")
					or found[folder]
				) then
					continue
				end
				plugins[#plugins + 1] = folder
				found[folder] = true
				findPlugins(path.."/"..folder.."/plugins")
			end

			for _, fileName in ipairs(files) do
				local pluginID = string.StripExtension(fileName)
				if (
					string.GetExtensionFromFilename(fileName) == "lua" and
					not found[pluginID]
				) then
					plugins[#plugins + 1] = pluginID
					found[pluginID] = true
				end
			end
		end

		findPlugins("nutscript/plugins")
		findPlugins(SCHEMA.folder.."/plugins")

		self.computedPlugins = plugins
		return plugins
	end

	function PLUGIN:setPluginDisabled(name, disabled)
		nut.plugin.setDisabled(name, disabled)
		self.overwrite[name] = disabled

		CAMI.GetPlayersWithAccess("NS.Config.Plugins", function(allowedPlys)
			net.Start("nutPluginDisable")
				net.WriteString(name)
				net.WriteBit(disabled)
			net.Send(allowedPlys)
		end)
	end

	concommand.Add("nut_disableplugin", function(client, _, arguments)
		if (IsValid(client) and not CAMI.PlayerHasAccess(client, "NS.Config.Plugins")) then
			return
		end

		local name = arguments[1]
		local disabled = tobool(arguments[2])
		PLUGIN:setPluginDisabled(name, disabled)

		local message = name.." is now "..(disabled and "disabled" or "enabled")
		if (IsValid(client)) then
			client:ChatPrint(message)
		end
		print(message)
	end)

	net.Receive("nutPluginDisable", function(_, client)
		if (not CAMI.PlayerHasAccess(client, "NS.Config.Plugins")) then return end
		local name = net.ReadString()
		local disabled = net.ReadBit() == 1
		PLUGIN:setPluginDisabled(name, disabled)
	end)

	net.Receive("nutPluginList", function(_, client)
		if (not CAMI.PlayerHasAccess(client, "NS.Config.Plugins")) then return end
		local plugins = PLUGIN:getPluginList()
		local disabled
		net.Start("nutPluginList")
			net.WriteUInt(#plugins, 32)
			for _, plugin in ipairs(plugins) do
				if (PLUGIN.overwrite[plugin] ~= nil) then
					disabled = PLUGIN.overwrite[plugin]
				else
					disabled = nut.plugin.isDisabled(plugin)
				end
				net.WriteString(plugin)
				net.WriteBit(disabled)
			end
		net.Send(client)
	end)
else
	function PLUGIN:createPluginPanel(parent, plugins)
		local frame = vgui.Create("DFrame")
		frame:SetTitle(L"togglePlugins")
		frame:SetSize(256, 512)
		frame:MakePopup()
		frame:Center()
		frame.plugins = {}

		local loading = frame:Add("DLabel")
		loading:Dock(FILL)
		loading:SetText(L"loading")
		loading:SetContentAlignment(5)

		nut.gui.pluginConfig = frame

		local info = frame:Add("DLabel")
		local text = L"togglePluginsDesc"
		info:SetText(text)
		info:Dock(TOP)
		info:DockMargin(0, 0, 0, 4)
		info:SetContentAlignment(5)
		surface.SetFont(info:GetFont())
		local _, h = surface.GetTextSize(text)
		info:SetTall(h)

		local scroll = frame:Add("DScrollPanel")
		scroll:Dock(FILL)

		local function onChange(box, value)
			local plugin = box.plugin
			if (not plugin) then return end
			net.Start("nutPluginDisable")
				net.WriteString(plugin)
				net.WriteBit(value)
			net.SendToServer()
		end

		hook.Add("RetrievedPluginList", frame, function(_, plugins)
			for name, disabled in SortedPairs(plugins) do
				local box = scroll:Add("DCheckBoxLabel")
				box:Dock(TOP)
				box:DockMargin(0, 0, 0, 4)
				box:SetValue(disabled)
				box:SetText(name)
				box.plugin = name
				box.OnChange = onChange
				frame.plugins[name] = box
			end
			loading:Remove()
		end)

		hook.Add("PluginConfigDisabled", frame, function(_, plugin, disabled)
			local box = frame.plugins[plugin]
			if (IsValid(box)) then
				box:SetValue(disabled)
			end
		end)

		net.Start("nutPluginList")
		net.SendToServer()
	end

	function PLUGIN:CreateConfigPanel(parent)
		local button = parent:Add("DButton")
		button:SetText(L"togglePlugins")
		button:Dock(TOP)
		button:DockMargin(0, 0, 0, 8)
		button:SetSkin("Default")
		button.DoClick = function()
			self:createPluginPanel(parent)
		end
	end

	net.Receive("nutPluginList", function()
		local length = net.ReadUInt(32)
		local plugins = {}
		for _ = 1, length do
			plugins[net.ReadString()] = net.ReadBit() == 1
		end
		hook.Run("RetrievedPluginList", plugins)
	end)

	net.Receive("nutPluginDisable", function()
		local name = net.ReadString()
		local disabled = net.ReadBit() == 1

		hook.Run("PluginConfigDisabled", name, disabled)
	end)
end
