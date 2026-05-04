# PRD: Stable Master Pins

## 1. Introduction / Overview

GiuiceHunterPets already has a working scraper/export pipeline for stable master data, but the generated data is not yet loaded or rendered by the addon. This feature adds stable master map pins for Hunter characters so players can find usable stable masters without leaving the existing addon map workflow.

The feature should mirror the proven tameable-pet pin behavior where practical, while keeping stable masters as a separate data table, index, rendering module, and setting. Stable master pins are enabled by default for Hunters, shown on both the world map and minimap, and filtered to stable masters usable by the player's faction.

## 2. Goals

- Generate and ship `StableMastersData.lua` from the existing stable master pipeline.(Already generated: `/StableMastersData.lua`)
- Load stable master data in the addon with correct TOC order.
- Render stable master pins on the world map and minimap for Hunter characters.
- Filter stable master pins to the player's faction plus neutral stable masters if neutral records represent usable stable masters.
- Provide one settings toggle that enables or disables stable master pins on both world map and minimap.
- Keep stable master data and pin behavior independent from tameable-pet data, pet pin settings, and pet pin HBD-Pins keys.
- Update release-facing documentation to describe the shipped feature and keep the data refresh runbook accurate.

## 3. User Stories

- As a Hunter, I want to see nearby stable masters on the minimap so I can quickly find one while moving through a zone.
- As a Hunter, I want to see stable masters on the world map so I can plan where to manage my stable before traveling.
- As a Hunter, I only want to see stable masters that are useful to my character's faction, so the map does not show irrelevant opposing-faction NPCs.
- As a player who prefers a less cluttered map, I want a setting that turns stable master pins off immediately.
- As a maintainer, I want stable master pins to use a separate data table and renderer so future stable master changes do not risk pet pin regressions.

## 4. Functional Requirements

1. The addon must include a generated root-level `StableMastersData.lua` file that defines `GHP.stable_masters`.
2. `StableMastersData.lua` records must include `npcID`, `name`, `zone_name`, `zoneID`, `coords`, and `faction`.
3. `GiuiceHunterPets.toc` must load `StableMastersData.lua` after core addon namespace initialization is available and before any stable master pin renderer reads `GHP.stable_masters`.
4. The addon must include stable master indexing helpers that group stable masters by `zoneID`.
5. The addon must render stable master pins on the current world map when stable master pins are enabled.
6. The addon must render stable master pins on the minimap for the player's current zone when stable master pins are enabled.
7. Stable master pins must use HBD-Pins references that do not collide with pet pin references.
8. Stable master pins must be shown only for Hunter characters, matching the existing pet pin class guard.
9. Stable master pins must be enabled by default for new users through `GHP_SavedVars.stableMasterPins = true` or equivalent nil-safe behavior.
10. The settings panel must expose one checkbox labeled for stable master pins.
11. Toggling the stable master pin setting off must remove existing world map and minimap stable master pins without affecting pet pins.
12. Toggling the stable master pin setting on must refresh world map and minimap stable master pins without requiring `/reload`.
13. Pin tooltips must show at least the stable master's name, "Stable Master", zone name, and faction.
14. The renderer must filter stable masters by the player's faction. Alliance characters should not see Horde-only stable masters; Horde characters should not see Alliance-only stable masters.
15. Neutral stable masters should be shown only if the data record's `faction = "Neutral"` is intended to mean the NPC is usable by both factions. If this is not guaranteed by the source data, neutral handling must be validated before shipping or treated as an open implementation decision.
16. The stable master feature must not change existing pet pin world map filtering, minimap behavior, tooltip behavior, or saved variables.
17. `docs/desc-curse.md` must mention stable master pins in the feature list and changelog/what's-new copy.
18. `docs/research/data-refresh-runbook.md` must remain accurate for stable master collection, build, and promotion. If already mostly updated, the implementation should only add missing stable-master locked-in or promotion details instead of rewriting unrelated sections.

## 5. Non-Goals

- Do not merge stable masters into `GHP.pet_by_zones`.
- Do not show stable masters in the pet list UI.
- Do not add stable master search, routing, distance sorting, or custom filters in this version.
- Do not implement per-map separate toggles for world map versus minimap stable master pins.
- Do not alter the existing pet pin setting values or defaults.
- Do not replace HereBeDragons or update vendored libraries as part of this feature.
- Do not start a broader map pin refactor unless required to prevent a stable master regression.

## 6. Design Considerations

- Use a stable master icon or texture that is recognizable at small minimap sizes.
- Faction color can be used as a visual cue, but faction filtering is required and is not a substitute for filtering.
- Pin sizes should be close to the existing pet pin scale: large enough for hover/click targeting, small enough to avoid excessive map clutter.
- Tooltip content should stay compact and use existing GameTooltip conventions.
- Stable master pins should feel like part of the existing map feature, not a separate UI surface.

## 7. Technical Considerations

- Existing patterns to mirror:
  - `MapPetIndex.lua` for map-index helper shape.
  - `GiuiceWorldMapButton.lua` for HBD-Pins world map and minimap rendering.
  - `Settings.lua` for `Settings.RegisterProxySetting` usage.
  - `GiuiceHunterPets.toc` for explicit load order.
- The stable master export is produced by `scrapper.refresh_data_v_fast build-stable-masters` and `scrapper/lua_export.py`.
- Stable masters have no shipped fallback baseline. The runbook and PRD acceptance should treat zero-record output or validation errors as a release blocker.
- The implementation should cache/rebuild the stable master map index only when `GHP.stable_masters` changes, matching the pet index source pattern.
- Faction filtering needs a clear mapping from `UnitFactionGroup("player")` to record `faction` values.
- The implementation should verify whether `"Neutral"` records are actually usable by both factions before including them. If source data uses neutral only for NPC reaction ambiguity, neutral pins may need to be excluded until reviewed.
- In-game verification is required because Lua API availability, texture paths, and HBD-Pins rendering cannot be fully validated by Python unit tests.

## 8. Success Metrics

- `StableMastersData.lua` exists at the addon root and contains `GHP.stable_masters = {`.
- The TOC includes `StableMastersData.lua`, `MapStableMasterIndex.lua`, and `GiuiceStableMasterPins.lua` in a load order that prevents nil reads.
- Opening the world map in a zone with faction-appropriate stable masters shows stable master pins.
- Moving into a zone with faction-appropriate stable masters shows stable master minimap pins.
- Opposing-faction stable masters are not shown.
- The settings checkbox removes and restores stable master pins immediately.
- Pet pins still render and toggle as before.
- Stable master pin tooltips show name, stable master label, zone, and faction.
- Relevant automated tests for exporter/index helper behavior pass, and manual in-game checks cover world map, minimap, tooltip, toggle, and faction filtering.

## 9. Open Questions

- Does the stable master data source guarantee that `faction = "Neutral"` means both factions can use that stable master? If not, neutral records should be manually reviewed or excluded from v1 pins.
- What exact texture path or atlas should be used if `Interface\\MINIMAP\\Tracking\\StableMaster` is unavailable in the current client?
- Should the generated `StableMastersData.lua` be committed together with the feature code, or generated as a release step after code lands?
