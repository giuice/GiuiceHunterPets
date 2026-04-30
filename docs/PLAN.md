# Plan — Resilient Refresh + Data.lua Baseline Fallback

## Context

The Wowhead refresh pipeline at `scrapper/refresh_data.py` aborts the build on the first per-pet failure (lines 362-366). User has 2,659+ cached HTML pages on disk, but at least one bad page (e.g. `npc=118244` with no `g_mapperData`) blocks the whole build.

**The architectural correction:** rename what the pipeline IS.

> **The checked-in production `Data.lua` is the trusted shipped baseline for hunter pet location data. It is the data shape already consumed by the addon and validated by real player use. Wowhead scraping applies corrective/additive updates when it succeeds. `scrapper/wow_pets.db` is only a structured auxiliary source because it may have helped generate the shipped data; it must not be treated as more authoritative than `Data.lua` without comparison.**

With this framing, even if scraping fails for individual pets, the build can preserve the shipped player-useful locations from `Data.lua`. **The user never loses known-good map pins just because a current Wowhead page is malformed.**

User priority is explicit: completeness > speed. This plan does NOT change delays, backend, or concurrency.

## Out of scope (deferred to a later plan)

- Backend swap (agent-browser → urllib)
- Lower `--delay`
- Parallel fetches
- Manifest write amplification
- DOM-marker fallback when `g_mapperData` is missing (the shipped pet baseline covers the same practical pet-location gap for now)
- Stable master fallback (there is no shipped stable master baseline and the feature hasn't shipped)



## Files

**Read first:**
- `scrapper/refresh_data.py` — `generate_pets` (296-386), `generate_stable_masters` (400-496), `_collect_one` (183-197), `_tameable_npc_ids_from_source` (519-530)
- `scrapper/data_records.py` — `PetRecord` (25-36), `source_tameable_rows` (77-94)
- `scrapper/lua_export.py` — `validate_pet_records` (63-82, note `zone_id == 0` rejection at 73-74)
- `scrapper/source_cache.py` — manifest write path (139-185)
- `Data.lua` — shipped production pet baseline; parse `GHP.pet_by_zones` into `PetRecord` fallback records keyed by `NpcId`
- `scrapper/wow_pets.db` — auxiliary comparison source only; schema confirmed: `pets(npc_id PK, family_id, name, min_level, max_level, pet_class, zone_name, zone_id, alliance_react, horde_react, display_id, coords TEXT, last_updated, mapID)`

**Modify:**
- `scrapper/refresh_data.py`
- `tests/python/test_refresh_data_cache.py`
- `docs/research/data-refresh-runbook.md`

**Create:**
- `scrapper/existing_pet_data.py`
- `tests/python/test_existing_pet_data.py`

## Sequence — 7 commits plus one optional audit, ~3.5-4 days junior

### Commit 0 — test fixture prep (skip unless needed)

Skim `tests/python/test_refresh_data_cache.py` for shared fail-fast helpers. Extract if present, skip otherwise.

### Commit 1 — Data.lua baseline reader (~0.75 day)

Create `scrapper/existing_pet_data.py`:

```python
def load_existing_pet_records(data_lua_path: Path) -> dict[int, PetRecord]:
    ...
```

- Read the checked-in production `Data.lua` as the fallback baseline.
- Parse only the existing `GHP.pet_by_zones` assignment shape; do not build a general Lua interpreter.
- Build `PetRecord` per table entry using existing exported keys: `zone_name`, `zoneID`, `name`, `maxlevel`, `minlevel`, `class`, `family`, `displayId`, `NpcId`, `coords`.
- **Discard rows where `zoneID` is missing/0.** Without a map ID, the record fails `validate_pet_records` and cannot guide a hunter.
- **Parse coordinates defensively.** Keep every identifiable valid `(x, y)` pair and discard only malformed coordinate entries. Drop the full pet row only when no valid coordinate pair remains.
- Keep a small summary of loaded/dropped/salvaged counts so maintainers can see whether useful shipped data was preserved.
- Return `{npc_id: PetRecord}` keyed by int.

Tests at `tests/python/test_existing_pet_data.py`:
- Loads from a fixture `Data.lua` with 3-5 records.
- Drops rows with missing/zero `zoneID`.
- Drops rows only when all coordinates are empty or invalid.
- Salvages partial coordinate lists by preserving valid coordinate pairs.
- Parses multi-coordinate pets.
- Returns `{}` for a missing `Data.lua` path and reports the absence without breaking builds.

### Commit 1.5 — optional DB comparison audit (~0.5 day, only if useful)

Use `scrapper/wow_pets.db` only to compare against the shipped baseline, not to define the fallback baseline.

- If the DB is readable, compare DB rows against `Data.lua` by NPC ID.
- Emit an audit summary for DB-only rows, Data-only rows, and zone/coordinate differences.
- Do not let DB-only rows enter fallback automatically in v1; they need explicit review because `Data.lua` is the proven shipped dataset.
- If this audit is too large for the milestone, defer it. It is not required for the first resilient build.

### Commit 2 — `generate_pets` skip-and-continue + shipped-baseline fallback + diff log (~1.25 days)

In `scrapper/refresh_data.py`:

1. Add parameter `fallback_records: dict[int, PetRecord] | None = None` to `generate_pets`.

2. **Empty tameable family (lines 358-360):** keep `source_cache.invalidate(...)`; replace `return 1` with `skipped.append(f"family {family.name}: empty tameable source")` + `continue`.

3. **Per-pet `SourceFetchError` (lines 364-366):**
   - If `fallback_records` and `tameable.id in fallback_records`:
     - Take the fallback `PetRecord`.
     - **Override family with Wowhead's** — replace `record.family` with `(family.id, family.name)` from the current Wowhead family iteration. (User decision: Wowhead is authoritative on family classification.)
     - Append the fallback record to `records`, log to `fallback_log`.
   - Else: append to `skipped`, continue.

4. **Successful scrape AND fallback exists:** scraper wins, but log a diff entry in `pet-scraper-vs-baseline-diff.md`:
   - Compare `scraped.zone_id` vs `fallback.zone_id` — if different, log "ZONE_DIFF".
   - Compare `scraped.coords` vs `fallback.coords` — if any coord differs by >5% or count differs by >50%, log "COORD_DIFF".
   - Diff log is informational — does not block build. User audits manually.

5. **Final `return 1` only if `len(records) == 0`** (genuine total failure).

6. New report files (clear with `_clear_lines` on success):
   - `scrapper/generated/pet-skipped.md` — pets with no fallback (existing concept)
   - `scrapper/generated/pet-fallback.md` — pets recovered from shipped baseline
   - `scrapper/generated/pet-scraper-vs-baseline-diff.md` — discrepancies for audit (NEW)

7. In `main()`, BEFORE calling `generate_pets`:
   ```python
   from scrapper.existing_pet_data import load_existing_pet_records
   fallback = load_existing_pet_records(Path("Data.lua"))
   ```
   Pass `fallback_records=fallback`. **Load ONCE, before writing any generated output.** Production `Data.lua` is the baseline and must not be overwritten during a build unless the generated file validates and the diff is reviewed.

Test updates in `test_refresh_data_cache.py`:

Invert old assertions in place with `# UPDATED: skip-and-continue` comments. Pattern:
```python
# Before:
self.assertEqual(exit_code, 1)
self.assertFalse(output.exists())
# After (UPDATED: skip-and-continue):
self.assertEqual(exit_code, 0)
self.assertTrue(output.exists())
self.assertIn("32517", (generated_dir / "pet-skipped.md").read_text())
```

Add new tests:
- `test_per_pet_failure_uses_data_lua_fallback_when_available`
- `test_per_pet_failure_skipped_when_baseline_has_no_record`
- `test_data_lua_fallback_overrides_family_with_wowhead_classification`
- `test_baseline_record_with_missing_zoneid_is_dropped_at_load_time` (Commit 1 contract)
- `test_baseline_record_with_all_invalid_coords_is_dropped_at_load_time`
- `test_baseline_record_with_partial_bad_coords_keeps_valid_pairs`
- `test_empty_family_skipped_and_invalidated_for_retry`
- `test_zero_records_still_returns_1`
- `test_scraper_vs_baseline_zone_difference_logged_to_diff_file`
- `test_scraper_vs_baseline_coord_difference_logged_to_diff_file`
- `test_baseline_loaded_once_in_main_not_per_build`

### Commit 2.5 — collect-time location filter (~0.5 day)

In `scrapper/refresh_data.py:519-530` (`_tameable_npc_ids_from_source`):

Currently fetches every NPC ID from the family page. Add: skip rows where `location` is empty/missing — those would be discarded by the build (`source_tameable_rows` line 80 already filters them) so fetching them is pure waste.

Concrete edit: in the loop at line 524, before `npc_ids.append(...)`:
```python
locations = row.get("location")
if not locations:
    continue
```

Empirical impact: 749 of 2785 tameable rows (~27%) have no location — those NPC pages would not be fetched.

Tests:
- `test_tameable_rows_without_location_are_not_fetched`
- `test_tameable_rows_with_location_are_fetched_normally`

### Commit 3 — `generate_stable_masters` skip-and-continue (~0.5 day)

Same shape as Commit 2, no fallback because there is no shipped stable master baseline.

In `refresh_data.py:460-489`: replace per-record `return 1` with `continue` + skipped log. Keep cache invalidation. Final `return 1` only when zero records.

Update tests at `test_refresh_data_cache.py:1505-2252`.

### Commit 4 — `_collect_one` resilience (~0.5 day)

In `refresh_data.py:183-197`:

- Catch fetch exception, call `source_cache.record_semantic_error(...)` (already done), **return `True` instead of `raise`**.
- Do NOT call `budget.mark_collected()` on error path — preserve existing behavior (errored fetches don't consume successful page slots).
- Print `f"Skipped {role} {url}: {error}"` for audit.

Outer `except SourceFetchError` blocks (lines 126, 174) still useful for systemic failures (index/family page semantic errors) — keep them.

Add a paragraph to `docs/research/data-refresh-runbook.md`: the `while true; sleep 5` outer loop is no longer required.

Update affected collect tests.

### Commit 5 — self-healing manifest (~0.5 day)

In `scrapper/refresh_data.py` build path:

When `_listview_rows_from_source` or `_extract_mapper_data_from_source` parses a cached page successfully **AND** the manifest entry for that URL is currently `parse_error` or `error`: update the manifest entry to `ok` (clear the error field).

Mitigation against false healing: only re-classify after the FULL parse + validation pass succeeds for that source. A partial-parse must NOT heal the entry.

Concrete edit point: introduce a small helper in `source_cache.py`:
```python
def mark_ok(self, url: str, role: str) -> None:
    # Update manifest entry to status='ok' if currently error.
    # Used by build after successful parse to heal stale diagnostic state.
```

Call from `_listview_rows_from_source` and `_extract_mapper_data_from_source` on the success path.

Tests:
- `test_build_heals_stale_parse_error_in_manifest`
- `test_build_does_not_heal_when_parse_partially_fails`

## Verification

**After Commit 2** (the milestone the user is waiting for):

```bash
# Build from existing cache — should now succeed despite known bad pages
rtk python3 -m scrapper.refresh_data build-pets --from-cache --output /tmp/Data.test.lua

# Expect:
# - exit code 0
# - /tmp/Data.test.lua exists, contains "GHP.pet_by_zones = {"
# - scrapper/generated/pet-skipped.md lists pets with no shipped-baseline fallback
# - scrapper/generated/pet-fallback.md lists pets recovered from Data.lua
# - scrapper/generated/pet-scraper-vs-baseline-diff.md lists zone/coord discrepancies for audit
```

Sanity-check counts:

```bash
grep -c '\["NpcId"\]' Data.lua            # production
grep -c '\["NpcId"\]' /tmp/Data.test.lua  # new — should preserve known-good baseline coverage where scraper fails

# Inspect diff log for surprising mismatches
head -50 scrapper/generated/pet-scraper-vs-baseline-diff.md
```

**After Commit 4:**

```bash
# Single collect call — should complete even with fetch errors
rtk python3 -m scrapper.refresh_data collect-pets --limit-pages 100 --delay 5

# Manifest should have errored entries but the run completed
rtk python3 -c "
import json
d = json.load(open('scrapper/generated/refresh-manifest.json'))
errs = [s for s in d['sources'].values() if s['status'] != 'ok']
print(f'errored: {len(errs)}/{len(d[\"sources\"])}')
"
```

**After Commit 5:**

Re-run `build-pets --from-cache`. Manifest entries that were `parse_error` for pages that now parse should switch to `ok`. Inspect:
```bash
rtk python3 -c "
import json
d = json.load(open('scrapper/generated/refresh-manifest.json'))
errs = [s for s in d['sources'].values() if s['status'] != 'ok']
print(f'remaining errors: {len(errs)}')
for s in errs[:5]: print(' -', s['url'], s['status'])
"
```

Run all Python tests:
```bash
rtk python3 -m unittest discover tests/python
```

## Decisions locked in this plan

| Topic | Decision |
|---|---|
| Fallback source | Production `Data.lua` is the trusted shipped baseline |
| DB role | `scrapper/wow_pets.db` is auxiliary/comparison data only until proven against `Data.lua` |
| Fallback eligibility | Drop records with missing/zero `zoneID`; salvage partial coordinate lists and drop a row only when no valid coordinates remain |
| Scraper vs baseline conflict | Scraper wins for current successful Wowhead records, log diff for audit |
| Family classification | Wowhead's `family_id`/name wins on fallback records (Wowhead is authoritative on classification) |
| Coord priority | Scraper coords used when scrape succeeds; shipped `Data.lua` coords when fallback fires |
| Stable master fallback | Deferred — there is no shipped stable master baseline and feature hasn't shipped |
| DOM-marker fallback | Deferred — shipped pet baseline covers the same practical gap for v1 |
| Order | Kill while-true processes → commits 1-5 → user re-runs clean collect |

## Pitfalls (read before starting)

1. **`Data.lua` is the baseline.** Do not let a newer-looking DB row override the shipped player-validated dataset without an explicit audit decision.
2. **Partial coordinates are useful.** Preserve every valid coordinate pair; drop only malformed coordinate entries, and drop a pet only when no valid coordinate remains.
3. **Don't re-read the baseline during build.** Load once in `main()`, pass dict in.
4. **Cache invalidation must still fire** in empty-family and per-pet error paths — only `return 1` is removed. This preserves re-collect retry behavior.
5. **Family ID drift on fallback.** When fallback fires, override baseline family with current Wowhead family. Log it.
6. **Pets removed from Wowhead but still in `Data.lua`** must NOT be carried forward automatically. Fallback fires only inside the per-tameable loop iterating Wowhead's current listing.
7. **Self-healing trap (Commit 5):** only heal a manifest entry to `ok` after a full successful parse+validation, never on partial. A loosened parser silently healing real errors is worse than the stale state.
8. **Budget accounting in `_collect_one`:** error path must NOT call `budget.mark_collected()`.
9. **Tests: invert in place, do not delete.** Reviewer needs to see the contract change as a 2-line diff per test.

## Total sizing

| Commit | Estimate |
|---|---|
| 0 — fixture prep | 0–0.5 day |
| 1 — Data.lua baseline reader | 0.75 day |
| 1.5 — optional DB comparison audit | 0-0.5 day |
| 2 — `generate_pets` + fallback + diff | 1.25 days |
| 2.5 — collect-time location filter | 0.5 day |
| 3 — `generate_stable_masters` | 0.5 day |
| 4 — `_collect_one` | 0.5 day |
| 5 — self-healing manifest | 0.5 day |
| **Total** | **~3.5-4 days** |
