local addonName, addon = ...
-- Saved variables
GiuiceHunterPetsDB = GiuiceHunterPetsDB or {}
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
    local titleBar = CreateFrame("Frame", nil, frame,  BackdropTemplateMixin and "BackdropTemplate")
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

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame:GetWidth()/2 - 14, 8)  -- Half width minus padding

    -- Scroll child adjustment
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(frame:GetWidth()/2 - 36, 1) -- Adjust width to half

    -- Create detail panel on right side
    local detailPanel = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    detailPanel:SetPoint("TOPLEFT", frame:GetWidth()/2, -32)
    detailPanel:SetPoint("BOTTOMRIGHT", -8, 8)
    detailPanel:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    detailPanel:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- Save position when frame stops moving
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        GiuiceHunterPetsDB.position = {point, relativeTo, relativePoint, xOfs, yOfs}
    end)

    frame.scrollChild = scrollChild
    frame.detailPanel = detailPanel
    frame:Hide()
    return frame
end

local function ShowPetDetails(detailPanel, petInfo)
    -- Clear previous content
    for _, child in pairs({detailPanel:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Create model viewer
    local modelViewer = CreateFrame("PlayerModel", nil, detailPanel)
    modelViewer:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 20, -20)
    modelViewer:SetSize(300, 300)
    modelViewer:SetCreature(petInfo.creatureID)
    
    -- Set initial position (facing forward)
    modelViewer:SetPosition(0, 0, 0)
    modelViewer:SetFacing(0)

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
    
    -- Add mouse wheel for zoom
    modelViewer:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetCameraDistance()
        local new = current - (delta * 0.5)
        self:SetCameraDistance(new)
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
    lastSection = CreateInfoSection(infoContainer, "Status", 
        string.format("%s%s%s", 
            petInfo.isExotic and "|cFFFF0000Exotic|r" or "|cFF00FF00Normal|r",
            petInfo.isFavorite and " |cFFFFD700★ Favorite|r" or "",
            petInfo.slotID and " |cFF00FF00(Active)|r" or ""
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


-- Function to update pet list
local function UpdatePetList(frame)
    local scrollChild = frame.scrollChild
    -- Clear existing contents
    for _, child in pairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    local stabledPets = C_StableInfo.GetStabledPetList()
    if not stabledPets then
        print("No pets in stable.")
        return
    end

    local previousElement
    local totalHeight = 0

    for index, petInfo in ipairs(stabledPets) do
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
            ShowPetDetails(frame.detailPanel, petInfo)
        end)

        -- -- Model viewer
        -- local modelViewer = CreateFrame("PlayerModel", nil, petContainer)
        -- modelViewer:SetSize(60, 60)
        -- modelViewer:SetPoint("LEFT", 5, 0)
        -- modelViewer:SetCreature(petInfo.creatureID)
        -- modelViewer:SetScript("OnMouseDown", function(self) self:SetCamDistanceScale(0.8) end)
        -- modelViewer:SetScript("OnMouseUp", function(self) self:SetCamDistanceScale(1.0) end)
        -- modelViewer:EnableMouse(true)
        -- Pet information
        -- local nameText = petContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        -- nameText:SetPoint("TOPLEFT", modelViewer, "TOPRIGHT", 10, -5)
        -- nameText:SetText(string.format(
        --     "%s - Level %d (%s) %s",
        --     petInfo.name,
        --     petInfo.level,
        --     petInfo.familyName,
        --     petInfo.isExotic and "|cFFFF0000Exotic|r" or ""
        -- ))

         -- Pet icon
         local iconFrame = CreateFrame("Frame", nil, petContainer)
         iconFrame:SetSize(50, 50)
         iconFrame:SetPoint("LEFT", 10, 0)
 
         local icon = petContainer:CreateTexture(nil, "ARTWORK")
         icon:SetSize(50, 50)
         icon:SetPoint("CENTER", iconFrame, "CENTER")
         icon:SetTexture(petInfo.icon)
 
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
            activeText:SetText("|cFF00FF00Active|r")
        end

        previousElement = petContainer
        totalHeight = totalHeight + 75 -- 70 for height + 5 for spacing
    end

    scrollChild:SetHeight(math.max(totalHeight, frame:GetHeight()))
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
            UpdatePetList(mainFrame)
        end
    end)

    -- Slash command
    SLASH_HUNTERPETLIST1 = "/hunterpets"
    SlashCmdList["HUNTERPETLIST"] = function()
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
            UpdatePetList(mainFrame)
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