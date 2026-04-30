# Architecture Research

## Components

| Component | Responsibility | Notes |
|-----------|----------------|-------|
| `scrapper/existing_pet_data.py` | Read shipped `Data.lua` pet records into `dict[int, PetRecord]` | New narrow module; no write behavior; production data is the trusted baseline. |
| `scrapper/refresh_data.py` | Orchestrate collection/build flows, fallback merge, report writing | Existing owner for command behavior. |
| `scrapper/source_cache.py` | Store source HTML, record errors, heal stale manifest entries | Needs a focused `mark_ok` helper for success paths. |
| `scrapper/data_records.py` | Normalize source rows and provide immutable records | Reuse `PetRecord`; no broad schema changes. |
| `scrapper/lua_export.py` | Validate and serialize final records | Existing validation remains the final gate. |
| `tests/python/` | Capture new behavior and guard regression | Add one focused DB-reader test file plus update refresh tests. |
| `docs/research/data-refresh-runbook.md` | Explain new collection/build behavior | Should remove the need for outer retry loops. |

## Data Flow

1. `main()` creates one `SourceCache`.
2. For pet builds, `main()` loads production `Data.lua` once into fallback records.
3. `generate_pets()` reads Wowhead family and tameable rows from cache.
4. For each current Wowhead tameable row, the scraper tries to build a fresh `PetRecord`.
5. If scraping succeeds, the scraped record is appended and compared against shipped-baseline fallback for audit-only diff reporting.
6. If scraping fails for that pet and shipped-baseline fallback exists, the fallback record is copied with the current Wowhead family classification and appended.
7. If neither scraper nor fallback can produce a record, the pet is written to `pet-skipped.md`.
8. Lua export validation runs on the merged records; only validated output is written.

## Build Order Implications

- Implement the `Data.lua` baseline reader first so fallback behavior has a tested contract.
- Change `generate_pets()` after the baseline reader exists; this is the highest-value milestone.
- Add collect-time location filtering after the build fallback path is stable.
- Apply stable master skip-and-continue separately because it has no shipped fallback baseline.
- Update `_collect_one` and manifest self-healing last because they touch collection/cache behavior outside pet builds.
