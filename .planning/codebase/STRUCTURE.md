# Codebase Structure

**Analysis Date:** 2026-04-29

## Directory Layout

```text
GiuiceHunterPets/
├── GiuiceHunterPets.toc          # WoW addon manifest and load order
├── GiuiceHunterPets.lua          # Main stable-list window and slash command
├── GiuiceHunterPets.xml          # XML templates consumed by mixins
├── GiuiceHunterPetListItemMixin.lua # Lua behavior for XML templates
├── StablePetList.lua             # Pure stable-list helper functions
├── MapPetIndex.lua               # Pure generated-pet index helpers
├── GiuiceWorldMapButton.lua      # World map and minimap pin runtime
├── GiuiceTooltipEnhancement.lua  # Unit tooltip enhancement runtime
├── Data.lua                      # Runtime pet family and pet location data
├── Settings.lua                  # Addon settings and saved variable defaults
├── Localization.lua              # Exotic-family localization lookup
├── GiuiceBattlePets.lua          # Separate battle-pet prototype frame
├── SavedVars.lua                 # Saved variable default table helper
├── locales/                      # AceLocale Lua files and locale XML loader
├── Libs/                         # Vendored WoW addon libraries
├── icons/                        # BLP assets used by map/minimap pins
├── scrapper/                     # Python data collection and Lua export pipeline
├── tests/                        # Lua and Python tests
├── docs/                         # Planning, research, and runbook documents
└── .planning/                    # GSD planning and codebase map outputs
```

## Directory Purposes

**Repository root:**
- Purpose: Contains the installable WoW addon runtime files that are loaded by `GiuiceHunterPets.toc`.
- Contains: Root `.lua` runtime modules, `GiuiceHunterPets.xml`, `GiuiceHunterPets.toc`, addon assets, documentation, and package metadata.
- Key files: `GiuiceHunterPets.toc`, `GiuiceHunterPets.lua`, `Data.lua`, `GiuiceWorldMapButton.lua`, `GiuiceTooltipEnhancement.lua`

**`locales/`:**
- Purpose: Defines AceLocale translations loaded by `locales/locales.xml`.
- Contains: Locale-specific Lua files and XML loader.
- Key files: `locales/locales.xml`, `locales/ghp-enUS.lua`, `locales/ghp-ptBR.lua`, `locales/ghp-esES.lua`

**`Libs/`:**
- Purpose: Vendored WoW addon libraries loaded explicitly from `GiuiceHunterPets.toc`.
- Contains: LibStub, CallbackHandler, AceLocale, LibDataBroker, LibDBIcon, HereBeDragons, and library metadata/tests.
- Key files: `Libs/LibStub/LibStub.lua`, `Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua`, `Libs/AceLocale-3.0/AceLocale-3.0.lua`, `Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua`, `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua`, `Libs/HereBeDragons/HereBeDragons-2.0.lua`, `Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua`

**`icons/`:**
- Purpose: Stores addon texture assets for family/map pin rendering.
- Contains: BLP family icons and source image assets.
- Key files: `icons/PetIcons/32x32/HighLight.blp`, `icons/PetIcons/32x32/Spirit Beast.blp`, `icons/petFamilies/Cat.blp`

**`scrapper/`:**
- Purpose: Holds the Python data refresh pipeline and generated/supporting source data.
- Contains: CLI orchestration, source parsing, cache management, record normalization, Lua exporting, old scraper artifacts, generated reports, JSON/source data, and a SQLite database.
- Key files: `scrapper/refresh_data.py`, `scrapper/source_cache.py`, `scrapper/wowhead_source.py`, `scrapper/data_records.py`, `scrapper/lua_export.py`, `scrapper/generated/Data.sample.lua`

**`scrapper/generated/`:**
- Purpose: Stores refresh outputs, blocker reports, validation reports, sample generated Lua, cache manifest, and cached source pages when collection runs.
- Contains: Generated Lua samples and markdown reports.
- Key files: `scrapper/generated/Data.sample.lua`, `scrapper/generated/pet-refresh-blockers.md`, `scrapper/generated/pet-skipped.md`, `scrapper/generated/stable-master-blockers.md`

**`tests/`:**
- Purpose: Contains direct tests for pure Lua helpers and Python refresh/export modules.
- Contains: Root Lua test scripts and Python `unittest` files under `tests/python/`.
- Key files: `tests/map_pet_index_test.lua`, `tests/stable_list_state_test.lua`, `tests/python/test_refresh_data_cache.py`, `tests/python/test_source_cache.py`, `tests/python/test_data_records.py`, `tests/python/test_lua_export.py`, `tests/python/test_wowhead_source.py`

