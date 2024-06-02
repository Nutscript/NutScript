
local PANEL = {}

local TEXT_COLOR = Color(255, 255, 255, 200)

local function findInTable(tbl, haystack)
	for _, needle in ipairs(tbl) do
		local startPos, endPos, matched = string.find(haystack, needle)

		if (startPos) then
			return startPos, endPos, matched
		end
	end
end

function PANEL:Init()
	nut.gui.chat = self

	self.filterTabs = {
		{name = "Main", filter = {"."}}
	}

	self:SetSize(ScrW() * 0.3, ScrH() * 0.35)
	self:SetPos(ScrW() * 0.1, ScrH() - self:GetTall() - ScrH() * 0.1)

	self.texts = {}
	self.filterTbl = {}

	self.frame = g_ContextMenu:Add("DFrame")
	self.frame:SetSize(self:GetSize())
	self.frame:SetPos(self:GetPos())
	self.frame:SetTitle("Chatbox")
	self.frame:ShowCloseButton(false)
	self.frame.OnCursorMoved = function(this, cursorX, cursorY)
		if (this.Dragging) then
			self:SetPos(this:GetPos())
		end
	end
	hook.Add("OnContextMenuOpen", self.frame, function(this)
		this:SetMouseInputEnabled(true)
	end)

	surface.SetFont("nutToolTipText")

	self.headerBar = self:Add("Panel")
	self.headerBar:Dock(TOP)
	self.headerBar:SetTall(select(2, surface.GetTextSize("W")))
	self.headerBar.Paint = function(this, width, height)
		if (self.active) then
			for _, v in ipairs(this:GetChildren()) do
				v:PaintManual()
			end
		end
	end

	self.tabsContainer = self.headerBar:Add("DHorizontalScroller")
	self.tabsContainer:Dock(LEFT)
	self.tabsContainer.btnLeft:SetPaintedManually(true)
	self.tabsContainer.btnRight:SetPaintedManually(true)

	self.newTab = self.headerBar:Add("DButton")
	self.newTab:Dock(LEFT)
	self.newTab:SetFont("nutToolTipText")
	self.newTab:SetText("+")
	self.newTab:SizeToContents()
	self.newTab:SetPaintedManually(true)
	self.newTab.DoClick = function()
		if (self.tabCustomize) then
			self.tabCustomize:Remove()
		end

		self.tabCustomize = vgui.Create("nutChatboxTabCustomize")
	end
	self.newTab.Paint = function(this, width, height)
		surface.SetDrawColor(nut.config.get("color"))
		surface.SetMaterial(nut.util.getMaterial("vgui/gradient-d"))
		surface.DrawTexturedRect(0, 0, width, height * (this:IsHovered() and 1 or 2))
	end

	self.textContainer = self:Add("DScrollPanel")
	self.textContainer:Dock(FILL)
	self.textContainer.pnlCanvas:DockPadding(4, 4, 4, 4)
	self.textContainer.VBar:SetWide(0)
	self.textContainer.Paint = function(this, width, height)
		if (self.active) then
			nut.util.drawBlur(this)

			local colorR, colorG, colorB = nut.config.get("colorBackground"):Unpack()

			surface.SetDrawColor(colorR, colorG, colorB, 32)

			surface.SetMaterial(nut.util.getMaterial("vgui/gradient-u"))
			surface.DrawTexturedRect(0, 0, width, height)

			surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
			surface.DrawTexturedRect(0, 0, width, height)

			surface.SetDrawColor(0, 0, 0, 128)
			surface.DrawRect(0, 0, width, height)

			surface.SetDrawColor(nut.config.get("color"))
			surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
			surface.DrawTexturedRect(0, 0, width, 2)
		end
	end

	self.commandList = self:Add("DScrollPanel")
	self.commandList:Dock(FILL)
	self.commandList:DockMargin(0, 2, 0, 0)
	self.commandList.pnlCanvas:DockPadding(4, 4, 4, 4)
	self.commandList.VBar:SetWide(0)
	self.commandList.Paint = function(this, width, height)
		if (!self.active or !self.arguments or self.activeCommand) then return end

		local commandsVisible = 0

		for k, v in ipairs(this:GetCanvas():GetChildren()) do
			if (v.visible) then
				commandsVisible = commandsVisible + 1
			end
		end

		if (commandsVisible > 0) then
			nut.util.drawBlur(this)

			surface.SetDrawColor(0, 0, 0, 192)
			surface.DrawRect(0, 0, width, height)

			for k, v in pairs(this:GetCanvas():GetChildren()) do
				v:PaintManual()
			end
		end
	end

	for k, v in SortedPairs(nut.command.list) do
		if (v.onCheckAccess and !v.onCheckAccess(LocalPlayer())) then
			continue
		else
			local b = self.commandList:Add("DButton")
			b:Dock(TOP)
			b:DockMargin(0, 0, 0, 4)
			b:SetText("")
			b:SetPaintedManually(true)
			b.command = k
			b.visible = true
			b.DoClick = function()
				self.entry:SetText("/" .. k)
				self.entry:SetCaretPos(string.len(self.entry:GetText()))
			end
			b.Paint = function(this, width, height)
				surface.SetDrawColor(this:IsHovered() and nut.config.get("color") or color_transparent)
				surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
				surface.DrawTexturedRect(0, 0, width, height)
			end

			local c = b:Add("DLabel")
			c:Dock(LEFT)
			c:DockMargin(0, 0, 4, 0)
			c:SetFont("nutToolTipText")
			c:SetText("/" .. (v.realCommand or k))
			c:SizeToContents()
			c:SetContentAlignment(4)
			c:SetPaintBackground(false)

			local syntax = b:Add("DLabel")
			syntax:Dock(LEFT)
			syntax:SetFont("nutToolTipText")
			syntax:SetText(v.syntax)
			syntax:SizeToContents()
			syntax:SetContentAlignment(4)
			syntax:SetPaintBackground(false)
		end
	end

	surface.SetFont("nutChatFont")

	self.entryContainer = self:Add("Panel")
	self.entryContainer:Dock(BOTTOM)
	self.entryContainer:DockPadding(4, 8, 4, 8)
	self.entryContainer:SetTall(select(2, surface.GetTextSize("W")) + 16)
	self.entryContainer.Paint = function(this, width, height)
		if (self.active) then
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, width, height)

			surface.SetDrawColor(32, 32, 32, 128)
			surface.SetMaterial(nut.util.getMaterial("vgui/gradient-u"))
			surface.DrawTexturedRect(0, 0, width, height * 1.5)
		end
	end
	hook.Add("LoadFonts", self.entryContainer, function(this)
		surface.SetFont("nutChatFont")
		this:SetTall(select(2, surface.GetTextSize("W")) + 16)
	end)

	surface.SetFont("nutToolTipText")

	self.commandContainer = self:Add("Panel")
	self.commandContainer:DockPadding(4, 8, 4, 8)
	self.commandContainer:SetSize(self:GetWide(), select(2, surface.GetTextSize("W")) + 16)
	self.commandContainer:SetMouseInputEnabled(false)

	self:InvalidateLayout(true)
	local x, y = self.entryContainer:GetPos()
	self.commandContainer:SetPos(x, y - self.commandContainer:GetTall())

	self.commandContainer.Paint = function(this, width, height)
		if (!self.active) then return end

		if (self.activeCommand) then
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, width, height)

			for k, v in pairs(this:GetChildren()) do
				v:PaintManual()
			end
		end
	end
	hook.Add("LoadFonts", self.commandContainer, function(this)
		surface.SetFont("nutToolTipText")
		this:SetTall(select(2, surface.GetTextSize("W")) + 16)

		self:InvalidateLayout(true)
		local x, y = self.entryContainer:GetPos()
		this:SetPos(x, y - this:GetTall())
	end)

	self.commandName = self.commandContainer:Add("DLabel")
	self.commandName:Dock(LEFT)
	self.commandName:DockMargin(0, 0, 4, 0)
	self.commandName:SetFont("nutToolTipText")
	self.commandName:SetText("")
	self.commandName:SetPaintedManually(true)

	self.commandSyntax = self.commandContainer:Add("DLabel")
	self.commandSyntax:Dock(LEFT)
	self.commandSyntax:SetFont("nutToolTipText")
	self.commandSyntax:SetText("")
	self.commandSyntax:SetPaintedManually(true)

	self.entry = self.entryContainer:Add("DTextEntry")
	self.entry:Dock(FILL)
	self.entry:SetFont("nutChatFont")
	self.entry:SetAllowNonAsciiCharacters(true)
	self.entry:DockMargin(0, 0, 0, 0)
	self.entry.OnEnter = function(this)
		local text = this:GetText()

		self:setActive(false)
		self.arguments = nil

		if (text:find("%S")) then
			netstream.Start("msg", text)
		end
	end
	self.entry.OnTextChanged = function(this)
		local text = this:GetText()

		hook.Run("ChatTextChanged", text)

		if (text:sub(1, 1) == "/") then
			self.arguments = nut.command.extractArgs(text:sub(2))

			for _, v in ipairs(self.commandList:GetCanvas():GetChildren()) do
				if (!v.command:find(text:sub(2))) then
					v.visible = false
					v.oldHeight = v.oldHeight or v:GetTall()
					v:SizeTo(-1, 0, 0.1, nil, nil, function(anim, panel)
						panel:DockMargin(0, 0, 0, 0)
					end)
				else
					v.visible = true
					v:SizeTo(-1, v.oldHeight or -1, 0.1, nil, nil, function(anim, panel)
						panel:DockMargin(0, 0, 0, 4)
					end)
				end
			end

			local command = text:match("^/(%S+)")

			if (command and command:sub(1, 1) == "/") then
				command = "/"
			end

			self.activeCommand = nut.command.list[command]

			if (self.activeCommand) then
				self.commandName:SetText(self.activeCommand.realCommand or command)
				self.commandName:SizeToContents()

				self.commandSyntax:SetText(self.activeCommand.syntax)
				self.commandSyntax:SizeToContents()
			end
		else
			self.activeCommand = nil
			self.arguments = nil
		end
	end
	self.entry.OnFocusChanged = function(this, gained)
		if (!gained) then
			this:RequestFocus()
		end
	end
	self.entry.Paint = function(this, width, height)
		this:DrawTextEntryText(TEXT_COLOR, nut.config.get("color"), TEXT_COLOR)
	end

	self:rebuildTabs()
	self:setActive(false)
