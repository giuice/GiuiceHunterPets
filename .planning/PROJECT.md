# GiuiceHunterPets

## What This Is

GiuiceHunterPets is a World of Warcraft hunter addon that helps players inspect their stable, view hunter pet families, and find tameable pets on the world map, minimap, and unit tooltips. The addon runtime depends on generated Lua pet-location data, while the Python refresh pipeline collects and validates Wowhead source pages before producing that data.

The current project focus is to make the refresh pipeline resilient: the checked-in production `Data.lua` is treated as the trusted shipped baseline for historical pet data, and Wowhead scraping becomes a corrective/additive update layer instead of a single point of failure. `scrapper/wow_pets.db` remains useful as a structured auxiliary artifact, but it must be compared against `Data.lua` before it can influence fallback behavior.

## Core Value

The addon must be able to produce complete, validated hunter pet location data even when individual Wowhead pages are malformed, missing mapper data, or temporarily unavailable.

The product truth behind every data-quality tradeoff is the hunter's search experience: partial but trustworthy location guidance is more valuable than no guidance. When choosing between hiding a pet and showing validated partial information such as a zone, area, or salvaged coordinates, prefer the option that best helps a hunter narrow the search in-game.

## Requirements

### Validated

- [validated] WoW addon runtime loads hunter stable UI, map/minimap pins, tooltip enhancement, localization, settings, and generated pet data through `GiuiceHunterPets.toc` - existing
- [validated] Python refresh pipeline can collect Wowhead source pages into a resumable local cache and build Lua pet/stable-master data from cached sources - existing
- [validated] Generated pet records are normalized through typed Python records and validated before Lua export - existing
- [validated] Pure Lua helper behavior for stable-list state and map pet indexes has local test coverage - existing
- [validated] Codebase map documents architecture, structure, integrations, and known concerns for downstream planning - existing

### Active

- [ ] Build pet data from available Wowhead records while skipping isolated per-family or per-pet failures.
- [ ] Load historical fallback pet records from production `Data.lua` and use them only when the current Wowhead scrape for the same listed pet fails.
- [ ] Preserve Wowhead as authoritative for current tameable listings and family classification.
- [ ] Produce audit reports for skipped pets, shipped-baseline fallback usage, and scraper-vs-baseline coordinate or zone discrepancies.
- [ ] Avoid collecting NPC pages for tameable rows that have no location data.
- [ ] Make stable master generation skip isolated malformed NPC records and fail only when no valid records can be produced.
- [ ] Make collection resilient to single-page fetch failures without consuming successful page budget.
- [ ] Heal stale manifest error entries only after a full successful parse and validation pass.
- [ ] Update tests and the data refresh runbook to lock in the new resilient-refresh contract.

### Out of Scope

- Backend swap from `agent-browser` to `urllib` - deferred; current priority is completeness, not transport changes.
- Lowering refresh delay, adding concurrency, or optimizing request speed - deferred because completeness is more important than speed.
- DOM-marker fallback for pages without `g_mapperData` - deferred while shipped `Data.lua` fallback covers the same practical pet-location cases.
- Stable master fallback - deferred because there is no shipped stable master baseline, the historical DB has no stable master data, and the feature has not shipped.
- Runtime UI refactors, frame pooling, pin clustering, packaging cleanup, and locale/API compatibility work - important but unrelated to the refresh resilience milestone.
- Carrying pets that disappeared from Wowhead but still exist in `Data.lua` or the DB - excluded so current Wowhead tameable listings remain the inclusion gate.

## Context

- The repository is a brownfield WoW addon with a root Lua runtime, vendored addon libraries, generated `Data.lua`, and a Python refresh toolchain in `scrapper/`.
- `docs/PLAN.md` documents the immediate implementation plan: make `build-pets --from-cache` succeed despite bad pages by merging successful scraper output with validated fallback records from shipped `Data.lua`.
- Existing codebase concerns show the current Python refresh tests are red, with many failures tied to manifest status-contract changes. Refresh work should include contract-focused test updates, not broad unrelated cleanup.
- Current known pet blockers include malformed or missing mapper data such as `npc=118244`, and the local cache is large enough that reusing existing cached HTML matters.
- The project has a local SQLite artifact at `scrapper/wow_pets.db` with historical pet data, coordinates, `mapID`, family IDs, and metadata. This DB is an auxiliary comparison source, not the trusted baseline; production `Data.lua` is more reliable because it is the shipped addon data players already use.
- `scrapper/lua_export.py` rejects records without `zone_id` or coordinates, so fallback loading must discard rows with missing/zero `zoneID` and rows with no valid coordinate pairs before build-time use. If a row has some malformed coordinates and some valid coordinates, keep the valid coordinates because one accurate location is more useful to a hunter than hiding the pet entirely.
- Data decisions should be evaluated from a hunter's perspective: if the addon can provide validated partial guidance that narrows where to look, that is usually better than omitting the pet entirely. The implementation should still avoid exporting records that fail current validation, but planning should favor salvage and audit over unnecessary data loss.
- Refresh diagnostics live under `scrapper/generated/`, including blocker, skipped, validation, fallback, and future diff reports.

## Constraints

- **Surgical scope**: Touch only refresh pipeline, focused Python tests, and the refresh runbook for this milestone.
- **Data integrity**: Do not replace production `Data.lua` unless generated output validates and skipped/fallback reports have been reviewed.
- **Fallback eligibility**: Drop fallback rows with missing/zero `zoneID`; salvage valid coordinate pairs and drop a row only when no valid coordinate pair remains.
- **Hunter-first data salvage**: Prefer preserving validated partial pet-location guidance over returning no information, because the addon exists to help hunters find pets in-game.
- **Authority order**: Scraped Wowhead records win when they succeed; shipped `Data.lua` fallback fills gaps only for pets still present in current Wowhead tameable family lists.
- **Family classification**: When fallback is used, override the shipped baseline family with the current Wowhead family from the family iteration.
- **Collection behavior**: A failed fetch should be recorded and skipped without counting against the successful page collection budget.
- **Manifest healing**: A stale error can become `ok` only after the relevant source fully parses and validates.
- **Verification**: Use Python unit tests for refresh behavior and run the cache-backed build command after the pet fallback milestone.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat production `Data.lua` as the trusted shipped pet baseline | It is the addon data already consumed by players and therefore a safer fallback baseline than an auxiliary DB whose relationship to the shipped data must be proven | Pending |
| Treat `scrapper/wow_pets.db` as auxiliary comparison data | It may have generated the shipped data and is structured, but should not override `Data.lua` without explicit audit | Pending |
| Keep Wowhead as current listing gate | Prevents removed pets from being carried forward solely because they exist in historical baseline or DB data | Pending |
| Scraper wins over shipped baseline when scrape succeeds | Current Wowhead data should correct historical coordinates/classification when available | Pending |
| Log scraper-vs-baseline diffs instead of blocking | Coordinate and zone drift needs human audit but should not stop a complete build | Pending |
| Optimize data decisions for hunters finding pets | A hunter benefits more from trustworthy partial guidance that narrows the search area than from the addon hiding the pet entirely | Pending |
| Keep stable master fallback out of v1 | There is no shipped stable master baseline, the DB has no stable master source, and stable master addon support is not yet shipped | Pending |
| Preserve existing delays/backend/concurrency | The current milestone prioritizes completeness over refresh speed | Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-30 after initialization*