**`docs/`:**
- Purpose: Project planning, runbook, research, and superpowers planning artifacts.
- Contains: Research markdown, phase plans, specs, and archived/outdated material.
- Key files: `docs/PLAN.md`, `docs/research/data-refresh-runbook.md`, `docs/research/hunter-pet-and-stable-master-data-sources.md`, `docs/superpowers/plans/2026-04-29-resumable-data-refresh-pipeline.md`

**`.planning/`:**
- Purpose: GSD workflow state and generated codebase intelligence.
- Contains: Planning artifacts and codebase map documents.
- Key files: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/STRUCTURE.md`

## Key File Locations

**Entry Points:**
- `GiuiceHunterPets.toc`: Primary WoW addon entry point and load-order declaration.
- `GiuiceHunterPets.lua`: Main addon initialization on `ADDON_LOADED` and `/hunterpets` slash command.
- `GiuiceWorldMapButton.lua`: Map/minimap pin initialization on file load and `ADDON_LOADED`.
- `GiuiceTooltipEnhancement.lua`: Tooltip post-call initialization on `PLAYER_LOGIN`.
- `GiuiceBattlePets.lua`: Separate `/petlist` battle-pet prototype entry point.
- `scrapper/refresh_data.py`: Python CLI entry point for source collection and generated data builds.

**Configuration:**
- `GiuiceHunterPets.toc`: Addon metadata, saved variables, library paths, and module order.
- `Settings.lua`: Runtime settings category, settings defaults, and setting callbacks.
- `SavedVars.lua`: Shared `GHP_SavedVars` default table.
- `package-lock.json`: Minimal npm lock metadata, no active frontend app structure detected.
- `AGENTS.md`: Repository behavior instructions for coding agents.

**Core Logic:**
- `StablePetList.lua`: Stable data state, search filtering, and ability aggregation.
- `MapPetIndex.lua`: Zone index, filtering by pin setting, and tameable creature index.
- `GiuiceHunterPets.lua`: Main stable UI construction, list refresh, detail rendering, and minimap launcher.
- `GiuiceHunterPetListItemMixin.lua`: List-item, active-pet, and secondary-pet mixin behavior.
- `GiuiceWorldMapButton.lua`: HereBeDragons world map and minimap pin behavior.
- `GiuiceTooltipEnhancement.lua`: Unit tooltip enhancement behavior.
- `Localization.lua`: Exotic-family localized lookup.

**Data:**
- `Data.lua`: Runtime family metadata and pet-by-zone table consumed by map and tooltip code.
- `scrapper/generated/Data.sample.lua`: Generated sample shape for `GHP.pet_by_zones`.
- `scrapper/pet_families.json`: Source/support data for pet families.
- `scrapper/zones.json`: Source/support data for zones.
- `scrapper/wow_pets.db`: SQLite data artifact used by legacy scraper code.

**Data Pipeline:**
- `scrapper/refresh_data.py`: Command dispatcher, collection flow, build flow, source validation, blocker report writing.
- `scrapper/source_cache.py`: HTML cache and manifest persistence.
- `scrapper/wowhead_source.py`: Wowhead URL builders and JavaScript data extraction.
- `scrapper/data_records.py`: Dataclass record shapes and row-to-record conversion.
- `scrapper/lua_export.py`: Lua table string export and final record validation.
- `scrapper/hunterpets.py`: Legacy Playwright/SQLite scraper implementation; keep separate from the current cache-first pipeline.

**Testing:**
- `tests/map_pet_index_test.lua`: Tests `MapPetIndex.lua` outside WoW.
- `tests/stable_list_state_test.lua`: Tests `StablePetList.lua` outside WoW.
- `tests/python/test_refresh_data_cache.py`: Tests resumable source cache and refresh failure behavior.
- `tests/python/test_source_cache.py`: Tests `scrapper/source_cache.py`.
- `tests/python/test_wowhead_source.py`: Tests `scrapper/wowhead_source.py`.
- `tests/python/test_data_records.py`: Tests `scrapper/data_records.py`.
- `tests/python/test_lua_export.py`: Tests `scrapper/lua_export.py`.

## Naming Conventions

**Files:**
- Root runtime Lua files use PascalCase or addon-prefixed names: `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `StablePetList.lua`, `MapPetIndex.lua`.
- XML template file matches the addon name: `GiuiceHunterPets.xml`.
- Locale files use `ghp-<locale>.lua`: `locales/ghp-enUS.lua`, `locales/ghp-ptBR.lua`, `locales/ghp-esES.lua`.
- Python modules use snake_case: `scrapper/refresh_data.py`, `scrapper/source_cache.py`, `scrapper/data_records.py`.
- Python tests use `test_*.py`: `tests/python/test_refresh_data_cache.py`.
- Lua tests use feature names ending in `_test.lua`: `tests/map_pet_index_test.lua`, `tests/stable_list_state_test.lua`.

