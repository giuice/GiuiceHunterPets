---
type: lesson
id: LESSON-002
title: Pipeline Pitfalls
created: 2026-05-04
updated: 2026-05-04
tags: [lesson, issue]
sources: [wiki/raw/specs/pipeline-pitfalls.md]
confidence: high
contested: false
contradictions: []
verified_by: human
approved: true
linked_issues: []
---

# LESSON-002: Pipeline Pitfalls

## Trigger

When modifying the data refresh pipeline, adding new fallback logic, or extending `generate_pets` / `generate_stable_masters` / `_collect_one`.

## Verified Lesson

| # | Pitfall | Warning Sign | Prevention Strategy | Phase |
|---|---------|--------------|---------------------|-------|
| 1 | Shipped-baseline fallback records fail Lua export validation | Fallback rows have `zone_id == 0` or no valid coords | Drop missing/zero `zoneID`, salvage valid coordinate pairs, and drop a row only when no valid coordinates remain | 1 |
| 2 | DB is accidentally treated as the authority | New work uses `scrapper/wow_pets.db` instead of production `Data.lua` as the fallback baseline | Keep `Data.lua` as the v1 trusted baseline; use DB only for optional comparison/audit until explicitly reviewed | 1 |
| 3 | Fallback accidentally carries removed pets | Records appear for NPCs not listed in current Wowhead tameable rows | Use fallback only inside the current tameable-row loop | 2 |
| 4 | Family classification drifts between baseline and Wowhead | Fallback record has historical family while current page lists a different one | Override fallback family with current Wowhead family and log the recovery | 2 |
| 5 | Build still fails fast after isolated pet errors | One bad NPC page returns exit code 1 even with many good records | Replace per-pet fatal returns with skipped/fallback flow; fail only when zero records or validation fails | 2 |
| 6 | Diff reporting blocks useful output | Zone/coord mismatch prevents export even though a record is valid | Keep diff report informational and audit-oriented | 2 |
| 7 | Locationless tameable rows waste fetches | Collector downloads NPC pages that `source_tameable_rows` later discards | Filter rows with missing `location` before appending NPC IDs | 3 |
| 8 | Collection errors consume successful page budget | Failed fetch increments `PageBudget.collected` | Do not call `mark_collected()` on fetch error path | 5 |
| 9 | Manifest self-healing hides real parse errors | Error entry becomes `ok` after only partial parsing | Call `mark_ok` only after full parse and validation succeeds | 6 |
| 10 | Existing red tests obscure new regressions | Test suite remains broadly failing after changes | Update old fail-fast assertions in place and keep new tests focused on changed contracts | All |

## Evidence

Derived from `.planning/research/PITFALLS.md` which maps each pitfall to the pipeline phase where it surfaces. Pitfalls 1-2 are baseline-reader boundary issues; pitfalls 3-6 are pet-build fallback logic; pitfalls 7-8 are collection-time; pitfall 9 is manifest integrity; pitfall 10 is ongoing test hygiene.

## Future Guidance

- Before touching `generate_pets` or `generate_stable_masters`, check this table for the relevant phase
- When adding new fallback paths, add a corresponding pitfall entry with warning sign and prevention strategy
- Pitfall #10 applies broadly: never leave the test suite in a broadly-failing state after changes

## Related Pages

- [[data-refresh-pipeline]] — locked-in decisions and operational commands for the same pipeline