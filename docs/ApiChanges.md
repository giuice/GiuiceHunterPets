# Wow Api Changes

## 11.x

### Breaking changes
The Settings API has been changed, particularly around the creation of settings. Refer to Settings API changes for more details.
- Macros and the macrotext attribute of SecureActionButtonTemplate have new limitations:
- macrotext limited to 255 characters (same length as real macros)
- All macros (real and macrotext-based) can no longer chain macros. One macro cannot /click a button that would execute another macro
- SharedTooltipTemplate and GameTooltipTemplate no longer inherit BackdropTemplate.

### Backdrop System Changes
Frames no longer provide Backdrop related APIs by default and need to be opted-in by either inheriting BackdropTemplate or including BackdropTemplateMixin and its associated script handlers.

#### Lua Changes
In the case of Lua-created frames that don't currently inherit a template, the following example would work on both live and beta clients:
```lua
local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate");
frame:SetBackdrop({ --[[ Usual backdrop parameters here ]] });
```
If necessary, templates can be comma-delimited to specify multiple.

#### XML Changes
For frames created in XML using the <Backdrop> element, ensure that the frame inherits the required template and instead either specify the parameters for the backdrop as the <KeyValue> elements listed below, or convert the backdrop definition to Lua and call self:SetBackdrop() in an OnLoad script handler.

#### The following <KeyValue> elements are accepted by the template:

Key	Type	Description
backdropInfo	global table	Name of a global table providing the backdrop definition, with bgFile, edgeFile, etc.
backdropColor	global table	Name of a global Color table for the background texture vertex color. If not specified, defaults to white. The alpha component is ignored.
backdropColorAlpha	number [0-1]	Alpha channel value for the background texture vertex color. If not specified, defaults to 1.
backdropBorderColor	global table	Name of a global Color table for the border texture vertex color. If not specified, defaults to white. The alpha component is ignored.
backdropBorderColorAlpha	number [0-1]	Alpha channel value for the border texture vertex color. If not specified, defaults to 1.
backdropBorderBlendMode	string	Name of a BlendMode to apply to the border textures. Optional, defaulting to BLEND.
Any key above listed as "global table" needs to refer to a table in the global environment which contains the backdrop definition as-would-be-passed to SetBackdrop directly. A full list of common Blizzard backdrops is available here.
```xml
<Frame name="TestFrame" parent="UIParent" inherits="BackdropTemplate">
    <KeyValues>
        <KeyValue key="backdropInfo" value="BACKDROP_TOOLTIP_16_16_5555" type="global"/>
        <KeyValue key="backdropBorderColor" value="LEGENDARY_ORANGE_COLOR" type="global"/>
        <KeyValue key="backdropBorderColorAlpha" value="0.25" type="number"/>
    </KeyValues>
    <Size x="300" y="300"/>
    <Anchors>
        <Anchor point="CENTER"/>
    </Anchors>
    <Scripts>
        <OnLoad inherit="prepend">
            print("Loaded!");
        </OnLoad>
    </Scripts>
</Frame>
```
#### Script Handlers
BackdropTemplate installs an OnLoad and OnSizeChanged script handler on any frames that inherit it. If you have custom logic for either of these handlers, ensure that you call the original functions (self:OnBackdropLoaded() and self:OnBackdropSizeChanged()) as part of them. In XML, you can use the inherit="prepend" attribute to do this automatically.

#### Usage
- Adding a new backdrop
1. Create a Frame that inherits BackdropTemplate.
2. Prepare a backdropInfo table, or choose an existing one from FrameXML/Backdrop.lua.
3. Apply the table in Lua using SetBackdrop(backdropInfo); or in XML using <KeyValue> tags.
4. Changing the backdrop
5. Change the vertex colors by calling SetBackdropColor(r, g, b [, a]) and SetBackdropBorderColor(r, g, b [, a]).
6. Change the other properties by calling SetBackdrop() with a new table (silently fails if its the same table, despite any changes).
7. Remove a backdrop by calling SetBackdrop() without args
- Alternatives
  - Instead of SetBackdrop(backdropInfo), save the table as frame.backdropInfo and call ApplyBackdrop().
  - Instead of SetBackdrop(nil), call ClearBackdrop()
  - Instead of creating a new Frame, mixin BackdropTemplateMixin or create custom textures.
