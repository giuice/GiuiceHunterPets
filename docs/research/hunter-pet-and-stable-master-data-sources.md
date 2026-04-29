# Hunter Pet And Stable Master Data Sources Research

## Questions

1. Is there an existing library, addon, or database with updated hunter pet spawn data that GiuiceHunterPets can safely reuse or import?
2. Is there an existing data source for stable master NPC locations that can be added to the addon?
3. What source and update process should replace or supplement the current local pet data?
4. How should the addon default map pins to rare pets for new installs without changing existing user settings?

## Current Code And Data To Inspect

- `Data.lua`
- `scrapper/`
- `GiuiceWorldMapButton.lua`
- `Settings.lua`
- `SavedVars.lua`
- `GiuiceHunterPets.toc`
- `MapPetIndex.lua`

## Sources To Check

- Existing WoW addons that track hunter pet locations.
- Aspect of the Hunter data/source and license.
- Warcraft Wiki hunter pet and stable master pages.
- Wowhead pages for hunter pet NPCs and stable master NPCs.
- Blizzard API availability for NPC/classification/map position data.
- HereBeDragons data capabilities and limitations.
- CurseForge/Wago addon licenses for any candidate data source.

## Source Evaluation Criteria

- **Coverage:** Retail target client, current zones, rare/elite/normal pets, stable masters.
- **Freshness:** How often the source updates after patches.
- **License:** Whether data can be copied, transformed, or bundled.
- **Structure:** Whether data maps cleanly to the current `GHP.pet_by_zones` shape.
- **Localization:** Whether names are locale-dependent or can use NPC IDs.
- **Maintenance:** Whether updates can be scripted or must be manual.
- **Reliability:** Whether coordinates are precise enough for map pins.

## Candidate Data Shapes

### Hunter Pet Spawn

```lua
{
    id = 2850,
    NpcId = 2850,
    name = "Broken Tooth",
    family = { 2, "Cat" },
    class = "Rare",
    zoneID = 1416,
    coords = {
        { 43.2, 37.6 },
    },
}
```

### Stable Master

```lua
{
    npcID = 99856,
    name = "Stable Master Name",
    zoneID = 84,
    coords = {
        { 67.8, 71.4 },
    },
    faction = "Alliance",
}
```

## Default Map Pin Setting Research

Current goal: new installs should default to rare pets to reduce map clutter.

Things to verify:

- Where `GHP_SavedVars.worldMapPins` is initialized.
- Whether missing/nil means default all pets today.
- How settings UI represents values:
  - `1`: all pets
  - `2`: rare pets
  - `3`: elite pets
  - `4`: no pets
- How to set the new default to `2` only when `GHP_SavedVars.worldMapPins == nil`.
- Existing users with a saved value must keep their choice.

## Research Tasks

- [x] Inspect current saved variable initialization and settings UI.
- [x] Identify at least 2 candidate hunter pet data sources.
- [x] Identify at least 2 candidate stable master location sources.
- [x] Record license/terms for each candidate.
- [x] Compare candidate data shape against `Data.lua`.
- [x] Decide whether stable masters should be a separate data table or merged into map-pin indexing.
- [x] Decide whether map pin default can be changed safely in the current maintenance phase or should be its own small phase.

## Findings

Research date: 2026-04-28.

### Browser Source Discovery

Discovery date: 2026-04-28/2026-04-29.

Tooling used:

- `agent-browser 0.26.0`
- Source pages:
  - `https://www.wowhead.com/hunter-pets`
  - `https://www.wowhead.com/pet=1/wolf`
  - `https://www.wowhead.com/npc=118/prowler`
  - `https://www.wowhead.com/search?q=stable%20master`

Confirmed page data shapes:

- The hunter pets index page exposes a structured `g_listviews.pets.data` object in page JavaScript.
  - Observed count: 60 pet families.
  - Family records include `id`, `name`, `exotic`, `diet`, `type`, `spells`, `minLevel`, `maxLevel`, and icon/popularity metadata.
- A hunter pet family page exposes a structured `g_listviews.tameable.data` object.
  - Example: `https://www.wowhead.com/pet=1/wolf` exposed 303 tameable wolf NPC rows.
  - Tameable rows include `id`, `name`, `family`, `classification`, `location`, `react`, `minlevel`, `maxlevel`, `type`, and display/name variants.
- An individual NPC page exposes `g_mapperData` when coordinates exist.
  - Example: `https://www.wowhead.com/npc=118/prowler` exposed `g_mapperData["12"][0]` with 73 coordinate pairs and `uiMapId = 37`, `uiMapName = "Elwynn Forest"`.
  - The same page exposed `g_npcs[118]` with NPC metadata matching the family list row.
- The Wowhead search page for stable masters exposes a structured `g_listviews.npcs.data` object.
  - Observed count: 440 NPC rows for `stable master`.
  - Rows include `id`, `name`, `tag`, `location`, `react`, `minlevel`, `maxlevel`, `classification`, and `type`.

