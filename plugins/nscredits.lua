
local PLUGIN = PLUGIN

PLUGIN.name = "Credits Tab"
PLUGIN.desc = "A tab where players can see who made the framework/schema"
PLUGIN.author = "NS Team"

if SERVER then return end

PLUGIN.excludeList = {
    ["github_username_here"] = true
}
PLUGIN.contributorData = PLUGIN.contributorData or {}

local logoMat = nut.util.getMaterial("nutscript/logo.png")

surface.CreateFont("nutSmallCredits", {
    font = "Roboto Th",
    size = 20,
    weight = 400
})

surface.CreateFont("nutBigCredits", {
    font = "Roboto Th",
    size = 32,
    weight = 600
})

local PANEL = {}

function PANEL:Paint(w, h)
    surface.SetMaterial(logoMat)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(w * 0.5 - 128, h * 0.5 - 128, 256, 256)
end

vgui.Register("CreditsLogo", PANEL, "Panel")

PANEL = {}

function PANEL:Init()
    if nut.gui.creditsPanel then
        nut.gui.creditsPanel:Remove()
    end
    nut.gui.creditsPanel = self

    self.logo = self:Add("CreditsLogo")
    self.logo:SetTall(256)
    self.logo:Dock(TOP)

    self.nsLabel = self:Add("DLabel")
    self.nsLabel:SetFont("nutBigCredits")
    self.nsLabel:SetText("NutScript")
    self.nsLabel:SetContentAlignment(5)
    self.nsLabel:SizeToContents()
    self.nsLabel:Dock(TOP)

    self.repoLabel = self:Add("DLabel")
    self.repoLabel:SetFont("nutSmallCredits")
    self.repoLabel:SetText("https://github.com/NutScript")
    self.repoLabel:SetMouseInputEnabled(true)
    self.repoLabel:SetCursor("hand")
    self.repoLabel:SetContentAlignment(5)
    self.repoLabel:SizeToContents()
    self.repoLabel:Dock(TOP)
    self.repoLabel:DockMargin(0, 0, 0, 48)
    self.repoLabel.DoClick = function()
        gui.OpenURL("https://github.com/NutScript")
    end

    self.contribList = self:Add("DIconLayout")
    self.contribList:Dock(TOP)
    self.contribList:SetSpaceX(8)
    self.contribList:SetSpaceY(8)

    if (#PLUGIN.contributorData == 0) then
        http.Fetch("https://api.github.com/repos/NutScript/NutScript/contributors?per_page=100",
            function(body, length, headers, code)
                if (#PLUGIN.contributorData > 0) then
                    self:RebuildContributors()

                    return
                end

                local contributors = util.JSONToTable(body)

                for k, v in pairs(contributors) do
                    if (not PLUGIN.excludeList[v.login]) then
                        table.insert(PLUGIN.contributorData, {url = v.html_url, avatar_url = v.avatar_url, name = v.login})
                    end
                end
            end, function(message) end, {})
    else
        self:RebuildContributors()
    end
end

function PANEL:RebuildContributors()
    self.contribList:Clear()
    self:LoadContributor(1, true)
end

function PANEL:LoadContributor(contributor, bLoadNextChunk)
    if (PLUGIN.contributorData[contributor]) then
        if (BRANCH == "x86-64") then
            local container = self.contribList:Add("Panel")
            container:SetSize(96, 116)
            container.highlightAlpha = 0
            container.Paint = function(this, width, height)
                if (this:IsHovered()) then
                    this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 128)
                else
                    this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 0)
                end

                surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha * 0.5))
                surface.SetMaterial(nut.util.getMaterial("vgui/gradient-d"))
                surface.DrawTexturedRect(0, 0, width, height)

                surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha))
                surface.DrawRect(0, height - 1, width, 1)
            end
            container.OnMousePressed = function(this, keyCode)
                if (keyCode == 107) then
                    gui.OpenURL(PLUGIN.contributorData[contributor].url)
                end
            end
            container.OnMouseWheeled = function(this, delta)
                self:OnMouseWheeled(delta)
            end
            container:SetCursor("hand")
            container:SetTooltip(PLUGIN.contributorData[contributor].url)

            local contributorPanel = container:Add("DHTML")
            contributorPanel:SetHTML("<style>body {overflow: hidden; margin:0;} img {height: 100%; width: 100%; border-radius: 50%;}</style><img src=\"" .. PLUGIN.contributorData[contributor].avatar_url .. "\">")
            contributorPanel:SetMouseInputEnabled(false)
            contributorPanel:Dock(FILL)
            contributorPanel:DockMargin(8, 8, 8, 8)
   
            if (bLoadNextChunk) then
                contributorPanel.OnFinishLoadingDocument = function(this, url)
                    -- load 3 at a time, nice balance between not eating up your cpu cycles and being quick to load all the avatars
                    for i = 1, 3 do
                        if (contributor + i > #PLUGIN.contributorData) then
                            return
                        end

                        self:LoadContributor(contributor + i, i == 3)
                    end
                end
            end

            local button = container:Add("DLabel")
            button:Dock(BOTTOM)
            button:SetMouseInputEnabled(false)
            button:SetFont("nutSmallCredits")
            button:SetText(PLUGIN.contributorData[contributor].name)
            button:SetContentAlignment(5)
            button:SetTall(20)
        else -- we're on 'main' branch, labels are made fast, just create them all at once
           for _, v in ipairs(PLUGIN.contributorData) do
                local button = self.contribList:Add("DLabel")
                button:SetMouseInputEnabled(true)
                button:SetText(v.name)
                button:SetFont("nutSmallCredits")
                button:SetCursor("hand")
                button:SetTooltip(v.url)
                button:SizeToContents()
                button.highlightAlpha = 0
                button.DoClick = function()
                    gui.OpenURL(v.url)
                end
                button.OnMouseWheeled = function(this, delta)
                    self:OnMouseWheeled(delta)
                end
                button.Paint = function(this, width, height)
                    if (this:IsHovered()) then
                        this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 128)
                    else
                        this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 0)
                    end

                    surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha * 0.5))
                    surface.SetMaterial(nut.util.getMaterial("vgui/gradient-d"))
                    surface.DrawTexturedRect(0, 0, width, height)

                    surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha))
                    surface.DrawRect(0, height - 1, width, 1)
                end
           end
        end
    end
end

vgui.Register("nutCreditsList", PANEL, "DScrollPanel")

hook.Add("BuildHelpMenu", "nutCreditsList", function(tabs)
	tabs["Credits"] = function()
        if helpPanel then
            local credits = helpPanel:Add("nutCreditsList")
            credits:Dock(FILL)
        end
        return ""
    end
end)
