# Wow Api Changes

## 11.x
### New menu system
A replacement menuing system has been implemented that serves as a replacement for the existing UIDropDownMenu framework.

All Blizzard defined menus have been migrated to the new menu system.

Documentation and examples have been provided by Blizzard in the 11.0.0 Menu Implementation Guide script in the user interface code export. Simplified examples for common use cases are provided below.
The new menu system may eventually make its way into Classic, but this isn't expected to be the case for potentially quite some time.
UIDropDownMenu has been retained for addon compatibility only, and is otherwise considered deprecated.
Utilities built around UIDropDownMenu such as EasyMenu have however been removed.
#### Dropdown menus
Dropdown menus can be created via the new DropdownButton intrinsic frame type. The following example sets up a basic dropdown in the middle of the screen that when clicked will open a menu with a non-interactive title, and three clickable buttons.
```lua
local Dropdown = CreateFrame("DropdownButton", nil, UIParent, "WowStyle1DropdownTemplate")
Dropdown:SetDefaultText("Default Text")
Dropdown:SetPoint("CENTER")
Dropdown:SetupMenu(function(dropdown, rootDescription)
    rootDescription:CreateTitle("Test Menu")
    rootDescription:CreateButton("Button 1", function() print("Clicked button 1") end)
    rootDescription:CreateButton("Button 2", function() print("Clicked button 2") end)
    rootDescription:CreateButton("Button 3", function() print("Clicked button 3") end)
end)
```
#### Context menus
Context menus can be spawned via the new MenuUtil.CreateContextMenu(ownerRegion, generator) function that should typically be called within an OnMouseDown handler on a button. When invoked, the context menu will be immediately populated and opened at the location of the mouse cursor. There is at present no support for explicitly anchoring a context menu to a region.
```lua
MenuUtil.CreateContextMenu(UIParent, function(ownerRegion, rootDescription)
    rootDescription:CreateTitle("Test Menu")
    rootDescription:CreateButton("Button 1", function() print("Clicked button 1") end)
    rootDescription:CreateButton("Button 2", function() print("Clicked button 2") end)
    rootDescription:CreateButton("Button 3", function() print("Clicked button 3") end)
end)
```
#### Basic menu factories
For basic menus that only consist of a list of elements that each share the same type, the following utility functions can be used to generate a menu description from a table of values. These may serve as suitable replacements for some usages of the now removed EasyMenu functionality.
```lua
MenuUtil.CreateButtonMenu(dropdown, ...)
MenuUtil.CreateButtonContextMenu(ownerRegion, ...)
MenuUtil.CreateCheckboxMenu(dropdown, isSelected, setSelected, ...)
MenuUtil.CreateCheckboxContextMenu(ownerRegion, isSelected, setSelected, ...)
MenuUtil.CreateRadioMenu(dropdown, isSelected, setSelected, ...)
MenuUtil.CreateRadioContextMenu(ownerRegion, isSelected, setSelected, ...)
The following example creates a dropdown menu button that when clicked will open up to a list of three radio buttons.

local RadioDropdown = CreateFrame("DropdownButton", nil, UIParent, "WowStyle1DropdownTemplate")
RadioDropdown:SetDefaultText("No selection")
RadioDropdown:SetPoint("CENTER")

local selectedValue = nil

local function IsSelected(value)
    return value == selectedValue
end

local function SetSelected(value)
    selectedValue = value
end

MenuUtil.CreateRadioMenu(RadioDropdown,
    IsSelected, 
    SetSelected,
    {"Radio 1", 1},
    {"Radio 2", 2},
    {"Radio 3", 3},
)
```
#### Hooking menus
Menus can be tagged with an arbitrary identifier for hooking. The Menu.ModifyMenu("tag", callback) function can be used to run a callback whenever the menu with the specified tag is shown.

Blizzard have pre-tagged many menus in the client, allowing them to be hooked immediately.
The menu modification callback may additionally receive a table of menu-specific contextual data as the third parameter.
In the case of unit popup menus, this contextual data includes attributes such as the unit token and the "which" parameter.
The following example demonstrates this by modifying the players' unit popup menu and inserting buttons into its root description.
```lua
Menu.ModifyMenu("MENU_UNIT_SELF", function(ownerRegion, rootDescription, contextData)
    -- Append a new section to the end of the menu.
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)
    rootDescription:CreateButton("Appended button", function() print("Clicked the appended button!") end)

    -- Insert a new section at the start of the menu.
    local title = MenuUtil.CreateTitle(addonName)
    rootDescription:Insert(title, 1)
    local button = MenuUtil.CreateButton("Inserted button", function() print("Clicked the inserted button!") end)
    rootDescription:Insert(button, 2)
    local divider = MenuUtil.CreateDivider()
    rootDescription:Insert(divider, 3)
end)
```

## 10.x
### Settings API
The interface options interface and APIs have changed significantly in 10.0. A small subset of the existing API remains as deprecated functions, along with a set of deprecated XML templates for various options controls.

