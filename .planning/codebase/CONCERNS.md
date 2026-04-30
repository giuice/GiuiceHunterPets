# Codebase Concerns

**Analysis Date:** 2026-04-29

## Tech Debt

**Refresh pipeline has two active command shapes:**
- Issue: `scrapper/refresh_data.py` keeps deprecated `pets` and `stable-masters` aliases beside the newer `collect-*` and `build-*` commands. The aliases are wired to cache-only generation with `from_cache=True`, while their parser options still expose `--resume` and `--reset-cache` as deprecated flags.
- Files: `scrapper/refresh_data.py:211`, `scrapper/refresh_data.py:221`, `scrapper/refresh_data.py:237`, `scrapper/refresh_data.py:273`
- Impact: Callers can choose commands that look like collection/generation shortcuts but actually require cached sources. This creates confusing failure reports such as missing cached source instead of the original network error.
- Fix approach: Keep `collect-pets`, `build-pets --from-cache`, `collect-stable-masters`, and `build-stable-masters --from-cache` as the only documented entry points. Either remove deprecated aliases after a compatibility window or make their behavior explicit in help and tests.

**Generated pet data is large and hand-loaded at runtime:**
- Issue: `Data.lua` is about 4.7 MB and 85,553 lines. It is loaded directly from the addon `.toc` before runtime index construction.
- Files: `Data.lua`, `GiuiceHunterPets.toc:34`, `MapPetIndex.lua:12`, `GiuiceWorldMapButton.lua:11`
- Impact: The addon pays a load-time memory and parse cost for the full pet table, then builds additional runtime indexes from it. Future data growth increases addon startup cost and map-pin memory use.
- Fix approach: Keep `Data.lua` generated only. Split generated data by expansion/region or produce precomputed indexes only if profiling shows the table load/index build dominates addon startup.

**Runtime UI code creates and discards frames instead of reusing views:**
- Issue: `GHP.utils.UpdatePetList` removes all list children and creates new `GiuiceHunterPetListItemTemplate` buttons on every search text change. `GHP.utils.ShowPetDetails` also destroys detail-panel children and creates a fresh `ModelScene` every selection.
- Files: `GiuiceHunterPets.lua:189`, `GiuiceHunterPets.lua:192`, `GiuiceHunterPets.lua:214`, `GiuiceHunterPets.lua:233`, `GiuiceHunterPets.lua:242`
- Impact: Typing in search and clicking pets can churn frames, textures, model scenes, and scripts. This is fragile in the WoW UI runtime and can cause UI lag as stable lists or active pet details grow.
- Fix approach: Reuse a fixed pool of list buttons and one detail model scene. Update text, textures, scripts, and visibility in place instead of detaching frames.

**Repository includes generated/runtime artifacts:**
- Issue: Compiled Python bytecode and the packaged addon zip are tracked. The large source cache is ignored, but `scrapper/generated/refresh-manifest.json` is also ignored while blocker reports are committed.
- Files: `scrapper/__pycache__/refresh_data.cpython-314.pyc`, `scrapper/__pycache__/source_cache.cpython-314.pyc`, `GiuiceHunterPets.zip`, `.gitignore:4`, `.gitignore:5`, `scrapper/generated/pet-refresh-blockers.md`
- Impact: Tracked artifacts create noisy diffs and can become stale relative to source. Ignoring the manifest while committing blockers makes it harder to reproduce exactly which cached sources produced a blocker.
- Fix approach: Remove tracked `__pycache__` files and package zip from version control. Commit only source, curated generated Lua, and concise blocker/runbook artifacts; keep large cache and manifest as local operational state unless a specific reproducibility policy says otherwise.

## Known Bugs

**Python test suite is failing:**
- Symptoms: `rtk python3 -m unittest discover -s tests/python` ran 68 tests with 36 failures and 1 error. Most failures expect invalidated manifest entries to use status `"error"`, but the code now records semantic invalidations as `"parse_error"`. One error comes from a mocked `generate_pets` helper that does not accept the current `from_cache` keyword.
- Files: `tests/python/test_refresh_data_cache.py`, `scrapper/source_cache.py:119`, `scrapper/source_cache.py:122`, `scrapper/refresh_data.py:273`, `scrapper/refresh_data.py:296`
- Trigger: Run `rtk python3 -m unittest discover -s tests/python`.
- Workaround: None for CI-quality verification. Decide whether `"parse_error"` is the intended manifest status and update tests/helpers, or restore the previous `"error"` contract.

