local addonName, GHP = ...

-- Initialize addon table with necessary functions
GHP.utils = GHP.utils or {}
GHP.frames = GHP.frames or {}


local CALL_PET_SPELL_IDS = { -- Each "active" pet slot corresponds to a "call pet" spell (with the exception of the secondary pet)
	0883,
	83242,
	83243,
	83244,
	83245,
};

local PET_STABLE_DEFAULT_ACTOR_TAG = "pet";
local ANIMAL_COMPANION_NODE_ID = 102361;
local EXTRA_PET_STABLE_SLOT_LUA_INDEX = Constants.PetConsts_PostCata.EXTRA_PET_STABLE_SLOT + 1;

-- Make required functions global for mixin
local GetListBackgroundForPetSpecialization = function(specialization)
    local backgrounds = {
        [STABLE_PET_SPEC_CUNNING] = "pet-list-bg-cunning-default",
        [STABLE_PET_SPEC_FEROCITY] = "pet-list-bg-ferocity-default",
        [STABLE_PET_SPEC_TENACITY] = "pet-list-bg-tenacity-default",
    }
    return backgrounds[specialization] or backgrounds[STABLE_PET_SPEC_FEROCITY];
end

local function IsActivePetSlotUnlocked(activePetSlot)
    if activePetSlot == 6 then
        return true
    end
	return IsSpellKnown(CALL_PET_SPELL_IDS[activePetSlot]);
end

local function GetBeastmasterSecondaryPet()
	return C_StableInfo.GetStablePetInfo(EXTRA_PET_STABLE_SLOT_LUA_INDEX);
end

local function HasAnimalCompanion()
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then
        return false
    end

    local nodeInfo = C_Traits.GetNodeInfo(configID, ANIMAL_COMPANION_NODE_ID)
    return nodeInfo and nodeInfo.ranksPurchased > 0
end

local function SetPortraitTextureFromCreatureDisplayIDFlipped(texture, creatureDisplayID)
	SetPortraitTextureFromCreatureDisplayID(texture, creatureDisplayID);
	texture:SetTexCoord(1, 0, 0, 1);
end

GiuiceHunterPetListItemMixin = {};

function GiuiceHunterPetListItemMixin:OnLoad()
    self.Background:SetAtlas(GetListBackgroundForPetSpecialization(STABLE_PET_SPEC_FEROCITY));
end

function GiuiceHunterPetListItemMixin:RefreshFavoriteIcon(petInfo)
    local isFavorite = C_StableInfo.IsPetFavorite(petInfo.slotID);
	self.Portrait.FavoriteIcon:SetShown(petInfo and isFavorite);
end

function GiuiceHunterPetListItemMixin:SetPetInfo(petInfo)
    -- Set name and type with clear text
    self.Name:SetText(petInfo.name);
    self.Name:SetFontObject(GameFontHighlightMed2)
    self.Type:SetText(string.format("%s %s", 
        petInfo.familyName,
        petInfo.isExotic and "(Exotic)" or ""));
    self.Type:SetFontObject(GameFontNormalSmall2)
    
    SetPortraitTextureFromCreatureDisplayIDFlipped(self.Portrait.Icon, petInfo.displayID);
    -- Update background based on specialization
    local atlas = GetListBackgroundForPetSpecialization(petInfo.specialization);
    if atlas then
        self.Background:SetAtlas(atlas);
    end
    
    -- Store pet info for reference
    self.petInfo = petInfo;
    self:RefreshFavoriteIcon(petInfo);
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
        GHP.utils.ShowPetDetails(GHP.frames.mainFrame.detailPanel, self.petInfo);
    end
end


GiuiceHunterActivePetButtonMixin = {};

function GiuiceHunterActivePetButtonMixin:OnLoad()
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    self:SetEnabled(false);
end

function GiuiceHunterActivePetButtonMixin:SetDesaturated(desaturate)
	self.Border:SetDesaturated(desaturate);
	self.Icon:SetDesaturated(desaturate);
end

function GiuiceHunterActivePetButtonMixin:SetPet(petData)
    self.petData = petData;
    if not petData then
        self:Reset();
        return;
    end

    SetPortraitTextureFromCreatureDisplayID(self.Icon, petData.displayID);
    self.Icon:SetDesaturated(false);
    self:SetEnabled(true);
    self:EnableMouse(true)
    self:SetScript("OnEnter", function()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(petData.name, 1, 1, 1)
        GameTooltip:Show()
    end)
    self:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function GiuiceHunterActivePetButtonMixin:Reset()
    self.petData = nil;
    self.Icon:SetTexture(nil);
    self:SetEnabled(false);
end

