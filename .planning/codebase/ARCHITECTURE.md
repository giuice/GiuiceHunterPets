<!-- refreshed: 2026-04-29 -->
# Architecture

**Analysis Date:** 2026-04-29

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                  World of Warcraft AddOn Runtime             │
├──────────────────┬──────────────────┬───────────────────────┤
│   Main stable UI │   Map/minimap    │    Tooltip enhancer    │
│ `GiuiceHunterPets.lua` │ `GiuiceWorldMapButton.lua` │ `GiuiceTooltipEnhancement.lua` │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Shared addon namespace and generated data       │
│ `GHP` from varargs, `Data.lua`, `MapPetIndex.lua`,           │
│ `StablePetList.lua`, `Localization.lua`                      │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│         Python data refresh pipeline and generated outputs   │
│ `scrapper/refresh_data.py`, `scrapper/generated/`,           │
│ `scrapper/source_cache.py`, `scrapper/lua_export.py`         │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Addon manifest | Declares WoW interface metadata, saved variable name, and deterministic Lua/XML load order. | `GiuiceHunterPets.toc` |
| Settings panel | Creates `GHP_SavedVars`, registers settings category, and wires settings callbacks to map modules. | `Settings.lua` |
| XML templates | Defines reusable Blizzard UI templates for pet list rows and active pet buttons. | `GiuiceHunterPets.xml` |
| Stable list logic | Computes stable-data state, filters pets, and merges active-pet ability sources. | `StablePetList.lua` |
| Map index logic | Builds zone and tameable creature indexes from generated pet records. | `MapPetIndex.lua` |
| UI mixins | Implements XML mixins for list rows, active pet buttons, and Beast Mastery secondary pet display. | `GiuiceHunterPetListItemMixin.lua` |
| Map pins | Creates world-map and minimap pins from `GHP.pet_by_zones`, `GHP.FAMILY_DATA`, and HereBeDragons. | `GiuiceWorldMapButton.lua` |
| Localization support | Builds `GHP.exoticFamilies` for localized exotic-family lookups. | `Localization.lua` |
| Runtime data | Provides `GHP.FAMILY_DATA`, specialization metadata, and `GHP.pet_by_zones`. | `Data.lua` |
| Main UI | Creates the main frame, minimap launcher, stable pet list, detail panel, and slash command. | `GiuiceHunterPets.lua` |
| Tooltip enhancer | Adds tameability, family, classification, and creature ID lines to unit tooltips. | `GiuiceTooltipEnhancement.lua` |
| Battle pet prototype | Creates a separate `/petlist` frame for battle pets; keep isolated from hunter-pet flows. | `GiuiceBattlePets.lua` |
| Refresh CLI | Collects Wowhead sources, validates source shape, builds records, and writes generated Lua output. | `scrapper/refresh_data.py` |
| Source cache | Stores fetched HTML, writes a manifest, and records semantic parse errors atomically. | `scrapper/source_cache.py` |
| Source parsing | Extracts Wowhead Listview and `g_mapperData` JavaScript assignments. | `scrapper/wowhead_source.py` |
| Data records | Normalizes Wowhead rows into immutable Python records. | `scrapper/data_records.py` |
| Lua export | Serializes validated records into addon-compatible Lua table files. | `scrapper/lua_export.py` |

## Pattern Overview

**Overall:** TOC-ordered WoW addon modules sharing a single namespace, with an offline Python generator feeding static Lua tables.

**Key Characteristics:**
- WoW load order in `GiuiceHunterPets.toc` is part of the architecture. Add dependencies before their consumers in `GiuiceHunterPets.toc`.
- Runtime modules communicate through the addon namespace table `GHP` from `local addonName, GHP = ...`, with a compatibility fallback to `_G.GHP` in utility modules such as `MapPetIndex.lua`.
- The Python pipeline produces static Lua data for runtime use. Keep scraping, source validation, and export logic in `scrapper/`; keep in-game runtime code in root Lua files.
- Hunter-only runtime modules exit early with `if (select(3, UnitClass("player")) ~= 3) then return end` in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceTooltipEnhancement.lua`, and `Data.lua`.

## Layers

**Manifest and Load Order:**
- Purpose: Defines addon metadata, saved variables, vendored libraries, templates, helpers, data, and runtime modules.
- Location: `GiuiceHunterPets.toc`
- Contains: Interface versions, `GHP_SavedVars`, library paths, locale XML, settings, templates, and Lua modules.
- Depends on: WoW addon loader.
- Used by: Every runtime module in the addon.

**Vendored Libraries:**
- Purpose: Provide third-party addon infrastructure for localization, launcher/minimap icon support, callbacks, and map pinning.
- Location: `Libs/`
- Contains: `Libs/LibStub/LibStub.lua`, `Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua`, `Libs/AceLocale-3.0/AceLocale-3.0.lua`, `Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua`, `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua`, `Libs/HereBeDragons/HereBeDragons-2.0.lua`, `Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua`.
- Depends on: WoW Lua runtime.
- Used by: `Settings.lua`, `Data.lua`, `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, and locale files in `locales/`.

