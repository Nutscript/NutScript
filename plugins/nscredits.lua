
local PLUGIN = PLUGIN

PLUGIN.name = "Credits Tab"
PLUGIN.desc = "A tab where players can see who made the framework/schema"
PLUGIN.author = "NS Team"

if SERVER then return end

PLUGIN.excludeList = {
    ["github_username_here"] = true
}
PLUGIN.nsCreators = {
    ["Chessnut"] = true,
    ["rebel1324"] = true,
}
PLUGIN.nsMaintainers = {
    ["TovarischPootis"] = true,
    ["zoephix"] = true
}

local creatorHeight = ScreenScale(32)
local maintainerHeight = ScreenScale(32)
local contributorWidth = ScreenScale(32)

PLUGIN.contributorData = PLUGIN.contributorData or {}

surface.CreateFont("nutSmallCredits", {
    font = "Roboto Th",
    size = ScreenScale(6),
    weight = 100
})

surface.CreateFont("nutBigCredits", {
    font = "Roboto Th",
    size = ScreenScale(12),
    weight = 100
})

local PANEL = {}

AccessorFunc(PANEL, "rowHeight", "RowHeight", FORCE_NUMBER)

DEFINE_BASECLASS("Panel")

function PANEL:Init()
    self.seperator = vgui.Create("Panel", self)
    self.seperator:Dock(TOP)
    self.seperator:SetTall(1)
    self.seperator.Paint = function(this, width, height)
            surface.SetDrawColor(color_white)

            surface.SetMaterial(nut.util.getMaterial("vgui/gradient-r"))
            surface.DrawTexturedRect(0, 0, width * 0.5, height)

            surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
            surface.DrawTexturedRect(width * 0.5, 0, width * 0.5, height)
        end
    self.seperator:DockMargin(0, 4, 0, 4)

    self.sectionLabel = vgui.Create("DLabel", self)
    self.sectionLabel:Dock(TOP)
    self.sectionLabel:SetFont("nutBigCredits")
    self.sectionLabel:SetContentAlignment(4)
end

function PANEL:Clear()
    for _, v in ipairs(self:GetChildren()) do
        if (v != self.seperator and v != self.sectionLabel) then
            v:Remove()
        end
    end
end

function PANEL:SetText(text)
    self.sectionLabel:SetText(text)
    self.sectionLabel:SizeToContents()
end

function PANEL:Add(pnl)
    return BaseClass.Add(IsValid(self.currentRow) and self.currentRow or self:newRow(), pnl)
end

function PANEL:PerformLayout(width, height)
    local tall = 0

    for _, v in ipairs(self:GetChildren()) do
        local lM, tM, rM, bM = v:GetDockMargin()
        tall = tall + v:GetTall() + tM + bM

        v:InvalidateLayout()
    end

    self:SetTall(tall)
end

function PANEL:newRow()
    self.currentRow = vgui.Create("Panel", self)
    self.currentRow:Dock(TOP)
    self.currentRow:SetTall(self:GetRowHeight())
    self.currentRow.PerformLayout = function(this)
        local totalWidth = 0

        for k, v in ipairs(this:GetChildren()) do
            if (k == 1) then
                v:DockMargin(0, 0, 0, 0)
            end

            totalWidth = totalWidth + v:GetWide() + v:GetDockMargin()

            if (totalWidth > self:GetWide()) then
                print(totalWidth, self:GetWide())
                v:SetParent(self:newRow())
            end
        end

        this:DockPadding(self:GetWide() * 0.5 - totalWidth * 0.5, 0, 0, 0)
    end

    return self.currentRow
end

vgui.Register("nutCreditsSpecialList", PANEL, "Panel")

PANEL = {}

function PANEL:Paint(w, h)
    surface.SetMaterial(nut.util.getMaterial("nutscript/logo.png"))
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(w * 0.5 - 128, h * 0.5 - 128, 256, 256)
end

vgui.Register("CreditsLogo", PANEL, "Panel")

PANEL = {}

local CONTRIB_PADDING = 8
local CONTRIB_MARGIN = 16

