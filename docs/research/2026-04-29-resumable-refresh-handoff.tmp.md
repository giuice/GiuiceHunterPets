# Resumable Data Refresh Handoff

Temporary handoff for starting the next spec in a new chat.

## Current State

Branch: `feature/scrap-new-data`

The data refresh pipeline exists and is committed. It can parse Wowhead embedded JavaScript, normalize pet/stable master records, export Lua, validate records, and run from `python3 -m scrapper.refresh_data`.

Latest relevant commits:

- `b7d0849 test: cover wowhead source extraction`
- `f49cb80 feat: extract wowhead embedded source data`
- `38e02d8 test: cover data normalization`
- `d234f2f feat: normalize pet and stable master records`
- `7a32e3b test: cover lua data export`
- `e7781b4 feat: export validated lua data`
- `b91a229 feat: add data refresh cli`
- `5ef6d14 docs: add data refresh runbook`
- `2999812 fix: handle live wowhead pet row variants`
- `8ba4017 perf: parallelize pet npc source fetches`
- `18ea466 docs: record wowhead source access blocker`

## Files Added Or Changed

Pipeline modules:

- `scrapper/__init__.py`
- `scrapper/wowhead_source.py`
- `scrapper/data_records.py`
- `scrapper/lua_export.py`
- `scrapper/refresh_data.py`

Tests:

- `tests/python/test_wowhead_source.py`
- `tests/python/test_data_records.py`
- `tests/python/test_lua_export.py`

Generated/research artifacts:

- `scrapper/generated/Data.sample.lua`
- `scrapper/generated/pet-skipped.md`
- `scrapper/generated/pet-refresh-blockers.md`
- `scrapper/generated/stable-master-blockers.md`
- `docs/research/data-refresh-runbook.md`

Production files intentionally not changed:

- `Data.lua`
- `StableMastersData.lua`
- `GiuiceHunterPets.toc`

## What Worked

The one-family sample worked before Wowhead started blocking the Python client:

```bash
rtk python3 -m scrapper.refresh_data pets --limit-families 1 --output scrapper/generated/Data.sample.lua
```

Observed result:

- Wrote 34 pet records to `scrapper/generated/Data.sample.lua`.
- `scrapper/generated/pet-skipped.md` recorded two skipped rows with no mapper coordinates.

The parser was hardened for live Wowhead source variants:

- Listview rows can contain unquoted JavaScript keys such as `skin: ""`.
- Some `react` values can contain `null`; these are normalized to `0`.
- Some mapper entries are nested dictionaries instead of lists.
- Some tameable rows omit `family`; these currently normalize to `0` so the known page family can still be used by `build_pet_record`.

## What Failed

The full pet refresh began as a sequential scrape, then became too slow. We added per-family progress logging and tried a `ThreadPoolExecutor`.

With `FETCH_WORKERS = 12`, Wowhead returned:

```text
HTTP Error 403: Forbidden
```

The worker count was reduced to `4`, but the environment remained blocked. Browser access via `agent-browser` could still open Wowhead, so the source itself was reachable; the Python HTTP path was blocked/rate-limited.

Current blocker files:

```text
scrapper/generated/pet-refresh-blockers.md
- https://www.wowhead.com/hunter-pets: HTTP Error 403: Forbidden

scrapper/generated/stable-master-blockers.md
- https://www.wowhead.com/search?q=stable%20master: HTTP Error 403: Forbidden
```

## Key Design Problem

The current pipeline loses useful downloaded source data if a later request fails. That is not acceptable for data refresh work.

A full refresh must not depend on one uninterrupted process. It should persist raw source pages and progress as it goes, then resume from the saved state.

## Recommended Next Spec

Create a spec for a resumable data refresh pipeline.

Suggested spec path:

```text
docs/superpowers/specs/2026-04-29-resumable-data-refresh-design.md
```

Suggested plan path after spec approval:

```text
docs/superpowers/plans/2026-04-29-resumable-data-refresh-pipeline.md
```

## Proposed Requirements

The next implementation should add:

- Raw source cache under `scrapper/generated/cache/`.
- Stable cache key per URL, probably SHA-256 of normalized URL.
- Cache metadata with URL, status, fetched timestamp, HTTP error if any, and source role.
- Manifest file, likely `scrapper/generated/refresh-manifest.json`.
- Resume behavior that reuses cached pages and only fetches missing/failed URLs.
- Explicit reset behavior, e.g. `--reset-cache`, to intentionally discard cached pages.
- Separation between source collection and Lua export:
  - collect/cache all required source pages;
  - extract/normalize from cache;
  - validate complete source set;
  - write Lua only after validation passes.
- No production replacement from partial data.
- Blocker files should distinguish source-access failures from data-validation failures.

Possible CLI shape:

```bash
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --resume
rtk python3 -m scrapper.refresh_data pets --output scrapper/generated/Data.lua --reset-cache
rtk python3 -m scrapper.refresh_data stable-masters --output scrapper/generated/StableMastersData.lua --resume
```

## Success Criteria For Next Work

- A failed full refresh leaves cached successful source pages on disk.
- A second run resumes from cache and does not re-download successful pages.
- Failed URLs are retried or recorded explicitly.
- Generated Lua is produced only when the source set is complete and validation passes.
- Python tests cover cache hit, cache miss, failed fetch, resume, and reset behavior.
- `docs/research/data-refresh-runbook.md` explains how to resume safely.

## Fresh Verification From Previous Session

Before this handoff, these passed:

```bash
rtk python3 -m unittest discover -s tests/python -p 'test_*.py' -v
rtk lua tests/stable_list_state_test.lua
rtk lua tests/map_pet_index_test.lua
```

Observed:

- Python: 17 tests passed.
- Lua stable list state: 6 tests passed.
- Lua map pet index: PASS.

## Important Caution

Do not solve the 403 by copying browser cookies into the Python client. That risks leaking browser session material and is not needed for the architectural fix. The next step is resumability and cache safety, not bypassing access controls.
