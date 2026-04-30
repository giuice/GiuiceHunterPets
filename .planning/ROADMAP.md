# Roadmap: GiuiceHunterPets

**Created:** 2026-04-30
**Granularity:** Coarse
**Core Value:** The addon must be able to produce complete, validated hunter pet location data even when individual Wowhead pages are malformed, missing mapper data, or temporarily unavailable.

## Phase Overview

| Phase | Name | Goal | Requirements | Success Criteria |
|-------|------|------|--------------|------------------|
| 1 | DB Fallback Reader | Establish safe historical pet fallback loading from SQLite. | DATA-01, DATA-02, DATA-03, DATA-04 | 4 |
| 2 | Resilient Pet Build | Merge successful Wowhead scrape records with DB fallback and audit reports. | PET-01, PET-02, PET-03, PET-04, PET-05, PET-06, PET-07, PET-08, TEST-02 | 5 |
| 3 | Location-Aware Collection | Avoid collecting NPC pages that cannot produce pet records. | COLL-01 | 3 |
| 4 | Stable Master Skip-And-Continue | Make stable master generation resilient to isolated bad NPC pages. | STBL-01, STBL-02, STBL-03 | 3 |
| 5 | Collection Error Resilience | Record page fetch failures without aborting collection or consuming page budget. | COLL-02, COLL-03, DOCS-01 | 4 |
| 6 | Manifest Healing and Full Verification | Heal stale error entries after successful parses and complete the regression suite. | MANI-01, MANI-02, MANI-03, TEST-01 | 4 |

## Phases

### Phase 1: DB Fallback Reader

**Goal:** Add a small read-only SQLite loader that converts valid historical DB rows into `PetRecord` fallback records.

**Requirements:** DATA-01, DATA-02, DATA-03, DATA-04

**Success Criteria:**
1. `load_existing_pet_records(Path("scrapper/wow_pets.db"))` returns `dict[int, PetRecord]`.
2. Rows with null/zero `mapID` or empty coordinates are excluded before export validation.
3. Multi-coordinate DB rows parse into `tuple[tuple[float, float], ...]`.
4. A missing DB file returns `{}` and logs or reports the absence without breaking builds.

**Suggested Plans:**
- Create `scrapper/existing_pet_db.py` with focused SQLite read and coordinate parsing.
- Add `tests/python/test_existing_pet_db.py` fixtures for valid rows, invalid rows, multi-coords, and missing DB file.

### Phase 2: Resilient Pet Build

**Goal:** Change pet generation from fail-fast to skip-and-continue with DB fallback, audit logs, and cache-backed build verification.

**Requirements:** PET-01, PET-02, PET-03, PET-04, PET-05, PET-06, PET-07, PET-08, TEST-02

**Success Criteria:**
1. A per-pet `SourceFetchError` uses DB fallback when available and records the recovery in `pet-fallback.md`.
2. Scraped records win over DB fallback and zone/coordinate discrepancies are written to `pet-scraper-vs-db-diff.md`.
3. Empty or malformed individual family/pet sources are skipped and recorded without aborting when other records exist.
4. The build exits 1 only when no records are produced or final validation fails.
5. `python3 -m scrapper.refresh_data build-pets --from-cache --output /tmp/Data.test.lua` exits 0 and writes `GHP.pet_by_zones = {` after known bad pages are handled.

**Suggested Plans:**
- Pass fallback records from `main()` into `generate_pets()`.
- Update report writing for skipped, fallback, and scraper-vs-DB diff files.
- Update existing fail-fast tests in place and add fallback/diff tests.

### Phase 3: Location-Aware Collection

**Goal:** Reduce wasted collection by skipping current Wowhead tameable rows that have no location data.

**Requirements:** COLL-01

**Success Criteria:**
1. `_tameable_npc_ids_from_source()` excludes rows where `location` is missing or empty.
2. Rows with valid location data are still fetched normally.
3. Tests cover both skipped and retained rows without changing build-time row normalization behavior.

**Suggested Plans:**
- Add a location guard before appending tameable NPC IDs.
- Add two focused tests in `tests/python/test_refresh_data_cache.py`.

### Phase 4: Stable Master Skip-And-Continue

**Goal:** Apply the same isolated-record resilience to stable master generation, without inventing a fallback source.

**Requirements:** STBL-01, STBL-02, STBL-03

**Success Criteria:**
1. Per-stable-master NPC source failures are skipped and written to `stable-master-skipped.md`.
2. Stable master build exits 1 when zero records are produced or validation fails.
3. Existing stable master tests are updated to assert the new contract.

**Suggested Plans:**
- Replace per-record fatal returns in `generate_stable_masters()` with skipped logging.
- Preserve fatal behavior for malformed search/index sources.

### Phase 5: Collection Error Resilience

**Goal:** Make collection commands complete with recorded page errors and clarify the runbook.

**Requirements:** COLL-02, COLL-03, DOCS-01

**Success Criteria:**
1. `_collect_one()` catches fetch exceptions, records the error, prints a skipped line, and returns `True`.
2. Fetch error paths do not call `budget.mark_collected()`.
3. Existing systemic failure handling for index/family parse errors remains intact.
4. `docs/research/data-refresh-runbook.md` explains that an outer retry loop is no longer required.

**Suggested Plans:**
- Update `_collect_one()` behavior and targeted collection tests.
- Add the runbook paragraph after test behavior is settled.

### Phase 6: Manifest Healing and Full Verification

**Goal:** Let successful build parses repair stale manifest errors and prove the whole refresh contract with tests.

**Requirements:** MANI-01, MANI-02, MANI-03, TEST-01

**Success Criteria:**
1. `SourceCache.mark_ok()` changes stale `parse_error` or `error` entries to `ok` only after successful parsing.
2. Listview sources heal only after list extraction, row shape checks, and optional row validation all pass.
3. Mapper sources heal only after mapper extraction and caller validation succeed.
4. `python3 -m unittest discover -s tests/python` passes or any remaining failures are unrelated and explicitly documented.

**Suggested Plans:**
- Add `mark_ok()` to `scrapper/source_cache.py`.
- Call it from listview and mapper success paths after full validation.
- Add tests for healing and non-healing partial failures.

## Requirement Coverage

| Requirement | Phase |
|-------------|-------|
| DATA-01 | Phase 1 |
| DATA-02 | Phase 1 |
| DATA-03 | Phase 1 |
| DATA-04 | Phase 1 |
| PET-01 | Phase 2 |
| PET-02 | Phase 2 |
| PET-03 | Phase 2 |
| PET-04 | Phase 2 |
| PET-05 | Phase 2 |
| PET-06 | Phase 2 |
| PET-07 | Phase 2 |
| PET-08 | Phase 2 |
| COLL-01 | Phase 3 |
| STBL-01 | Phase 4 |
| STBL-02 | Phase 4 |
| STBL-03 | Phase 4 |
| COLL-02 | Phase 5 |
| COLL-03 | Phase 5 |
| MANI-01 | Phase 6 |
| MANI-02 | Phase 6 |
| MANI-03 | Phase 6 |
| DOCS-01 | Phase 5 |
| TEST-01 | Phase 6 |
| TEST-02 | Phase 2 |

**Coverage:** 24/24 v1 requirements mapped.

## Next Up

**Phase 1: DB Fallback Reader** - Establish safe fallback data loading before changing build behavior.

`$gsd-plan-phase 1`

---
*Roadmap created: 2026-04-30*