Technical conclusion:

- The current source shape is embedded JavaScript/listview data, not a rendered-DOM-only shape.
- A repeatable exporter should prefer plain HTTP fetching plus extraction of Wowhead listview/global assignments where possible.
- Browser automation remains useful for discovery and spot checks, but should not be the core exporter unless HTTP extraction fails.
- Stable masters appear technically viable in the same collect-normalize-export flow: collect rows from the stable-master NPC list, enrich each NPC through its page-level `g_mapperData`, then export a separate stable master table.

Risks and constraints:

- Wowhead terms/licensing risks recorded below still apply. This finding confirms technical shape, not legal suitability for redistributing generated data.
- Some NPC pages may omit `g_mapperData`; the exporter must validate and reject rows without non-empty coordinates.
- Search results for stable masters include non-service or special-case NPCs, so the stable-master pipeline needs filtering/review before production export.

### Current Local State

- `Data.lua` defines `GHP.pet_by_zones` as a large static Lua array. The current shape already contains the fields needed for map pins: `zoneID`, `name`, `class`, `family`, `displayId`, `NpcId`, and `coords`.
- `scrapper/hunterpets.py` already stores scraped pet rows in SQLite and exports Lua-compatible pet data, but it depends on Playwright and Wowhead page structure.
- `SavedVars.lua` and `Settings.lua` both initialize `GHP_SavedVars.worldMapPins = 1`.
- `Settings.lua` also sets the proxy setting default to `1`, and `GetValue()` returns `GHP_SavedVars.worldMapPins or defaultValue`.
- `MapPetIndex.lua` treats nil settings as `1` through `settingValue or 1`.
- `GiuiceWorldMapButton.lua` has several `GHP_SavedVars.worldMapPins or 1` fallbacks, so changing the new-install default safely requires updating all fallback/default paths together.

### Candidate Hunter Pet Data Sources

