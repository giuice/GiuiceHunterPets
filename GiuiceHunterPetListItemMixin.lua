local addonName, GHP = ...

-- Initialize addon table with necessary functions
GHP.utils = GHP.utils or {}
GHP.frames = GHP.frames or {}
-- Make required functions global for mixin
local GetListBackgroundForPetSpecialization = function(specialization)
    local backgrounds = {
        [STABLE_PET_SPEC_CUNNING] = "pet-list-bg-cunning-default",
        [STABLE_PET_SPEC_FEROCITY] = "pet-list-bg-ferocity-default",
        [STABLE_PET_SPEC_TENACITY] = "pet-list-bg-tenacity-default",
    }
    return backgrounds[specialization] or backgrounds[STABLE_PET_SPEC_FEROCITY];
end

GiuiceHunterPetListItemMixin = {};

function GiuiceHunterPetListItemMixin:OnLoad()
    self.Background:SetAtlas(GetListBackgroundForPetSpecialization(STABLE_PET_SPEC_FEROCITY));
end

function GiuiceHunterPetListItemMixin:SetPetInfo(petInfo)
    -- Set name and type with clear text
    self.Name:SetText(petInfo.name);
    self.Type:SetText(string.format("%s %s", 
        petInfo.familyName,
        petInfo.isExotic and "(Exotic)" or ""));
    
    -- Set portrait properly
    self.Portrait.Icon:SetTexture(petInfo.icon);
    self.Portrait.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
    
    -- Update background based on specialization
    local atlas = GetListBackgroundForPetSpecialization(petInfo.specialization);
    if atlas then
        self.Background:SetAtlas(atlas);
    end
    
    -- Store pet info for reference
    self.petInfo = petInfo;
end

function GiuiceHunterPetListItemMixin:OnEnter()
    -- Create highlight effect
    if not self.HighlightTexture then
        self.HighlightTexture = self:CreateTexture(nil, "HIGHLIGHT")
        self.HighlightTexture:SetAllPoints(self.Background)
        self.HighlightTexture:SetColorTexture(1, 1, 1, 0.1)
    end
    self.HighlightTexture:Show()
    
    -- Show tooltip if needed
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.petInfo.name, 1, 1, 1)
    GameTooltip:AddLine(string.format("%s %s", 
        self.petInfo.familyName,
        self.petInfo.isExotic and "(Exotic)" or ""), 
        1, 0.82, 0)
    GameTooltip:Show()
end

function GiuiceHunterPetListItemMixin:OnLeave()
    if self.HighlightTexture then
        self.HighlightTexture:Hide()
    end
    GameTooltip:Hide()
end

function GiuiceHunterPetListItemMixin:OnClick()
    if self.petInfo then
        print("Clicked on pet: " .. self.petInfo.name)
        GHP.utils.ShowPetDetails(GHP.frames.mainFrame.detailPanel, self.petInfo);
    end
end