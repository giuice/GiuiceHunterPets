_, GHP = ...

-- Create settings category
local category = Settings.RegisterVerticalLayoutCategory("Giuice Hunter Pets")
GHP.category_id = category:GetID()
-- Create checkbox settings
do
    -- World Map Pins checkbox
    -- local name = "Show Pet Pins on World Map"
    -- local variable = "GHP_WorldMapPins"
    -- local variableKey = "worldMapPins"
    -- local defaultValue = true

    -- local setting = Settings.RegisterAddOnSetting(category, 
    --     variable,
    --     variableKey, 
    --     GHP_SavedVars,  -- Pass the table here, not a string
    --     type(defaultValue), 
    --     name,
    --     defaultValue)
    
    -- local tooltip = "Enable or disable showing tameable pet locations on the world map"
    -- Settings.CreateCheckbox(category, setting, tooltip)
    
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
    
        local setting = Settings.RegisterAddOnSetting(category, 
            variable,
            variableKey, 
            GHP_SavedVars,  -- Pass the table here, not a string
            type(defaultValue), 
            name,
            defaultValue)
        Settings.CreateDropdown(category, setting, GetOptions, tooltip)
        --Settings.SetOnValueChangedCallback(variableKey, GHP.OnWorldMapPinsSettingChanged)
        setting:SetValueChangedCallback(GHP.OnWorldMapPinsSettingChanged)
    end

end

do
    -- Tooltips checkbox
    local name = "Enable Enhanced Tooltips"
    local variable = "GHP_Tooltips"
    local variableKey = "tooltips"
    local defaultValue = true

    local setting = Settings.RegisterAddOnSetting(category, 
        variable,
        variableKey,
        GHP_SavedVars,  -- Pass the table here
        type(defaultValue),
        name, 
        defaultValue)

    local tooltip = "Show additional information in tooltips for tameable pets"
    Settings.CreateCheckbox(category, setting, tooltip)

end

do
    -- Minimap Pins checkbox
    local name = "Show Pet Pins on Minimap"
    local variable = "GHP_MinimapPins"
    local variableKey = "minimapPins"
    local defaultValue = true

    local setting = Settings.RegisterAddOnSetting(category, 
        variable,
        variableKey,
        GHP_SavedVars,  -- Pass the table here
        type(defaultValue),
        name,
        defaultValue)

    local tooltip = "Enable or disable showing nearby tameable pets on the minimap"
    Settings.CreateCheckbox(category, setting, tooltip)
    
end

-- Register the category
Settings.RegisterAddOnCategory(category)