- Table structure
backdropInfo
Key	Type	Description
bgFile	string	Texture path to use for the background.
edgeFile	string	Texture path to use for the edges.
tile	boolean	True to tile the background, false to stretch it.
tileSize	number	Width and height of each tile.
edgeSize	number	Border thickness and corner size.
insets	table	How far from the edges the background is drawn.
insets
Key	Type	Description
left	number	Distance inside the left edge.
right	number	Distance inside the right edge.
top	number	Distance inside the top edge.
bottom	number	Distance inside the bottom edge.
#### Methods
When applied to any Frame, BackdropTemplateMixin adds the following API:

ApplyBackdrop() - Applies the backdrop currently saved as frame.backdropInfo. {BackdropTemplateMixin:ApplyBackdrop at Townlong-Yak⁠}
ClearBackdrop() - Hides the current background and border textures. {BackdropTemplateMixin:ClearBackdrop at Townlong-Yak⁠}
SetBackdrop(backdropInfo) - Saves the table to frame.backdropInfo and calls ApplyBackdrop(), or calls ClearBackdrop() if the argument is nil. {BackdropTemplateMixin:SetBackdrop at Townlong-Yak⁠}
GetBackdrop() : table - Returns a copy of frame.backdropInfo. {BackdropTemplateMixin:GetBackdrop at Townlong-Yak⁠}
GetBackdropColor() : r, g, b, a - Returns the background vertex color. {BackdropTemplateMixin:GetBackdropColor at Townlong-Yak⁠}
GetBackdropBorderColor() : r, g, b, a - Returns the border color. {BackdropTemplateMixin:GetBackdropBorderColor at Townlong-Yak⁠}
SetBackdropColor(r, g, b [, a]) - Returns the background vertex color. {BackdropTemplateMixin:GetBackdropColor at Townlong-Yak⁠}
SetBackdropBorderColor(: r, g, b [, a]) - Returns the border color. {BackdropTemplateMixin:GetBackdropBorderColor at Townlong-Yak⁠}
The following methods also exist, but should not need to be called as they are registered via BackdropTemplate:

OnBackdropLoaded() - OnLoad handler to apply a background if it was set in XML using <KeyValues> tags.
OnBackdropSizeChanged() - OnSizeChanged handler to update the textures.
Examples
Creating a Frame in Lua and calling SetBackdrop()