**Stable master generation is blocked and not shipped into the addon:**
- Symptoms: `scrapper/generated/stable-master-blockers.md` records `https://www.wowhead.com/search?q=stable%20master: HTTP Error 403: Forbidden`. No root `StableMastersData.lua` exists, and `GiuiceHunterPets.toc` does not load stable master data.
- Files: `scrapper/generated/stable-master-blockers.md`, `scrapper/refresh_data.py:400`, `scrapper/lua_export.py:38`, `GiuiceHunterPets.toc:34`
- Trigger: Run stable master collection/generation against Wowhead without usable cached stable master search data.
- Workaround: Keep stable master rendering/data loading out of production until `scrapper/generated/StableMastersData.lua` validates and `GiuiceHunterPets.toc` explicitly loads a root `StableMastersData.lua`.

**Pet refresh currently has live blockers:**
- Symptoms: `scrapper/generated/pet-refresh-blockers.md` records a failed `agent-browser open` for `https://www.wowhead.com/npc=158226`. `scrapper/generated/pet-skipped.md` records two pets with no mapper coordinates: `213428 Aradan` and `118244 Lightning Paw`.
- Files: `scrapper/generated/pet-refresh-blockers.md`, `scrapper/generated/pet-skipped.md`, `scrapper/refresh_data.py:361`, `scrapper/refresh_data.py:367`, `scrapper/refresh_data.py:381`
- Trigger: Continue or build the pet refresh from the current source set.
- Workaround: Preserve production `Data.lua` until generated `scrapper/generated/Data.lua` validates and the skipped/blocker list is reviewed.

**Minimap pin setting can read `false` as the default `true`:**
- Symptoms: The minimap setting getter returns `GHP_SavedVars.minimapPins or defaultValue`, so a saved `false` value displays/reads as `true`.
- Files: `Settings.lua:66`, `Settings.lua:68`, `Settings.lua:72`, `GiuiceWorldMapButton.lua:578`
- Trigger: Disable minimap pins, reload/open settings, and inspect the proxy setting value.
- Workaround: Change the getter to return `defaultValue` only when `GHP_SavedVars.minimapPins == nil`.

**Locale path casing is inconsistent:**
- Symptoms: The `.toc` loads `Locales\locales.xml`, but the repository directory is `locales/`.
- Files: `GiuiceHunterPets.toc:19`, `GiuiceHunterPets.toc:20`, `locales/locales.xml`
- Trigger: Install or package on a case-sensitive filesystem/runtime path resolver.
- Workaround: Align the `.toc` path and directory casing exactly.

## Security Considerations

**Refresh pipeline executes external browser CLI and parses third-party HTML:**
- Risk: `AgentBrowserFetcher` shells out to `agent-browser` with Wowhead URLs and returns page HTML to custom parsers. The parser intentionally converts Wowhead JavaScript-like objects to JSON.
- Files: `scrapper/refresh_data.py:61`, `scrapper/refresh_data.py:73`, `scrapper/wowhead_source.py:34`, `scrapper/wowhead_source.py:48`, `scrapper/wowhead_source.py:93`
- Current mitigation: URLs are constructed from fixed Wowhead base helpers, and generated records are validated before Lua output is written.
- Recommendations: Keep all fetch targets generated from `pet_family_url()` and `npc_url()`. Do not add arbitrary URL input without host allowlisting. Keep generated Lua review and validation mandatory before replacing `Data.lua`.

**No secret-bearing configuration detected:**
- Risk: Not applicable for addon runtime; no `.env` files were read or required.
- Files: `.gitignore`, `scrapper/refresh_data.py`
- Current mitigation: No API keys or credentials are needed for the checked-in refresh code.
- Recommendations: Keep browser/session state outside the repository and do not commit cache files if they ever include authenticated content.

## Performance Bottlenecks

