local addonName, GHP = ...
local HBD = LibStub("HereBeDragons-2.0");
local petPins = LibStub("HereBeDragons-Pins-2.0");
if (select(3, UnitClass("player")) ~= 3) then return end


local function CreateFamilyInfoWindowOld()
    -- Create main frame if it doesn't exist
    if not GHP.familyInfoFrame then
        local frame = CreateFrame("Frame", "GHPFamilyInfoFrame", UIParent, "TooltipBorderBackdropTemplate")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetSize(400, 300)

        --create close button Here
        frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeButton:SetPoint("TOPRIGHT", 0, 0)
        frame.closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)


        -- Title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
        frame.title:SetPoint("TOPLEFT", 15, -15)

        -- Pet Type
        frame.petType = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.petType:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)

        frame.modelViewer = CreateFrame("ModelScene", nil, frame, "PanningModelSceneMixinTemplate") -- Create the model frame in the right position
        frame.modelViewer:SetPoint("TOPLEFT", frame, "TOPLEFT", 140, -80)
        frame.modelViewer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 20)


        -- Diet
        frame.diet = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.diet:SetPoint("TOPLEFT", frame.petType, "BOTTOMLEFT", 0, -5)

        -- Exotic Status
        frame.exotic = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.exotic:SetPoint("TOPLEFT", frame.diet, "BOTTOMLEFT", 0, -5)

        -- class Status
        frame.class = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.class:SetPoint("TOPLEFT", frame.exotic, "BOTTOMLEFT", 0, -5)

        -- Abilities Header
        frame.abilitiesHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
        frame.abilitiesHeader:SetText("Abilities")
        frame.abilitiesHeader:SetPoint("TOPLEFT", frame.exotic, "BOTTOMLEFT", 0, -15)

        -- Abilities Container
        frame.abilities = CreateFrame("Frame", nil, frame)
        frame.abilities:SetPoint("TOPLEFT", frame.abilitiesHeader, "BOTTOMLEFT", 0, -5)
        frame.abilities:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)

        -- Style the frame
        frame:SetBackdropBorderColor(0.6, 0.6, 0.6)
        frame:SetBackdropColor(0, 0, 0, 0.8)

        -- Modal handling
        frame:SetScript("OnShow", function(self)
            GameTooltip:Hide() -- Hide the tooltip when opening
        end)

        frame:SetScript("OnHide", function(self)

        end)

        GHP.familyInfoFrame = frame
    end

    return GHP.familyInfoFrame
end


local function CreateFamilyInfoWindow()
    if not GHP.familyInfoFrame then
        local frame = CreateFrame("Frame", "GHPFamilyInfoFrame", UIParent, "TooltipBorderBackdropTemplate")
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetSize(400, 300)
        -- Create left panel for information
        frame.leftPanel = CreateFrame("Frame", nil, frame)
        frame.leftPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
        frame.leftPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
        frame.leftPanel:SetWidth(frame:GetWidth() * 0.4 - 20) -- 50% width minus padding

        -- Create close button
        frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.closeButton:SetPoint("TOPRIGHT", 0, 0)
        frame.closeButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        -- Title
        frame.title = frame.leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
        frame.title:SetPoint("TOPLEFT", 0, 0)

        -- Pet Type
        frame.petType = frame.leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.petType:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)

        -- Diet
        frame.diet = frame.leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.diet:SetPoint("TOPLEFT", frame.petType, "BOTTOMLEFT", 0, -5)

        -- Exotic Status
        frame.exotic = frame.leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.exotic:SetPoint("TOPLEFT", frame.diet, "BOTTOMLEFT", 0, -5)

        -- Class Status
        frame.class = frame.leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.class:SetPoint("TOPLEFT", frame.exotic, "BOTTOMLEFT", 0, -5)

        -- Abilities Header
        frame.abilitiesHeader = frame.leftPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
        frame.abilitiesHeader:SetText("Abilities")
        frame.abilitiesHeader:SetPoint("TOPLEFT", frame.class, "BOTTOMLEFT", 0, -15)

        -- Abilities Container
        frame.abilities = CreateFrame("Frame", nil, frame.leftPanel)
        frame.abilities:SetPoint("TOPLEFT", frame.abilitiesHeader, "BOTTOMLEFT", 0, -5)
        frame.abilities:SetPoint("BOTTOMRIGHT", frame.leftPanel, "BOTTOMRIGHT", 0, 0)

        -- Create right panel with border for model viewer
        frame.rightPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
        frame.rightPanel:SetPoint("TOPLEFT", frame.leftPanel, "TOPRIGHT", 10, -30)
        frame.rightPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)

        

        -- Create model viewer inside right panel
        frame.modelViewer = CreateFrame("ModelScene", nil, frame.rightPanel, "PanningModelSceneMixinTemplate")
        frame.modelViewer:SetPoint("TOPLEFT", frame.rightPanel, "TOPLEFT", 4, -4)
        frame.modelViewer:SetPoint("BOTTOMRIGHT", frame.rightPanel, "BOTTOMRIGHT", -4, 4)

        -- Style the main frame
        frame:SetBackdropBorderColor(0.6, 0.6, 0.6)
        frame:SetBackdropColor(0, 0, 0, 0.8)

        -- Modal handling
        frame:SetScript("OnShow", function(self)
            GameTooltip:Hide()
        end)

        frame:SetScript("OnHide", function(self)
        end)

        GHP.familyInfoFrame = frame
    end

    return GHP.familyInfoFrame
