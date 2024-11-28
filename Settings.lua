_, GHP = ...


GHP_SavedVars = GHP_SavedVars or {
    worldMapPins = 1, -- Default to "All Pets Pins"
    tooltips = true,
    minimapPins = true,
    position = nil,
    minimap = { hide = false }
}

-- Create settings category
local category = Settings.RegisterVerticalLayoutCategory("Giuice Hunter Pets")
GHP.category_id = category:GetID()


do
    local name = "Show Pet Pins on World Map"
    local variable = "GHP_WorldMapPins"
    local variableKey = "worldMapPins"
    local defaultValue = 1

    local tooltip = "Enable or disable showing tameable pet locations on the world map."

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add(1, "All Pets Pins")
        container:Add(2, "Rares Pets Pins")
        container:Add(3, "Elite Pets Pins")
        container:Add(4, "Disable Pins")
        return container:GetData()
    end

    local function GetValue()
        return GHP_SavedVars.worldMapPins or defaultValue
    end

    local function SetValue(value)
        GHP_SavedVars.worldMapPins = value
    end

    local setting = Settings.RegisterProxySetting(category,
        variable,
        type(defaultValue),
        name,
        defaultValue,
        GetValue,
        SetValue
    )

    Settings.CreateDropdown(category, setting, GetOptions, tooltip)
    
    setting:SetValueChangedCallback(function(setting, value)
        GHP.OnWorldMapPinsSettingChanged(setting, value)
    end)
end



do
    -- Minimap Pins checkbox
    local name = "Show Pet Pins on Minimap"
    local variable = "GHP_MinimapPins"
    local variableKey = "minimapPins"
    local variableTbl = GHP_SavedVars -- Pass the table here
    local defaultValue = true

    local function GetValue()
        return GHP_SavedVars.minimapPins or defaultValue
    end

    local function SetValue(value)
        GHP_SavedVars.minimapPins = value
    end

    local setting = Settings.RegisterProxySetting(category,
        variableKey,
        type(defaultValue),
        name,
        defaultValue,
        GetValue,
        SetValue
    )

    -- local setting = Settings.RegisterAddOnSetting(category,
    --     variableKey,    -- Key in the saved variables table
    --     variable,       -- Variable name 
    --     variableTbl,    -- Table to store the setting
    --     type(defaultValue), -- Type
    --     name,           -- Display name
    --     defaultValue)   -- Default value

    local tooltip = "Enable or disable showing nearby tameable pets on the minimap"
    setting:SetValueChangedCallback(function(setting, value)
        GHP.OnMinimapPinsSettingChanged(setting, value)
    end)
    Settings.CreateCheckbox(category, setting, tooltip)
    
end

-- Register the category
Settings.RegisterAddOnCategory(category)
