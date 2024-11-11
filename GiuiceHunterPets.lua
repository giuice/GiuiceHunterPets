local addonName, GHP = ...

-- Initialize addon table with necessary functions
GHP.utils = {}
GHP.frames = {}

-- Check for Hunter class first
if (select(3, UnitClass("player")) ~= 3) then return end


-- Check for required libraries
assert(LibStub, "GiuiceHunterPets requires LibStub")
local LDB = LibStub:GetLibrary("LibDataBroker-1.1", true)
assert(LDB, "GiuiceHunterPets requires LibDataBroker-1.1")
local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)
assert(LibDBIcon, "GiuiceHunterPets requires LibDBIcon-1.0")

-- Initialize saved variables with LibDBIcon settings
GiuiceHunterPetsDB = GiuiceHunterPetsDB or {
    position = nil,
    minimap = { hide = false },
}



-- Create the LibDataBroker object
local minimapLDB = LDB:NewDataObject("GiuiceHunterPets", {
    type = "launcher",
    icon = "Interface\\Icons\\Ability_Hunter_Pet_Devilsaur",
    OnClick = function(self, button)
        if button == "LeftButton" then
            if GiuiceHunterPetsFrame:IsShown() then
                GiuiceHunterPetsFrame:Hide()
            else
                GiuiceHunterPetsFrame:Show()
                GHP.utils.UpdatePetList(GiuiceHunterPetsFrame)
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("GiuiceHunterPets", 1, 0.82, 0)
        tooltip:AddLine("Left Click: Toggle pet window", 1, 1, 1)
    end,
})

-- Function to initialize minimap button
local function InitializeMinimapButton()
    LibDBIcon:Register("GiuiceHunterPets", minimapLDB, GiuiceHunterPetsDB.minimap)
end

function GHP.utils.GetAllPets()
    local allPets = {}
    local activePets = C_StableInfo.GetActivePetList() or {}
    local stabledPets = C_StableInfo.GetStabledPetList() or {}

    -- First, add active pets
    for _, pet in ipairs(activePets) do
        pet.isActive = true
        table.insert(allPets, pet)
    end

    -- Then add stabled pets
    for _, pet in ipairs(stabledPets) do
        pet.isActive = false
        table.insert(allPets, pet)
    end

    return allPets
end

function GHP.utils.CreatePetEntryOld(petContainer, petInfo)
    -- Background improvements
    petContainer:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Set different background colors for active vs stabled pets
    local r, g, b = 0.1, 0.1, 0.1
    if petInfo.isActive then
        r, g, b = 0.15, 0.2, 0.15
    end
    petContainer:SetBackdropColor(r, g, b, 0.9)
    petContainer:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Pet icon with better framing
    local iconFrame = CreateFrame("Frame", nil, petContainer, BackdropTemplateMixin and "BackdropTemplate")
    iconFrame:SetSize(54, 54)
    iconFrame:SetPoint("LEFT", 8, 0)
    iconFrame:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 8,
    })
    iconFrame:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)

    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(50, 50)
    icon:SetPoint("CENTER")
    icon:SetTexture(petInfo.icon)

    -- Create the main text container
    local textContainer = CreateFrame("Frame", nil, petContainer)
    textContainer:SetPoint("LEFT", iconFrame, "RIGHT", 12, 0)
    textContainer:SetPoint("RIGHT", petContainer, "RIGHT", -8, 0)
    textContainer:SetHeight(50)

    -- Pet name and level
    local nameText = textContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    nameText:SetPoint("TOPLEFT", 0, -2)
    nameText:SetPoint("RIGHT", -5, 0)
    nameText:SetJustifyH("LEFT")

    -- Create name string with proper coloring
    local nameString = string.format(
        "%s - Level %d (%s) %s",
        petInfo.name,
        petInfo.level,
        petInfo.familyName,
        petInfo.isExotic and "|cFFFF0000Exotic|r" or ""
    )
    nameText:SetText(nameString)

    -- Status indicators container
    local statusContainer = CreateFrame("Frame", nil, textContainer)
    statusContainer:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    statusContainer:SetPoint("RIGHT", -5, 0)
    statusContainer:SetHeight(20)

    -- Favorite indicator (star)
    if petInfo.isFavorite then
        local favoriteIcon = statusContainer:CreateTexture(nil, "OVERLAY")
        favoriteIcon:SetSize(16, 16)
        favoriteIcon:SetPoint("LEFT", 0, 0)
        favoriteIcon:SetTexture("Interface/Common/FavoritesIcon")
        favoriteIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Trim the texture edges
        favoriteIcon:SetVertexColor(1, 0.82, 0)      -- Gold color
    end

    -- Status text (With me/On Stable)
    local statusText = statusContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("LEFT", petInfo.isFavorite and 20 or 0, 0)
    if petInfo.isActive then
        statusText:SetText("|cFF00FF00With me|r")
    else
        statusText:SetText("|cFF888888On Stable|r")
    end

    -- Hover effect
    petContainer:SetScript("OnEnter", function(self)
        local hr, hg, hb = r + 0.1, g + 0.1, b + 0.1
        self:SetBackdropColor(hr, hg, hb, 0.9)
    end)

    petContainer:SetScript("OnLeave", function(self)
        self:SetBackdropColor(r, g, b, 0.9)
    end)

    return petContainer