**Runtime Namespace and Data:**
- Purpose: Holds shared state, generated data, derived indexes, utility functions, and references to live frames.
- Location: `Data.lua`, `Localization.lua`, `StablePetList.lua`, `MapPetIndex.lua`
- Contains: `GHP.FAMILY_DATA`, `GHP.pet_by_zones`, `GHP.exoticFamilies`, `GHP.utils`, `GHP.BuildMapPetIndex`, `GHP.GetPetsForMap`, `GHP.BuildTameableCreatureIndex`.
- Depends on: `AceLocale-3.0` and addon varargs.
- Used by: `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceTooltipEnhancement.lua`, and Lua tests in `tests/`.

**UI Templates and Mixins:**
- Purpose: Separates XML frame shape from Lua behavior for repeated pet-list and active-pet controls.
- Location: `GiuiceHunterPets.xml`, `GiuiceHunterPetListItemMixin.lua`
- Contains: `GiuiceHunterPetListItemTemplate`, `GiuiceHunterActivePetButtonTemplate`, `GiuiceHunterActivePetListTemplate`, `GiuiceHunterPetListItemMixin`, `GiuiceHunterActivePetButtonMixin`, `GiuiceHunterActivePetListMixin`, `GiuiceHunterBeastMasterSecondaryPetButtonMixin`.
- Depends on: Blizzard UI templates and stable APIs.
- Used by: `GiuiceHunterPets.lua`.

**Main Stable UI:**
- Purpose: Presents the hunter stable list, search controls, detail model scene, active pets, minimap launcher, and `/hunterpets` command.
- Location: `GiuiceHunterPets.lua`
- Contains: `CreateMainFrame`, `GHP.utils.UpdatePetList`, `GHP.utils.ShowPetDetails`, `InitializeAddon`.
- Depends on: `GHP.utils` from `StablePetList.lua`, templates from `GiuiceHunterPets.xml`, LibDataBroker, LibDBIcon, `C_StableInfo`, and `C_Spell`.
- Used by: User interactions through minimap icon, slash command, stable events, and pet row clicks.

**Map and Tooltip Runtime:**
- Purpose: Adds creature-location pins and tameability information outside the main stable frame.
- Location: `GiuiceWorldMapButton.lua`, `GiuiceTooltipEnhancement.lua`
- Contains: `EnsurePetIndexes`, `DisplayPetIcons`, `UpdateMinimapPins`, settings callbacks, and tooltip post-call logic.
- Depends on: `GHP.pet_by_zones`, `GHP.FAMILY_DATA`, `MapPetIndex.lua`, HereBeDragons, `TooltipDataProcessor`, and WoW map APIs.
- Used by: World map, minimap, addon settings, and unit tooltips.

**Data Refresh Pipeline:**
- Purpose: Collects and validates Wowhead source pages, then emits Lua tables consumed by addon runtime.
- Location: `scrapper/`
- Contains: CLI command routing in `scrapper/refresh_data.py`, immutable records in `scrapper/data_records.py`, HTML cache in `scrapper/source_cache.py`, Wowhead JS parsing in `scrapper/wowhead_source.py`, and Lua serialization in `scrapper/lua_export.py`.
- Depends on: Python standard library, `agent-browser` optional backend, Wowhead HTML structure.
- Used by: Maintainers refreshing `Data.lua` or generated files under `scrapper/generated/`.

**Tests:**
- Purpose: Verify pure Lua helpers and Python refresh/export behavior outside WoW.
- Location: `tests/`
- Contains: Lua smoke/unit scripts in `tests/map_pet_index_test.lua` and `tests/stable_list_state_test.lua`; Python `unittest` suites in `tests/python/`.
- Depends on: Local Lua interpreter for Lua tests and Python `unittest` for Python tests.
- Used by: Development verification.

## Data Flow

### Primary Request Path