end

function PANEL:Remove()
	self.frame:Remove()

	baseclass.Get("EditablePanel").Remove(self)
end

function PANEL:Think()
	if (self.active) then
		if (gui.IsGameUIVisible()) then
			self:setActive(false)
		end
	end
end

function PANEL:rebuildTabs()
	self.tabsContainer:GetCanvas():Clear()

	local totalWidth = 0

	for k, v in ipairs(self.filterTabs) do
		local b = vgui.Create("DButton", self.tabsContainer)
		self.tabsContainer:AddPanel(b)
		b:Dock(LEFT)
		b:SetFont("nutToolTipText")
		b:SetText(v.name)
		b:SizeToContents()
		totalWidth = totalWidth + b:GetWide()
		b:SetPaintedManually(true)
		b.DoClick = function(this)
			if (this.state != true) then
				this.state = true
				self.filterTbl = v.filter
				self.selectedFilter = k

				for _, v in ipairs(self.tabsContainer:GetCanvas():GetChildren()) do
					if (v != this) then
						v.state = false
					end
				end

				local lastText

				for _, textPanel in ipairs(self.texts) do
					if (textPanel.chatClass and textPanel.chatClass.filter) then
						if (!findInTable(v.filter, textPanel.chatClass.filter)) then
							textPanel:SetVisible(false)
						else
							textPanel:SetVisible(true)
							lastText = textPanel
						end
					else
						lastText = textPanel
					end
				end

				self.textContainer:GetCanvas():InvalidateLayout(true)

				if (IsValid(lastText)) then
					self.textContainer:InvalidateLayout(true)

					local x, y = self.textContainer:GetCanvas():GetChildPosition(lastText)
					local w, h = lastText:GetSize()

					y = y + h * 0.5
					y = y - self.textContainer:GetTall() * 0.5

					self.textContainer.VBar:SetScroll(y)
				end
			end
		end
		b.DoRightClick = function(this)
			local menu = DermaMenu()

			local customizeButton = menu:AddOption("Customize", function()
				vgui.Create("nutChatboxTabCustomize"):setFilter(k, v)
			end)
			customizeButton:SetIcon("icon16/pencil.png")	

			menu:AddSpacer()

			local deleteButton = menu:AddOption("Delete", function()
				table.remove(self.filterTabs, k)

				if (self.selectedFilter == k) then
					self.selectedFilter = nil
					self.filterTbl = {}
				end

				self:rebuildTabs()
			end)
			deleteButton:SetIcon("icon16/cross.png")

			menu:Open()
		end
		b.Paint = function(this, width, height)
			surface.SetDrawColor(nut.config.get("color"))

			if (this.state) then
				surface.DrawRect(0, 0, width, height)
			else
				surface.SetMaterial(nut.util.getMaterial("vgui/gradient-d"))
				surface.DrawTexturedRect(0, 0, width, height * (this:IsHovered() and 1 or 2))
			end
		end

		if (#self.filterTbl == 0 or self.selectedFilter == k) then
			b:DoClick()
		end
	end

	self.tabsContainer:SetWide(totalWidth)
end

function PANEL:setActive(active)
	if (g_ContextMenu:IsVisible()) then return end

	self.active = active

	if (active) then
		self:MakePopup()
		self.entry:RequestFocus()
	end

	self:SetKeyboardInputEnabled(active)
	self:SetMouseInputEnabled(active)

	self.entry:SetVisible(active)
	self.entry:SetText("")
	self.entry:OnTextChanged()
end

function PANEL:addText(...)
	local text = "<font=nutChatFont>"

	if (CHAT_CLASS) then
		text = "<font="..(CHAT_CLASS.font or "nutChatFont")..">"
	end

	text = hook.Run("ChatAddText", text, ...) or text

	for k, v in ipairs({...}) do
		if (type(v) == "IMaterial") then
			local ttx = v:GetName()
			text = text.."<img="..ttx..","..v:Width().."x"..v:Height()..">"
		elseif (IsColor(v) and v.r and v.g and v.b) then
			text = text.."<color="..v.r..","..v.g..","..v.b..">"
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			text = text.."<color="..color.r..","..color.g..","..color.b..">"..v:Name():gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("#", "\226\128\139#")
		else
			text = text..tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
			text = text:gsub("%b**", function(value)
				local inner = value:sub(2, -2)

				if (inner:find("%S")) then
					return "<font=nutChatFontItalics>"..value:sub(2, -2).."</font>"
				end
			end)
		end
	end

	text = text.."</font>"

	local panel = self.textContainer:Add("nutMarkupPanel")
	panel:Dock(TOP)
	panel:setMarkup(text, OnDrawText)
	panel.chatClass = CHAT_CLASS
	panel.start = CurTime() + 15
	panel.finish = panel.start + 20
	panel.Think = function(this)
		if (self.active) then
			this:SetAlpha(255)
		else
			this:SetAlpha((1 - math.TimeFraction(this.start, this.finish, CurTime())) * 255)
		end
	end

	self.textContainer:GetCanvas():InvalidateLayout(true)

	if (CHAT_CLASS and CHAT_CLASS.filter and !findInTable(self.filterTbl, CHAT_CLASS.filter)) then
		panel:SetVisible(false)
	else
		self.textContainer:ScrollToChild(panel)
	end

	table.insert(self.texts, panel)
end

vgui.Register("nutChatBox", PANEL, "EditablePanel")
