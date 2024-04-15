nut.config = nut.config or {}
nut.config.stored = nut.config.stored or {}

function nut.config.add(key, value, desc, callback, data, noNetworking, schemaOnly)
	assert(isstring(key), "expected config key to be string, got " .. type(key))
	assert(istable(data), "expected config data to be a table, got " .. type(data))
	local oldConfig = nut.config.stored[key]
	local savedValue
	if (oldConfig) then
		savedValue = oldConfig.value
	else
		savedValue = value
	end

	nut.config.stored[key] = {data = data, value = savedValue, default = value, desc = desc, noNetworking = noNetworking, global = not schemaOnly, callback = callback}
end

function nut.config.setDefault(key, value)
	local config = nut.config.stored[key]

	if (config) then
		config.default = value
	end
end

function nut.config.forceSet(key, value, noSave)
	local config = nut.config.stored[key]

	if (config) then
		config.value = value
	end

	if (noSave) then
		nut.config.save()
	end
end

function nut.config.set(key, value)
	local config = nut.config.stored[key]

	if (config) then
		local oldValue = value
		config.value = value

		if (SERVER) then
			if (not config.noNetworking) then
				netstream.Start(nil, "cfgSet", key, value)
			end

			if (config.callback) then
				config.callback(oldValue, value)
			end

			nut.config.save()
		end
	end
end

function nut.config.get(key, default)
	local config = nut.config.stored[key]

	if (config) then
		if (config.value ~= nil) then
			if istable(config.value) and config.value.r and config.value.g and config.value.b then -- if the value is a table with rgb values
				config.value = Color(config.value.r, config.value.g, config.value.b) -- convert it to a Color table
			end
			return config.value
		elseif (config.default ~= nil) then
			return config.default
		end
	end

	return default
end

function nut.config.load()
	if (SERVER) then
		local globals = nut.data.get("config", nil, true, true)
		local data = nut.data.get("config", nil, false, true)
		if (globals) then
			for k, v in pairs(globals) do
				nut.config.stored[k] = nut.config.stored[k] or {}
				nut.config.stored[k].value = v
			end
		end

		if (data) then
			for k, v in pairs(data) do
				nut.config.stored[k] = nut.config.stored[k] or {}
				nut.config.stored[k].value = v
			end
		end
	end

	nut.util.include("nutscript/gamemode/config/sh_config.lua")
	hook.Run("InitializedConfig")
end

if (SERVER) then
	function nut.config.getChangedValues()
		local data = {}

		for k, v in pairs(nut.config.stored) do
			if (v.default ~= v.value) then
				data[k] = v.value
			end
		end

		return data
	end

	function nut.config.send(client)
		netstream.Start(client, "cfgList", nut.config.getChangedValues())
	end

	function nut.config.save()
		local globals = {}
		local data = {}

		for k, v in pairs(nut.config.getChangedValues()) do
			if (nut.config.stored[k].global) then
				globals[k] = v
			else
				data[k] = v
			end
		end

		-- Global and schema data set respectively.
		nut.data.set("config", globals, true, true)
		nut.data.set("config", data, false, true)
	end

	netstream.Hook("cfgSet", function(client, key, value)
		if (client:IsSuperAdmin() and type(nut.config.stored[key].default) == type(value) and hook.Run("CanPlayerModifyConfig", client, key) ~= false) then
			nut.config.set(key, value)

			if (istable(value)) then
				local value2 = "["
				local count = table.Count(value)
				local i = 1

				for _, v in SortedPairs(value) do
					value2 = value2 .. v .. (i == count and "]" or ", ")
					i = i + 1
				end
				value = value2
			end

			nut.util.notifyLocalized("cfgSet", nil, client:Name(), key, tostring(value))
		end
	end)
else
	netstream.Hook("cfgList", function(data)
		for k, v in pairs(data) do
			if (nut.config.stored[k]) then
				nut.config.stored[k].value = v
			end
		end

		hook.Run("InitializedConfig", data)
	end)

	netstream.Hook("cfgSet", function(key, value)
		local config = nut.config.stored[key]

		if (config) then
			if (config.callback) then
				config.callback(config.value, value)
			end

			config.value = value

			local properties = nut.gui.properties

			if (IsValid(properties)) then
				local row = properties:GetCategory(L(config.data and config.data.category or "misc")):GetRow(key)

				if (IsValid(row)) then
					if (istable(value) and value.r and value.g and value.b) then
						value = Vector(value.r / 255, value.g / 255, value.b / 255)
					end

					row:SetValue(value)
				end
			end
		end
	end)