1. WoW loads `GiuiceHunterPets.toc` in order, loading libraries, locales, settings, XML templates, helper modules, data, and runtime modules (`GiuiceHunterPets.toc:10`).
2. `Settings.lua` creates defaults in `GHP_SavedVars` and registers settings callbacks (`Settings.lua:4`).
3. `GiuiceHunterPets.lua` handles `ADDON_LOADED`, then calls `InitializeAddon` (`GiuiceHunterPets.lua:416`).
4. `InitializeAddon` creates the main frame, registers the LibDBIcon launcher, subscribes to stable events, and registers `/hunterpets` (`GiuiceHunterPets.lua:388`).
5. Opening the frame calls `GHP.utils.UpdatePetList`, which reads `C_StableInfo.GetStabledPetList()` and `C_StableInfo.GetActivePetList()` (`GiuiceHunterPets.lua:189`).
6. `StablePetList.lua` determines loaded/active-only/empty state and filters by search text (`StablePetList.lua:10`).
7. `GHP.utils.CreatePetEntry` instantiates `GiuiceHunterPetListItemTemplate`, then `GiuiceHunterPetListItemMixin:SetPetInfo` renders row data (`GiuiceHunterPets.lua:182`, `GiuiceHunterPetListItemMixin.lua:68`).
8. Selecting a row calls `GHP.utils.ShowPetDetails`, which renders abilities, metadata, and a `ModelScene` for the selected pet (`GiuiceHunterPets.lua:233`).

### Map Pin Flow

1. `Data.lua` defines `GHP.pet_by_zones` and `GHP.FAMILY_DATA`; `MapPetIndex.lua` defines index builders (`Data.lua`, `MapPetIndex.lua:13`).
2. `GiuiceWorldMapButton.lua` creates indexes lazily through `EnsurePetIndexes` when `GHP.pet_by_zones` is present (`GiuiceWorldMapButton.lua:6`).
3. World-map settings call `GHP.OnWorldMapPinsSettingChanged`, store the setting, clear pins when disabled, and refresh map/minimap pins when enabled (`GiuiceWorldMapButton.lua:520`).
4. `DisplayPetIcons` gets the player map, filters pets through `GHP.GetPetsForMap`, creates pin buttons, and registers them with HereBeDragons Pins (`GiuiceWorldMapButton.lua:380`).
5. `UpdateMinimapPins` uses `HBD:GetPlayerZone()`, filters the same index, and registers minimap icons (`GiuiceWorldMapButton.lua:338`).

### Tooltip Flow

1. `Localization.lua` builds `GHP.exoticFamilies` for the client locale (`Localization.lua:51`).
2. `GiuiceTooltipEnhancement.lua` registers `TooltipDataProcessor.AddTooltipPostCall` after `PLAYER_LOGIN` (`GiuiceTooltipEnhancement.lua:97`).
3. `EnhanceTooltip` extracts the unit GUID creature ID, filters to beasts, checks `GHP.tameableCreatureIndex`, and appends hunter pet metadata (`GiuiceTooltipEnhancement.lua:34`).

### Data Refresh Flow

1. `scrapper/refresh_data.py` parses commands such as `collect-pets`, `build-pets`, `collect-stable-masters`, and `build-stable-masters` (`scrapper/refresh_data.py:211`).
2. Collection commands use `SourceCache` plus either `agent-browser` or Python `urlopen` to store source HTML under `scrapper/generated/cache/` and `scrapper/generated/refresh-manifest.json` (`scrapper/refresh_data.py:86`, `scrapper/source_cache.py:37`).
3. Build commands parse cached Listview and `g_mapperData` assignments through `scrapper/wowhead_source.py` (`scrapper/refresh_data.py:296`, `scrapper/wowhead_source.py:38`).
4. Source rows are normalized into dataclasses in `scrapper/data_records.py` and validated before export (`scrapper/data_records.py:7`, `scrapper/refresh_data.py:376`).
5. `scrapper/lua_export.py` writes `GHP.pet_by_zones` or `GHP.stable_masters` Lua tables (`scrapper/lua_export.py:14`, `scrapper/lua_export.py:38`).

**State Management:**
- Runtime addon state lives in `GHP`, `GHP_SavedVars`, and live WoW frames. Use `GHP.utils` for shared helper functions and `GHP.frames` for frame references in `GiuiceHunterPets.lua`.
- Persistent settings live only in `GHP_SavedVars`, declared in `GiuiceHunterPets.toc` and initialized in `Settings.lua` and `SavedVars.lua`.
- Generated data is static Lua table state in `Data.lua` and sample/generated files under `scrapper/generated/`.
- Python refresh state lives in `scrapper/generated/refresh-manifest.json`, cached HTML files, and blocker/validation report files under `scrapper/generated/`.

