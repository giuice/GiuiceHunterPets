# Feature Research

## Table Stakes

| Feature | Complexity | Dependencies |
|---------|------------|--------------|
| Cache-backed pet build can continue past isolated NPC failures | Medium | Existing `generate_pets`, source cache error reporting, tests |
| DB fallback records load safely from `scrapper/wow_pets.db` | Medium | SQLite schema, `PetRecord`, Lua export validation |
| Fallback rows with unusable location data are discarded early | Low | DB reader and validation expectations |
| Scraper output replaces DB fallback when both exist | Medium | Record comparison and control-flow ordering |
| Skipped/fallback/diff reports are written for audit | Medium | Existing report writer helpers |
| Stable master build skips isolated per-NPC failures | Low | Existing stable master generation path |
| Collection skips fetch failures and preserves page budget semantics | Low | `_collect_one`, `PageBudget`, manifest error recording |
| Manifest errors heal only after successful parse/validation | Medium | Source cache manifest update helper and parser success paths |
| Tests describe the new skip-and-continue contract | Medium | Existing `tests/python/test_refresh_data_cache.py` |

## Differentiators

| Feature | Complexity | Reason to Defer or Include |
|---------|------------|----------------------------|
| DOM-marker fallback for pages without mapper data | Medium | Deferred; DB fallback handles current known blockers. |
| Backend swap away from `agent-browser` | Medium | Deferred; not needed for build-from-cache resilience. |
| Cache pruning/cleanup command | Medium | Useful later for 1GB+ caches, not necessary for correctness. |
| Stable master production addon integration | Medium | Deferred; stable master data is not loaded by the addon yet. |

## Anti-Features

- Carrying all DB pets regardless of current Wowhead listings would increase completeness numerically but risks reintroducing removed or no-longer-tameable pets.
- Flattening all manifest errors into a single status to make tests pass would hide useful diagnostic distinctions.
- Re-reading the DB inside the per-pet loop would make fallback behavior harder to reason about and test.