**Directories:**
- Vendored libraries keep upstream-style names under `Libs/`: `Libs/LibDBIcon-1.0/`, `Libs/HereBeDragons/`.
- Addon textures are grouped by usage/family under `icons/`: `icons/PetIcons/32x32/`, `icons/petFamilies/`.
- Python refresh code lives under `scrapper/`; generated refresh outputs live under `scrapper/generated/`; tests live under `tests/` and `tests/python/`.

## Where to Add New Code

**New Stable-List Behavior:**
- Primary code: `StablePetList.lua` for pure state/filtering logic; `GiuiceHunterPets.lua` for frame creation, event handling, and WoW API calls.
- Tests: `tests/stable_list_state_test.lua` for pure Lua helper behavior.

**New Pet Row or Active Pet UI:**
- Primary code: `GiuiceHunterPets.xml` for reusable frame layout; `GiuiceHunterPetListItemMixin.lua` for behavior.
- Caller code: `GiuiceHunterPets.lua` for creating or refreshing instances.
- Tests: Prefer extracting pure logic into `StablePetList.lua` and testing in `tests/stable_list_state_test.lua`.

**New Map or Minimap Pin Behavior:**
- Primary code: `GiuiceWorldMapButton.lua` for WoW map/minimap integration.
- Shared filtering/indexing: `MapPetIndex.lua`.
- Tests: `tests/map_pet_index_test.lua` for pure index/filter logic.

**New Tooltip Behavior:**
- Primary code: `GiuiceTooltipEnhancement.lua`.
- Shared lookup data: `Localization.lua`, `MapPetIndex.lua`, and `Data.lua`.
- Tests: Keep WoW API-free helpers in a pure module before adding Lua tests under `tests/`.

**New Addon Setting:**
- Primary code: `Settings.lua`.
- Runtime consumer: Expose a callback or read setting value from the module that owns the behavior, following `GHP.OnWorldMapPinsSettingChanged` and `GHP.OnMinimapPinsSettingChanged` in `GiuiceWorldMapButton.lua`.
- Manifest changes: Update `GiuiceHunterPets.toc` only if a new file is added.

**New Generated Data Field:**
- Source parsing and validation: `scrapper/refresh_data.py` and `scrapper/wowhead_source.py`.
- Record shape: `scrapper/data_records.py`.
- Lua output: `scrapper/lua_export.py`.
- Runtime consumer: `Data.lua` consumers such as `GiuiceWorldMapButton.lua` or `GiuiceTooltipEnhancement.lua`.
- Tests: `tests/python/test_data_records.py`, `tests/python/test_lua_export.py`, and `tests/python/test_refresh_data_cache.py`.

**New Refresh Pipeline Command:**
- CLI wiring: `scrapper/refresh_data.py`.
- Shared cache behavior: `scrapper/source_cache.py`.
- Tests: `tests/python/test_refresh_data_cache.py` and focused tests under `tests/python/`.

**Utilities:**
- Shared Lua helpers: `StablePetList.lua` or `MapPetIndex.lua` when logic is pure and testable.
- WoW API helpers: Keep near the owning runtime module in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, or `GiuiceTooltipEnhancement.lua`.
- Python helpers: Add to the focused module in `scrapper/`; avoid broad utility modules unless multiple modules already need the behavior.

## Special Directories

**`Libs/`:**
- Purpose: Vendored third-party WoW addon libraries.
- Generated: No.
- Committed: Yes.

**`icons/`:**
- Purpose: Runtime BLP texture assets for addon iconography and map pins.
- Generated: No.
- Committed: Yes.

**`scrapper/generated/`:**
- Purpose: Generated Lua samples, refresh blocker reports, skipped records, validation reports, source cache, and manifest files.
- Generated: Yes.
- Committed: Partially. Existing sample/report files are present; cache files and manifests should be treated as generated refresh artifacts.

**`scrapper/__pycache__/` and `tests/python/__pycache__/`:**
- Purpose: Python bytecode cache files.
- Generated: Yes.
- Committed: No new code should depend on these files.

**`docs/`:**
- Purpose: Human planning, research, and runbook context.
- Generated: Mixed. GSD/superpowers workflow files are authored planning artifacts.
- Committed: Yes.

**`.planning/`:**
- Purpose: GSD workflow metadata and codebase intelligence.
- Generated: Yes.
- Committed: Project-dependent; mapper outputs are written here for other GSD commands.

---

*Structure analysis: 2026-04-29*