local backdropInfo =
{
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
 	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
 	tile = true,
 	tileEdge = true,
 	tileSize = 8,
 	edgeSize = 8,
 	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local frame = CreateFrame("Frame", nil, nil, "BackdropTemplate")
frame:SetBackdrop(backdropInfo)
Creating a Frame in Lua and calling ApplyBackdrop()

local frame = CreateFrame("Frame", nil, nil, "BackdropTemplate")
frame.backdropInfo = BACKDROP_TOOLTIP_8_8_1111  -- from FrameXML/Backdrop.lua
frame:ApplyBackdrop()
Creating a Frame in XML with KeyValue tags

 <Frame inherits="BackdropTemplate">
 	<KeyValues>
 		<KeyValue key="backdropInfo" value="BACKDROP_TOOLTIP_8_8_1111" type="global" />
 	</KeyValues>
 </Frame>


### Settings API changes
The Settings API has been updated to resolve a few usability issues with respect to the creation and management of settings.

- The Settings.RegisterAddOnSetting function has had its signature changed significantly and now requires two additional parameters (variableKey and variableTbl) in the middle of the parameter list. These are used to directly read and write settings from a supplied table, which is typically expected to be the addon's saved variables.
- The Settings.RegisterProxySetting function has been adjusted and can now be called from insecure code. Proxy settings can be used to execute author-supplied callbacks when reading and writing settings as an alternative to RegisterAddOnSetting.
- The Settings.OpenToCategory function has been improved and now supports directly opening to a subcategory, as well as automatically expanding any categories that it opens.
A minimal example of registering both an addon and a proxy setting is provided below.
```lua
MyAddOn_SavedVars = {}

local category = Settings.RegisterVerticalLayoutCategory("My AddOn")

local function OnSettingChanged(setting, value)
	-- This callback will be invoked whenever a setting is modified.
	print("Setting changed:", setting:GetVariable(), value)
end

do 
	-- RegisterAddOnSetting example. This will read/write the setting directly
	-- to `MyAddOn_SavedVars.toggle`.

    local name = "Test Checkbox"
    local variable = "MyAddOn_Toggle"
	local variableKey = "toggle"
	local variableTbl = MyAddOn_SavedVars
    local defaultValue = false

    local setting = Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, type(defaultValue), name, defaultValue)
	setting:SetValueChangedCallback(OnSettingChanged)

    local tooltip = "This is a tooltip for the checkbox."
	Settings.CreateCheckbox(category, setting, tooltip)
end

do
	-- RegisterProxySetting example. This will run the GetValue and SetValue
	-- callbacks whenever access to the setting is required.

	local name = "Test Slider"
	local variable = "MyAddOn_Slider"
    local defaultValue = 180
    local minValue = 90
    local maxValue = 360
    local step = 10

	local function GetValue()
		return MyAddOn_SavedVars.slider or defaultValue
	end

	local function SetValue(value)
		MyAddOn_SavedVars.slider = value
	end

	local setting = Settings.RegisterProxySetting(category, variable, type(defaultValue), name, defaultValue, GetValue, SetValue)
	setting:SetValueChangedCallback(OnSettingChanged)

	local tooltip = "This is a tooltip for the slider."
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
    Settings.CreateSlider(category, setting, options, tooltip)
end

Settings.RegisterAddOnCategory(category)
```
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

### Texture Slicing
A new texture slicing system has been implemented that allows a single Texture object to render a grid of nine sub-textures without distortion at the corners. The edges and central fill of the rendered texture can be configured to either tile or stretch across their respective dimensions.

This system is recommended to be used in new code going forward as a replacement for both the deprecated Backdrop system and the script-based NineSlice panel layout utility. One of the advantages of this new system is that it only requires a single texture object to render the grid, whereas both the old systems required nine separate objects. This system is fully compatible with custom texture assets and does not require the use of atlases.

To use this system from Lua the TextureBase:SetTextureSliceMargins method should be called to specify the pixel margins that represent the edges of the underlying asset. The TextureBase:SetTextureSliceMode method controls whether or not the central portion of the texture and its surrounding edges will be tiled or stretched, with the default being stretched. The below example demonstrates the usage of these APIs.
```lua
local SliceDemo = CreateFrame("Frame", nil, UIParent);
SliceDemo:SetPoint("CENTER");
SliceDemo:SetSize(256, 256);
SliceDemo:SetResizable(true);

SliceDemo.Texture = SliceDemo:CreateTexture();
SliceDemo.Texture:SetTexture([[interface/soulbinds/soulbindsconduitpendinganimationmask]])
SliceDemo.Texture:SetTextureSliceMargins(24, 24, 24, 24);
SliceDemo.Texture:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled);
SliceDemo.Texture:SetAllPoints(SliceDemo);
SliceDemo.Texture:SetVertexColor(0, 1, 0);

SliceDemo.ResizeButton = CreateFrame("Button", nil, SliceDemo, "PanelResizeButtonTemplate");
SliceDemo.ResizeButton:SetPoint("BOTTOMRIGHT");
SliceDemo.ResizeButton:Init(SliceDemo, 64, 64, 512, 512);
```

The following new elements in XML can be supplied when defining a Texture object to configure this functionality.
```xml
<Texture file="interface/soulbinds/soulbindsconduitpendinganimationmask">
    <TextureSliceMargins left="24" right="24" top="24" bottom="24"/>
    <TextureSliceMode mode="Tiled"/>  <!-- Can be "Tiled" or "Stretched" -->
</Texture>
```

## Tooltip Changes
- <GameTooltip> frames no longer expose native methods for retrieving or populating tooltip contents. Instead, a new C_TooltipInfo namespace has been added which provides APIs for retrieving structured data for use in tooltips and a new set of tooltip-related mixins have been added to populate tooltips from these APIs.

### Custom Tooltip Frames
Any addons that are creating GameTooltip frames should now ensure they inherit GameTooltipTemplate. This template has been updated to include the new GameTooltipDataMixin mixin, which provides automatic updates of tooltip contents from the TOOLTIP_DATA_UPDATE event as well as a subset of backwards-compatible methods for retrieving or populating tooltip contents from the new C_TooltipInfo APIs.

### Scanning Tooltips
The C_TooltipInfo functions can be used to replace existing tooltip scanning techniques, removing the need to create a tooltip frame. The following example will demonstrate extracting information for a unit tooltip on the player.
```lua
local tooltipData = C_TooltipInfo.GetUnit("player")

TooltipUtil.SurfaceArgs(tooltipData)

for _, line in ipairs(tooltipData.lines) do
    TooltipUtil.SurfaceArgs(line)
end

-- The above SurfaceArgs calls are required to assign values to the
-- 'type', 'guid', and 'leftText' fields seen below.

print("Tooltip Type: ", tooltipData.type)
print("Unit GUID: ", tooltipData.guid)
print("Unit Name: ", tooltipData.lines[1].leftText)
print("Unit Info: ", tooltipData.lines[2].leftText)
print("Unit Faction: ", tooltipData.lines[3].leftText)
DevTools_Dump({ tooltipData })
```
> Tooltip Type: 2 (Enum.TooltipDataType.Unit)
> Unit GUID: "Player-4184-00227A8F"
> Unit Name: "Sandse"
> Unit Info: "Level 70 Gnome Mage (Player)"
> Unit Faction: "Alliance"

The tooltipData dump below has been significantly shortened to only show the fields written by TooltipUtil.SurfaceArgs.
```lua
tooltipData = {
    type = 2,
    lines = {
        [1] = {
            leftText = "Sandse",
            leftColor = { r = 1, g = 0.81960791349411, b = 0 },
            type = 2,
            unitToken = "player",
        },
        [2] = {
            leftColor = { r = 1, g = 1, b = 1 },
            type = 0,
            leftText = "Level 70 Gnome Mage (Player)",
        },
        [3] = {
            leftColor = { r = 1, g = 1, b = 1 },
            type = 0,
            leftText = "Alliance",
        },
    },
    guid = "Player-4184-00227A8F",
    healthGUID = "Player-4184-00227A8F",
}
```
### Tooltip Script Handlers
The following GameTooltip script handlers have been removed. This change will not be reflected in the UI XML schema definition until a future patch.

OnTooltipAddMoney
OnTooltipSetAchievement
OnTooltipSetEquipmentSet
OnTooltipSetItem
OnTooltipSetQuest
OnTooltipSetSpell
OnTooltipSetUnit
Usages of these script handlers should be replaced by registering callbacks with the new TooltipDataProcessor.AddTooltipPostCall function. Note that callbacks registered with this mechanism are global and will be triggered for all tooltips which inherit from GameTooltipTemplate.
```lua
local function OnTooltipSetItem(tooltip, data)
    if tooltip == GameTooltip then
        print("OnTooltipSetItem", tooltip, data)
    end
end

-- Replace 'Enum.TooltipDataType.Item' with an appropriate type for the tooltip
-- data you are wanting to process; eg. use 'Enum.TooltipDataType.Spell' for
-- replacing usage of OnTooltipSetSpell.
--
-- If you wish to respond to all tooltip data updates, you can instead replace
-- the enum with 'TooltipDataProcessor.AllTypes' (or the string "ALL").

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItem)
```

