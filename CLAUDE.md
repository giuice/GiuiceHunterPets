# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GiuiceHunterPets is a World of Warcraft addon for hunters. It lists stabled pets in a custom frame, shows pet details with a 3D model viewer, enhances unit tooltips with tamability info, and displays tameable-pet pins on the world map and minimap.

There is no build system, package manager, or automated test suite. The addon is written entirely in Lua and XML, loaded directly by the WoW client.

## Development Workflow

- **No build step.** Changes are live after `/reload` in-game.
- **Verify Lua errors** in the WoW client error frame or via a bug-catching addon (e.g., BugSack).
- **Testing** is done manually in-game on a Hunter character. Many files early-return if the player is not a Hunter (`select(3, UnitClass("player")) ~= 3`).
- **VSCode setup:** The workspace uses the Ketho wow-api extension for Blizzard API annotations (`Lua.workspace.library` points to `~/.vscode/extensions/ketho.wow-api-*/Annotations/Core`).

## Architecture

### Load Order and TOC

`GiuiceHunterPets.toc` defines the exact load order. Every Lua/XML file must be listed there or it will not be loaded by the client. The addon targets multiple WoW versions (retail and classic eras), reflected in the multi-interface header.

Key sections in the TOC:
1. **Libraries** (`Libs/…`) – vendored Ace/Blizzard libraries (LibStub, CallbackHandler, AceLocale, LibDataBroker, LibDBIcon, HereBeDragons).
2. **Locales** (`locales/locales.xml`)
3. **Templates** (`GiuiceHunterPets.xml`, `GiuiceHunterPetListItemMixin.lua`, `GiuiceWorldMapButton.lua`)
4. **Core** (`Localization.lua`, `Data.lua`, `GiuiceHunterPets.lua`, `GiuiceBattlePets.lua`, `GiuiceTooltipEnhancement.lua`)

### Addon Namespace

All core Lua files receive the addon namespace via:

```lua
local addonName, GHP = ...
```

Shared state and utilities are stored on the `GHP` table (e.g., `GHP.utils`, `GHP.frames`, `GHP.FAMILY_DATA`, `GHP.pet_by_zones`).

Saved variables are stored in the global `GHP_SavedVars` table, declared in the TOC (`## SavedVariables: GHP_SavedVars`) and initialized in `Settings.lua`.

### UI Architecture

- **XML Templates** (`GiuiceHunterPets.xml`) define virtual frame/button templates with mixins.
- **Lua Mixins** (`GiuiceHunterPetListItemMixin.lua`) implement the template behavior (e.g., `GiuiceHunterPetListItemMixin:OnClick`, `GiuiceHunterActivePetListMixin:Refresh`).
- **Main Frame** (`GiuiceHunterPets.lua`) creates the primary window programmatically with `CreateFrame`, including the scroll list, search box, dropdown, and detail panel with a `ModelScene`.
- **Active Pet List** is rendered as a template (`GiuiceHunterActivePetListTemplate`) inside the detail panel; it shows the 5 call-pet slots plus a conditional Beast Mastery secondary-pet slot.

### Data Layer

- `Data.lua` contains large static lookup tables:
  - `GHP.FAMILY_DATA[familyID]` – diet, pet type, exotic flag, and ability list.
  - `GHP.pet_by_zones` – array of tameable pets with zone IDs, coordinates, classification, and display ID.
  - `GHP.specSkills` and `GHP.specColors` – mapping from specialization name to spells/color strings.
- `Localization.lua` builds `GHP.exoticFamilies` from a small localized name table to determine whether a family is exotic at runtime.

### Map Pins

`GiuiceWorldMapButton.lua` handles both world-map and minimap pins:
- Uses **HereBeDragons** (`LibStub("HereBeDragons-2.0")`) and **HereBeDragons-Pins-2.0** for coordinate translation and pin management.
- World-map pins are created on the `WorldMapFrame` canvas and filtered by a setting (All / Rare / Elite / Disabled).
- Minimap pins are created as frames parented to `Minimap` and updated on zone-change events.
- The tooltip for map pins embeds a `PlayerModel` (`GHPTooltipModel`) to preview the pet.

### Settings

`Settings.lua` registers a vertical-layout category in the WoW Settings panel:
- Uses `Settings.RegisterProxySetting` with getters/setters backed by `GHP_SavedVars`.
- Changing the world-map pin setting triggers `GHP.OnWorldMapPinsSettingChanged`, which adds/removes pins and hooks/unhooks `WorldMapFrame` events.

### Tooltip Enhancement

`GiuiceTooltipEnhancement.lua` hooks `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, …)` to append lines showing:
- Creature family and classification
- Whether the beast is tameable (with exotic/Beast-Mastery gating)
- Creature ID

## Important Constraints

- **Library updates:** `important-readme.md` documents the safe process for updating vendored libraries. The folder structure inside `Libs/` must match the paths in the TOC exactly. Extra nested folders or embedded duplicate libraries will break loading.
- **Class guard:** Most files immediately return if the player is not a Hunter. This means some code paths are unreachable on non-Hunter characters.
- **Icon assets:** Pet family icons are expected at `icons/PetIcons/32x32/<FamilyName>.blp`. Missing textures fall back to Blizzard atlas names derived from the family name.

## External References

- `important-readme.md` – step-by-step guide for updating libraries without breaking the addon.
- `AGENTS.md` – behavioral guidelines for coding in this repository (simplicity, surgical changes, goal-driven execution).
