# PRD: Pet Pin Filters and Instance Stable Fallback

## 1. Introduction / Overview

GiuiceHunterPets currently exposes pet pin settings and a stable pet list window, but two user-facing gaps need careful treatment before implementation.

First, the settings menu should make rare and elite pet pin filtering clear and reliable. `Settings.lua` already exposes world map dropdown options for all pets, rare pets, elite pets, and disabled pins, and `MapPetIndex.lua` already filters by `Rare` and `Elite`. This feature should validate and improve that menu behavior without changing unrelated settings or stable master pin behavior.

Second, opening the pet viewer in an instance can show a message that asks the player to visit a stable master first, even when the player previously had stable pets visible. The feature should avoid a confusing empty/unloaded state where possible by showing active pets when full stable data is unavailable, while making the instance limitation explicit.

## 2. Goals

- Make the pet pin filter options for rare and elite pets clear in the settings menu.
- Verify that rare and elite world map filters refresh immediately and continue to affect minimap pet pins through the existing shared filtering path.
- Support `Rare Elite` pet classification deliberately so rare/elite filtering does not silently miss important tameable pets.
- Improve the stable pet list behavior when full stable data is unavailable in instances.
- Show active pets as a fallback when full stable pets cannot be loaded and active pets are available.
- Display a clear, non-alarming message explaining that the full stable may be unavailable in the current instance/context.
- Avoid regressions to stable master pins, pet tooltip rendering, saved variables, or existing pet list search behavior.

## 3. User Stories

- As a Hunter, I want to choose rare or elite pet pins from the addon settings so my map is less cluttered.
- As a Hunter, I want rare and elite map filters to include pets whose classification combines rare and elite traits when appropriate.
- As a Hunter, I want setting changes to update pins without requiring `/reload`.
- As a Hunter in an instance, I want the pet viewer to show my active pets if the full stable list is unavailable.
- As a Hunter in an instance, I want the addon to explain that only active pets are being shown because full stable data cannot currently be accessed.
- As a maintainer, I want these changes covered by focused tests so map filtering and stable list state behavior remain stable.

## 4. Functional Requirements

1. The settings panel must keep a pet pin dropdown under the existing pet world map pin setting.
2. The dropdown must include options for all pet pins, rare pet pins, elite pet pins, and disabled pet pins.
3. The option labels must be clear English and avoid awkward wording such as "Rares Pets Pins".
4. The implementation must preserve existing saved variable values for `GHP_SavedVars.worldMapPins`: `1` for all pets, `2` for rare pets, `3` for elite pets, and `4` for disabled pins.
5. Changing the pet pin dropdown must refresh visible world map pins without requiring `/reload`.
6. Changing the pet pin dropdown must refresh minimap pet pins when minimap pet pins are enabled, matching the current shared `GetPetsForMap` behavior.
7. The rare pet filter must include pets classified as `Rare`.
8. The rare pet filter must also include pets classified as `Rare Elite`, unless implementation research proves the data uses another canonical value for rare elite pets.
9. The elite pet filter must include pets classified as `Elite`.
10. The elite pet filter must also include pets classified as `Rare Elite`.
11. Disabled pet pins must continue to remove pet world map pins and prevent pet minimap pins from being added through the pet filter path.
12. Stable master pins must not be affected by pet pin filter changes.
13. The pet viewer must continue to prefer the full stable pet list when `C_StableInfo.GetStabledPetList()` returns one or more pets.
14. If the full stable pet list is unavailable or empty and active pets are available, the pet viewer must show active pets as a fallback.
15. When active pets are shown as fallback in an instance or other limited context, the empty/status message must clearly say that only active pets are currently available and that full stable data may require leaving the instance or opening a stable master.
16. If no full stable pets and no active pets are available, the pet viewer may continue to show an empty/unloaded message, but the wording should not imply a stable visit is the only possible cause when the player is in an instance.
17. Existing search by name, family, and level must continue to filter whichever list is currently displayed.
18. Existing pet details and ability display must continue to work for active pet fallback entries.

## 5. Non-Goals

- Do not implement this PRD during the PRD step.
- Do not redesign the full settings panel.
- Do not add new saved variable values for additional pet pin modes unless required by implementation research.
- Do not add separate minimap-only rare/elite settings in this version.
- Do not change stable master pin settings, faction filtering, or HBD-Pins keys.
- Do not replace Blizzard stable APIs or add a custom persistent stable cache in this version.
- Do not change the pet data scraper unless implementation proves the shipped classification values are wrong.
- Do not localize the new setting/message text in this PRD unless the implementation phase explicitly includes localization work.

## 6. Design Considerations

- Settings labels should be short and readable in the native WoW settings UI.
- Suggested labels:
  - `All Pet Pins`
  - `Rare Pet Pins`
  - `Elite Pet Pins`
  - `Disable Pet Pins`
- The active-pet fallback message should be concise and fit the existing empty-state area in the pet viewer.
- The message should distinguish "full stable data unavailable right now" from "you have no pets".
- The UI should not add another modal, alert, or confirmation for this state.

## 7. Technical Considerations

- Relevant files:
  - `Settings.lua` for dropdown labels and settings callbacks.
  - `SavedVars.lua` for default saved variable compatibility.
  - `MapPetIndex.lua` for map pet classification filtering.
  - `GiuiceWorldMapButton.lua` for immediate pin refresh behavior.
  - `StablePetList.lua` for stable list state selection and messages.
  - `GiuiceHunterPets.lua` for pet list update flow and active/full stable API calls.
  - `tests/map_pet_index_test.lua` for rare, elite, rare elite, disabled, and missing-map filtering.
  - `tests/stable_list_state_test.lua` for loaded, unloaded, active-only, empty, and search behavior.
- `MapPetIndex.lua` currently maps setting values to `allpets`, `rarepets`, `elitepets`, and `nopets`.
- `MapPetIndex.lua` currently matches exact `petData.class == "Rare"` or `"Elite"`, which likely excludes `"Rare Elite"` records present in generated data.
- `StablePetList.lua` already has an `active-only` state when `stabledPets` is an empty table and active pets exist. Implementation should verify whether instance behavior returns `nil` instead of `{}` for `GetStabledPetList()` and adjust fallback logic carefully if needed.
- `GiuiceHunterPets.lua` calls `C_StableInfo.GetStabledPetList()` and `C_StableInfo.GetActivePetList()` before delegating to `GetStablePetListState`, making `StablePetList.lua` the preferred place for state logic.
- Automated Lua tests can cover classification filtering and state selection, but in-game verification is still required for actual Blizzard API behavior in instances.

## 8. Success Metrics

- The settings dropdown shows clear rare and elite pet pin labels.
- Existing saved variables continue to map to the same behavior after the label/filter improvement.
- `GetPetsForMap` returns `Rare Elite` pets for both rare and elite filter modes.
- World map pet pins refresh after changing the dropdown.
- Minimap pet pins reflect the current world map pet filter when minimap pins are enabled.
- Stable master pins remain independent and unaffected.
- In an instance where full stable data is unavailable but active pets are available, the pet viewer displays active pets.
- The pet viewer message clearly explains that only active pets are shown because full stable data is unavailable in the current context.
- Existing tests pass, and focused tests are added or updated for rare elite filtering and active-pet fallback.

## 9. Open Questions

- In the current WoW client, does `C_StableInfo.GetStabledPetList()` return `nil` or `{}` inside instances after full stable data was previously available?
- Should the instance/limited-context message explicitly mention "instance", or should it stay generic to cover any context where Blizzard returns no full stable data?
- Should the active-pet fallback message be localized immediately, or is English-only acceptable for this focused change?
