package.path = "./?.lua;" .. package.path

local GHP = { utils = {} }
_G.GHP = GHP

dofile("StablePetList.lua")

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

local tests = {}

function tests.nil_stabled_list_is_unloaded()
    local state = GHP.utils.GetStablePetListState(nil, false)
    assertEqual(state.status, "unloaded", "status")
    assertTableLength(state.pets, 0, "pets")
    assertEqual(state.message, "Stable data is not available right now. Full stable data may require leaving the instance or opening a stable master.", "message")
end

function tests.nil_stabled_list_is_unloaded_away_from_stable_master()
    local state = GHP.utils.GetStablePetListState(nil, false)
    assertEqual(state.status, "unloaded", "status")
    assertTableLength(state.pets, 0, "pets")
    assertEqual(state.message, "Stable data is not available right now. Full stable data may require leaving the instance or opening a stable master.", "message")
end

function tests.empty_stabled_list_at_stable_master_is_empty()
    local state = GHP.utils.GetStablePetListState({}, true)
    assertEqual(state.status, "empty", "status")
    assertTableLength(state.pets, 0, "pets")
    assertEqual(state.message, "No stable pets were returned for this hunter.", "message")
end

function tests.empty_stabled_list_is_unloaded_away_from_stable_master()
    local state = GHP.utils.GetStablePetListState({}, false)
    assertEqual(state.status, "unloaded", "status")
    assertTableLength(state.pets, 0, "pets")
    assertEqual(state.message, "Stable data is not available right now. Full stable data may require leaving the instance or opening a stable master.", "message")
end

function tests.stabled_pets_take_priority()
    local stabledPets = {
        { name = "Stable One", familyName = "Bear", level = 70 },
    }
    local state = GHP.utils.GetStablePetListState(stabledPets, false)
    assertEqual(state.status, "loaded", "status")
    assertTableLength(state.pets, 1, "pets")
    assertEqual(state.message, nil, "message")
end

function tests.search_does_not_reveal_pets_when_stable_is_unloaded()
    local state = GHP.utils.GetStablePetListState({}, false)
    local filteredPets = GHP.utils.FilterStablePets(state.pets, "Active", "name")
    assertTableLength(filteredPets, 0, "filteredPets")
end

function tests.filters_by_name_family_and_level_safely()
    local pets = {
        { name = "Shadow", familyName = "Spirit Beast", level = 70 },
        { name = "Bark", familyName = "Wolf", level = 65 },
        { name = nil, familyName = nil, level = nil },
    }

    local byName = GHP.utils.FilterStablePets(pets, "sha", "name")
    assertTableLength(byName, 1, "byName")
    assertEqual(byName[1].name, "Shadow", "byName first")

    local byFamily = GHP.utils.FilterStablePets(pets, "wolf", "family")
    assertTableLength(byFamily, 1, "byFamily")
    assertEqual(byFamily[1].name, "Bark", "byFamily first")

    local byLevel = GHP.utils.FilterStablePets(pets, "70", "level")
    assertTableLength(byLevel, 1, "byLevel")
    assertEqual(byLevel[1].name, "Shadow", "byLevel first")
end

function tests.active_pets_are_indexed_by_slot_id()
    local activePets = {
        { name = "Slot One", slotID = 1 },
        { name = "Slot Four", slotID = 4 },
    }

    local petsBySlot = GHP.utils.IndexActivePetsBySlot(activePets, 5)
    assertEqual(petsBySlot[1].name, "Slot One", "slot one")
    assertEqual(petsBySlot[2], nil, "slot two")
    assertEqual(petsBySlot[3], nil, "slot three")
    assertEqual(petsBySlot[4].name, "Slot Four", "slot four")
    assertEqual(petsBySlot[5], nil, "slot five")
end

function tests.active_pets_without_slot_id_do_not_shift_into_empty_slots()
    local activePets = {
        { name = "Missing Slot" },
        { name = "Slot Three", slotID = 3 },
    }

    local petsBySlot = GHP.utils.IndexActivePetsBySlot(activePets, 5)
    assertEqual(petsBySlot[1], nil, "slot one")
    assertEqual(petsBySlot[2], nil, "slot two")
    assertEqual(petsBySlot[3].name, "Slot Three", "slot three")
end

function tests.active_pet_abilities_are_combined_for_details()
    local pet = {
        petAbilities = { 17253, 24423 },
        specAbilities = { 264662, 388035 },
    }

    local abilities = GHP.utils.GetPetDisplayAbilities(pet)
    assertTableLength(abilities, 4, "abilities")
    assertEqual(abilities[1], 17253, "first ability")
    assertEqual(abilities[4], 388035, "last ability")
end

local passed = 0
for name, test in pairs(tests) do
    test()
    passed = passed + 1
    print("PASS stable_list_state_test." .. name)
end

print(string.format("PASS stable_list_state_test: %d tests", passed))
