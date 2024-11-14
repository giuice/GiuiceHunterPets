addonName, GHP = ...
local HBD = LibStub("HereBeDragons-2.0");
local petPins = LibStub("HereBeDragons-Pins-2.0");
if (select(3, UnitClass("player")) ~= 3) then return end

local function CreateButton(parent)
    local button = CreateFrame("Button", "GHPMapButton", parent, "UIPanelButtonTemplate")
    button:SetText("Pet Map Options")
    button:SetSize(120, 30)
    button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -50, -30)

    local menu = CreateFrame("Frame", "GHPMapMenu", button, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(menu, 120)
    UIDropDownMenu_Initialize(menu, function(self, level)
        if not self then return end
        local info = UIDropDownMenu_CreateInfo()
        
        -- Show All Pets option
        info.text = "Show All Pets"
        info.func = function() GHP:ToggleAllPets(true) end
        UIDropDownMenu_AddButton(info, level)
        
        -- Visualize Pet Families option
        info.text = "Visualize Pet Families"
        info.func = function() GHP:ToggleFamilyVisualization(true) end
        UIDropDownMenu_AddButton(info, level)
    end)

    button:SetScript("OnClick", function(self)
        ToggleDropDownMenu(1, nil, menu, self, 0, 0)
    end)
end

-- Call this function to create the button when you initialize your addon.



local function DisplayPetIcons()
    local playerZoneID = HBD:GetPlayerZone()
	print(playerZoneID);
    for _, petData in ipairs(GHP.pet_by_zones) do
        if petData.zoneID == playerZoneID then
            for _, coords in ipairs(petData.coords) do
                local x, y = unpack(coords)
                local worldX, worldY = WorldMapFrame:GetNormalizedCursorPosition()
                local mapX, mapY = HBD:ComputeWorldPosition(playerZoneID, x / 100, y / 100)
                
                -- Create an icon frame
                local icon = CreateFrame("Frame", nil, WorldMapFrame, "GHP_PetIconTemplate")
                icon:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", mapX * WorldMapDetailFrame:GetWidth(), -mapY * WorldMapDetailFrame:GetHeight())
            end
        end
    end
end


local initializeModule = function()
	CreateButton(WorldMapFrame);
	DisplayPetIcons();
end

-- Register for ADDON_LOADED
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == addonName then
        initializeModule()
        print("GiuiceHunterMapButton loaded successfully!")
    end
end)
