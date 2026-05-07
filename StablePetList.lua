local addonName, GHP = ...

if UnitClass and select(3, UnitClass("player")) ~= 3 then
    return
end

GHP = GHP or _G.GHP or {}
GHP.utils = GHP.utils or {}

local UNLOADED_MESSAGE = "Stable data is not available right now. Full stable data may require leaving the instance or opening a stable master."
local ACTIVE_ONLY_MESSAGE = "Only active pets are available right now. Full stable data may require leaving the instance or opening a stable master."
local EMPTY_MESSAGE = "No stable pets were returned for this hunter."

function GHP.utils.GetStablePetListState(stabledPets, activePets)
    if stabledPets and #stabledPets > 0 then
        return {
            status = "loaded",
            pets = stabledPets,
            message = nil,
        }
    end

    if activePets and #activePets > 0 then
        return {
            status = "active-only",
            pets = activePets,
            message = ACTIVE_ONLY_MESSAGE,
        }
    end

    if stabledPets == nil then
        return {
            status = "unloaded",
            pets = {},
            message = UNLOADED_MESSAGE,
        }
    end

    return {
        status = "empty",
        pets = {},
        message = EMPTY_MESSAGE,
    }
end

local function LowerText(value)
    return tostring(value or ""):lower()
end

function GHP.utils.FilterStablePets(pets, searchText, searchType)
    if not searchText or searchText == "" then
        return pets
    end

    local needle = searchText:lower()
    local filteredPets = {}

    for _, pet in ipairs(pets) do
        local value
        if searchType == "family" then
            value = pet.familyName
        elseif searchType == "level" then
            value = pet.level
        else
            value = pet.name
        end

        if LowerText(value):find(needle, 1, true) then
            table.insert(filteredPets, pet)
        end
    end

    return filteredPets
end

local function AppendAbilities(target, abilities)
    for _, abilityID in ipairs(abilities or {}) do
        table.insert(target, abilityID)
    end
end

function GHP.utils.GetPetDisplayAbilities(petInfo)
    local abilities = {}

    if not petInfo then
        return abilities
    end

    if petInfo.abilities and #petInfo.abilities > 0 then
        AppendAbilities(abilities, petInfo.abilities)
        return abilities
    end

    AppendAbilities(abilities, petInfo.petAbilities)
    AppendAbilities(abilities, petInfo.specAbilities)

    return abilities
end
