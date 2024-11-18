local addonName, GHP = ...
local HBD = LibStub("HereBeDragons-2.0");
local petPins = LibStub("HereBeDragons-Pins-2.0");
if (select(3, UnitClass("player")) ~= 3) then return end

local function CreateButton(parent)


    local Dropdown = CreateFrame("DropdownButton", "GHPMapButton", parent, "WowStyle1DropdownTemplate")
    Dropdown:SetDefaultText("Default Text")
    Dropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -50, -30)
    Dropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:CreateTitle("Test Menu")
    rootDescription:CreateButton("Show pets on Map", function() print("Clicked button 1") end)
    rootDescription:CreateButton("Show pets on Minimap", function() print("Clicked button 2") end)
    rootDescription:CreateButton("Hide pets on Map", function() print("Clicked button 3") end)
    end)


    -- local button = CreateFrame("Button", "GHPMapButton", parent, "UIPanelButtonTemplate")
    -- button:SetText("Pet Map Options")
    -- button:SetSize(120, 30)
    -- button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -50, -30)




    -- local menu = CreateFrame("Frame", "GHPMapMenu", button, "UIDropDownMenuTemplate")
    -- UIDropDownMenu_SetWidth(menu, 120)
    -- UIDropDownMenu_Initialize(menu, function(self, level)
    --     if not self then return end
    --     local info = UIDropDownMenu_CreateInfo()
        
    --     -- Show All Pets option
    --     info.text = "Show All Pets"
    --     info.func = function() GHP:ToggleAllPets(true) end
    --     UIDropDownMenu_AddButton(info, level)
        
    --     -- Visualize Pet Families option
    --     info.text = "Visualize Pet Families"
    --     info.func = function() GHP:ToggleFamilyVisualization(true) end
    --     UIDropDownMenu_AddButton(info, level)
    -- end)

    -- button:SetScript("OnClick", function(self)
    --     ToggleDropDownMenu(1, nil, menu, self, 0, 0)
    --end)
end

local function ShowFamilyInfoWindow(petData, familyInfo, anchorFrame)
    -- Create or get the window
    if not GHP.familyInfoWindow then
        local window = CreateFrame("Frame", "GHPFamilyInfoWindow", UIParent, "BackdropTemplate")
        GHP.familyInfoWindow = window
        window:SetSize(300, 400)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        
        -- Set backdrop
        window:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        window:SetBackdropColor(0, 0, 0, 0.9)
        
        -- Add close button
        local closeButton = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, 0)
        
        -- Title
        window.title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        window.title:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -10)
        
        -- Content frame for abilities
        window.content = CreateFrame("Frame", nil, window)
        window.content:SetPoint("TOPLEFT", window.title, "BOTTOMLEFT", 0, -10)
        window.content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -10, 10)
    end
    
    local window = GHP.familyInfoWindow
    window:Show()
    
    -- Update title
    window.title:SetText(petData.name)
    
    -- Clear previous content
    if window.abilityFrames then
        for _, frame in ipairs(window.abilityFrames) do
            frame:Hide()
        end
    end
    window.abilityFrames = {}
    
    -- Add abilities
    local lastFrame = nil
    if familyInfo.abilities then
        for i, abilityData in ipairs(familyInfo.abilities) do
            print(abilityData.name, abilityData.spell_id)
            local abilityFrame = CreateFrame("Frame", nil, window.content)
            table.insert(window.abilityFrames, abilityFrame)
            abilityFrame:SetSize(280, 32)
            abilityFrame:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0, -10)
            
            -- Icon
            local icon = abilityFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("LEFT", 0, 0)
            
            -- Try to get spell info
            local name, _, iconTexture = C_Spell.GetSpellInfo(abilityData.spell_id)
            if iconTexture then
                icon:SetTexture(iconTexture)
            else
                icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
            
            -- Name text
            local nameText = abilityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameText:SetText(abilityData.name or name or "Unknown Ability")
            
            -- Tooltip
            abilityFrame:EnableMouse(true)
            abilityFrame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(abilityFrame, "ANCHOR_RIGHT")
                if abilityData.spell_id then
                    GameTooltip:SetSpellByID(abilityData.spell_id)
                else
                    GameTooltip:SetText(abilityData.name or "Unknown Ability")
                end
                GameTooltip:Show()
            end)
            abilityFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            lastFrame = abilityFrame
        end
    end
end

local function DisplayPetIcons()
    -- 1. Clear existing pins
    petPins:RemoveAllWorldMapIcons("GiuiceHunterPetsIcons")
    
    -- 2. Get current map ID
    local playerMapID = C_Map.GetBestMapForUnit("player")
    if not playerMapID then
        print("Could not determine player's zone ID.")
        return
    end
    -- 3. Add pins for each pet location
    for _, petData in ipairs(GHP.pet_by_zones) do
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
                
                local texturePath = "Interface\\AddOns\\GiuiceHunterPets\\icons\\PetIcons\\32x32\\" .. familyName .. ".blp"
                texture:SetTexture(texturePath)
                if not texture:GetTexture() then
                    
                    local familyAtlasName = "Interface\\Icons\\Ability_Hunter_Pet_" .. familyName:gsub("(%a)([%w_']*)", function(first, rest)
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
                
                pin:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                pin:SetScript("OnMouseDown", function(self)
                    local familyInfo = GHP.FAMILY_DATA[petData.family[1]]
                    print("familyInfo: ", familyInfo.diet)
                    if familyInfo then
                        ShowFamilyInfoWindow(petData, familyInfo, self)
                    end
                end)
                
                -- 7. Add the pin using HBD-Pins
                petPins:AddWorldMapIconMap("GiuiceHunterPetsIcons", pin, playerMapID, tonumber(x)/100, tonumber(y)/100, HBD_PINS_WORLDMAP_SHOW_WORLD)
            end
        end
    end
end


function WorldMapAvailable()
    
    if not (WorldMapFrame:IsVisible()) then
        return false;
    end
    
    local width = WorldMapFrame:GetCanvas():GetWidth()
    local height = WorldMapFrame:GetCanvas():GetHeight()
    
    if (width <= 0 or height <= 0) then
        return false;
    end
    
    return true;
end

function GetWorldMapID()
    return WorldMapFrame:GetMapID();
end

function GetWorldMapZone()
    return WorldMapFrame:GetCurrentZoneID();
end

function GetMapID()
    return C_Map.GetBestMapForUnit("player");
end

function GetPlayerPosition(mapID)
    return C_Map.GetPlayerMapPosition(mapID, "player");
end

WorldMapFrame:HookScript("OnShow", DisplayPetIcons)
WorldMapFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
WorldMapFrame:HookScript("OnEvent", DisplayPetIcons)

local initializeModule = function()
	CreateButton(WorldMapFrame);
    
	--DisplayPetIcons();
end


local function OnEvent(self, event, ...)
	print(event, GetSubZoneText(), GetZoneText(), C_Map.GetBestMapForUnit("player") )
end

local f = CreateFrame("Frame")
f:RegisterEvent("ZONE_CHANGED")
f:SetScript("OnEvent", OnEvent)

-- Register for ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        initializeModule()
    end
end)
