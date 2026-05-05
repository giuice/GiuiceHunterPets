# Tasks — 0002 PRD Pet Pin Filters and Instance Stable Fallback

Source PRD: `0002-prd-pet-pin-filters-and-instance-stable-fallback.md`

## Relevant Files

- `Settings.lua` — clean up pet world map dropdown labels, add a separate `Rare Elite` filter option, and verify dropdown callback refresh behavior.
- `MapPetIndex.lua` — keep `Rare`, `Elite`, and `Rare Elite` as separate filter modes.
- `GiuiceWorldMapButton.lua` — verify immediate pet pin refresh paths, especially disabled world map pet pins and minimap pet pin cleanup.
- `StablePetList.lua` — adjust stable list state selection and empty/status messages for active-pet fallback when full stable data is unavailable.
- `GiuiceHunterPets.lua` — confirm existing stable/active pet API flow continues to pass both lists into `StablePetList.lua`.
- `SavedVars.lua` — confirm existing `worldMapPins` values remain compatible; implementation changes should not require saved-variable migration.
- `tests/map_pet_index_test.lua` — add/update rare, elite, rare elite, disabled, and missing-map filter coverage.
- `tests/stable_list_state_test.lua` — add/update loaded, nil-stabled active fallback, empty, unloaded, and search behavior coverage.

## Context

The implementation should stay focused on pet pin filters and stable pet list fallback behavior. Stable master pins must remain untouched: do not change stable master settings, data, indexes, renderers, faction filtering, or HBD-Pins keys.

User override after implementation review: `Rare Elite` must not be merged into `Rare` or `Elite`. Add a separate `Rare Elite Pet Pins` option instead.

Existing architecture already routes pet world map and minimap filtering through `MapPetIndex.lua` / `GetPetsForMap`, and `GiuiceHunterPets.lua` already retrieves both `C_StableInfo.GetStabledPetList()` and `C_StableInfo.GetActivePetList()` before delegating list-state decisions. Prefer fixing the existing state and filtering logic instead of adding new settings, saved variable values, or persistent stable caches.

## Reusable Utilities, Patterns, and Constraints

- Preserve existing `GHP_SavedVars.worldMapPins` values: `1` all pets, `2` rare pets, `3` elite pets, `4` disabled pet pins. Use `5` for the new `Rare Elite` filter.
- Reuse the existing `MapPetIndex.lua` filter-mode mapping rather than introducing a new minimap-specific filter.
- Reuse existing settings registration/callback patterns in `Settings.lua`.
- Reuse existing stable list rendering, search, pet details, and ability display paths in `StablePetList.lua`.
- Treat `Rare Elite` as a separate filter mode.
- Disabled pet pins should prevent pet pins from being added and should clear visible pet pins promptly.
- Stable master pins are independent and must not be affected by any pet pin filter changes.
- Automated Lua tests should cover deterministic state/filter behavior; in-game verification is still required for Blizzard API behavior inside instances.

## Parent Tasks

1. **Clean up pet pin setting labels without changing saved values**
   - [x] 1.1 Update `Settings.lua` dropdown labels to clear English text:
     - `All Pet Pins`
     - `Rare Pet Pins`
     - `Elite Pet Pins`
     - `Rare Elite Pet Pins`
     - `Disable Pet Pins`
   - [x] 1.2 Keep the existing dropdown under the pet world map pin setting.
   - [x] 1.3 Preserve the existing `worldMapPins` numeric values and default behavior.
   - [x] 1.4 Verify no stable master setting labels or saved variables are touched.

2. **Keep rare, elite, and rare elite pet filtering separate**
   - [x] 2.1 Update `MapPetIndex.lua` so rare mode includes only pets classified as `Rare`.
   - [x] 2.2 Update `MapPetIndex.lua` so elite mode includes only pets classified as `Elite`.
   - [x] 2.3 Add a separate `Rare Elite` filter mode for pets classified as `Rare Elite`.
   - [x] 2.4 Keep all-pets and disabled-pets behavior unchanged.
   - [x] 2.5 Avoid scraper or generated data changes unless implementation proves the shipped classification value is not actually `Rare Elite`.

3. **Verify immediate world map and minimap pet pin refresh behavior**
   - [ ] 3.1 Confirm changing the pet pin dropdown refreshes visible world map pet pins without `/reload`.
   - [x] 3.2 Confirm minimap pet pins continue to use the shared `GetPetsForMap` filtering path when minimap pet pins are enabled.
   - [x] 3.3 Check the disabled setting path carefully so disabling pet pins clears visible pet minimap pins immediately when needed.
   - [x] 3.4 Ensure these refresh changes do not call stable master pin refresh functions or alter stable master pin state.

4. **Implement active-pet fallback when full stable data is unavailable**
   - [x] 4.1 Update `StablePetList.lua` state selection so `nil` or unavailable stabled pets can fall back to active pets when active pets exist.
   - [x] 4.2 Continue to prefer the full stabled pet list whenever `GetStabledPetList()` returns one or more pets.
   - [x] 4.3 Preserve existing behavior for a genuinely empty state when no stabled pets and no active pets are available.
   - [x] 4.4 Keep existing search by name, family, and level working against whichever list is displayed.
   - [x] 4.5 Keep pet detail and ability display behavior working for active-pet fallback entries.

5. **Clarify stable list status messages for limited contexts**
   - [x] 5.1 Add or adjust the active-only fallback message to explain that only active pets are currently available because full stable data may be unavailable in the current context.
   - [x] 5.2 Avoid wording that implies visiting a stable master is the only possible fix when the player is in an instance.
   - [x] 5.3 Keep the message concise enough for the existing stable pet viewer empty/status area.
   - [x] 5.4 Do not add new modals, alerts, localization systems, or persistent cache behavior.

6. **Add focused regression tests**
   - [x] 6.1 Update `tests/map_pet_index_test.lua` to cover:
     - all-pets mode includes normal, rare, elite, and rare elite records
     - rare mode includes only `Rare`
     - elite mode includes only `Elite`
     - rare elite mode includes only `Rare Elite`
     - disabled mode returns no pet pins
     - missing-map or unrelated-map behavior remains unchanged
   - [x] 6.2 Update `tests/stable_list_state_test.lua` to cover:
     - full stable list is preferred when available
     - nil/unavailable stabled pets with active pets uses active-only fallback
     - empty stabled pets with active pets still uses active-only fallback
     - no stabled pets and no active pets shows the appropriate empty/unloaded state
     - search filters the currently displayed fallback list
   - [x] 6.3 Keep test fixtures minimal and scoped to the changed behavior.

7. **Perform verification and in-game checks**
   - [x] 7.1 Run the existing Lua test suite after implementation.
   - [ ] 7.2 Verify settings dropdown labels in-game.
   - [ ] 7.3 Verify the separate rare elite filter includes known `Rare Elite` tameable pets on the world map.
   - [ ] 7.4 Toggle pet filter modes in-game and confirm world map pins refresh without `/reload`.
   - [ ] 7.5 With minimap pet pins enabled, verify minimap pet pins reflect the current world map pet filter.
   - [ ] 7.6 Disable pet pins and confirm pet world map and minimap pins clear.
   - [ ] 7.7 Confirm stable master pins remain visible/configurable according to their own setting and are not affected by pet filter changes.
   - [ ] 7.8 In an instance or other limited context, open the pet viewer and confirm active pets appear when full stable data is unavailable.