end

function GHP.utils.CreatePetEntry(scrollChild, petInfo)
    local petContainer = CreateFrame("Button", nil, scrollChild, "GiuiceHunterPetListItemTemplate")
    petContainer:SetPetInfo(petInfo)
    return petContainer
end

-- Function to update pet list
function GHP.utils.UpdatePetList(frame, searchText)
    local scrollChild = frame.scrollChild
    -- Clear existing contents
    for _, child in pairs({ scrollChild:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Get both stabled and active pets
    local stabledPets = GHP.utils.GetAllPets()


    if not stabledPets then
        print("No pets in stable.")
        return
    end

    -- Filter pets based on search
    local filteredPets = stabledPets
    if searchText and searchText ~= "" then
        searchText = searchText:lower()
        filteredPets = {}
        local searchType = frame.searchType()

        for _, pet in ipairs(stabledPets) do
            local match = false
            if searchType == "name" then
                match = pet.name:lower():find(searchText, 1, true)
            elseif searchType == "family" then
                match = pet.familyName:lower():find(searchText, 1, true)
            elseif searchType == "level" then
                match = tostring(pet.level):find(searchText, 1, true)
            end

            if match then
                table.insert(filteredPets, pet)
            end
        end
    end

    local previousElement
    local totalHeight = 0

    for index, petInfo in ipairs(filteredPets) do
        local petContainer = GHP.utils.CreatePetEntry(scrollChild, petInfo) --CreateFrame("Frame", nil, scrollChild, BackdropTemplateMixin and "BackdropTemplate")
        petContainer:SetSize(scrollChild:GetWidth() - 8, 70)
        if previousElement then
            petContainer:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", 0, -2)
        else
            petContainer:SetPoint("TOPLEFT", 0, 0)
        end

        -- petContainer:EnableMouse(true)
        -- petContainer:SetScript("OnMouseDown", function()
        --     GHP.utils.ShowPetDetails(frame.detailPanel, petInfo)
        -- end)

        --GHP.utils.CreatePetEntry(petContainer, petInfo)
        previousElement = petContainer
    end

    scrollChild:SetHeight(math.max(totalHeight, frame:GetHeight()))
end

-- Create main frame
local function CreateMainFrame()
    local frame = CreateFrame("Frame", "GiuiceHunterPetsFrame", UIParent,  "PortraitFrameTemplate")
    frame:SetSize(1000, 700)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetMovable(true)

    -- Set saved position or default
    if GiuiceHunterPetsDB.position then
        frame:SetPoint(unpack(GiuiceHunterPetsDB.position))
    else
        frame:SetPoint("CENTER")
    end

    -- Add hunter icon
    frame.portraitIcon = "Interface\\Icons\\ClassIcon_Hunter"
     -- Portrait and title (correct method)
    SetPortraitToTexture(frame.PortraitContainer.portrait, "Interface\\Icons\\ClassIcon_Hunter")
        -- Title text
    frame.TitleContainer.TitleText:SetText("Giuice's hunter pets viewer")
    
    -- Movement handling
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        GiuiceHunterPetsDB.position = { point, relativeTo, relativePoint, xOfs, yOfs }
    end)

    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(24)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)


    
    -- Create detail panel on right side
    local detailPanel = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    detailPanel:SetPoint("TOPLEFT", frame:GetWidth() / 2, -32)
    detailPanel:SetPoint("BOTTOMRIGHT", -8, 8)
    detailPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    detailPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- Search container frame for better organization
    local searchContainer = CreateFrame("Frame", nil, frame)
    searchContainer:SetHeight(30) -- Height for search elements
    searchContainer:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    searchContainer:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)

    -- Search box
    local searchBox = CreateFrame("EditBox", nil, searchContainer, "SearchBoxTemplate")
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 65, -5)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetScript("OnTextChanged", function(self)
        GHP.utils.UpdatePetList(frame, self:GetText())
    end)

    -- Search options dropdown
    local searchOptions = CreateFrame("Frame", "GiuiceHunterPetsSearchOptions", searchContainer, "UIDropDownMenuTemplate")
    searchOptions:SetPoint("LEFT", searchBox, "RIGHT", 0, -2)

    local searchType = "name" -- Default search type

    local function InitializeSearchOptions(self, level)
        local info = UIDropDownMenu_CreateInfo()
        local options = {
            { text = "Name",   value = "name" },
            { text = "Family", value = "family" },
            { text = "Level",  value = "level" },
        }

        for _, option in ipairs(options) do
            info.text = option.text
            info.value = option.value
            info.checked = searchType == option.value
            info.func = function(self)
                searchType = self.value
                UIDropDownMenu_SetText(searchOptions, option.text)
                GHP.utils.UpdatePetList(frame, searchBox:GetText())
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(searchOptions, InitializeSearchOptions)
    UIDropDownMenu_SetText(searchOptions, "Name")
    UIDropDownMenu_SetWidth(searchOptions, 100)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", searchContainer, "BOTTOMLEFT", 8, -8) -- Position below search container
    scrollFrame:SetPoint("BOTTOMRIGHT", frame:GetWidth() / 2 - 14, 8)

    -- Scroll child adjustment
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(frame:GetWidth() / 2 - 36, 1) -- Adjust width to half

    frame.searchBox = searchBox
    frame.searchType = function() return searchType end

    -- Save position when frame stops moving
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        GiuiceHunterPetsDB.position = { point, relativeTo, relativePoint, xOfs, yOfs }
    end)

    frame.scrollChild = scrollChild
    frame.detailPanel = detailPanel
    frame:Hide()

    GHP.frames.mainFrame = frame
    return frame
