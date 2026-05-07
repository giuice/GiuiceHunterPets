---
type: concept
id: CONCEPT-002
title: Hunter-Only Runtime Initialization
created: 2026-05-07
updated: 2026-05-07
tags: [architecture, release]
sources:
  - GiuiceHunterPets.toc
  - GiuiceHunterPets.lua
  - Data.lua
  - Settings.lua
  - MapPetIndex.lua
  - StablePetList.lua
  - StableMastersData.lua
  - StableMasterIndex.lua
  - StableMasterPins.lua
  - GiuiceWorldMapButton.lua
  - GiuiceTooltipEnhancement.lua
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
---

# CONCEPT-002: Hunter-Only Runtime Initialization

## Definition

GiuiceHunterPets is installed as a normal WoW addon, but its runtime features are intended only for Hunter characters. Because the `.toc` executes each Lua file independently and in order, an early `return` in one file only stops that file. It does not stop later or earlier `.toc` files from registering settings, frames, data tables, slash commands, map pins, or tooltip hooks.

The current implementation therefore places lightweight class guards in modules with runtime side effects:

```lua
if UnitClass and select(3, UnitClass("player")) ~= 3 then
    return
end
```

The `UnitClass` existence check keeps local Lua tests usable outside the WoW client, where the WoW API is not defined.

## Current Understanding

The broad guard is required because several important files run before or outside `GiuiceHunterPets.lua` in `GiuiceHunterPets.toc`. In particular, `Settings.lua`, `Data.lua`, `StableMastersData.lua`, index builders, mixins, and secondary UI modules can perform observable setup before the main addon file gets a chance to return.

For non-Hunter characters, the addon may still appear as installed in the WoW AddOns list, but runtime behavior should not initialize pet data, stable master data, settings categories, map pins, tooltip hooks, or UI frames.

The current approach is intentionally surgical. A cleaner future architecture would use a tiny loader addon plus a `LoadOnDemand` runtime addon, so non-Hunters never load the heavy data files at all. Until that split exists, per-module guards are the safer behavior for `.toc`-loaded files with side effects.

## Verification

Local verification should include:

- `luac -p` over the runtime Lua files to catch syntax regressions.
- Lua tests for pure modules, with no global `UnitClass` required.
- Manual in-game checks on a Hunter and a non-Hunter, because local Lua tests cannot prove WoW `.toc` loading behavior, settings registration, tooltip hooks, or map pin registration.

## Related Pages

- [[pet-map-pins]] — pet pin filtering and map index behavior protected by the runtime guard
- [[stable-master-pins]] — stable master map and minimap behavior protected by the runtime guard
- [[addon-staging-script]] — release staging workflow for copying runtime files into a WoW addon folder