**World map and minimap pin refresh rebuilds all pins:**
- Problem: `UpdateMinimapPins` clears all minimap icons and recreates a frame per coordinate on every registered zone/minimap event. `DisplayPetIcons` creates a world-map button per coordinate for the player's current map.
- Files: `GiuiceWorldMapButton.lua:338`, `GiuiceWorldMapButton.lua:353`, `GiuiceWorldMapButton.lua:361`, `GiuiceWorldMapButton.lua:380`, `GiuiceWorldMapButton.lua:400`, `GiuiceWorldMapButton.lua:406`
- Cause: Pin lifecycle is stateless; frame reuse and coordinate diffing are not implemented.
- Improvement path: Pool minimap/world map pins by map and setting, update only changed coordinates, and throttle high-frequency minimap events.

**Generated source cache is very large locally:**
- Problem: `scrapper/generated/cache` is about 1.1 GB in the current working tree, with `scrapper/generated/refresh-manifest.json` about 1.3 MB.
- Files: `scrapper/generated/cache/`, `scrapper/generated/refresh-manifest.json`, `.gitignore:4`, `.gitignore:5`
- Cause: The refresh pipeline stores full Wowhead HTML pages for resumability.
- Improvement path: Keep cache ignored, add a pruning command or documented cleanup policy, and store only fetch metadata needed for blocker reports.

**Build process fails fast on individual malformed source pages:**
- Problem: `generate_pets` returns on first source/semantic failure for family or NPC data, even when many records are already usable. The current planning docs also call out skip-and-continue work for this area.
- Files: `scrapper/refresh_data.py:335`, `scrapper/refresh_data.py:340`, `scrapper/refresh_data.py:352`, `scrapper/refresh_data.py:361`, `docs/PLAN.md:5`, `docs/PLAN.md:164`
- Cause: Refresh generation treats malformed page data as fatal except for mapper entries that produce `record is None`.
- Improvement path: Skip isolated bad pet/NPC records into a reviewed skipped report and fail only when output would be empty or validation fails globally.

## Fragile Areas

**Cache manifest invalidation contract is inconsistent with tests:**
- Files: `scrapper/source_cache.py:119`, `scrapper/source_cache.py:153`, `scrapper/refresh_data.py:513`, `scrapper/refresh_data.py:746`, `tests/python/test_refresh_data_cache.py`
- Why fragile: The code distinguishes `"parse_error"` from `"error"`, while the tests assert `"error"` for invalidation. Future changes may accidentally satisfy tests by flattening statuses or satisfy code semantics while leaving CI red.
- Safe modification: Define the manifest status enum in one place and update tests to assert that contract explicitly. Include migration handling for existing `scrapper/generated/refresh-manifest.json` entries if the manifest is ever committed or shared.
- Test coverage: Broad Python coverage exists but currently fails; fix this before changing refresh semantics.

**Addon UI behavior has minimal automated coverage:**
- Files: `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceHunterPetListItemMixin.lua`, `tests/map_pet_index_test.lua`, `tests/stable_list_state_test.lua`
- Why fragile: The passing Lua tests cover map index filtering and stable-list pure helpers only. Frame creation, settings callbacks, tooltips, model scenes, minimap pins, world map hooks, and WoW API compatibility are untested outside the game client.
- Safe modification: Keep pure logic in small Lua helpers that can run under local Lua. For frame/UI changes, add a manual in-game verification checklist and avoid mixing UI rewrites with data changes.
- Test coverage: `rtk lua tests/map_pet_index_test.lua` and `rtk lua tests/stable_list_state_test.lua` pass; no automated frame-level WoW UI harness is present.

**World map code contains unused modal-family UI and nil-sensitive paths:**
- Files: `GiuiceWorldMapButton.lua:24`, `GiuiceWorldMapButton.lua:104`, `GiuiceWorldMapButton.lua:161`, `GiuiceWorldMapButton.lua:203`
- Why fragile: `ShowFamilyInfoWindow` and `SetModelViewer` are local and not referenced by the rest of the repo. If reconnected, `C_Spell.GetSpellInfo()` can return nil but `spellInfo.iconID` is read without a nil guard, and the model-scene mousewheel handler assumes an actor exists.
- Safe modification: Either remove the unused modal path in a dedicated cleanup or add nil-safe guards before wiring it to user interaction.
- Test coverage: Not covered by current Lua tests.

