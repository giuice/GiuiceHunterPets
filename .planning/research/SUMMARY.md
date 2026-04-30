# Research Summary

## Key Findings

**Stack:** The existing Python standard-library stack is sufficient. Use `sqlite3` for fallback reads, reuse `PetRecord`, and keep refresh reports as markdown files under `scrapper/generated/`.

**Table Stakes:** The resilient build must continue past isolated malformed pages, recover current Wowhead-listed pets from DB fallback when available, validate merged output before writing Lua, and leave clear audit reports.

**Watch Out For:** The safest boundary is current Wowhead listings. DB fallback should never become a second source of current pet inclusion; it should only fill missing details for pets that Wowhead still lists as tameable.

## Roadmap Implications

- Phase 1 should establish the DB reader and fallback data contract.
- Phase 2 should deliver the user-critical pet build fallback path and verification command.
- Later phases can reduce wasted collection, handle stable masters, improve collection resilience, and heal stale manifest state.

## Verification Focus

- Unit tests for DB loading and fallback eligibility.
- Updated refresh tests showing skip-and-continue behavior.
- Cache-backed pet build command producing a valid Lua output even with known bad pages.