end

if (CLIENT) then
	local legacyConfigMenu = CreateClientConVar("nut_legacyconfig", "0", true, true)

	hook.Add("CreateMenuButtons", "nutConfig", function(tabs)
		if (not LocalPlayer():IsSuperAdmin() or hook.Run("CanPlayerUseConfig", LocalPlayer()) == false) then
			return
		end

		tabs["config"] = function(panel)

			if legacyConfigMenu:GetBool() ~= true then
				local canvas = panel:Add("DPanel")
				canvas:Dock(FILL)
				canvas:SetPaintBackground(false)

				canvas:InvalidateLayout(true)

				local config = canvas:Add("NutConfigPanel")
				config:SetSize(panel:GetSize())
				config:AddElements()
			else
				local scroll = panel:Add("DScrollPanel")
				scroll:Dock(FILL)

				hook.Run("CreateConfigPanel", panel)

				local properties = scroll:Add("DProperties")
				properties:SetSize(panel:GetSize())

				nut.gui.properties = properties

				-- We're about to store the categories in this buffer.
				local buffer = {}

				for k, v in pairs(nut.config.stored) do
					-- Get the category name.
					local index = v.data and v.data.category or "misc"

					-- Insert the config into the category list.
					buffer[index] = buffer[index] or {}
					buffer[index][k] = v
				end

				-- Loop through the categories in alphabetical order.
				for category, configs in SortedPairs(buffer) do
					category = L(category)

					-- Ditto, except we're looping through configs.
					for k, v in SortedPairs(configs) do
						-- Determine which type of panel to create.
						local form = v.data and v.data.form
						local value = nut.config.stored[k].default

						-- Let's see if the parameter has a form to perform some additional operations.
						if (form) then
							if (form == "Int") then
								-- math.Round can create an error without failing silently as expected if the parameter is invalid.
								-- So an alternate value is entered directly into the function and not outside of it.
								value = math.Round(nut.config.get(k) or value)
							elseif (form == "Float") then
								value = tonumber(nut.config.get(k)) or value
							elseif (form == "Boolean") then
								value = tobool(nut.config.get(k)) or value
							else
								value = nut.config.get(k) or value
							end
						else
							local formType = type(value)

							if (formType == "number") then
								form = "Int"
								value = tonumber(nut.config.get(k)) or value
							elseif (formType == "boolean") then
								form = "Boolean"
								value = tobool(nut.config.get(k))
							else
								form = "Generic"
								value = nut.config.get(k) or value
							end
						end

						if form == "Combo" then
							v.data.data = v.data.data or {}
							v.data.data.text = value
							v.data.data.values = {}
							for niceName, optionData in pairs(v.data.options) do
								niceName = tonumber(niceName) and optionData or niceName
								v.data.data.values[tonumber(niceName) and optionData or niceName] = optionData

								if optionData == value then
									v.data.data.text = niceName
								end
							end
						end

						-- VectorColor currently only exists for DProperties.
						if (form == "Generic" and istable(value) and value.r and value.g and value.b) then
							-- Convert the color to a vector.
							value = Vector(value.r / 255, value.g / 255, value.b / 255)
							form = "VectorColor"
						end

						local delay = 1

						if (form == "Boolean") or (form == "Combo") then
							delay = 0
						end

						-- Add a new row for the config to the properties.
						local row = properties:CreateRow(category, tostring(k))
						row:Setup(form, v.data and v.data.data or {})
						row:SetValue(value)
						row:SetTooltip(v.desc)
						row.DataChanged = function(this, newValue)
							debug.Trace()
							timer.Create("nutCfgSend" .. k, delay, 1, function()
								if (not IsValid(row)) then
									return
								end

								if (form == "VectorColor") then
									local vector = Vector(newValue)

									newValue = Color(math.floor(vector.x * 255), math.floor(vector.y * 255), math.floor(vector.z * 255))
								elseif (form == "Int" or form == "Float") then
									newValue = tonumber(newValue)

									if (form == "Int") then
										newValue = math.Round(newValue)
									end
								elseif (form == "Boolean") then
									newValue = tobool(newValue)
								end
								netstream.Start("cfgSet", k, newValue)
							end)
						end

						if form == "Combo" then
							row.SetValue = function() end -- without this config gets set twice. idk why - Tov
						end
					end
				end
			end
		end
	end)
end