The new settings API permits registering nestable categories that fit one of two layout archetypes;

A "Canvas" layout wherein a frame has full manual control over the placement and behavior of its child widgets. This concept matches what addon authors are already acquainted with through the existing InterfaceOptions_AddCategory API.
A "Vertical" layout wherein controls will be automatically positioned and stacked in vertically in a list. The controls can be configured to automatically read and write their values to a destination table.
Canvas Layout

Example settings category using a manual canvas layout.
A minimal example of the "Canvas" layout registration API can be found below. This example will register a custom frame that consists of a single full-size texture within the "AddOns" tab of the Settings interface.
```lua
local frame = CreateFrame("Frame")
local background = frame:CreateTexture()
background:SetAllPoints(frame)
background:SetColorTexture(1, 0, 1, 0.5)

local category = Settings.RegisterCanvasLayoutCategory(frame, "My AddOn")
Settings.RegisterAddOnCategory(category)
```

### Vertical Layout

Example settings category using an automatic vertical layout.
A minimal example of the "Vertical" layout registration API can be found below. This will create three controls - a checkbox, slider, and dropdown - and configure them to automatically read and write their values to a global table named MyAddOn_SavedVars.
```lua
MyAddOn_SavedVars = {}

local function OnSettingChanged(_, setting, value)
	local variable = setting:GetVariable()
	MyAddOn_SavedVars[variable] = value
end

local category = Settings.RegisterVerticalLayoutCategory("My AddOn")

do
    local variable = "MyAddOn_Toggle"
    local name = "Test Checkbox"
    local tooltip = "This is a tooltip for the checkbox."
    local defaultValue = false

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    Settings.CreateCheckbox(category, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end

do
    local variable = "MyAddOn_Slider"
    local name = "Test Slider"
    local tooltip = "This is a tooltip for the slider."
    local defaultValue = 180
    local minValue = 90
    local maxValue = 360
    local step = 10

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
    Settings.CreateSlider(category, setting, options, tooltip)
	Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end

do
    local variable = "MyAddOn_Selection"
    local defaultValue = 2  -- Corresponds to "Option 2" below.
    local name = "Test Dropdown"
    local tooltip = "This is a tooltip for the dropdown."

    local function GetOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add(1, "Option 1")
        container:Add(2, "Option 2")
        container:Add(3, "Option 3")
        return container:GetData()
    end

    local setting = Settings.RegisterAddOnSetting(category, name, variable, type(defaultValue), defaultValue)
    Settings.CreateDropdown(category, setting, GetOptions, tooltip)
	Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
end

Settings.RegisterAddOnCategory(category)
```

### Unit Aura Changes
The UNIT_AURA event is now capable of delivering information in its payload about which specific auras on a unit have been added, changed, or removed since the last aura update.

Auras now have an "instance ID" (auraInstanceID) which uniquely refers to an instance of an aura for the duration of its lifetime on a unit. The instance ID is expected to remain stable and suitable for use as a table key between successive updates of auras on a unit until a full aura update occurs.

Three new APIs are provided to query information about auras and will return structured tables:

C_UnitAuras.GetAuraDataByAuraInstanceID can be used to obtain aura information given a unit token and an aura instance ID.
C_UnitAuras.GetAuraDataBySlot can be used as an alternative to UnitAuraBySlot to access aura information by filtered slot indices.
C_UnitAuras.GetPlayerAuraBySpellID queries for aura information on the player unit by a given spell ID.
From each of these APIs the returned aura structure is expected to contain the same return values as are obtainable through the existing UnitAura APIs, however note that some field names may not line up with the documented return value names. The returned information will also include the instance ID of the aura.

The below example will demonstrate how the payload from UNIT_AURA can be processed to collect information about the players' auras into a table for both the full-update and incremental-update cases.
```lua
local PlayerAuras = {}

local function UpdatePlayerAurasFull()
    PlayerAuras = {}

    local function HandleAura(aura)
        PlayerAuras[aura.auraInstanceID] = aura
        -- Perform any setup or update tasks for this aura here.
    end

    local batchCount = nil
    local usePackedAura = true
    AuraUtil.ForEachAura("player", "HELPFUL", batchCount, HandleAura, usePackedAura)
    AuraUtil.ForEachAura("player", "HARMFUL", batchCount, HandleAura, usePackedAura)
end

local function UpdatePlayerAurasIncremental(unitAuraUpdateInfo)
    if unitAuraUpdateInfo.addedAuras ~= nil then
        for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
            PlayerAuras[aura.auraInstanceID] = aura
            -- Perform any setup tasks for this aura here.
        end
    end

    if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
        for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
            PlayerAuras[auraInstanceID] = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
            -- Perform any update tasks for this aura here.
        end
    end

    if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
        for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
            PlayerAuras[auraInstanceID] = nil
            -- Perform any cleanup tasks for this aura here.
        end
    end
end

local function OnUnitAurasUpdated(unit, unitAuraUpdateInfo)
    if unit ~= "player" then
        return
    end

    if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate then
        UpdatePlayerAurasFull()
    else
        UpdatePlayerAurasIncremental(unitAuraUpdateInfo)
    end
end

EventRegistry:RegisterFrameEventAndCallback("UNIT_AURA", OnUnitAurasUpdated)
```
### Interaction Manager
Show and Hide events have been streamlined into PLAYER_INTERACTION_MANAGER_FRAME_SHOW/Hide, for example:
```lua
local function OnEvent(self, event, id)
	if id == Enum.PlayerInteractionType.Banker then
		print("opened the bank")
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
--f:RegisterEvent("BANKFRAME_OPENED")
f:SetScript("OnEvent", OnEvent)
```
## Templates
### DeprecatedTemplates.xml

