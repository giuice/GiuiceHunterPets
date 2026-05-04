package.path = "./?.lua;" .. package.path

local GHP = {}
_G.GHP = GHP

dofile("StableMasterIndex.lua")

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

local stableMasters = {
    { zoneID = 1, name = "Shoja'my", faction = "Horde", coords = { { 52, 41.8 } } },
    { zoneID = 1, name = "Shared Handler", faction = "Neutral", coords = { { 53.4, 40.8 } } },
    { zoneID = 84, name = "Jenova Stoneshield", faction = "Alliance", coords = { { 67, 37.4 } } },
    { name = "Missing Zone" },
}

local index = GHP.BuildStableMasterIndex(stableMasters)

local durotarStableMasters = GHP.GetStableMastersForMap(index, 1)
assertTableLength(durotarStableMasters, 2, "durotarStableMasters")
assertEqual(durotarStableMasters[1].name, "Shoja'my", "durotarStableMasters first")
assertEqual(durotarStableMasters[2].name, "Shared Handler", "durotarStableMasters second")

local stormwindStableMasters = GHP.GetStableMastersForMap(index, 84)
assertTableLength(stormwindStableMasters, 1, "stormwindStableMasters")
assertEqual(stormwindStableMasters[1].name, "Jenova Stoneshield", "stormwindStableMasters first")

local missingMapStableMasters = GHP.GetStableMastersForMap(index, 999)
assertTableLength(missingMapStableMasters, 0, "missingMapStableMasters")

assertEqual(index[2], nil, "missing zone is ignored")

GHP.stable_masters = stableMasters
local ensuredIndex = GHP.EnsureStableMasterIndex()
assertEqual(ensuredIndex, GHP.stableMasterIndex, "EnsureStableMasterIndex stores index")
assertEqual(GHP.stableMasterIndexSource, stableMasters, "EnsureStableMasterIndex tracks source")

local rebuiltSource = {
    { zoneID = 7, name = "Seikwa", faction = "Horde", coords = { { 47, 59.6 } } },
}
GHP.stable_masters = rebuiltSource
local rebuiltIndex = GHP.EnsureStableMasterIndex()
local mulgoreStableMasters = GHP.GetStableMastersForMap(rebuiltIndex, 7)
assertTableLength(mulgoreStableMasters, 1, "mulgoreStableMasters")
assertEqual(mulgoreStableMasters[1].name, "Seikwa", "mulgoreStableMasters first")

print("PASS stable_master_index_test: stable master indexing and cache invalidation")