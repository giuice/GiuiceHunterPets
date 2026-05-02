# External Integrations

**Analysis Date:** 2026-04-29

## APIs & External Services

**World of Warcraft Client APIs:**
- Blizzard AddOn/UI runtime - creates frames, templates, model scenes, settings, events, and slash commands.
  - SDK/Client: built-in WoW Lua API via `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `Settings.lua`, `GiuiceBattlePets.lua`, `GiuiceHunterPetListItemMixin.lua`, and `GiuiceHunterPets.xml`
  - Auth: game client session; no addon-managed credentials
- Stable/Pet APIs - reads hunter stable and pet information.
  - SDK/Client: `C_StableInfo` in `GiuiceHunterPets.lua` and `GiuiceHunterPetListItemMixin.lua`; `C_PetJournal` in `GiuiceBattlePets.lua`
  - Auth: game client session
- Map/World APIs - reads player map state and renders pins.
  - SDK/Client: `C_Map`, `WorldMapFrame`, `Minimap`, `HereBeDragons-2.0`, and `HereBeDragons-Pins-2.0` in `GiuiceWorldMapButton.lua`
  - Auth: game client session
- Spell/Talent APIs - resolves ability icons, active pets, and Animal Companion state.
  - SDK/Client: `C_Spell`, `C_SpellBook`, `C_ClassTalents`, and `C_Traits` in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, and `GiuiceHunterPetListItemMixin.lua`
  - Auth: game client session

**External Data Sources:**
- Wowhead - source pages for hunter pet families, tameable NPCs, NPC map coordinates, and stable master search data.
  - SDK/Client: Python standard-library `urllib.request` in `scrapper/wowhead_source.py`
  - Auth: none; requests send a browser-like `User-Agent` header in `scrapper/wowhead_source.py`
- Wowhead through browser automation - alternate backend for pages that need a browser context.
  - SDK/Client: `agent-browser` CLI invoked through `subprocess.run` by `AgentBrowserFetcher` in `scrapper/refresh_data.py`
  - Auth: none configured in repo

**Third-Party Addon Libraries:**
- WoW Ace/local addon ecosystem libraries - bundled libraries used at runtime.
  - SDK/Client: `Libs/LibStub/LibStub.lua`, `Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua`, `Libs/AceLocale-3.0/AceLocale-3.0.lua`, `Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua`, `Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua`, and `Libs/HereBeDragons/`
  - Auth: not applicable

## Data Storage

**Databases:**
- Local SQLite artifact detected at `scrapper/wow_pets.db`.
  - Connection: local file path only; no connection string or runtime client detected in current Python modules
  - Client: Not detected in active source files

**File Storage:**
- Local filesystem only.
- Addon data is stored in Lua files such as `Data.lua`, `scrapper/generated/Data.lua`, `scrapper/generated/Data.sample.lua`, `scrapper/hunter_pets.lua`, `scrapper/families_data.lua`, and `scrapper/zones.lua`.
- Scraper source cache stores fetched Wowhead HTML under `scrapper/generated/cache/` and records metadata in `scrapper/generated/refresh-manifest.json`.
- Scraper diagnostics are markdown files under `scrapper/generated/`, including `scrapper/generated/pet-refresh-blockers.md`, `scrapper/generated/stable-master-blockers.md`, and `scrapper/generated/pet-skipped.md`.
- WoW saved variables are stored by the game client through `GHP_SavedVars`, declared in `GiuiceHunterPets.toc` and initialized in `Settings.lua` and `SavedVars.lua`.

**Caching:**
- File-based scraper cache implemented by `SourceCache` in `scrapper/source_cache.py`.
- Cache keys are SHA-256 hashes of normalized URLs; cached pages are written as `.html` files under `scrapper/generated/cache/`.
- Cache manifest entries include `url`, `role`, `status`, `path`, `fetched_at`, and `error` in `scrapper/generated/refresh-manifest.json`.
- `.gitignore` excludes `scrapper/generated/cache/` and `scrapper/generated/refresh-manifest.json`.

## Authentication & Identity

**Auth Provider:**
- No application-managed auth provider detected.
  - Implementation: the addon runs inside an authenticated WoW client session and relies on Blizzard-provided runtime APIs.
- Wowhead scraper uses unauthenticated HTTP/browser fetches.
  - Implementation: `fetch_text()` in `scrapper/wowhead_source.py` sends static request headers; `AgentBrowserFetcher` in `scrapper/refresh_data.py` shells out to `agent-browser`.

## Monitoring & Observability

**Error Tracking:**
- None detected.

**Logs:**
- WoW addon runtime uses visible UI state and standard Lua errors/assertions, including library asserts in `GiuiceHunterPets.lua`.
- Scraper CLI prints progress and failure summaries from `scrapper/refresh_data.py`.
- Scraper failures are persisted to local markdown diagnostics in `scrapper/generated/pet-refresh-blockers.md`, `scrapper/generated/stable-master-blockers.md`, `scrapper/generated/pet-validation-errors.md`, and `scrapper/generated/stable-master-validation-errors.md`.
- Scraper cache status and errors are persisted in `scrapper/generated/refresh-manifest.json` by `scrapper/source_cache.py`.

## CI/CD & Deployment

**Hosting:**
- World of Warcraft addon distribution; no hosted web service detected.
- `GiuiceHunterPets.zip` is present as a packaged artifact.
- `readme.md` references GitHub repository `https://github.com/giuice/GiuiceHunterPets`.

**CI Pipeline:**
- None detected. No GitHub Actions, tox, pytest, package scripts, or other CI config was found in the scanned repo files.

## Environment Configuration

**Required env vars:**
- None detected.

**Secrets location:**
- Not applicable. No `.env`, credential, key, or secret files were detected.

## Webhooks & Callbacks

**Incoming:**
- None detected for network webhooks.
- WoW runtime event callbacks are registered in `GiuiceHunterPets.lua`, `GiuiceWorldMapButton.lua`, `GiuiceTooltipEnhancement.lua`, and `GiuiceHunterPetListItemMixin.lua`.

**Outgoing:**
- None detected for network webhooks.
- Outgoing HTTP/browser requests go to Wowhead URLs defined in `scrapper/wowhead_source.py`: `https://www.wowhead.com/hunter-pets`, `https://www.wowhead.com/pet=<family-id>`, `https://www.wowhead.com/npc=<npc-id>`, and `https://www.wowhead.com/search?q=stable%20master`.
- Optional browser-control subprocess calls execute `agent-browser open`, `agent-browser eval`, and `agent-browser close` from `scrapper/refresh_data.py`.

---

*Integration audit: 2026-04-29*
