local addonName, addonTable = ...

local GHP = addonTable or _G.GHP or {}
_G.GHP = GHP

local pinSettingsTableOptions = {
    [1] = "allpets",
    [2] = "rarepets",
    [3] = "elitepets",
    [4] = "nopets",
    [5] = "rareelitepets",
}

local function IsRareClassification(classification)
    return classification == "Rare"
end

local function IsEliteClassification(classification)
    return classification == "Elite"
end

local function IsRareEliteClassification(classification)
    return classification == "Rare Elite"
end

function GHP.BuildMapPetIndex(pets)
    local index = {}

    for _, petData in ipairs(pets or {}) do
        if petData.zoneID then
            index[petData.zoneID] = index[petData.zoneID] or {}
            table.insert(index[petData.zoneID], petData)
        end
    end

    return index
end

function GHP.GetPetsForMap(index, mapID, settingValue)
    if not mapID or settingValue == 4 then
        return {}
    end

    local setting = pinSettingsTableOptions[settingValue or 1]
    local petsForMap = index and index[mapID] or {}
    local filteredPets = {}

    for _, petData in ipairs(petsForMap) do
        if setting == "allpets"
            or (setting == "rarepets" and IsRareClassification(petData.class))
            or (setting == "elitepets" and IsEliteClassification(petData.class))
            or (setting == "rareelitepets" and IsRareEliteClassification(petData.class)) then
            table.insert(filteredPets, petData)
        end
    end

    return filteredPets
end

function GHP.BuildTameableCreatureIndex(pets)
    local index = {}

    for _, petData in ipairs(pets or {}) do
        local npcId = petData.NpcId or petData.id
        if npcId then
            index[npcId] = true
        end
    end

    return index
end
