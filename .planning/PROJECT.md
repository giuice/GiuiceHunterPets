# GiuiceHunterPets

## What This Is

GiuiceHunterPets is a World of Warcraft hunter addon that helps players inspect their stable, view hunter pet families, and find tameable pets on the world map, minimap, and unit tooltips. The addon runtime depends on generated Lua pet-location data, while the Python refresh pipeline collects and validates Wowhead source pages before producing that data.

The current project focus is to make the refresh pipeline resilient: `scrapper/wow_pets.db` is treated as the source of truth for historical pet data, and Wowhead scraping becomes a corrective/additive update layer instead of a single point of failure.

## Core Value

The addon must be able to produce complete, validated hunter pet location data even when individual Wowhead pages are malformed, missing mapper data, or temporarily unavailable.

## Requirements

### Validated

- [validated] WoW addon runtime loads hunter stable UI, map/minimap pins, tooltip enhancement, localization, settings, and generated pet data through `GiuiceHunterPets.toc` - existing
- [validated] Python refresh pipeline can collect Wowhead source pages into a resumable local cache and build Lua pet/stable-master data from cached sources - existing
- [validated] Generated pet records are normalized through typed Python records and validated before Lua export - existing
- [validated] Pure Lua helper behavior for stable-list state and map pet indexes has local test coverage - existing
- [validated] Codebase map documents architecture, structure, integrations, and known concerns for downstream planning - existing

### Active

- [ ] Build pet data from available Wowhead records while skipping isolated per-family or per-pet failures.
- [ ] Load historical fallback pet records from `scrapper/wow_pets.db` and use them only when the current Wowhead scrape for the same listed pet fails.
- [ ] Preserve Wowhead as authoritative for current tameable listings and family classification.
- [ ] Produce audit reports for skipped pets, DB fallback usage, and scraper-vs-DB coordinate or zone discrepancies.
- [ ] Avoid collecting NPC pages for tameable rows that have no location data.
- [ ] Make stable master generation skip isolated malformed NPC records and fail only when no valid records can be produced.
- [ ] Make collection resilient to single-page fetch failures without consuming successful page budget.
- [ ] Heal stale manifest error entries only after a full successful parse and validation pass.
- [ ] Update tests and the data refresh runbook to lock in the new resilient-refresh contract.

### Out of Scope

- Backend swap from `agent-browser` to `urllib` - deferred; current priority is completeness, not transport changes.
- Lowering refresh delay, adding concurrency, or optimizing request speed - deferred because completeness is more important than speed.
- DOM-marker fallback for pages without `g_mapperData` - deferred while DB fallback covers the same practical cases.
- Stable master DB fallback - deferred because the historical DB has no stable master data and the feature has not shipped.
- Runtime UI refactors, frame pooling, pin clustering, packaging cleanup, and locale/API compatibility work - important but unrelated to the refresh resilience milestone.
- Carrying pets that disappeared from Wowhead but still exist in the DB - excluded so current Wowhead tameable listings remain the inclusion gate.

## Context

- The repository is a brownfield WoW addon with a root Lua runtime, vendored addon libraries, generated `Data.lua`, and a Python refresh toolchain in `scrapper/`.
- `docs/PLAN.md` documents the immediate implementation plan: make `build-pets --from-cache` succeed despite bad pages by merging successful scraper output with validated DB fallback records.
- Existing codebase concerns show the current Python refresh tests are red, with many failures tied to manifest status-contract changes. Refresh work should include contract-focused test updates, not broad unrelated cleanup.
- Current known pet blockers include malformed or missing mapper data such as `npc=118244`, and the local cache is large enough that reusing existing cached HTML matters.
- The project has a local SQLite artifact at `scrapper/wow_pets.db` with historical pet data, coordinates, `mapID`, family IDs, and metadata. The active plan treats this DB as the historical source of truth.
- `scrapper/lua_export.py` rejects records without `zone_id` or coordinates, so fallback loading must discard DB rows with null/zero `mapID` or empty coordinate data before build-time use.
- Refresh diagnostics live under `scrapper/generated/`, including blocker, skipped, validation, fallback, and future diff reports.

## Constraints

- **Surgical scope**: Touch only refresh pipeline, focused Python tests, and the refresh runbook for this milestone.
- **Data integrity**: Do not replace production `Data.lua` unless generated output validates and skipped/fallback reports have been reviewed.
- **Fallback eligibility**: Drop fallback rows with null/zero `mapID` or empty coordinates before they can reach Lua export validation.
- **Authority order**: Scraped Wowhead records win when they succeed; DB fallback fills gaps only for pets still present in current Wowhead tameable family lists.
- **Family classification**: When DB fallback is used, override the DB family with the current Wowhead family from the family iteration.
- **Collection behavior**: A failed fetch should be recorded and skipped without counting against the successful page collection budget.
- **Manifest healing**: A stale error can become `ok` only after the relevant source fully parses and validates.
- **Verification**: Use Python unit tests for refresh behavior and run the cache-backed build command after the pet fallback milestone.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat `scrapper/wow_pets.db` as historical fallback source of truth | It contains broad, previously validated pet data and prevents total data loss when Wowhead pages fail | Pending |
| Keep Wowhead as current listing gate | Prevents removed pets from being carried forward solely because they exist in historical DB data | Pending |
| Scraper wins over DB when scrape succeeds | Current Wowhead data should correct historical coordinates/classification when available | Pending |
| Log scraper-vs-DB diffs instead of blocking | Coordinate and zone drift needs human audit but should not stop a complete build | Pending |
| Keep stable master fallback out of v1 | The DB has no stable master source, and stable master addon support is not yet shipped | Pending |
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