function PANEL:Init()
    if nut.gui.creditsPanel then
        nut.gui.creditsPanel:Remove()
    end
    nut.gui.creditsPanel = self

    self.logo = self:Add("CreditsLogo")
    self.logo:SetTall(180)
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
    self.repoLabel.DoClick = function()
        gui.OpenURL("https://github.com/NutScript")
    end

    if (table.Count(PLUGIN.nsCreators) > 0) then
        self.creatorList = self:Add("nutCreditsSpecialList")
        self.creatorList:Dock(TOP)
        self.creatorList:SetText("Creators")
        self.creatorList:SetRowHeight(creatorHeight)
        self.creatorList:DockMargin(0, 0, 0, 4)
    end

    if (table.Count(PLUGIN.nsMaintainers) > 0) then
        self.maintainerList = self:Add("nutCreditsSpecialList")
        self.maintainerList:Dock(TOP)
        self.maintainerList:SetText("Maintainers")
        self.maintainerList:SetRowHeight(maintainerHeight)
        self.maintainerList:DockMargin(0, 0, 0, 4)
    end

    local seperator = self:Add("Panel")
    seperator:Dock(TOP)
    seperator:SetTall(1)
    seperator.Paint = function(this, width, height)
        surface.SetDrawColor(color_white)

        surface.SetMaterial(nut.util.getMaterial("vgui/gradient-r"))
        surface.DrawTexturedRect(0, 0, width * 0.5, height)

        surface.SetMaterial(nut.util.getMaterial("vgui/gradient-l"))
        surface.DrawTexturedRect(width * 0.5, 0, width * 0.5, height)
    end
    seperator:DockMargin(0, 4, 0, 4)

    self.contribLabel = self:Add("DLabel")
    self.contribLabel:SetFont("nutBigCredits")
    self.contribLabel:SetText("Contributors")
    self.contribLabel:SetContentAlignment(4)
    self.contribLabel:SizeToContents()
    self.contribLabel:Dock(TOP)

    self.contribList = self:Add("DIconLayout")
    self.contribList:Dock(TOP)
    self.contribList:SetSpaceX(CONTRIB_MARGIN)
    self.contribList:SetSpaceY(CONTRIB_MARGIN)

    if (#PLUGIN.contributorData == 0) then
        http.Fetch("https://api.github.com/repos/NutScript/NutScript/contributors?per_page=100",
            function(body, length, headers, code)
                local contributors = util.JSONToTable(body)

                for k, v in pairs(contributors) do
                    if (not PLUGIN.excludeList[v.login]) then
                        table.insert(PLUGIN.contributorData, {url = v.html_url, avatar_url = v.avatar_url, name = v.login})
                    end
                end

                self:rebuildContributors()
            end, function(message) end, {})
    else
        self:rebuildContributors()
    end
end

function PANEL:rebuildContributors()
    if (IsValid(self.creatorList)) then
        self.creatorList:Clear()
    end

    if (IsValid(self.maintainerList)) then
        self.maintainerList:Clear()
    end

    self.contribList:Clear()
    self:loadContributor(1, true)
end

function PANEL:loadContributor(contributor, bLoadNextChunk)
    if (PLUGIN.contributorData[contributor]) then
        local isCreator = PLUGIN.nsCreators[PLUGIN.contributorData[contributor].name]
        local isMaintainer = PLUGIN.nsMaintainers[PLUGIN.contributorData[contributor].name]

        local container = vgui.Create("Panel")
        
        if (isCreator) then
            self.creatorList:Add(container)
        elseif (isMaintainer) then
            self.maintainerList:Add(container)
        else
            self.contribList:Add(container)
        end

        container:Dock((isCreator or isMaintainer) and LEFT or NODOCK)
        container:DockMargin(unpack((isCreator or isMaintainer) and {CONTRIB_MARGIN, 0, 0, 0} or {0, 0, 0, 0}))

        container:DockPadding(CONTRIB_PADDING, CONTRIB_PADDING, CONTRIB_PADDING, CONTRIB_PADDING)

        container.highlightAlpha = 0
        container.Paint = function(this, width, height)
            if (this:IsHovered()) then
                this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 128)
            else
                this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 0)
            end

            surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha * 0.5))
            surface.SetMaterial((isCreator or isMaintainer) and nut.util.getMaterial("vgui/gradient-l") or nut.util.getMaterial("vgui/gradient-d"))
            -- to textured rect or not to textured rect, that is the question
            surface.DrawTexturedRect(0, 0, width, height)

            surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha))

            if (isCreator or isMaintainer) then
                surface.DrawRect(0, 0, 1, height)
            else
                surface.DrawRect(0, height - 1, width, 1)
            end
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

        if (BRANCH == "x86-64") then
            local contributorPanel = container:Add("DHTML")
            contributorPanel:SetHTML(
                "<style>body {overflow: hidden; margin:0;} img {height: 100%; width: 100%; border-radius: 50%;}</style><img src=\""
                .. PLUGIN.contributorData[contributor].avatar_url .. "\">"
            )
            contributorPanel:SetMouseInputEnabled(false)

            contributorPanel:Dock((isCreator or isMaintainer) and LEFT or FILL)
            contributorPanel:DockMargin(unpack((isCreator or isMaintainer) and {0, 0, CONTRIB_PADDING, 0} or {0, 0, 0, CONTRIB_PADDING}))
            contributorPanel:SetWide(isCreator and creatorHeight - CONTRIB_PADDING * 2 or isMaintainer and maintainerHeight - CONTRIB_PADDING * 2 or 0)

            if (bLoadNextChunk) then
                contributorPanel.OnFinishLoadingDocument = function(this, url)
                    -- load 3 at a time, nice balance between not eating up your cpu cycles and being quick to load all the avatars
                    for i = 1, 3 do
                        if (contributor + i > #PLUGIN.contributorData) then
                            return
                        end

                        self:loadContributor(contributor + i, i == 3)
                    end
                end
            end
        elseif (bLoadNextChunk) then
            for i = 1, #PLUGIN.contributorData - 1 do
                self:loadContributor(contributor + i)
            end
        end

        local button = container:Add("DLabel")
        button:SetMouseInputEnabled(false)
        button:SetText(PLUGIN.contributorData[contributor].name)
        button:SetContentAlignment(5)

        button:Dock((isCreator or isMaintainer) and FILL or BOTTOM)
        button:SetFont((isCreator or isMaintainer) and "nutBigCredits" or "nutSmallCredits")
        button:SizeToContents()

        container:SetSize(
            isCreator and button:GetWide() + creatorHeight + CONTRIB_PADDING
            or isMaintainer and button:GetWide() + maintainerHeight + CONTRIB_PADDING
            or contributorWidth,
            button:GetTall() + (BRANCH == "x86-64" and contributorWidth or CONTRIB_PADDING) + CONTRIB_PADDING
        )
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
