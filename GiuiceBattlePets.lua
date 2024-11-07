

-- Create the main frame
local petListFrame = CreateFrame("Frame", "PetListFrame", UIParent, "BasicFrameTemplateWithInset")
petListFrame:SetSize(300, 400)
petListFrame:SetPoint("CENTER")
petListFrame.title = petListFrame:CreateFontString(nil, "OVERLAY")
petListFrame.title:SetFontObject("GameFontHighlightLarge")
petListFrame.title:SetPoint("TOP", 0, -10)
petListFrame.title:SetText("Your Pets")

-- Scroll Frame and Child to hold the pet list
local scrollFrame = CreateFrame("ScrollFrame", nil, petListFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(260, 380)
scrollFrame:SetScrollChild(content)

petListFrame:Hide()  -- Hide the frame initially

-- Function to list all pets
local function ListAllPets()
    local numPets = C_PetJournal.GetNumPets()
    local yOffset = -10  -- Starting offset for pet entries

    for i = 1, numPets do
        -- Retrieve pet info
        local petID, speciesID, isOwned, customName, level, favorite, isRevoked,
              speciesName, icon, petType = C_PetJournal.GetPetInfoByIndex(i)
        
        if isOwned then  -- Only show owned pets
            -- Create a font string for each pet
            local petText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            petText:SetPoint("TOPLEFT", 10, yOffset)
            petText:SetText(("%s (Level %d)"):format(customName or speciesName, level))
            
            yOffset = yOffset - 20  -- Update yOffset for next pet entry
        end
    end
    
    content:SetHeight(-yOffset)  -- Set content height based on total entries
end

-- Show pets when the frame is shown
petListFrame:SetScript("OnShow", ListAllPets)

-- Toggle the frame with a slash command
SLASH_PETLIST1 = "/petlist"
SlashCmdList["PETLIST"] = function()
    if petListFrame:IsShown() then
        petListFrame:Hide()
    else
        petListFrame:Show()
    end
end
