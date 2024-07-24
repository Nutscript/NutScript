local gradientU = nut.util.getMaterial("vgui/gradient-u")
local gradientD = nut.util.getMaterial("vgui/gradient-d")
local gradientL = nut.util.getMaterial("vgui/gradient-l")
local gradientR = nut.util.getMaterial("vgui/gradient-r")
local gradientC = nut.util.getMaterial("gui/center_gradient")
local palette = palette or {}
local SKIN = {}
SKIN.fontFrame = "BudgetLabel"
SKIN.fontTab = "nutSmallFont"
SKIN.fontButton = "nutSmallFont"
SKIN.Colours = table.Copy(derma.SkinList.Default.Colours)
SKIN.Colours.Window.TitleActive = Color(0, 0, 0)
SKIN.Colours.Window.TitleInactive = Color(255, 255, 255)
local defaultLight, defaultDark = color_white, Color(80, 80, 80)
SKIN.Colours.Button.Normal = defaultDark
SKIN.Colours.Button.Hover = defaultLight
SKIN.Colours.Button.Down = Color(180, 180, 180)
SKIN.Colours.Button.Disabled = Color(0, 0, 0, 100)
local clamp = function(value) return math.Clamp(value, 0.2, 1) end
local toColor = function(baseColor) return Color(baseColor.r, baseColor.g, baseColor.b) end
local themeGenerator = {
	["dark"] = function(h, s, l)
		local secondary = HSVToColor(h, s, l - 0.5 <= 0.2 and l + 0.3 or l - 0.5)
		local background = HSVToColor(h, s - 0.3 < 0.1 and s + 0.3 or s - 0.3, l - 0.5 <= 0.2 and l + 0.3 or l - 0.5)
		local light = HSVToColor(h, 0.1, 1)
		local dark = HSVToColor(h, 1, 0.2)
		return toColor(secondary), toColor(background), toColor(light), toColor(dark)
	end,
	["light"] = function(h, s, l)
		local secondary = HSVToColor(h, s, l - 0.2 <= 0.2 and l + 0.6 or l - 0.2)
		local background = HSVToColor(h, s - 0.3 < 0.1 and s + 0.3 or s - 0.3, clamp(s + 0.05))
		local light = HSVToColor(h, 0.1, 1)
		local dark = HSVToColor(h, 1, 0.2)
		return toColor(secondary), toColor(background), toColor(light), toColor(dark)
	end,
}

-- Function to create a monochromatic color palette
local function createMonochromaticPalette()
	-- Calculate the HSL values of the base color
	local theme = nut.config.get("colorAutoTheme", "dark")
	local primary = nut.config.get("color")
	local h, s, l = ColorToHSV(primary)
	local secondary = nut.config.get("colorSecondary", Color(55, 87, 140))
	local background = nut.config.get("colorBackground", Color(45, 45, 45))
	local light, dark = defaultLight, defaultDark
	if themeGenerator[theme] ~= nil then secondary, background, light, dark = themeGenerator[theme](h, s, l) end
	return {
		primary = primary,
		secondary = secondary,
		background = background,
		light = light,
		dark = dark
	}
end

