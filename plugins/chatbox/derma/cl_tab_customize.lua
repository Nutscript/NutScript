
local PANEL = {}

local TEXT_COLOR = Color(255, 255, 255, 200)

function PANEL:Init()
	self:SetSize(ScrW() * 0.15, ScrH() * 0.3)
	self:Center()

	self:SetTitle("Tab Customize")
	self:MakePopup()

	surface.SetFont("nutBigFont")

	self.nameEntry = self:Add("DTextEntry")
	self.nameEntry:Dock(TOP)
	self.nameEntry:DockMargin(0, 0, 0, 4)
	self.nameEntry:SetFont("nutBigFont")
	self.nameEntry:SetTall(select(2, surface.GetTextSize("W")))
	self.nameEntry:SetPlaceholderText("Tab Name")
	self.nameEntry:SetPaintBackground(false)
	self.nameEntry:SetTextColor(TEXT_COLOR)
	self.nameEntry:SetHighlightColor(nut.config.get("color"))
	self.nameEntry:SetCursorColor(TEXT_COLOR)
	self.nameEntry.Paint = function(this, width, height)
		surface.SetDrawColor(0, 0, 0, 127)
		surface.DrawRect(0, 0, width, height)

		derma.SkinHook("Paint", "TextEntry", this, width, height)
	end

	surface.SetFont("nutMediumLightFont")

	self.filterEntry = self:Add("DTextEntry")
	self.filterEntry:Dock(TOP)
	self.filterEntry:DockMargin(0, 0, 0, 4)
	self.filterEntry:SetFont("nutMediumLightFont")
	self.filterEntry:SetTall(select(2, surface.GetTextSize("W")))
	self.filterEntry:SetPlaceholderText("Filter")
	self.filterEntry:SetPaintBackground(false)
	self.filterEntry:SetTextColor(TEXT_COLOR)
	self.filterEntry:SetHighlightColor(nut.config.get("color"))
	self.filterEntry:SetCursorColor(TEXT_COLOR)
	self.filterEntry.OnTextChanged = function(this)
		local text = this:GetText()

		for k, v in pairs(self.scroll:GetCanvas():GetChildren()) do
			if (!string.find(v.filter, text)) then
				v.oldHeight = v.oldHeight or v:GetTall()
				v:SizeTo(-1, 0, 0.1, nil, nil, function(anim, panel)
					panel:DockMargin(0, 0, 0, 0)
				end)
			else
				v:SizeTo(-1, v.oldHeight or -1, 0.1, nil, nil, function(anim, panel)
					panel:DockMargin(0, 0, 0, 4)
				end)
			end
		end
	end
	self.filterEntry.Paint = function(this, width, height)
		surface.SetDrawColor(0, 0, 0, 127)
		surface.DrawRect(0, 0, width, height)

		derma.SkinHook("Paint", "TextEntry", this, width, height)
	end

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)

	self.filter = {}

	for _, v in pairs(nut.chat.classes) do
		if (v.filter) then
			self.filter[v.filter] = true
		end
	end

	self.modified = false

	for k in pairs(self.filter) do
		local b = self.scroll:Add("DButton")
		b:Dock(TOP)
		b:DockMargin(0, 0, 0, 4)
		b:SetText(k)
		b.filter = k
		b.DoClick = function(this)
			self.modified = true
			self.filter[k] = !self.filter[k]
		end
		b.Paint = function(this, width, height)
			if (self.filter[k] or this:IsHovered()) then
				surface.SetDrawColor(this:IsHovered() and (self.filter[k] and Color(255, 0, 0) or Color(0, 255, 0)) or nut.config.get("color"))
				surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
				surface.DrawTexturedRect(0, 0, width, height)
			end
		end
	end

	self.save = self:Add("DButton")
	self.save:Dock(BOTTOM)
	self.save:SetText("Save Tab")
	self.save.DoClick = function(this)
		if (self.nameEntry:GetValue():find("%S")) then
			self:Remove()

			local filterTbl = {}

			if (!self.modified) then
				table.insert(filterTbl, ".")
			else
				for k, v in pairs(self.filter) do
					if (v) then
						table.insert(filterTbl, k)
					end
				end
			end

			local index = self.index or #nut.gui.chat.filterTabs + 1

			nut.gui.chat.filterTabs[index] = {
				name = self.nameEntry:GetValue(),
				filter = filterTbl
			}
			nut.gui.chat:rebuildTabs()
		else
			nut.util.notify("invalid name")
		end
	end
	self.save.Paint = function(this, width, height)
		surface.SetDrawColor(nut.config.get("color"))
		surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
		surface.DrawTexturedRect(-width * (this:IsHovered() and 0 or 1), 0, width * (this:IsHovered() and 1 or 2), height)
	end
end

function PANEL:setFilter(index, filterData)
	self.nameEntry:SetText(filterData.name)
	self.index = index

	local filterTbl = filterData.filter
	if (filterTbl[1] == ".") then
		return
	end

	self.modified = true

	local filter = {}

	for _, v in pairs(filterTbl) do
		filter[v] = true
	end

	for k in pairs(self.filter) do
		self.filter[k] = filter[k] or false
	end
end

vgui.Register("nutChatboxTabCustomize", PANEL, "DFrame")
