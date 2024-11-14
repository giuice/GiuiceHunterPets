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


local backgroundForPetSpec = {
	[STABLE_PET_SPEC_CUNNING] = "hunter-stable-bg-art_cunning",
	[STABLE_PET_SPEC_FEROCITY] = "hunter-stable-bg-art_ferocity",
	[STABLE_PET_SPEC_TENACITY] = "hunter-stable-bg-art_tenacity",
};


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

local function CreateMainFrame()
    local frame = CreateFrame("Frame", "GiuiceHunterPetsFrame", UIParent,  "PortraitFrameTemplate")
    frame:SetSize(1200, 700)
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
    detailPanel:SetPoint("TOPLEFT", 450, -32)
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
    scrollFrame:SetPoint("BOTTOMRIGHT", 450 - 14, 8)

    -- Scroll child adjustment
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(450 - 36, 1) -- Adjust width to half

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
    local stabledPets = C_StableInfo.GetStabledPetList() --GHP.utils.GetAllPets()


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
        previousElement = petContainer
    end

    scrollChild:SetHeight(math.max(totalHeight, frame:GetHeight()))
    if(filteredPets and #filteredPets > 0) then
        GHP.utils.ShowPetDetails(GHP.frames.mainFrame.detailPanel,filteredPets[1]);
    end
    
end

function GHP.utils.ShowPetDetails(detailPanel, petInfo)
     -- Clear previous content
     for _, child in pairs({ detailPanel:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local modelViewer = CreateFrame("ModelScene", nil, detailPanel, "PanningModelSceneMixinTemplate")
    modelViewer:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 20, -20)
    modelViewer:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -20, 20)

    -- Add abilities list header
    local header = modelViewer:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
    header:SetPoint("TOPLEFT", modelViewer, "TOPLEFT", 20, -20)
    header:SetText(STABLE_PET_ABILITIES_LIST_HEADER)
    header:GetShadowOffset(1)

    -- Create abilities list
    if petInfo.abilities and #petInfo.abilities > 0 then
        local lastAbility
        for i, abilityID in ipairs(petInfo.abilities) do
            local ability = CreateFrame("Frame", nil, modelViewer)
            ability:SetSize(250, 22)
            
            if i == 1 then
                ability:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
            else
                ability:SetPoint("TOPLEFT", lastAbility, "BOTTOMLEFT", 0, -4)
            end

            -- Create icon texture
            local icon = ability:CreateTexture(nil, "ARTWORK")
            icon:SetSize(22, 22)
            icon:SetPoint("LEFT", 0, 0)
            
            local spellInfo = C_Spell.GetSpellInfo(abilityID)
            icon:SetTexture(spellInfo.iconID)

            -- Create name text
            local name = ability:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            name:SetText(spellInfo.name)
            name:SetJustifyH("LEFT")

            -- Setup tooltip
            ability:EnableMouse(true)
            ability:SetScript("OnEnter", function()
                GameTooltip:SetOwner(ability, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(abilityID, true, true)
                GameTooltip:Show()
            end)
            ability:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            lastAbility = ability
        end
    end

    -- Add basic info below abilities
    local infoContainer = CreateFrame("Frame", nil, modelViewer)
    infoContainer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -150) -- Adjust spacing as needed
    infoContainer:SetSize(250, 200)

    -- Add pet info
    local function AddInfoLine(label, value, previousLine)
        local container = CreateFrame("Frame", nil, infoContainer)
        container:SetHeight(20)
        if previousLine then
            container:SetPoint("TOPLEFT", previousLine, "BOTTOMLEFT", 0, -5)
        else
            container:SetPoint("TOPLEFT", infoContainer, "TOPLEFT")
        end
        container:SetWidth(250)

        local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        labelText:SetPoint("LEFT")
        labelText:SetText(label .. ":")
        labelText:SetTextColor(0.8, 0.8, 0.8)

        local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        valueText:SetPoint("LEFT", labelText, "RIGHT", 5, 0)
        valueText:SetText(value)

        return container
    end

    local lastLine = AddInfoLine("Family", petInfo.familyName)
    lastLine = AddInfoLine("Specialization", petInfo.specialization, lastLine)
    lastLine = AddInfoLine("Diet", table.concat(C_StableInfo.GetStablePetFoodTypes(petInfo.slotID), ", "), lastLine)
    lastLine = AddInfoLine("Status", petInfo.isExotic and "Exotic" or "Normal", lastLine)

    -- Add background layer
    local background = modelViewer:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT")
    background:SetPoint("BOTTOMRIGHT") 
    background:SetAtlas(backgroundForPetSpec[petInfo.specialization] or "hunter-stable-bg-art_cunning")
    background:SetAlpha(0.8)

    -- Add pet shadow
    local shadow = modelViewer:CreateTexture(nil, "ARTWORK")
    shadow:SetAtlas("perks-char-shadow")
    shadow:SetAlpha(0.6)
    shadow:SetSize(410, 90)
    shadow:SetPoint("CENTER", modelViewer, "CENTER", -8, -145)

    -- Setup model scene with proper camera
    local forceSceneChange = true
    modelViewer:TransitionToModelSceneID(petInfo.uiModelSceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, forceSceneChange)
    
    -- Create and setup the actor
    local actor = modelViewer:GetActorByTag("pet")
    if not actor then
        actor = modelViewer:CreateActorByTag("pet")
    end
    
    if actor then
        actor:SetModelByCreatureDisplayID(petInfo.displayID)
        actor:SetSpellVisualKit(0)
        actor:Show()
    end

    -- Add control frame
    local controlFrame = CreateFrame("Frame", nil, modelViewer, "ModelSceneControlFrameTemplate") 
    controlFrame:SetPoint("BOTTOM", modelViewer, "BOTTOM", 0, 90)
    controlFrame:SetModelScene(modelViewer)

    -- Set up mouse wheel zoom
    modelViewer:SetScript("OnMouseWheel", function(self, delta)
        local zoomChange = delta * 0.5
        local actorScale = actor:GetScale()
        actorScale = math.max(0.1, math.min(3.0, actorScale + zoomChange))
        actor:SetScale(actorScale)
    end)

    -- Create the active pets list using the template
    if not modelViewer.activePetList then
        modelViewer.activePetList = CreateFrame("Frame", nil, detailPanel, "GiuiceHunterActivePetListTemplate");
        modelViewer.activePetList:SetPoint("TOPLEFT", modelViewer, "BOTTOMLEFT", 0, 45);
        modelViewer.activePetList:SetPoint("TOPRIGHT", modelViewer, "BOTTOMRIGHT", 0, 45);
    end
    
    modelViewer.activePetList:Refresh();

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
