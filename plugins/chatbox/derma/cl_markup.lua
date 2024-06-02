
local PANEL = {}

function PANEL:Init()
	hook.Add("LoadFonts", self, function(this)
		if (this.text) then
			this:setMarkup(this.text, this.onDrawText)
		end
	end)
end

function PANEL:setMarkup(text, onDrawText)
	self:InvalidateParent(true)
	self:InvalidateLayout(true)

	self.text = text
	self.onDrawText = onDrawText

	local object = nut.markup.parse(text, self:GetWide())
	object.onDrawText = onDrawText

	self:SetTall(object:getHeight())
	self.Paint = function(this, width, height)
		object:draw(0, 0)
	end
end

vgui.Register("nutMarkupPanel", PANEL, "DPanel")