OptionsBaseCheckButtonTemplate
InterfaceOptionsCheckButtonTemplate
InterfaceOptionsBaseCheckButtonTemplate
OptionsSliderTemplate
OptionsFrameTabButtonTemplate
OptionsListButtonTemplate

FauxScrollFrameTemplate
FauxScrollFrameTemplateLight
ListScrollFrameTemplate
MinimalScrollBarTemplate
MinimalScrollBarWithBorderTemplate
MinimalScrollFrameTemplate
UIPanelInputScrollFrameTemplate
UIPanelScrollBarTemplate
UIPanelScrollBarTemplateLightBorder
UIPanelScrollBarTrimTemplate
UIPanelScrollFrameCodeTemplate
UIPanelScrollFrameTemplate
UIPanelStretchableArtScrollBarTemplate
The ScrollFrame_OnLoad function was renamed to UIPanelScrollFrame_OnLoad, however the old function name was reused and now refers to an entirely new and different function. If you are having issues with multiple scrollbars appearing on a scroll frame, renaming these function calls may be a solution.

### Replacements

HorizontalSliderTemplate -> UISliderTemplate
OptionsBoxTemplate was removed without a direct replacement, a Lua fix could be similar to this:
```lua
local f = CreateFrame("Frame", "SomeFrame", nil, "TooltipBorderBackdropTemplate")
f.Title = f:CreateFontString(f:GetName().."Title", "BACKGROUND", "GameFontHighlightSmall")
f.Title:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 5, 0)
f:SetBackdropColor(DARKGRAY_COLOR:GetRGBA())
```

## Scroll Templates
A new ScrollFrame template named ScrollFrameTemplate has been added. This serves as a replacement for many old scrolling related templates that are now deprecated as of this patch. This template can be used as a simpler alternative to ScrollBox views, and automatically creates and configures a scrollbar for use with the frame. An Lua example can be found below to demonstrate the use of this new template.
```lua
local ScrollFrame = CreateFrame("ScrollFrame", nil, UIParent, "ScrollFrameTemplate")
ScrollFrame:SetSize(300, 300)
ScrollFrame:SetPoint("CENTER")

local ScrollChild = CreateFrame("Frame")
ScrollChild:SetSize(300, 600)

local ScrollTexture = ScrollChild:CreateTexture(nil, "OVERLAY")
ScrollTexture:SetAllPoints(ScrollChild)
ScrollTexture:SetColorTexture(1, 0, 0, 1)
ScrollTexture:SetGradient("VERTICAL", CreateColor(1, 0, 0, 1), CreateColor(0, 0, 0, 1))

ScrollFrame:SetScrollChild(ScrollChild)
```
For XML use cases, refer to the following example.
```xml
<ScrollFrame name="MyAddon_ScrollFrame" inherits="ScrollFrameTemplate" parent="UIParent">
    <Size x="300" y="300"/>
    <Anchors>
        <Anchor point="CENTER"/>
    </Anchors>
    <ScrollChild>
        <Frame>
            <Size x="300" y="600"/>
            <Layers>
                <Layer level="OVERLAY">
                    <Texture setAllPoints="true">
                        <Color r="1"/>
                        <Gradient orientation="VERTICAL">
                            <MinColor r="1"/>
                            <MaxColor r="0"/>
                        </Gradient>
                    </Texture>
                </Layer>
            </Layers>
        </Frame>
    </ScrollChild>
</ScrollFrame>
```
The following key values pairs can be assigned via XML to customize the creation of the scrollbar.

Key	Description
noScrollBar	If true, don't create a scrollbar when the template is loaded.
scrollBarBottomY	Bottom anchor offest for the scroll bar.
scrollBarHideIfUnscrollable	If true, hide the scrollbar automatically if the scrollframe contents cannot be scrolled.
scrollBarHideTrackIfThumbExceedsTrack	If true, hide the scrollbar track and thumb if the thumb would be too large to fit in the scrollbar.
scrollBarTemplate	The name of a template to instantiate for the scrollbar. Defaults to MinimalScrollBar.
scrollBarTopY	Top anchor Vertical offset for the scroll bar.
scrollBarX	Left anchor offset for the scroll bar.	

