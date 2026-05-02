# Research Summary

## Key Findings

**Stack:** The existing Python standard-library stack is sufficient. Parse the shipped production `Data.lua` baseline into `PetRecord` objects, keep `sqlite3` only for optional DB comparison/audit work, and keep refresh reports as markdown files under `scrapper/generated/`.

**Table Stakes:** The resilient build must continue past isolated malformed pages, recover current Wowhead-listed pets from shipped `Data.lua` fallback when available, validate merged output before writing Lua, and leave clear audit reports.

**Watch Out For:** The safest boundary is current Wowhead listings. Shipped `Data.lua` fallback should never become a second source of current pet inclusion; it should only fill missing details for pets that Wowhead still lists as tameable. `scrapper/wow_pets.db` should not override the shipped baseline without explicit audit.

## Roadmap Implications

- Phase 1 should establish the shipped-baseline reader and fallback data contract.
- Phase 2 should deliver the user-critical pet build fallback path and verification command.
- Later phases can reduce wasted collection, handle stable masters, improve collection resilience, and heal stale manifest state.

## Verification Focus

- Unit tests for `Data.lua` fallback loading, partial coordinate salvage, and fallback eligibility.
- Updated refresh tests showing skip-and-continue behavior.
- Cache-backed pet build command producing a valid Lua output even with known bad pages.
