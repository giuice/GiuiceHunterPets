# Coding Conventions

**Analysis Date:** 2026-04-29

## Naming Patterns

**Files:**
- Addon runtime files use PascalCase Lua filenames at the repository root, such as `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `StablePetList.lua`, and `MapPetIndex.lua`.
- Addon XML and TOC files follow the addon name: `GiuiceHunterPets.xml` and `GiuiceHunterPets.toc`.
- Locale files use lowercase addon prefixes and locale suffixes: `locales/ghp-enUS.lua`, `locales/ghp-ptBR.lua`, and `locales/ghp-esES.lua`.
- Python scraper modules use lowercase snake_case filenames under `scrapper/`, such as `scrapper/data_records.py`, `scrapper/source_cache.py`, `scrapper/wowhead_source.py`, `scrapper/lua_export.py`, and `scrapper/refresh_data.py`.
- Python tests use `test_*.py` under `tests/python/`, such as `tests/python/test_source_cache.py` and `tests/python/test_refresh_data_cache.py`.
- Lua tests use descriptive `*_test.lua` filenames under `tests/`, such as `tests/stable_list_state_test.lua` and `tests/map_pet_index_test.lua`.
- Generated or data-heavy files are explicit by name and location: `Data.lua`, `scrapper/generated/Data.sample.lua`, `scrapper/generated/pet-refresh-blockers.md`, and `scrapper/generated/stable-master-blockers.md`.

**Functions:**
- Lua addon APIs exported on `GHP` use PascalCase after the namespace: `GHP.BuildMapPetIndex`, `GHP.GetPetsForMap`, `GHP.BuildTameableCreatureIndex` in `MapPetIndex.lua`; `GHP.utils.GetStablePetListState`, `GHP.utils.FilterStablePets`, and `GHP.utils.GetPetDisplayAbilities` in `StablePetList.lua`.
- Lua local helper functions use PascalCase in newer utility files: `LowerText` and `AppendAbilities` in `StablePetList.lua`; `EnsurePetIndexes`, `CreateFamilyInfoWindow`, `SetModelViewer`, and `DisplayPetIcons` in `GiuiceWorldMapButton.lua`.
- Some older Lua helpers use lower camelCase: `getMinimapData`, `showToolTip`, and `getMinimapButton` in `GiuiceWorldMapButton.lua`. Match the local file style when editing existing functions.
- Lua mixin methods use WoW mixin method names with colon syntax: `GiuiceHunterPetListItemMixin:OnLoad`, `GiuiceHunterPetListItemMixin:SetPetInfo`, and `GiuiceHunterActivePetListMixin:Refresh` in `GiuiceHunterPetListItemMixin.lua`.
- Python public functions use snake_case: `classification_label`, `build_pet_record`, and `build_stable_master_record` in `scrapper/data_records.py`; `extract_listview_data` and `extract_mapper_data` in `scrapper/wowhead_source.py`.
- Python private helpers use a leading underscore: `_coords` in `scrapper/data_records.py`, `_parse_jsonish_value` in `scrapper/wowhead_source.py`, `_write_text_atomic` in `scrapper/source_cache.py`, and `_validate_mapper_coords` in `scrapper/refresh_data.py`.
- Python test methods use behavior-oriented `test_*` names: `test_cache_miss_fetches_and_writes_manifest` in `tests/python/test_source_cache.py` and `test_generate_pets_reuses_cached_sources_without_fetching` in `tests/python/test_refresh_data_cache.py`.

**Variables:**
- Lua locals use lower camelCase for runtime state: `searchBox`, `searchType`, `scrollChild`, `emptyState`, and `detailPanel` in `GiuiceHunterPets.lua`; `filteredPets` in `MapPetIndex.lua`.
- Lua constants use uppercase with underscores: `UNLOADED_MESSAGE`, `ACTIVE_ONLY_MESSAGE`, and `EMPTY_MESSAGE` in `StablePetList.lua`.
- Addon globals are rooted under `GHP` and saved variables under `GHP_SavedVars`; new addon runtime state should prefer `GHP.<feature>` or `GHP.utils.<function>` instead of unrelated globals.
- Python locals and parameters use snake_case: `cache_dir`, `manifest_path`, `source_cache`, `generated_dir`, and `from_cache` in `scrapper/source_cache.py` and `scrapper/refresh_data.py`.
- Python tests use explicit fixture variable names such as `pages`, `calls`, `first_cache`, `resumed_cache`, `first_output`, and `second_output` in `tests/python/test_refresh_data_cache.py`.

**Types:**
- Python data-transfer objects use PascalCase dataclasses: `PetFamilySourceRow`, `TameablePetSourceRow`, `PetRecord`, and `StableMasterRecord` in `scrapper/data_records.py`; `SourceResult` in `scrapper/source_cache.py`.
- Python exceptions use PascalCase ending in `Error`: `SourceFetchError` in `scrapper/source_cache.py`.
- Python tests use PascalCase `unittest.TestCase` classes: `SourceCacheTest`, `DataRecordsTest`, `LuaExportTest`, `WowheadSourceTest`, and `RefreshDataCacheTest`.
- Lua data shapes mirror WoW addon and generated data field names. Preserve established keys such as `zoneID`, `NpcId`, `displayId`, `pet_by_zones`, and `stable_masters` in `Data.lua`, `scrapper/lua_export.py`, and tests.

## Code Style

**Formatting:**
- No repository formatter config is detected for Lua or Python; `.prettierrc`, `pyproject.toml`, `ruff.toml`, `stylua.toml`, and `.editorconfig` are not present.
- Python code follows a standard-library style with 4-space indentation, blank lines between top-level functions/classes, type hints on new pipeline code, and `from __future__ import annotations` in `scrapper/data_records.py`, `scrapper/source_cache.py`, `scrapper/wowhead_source.py`, `scrapper/lua_export.py`, and `scrapper/refresh_data.py`.
- Python modules use explicit imports from the standard library and local package imports, as seen in `scrapper/source_cache.py` and `scrapper/refresh_data.py`.
- Lua addon code primarily uses 4-space indentation in project-owned files such as `StablePetList.lua`, `MapPetIndex.lua`, and `GiuiceWorldMapButton.lua`. `GiuiceHunterPets.lua` contains a small amount of older tab/semicolon style near `backgroundForPetSpec`; avoid reformatting unrelated legacy sections.
- Lua table literals in project-owned tests and utilities use spaces inside inline tables, for example `{ zoneID = 1, name = "Common Cat" }` in `tests/map_pet_index_test.lua` and `{ name = "Active One", familyName = "Cat", level = 70 }` in `tests/stable_list_state_test.lua`.
- Shell commands in project instructions must be prefixed with `rtk`, as required by `AGENTS.md` and `/home/giuice/.codex/RTK.md`.

**Linting:**
- No lint tool config is detected for project code. `luacheck`, `stylua`, `ruff`, `flake8`, `mypy`, `pytest`, ESLint, Prettier, and Biome configs are not present.
- Use the existing tests as the primary style and behavior gate: `tests/python/*.py`, `tests/stable_list_state_test.lua`, and `tests/map_pet_index_test.lua`.
- Do not lint or reformat vendored libraries under `Libs/`, including `Libs/LibStub/`, `Libs/LibDataBroker-1.1/`, `Libs/LibDBIcon-1.0/`, and `Libs/HereBeDragons/`.

## Import Organization

**Order:**
1. Python future imports first: `from __future__ import annotations` in scraper modules.
2. Python standard-library imports next, grouped together: `hashlib`, `json`, `tempfile`, `threading`, `Path`, and `Callable` in `scrapper/source_cache.py`.
3. Python local package imports last: `from scrapper.wowhead_source import fetch_text` in `scrapper/source_cache.py`, and `from scrapper.data_records import PetRecord, StableMasterRecord` in `scrapper/lua_export.py`.
4. Python tests import standard library first, then test helpers and code under test: `tests/python/test_refresh_data_cache.py` imports `json`, `tempfile`, `unittest`, `StringIO`, `Path`, `patch`, and `HTTPError` before importing `scrapper.refresh_data`.
5. Lua modules do not use an import system; addon load order is controlled by `GiuiceHunterPets.toc`. Put dependencies earlier in `GiuiceHunterPets.toc` when a later file uses their globals.

**Path Aliases:**
- Python uses normal package imports from the repository root, such as `from scrapper.source_cache import SourceCache` in `tests/python/test_source_cache.py`.
- Lua tests set `package.path = "./?.lua;" .. package.path` and load project files with `dofile("StablePetList.lua")` or `dofile("MapPetIndex.lua")`.
- Addon runtime modules receive `local addonName, GHP = ...` or compatible fallback variants, as in `GiuiceHunterPets.lua`, `StablePetList.lua`, and `MapPetIndex.lua`.

## Error Handling

**Patterns:**
- Fail fast for required addon libraries with `assert`, as in `GiuiceHunterPets.lua` for `LibStub`, `LibDataBroker-1.1`, and `LibDBIcon-1.0`.
- Return safe empty values for expected missing runtime data in utility functions. `GHP.GetPetsForMap` returns `{}` when no map ID is available or pins are disabled in `MapPetIndex.lua`; `GHP.utils.GetPetDisplayAbilities` returns `{}` for nil pet info in `StablePetList.lua`.
- Use `pcall` around WoW APIs that may be unavailable for some pet records, as in `GiuiceHunterPets.lua` around `C_StableInfo.GetStablePetFoodTypes`.
- Python source fetching wraps lower-level exceptions in `SourceFetchError` with URL and role context in `scrapper/source_cache.py`.
- Python cache writes should be atomic through `_write_text_atomic` in `scrapper/source_cache.py`; avoid direct partial writes for cache and manifest files.
- Python parsing and validation functions raise `ValueError` for semantic data shape issues, then caller code records source invalidation and blockers in `scrapper/refresh_data.py`.
- CLI entrypoints should return integer exit codes and raise `SystemExit(main())` only at the module boundary, as in `scrapper/refresh_data.py`.
- Generated-data validation returns lists of error strings instead of raising, as in `validate_pet_records` and `validate_stable_master_records` in `scrapper/lua_export.py`.

## Logging

**Framework:** `print` / standard streams

**Patterns:**
- Addon runtime uses `print` sparingly for user-visible diagnostics, such as load confirmation in `GiuiceHunterPets.lua` and minimap setting messages in `GiuiceWorldMapButton.lua`.
- Python pipeline progress uses `print(..., flush=True)` for long-running collection and build phases in `scrapper/refresh_data.py`.
- Python failure summaries print to `sys.stderr` in `_print_failure_report` in `scrapper/refresh_data.py`.
- Tests print only final or per-test PASS messages in Lua scripts: `tests/stable_list_state_test.lua` and `tests/map_pet_index_test.lua`.
- Prefer structured files for machine-readable state: `refresh-manifest.json` from `scrapper/source_cache.py`, blocker files from `scrapper/refresh_data.py`, and generated Lua from `scrapper/lua_export.py`.

## Comments

**When to Comment:**
- Keep comments brief and tied to WoW API context, UI intent, or historical compatibility. Examples include section comments in `GiuiceHunterPets.lua`, settings comments in `Settings.lua`, and TOC section comments in `GiuiceHunterPets.toc`.
- Avoid expanding comments around straightforward Python validation and transformation code; modules such as `scrapper/data_records.py` and `scrapper/lua_export.py` are mostly self-documenting through function names and dataclasses.
- Do not edit explanatory comments in vendored libraries under `Libs/`.

**JSDoc/TSDoc:**
- Not applicable. The repository has no TypeScript or JavaScript source conventions.
- Python docstrings are not used in current scraper modules; preserve the function-name and type-hint style unless adding a genuinely complex API boundary.
- LuaDoc annotations are not used in project-owned Lua files.

## Function Design

**Size:** Use focused, testable functions for pure transformations and validation. Examples: `GHP.GetPetsForMap` in `MapPetIndex.lua`, `GHP.utils.FilterStablePets` in `StablePetList.lua`, `classification_label` in `scrapper/data_records.py`, and `_validate_mapper_coords` in `scrapper/refresh_data.py`.

**Parameters:** Pass dependencies into Python pipeline functions rather than using live services directly. `SourceCache` accepts an injected `fetcher` in `scrapper/source_cache.py`, and `generate_pets` / `generate_stable_masters` accept `source_cache`, `generated_dir`, limits, and output paths in `scrapper/refresh_data.py`.

**Return Values:** Prefer explicit data values over hidden side effects for reusable helpers. Lua utilities return tables or lists in `StablePetList.lua` and `MapPetIndex.lua`; Python builders return dataclass instances or `None` in `scrapper/data_records.py`; CLI build functions return `0` or `1` in `scrapper/refresh_data.py`.

## Module Design

**Exports:** Lua modules attach public addon functions to `GHP` or `GHP.utils`, while private helpers stay `local` in the same file. Python modules expose plain functions/classes directly from each module without package-level re-export in `scrapper/__init__.py`.

**Barrel Files:** No barrel files are used. `scrapper/__init__.py` is empty, and callers import from concrete modules such as `scrapper.source_cache`, `scrapper.data_records`, and `scrapper.wowhead_source`.

---

*Convention analysis: 2026-04-29*
