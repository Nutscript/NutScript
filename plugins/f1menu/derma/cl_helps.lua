
	local HELP_DEFAULT

	hook.Add("CreateMenuButtons", "nutHelpMenu", function(tabs)
		HELP_DEFAULT = [[
			<div id="parent"><div id="child">
				<center>
				    <img src="https://static.miraheze.org/nutscriptwiki/2/26/Nutscript.png"></img>
					<br><font size=15>]] .. L"helpDefault" .. [[</font>
				</center>
			</div></div>
		]]

		tabs["help"] = function(panel)
			local html
			local header = [[<html>
			<head>
				<style>
					@import url(http://fonts.googleapis.com/earlyaccess/jejugothic.css);

					#parent {
					    padding: 5% 0;
					}

					#child {
					    padding: 10% 0;
					}

					body {
						color: #FAFAFA;
						font-family: 'Jeju Gothic', serif;
						-webkit-font-smoothing: antialiased;
					}

					h2 {
						margin: 0;
					}
				</style>
			</head>
			<body>
			]]

			local tree = panel:Add("DTree")
			tree:SetPadding(5)
			tree:Dock(LEFT)
			tree:SetWide(180)
			tree:DockMargin(0, 0, 15, 0)
			tree.OnNodeSelected = function(this, node)
				if (node.onGetHTML) then
					for k, panel in ipairs(helpPanel:GetChildren()) do
						if (panel != html) then
							panel:Remove()
						end
					end

					local source = node:onGetHTML()

					if (source and source:sub(1, 4) == "http") then
						html:OpenURL(source)
					else
						html:SetHTML(header..source.."</body></html>")
					end
				end
			end

			if not IsValid(helpPanel) then
				helpPanel = panel:Add("Panel")
				helpPanel:Dock(FILL)

				html = helpPanel:Add("DHTML")
				html:Dock(FILL)
				html:SetHTML(header..HELP_DEFAULT)
			end
			tabs = {}
			hook.Run("BuildHelpMenu", tabs)

			for k, v in SortedPairs(tabs) do
				if (not isfunction(v)) then
					local source = v

					v = function() return tostring(source) end
				end

				tree:AddNode(L(k)).onGetHTML = v or function() return "" end
			end
		end
	end)

hook.Add("BuildHelpMenu", "nutBasicHelp", function(tabs)
	tabs["commands"] = function(node)
		local body = ""

		for k, v in SortedPairs(nut.command.list) do
			local allowed = false

			if (v.adminOnly and not LocalPlayer():IsAdmin()or v.superAdminOnly and not LocalPlayer():IsSuperAdmin()) then
				continue
			end

			if (v.group) then
				if (istable(v.group)) then
					for _, v1 in pairs(v.group) do
						if (LocalPlayer():IsUserGroup(v1)) then
							allowed = true

							break
						end
					end
				elseif (LocalPlayer():IsUserGroup(v.group)) then
					return true
				end
			else
				allowed = true
			end

			if (allowed) then
				body = body.."<h2>/"..k.."</h2><strong>Syntax:</strong> <em>"..v.syntax.."</em><br /><br />"
			end
		end

		return body
	end

	tabs["flags"] = function(node)
		local body = [[<table border="0" cellspacing="8px">]]

		for k, v in SortedPairs(nut.flag.list) do
			local icon

			if (LocalPlayer():getChar():hasFlags(k)) then
				icon = [[<img src="asset://garrysmod/materials/icon16/tick.png" />]]
			else
				icon = [[<img src="asset://garrysmod/materials/icon16/cross.png" />]]
			end

			body = body..Format([[
				<tr>
					<td>%s</td>
					<td><b>%s</b></td>
					<td>%s</td>
				</tr>
			]], icon, k, v.desc)
		end

		return body.."</table>"
	end

	tabs["plugins"] = function(node)
		local body = ""

		for _, v in SortedPairsByMemberValue(nut.plugin.list, "name") do
			body = (body..[[
				<p>
					<span style="font-size: 22;"><b>%s</b><br /></span>
					<span style="font-size: smaller;">
					<b>%s</b>: %s<br />
					<b>%s</b>: %s
			]]):format(v.name or "Unknown", L"desc", v.desc or L"noDesc", L"author", nut.plugin.namecache[v.author] or v.author)

			if (v.version) then
				body = body.."<br /><b>"..L"version".."</b>: "..v.version
			end

			body = body.."</span></p>"
		end

		return body
	end
end)
