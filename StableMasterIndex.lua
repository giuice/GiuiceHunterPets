local addonName, addonTable = ...

if UnitClass and select(3, UnitClass("player")) ~= 3 then
    return
end

local GHP = addonTable or _G.GHP or {}
_G.GHP = GHP

function GHP.BuildStableMasterIndex(stableMasters)
    local index = {}

    for _, stableMasterData in ipairs(stableMasters or {}) do
        if stableMasterData.zoneID then
            index[stableMasterData.zoneID] = index[stableMasterData.zoneID] or {}
            table.insert(index[stableMasterData.zoneID], stableMasterData)
        end
    end

    return index
end

function GHP.GetStableMastersForMap(index, mapID)
    if not mapID then
        return {}
    end

    return index and index[mapID] or {}
end

function GHP.EnsureStableMasterIndex()
    if not GHP.stable_masters then
        return
    end

    if GHP.stableMasterIndexSource ~= GHP.stable_masters then
        GHP.stableMasterIndex = GHP.BuildStableMasterIndex(GHP.stable_masters)
        GHP.stableMasterIndexSource = GHP.stable_masters
    end

    return GHP.stableMasterIndex
end
