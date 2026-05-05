# Tasks — 0001 PRD Stable Master Pins

Source PRD: `0001-prd-stable-master-pins.md`

## Relevant Files

- `GiuiceHunterPets.toc` — load order for addon modules and data files.
- `Settings.lua` — addon settings registration and stable-master toggle.
- `SavedVars.lua` — fallback saved-variable defaults.
- `StableMastersData.lua` — stable master source data attached to `GHP.stable_masters`.
- `StableMasterIndex.lua` — dedicated zone index and cache invalidation helper for stable masters.
- `StableMasterPins.lua` — independent stable-master world map and minimap renderer with separate HBD-Pins keys.
- `docs/desc-curse.md` — release-facing feature, what's-new, and changelog copy for stable master pins.
- `docs/research/data-refresh-runbook.md` — stable-master promotion expectations and required in-game verification notes.
- `tests/stable_master_index_test.lua` — regression check for zone grouping and source-based rebuilds.
- `tests/stable_master_pins_settings_test.lua` — regression check for immediate stable-master setting refresh, faction filtering, tooltip content, and independent pin keys.

## Context

`StableMastersData.lua` already exists at the repository root and defines `GHP.stable_masters`, so the remaining work is to wire the data into the addon safely and ship the feature without regressing existing pet pins. The implementation should mirror proven pet-pin patterns where useful, while keeping stable masters independent in data indexing, rendering, settings, and HBD-Pins keys.

Neutral stable master records are treated as visible to both factions for v1 pins. This is an explicit release decision because the current task context does not provide stronger source confirmation beyond the exported `faction = "Neutral"` field.

## Parent Tasks

1. **Add stable master data loading and index helpers**
   - Update `GiuiceHunterPets.toc` so `StableMastersData.lua` loads after addon namespace setup and before any stable-master renderer reads `GHP.stable_masters`.
   - Add a dedicated stable-master index module, following the `MapPetIndex.lua` pattern, to group records by `zoneID` and rebuild only when `GHP.stable_masters` changes.
   - Verify the index can be built without touching pet data structures or pet-pin HBD keys.

2. **Implement independent stable master world map and minimap rendering**
   - Create a dedicated stable-master pin renderer that mirrors the proven `GiuiceWorldMapButton.lua` event and HBD-Pins flow without folding stable masters into the pet-pin module.
   - Render stable master pins on both the world map and minimap for Hunter characters only, using separate HBD-Pins references from the pet feature.
   - Verify pins appear in zones with known stable masters and that pet pins continue to behave exactly as before.

3. **Add stable master settings with immediate refresh behavior**
   - Add a `stableMasterPins` saved-variable default and expose one settings checkbox in `Settings.lua` using the existing `Settings.RegisterProxySetting` pattern.
   - Ensure toggling the setting removes or restores stable master pins on both world map and minimap immediately, without requiring `/reload`.
   - Verify the toggle does not affect pet world-map filtering, pet minimap pins, or other saved variables.

4. **Implement faction filtering and resolve neutral-record handling**
   - Add filtering so Alliance hunters do not see Horde-only stable masters and Horde hunters do not see Alliance-only stable masters.
   - Validate whether `faction = "Neutral"` means the stable master is usable by both factions; if that cannot be confirmed from the current source, treat neutral handling as an explicit release decision and document the chosen behavior.
   - Verify tooltip content includes stable master name, stable-master label, zone, and faction for the records that remain visible after filtering.

5. **Finish release-facing docs and in-game verification notes**
   - Update `docs/desc-curse.md` so the feature list and what's-new/changelog copy mention stable master pins.
   - Refine `docs/research/data-refresh-runbook.md` only where needed so stable-master collection, build, promotion, and release-blocker expectations remain accurate.
   - Capture the required in-game verification coverage for world map, minimap, tooltip, toggle refresh, faction filtering, and any icon/texture fallback needed if the preferred stable-master texture is unavailable.

## Manual In-game Verification Required

- Horde Hunter: confirm Horde and Neutral stable master pins render on world map and minimap; Alliance-only pins do not render.
- Alliance Hunter: confirm Alliance and Neutral stable master pins render on world map and minimap; Horde-only pins do not render.
- Confirm each visible pin tooltip includes stable master name, `Stable Master`, zone, and faction.
- Toggle `Show Stable Master Pins` off and on; stable master world-map and minimap pins should disappear and return without `/reload`.
- Confirm pet world-map filter and pet minimap toggle still affect only pet pins.
- Confirm `Interface\\Icons\\Ability_Hunter_BeastCall` renders correctly; choose a fallback before release if the client shows a missing texture.

## Subtask Progress

- [x] 1. Add stable master data loading and index helpers
- [x] 2. Implement independent stable master world map and minimap rendering
- [x] 3. Add stable master settings with immediate refresh behavior
- [x] 4. Implement faction filtering and resolve neutral-record handling
- [x] 5. Finish release-facing docs and in-game verification notes
