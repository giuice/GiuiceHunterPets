# Stack Research

## Scope

Research target: resilient data refresh for a brownfield World of Warcraft addon with a Python scraper/export pipeline and Lua runtime consumers.

## Current Stack

| Area | Current Choice | Confidence | Notes |
|------|----------------|------------|-------|
| Addon runtime | WoW Lua loaded through `GiuiceHunterPets.toc` | High | Existing runtime shape is established and out of scope for this milestone. |
| Runtime libraries | LibStub, AceLocale, LibDataBroker, LibDBIcon, HereBeDragons | High | Vendored and loaded through the TOC. |
| Refresh CLI | Python standard library with `argparse`, `urllib`, subprocess-backed `agent-browser`, dataclasses, and optional SQLite comparison tooling | High | No new dependency is needed for the planned fallback work. |
| Source cache | Filesystem HTML cache plus JSON manifest | High | Already supports resumable collection and semantic error recording. |
| Historical fallback data | Production `Data.lua` | High | It is the trusted shipped baseline already consumed by addon players. |
| Auxiliary comparison data | `scrapper/wow_pets.db` SQLite file | Medium | Useful for audits and possible future enrichment after comparison with `Data.lua`; not the v1 fallback authority. |
| Tests | Python `unittest` and local Lua scripts | High | Existing Python refresh tests are the right place to lock contract changes. |

## Recommendations

- Parse production `Data.lua` in a small `scrapper/existing_pet_data.py` module so `refresh_data.py` stays focused on orchestration.
- If DB comparison is added, use Python standard-library `sqlite3`; adding an ORM would be unnecessary for a single read-only audit query.
- Keep immutable `PetRecord` as the interchange type for fallback records; avoid adding a second fallback-only record shape.
- Keep report outputs as markdown under `scrapper/generated/` to match existing blocker and skipped reports.
- Keep CLI command shapes unchanged for this milestone: `collect-pets`, `build-pets --from-cache`, `collect-stable-masters`, and `build-stable-masters --from-cache`.

## Do Not Use

- Do not introduce a scraping backend change while solving resilience.
- Do not introduce concurrency or async IO in the same milestone.
- Do not treat `scrapper/wow_pets.db` as more authoritative than production `Data.lua` without explicit comparison and review.
- Do not add broad packaging, CI, or WoW UI test infrastructure to this refresh-pipeline milestone.