end

function GHP.utils.ShowPetDetails(detailPanel, petInfo)
    -- Clear previous content
    for _, child in pairs({ detailPanel:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Create model viewer
    local modelViewer = CreateFrame("PlayerModel", nil, detailPanel, "PanningModelSceneMixinTemplate")
    modelViewer:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 20, -20)
    modelViewer:SetSize(430, 300)
    modelViewer:SetCreature(petInfo.creatureID)

    -- Set initial position (facing forward)
    modelViewer:SetPosition(0, 0, 0)
    modelViewer:SetFacing(0)

    -- Set initial camera
    modelViewer:SetCamera(0)
    modelViewer.defaultZoom = -3
    modelViewer.minZoom = -1.5
    modelViewer.maxZoom = 1.5
    modelViewer.zoomLevel = modelViewer.defaultZoom

    -- Add basic controls
    modelViewer:EnableMouse(true)
    modelViewer:EnableMouseWheel(true)

    -- Improved rotation control
    local rotationStart = nil
    modelViewer:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            rotationStart = GetCursorPosition()
            self.isRotating = true
        end
    end)

    modelViewer:SetScript("OnMouseUp", function(self)
        self.isRotating = false
        rotationStart = nil
    end)

    modelViewer:SetScript("OnUpdate", function(self)
        if self.isRotating and rotationStart then
            local x = GetCursorPosition()
            local rotation = (x - rotationStart) * 0.01
            self:SetFacing(rotation)
        end
    end)

    -- Improved zoom handling
    modelViewer:SetScript("OnMouseWheel", function(self, delta)
        local zoomChange = delta * 0.1
        self.zoomLevel = max(self.minZoom, min(self.maxZoom, self.zoomLevel + zoomChange))
        self:SetPortraitZoom(self.zoomLevel)
    end)

    -- Create info container below model
    local infoContainer = CreateFrame("Frame", nil, detailPanel)
    infoContainer:SetPoint("TOPLEFT", modelViewer, "BOTTOMLEFT", 0, -20)
    infoContainer:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -20, 20)

    -- Helper function to create text sections
    local function CreateInfoSection(parent, label, value, previousSection, spacing)
        local section = CreateFrame("Frame", nil, parent)
        section:SetHeight(20)
        if previousSection then
            section:SetPoint("TOPLEFT", previousSection, "BOTTOMLEFT", 0, -(spacing or 5))
            section:SetPoint("TOPRIGHT", previousSection, "BOTTOMRIGHT", 0, -(spacing or 5))
        else
            section:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
            section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
        end

        local labelText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        labelText:SetPoint("LEFT", section, "LEFT", 0, 0)
        labelText:SetTextColor(1, 0.82, 0) -- Gold color
        labelText:SetText(label .. ":")

        local valueText = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valueText:SetPoint("LEFT", labelText, "RIGHT", 5, 0)
        valueText:SetText(value)

        return section
    end

    -- Create sections for pet information
    local lastSection

    -- Name and Level
    lastSection = CreateInfoSection(infoContainer, "Name",
        string.format("|cFFFFFFFF%s|r", petInfo.name), nil, 10)

    -- Level and Family
    lastSection = CreateInfoSection(infoContainer, "Level & Family",
        string.format("|cFFFFFFFF%d %s|r", petInfo.level, petInfo.familyName), lastSection)

    -- Specialization
    if petInfo.specialization then
        lastSection = CreateInfoSection(infoContainer, "Specialization",
            string.format("|cFFFFFFFF%s|r", petInfo.specialization), lastSection)
    end

    -- Type
    lastSection = CreateInfoSection(infoContainer, "Type",
        string.format("|cFFFFFFFF%s|r", petInfo.type), lastSection)

    -- Exotic Status
    -- lastSection = CreateInfoSection(infoContainer, "Status",
    --     string.format("%s%s%s",
    --         petInfo.isExotic and "|cFFFF0000Exotic|r" or "|cFF00FF00Normal|r",
    --         petInfo.isFavorite and " |cFFFFD700★ Favorite|r" or "",
    --         petInfo.slotID and " |cFF00FF00(Active)|r" or ""
    --     ), lastSection)

    lastSection = CreateInfoSection(infoContainer, "Status",
        string.format("%s%s%s",
            petInfo.isExotic and "|cFFFF0000Exotic|r" or "|cFF00FF00Normal|r",
            petInfo.isFavorite and " |cFFFFD700★ Favorite|r" or "",
            petInfo.isActive and " |cFF00FF00(Active)|r" or ""
        ), lastSection)

    -- Pet Number
    lastSection = CreateInfoSection(infoContainer, "Pet Number",
        string.format("|cFFFFFFFF%d|r", petInfo.petNumber), lastSection)

    -- Creature ID (useful for debugging/advanced users)
    lastSection = CreateInfoSection(infoContainer, "Creature ID",
        string.format("|cFFFFFFFF%d|r", petInfo.creatureID), lastSection)

    -- Abilities Header
    if petInfo.abilities and #petInfo.abilities > 0 then
        local abilityHeader = lastSection:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        abilityHeader:SetPoint("TOPLEFT", lastSection, "BOTTOMLEFT", 0, -20)
        abilityHeader:SetTextColor(1, 0.82, 0)
        abilityHeader:SetText("Abilities:")

        -- Create ability icons
        local lastAbility
        for i, abilityID in ipairs(petInfo.abilities) do
            local abilityIcon = CreateFrame("Button", nil, infoContainer)
            abilityIcon:SetSize(32, 32)
            if i == 1 then
                abilityIcon:SetPoint("TOPLEFT", abilityHeader, "BOTTOMLEFT", 0, -10)
            else
                abilityIcon:SetPoint("LEFT", lastAbility, "RIGHT", 5, 0)
            end

            local texture = abilityIcon:CreateTexture(nil, "ARTWORK")
            texture:SetAllPoints()
            local spellInfo = C_Spell.GetSpellInfo(abilityID)
            texture:SetTexture(spellInfo.originalIconID)

            -- Add tooltip
            abilityIcon:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(abilityID)
                GameTooltip:Show()
            end)
            abilityIcon:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            lastAbility = abilityIcon
        end
    end
end

-- Create and initialize the addon
local function InitializeAddon()
    local mainFrame = CreateMainFrame()
    InitializeMinimapButton()

    -- Event handling
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PET_STABLE_SHOW")
    eventFrame:RegisterEvent("PET_STABLE_UPDATE")

    eventFrame:SetScript("OnEvent", function(self, event)
        if mainFrame:IsShown() then
            GHP.utils.UpdatePetList(mainFrame)
        end
    end)

    -- Slash command
    SLASH_HUNTERPETLIST1 = "/hunterpets"
    SlashCmdList["HUNTERPETLIST"] = function()
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
            GHP.utils.UpdatePetList(mainFrame)
        end
    end
end

-- Register for ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        InitializeAddon()
        print("GiuiceHunterPets loaded successfully!")
    end
end)