hook.Add("PostDrawHUD", "nutdebugTestlalal", function()
	--[[ if not table.IsEmpty(palette) then
			local x, y = 0, 0
			local w, h = 100, 100
			for i = 1, #palette do
				local color = palette[i]
				surface.SetDrawColor(color)
				surface.DrawRect(x, y, w, h)
				--draw text inside the box with the color r,g,b
				draw.SimpleText("R: "..color.r, "nutSmallFont", x + w/2, y + h*0.25, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("G: "..color.g, "nutSmallFont", x + w/2, y + h*0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText("B: "..color.b, "nutSmallFont", x + w/2, y + h*0.75, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				x = x + w
			end
		end ]]
end)

local function updateColors()
	timer.Simple(0, function()
		palette = createMonochromaticPalette()
		local primary, secondary, background, light, dark = palette.primary, palette.secondary, palette.background, palette.light, palette.dark
		nut.config.set("color", primary)
		nut.config.set("colorSecondary", secondary)
		nut.config.set("colorBackground", background)
		if themeGenerator[nut.config.get("colorAutoTheme", "dark")] ~= nil then
			nut.config.setDefault("colorSecondary", secondary)
			nut.config.setDefault("colorBackground", background)
		end

		SKIN.Colours.Window.TitleActive = secondary
		SKIN.Colours.Window.TitleInactive = Color(255, 255, 255)
		SKIN.tex.CategoryList.Header = function(x, y, w, h)
			surface.SetDrawColor(primary)
			surface.DrawRect(x, y, w, h)
		end

		SKIN.Colours.Button.Normal = light
		--[[ 			SKIN.Colours.Button.Normal = secondary
			SKIN.Colours.Button.Hover = light
			SKIN.Colours.Button.Down = dark
			SKIN.Colours.Button.Disabled = background ]]
		SKIN.colTextEntryTextHighlight = secondary
	end)
end

hook.Add("nutUpdateColors", "nutSkinUpdateColors", updateColors)
local function updateTextColors()
	timer.Simple(0, function()
		local normal = nut.config.get("colorText")
		local h, s, v = ColorToHSV(normal)
		local h1, s1, v1 = ColorToHSV(nut.config.get("color"))
		local hover = toColor(HSVToColor(h1, s, v))
		local down = toColor(HSVToColor(h, 0, v * 0.2))
		local bright = toColor(HSVToColor(h, 0, v * 1.2))
		local dark = toColor(HSVToColor(h, 0, v * 0.8))
		local disabled = toColor(HSVToColor(h, 0, v * 0.5))
		SKIN.Colours.Button.Normal = normal
		SKIN.Colours.Button.Hover = hover
		SKIN.Colours.Button.Down = down
		SKIN.Colours.Button.Disabled = disabled
		SKIN.Colours.Tree.Normal = normal
		SKIN.Colours.Tree.Hover = hover
		SKIN.Colours.Tree.Selected = down
		SKIN.Colours.Category.Line.Text = normal
		SKIN.Colours.Category.Line.Text_Hover = hover
		SKIN.Colours.Category.Line.Text_Selected = down
		SKIN.Colours.Category.LineAlt.Text = normal
		SKIN.Colours.Category.LineAlt.Text_Hover = hover
		SKIN.Colours.Category.LineAlt.Text_Selected = down
		SKIN.Colours.Label.Default = normal
		SKIN.Colours.Label.Bright = bright
		SKIN.Colours.Label.Dark = dark
		SKIN.Colours.Label.Highlight = hover
	end)

	if IsValid(nut.gui.score) then nut.gui.score:Remove() end
end

hook.Add("nutUpdateColors", "nutSkinUpdateTextColors", updateTextColors)
local function nsBackground(panel, x, y, w, h, alt)
	local colorR, colorG, colorB = nut.config.get("color"):Unpack()
	local backgroundR, backgroundG, backgroundB = nut.config.get("colorBackground"):Unpack()
	nut.util.drawBlur(panel, 10)
	surface.SetDrawColor(alt and 255 or colorR, alt and 255 or colorG, alt and 255 or colorB, 200)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(backgroundR, backgroundG, backgroundB, 255)
	surface.SetMaterial(gradientD)
	surface.DrawTexturedRect(x, y, w, h)
	surface.SetMaterial(gradientR)
	surface.DrawTexturedRect(x, y, w, h)
end

local function nsComboBackground(panel, x, y, w, h, alt)
	local colorR, colorG, colorB = nut.config.get("color"):Unpack()
	local backgroundR, backgroundG, backgroundB = nut.config.get("colorSecondary"):Unpack()
	--nut.util.drawBlur(panel, 10)
	surface.SetDrawColor(backgroundR, backgroundG, backgroundB, 255)
	surface.DrawRect(x, y, w, h)
	if alt then
		surface.SetDrawColor(colorR, colorG, colorB, 255)
		surface.SetMaterial(gradientL)
		surface.DrawTexturedRect(x, y, w, h)
	end
end

function SKIN:PaintFrame(panel, w, h)
	nsBackground(panel, 0, 0, w, h)
	surface.SetDrawColor(nut.config.get("color"))
	surface.DrawRect(0, 0, panel:GetWide(), 24)
	surface.SetDrawColor(nut.config.get("color"))
	surface.DrawOutlinedRect(0, 0, panel:GetWide(), panel:GetTall())
end

function SKIN:PaintPanel(panel)
	if not panel.m_bBackground then return end
	if panel.GetPaintBackground and not panel:GetPaintBackground() then return end
	local backgroundR, backgroundG, backgroundB = nut.config.get("colorBackground"):Unpack()
	local w, h = panel:GetWide(), panel:GetTall()
	surface.SetDrawColor(backgroundR, backgroundG, backgroundB, 100)
	surface.DrawRect(0, 0, w, h)
	surface.DrawOutlinedRect(0, 0, w, h)
end

function SKIN:PaintButton(panel)
	if not panel.m_bBackground then return end
	if panel.GetPaintBackground and not panel:GetPaintBackground() then return end
	local backgroundR, backgroundG, backgroundB = nut.config.get("colorBackground"):Unpack()
	local secondaryR, secondaryG, secondaryB = nut.config.get("colorSecondary"):Unpack()
	local w, h = panel:GetWide(), panel:GetTall()
	local alpha = 50
	if panel:GetDisabled() then
		alpha = 10
	elseif panel.Depressed then
		alpha = 100
	elseif panel.Hovered then
		alpha = 75
	end

	surface.SetDrawColor(backgroundR, backgroundG, backgroundB, alpha)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(secondaryR, secondaryG, secondaryB, 180)
	surface.DrawOutlinedRect(0, 0, w, h)
	surface.SetDrawColor(180, 180, 180, 2)
	surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
end

-- I don't think we gonna need minimize button and maximize button.
function SKIN:PaintWindowMinimizeButton(panel, w, h)
end

function SKIN:PaintWindowMaximizeButton(panel, w, h)
end

function SKIN:PaintCollapsibleCategory(panel, w, h)
	if h <= panel:GetHeaderHeight() then
		--self.tex.CategoryList.Header( 0, 0, w, h )
		draw.RoundedBoxEx(6, 0, 0, w, h, palette.secondary, true, true, false, false)
		-- Little hack, draw the ComboBox's dropdown arrow to tell the player the category is collapsed and not empty
		if not panel:GetExpanded() then self.tex.Input.ComboBox.Button.Down(w - 18, h / 2 - 8, 15, 15) end
		return
	end

	--self.tex.CategoryList.InnerH( 0, 0, w, panel:GetHeaderHeight() )
	draw.RoundedBoxEx(6, 0, 0, w, panel:GetHeaderHeight(), palette.primary, true, true, false, false)
	--self.tex.CategoryList.Inner( 0, panel:GetHeaderHeight(), w, h - panel:GetHeaderHeight() )
	nsBackground(panel, 0, panel:GetHeaderHeight(), w, h - panel:GetHeaderHeight())
end

--[[---------------------------------------------------------
		Panel
	-----------------------------------------------------------]]
function SKIN:PaintPanel(panel, w, h)
	if not panel.m_bBackground then return end
	nsBackground(panel, 0, 0, w, h)
end

--[[---------------------------------------------------------
		Tree
	-----------------------------------------------------------]]
function SKIN:PaintTree(panel, w, h)
	if not panel.m_bBackground then return end
	nsBackground(panel, 0, 0, w, h)
end

--[[---------------------------------------------------------
		Menu
	-----------------------------------------------------------]]
function SKIN:PaintMenu(panel, w, h)
	if panel:GetDrawColumn() then
		self.tex.MenuBG_Column(0, 0, w, h)
	else
		nsBackground(panel, 0, 0, w, h)
	end
end

--[[---------------------------------------------------------
		MenuOption
	-----------------------------------------------------------]]
function SKIN:PaintMenuOption(panel, w, h)
	--[[ if ( panel.m_bBackground && !panel:IsEnabled() ) then
			surface.SetDrawColor( Color( 0, 0, 0, 50 ) )
			surface.DrawRect( 0, 0, w, h )
		end ]]
	--[[ 	if ( panel.m_bBackground && ( panel.Hovered || panel.Highlight) ) then
			self.tex.MenuBG_Hover( 0, 0, w, h )
		end ]]
	if panel:GetChecked() then self.tex.Menu_Check(5, h / 2 - 7, 15, 15) end
	nsComboBackground(panel, 0, 0, w, h, panel.m_bBackground and (panel.Hovered or panel.Highlight))
end

--[[---------------------------------------------------------
		ComboBox
	-----------------------------------------------------------]]
function SKIN:PaintComboBox(panel, w, h)
	if panel:GetDisabled() then return self.tex.Input.ComboBox.Disabled(0, 0, w, h) end
	if panel.Depressed or panel:IsMenuOpen() then return self.tex.Input.ComboBox.Down(0, 0, w, h) end
	if panel.Hovered then
		nsComboBackground(panel, 0, 0, w, h, true)
		return
	end

	nsComboBackground(panel, 0, 0, w, h)
end

function SKIN:PaintCategoryButton(panel, w, h)
	local r, g, b = nut.config.get("colorSecondary"):Unpack()
	local r2, g2, b2 = r - 25, g - 25, b - 25
	if panel.AltLine then
		surface.SetDrawColor(r, g, b)
	else
		surface.SetDrawColor(r2, g2, b2)
	end

	surface.DrawRect(0, 0, w, h)
end

function SKIN:PaintListBox(panel, w, h)
	nsBackground(panel, 0, 0, w, h)
end

function SKIN:PaintListView(panel, w, h)
	if not panel.m_bBackground then return end
	nsBackground(panel, 0, 0, w, h)
end

function SKIN:PaintMenuBar(panel, w, h)
	local colorR, colorG, colorB = nut.config.get("color"):Unpack()
	local backgroundR, backgroundG, backgroundB = nut.config.get("colorBackground"):Unpack()
	nut.util.drawBlur(panel, 10)
	surface.SetDrawColor(backgroundR, backgroundG, backgroundB, 200)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(colorR, colorG, colorB, 255)
	surface.SetMaterial(gradientC)
	surface.DrawTexturedRect(0, 0, w, h)
end

function SKIN:PaintProgress(panel, w, h)
	local colorR, colorG, colorB = nut.config.get("color"):Unpack()
	local backgroundR, backgroundG, backgroundB = nut.config.get("colorBackground"):Unpack()
	surface.SetDrawColor(backgroundR, backgroundG, backgroundB, 200)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(colorR, colorG, colorB, 255)
	--surface.SetMaterial(gradientC)
	surface.DrawRect(0, 0, w * panel:GetFraction(), h)
end

derma.DefineSkin("nutscript", "The base skin for the NutScript framework.", SKIN)
derma.RefreshSkins()