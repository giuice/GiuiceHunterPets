# Main file of aspect of the hunter addon
```lua
AddOnName, AOTH = ...;

AspectOfTheHunter = LibStub("AceAddon-3.0"):GetAddon("AspectOfTheHunter")
local HBD = LibStub("HereBeDragons-2.0")
local petPins = LibStub("HereBeDragons-Pins-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AspectOfTheHunter")


if (select(3, UnitClass("player")) ~= 3) then return end

----------------------------------------------------------
-- TODO
--* Add rare elites to db
--* Add rare mech pets
----------------------------------------------------------
--[[
DEBUG SECTION
]]
SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

SLASH_VERSION1 = "/ver"
SlashCmdList.VERSION = function()print("|cFF00FF00 The version of AOTH you are using is:|r " .. ADDON_VERSION) end

SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
    LoadAddOn("Blizzard_DebugTools")
    FrameStackTooltip_Toggle()
end


local ICON_PATH = "Interface\\AddOns\\" .. AOTH.constants["ADDON_NAME"] .. "\\Icons\\";


local RARE_COLLECTION = {}
local KEY_WORLD_MAP_PIN = "worldpin";
local KEY_ZONE_NAME = "zonename";
local KEY_NPC_NAME = "npcname";
local KEY_FAMILY = "petName";
local KEY_POSITION_X = "x";
local KEY_POSITION_Y = "y";
local KEY_MINLEVEL = "minlevel";
local KEY_MAXLEVEL = "maxlevel";
local KEY_CLASS = "class";
local KEY_TYPE = "type";
local KEY_ABILITY = "ability";
local KEY_INFO = "info"
local KEY_ARMOR = "armor";
local KEY_SPAWN = "spawn";
local KEY_MODEL = "model";
local KEY_SPELLS = "spells";
local KEY_PIN_ID = "loot";
local KEY_LOADED = "loaded";
local KEY_TEXTURE = "texture";
local KEY_PET_ID = "id";


PET_FAMILY_TO_HIDE = ""
PIN_POSITION = 1;

local CLASS_RARE = L["RARE_PET"];
local CLASS_RARE_ELITE = L["RARE_ELITE_PET"];
local CLASS_ELITE = L["ELITE_PET"];
local CLASS_STABLE_MASTER = L["STABLE_MASTER"];
--local CLASS_NORMAL        = L["NORMAL_PET"] ;
local CLASS_BOSS = L["BOSS"];
local CLASS_WORLD_BOSS = L["WORLD_BOSS"];




local CLASS_COLOR_CODES = {};
CLASS_COLOR_CODES[CLASS_RARE] = "|c1eff00ff";
CLASS_COLOR_CODES[CLASS_RARE_ELITE] = "|c0070ddff";
CLASS_COLOR_CODES[CLASS_ELITE] = "|c0070ddff";
CLASS_COLOR_CODES[CLASS_STABLE_MASTER] = "|c00ffffff";
CLASS_COLOR_CODES[CLASS_BOSS] = "|ca335eeff";
CLASS_COLOR_CODES[CLASS_WORLD_BOSS] = "|ca335eeff";

local TYPE_BEAST = "Beast";

local DELAY = 1; -- Seconds
local DATA = {};

local WORLD_MAP_ID = -1;
local WORLD_MAP_PINS = {};
local STABLE_MASTERS = {}
local PET_MENU = "";
local petModel = "";
local WORLD_MAP_CONTAINER = WorldMapFrame:GetCanvas();
local WORLD_MAP_PIN_SIZE = 22;

local PLAYER_MAP_ID = -1;
local TOOLTIP_PADDING = "          "
local PETS_TO_LOAD = {}
local MINI_PETS_TO_LOAD = {}
local ZONE_TO_LOAD = {}
local MAIN_FRAME = CreateFrame("Frame", AOTH.constants["ADDON_NAME"]);
MAIN_FRAME:RegisterEvent("PLAYER_LOGOUT")
MAIN_FRAME:RegisterEvent("ADDON_LOADED")
MAIN_FRAME:RegisterEvent("ZONE_CHANGED");
MAIN_FRAME:SetScript("OnUpdate", function(self, sinceLastUpdate)AspectOfTheHunter:OnUpdate(sinceLastUpdate); end);
MAIN_FRAME:SetScript("OnEvent", function(self, event, ...)AspectOfTheHunter:OnEvent(event); end);




function AspectOfTheHunter:InitializeZones()
    
    local minimal = AOTH.db.general.MinimalMapIcons;
    
    for i = 1, #AOTH.test, 1 do
        local idCount = 0
        if (#AOTH.test[i]["coords"] > 1) then
            for n = 1, #AOTH.test[i]["coords"] do
                idCount = AOTH:Increment(idCount, minimal)
                local x = AOTH.test[i]["coords"][n][1]
                local y = AOTH.test[i]["coords"][n][2]
                
                AspectOfTheHunter:SetZoneNPCData(AOTH.test[i]["zoneID"], -- ZONE
                    AOTH.test[i]["name"] .. " [Spot: " .. n .. "]", -- NAME
                    AOTH.test[i]["family"][2],
                    x, y, AOTH.test[i]["minlevel"], AOTH.test[i]["maxlevel"], -- X , Y, LEVEL
                    AOTH.test[i]["class"], -- Rarity
                    TYPE_BEAST, -- type
                    AOTH.test[i]["abilities"],
                    AOTH.test[i]["info"], -- Abilities
                    {0, 0, 0}, AOTH.test[i]["id"], -- sawn timer
                    AOTH.test[i]["familySkills"],
                    idCount,
                    AOTH.test[i]["name"]);
            end
        else
            idCount = AOTH:Increment(idCount, minimal)
            local xx = AOTH.test[i]["coords"][1][1]
            local yy = AOTH.test[i]["coords"][1][2]
            AspectOfTheHunter:SetZoneNPCData(AOTH.test[i]["zoneID"],
                AOTH.test[i]["name"],
                AOTH.test[i]["family"][2],
                xx, yy, AOTH.test[i]["minlevel"], AOTH.test[i]["maxlevel"],
                AOTH.test[i]["class"],
                TYPE_BEAST,
                AOTH.test[i]["abilities"],
                AOTH.test[i]["info"],
                {0, 0, 0}, AOTH.test[i]["id"],
                AOTH.test[i]["familySkills"],
                idCount,
                AOTH.test[i]["name"]);
        end
    end
end



function AspectOfTheHunter:OnUpdate(sinceLastUpdate)
    --self:UpdateWorldMapPins()
    self:CheckZone()
    self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
    if (self.sinceLastUpdate >= DELAY) then
        self.sinceLastUpdate = 0;
        if not (IsResting()) then
            self:Nearby();
        
        end
    
    end

end




function AspectOfTheHunter:OnEvent(event)
    pinCount = 0
    
    if (event == "ZONE_CHANGED") then
        
        self:CheckZone();

    end



end



function AspectOfTheHunter:SetZoneNPCData(zone, name, family, x, y, minlvl, maxlvl, cl, typ, ability, info, spawn, ID, spells, idCount, textureID)
    
    
    
    -- Ensure sure the zone data exists
    local zoneData = AspectOfTheHunter:GetZoneData(zone);
    if (zoneData == nil) then
        zoneData = {};
        DATA[zone] = zoneData;
    end
    
    -- Define the data keys for this NPC
    local npcData = {};
    npcData[KEY_ZONE_NAME] = zone;
    npcData[KEY_NPC_NAME] = name;
    npcData[KEY_FAMILY] = family;
    npcData[KEY_POSITION_X] = x;
    npcData[KEY_POSITION_Y] = y;
    npcData[KEY_MINLEVEL] = minlvl;
    npcData[KEY_MAXLEVEL] = maxlvl;
    npcData[KEY_CLASS] = cl;
    npcData[KEY_TYPE] = typ;
    npcData[KEY_ABILITY] = ability;
    npcData[KEY_INFO] = info;
    npcData[KEY_SPAWN] = spawn;
    npcData[KEY_PET_ID] = ID;
    npcData[KEY_SPELLS] = spells;
    npcData[KEY_PIN_ID] = idCount;
    npcData[KEY_TEXTURE] = textureID;
    npcData[KEY_LOADED] = false;
    
    
    -- Store the data foor this NPC in the corresponding zone data
    zoneData[name] = npcData;

end



function AspectOfTheHunter:GetZoneData(zone)
    return DATA[zone];
end


function AspectOfTheHunter:CreateMapPin(container, data)
    
    
    local pinFrame = CreateFrame("Button", "AOTHMapPin", container);
    
    
    pinFrame:EnableMouse(true);
    --pinFrame:SetFrameStrata("MEDIUM")
    if (data[KEY_PIN_ID] == 1) then
        pinFrame:SetFrameLevel(2800);
    else
        pinFrame:SetFrameLevel(2400);
    end
    if (data[KEY_PIN_ID] == 1) then
        pinFrame:SetScript("OnClick", function(pin)AspectOfTheHunter:ShowFurtherPetInfo(pin) end);
        pinFrame:SetScript("OnEnter", function(pin)AspectOfTheHunter:ShowPinTooltip(pin) end);
        pinFrame:SetScript("OnLeave", function(pin)AspectOfTheHunter:HidePinTooltip(pin) end);
    else
        pinFrame:SetScript("OnEnter", function(pin)AspectOfTheHunter:ShowPinTooltip(pin) end);
        pinFrame:SetScript("OnLeave", function(pin)AspectOfTheHunter:HidePinTooltip(pin) end);
    end
    
    
    local pinIcon = "";
    local highLightPin = "";
    if (data[KEY_CLASS] == CLASS_RARE) then
        
        pinIcon = "PetIcons\\32x32\\" .. data[KEY_FAMILY] .. ".blp";
        
        highLightPin = "PetIcons\\32x32\\HighLight.blp"
    elseif (data[KEY_CLASS] == CLASS_RARE_ELITE) then
        pinIcon = "PetIcons\\32x32\\" .. data[KEY_FAMILY] .. ".blp";
        
        highLightPin = "PetIcons\\32x32\\HighLight.blp"
    elseif (data[KEY_CLASS] == CLASS_ELITE) then
        pinIcon = "PetIcons\\32x32\\" .. data[KEY_FAMILY] .. ".blp";
        
        highLightPin = "PetIcons\\32x32\\HighLight.blp"
    
    elseif (data[KEY_CLASS] == CLASS_STABLE_MASTER) then
        
        pinIcon = data[KEY_FAMILY] .. ".blp";
        highLightPin = data[KEY_FAMILY] .. ".blp";
    
    end
    
    local pinTexture = pinFrame:CreateTexture(nil, "BACKGROUND");
    pinFrame.__data = data;
    pinFrame.texture = pinTexture;
    pinTexture:SetAllPoints(pinFrame);
    pinTexture:SetTexture(ICON_PATH .. pinIcon);
    
    pinFrame:SetHighlightTexture(ICON_PATH .. highLightPin, "ADD");
    
    
    
    pinFrame:Hide();
    
    return pinFrame;

end



function AspectOfTheHunter:MiniMapPins(ref, icon, uiMapID, x, y, showInParentZone, floatOnEdge)
    
    
    petPins:AddMinimapIconMap(ref, icon, uiMapID, x, y, showInParentZone, floatOnEdge)



end


function AspectOfTheHunter:ShowFurtherPetInfo(pin)
    if (pin == nil) then return; end
    
    local npcData = pin.__data;
    local npcColor = AOTH.colors[npcData[KEY_CLASS]];
    
    if (npcData["class"] == CLASS_STABLE_MASTER) then return end
    
    if (npcData == nil) then return end
    
    GameTooltip:SetOwner(pin, "ANCHOR_BOTTOMRIGHT");
    GameTooltip:SetText("FURTHER INFORMATION", npcColor[1], npcColor[2], npcColor[3]);
    
    GameTooltip:AddLine(" ");
    
    local petinfo = AOTH.families
    local GROWL = 2649;
    local DASH = 61684;
    
    for i = 1, #petinfo do
        if (petinfo[i][1] == npcData[KEY_FAMILY]) then
            if (petinfo[i][3] == true) then
                GameTooltip:AddLine(L["EXOTIC"]);
                GameTooltip:AddTexture("Interface\\MINIMAP\\Minimap_shield_elite.blp");
                GameTooltip:AddLine(" ");
            end
            
            GameTooltip:AddLine(L["SPECIALTY"] .. string.upper(petinfo[i][2]));
            for k, v in pairs(AOTH.specSkills) do
                if (petinfo[i][2] == k) then
                    local spName, sp, spIcon = C_Spell.GetSpellInfo(v[1])
                    GameTooltip:AddLine(spName, 1.0, 1.0, 1.0);
                    GameTooltip:AddTexture(spIcon);
                    local spName2, sp, spIcon2 = C_Spell.GetSpellInfo(v[2])
                    GameTooltip:AddLine(spName2, 1.0, 1.0, 1.0);
                    GameTooltip:AddTexture(spIcon2);
                end
            end
            GameTooltip:AddLine(" ");
            GameTooltip:AddLine(L["COMMON_ABILITIES"]);
            local spName, sp, spIcon = C_Spell.GetSpellInfo(GROWL)
            GameTooltip:AddLine(spName, 1, 1, 1);
            GameTooltip:AddTexture(spIcon);
            
            local spName2, sp2, spIcon2 = C_Spell.GetSpellInfo(DASH)
            GameTooltip:AddLine(spName2, 1, 1, 1);
            GameTooltip:AddTexture(spIcon2);
            GameTooltip:AddLine(" ");
            
            GameTooltip:AddLine(npcData[KEY_INFO], 1, 1, 1, 1)
        
        
        end
    end
    
    
    
    
    GameTooltip:AddLine(" ");
    
    
    
    petModel:ClearModel()
    petModel:Hide()
    petModel:RefreshUnit()
    GameTooltip:Show();

end

petModel = CreateFrame("PlayerModel", "petView", GameTooltip)




-- Pet Tool TIP
function AspectOfTheHunter:ShowPinTooltip(pin)
    
    if (pin == nil) then return; end
    
    local npcData = pin.__data;
    
    if (npcData == nil) then return; end
    
    local npcName = npcData[KEY_NPC_NAME];
    local npcFamily = npcData[KEY_FAMILY]
    local npcX = npcData[KEY_POSITION_X];
    local npcY = npcData[KEY_POSITION_Y];
    local npcMINLevel = npcData[KEY_MINLEVEL];
    local npcMAXLevel = npcData[KEY_MAXLEVEL];
    local npcClass = npcData[KEY_CLASS];
    local npcType = npcData[KEY_TYPE];
    local npcAbilities = npcData[KEY_ABILITY];
    local npcArmor = npcData[KEY_ARMOR];
    local npcSpawn = npcData[KEY_SPAWN];
    local npcModel = npcData[KEY_MODEL];
    local npcSpells = npcData[KEY_SPELLS];
    local npcColor = AOTH.colors[npcClass];
    local npcID = npcData[KEY_PET_ID];
    
    
    GameTooltip:SetOwner(pin, "ANCHOR_BOTTOMRIGHT");
    
    if (npcData[KEY_PIN_ID] == 1) then
        if (npcClass == CLASS_STABLE_MASTER) then npcType = "NPC" end
        if (#npcName > 15 and #npcName <= 20) then
            GameTooltip:SetText(npcName .. " (" .. npcFamily .. ") " .. TOOLTIP_PADDING, npcColor[1], npcColor[2], npcColor[3]);
        elseif (#npcName <= 15) then
            GameTooltip:SetText(npcName .. " (" .. npcFamily .. ") " .. TOOLTIP_PADDING, npcColor[1], npcColor[2], npcColor[3]);
        else
            GameTooltip:SetText(npcName .. " (" .. npcFamily .. ") ", npcColor[1], npcColor[2], npcColor[3]);
        end
        if (strmatch(npcMINLevel, "%d") or strmatch(npcMAXLevel, "%d")) then
            if (npcMINLevel == npcMAXLevel) then
                GameTooltip:AddLine("Level " .. npcMAXLevel / 2 .. " ", 1, 1, 1);
            else
                GameTooltip:AddLine(string.format("|c0070ddff%-6s|r%s |c00ffffff%d|r\n|c0070ddff%-5s|r%s |c00ffffff%d|r\n|c00ff0000%s", "MIN", L["LEVEL"], npcMINLevel / 2, "MAX", L["LEVEL"], npcMAXLevel / 2, npcType));
            end
        else
            GameTooltip:AddLine(string.format("|c0070ddff%-6s|r%s |c00ffffff%s|r\n|c0070ddff%-5s|r%s |c00ffffff%s|r\n|c00ff0000%s", "MIN", L["LEVEL"], npcMINLevel, "MAX", L["LEVEL"], npcMAXLevel, npcType));
        
        end
        GameTooltip:AddLine(npcClass, 0.7, 0.7, 0.7);
        
        
        petModel:SetSize(GameTooltip:GetWidth() / 2, GameTooltip:GetHeight() * 3)
        --petModel:SetSize(150,150)
        local scale = (petModel:GetWidth() + petModel:GetHeight()) / 100;
        for k, v in pairs(AOTH.test) do
            if (npcID == AOTH.test[k]["id"]) then
                petModel:SetDisplayInfo(AOTH.test[k]["displayID"])
            end
        end
        
        petModel:SetFrameStrata("TOOLTIP")
        --petModel:SetCreature(npcID)
        --petModel:SetCreature(npcID)
        petModel:SetPoint("TOPRIGHT", -4, -40)
        petModel:SetFacing(20 * math.pi / 180);
        --petModel:TransformCameraSpaceToModelSpace(10, 0, 50)
        --petModel:SetCamDistanceScale(1.5)
        petModel:Show()
        
        
        
        if (#npcSpells > 0) then
            GameTooltip:AddLine(" ");
            GameTooltip:AddLine("Skills:");
            for i, spellID in pairs(npcSpells) do
                local spellName, spellRank, spellIcon = C_Spell.GetSpellInfo(spellID);
                if (spellName ~= nil) then
                    GameTooltip:AddLine(spellName, 1, 1, 1);
                    GameTooltip:AddTexture(spellIcon);
                end
            end
        end
        
        
        local spawnTime = "";
        if (type(npcSpawn) == "table" and #npcSpawn > 0) then
            local spawnDays = npcSpawn[1];
            local spawnHours = npcSpawn[2];
            local spawnMinutes = npcSpawn[3];
            
            if (spawnDays > 0) then spawnTime = spawnTime .. spawnDays .. " Days "; end;
            if (spawnHours > 0) then spawnTime = spawnTime .. spawnHours .. " Hours "; end;
            if (spawnMinutes > 0) then spawnTime = spawnTime .. spawnMinutes .. " Minutes "; end;
        else
            spawnTime = "Under Development";
        end
        
        if (spawnTime:len() > 0) then
            GameTooltip:AddLine(" ");
            GameTooltip:AddLine("Spawn Rate:");
            GameTooltip:AddLine(spawnTime, 1, 1, 1);
        end
        local clickMsg = "(Click For More Info!)"
        if (npcClass == CLASS_STABLE_MASTER) then
            clickMsg = ""
            GameTooltip:AddLine(" ");
            
            for i = 1, #AOTH.test do
                if (tostring(npcName) == AOTH.test[i]["name"] and AOTH.test[i]["react"][1] == 1 and AOTH.test[i]["react"][2] == 1) then
                    GameTooltip:AddLine(L["BOTH_FACTIONS"]);
                elseif (tostring(npcName) == AOTH.test[i]["name"] and AOTH.test[i]["react"][1] == 1) then
                    GameTooltip:AddLine(L["ALLIANCE_FRIEND"]);
                
                elseif (tostring(npcName) == AOTH.test[i]["name"] and AOTH.test[i]["react"][2] == 1) then
                    GameTooltip:AddLine(L["HORDE_FRIEND"]);
                
                
                end
            end
        
        end
        
        GameTooltip:AddLine(" ");
        GameTooltip:AddLine("Coords:");
        GameTooltip:AddLine("X: " .. npcX .. " , " .. "Y: " .. npcY);
        if (clickMsg == "") then
            GameTooltip:AddLine(" ");
        else
            GameTooltip:AddLine(clickMsg, 0.7, 0.7, 0.7);
        end
    else
        GameTooltip:SetText(npcData[KEY_NPC_NAME])
    end
    GameTooltip:Show();

end



function AspectOfTheHunter:HidePinTooltip(pin)
    TOOLTIP_LOOT_INDEX = 1;
    GameTooltip:Hide();
    if (pin.__data[KEY_PIN_ID] == 1) then
        petModel:ClearModel()
        petModel:Hide()
    end

end



function AspectOfTheHunter:CheckZone()
    
    self:CheckWorldMap();
    self:CheckPlayerMap();

end



function AspectOfTheHunter:CheckPlayerMap()
    
    local mapID = GetMapID();
    --[[     if (mapID ~= PLAYER_MAP_ID) then
    self:UpdateMacros();
    end ]]
    PLAYER_MAP_ID = mapID;

end


function AspectOfTheHunter:UpdateMacros()
    
    --print("Updating Macros");
    local macroName = "AOTH";
    local macroContent = "";
    local mapID = GetMapID();
    local zoneData = AspectOfTheHunter:GetZoneData(mapID);
    if (mapID ~= null) then
        for i = 1, #AOTH.test do
            if (AOTH.test[i]["zoneID"] == mapID) then
                local npcName = AOTH.test[i]["name"];
                macroContent = macroContent .. "/tar " .. npcName .. ";\n";
            end
        end
    end
    
    local macro = GetMacroInfo(macroName);
    if (macro == nil) then
        CreateMacro(macroName, 236203, macroContent, nil);
    else
        EditMacro(macroName, macroName, 236203, macroContent);
    end

end

function AspectOfTheHunter:CheckWorldMap()
    
    if (WorldMapAvailable()) then
        local worldMapID = GetWorldMapID();
        if (worldMapID ~= WORLD_MAP_ID) then
            AspectOfTheHunter:DrawWorldMapPins();
            AspectOfTheHunter:LoadStableMasters()
        
        end
    self:UpdateWorldMapPins();
    end

end

function RareCheck(id, npc_id, npcType)
    
    local class = UnitClassification(id)
    local isTameable, isPlayerpet
    
    if (npcType == "Pet") then isPlayerpet = false else isPlayerpet = true end
    
    if (class == "rare" or class == "rareelite") then
        
        for dID = 1, #AOTH.tamablePets do
            
            if (tonumber(npc_id) == AOTH.tamablePets[dID]) then
                
                isTameable = true
            end
        
        end
        
        return true, isTameable, isPlayerpet
    end

end

local ef = CreateFrame("Frame")
ef:RegisterEvent("PLAYER_REGEN_DISABLED")
ef:RegisterEvent("PLAYER_REGEN_ENABLED")

function AspectOfTheHunter:Nearby()
    
    if UnitOnTaxi("player") then return end
    
    local mapID = GetMapID();
    
    if (InCombatLockdown() or not mapID) then return end
    
    for i = 1, 10 do
        local npcID = UnitGUID("nameplate" .. i);
        
        
        if npcID then
            
            local npcType, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = ("-"):split(npcID);
            
            local isRare, isTameable, isPlayerpet = RareCheck("nameplate" .. i, npc_id, npcType)
            
            if not (select(1, IsInInstance())) then
                if (isRare and isTameable and isPlayerpet and select(3, UnitClass("player")) == 3 and AOTH.db.general.TargetSystem) then
                    
                    ef:SetScript("OnEvent", function(self, event)
                        if (event == "PLAYER_REGEN_DISABLED") then
                            _G["TB_" .. npc_id]:Hide()
                            SetRaidTarget("Target", 9)
                            SetRaidTarget("Target", 9)
                        end
                    
                    end)
                    
                    if not GetRaidTargetIndex("nameplate" .. i) then
                        
                        
                        SetRaidTarget("nameplate" .. i, 8)
                        
                        local family = UnitCreatureFamily("nameplate" .. i)
                        local name = UnitName("nameplate" .. i)
                        local RARE_FRAME_FOUND = false
                        
                        
                        for RARE = 1, #RARE_COLLECTION do
                            
                            local id = string.sub(RARE_COLLECTION[RARE]:GetName(), 4)
                            
                            if (tonumber(id) == tonumber(npc_id)) then
                                
                                RARE_COLLECTION[RARE]:SetAttribute("type1", "macro")
                                RARE_COLLECTION[RARE]:SetAttribute("macrotext", "/cleartarget\n/target " .. name)
                                PlaySoundFile("Interface\\AddOns\\AspectOfTheHunter\\Sounds\\Event_wardrum_ogre-1.ogg", "Master")
                                RARE_COLLECTION[RARE]:Show()
                                RARE_FRAME_FOUND = true
                                break;
                            end
                        
                        
                        end
                        
                        if not (RARE_FRAME_FOUND) then
                            
                            table.insert(RARE_COLLECTION, 1, AOTH:CreateTargetButton(tonumber(npc_id), family, name, "nameplate" .. i))
                            RARE_COLLECTION[1]:SetAttribute("type1", "macro")
                            RARE_COLLECTION[1]:SetAttribute("macrotext1", "/cleartarget\n/target " .. name)
                            RARE_COLLECTION[1]:HookScript("OnClick", function(self, button)
                                
                                if (button == "RightButton") then
                                    
                                    RARE_COLLECTION[1]:Hide()
                                    RARE_COLLECTION[1]:SetAttribute("macrotext", "/cleartarget")
                                
                                end
                            end)
                            RARE_COLLECTION[1]:Show()
                            RARE_FRAME_FOUND = false
                        end
                        
                        print("|cFF00FF00[" .. L["ADDON_NAME"] .. "]: |cFFFFFFFF" .. string.upper(UnitClassification("nameplate" .. i)) .. " " .. L["PET"] .. " |c0069CCF0[" .. string.upper(name) .. "]|r " .. L["FOUND"]);
                    end
                end
            end
        end
    end

end




-- World Map --
function AspectOfTheHunter:DrawWorldMapPins()
    
    AspectOfTheHunter:HideWorldMapPins();
    
    AspectOfTheHunter:ShowWorldMapPins();



end







function AspectOfTheHunter:LoadStableMasters()
    
    WORLD_MAP_ID = GetWorldMapID();
    local zoneData = AspectOfTheHunter:GetZoneData(WORLD_MAP_ID);
    
    if (zoneData == nil) then return; end
    
    if not (AOTH.db.general.hideStablesOnMap) then
        
        for npcName, npcData in pairs(zoneData) do
            npcPin = npcData[KEY_WORLD_MAP_PIN]

            self:ShowWorldMapNPC(npcData, "Stable Master");
            
            table.insert(WORLD_MAP_PINS, npcPin)
        end
        
    end
    
    
    self:UpdateWorldMapPins();

end

function AspectOfTheHunter:UpdateWorldMapPins()
    
    local scale = WORLD_MAP_CONTAINER:GetEffectiveScale()
    local width = WORLD_MAP_CONTAINER:GetWidth()
    local height = WORLD_MAP_CONTAINER:GetHeight()
    
    local pinSize = WORLD_MAP_PIN_SIZE / scale;
    
    for i, npcPin in pairs(WORLD_MAP_PINS) do
        
        local npcData = npcPin.__data;
        local npcPin = npcData[KEY_WORLD_MAP_PIN];
        local pointX = npcData[KEY_POSITION_X];
        local pointY = npcData[KEY_POSITION_Y];
        
        local pinX = ((pointX / 100) * width) - (width / 2);
        local pinY = (((pointY / 100) * height) - (height / 2)) * -1;
        npcPin:SetPoint("CENTER", pinX, pinY)
        if (npcPin.__data[KEY_CLASS] == CLASS_STABLE_MASTER and AOTH.db.general.ResizeStableIcon) then
            npcPin:SetWidth(16 / scale);
            npcPin:SetHeight(16 / scale);
        elseif (npcPin.__data[KEY_CLASS] == CLASS_STABLE_MASTER and AOTH.db.general.hideStablesOnMap) then  
            npcPin:Hide();
        else
            if (npcPin.__data[KEY_PIN_ID] == 1) then
                npcPin:SetWidth(pinSize);
                npcPin:SetHeight(pinSize);
            else
                npcPin:SetWidth(pinSize / 2);
                npcPin:SetHeight(pinSize / 2);
            end
        end
    
    end

end


-- Utility
function AspectOfTheHunter:LoadNPCData(data)
    
    local npcLoaded = data[KEY_LOADED];
    
    if (npcLoaded == true) then return; end
    
    local npcSpells = data[KEY_SPELLS];
    
    ---- Pre-load the spells to prevent bugs on tooltips
    --if (#npcSpells > 0) then
    --    for s, spellID in pairs(npcSpells) do
    --        local spellName, spellRank, spellIcon = GetSpellInfo(spellID);
    --    end
    --end
    data[KEY_LOADED] = true;
    data[KEY_WORLD_MAP_PIN] = AspectOfTheHunter:CreateMapPin(WORLD_MAP_CONTAINER, data);


end


--[[ SHOW FUNCTIONS ]]
function AspectOfTheHunter:ShowWorldMapNPC(data, familyToSHow)
    self:LoadNPCData(data);
    npcPin = data[KEY_WORLD_MAP_PIN];
    
    
    
    local zoneID = tonumber(familyToSHow);
    if (data[KEY_ZONE_NAME] == zoneID) then
        

        npcPin:Show();
        
    elseif (data["petName"] == familyToSHow) then
        npcPin:Show();
    end





end

function AspectOfTheHunter:ShowWorldMapPins()
    
    
    WORLD_MAP_ID = GetWorldMapID();
    local zoneData = AspectOfTheHunter:GetZoneData(WORLD_MAP_ID);
    
    if (zoneData == nil) then return end
    
    for i = PIN_POSITION, #PETS_TO_LOAD do
        
        for npcName, npcData in pairs(zoneData) do
            
            npcPin = npcData[KEY_WORLD_MAP_PIN]
            
            self:ShowWorldMapNPC(npcData, PETS_TO_LOAD[i]);
            
            table.insert(WORLD_MAP_PINS, npcPin)
        
        end
    
    end
    
    self:UpdateWorldMapPins();


end

function AspectOfTheHunter:ShowToolTip(pin, petName)
    local tooltip = GameTooltip
    
    tooltip:SetOwner(pin, "ANCHOR_TOP")
    tooltip:SetText(petName)
    tooltip:Show()

end

function AspectOfTheHunter:SetFamilyToFind(petFamily, flag)
    local count = 0;
    
    --print("|c0000ff00---===<<<[ " .. strupper(petFamily) .. "'S FOUND ]>>>===---")
    if (flag > 0) then
        
        for i = 1, #AOTH.test do
            if (AOTH.test[i]["family"][2] == petFamily) then
                count = count + 1
                
                print("|c0000ff00" .. count .. ":|r " .. AOTH.test[i]["zone_name"] .. " |c0000bbff[" .. AOTH.test[i]["name"] .. "]")
            
            end
        end
    end
    
    
    if (tonumber(petFamily)) then
        
        
        for i = 1, #AOTH.test do
            
            if (AOTH.test[i]["zoneID"] == petFamily) then
                
                for v=1, #AOTH.families do
            
                    if (AOTH.families[v][1] == AOTH.test[i]["family"][2] ) then
        
                        checkFamily[v] = true;
        
                    end
        
                end

                table.insert(MINI_PETS_TO_LOAD, AOTH.test[i]["family"][2])
            end
        
        end
        table.insert(PETS_TO_LOAD, petFamily)
    else
        table.insert(PETS_TO_LOAD, petFamily)
        table.insert(MINI_PETS_TO_LOAD, petFamily)
    end

    if(flag == 2) then
        table.wipe(checkFamily);
    end
    
    AspectOfTheHunter:UpdateMinimapPlugin()
end


--------- END SHOW FUNCTIONS -------------
function AspectOfTheHunter:ResetMenu()
    
    table.wipe(PETS_TO_LOAD);
    table.wipe(WORLD_MAP_PINS);
    table.wipe(MINI_PETS_TO_LOAD);

end




--[[ VV  HIDE FUNCTIONS    VV  ]]
function AspectOfTheHunter:HideWorldMapNPC(data)
    npcPin = data[KEY_WORLD_MAP_PIN];
    
    
    npcPin:Hide();

end

function AspectOfTheHunter:SetFamilyToHide(petFamily)
    
    
    for i = 1, #PETS_TO_LOAD do
        if (PETS_TO_LOAD[i] == petFamily) then
            table.remove(PETS_TO_LOAD, i);
        end
    
    end
    
    for i = 1, #MINI_PETS_TO_LOAD do
        if (MINI_PETS_TO_LOAD[i] == petFamily) then
            table.remove(MINI_PETS_TO_LOAD, i);
        end
    
    end
    
    AspectOfTheHunter:UpdateMinimapPlugin()
end


function AspectOfTheHunter:HidePets(petToHide)
    
    
    
    for i, npcPin in pairs(WORLD_MAP_PINS) do
        local npcData = npcPin.__data;
        
        if (petToHide == npcData["petName"] and npcData[KEY_CLASS] ~= CLASS_STABLE_MASTER) then
            self:HideWorldMapNPC(npcData);
        elseif (petToHide == npcData["zonename"] and npcData[KEY_CLASS] ~= CLASS_STABLE_MASTER) then
            self:HideWorldMapNPC(npcData);
        end
    
    end

end

function AspectOfTheHunter:HideMinimapPins()
    petPins:RemoveAllMinimapIcons("AspectOfTheHunter")
    AspectOfTheHunter:ClearAllPins()
    pinCount = 0
end

function AspectOfTheHunter:HideWorldMapPins()
    
    
    for i, npcPin in pairs(WORLD_MAP_PINS) do
        local npcData = npcPin.__data;
        
        
        self:HideWorldMapNPC(npcData);
    
    end

end

--[[ ^^   END OF HIDE FUNCTIONS    ^^  ]]
--[[

MINIMAP FUNCTIONS

]]
local pinCache = {}
local minimapPins = {}
pinCount = 0

local function getNewPin()
    pinCount = pinCount + 1
    -- create a new pin
    pinFrame = CreateFrame("Button", "AothPin" .. pinCount, Minimap)
    
    
    pinFrame:EnableMouse(true)
    pinFrame:SetWidth(12)
    pinFrame:SetHeight(12)
    pinFrame:SetPoint("CENTER", Minimap, "CENTER")
    local texture = pinFrame:CreateTexture(nil, "OVERLAY")
    pinFrame.texture = texture
    texture:SetAllPoints(pinFrame)
    texture:SetTexelSnappingBias(0)
    texture:SetSnapToPixelGrid(false)
    pinFrame:RegisterForClicks("AnyUp", "AnyDown")
    pinFrame:SetMovable(true)
    
    
    pinFrame:Hide()
    
    return pinFrame

end



function AspectOfTheHunter:UpdateMinimapPlugin()
    AspectOfTheHunter:HideMinimapPins()
    if not Minimap:IsVisible() then return end
    local uiMapID = HBD:GetPlayerZone()
    if not uiMapID then return end
    
    local ourScale, ourAlpha = 12 * 1.0, 1.0
    local frameLevel = Minimap:GetFrameLevel() + 5
    local frameStrata = Minimap:GetFrameStrata()
    if not (AOTH.db.general.ToggleMiniMapIcon) then
        
        
        for p = 1, #MINI_PETS_TO_LOAD do
            
            for i = 1, #AOTH.test do
                
                if (uiMapID == AOTH.test[i]["zoneID"] and AOTH.test[i]["family"][2] == MINI_PETS_TO_LOAD[p]) then
                    
                    for k = 1, #AOTH.test[i]["coords"] do
                        local petX = AOTH.test[i]["coords"][k][1]
                        local petY = AOTH.test[i]["coords"][k][2]
                        icon = getNewPin()
                        icon:SetParent(Minimap)
                        icon:SetFrameStrata(frameStrata)
                        icon:SetFrameLevel(frameLevel)
                        scale = ourScale * 1.5
                        icon:SetHeight(scale)
                        icon:SetWidth(scale)
                        icon:SetAlpha(ourAlpha * 1.0)
                        local t = icon.texture
                        
                        t:SetTexCoord(0, 1, 0, 1)
                        t:SetVertexColor(1, 1, 1, 1)
                        if (AOTH.test[i][KEY_CLASS] == CLASS_STABLE_MASTER) then
                            t:SetTexture(nil)
                        else
                            t:SetTexture(ICON_PATH .. "PetIcons\\32x32\\" .. AOTH.test[i]["family"][2] .. ".blp")
                        end
                        
                        icon:SetScript("OnEnter", function(pin)AspectOfTheHunter:ShowToolTip(pin, AOTH.test[i]["name"]) end)
                        icon:SetScript("OnLeave", function()
                            
                            
                            end)
                        
                        x, y = petX / 100, petY / 100
                        
                        t:ClearAllPoints()
                        t:SetAllPoints(icon)
                        
                        
                        table.insert(minimapPins, icon)
                        
                        
                        petPins:AddMinimapIconMap("AspectOfTheHunter", icon, uiMapID, x, y, true)
                        
                        
                        
                        icon.mapFile = nil
                        
                        icon.uiMapID = uiMapID
                    end
                end
            end
        end
    end
end


function AspectOfTheHunter:ClearAllPins()
    for key, frame in pairs(minimapPins) do
        frame.texture:Hide()
        frame:SetParent(nil)
        frame.texture:ClearAllPoints()
        frame:SetScript("OnUpdate", nil)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:UnregisterAllEvents()
        
        minimapPins[frame] = nil
        frame.factionType = nil
        frame.MinLevel = nil
        frame.ItemLocation = nil
        frame.TimeSinceUpdate = nil
        frame.IsMinimapIcon = nil
        frame.Name = nil
    end
    
    minimapPins = {}

end



-- HELPER FUNCTIONS
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


function GetMapID()
    return C_Map.GetBestMapForUnit("player");
end


function GetPlayerPosition(mapID)
    return C_Map.GetPlayerMapPosition(mapID, "player");
end

```