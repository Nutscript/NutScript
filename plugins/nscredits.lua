
local PLUGIN = PLUGIN

PLUGIN.name = "Credits Page"
PLUGIN.desc = "Adds an always up to date page listing contributors to the framework."
PLUGIN.author = "Miyoglow"

if (SERVER) then return end

PLUGIN.NS_CREATORS = {
    -- Chessnut
    [1689094] = true,
    -- rebel1324
    [2784192] = true
}

PLUGIN.NAME_OVERRIDES = {
    [1689094] = "Chessnut",
    [2784192] = "Black Tea"
}

PLUGIN.CACHE_URL = "https://raw.githubusercontent.com/NutScript/NutScript/credits-cache"
PLUGIN.MATERIAL_FOLDER = "ns/credits-cache"

PLUGIN.contributorData = PLUGIN.contributorData or {
    {id = 1689094, name = "Chessnut", login = "Chessnut"},
    {id = 2784192, name = "Black Tea", login = "rebel1324"}
}

PLUGIN.avatarMaterials = PLUGIN.avatarMaterials or {}
PLUGIN.fetchedContributors = PLUGIN.fetchedContributors or false

local creatorHeight = ScreenScale(32)
local maintainerHeight = ScreenScale(32)
local contributorWidth = ScreenScale(32)

local contributorPadding = 8
local contributorMargin = 16

surface.CreateFont("nutSmallCredits", {
    font = "Segoe UI Light",
    size = ScreenScale(6),
    weight = 100
})

