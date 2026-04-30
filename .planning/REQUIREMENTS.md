# Requirements: GiuiceHunterPets

**Defined:** 2026-04-30
**Core Value:** The addon must be able to produce complete, validated hunter pet location data even when individual Wowhead pages are malformed, missing mapper data, or temporarily unavailable.

## v1 Requirements

### Fallback Data

- [ ] **DATA-01**: Maintainer can load historical pet records from production `Data.lua` into `PetRecord` objects keyed by NPC ID.
- [ ] **DATA-02**: Shipped-baseline fallback loading excludes records with missing/zero `zoneID` before Lua export validation.
- [ ] **DATA-03**: Shipped-baseline fallback loading preserves every valid coordinate pair, discards malformed coordinate entries, and excludes a record only when no valid coordinate pair remains.
- [ ] **DATA-04**: Missing `Data.lua` path returns an empty fallback set without failing the build.

### Pet Build

- [ ] **PET-01**: Maintainer can run `build-pets --from-cache` and continue past an empty or malformed individual pet family without aborting the whole build.
- [ ] **PET-02**: Maintainer can run `build-pets --from-cache` and recover a failed current Wowhead-listed pet from shipped `Data.lua` fallback when a valid fallback record exists.
- [ ] **PET-03**: Scraped pet records replace shipped-baseline fallback records whenever scraping succeeds for the same NPC ID.
- [ ] **PET-04**: Shipped-baseline fallback records use the current Wowhead family ID and family name when recovered during a family iteration.
- [ ] **PET-05**: Pets that fail scraping and have no valid shipped-baseline fallback are recorded in `scrapper/generated/pet-skipped.md` without stopping the build.
- [ ] **PET-06**: Pet build returns failure only when no pet records can be produced or final validation fails.
- [ ] **PET-07**: Pet build writes `pet-fallback.md` listing records recovered from shipped-baseline fallback.
- [ ] **PET-08**: Pet build writes `pet-scraper-vs-baseline-diff.md` for audit-only zone or coordinate discrepancies between successful scrape and shipped-baseline fallback.

### Collection

- [ ] **COLL-01**: Pet source collection does not fetch NPC pages for tameable rows with no location data.
- [ ] **COLL-02**: Single-page fetch failures are recorded in the manifest and skipped without consuming successful page budget.
- [ ] **COLL-03**: A collection run can complete with recorded page errors instead of relying on an external retry loop.

### Stable Masters

- [ ] **STBL-01**: Stable master build skips isolated malformed or missing stable-master NPC mapper pages.
- [ ] **STBL-02**: Stable master build fails when zero stable master records can be produced or final validation fails.
- [ ] **STBL-03**: Stable master skipped records are written to `scrapper/generated/stable-master-skipped.md`.

### Manifest

- [ ] **MANI-01**: Build parsing can mark a stale `parse_error` or `error` manifest entry as `ok` after a full successful listview parse and row validation.
- [ ] **MANI-02**: Mapper source parsing can mark a stale `parse_error` or `error` manifest entry as `ok` only after mapper extraction and location validation succeeds.
- [ ] **MANI-03**: Partial or failed parses do not heal manifest error entries.

### Documentation and Verification

- [ ] **DOCS-01**: Refresh runbook explains that the outer `while true` collection loop is no longer required.
- [ ] **TEST-01**: Python tests cover shipped-baseline fallback loading, fallback eligibility filtering, partial coordinate salvage, skip-and-continue pet builds, diff reporting, stable master skip behavior, collection error handling, and manifest healing.
- [ ] **TEST-02**: The cache-backed pet build verification command exits 0 and writes a Lua output containing `GHP.pet_by_zones = {` after the pet fallback phase.

## v2 Requirements

### Runtime and Packaging

- **RUN-01**: Addon runtime can load and display stable master data after stable master data generation is validated.
- **RUN-02**: World map and minimap pins reuse or pool frames when map data grows.
- **PKG-01**: Release packaging verifies `.toc` path casing, zip freshness, and generated data presence.

### Refresh Enhancements

- **REFR-01**: Maintainer can prune or summarize the large HTML source cache without losing useful diagnostics.
- **REFR-02**: Refresh backend can be swapped or hardened after the fallback build path is stable.
- **REFR-03**: DOM-marker fallback can recover mapper coordinates when both scraping and shipped-baseline fallback are insufficient.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Parallel collection | Completeness is the immediate priority; concurrency adds rate-limit and race complexity. |
| Lower request delay | Speed tuning is unrelated to making cache-backed builds resilient. |
| Stable master fallback | There is no shipped stable master baseline and the historical DB has no stable master data. |
| Runtime UI refactor | Existing UI concerns are real but separate from refresh-data correctness. |
| Production `Data.lua` replacement | Generated output must be validated and reviewed before replacing runtime data. |
| Removing deprecated CLI aliases | Useful cleanup, but not required for the resilient refresh milestone. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 1 | Pending |
| DATA-02 | Phase 1 | Pending |
| DATA-03 | Phase 1 | Pending |
| DATA-04 | Phase 1 | Pending |
| PET-01 | Phase 2 | Pending |
| PET-02 | Phase 2 | Pending |
| PET-03 | Phase 2 | Pending |
| PET-04 | Phase 2 | Pending |
| PET-05 | Phase 2 | Pending |
| PET-06 | Phase 2 | Pending |
| PET-07 | Phase 2 | Pending |
| PET-08 | Phase 2 | Pending |
| COLL-01 | Phase 3 | Pending |
| STBL-01 | Phase 4 | Pending |
| STBL-02 | Phase 4 | Pending |
| STBL-03 | Phase 4 | Pending |
| COLL-02 | Phase 5 | Pending |
| COLL-03 | Phase 5 | Pending |
| MANI-01 | Phase 6 | Pending |
| MANI-02 | Phase 6 | Pending |
| MANI-03 | Phase 6 | Pending |
| DOCS-01 | Phase 5 | Pending |
| TEST-01 | Phase 6 | Pending |
| TEST-02 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0

---
*Requirements defined: 2026-04-30*
*Last updated: 2026-04-30 after initial definition*
