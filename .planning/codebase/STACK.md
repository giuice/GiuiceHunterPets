# Technology Stack

**Analysis Date:** 2026-04-29

## Languages

**Primary:**
- Lua - World of Warcraft addon runtime code in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceHunterPetListItemMixin.lua`, `Settings.lua`, `Localization.lua`, `GiuiceBattlePets.lua`, `GiuiceTooltipEnhancement.lua`, `MapPetIndex.lua`, `StablePetList.lua`, `Data.lua`, and `locales/*.lua`.
- Python 3.14.4 - offline/source-refresh tooling in `scrapper/refresh_data.py`, `scrapper/wowhead_source.py`, `scrapper/source_cache.py`, `scrapper/data_records.py`, and `scrapper/lua_export.py`.

**Secondary:**
- XML - WoW UI frame/template declarations in `GiuiceHunterPets.xml`, `locales/locales.xml`, and vendored library XML files under `Libs/`.
- JSON - generated/source metadata in `scrapper/generated/refresh-manifest.json`, static scraper inputs in `scrapper/zones.json`, and package lock metadata in `package-lock.json`.
- Markdown - runbooks, plans, and generated diagnostics in `docs/`, `scrapper/generated/*.md`, and `.planning/`.

## Runtime

**Environment:**
- World of Warcraft addon runtime - declared by `GiuiceHunterPets.toc` with interface targets `11508`, `11507`, `20505`, `30405`, `38001`, `40402`, `50503`, `50502`, `120001`, `120005`, and `120000`.
- Python 3.14.4 - detected via `python3 --version`; used for scraper CLI and Python unit tests.
- Lua interpreter - used for standalone Lua tests such as `tests/map_pet_index_test.lua` and `tests/stable_list_state_test.lua`; WoW itself provides the production Lua environment.

**Package Manager:**
- Python: none detected. There is no `requirements.txt`, `pyproject.toml`, `Pipfile`, `poetry.lock`, or `uv.lock`; scraper code uses the Python standard library plus optional external CLI execution.
- Node/npm: no `package.json` detected. `package-lock.json` is present but contains no packages.
- Lockfile: `package-lock.json` present with empty `packages`; no Python lockfile detected.

## Frameworks

**Core:**
- World of Warcraft AddOn API - frame creation, events, settings, model scenes, stable info, pet journal, map APIs, and slash commands are used from `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `Settings.lua`, `GiuiceBattlePets.lua`, and `GiuiceHunterPetListItemMixin.lua`.
- Blizzard Settings API - addon settings category and proxy settings are registered in `Settings.lua`.
- Blizzard C_* APIs - stable, spell, map, talent, pet journal, timer, and model scene APIs are used in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceBattlePets.lua`, and `GiuiceHunterPetListItemMixin.lua`.

**Testing:**
- Python `unittest` - test modules under `tests/python/`, including `tests/python/test_source_cache.py`, `tests/python/test_refresh_data_cache.py`, `tests/python/test_wowhead_source.py`, `tests/python/test_data_records.py`, and `tests/python/test_lua_export.py`.
- Plain Lua assertions - standalone tests in `tests/map_pet_index_test.lua`, `tests/stable_list_state_test.lua`, and vendored `Libs/LibStub/tests/*.lua`.

**Build/Dev:**
- `scrapper.refresh_data` CLI - cache-first source collection and offline Lua generation in `scrapper/refresh_data.py`.
- `agent-browser` CLI - optional scraper backend invoked by `AgentBrowserFetcher` in `scrapper/refresh_data.py`.
- Python standard-library `urllib.request` - direct HTTP scraper backend in `scrapper/wowhead_source.py`.
- Manual addon packaging - `GiuiceHunterPets.zip` is present; no build script or release automation config was detected.

## Key Dependencies

**Critical:**
- `LibStub` minor `2` - library versioning shim loaded from `Libs/LibStub/LibStub.lua` and required by `GiuiceHunterPets.lua`.
- `CallbackHandler-1.0` minor `8` - callback library loaded from `Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua`.
- `AceLocale-3.0` minor `6` - localization library loaded from `Libs/AceLocale-3.0/AceLocale-3.0.lua` and used by `Localization.lua`, `Data.lua`, and `locales/*.lua`.
- `LibDataBroker-1.1` minor `4` - launcher data object library loaded from `Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua` and used in `GiuiceHunterPets.lua`.
- `LibDBIcon-1.0` version `v12.0.0`, minor `56` - minimap icon library loaded from `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua` and `Libs/LibDBIcon-1.0/LibDBIcon-1.0.toc`.
- `HereBeDragons-2.0` version `2.16-release`, minor `33` - map coordinate library loaded from `Libs/HereBeDragons/HereBeDragons-2.0.lua` and used by `GiuiceWorldMapButton.lua`.
- `HereBeDragons-Pins-2.0` minor `16` - map/minimap pin library loaded from `Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua` and used by `GiuiceWorldMapButton.lua`.

**Infrastructure:**
- Python standard library `argparse`, `json`, `hashlib`, `tempfile`, `threading`, `urllib.request`, `subprocess`, and `pathlib` - scraper CLI, cache, parsing, and file generation in `scrapper/`.
- Wowhead source pages - data source constants in `scrapper/wowhead_source.py` and source-shape documentation in `docs/research/data-refresh-runbook.md`.
- Local generated artifacts - `scrapper/generated/cache/`, `scrapper/generated/refresh-manifest.json`, `scrapper/generated/Data.sample.lua`, and diagnostic markdown files under `scrapper/generated/`.

## Configuration

**Environment:**
- Addon metadata and load order are configured in `GiuiceHunterPets.toc`.
- Persistent in-game settings are stored through the WoW saved variable `GHP_SavedVars`, declared in `GiuiceHunterPets.toc` and initialized in `Settings.lua` and `SavedVars.lua`.
- Runtime settings include `worldMapPins`, `tooltips`, `minimapPins`, `position`, and `minimap` in `Settings.lua` and `SavedVars.lua`.
- No `.env`, `.env.*`, or other secret-bearing environment files were detected during the repo scan.

**Build:**
- `GiuiceHunterPets.toc` controls addon packaging/load order.
- `GiuiceHunterPets.xml` defines frame templates loaded by the addon.
- `docs/research/data-refresh-runbook.md` documents refresh commands and production replacement checks.
- `scrapper/refresh_data.py` provides the CLI for source collection and Lua generation.
- `.gitignore` excludes `scrapper/generated/cache/` and `scrapper/generated/refresh-manifest.json`.
- No lint, formatter, bundler, or CI config was detected.

## Platform Requirements

**Development:**
- Work from repo root `/home/giuice/desenv/GiuiceHunterPets`.
- Use `rtk` as the shell command prefix per `AGENTS.md` and `/home/giuice/.codex/RTK.md`.
- Python 3.14.4 is available for `rtk python3 -m scrapper.refresh_data ...` and `rtk python3 -m unittest ...`.
- Optional `agent-browser` is used by the default scraper backend in `scrapper/refresh_data.py`; use `--backend python` to use `urllib.request` instead.
- A Lua interpreter is required to run `tests/map_pet_index_test.lua` and `tests/stable_list_state_test.lua` outside WoW.

**Production:**
- Deploy as a World of Warcraft addon directory matching `GiuiceHunterPets.toc`, typically under `Interface/AddOns/GiuiceHunterPets/`.
- Production runtime is the WoW client; addon code depends on Blizzard global APIs and bundled libraries under `Libs/`.
- Generated production data is loaded from `Data.lua`; generated stable-master output is currently produced under `scrapper/generated/StableMastersData.lua` according to `docs/research/data-refresh-runbook.md` but is not listed in `GiuiceHunterPets.toc`.

---

*Stack analysis: 2026-04-29*