## Key Abstractions

**`GHP` namespace:**
- Purpose: Shared addon namespace passed by WoW varargs and used across root Lua files.
- Examples: `GiuiceHunterPets.lua`, `StablePetList.lua`, `MapPetIndex.lua`, `GiuiceWorldMapButton.lua`
- Pattern: Attach cross-module functions and data under `GHP`, especially `GHP.utils`, `GHP.frames`, `GHP.FAMILY_DATA`, `GHP.pet_by_zones`, `GHP.mapPetIndex`, and settings callbacks.

**Stable list state:**
- Purpose: Normalizes Blizzard stable API states into `status`, `pets`, and `message`.
- Examples: `StablePetList.lua`, `tests/stable_list_state_test.lua`
- Pattern: Keep stable data fallback logic in `GHP.utils.GetStablePetListState` and use `GHP.utils.FilterStablePets` for search behavior.

**Map pet index:**
- Purpose: Converts the flat generated pet table into zone-keyed and NPC-keyed lookup tables.
- Examples: `MapPetIndex.lua`, `GiuiceWorldMapButton.lua`, `GiuiceTooltipEnhancement.lua`, `tests/map_pet_index_test.lua`
- Pattern: Build indexes with `GHP.BuildMapPetIndex` and `GHP.BuildTameableCreatureIndex`; read pets with `GHP.GetPetsForMap`.

**XML mixins:**
- Purpose: Binds Blizzard XML templates to Lua behavior.
- Examples: `GiuiceHunterPets.xml`, `GiuiceHunterPetListItemMixin.lua`
- Pattern: Put repeated frame layout in XML and behavioral methods in global mixin tables named by the XML `mixin` attribute.

**Source cache:**
- Purpose: Makes Wowhead collection resumable and records parse/fetch status.
- Examples: `scrapper/source_cache.py`, `scrapper/refresh_data.py`, `tests/python/test_source_cache.py`
- Pattern: Fetch through `SourceCache.get_text` or collect through `_collect_one`; invalidate malformed semantic sources instead of silently reusing them.

**Generated records:**
- Purpose: Provides explicit Python shapes before Lua serialization.
- Examples: `scrapper/data_records.py`, `scrapper/lua_export.py`, `tests/python/test_data_records.py`
- Pattern: Convert raw Wowhead rows into frozen dataclasses, validate records, then export Lua strings.

## Entry Points

**WoW Addon Loader:**
- Location: `GiuiceHunterPets.toc`
- Triggers: WoW loads the addon.
- Responsibilities: Load libraries before addon modules, declare `GHP_SavedVars`, and include XML templates before mixin consumers.

**Addon Initialization:**
- Location: `GiuiceHunterPets.lua`
- Triggers: `ADDON_LOADED` for `GiuiceHunterPets`.
- Responsibilities: Create main UI, register minimap launcher, subscribe to stable updates, and register `/hunterpets`.

**Settings Initialization:**
- Location: `Settings.lua`
- Triggers: File load through `GiuiceHunterPets.toc`.
- Responsibilities: Initialize saved variable defaults, register settings category, and bind setting changes to `GHP.OnWorldMapPinsSettingChanged` and `GHP.OnMinimapPinsSettingChanged`.

**Map Pins Initialization:**
- Location: `GiuiceWorldMapButton.lua`
- Triggers: File load and `ADDON_LOADED`.
- Responsibilities: Set up map hooks, minimap event frame, pin refresh callbacks, and lazy indexes.

**Tooltip Initialization:**
- Location: `GiuiceTooltipEnhancement.lua`
- Triggers: `PLAYER_LOGIN`.
- Responsibilities: Register a tooltip post-call for unit tooltips.

**Refresh CLI:**
- Location: `scrapper/refresh_data.py`
- Triggers: `python3 -m scrapper.refresh_data ...`.
- Responsibilities: Collect sources, build generated Lua data, write blockers/validation reports, and return nonzero on refresh failure.

## Architectural Constraints

