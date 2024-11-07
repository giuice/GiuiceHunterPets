-- Create the main frame
local petListFrame = CreateFrame("Frame", "HunterPetListFrame", UIParent, "BasicFrameTemplateWithInset")
petListFrame:SetSize(300, 400)
petListFrame:SetPoint("CENTER")
petListFrame.title = petListFrame:CreateFontString(nil, "OVERLAY")
petListFrame.title:SetFontObject("GameFontHighlightLarge")
petListFrame.title:SetPoint("TOP", 0, -10)
petListFrame.title:SetText("Your Hunter Pets")

-- Scroll Frame and Child to hold the pet list
local scrollFrame = CreateFrame("ScrollFrame", nil, petListFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(260, 380)
scrollFrame:SetScrollChild(content)

petListFrame:Hide()  -- Hide the frame initially

-- Function to list all hunter pets
local function ListHunterPets()
    local numStablePets = C_StableInfo.GetNumStablePets()
    local yOffset = -10  -- Starting offset for pet entries
    
    for i = 1, numStablePets do
        local petInfo = C_StableInfo.GetStablePetInfo(i)
        
        if petInfo then
            local name = petInfo.name or "Unknown"
            local level = petInfo.level or 0
            local isActive = petInfo.isActive  -- True if pet is one of the active pets
            
            -- Display pet info
            local petText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            petText:SetPoint("TOPLEFT", 10, yOffset)
            petText:SetText(("%s (Level %d)%s"):format(name, level, isActive and " [Active]" or ""))
            
            yOffset = yOffset - 20  -- Update yOffset for next pet entry
        end
    end
    
    content:SetHeight(-yOffset)  -- Set content height based on total entries
end

-- Show hunter pets when the frame is shown
petListFrame:SetScript("OnShow", ListHunterPets)

-- Toggle the frame with a slash command
SLASH_HUNTERPETLIST1 = "/hunterpets"
SlashCmdList["HUNTERPETLIST"] = function()
    if petListFrame:IsShown() then
        petListFrame:Hide()
    else
        petListFrame:Show()
    end
end
