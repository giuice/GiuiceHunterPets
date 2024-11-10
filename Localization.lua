local addonName, GHP = ...

-- Add after our existing helper functions
local L = {
    -- English
    ["enUS"] = {
        ["Aqiri"] = "Aqiri",
        ["Carapid"] = "Carapid",
        ["Chimaera"] = "Chimaera",
        ["Core Hound"] = "Core Hound",
        ["Devilsaur"] = "Devilsaur",
        ["Pterrordax"] = "Pterrordax",
        ["Shale Beast"] = "Shale Beast",
        ["Spirit Beast"] = "Spirit Beast",
        ["Stone Hound"] = "Stone Hound",
        ["Water Strider"] = "Water Strider",
        ["Worm"] = "Worm"
    },
    -- Brazilian Portuguese
    ["ptBR"] = {
        ["Aqiri"] = "Aqir",
        ["Water Strider"] = "Caminhante das Águas",
        ["Stone Hound"] = "Canaz Pétreo",
        ["Core Hound"] = "Cão-magma",
        ["Carapid"] = "Carapídeo",
        ["Devilsaur"] = "Demossauro",
        ["Spirit Beast"] = "Fera Espiritual",
        ["Shale Beast"] = "Fera Xistosa",
        ["Pterrordax"] = "Pterrordax",
        ["Chimaera"] = "Quimera",
        ["Worm"] = "Verme"
    },
    -- Spanish
    ["esES"] = {
        ["Aqiri"] = "Aqir",
        ["Water Strider"] = "Zancudo acuático",
        ["Stone Hound"] = "Can de piedra",
        ["Core Hound"] = "Can del Núcleo",
        ["Carapid"] = "Carápido",
        ["Devilsaur"] = "Demosaurio",
        ["Spirit Beast"] = "Bestia espíritu",
        ["Shale Beast"] = "Bestia de esquisto",
        ["Pterrordax"] = "Pterrordáctilo",
        ["Chimaera"] = "Quimera",
        ["Worm"] = "Gusano"
    },
}


-- Get current client locale
local clientLocale = GetLocale()

-- Create exotic families lookup table with localized names
GHP.exoticFamilies = {}
for baseKey, baseValue in pairs(L["enUS"]) do
    -- Add English version
    GHP.exoticFamilies[baseValue] = true
    -- Add localized version if it exists
    if L[clientLocale] and L[clientLocale][baseKey] then
        GHP.exoticFamilies[L[clientLocale][baseKey]] = true
    end
end

local function DebugExoticFamilies()
    for key, value in pairs(GHP.exoticFamilies) do
        print(key, value)
    end
end
DebugExoticFamilies()