function GiuiceHunterActivePetButtonMixin:SetLocked(locked)
    self.Lock:SetShown(locked);
    self.Icon:SetDesaturated(locked);
    self:SetEnabled(not locked);
end


GiuiceHunterActivePetListMixin = {};

function GiuiceHunterActivePetListMixin:OnLoad()
    self.pets = {};
    self.PetButtons = {
        self.PetButton1,
        self.PetButton2,
        self.PetButton3,
        self.PetButton4,
        self.PetButton5,
    };
    
    self:RegisterEvent("PET_STABLE_UPDATE");
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    self:RegisterEvent("SPELLS_CHANGED");
end

function GiuiceHunterActivePetListMixin:OnEvent(event, ...)
    if event == "PET_STABLE_UPDATE" or 
       event == "PLAYER_SPECIALIZATION_CHANGED" or 
       event == "SPELLS_CHANGED" then
        self:Refresh();
    end
end

function GiuiceHunterActivePetListMixin:Refresh()
    self.pets = C_StableInfo.GetActivePetList() or {};
    
    -- Update regular pet slots
    for i = 1, 5 do
        local button = self.PetButtons[i];
        if button then  -- Make sure button exists
            local isUnlocked = IsActivePetSlotUnlocked(i);
            button:SetLocked(not isUnlocked);
            
            if isUnlocked then
                local petData = self.pets[i];
                if petData then
                    button:SetPet(petData);
                    button.Highlight:Show();
                else
                    button.Highlight:Hide();
                    button:Reset();
                end
            end
        end
    end

    -- Update secondary pet button if available
    local hasAnimalCompanion = HasAnimalCompanion();
    if self.BeastMasterSecondaryPetButton then
        self.BeastMasterSecondaryPetButton:SetShown(hasAnimalCompanion);
        self.Divider:SetShown(hasAnimalCompanion);
        
        if hasAnimalCompanion then
            local secondaryPet = GetBeastmasterSecondaryPet();
            if secondaryPet then
                self.BeastMasterSecondaryPetButton:SetPet(secondaryPet);
                self.BeastMasterSecondaryPetButton.Highlight:Show();
            else
                self.BeastMasterSecondaryPetButton.Highlight:Hide();
                self.BeastMasterSecondaryPetButton:Reset();
            end
        end
    end
end

GiuiceHunterBeastMasterSecondaryPetButtonMixin = CreateFromMixins(GiuiceHunterActivePetButtonMixin);

function GiuiceHunterBeastMasterSecondaryPetButtonMixin:OnShow()
    self:Refresh();
    self:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED");
end

function GiuiceHunterBeastMasterSecondaryPetButtonMixin:OnHide()
    self:UnregisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED");
end

function GiuiceHunterBeastMasterSecondaryPetButtonMixin:OnEvent(event, ...)
    if event == "ACTIVE_COMBAT_CONFIG_CHANGED" then
        self:Refresh();
    end
end

function GiuiceHunterBeastMasterSecondaryPetButtonMixin:Refresh()
    local configID = C_ClassTalents.GetActiveConfigID();
    local animalCompanionTalentInfo = configID and C_Traits.GetNodeInfo(configID, ANIMAL_COMPANION_NODE_ID);
    local knowsAnimalCompanion = animalCompanionTalentInfo and animalCompanionTalentInfo.ranksPurchased > 0;
    
    self:SetEnabled(knowsAnimalCompanion);
    self:SetDesaturated(not knowsAnimalCompanion);
    self:SetLocked(not knowsAnimalCompanion);
    
    if knowsAnimalCompanion then
        local secondaryPet = GetBeastmasterSecondaryPet();
        if secondaryPet then
            self:SetPet(secondaryPet);
        else
            self:Reset();
        end
    else
        self:Reset();
    end
    
    -- Set disabled tooltip
    self.disabledTooltip = STABLE_SECONDARY_PET_DISABLED;
end

function GiuiceHunterBeastMasterSecondaryPetButtonMixin:SetDesaturated(desaturate)
    if self.Icon then
        self.Icon:SetDesaturated(desaturate);
    end
    if self.Border then
        self.Border:SetDesaturated(desaturate);
    end
end

function GiuiceHunterBeastMasterSecondaryPetButtonMixin:OnEnter()
    if self:IsEnabled() then
        self.Highlight:Show();
    end
    
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if not self:IsEnabled() then
        GameTooltip_AddErrorLine(GameTooltip, self.disabledTooltip);
    elseif self.petData then
        GameTooltip:SetText(self.petData.name, 1, 1, 1);
        GameTooltip:AddLine(self.petData.familyName, 1, 0.82, 0);
        GameTooltip:AddLine(STABLE_SECONDARY_PET_TOOLTIP, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
end