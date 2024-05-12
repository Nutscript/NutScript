local PANEL = {}
	local paintFunctions = {}
	paintFunctions[0] = function(this, w, h)
		surface.SetDrawColor(0, 0, 0, 50)
		surface.DrawRect(0, 0, w, h)
	end
	paintFunctions[1] = function(this, w, h)
	end

	function PANEL:Init()
		if (IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end

		nut.gui.score = self

		self:SetSize(ScrW() * nut.config.get("sbWidth"), ScrH() * nut.config.get("sbHeight"))
		self:Center()

		self.title = self:Add("DLabel")
		self.title:SetText(GetHostName())
		self.title:SetFont("nutBigFont")
		self.title:SetContentAlignment(5)
		self.title:SetTextColor(nut.config.get("colorText", color_white))
		self.title:SetExpensiveShadow(1, color_black)
		self.title:Dock(TOP)
		self.title:SizeToContentsY()
		self.title:SetTall(self.title:GetTall() + 16)
		self.title.Paint = function(this, w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
		end

		self.scroll = self:Add("DScrollPanel")
		self.scroll:Dock(FILL)
		self.scroll:DockMargin(1, 0, 1, 0)
		self.scroll.VBar:SetWide(0)

		self.layout = self.scroll:Add("DListLayout")
		self.layout:Dock(TOP)

		self.teams = {}
		self.slots = {}
		self.i = {}

		for k, v in ipairs(nut.faction.indices) do
			local color = team.GetColor(k)
			local r, g, b = color.r, color.g, color.b

			local list = self.layout:Add("DListLayout")
			list:Dock(TOP)
			list:SetTall(28)
			list.Think = function(this)
				for k2, v2 in ipairs(team.GetPlayers(k)) do
					if (not IsValid(v2.nutScoreSlot) or v2.nutScoreSlot:GetParent() ~= this) then
						if (IsValid(v2.nutPlayerSlot)) then
							v2.nutPlayerSlot:SetParent(this)
						else
							self:addPlayer(v2, this)
						end
					end
				end
			end

			local header = list:Add("DLabel")
			header:Dock(TOP)
			header:SetText(L(v.name))
			header:SetTextInset(3, 0)
			header:SetFont("nutMediumFont")
			header:SetTextColor(nut.config.get("colorText", color_white))
			header:SetExpensiveShadow(1, color_black)
			header:SetTall(28)
			header.Paint = function(this, w, h)
				surface.SetDrawColor(r, g, b, 20)
				surface.DrawRect(0, 0, w, h)
			end

			self.teams[k] = list
		end
	end

	function PANEL:Think()
		if ((self.nextUpdate or 0) < CurTime()) then
			self.title:SetText(nut.config.get("sbTitle", GetHostName()))

			local visible, amount

			for faction, v in ipairs(self.teams) do
				visible, amount = v:IsVisible(), team.NumPlayers(faction)

				if (visible and amount == 0) then
					v:SetVisible(false)
					self.layout:InvalidateLayout()
				elseif (not visible and amount > 0) then
					v:SetVisible(true)
				end

				if (amount ~= 0) then
					v:SetVisible(hook.Run("ShowFactionInScoreboard", faction) ~= false or LocalPlayer():IsAdmin())
				end
			end

			for _, v in pairs(self.slots) do
				if (IsValid(v)) then
					v:update()
				end
			end

			self.nextUpdate = CurTime() + 0.1
		end
	end

	function PANEL:addPlayer(client, parent)
		if (not client:getChar() or not IsValid(parent)) then
			return
		end

		local slot = parent:Add("DPanel")
		slot:Dock(TOP)
		slot:SetTall(64)
		slot:DockMargin(0, 0, 0, 1)
		slot.character = client:getChar()

		client.nutScoreSlot = slot

		slot.model = slot:Add("nutSpawnIcon")
		slot.model:SetModel(client:GetModel(), client:GetSkin())
		slot.model:SetSize(64, 64)
		slot.model.DoClick = function()
			local menu = DermaMenu()
				local options = {}

				hook.Run("ShowPlayerOptions", client, options)

				if (table.Count(options) > 0) then
					for k, v in SortedPairs(options) do
						menu:AddOption(L(k), v[2]):SetImage(v[1])
					end
				end
			menu:Open()

			RegisterDermaMenuForClose(menu)
		end
		slot.model:SetTooltip(L("sbOptions", client:steamName()))

		timer.Simple(0, function()
			if (not IsValid(slot)) then
				return
			end

			local entity = slot.model.Entity

			if (IsValid(entity)) then
				for k, v in ipairs(client:GetBodyGroups()) do
					entity:SetBodygroup(v.id, client:GetBodygroup(v.id))
				end

				for k, v in ipairs(client:GetMaterials()) do
					entity:SetSubMaterial(k - 1, client:GetSubMaterial(k - 1))
				end
			end
		end)

		slot.name = slot:Add("DLabel")
		slot.name:Dock(TOP)
		slot.name:DockMargin(65, 0, 48, 0)
		slot.name:SetTall(18)
		slot.name:SetFont("nutGenericFont")
		slot.name:SetTextColor(nut.config.get("colorText", color_white))
		slot.name:SetExpensiveShadow(1, color_black)

		if client ~= LocalPlayer() then
			slot.mute = slot:Add("DImageButton")
			slot.mute:DockMargin(5, 15, 0, 0)
			slot.mute:Dock(RIGHT)
			slot.mute:SetWide(30)
			slot.mute:Hide()
		end

		slot.ping = slot:Add("DLabel")
		slot.ping:SetPos(self:GetWide() - 48, 0)
		slot.ping:SetSize(48, 64)
		slot.ping:SetText("0")
		slot.ping.Think = function(this)
			if (IsValid(client)) then
				local ping = client:Ping()
				local text = this:GetText()
				if text ~= ping then
					this:SetText(ping)
					this:SizeToContentsX()
					this:SetPos(self:GetWide() - (24 + (string.len(this:GetText()) * 4)))
				end
			end
		end

		slot.ping:SetFont("nutGenericFont")
		slot.ping:SetContentAlignment(6)
		slot.ping:SetTextColor(nut.config.get("colorText", color_white))
		slot.ping:SetTextInset(16, 0)
		slot.ping:SetExpensiveShadow(1, color_black)

		slot.desc = slot:Add("DLabel")
		slot.desc:Dock(FILL)
		slot.desc:DockMargin(65, 0, 48, 0)
		slot.desc:SetWrap(true)
		slot.desc:SetContentAlignment(7)
		slot.desc:SetTextColor(nut.config.get("colorText", color_white))
		slot.desc:SetExpensiveShadow(1, Color(0, 0, 0, 100))
		slot.desc:SetFont("nutSmallFont")

		local oldTeam = client:Team()

		function slot:update()
			if (not IsValid(client) or not client:getChar() or not self.character or self.character ~= client:getChar() or oldTeam ~= client:Team()) then
				self:Remove()

				local i = 0

				for k, v in ipairs(parent:GetChildren()) do
					if (IsValid(v.model) and v ~= self) then
						i = i + 1
						v.Paint = paintFunctions[i % 2]
					end
				end

				return
			end

			local overrideName = hook.Run("ShouldAllowScoreboardOverride", client, "name") and hook.Run("GetDisplayedName", client, nil, "sb")
			local name = overrideName or client:Name()
			name = name:gsub("#", "\226\128\139#")

			local model = client:GetModel()
			local skin = client:GetSkin()
			local desc = hook.Run("ShouldAllowScoreboardOverride", client, "desc") and hook.Run("GetDisplayedDescription", client, "sb") or (client:getChar() and client:getChar():getDesc()) or ""
			desc = desc:gsub("#", "\226\128\139#")

			self.model:setHidden(hook.Run("ShouldAllowScoreboardOverride", client, "model"))

			if (self.lastName ~= name) then
				self.name:SetText(name)
				self.lastName = name
			end

			local entity = self.model.Entity

			if (self.lastDesc ~= desc) then
				self.desc:SetText(desc)
				self.lastDesc = desc
			end

			if (not IsValid(entity)) then
				return
			end

			if nut.config.get("allowVoice", false) then
				if IsValid(self.mute) then
					self.mute:Show()
					self.ping:SetTall(48)

					local isMuted = client:IsMuted()
					self.mute:SetImage(isMuted and "icon32/muted.png" or "icon32/unmuted.png")
					self.mute.DoClick = function()
						client:SetMuted(not isMuted)
					end
				end
			else
				if IsValid(self.mute) then
					self.mute:Hide()
					self.ping:SetTall(64)
				end
			end

			if (self.lastModel ~= model or self.lastSkin ~= skin) then
				self.model:SetModel(client:GetModel(), client:GetSkin())
				self.model:SetTooltip(L("sbOptions", client:steamName()))

				self.lastModel = model
				self.lastSkin = skin
			end

			timer.Simple(0, function()
				if (not IsValid(entity) or not IsValid(client)) then
					return
				end

				for k, v in ipairs(client:GetBodyGroups()) do
					entity:SetBodygroup(v.id, client:GetBodygroup(v.id))
				end
			end)
		end

		self.slots[#self.slots + 1] = slot

		parent:SetVisible(true)
		parent:SizeToChildren(false, true)
		parent:InvalidateLayout(true)

		local i = 0

		for k, v in ipairs(parent:GetChildren()) do
			if (IsValid(v.model)) then
				i = i + 1
				v.Paint = paintFunctions[i % 2]
			end
		end

		slot:update()

		return slot
	end

	function PANEL:OnRemove()
		CloseDermaMenus()
	end

	function PANEL:Paint(w, h)
		nut.util.drawBlur(self, 10)

		surface.SetDrawColor(30, 30, 30, 100)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
vgui.Register("nutScoreboard", PANEL, "EditablePanel")

concommand.Add("dev_reloadsb", function()
	if (IsValid(nut.gui.score)) then
		nut.gui.score:Remove()
	end
end)