end



local function SetModelViewerOld(frame, displayId)
    -- Clear previous scene and actors
    frame.modelViewer:ClearScene()

    -- Set up camera parameters
    frame.modelViewer:SetCameraPosition(0, 0, 20) -- Adjust Z to move camera back
    frame.modelViewer:SetCameraFieldOfView(0.9)   -- Narrower FOV to reduce perspective distortion
    frame.modelViewer:SetCameraNearClip(0.1)      -- Closer near clip plane
    frame.modelViewer:SetCameraFarClip(100)       -- Further far clip plane


    -- Use proper transition with camera settings
    local forceSceneChange = true
    frame.modelViewer:TransitionToModelSceneID(718,
        CAMERA_TRANSITION_TYPE_IMMEDIATE,
        CAMERA_MODIFICATION_TYPE_DISCARD,
        forceSceneChange
    )

    local actor = frame.modelViewer:GetActorByTag("pet")
    if not actor then
        actor = frame.modelViewer:CreateActorFromScene(displayId) -- Better actor creation
        if not actor then
            actor = frame.modelViewer:AcquireActor()              -- Fallback
        end
    end

    if actor then
        actor:SetModelByCreatureDisplayID(displayId)
        
        -- Center the actor in the safe area
        actor:SetPosition(0, 0, -2)
        -- Set initial scale that works with the insets
        actor:SetScale(0.7)
        actor:Show()
        
        frame.modelViewer:AddOrUpdateDropShadow(actor, 1.0)
    end

    -- Control frame (create once)
    if not frame.modelViewer.ControlFrame then
        local controlFrame = CreateFrame("Frame", nil, frame.modelViewer, "ModelSceneControlFrameTemplate")
        controlFrame:SetPoint("BOTTOM", frame.modelViewer, "BOTTOM", 0, 10)
        controlFrame:SetModelScene(frame.modelViewer)
        frame.modelViewer.ControlFrame = controlFrame
        -- Mouse over events for control frame
        frame.modelViewer:SetScript("OnEnter", function(self)
            self.ControlFrame:Show()
        end)
        frame.modelViewer:SetScript("OnLeave", function(self)
            self.ControlFrame:Hide()
        end)
    end

    -- Zoom via actor scaling
    frame.modelViewer:SetScript("OnMouseWheel", function(self, delta)
        local zoomChange = delta * 0.1
        local actorScale = actor and actor:GetScale() or 1
        actorScale = math.max(0.1, math.min(3.0, actorScale + zoomChange))
        if actor then actor:SetScale(actorScale) end
    end)

    frame:Show()
end

