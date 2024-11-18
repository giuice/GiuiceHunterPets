-- Create addon namespace
local addonName, GHP = ...

-- Check for Hunter class first
if (select(3, UnitClass("player")) ~= 3) then return end

local function IsPlayerBeastMastery()
    -- Get current specialization
    local currentSpec = GetSpecialization()
    if not currentSpec then return false end
    
    -- Beast Mastery is spec 1 for hunters
    return currentSpec == 1
end

local function IsExoticFamily(family)
    print("family: " .. family)
    return family and GHP.exoticFamilies[family] or false
end

-- Create frame for events
local f = CreateFrame("Frame")


local function IsInTameableList(creatureID)
    
    
    if not creatureID then 
        return false 
    end

    -- Since our table is an array of IDs, we need to iterate through it
    for _, petData in ipairs(GHP.pets_by_zone) do
        local npcId = petData["NpcId"]
        if npcId == creatureID then
            return true
        end
    end

    return false
end

-- Function to enhance tooltip
local function EnhanceTooltip(tooltip, data)
    -- Get the unit directly from the tooltip
    local _, unit = tooltip:GetUnit()
    if not unit then return end


    -- Get GUID and extract creature ID
    local guid = UnitGUID(unit)
    local creatureID
    if guid then
        local type, _, _, _, _, id = strsplit("-", guid)
        if type == "Creature" then
            creatureID = tonumber(id)
        end
    end
    
    -- Check if it's a beast
    local creatureType = UnitCreatureType(unit)
    local isValidBeast = creatureType == "Beast" or -- English
                        creatureType == "Fera"  or -- Portuguese
                        creatureType == "Bestia"    -- Spanish
    
    if not isValidBeast then return end
    
    -- Get family information
    local family = UnitCreatureFamily(unit)
    
    -- Check if the creature is in our tameable list
    local isTameable = IsInTameableList(creatureID)
    
    -- Get classification
    local classification = UnitClassification(unit)
    
    
    -- Add our custom lines
    tooltip:AddLine(" ")  -- Blank line for spacing
    tooltip:AddLine("Hunter Pet Information:", 1, 0.82, 0)
    tooltip:AddLine("Family: " .. (family or "Unknown"), 1, 1, 1)
    tooltip:AddLine("Classification: " .. (classification or "normal"), 1, 1, 1)

    local tameableText = "Tamable: "
    if isTameable then
        if IsExoticFamily(family) then
            if not IsPlayerBeastMastery() then
                tameableText = tameableText .. "|cFFFFFF00Yes - Requires Beast Mastery|r"
            else
                tameableText = tameableText .. "|cFF00FF00Yes (Exotic)|r"
            end
        else
            tameableText = tameableText .. "|cFF00FF00Yes|r"
        end
    else
        tameableText = tameableText .. "|cFFFF0000No|r"
    end
    tooltip:AddLine(tameableText)
    
    -- Add creature ID if it exists
    if creatureID then
        tooltip:AddLine("Creature ID: " .. creatureID, 0.7, 0.7, 0.7)
    end
    
    -- -- Debug information
    -- tooltip:AddLine("Debug Info:", 0.5, 0.5, 0.5)
    -- tooltip:AddLine("Has Pet UI: " .. (hasUI and "Yes" or "No"), 0.5, 0.5, 0.5)
    -- tooltip:AddLine("Is Hunter Pet: " .. (isHunterPet and "Yes" or "No"), 0.5, 0.5, 0.5)

	--local unitID = UnitGUID("mouseover")
	
end

-- Initialize function
local function Init()
    -- Register our tooltip processor
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, EnhanceTooltip)
end

-- Register events
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Init()
    end
end)