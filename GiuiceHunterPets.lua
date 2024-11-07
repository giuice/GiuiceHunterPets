local addonName, addon = ...

-- Initialize addon table with necessary functions
addon.utils = {}
addon.frames = {}

-- Saved variables
GiuiceHunterPetsDB = GiuiceHunterPetsDB or {}

function addon.utils.GetAllPets()
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

-- Function to update pet list
function addon.utils.UpdatePetList(frame, searchText)
    local scrollChild = frame.scrollChild
    -- Clear existing contents
    for _, child in pairs({ scrollChild:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Get both stabled and active pets
    local stabledPets = addon.utils.GetAllPets()
    

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
        -- Create container for this pet
        local petContainer = CreateFrame("Frame", nil, scrollChild, BackdropTemplateMixin and "BackdropTemplate")
        petContainer:SetSize(scrollChild:GetWidth(), 70)
        if previousElement then
            petContainer:SetPoint("TOPLEFT", previousElement, "BOTTOMLEFT", 0, -5)
        else
            petContainer:SetPoint("TOPLEFT", 0, 0)
        end

        -- Add background for better visibility
        petContainer:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        petContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.5)

        -- Add hover effect
        petContainer:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 0.7)
        end)

        petContainer:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        end)

        -- Add click handling
        petContainer:EnableMouse(true)
        petContainer:SetScript("OnMouseDown", function()
            addon.utils.ShowPetDetails(frame.detailPanel, petInfo)
        end)

        -- Pet icon
        local iconFrame = CreateFrame("Frame", nil, petContainer)
        iconFrame:SetSize(50, 50)
        iconFrame:SetPoint("LEFT", 10, 0)

        local icon = petContainer:CreateTexture(nil, "ARTWORK")
        icon:SetSize(50, 50)
        icon:SetPoint("CENTER", iconFrame, "CENTER")
        icon:SetTexture(petInfo.icon)

        -- Status indicators container
        local statusContainer = CreateFrame("Frame", nil, petContainer)
        statusContainer:SetSize(20, 50)
        statusContainer:SetPoint("RIGHT", petContainer, "RIGHT", -5, 0)

        -- Active pet indicator
        if petInfo.isActive then
            local activeIcon = statusContainer:CreateTexture(nil, "ARTWORK")
            activeIcon:SetSize(16, 16)
            activeIcon:SetPoint("TOP", statusContainer, "TOP", 0, -5)
            activeIcon:SetTexture("Interface\\PetBattles\\PetBattle-StatIcons") -- Using a built-in texture
            activeIcon:SetTexCoord(0, 0.5, 0, 0.5)                              -- Adjust this to get the proper icon section

            -- Add tooltip
            statusContainer:EnableMouse(true)
            statusContainer:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Active Pet", 0, 1, 0)
                GameTooltip:Show()
            end)
            statusContainer:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        -- Adjust pet information layout
        local nameText = petContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        nameText:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 10, -5)
        nameText:SetPoint("RIGHT", petContainer, "RIGHT", -10, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        nameText:SetText(string.format(
            "%s - Level %d (%s) %s",
            petInfo.name,
            petInfo.level,
            petInfo.familyName,
            petInfo.isExotic and "|cFFFF0000Exotic|r" or ""
        ))
        -- Status texts
        if petInfo.isFavorite then
            local favText = petContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            favText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)
            favText:SetText("|cFFFFD700★ Favorite|r")
        end

        if petInfo.isActive then
            local activeText = petContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            activeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, petInfo.isFavorite and -20 or -5)
            activeText:SetText("|cFF00FF00With me|r")
        else
            local activeText = petContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            activeText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, petInfo.isFavorite and -20 or -5)
            activeText:SetText("|cAA00AA00On Stable|r")
        end

        previousElement = petContainer
        totalHeight = totalHeight + 75 -- 70 for height + 5 for spacing
    end

    scrollChild:SetHeight(math.max(totalHeight, frame:GetHeight()))
end

-- Create main frame
local function CreateMainFrame()
    local frame = CreateFrame("Frame", "GiuiceHunterPetsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
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

    -- Make it look like a proper window
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    titleBar:SetHeight(24)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    titleBar:SetBackdropColor(0.1, 0.1, 0.1, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    -- Title text
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", titleBar, "CENTER")
    title:SetText("Hunter Stabled Pets")

    -- Close button
    local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 2)
    closeButton:SetScript("OnClick", function() frame:Hide() end)



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
    searchBox:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -5)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetScript("OnTextChanged", function(self)
        addon.utils.UpdatePetList(frame, self:GetText())
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
                addon.utils.UpdatePetList(frame, searchBox:GetText())
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
    return frame
end

function addon.utils.ShowPetDetails(detailPanel, petInfo)
    -- Clear previous content
    for _, child in pairs({ detailPanel:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Create model viewer
    local modelViewer = CreateFrame("PlayerModel", nil, detailPanel)
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

    -- Event handling
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PET_STABLE_SHOW")
    eventFrame:RegisterEvent("PET_STABLE_UPDATE")

    eventFrame:SetScript("OnEvent", function(self, event)
        if mainFrame:IsShown() then
            addon.utils.UpdatePetList(mainFrame)
        end
    end)

    -- Slash command
    SLASH_HUNTERPETLIST1 = "/hunterpets"
    SlashCmdList["HUNTERPETLIST"] = function()
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
            addon.utils.UpdatePetList(mainFrame)
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