local function SetModelViewer(frame, displayId)
    -- Clear previous scene and actors
    frame.modelViewer:ClearScene()

    -- Use proper transition with camera settings
    local forceSceneChange = true
    frame.modelViewer:TransitionToModelSceneID(718,
        CAMERA_TRANSITION_TYPE_IMMEDIATE,
        CAMERA_MODIFICATION_TYPE_DISCARD,
        forceSceneChange
    )

    -- Create and setup the actor using Blizzard's pattern
    local actor = frame.modelViewer:GetActorByTag("pet")
    if not actor then
        actor = frame.modelViewer:CreateActorFromScene(displayId) -- Better actor creation
        if not actor then
            actor = frame.modelViewer:AcquireActor()              -- Fallback
        end
    end



    if actor then
        actor:SetModelByCreatureDisplayID(displayId)
        actor:SetSpellVisualKit(0)
        actor:SetScale(0.8)
        actor:Show()

        -- Add drop shadow for better visuals
        frame.modelViewer:AddOrUpdateDropShadow(actor, 1.0)

    end

    -- Create control frame if not exists
    if not frame.modelViewer.ControlFrame then
        local controlFrame = CreateFrame("Frame", nil, frame.modelViewer, "ModelSceneControlFrameTemplate")
        controlFrame:SetPoint("BOTTOM", frame.modelViewer, "BOTTOM", 0, 30)
        controlFrame:SetModelScene(frame.modelViewer)
        frame.modelViewer.ControlFrame = controlFrame

        -- Show/Hide control frame on mouse over
        frame.modelViewer:SetScript("OnEnter", ModelSceneMixin.OnEnter)
        frame.modelViewer:SetScript("OnLeave", ModelSceneMixin.OnLeave)
    end

    -- Better zoom handling using proper camera controls
    frame.modelViewer:SetScript("OnMouseWheel", function(self, delta)
        local zoomChange = delta * 0.5
        local actorScale = actor:GetScale()
        actorScale = math.max(0.1, math.min(3.0, actorScale + zoomChange))
        actor:SetScale(actorScale)
    end)
end



local function ShowFamilyInfoWindow(familyData, petData, anchor)
    if not familyData then return end

    local frame = CreateFamilyInfoWindow()

    -- Update content
    frame.title:SetText((petData.name .. " (" .. petData.family[2] .. ") ") or "Unknown Family")
    frame.petType:SetText("Type: " .. (familyData.pet_type or "Unknown"))
    frame.diet:SetText("Diet: " .. (familyData.diet or "Unknown"))
    frame.exotic:SetText(familyData.exotic == 1 and "|cFFFFFF00Exotic|r" or "No Exotic")
    frame.class:SetText("Class: " .. (petData.class or "Unknown"))

    SetModelViewer(frame, petData.displayId)

    -- Clear and recreate ability buttons
    if frame.abilityButtons then
        for _, button in ipairs(frame.abilityButtons) do
            button:Hide()
        end
    end

    frame.abilityButtons = frame.abilityButtons or {}

    if familyData.abilities then
        local previousButton
        for i, ability in ipairs(familyData.abilities) do
            local button = frame.abilityButtons[i] or CreateFrame("Button", nil, frame.abilities)
            frame.abilityButtons[i] = button

            -- Style ability button
            button:SetSize(240, 24)
            if not button.texture then
                button.texture = button:CreateTexture(nil, "ARTWORK")
                button.texture:SetSize(24, 24)
                button.texture:SetPoint("LEFT")

                button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                button.text:SetPoint("LEFT", button.texture, "RIGHT", 5, 0)
            end

            -- Set ability info

            button.text:SetText(ability.name:gsub("^%l", string.upper))
            local spellInfo = C_Spell.GetSpellInfo(ability.spell_id)
            if spellInfo.iconID then
                button.texture:SetTexture(spellInfo.iconID)
            else
                button.texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- Default icon if not found
            end

            -- Position button
            button:ClearAllPoints()
            if previousButton then
                button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -2)
            else
                button:SetPoint("TOPLEFT", 0, 0)
            end

            button:Show()
            previousButton = button
        end
    end

    -- Position frame near anchor
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER")

    -- Show with fade animation
    frame:SetAlpha(0)
    frame:Show()
    frame:SetScript("OnUpdate", function(self)
        local alpha = self:GetAlpha() + 0.1
        if alpha >= 1.0 then
            self:SetAlpha(1.0)
            self:SetScript("OnUpdate", nil)
        else
            self:SetAlpha(alpha)
        end
    end)
end


-- Function to remove all existing pins
local function RemoveAllPins()
    petPins:RemoveAllWorldMapIcons("GiuiceHunterPetsIcons")
end