| Source | Coverage/Freshness | License/Terms | Shape Fit | Notes |
| --- | --- | --- | --- | --- |
| Current Wowhead-based scraper | Broad NPC/pet coverage and coordinates when pages expose them; freshness is good if the scraper still works after Wowhead page changes. | Wowhead points to Fanbyte/ZAM terms. Terms grant only a personal, limited, non-commercial license, prohibit modifying/reproducing/distributing the service except as permitted, and prohibit crawlers/data mining tools other than provided search agents. Source: [Wowhead TOS](https://www.wowhead.com/tos), [Fanbyte/ZAM terms](https://corp.fanbyte.com/legal/terms?zaf_referer=https%3A%2F%2Fwww.wowhead.com%2F). | Strong fit: current scrapper already targets the existing `GHP.pet_by_zones` shape. | Technically convenient but legally/operationally risky as a bundled regenerated dataset source. Keep as internal research input only unless terms are clarified. |
| Petopia | Strong hunter-pet editorial coverage; site is active and copyright footer shows 2004-2026. | Petopia page footer says all rights reserved. Source: [Petopia](https://www.wow-petopia.com/php/). | Partial fit: useful for family/appearance/taming sanity checks, but no obvious structured downloadable coordinates API found. | Good manual validation source, not a data source to copy into the addon. |
| Aspect of the Hunter addon | Retail hunter pet hunting addon, last CurseForge release listed for 10.1.7 on 2023-11-13. | CurseForge lists `All Rights Reserved`. Source: [Aspect Of The Hunter](https://www.curseforge.com/wow/addons/aspect-of-the-hunter). | Likely similar map-pin/pet data internally, but not safe to copy. | Reference only. Not reusable without explicit permission. |
| Hunter Pets addon | Historical in-game browser with pet locations, latest release 2017. | CurseForge lists `All Rights Reserved`. Source: [Hunter Pets](https://www.curseforge.com/wow/addons/hunter-pets). | Likely has old pet-location data, but outdated and not safe to copy. | Reference only. Poor fit for modern retail. |
| Blizzard Game Data / Profile APIs | Official APIs include creature search/static data and character hunter-pets profile endpoints. | Official API access requires Battle.net auth and terms compliance. | Weak fit for this addon: public material found does not show NPC spawn coordinates or stable master coordinates. | A Blizzard forum answer says Wowhead location data comes from player-uploaded Wowhead Client data, not Blizzard's game data API. Source: [Blizzard API forum](https://us.forums.blizzard.com/en/blizzard/t/wow-creature-api-for-dungeon-npcs/11558/6). |
| Tamed addon | MIT addon, updated in 2026, but aimed at Classic pet abilities. | CurseForge lists MIT. Source: [Tamed](https://www.curseforge.com/wow/addons/tamed). | Poor fit for retail `GHP.pet_by_zones`; focuses ability-learning pets, not current retail tameable spawn coverage. | Useful only if a future Classic-specific branch needs ability data. |

### Candidate Stable Master Data Sources

| Source | Coverage/Freshness | License/Terms | Shape Fit | Notes |
| --- | --- | --- | --- | --- |
| Warcraft Wiki `Stable master` page | Large faction-grouped stable master list. Search result showed recent crawl and page updates in 2026. | Warcraft Wiki text is CC BY-SA 4.0 unless noted. Sources: [Stable master](https://warcraft.wiki.gg/wiki/Stable_master), [Warcraft Wiki copyrights](https://warcraft.wiki.gg/wiki/Warcraft_Wiki:Copyrights). | Partial fit: provides names, factions, and location text, but not consistent `npcID`, `zoneID`, or coordinates. | Best license-compatible seed for a curated stable master list if attribution/share-alike obligations are acceptable. Needs enrichment. |
| Warcraft Wiki `Category:Stable masters` pages | Broad index of stable master NPC pages. | CC BY-SA 4.0 unless noted. Source: [Category:Stable masters](https://warcraft.wiki.gg/wiki/Category:Stable_masters). | Partial fit: can discover NPC names/pages, but still needs IDs and coordinates. | Could be used to build a review queue, not direct map pins. |
| Wowhead NPC pages/filter | Strong chance of NPC IDs and coordinates per NPC page. | Same Fanbyte/ZAM terms risk as Wowhead pet scraping; automated extraction/data mining is specifically risky. | Strong technical fit if manually confirmed, but not safe as an automated bundled source without permission. | Useful for manual spot checks only. |
| In-game discovery / manual curation | Fully controlled if coordinates are collected by maintainers in-game. | Project-owned data if collected by project maintainers. | Strong fit: can directly record `npcID`, `name`, `zoneID`, `coords`, `faction`. | Safest path for an MVP covering major hubs; slower but legally clean. |
| HereBeDragons | Current project already vendors HereBeDragons. CurseForge lists BSD license and a 2026 release. Source: [HereBeDragons](https://www.curseforge.com/wow/addons/herebedragons). | BSD License. | Not a stable master data source; only map coordinate math and pin APIs. | Keep using it for rendering/coordinate conversion. It does not solve NPC discovery. |

### Data Shape Comparison

- Hunter pet data from the current scraper already maps to `GHP.pet_by_zones`; replacing it should preserve the current Lua table shape unless a future source cannot provide one of the fields.
- Stable masters should not be merged into `GHP.pet_by_zones`. They are not pets, should not use pet family icons, should not be filtered by pet rarity, and should not appear on the minimap per `SPEC.md`.
- A separate `GHP.stable_masters` table plus `BuildStableMasterIndex(stableMasters)` is the cleanest shape. It keeps map rendering shared but filtering/data semantics separate.

### Default Map Pin Setting

- The default can be changed safely as its own small phase.
- Required changes must be coordinated across:
  - `SavedVars.lua`: do not seed new saved variables with `worldMapPins = 1`.
  - `Settings.lua`: proxy setting default should become `2`, and `GetValue()` should distinguish `nil` from valid saved values.
  - `MapPetIndex.lua`: `GetPetsForMap(..., nil)` should resolve to rare pets (`2`), not all pets (`1`).
  - `GiuiceWorldMapButton.lua`: remove `or 1` fallbacks for world-map/minimap pin filtering and pin cache keys.
- Existing users with `worldMapPins = 1`, `3`, or `4` should be preserved because those explicit values are non-nil.

## Recommended Approach

1. Do not copy bundled pet or stable master data from other CurseForge addons unless the author grants explicit permission. The useful retail hunter-pet addons found are `All Rights Reserved`.
2. Treat Wowhead as high-risk for automated regeneration. The current scraper can remain documented as an existing internal tool, but it should not be presented as a clean reusable source of truth without resolving terms/permission.
3. Use a two-lane data strategy:
   - Hunter pets: keep the current checked-in `Data.lua` as the last-known-good dataset, then harden/document the current exporter. For updates, prefer manual review of diffs and source attribution notes.
   - Stable masters: start with a small project-owned/manual dataset for major hubs, using Warcraft Wiki CC BY-SA pages as a discovery/reference source if the project is willing to satisfy attribution/share-alike requirements.
4. Implement the default map-pin change separately before stable master integration. It is low-risk and independent from the data-source uncertainty.

## Open Follow-Up Questions

- Is this addon intended to be distributed under a license compatible with CC BY-SA-derived stable master data? If not, Warcraft Wiki should be reference-only, not copied/transformed into bundled data.
- Should the initial stable master MVP cover only capital/current-expansion hubs, or all stable masters listed by Warcraft Wiki?
- Should we contact Aspect of the Hunter / Petopia maintainers for permission or data collaboration before investing in our own update pipeline?
