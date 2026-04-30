# Phase 1: Shipped Baseline Reader - Context

**Gathered:** 2026-04-30
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase adds a small read-only loader that parses the checked-in production `Data.lua` pet table and converts valid shipped pet-location rows into `PetRecord` fallback records keyed by NPC ID. It does not change Wowhead scraping, build merge behavior, report generation, collection, stable masters, or manifest healing.

</domain>

<decisions>
## Implementation Decisions

### Hunter-First Data Salvage
- **D-01:** Treat the hunter's search experience as the source of truth for data tradeoffs. Partial but trustworthy location guidance is more valuable than no guidance when it helps a hunter narrow the in-game search area.
- **D-02:** Preserve every valid coordinate pair from the shipped baseline. Drop a pet row only when it has no valid zone ID or no usable coordinates left.
- **D-03:** Do not reject a full pet row because some coordinates are malformed. Salvage valid coordinates and discard only malformed coordinate entries.

### Parser Scope
- **D-04:** Implement a focused parser for the current exported `GHP.pet_by_zones` shape in `Data.lua`.
- **D-05:** The parser should tolerate small formatting variations in the current export shape, such as whitespace and field ordering where practical.
- **D-06:** Do not build a general Lua interpreter or support arbitrary Lua syntax in this phase.

### Loader API
- **D-07:** Keep the primary API simple: `load_existing_pet_records(path: Path) -> dict[int, PetRecord]`.
- **D-08:** Audit/summary information is useful if it stays simple, but it must not complicate the primary loader API or block the phase. Tests should focus first on returned records and eligibility behavior.
- **D-09:** A missing `Data.lua` path returns `{}` without failing the build path.

### Duplicate Fallback Rows
- **D-10:** If the same `NpcId` appears more than once inside shipped `Data.lua`, the last valid record wins for this phase. Do not merge coordinates or invent conflict resolution in the baseline loader.
- **D-11:** In later pet build phases, successful current Wowhead scrape data wins over shipped baseline fallback. The baseline exists only to fill gaps when Wowhead fails for a currently listed pet.

### the agent's Discretion
- The planner may choose the smallest parser structure that is easy to test and maintain.
- The planner may include lightweight internal counters or helper functions for test visibility if they remain secondary to the primary `dict[int, PetRecord]` API.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product And Phase Source Of Truth
- `.planning/PROJECT.md` — Defines production `Data.lua` as the trusted shipped baseline and records the hunter-first data salvage principle.
- `.planning/REQUIREMENTS.md` — Defines DATA-01 through DATA-04 for shipped-baseline fallback loading.
- `.planning/ROADMAP.md` — Defines Phase 1 goal, boundary, and success criteria.
- `docs/PLAN.md` — Original implementation plan and rationale for using shipped `Data.lua` as fallback.

### Code Contracts
- `Data.lua` — Production shipped pet baseline, specifically the `GHP.pet_by_zones` assignment.
- `scrapper/data_records.py` — Defines `PetRecord`, the target record shape for fallback rows.
- `scrapper/lua_export.py` — Defines validation expectations, especially nonzero `zone_id` and nonempty valid coordinates.
- `.planning/codebase/STRUCTURE.md` — Maps where new refresh pipeline code and tests belong.
- `.planning/codebase/TESTING.md` — Captures current Python `unittest` patterns and fixture style.
- `.planning/codebase/CONCERNS.md` — Notes existing refresh test failures and data-refresh fragility.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PetRecord` in `scrapper/data_records.py`: the loader should return this exact dataclass so Phase 2 can pass fallback records into pet generation without adapter churn.
- `validate_pet_records` in `scrapper/lua_export.py`: fallback loader eligibility should align with export validation by excluding records with missing/zero `zone_id` or no coordinates.
- Python `unittest` patterns in `tests/python/`: new tests should use focused fixtures and temporary files, matching existing test style.

### Established Patterns
- Python refresh code lives under `scrapper/`, with focused modules preferred over broad utilities.
- Tests for new parser behavior should live in `tests/python/test_existing_pet_data.py`.
- Generated/runtime `Data.lua` is large, so tests should use small fixture files rather than reading the full production file in every unit test.

### Integration Points
- New module: `scrapper/existing_pet_data.py`.
- Future integration: Phase 2 should load fallback records once before generated output is written, then pass them into `generate_pets`.
- This phase should not modify `scrapper/refresh_data.py` build behavior yet.

</code_context>

<specifics>
## Specific Ideas

- The guiding question for ambiguous data choices is: "What helps me more as a WoW hunter looking for this pet: no information, or trustworthy partial information that narrows the search?"
- A known-good zone or salvaged coordinate can be player-useful even when the source row is imperfect.
- Wowhead's current scrape is authoritative when available; the shipped baseline is a fallback for gaps, not a replacement for current successful data.

</specifics>

<deferred>
## Deferred Ideas

- Merge successful Wowhead scrape records with shipped-baseline fallback records in Phase 2.
- Write fallback usage and scraper-vs-baseline diff reports in Phase 2.
- More sophisticated duplicate/conflict audits can be considered later if real shipped data shows problematic duplicates.

</deferred>

---

*Phase: 1-Shipped Baseline Reader*
*Context gathered: 2026-04-30*