local pinSettingsTableOptions = {
    [1] = "allpets",
    [2] = "rarepets",
    [3] = "elitepets",
    [4] = "nopets"
}
local function DisplayPetIcons()
    if not GHP_SavedVars.worldMapPins or GHP_SavedVars.worldMapPins == 4 then
        return
    end  
    -- 1. Clear existing pins
    petPins:RemoveAllWorldMapIcons("GiuiceHunterPetsIcons")

    -- 2. Get current map ID
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then
        --print("Could not determine player's zone ID.")
        return
    end

     -- Filter pets based on settings
     local filteredPets = {}
     for _, petData in ipairs(GHP.pet_by_zones) do
         if petData.zoneID == playerMapID then
             local setting = pinSettingsTableOptions[GHP_SavedVars.worldMapPins]
             if (setting == "rarepets" and petData.class == "Rare") or
                (setting == "elitepets" and petData.class == "Elite") or
                (setting == "allpets") then
                 table.insert(filteredPets, petData)
             end
         end
     end

    -- 3. Add pins for each pet location
    for _, petData in ipairs(filteredPets) do
        if petData.zoneID == playerMapID then
            for _, coords in ipairs(petData.coords) do
                local x, y = unpack(coords)
                local familyName = petData.family[2];

                -- 4. Create pin frame
                local pin = CreateFrame("Frame", nil, WorldMapFrame)
                pin:SetSize(24, 24)

                -- 5. Setup pin texture
                local texture = pin:CreateTexture(nil, "OVERLAY")
                texture:SetAllPoints()

                local texturePath = "Interface\\AddOns\\GiuiceHunterPets\\icons\\PetIcons\\32x32\\" ..
                    familyName .. ".blp"
                texture:SetTexture(texturePath)
                if not texture:GetTexture() then
                    local familyAtlasName = "Interface\\Icons\\Ability_Hunter_Pet_" ..
                        familyName:gsub("(%a)([%w_']*)", function(first, rest)
                            return first:upper() .. rest:lower()
                        end):gsub("%s+", "")

                    texture:SetTexture(familyAtlasName)
                    if not texture:GetTexture() then
                        texturePath = "Interface\\AddOns\\GiuiceHunterPets\\icons\\PetIcons\\32x32\\Unknown.blp"
                        texture:SetTexture(texturePath)
                    end
                end

                --texture:SetTexture(texturePath)
                pin:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(petData.name)
                    local familyInfo = GHP.FAMILY_DATA[petData.family[1]]
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFFFFD100Family:|r " .. petData.family[2], 1, 1, 1)
                    -- Add any additional family info if available
                    if familyInfo.specialization then
                        GameTooltip:AddLine("|cFFFFD100Specialization:|r " .. familyInfo.specialization, 1, 1, 1)
                    end
                    -- Add hint for abilities
                    if familyInfo.abilities and #familyInfo.abilities > 0 then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("|cFFFFD100Abilities:|r Click to view", 0.5, 0.8, 1)
                    end
                    GameTooltip:Show()
                end)

                pin:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                pin:SetScript("OnMouseDown", function(self)
                    GameTooltip:Hide()
                    local familyData = GHP.FAMILY_DATA[petData.family[1]]
                    ShowFamilyInfoWindow(familyData, petData, self)
                end)

                -- 7. Add the pin using HBD-Pins
                petPins:AddWorldMapIconMap("GiuiceHunterPetsIcons", pin, playerMapID, tonumber(x) / 100, tonumber(y) /
                    100, HBD_PINS_WORLDMAP_SHOW_WORLD)
            end
        end
    end
end


-- Function to manage events based on setting
local function ManageWorldMapEvents(value)
    if value ~= 4 then
        WorldMapFrame:HookScript("OnShow", DisplayPetIcons)
        WorldMapFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        WorldMapFrame:HookScript("OnEvent", DisplayPetIcons)
    else
        WorldMapFrame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
        -- Unhook scripts if possible
        if WorldMapFrame.OnShow then
            WorldMapFrame:SetScript("OnShow", WorldMapFrame.OnShow)
        end
        if WorldMapFrame.OnEvent then
            WorldMapFrame:SetScript("OnEvent", WorldMapFrame.OnEvent)
        end
    end
end

-- Settings change handler
GHP.OnWorldMapPinsSettingChanged = function(setting, value)
    GHP_SavedVars["worldMapPins"] = value
    
    if value == 4 or not value then
        RemoveAllPins()
    end
    ManageWorldMapEvents(value)
    -- If enabled and map is currently shown, refresh pins
    if value and value ~= 4 and WorldMapFrame:IsVisible() then
        DisplayPetIcons()
    end
end

-- Initialize
local function InitializeWorldMapPins()
    -- Setup initial state based on saved setting
    local currentSetting = GHP_SavedVars.worldMapPins or 1
    ManageWorldMapEvents(currentSetting)
    if WorldMapFrame:IsVisible() then
        DisplayPetIcons()
    end
end

local initializeModule = function()
    InitializeWorldMapPins()
end




-- Register for ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        initializeModule()
    end
end)
