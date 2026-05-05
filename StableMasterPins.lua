local addonName, addonTable = ...

local GHP = addonTable or _G.GHP or {}
_G.GHP = GHP

local HBD = LibStub("HereBeDragons-2.0")
local stableMasterPins = LibStub("HereBeDragons-Pins-2.0")

if select(3, UnitClass("player")) ~= 3 then
    return
end

local WORLD_MAP_PIN_KEY = "GiuiceHunterPetsStableMasterIcons"
local MINIMAP_PIN_KEY = "GiuiceHunterPetsStableMasterMinimapIcons"
local STABLE_MASTER_ICON = "Interface\\Icons\\INV_Misc_Horseshoe_01"

local lastWorldMapPinKey

local function IsStableMasterPinsEnabled()
    return GHP_SavedVars.stableMasterPins ~= false
end

local function EnsureStableMasterIndex()
    if GHP.EnsureStableMasterIndex then
        return GHP.EnsureStableMasterIndex()
    end
end

local function GetStableMastersForMap(mapID)
    local index = EnsureStableMasterIndex()

    if not GHP.GetStableMastersForMap then
        return {}
    end

    return GHP.GetStableMastersForMap(index, mapID)
end

local function IsStableMasterVisibleForPlayer(stableMasterData)
    local playerFaction = UnitFactionGroup("player")
    local stableMasterFaction = stableMasterData.faction

    if stableMasterFaction == "Neutral" then
        return true
    end

    return stableMasterFaction == playerFaction
end

local function ClearWorldMapPins()
    stableMasterPins:RemoveAllWorldMapIcons(WORLD_MAP_PIN_KEY)
    lastWorldMapPinKey = nil
end

local function ClearMinimapPins()
    stableMasterPins:RemoveAllMinimapIcons(MINIMAP_PIN_KEY)
end

local function SetStableMasterTooltip(pin, stableMasterData)
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    GameTooltip:SetText(stableMasterData.name or "Stable Master")
    GameTooltip:AddLine("Stable Master", 1, 1, 1)

    if stableMasterData.zone_name then
        GameTooltip:AddLine(stableMasterData.zone_name, 0.7, 0.7, 0.7)
    end

    if stableMasterData.faction then
        GameTooltip:AddLine("Faction: " .. stableMasterData.faction, 0.7, 0.7, 0.7)
    end

    GameTooltip:Show()
end

local function CreateStableMasterPin(parent, size, frameStrata, frameLevel, stableMasterData)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetSize(size, size)

    if frameStrata then
        pin:SetFrameStrata(frameStrata)
    end

    if frameLevel then
        pin:SetFrameLevel(frameLevel)
    end

    local texture = pin:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetTexture(STABLE_MASTER_ICON)

    pin:SetScript("OnEnter", function(self)
        SetStableMasterTooltip(self, stableMasterData)
    end)
    pin:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return pin
end

local function DisplayWorldMapStableMasters()
    if not IsStableMasterPinsEnabled() then
        ClearWorldMapPins()
        return
    end

    if not WorldMapFrame or not WorldMapFrame:GetCanvas() then
        return
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return
    end

    local pinKey = tostring(mapID) .. ":" .. tostring(GHP.stable_masters)
    if lastWorldMapPinKey == pinKey then
        return
    end

    ClearWorldMapPins()
    lastWorldMapPinKey = pinKey

    for _, stableMasterData in ipairs(GetStableMastersForMap(mapID)) do
        if IsStableMasterVisibleForPlayer(stableMasterData) then
            for _, coords in ipairs(stableMasterData.coords or {}) do
                local x, y = unpack(coords)
                local pin = CreateStableMasterPin(WorldMapFrame:GetCanvas(), 24, nil, 2801, stableMasterData)
                stableMasterPins:AddWorldMapIconMap(
                    WORLD_MAP_PIN_KEY,
                    pin,
                    mapID,
                    tonumber(x) / 100,
                    tonumber(y) / 100,
                    HBD_PINS_WORLDMAP_SHOW_WORLD
                )
            end
        end
    end
end

local function UpdateMinimapStableMasters()
    if not IsStableMasterPinsEnabled() then
        ClearMinimapPins()
        return
    end

    if not Minimap:IsVisible() then
        return
    end

    local mapID = HBD:GetPlayerZone()
    if not mapID then
        return
    end

    ClearMinimapPins()

    local frameLevel = Minimap:GetFrameLevel() + 6
    local frameStrata = Minimap:GetFrameStrata()

    for _, stableMasterData in ipairs(GetStableMastersForMap(mapID)) do
        if IsStableMasterVisibleForPlayer(stableMasterData) then
            for _, coords in ipairs(stableMasterData.coords or {}) do
                local x, y = unpack(coords)
                local pin = CreateStableMasterPin(Minimap, 16, frameStrata, frameLevel, stableMasterData)
                stableMasterPins:AddMinimapIconMap(MINIMAP_PIN_KEY, pin, mapID, tonumber(x) / 100, tonumber(y) / 100, true)
            end
        end
    end
end

local stableMasterEventFrame = CreateFrame("Frame")
stableMasterEventFrame:RegisterEvent("ADDON_LOADED")
stableMasterEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
stableMasterEventFrame:RegisterEvent("ZONE_CHANGED")
stableMasterEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
stableMasterEventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
stableMasterEventFrame:RegisterEvent("MINIMAP_UPDATE_ZOOM")

stableMasterEventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName ~= addonName then
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(4, function()
            DisplayWorldMapStableMasters()
            UpdateMinimapStableMasters()
        end)
        return
    end

    if event == "ZONE_CHANGED_NEW_AREA" then
        lastWorldMapPinKey = nil
    end

    DisplayWorldMapStableMasters()
    UpdateMinimapStableMasters()
end)

WorldMapFrame:HookScript("OnShow", DisplayWorldMapStableMasters)
WorldMapFrame:HookScript("OnHide", ClearWorldMapPins)

Minimap:HookScript("OnShow", UpdateMinimapStableMasters)
Minimap:HookScript("OnHide", ClearMinimapPins)

function GHP.OnStableMasterPinsSettingChanged(setting, value)
    GHP_SavedVars.stableMasterPins = value

    if value then
        DisplayWorldMapStableMasters()
        UpdateMinimapStableMasters()
    else
        ClearWorldMapPins()
        ClearMinimapPins()
    end
end
