package.path = "./?.lua;" .. package.path

local GHP = {}
_G.GHP = GHP

dofile("MapPetIndex.lua")

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

local pets = {
    { zoneID = 1, name = "Common Cat", class = "Normal", family = { 1, "Cat" }, coords = { { 10, 20 } } },
    { zoneID = 1, name = "Rare Wolf", class = "Rare", family = { 2, "Wolf" }, coords = { { 30, 40 } } },
    { zoneID = 1, name = "Elite Bear", class = "Elite", family = { 3, "Bear" }, coords = { { 50, 60 } } },
    { zoneID = 1, name = "Rare Elite Spirit Beast", class = "Rare Elite", family = { 46, "Spirit Beast" }, coords = { { 55, 65 } } },
    { zoneID = 2, name = "Other Zone", class = "Rare", family = { 4, "Fox" }, coords = { { 70, 80 } } },
}

local index = GHP.BuildMapPetIndex(pets)

local allPets = GHP.GetPetsForMap(index, 1, 1)
assertTableLength(allPets, 4, "allPets")
assertEqual(allPets[1].name, "Common Cat", "allPets first")

local rarePets = GHP.GetPetsForMap(index, 1, 2)
assertTableLength(rarePets, 1, "rarePets")
assertEqual(rarePets[1].name, "Rare Wolf", "rarePets first")

local elitePets = GHP.GetPetsForMap(index, 1, 3)
assertTableLength(elitePets, 1, "elitePets")
assertEqual(elitePets[1].name, "Elite Bear", "elitePets first")

local rareElitePets = GHP.GetPetsForMap(index, 1, 5)
assertTableLength(rareElitePets, 3, "rareElitePets")
assertEqual(rareElitePets[1].name, "Rare Wolf", "rareElitePets first")
assertEqual(rareElitePets[2].name, "Elite Bear", "rareElitePets second")
assertEqual(rareElitePets[3].name, "Rare Elite Spirit Beast", "rareElitePets third")

local disabledPets = GHP.GetPetsForMap(index, 1, 4)
assertTableLength(disabledPets, 0, "disabledPets")

local missingMapPets = GHP.GetPetsForMap(index, 999, 1)
assertTableLength(missingMapPets, 0, "missingMapPets")

print("PASS map_pet_index_test: map indexing and filtering")
