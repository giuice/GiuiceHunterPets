package.path = "./?.lua;" .. package.path

local worldMapAdds = {}
local minimapAdds = {}
local worldMapClears = {}
local minimapClears = {}

local GHP = {
    stable_masters = {
        {
            name = "Alliance Handler",
            zone_name = "Durotar",
            zoneID = 1,
            coords = { { 50, 40 } },
            faction = "Alliance",
        },
        {
            name = "Horde Handler",
            zone_name = "Durotar",
            zoneID = 1,
            coords = { { 52, 41.8 } },
            faction = "Horde",
        },
        {
            name = "Neutral Handler",
            zone_name = "Durotar",
            zoneID = 1,
            coords = { { 53.4, 40.8 } },
            faction = "Neutral",
        },
    },
}

_G.GHP = GHP
_G.GHP_SavedVars = {
    worldMapPins = 2,
    minimapPins = false,
    stableMasterPins = true,
}

function GHP.EnsureStableMasterIndex()
    return {
        [1] = GHP.stable_masters,
    }
end

function GHP.GetStableMastersForMap(index, mapID)
    return index[mapID] or {}
end

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
    end
end

local function assertTableLength(value, expected, label)
    if type(value) ~= "table" then
        error(label .. ": expected table", 2)
    end
    if #value ~= expected then
        error(string.format("%s: expected length %d, got %d", label, expected, #value), 2)
    end
end

local stablePins = {
    RemoveAllWorldMapIcons = function(_, key)
        table.insert(worldMapClears, key)
    end,
    RemoveAllMinimapIcons = function(_, key)
        table.insert(minimapClears, key)
    end,
    AddWorldMapIconMap = function(_, key, pin, mapID, x, y)
        table.insert(worldMapAdds, { key = key, pin = pin, mapID = mapID, x = x, y = y })
    end,
    AddMinimapIconMap = function(_, key, pin, mapID, x, y)
        table.insert(minimapAdds, { key = key, pin = pin, mapID = mapID, x = x, y = y })
    end,
}

_G.LibStub = function(name)
    if name == "HereBeDragons-2.0" then
        return {
            GetPlayerZone = function()
                return 1
            end,
        }
    end

    if name == "HereBeDragons-Pins-2.0" then
        return stablePins
    end

    error("unexpected LibStub library: " .. tostring(name))
end

_G.UnitClass = function()
    return "Hunter", "HUNTER", 3
end

_G.UnitFactionGroup = function()
    return "Horde"
end

local framePrototype = {}

function framePrototype:SetSize(width, height)
    self.width = width
    self.height = height
end

function framePrototype:SetFrameStrata(frameStrata)
    self.frameStrata = frameStrata
end

function framePrototype:SetFrameLevel(frameLevel)
    self.frameLevel = frameLevel
end

function framePrototype:CreateTexture()
    return {
        SetAllPoints = function() end,
        SetTexture = function(_, texture)
            self.texture = texture
        end,
    }
end

function framePrototype:SetScript(scriptName, handler)
    self.scripts[scriptName] = handler
end

function framePrototype:RegisterEvent(event)
    self.events[event] = true
end

local function newFrame()
    return setmetatable({ scripts = {}, events = {} }, { __index = framePrototype })
end

_G.CreateFrame = function()
    return newFrame()
end

_G.WorldMapFrame = newFrame()
function WorldMapFrame:GetCanvas()
    return self
end
function WorldMapFrame:HookScript(scriptName, handler)
    self.scripts[scriptName] = handler
end

_G.Minimap = newFrame()
function Minimap:IsVisible()
    return true
end
function Minimap:GetFrameLevel()
    return 10
end
function Minimap:GetFrameStrata()
    return "MEDIUM"
end
function Minimap:HookScript(scriptName, handler)
    self.scripts[scriptName] = handler
end

local tooltipText
local tooltipLines = {}

_G.GameTooltip = {
    SetOwner = function() end,
    SetText = function(_, text)
        tooltipText = text
    end,
    AddLine = function(_, text)
        table.insert(tooltipLines, text)
    end,
    Show = function() end,
    Hide = function() end,
}

_G.C_Map = {
    GetBestMapForUnit = function()
        return 1
    end,
}

_G.C_Timer = {
    After = function(_, callback)
        callback()
    end,
}

_G.HBD_PINS_WORLDMAP_SHOW_WORLD = true
_G.unpack = table.unpack

dofile("StableMasterPins.lua")

GHP.OnStableMasterPinsSettingChanged(nil, false)

assertEqual(GHP_SavedVars.stableMasterPins, false, "stableMasterPins disabled")
assertEqual(GHP_SavedVars.worldMapPins, 2, "pet world map setting untouched")
assertEqual(GHP_SavedVars.minimapPins, false, "pet minimap setting untouched")
assertEqual(worldMapClears[#worldMapClears], "GiuiceHunterPetsStableMasterIcons", "stable world map key cleared")
assertEqual(minimapClears[#minimapClears], "GiuiceHunterPetsStableMasterMinimapIcons", "stable minimap key cleared")

GHP.OnStableMasterPinsSettingChanged(nil, true)

assertEqual(GHP_SavedVars.stableMasterPins, true, "stableMasterPins enabled")
assertTableLength(worldMapAdds, 2, "worldMapAdds")
assertTableLength(minimapAdds, 2, "minimapAdds")
assertEqual(worldMapAdds[1].key, "GiuiceHunterPetsStableMasterIcons", "stable world map key added")
assertEqual(minimapAdds[1].key, "GiuiceHunterPetsStableMasterMinimapIcons", "stable minimap key added")
assertEqual(worldMapAdds[1].pin.texture, "Interface\\Icons\\INV_Misc_Horseshoe_01", "stable master icon")

worldMapAdds[1].pin.scripts.OnEnter(worldMapAdds[1].pin)

assertEqual(tooltipText, "Horde Handler", "tooltip stable master name")
assertEqual(tooltipLines[1], "Stable Master", "tooltip stable master label")
assertEqual(tooltipLines[2], "Durotar", "tooltip stable master zone")
assertEqual(tooltipLines[3], "Faction: Horde", "tooltip stable master faction")

print("PASS stable_master_pins_settings_test: stable master setting refresh, faction filtering, and tooltip content")