surface.CreateFont("nutBigCredits", {
    font = "Segoe UI Light",
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

        local newRow

        for k, v in ipairs(this:GetChildren()) do
            if (k == 1) then
                v:DockMargin(0, 0, 0, 0)
            end

            local childWidth = v:GetWide() + v:GetDockMargin()
            totalWidth = totalWidth + childWidth

            if (totalWidth > self:GetWide() and childWidth < self:GetWide()) then
                newRow = newRow or self:newRow()
                v:SetParent(newRow)
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

    self.creatorList = self:Add("nutCreditsSpecialList")
    self.creatorList:Dock(TOP)
    self.creatorList:SetText("Creators")
    self.creatorList:SetRowHeight(creatorHeight)
    self.creatorList:DockMargin(0, 0, 0, 4)

    self.maintainerList = self:Add("nutCreditsSpecialList")
    self.maintainerList:Dock(TOP)
    self.maintainerList:SetText("Maintainers")
    self.maintainerList:SetRowHeight(maintainerHeight)
    self.maintainerList:DockMargin(0, 0, 0, 4)
    self.maintainerList:SetVisible(false)

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
    self.contribList:SetSpaceX(contributorMargin)
    self.contribList:SetSpaceY(contributorMargin)

    if (!PLUGIN.fetchedContributors) then
        HTTP({
            url = PLUGIN.CACHE_URL .. "/contributors.json",
            method = "GET",
            success = function(code, body, headers)
                PLUGIN.contributorData = {}
                PLUGIN.fetchedContributors = true

                local contributors = util.JSONToTable(body)

                for k, data in ipairs(contributors or {}) do
                    if (istable(data) and data.id) then
                        table.insert(PLUGIN.contributorData, data)
                    end
                end

                if (IsValid(self)) then
                    self:rebuildContributors()
                end
            end,
            failed = function(message)
                if (IsValid(self)) then
                    self:rebuildContributors()
                end
            end
        })
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

    if (!self.maintainerList:IsVisible()) then
        for _, v in ipairs(PLUGIN.contributorData) do
            if (v.maintainer) then
                self.maintainerList:SetVisible(true)
                break
            end
        end
    end

    self.contribList:Clear()
    self:loadContributor(1, true)
end

PLUGIN.circleCache = PLUGIN.circleCache or {}

-- draw.Circle, with cache added by miyo
-- https://wiki.facepunch.com/gmod/surface.DrawPoly
local drawCircle = function (x, y, r, s)
    local c = PLUGIN.circleCache
    local cir = {}

    if (c[x] and c[x][y] and c[x][y][r] and c[x][y][r][s]) then
        cir = c[x][y][r][s]
    else
        table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
        for i = 0, s do
            local a = math.rad( ( i / s ) * -360 )
            table.insert( cir, { x = x + math.sin( a ) * r, y = y + math.cos( a ) * r, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
        end

        local a = math.rad( 0 ) -- This is needed for non absolute segment counts
        table.insert( cir, { x = x + math.sin( a ) * r, y = y + math.cos( a ) * r, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

        c[x] = c[x] or {}
        c[x][y] = c[x][y] or {}
        c[x][y][r] = c[x][y][r] or {}
        c[x][y][r][s] = cir

        PLUGIN.circleCache = c
    end

    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(0)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_KEEP)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.ClearStencil()
	surface.DrawPoly( cir )
end

function PANEL:loadContributor(contributor, bLoadNextChunk)
    local contributorData = PLUGIN.contributorData[contributor]

    if (contributorData) then
        local isCreator = PLUGIN.NS_CREATORS[contributorData.id]
        local isMaintainer = contributorData.maintainer

        local container = vgui.Create("Panel")

        if (isCreator) then
            self.creatorList:Add(container)
        elseif (isMaintainer) then
            self.maintainerList:Add(container)
        else
            self.contribList:Add(container)
        end

        container:Dock((isCreator or isMaintainer) and LEFT or NODOCK)
        container:DockMargin(unpack((isCreator or isMaintainer) and {contributorMargin, 0, 0, 0} or {0, 0, 0, 0}))

        container:DockPadding(contributorPadding, contributorPadding, contributorPadding, contributorPadding)

        container.highlightAlpha = 0
        container.Paint = function(this, width, height)
            if (this:IsHovered()) then
                this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 128)
            else
                this.highlightAlpha = Lerp(FrameTime() * 16, this.highlightAlpha, 0)
            end

            surface.SetDrawColor(ColorAlpha(nut.config.get("color"), this.highlightAlpha * 0.5))
            surface.SetMaterial((isCreator or isMaintainer) and nut.util.getMaterial("vgui/gradient-l") or nut.util.getMaterial("vgui/gradient-d"))
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
                gui.OpenURL("https://github.com/" .. contributorData.login)
            end
        end
        container.OnMouseWheeled = function(this, delta)
            self:OnMouseWheeled(delta)
        end
        container:SetCursor("hand")
        container:SetTooltip("https://github.com/" .. contributorData.login)
        
        local avatar = container:Add("Panel")
        avatar:SetMouseInputEnabled(false)

        avatar:Dock((isCreator or isMaintainer) and LEFT or FILL)
        avatar:DockMargin(unpack((isCreator or isMaintainer) and {0, 0, contributorPadding, 0} or {0, 0, 0, contributorPadding}))
        avatar:SetWide(isCreator and creatorHeight - contributorPadding * 2 or isMaintainer and maintainerHeight - contributorPadding * 2 or 0)

        avatar.Paint = function(this, width, height)
            if (this.material) then
                surface.SetMaterial(this.material)
                surface.SetDrawColor(255, 255, 255, 255)
	            drawCircle(width * 0.5, height * 0.5, width * 0.5, 64)
            end
        end

        if (bLoadNextChunk) then
            avatar.OnFinishGettingMaterial = function(this, all)
                local toLoad = (all and #PLUGIN.contributorData - 1) or 7

                for i = 1, toLoad do
                    if (contributor + i > #PLUGIN.contributorData) then
                        return
                    end

                    self:loadContributor(contributor + i, i == toLoad)
                end
            end
        end

        if (!PLUGIN.avatarMaterials[contributor]) then
            HTTP({
                url = PLUGIN.CACHE_URL .. "/" .. tostring(contributorData.id),
                method = "GET",
                success = function(code, body)
                    file.CreateDir(PLUGIN.MATERIAL_FOLDER)
                    file.Write(PLUGIN.MATERIAL_FOLDER .. "/" .. tostring(contributorData.id) .. ".png", body)

                    PLUGIN.avatarMaterials[contributor] = Material("data/" .. PLUGIN.MATERIAL_FOLDER .. "/" .. tostring(contributorData.id) .. ".png", "mips smooth")
    
                    if (IsValid(avatar)) then
                        avatar.material = PLUGIN.avatarMaterials[contributor]

                        if (avatar.OnFinishGettingMaterial) then
                            avatar:OnFinishGettingMaterial()
                        end
                    end
                end
            })
        else
            avatar.material = PLUGIN.avatarMaterials[contributor]

            if (avatar.OnFinishGettingMaterial) then
                avatar:OnFinishGettingMaterial(true)
            end
        end

        local name = container:Add("DLabel")
        name:SetMouseInputEnabled(false)
        name:SetText(PLUGIN.NAME_OVERRIDES[contributorData.id] or contributorData.name)
        name:SetContentAlignment(5)

        name:Dock((isCreator or isMaintainer) and FILL or BOTTOM)
        name:SetFont((isCreator or isMaintainer) and "nutBigCredits" or "nutSmallCredits")
        name:SizeToContents()

        container:SetSize(
            isCreator and name:GetWide() + creatorHeight + contributorPadding
            or isMaintainer and name:GetWide() + maintainerHeight + contributorPadding
            or contributorWidth,
            name:GetTall() + contributorWidth + contributorPadding
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
