# Stack Research

## Scope

Research target: resilient data refresh for a brownfield World of Warcraft addon with a Python scraper/export pipeline and Lua runtime consumers.

## Current Stack

| Area | Current Choice | Confidence | Notes |
|------|----------------|------------|-------|
| Addon runtime | WoW Lua loaded through `GiuiceHunterPets.toc` | High | Existing runtime shape is established and out of scope for this milestone. |
| Runtime libraries | LibStub, AceLocale, LibDataBroker, LibDBIcon, HereBeDragons | High | Vendored and loaded through the TOC. |
| Refresh CLI | Python standard library with `argparse`, `urllib`, subprocess-backed `agent-browser`, SQLite, dataclasses | High | No new dependency is needed for the planned fallback work. |
| Source cache | Filesystem HTML cache plus JSON manifest | High | Already supports resumable collection and semantic error recording. |
| Historical fallback data | `scrapper/wow_pets.db` SQLite file | High | Should be read with Python `sqlite3` in a narrow module. |
| Tests | Python `unittest` and local Lua scripts | High | Existing Python refresh tests are the right place to lock contract changes. |

## Recommendations

- Use Python standard-library `sqlite3` for the DB reader. Adding an ORM would be unnecessary for a single read-only query.
- Keep fallback conversion in a small `scrapper/existing_pet_db.py` module so `refresh_data.py` stays focused on orchestration.
- Keep immutable `PetRecord` as the interchange type for DB fallback records; avoid adding a second fallback-only record shape.
- Keep report outputs as markdown under `scrapper/generated/` to match existing blocker and skipped reports.
- Keep CLI command shapes unchanged for this milestone: `collect-pets`, `build-pets --from-cache`, `collect-stable-masters`, and `build-stable-masters --from-cache`.

## Do Not Use

- Do not introduce a scraping backend change while solving resilience.
- Do not introduce concurrency or async IO in the same milestone.
- Do not parse production `Data.lua` as fallback data; the plan has already chosen SQLite as the cleaner source.
- Do not add broad packaging, CI, or WoW UI test infrastructure to this refresh-pipeline milestone.

