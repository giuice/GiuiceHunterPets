---
type: entity
id: ENTITY-001
title: Stable Master Pins
name: Stable Master Pins
created: 2026-05-04
updated: 2026-05-05
tags: [architecture, testing, release]
sources:
  - .codewiki/tasks/0001-prd-stable-master-pins.md
  - .codewiki/tasks/tasks-0001-prd-stable-master-pins.md
  - StableMasterPins.lua
  - StableMasterIndex.lua
  - tests/stable_master_index_test.lua
  - tests/stable_master_pins_settings_test.lua
status: active
key_files:
  - GiuiceHunterPets.toc
  - StableMastersData.lua
  - StableMasterIndex.lua
  - StableMasterPins.lua
  - Settings.lua
  - SavedVars.lua
  - tests/stable_master_index_test.lua
  - tests/stable_master_pins_settings_test.lua
file_hashes: {}
linked_issues: []
linked_lessons:
  - lessons/data-refresh-pipeline.md
confidence: medium
contested: false
contradictions: []
verified_by: human
approved: true
---

# ENTITY-001: Stable Master Pins

## Purpose

Stable Master Pins add Hunter-only world map and minimap pins for stable master NPCs. The feature lets Hunters find stable masters from the existing map workflow without mixing stable master data into pet data structures.

The implementation deliberately keeps stable masters independent from tameable pet pins: separate source data, separate zone index, separate renderer, separate settings key, and separate HereBeDragons-Pins keys.

## Key Files

- `StableMastersData.lua` defines `GHP.stable_masters` from the stable master data pipeline.
- `StableMasterIndex.lua` groups stable master records by `zoneID` and rebuilds only when the `GHP.stable_masters` table reference changes.
- `StableMasterPins.lua` renders world map and minimap pins, applies Hunter and faction guards, handles tooltips, and owns stable-master-specific HBD-Pins keys.
- `Settings.lua` exposes the `Show Stable Master Pins` checkbox through `Settings.RegisterProxySetting`.
- `SavedVars.lua` sets the fallback `stableMasterPins = true` default.
- `GiuiceHunterPets.toc` loads `StableMastersData.lua`, `StableMasterIndex.lua`, and `StableMasterPins.lua` before the existing pet map renderer.

## Current Behavior

`StableMasterPins.lua` exits early for non-Hunter characters by checking `select(3, UnitClass("player"))`. For Hunters, it renders stable masters on the current world map and minimap when `GHP_SavedVars.stableMasterPins ~= false`.

Stable master pins use these independent HBD-Pins keys:

- `GiuiceHunterPetsStableMasterIcons` for world map pins
- `GiuiceHunterPetsStableMasterMinimapIcons` for minimap pins

This separation is important because pet pins use their own keys and should not be removed or refreshed when stable master pins are toggled.

## Filtering And Tooltip

Faction filtering compares each record's `faction` field to `UnitFactionGroup("player")`. Opposing-faction stable masters are hidden. Neutral records are visible to both factions by the v1 decision in [[stable-master-neutral-faction]].

Pin tooltips include the stable master's name, `Stable Master`, zone name, and faction. Automated tests cover this tooltip contract using a Lua WoW API stub.

## Verification

Automated coverage:

- `tests/stable_master_index_test.lua` checks zone grouping, ignored records without `zoneID`, and cache invalidation when `GHP.stable_masters` changes.
- `tests/stable_master_pins_settings_test.lua` checks immediate toggle refresh, independent HBD-Pins keys, pet setting isolation, faction filtering, and tooltip content.

Manual in-game checks remain required before release because HBD-Pins rendering, minimap behavior, WoW frame APIs, and texture availability cannot be fully validated by the local Lua tests.

## Open Questions

- Confirm in-game that `Interface\\Icons\\Ability_Hunter_BeastCall` renders acceptably as the stable master pin icon.
- Confirm Horde and Alliance manual checks pass in zones that contain faction-specific and Neutral stable master records.

## Related Pages

- [[data-refresh-pipeline]] — stable master source collection, validation, and release checks