**Tooltip tameability depends on localized creature-type strings:**
- Files: `GiuiceTooltipEnhancement.lua:50`, `GiuiceTooltipEnhancement.lua:52`, `GiuiceTooltipEnhancement.lua:59`, `Localization.lua:46`
- Why fragile: Beast detection checks literal English, Portuguese, and Spanish creature type strings. Other locales can skip valid beasts even if `GHP.tameableCreatureIndex` has the creature ID.
- Safe modification: Prefer stable creature IDs and family/index checks where possible, or expand locale coverage intentionally through `locales/`.
- Test coverage: Not covered by automated tests.

## Scaling Limits

**Pet pin rendering scales with coordinate count per zone:**
- Current capacity: Current production data is 85,553 lines and many pet records have multiple coordinates.
- Limit: Zones with many tameable pet coordinates create many button frames and tooltip closures each refresh.
- Scaling path: Cap pin density by user setting, cluster pins, or pool frames by visible map before adding more generated datasets.

**Refresh cache scales with full HTML size:**
- Current capacity: Local ignored cache is about 1.1 GB.
- Limit: Full refreshes become disk-heavy and slow to scan/copy in workspaces or backups.
- Scaling path: Add cache pruning by role/date/status and keep only required HTML for incomplete or failed sources.

## Dependencies at Risk

**Wowhead scraping is unstable:**
- Risk: Current blocker files show Wowhead HTTP 403 for stable master search and an `agent-browser` failure for one NPC page.
- Impact: Data refresh can stall even when the addon runtime is otherwise functional.
- Migration plan: Keep a reviewed fallback from `scrapper/wow_pets.db` or production `Data.lua`, and use Wowhead cache-first collection as an enrichment source rather than the sole path to a usable build.

**WoW API surface spans many interface versions:**
- Risk: `GiuiceHunterPets.toc` declares many interface versions, while runtime code uses modern APIs such as `Settings.*`, `TooltipDataProcessor`, `C_Traits`, and `ModelScene`.
- Impact: Classic-era clients listed in the `.toc` may load files that call APIs unavailable in that client variant.
- Migration plan: Gate client-specific modules behind API checks, split `.toc` variants by game flavor, or reduce declared interface support to the versions actually verified.

## Missing Critical Features

**Stable master data is generated by tooling but absent from production addon load:**
- Problem: The exporter can emit `GHP.stable_masters`, but the production addon has no `StableMastersData.lua` and no `.toc` entry for it.
- Blocks: Stable master map pins or stable master lookup features cannot ship from current root files.

**No automated package validation:**
- Problem: `GiuiceHunterPets.zip` is tracked, but no script verifies that the zip contents match the current source tree and `.toc` paths.
- Blocks: Confident release packaging after source changes.

## Test Coverage Gaps

**Python refresh tests are red:**
- What's not tested: Passing end-to-end source cache generation under the current manifest status contract.
- Files: `tests/python/test_refresh_data_cache.py`, `scrapper/source_cache.py`, `scrapper/refresh_data.py`
- Risk: Refresh pipeline changes can land while the main regression suite is failing.
- Priority: High

**WoW UI frame behavior is mostly manual:**
- What's not tested: Main frame creation, search UI callbacks, detail panel rendering, model scene setup, settings callbacks, minimap pins, world map pins, and tooltip enhancement.
- Files: `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceHunterPetListItemMixin.lua`, `GiuiceTooltipEnhancement.lua`
- Risk: API drift or nil returns can break runtime UI without local tests catching it.
- Priority: High

**Packaging and load-order validation are absent:**
- What's not tested: `.toc` path casing, file ordering, presence of generated production data, and zip freshness.
- Files: `GiuiceHunterPets.toc`, `locales/locales.xml`, `Data.lua`, `GiuiceHunterPets.zip`
- Risk: A packaged release can omit or mis-case files while local Lua helper tests still pass.
- Priority: Medium

---

*Concerns audit: 2026-04-29*