- **Threading:** WoW addon code is event-driven in a single Lua UI runtime. Python cache manifest writes in `scrapper/source_cache.py` use a `threading.Lock`, but the refresh CLI is structured as a single-process command.
- **Global state:** Runtime shared mutable state is `GHP` and `GHP_SavedVars` in `GiuiceHunterPets.lua`, `Settings.lua`, `Data.lua`, `MapPetIndex.lua`, and `GiuiceWorldMapButton.lua`. Global mixin names in `GiuiceHunterPetListItemMixin.lua` are required by `GiuiceHunterPets.xml`.
- **Load order:** `GiuiceHunterPets.toc` must load `Settings.lua` before modules that rely on `GHP_SavedVars`, `MapPetIndex.lua` before `GiuiceWorldMapButton.lua`, `Localization.lua` before `GiuiceTooltipEnhancement.lua`, and `Data.lua` before map/tooltip consumers.
- **Circular imports:** Python modules use a one-way pipeline: `scrapper/refresh_data.py` imports `scrapper/data_records.py`, `scrapper/lua_export.py`, `scrapper/source_cache.py`, and `scrapper/wowhead_source.py`; `scrapper/source_cache.py` imports only `fetch_text` from `scrapper/wowhead_source.py`. No circular Python import chain is detected in the active modules.
- **WoW API boundary:** Root Lua files directly call Blizzard APIs such as `C_StableInfo`, `C_Spell`, `C_Map`, `TooltipDataProcessor`, `Settings`, `CreateFrame`, and `LibStub`. Keep WoW-dependent code out of `scrapper/` and pure helper tests.

## Anti-Patterns

### Bypassing the Namespace

**What happens:** New runtime helpers are added as standalone globals instead of fields on `GHP` or as required XML mixin globals.
**Why it's wrong:** The addon already coordinates modules through `GHP`, and unexpected globals increase load-order and name-collision risk.
**Do this instead:** Add shared helpers under `GHP.utils` as in `StablePetList.lua`; add map APIs under `GHP` as in `MapPetIndex.lua`; use globals only for XML mixin tables declared in `GiuiceHunterPets.xml`.

### Editing Generated Runtime Data by Hand

**What happens:** Pet location data or stable master data is patched directly in `Data.lua` or generated files.
**Why it's wrong:** The refresh pipeline validates source shape and output records in `scrapper/refresh_data.py`, `scrapper/data_records.py`, and `scrapper/lua_export.py`.
**Do this instead:** Update collection/build logic in `scrapper/`, regenerate the Lua output, and verify with `tests/python/`.

### Loading Libraries Outside the TOC

**What happens:** Runtime modules attempt to load or vendor libraries from code instead of through `GiuiceHunterPets.toc`.
**Why it's wrong:** The addon relies on deterministic TOC order and documented flat library paths in `important-readme.md`.
**Do this instead:** Add or update library paths in `GiuiceHunterPets.toc` and keep files under `Libs/` with paths matching the TOC.

### Mixing WoW API Calls Into Pure Helpers

**What happens:** Pure testable helpers such as `StablePetList.lua` or `MapPetIndex.lua` start calling `C_StableInfo`, `C_Map`, or frame APIs directly.
**Why it's wrong:** Existing Lua tests load those modules with `dofile` outside WoW in `tests/stable_list_state_test.lua` and `tests/map_pet_index_test.lua`.
**Do this instead:** Keep WoW calls in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, or `GiuiceTooltipEnhancement.lua`, then pass plain tables into helper functions.

## Error Handling

**Strategy:** Runtime Lua code favors guard clauses and WoW API assertions; Python refresh code treats malformed source data as explicit blockers with report files.

**Patterns:**
- Use `assert` for required libraries in `GiuiceHunterPets.lua`.
- Guard hunter-only modules with a class check in root runtime files.
- Use `pcall` around optional stable food type lookup in `GiuiceHunterPets.lua`.
- Use source invalidation plus blocker files in `scrapper/refresh_data.py` when Wowhead source shape is missing or malformed.
- Use atomic writes for cached HTML and manifests in `scrapper/source_cache.py`.

## Cross-Cutting Concerns

**Logging:** Runtime Lua uses `print` in `GiuiceHunterPets.lua` and `GiuiceWorldMapButton.lua` for load/minimap status. Python refresh commands print collection/build progress and failure report paths from `scrapper/refresh_data.py`.
**Validation:** Runtime validation is mostly guards around WoW API availability and settings values. Python refresh validation is centralized in `scrapper/refresh_data.py`, `scrapper/data_records.py`, and `scrapper/lua_export.py`.
**Authentication:** Not applicable. The addon and refresh pipeline do not implement user authentication.
**Localization:** Locale files under `locales/` register AceLocale translations; `Localization.lua` provides a separate exotic-family lookup for tooltip logic.
**Assets:** Runtime icons and textures live under `icons/` and `huntericon.blp`; map pin code resolves family icons from `icons/PetIcons/32x32/`.

---

*Architecture analysis: 2026-04-29*
